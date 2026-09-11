# MF028 negative routing tests

This directory validates compile-time rejection of duplicate Console bindings,
scan chains without a terminal binding, invalid named-scan receivers, ambiguous
chains and invalid `Void`/`Console`/`Pending<Text>` terminal combinations.

Diagnostics are emitted by `ConsoleRouteRequest.error_code`. Failed analyses do not allocate a `ConsoleRouteId` and do not increment the routing table count.
