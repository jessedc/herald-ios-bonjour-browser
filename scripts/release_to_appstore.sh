#!/bin/bash
set -euo pipefail

# Automate App Store Connect release preparations for Herald.
#
# Uses the `asc` CLI (App-Store-Connect-CLI) to:
#   1. Select a build from Xcode Cloud
#   2. Create an App Store version (or reuse existing)
#   3. Upload "What's New" text from CHANGELOG.md
#   4. Upload screenshots for all device sizes
#   5. Attach the build to the version
#   6. Run preflight checks and submit for review
#
# Every step is idempotent — safe to re-run if interrupted.
#
# See --help for setup instructions.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Herald's known App Store ID (from App Store listing)
HERALD_APP_STORE_ID="6759459419"

# Project paths
PBXPROJ="$REPO_ROOT/Herald/Herald.xcodeproj/project.pbxproj"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"
SCREENSHOTS_DIR="$REPO_ROOT/screenshots"

# Screenshot directory → asc display type mapping.
# If uploads fail, run `asc screenshots sizes` to find correct identifiers.
screenshot_types_for() {
  case "$1" in
    6.7-inch)     echo "APP_IPHONE_65" ;;
    6.9-inch)     echo "APP_IPHONE_67 APP_IPHONE_69" ;;
    iPad-13-inch) echo "APP_IPAD_PRO_3GEN_129" ;;
    *)            echo "" ;;
  esac
}

# TTY-aware colors
if [ -t 1 ]; then
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  YELLOW='\033[0;33m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  GREEN='' RED='' YELLOW='' BOLD='' RESET=''
fi

# Run an asc CLI command and store its JSON output in the named variable.
# On failure, prints the asc error output and exits instead of silently falling
# back to empty data (which masks flag typos and auth failures).
# Usage: run_asc VARNAME "description" asc args...
run_asc() {
  local _var="$1" _desc="$2"
  shift 2
  local _stderr_file _output
  _stderr_file=$(mktemp)
  if _output=$("$@" 2>"$_stderr_file"); then
    printf -v "$_var" '%s' "$_output"
  else
    echo -e "${RED}Error: $_desc${RESET}" >&2
    sed 's/^/  /' "$_stderr_file" >&2
    rm -f "$_stderr_file"
    exit 1
  fi
  rm -f "$_stderr_file"
}

# Global state
DRY_RUN=false
BUILD_ID=""
APP_ID=""
VERSION=""
VERSION_ID=""
LOCALIZATION_ID=""

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------

usage() {
  cat <<'HELP'
Usage: release_to_appstore.sh [OPTIONS]

Automate App Store Connect release preparations for Herald.

OPTIONS:
  --build-id BUILD_ID   Use a specific build ID (skip interactive selection)
  --dry-run             Show what would happen without making changes
  --help, -h            Show this help message

SETUP REQUIREMENTS:

  1. Install the asc CLI:

       brew install asc

  2. Generate an App Store Connect API key:

       https://appstoreconnect.apple.com/access/integrations/api

     Required role: Admin or App Manager.
     Download the .p8 private key file — it can only be downloaded once.

  3. Authenticate:

       asc auth login \
         --name "Herald" \
         --key-id "YOUR_KEY_ID" \
         --issuer-id "YOUR_ISSUER_ID" \
         --private-key /path/to/AuthKey_XXXXXXXX.p8

  4. Verify authentication works:

       asc auth status --validate

ENVIRONMENT VARIABLES:

  ASC_APP_ID    Override the App Store Connect app ID.
                Defaults to Herald's known ID (6759459419).

WHAT THIS SCRIPT DOES:

  Step 1: Reads MARKETING_VERSION from the Xcode project
  Step 2: Lists recent builds and lets you pick one (or use --build-id)
  Step 3: Creates an App Store version (or reuses if it already exists)
  Step 4: Uploads "What's New" text parsed from CHANGELOG.md
  Step 5: Uploads screenshots from screenshots/ for all device sizes
  Step 6: Attaches the selected build to the version
  Step 7: Runs a preflight check for submission readiness
  Step 8: Submits for App Store review (with interactive confirmation)

Each step is idempotent — safe to re-run if interrupted.

PREREQUISITES BEFORE RUNNING:

  Before running this script, complete the source code preparations:
    - Increment MARKETING_VERSION in the Xcode project
    - Generate screenshots:  ./scripts/capture_screenshots.sh
    - Update CHANGELOG.md with the new version's changes
    - Commit all changes

HELP
  exit 0
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --build-id)
        if [[ $# -lt 2 ]]; then
          echo "Error: --build-id requires a value" >&2
          exit 1
        fi
        BUILD_ID="$2"
        shift 2
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --help|-h)
        usage
        ;;
      *)
        echo "Unknown option: $1" >&2
        echo "Run with --help for usage information." >&2
        exit 1
        ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Prerequisites
