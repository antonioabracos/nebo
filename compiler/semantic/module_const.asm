; Nebo Assembly — CONSTBINDING-POR-ALL-CAPS-E-IDENTIDADE-DE-NOMES module compile-time ConstBinding validation
bits 64
default rel

%include "compiler/semantic/const_binding.inc"
%include "compiler/semantic/module_const.inc"

global neboc_module_const_validate

section .text

; rdi=const symbol, rsi=analysis flags, rdx=folded value, rcx=out descriptor
; eax=status; descriptor remains unchanged on every rejection.
neboc_module_const_validate:
    test rdi, rdi
    jz .invalid
    test rcx, rcx
    jz .invalid
    cmp qword [rdi + NEBOC_CONST_SYMBOL_KIND_OFFSET], NEBOC_BINDING_KIND_CONST
    jne .invalid
    test rsi, NEBOC_MODULE_INIT_EFFECTFUL
    jnz .effectful
    mov rax, rsi
    and eax, NEBOC_MODULE_INIT_REQUIRED
    cmp eax, NEBOC_MODULE_INIT_REQUIRED
    jne .not_compile_time
    mov rax, [rdi + NEBOC_CONST_SYMBOL_ID_OFFSET]
    mov [rcx + NEBOC_MODULE_CONST_SYMBOL_ID_OFFSET], rax
    mov [rcx + NEBOC_MODULE_CONST_VALUE_OFFSET], rdx
    mov [rcx + NEBOC_MODULE_CONST_ANALYSIS_FLAGS_OFFSET], rsi
    mov qword [rcx + NEBOC_MODULE_CONST_STATE_OFFSET], NEBOC_MODULE_CONST_VALID
    xor eax, eax
    ret
.effectful:
    mov eax, NEBOC_CONST_EFFECTFUL_INITIALIZER
    ret
.not_compile_time:
    mov eax, NEBOC_CONST_NOT_COMPILE_TIME
    ret
.invalid:
    mov eax, NEBOC_CONST_INVALID_ARGUMENT
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
