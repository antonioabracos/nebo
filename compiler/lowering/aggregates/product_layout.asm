; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F02 checked A0 layout for named products and Tuple values.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/struct_tuple.inc"
%include "compiler/lowering/aggregates/product_layout.inc"

section .text

; layout(request*) -> Status. Empty Tuple is size/alignment 1. Named empty
; structs are rejected by the semantic layer before reaching this algorithm.
NEBOC_ABI_FUNCTION neboc_product_layout
 test rdi,rdi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_LAYOUT_SIZE_OFFSET],0
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_LAYOUT_ALIGN_OFFSET],0
 mov qword [r12+NEBOC_LAYOUT_DROP_COUNT_OFFSET],0
 mov qword [r12+NEBOC_LAYOUT_CLEANUP_HASH_OFFSET],0
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_LAYOUT_DIAGNOSTIC_OFFSET],0
 mov r13,[r12+neboc_option_result_null_externo_e_erros_tipados_LAYOUT_MEMBER_COUNT_OFFSET]
 cmp r13,NEBOC_LAYOUT_MAX_MEMBERS
 ja .bounds
 test r13,r13
 jz .empty
 mov r14,[r12+NEBOC_LAYOUT_SIZES_OFFSET]
 mov r15,[r12+NEBOC_LAYOUT_ALIGNS_OFFSET]
 mov rbx,[r12+NEBOC_LAYOUT_OFFSETS_OFFSET]
 test r14,r14
 jz .invalid
 test r15,r15
 jz .invalid
 test rbx,rbx
 jz .invalid
 mov r10d,1
 xor r9d,r9d
 xor ecx,ecx
.field:
 mov rax,[r15+rcx*8]
 test rax,rax
 jz .alignment
 cmp rax,NEBOC_LAYOUT_MAX_ALIGN
 ja .alignment
 lea rdx,[rax-1]
 test rax,rdx
 jnz .alignment
 cmp rax,r10
 cmova r10,rax
 add r9,rdx
 jc .bounds
 not rdx
 and r9,rdx
 mov [rbx+rcx*8],r9
 mov rax,[r14+rcx*8]
 test rax,rax
 jz .bounds
 add r9,rax
 jc .bounds
 cmp r9,NEBOC_LAYOUT_MAX_SIZE
 ja .bounds
 inc rcx
 cmp rcx,r13
 jb .field
 lea rdx,[r10-1]
 add r9,rdx
 jc .bounds
 not rdx
 and r9,rdx
 cmp r9,NEBOC_LAYOUT_MAX_SIZE
 ja .bounds
 mov [r12+neboc_option_result_null_externo_e_erros_tipados_LAYOUT_SIZE_OFFSET],r9
 mov [r12+neboc_option_result_null_externo_e_erros_tipados_LAYOUT_ALIGN_OFFSET],r10
 mov r14,[r12+NEBOC_LAYOUT_DROP_COUNTS_OFFSET]
 mov r15,14695981039346656037
 mov r8,1099511628211
 xor ecx,ecx
.drops:
 cmp rcx,r13
 jae .success
 xor eax,eax
 test r14,r14
 jz .drop_value
 mov rax,[r14+rcx*8]
.drop_value:
 add [r12+NEBOC_LAYOUT_DROP_COUNT_OFFSET],rax
 jc .bounds
 ; Cleanup is declaration-order ownership, executed in reverse. Hash the
 ; reverse member ordinal and its leaf-drop count without pointer material.
 mov rdx,r13
 sub rdx,rcx
 xor r15,rdx
 imul r15,r8
 xor r15,rax
 imul r15,r8
 inc rcx
 jmp .drops
.empty:
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_LAYOUT_SIZE_OFFSET],1
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_LAYOUT_ALIGN_OFFSET],1
 mov r15,14695981039346656037
.success:
 mov [r12+NEBOC_LAYOUT_CLEANUP_HASH_OFFSET],r15
 xor eax,eax
 jmp .done
.alignment:
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_LAYOUT_DIAGNOSTIC_OFFSET],NEBOC_DIAG_INVALID_ALIGNMENT
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.bounds:
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_LAYOUT_DIAGNOSTIC_OFFSET],NEBOC_DIAG_LAYOUT_OVERFLOW
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; Explicit caller-storage aggregate pass/return bridge. This is a bounded ABI
; operation, not allocation and not an implicit clone.
NEBOC_ABI_FUNCTION neboc_product_pass_return
 test rdi,rdi
 jz .copy_invalid
 test rsi,rsi
 jz .copy_invalid
 cmp rdx,NEBOC_LAYOUT_MAX_SIZE
 ja .copy_limit
 mov rcx,rdx
 rep movsb
 xor eax,eax
 ret
.copy_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.copy_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
