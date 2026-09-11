# Executable test cases

Future cases use:

```txt
tests/cases/<TEST-ID>.sh
```

Exit contract:

```txt
0  PASS
10 FAIL
20 BLOCKED
30 SKIPPED_NOT_APPLICABLE — requires <case>.skip metadata
40 NOT_EXECUTED_WITH_REASON — requires <case>.reason metadata
other nonzero FAIL
```

A missing case is reported as `NOT_IMPLEMENTED`. It is never silently skipped.
