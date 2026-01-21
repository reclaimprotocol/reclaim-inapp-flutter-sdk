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

    APPLE_DEVELOPMENT_SIGNING_IDENTITY_ORGANIZATION="Creatoros Inc"

    APPLE_DEVELOPER_SIGNING_CERTIFICATE_ID="$(security find-certificate -a | grep "$APPLE_DEVELOPMENT_SIGNING_IDENTITY_ORGANIZATION" | grep -o '([A-Z0-9]\{10\})' | tr -d '()')"
    if [ -z "$APPLE_DEVELOPER_SIGNING_CERTIFICATE_ID" ]; then
        echo "Error: No Apple Development signing identity found in the keychain with organization $APPLE_DEVELOPMENT_SIGNING_IDENTITY_ORGANIZATION. To check available, try running: security find-certificate -v -p codesigning | grep \"$APPLE_DEVELOPMENT_SIGNING_IDENTITY_ORGANIZATION\""
        exit 1
    fi

    APPLE_DEVELOPMENT_SIGNING_IDENTITY="$(security find-identity -v -p codesigning | grep "$APPLE_DEVELOPER_SIGNING_CERTIFICATE_ID" | head -n 1 | awk '{print $2}')"
    if [ -z "$APPLE_DEVELOPMENT_SIGNING_IDENTITY" ]; then
        echo "Error: No Apple Development signing identity found in the keychain. To check available, try running: security find-identity -v -p codesigning | grep \"Apple Development:\""
        exit 1
    fi

    echo "Using apple development signing identity: $APPLE_DEVELOPMENT_SIGNING_IDENTITY"

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

# Example usage:
# create_xcframework objective_c
create_xcframework() {
    local somepackage="$1"

    if [ -z "$somepackage" ]; then
        echo "Usage: create_xcframework <package_name>"
        return 1
    fi

    mkdir -p iphoneos
    mkdir -p iphonesimulator

    rm -rf "$somepackage.framework/_CodeSignature"
    cp -R "$somepackage.framework/" "iphoneos/$somepackage.framework"
    cp -R "$somepackage.framework/" "iphonesimulator/$somepackage.framework"

    echo "Original framework architectures:"
    xcrun lipo -info "$somepackage.framework/$somepackage"

    # Create iphoneos version (remove x86_64, keep arm64)
    xcrun lipo -remove x86_64 "./iphoneos/$somepackage.framework/$somepackage" -o "./iphoneos/$somepackage.framework/$somepackage"
    vtool -set-build-version 2 14 26.1 -output "./iphoneos/$somepackage.framework/$somepackage" "./iphoneos/$somepackage.framework/$somepackage"
    vtool -remove-build-version 7 -output "./iphoneos/$somepackage.framework/$somepackage" "./iphoneos/$somepackage.framework/$somepackage"

    echo "iphoneos framework architectures:"
    xcrun lipo -info "iphoneos/$somepackage.framework/$somepackage"

    # Create XCFramework
    xcodebuild -create-xcframework \
        -framework "iphoneos/$somepackage.framework/" \
        -framework "iphonesimulator/$somepackage.framework/" \
        -output "$somepackage.xcframework"

    rm -rf ./iphonesimulator;
    rm -rf ./iphoneos;
}

dart run scripts/prepare_ios.dart

ONLY_RELEASE_TARGETS=true

FRAMEWORK_PATTERN=""
if [ "$ONLY_RELEASE_TARGETS" != "true" ]; then
    FRAMEWORK_PATTERN="build/ios/ReclaimXCFrameworks/**/*.framework"
else
    FRAMEWORK_PATTERN="build/ios/ReclaimXCFrameworks/*.framework"
fi

echo "Converting any binary frameworks to xcframework"

project_dir="$(pwd)"

for framework_path in $FRAMEWORK_PATTERN; do
    echo "Trying to make XCframework for $framework_path"
    if [ -d "$framework_path" ]; then
        echo "Temporarily disabled .xcframework development. Try uploading app to Testflight when this is needed again"
        exit 1;
        framework_name=$(basename $framework_path .framework)

        echo "📦 Creating xcframework for $framework_name"

        cd "$(dirname $framework_path)"
        create_xcframework $framework_name 
        cd $project_dir;

        rm -rf $framework_path
    fi
done


sign_frameworks_in_directory "build/ios/ReclaimXCFrameworks"

(cd build/ios && tar -zcvf ReclaimXCFrameworks.tar.gz ReclaimXCFrameworks) # FAST
rm -rf $DIST_IOS
mkdir -p $DIST_IOS
mv build/ios/ReclaimXCFrameworks.tar.gz $DIST_IOS

echo "Build ready in $DIST_IOS"
