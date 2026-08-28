# Stack-alignment delta regression

This public regression records the seven corrected System V AMD64 call sites
and validates the released compiler with both stack auditors:

- `scripts/mf056/audit-stack-alignment.py`
  (`b735cb0e368209c3918f168c965afd2083209b021d9e362fcd1bb248f7426b65`)
- `scripts/release/nebo-1.0/prepublication-remediation/stack_alignment_oracle.py`
  (`9e29c7fce77c79e94432d9cf4ac1379c74ffde7201c8cea49babb02de8bb6806`)

The project retains frozen historical alignment debt. The public release gate
requires none of the seven rows in `authenticated-seven-findings.tsv` to remain
and requires the frozen counts (MF056 285, independent oracle 133). The test
never allowlists a release finding and requires no network or pre-existing
temporary directory.

Run from any directory with:

```text
bash tests/regressions/stack-alignment-delta/validate.sh
```
