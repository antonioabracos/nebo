# RF27-G02 bounded mutability and control flow

These examples exercise the public bounded G02 profile: local mutable scalar
bindings, checked assignment, lexical `while`/`loop` control, sequential
Range/Array/Slice iteration, and non-local cleanup supplied by the ownership
core.

The profile deliberately excludes global mutation, public `goto`, labelled or
parallel loops, iterator mutation, and unrestricted dynamic iteration.
