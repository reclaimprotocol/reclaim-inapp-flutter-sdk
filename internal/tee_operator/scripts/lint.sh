#!/usr/bin/env bash

set -e;

flutter config --enable-swift-package-manager
cd ios;
pod lib lint reclaim_tee_operator_flutter.podspec  --configuration=Debug --skip-tests --use-modular-headers --use-libraries --allow-warnings
pod lib lint reclaim_tee_operator_flutter.podspec  --configuration=Debug --skip-tests --use-modular-headers --allow-warnings
cd ../;
dart analyze;
dart format . --set-exit-if-changed;

# Validate the SwiftPM manifest parses/evaluates correctly (does not resolve
# dependencies, so it works without the Flutter-generated FlutterFramework).
swift package --package-path ios/reclaim_tee_operator_flutter dump-package > /dev/null

# Lint Swift sources (formatting check). --strict turns findings into errors so
# the gate fails, mirroring `dart format --set-exit-if-changed` above.
# To auto-fix locally, run:
#   swift format format --in-place --recursive ios/reclaim_tee_operator_flutter/Sources
swift format lint --strict --recursive ios/reclaim_tee_operator_flutter/Sources
