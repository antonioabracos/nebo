
# NEBO 1.0 THREAT MODEL

FRONT=RF204-G197-F01
STATE=FROZEN_FACTUAL
PROFILE=LOCAL_LINUX_X86_64_PRE_RC

Trust boundaries cover source, compiler, build, SDK, packages, install, runtime, Console, loopback network and plugins. Assets and untrusted inputs are explicit; release signing keys are outside this program.

## Invariants

- `console()` remains canonical; `.print()` is not introduced.
- No import grants a capability and no external network is used.
- No real secret or private key is read, copied, generated or packaged.
- Failure is fail-closed and leaves zero accepted partial state.
- P08, RC1, tags, releases and remote publication remain unauthorized.
