# Operator protocol and typed-resolution core

The versioned `OperatorProtocol`/`OperatorKind` schema resolves exact operand
types against a bounded implementation table. Candidate ranking is based on
specificity and treats an equal best rank as ambiguity; declaration order is
never a tie breaker. Generic result TypeIds are resolved through a bounded,
immutable substitution map before publication. User implementations are
admitted only for known protocol identities and only when an operand type owns
the implementation. Resolution does not search conversion routes.

The compiler's current built-in table covers its factual `Int`, `Bool`, `Text`,
and `Bytes` operators. Lowering consumes the resolved semantic identity and
records result type, left-to-right evaluation, exactly-once counts, lazy RHS,
and checked-failure policy. Later groups own additional public operator
families, syntax activation, and domain-gated implementations.
