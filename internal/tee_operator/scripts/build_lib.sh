#!/usr/bin/env bash

set -e;

./scripts/lint.sh

if [ -z "$GO_RECLAIM_DIR" ]
then
    # Default to local monorepo path if available
    if [ -d "$(pwd)/../reclaim-tee" ]; then
        export GO_RECLAIM_DIR="$(pwd)/../reclaim-tee";
        echo "Using local GO_RECLAIM_DIR: $GO_RECLAIM_DIR";
    else
        GO_RECLAIM_REPO_URL="https://github.com/reclaimprotocol/reclaim-tee.git";
        mkdir -p vendor;
        if [ -d "vendor/reclaim-tee" ]; then
            echo "vendor/reclaim-tee already exists, pulling latest changes";
            cd vendor/reclaim-tee;
            git pull origin main;
            cd ../..;
        else
            echo "Cloning reclaim-tee repository";
            git clone $GO_RECLAIM_REPO_URL vendor/reclaim-tee;
        fi
        export GO_RECLAIM_DIR="$(pwd)/vendor/reclaim-tee";
    fi
fi

echo "Generating native assets for iOS & Android from source $GO_RECLAIM_DIR"

rm -rf ./assets;
mkdir -p ./assets/android;

./scripts/build_ios.sh
./scripts/build_android.sh

cd src;
make gen_bindings;
cd ../;

sdk_dir=$(pwd)

library_source_git_hash=$(cd $GO_RECLAIM_DIR; git rev-parse HEAD;)
echo "const RECLAIM_TEE_SOURCE_REVISION = \"$library_source_git_hash\";" > $sdk_dir/lib/revision.dart

cd $sdk_dir
