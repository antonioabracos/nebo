bits 64
default rel
%include "compiler/semantic/types/format_semantic.inc"
section .text
global neboc_format_require_pure
global neboc_interpolation_require_pure
; rdi=expression bytes, rsi=len. A conservative pure-expression boundary.
neboc_format_require_pure:
    test rdi, rdi
    jz .effect
    ; The zero-argument Text observer is a pure intrinsic.  Admit its exact
    ; bounded spelling while retaining the conservative call rejection below
    ; for effectful or unresolved invocations.
    cmp rsi, 21
    jne .scan_start
    mov rax, 0x646f632e74786574               ; "text.cod"
    cmp qword [rdi], rax
    jne .scan_start
    mov rax, 0x6f43746e696f7065               ; "epointCo"
    cmp qword [rdi+8], rax
    jne .scan_start
    cmp dword [rdi+16], 0x28746e75            ; "unt("
    jne .scan_start
    cmp byte [rdi+20], ')'
    je .ok
.scan_start:
    xor ecx, ecx
.scan:
    cmp rcx, rsi
    je .ok
    mov al, [rdi + rcx]
    cmp al, '!'
    je .effect
    cmp al, '='
    je .effect
    cmp al, ';'
    je .effect
    cmp al, '('
    je .effect
    cmp al, ')'
    je .effect
    inc rcx
    jmp .scan
.ok:
    xor eax, eax
    ret
.effect:
    mov eax, FORMAT_SEMANTIC_E_EFFECT
    ret

; The interpolation owner deliberately delegates to the existing effects
; boundary.  This alias makes that ownership visible without a second policy.
neboc_interpolation_require_pure:
    jmp neboc_format_require_pure

section .note.GNU-stack noalloc noexec nowrite progbits
