# MF032 codegen tests

The native test binary provides nine numbered scenarios. Six are primary Test
Manifest contracts and three are infrastructure checks for lowering-plan
consumption, target mismatch and transactional writer limits. Canonical `.asm`
outputs are also assembled independently by NASM.

A zero-argument invocation is a dedicated process-level smoke contract. It exits
successfully without running a numbered scenario so that the historical
`scripts/mf002/verify-no-c.sh` verifier can execute the binary while checking its
ELF64/no-C/no-libc closure. Invalid explicit arguments still exit with usage
status `2`; numbered scenarios `1..9` retain their original behavior.

MF037 adds `003-arithmetic.asm` and `004-comparison-bool.asm` as canonical checked-Int and Bool outputs.

## Ownership of goldens

MF032 owns the standalone historical set `001`, `002`, `007`, `012`, and
`plan-lowering`. MF037 owns `003-arithmetic.asm` and
`004-comparison-bool.asm`; these include runtime-facing extern contracts and
are validated by the MF037 suite, not by the MF032 wildcard regression.
