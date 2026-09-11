#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../../.." && pwd)
compiler="$repo_root/build/bin/neboc"
fixture_root="$repo_root/tests/rf27-g21/function-slice-input"
work_root=$(mktemp -d /tmp/nebo-rf27-g21-function-slice-input.XXXXXX)
trap 'rm -rf -- "$work_root"' EXIT INT TERM HUP

[[ -x $compiler ]]

positive_names=(int_length bool_at char_iteration mixed_two_slices forwarding)
positive_exits=(3 1 65 9 2)

for index in "${!positive_names[@]}"; do
    name=${positive_names[$index]}
    expected=${positive_exits[$index]}
    source="$fixture_root/positive/$name.no"
    "$compiler" check "$source"
    "$compiler" emit-asm "$source" -o "$work_root/$name.asm"
    "$compiler" build "$source" -o "$work_root/$name.elf"
    set +e
    "$work_root/$name.elf"
    actual=$?
    set -e
    [[ $actual -eq $expected ]]
done

for source in "$fixture_root"/negative/*.no; do
    name=$(basename "$source" .no)
    for mode in check emit-asm build; do
        artifact="$work_root/$name.$mode"
        set +e
        if [[ $mode == check ]]; then
            "$compiler" check "$source" --message-format json >"$artifact.stdout" 2>&1
        else
            "$compiler" "$mode" "$source" -o "$artifact.out" >"$artifact.stdout" 2>&1
        fi
        status=$?
        set -e
        [[ $status -ne 0 ]]
        [[ ! -e $artifact.out ]]
        if [[ $mode == check ]]; then
            rg -q '"code":"NEBO_' "$artifact.stdout"
        fi
    done
done

echo 'NPT_LANG_21_FUNCTION_SLICE_INPUT=PASS'
