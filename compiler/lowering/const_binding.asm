; Nebo Assembly — CONSTBINDING-POR-ALL-CAPS-E-IDENTIDADE-DE-NOMES local ConstBinding runtime-once lowering
bits 64
default rel

%include "compiler/semantic/const_binding.inc"
%include "compiler/lowering/const_binding.inc"

global neboc_const_lower_local

section .text

; rdi=symbol record, rsi=initializer(ctx)->eax status,rdx value,
; rdx=initializer context, rcx=out local descriptor. Output is atomic.
neboc_const_lower_local:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    test rcx, rcx
    jz .invalid
    cmp qword [rdi + NEBOC_CONST_SYMBOL_KIND_OFFSET], NEBOC_BINDING_KIND_CONST
    jne .invalid
    push rbx
    push r12
    push r13
    mov rbx, rdi
    mov r12, rcx
    mov r13, rsi
    mov rdi, rdx
    call r13
    test eax, eax
    jnz .initializer_failed
    mov [r12 + NEBOC_CONST_LOCAL_VALUE_OFFSET], rdx
    mov rax, [rbx + NEBOC_CONST_SYMBOL_ID_OFFSET]
    mov [r12 + NEBOC_CONST_LOCAL_SYMBOL_ID_OFFSET], rax
    mov qword [r12 + NEBOC_CONST_LOCAL_EVALUATION_COUNT_OFFSET], 1
    mov qword [r12 + NEBOC_CONST_LOCAL_STATE_OFFSET], NEBOC_CONST_LOCAL_INITIALIZED
    xor eax, eax
    jmp .done
.initializer_failed:
    mov eax, NEBOC_CONST_INITIALIZER_FAILED
.done:
    pop r13
    pop r12
    pop rbx
    ret
.invalid:
    mov eax, NEBOC_CONST_INVALID_ARGUMENT
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
