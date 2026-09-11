# Security guide

Treat source files, package manifests, plugin manifests and capability inputs as
untrusted. Keep capabilities deny-by-default, use bounded values, and redact
sensitive fields before logs, traces or audit sinks. Never place credentials,
private keys or personal data in examples or reports.

The verified core products are static x86-64 ELF binaries without a C or libc
dependency. Plugin execution and local subprocesses provide bounded process
isolation, not a strong OS sandbox. Dynamic FFI, arbitrary network access,
signing keys and independent security review are not claimed. Vulnerabilities
should be reported privately according to [SECURITY.md](SECURITY.md).

Run `neboc doctor` for the bounded local toolchain inventory and
`neboc security-report` for its SBOM, provenance, report-channel, fuzz-campaign,
and package-signature facts. The reports use no network and explicitly report
that no signing keys or signature claim are available.
