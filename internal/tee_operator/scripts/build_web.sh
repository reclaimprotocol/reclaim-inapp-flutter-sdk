#!/usr/bin/env bash

set -e;

echo "Starting build for Web"

cd src;
make wasm;
cd ../;

echo "Build completed for Web"

git add web
