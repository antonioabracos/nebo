# Test fixtures

Fixtures are added by the microfront that owns the corresponding Test ID.

Rules:

- include the Test ID in the filename;
- contain no secrets or personal data;
- preserve UTF-8/LF unless the test explicitly covers another byte sequence;
- record a hash in evidence when executed;
- never overwrite a failing regression fixture to make a test pass.
