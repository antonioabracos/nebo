# Security policy

Report suspected vulnerabilities privately to the project maintainers with the
affected commit, target, minimal synthetic reproducer and impact. Do not include
credentials or personal data. No disclosure or telemetry request is sent by
this policy or by the security readiness inspector.

The current functional profile is local Linux x86-64 System V static ELF.
It is not security certified. Native capability, bounds, ownership, privacy and
provenance owners have bounded conformance tests; these do not establish whole
compiler memory safety, universal information flow or protection from malicious
native code running with the same user authority. Source programs and compiler
inputs require an independently configured process boundary when untrusted.

The [release threat model](../reference/security/NEBO-1.0-THREAT-MODEL.md) defines the
assets, adversaries, controls and exclusions. The corresponding control matrix,
review gates, waiver register and readiness report are shipped as
`sdk/nebo-1.0/security/`. `tools/nebo-security.py` checks these records against a
caller-supplied trusted pin. Record integrity is not independent review.

External security, legal, signing-policy and final-candidate gates remain open.
Advanced crypto, constant-time assurance, external network environments, dynamic
FFI, remote clusters and additional targets are not certified by local tests.
Explicit review receipts bind a candidate and a reviewer role; waivers never
satisfy review gates or permit an unproven mandatory security claim.
