# Signing and public verification policy

Local G198 artifacts and attestations are unsigned. SHA-256 pins authenticate
bytes only against an independently retained expected value, not a publisher.
The verification-only test profile uses Ed25519 and an RFC 8032 public test
vector. This profile accepts public-key bytes and detached signature bytes;
it has no signing or private-key input API. Test keys cannot authorize releases.

A future release signer requires separate explicit authorization and completion
of RELEASE-SIGNING and RELEASE-LEGAL. The proposed release algorithm is Ed25519;
a maintainer-approved public key SHA-256 must be distributed through an
independent trusted channel. Keep private keys offline under an authorized
maintainer, preferably in a hardware-backed store. CI receives no private key.
Never place keys in source archives, logs, environment variables or artifacts.

Rotation requires a new independently approved public-key pin, a recorded
activation date and retirement of the old pin. Revocation is immediate on
suspected compromise; verifiers reject revoked keys even when the cryptographic
signature is valid. Offline verification requires a separately authenticated,
current revocation record; unavailable or stale authorization fails closed.
There is no automatic trust-on-first-use or network key discovery.

The local verifier checks the public pin and revocation/usage policy before
OpenSSL verification. It never converts a valid test signature into release
approval. An unsigned attestation cannot assert signing or publication.

The bounded local verification API accepts nonempty messages up to 16 MiB.
OpenSSL runs with configuration disabled; only supplied public bytes are used.
