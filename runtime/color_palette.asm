; Nebo Assembly — PAPEIS-DE-COR-PALETTES-THEMES-COLORMAPS-E-ACESSIBILIDADE bounded named Color palettes
bits 64
default rel
%include "runtime/color.inc"
%include "runtime/color_palette.inc"
global nebo_palette_validate
global nebo_palette_lookup
section .text
; rdi=entries, rsi=count. Validates the complete immutable view before use.
nebo_palette_validate:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp rsi, NEBO_PALETTE_MAX_ENTRIES
    ja .capacity
    xor r8d, r8d
.outer:
    cmp r8, rsi
    jae .ok
    imul rax, r8, NEBO_PALETTE_ENTRY_SIZE
    lea r9, [rdi + rax]
    cmp qword [r9 + NEBO_PALETTE_ENTRY_NAME_OFFSET], 0
    je .invalid
    mov r10, [r9 + NEBO_PALETTE_ENTRY_NAME_LEN_OFFSET]
    test r10, r10
    jz .invalid
    cmp r10, NEBO_PALETTE_MAX_NAME_BYTES
    ja .capacity
    lea r11, [r8 + 1]
.duplicates:
    cmp r11, rsi
    jae .next
    imul rax, r11, NEBO_PALETTE_ENTRY_SIZE
    lea rdx, [rdi + rax]
    cmp r10, [rdx + NEBO_PALETTE_ENTRY_NAME_LEN_OFFSET]
    jne .dup_next
    mov rcx, r10
    mov rax, [r9 + NEBO_PALETTE_ENTRY_NAME_OFFSET]
    mov rdx, [rdx + NEBO_PALETTE_ENTRY_NAME_OFFSET]
    test rdx, rdx
    jz .invalid
.compare:
    mov r10b, [rax]
    cmp r10b, [rdx]
    jne .restore
    inc rax
    inc rdx
    loop .compare
    mov eax, NEBO_PALETTE_DUPLICATE
    ret
.restore:
    mov r10, [r9 + NEBO_PALETTE_ENTRY_NAME_LEN_OFFSET]
.dup_next:
    inc r11
    jmp .duplicates
.next:
    inc r8
    jmp .outer
.ok:
    xor eax, eax
    ret
.capacity:
    mov eax, NEBO_COLOR_CAPACITY
    ret
.invalid:
    mov eax, NEBO_COLOR_INVALID
    ret
; rdi=entries, rsi=count, rdx=name, rcx=name_len, r8=out Color.
nebo_palette_lookup:
    test r8, r8
    jz .lookup_invalid
    push r12
    push r13
    push r14
    push r15
    push rbx
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov rbx, r8
    call nebo_palette_validate
    test eax, eax
    jnz .lookup_done
    test r14, r14
    jz .lookup_invalid_saved
    test r15, r15
    jz .lookup_invalid_saved
    xor r9d, r9d
.lookup_loop:
    cmp r9, r13
    jae .not_found
    imul rax, r9, NEBO_PALETTE_ENTRY_SIZE
    lea r10, [r12 + rax]
    cmp r15, [r10 + NEBO_PALETTE_ENTRY_NAME_LEN_OFFSET]
    jne .lookup_next
    mov rcx, r15
    mov rax, [r10 + NEBO_PALETTE_ENTRY_NAME_OFFSET]
    mov rdx, r14
.lookup_compare:
    mov sil, [rax]
    cmp sil, [rdx]
    jne .lookup_next
    inc rax
    inc rdx
    loop .lookup_compare
    mov eax, [r10 + NEBO_PALETTE_ENTRY_COLOR_OFFSET]
    mov [rbx], eax
    xor eax, eax
    jmp .lookup_done
.lookup_next:
    inc r9
    jmp .lookup_loop
.not_found:
    mov eax, NEBO_PALETTE_NOT_FOUND
    jmp .lookup_done
.lookup_invalid_saved:
    mov eax, NEBO_COLOR_INVALID
.lookup_done:
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret
.lookup_invalid:
    mov eax, NEBO_COLOR_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
