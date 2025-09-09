#!/usr/bin/env bash

# script may have bumped version build number already before build+deploy.
file="pubspec.yaml"

# Exit if not on main branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
    git add $file
    git commit -m "[CI] Bump version"
    git push
    exit 0
fi

version_line=$(grep "^version:" $file)
current_version=$(echo $version_line | cut -d' ' -f2)

git add $file;
git commit -m "[CI] Bump version - $current_version";
git tag -a $current_version -m "$current_version";
git push --tags;

set -ex;

# do this when publishing to stores on prod. For next versions, use minor version bumps.
./scripts/update_version.sh --minor; 
git add $file;
git commit -m "[CI] Bump version (next version)";
git remote rm origin;
git remote add origin https://$PACKAGE_CLONE_USER:$PACKAGE_CLONE_PASSWD@github.com/reclaimprotocol/reclaim_inapp_sdk_wrapper.git;

get_timestamp() {
    date "+%Y%m%d%H%M"
}

export BUILD_BRANCH="bump-version-$(get_timestamp)"
git checkout -b $BUILD_BRANCH;

git push --set-upstream origin $BUILD_BRANCH;
git push;

curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $PACKAGE_CLONE_PASSWD" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/reclaimprotocol/reclaim_inapp_sdk_wrapper/pulls \
  -d '{"title":"[CI] Bump version (next version)","body":"[CI] Bump version (next version)","head":"'$BUILD_BRANCH'","base":"main"}'
