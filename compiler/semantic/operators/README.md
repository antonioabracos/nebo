# MF022 — operator rules

The table-free v0.1 rules accept only exact fundamental types. `Int` owns
checked arithmetic and comparisons, `Bool` owns logical operators, and equality
is permitted only for `Int`, `Bool` and UTF-8 `Text`. There is no truthiness,
implicit coercion, `Text + Text`, Float, collection operator or code generation.
