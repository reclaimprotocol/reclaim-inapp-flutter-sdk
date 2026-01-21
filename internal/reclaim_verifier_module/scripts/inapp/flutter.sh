#!/usr/bin/env bash

set -ex;

export VERSION=$(grep '^version:' pubspec.yaml | sed -e 's/version: //')

mkdir -p inapp-sdks;

cd inapp-sdks;

export WORK_DIR="$(pwd)";

export RN_CLONE_DIR="$WORK_DIR/build/flutter-sdk";

if [[ -z "$PACKAGE_CLONE_USER" ]]; then
    git clone git@github.com:reclaimprotocol/reclaim-inapp-flutter-sdk.git $RN_CLONE_DIR;
else
    git clone https://$PACKAGE_CLONE_USER:$PACKAGE_CLONE_PASSWD@github.com/reclaimprotocol/reclaim-inapp-flutter-sdk.git $RN_CLONE_DIR;
fi

cd $RN_CLONE_DIR;

DEFAULT_CHANGELOG="## $VERSION

* Updates inapp module dependency to $VERSION
"

EFFECTIVE_CHANGELOG="${NEXT_CHANGELOG:-$DEFAULT_CHANGELOG}"

# copy current changelog.md
cat CHANGELOG.md > temp;
# enter new changes
echo "$EFFECTIVE_CHANGELOG" > CHANGELOG.md
# append old changelog
cat temp >> CHANGELOG.md;
# remove copy
rm temp;

# sed -i '' "s/ReclaimInAppSdk\", \"~> .*\"/ReclaimInAppSdk\", \"~> $VERSION\"/" ./InappRnSdk.podspec;
# sed -i '' "s/implementation \"org.reclaimprotocol:inapp_sdk:.*\"/implementation \"org.reclaimprotocol:inapp_sdk:$VERSION\"/" ./android/build.gradle;
# sed -i '' "s/ReclaimInAppSdk', '~> .*'/ReclaimInAppSdk', '~> $VERSION'/" ./documentation/install-no-framework.md;
# sed -i '' "s/pod 'ReclaimInAppSdk', :git => 'https:\/\/github.com\/reclaimprotocol\/reclaim-inapp-ios-sdk.git', :tag => '.*'/pod 'ReclaimInAppSdk', :git => 'https:\/\/github.com\/reclaimprotocol\/reclaim-inapp-ios-sdk.git', :tag => '$VERSION'/" ./documentation/install-no-framework.md;
# sed -i '' "s/Latest version on \[cocoapods.org is .*\]/Latest version on \[cocoapods.org is $VERSION\]/" ./documentation/migration.md;
# sed -i '' "s/\"version\": \".*\",/\"version\": \"$VERSION\",/" ./package.json;
# sed -i '' "s/\"@reclaimprotocol\/inapp-rn-sdk\": \"\^.*\"/\"@reclaimprotocol\/inapp-rn-sdk\": \"\^$VERSION\"/" ./samples/example_expo/package.json;
# sed -i '' "s/\"@reclaimprotocol\/inapp-rn-sdk\": \"\^.*\"/\"@reclaimprotocol\/inapp-rn-sdk\": \"\^$VERSION\"/" ./samples/example_new_arch/package.json;