# ---------------------------------------------------------------------------

check_prerequisites() {
  echo "==> Checking prerequisites..."

  if ! command -v asc &>/dev/null; then
    echo -e "${RED}Error: 'asc' CLI not found.${RESET}" >&2
    echo "" >&2
    echo "Install it with:" >&2
    echo "  brew install asc" >&2
    echo "" >&2
    echo "See: https://github.com/rudrankriyam/App-Store-Connect-CLI" >&2
    exit 1
  fi

  if ! command -v jq &>/dev/null; then
    echo -e "${RED}Error: 'jq' not found.${RESET}" >&2
    echo "" >&2
    echo "Install it with:" >&2
    echo "  brew install jq" >&2
    exit 1
  fi

  echo "  Validating App Store Connect authentication..."
  if ! asc auth status --validate &>/dev/null; then
    echo -e "${RED}Error: asc authentication failed.${RESET}" >&2
    echo "" >&2
    echo "Set up authentication:" >&2
    echo "  1. Generate an API key at https://appstoreconnect.apple.com/access/integrations/api" >&2
    echo "  2. Run: asc auth login --name Herald --key-id KEY --issuer-id ISSUER --private-key /path/to/AuthKey.p8" >&2
    echo "  3. Verify: asc auth status --validate" >&2
    echo "" >&2
    echo "For diagnostics, run: asc auth doctor" >&2
    exit 1
  fi
  echo -e "  ${GREEN}Authentication valid.${RESET}"
}

# ---------------------------------------------------------------------------
# App ID
# ---------------------------------------------------------------------------

determine_app_id() {
  if [[ -n "${ASC_APP_ID:-}" ]]; then
    APP_ID="$ASC_APP_ID"
    echo "==> Using APP_ID from ASC_APP_ID env var: $APP_ID"
  else
    APP_ID="$HERALD_APP_STORE_ID"
    echo "==> Using Herald App Store ID: $APP_ID"
  fi
}

# ---------------------------------------------------------------------------
# Version detection
# ---------------------------------------------------------------------------

read_marketing_version() {
  echo "==> Reading MARKETING_VERSION from Xcode project..."

  if [[ ! -f "$PBXPROJ" ]]; then
    echo -e "${RED}Error: project.pbxproj not found at $PBXPROJ${RESET}" >&2
    exit 1
  fi

  VERSION=$(grep 'MARKETING_VERSION' "$PBXPROJ" | head -1 | sed 's/.*= *//; s/ *;.*//')

  if [[ -z "$VERSION" ]]; then
    echo -e "${RED}Error: Could not read MARKETING_VERSION from project.pbxproj${RESET}" >&2
    exit 1
  fi

  echo "  Version: $VERSION"
}

# ---------------------------------------------------------------------------
# Build selection
# ---------------------------------------------------------------------------

