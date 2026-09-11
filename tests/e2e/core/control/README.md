# MF039 control and Text fixtures

This directory freezes native `if/else`, real `&&`/`||` short-circuiting,
content-based `Text` equality, and equivalent explicit/implicit declarations:

```nebo
Int(100).num;
100.num;
```

The explicit constructor is a type assertion, not a coercion. A mismatch such
as `Bool(100).invalid;` is rejected as invalid source.
