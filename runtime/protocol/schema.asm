; AST-HIR-LIR-PLANNER-E-OTIMIZACAO-F01: bounded versioned schemas and compatibility.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/protocol/schema.inc"

section .text

; rdi=protocol, rsi=version, rdx=fields, rcx=field_count,
; r8=reserved ids, r9=reserved_count
NEBOC_ABI_FUNCTION nebo_protocol_define
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp rcx,NEBO_MAX_FIELDS
    ja .limit
    test rcx,rcx
    jz .fields_ok
    test rdx,rdx
    jz .invalid
.fields_ok:
    cmp r9,NEBO_MAX_FIELDS
    ja .limit
    test r9,r9
    jz .reserved_ok
    test r8,r8
    jz .invalid
.reserved_ok:
    mov [rdi+nebo_ast_hir_lir_planner_e_otimizacao_PROTOCOL_VERSION],rsi
    mov [rdi+NEBO_PROTOCOL_FIELD_COUNT],rcx
    mov [rdi+NEBO_PROTOCOL_FIELDS],rdx
    mov [rdi+NEBO_PROTOCOL_RESERVED_COUNT],r9
    mov [rdi+NEBO_PROTOCOL_RESERVED],r8
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.limit:
    mov eax,NEBO_LIMIT
    ret

; Message.define uses the same bounded descriptor validation contract.
NEBOC_ABI_FUNCTION nebo_message_define
    jmp nebo_protocol_validate_schema

; rdi=field, rsi=id, rdx=type
NEBOC_ABI_FUNCTION nebo_field_required
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    cmp rdx,8
    ja .invalid
    mov [rdi+NEBO_FIELD_ID],rsi
    mov [rdi+NEBO_FIELD_TYPE],rdx
    mov qword [rdi+NEBO_FIELD_FLAGS],NEBO_FIELD_REQUIRED
    mov qword [rdi+NEBO_FIELD_LIMIT],1
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret

; rdi=field, rsi=id, rdx=type
NEBOC_ABI_FUNCTION nebo_field_optional
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    cmp rdx,8
    ja .invalid
    mov [rdi+NEBO_FIELD_ID],rsi
    mov [rdi+NEBO_FIELD_TYPE],rdx
    mov qword [rdi+NEBO_FIELD_FLAGS],0
    mov qword [rdi+NEBO_FIELD_LIMIT],1
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret

; rdi=field, rsi=id, rdx=type, rcx=limit
NEBOC_ABI_FUNCTION nebo_field_repeated
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    cmp rdx,8
    ja .invalid
    test rcx,rcx
    jz .limit
    cmp rcx,NEBO_MAX_REPEATED
    ja .limit
    mov [rdi+NEBO_FIELD_ID],rsi
    mov [rdi+NEBO_FIELD_TYPE],rdx
    mov qword [rdi+NEBO_FIELD_FLAGS],NEBO_FIELD_REPEATED
    mov [rdi+NEBO_FIELD_LIMIT],rcx
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.limit:
    mov eax,NEBO_LIMIT
    ret

; rdi=protocol
NEBOC_ABI_FUNCTION nebo_protocol_validate_schema
    test rdi,rdi
    jz .invalid
    cmp qword [rdi+nebo_ast_hir_lir_planner_e_otimizacao_PROTOCOL_VERSION],0
    je .invalid
    mov r8,[rdi+NEBO_PROTOCOL_FIELD_COUNT]
    cmp r8,NEBO_MAX_FIELDS
    ja .limit
    mov r9,[rdi+NEBO_PROTOCOL_FIELDS]
    test r8,r8
    jz .reserved_header
    test r9,r9
    jz .invalid
    xor ecx,ecx
.field_loop:
    cmp rcx,r8
    jae .reserved_header
    mov r10,rcx
    shl r10,5
    add r10,r9
    mov rax,[r10+NEBO_FIELD_ID]
    test rax,rax
    jz .invalid
    mov rdx,[r10+NEBO_FIELD_TYPE]
    test rdx,rdx
    jz .invalid
    cmp rdx,8
    ja .invalid
    mov rdx,[r10+NEBO_FIELD_FLAGS]
    test rdx,~(NEBO_FIELD_REQUIRED|NEBO_FIELD_REPEATED)
    jnz .invalid
    test rdx,NEBO_FIELD_REPEATED
    jz .single_limit
    cmp qword [r10+NEBO_FIELD_LIMIT],0
    je .limit
    cmp qword [r10+NEBO_FIELD_LIMIT],NEBO_MAX_REPEATED
    ja .limit
    jmp .duplicate_scan
.single_limit:
    cmp qword [r10+NEBO_FIELD_LIMIT],1
    jne .invalid
.duplicate_scan:
    mov r11,rcx
    inc r11
.duplicate_loop:
    cmp r11,r8
    jae .check_reserved_use
    mov rdx,r11
    shl rdx,5
    cmp rax,[r9+rdx+NEBO_FIELD_ID]
    je .duplicate
    inc r11
    jmp .duplicate_loop
