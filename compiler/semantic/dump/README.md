# Semantic dump

MF025 emits a deterministic, fixed-width textual view of the Validated AST
semantic side tables. Rows follow ascending one-based `NodeId` order and encode
only stable values; memory addresses are never serialized.

The dump is a target-independent audit artifact and a canonical future lowering
input. It is not HIR, MIR, LIR, a physical `FunctionPlan`, Console routing or
backend output.
