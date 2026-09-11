bits 64
default rel

extern nebo_stack_alignment_sentinel

section .rodata
expected:
    times 16 db 1
expected_len equ $ - expected

section .bss
observed: resb expected_len

section .text
global _start

%macro RUN_CASE 2
    call %1
    mov byte [observed + %2], al
%endmacro

_start:
    RUN_CASE case_direct, 0
    RUN_CASE case_indirect, 1
    RUN_CASE case_nested, 2
    mov edi, 2
    call case_recursive
    mov byte [observed + 3], al
    RUN_CASE case_even_pushes, 4
    RUN_CASE case_odd_pushes, 5
    RUN_CASE case_local_frame, 6
    RUN_CASE case_spills, 7
    RUN_CASE case_if_else, 8
    RUN_CASE case_loop, 9
    RUN_CASE case_early_return, 10
    RUN_CASE case_error_cleanup, 11
    RUN_CASE case_compiler_driver, 12
    RUN_CASE case_runtime, 13
    RUN_CASE case_x11, 14
    RUN_CASE case_sdk_neboc, 15

    mov eax, 1
    mov edi, 1
    lea rsi, [observed]
    mov edx, expected_len
    syscall

    xor edi, edi
    xor ecx, ecx
.compare:
    cmp ecx, expected_len
    jae .exit
    mov al, byte [observed + rcx]
    cmp al, byte [expected + rcx]
    jne .bad
    inc ecx
    jmp .compare
.bad:
    mov edi, 1
.exit:
    mov eax, 60
    syscall

case_direct:
    sub rsp, 8
    call nebo_stack_alignment_sentinel
    add rsp, 8
    ret

case_indirect:
    lea rax, [nebo_stack_alignment_sentinel]
    sub rsp, 8
    call rax
    add rsp, 8
    ret

; Nested and recursive cases use an explicit odd-qword correction at each call.
case_nested:
    sub rsp, 8
    call nested_leaf
    add rsp, 8
    ret
nested_leaf:
    sub rsp, 8
    call nebo_stack_alignment_sentinel
    add rsp, 8
    ret

case_recursive:
    test edi, edi
    jz .leaf
    dec edi
    sub rsp, 8
    call case_recursive
    add rsp, 8
    ret
.leaf:
    sub rsp, 8
    call nebo_stack_alignment_sentinel
    add rsp, 8
    ret

case_even_pushes:
    push rbx
    push r12
    sub rsp, 8
    call nebo_stack_alignment_sentinel
    add rsp, 8
    pop r12
    pop rbx
    ret

case_odd_pushes:
    push rbx
    call nebo_stack_alignment_sentinel
    pop rbx
    ret

case_local_frame:
    sub rsp, 40
    call nebo_stack_alignment_sentinel
    add rsp, 40
    ret

case_spills:
    push rbx
    sub rsp, 16
    call nebo_stack_alignment_sentinel
    add rsp, 16
    pop rbx
    ret

case_if_else:
    sub rsp, 8
    xor eax, eax
    test eax, eax
    jz .else
    call nebo_stack_alignment_sentinel
    add rsp, 8
    ret
.else:
    call nebo_stack_alignment_sentinel
    add rsp, 8
    ret

case_loop:
    sub rsp, 8
    mov ecx, 1
.again:
    call nebo_stack_alignment_sentinel
    loop .again
    add rsp, 8
    ret

case_early_return:
    xor eax, eax
    test eax, eax
    jz .early
    mov eax, 1
    ret
.early:
    sub rsp, 8
    call nebo_stack_alignment_sentinel
    add rsp, 8
    ret

case_error_cleanup:
    sub rsp, 8
    jmp .cleanup
.cleanup:
    call nebo_stack_alignment_sentinel
    lea rsp, [rsp + 8]
    ret

case_compiler_driver:
    sub rsp, 8
    call nebo_stack_alignment_sentinel
    add rsp, 8
    ret

case_runtime:
    sub rsp, 24
    call nebo_stack_alignment_sentinel
    add rsp, 24
    ret

case_x11:
    push rbx
    push r12
    sub rsp, 8
    call nebo_stack_alignment_sentinel
    add rsp, 8
    pop r12
    pop rbx
    ret

case_sdk_neboc:
    lea rax, [nebo_stack_alignment_sentinel]
    sub rsp, 8
    call rax
    add rsp, 8
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
