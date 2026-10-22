#!/usr/bin/env bash
# Builds the demo app and launches it in the iOS Simulator.
#
#   ./scripts/run.sh                    # uses a booted iPhone simulator, or the newest iPhone Pro
#   ./scripts/run.sh "iPhone 16 Pro"    # or a simulator by name
set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="Demo/StreakDemo.xcodeproj"
SCHEME="StreakDemo"
BUNDLE_ID="com.nodedesign.StreakDemo"
DERIVED_DATA=".build/DerivedData"
APP="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/StreakDemo.app"

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "✗ xcodebuild needs the full Xcode app, not just the Command Line Tools."
  echo "  Install Xcode from the App Store, then run:"
  echo "  sudo xcode-select -s /Applications/Xcode.app"
  exit 1
fi

UDID_PATTERN='[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}'

pick_simulator() {
  local devices line=""
  devices=$(xcrun simctl list devices available)
  if [[ -n "${1:-}" ]]; then
    line=$(echo "$devices" | grep -m1 -F "    $1 (" || true)
  else
    # A booted iPhone first, then the newest "iPhone NN Pro", then any iPhone.
    line=$(echo "$devices" | grep -m1 -E '^ +iPhone.*\(Booted\)' || true)
    [[ -z "$line" ]] && line=$(echo "$devices" | grep -E '^ +iPhone [0-9]+ Pro \(' | tail -1 || true)
    [[ -z "$line" ]] && line=$(echo "$devices" | grep -E '^ +iPhone' | tail -1 || true)
  fi
  echo "$line" | grep -oE "$UDID_PATTERN" || true
}

UDID=$(pick_simulator "${1:-}")
if [[ -z "$UDID" ]]; then
  echo "✗ No matching iPhone simulator found. Available ones:"
  xcrun simctl list devices available | grep -E '^ +iPhone' || echo "  (none: add one in Xcode ▸ Settings ▸ Components)"
  exit 1
fi
NAME=$(xcrun simctl list devices | grep -m1 "$UDID" | sed -E 's/^ +//; s/ \(.*//')

echo "▶ Booting $NAME"
xcrun simctl boot "$UDID" 2>/dev/null || true # fine if it's already running
open -a Simulator --args -CurrentDeviceUDID "$UDID"

echo "▶ Building $SCHEME (errors and warnings only)"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "id=$UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  -quiet \
  build

echo "▶ Installing and launching"
xcrun simctl install "$UDID" "$APP"
xcrun simctl launch "$UDID" "$BUNDLE_ID" >/dev/null
echo "✓ Running on $NAME"
