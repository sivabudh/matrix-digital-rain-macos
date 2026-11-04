#!/bin/zsh
set -eu
ROOT=${0:A:h}
COMPILER=$(xcrun --find swiftc)
TEST_PLUGIN_DIR="${COMPILER:h:h}/lib/swift/host/plugins/testing"
arguments=()
# Some Command Line Tools releases install Testing macros in a subdirectory
# that Swift Build does not search automatically. Use the selected toolchain.
if [[ -d "$TEST_PLUGIN_DIR" ]]; then
    arguments=(-Xswiftc -plugin-path -Xswiftc "$TEST_PLUGIN_DIR")
fi
swift test --package-path "$ROOT" --disable-xctest "${arguments[@]}" "$@"

swift build --package-path "$ROOT" --target NativeChecks -Xswiftc -enable-testing
BIN=$(swift build --package-path "$ROOT" --show-bin-path)
"$BIN/NativeChecks"
