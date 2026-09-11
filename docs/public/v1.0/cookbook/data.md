# Canonical JSON from a local file

Read bounded UTF-8 JSON from input.json, validate the bounded sorted-key profile and atomically write output.json. Expected bytes are {"factor":3,"name":"sample"}, with keys already in sorted order and whitespace normalized.

The filesystem import is explicit; all effects stay inside the caller-owned working directory. Use at most 4096 bytes in this recipe. Invalid JSON, traversal and oversized inputs must reject without replacing prior output.

Imports: explicit std.fs File and Path. Required effects/capabilities: read/write access to this private working directory. No network, live display, external credentials or device capability is used.

```nebo
import "std.fs" { Path; File; }.fs;
// Canonical key ordering has independently specified bytes.
start(){Path.parse("input.json").p;File.readText(p,utf8,4096).raw;Json.parse(raw).v;v.toJson(canonicalKeys).s;Path.parse("output.json").q;File.writeText(q,s,utf8,atomic);s.console();47.return;}
```

Expected context:
```json
{
  "expected_exit": 47,
  "expected_files": {
    "output.json": {
      "bytes_hex": "7b22666163746f72223a332c226e616d65223a2273616d706c65227d"
    }
  },
  "inputs": {
    "input.json": {
      "bytes_hex": "7b22666163746f72223a332c20226e616d65223a2273616d706c65227d"
    }
  },
  "kinds": [
    2
  ],
  "text": {
    "bytes_hex": "7b22666163746f72223a332c226e616d65223a2273616d706c65227d"
  }
}
```
