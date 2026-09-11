#!/usr/bin/env sh
set -eu

root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}
cd "$root"

./scripts/mf005/verify-reproducibility.sh
