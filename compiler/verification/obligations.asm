; REDE-E-PROTOCOLOS-F03 finite proof obligations for overflow, bounds, cleanup and effects.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/verification/obligations.inc"
section .text
NEBOC_ABI_FUNCTION nebo_obligation_evaluate
 ; kind, lhs, rhs, output; returns call status, writes proof state/witness/kind
 test rcx,rcx
 jz .invalid
 mov qword [rcx],0
 mov qword [rcx+8],0
 mov qword [rcx+16],0
 cmp rdi,NEBO_OBLIGATION_OVERFLOW_ADD
 je .overflow
 cmp rdi,NEBO_OBLIGATION_BOUNDS
 je .bounds
 cmp rdi,NEBO_OBLIGATION_CLEANUP
 je .cleanup
 cmp rdi,NEBO_OBLIGATION_EFFECTS
 je .effects
 jmp .invalid
.overflow:
 mov rax,rsi
 add rax,rdx
 jo .failed
 mov [rcx+NEBO_OBLIGATION_RESULT_WITNESS],rax
 jmp .proved
.bounds:
 test rdx,rdx
 jz .failed
 cmp rsi,rdx
 jae .failed
 mov [rcx+NEBO_OBLIGATION_RESULT_WITNESS],rsi
 jmp .proved
.cleanup:
 ; lhs acquired mask, rhs released mask
 mov rax,rsi
 and rax,rdx
 cmp rax,rsi
 jne .runtime
 mov [rcx+NEBO_OBLIGATION_RESULT_WITNESS],rax
 jmp .proved
.effects:
 ; lhs inferred, rhs allowed
 mov rax,rsi
 not rdx
 and rax,rdx
 jnz .failed
 mov [rcx+NEBO_OBLIGATION_RESULT_WITNESS],rsi
.proved:
 mov qword [rcx+NEBO_OBLIGATION_RESULT_STATE],NEBO_OBLIGATION_STATE_PROVED
 mov [rcx+NEBO_OBLIGATION_RESULT_KIND],rdi
 xor eax,eax
 ret
.runtime:
 mov qword [rcx+NEBO_OBLIGATION_RESULT_STATE],NEBO_OBLIGATION_STATE_RUNTIME
 mov [rcx+NEBO_OBLIGATION_RESULT_KIND],rdi
 xor eax,eax
 ret
.failed:
 mov qword [rcx+NEBO_OBLIGATION_RESULT_STATE],NEBO_OBLIGATION_STATE_FAILED
 mov [rcx+NEBO_OBLIGATION_RESULT_KIND],rdi
 xor eax,eax
 ret
.invalid: mov eax,NEBO_OBLIGATION_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_obligations_validate_count
 test rdi,rdi
 jz .invalid_count
 cmp rdi,NEBO_OBLIGATION_MAX_COUNT
 ja .limit
 xor eax,eax
 ret
.invalid_count: mov eax,NEBO_OBLIGATION_STATUS_INVALID
 ret
.limit: mov eax,NEBO_OBLIGATION_STATUS_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
