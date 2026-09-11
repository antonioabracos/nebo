# Install, create, check and run

The clean-root path uses a local compiler SDK and a separate documentation archive. Linux x86_64, Python 3, NASM and GNU ld are required. No development checkout, download, PATH modification or administrator install is required. Archive integrity is local content integrity; it is not an authenticated release signature.

Obtain the local SDK archive and the matching documentation archive from your local build owner. Restore to a new prefix, verify the SDK, and restore documentation below share/doc/nebo. Create main.no from the source below. Its result is 41: 17 + 24. Shell exit status is the observation; Console retained rendering is documented separately.

```nebo
// A calculated exit status is visible in every shell.
start(){(17+24).return;}
```

Expected context:
```json
{
  "expected_exit": 41
}
```
neboc sdk verify local-sdk.tar
neboc sdk restore local-sdk.tar --destination ./candidate
(cd candidate && python3 -B -S -m compiler.sdk.sdk_lifecycle install . ../sdk)
(cd candidate && python3 -B -S -m compiler.sdk.sdk_lifecycle verify ../sdk)
./sdk/bin/neboc docs portal restore nebo-docs-v1.0.tar -o ./docs
./sdk/bin/neboc docs portal verify ./docs
# Create main.no using the complete source above.
./sdk/bin/neboc check main.no
./sdk/bin/neboc build main.no -o hello
./hello
# Inspect the process status: 41. Open docs/index.html.
./sdk/bin/neboc docs search "getting started" --index ./docs/search-index.json
