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
LAST_NDK_VERSIONS_ENTRY_INDEX=$(( ${#NDK_VERSIONS[@]} - 1 ))
NDK_VERSION="${NDK_VERSIONS[$LAST_NDK_VERSIONS_ENTRY_INDEX]}"
NDK_TOOLCHAINS=($NDK_VERSION/toolchains/llvm/prebuilt/*)

export ANDROID_NDK_HOME="${NDK_TOOLCHAINS[0]}"
echo "ANDROID_NDK_HOME found at $ANDROID_NDK_HOME"
else
echo "ANDROID_NDK_HOME is set to '$ANDROID_NDK_HOME'"; 
fi

cd src;
make android;
cd ../;

echo "build completed for Android"

git add android;
