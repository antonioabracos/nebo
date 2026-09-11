# MF029 Pending and dependency tests

Primary Test IDs:

- `NEBO-PENDING-CONTRACT-001` — scan creates a complete `Pending<Text>` record;
- `NEBO-PENDING-CONTRACT-002` — a Text consumer creates the producer edge;
- `NEBO-PENDING-CONTRACT-003` — unrelated Pending flows remain independent;
- `NEBO-PENDING-CONTRACT-004` — dependent edges preserve canonical source order;
- `NEBO-PENDING-NEG-005` — a static cycle is rejected before graph mutation;
- `NEBO-PENDING-CONTRACT-008` — continuation seed IDs and dumps are deterministic;
- `NEBO-PENDING-CONTRACT-009` — capture sets contain only values actually used.

Infrastructure scenarios also verify orphan classification and attachment of the
frozen `PendingTable` and `DependencyGraph` to `SemanticDatabase`.
