#!/usr/bin/env bash

set -e;

echo "Starting build for Android"

if [ ! -d ${ANDROID_NDK_HOME} ] || [[ $ANDROID_NDK_HOME != *"toolchains/llvm/prebuilt"* ]]; 
then 
echo "Finding Android NDK"; 

if [ -z ${ANDROID_HOME+x} ]; 
then
    echo "Finding Android SDK"
    # Only works with darwin
    export ANDROID_HOME="$HOME/Library/Android/sdk"
    echo "ANDROID_HOME is $ANDROID_HOME";
else
    echo "ANDROID_HOME is $ANDROID_HOME";
fi

NDK_VERSIONS=($ANDROID_HOME/ndk/*)
# Find the first valid NDK (with complete toolchain) by iterating in reverse
for (( i=${#NDK_VERSIONS[@]}-1 ; i>=0 ; i-- )) ; do
    NDK_VERSION="${NDK_VERSIONS[$i]}"
    NDK_TOOLCHAINS=($NDK_VERSION/toolchains/llvm/prebuilt/*)

    # Check if toolchain directory exists and has content (not just wildcards)
    if [ -d "${NDK_TOOLCHAINS[0]}" ] && [ "${NDK_TOOLCHAINS[0]}" != "$NDK_VERSION/toolchains/llvm/prebuilt/*" ]; then
        export ANDROID_NDK_HOME="${NDK_TOOLCHAINS[0]}"
        echo "ANDROID_NDK_HOME found at $ANDROID_NDK_HOME"
        break
    else
        echo "Skipping incomplete NDK: $NDK_VERSION"
    fi
done

if [ -z "$ANDROID_NDK_HOME" ]; then
    echo "Error: No valid NDK found"
    exit 1
fi
else
echo "ANDROID_NDK_HOME is set to '$ANDROID_NDK_HOME'"; 
fi

cd src;
make android;
cd ../;

echo "build completed for Android"

git add android;
