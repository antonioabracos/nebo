; Nebo Assembly — strict UTF-8 validator v0
;
; Purpose:
;   Validate UTF-8 bytes without normalization and report the first bad offset.
;
; Inputs:
;   RDI = bytes (nullable only when RSI is zero)
;   RSI = byte length
;   RDX = non-null out_invalid_offset
;
; Outputs:
;   [RDX] = first invalid byte offset, or length on success.
;
; Status:
;   OK, INVALID_ARGUMENT or INVALID_SOURCE.
;
; Clobbers:
;   Caller-saved registers and flags.
;
; Preserved:
;   RBX, RBP, R12, R13, R14, R15 and RSP.
;
; Stack:
;   Unchanged; no red-zone dependency.
;
; Ownership:
;   Borrowed bytes only.
;
; Thread safety:
;   Reentrant and stateless.
;
; Errors:
;   Overlong, surrogate, out-of-range and truncated sequences are rejected.
;
; Tests:
;   NEBO-SOURCE-GOLDEN-001 and NEBO-SOURCE-NEG-003.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"

section .text

NEBOC_ABI_FUNCTION neboc_utf8_validate
    test rdx, rdx
    jz .invalid_argument
    mov [rdx], rsi
    test rsi, rsi
    jz .ok
    test rdi, rdi
    jz .invalid_argument
    xor ecx, ecx
.next:
    cmp rcx, rsi
    jae .ok
    movzx eax, byte [rdi + rcx]
    cmp al, 0x80
    jb .one
    cmp al, 0xc2
    jb .bad
    cmp al, 0xdf
    jbe .two
    cmp al, 0xe0
    je .three_e0
    cmp al, 0xec
    jbe .three_general
    cmp al, 0xed
    je .three_ed
    cmp al, 0xef
    jbe .three_general
    cmp al, 0xf0
    je .four_f0
    cmp al, 0xf3
    jbe .four_general
    cmp al, 0xf4
    je .four_f4
    jmp .bad
.one:
    inc rcx
    jmp .next
.two:
    lea r8, [rcx + 1]
    cmp r8, rsi
    jae .bad
    movzx r9d, byte [rdi + r8]
    and r9d, 0xc0
    cmp r9d, 0x80
    jne .bad
    add rcx, 2
    jmp .next
.three_e0:
    lea r8, [rcx + 2]
    cmp r8, rsi
    jae .bad
    movzx r9d, byte [rdi + rcx + 1]
    cmp r9d, 0xa0
    jb .bad
    cmp r9d, 0xbf
    ja .bad
    jmp .three_last
.three_general:
    lea r8, [rcx + 2]
    cmp r8, rsi
    jae .bad
    movzx r9d, byte [rdi + rcx + 1]
    and r9d, 0xc0
    cmp r9d, 0x80
    jne .bad
    jmp .three_last
.three_ed:
    lea r8, [rcx + 2]
    cmp r8, rsi
    jae .bad
    movzx r9d, byte [rdi + rcx + 1]
    cmp r9d, 0x80
    jb .bad
    cmp r9d, 0x9f
    ja .bad
.three_last:
    movzx r9d, byte [rdi + rcx + 2]
    and r9d, 0xc0
    cmp r9d, 0x80
    jne .bad
    add rcx, 3
    jmp .next
.four_f0:
    lea r8, [rcx + 3]
    cmp r8, rsi
    jae .bad
    movzx r9d, byte [rdi + rcx + 1]
    cmp r9d, 0x90
    jb .bad
    cmp r9d, 0xbf
    ja .bad
    jmp .four_tail
.four_general:
    lea r8, [rcx + 3]
    cmp r8, rsi
    jae .bad
    movzx r9d, byte [rdi + rcx + 1]
    and r9d, 0xc0
    cmp r9d, 0x80
    jne .bad
    jmp .four_tail
.four_f4:
    lea r8, [rcx + 3]
    cmp r8, rsi
    jae .bad
    movzx r9d, byte [rdi + rcx + 1]
    cmp r9d, 0x80
    jb .bad
    cmp r9d, 0x8f
    ja .bad
.four_tail:
    movzx r9d, byte [rdi + rcx + 2]
    and r9d, 0xc0
    cmp r9d, 0x80
    jne .bad
    movzx r9d, byte [rdi + rcx + 3]
    and r9d, 0xc0
    cmp r9d, 0x80
    jne .bad
    add rcx, 4
    jmp .next
.bad:
    mov [rdx], rcx
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.ok:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
