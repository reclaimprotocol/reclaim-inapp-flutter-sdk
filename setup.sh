#!/usr/bin/env bash

set -ex;

rm -rf internal;
mkdir -p internal;

# SDK_MODULE_VERSION=main
SDK_MODULE_VERSION=0.8.3

cd internal;

git clone --depth=1 --branch=$SDK_MODULE_VERSION git@github.com:reclaimprotocol/reclaim-inapp-sdk.git sdk
rm -rf ./sdk/.git
# remove unnecessary files to avoid confusion
rm -rf ./sdk/example
rm -rf ./sdk/README.md

git clone --depth=1 --branch=main git@github.com:reclaimprotocol/reclaim-gnark-zkoperator-flutter.git zkoperator
rm -rf ./zkoperator/.git

cd ..;

echo "
interface class BuildEnv {
  static const bool IS_VERIFIER_INAPP_MODULE = true;
}
" > internal/sdk/lib/build_env.dart

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
