#!/bin/bash

tmux new-session -A -s maxima \
  'xvfb-run -a --server-args="-screen 0 1024x768x24" maxima-cli'
