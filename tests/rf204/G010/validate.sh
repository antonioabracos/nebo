#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
cd "$repo_root"
compiler="$repo_root/build/bin/neboc"
work=$(mktemp -d /tmp/nebo-rf204-g010.XXXXXX)
cleanup() { find "$work" -depth -mindepth 1 -delete; rmdir "$work"; }
trap cleanup EXIT INT TERM HUP

ninja -f build.ninja -j2 build/bin/neboc rf204-g010-conformance-tests >/dev/null

python3 -B tests/rf204/G010/validate.py --report "$work/source-report.json"

native_programs=(
  build/tests/rf27-g10/f02/column_test
  build/tests/rf27-g10/f03/table_test
  build/tests/rf27-g10/f04/validation_test
  build/tests/rf27-g10/f05/dataset_test
  build/tests/rf27-g10/f06/stream_test
  build/tests/rf27-g10/f08/file_dataset_bridge_test
  build/tests/rf27-g10/f09/channel_stream_bridge_test
  build/tests/rf204/G010/g010_runtime_test
)
for native in "${native_programs[@]}"; do
  timeout 10 "$native"
  timeout 10 "$native"
  file "$native" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
  ! readelf -lW "$native" | rg -q INTERP
  test -z "$(nm -u "$native")"
done

# Exercise current typed adjacent owners. The early G009 wrapper requires a
# retired whole-source probe, and pre-G163 I/O fixtures lack explicit imports.
# Their source-to-effect successors own values, paths and filesystem effects.
python3 -B tests/release/post-g204-remediation/source_suite.py relational --report "$work/relational.json"
python3 -B tests/release/post-g204-remediation/source_suite.py filesystem --report "$work/filesystem.json"
"$compiler" check examples/evolution/g12-column-int4.no --message-format json-lines --color never >"$work/legacy-column.check"
test ! -s "$work/legacy-column.check"

for symbol in \
  neboc_schema_init neboc_schema_field neboc_schema_index_of neboc_row_from \
  neboc_row_get neboc_row_project neboc_row_to_tuple neboc_column_from \
  neboc_column_get neboc_column_cast neboc_column_sum_i64 neboc_column_min_i64 \
  neboc_column_max_i64 neboc_colecoes_primitivas_column_count_missing \
  neboc_table_from_columns neboc_table_row_count neboc_table_column_count \
  neboc_table_select neboc_table_filter_eq_i64 neboc_table_sort_by_i64 \
  neboc_table_group_by_i64 neboc_table_join_i64 neboc_column_is_missing \
  neboc_column_fill_missing neboc_column_drop_missing neboc_column_coalesce \
  neboc_table_validate neboc_table_invalid_rows neboc_dataset_from_tables \
  neboc_dataset_schema neboc_dataset_partition_count neboc_dataset_repartition \
  neboc_dataset_scan neboc_dataset_collect_refs neboc_dataset_cache \
  neboc_event_value neboc_flow_value neboc_stream_from neboc_stream_map \
  neboc_stream_filter neboc_stream_batch neboc_stream_window neboc_stream_sink; do
  nm -g --defined-only build/obj/runtime_practical_io.o | rg "[[:space:]]${symbol}$" >/dev/null
done

if rg -n 'RF204-G010-S0[1-6]|examples/rf204/G010|tests/rf204/G010' compiler runtime >"$work/fixture-route.log"; then
  cat "$work/fixture-route.log" >&2
  exit 1
fi

expected_header=$'surface_id\tsubgroup\tsource_example\ttest_case\texpected_observation\timplementation_owner\tstatus'
test "$(head -n1 tests/rf204/G010/SURFACE-MAP.tsv)" = "$expected_header"
test "$(awk -F '\t' 'NR>1 && $7=="PASS" {n++} END {print n+0}' tests/rf204/G010/SURFACE-MAP.tsv)" -eq 44
test "$(awk -F '\t' 'END {print NR-1}' tests/rf204/G010/SURFACE-MAP.tsv)" -eq 44
test "$(cut -f1 tests/rf204/G010/SURFACE-MAP.tsv | tail -n +2 | sort -u | wc -l)" -eq 44
test "$(find examples/rf204/G010 -maxdepth 1 -type f -name 'RF204-G010-S??.no' | wc -l)" -eq 6
test "$("$compiler" --version)" = "$(python3 -B scripts/check-version-consistency.py --expected-cli)"

echo 'RF204_G010_GREEN SUBGROUPS=6/6 SURFACES=44/44 EXAMPLES=6/6 CURRENT_SOURCE_ORACLES=PASS FALSE_GREEN=0'
