#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo"
NEBOC="${NEBOC:-build/bin/neboc}"
fail(){ printf 'RF27_AUD002_VALIDATION_ERROR step=%s detail=%s\n' "$1" "${2:-unknown}" >&2; exit 1; }
for tool in ninja nasm file readelf nm rg cmp timeout python3 sha256sum awk sort stat; do command -v "$tool" >/dev/null 2>&1 || fail tool "$tool"; done
[[ -x "$NEBOC" ]] || fail tool missing_neboc

tmp="$(mktemp -d "${TMPDIR:-/tmp}/rf27-aud002.XXXXXXXX")"
trap 'rm -rf -- "$tmp"' EXIT

static_elf(){
  local artifact="$1"
  file "$artifact" | rg -q 'ELF 64-bit.*x86-64.*statically linked' || return 1
  ! readelf -lW "$artifact" | rg -q INTERP || return 1
  ! readelf -dW "$artifact" 2>/dev/null | rg -q NEEDED || return 1
  [[ -z "$(nm -u "$artifact")" ]] || return 1
  readelf -lW "$artifact" | rg -q 'GNU_STACK.*RW[[:space:]]' || return 1
  ! readelf -lW "$artifact" | rg -q 'GNU_STACK.*RWE' || return 1
}

printf 'RF27_AUD002_GATE_PROGRESS=focused_build_start\n'
# The first AUD-002 replay exposed that the phony target built only neboc and
# could leave the isolated G05 native-lowering object stale in build/. Remove
# only those ignored outputs, rebuild through the corrected graph, and compare
# the graph object with two direct deterministic NASM rebuilds.
rm -f build/obj/g05_binding_native_lowering.o \
      build/tests/g05-pf004/binding_native_test
ninja -v -j2 rf27-aud002-binding-console-composition
[[ -f build/obj/g05_binding_native_lowering.o ]] || fail build missing_fresh_native_lowering_object
[[ -x build/tests/g05-pf004/binding_native_test ]] || fail build missing_g05_pf004_native_test
nasm -f elf64 -Wall -Werror -I./ \
  -o "$tmp/g05_binding_native_lowering.a.o" \
  compiler/lowering/bindings/binding_native_lowering.asm
nasm -f elf64 -Wall -Werror -I./ \
  -o "$tmp/g05_binding_native_lowering.b.o" \
  compiler/lowering/bindings/binding_native_lowering.asm
cmp -s "$tmp/g05_binding_native_lowering.a.o" "$tmp/g05_binding_native_lowering.b.o" \
  || fail determinism native_lowering_object_a_b
cmp -s build/obj/g05_binding_native_lowering.o "$tmp/g05_binding_native_lowering.a.o" \
  || fail build stale_native_lowering_object
printf 'RF27_AUD002_GATE_PROGRESS=fresh_native_lowering_object_green build_graph=g05_pf004 deterministic=a_b\n'
python3 scripts/rf27-aud002/stack_check.py \
  build/obj/g05_binding_vertical.o \
  build/obj/g05_binding_codegen.o \
  build/obj/rf27_g02_scoped_slot_layout.o \
  build/obj/g05_binding_native_lowering.o
python3 scripts/rf27-aud002/validate-model.py
python3 scripts/rf27-aud002/composition_corpus.py --self-test
python3 scripts/rf27-aud002/composition_corpus.py --emit "$tmp/corpus"
declare -A checked_in=(
  [explicit-int]=explicit-int-binding-console.no
  [inferred-int]=inferred-int-binding-console.no
  [expression]=expression-binding-console.no
  [call-result]=call-result-binding-console.no
  [text]=text-binding-console.no
  [bool]=bool-binding-console.no
)
for profile in "${!checked_in[@]}"; do
  cmp -s "tests/rf27-aud002/positive/${checked_in[$profile]}" "$tmp/corpus/$profile--exact.no" \
    || fail corpus "$profile:checked_in_exact_drift"
done

