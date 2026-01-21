#!/usr/bin/env bash

set -e;

echo "Starting build for iOS"

cd src;
make ios;
cd ../;

echo "Build completed for iOS"

git add ios
