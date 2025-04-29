#!/usr/bin/env bash

set -e;

./scripts/build_ios.sh
./scripts/build_android.sh

previous_dir=$(pwd)

cd $GO_GNARKPROVER_DIR

git_hash=$(git rev-parse HEAD)
echo "
const ZK_SYMMETRIC_CRYPTO_PROVER_SOURCE_REVISION = \"$git_hash\";
" > $previous_dir/lib/src/revision.dart

cd $previous_dir
