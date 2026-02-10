#!/bin/bash

AUTH_FILE="$HOME/.local/share/maxima/auth.toml"

if [ ! -f "$AUTH_FILE" ]; then
    mkdir -p "$(dirname "$AUTH_FILE")"
    nano "$AUTH_FILE"
fi

xvfb-run -a \
    --server-args="-screen 0 1024x768x24" \
    env WINEPREFIX="$HOME/.local/share/maxima/wine/prefix" \
    "$HOME/ge-proton/files/bin/wine64" 123.exe || true

xvfb-run -a --server-args="-screen 0 1024x768x24" maxima-cli