.check_reserved_use:
    mov r11,[rdi+NEBO_PROTOCOL_RESERVED_COUNT]
    mov rdx,[rdi+NEBO_PROTOCOL_RESERVED]
    xor esi,esi
.reserved_use_loop:
    cmp rsi,r11
    jae .next_field
    cmp rax,[rdx+rsi*8]
    je .reserved
    inc rsi
    jmp .reserved_use_loop
.next_field:
    inc rcx
    jmp .field_loop
.reserved_header:
    mov r8,[rdi+NEBO_PROTOCOL_RESERVED_COUNT]
    cmp r8,NEBO_MAX_FIELDS
    ja .limit
    mov r9,[rdi+NEBO_PROTOCOL_RESERVED]
    test r8,r8
    jz .ok
    test r9,r9
    jz .invalid
    xor ecx,ecx
.reserved_outer:
    cmp rcx,r8
    jae .ok
    mov rax,[r9+rcx*8]
    test rax,rax
    jz .invalid
    mov rdx,rcx
    inc rdx
.reserved_inner:
    cmp rdx,r8
    jae .reserved_next
    cmp rax,[r9+rdx*8]
    je .duplicate
    inc rdx
    jmp .reserved_inner
.reserved_next:
    inc rcx
    jmp .reserved_outer
.ok:
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.limit:
    mov eax,NEBO_LIMIT
    ret
.duplicate:
    mov eax,NEBO_DUPLICATE_ID
    ret
.reserved:
    mov eax,NEBO_RESERVED_ID
    ret

; rdi=protocol, rsi=values, rdx=value_count
NEBOC_ABI_FUNCTION nebo_message_validate
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    call nebo_protocol_validate_schema
    test eax,eax
    jnz .done
    cmp r14,NEBO_MAX_FIELDS
    ja .limit
    test r14,r14
    jz .required_scan
    test r13,r13
    jz .invalid
    xor r15d,r15d
.value_loop:
    cmp r15,r14
    jae .required_scan
    mov r8,r15
    shl r8,5
    add r8,r13
    mov rax,[r8+NEBO_VALUE_ID]
    test rax,rax
    jz .invalid
    mov rcx,r15
    inc rcx
.value_dup:
    cmp rcx,r14
    jae .find_field
    mov rdx,rcx
    shl rdx,5
    cmp rax,[r13+rdx+NEBO_VALUE_ID]
    je .duplicate
    inc rcx
    jmp .value_dup
.find_field:
    mov rcx,[r12+NEBO_PROTOCOL_FIELD_COUNT]
    mov r9,[r12+NEBO_PROTOCOL_FIELDS]
    xor edx,edx
.field_find_loop:
    cmp rdx,rcx
    jae .not_found
    mov r10,rdx
    shl r10,5
    add r10,r9
    cmp rax,[r10+NEBO_FIELD_ID]
    je .found
    inc rdx
    jmp .field_find_loop
.found:
    mov r11,[r8+NEBO_VALUE_TYPE]
    cmp r11,[r10+NEBO_FIELD_TYPE]
    jne .type_mismatch
    mov r11,[r8+NEBO_VALUE_COUNT]
    test r11,r11
    jz .limit
    mov rax,[r10+NEBO_FIELD_FLAGS]
    test rax,NEBO_FIELD_REPEATED
    jnz .repeated_value
    cmp r11,1
    jne .limit
    jmp .value_next
.repeated_value:
    cmp r11,[r10+NEBO_FIELD_LIMIT]
    ja .limit
.value_next:
    inc r15
    jmp .value_loop
.required_scan:
    mov rcx,[r12+NEBO_PROTOCOL_FIELD_COUNT]
    mov r9,[r12+NEBO_PROTOCOL_FIELDS]
    xor edx,edx
.required_loop:
    cmp rdx,rcx
    jae .ok
    mov r10,rdx
    shl r10,5
    add r10,r9
    test qword [r10+NEBO_FIELD_FLAGS],NEBO_FIELD_REQUIRED
    jz .required_next
    mov rax,[r10+NEBO_FIELD_ID]
    xor r8d,r8d
.required_value_loop:
    cmp r8,r14
    jae .not_found
    mov r11,r8
    shl r11,5
    cmp rax,[r13+r11+NEBO_VALUE_ID]
    je .required_next
    inc r8
    jmp .required_value_loop
.required_next:
    inc rdx
    jmp .required_loop
.ok:
    xor eax,eax
    jmp .done
.invalid:
    mov eax,NEBO_INVALID
    jmp .done
.limit:
    mov eax,NEBO_LIMIT
    jmp .done
.duplicate:
    mov eax,NEBO_DUPLICATE_ID
    jmp .done
.not_found:
    mov eax,NEBO_NOT_FOUND
    jmp .done
.type_mismatch:
    mov eax,NEBO_TYPE_MISMATCH
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

