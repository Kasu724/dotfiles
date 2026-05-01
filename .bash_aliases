alias mybonsai='cbonsai -ilm "wah!"'

myfetch() {
    local video="${1:-takodachi.gif}"

    if [[ "$video" == "takodachi.gif" && ! -e "$HOME/.local/share/anifetch/assets/takodachi.gif" ]]; then
        video="$HOME/.config/anifetch/takodachi.gif"
    fi

    anifetch "$video" \
        -r 15 \
        -W 50 \
        -H 50 \
        -ca "--symbols braille --fg-only" \
        --center \
        -c main
}
