# Function Code Generation

MF038 introduces the native receiver-first function boundary. The first target keeps deterministic source-order symbol IDs, with `nebo_fn_1` reserved for `start()` and receiver-first declarations assigned `nebo_fn_2...`.

Only direct, statically resolved calls are accepted in this front. Self recursion, mutual recursion and forward calls from receiver-first functions remain rejected.
