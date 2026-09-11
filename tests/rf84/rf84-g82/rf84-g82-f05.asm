bits 64
default rel
%include "runtime/textual/format_data.inc"
global _start

section .text
_start:
    mov edi, 31
    call format_front_state
    cmp eax, 2
    jne fail

    lea rdi, [rel descriptors]
    mov esi, 2
    call ascii_upper_vector
    test eax, eax
    jnz fail
    lea r10, [rel out_a]
    lea r11, [rel expected]
    xor ecx, ecx
.compare_a:
    cmp ecx, sample_len
    jae .compare_b_start
    mov al, [r10 + rcx]
    cmp al, [r11 + rcx]
    jne fail
    inc ecx
    jmp .compare_a
.compare_b_start:
    lea r10, [rel out_b]
    xor ecx, ecx
.compare_b:
    cmp ecx, sample_len
    jae .capacity_failure
    mov al, [r10 + rcx]
    cmp al, [r11 + rcx]
    jne fail
    inc ecx
    jmp .compare_b
.capacity_failure:
    lea rdi, [rel bad_descriptor]
    mov esi, 1
    call ascii_upper_vector
    cmp eax, FMT_CAPACITY
    jne fail

success:
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .rodata
sample_a: db 'Ab c'
sample_b: db 'aB C'
expected: db 'AB C'
sample_len equ $ - expected
descriptors:
    dq sample_a, 4, out_a, 4
    dq sample_b, 4, out_b, 4
bad_descriptor: dq sample_a, 4, out_a, 3
section .bss
out_a: resb 4
out_b: resb 4
