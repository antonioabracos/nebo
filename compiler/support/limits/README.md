# Compilation limits v0

The values are the approved DG-009 compiler defaults:

```txt
source/session: 16 MiB
tokens: 2,000,000
AST nodes: 1,000,000
symbols: 1,000,000
functions: 65,536
diagnostics displayed: 512
parser nesting: 512
dependency nodes: 1,000,000
dependency edges: 2,000,000
generated Assembly: 256 MiB
captured tool output: 16 MiB
```

Every value is checked. A checked override may reduce a limit for tests or a
future option, but it cannot silently exceed the approved default.
