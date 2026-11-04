#!/bin/zsh
set -eu
ROOT=${0:A:h}
APP="$ROOT/build/Matrix Rain.app"
mkdir -p "$APP/Contents/MacOS"
swift build --package-path "$ROOT" -c release --arch arm64 --product MatrixRain -Xswiftc -warnings-as-errors
BIN=$(swift build --package-path "$ROOT" -c release --arch arm64 --show-bin-path)
cp "$BIN/MatrixRain" "$APP/Contents/MacOS/MatrixRain"
cp "$ROOT/Info.plist" "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
echo "Built: $APP"
