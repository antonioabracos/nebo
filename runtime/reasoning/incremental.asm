; RUNTIME-DISTRIBUIDO-E-STREAMING-DISTRIBUIDO-F04 incremental fact delta and explicit derivation record.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/reasoning/incremental.inc"
section .text
NEBOC_ABI_FUNCTION nebo_inference_apply_delta
 ; base,add,retract,out
 test rcx,rcx
 jz .invalid
 mov rax,rdi
 or rax,rsi
 not rdx
 and rax,rdx
 mov [rcx],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBO_INCREMENTAL_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_explanation_init
 ; record,fact,rule,premise_mask,status
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov [rdi+NEBO_EXPLAIN_FACT],rsi
 mov [rdi+NEBO_EXPLAIN_RULE],rdx
 mov [rdi+NEBO_EXPLAIN_PREMISES],rcx
 mov [rdi+NEBO_EXPLAIN_STATUS],r8
 xor eax,eax
 ret
.invalid: mov eax,NEBO_INCREMENTAL_INVALID
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
