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

# Simulators to try, best first: the one you named; otherwise one that's already booted, then the
# "iPhone NN Pro" models newest first, then any other iPhone.
candidates() {
  local devices
  devices=$(xcrun simctl list devices available)
  if [[ -n "${1:-}" ]]; then
    echo "$devices" | grep -F "    $1 (" || true
  else
    echo "$devices" | grep -E '^ +iPhone.*\(Booted\)' || true
    echo "$devices" | grep -E '^ +iPhone [0-9]+ Pro \(' | awk '{ l[NR] = $0 } END { for (i = NR; i > 0; i--) print l[i] }' || true
    echo "$devices" | grep -E '^ +iPhone' | awk '{ l[NR] = $0 } END { for (i = NR; i > 0; i--) print l[i] }' || true
  fi
}

# Reads the whole list (no early exit), so `simctl` never gets cut off mid-write under `pipefail`.
device_name() {
  xcrun simctl list devices | awk -v id="$1" '!found && index($0, id) { sub(/^ +/, ""); sub(/ \(.*/, ""); print; found = 1 }'
}

UDIDS=$(candidates "${1:-}" | grep -oE "$UDID_PATTERN" | awk '!seen[$0]++' || true)
if [[ -z "$UDIDS" ]]; then
  echo "✗ No matching iPhone simulator found. Available ones:"
  xcrun simctl list devices available | grep -E '^ +iPhone' || echo "  (none: add one in Xcode ▸ Settings ▸ Components)"
  exit 1
fi

# Boot the first one that will. `bootstatus -b` boots it if needed and waits until it's ready, and fails
# loudly if it can't, which is what happens when its iOS runtime isn't fully installed yet.
UDID=""
BOOT_LOG=$(mktemp)
trap 'rm -f "$BOOT_LOG"' EXIT
for candidate in $UDIDS; do
  candidate_name=$(device_name "$candidate")
  echo "▶ Booting $candidate_name"
  if xcrun simctl bootstatus "$candidate" -b >/dev/null 2>"$BOOT_LOG"; then
    UDID=$candidate
    NAME=$candidate_name
    break
  fi
  echo "  ✗ It wouldn't boot: $(grep -v '^ *$' "$BOOT_LOG" | tail -1 || true)"
done

if [[ -z "$UDID" ]]; then
  echo
  echo "✗ No iPhone simulator would boot. On a new Mac this usually means the iOS simulator runtime"
  echo "  isn't fully installed yet. To fix it:"
  echo "    1. Open Xcode once and let it finish installing its components (or run: xcodebuild -runFirstLaunch)."
  echo "    2. Install the iOS simulator in Xcode ▸ Settings ▸ Components (or run: xcodebuild -downloadPlatform iOS)."
  echo "    3. Run this script again."
  echo "  The simulator runtimes Xcode can see right now:"
  xcrun simctl list runtimes | sed 's/^/    /'
  exit 1
fi
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
