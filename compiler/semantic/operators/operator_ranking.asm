; Deterministic constrained-candidate ranking. Equal best ranks are ambiguity,
; never source-order tie breaking.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/operators/operator_protocol.inc"

section .text
; rank_candidates(candidates, count, out_index*) -> status, EDX diagnostic.
; out_index is changed only for a unique best admissible candidate.
NEBOC_ABI_FUNCTION neboc_operator_rank_candidates
 test rdi,rdi
 jz .invalid_argument
 test rdx,rdx
 jz .invalid_argument
 test rsi,rsi
 jz .no_candidate
 cmp rsi,NEBOC_OPERATOR_MAX_CANDIDATES
 ja .limit
 xor r8d,r8d
 xor r9d,r9d
 xor r10d,r10d
 xor r11d,r11d
.loop:
 cmp r8,rsi
 jae .done_scan
 mov rax,r8
 imul rax,NEBOC_OPERATOR_IMPL_SIZE
 add rax,rdi
 cmp qword [rax+NEBOC_OPERATOR_IMPL_CONSTRAINTS_OFFSET],NEBOC_OPERATOR_MAX_CONSTRAINTS
 ja .limit
 mov rcx,[rax+NEBOC_OPERATOR_IMPL_FLAGS_OFFSET]
 test rcx,NEBOC_OPERATOR_IMPL_FLAG_ACTIVE
 jz .next
 test rcx,NEBOC_OPERATOR_IMPL_FLAG_INACTIVE
 jnz .next
 test rcx,NEBOC_OPERATOR_IMPL_FLAG_EXACT_TYPES
 jz .next
 mov rcx,[rax+NEBOC_OPERATOR_IMPL_SPECIFICITY_OFFSET]
 test r11d,r11d
 jz .new_best
 cmp rcx,r9
 ja .new_best
 jne .next
 inc r11d
 jmp .next
.new_best:
 mov r9,rcx
 mov r10,r8
 mov r11d,1
.next:
 inc r8
 jmp .loop
.done_scan:
 test r11d,r11d
 jz .no_candidate
 cmp r11d,1
 jne .ambiguous
 mov [rdx],r10
 xor eax,eax
 xor edx,edx
 ret
.ambiguous:
 mov edx,NEBOC_OPERATOR_DIAG_AMBIGUOUS_CANDIDATE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.no_candidate:
 mov edx,NEBOC_OPERATOR_DIAG_NO_EXACT_CANDIDATE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.limit:
 mov edx,NEBOC_OPERATOR_DIAG_LIMIT_EXCEEDED
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid_argument:
 xor edx,edx
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
