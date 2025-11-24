#!/usr/bin/env bash

mkdir -p build/

curl "https://codeload.github.com/crasowas/app_privacy_manifest_fixer/tar.gz/refs/tags/v1.5.0" -o build/app_privacy_manifest_fixer.gz
mkdir -p build/app_privacy_manifest_fixer;
tar -xvzf build/app_privacy_manifest_fixer.gz -C build/app_privacy_manifest_fixer --strip-components=1;
