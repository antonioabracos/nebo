# Pending records

MF029 materializes one deterministic `Pending<Text>` record for every accepted
scan route. `PendingId` values are 1-based and follow producer source order.

A record owns compile-time identity and metadata only:

- producer scan `NodeId`;
- `ConsoleRouteId`;
- scan `IntrinsicId`;
- `Pending<Text>` and resolved `Text` type IDs;
- source order;
- first dependent edge and dependent count;
- produced, connected or orphan classification;
- pointer-free FNV-1a32 hash.

No runtime future, scheduler, await or continuation code is created here.
