#!/usr/bin/env bash

set -ex;

rm -rf internal;
mkdir -p internal;

cd internal;

git clone --depth=1 --branch=main git@github.com:reclaimprotocol/reclaim-inapp-sdk.git sdk
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

flutter pub get;
