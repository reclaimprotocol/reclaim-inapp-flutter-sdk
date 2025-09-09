#!/usr/bin/env bash

mkdir -p vendor;

if [[ -z "$OVERRIDE_GNARK_PROVER_GIT" ]]; then
  OVERRIDE_GNARK_PROVER_GIT="main"
fi
if [[ -z "$OVERRIDE_RECLAIM_FLUTTER_SDK_GIT" ]]; then
  OVERRIDE_RECLAIM_FLUTTER_SDK_GIT="main"
fi

echo "OVERRIDE_RECLAIM_FLUTTER_SDK_GIT=$OVERRIDE_RECLAIM_FLUTTER_SDK_GIT"
echo "OVERRIDE_GNARK_PROVER_GIT=$OVERRIDE_GNARK_PROVER_GIT"

echo "dependency_overrides:
  reclaim_gnark_zkoperator:
    git:
      url: https://$PACKAGE_CLONE_USER:$PACKAGE_CLONE_PASSWD@github.com/reclaimprotocol/reclaim-gnark-zkoperator-flutter.git
      ref: $OVERRIDE_GNARK_PROVER_GIT
  reclaim_inapp_sdk:
    git:
      url: https://$PACKAGE_CLONE_USER:$PACKAGE_CLONE_PASSWD@github.com/reclaimprotocol/reclaim-inapp-sdk.git
      ref: $OVERRIDE_RECLAIM_FLUTTER_SDK_GIT
" > pubspec_overrides.yaml

echo "APP_ID=$RECLAIM_CONSUMER_APP_ID
APP_SECRET=$RECLAIM_CONSUMER_APP_SECRET
" > .env
