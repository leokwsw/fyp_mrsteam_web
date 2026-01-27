#!/bin/zsh

rm -rf build

if command -v fvm >/dev/null 2>&1; then
  fvm flutter packages pub run build_runner build
  fvm flutter run
else
  flutter packages pub run build_runner build
  flutter run
fi
