; MEDIA-IMAGEM-AUDIO-E-VIDEO-F02 explicit dependency tracking and failure-atomic recomputation.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/reactive/computed.inc"
section .text
NEBOC_ABI_FUNCTION nebo_computed_init
 test rdi,rdi
 jz .invalid_init
 mov [rdi+NEBO_COMPUTED_VALUE],rsi
 mov qword [rdi+NEBO_COMPUTED_VERSION],1
 mov qword [rdi+NEBO_COMPUTED_DEPENDENCY_MASK],0
 mov qword [rdi+NEBO_COMPUTED_VALID],1
 mov qword [rdi+NEBO_COMPUTED_WHY_CHANGED],0
 xor eax,eax
 ret
.invalid_init: mov eax,NEBO_COMPUTED_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_computed_add_dependency
 test rdi,rdi
 jz .invalid_add
 cmp rsi,NEBO_COMPUTED_MAX_DEPENDENCIES
 jae .limit_add
 bts [rdi+NEBO_COMPUTED_DEPENDENCY_MASK],rsi
 xor eax,eax
 ret
.invalid_add: mov eax,NEBO_COMPUTED_STATUS_INVALID
 ret
.limit_add: mov eax,NEBO_COMPUTED_STATUS_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_computed_invalidate
 test rdi,rdi
 jz .invalid_invalidate
 test rsi,rsi
 jz .invalid_invalidate
 mov qword [rdi+NEBO_COMPUTED_VALID],0
 mov [rdi+NEBO_COMPUTED_WHY_CHANGED],rsi
 xor eax,eax
 ret
.invalid_invalidate: mov eax,NEBO_COMPUTED_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_computed_recompute_sum
 ; node, dependency values, count, report
 test rcx,rcx
 jz .invalid_recompute
 mov qword [rcx],0
 mov qword [rcx+8],0
 mov qword [rcx+16],0
 mov qword [rcx+24],0
 test rdi,rdi
 jz .invalid_recompute
 test rsi,rsi
 jz .invalid_recompute
 test rdx,rdx
 jz .invalid_recompute
 cmp rdx,NEBO_COMPUTED_MAX_DEPENDENCIES
 ja .limit_recompute
 cmp qword [rdi+NEBO_COMPUTED_VALID],0
 jne .already_valid
 mov r8,[rdi+NEBO_COMPUTED_DEPENDENCY_MASK]
 xor eax,eax
 xor r9d,r9d
.sum_loop:
 cmp rax,rdx
 jae .sum_done
 bt r8,rax
 jnc .sum_next
 add r9,[rsi+rax*8]
 jo .overflow_recompute
.sum_next: inc rax
 jmp .sum_loop
.sum_done:
 mov rax,[rdi+NEBO_COMPUTED_VALUE]
 mov [rcx+NEBO_COMPUTED_REPORT_OLD_VALUE],rax
 mov [rcx+NEBO_COMPUTED_REPORT_NEW_VALUE],r9
 mov rax,r8
 popcnt rax,rax
 mov [rcx+NEBO_COMPUTED_REPORT_DEPENDENCIES],rax
 mov rax,[rdi+NEBO_COMPUTED_WHY_CHANGED]
 mov [rcx+NEBO_COMPUTED_REPORT_REASON],rax
 mov [rdi+NEBO_COMPUTED_VALUE],r9
 inc qword [rdi+NEBO_COMPUTED_VERSION]
 mov qword [rdi+NEBO_COMPUTED_VALID],1
 mov qword [rdi+NEBO_COMPUTED_WHY_CHANGED],0
 xor eax,eax
 ret
.invalid_recompute: mov eax,NEBO_COMPUTED_STATUS_INVALID
 ret
.limit_recompute: mov eax,NEBO_COMPUTED_STATUS_LIMIT
 ret
.overflow_recompute: mov eax,NEBO_COMPUTED_STATUS_OVERFLOW
 ret
.already_valid: mov eax,NEBO_COMPUTED_STATUS_VALID
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
