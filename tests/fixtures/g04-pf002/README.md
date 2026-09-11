# G04-PF002 fixtures

This directory contains isolated syntax/API/diagnostic contract sources.

- `001`–`008`: positive parser-contract sources; the public CLI must still reject them in PF002.
- `009`–`028`: negative or deferred contract sources.
- `014`–`016` intentionally contain invalid UTF-8 byte sequences and are binary test fixtures.

No file here declares public semantic, codegen or runtime support.
