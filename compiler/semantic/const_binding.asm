; Nebo Assembly — CONSTBINDING-POR-ALL-CAPS-E-IDENTIDADE-DE-NOMES stable ConstBinding symbol resolution
bits 64
default rel

%include "compiler/semantic/name_style.inc"
%include "compiler/semantic/const_binding.inc"

extern neboc_name_style_classify
global neboc_const_symbol_resolve
global neboc_const_validate_action
global neboc_const_check_visible_collision

section .text

; rdi=name, rsi=length, rdx=stable lexical scope id, rcx=out symbol record
; eax=status. Output is not touched on failure.
neboc_const_symbol_resolve:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    test rcx, rcx
    jz .invalid
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov rbx, rcx
    call neboc_name_style_classify
    cmp eax, NEBOC_NAME_ALL_CAPS
    jne .not_caps

    ; FNV-1a over spelling followed by the explicit lexical scope id.
    mov rax, 0xcbf29ce484222325
    mov r8, 0x100000001b3
    xor ecx, ecx
.hash_name:
    cmp rcx, r13
    jae .hash_scope
    movzx edx, byte [r12 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .hash_name
.hash_scope:
    xor rax, r14
    imul rax, r8
    test rax, rax
    jnz .commit
    mov rax, 1                       ; reserve zero as invalid SymbolId
.commit:
    mov [rbx + NEBOC_CONST_SYMBOL_ID_OFFSET], rax
    mov [rbx + NEBOC_CONST_SYMBOL_NAME_OFFSET], r12
    mov [rbx + NEBOC_CONST_SYMBOL_NAME_LENGTH_OFFSET], r13
    mov qword [rbx + NEBOC_CONST_SYMBOL_KIND_OFFSET], NEBOC_BINDING_KIND_CONST
    mov qword [rbx + NEBOC_CONST_SYMBOL_FLAGS_OFFSET], \
        NEBOC_CONST_FLAG_IMMUTABLE | NEBOC_CONST_FLAG_STABLE_SYMBOL_ID
    xor eax, eax
    jmp .done
.not_caps:
    mov eax, NEBOC_CONST_NAME_NOT_ALL_CAPS
.done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.invalid:
    mov eax, NEBOC_CONST_INVALID_ARGUMENT
    ret

; rdi=const symbol, rsi=NEBOC_RF116_CONST_ACTION_*. Pure check.
neboc_const_validate_action:
    test rdi, rdi
    jz .action_invalid
    cmp qword [rdi + NEBOC_CONST_SYMBOL_KIND_OFFSET], NEBOC_BINDING_KIND_CONST
    jne .action_invalid
    cmp esi, NEBOC_CONST_ACTION_READ
    je .action_ok
    cmp esi, NEBOC_CONST_ACTION_WRITE
    je .action_write
    cmp esi, NEBOC_CONST_ACTION_MARK_MUTABLE
    je .action_write
    cmp esi, NEBOC_CONST_ACTION_SHADOW
    je .action_shadow
.action_invalid:
    mov eax, NEBOC_CONST_INVALID_ARGUMENT
    ret
.action_write:
    mov eax, NEBOC_CONST_WRITE_FORBIDDEN
    ret
.action_shadow:
    mov eax, NEBOC_CONST_SHADOW_FORBIDDEN
    ret
.action_ok:
    xor eax, eax
    ret

; rdi=visible contiguous symbol records, rsi=count, rdx=candidate record.
; Name equality is checked rather than a hash alone, so collisions cannot
; create false identity. Returns SHADOW_FORBIDDEN on the first equal spelling.
neboc_const_check_visible_collision:
    test rdx, rdx
    jz .collision_invalid
    test rsi, rsi
    jz .collision_clear
    test rdi, rdi
    jz .collision_invalid
    cmp rsi, NEBOC_CONST_MAX_VISIBLE_SYMBOLS
    ja .collision_invalid
    push rbx
    push r12
    push r13
    push r14
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    xor r14d, r14d
.collision_next:
    cmp r14, r12
    jae .collision_clear_saved
    mov rax, r14
    imul rax, NEBOC_CONST_SYMBOL_SIZE
    lea r8, [rbx + rax]
    mov rcx, [r8 + NEBOC_CONST_SYMBOL_NAME_LENGTH_OFFSET]
    cmp rcx, [r13 + NEBOC_CONST_SYMBOL_NAME_LENGTH_OFFSET]
    jne .collision_advance
    mov r9, [r8 + NEBOC_CONST_SYMBOL_NAME_OFFSET]
    mov r10, [r13 + NEBOC_CONST_SYMBOL_NAME_OFFSET]
    xor eax, eax
.collision_bytes:
    cmp rax, rcx
    jae .collision_found
    mov dl, [r9 + rax]
    cmp dl, [r10 + rax]
    jne .collision_advance
    inc rax
    jmp .collision_bytes
.collision_advance:
    inc r14
    jmp .collision_next
.collision_found:
    mov eax, NEBOC_CONST_SHADOW_FORBIDDEN
    jmp .collision_done
.collision_clear_saved:
    xor eax, eax
.collision_done:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.collision_clear:
    xor eax, eax
    ret
.collision_invalid:
    mov eax, NEBOC_CONST_INVALID_ARGUMENT
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