; rdi=current protocol, rsi=previous protocol
NEBOC_ABI_FUNCTION nebo_protocol_compatibility
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    call nebo_protocol_validate_schema
    test eax,eax
    jnz .done
    mov rdi,r13
    call nebo_protocol_validate_schema
    test eax,eax
    jnz .done
    mov r14,[r13+NEBO_PROTOCOL_FIELD_COUNT]
    xor r15d,r15d
.previous_loop:
    cmp r15,r14
    jae .new_required_scan
    mov r8,r15
    shl r8,5
    add r8,[r13+NEBO_PROTOCOL_FIELDS]
    mov rax,[r8+NEBO_FIELD_ID]
    mov rcx,[r12+NEBO_PROTOCOL_FIELD_COUNT]
    mov r9,[r12+NEBO_PROTOCOL_FIELDS]
    xor edx,edx
.current_find:
    cmp rdx,rcx
    jae .missing_previous
    mov r10,rdx
    shl r10,5
    add r10,r9
    cmp rax,[r10+NEBO_FIELD_ID]
    je .compare_field
    inc rdx
    jmp .current_find
.missing_previous:
    test qword [r8+NEBO_FIELD_FLAGS],NEBO_FIELD_REQUIRED
    jnz .breaking
    mov rcx,[r12+NEBO_PROTOCOL_RESERVED_COUNT]
    mov r9,[r12+NEBO_PROTOCOL_RESERVED]
    xor edx,edx
.removed_reserved:
    cmp rdx,rcx
    jae .breaking
    cmp rax,[r9+rdx*8]
    je .previous_next
    inc rdx
    jmp .removed_reserved
.compare_field:
    mov rax,[r8+NEBO_FIELD_TYPE]
    cmp rax,[r10+NEBO_FIELD_TYPE]
    jne .breaking
    mov rax,[r8+NEBO_FIELD_FLAGS]
    mov rdx,[r10+NEBO_FIELD_FLAGS]
    test rax,NEBO_FIELD_REQUIRED
    jnz .required_unchanged
    test rdx,NEBO_FIELD_REQUIRED
    jnz .breaking
.required_unchanged:
    test rax,NEBO_FIELD_REPEATED
    jz .previous_next
    test rdx,NEBO_FIELD_REPEATED
    jz .breaking
    mov rax,[r8+NEBO_FIELD_LIMIT]
    cmp [r10+NEBO_FIELD_LIMIT],rax
    jb .breaking
.previous_next:
    inc r15
    jmp .previous_loop
.new_required_scan:
    mov r14,[r12+NEBO_PROTOCOL_FIELD_COUNT]
    xor r15d,r15d
.new_loop:
    cmp r15,r14
    jae .ok
    mov r8,r15
    shl r8,5
    add r8,[r12+NEBO_PROTOCOL_FIELDS]
    test qword [r8+NEBO_FIELD_FLAGS],NEBO_FIELD_REQUIRED
    jz .new_next
    mov rax,[r8+NEBO_FIELD_ID]
    mov rcx,[r13+NEBO_PROTOCOL_FIELD_COUNT]
    mov r9,[r13+NEBO_PROTOCOL_FIELDS]
    xor edx,edx
.old_find:
    cmp rdx,rcx
    jae .breaking
    mov r10,rdx
    shl r10,5
    cmp rax,[r9+r10+NEBO_FIELD_ID]
    je .new_next
    inc rdx
    jmp .old_find
.new_next:
    inc r15
    jmp .new_loop
.ok:
    xor eax,eax
    jmp .done
.breaking:
    mov eax,NEBO_BREAKING
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

; rdi=protocol, rsi=id, rdx=reserved capacity
NEBOC_ABI_FUNCTION nebo_protocol_reserve_field
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp rdx,NEBO_MAX_FIELDS
    ja .limit
    mov r8,[rdi+NEBO_PROTOCOL_RESERVED_COUNT]
    cmp r8,rdx
    jae .limit
    mov r9,[rdi+NEBO_PROTOCOL_RESERVED]
    test r9,r9
    jz .invalid
    mov rcx,[rdi+NEBO_PROTOCOL_FIELD_COUNT]
    mov r10,[rdi+NEBO_PROTOCOL_FIELDS]
    xor eax,eax
.field_scan:
    cmp rax,rcx
    jae .reserved_scan
    mov r11,rax
    shl r11,5
    cmp rsi,[r10+r11+NEBO_FIELD_ID]
    je .duplicate
    inc rax
    jmp .field_scan
.reserved_scan:
    xor eax,eax
.reserved_loop:
    cmp rax,r8
    jae .append
    cmp rsi,[r9+rax*8]
    je .duplicate
    inc rax
    jmp .reserved_loop
.append:
    mov [r9+r8*8],rsi
    inc r8
    mov [rdi+NEBO_PROTOCOL_RESERVED_COUNT],r8
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.limit:
    mov eax,NEBO_LIMIT
    ret
.duplicate:
    mov eax,NEBO_DUPLICATE_ID
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
