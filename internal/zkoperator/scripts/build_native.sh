#!/usr/bin/env bash

set -e;

if [ -z "$GO_GNARKPROVER_DIR" ]
then
    GO_GNARKPROVER_REPO_URL="https://github.com/reclaimprotocol/zk-symmetric-crypto";
    mkdir -p vendor;
    git clone $GO_GNARKPROVER_REPO_URL vendor/zk-symmetric-crypto;
    export GO_GNARKPROVER_DIR="$(pwd)/vendor/zk-symmetric-crypto/gnark";
fi

./scripts/build_lib.sh

# cleanup
rm -rf $GO_GNARKPROVER_DIR;

echo "Updating repository with new native libraries";

bash ./scripts/update_version.sh --minor;

get_timestamp() {
    date "+%Y%m%d%H%M"
}

export BUILD_BRANCH="build-$(get_timestamp)"
git checkout -b $BUILD_BRANCH;

git add pubspec.yaml;

BUILD_COMMIT_MESSAGE="Update [CI] native libraries for Android & iOS";

git commit -m "$BUILD_COMMIT_MESSAGE";
git push --set-upstream origin $BUILD_BRANCH;
git push;

curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $PACkAGE_CLONE_PASSWD" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/reclaimprotocol/reclaim-gnark-zkoperator-flutter/pulls \
  -d '{"title":"Update [CI] native libraries for Android & iOS","body":"Updated native libraries built by CI from latest changes in the [zk-symmetric-crypto/gnark](https://github.com/reclaimprotocol/zk-symmetric-crypto/tree/main/gnark) repository","head":"'$BUILD_BRANCH'","base":"main"}'
