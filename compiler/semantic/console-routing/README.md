# Console routing — MF027

MF027 resolves valid Console and Scan chain shapes before code generation.

The table stores stable `ConsoleRouteId` values in source order and records:

- route mode;
- logical Console identity source;
- initial value, console call and scan nodes;
- terminal binding symbol;
- source order;
- complete runtime operation mask and count;
- intrinsic IDs;
- compile-time completeness flags;
- pointer-free deterministic hash.

Supported positive modes are `DEFAULT`, `NAMED`, `ANONYMOUS`, `SCAN_DEFAULT`
and `SCAN_NAMED`. Named and anonymous routes receive independent logical
identities. The runtime must consume this metadata and must not infer routing
from text, call shape or window state.

MF027 does not implement negative diagnostics, Pending records, dependency
edges, runtime windows, handles, HIR/MIR/LIR, lowering or backend emission.

## MF028 negative contract closure

MF028 rejects duplicate terminal bindings, scan chains without a binding,
non-Console named-scan receivers, explicitly ambiguous chains and invalid
terminal type combinations. `Console` routes terminate as `Console`; scan
routes terminate as `Pending<Text>`; `Void` is never a valid route terminal.
Every rejection has a stable diagnostic code and canonical diagnostic name.
Failed analyses allocate no route and leave the routing table count unchanged.
