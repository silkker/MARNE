#!/bin/bash

tmux new-session -A -s maxima \
  'Xvfb :99 -screen 0 1024x768x24'

# One day
# 'xwayland-run -- maxima-cli'
# 'wlheadless-run -c weston -- maxima-cli'
