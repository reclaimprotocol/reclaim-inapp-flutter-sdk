#!/usr/bin/env bash

set -ex;

export VERSION=$(grep '^version:' pubspec.yaml | sed -e 's/version: //')

DIST_ANDROID=./dist/android/$VERSION

mkdir -p debug/android/
flutter build aar --dart-define-from-file=./env.json --build-number=$VERSION; # --split-debug-info=debug/android/v$VERSION
rm -rf $DIST_ANDROID
mkdir -p $DIST_ANDROID
mv build/host/outputs/repo/ $DIST_ANDROID/repo
