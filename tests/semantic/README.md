# MF025 Validated AST tests

The parameterized Assembly executable covers the five primary MF025 contracts:

1. complete type metadata and controlled rejection of a missing type;
2. complete effect metadata for call nodes;
3. completeness auditing of already-supplied route IDs;
4. completeness auditing of already-supplied Pending dependency IDs;
5. pointer-independent semantic hash/dump determinism and the ErrorNode exit gate.

`goldens/009-validated-ast-dump.txt` is the canonical semantic dump. The
FunctionPlan determinism contract is satisfied by proving stable target-
independent lowering input order; MF025 does not materialize backend IR.
