# Pending dependency graph

MF029 records producer/consumer relationships between `Pending<Text>` values
and their consumers before lowering.

The graph is deterministic:

- pending nodes are registered in 1-based `PendingId` order;
- edges are canonicalized by producer, source order and consumer node;
- `EdgeId` and `ContinuationSeedId` are reassigned after canonical ordering;
- capture candidates are reduced to the values actually used;
- cycle checks run before mutation;
- independent flows remain disconnected;
- orphan records are classified without inventing runtime policy;
- hashes and dumps exclude pointers.

MF030 may consume the continuation seeds and capture sets, but MF029 emits no
continuation code and implements no cancellation or scheduler.
