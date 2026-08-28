; LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-F03 deterministic slots for outer and first-depth branch locals
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/binding_definite_assignment_contract.inc"
%include "compiler/semantic/bindings/binding_vertical.inc"
%include "compiler/codegen/bindings/x86_64/binding_codegen.inc"

section .text

; request* -> assign one stable slot per source declaration across the main
; table and every persistent branch/loop body snapshot. Copies of an existing
; declaration reuse its slot; simultaneously live distinct declarations do not.
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
 cmp qword [r12+NEBOC_CODEGEN_SLOT_CATALOG_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_CODEGEN_SLOT_CATALOG_CAPACITY_OFFSET],0
 je .invalid
 mov qword [r12+NEBOC_CODEGEN_SLOT_CATALOG_COUNT_OFFSET],0
 xor r13d,r13d                 ; current raw frame extent
 mov rdi,r12
 mov rsi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET]
 mov rdx,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET]
 mov rcx,r13
 call scoped_slot_assign_table
 cmp rax,-1
 je .bad
 mov r13,rax
 cmp qword [r12+NEBOC_CODEGEN_BRANCH_A_COUNTS_OFFSET],0
 je .legacy
 cmp qword [r12+NEBOC_CODEGEN_BRANCH_B_COUNTS_OFFSET],0
 je .legacy
 xor r14d,r14d
.snapshot_loop:
 cmp r14,[r12+NEBOC_CODEGEN_BRANCH_SNAPSHOT_COUNT_OFFSET]
 jae .loop_catalog
 mov rax,NEBOC_VERTICAL_BRANCH_SNAPSHOT_BYTES
 imul rax,r14
 mov rsi,[r12+NEBOC_CODEGEN_BRANCH_A_OFFSET]
 add rsi,rax
 mov rdx,[r12+NEBOC_CODEGEN_BRANCH_A_COUNTS_OFFSET]
 mov rdx,[rdx+r14*8]
 mov rdi,r12
 mov rcx,r13
 call scoped_slot_assign_table
 cmp rax,-1
 je .bad
 mov r13,rax
 mov rax,NEBOC_VERTICAL_BRANCH_SNAPSHOT_BYTES
 imul rax,r14
 mov rsi,[r12+NEBOC_CODEGEN_BRANCH_B_OFFSET]
 add rsi,rax
 mov rdx,[r12+NEBOC_CODEGEN_BRANCH_B_COUNTS_OFFSET]
 mov rdx,[rdx+r14*8]
 mov rdi,r12
 mov rcx,r13
 call scoped_slot_assign_table
 cmp rax,-1
 je .bad
 mov r13,rax
 inc r14
 jmp .snapshot_loop
.legacy:
 mov rdi,r12
 mov rsi,[r12+NEBOC_CODEGEN_BRANCH_A_OFFSET]
 mov rdx,[r12+NEBOC_CODEGEN_BRANCH_A_COUNT_OFFSET]
 mov rcx,r13
 call scoped_slot_assign_table
 cmp rax,-1
 je .bad
 mov r13,rax
 mov rdi,r12
 mov rsi,[r12+NEBOC_CODEGEN_BRANCH_B_OFFSET]
 mov rdx,[r12+NEBOC_CODEGEN_BRANCH_B_COUNT_OFFSET]
 mov rcx,r13
 call scoped_slot_assign_table
 cmp rax,-1
 je .bad
 mov r13,rax
.loop_catalog:
 cmp qword [r12+NEBOC_CODEGEN_LOOP_BODIES_OFFSET],0
 je .finish
 cmp qword [r12+NEBOC_CODEGEN_LOOP_BODY_COUNTS_OFFSET],0
 je .finish
 xor r14d,r14d
.loop_snapshot:
 cmp r14,[r12+NEBOC_CODEGEN_LOOP_SNAPSHOT_COUNT_OFFSET]
 jae .finish
 mov rax,NEBOC_VERTICAL_LOOP_SNAPSHOT_BYTES
 imul rax,r14
 mov rsi,[r12+NEBOC_CODEGEN_LOOP_BODIES_OFFSET]
 add rsi,rax
 mov rdx,[r12+NEBOC_CODEGEN_LOOP_BODY_COUNTS_OFFSET]
 mov rdx,[rdx+r14*8]
 mov rdi,r12
 mov rcx,r13
 call scoped_slot_assign_table
 cmp rax,-1
 je .bad
 mov r13,rax
 inc r14
 jmp .loop_snapshot
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

; request*, table*, count, current extent -> new extent or -1.
scoped_slot_assign_table:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 xor ebx,ebx
.loop:
 cmp rbx,r14
 jae .ok
 mov rax,rbx
 imul rax,NEBOC_SYMBOL_RECORD_SIZE
 add rax,r13
 mov rdi,r12
 mov rsi,rax
 mov rdx,r15
 call scoped_slot_assign_or_reuse
 cmp rax,-1
 je .done
 mov r15,rax
 inc rbx
 jmp .loop
.ok:
 mov rax,r15
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, record*, current extent -> new extent or -1. Declaration source
; positions are stable identities shared by copied semantic records.
scoped_slot_assign_or_reuse:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,[r13+NEBOC_SYMBOL_DECL_START_OFFSET]
 xor ebx,ebx
.find:
 cmp rbx,[r12+NEBOC_CODEGEN_SLOT_CATALOG_COUNT_OFFSET]
 jae .new
 mov rax,rbx
 imul rax,NEBOC_CODEGEN_SLOT_CATALOG_RECORD_SIZE
 add rax,[r12+NEBOC_CODEGEN_SLOT_CATALOG_OFFSET]
 cmp r15,[rax+NEBOC_CODEGEN_SLOT_CATALOG_DECL_OFFSET]
 je .reuse
 inc rbx
 jmp .find
.reuse:
 mov rax,[rax+NEBOC_CODEGEN_SLOT_CATALOG_SLOT_OFFSET]
 mov [r13+NEBOC_SYMBOL_SLOT_OFFSET],rax
 mov rax,r14
 jmp .done
.new:
 cmp rbx,[r12+NEBOC_CODEGEN_SLOT_CATALOG_CAPACITY_OFFSET]
 jae .bad
 mov rdi,r13
 mov rsi,r14
 call scoped_slot_assign_record
 cmp rax,-1
 je .done
 mov [rsp],rax
 mov rdx,rbx
 imul rdx,NEBOC_CODEGEN_SLOT_CATALOG_RECORD_SIZE
 add rdx,[r12+NEBOC_CODEGEN_SLOT_CATALOG_OFFSET]
 mov [rdx+NEBOC_CODEGEN_SLOT_CATALOG_DECL_OFFSET],r15
 mov rcx,[r13+NEBOC_SYMBOL_SLOT_OFFSET]
 mov [rdx+NEBOC_CODEGEN_SLOT_CATALOG_SLOT_OFFSET],rcx
 inc qword [r12+NEBOC_CODEGEN_SLOT_CATALOG_COUNT_OFFSET]
 mov rax,[rsp]
 jmp .done
.bad:
 mov rax,-1
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
