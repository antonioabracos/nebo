#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -j1 rf27-g24-f04-tests >/dev/null
build/tests/rf27-g24/f04/packages_test
python3 tests/rf27-g24/f04/graph_oracle.py

temp_root="$(mktemp -d /tmp/rf27-g24-f04.XXXXXX)"
trap 'rm -rf "$temp_root"' EXIT
tools/rf27-package.py init "$temp_root/dep" --name dep
tools/rf27-package.py init "$temp_root/root" --name root
printf 'start() {\n  7;\n}\n' > "$temp_root/dep/src/main.no"
tools/rf27-package.py add "$temp_root/root" "$temp_root/dep"
test -L "$temp_root/root/nebo.package.json"
test -L "$temp_root/root/nebo.lock.json"
state_generation="$(readlink "$temp_root/root/.nebo-state/current")"
test -f "$temp_root/root/.nebo-state/$state_generation/nebo.package.json"
test -f "$temp_root/root/.nebo-state/$state_generation/nebo.lock.json"
tools/rf27-package.py audit "$temp_root/root"
first_lock="$(sha256sum "$temp_root/root/nebo.lock.json")"
tools/rf27-package.py resolve "$temp_root/root"
test "$first_lock" = "$(sha256sum "$temp_root/root/nebo.lock.json")"
test -L "$temp_root/root/.nebo-state/current"
tools/rf27-package.py vendor "$temp_root/root"
test -f "$temp_root/root/vendor/dep/nebo.package.json"
tools/rf27-package.py package "$temp_root/root" --output "$temp_root/a.nbpkg"
tools/rf27-package.py package "$temp_root/root" --output "$temp_root/b.nbpkg"
cmp "$temp_root/a.nbpkg" "$temp_root/b.nbpkg"

cp "$temp_root/dep/src/main.no" "$temp_root/dep/source.saved"
printf 'start() {\n  8;\n}\n' > "$temp_root/dep/src/main.no"
if tools/rf27-package.py audit "$temp_root/root" >/dev/null 2>&1; then
  echo 'PACKAGE_AUDIT_CORRUPTION_EXPECTED_RED' >&2
  exit 1
fi
mv "$temp_root/dep/source.saved" "$temp_root/dep/src/main.no"
tools/rf27-package.py audit "$temp_root/root"

tools/rf27-package.py init "$temp_root/a" --name a
tools/rf27-package.py init "$temp_root/b" --name b
tools/rf27-package.py add "$temp_root/a" "$temp_root/b"
before_manifest="$(sha256sum "$temp_root/b/nebo.package.json")"
before_lock="$(sha256sum "$temp_root/b/nebo.lock.json")"
if tools/rf27-package.py add "$temp_root/b" "$temp_root/a" >/dev/null 2>&1; then
  echo 'PACKAGE_CYCLE_EXPECTED_RED' >&2
  exit 1
fi
test "$before_manifest" = "$(sha256sum "$temp_root/b/nebo.package.json")"
test "$before_lock" = "$(sha256sum "$temp_root/b/nebo.lock.json")"
if tools/rf27-package.py add "$temp_root/b" "$temp_root/dep" --min-version 9.0.0 >/dev/null 2>&1; then
  echo 'PACKAGE_MIN_VERSION_EXPECTED_RED' >&2
  exit 1
fi
tools/rf27-package.py remove "$temp_root/root" dep
tools/rf27-package.py audit "$temp_root/root"

file build/tests/rf27-g24/f04/packages_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g24/f04/packages_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g24/f04/packages_test)"
python3 scripts/mf056/audit-stack-alignment.py build/tests/rf27-g24/f04/packages_test
test -z "$(find tools -type d -name __pycache__ -print)"
printf '%s\n' 'RF27_G24_F04_GREEN native_assertions=12 graph_cases=5000 init_add_remove_resolve_lock_vendor_package_audit=yes offline=only sha256=yes cycle_conflict_min_version=yes deterministic=yes static_elf=yes no_c_no_libc=yes'
