; RUNTIME-DISTRIBUIDO-E-STREAMING-DISTRIBUIDO-F06 explicit grounded claim classification.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/knowledge/claim.inc"
section .text
NEBOC_ABI_FUNCTION nebo_claim_classify
 ; valid,support_count,contradiction_count
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .no_support
 test rdx,rdx
 jnz .ambiguous
 mov eax,NEBO_CLAIM_SUPPORTED
 ret
.no_support:
 test rdx,rdx
 jnz .contradicted
 mov eax,NEBO_CLAIM_UNKNOWN
 ret
.contradicted: mov eax,NEBO_CLAIM_CONTRADICTED
 ret
.ambiguous: mov eax,NEBO_CLAIM_AMBIGUOUS
 ret
.invalid: mov eax,NEBO_CLAIM_INVALID
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
