# Canonical AST dump — MF020

The dump is caller-buffered and contains no addresses. It starts with `ASTv1`
and emits one fixed-width lowercase hexadecimal line per node in NodeId order.
Each line contains the NodeId followed by the ten physical `AstNode` qwords.

```txt
Header bytes:
ASTv1\n

Per-node line:
NodeId|Kind|Flags|SourceId|Start|End|FirstChild|NextSibling|ChildCount|Payload0|Payload1\n

Line size:
187 bytes

Ordering:
ascending NodeId

Locale/timestamps/pointers:
ABSENT
```
