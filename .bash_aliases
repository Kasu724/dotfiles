alias mybonsai='cbonsai -ilm "wah!"'

alias mymatrix='unimatrix -afos 96'

alias myquarium='asciiquarium'

myhelp() {
    printf '%s\n' \
        'Animation aliases:' \
        '  mybonsai   - custom cbonsai: cbonsai -ilm "wah!"' \
        '  mymatrix   - custom unimatrix: unimatrix -afos 96' \
        '  myquarium  - custom asciiquarium' \
        '  myfetch    - custom anifetch: anifetch with takodachi animation'
}

alias myhelp='myhelp'

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

alias myfetch='myfetch'
