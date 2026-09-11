#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
NEBOC="${NEBOC:-build/bin/neboc}"
tmp="$(mktemp -d /tmp/nebo-post-rc1-g12-XXXXXX)"
trap 'rm -rf -- "$tmp"' EXIT

fail() {
  local step="${1:-unknown}" detail="${2:-unspecified}"
  echo "POST_RC1_G12_ERROR step=$step detail=$detail" >&2
  exit 1
}

static_elf() {
  local artifact="$1"
  file "$artifact" | grep -Fq 'ELF 64-bit LSB executable, x86-64' || return 1
  file "$artifact" | grep -Fq 'statically linked' || return 1
  ! readelf -lW "$artifact" | grep -q INTERP || return 1
  ! readelf -dW "$artifact" | grep -q NEEDED || return 1
  [[ -z "$(nm -u "$artifact")" ]] || return 1
  readelf -lW "$artifact" | grep GNU_STACK | grep -Fq ' RW '
}

positive_count=0
while IFS=$'\t' read -r proof source _ scenario expected_exit; do
  [[ "$proof" == proof_id ]] && continue
  "$NEBOC" check "$source" >"$tmp/$proof.check.out" 2>"$tmp/$proof.check.err" || fail positive "$proof:check"
  "$NEBOC" emit-asm "$source" -o "$tmp/$proof.a.asm" >"$tmp/$proof.emit-a.out" 2>"$tmp/$proof.emit-a.err" || fail positive "$proof:emit-a"
  "$NEBOC" emit-asm "$source" -o "$tmp/$proof.b.asm" >"$tmp/$proof.emit-b.out" 2>"$tmp/$proof.emit-b.err" || fail positive "$proof:emit-b"
  cmp -s "$tmp/$proof.a.asm" "$tmp/$proof.b.asm" || fail determinism "$proof"
  "$NEBOC" build "$source" -o "$tmp/$proof.elf" >"$tmp/$proof.build.out" 2>"$tmp/$proof.build.err" || fail positive "$proof:build"
  static_elf "$tmp/$proof.elf" || fail elf "$proof"
  set +e
  timeout 5 "$tmp/$proof.elf" >"$tmp/$proof.native.out" 2>"$tmp/$proof.native.err"
  rc=$?
  set -e
  [[ "$rc" -eq "$expected_exit" ]] || fail native "$proof:$scenario:exit=$rc:expected=$expected_exit"
  [[ ! -s "$tmp/$proof.native.out" && ! -s "$tmp/$proof.native.err" ]] || fail native "$proof:unexpected-output"
  positive_count=$((positive_count + 1))
done < tests/goldens/g12-pf005/public-positive.tsv

public=examples/evolution/g12-column-int4.no
"$NEBOC" check "$public" >/dev/null || fail public check
"$NEBOC" emit-asm "$public" -o "$tmp/public.a.asm" >/dev/null || fail public emit-a
"$NEBOC" emit-asm "$public" -o "$tmp/public.b.asm" >/dev/null || fail public emit-b
cmp -s "$tmp/public.a.asm" "$tmp/public.b.asm" || fail public determinism
"$NEBOC" build "$public" -o "$tmp/public.elf" >/dev/null || fail public build
static_elf "$tmp/public.elf" || fail public elf
set +e
timeout 5 "$tmp/public.elf" >"$tmp/public.native.out" 2>"$tmp/public.native.err"
public_rc=$?
set -e
[[ "$public_rc" -eq 10 ]] || fail public "native-exit=$public_rc"
[[ ! -s "$tmp/public.native.out" && ! -s "$tmp/public.native.err" ]] || fail public unexpected-output
positive_count=$((positive_count + 1))

negative_count=0
while IFS=$'\t' read -r proof source _ diagnostic _; do
  [[ "$proof" == proof_id ]] && continue
  for mode in check emit-asm build; do
    artifact="$tmp/$proof.$mode.artifact"
    set +e
    case "$mode" in
      check) "$NEBOC" check "$source" >"$tmp/$proof.$mode.out" 2>"$tmp/$proof.$mode.err" ;;
      emit-asm) "$NEBOC" emit-asm "$source" -o "$artifact" >"$tmp/$proof.$mode.out" 2>"$tmp/$proof.$mode.err" ;;
      build) "$NEBOC" build "$source" -o "$artifact" >"$tmp/$proof.$mode.out" 2>"$tmp/$proof.$mode.err" ;;
    esac
    rc=$?
    set -e
    [[ "$rc" -eq 1 ]] || fail negative "$proof:$mode:exit=$rc"
    [[ ! -s "$tmp/$proof.$mode.out" && ! -e "$artifact" ]] || fail negative "$proof:$mode:residual"
    grep -Fq "$diagnostic" "$tmp/$proof.$mode.err" || fail negative "$proof:$mode:diagnostic"
  done
  cmp -s "$tmp/$proof.check.err" "$tmp/$proof.emit-asm.err" || fail negative "$proof:emit-diagnostic-drift"
  cmp -s "$tmp/$proof.check.err" "$tmp/$proof.build.err" || fail negative "$proof:build-diagnostic-drift"
  negative_count=$((negative_count + 1))
done < tests/goldens/g12-pf005/public-diagnostics.tsv

echo "POST_RC1_G12_GREEN positives=$positive_count negatives=$negative_count public_exit=$public_rc"
