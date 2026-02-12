#!/bin/bash

tmux new-session -A -s maxima \
  'weston --backend=headless-backend.so --socket=wayland-0'
