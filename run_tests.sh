run_tests() {
  WATCH_HARDWARE="$1"
  echo "Running tests on $WATCH_HARDWARE..."

  # Create the paired hardware
  IPHONE_UUID=$(xcrun simctl create "🤖 iPhone 14 Pro" "iPhone 14 Pro" "iOS16.0")
  WATCH_UUID=$(xcrun simctl create "🤖 $WATCH_HARDWARE" "$WATCH_HARDWARE" "watchOS9.1")
  PAIRED_DEVICE=$(xcrun simctl pair "$IPHONE_UUID" "$WATCH_UUID")

  # Run the tests
  set -o pipefail && xcodebuild test -project ElectricSidecar/ElectricSidecar.xcodeproj -scheme "Watch" -destination "platform=WatchOS Simulator,id=$WATCH_UUID" | xcpretty
  set -o pipefail && xcodebuild test -project ElectricSidecar/ElectricSidecar.xcodeproj -scheme "WatchUICatalog" -destination "platform=WatchOS Simulator,id=$WATCH_UUID" TEST_ENVIRONMENT="$WATCH_HARDWARE" IS_RECORDING="false" | xcpretty

  xcrun simctl delete "$IPHONE_UUID"
  xcrun simctl delete "$WATCH_UUID"
}

run_tests "Apple Watch Series 8 (45mm)"
run_tests "Apple Watch Series 8 (41mm)"
run_tests "Apple Watch Series 4 (40mm)"


# Pin device settings
#xcrun simctl status_bar "$IPHONE_UUID" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
