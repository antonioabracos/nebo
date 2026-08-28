# G08 bounded PositiveInt refinement example

`../g08-positive-int-refinement.no` is the executable documentation example.
It converts the literal `7` through the validated `PositiveInt` boundary and
uses the total `unwrapOr(1)` observer. Its native process exit is `7`.

The candidate surface is deliberately literal-only. Direct construction,
aliases, dynamic values, other domain families and G09 user-defined aggregate
types remain unavailable.
