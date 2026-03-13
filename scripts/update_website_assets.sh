#!/bin/bash
#
# update_website_assets.sh
#
# Copies app icon and screenshots from project sources into docs/assets
# for the GitHub Pages website, optimizing PNGs with pngcrush and
# generating favicon/apple-touch-icon sizes with sips.
#
# Uses only macOS built-in tools (sips, pngcrush via Xcode).

set -euo pipefail

PNGCRUSH="$(xcrun --find pngcrush 2>/dev/null || true)"
if [ -z "$PNGCRUSH" ]; then
  echo "Error: pngcrush not found. Install Xcode or Xcode Command Line Tools." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ICON_SRC="$REPO_ROOT/Herald/Herald/Resources/Assets.xcassets/AppIcon.appiconset/logo-draft-2.png"
SCREENSHOTS_SRC="$REPO_ROOT/screenshots/6.9-inch"

ICON_DEST="$REPO_ROOT/docs/assets/icon"
SCREENSHOTS_DEST="$REPO_ROOT/docs/assets/screenshots"

# ── Helpers ──────────────────────────────────────────

crush() {
  local src="$1" dest="$2"
  "$PNGCRUSH" -ow -q -rem allb -reduce "$dest" 2>/dev/null
  local before after
  before=$(stat -f%z "$src")
  after=$(stat -f%z "$dest")
  local pct=$((100 - (after * 100 / before)))
  printf "  %-40s %6s → %6s (%d%% smaller)\n" \
    "$(basename "$dest")" \
    "$(echo "$before" | awk '{printf "%.0fK", $1/1024}')" \
    "$(echo "$after" | awk '{printf "%.0fK", $1/1024}')" \
    "$pct"
}

# ── Setup ────────────────────────────────────────────

mkdir -p "$ICON_DEST" "$SCREENSHOTS_DEST"

echo "Updating website assets..."
echo ""

# ── App Icon ─────────────────────────────────────────

echo "App icon:"

# Web-size icon (256px — the site only displays at 64px max, 2x retina = 128px)
sips -z 256 256 --out "$ICON_DEST/app-icon.png" "$ICON_SRC" >/dev/null 2>&1
"$PNGCRUSH" -ow -q -rem allb -reduce "$ICON_DEST/app-icon.png" 2>/dev/null
printf "  %-40s generated (256x256)\n" "app-icon.png"

# Apple touch icon (180px)
sips -z 180 180 --out "$ICON_DEST/apple-touch-icon.png" "$ICON_SRC" >/dev/null 2>&1
"$PNGCRUSH" -ow -q -rem allb -reduce "$ICON_DEST/apple-touch-icon.png" 2>/dev/null
printf "  %-40s generated (180x180)\n" "apple-touch-icon.png"

# Favicon (32px)
sips -z 32 32 --out "$ICON_DEST/favicon-32.png" "$ICON_SRC" >/dev/null 2>&1
"$PNGCRUSH" -ow -q -rem allb -reduce "$ICON_DEST/favicon-32.png" 2>/dev/null
printf "  %-40s generated (32x32)\n" "favicon-32.png"

echo ""

# ── Screenshots ──────────────────────────────────────

echo "Screenshots:"

for src in "$SCREENSHOTS_SRC"/*.png; do
  filename="$(basename "$src")"
  dest="$SCREENSHOTS_DEST/$filename"
  cp "$src" "$dest"
  crush "$src" "$dest"
done

echo ""
echo "Done."
