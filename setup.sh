#!/usr/bin/env bash

set -ex;

echo "Removing existing vendored library..";

rm -rf internal;
mkdir -p internal;

SDK_MODULE_VERSION=0.36.0
# SDK_MODULE_VERSION=main

cd internal;

echo "Downloading and vendoring SDK module version: $SDK_MODULE_VERSION";

echo "Downloading SDK"

git clone --depth=1 --branch=$SDK_MODULE_VERSION git@github.com:reclaimprotocol/reclaim-inapp-sdk.git sdk
rm -rf ./sdk/.git
# remove unnecessary files to avoid confusion
rm -rf ./sdk/example
rm -rf ./sdk/README.md

echo "Downloading TEE Operator"

git clone --depth=1 --branch=main git@github.com:reclaimprotocol/reclaim-tee-operator-flutter.git tee_operator
rm -rf ./tee_operator/.git
rm -rf ./tee_operator/example
rm -rf ./tee_operator/README.md
rm -rf ./tee_operator/src

echo "Downloading Add to App Module"

git clone --depth=1 --branch=main git@github.com:reclaimprotocol/reclaim-inapp-add-to-app-module.git reclaim_verifier_module
rm -rf ./reclaim_verifier_module/.git
rm -rf ./reclaim_verifier_module/env.json
rm -rf ./reclaim_verifier_module/Makefile
rm -rf ./reclaim_verifier_module/scripts

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
