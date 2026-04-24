#!/usr/bin/env python3

from pathlib import Path
import sys

PALETTE_PATH = Path.home() / ".config" / "colors.txt"
POLYBAR_OUTPUT_PATH = Path.home() / ".config" / "polybar" / "colors.ini"
ROFI_OUTPUT_PATH = Path.home() / ".config" / "rofi" / "colors.rasi"

RESERVED_KEYS = {"start", "end", "steps"}
REQUIRED_KEYS = ("start", "end", "steps")


def hex_to_rgb(hex_color: str):
    hex_color = normalize_hex_color(hex_color).lstrip("#")
    return [int(hex_color[i:i+2], 16) / 255.0 for i in (0, 2, 4)]


def rgb_to_hex(rgb):
    rgb = [max(0, min(1, c)) for c in rgb]
    return "#{:02x}{:02x}{:02x}".format(
        int(round(rgb[0] * 255)),
        int(round(rgb[1] * 255)),
        int(round(rgb[2] * 255)),
    )


def normalize_hex_color(hex_color: str):
    normalized = hex_color.strip().lstrip("#")
    if len(normalized) != 6 or any(c not in "0123456789abcdefABCDEF" for c in normalized):
        raise ValueError(f"Invalid hex color: {hex_color}")
    return f"#{normalized.lower()}"


def normalize_alpha(alpha: str):
    normalized = alpha.strip().lstrip("#")
    if len(normalized) != 2 or any(c not in "0123456789abcdefABCDEF" for c in normalized):
        raise ValueError(f"Invalid alpha value: {alpha}")
    return normalized.lower()


def with_alpha(hex_color: str, alpha: str):
    return f"{normalize_hex_color(hex_color)}{normalize_alpha(alpha)}"


def is_generated_alpha_key(key: str):
    if key == "backgroundalpha":
        return True
    if not key.startswith("c") or not key.endswith("alpha"):
        return False

    color_index = key[1:-5]
    return color_index.isdigit()


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def linear_to_srgb(c):
    return 12.92 * c if c <= 0.0031308 else 1.055 * (c ** (1 / 2.4)) - 0.055


def rgb_to_oklab(rgb):
    r, g, b = [srgb_to_linear(c) for c in rgb]

    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

    l_, m_, s_ = l ** (1 / 3), m ** (1 / 3), s ** (1 / 3)

    L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
    a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
    b = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_

    return [L, a, b]


def oklab_to_rgb(lab):
    L, a, b = lab

    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b

    l, m, s = l_ ** 3, m_ ** 3, s_ ** 3

    r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
    g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
    b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

    return [linear_to_srgb(c) for c in (r, g, b)]


def interpolate_oklab(start_rgb, end_rgb, steps):
    start_lab = rgb_to_oklab(start_rgb)
    end_lab = rgb_to_oklab(end_rgb)

    colors = []
    for i in range(steps):
        t = i / (steps - 1) if steps > 1 else 0
        lab = [start_lab[j] + (end_lab[j] - start_lab[j]) * t for j in range(3)]
        colors.append(oklab_to_rgb(lab))

    return colors


def parse_palette_file(path: Path):
    data = {}
    extra_colors = {}

    with open(path, "r", encoding="utf-8") as f:
        for raw_line in f:
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                raise ValueError(f"Invalid line in {path}: {raw_line.rstrip()}")

            key, value = [part.strip() for part in line.split("=", 1)]
            normalized_key = key.lower()

            if normalized_key in data or normalized_key in extra_colors:
                raise ValueError(f"Duplicate key in {path}: {key}")

            if normalized_key in RESERVED_KEYS:
                data[normalized_key] = value
            else:
                extra_colors[normalized_key] = value

    missing = [key for key in REQUIRED_KEYS if key not in data]
    if missing:
        raise ValueError(f"Missing keys in {path}: {', '.join(missing)}")

    data["steps"] = int(data["steps"])
    if data["steps"] <= 0:
        raise ValueError("steps must be greater than 0")

    return data, extra_colors


def add_alpha_variants(colors, extra_colors):
    alpha = extra_colors.get("alpha")
    if alpha is None:
        return extra_colors

    if any(is_generated_alpha_key(key) for key in extra_colors):
        raise ValueError("backgroundalpha and cNalpha values are generated automatically; remove them from colors.txt")
    if "background" not in extra_colors:
        raise ValueError("backgroundalpha requires a background color in colors.txt")

    color_variants = {key: value for key, value in extra_colors.items() if key != "alpha"}
    color_variants["backgroundalpha"] = with_alpha(extra_colors["background"], alpha)
    for i, color in enumerate(colors, start=1):
        color_variants[f"c{i}alpha"] = with_alpha(color, alpha)
    return color_variants


def iter_color_entries(colors, extra_colors):
    for i, color in enumerate(colors, start=1):
        yield f"c{i}", color
    yield from extra_colors.items()


def write_polybar_colors(path: Path, colors, extra_colors):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write("[colors]\n")
        for key, value in iter_color_entries(colors, extra_colors):
            f.write(f"{key} = {value}\n")


def write_rofi_colors(path: Path, colors, extra_colors):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write("* {\n")
        for key, value in iter_color_entries(colors, extra_colors):
            f.write(f"    {key}: {value};\n")
        f.write("}\n")


def main():
    palette_path = Path(sys.argv[1]).expanduser() if len(sys.argv) > 1 else PALETTE_PATH
    values, extra_colors = parse_palette_file(palette_path)

    gradient = interpolate_oklab(
        hex_to_rgb(values["start"]),
        hex_to_rgb(values["end"]),
        values["steps"],
    )
    hex_colors = [rgb_to_hex(rgb) for rgb in gradient]
    extra_colors = add_alpha_variants(hex_colors, extra_colors)

    write_polybar_colors(POLYBAR_OUTPUT_PATH, hex_colors, extra_colors)
    write_rofi_colors(ROFI_OUTPUT_PATH, hex_colors, extra_colors)

    print(f"Read palette from: {palette_path}")
    print(f"Wrote: {POLYBAR_OUTPUT_PATH}")
    print(f"Wrote: {ROFI_OUTPUT_PATH}")


if __name__ == "__main__":
    main()
