#!/bin/bash
#
# build_cli.sh
#
# Builds a release version of the `herald` macOS CLI (in HeraldCLI/) and
# prints instructions for placing the resulting binary on $PATH.
#
# Usage:
#   ./scripts/build_cli.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLI_DIR="$REPO_ROOT/HeraldCLI"

if [ ! -f "$CLI_DIR/Package.swift" ]; then
  echo "Error: HeraldCLI/Package.swift not found at $CLI_DIR" >&2
  exit 1
fi

echo "Building herald CLI (release configuration)..."
echo ""

cd "$CLI_DIR"
swift build -c release

# Resolve the actual binary path from SwiftPM rather than hard-coding
# .build/release — this honours custom build paths and arch-specific dirs.
BIN_PATH="$(swift build -c release --show-bin-path)/herald"

if [ ! -x "$BIN_PATH" ]; then
  echo "Error: expected binary at $BIN_PATH but it is missing or not executable." >&2
  exit 1
fi

echo ""
echo "Build complete."
echo ""
echo "Binary: $BIN_PATH"
echo ""
echo "To run it as 'herald' from anywhere, add this binary to a directory"
echo "on your \$PATH."
