#!/bin/bash
set -euo pipefail

# Xcode Cloud runs this script after cloning the repository.
# It writes PRODUCT_BUNDLE_IDENTIFIER into Config.xcconfig from the
# HERALD_BUNDLE_ID environment variable (set in the Xcode Cloud workflow).

CONFIG_FILE="$CI_PRIMARY_REPOSITORY_PATH/Herald/Config.xcconfig"

if [ -n "${HERALD_BUNDLE_ID:-}" ]; then
    echo "PRODUCT_BUNDLE_IDENTIFIER = ${HERALD_BUNDLE_ID}" >> "$CONFIG_FILE"
    echo "Set PRODUCT_BUNDLE_IDENTIFIER to ${HERALD_BUNDLE_ID}"
else
    echo "Error: HERALD_BUNDLE_ID environment variable not set"
    exit 1
fi
