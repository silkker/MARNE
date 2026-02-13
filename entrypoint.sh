#!/bin/bash

tmux new-session -A -s maxima \
  'weston --backend=headless --socket=wayland-1 & xwayland-run -- maxima-cli'
