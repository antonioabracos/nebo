# MF024 Semantic Control

Every `if`, `&&`, and `||` condition must be `Bool`. Logical operators publish
short-circuit annotations rather than executing runtime control. Branch scopes
are explicit child scopes and do not leak bindings to the parent scope.
