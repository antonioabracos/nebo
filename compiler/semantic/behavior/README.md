# MF024 Behavior Semantics

Behavior descriptors are immutable, pure semantic values. MF024 approves only
`Color`, with `RED.color` as the contract fixture. Behaviors may be interleaved
with positional arguments; positional binding remains independent, while
behavior application order follows source order. Duplicate behavior classes,
unsupported descriptors and effectful descriptors are diagnostics.
