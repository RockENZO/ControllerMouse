#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/controllermouse-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
swiftc -module-cache-path "$test_dir/module-cache" -o "$test_dir/mapping-tests" \
  Sources/Configuration/ButtonMapping.swift Sources/App/AppState.swift \
  Sources/Mouse/MouseController.swift Sources/Mouse/ClickDragHandler.swift \
  Sources/Mouse/KeyboardSimulator.swift Sources/Controllers/ControllerInputHandler.swift \
  Tests/ControllerMappingTests.swift
"$test_dir/mapping-tests"