mkdir -p "$tmp/reference"
positive_cases=0
while IFS=$'\t' read -r case_id profile variant source_path source_sha; do
  [[ "$case_id" != case_id ]] || continue
  source="$tmp/corpus/$source_path"
  [[ "$(sha256sum "$source" | awk '{print $1}')" == "$source_sha" ]] || fail corpus "$case_id:hash"
  "$NEBOC" check "$source" >"$tmp/$case_id.check.out" 2>"$tmp/$case_id.check.err" || fail positive "$case_id:check"
  "$NEBOC" emit-asm "$source" -o "$tmp/$case_id.a.asm" >"$tmp/$case_id.emit-a.out" 2>"$tmp/$case_id.emit-a.err" || fail positive "$case_id:emit-a"
  "$NEBOC" emit-asm "$source" -o "$tmp/$case_id.b.asm" >"$tmp/$case_id.emit-b.out" 2>"$tmp/$case_id.emit-b.err" || fail positive "$case_id:emit-b"
  cmp -s "$tmp/$case_id.a.asm" "$tmp/$case_id.b.asm" || fail determinism "$case_id:assembly-a-b"
  "$NEBOC" build "$source" -o "$tmp/$case_id.elf" >"$tmp/$case_id.build.out" 2>"$tmp/$case_id.build.err" || fail positive "$case_id:build"
  for stream in check.out check.err emit-a.out emit-a.err emit-b.out emit-b.err build.out build.err; do
    [[ ! -s "$tmp/$case_id.$stream" ]] || fail output "$case_id:$stream"
  done
  static_elf "$tmp/$case_id.elf" || fail elf "$case_id"
  [[ "$(rg -c '^[[:space:]]+call nebo_runtime_contract_1$' "$tmp/$case_id.a.asm")" == 1 ]] || fail assembly "$case_id:console_call"
  rg -q 'mov \[rbp - [0-9]+\], (rax|eax|al)' "$tmp/$case_id.a.asm" || fail assembly "$case_id:slot_store"
  rg -q 'mov(zx)? (rax|eax), (byte )?\[rbp - [0-9]+\]' "$tmp/$case_id.a.asm" || fail assembly "$case_id:slot_load"
  case "$profile" in
    expression)
      rg -q '^[[:space:]]+imul rax, rcx$' "$tmp/$case_id.a.asm" || fail assembly "$case_id:imul"
      rg -q '^[[:space:]]+add rax, rcx$' "$tmp/$case_id.a.asm" || fail assembly "$case_id:add"
      ;;
    call-result)
      rg -q '^[[:space:]]+call nebo_runtime_textual_text_byte_length$' "$tmp/$case_id.a.asm" || fail assembly "$case_id:call_result"
      ;;
  esac
  if [[ "$variant" == exact ]]; then
    "$NEBOC" build "$source" -o "$tmp/$case_id.b.elf" >"$tmp/$case_id.build-b.out" 2>"$tmp/$case_id.build-b.err" \
      || fail positive "$case_id:build-b"
    [[ ! -s "$tmp/$case_id.build-b.out" && ! -s "$tmp/$case_id.build-b.err" ]] || fail output "$case_id:build-b"
    cmp -s "$tmp/$case_id.elf" "$tmp/$case_id.b.elf" || fail determinism "$case_id:elf-a-b"
    cp "$tmp/$case_id.a.asm" "$tmp/reference/$profile.asm"
    cp "$tmp/$case_id.elf" "$tmp/reference/$profile.elf"
  else
    cmp -s "$tmp/reference/$profile.asm" "$tmp/$case_id.a.asm" || fail metamorphic "$case_id:assembly"
    cmp -s "$tmp/reference/$profile.elf" "$tmp/$case_id.elf" || fail metamorphic "$case_id:elf"
  fi
  set +e
  timeout 8 "$tmp/$case_id.elf" >"$tmp/$case_id.native.out" 2>"$tmp/$case_id.native.err"
  rc=$?
  set -e
  [[ "$rc" -eq 0 ]] || fail native "$case_id:exit=$rc"
  [[ ! -s "$tmp/$case_id.native.out" && ! -s "$tmp/$case_id.native.err" ]] || fail native "$case_id:unexpected_output"
  positive_cases=$((positive_cases + 1))