select_build() {
  echo "==> Selecting build..."

  if [[ -n "$BUILD_ID" ]]; then
    echo "  Using provided build ID: $BUILD_ID"
    return
  fi

  echo "  Fetching recent builds..."
  local builds_json
  run_asc builds_json "Failed to list builds for app $APP_ID." \
    asc builds list --app "$APP_ID" --limit 10 --output json

  local count
  count=$(echo "$builds_json" | jq '.data | length')

  if [[ "$count" -eq 0 ]]; then
    echo -e "${RED}Error: No builds found for app $APP_ID.${RESET}" >&2
    echo "" >&2
    echo "  Ensure a build has been uploaded via Xcode Cloud or Xcode." >&2
    echo "  You can also upload manually: asc builds upload --app $APP_ID --ipa /path/to/Herald.ipa" >&2
    exit 1
  fi

  echo ""
  echo "  Recent builds:"
  echo "  ──────────────────────────────────────────────────────────"

  # Display builds as a numbered list
  local i=1
  while IFS= read -r line; do
    local bid bversion bstate bdate
    bid=$(echo "$line" | jq -r '.id')
    bversion=$(echo "$line" | jq -r '.attributes.version // "?"')
    bstate=$(echo "$line" | jq -r '.attributes.processingState // "?"')
    bdate=$(echo "$line" | jq -r '.attributes.uploadedDate // "unknown"')
    printf "  %2d) %-14s  v%-6s  %-10s  %s\n" "$i" "$bid" "$bversion" "$bstate" "$bdate"
    i=$((i + 1))
  done < <(echo "$builds_json" | jq -c '.data[]')

  echo "  ──────────────────────────────────────────────────────────"
  echo ""

  if [ -t 0 ]; then
    read -r -p "  Select build number (1-$count) or enter a build ID [1]: " selection </dev/tty

    if [[ -z "$selection" ]]; then
      selection=1
    fi

    # Check if selection is a number (list index) or a build ID string
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le "$count" ]]; then
      BUILD_ID=$(echo "$builds_json" | jq -r ".data[$((selection - 1))].id")
    else
      BUILD_ID="$selection"
    fi
  else
    # Non-interactive: use the latest build
    BUILD_ID=$(echo "$builds_json" | jq -r '.data[0].id')
    echo "  Non-interactive mode: using latest build."
  fi

  echo -e "  ${GREEN}Selected build: $BUILD_ID${RESET}"
}

# ---------------------------------------------------------------------------
# Version creation (idempotent)
# ---------------------------------------------------------------------------

create_or_get_version() {
  echo "==> Creating or finding App Store version $VERSION..."

  # Check if version already exists
  local versions_json
  run_asc versions_json "Failed to list App Store versions." \
    asc versions list --app "$APP_ID" --output json

  # Look for a version matching our version string
  local existing_id existing_state
  existing_id=$(echo "$versions_json" | jq -r --arg v "$VERSION" \
    '.data[] | select(.attributes.versionString == $v) | .id' | head -1)

  if [[ -n "$existing_id" ]]; then
    VERSION_ID="$existing_id"
    existing_state=$(echo "$versions_json" | jq -r --arg v "$VERSION" \
      '.data[] | select(.attributes.versionString == $v) | .attributes.appStoreState' | head -1)
    echo -e "  ${GREEN}Version $VERSION already exists (ID: $VERSION_ID, state: $existing_state).${RESET}"
    return
  fi

  # Find previous version string for metadata copy
  local prev_version
  prev_version=$(echo "$versions_json" | jq -r '.data[0].attributes.versionString // empty')

  if $DRY_RUN; then
    echo "  [DRY RUN] Would create version $VERSION"
    [[ -n "$prev_version" ]] && echo "  [DRY RUN] Would copy metadata from $prev_version (excluding whatsNew)"
    VERSION_ID="DRY_RUN_VERSION_ID"
    return
  fi

  echo "  Creating version $VERSION..."
  local create_result
  if [[ -n "$prev_version" ]]; then
    echo "  Copying metadata from version $prev_version (excluding whatsNew)..."
    create_result=$(asc versions create \
      --app "$APP_ID" \
      --version "$VERSION" \
      --platform IOS \
      --copy-metadata-from "$prev_version" \
      --exclude-fields whatsNew \
      --output json)
  else
    create_result=$(asc versions create \
      --app "$APP_ID" \
      --version "$VERSION" \
      --platform IOS \
      --output json)
  fi

  VERSION_ID=$(echo "$create_result" | jq -r '.data.id // empty')

  if [[ -z "$VERSION_ID" ]]; then
    echo -e "${RED}Error: Failed to create version $VERSION.${RESET}" >&2
    echo "$create_result" >&2
    exit 1
  fi

  echo -e "  ${GREEN}Created version $VERSION (ID: $VERSION_ID).${RESET}"
}

# ---------------------------------------------------------------------------
# Localization ID
# ---------------------------------------------------------------------------

