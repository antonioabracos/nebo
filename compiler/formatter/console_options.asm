; Nebo Assembly — CONSOLECALL-CONSOLEOPTION-REGISTRY-E-NORMALIZACAO schema-key preserving ConsoleOption formatter
bits 64
default rel
%include "runtime/console_options.inc"
%include "runtime/console_option_registry.inc"
%include "compiler/formatter/console_options.inc"
global neboc_format_option_schema_key
section .text
; rdi=key, rsi=len, rdx=out, rcx=capacity. Exact bytes are preserved.
neboc_format_option_schema_key:
    test rdi, rdi
    jz .invalid
    test rdx, rdx
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp rsi, NEBO_OPTION_NAMED_KEY_MAX_BYTES
    ja .invalid
    cmp rcx, rsi
    jb .capacity
    xor eax, eax
.copy:
    cmp rax, rsi
    jae .ok
    mov cl, [rdi + rax]
    mov [rdx + rax], cl
    inc rax
    jmp .copy
.ok:
    xor eax, eax
    ret
.capacity:
    mov eax, NEBOC_OPTION_FORMAT_CAPACITY
    ret
.invalid:
    mov eax, NEBO_OPTIONS_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
