; Nebo Assembly — CONSOLECALL-CONSOLEOPTION-REGISTRY-E-NORMALIZACAO bounded ConsoleOption schema registry
bits 64
default rel
%include "compiler/parser/console_arguments.inc"
%include "runtime/console_options.inc"
%include "runtime/console_option_registry.inc"
global nebo_option_registry_validate
global nebo_option_registry_lookup
global nebo_option_registry_validate_names
global nebo_option_registry_lookup_name
section .text
; rdi=schema entries, rsi=count.
nebo_option_registry_validate:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp rsi, NEBO_OPTION_REGISTRY_MAX
    ja .capacity
    xor r8d, r8d
.entry:
    cmp r8, rsi
    jae .ok
    imul rax, r8, NEBO_OPTION_SCHEMA_SIZE
    lea r9, [rdi + rax]
    mov r10, [r9 + NEBO_OPTION_SCHEMA_KIND_OFFSET]
    cmp r10, NEBO_OPTION_KIND_MIN
    jb .invalid
    cmp r10, NEBO_OPTION_KIND_MAX
    ja .invalid
    mov rax, [r9 + NEBO_OPTION_SCHEMA_MIN_ARGS_OFFSET]
    cmp rax, [r9 + NEBO_OPTION_SCHEMA_MAX_ARGS_OFFSET]
    ja .arity
    cmp qword [r9 + NEBO_OPTION_SCHEMA_MAX_ARGS_OFFSET], NEBOC_MAX_OPTION_ARGUMENTS
    ja .arity
    lea r11, [r8 + 1]
.duplicate:
    cmp r11, rsi
    jae .next
    imul rax, r11, NEBO_OPTION_SCHEMA_SIZE
    cmp r10, [rdi + rax + NEBO_OPTION_SCHEMA_KIND_OFFSET]
    je .duplicate_error
    inc r11
    jmp .duplicate
.next:
    inc r8
    jmp .entry
.ok:
    xor eax, eax
    ret
.capacity:
    mov eax, NEBO_OPTIONS_CAPACITY
    ret
.duplicate_error:
    mov eax, NEBO_OPTION_REGISTRY_DUPLICATE
    ret
.arity:
    mov eax, NEBO_OPTION_REGISTRY_ARITY
    ret
.invalid:
    mov eax, NEBO_OPTIONS_INVALID
    ret
; rdi=entries, rsi=count, rdx=kind, rcx=out schema pointer.
nebo_option_registry_lookup:
    test rcx, rcx
    jz .lookup_invalid
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    call nebo_option_registry_validate
    test eax, eax
    jnz .lookup_done
    xor r8d, r8d
.lookup:
    cmp r8, r12
    jae .not_found
    imul rax, r8, NEBO_OPTION_SCHEMA_SIZE
    lea r9, [rbx + rax]
    cmp r13, [r9 + NEBO_OPTION_SCHEMA_KIND_OFFSET]
    je .found
    inc r8
    jmp .lookup
.found:
    mov [r14], r9
    xor eax, eax
    jmp .lookup_done
.not_found:
    mov eax, NEBO_OPTION_REGISTRY_NOT_FOUND
.lookup_done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.lookup_invalid:
    mov eax, NEBO_OPTIONS_INVALID
    ret

; rdi=entries, rsi=count. Named keys are internal schema metadata.
nebo_option_registry_validate_names:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov rbx, rdi
    mov r12, rsi
    call nebo_option_registry_validate
    test eax, eax
    jnz .names_done
    xor r13d, r13d
.name_outer:
    cmp r13, r12
    jae .names_ok
    imul rax, r13, NEBO_OPTION_SCHEMA_SIZE
    lea r14, [rbx + rax]
    cmp qword [r14 + NEBO_OPTION_SCHEMA_NAME_OFFSET], 0
    je .name_invalid
    mov r15, [r14 + NEBO_OPTION_SCHEMA_NAME_LEN_OFFSET]
    test r15, r15
    jz .name_invalid
    cmp r15, NEBO_OPTION_NAMED_KEY_MAX_BYTES
    ja .name_invalid
    lea r8, [r13 + 1]
.name_pair:
    cmp r8, r12
    jae .name_next
    imul rax, r8, NEBO_OPTION_SCHEMA_SIZE
    lea r9, [rbx + rax]
    cmp r15, [r9 + NEBO_OPTION_SCHEMA_NAME_LEN_OFFSET]
    jne .name_pair_next
    mov r10, [r14 + NEBO_OPTION_SCHEMA_NAME_OFFSET]
    mov r11, [r9 + NEBO_OPTION_SCHEMA_NAME_OFFSET]
    test r11, r11
    jz .name_invalid
    mov rcx, r15
.name_compare:
    mov dl, [r10]
    cmp dl, [r11]
    jne .name_pair_next
    inc r10
    inc r11
    loop .name_compare
    mov eax, NEBO_OPTION_REGISTRY_NAME_DUPLICATE
    jmp .names_done
.name_pair_next:
    inc r8
    jmp .name_pair
.name_next:
    inc r13
    jmp .name_outer
.names_ok:
    xor eax, eax
    jmp .names_done
.name_invalid:
    mov eax, NEBO_OPTION_REGISTRY_NAME_INVALID
.names_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; rdi=entries, rsi=count, rdx=name, rcx=name_len, r8=out schema pointer.
nebo_option_registry_lookup_name:
    test r8, r8
    jz .name_lookup_invalid
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    mov r15, r8
    call nebo_option_registry_validate_names
    test eax, eax
    jnz .name_lookup_done
    test r13, r13
    jz .name_lookup_invalid_saved
    test r14, r14
    jz .name_lookup_invalid_saved
    cmp r14, NEBO_OPTION_NAMED_KEY_MAX_BYTES
    ja .name_lookup_invalid_saved
    xor r8d, r8d
.name_lookup_loop:
    cmp r8, r12
    jae .name_lookup_not_found
    imul rax, r8, NEBO_OPTION_SCHEMA_SIZE
    lea r9, [rbx + rax]
    cmp r14, [r9 + NEBO_OPTION_SCHEMA_NAME_LEN_OFFSET]
    jne .name_lookup_next
    mov r10, [r9 + NEBO_OPTION_SCHEMA_NAME_OFFSET]
    mov r11, r13
    mov rcx, r14
.name_lookup_compare:
    mov dl, [r10]
    cmp dl, [r11]
    jne .name_lookup_next
    inc r10
    inc r11
    loop .name_lookup_compare
    mov [r15], r9
    xor eax, eax
    jmp .name_lookup_done
.name_lookup_next:
    inc r8
    jmp .name_lookup_loop
.name_lookup_not_found:
    mov eax, NEBO_OPTION_REGISTRY_NOT_FOUND
    jmp .name_lookup_done
.name_lookup_invalid_saved:
    mov eax, NEBO_OPTION_REGISTRY_NAME_INVALID
.name_lookup_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.name_lookup_invalid:
    mov eax, NEBO_OPTIONS_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
