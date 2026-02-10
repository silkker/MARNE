#!/bin/bash

xvfb-run -a \
    --server-args="-screen 0 1024x768x24" \
    env WINEPREFIX="$HOME/.local/share/maxima/wine/prefix" \
    "$HOME/ge-proton/files/bin/wine64" 123.exe || true

xvfb-run -a --server-args="-screen 0 1024x768x24" maxima-cli
