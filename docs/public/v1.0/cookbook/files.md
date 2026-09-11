# Write and read a bounded file

Write Nebo83 atomically and read it with a 64-byte bound. The expected file and retained Console bytes are exactly Nebo83.

Filesystem permission belongs to the execution environment; importing std.fs does not grant it. Paths are relative to the private working directory. Do not use real credentials or personal files for the walkthrough.

Imports: explicit std.fs File and Path. Required effects/capabilities: read/write access to this private working directory. No network, live display, external credentials or device capability is used.

```nebo
import "std.fs" { Path; File; }.fs;
// Atomic output is confined to the working directory.
start(){Path.parse("note.txt").p;File.writeText(p,"Nebo83",utf8,atomic);File.readText(p,utf8,64).console();53.return;}
```

Expected context:
```json
{
  "expected_exit": 53,
  "expected_files": {
    "note.txt": {
      "bytes_hex": "4e65626f3833"
    }
  },
  "kinds": [
    2
  ],
  "text": {
    "bytes_hex": "4e65626f3833"
  }
}
```
