#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}
cd "$root"
ninja mf043-console-document-tests >/dev/null
build/tests/mf043/console_document_test 2
echo NEBO_DOCUMENT_HEADLESS_002_GREEN
