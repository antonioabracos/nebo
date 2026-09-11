# Explicit imports and current spelling

Keep Edition, release version, serialized interface version and target identity distinct. Edition 1 filesystem use requires import "std.fs" with the selected File and Path names. A missing import is a visibility error; .console() is the current rendered output sink.

Diagnose first: read the diagnostic code and source span, fix the causal declaration/import/operator, then check and build again. Never edit an expected result to silence a failure. For SDK repair, verify the local candidate and run the existing lifecycle repair command against its owned prefix; foreign files are retained. For operators, use Edition 1 arithmetic +, *, comparison < and compound += with compatible typed operands; the tour exercises these spellings. Replace an assumed .get() on a Scan result with its documented .unwrapOr(default) and handle .isErr() before consuming it. Unsupported editions, stale interfaces and unreviewed cryptography remain explicit boundaries.

```nebo
import "std.fs" { Path; File; }.fs;
// Explicit visibility replaces an undeclared filesystem name.
start(){Path.parse("migrated.txt").p;File.writeText(p,"value=71",utf8,atomic);File.readText(p,utf8,64).console();53.return;}
```

Expected context:
```json
{
  "expected_exit": 53,
  "expected_files": {
    "migrated.txt": {
      "bytes_hex": "76616c75653d3731"
    }
  },
  "kinds": [
    2
  ],
  "text": {
    "bytes_hex": "76616c75653d3731"
  }
}
```
