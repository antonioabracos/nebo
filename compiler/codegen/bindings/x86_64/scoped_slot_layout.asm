; LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-F03 deterministic slots for outer and first-depth branch locals
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/binding_definite_assignment_contract.inc"
%include "compiler/semantic/bindings/binding_vertical.inc"
%include "compiler/codegen/bindings/x86_64/binding_codegen.inc"

section .text

; request* -> assign distinct stable offsets across main, then and else tables.
NEBOC_ABI_FUNCTION neboc_scoped_slots_assign
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 test r12,r12
 jz .invalid
 xor r13d,r13d                 ; current raw frame extent
 xor r14d,r14d
.main_loop:
 cmp r14,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET]
 jae .branch_a
 mov rax,r14
 imul rax,NEBOC_SYMBOL_RECORD_SIZE
 mov rbx,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET]
 add rbx,rax
 mov rdi,rbx
 mov rsi,r13
 call scoped_slot_assign_record
 cmp rax,-1
 je .bad
 mov r13,rax
 mov rcx,[rbx+NEBOC_SYMBOL_SLOT_OFFSET]
 mov rdx,[r12+NEBOC_CODEGEN_BRANCH_A_OFFSET]
 test rdx,rdx
 jz .copy_b
 mov rax,r14
 imul rax,NEBOC_SYMBOL_RECORD_SIZE
 mov [rdx+rax+NEBOC_SYMBOL_SLOT_OFFSET],rcx
.copy_b:
 mov rdx,[r12+NEBOC_CODEGEN_BRANCH_B_OFFSET]
 test rdx,rdx
 jz .main_next
 mov rax,r14
 imul rax,NEBOC_SYMBOL_RECORD_SIZE
 mov [rdx+rax+NEBOC_SYMBOL_SLOT_OFFSET],rcx
.main_next:
 inc r14
 jmp .main_loop
.branch_a:
 mov r14,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET]
.branch_a_loop:
 cmp r14,[r12+NEBOC_CODEGEN_BRANCH_A_COUNT_OFFSET]
 jae .branch_b
 mov rax,r14
 imul rax,NEBOC_SYMBOL_RECORD_SIZE
 add rax,[r12+NEBOC_CODEGEN_BRANCH_A_OFFSET]
 mov rdi,rax
 mov rsi,r13
 call scoped_slot_assign_record
 cmp rax,-1
 je .bad
 mov r13,rax
 inc r14
 jmp .branch_a_loop
.branch_b:
 mov r14,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET]
.branch_b_loop:
 cmp r14,[r12+NEBOC_CODEGEN_BRANCH_B_COUNT_OFFSET]
 jae .finish
 mov rax,r14
 imul rax,NEBOC_SYMBOL_RECORD_SIZE
 add rax,[r12+NEBOC_CODEGEN_BRANCH_B_OFFSET]
 mov rdi,rax
 mov rsi,r13
 call scoped_slot_assign_record
 cmp rax,-1
 je .bad
 mov r13,rax
 inc r14
 jmp .branch_b_loop
.finish:
 mov rax,r13
 add rax,15
 and rax,-16
 test rax,rax
 jnz .store
 mov eax,16
.store:
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_FRAME_SIZE_OFFSET],rax
 xor eax,eax
 jmp .done
.bad:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_SYMBOL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; record*, current extent -> new extent, or -1 for an unsupported type.
scoped_slot_assign_record:
 mov rax,[rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_TYPE_OFFSET]
 cmp rax,NEBOC_BIND_TYPE_BOOL
 je .size1
 cmp rax,NEBOC_BIND_TYPE_CHAR
 je .size4
 cmp rax,NEBOC_BIND_TYPE_INT
 je .size8
 cmp rax,NEBOC_BIND_TYPE_FLOAT
 je .size8
 cmp rax,NEBOC_BIND_TYPE_TEXT
 je .size8
 cmp rax,NEBOC_BIND_TYPE_CONSOLE
 je .size8
 cmp rax,NEBOC_BIND_TYPE_BYTES
 je .size8
 mov rax,-1
 ret
.size1:
 mov ecx,1
 mov edx,1
 jmp .place
.size4:
 mov ecx,4
 mov edx,4
 jmp .place
.size8:
 mov ecx,8
 mov edx,8
.place:
 mov rax,rsi
 add rax,rdx
 dec rcx
 add rax,rcx
 not rcx
 and rax,rcx
 mov [rdi+NEBOC_SYMBOL_SLOT_OFFSET],rax
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