done < "$tmp/corpus/MANIFEST.tsv"
[[ "$positive_cases" == 24 ]] || fail corpus "positive_cases=$positive_cases"
printf 'RF27_AUD002_GATE_PROGRESS=positive_composition_green cases=24 modes=check_emit_build_native\n'

declare -A expected_diag=(
  [undefined-binding-console.no]='NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-UNDEFINED-NAME'
  [char-binding-console.no]='NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-TYPE-MISMATCH'
  [float-arithmetic-console.no]='NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-TYPE-MISMATCH'
  [console-argument.no]='NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-TYPE-MISMATCH'
)
negative_cases=0
for source in tests/rf27-aud002/negative/*.no; do
  name="$(basename "$source")"
  diag="${expected_diag[$name]:-}"
  [[ -n "$diag" ]] || fail negative "$name:missing_expected_diagnostic"
  for mode in check emit-asm build; do
    artifact="$tmp/$name.$mode.artifact"
    set +e
    case "$mode" in
      check) "$NEBOC" check "$source" >"$tmp/$name.$mode.out" 2>"$tmp/$name.$mode.err" ;;
      emit-asm) "$NEBOC" emit-asm "$source" -o "$artifact" >"$tmp/$name.$mode.out" 2>"$tmp/$name.$mode.err" ;;
      build) "$NEBOC" build "$source" -o "$artifact" >"$tmp/$name.$mode.out" 2>"$tmp/$name.$mode.err" ;;
    esac
    rc=$?
    set -e
    [[ "$rc" -eq 1 ]] || fail negative "$name:$mode:exit=$rc"
    [[ ! -s "$tmp/$name.$mode.out" && ! -e "$artifact" ]] || fail negative "$name:$mode:residual"
    rg -q "$diag" "$tmp/$name.$mode.err" || fail negative "$name:$mode:diagnostic"
  done
  cmp -s "$tmp/$name.check.err" "$tmp/$name.emit-asm.err" || fail negative "$name:emit_drift"
  cmp -s "$tmp/$name.check.err" "$tmp/$name.build.err" || fail negative "$name:build_drift"
  negative_cases=$((negative_cases + 1))
done
[[ "$negative_cases" == 4 ]] || fail negative "count=$negative_cases"
printf 'RF27_AUD002_GATE_PROGRESS=negative_composition_green cases=4 tri_mode=yes typed_diagnostics=yes\n'

# AUD-002 must not preempt the historical literal-Console routes merely
# because their outer chain terminates in a binding.  These two fixtures are
# the minimal ownership regressions: a named literal Console and a
# literal.console().scan().name chain.
legacy_console_cases=0
for source in \
  tests/e2e/console-output/fixtures/named.no \
  tests/post-rc1-coherence/fixtures/scan-console.no
do
  id="legacy-console-$legacy_console_cases"
  "$NEBOC" check "$source" >"$tmp/$id.check.out" 2>"$tmp/$id.check.err" \
    || fail routing "$source:check"
  "$NEBOC" emit-asm "$source" -o "$tmp/$id.a.asm" >"$tmp/$id.emit-a.out" 2>"$tmp/$id.emit-a.err" \
    || fail routing "$source:emit-a"
  "$NEBOC" emit-asm "$source" -o "$tmp/$id.b.asm" >"$tmp/$id.emit-b.out" 2>"$tmp/$id.emit-b.err" \
    || fail routing "$source:emit-b"
  cmp -s "$tmp/$id.a.asm" "$tmp/$id.b.asm" || fail routing "$source:determinism"
  "$NEBOC" build "$source" -o "$tmp/$id.elf" >"$tmp/$id.build.out" 2>"$tmp/$id.build.err" \
    || fail routing "$source:build"
  for stream in check.out check.err emit-a.out emit-a.err emit-b.out emit-b.err build.out build.err; do
    [[ ! -s "$tmp/$id.$stream" ]] || fail routing "$source:$stream"
  done
  static_elf "$tmp/$id.elf" || fail routing "$source:elf"
  legacy_console_cases=$((legacy_console_cases + 1))
done
[[ "$legacy_console_cases" == 2 ]] || fail routing "legacy_console_cases=$legacy_console_cases"
printf 'RF27_AUD002_GATE_PROGRESS=legacy_console_chain_green cases=2 routing=historical_literal_console\n'

# The canonical Console contract and rejection of print() must remain intact.
if ! bash tests/post-rc1-coherence/console-g04.sh >"$tmp/console-g04.log" 2>&1; then
  tail -n 160 "$tmp/console-g04.log" >&2 || true
  fail regression console_g04
fi
rg -q '^POST_RC1_CONSOLE_G04_GREEN positives=10 negatives=4 print_alias=NO$' "$tmp/console-g04.log" || fail regression console_g04_marker
python3 - <<'PYPRINT' || fail console print_alias_active
import re
from pathlib import Path
for name in (
    "compiler/semantic/bindings/binding_vertical.asm",
    "compiler/codegen/bindings/x86_64/binding_codegen.asm",
):
    body = Path(name).read_text(encoding="utf-8")
    if re.search(r"(^|\n)\s*n_print\b|db\s+[\"']print[\"']", body):
        raise SystemExit(1)
PYPRINT
printf 'RF27_AUD002_GATE_PROGRESS=console_policy_green console=canonical print_alias=NO\n'

# Preserve the historical G05 binding contract before exercising the terminal
# structural-dispatch and G14-G18 closeout regressions.  The canonical G05-PF005
# front validator predates both v0.2 tag materialization and the repository-wide
# umask 077 delivery discipline.  Its linked-symbol discovery uses `-perm -111`,
# which requires owner, group and other execute bits simultaneously.  Fresh test
# executables created under umask 077 are mode 0700, so the old predicate skips the
# correctly linked G05-PF003 semantic test and reports `symbol not_linked`.
#
# Reuse a temporary read-only current-front overlay and replace exactly two stale
# assumptions: the pre-materialization tag gate and the all-three-execute-bits
# predicate.  The replacement keeps type/path bounds and exact `nm` symbol checks;
# it merely accepts any executable bit (`-perm /111`), which includes owner-only
# executables.  Historical scripts, reports, refs and package bytes remain untouched.
printf 'RF27_AUD002_GATE_PROGRESS=regression_g05_pf005_start\n'
g05_current_validator='scripts/pre-commit/validate-current-front.sh'
g05_leaf_validator='scripts/g05-pf005/validate.sh'
g05_current_before="$(sha256sum "$g05_current_validator" | awk '{print $1}')"
g05_leaf_before="$(sha256sum "$g05_leaf_validator" | awk '{print $1}')"
g05_symbol='neboc_binding_semantic_analyze'
g05_semantic_object='build/obj/g05_binding_semantic.o'
g05_semantic_test_object='build/obj/tests/types/g05_pf003_binding_semantic_test.o'
g05_semantic_test='build/tests/g05-pf003/binding_semantic_test'

[[ "$(grep -Fc 'nebo_validate_v02_tag_boundary || fail release v02_tag_policy' "$g05_current_validator")" -eq 1 ]] \
  || fail regression g05_pf005_overlay_release_shape
[[ "$(grep -Fc 'done < <(find build/tests -mindepth 2 -maxdepth 2 -type f -perm -111 -path "*/$group_lower-*/*" | sort)' "$g05_current_validator")" -eq 1 ]] \
  || fail regression g05_pf005_overlay_exec_shape

# Prove the actual failure primitive from fresh ignored build outputs.  Under this
# validator's inherited umask 077, ld creates the test executable as 0700.
rm -f "$g05_semantic_object" "$g05_semantic_test_object" "$g05_semantic_test"
if ! ninja -v -j2 g05-pf005 >"$tmp/g05-pf005-prerequisite-build.log" 2>&1; then
  tail -n 160 "$tmp/g05-pf005-prerequisite-build.log" >&2 || true
  fail regression g05_pf005_prerequisite_build
fi
[[ -f "$g05_semantic_object" ]] || fail regression g05_pf005_semantic_object_missing
[[ -x "$g05_semantic_test" ]] || fail regression g05_pf005_semantic_test_missing
nm -g --defined-only "$g05_semantic_object" | awk -v symbol="$g05_symbol" '$3==symbol {found=1} END{exit !found}' \
  || fail regression g05_pf005_symbol_object_missing
nm -g --defined-only "$g05_semantic_test" | awk -v symbol="$g05_symbol" '$3==symbol {found=1} END{exit !found}' \
  || fail regression g05_pf005_symbol_test_missing
g05_test_mode="$(stat -c '%a' "$g05_semantic_test")"
[[ "$g05_test_mode" == 700 ]] || fail regression "g05_pf005_semantic_test_mode_$g05_test_mode"

old_symbol_matches=0
while IFS= read -r candidate; do
  if nm -g --defined-only "$candidate" 2>/dev/null | awk -v symbol="$g05_symbol" '$3==symbol {found=1} END{exit !found}'; then
    old_symbol_matches=$((old_symbol_matches + 1))
  fi
done < <(find build/tests -mindepth 2 -maxdepth 2 -type f -perm -111 -path '*/g05-*/*' | sort)
new_symbol_matches=0
new_target_found=NO
while IFS= read -r candidate; do
  if nm -g --defined-only "$candidate" 2>/dev/null | awk -v symbol="$g05_symbol" '$3==symbol {found=1} END{exit !found}'; then
    new_symbol_matches=$((new_symbol_matches + 1))
    [[ "$candidate" == "$g05_semantic_test" ]] && new_target_found=YES
  fi
done < <(find build/tests -mindepth 2 -maxdepth 2 -type f -perm /111 -path '*/g05-*/*' | sort)
[[ "$old_symbol_matches" -eq 0 ]] || fail regression "g05_pf005_old_exec_predicate_matches_$old_symbol_matches"
[[ "$new_symbol_matches" -ge 1 && "$new_target_found" == YES ]] \
  || fail regression "g05_pf005_new_exec_predicate_matches_${new_symbol_matches}_target_${new_target_found}"
printf 'RF27_AUD002_G05_EXECUTABLE_DISCOVERY=PASS test_mode=%s old_perm_all_symbol_matches=%s new_perm_any_symbol_matches=%s target_found=%s\n' \
  "$g05_test_mode" "$old_symbol_matches" "$new_symbol_matches" "$new_target_found"

python3 - "$g05_current_validator" "$tmp/validate-current-front-g05-pf005.sh" <<'PY_G05_OVERLAY'
from pathlib import Path
import sys
src=Path(sys.argv[1])
dst=Path(sys.argv[2])
text=src.read_text(encoding='utf-8')
old_release='nebo_validate_v02_tag_boundary || fail release v02_tag_policy'
new_release='bash scripts/rf27-g01/validate-successor-boundary.sh >/dev/null || fail release rf27_successor_boundary'
old_exec='  done < <(find build/tests -mindepth 2 -maxdepth 2 -type f -perm -111 -path "*/$group_lower-*/*" | sort)'
new_exec='  done < <(find build/tests -mindepth 2 -maxdepth 2 -type f -perm /111 -path "*/$group_lower-*/*" | sort)'
if text.count(old_release)!=1:
    raise SystemExit('RELEASE_SHAPE')
if text.count(old_exec)!=1:
    raise SystemExit('EXEC_SHAPE')
text=text.replace(old_release,new_release,1).replace(old_exec,new_exec,1)
dst.write_text(text,encoding='utf-8')
PY_G05_OVERLAY
[[ "$(grep -Fc 'bash scripts/rf27-g01/validate-successor-boundary.sh >/dev/null || fail release rf27_successor_boundary' "$tmp/validate-current-front-g05-pf005.sh")" -eq 1 ]] \
  || fail regression g05_pf005_overlay_successor_shape
[[ "$(grep -Fc 'done < <(find build/tests -mindepth 2 -maxdepth 2 -type f -perm /111 -path "*/$group_lower-*/*" | sort)' "$tmp/validate-current-front-g05-pf005.sh")" -eq 1 ]] \
  || fail regression g05_pf005_overlay_exec_any_shape
! grep -Fq 'nebo_validate_v02_tag_boundary || fail release v02_tag_policy' "$tmp/validate-current-front-g05-pf005.sh" \
  || fail regression g05_pf005_overlay_old_boundary_remains
! grep -Fq 'done < <(find build/tests -mindepth 2 -maxdepth 2 -type f -perm -111 -path "*/$group_lower-*/*" | sort)' "$tmp/validate-current-front-g05-pf005.sh" \
  || fail regression g05_pf005_overlay_old_exec_predicate_remains
if ! bash scripts/rf27-g01/validate-successor-boundary.sh >"$tmp/g05-successor-boundary.log" 2>&1; then
  tail -n 160 "$tmp/g05-successor-boundary.log" >&2 || true
  fail regression g05_pf005_successor_boundary
fi
if ! bash "$tmp/validate-current-front-g05-pf005.sh" G05-PF005 >"$tmp/g05-pf005.log" 2>&1; then
  tail -n 160 "$tmp/g05-pf005.log" >&2 || true
  fail regression g05_pf005
fi
[[ "$(sha256sum "$g05_current_validator" | awk '{print $1}')" == "$g05_current_before" ]] \
  || fail read_only g05_current_validator_mutated
[[ "$(sha256sum "$g05_leaf_validator" | awk '{print $1}')" == "$g05_leaf_before" ]] \
  || fail read_only g05_leaf_validator_mutated
rg -q '^RF27_G01_SUCCESSOR_BOUNDARY_GREEN ' "$tmp/g05-successor-boundary.log" \
  || fail regression g05_pf005_successor_boundary_marker
rg -q '^CURRENT_FRONT_VALIDATION_GREEN front=G05-PF005 ' "$tmp/g05-pf005.log" \
  || fail regression g05_pf005_marker
printf 'RF27_AUD002_GATE_PROGRESS=regression_g05_pf005_green release_boundary=temporary_successor_safe_overlay executable_discovery=any_execute_bit historical_scripts_mutated=no\n'

printf 'RF27_AUD002_GATE_PROGRESS=regression_aud001_start\n'
if ! bash tests/rf27-aud001/validate.sh >"$tmp/aud001.log" 2>&1; then
  tail -n 200 "$tmp/aud001.log" >&2 || true
  fail regression rf27_aud001
fi
rg -q '^RF27_AUD001_GREEN ' "$tmp/aud001.log" \
  || fail regression rf27_aud001_marker
rg -q '^RF27_AUD001_GATE_PROGRESS=terminal_regression_green rf27_g18_f09=pass$' "$tmp/aud001.log" \
  || fail regression rf27_g18_f09_marker
printf 'RF27_AUD002_GATE_PROGRESS=regression_aud001_green includes_f09=pass\n'

printf 'RF27_AUD002_COMPOSITION_GREEN profiles=6 generated_positive=24 negative=4 explicit=pass inferred=pass expression=pass call_result=pass text=pass bool=pass console=canonical print=rejected g05_pf005=pass g05_exec_discovery=any_execute_bit aud001=pass f09=pass deterministic_asm_elf=yes static_elf=yes\n'
