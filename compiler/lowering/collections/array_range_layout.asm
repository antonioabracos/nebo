; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F03 checked A0 Array layout and non-iterating Range length helpers.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/array_range.inc"
%include "compiler/lowering/collections/array_range_layout.inc"

section .text

NEBOC_ABI_FUNCTION neboc_option_result_null_externo_e_erros_tipados_array_layout
 test rdi,rdi
 jz .invalid_argument
 test rdi,7
 jnz .invalid_argument
 mov qword [rdi+neboc_option_result_null_externo_e_erros_tipados_ARRAY_LAYOUT_STRIDE_OFFSET],0
 mov qword [rdi+NEBOC_ARRAY_LAYOUT_TOTAL_SIZE_OFFSET],0
 mov qword [rdi+neboc_option_result_null_externo_e_erros_tipados_ARRAY_LAYOUT_DIAGNOSTIC_OFFSET],0
 mov rax,[rdi+neboc_option_result_null_externo_e_erros_tipados_ARRAY_LAYOUT_ELEMENT_SIZE_OFFSET]
 test rax,rax
 jz .alignment
 mov rcx,[rdi+NEBOC_ARRAY_LAYOUT_ELEMENT_ALIGN_OFFSET]
 test rcx,rcx
 jz .alignment
 mov rdx,rcx
 dec rdx
 test rcx,rdx
 jnz .alignment
 cmp rcx,4096
 ja .alignment
 add rax,rdx
 jc .overflow
 not rdx
 and rax,rdx
 mov [rdi+neboc_option_result_null_externo_e_erros_tipados_ARRAY_LAYOUT_STRIDE_OFFSET],rax
 mov rcx,[rdi+NEBOC_ARRAY_LAYOUT_LENGTH_OFFSET]
 cmp rcx,NEBOC_AR_MAX_LENGTH
 ja .length
 mul rcx
 test rdx,rdx
 jnz .overflow
 cmp rax,NEBOC_AR_MAX_LAYOUT
 ja .overflow
.store:
 mov [rdi+NEBOC_ARRAY_LAYOUT_TOTAL_SIZE_OFFSET],rax
 xor eax,eax
 ret
.alignment:
 mov qword [rdi+neboc_option_result_null_externo_e_erros_tipados_ARRAY_LAYOUT_DIAGNOSTIC_OFFSET],2
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.length:
 mov qword [rdi+neboc_option_result_null_externo_e_erros_tipados_ARRAY_LAYOUT_DIAGNOSTIC_OFFSET],NEBOC_AR_DIAG_CONST_LENGTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.overflow:
 mov qword [rdi+neboc_option_result_null_externo_e_erros_tipados_ARRAY_LAYOUT_DIAGNOSTIC_OFFSET],3
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid_argument:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION neboc_range_length
 test rdi,rdi
 jz .invalid_argument
 test rdi,7
 jnz .invalid_argument
 mov qword [rdi+NEBOC_RANGE_LENGTH_OFFSET],0
 mov qword [rdi+NEBOC_RANGE_DIAGNOSTIC_OFFSET],0
 mov r8,[rdi+NEBOC_ARRAY_RANGE_LAYOUT_RANGE_START_OFFSET]
 mov r9,[rdi+NEBOC_ARRAY_RANGE_LAYOUT_RANGE_END_OFFSET]
 mov r10,[rdi+NEBOC_ARRAY_RANGE_LAYOUT_RANGE_STEP_OFFSET]
 test r10,r10
 jz .range
 cmp r8,r9
 je .equal
 jl .ascending
 test r10,r10
 jns .range
 mov rax,r8
 sub rax,r9
 jo .range
 mov rcx,r10
 neg rcx
 jo .range
 jmp .divide
.ascending:
 test r10,r10
 jle .range
 mov rax,r9
 sub rax,r8
 jo .range
 mov rcx,r10
.divide:
 xor edx,edx
 div rcx
 test qword [rdi+NEBOC_RANGE_FLAGS_OFFSET],NEBOC_AR_RANGE_INCLUSIVE
 jnz .inclusive
 test rdx,rdx
 jz .store
 inc rax
 jo .range
 jmp .store
.inclusive:
 inc rax
 jo .range
 jmp .store
.equal:
 xor eax,eax
 test qword [rdi+NEBOC_RANGE_FLAGS_OFFSET],NEBOC_AR_RANGE_INCLUSIVE
 jz .store
 inc eax
.store:
 mov [rdi+NEBOC_RANGE_LENGTH_OFFSET],rax
 xor eax,eax
 ret
.range:
 mov qword [rdi+NEBOC_RANGE_DIAGNOSTIC_OFFSET],NEBOC_AR_DIAG_RANGE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid_argument:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