get_localization_id() {
  echo "==> Getting localization ID for en-US..."

  if $DRY_RUN; then
    LOCALIZATION_ID="DRY_RUN_LOC_ID"
    echo "  [DRY RUN] Skipping localization lookup."
    return
  fi

  local loc_json
  run_asc loc_json "Failed to list localizations for version $VERSION_ID." \
    asc localizations list --version "$VERSION_ID" --output json

  LOCALIZATION_ID=$(echo "$loc_json" | jq -r \
    '.data[] | select(.attributes.locale == "en-US") | .id' | head -1)

  if [[ -z "$LOCALIZATION_ID" ]]; then
    echo -e "${RED}Error: No en-US localization found for version $VERSION_ID.${RESET}" >&2
    echo "  This is unexpected — App Store Connect should create one automatically." >&2
    exit 1
  fi

  echo "  Localization ID: $LOCALIZATION_ID"
}

# ---------------------------------------------------------------------------
# What's New (from CHANGELOG.md)
# ---------------------------------------------------------------------------

parse_changelog() {
  # Extract content for the latest version from CHANGELOG.md.
  # Reads between the first "## Version X.Y" and the next "## Version" heading.
  # Converts ### headers to plain text, keeps bullet points.
  local in_section=false
  local content=""

  while IFS= read -r line; do
    if [[ "$line" =~ ^##[[:space:]]Version ]]; then
      if $in_section; then
        break
      fi
      in_section=true
      continue
    fi
    if $in_section; then
      # Skip leading blank lines before any real content
      if [[ -z "$content" && -z "$line" ]]; then
        continue
      fi
      if [[ "$line" =~ ^###[[:space:]] ]]; then
        local header="${line#\#\#\# }"
        # Add blank line before section headers (except at the start)
        if [[ -n "$content" ]]; then
          content+=$'\n'
        fi
        content+="$header"$'\n'
      else
        content+="$line"$'\n'
      fi
    fi
  done < "$CHANGELOG"

  # Output content; command substitution in the caller strips trailing newlines
  printf '%s' "$content"
}

upload_whats_new() {
  echo "==> Uploading What's New text..."

  if [[ ! -f "$CHANGELOG" ]]; then
    echo -e "${YELLOW}  Warning: CHANGELOG.md not found at $CHANGELOG. Skipping.${RESET}"
    return
  fi

  local whats_new
  whats_new=$(parse_changelog)

  if [[ -z "$whats_new" ]]; then
    echo -e "${YELLOW}  Warning: Could not parse a version entry from CHANGELOG.md. Skipping.${RESET}"
    return
  fi

  echo "  What's New text:"
  echo "$whats_new" | sed 's/^/    /'
  echo ""

  if $DRY_RUN; then
    echo "  [DRY RUN] Would upload What's New text for version $VERSION."
    return
  fi

  asc localizations update \
    --version "$VERSION_ID" \
    --locale "en-US" \
    --whats-new "$whats_new" \
    --output json >/dev/null

  echo -e "  ${GREEN}What's New text uploaded.${RESET}"
}

# ---------------------------------------------------------------------------
# Screenshots
# ---------------------------------------------------------------------------

upload_screenshots() {
  echo "==> Uploading screenshots..."

  if [[ ! -d "$SCREENSHOTS_DIR" ]]; then
    echo -e "${YELLOW}  Warning: screenshots/ directory not found. Skipping.${RESET}"
    echo "  Run ./scripts/capture_screenshots.sh first to generate screenshots."
    return
  fi

  for dir_name in "6.7-inch" "6.9-inch" "iPad-13-inch"; do
    local src_dir="$SCREENSHOTS_DIR/$dir_name"

    if [[ ! -d "$src_dir" ]]; then
      echo -e "${YELLOW}  Skipping $dir_name (directory not found).${RESET}"
      continue
    fi

    local png_count
    png_count=$(find "$src_dir" -maxdepth 1 -name '*.png' | wc -l | tr -d ' ')

    if [[ "$png_count" -eq 0 ]]; then
      echo -e "${YELLOW}  Skipping $dir_name (no PNG files found).${RESET}"
      continue
    fi

    local device_types
    device_types=$(screenshot_types_for "$dir_name")

    for device_type in $device_types; do
      echo "  Uploading $dir_name ($png_count screenshots) as $device_type..."

      if $DRY_RUN; then
        echo "  [DRY RUN] Would upload $png_count screenshots to $device_type."
        continue
      fi

      if ! asc screenshots upload \
        --version-localization "$LOCALIZATION_ID" \
        --path "$src_dir" \
        --device-type "$device_type" \
        --skip-existing \
        --output json >/dev/null 2>&1; then
        echo -e "${RED}  Error uploading $dir_name as $device_type.${RESET}" >&2
        echo "  The display type identifier may be incorrect." >&2
        echo "  Run 'asc screenshots sizes' to list valid device types and dimensions." >&2
        echo "  Then update the SCREENSHOT_TYPES mapping in this script." >&2
        exit 1
      fi

      echo -e "  ${GREEN}  Uploaded $dir_name as $device_type.${RESET}"
    done
  done

  echo -e "  ${GREEN}Screenshot upload complete.${RESET}"
}

# ---------------------------------------------------------------------------
# Attach build
# ---------------------------------------------------------------------------

attach_build() {
  echo "==> Attaching build $BUILD_ID to version $VERSION_ID..."

  if $DRY_RUN; then
    echo "  [DRY RUN] Would attach build $BUILD_ID to version $VERSION_ID."
    return
  fi

  asc versions attach-build \
    --version-id "$VERSION_ID" \
    --build "$BUILD_ID" \
    --output json >/dev/null

  echo -e "  ${GREEN}Build attached.${RESET}"
}

# ---------------------------------------------------------------------------
# Preflight check
# ---------------------------------------------------------------------------

preflight_check() {
  echo "==> Running submission preflight check..."

  if $DRY_RUN; then
    echo "  [DRY RUN] Would run preflight check."
    return
  fi

  if ! asc submit preflight \
    --app "$APP_ID" \
    --version "$VERSION" \
    --platform IOS \
    --output text 2>/dev/null; then
    echo -e "${YELLOW}  Warning: Preflight check reported issues.${RESET}"
    echo "  Review the output above. You may still proceed — some warnings are non-blocking."
    echo ""
  else
    echo -e "  ${GREEN}Preflight check passed.${RESET}"
  fi
}

# ---------------------------------------------------------------------------
# Submit for review
# ---------------------------------------------------------------------------

submit_for_review() {
  echo ""
  echo "  ============================================"
  echo -e "  ${BOLD}SUBMISSION SUMMARY${RESET}"
  echo "  ============================================"
  echo "  App:        Herald ($APP_ID)"
  echo "  Version:    $VERSION"
  echo "  Build:      $BUILD_ID"
  echo "  Version ID: $VERSION_ID"
  echo "  ============================================"
  echo ""

  if $DRY_RUN; then
    echo "  [DRY RUN] Would submit version $VERSION for review."
    return
  fi

  if [ -t 0 ]; then
    read -r -p "  Submit for App Store review? (y/N): " confirm </dev/tty
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo ""
      echo "  Submission skipped."
      echo "  You can submit later from App Store Connect or re-run this script."
      return
    fi
  else
    echo -e "${YELLOW}  Non-interactive mode: skipping submission (requires confirmation).${RESET}"
    echo "  Run interactively or submit manually from App Store Connect."
    return
  fi

  echo "==> Submitting version $VERSION for review..."

  if ! asc submit create \
    --app "$APP_ID" \
    --version-id "$VERSION_ID" \
    --build "$BUILD_ID" \
    --confirm \
    --output json >/dev/null 2>&1; then
    echo -e "${RED}Error: Submission failed.${RESET}" >&2
    echo "" >&2
    echo "  Check App Store Connect for missing requirements:" >&2
    echo "  - Encryption compliance declarations" >&2
    echo "  - Content rights declarations" >&2
    echo "  - App Privacy details" >&2
    echo "" >&2
    echo "  Run 'asc submit preflight --app $APP_ID --version $VERSION --platform IOS'" >&2
    echo "  for a detailed readiness report." >&2
    exit 1
  fi

  echo -e "  ${GREEN}Version $VERSION submitted for App Store review!${RESET}"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  parse_args "$@"

  if $DRY_RUN; then
    echo -e "${YELLOW}==> DRY RUN MODE — no changes will be made.${RESET}"
    echo ""
  fi

  check_prerequisites
  determine_app_id
  read_marketing_version
  select_build
  create_or_get_version
  get_localization_id
  upload_whats_new
  upload_screenshots
  attach_build
  preflight_check
  submit_for_review

  echo ""
  echo -e "${GREEN}==> Done!${RESET}"
}

main "$@"
