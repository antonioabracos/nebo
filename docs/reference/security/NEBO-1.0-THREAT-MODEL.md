# Nebo 1.0 release threat model

## Assets, actors and trust roots

Assets: caller source and private data; compiler/build inputs; pinned package
identities and compiled interfaces; SDK payloads and install ownership; runtime
memory and handles; Console/Scan streams; local reports. Threat actors include
malformed input producers, malicious package/plugin publishers, accidental
misconfiguration and path substitution by another local process. Tests use only
synthetic canaries, ephemeral local keys and caller-owned directories.

The trust base is the selected checkout and compiler, Python/NASM/ld and Linux,
the caller's expected digests, private install parent, and explicitly authorized
reviewer acceptance. Hashes bind bytes to a trusted pin; a replacement pin is a
replacement authority. Unsigned manifests and HMAC with a local shared test key
are not publisher identity certification. A process able to rewrite the entire
SDK/pin or read the host capability secret is outside those controls. The host
must protect capability authority memory. No privilege separation exists between
arbitrary Python code and Python reference-model capability objects.

## Boundaries and observed controls

| Boundary | Control and owner | Adversarial evidence | Residual limit |
|---|---|---|---|
| Source to compiler | Native lexer/parser/semantic checks, Unicode policy | Structured rejection, same-path valid/invalid reuse, bounded malformed corpus | General untrusted compilation needs OS isolation; no whole-compiler proof |
| Compiler to build | Explicit source closure, native ELF and local tool identities | Rebuild and independent ELF/value oracle | Toolchain and host kernel remain trusted; no diverse bootstrap claim |
| Package and .ni to SDK | Bounded strict schemas, pinned digest, ABI and type checking | Malformed .ni, forged manifests, traversal and archive mutations | Hashes do not authenticate an attacker-controlled pin |
| SDK to install | Descriptor-relative nofollow reads, owned files, private parent, flock, staged no-replace install | Links, permissions, injected failures, original bytes preserved | Same-user malicious writers are not isolated; multi-file repair is not power-loss atomic |
| Host authority to runtime | HMAC/address-bound grants, attenuated budget/effects/scope and epoch revocation | Native grant/copy/tamper/attenuation/revoke assertions | Host authority secret and native pointers must be protected; no constant-time certification |
| Runtime to memory | Checked allocators, move/drop/arena state and bounded operations | Allocation events, UAF/double-free rejection, numeric/OOB assertions | Evidence is bounded to tested owners; zero findings is not absence of all vulnerabilities |
| Runtime to FS/process/network | Explicit root/capability checks and bounded logical policies | Native checks plus separate Landlock/seccomp/resource test envelope | Test kernel isolation is not automatically installed in generated programs |
| Values to Console/Scan/files | Typed privacy policy and secret Scan trace redaction; explicit output contracts | Changed synthetic canaries, no raw values in diagnostic/report channels | Scan source value remains usable by caller; no universal taint tracking or zeroization of all copies |
| Plugin to FFI/IPC/distributed | Pinned signed local JSON, closed behavior set, ABI/budget/lifetime validation | Path races, forged signatures, invalid ABI, call denial, local fault injection | Logical Python reference only; no dlopen, remote process, network consensus or strong sandbox |
| Review to release claims | Caller-pinned records/receipts and explicit external gates | Altered policy/receipt/state/waiver mutations fail closed | Inspector never authorizes release or authenticates reviewer identity by itself |

## Network and cryptographic maturity

Local native socket/HTTP tests use loopback only. External networking and DNS
are not exercised or authorized here. Kernel test confinement rejects socket
creation before any packet. This proves the test envelope, not a default sandbox
on every Nebo executable. SHA-256/HMAC-SHA-256 use independent known-answer tests
and mutated inputs. They make no timing, erasure or security certification claim.
The TLS-labelled native profile proves a pinned local HMAC identity exchange,
not TLS 1.3, Internet PKI or transport encryption. Native AES-256-GCM uses the
Linux AF_ALG AES owner and bounded authenticated-before-publication composition;
PBKDF2-HMAC-SHA256 has a bounded native implementation. Their vectors and
wrong-tag/AAD rejection are tested without networking; none is certified.
PQC, ZK, MPC, attestation and persistent vault operations remain unavailable
pending implementation and review. No gate is satisfied by an algorithm name,
a functional vector, an internal symbol or an SDK reference model.

## Mandatory local profile and exclusions

The G178/G179 functional classification is unchanged. Mandatory claims here are
bounded parser/owner/runtime behavior, descriptor-level path handling, explicit
privacy of the tested sinks and fail-closed records. Broader memory safety,
unforgeability against arbitrary host-memory access, universal noninterference,
constant-time crypto and sandbox security are unclaimed and externally gated.
No new external acceptance or waiver is created. Every active external gate has
an owner role and release impact. Optional exclusions cannot become a dependency
of the mandatory functional profile.
