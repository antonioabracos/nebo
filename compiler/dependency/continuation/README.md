# Continuation descriptors

MF030 converts deterministic `ContinuationSeedId` values from the MF029 dependency
graph into compiler-owned descriptors. Each descriptor records:

- deterministic identity and logical entry label `nebo_cont_<FunctionId>_<ContinuationId>`;
- producer and optional consumer `PendingId`;
- trigger `EdgeId`, source order and execution domain;
- the minimal capture set copied from the frozen dependency edge;
- transitive cancellation policy and a one-shot abstract lifecycle.

The lifecycle models compile-time/runtime contracts only. MF030 does not emit
continuation Assembly, run a scheduler or expose closures in the Nebo language.
