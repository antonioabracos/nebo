# Runtime-call lowering v0

This layer lowers compile-time Console routing decisions to deterministic calls to the runtime thunks materialized by MF033. It does not implement the visual Console runtime.

Each successful runtime call is accounted atomically in both `RuntimeLowering.call_count` and `AbiAdapter.current_function_calls`. The operation validates the frozen signature call budget before emitting bytes; multi-fragment named/scan emission restores the writer length if any append fails.
