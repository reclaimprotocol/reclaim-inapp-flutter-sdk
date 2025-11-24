#!/usr/bin/env bash

set -ex;

echo "Removing existing vendored library..";

rm -rf internal;
mkdir -p internal;

# SDK_MODULE_VERSION=main
SDK_MODULE_VERSION=0.24.0

cd internal;

echo "Downloading and vendoring SDK module version: $SDK_MODULE_VERSION";

echo "Downloading SDK"

git clone --depth=1 --branch=$SDK_MODULE_VERSION git@github.com:reclaimprotocol/reclaim-inapp-sdk.git sdk
rm -rf ./sdk/.git
# remove unnecessary files to avoid confusion
rm -rf ./sdk/example
rm -rf ./sdk/README.md

echo "Downloading ZK Operator package"

git clone --depth=1 --branch=main git@github.com:reclaimprotocol/reclaim-gnark-zkoperator-flutter.git zkoperator
rm -rf ./zkoperator/.git

echo "Downloading Add to App Module"

git clone --depth=1 --branch=$SDK_MODULE_VERSION git@github.com:reclaimprotocol/reclaim_inapp_sdk_wrapper.git reclaim_verifier_module
rm -rf ./reclaim_verifier_module/.git
rm -rf ./reclaim_verifier_module/env.json
rm -rf ./reclaim_verifier_module/Makefile

cd ..;

file="internal/sdk/pubspec.yaml"
version_line=$(grep "^version:" $file)
current_version=$(echo $version_line | cut -d' ' -f2)

# Use different sed syntax for macOS (BSD) and Linux (GNU)
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/^version:.*/version: $current_version/" pubspec.yaml
else
    sed -i "s/^version:.*/version: $current_version/" pubspec.yaml
fi

echo "Updated version from sdk dependency: $current_version"

flutter pub get;
