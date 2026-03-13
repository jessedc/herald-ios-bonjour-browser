#!/bin/bash
# Run SwiftLint using the local SPM plugin (no global install required).
# Usage:
#   ./lint.sh          # lint all sources
#   ./lint.sh --fix    # auto-fix what's possible

set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "${1:-}" == "--fix" ]]; then
    swift package plugin --allow-writing-to-package-directory swiftlint --fix --config .swiftlint.yml
else
    swift package plugin --allow-writing-to-package-directory swiftlint lint --config .swiftlint.yml
fi
