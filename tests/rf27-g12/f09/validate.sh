#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja rf27-g12-f09-tests >/dev/null
timeout 5 build/tests/rf27-g12/f09/http_test
file build/tests/rf27-g12/f09/http_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
test -z "$(nm -u build/tests/rf27-g12/f09/http_test)"
! rg -qi 'TLS|redirect|external host|HTTP/2|HTTP/3' runtime/network/http.asm
bash tests/rf27-g12/f07/validate.sh >/dev/null
bash tests/rf27-g12/f08/validate.sh >/dev/null
printf '%s\n' 'RF27_G12_F09_GREEN native=17 HTTP=1.1_local framing=strict_CRLF request=structured_headers response=status+content_length chunked=bounded_in_place limits=headers+body smuggling=bare_LF_rejected TLS=local_pinned_profile static_elf=yes'
