#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g05-f08-tests >/dev/null
build/tests/rf27-g05/f08/system_error_test
file build/tests/rf27-g05/f08/system_error_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
test -z "$(nm -u build/tests/rf27-g05/f08/system_error_test)"
ninja rf27-g05-f06-error-tests >/dev/null
build/tests/rf27-g05-f06/error_native_test >/dev/null
rg -q 'NEBOC_ERROR_LAYOUT_SIZE 64' compiler/parser/option_result_parser.inc
rg -q 'mov qword \[rdi\+NEBO_ERROR_MESSAGE\],0' runtime/error/system_error.asm
rg -q 'mov qword \[rdi\+NEBO_ERROR_MESSAGE_LENGTH\],0' runtime/error/system_error.asm
ninja -f build.ninja -j2 rf204-g005-integration-tests >/dev/null
build/tests/rf204/G005/system_error_integration_test
printf '%s\n' 'RF27_G05_F08_GREEN native=13 Error=64 categories=filesystem+process+network+http raw_code=preserved source_id=preserved context=safe_hash_only retryable=typed cause=bounded secrets_paths_addresses=not_copied Result=structured file_network=2/2 static_elf=yes'
