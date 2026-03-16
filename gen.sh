#!/bin/zsh

if command -v fvm >/dev/null 2>&1; then
  fvm flutter packages pub run build_runner build
else
  flutter packages pub run build_runner build
fi