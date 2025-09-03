#!/usr/bin/env bash

set -ex;

export VERSION=$(grep '^version:' pubspec.yaml | sed -e 's/version: //')

mkdir -p inapp-sdks;

cd inapp-sdks;

export WORK_DIR="$(pwd)";

export IOS_CLONE_DIR="$WORK_DIR/build/ios-sdk";

if [[ -z "$PACKAGE_CLONE_USER" ]]; then
    git clone git@github.com:reclaimprotocol/reclaim-inapp-ios-sdk.git $IOS_CLONE_DIR;
else
    git clone https://$PACKAGE_CLONE_USER:$PACkAGE_CLONE_PASSWD@github.com/reclaimprotocol/reclaim-inapp-ios-sdk.git $IOS_CLONE_DIR;
fi

cd $IOS_CLONE_DIR;

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

echo $VERSION > Sources/ReclaimInAppSdk/Resources/InAppSdk.version;

sed -i '' "s/RECLAIM_SDK_VERSION=\".*\"/RECLAIM_SDK_VERSION=\"$VERSION\"/" ./Scripts/download_frameworks.sh;
sed -i '' "s/s.version           = '.*'/s.version           = '$VERSION'/" ./Devel/podspec.prod;
sed -i '' "s/s.version           = '.*'/s.version           = '$VERSION'/" ./ReclaimInAppSdk.podspec;
sed -i '' "s/pod 'ReclaimInAppSdk', :git => 'https:\/\/github.com\/reclaimprotocol\/reclaim-inapp-ios-sdk.git', :tag => '.*'/pod 'ReclaimInAppSdk', :git => 'https:\/\/github.com\/reclaimprotocol\/reclaim-inapp-ios-sdk.git', :tag => '$VERSION'/" ./README.md;
sed -i '' "s/.package(url: \"https:\/\/github.com\/reclaimprotocol\/reclaim-inapp-ios-sdk.git\", from: \".*\")/.package(url: \"https:\/\/github.com\/reclaimprotocol\/reclaim-inapp-ios-sdk.git\", from: \"$VERSION\")/" ./README.md;
sed -i '' "s/Currently the latest version is \`.*\`/Currently the latest version is \`$VERSION\`/" ./README.md;
sed -i '' "s/pod 'ReclaimInAppSdk', :git => 'https:\/\/github.com\/reclaimprotocol\/reclaim-inapp-ios-sdk.git', :tag => '.*'/pod 'ReclaimInAppSdk', :git => 'https:\/\/github.com\/reclaimprotocol\/reclaim-inapp-ios-sdk.git', :tag => '$VERSION'/" ./Examples/SwiftUIWithPodExample/Podfile;
sed -i '' "s/pod 'ReclaimInAppSdk', '~> .*'/pod 'ReclaimInAppSdk', '~> $VERSION'/" ./Examples/SwiftUIWithPodExample/Podfile;

echo "
RECLAIM_APP_ID = ${RECLAIM_CONSUMER_APP_ID}
RECLAIM_APP_SECRET = ${RECLAIM_CONSUMER_APP_SECRET}
RECLAIM_PROVIDER_ID = example

" > Examples/SwiftUIWithPodExample/BaseConfig.xcconfig;

cp Examples/SwiftUIWithPodExample/BaseConfig.xcconfig Examples/SwiftUIExample/BaseConfig.xcconfig;

./Scripts/prepare.sh

echo "Upload $IOS_CLONE_DIR/Build/$VERSION to S3 bucket, make sure $VERSION/ directory exists, and $VERSION/ should have the files and not $VERSION/"

cat Devel/Package.swift.prod > Package.swift
cat Devel/podspec.prod > ReclaimInAppSdk.podspec

# COMMIT, TAG, PUSH

echo "Test, then 'git tag -a $VERSION -m $VERSION; git push; git push --tags', and then finally run the following to deploy to Cocoapods (will be available for use in ~1 hour):"
echo "pod trunk push ReclaimInAppSdk.podspec --allow-warnings"

cd $WORK_DIR;