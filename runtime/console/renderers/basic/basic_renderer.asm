; Nebo Console basic logical value renderer — MF043
bits 64
default rel

%include "runtime/console/handles/console_handle.inc"
%include "runtime/console/renderers/basic/basic_renderer.inc"

global nebo_console_basic_validate_utf8
global nebo_console_basic_format_int64
global nebo_console_basic_format_bool

section .rodata align=8
nebo_console_basic_true_bytes: db 'true'
nebo_console_basic_false_bytes: db 'false'

section .text

; validate_utf8(data*, length) -> status
; Strict scalar-value UTF-8: rejects overlong encodings, surrogates and values
; above U+10FFFF. Empty input is valid even with a null data pointer.
nebo_console_basic_validate_utf8:
    test rsi, rsi
    jz .utf8_ok
    test rdi, rdi
    jz .utf8_invalid
    xor rcx, rcx
.utf8_loop:
    cmp rcx, rsi
    jae .utf8_ok
    movzx eax, byte [rdi+rcx]
    cmp eax, 0x80
    jb .utf8_one
    cmp eax, 0xC2
    jb .utf8_invalid
    cmp eax, 0xDF
    jbe .utf8_two
    cmp eax, 0xE0
    je .utf8_three_e0
    cmp eax, 0xED
    je .utf8_three_ed
    cmp eax, 0xEF
    jbe .utf8_three_regular
    cmp eax, 0xF0
    je .utf8_four_f0
    cmp eax, 0xF3
    jbe .utf8_four_regular
    cmp eax, 0xF4
    je .utf8_four_f4
    jmp .utf8_invalid
.utf8_one:
    inc rcx
    jmp .utf8_loop
.utf8_two:
    lea rdx, [rcx+1]
    cmp rdx, rsi
    jae .utf8_invalid
    movzx edx, byte [rdi+rcx+1]
    and edx, 0xC0
    cmp edx, 0x80
    jne .utf8_invalid
    add rcx, 2
    jmp .utf8_loop
.utf8_three_e0:
    lea rdx, [rcx+2]
    cmp rdx, rsi
    jae .utf8_invalid
    movzx edx, byte [rdi+rcx+1]
    cmp edx, 0xA0
    jb .utf8_invalid
    cmp edx, 0xBF
    ja .utf8_invalid
    jmp .utf8_three_tail
.utf8_three_ed:
    lea rdx, [rcx+2]
    cmp rdx, rsi
    jae .utf8_invalid
    movzx edx, byte [rdi+rcx+1]
    cmp edx, 0x80
    jb .utf8_invalid
    cmp edx, 0x9F
    ja .utf8_invalid
    jmp .utf8_three_tail
.utf8_three_regular:
    lea rdx, [rcx+2]
    cmp rdx, rsi
    jae .utf8_invalid
    movzx edx, byte [rdi+rcx+1]
    and edx, 0xC0
    cmp edx, 0x80
    jne .utf8_invalid
.utf8_three_tail:
    movzx edx, byte [rdi+rcx+2]
    and edx, 0xC0
    cmp edx, 0x80
    jne .utf8_invalid
    add rcx, 3
    jmp .utf8_loop
.utf8_four_f0:
    lea rdx, [rcx+3]
    cmp rdx, rsi
    jae .utf8_invalid
    movzx edx, byte [rdi+rcx+1]
    cmp edx, 0x90
    jb .utf8_invalid
    cmp edx, 0xBF
    ja .utf8_invalid
    jmp .utf8_four_tail
.utf8_four_regular:
    lea rdx, [rcx+3]
    cmp rdx, rsi
    jae .utf8_invalid
    movzx edx, byte [rdi+rcx+1]
    and edx, 0xC0
    cmp edx, 0x80
    jne .utf8_invalid
    jmp .utf8_four_tail
.utf8_four_f4:
    lea rdx, [rcx+3]
    cmp rdx, rsi
    jae .utf8_invalid
    movzx edx, byte [rdi+rcx+1]
    cmp edx, 0x80
    jb .utf8_invalid
    cmp edx, 0x8F
    ja .utf8_invalid
.utf8_four_tail:
    movzx edx, byte [rdi+rcx+2]
    and edx, 0xC0
    cmp edx, 0x80
    jne .utf8_invalid
    movzx edx, byte [rdi+rcx+3]
    and edx, 0xC0
    cmp edx, 0x80
    jne .utf8_invalid
    add rcx, 4
    jmp .utf8_loop
.utf8_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret
.utf8_ok:
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret

; format_int64(value, output*, capacity, out_length*) -> status
; Produces exact canonical decimal bytes without a terminator.
nebo_console_basic_format_int64:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, NEBO_CONSOLE_INT64_FORMAT_BUFFER_SIZE+8
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    test r15, r15
    jz .int_invalid
    mov qword [r15], 0
    test r13, r13
    jz .int_invalid
    lea r8, [rsp+NEBO_CONSOLE_INT64_FORMAT_BUFFER_SIZE]
    mov r9, r8
    xor r10d, r10d
    mov rax, r12
    test rax, rax
    jns .int_magnitude_ready
    mov r10d, 1
    neg rax
.int_magnitude_ready:
    mov ebx, 10
    test rax, rax
    jnz .int_digit_loop
    dec r9
    mov byte [r9], '0'
    jmp .int_sign
.int_digit_loop:
    xor edx, edx
    div rbx
    add dl, '0'
    dec r9
    mov [r9], dl
    test rax, rax
    jnz .int_digit_loop
.int_sign:
    test r10d, r10d
    jz .int_count
    dec r9
    mov byte [r9], '-'
.int_count:
    mov rax, r8
    sub rax, r9
    cmp rax, r14
    ja .int_limit
    mov [r15], rax
    mov rcx, rax
    mov rsi, r9
    mov rdi, r13
    cld
    rep movsb
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .int_done
.int_limit:
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .int_done
.int_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.int_done:
    add rsp, NEBO_CONSOLE_INT64_FORMAT_BUFFER_SIZE+8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; format_bool(canonical_bool, output*, capacity, out_length*) -> status
; Only 0 and 1 are valid Bool ABI values.
nebo_console_basic_format_bool:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    test r14, r14
    jz .bool_invalid
    mov qword [r14], 0
    test r12, r12
    jz .bool_invalid
    cmp rdi, 0
    je .bool_false
    cmp rdi, 1
    jne .bool_invalid
    lea rsi, [rel nebo_console_basic_true_bytes]
    mov ebx, NEBO_CONSOLE_BOOL_TRUE_LENGTH
    jmp .bool_copy
.bool_false:
    lea rsi, [rel nebo_console_basic_false_bytes]
    mov ebx, NEBO_CONSOLE_BOOL_FALSE_LENGTH
.bool_copy:
    cmp r13, rbx
    jb .bool_limit
    mov rdi, r12
    mov rcx, rbx
    cld
    rep movsb
    mov [r14], rbx
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .bool_done
.bool_limit:
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .bool_done
.bool_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.bool_done:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
