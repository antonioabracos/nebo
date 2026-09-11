bits 64
default rel
%include "runtime/protocol/schema.inc"
extern nebo_protocol_define
extern nebo_message_define
extern nebo_field_required
extern nebo_field_optional
extern nebo_field_repeated
extern nebo_message_validate
extern nebo_protocol_compatibility
extern nebo_protocol_reserve_field

section .bss
previous resb NEBO_PROTOCOL_SIZE
current resb NEBO_PROTOCOL_SIZE
fields_old resb nebo_ast_hir_lir_planner_e_otimizacao_FIELD_SIZE*2
fields_new resb nebo_ast_hir_lir_planner_e_otimizacao_FIELD_SIZE*3
reserved resq 8
values resb nebo_ast_hir_lir_planner_e_otimizacao_VALUE_SIZE*3

section .text
global _start
_start:
    lea rdi,[fields_old]
    mov esi,1
    mov edx,1
    call nebo_field_required
    test eax,eax
    jnz fail
    lea rdi,[fields_old+nebo_ast_hir_lir_planner_e_otimizacao_FIELD_SIZE]
    mov esi,2
    mov edx,2
    call nebo_field_optional
    test eax,eax
    jnz fail
    lea rdi,[previous]
    mov esi,1
    lea rdx,[fields_old]
    mov ecx,2
    xor r8d,r8d
    xor r9d,r9d
    call nebo_protocol_define
    test eax,eax
    jnz fail
    lea rdi,[fields_new]
    mov esi,1
    mov edx,1
    call nebo_field_required
    test eax,eax
    jnz fail
    lea rdi,[fields_new+nebo_ast_hir_lir_planner_e_otimizacao_FIELD_SIZE]
    mov esi,2
    mov edx,2
    call nebo_field_optional
    test eax,eax
    jnz fail
    lea rdi,[fields_new+nebo_ast_hir_lir_planner_e_otimizacao_FIELD_SIZE*2]
    mov esi,3
    mov edx,3
    mov ecx,4
    call nebo_field_repeated
    test eax,eax
    jnz fail
    lea rdi,[current]
    mov esi,2
    lea rdx,[fields_new]
    mov ecx,3
    lea r8,[reserved]
    xor r9d,r9d
    call nebo_protocol_define
    test eax,eax
    jnz fail
    lea rdi,[current]
    call nebo_message_define
    test eax,eax
    jnz fail
    lea rdi,[current]
    lea rsi,[previous]
    call nebo_protocol_compatibility
    test eax,eax
    jnz fail
    mov qword [values+NEBO_VALUE_ID],1
    mov qword [values+NEBO_VALUE_TYPE],1
    mov qword [values+NEBO_VALUE_COUNT],1
    mov qword [values+nebo_ast_hir_lir_planner_e_otimizacao_VALUE_SIZE+NEBO_VALUE_ID],3
    mov qword [values+nebo_ast_hir_lir_planner_e_otimizacao_VALUE_SIZE+NEBO_VALUE_TYPE],3
    mov qword [values+nebo_ast_hir_lir_planner_e_otimizacao_VALUE_SIZE+NEBO_VALUE_COUNT],4
    lea rdi,[current]
    lea rsi,[values]
    mov edx,2
    call nebo_message_validate
    test eax,eax
    jnz fail
    mov qword [values+nebo_ast_hir_lir_planner_e_otimizacao_VALUE_SIZE+NEBO_VALUE_COUNT],5
    lea rdi,[current]
    lea rsi,[values]
    mov edx,2
    call nebo_message_validate
    cmp eax,NEBO_LIMIT
    jne fail
    mov qword [values+nebo_ast_hir_lir_planner_e_otimizacao_VALUE_SIZE+NEBO_VALUE_COUNT],4
    mov qword [values+NEBO_VALUE_TYPE],8
    lea rdi,[current]
    lea rsi,[values]
    mov edx,2
    call nebo_message_validate
    cmp eax,NEBO_TYPE_MISMATCH
    jne fail
    mov qword [values+NEBO_VALUE_TYPE],1
    lea rdi,[current]
    mov esi,9
    mov edx,8
    call nebo_protocol_reserve_field
    test eax,eax
    jnz fail
    cmp qword [reserved],9
    jne fail
    lea rdi,[current]
    mov esi,9
    mov edx,8
    call nebo_protocol_reserve_field
    cmp eax,NEBO_DUPLICATE_ID
    jne fail
    ; type evolution must be breaking
    mov qword [fields_new+NEBO_FIELD_TYPE],2
    lea rdi,[current]
    lea rsi,[previous]
    call nebo_protocol_compatibility
    cmp eax,NEBO_BREAKING
    jne fail
    mov qword [fields_new+NEBO_FIELD_TYPE],1
    ; duplicate schema IDs must fail without mutating descriptors
    mov qword [fields_new+nebo_ast_hir_lir_planner_e_otimizacao_FIELD_SIZE+NEBO_FIELD_ID],1
    lea rdi,[current]
    call nebo_message_define
    cmp eax,NEBO_DUPLICATE_ID
    jne fail
    xor edi,edi
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
