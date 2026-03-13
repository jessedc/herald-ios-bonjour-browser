#!/bin/bash
set -euo pipefail

# Capture App Store screenshots by running the "AppStore Screenshots" test plan
# and extracting the resulting screenshot attachments.
#
# Produces three sets of screenshots matching App Store Connect size requirements:
#   - 6.7"  (1284 × 2778): iPhone 14 Plus
#   - 6.9"  (1320 × 2868): iPhone 16 Pro Max
#   - iPad 13" (2064 × 2752): iPad Pro 13-inch (M4)

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

PROJECT="$REPO_ROOT/Herald/Herald.xcodeproj"
SCHEME="Herald"
TEST_PLAN="AppStore Screenshots"
OUTPUT_DIR="$REPO_ROOT/screenshots"

SIMULATORS="iPhone 14 Plus|6.7-inch|com.apple.CoreSimulator.SimDeviceType.iPhone-14-Plus
iPhone 16 Pro Max|6.9-inch|com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro-Max
iPad Pro 13-inch (M4)|iPad-13-inch|com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M4-8GB"

RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-26-2"

echo "==> Cleaning previous results..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Ensure each simulator exists, creating if needed
echo "$SIMULATORS" | while IFS='|' read -r SIMULATOR SIZE_DIR DEVICE_TYPE; do
    if ! xcrun simctl list devices | grep -q "$SIMULATOR"; then
        echo "==> Creating simulator: $SIMULATOR"
        xcrun simctl create "$SIMULATOR" "$DEVICE_TYPE" "$RUNTIME"
    fi
done

echo "$SIMULATORS" | while IFS='|' read -r SIMULATOR SIZE_DIR DEVICE_TYPE; do
    RESULT_BUNDLE="/tmp/Herald/AppStoreScreenshots-${SIZE_DIR}.xcresult"

    echo ""
    echo "============================================"
    echo "==> Capturing on $SIMULATOR ($SIZE_DIR)"
    echo "============================================"

    rm -rf "$RESULT_BUNDLE"

    # Boot the simulator so we can set the status bar
    echo "==> Booting $SIMULATOR..."
    xcrun simctl boot "$SIMULATOR" 2>/dev/null || true

    # Override the status bar for clean marketing screenshots
    echo "==> Setting status bar overrides..."
    xcrun simctl status_bar "$SIMULATOR" override \
        --time "9:41" \
        --batteryState charged \
        --batteryLevel 100 \
        --cellularMode active \
        --cellularBars 4 \
        --wifiBars 3 \
        --operatorName ""

    echo "==> Running '$TEST_PLAN' test plan..."
    xcodebuild \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -testPlan "$TEST_PLAN" \
        -destination "platform=iOS Simulator,name=$SIMULATOR" \
        -resultBundlePath "$RESULT_BUNDLE" \
        test 2>&1 | tail -20

    # Clear status bar overrides
    xcrun simctl status_bar "$SIMULATOR" clear

    if [ ! -d "$RESULT_BUNDLE" ]; then
        echo "ERROR: Result bundle not found at $RESULT_BUNDLE"
        exit 1
    fi

    echo "==> Exporting attachments..."
    ATTACHMENTS_DIR="/tmp/Herald/screenshot_attachments-${SIZE_DIR}"
    rm -rf "$ATTACHMENTS_DIR"
    mkdir -p "$ATTACHMENTS_DIR"

    xcrun xcresulttool export attachments \
        --path "$RESULT_BUNDLE" \
        --output-path "$ATTACHMENTS_DIR"

    if [ ! -f "$ATTACHMENTS_DIR/manifest.json" ]; then
        echo "ERROR: No manifest.json found — no attachments exported"
        exit 1
    fi

    echo "==> Organizing screenshots..."
    DEST_DIR="$OUTPUT_DIR/$SIZE_DIR"
    mkdir -p "$DEST_DIR"

    python3 -c "
import json, shutil, os, re, sys

manifest_path = '$ATTACHMENTS_DIR/manifest.json'
attachments_dir = '$ATTACHMENTS_DIR'
output_dir = '$DEST_DIR'

with open(manifest_path) as f:
    manifest = json.load(f)

count = 0
for test_entry in manifest:
    for att in test_entry.get('attachments', []):
        exported = att.get('exportedFileName', '')
        human_name = att.get('suggestedHumanReadableName', exported)

        # Strip the trailing '_0_<UUID>.png' to get the clean name
        clean = re.sub(r'_\d+_[0-9A-Fa-f-]+\.png$', '', human_name)
        if not clean:
            clean = os.path.splitext(exported)[0]
        name = clean + '.png'

        src = os.path.join(attachments_dir, exported)
        if os.path.exists(src):
            dst = os.path.join(output_dir, name)
            shutil.copy2(src, dst)
            print(f'  {name}')
            count += 1

if count == 0:
    print('WARNING: No screenshot attachments found in manifest', file=sys.stderr)
    sys.exit(1)
else:
    print(f'Extracted {count} screenshot(s)')
"
done

echo ""
echo "==> Done! Screenshots saved to $OUTPUT_DIR/"
echo ""
echo "Contents:"
for SIZE_DIR in "6.7-inch" "6.9-inch" "iPad-13-inch"; do
    echo "  $SIZE_DIR:"
    ls -1 "$OUTPUT_DIR/$SIZE_DIR/" 2>/dev/null | sed 's/^/    /'
done
