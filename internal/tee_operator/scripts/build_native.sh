#!/usr/bin/env bash

set -e;

echo "Building native libraries";

./scripts/build_lib.sh

echo "Updating repository with new native libraries";

bash ./scripts/update_version.sh --minor;

get_timestamp() {
    date "+%Y%m%d%H%M"
}

export BUILD_BRANCH="build-$(get_timestamp)"
git checkout -b $BUILD_BRANCH;

git add pubspec.yaml lib/revision.dart;

BUILD_COMMIT_MESSAGE="Update [CI] native libraries for Android & iOS";

git commit -m "$BUILD_COMMIT_MESSAGE";
git push --set-upstream origin $BUILD_BRANCH;
git push;

curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $PACkAGE_CLONE_PASSWD" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/reclaimprotocol/reclaim-tee-operator-flutter/pulls \
  -d '{"title":"Update [CI] native libraries for Android & iOS","body":"Updated native libraries built by CI from latest changes in the [reclaim-tee](https://github.com/reclaimprotocol/reclaim-tee) repository","head":"'$BUILD_BRANCH'","base":"main"}'
