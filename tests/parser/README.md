# MF016 parser tests

The native suite uses explicit token arrays to isolate parser behavior from the
already-green lexer. AST goldens cover an empty `start()`, a receiver-first
function with one positional parameter, and semantic equality between one-line
and multiline opaque block token streams.
