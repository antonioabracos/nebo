# Core value codegen

MF037 materializes checked signed 64-bit `Int`, canonical `Bool` (`0/1`), arithmetic/comparison lowering, a short-circuit foundation and deterministic overflow/division-by-zero trap edges for the single x86-64 System V target. It consumes the parser AST and AssemblyWriter directly; it does not implement functions, `.return`, `if/else`, Float, wrapping arithmetic or optimization.
