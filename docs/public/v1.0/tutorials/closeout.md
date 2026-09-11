# Input, typed error handling and return

The completed local walkthrough parses 67 and calculates 67*2+3=137. Failed parsing returns early before arithmetic. Every new source and project is linked to an independent expected result.

The public documentation archive is deterministic: sorted relative files, fixed mode 0644, zero owner IDs and timestamps. Restore checks the full manifest before publishing to a new root. Broken links, hostile archive members, missing search rows and modified code examples are rejected. This documentation package is local and grants no release, target or security certification.

```nebo
// Parsing succeeds before the independent arithmetic observation.
start(){"Value".scan(.int(),.result(),.mock("67")).r;if(r.isErr()){7.return;} (r.unwrapOr(0)*2+3).return;}
```

Expected context:
```json
{
  "expected_exit": 137
}
```
