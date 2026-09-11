# Nebo Symbol and Operator Registry — operational library

This library is a deterministic projection of `NEBO-SYMBOL-AND-OPERATOR-REGISTRY-v1.0.md` and
`NEBO-SYMBOL-AND-OPERATOR-REGISTRY-v1.0.tsv`. The authority hashes are `04b9d6a32718a0e1a196babe28ec5d189fd477beb6bd52d78bfca33d00abef86` and
`a6f6cd1fbda1b6ee77934fa24a3b1f654ae16c657a1bd2a1c9c61444f5d72f2a`. The authority remains design-level and this
installation activates zero entries.

The five mutually exclusive classes are `CORE_ALWAYS_ON`, `UNICODE_ALIAS`,
`DOMAIN_GATED`, `RESERVED`, and `REJECTED`. Current state records material
reality; target state records the approved destination without claiming it has
been reached. Unicode aliases preserve exact code-point sequences and never
use NFKC rewriting. Domain gates require explicit typed context. Reserved
forms have no executable semantics; rejected forms remain invalid.

User types may implement known operator protocols but may not create lexemes.
Validate the authorities before these projections and run
`scripts/rf148/validate-installation.sh`. Installation is not syntax
activation and preserves `console()` as the canonical output API.
