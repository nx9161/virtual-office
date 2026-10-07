#!/usr/bin/env bash
# Sloane Virtual Office — Direct Hardware Target Deployment Engine
# Detects a USB-connected device, builds the release package, pushes it,
# and auto-launches the app. Run from the project root.
set -euo pipefail

echo "=================================================="
echo "[+] Sloane Virtual Office Deployment Target Engine"
echo "=================================================="

# Step 1: Detect Connected Hardware Target
TARGET_OS="unknown"
DEVICE_ID=""

if command -v adb &> /dev/null && adb devices 2>/dev/null | grep -q "	device$"; then
    TARGET_OS="android"
    DEVICE_ID=$(adb devices 2>/dev/null | awk '$2=="device" {print $1; exit}')
    echo "[+] Hardware Detected: Android Device ID [$DEVICE_ID]"
elif command -v xcrun &> /dev/null && xcrun devicectl list devices 2>/dev/null | grep -q "Connected"; then
    TARGET_OS="ios"
    echo "[+] Hardware Detected: iOS Physical Device Connected."
else
    echo "[!] Warning: No physical USB target detected. Defaulting to local emulator."
    TARGET_OS="emulator"
fi

# Step 2: Trigger Cross-Platform Release Build
echo "[+] Compiling release package..."
if [ -f "pubspec.yaml" ]; then
    flutter build apk --release --target-platform android-arm64
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
elif [ -f "package.json" ]; then
    npx react-native run-android --mode=release
    APK_PATH=""
else
    echo "[!] No Flutter or React Native project detected in $(pwd). Aborting."
    exit 1
fi

# Step 3: Direct Push to Connected Target
if [ "$TARGET_OS" = "android" ]; then
    if [ -z "${APK_PATH:-}" ] || [ ! -f "$APK_PATH" ]; then
        echo "[!] Release APK not found at $APK_PATH. Aborting."
        exit 1
    fi
    echo "[+] Pushing application binary directly to hardware target [$DEVICE_ID]..."
    adb -s "$DEVICE_ID" install -r "$APK_PATH"

    # Auto-Launch application on device
    if [ -f "pubspec.yaml" ]; then
        APP_NAME=$(grep '^name:' pubspec.yaml | awk '{print $2}')
        APP_PACKAGE="com.office.${APP_NAME}"
        echo "[+] Launching $APP_PACKAGE on hardware..."
        adb -s "$DEVICE_ID" shell am start -n "$APP_PACKAGE/.MainActivity" \
            || echo "[!] Auto-launch failed — app is installed; launch it manually."
    fi
    echo "=================================================="
    echo "[✓] SUCCESS: App compiled, pushed, and running on device!"
    echo "=================================================="
elif [ "$TARGET_OS" = "ios" ]; then
    echo "[!] iOS detected: complete signing & deployment via Xcode (manual step)."
    exit 2
else
    echo "[!] Emulator mode: start an emulator and re-run, or connect a device."
    exit 3
fi
