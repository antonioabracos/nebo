# Format a typed UTF-8 value

Text is UTF-8. The bytes in ação Ω total 9. The typed format inserts 31 into count=%d, producing count=31. These are retained Console values, not an assumed stdout stream.

Use byteLength for byte budgets. Format values according to their declared type. An incompatible format argument is diagnosed before publication; changing the argument must change the rendered value.

Imports: the current implicit prelude. Required effects/capabilities: retained local Console rendering. No network, live display, external credentials or device capability is used.

```nebo
// UTF-8 byte length is distinct from character count.
start(){"ação Ω".byteLength().console();"count=%d".format(31).console();43.return;}
```

Expected context:
```json
{
  "expected_exit": 43,
  "kinds": [
    4,
    2
  ],
  "text": {
    "bytes_hex": "39636f756e743d3331"
  }
}
```
