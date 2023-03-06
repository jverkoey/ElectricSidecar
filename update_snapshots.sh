SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

run_watch_tests() {
  WATCH_HARDWARE="$1"
  echo "Running tests on $WATCH_HARDWARE..."

  # Create the paired hardware
  IPHONE_UUID=$(xcrun simctl create "iPhone 14 Pro" "iPhone 14 Pro" "iOS16.2")
  WATCH_UUID=$(xcrun simctl create "$WATCH_HARDWARE" "$WATCH_HARDWARE" "watchOS9.1")
  PAIRED_DEVICE=$(xcrun simctl pair "$IPHONE_UUID" "$WATCH_UUID")

  SCREENSHOTS_PATH="$SCRIPTPATH/screenshots/$WATCH_HARDWARE/"
  mkdir -p "$SCREENSHOTS_PATH"

  # Run the tests
  set -o pipefail && xcodebuild test \
    -project ElectricSidecar/ElectricSidecar.xcodeproj \
    -scheme "WatchUICatalog" \
    -destination "platform=WatchOS Simulator,id=$WATCH_UUID" \
    -resultBundlePath "TestResults/$WATCH_HARDWARE" \
    SNAPSHOT_PATH="$SCREENSHOTS_PATH" | xcpretty

  xcrun simctl delete "$IPHONE_UUID"
  xcrun simctl delete "$WATCH_UUID"
}

run_phone_tests() {
  PHONE_HARDWARE="$1"
  echo "Running tests on $PHONE_HARDWARE..."

  IPHONE_UUID=$(xcrun simctl create "$PHONE_HARDWARE" "$PHONE_HARDWARE" "iOS16.2")

  xcrun simctl boot "$IPHONE_UUID"
  xcrun simctl status_bar "$IPHONE_UUID" override \
    --time 9:41 \
    --dataNetwork wifi \
    --wifiMode active \
    --wifiBars 3 \
    --cellularMode active \
    --cellularBars 4 \
    --batteryState charged \
    --batteryLevel 100

  SCREENSHOTS_PATH="$SCRIPTPATH/screenshots/$PHONE_HARDWARE/"
  mkdir -p "$SCREENSHOTS_PATH"

  # Run the tests
  set -o pipefail && xcodebuild test \
    -project ElectricSidecar/ElectricSidecar.xcodeproj \
    -scheme "PhoneUICatalog" \
    -destination "platform=iOS Simulator,id=$IPHONE_UUID" \
    -resultBundlePath "TestResults/$PHONE_HARDWARE" \
    SNAPSHOT_PATH="$SCREENSHOTS_PATH" | xcpretty

  xcrun simctl delete "$IPHONE_UUID"
}
#
#run_watch_tests "Apple Watch Series 8 (45mm)"
#run_watch_tests "Apple Watch Series 8 (41mm)"
#run_watch_tests "Apple Watch Ultra (49mm)"

run_phone_tests "iPhone 14 Pro"
