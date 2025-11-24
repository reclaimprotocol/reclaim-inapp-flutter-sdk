#!/usr/bin/env bash

set -ex;

export VERSION=$(grep '^version:' pubspec.yaml | sed -e 's/version: //')

DIST_IOS=./dist/ios/$VERSION

(cd .ios && pod deintegrate && rm -rf Podfile.lock && rm -rf ./Pods/);
sed -i '' "s/platform :ios, '.*'/platform :ios, '14.0'/" ./.ios/Podfile;

(cd .ios && pod install)
mkdir -p build/ios
mkdir -p debug/ios/
flutter build ios-framework --output=build/ios --release --no-profile --debug; # --split-debug-info=debug/ios/v$VERSION

# Function to clean and sign frameworks (same as in sign_ios_frameworks.sh)
sign_frameworks_in_directory() {
    local frameworks_dir="$1"

    if [ ! -d "$frameworks_dir" ]; then
        echo "❌ Error: Directory not found at $frameworks_dir"
        return 1
    fi

    echo "📂 Processing frameworks in: $frameworks_dir"

    # Step 3: Sign all frameworks properly
    echo "✍️  Signing frameworks..."

    FRAMEWORK_PATTERN="$frameworks_dir/*.xcframework"

    APPLE_DEVELOPMENT_SIGNING_IDENTITY="$(security find-identity -v -p codesigning | grep "Apple Development:" | head -n 1 | awk '{print $2}')"
    if [ -z "$APPLE_DEVELOPMENT_SIGNING_IDENTITY" ]; then
        echo "Error: No Apple Development signing identity found in the keychain. To check available, try running: security find-identity -v -p codesigning | grep \"Apple Development:\""
        exit 1
    fi

    for framework_path in $FRAMEWORK_PATTERN; do
        echo "📦 Processing: $framework_path";
        local framework_name="$(basename "$framework_path")"
        codesign --timestamp -v -f --sign "$APPLE_DEVELOPMENT_SIGNING_IDENTITY" "$framework_path";
        echo $(codesign -dv "$framework_path");
        echo $(codesign -vv "$framework_path");
        echo "  ✓ Signed: $framework_name";
    done

    return 0
}

dart run scripts/prepare_ios.dart

sign_frameworks_in_directory "build/ios/ReclaimXCFrameworks"

(cd build/ios && tar -zcvf ReclaimXCFrameworks.tar.gz ReclaimXCFrameworks) # FAST
rm -rf $DIST_IOS
mkdir -p $DIST_IOS
mv build/ios/ReclaimXCFrameworks.tar.gz $DIST_IOS
