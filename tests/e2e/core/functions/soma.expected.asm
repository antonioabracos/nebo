bits 64
default rel
extern nebo_runtime_trap_overflow
extern nebo_runtime_trap_division_by_zero
extern nebo_runtime_numeric_safety_int_to_float
extern nebo_runtime_numeric_safety_is_finite
extern nebo_runtime_numeric_safety_is_nan
extern nebo_runtime_numeric_safety_is_infinite
extern nebo_runtime_numeric_safety_is_negative_zero
extern nebo_runtime_textual_text_byte_length
extern nebo_runtime_textual_text_codepoint_count
extern nebo_runtime_textual_char_codepoint
extern nebo_runtime_textual_bytes_empty
extern nebo_runtime_textual_bytes_byte_length
extern neboc_runtime_store_zero_payload
extern neboc_runtime_store_integer
extern neboc_runtime_store_float
extern neboc_runtime_tag_test
extern neboc_runtime_unwrap_integer
extern neboc_runtime_unwrap_float
global _start
extern nebo_runtime_start

section .text
_start:
    lea rdi, [rel nebo_fn_1]
    call nebo_runtime_start
    ud2

section .text
global nebo_fn_2
nebo_fn_2:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, [rbp - 8]
    push rax
    mov rax, [rbp - 16]
    mov rcx, rax
    pop rax
    add rax, rcx
    jo .nebo_trap_overflow
    mov rsp, rbp
    pop rbp
    ret
.nebo_trap_overflow:
    jmp nebo_runtime_trap_overflow
global nebo_fn_1
nebo_fn_1:
    push rbp
    mov rbp, rsp
    mov rax, 2
    push rax
    mov rax, 3
    push rax
    pop rsi
    pop rdi
    call nebo_fn_2
    mov rsp, rbp
    pop rbp
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
