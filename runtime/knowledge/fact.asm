; RUNTIME-DISTRIBUIDO-E-STREAMING-DISTRIBUIDO-F01 stable fact identity and provenance record.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/knowledge/fact.inc"
extern nebo_db_fnv1a64
section .text
NEBOC_ABI_FUNCTION nebo_fact_init
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 test r8,r8
 jz .invalid
 test r9,r9
 jz .invalid
 mov [rdi+NEBO_FACT_SUBJECT],rsi
 mov [rdi+NEBO_FACT_PREDICATE],rdx
 mov [rdi+NEBO_FACT_OBJECT],rcx
 mov [rdi+NEBO_FACT_SOURCE],r8
 mov [rdi+NEBO_FACT_VERSION],r9
 xor eax,eax
 ret
.invalid: mov eax,NEBO_FACT_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_fact_hash
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 push rbx
 mov rbx,rsi
 mov esi,NEBO_FACT_SIZE
 call nebo_db_fnv1a64
 mov [rbx],rax
 pop rbx
 xor eax,eax
 ret
.invalid: mov eax,NEBO_FACT_INVALID
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
