#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/"

usage() {
    echo "Usage: $(basename "$0") [-n] <destination>"
    echo "  -n    Dry run (show what would be transferred)"
    exit 1
}

DRY_RUN=""
while getopts "n" opt; do
    case $opt in
        n) DRY_RUN="--dry-run" ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

[[ $# -ne 1 ]] && usage
DEST="$1"

rsync -av --delete $DRY_RUN \
    --exclude '.git/' \
    --exclude '.build/' \
    --exclude 'dev-docs/' \
    --exclude 'dev-assets/' \
    --exclude '.claude/' \
    --exclude 'CLAUDE.md' \
    --exclude 'Herald/Herald.xcodeproj/xcuserdata/' \
    --exclude 'Herald/Herald.xcodeproj/project.xcworkspace/xcuserdata/' \
    --exclude '.DS_Store' \
    "$SRC_DIR" "$DEST"
