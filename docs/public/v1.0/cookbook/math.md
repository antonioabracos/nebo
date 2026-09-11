# Observe scalar math in a return

The admitted scalar math return form computes max(37,97)=97. This is a process result from an actual native computation.

Use the precise form and value domains in the math reference. Scientific Matrix/Tensor imports are separate experimental modules, not implied by scalar math. Hardware acceleration and superiority claims are outside this recipe.

Imports: the current implicit prelude and qualified scalar math surface. Required effects/capabilities: none beyond computation and local allocation. No network, live display, external credentials or device capability is used.

```nebo
// The scalar math return form computes this maximum.
start(){std.math.max(37,97).return;}
```

Expected context:
```json
{
  "expected_exit": 97
}
```
