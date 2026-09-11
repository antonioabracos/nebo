# G03-PF003 semantic proof sources

These files describe the semantic/abstract-IR contract frozen by G03-PF003.
The ten sources are deliberately **not** wired into the public parser,
typechecker, lowering pipeline or CLI in this front. The transactional validator
therefore requires all ten to remain `neboc check` rejections while the isolated
Assembly semantic test proves their normalized types, effects, HIR/LIR shapes
or expected diagnostic ownership.
