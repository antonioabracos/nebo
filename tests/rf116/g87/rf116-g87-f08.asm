bits 64
default rel
%include "runtime/color.inc"
extern nebo_color_serialize_hex
extern nebo_color_to_hex
extern nebo_color_to_hex_with_alpha
global _start
section .text
_start:
    mov edi, 0x12abcdef
    lea rsi, [rel rgba]
    mov edx, 9
    mov ecx, 1
    call nebo_color_serialize_hex
    test eax, eax
    jnz fail
    cmp rdx, 9
    jne fail
    mov rax, [rel expected_rgba]
    cmp rax, [rel rgba]
    jne fail
    mov al, [rel expected_rgba + 8]
    cmp al, [rel rgba + 8]
    jne fail
    mov edi, 0x12abcde0
    lea rsi, [rel rgb]
    mov edx, 7
    xor ecx, ecx
    call nebo_color_serialize_hex
    test eax, eax
    jnz fail
    mov rax, [rel expected_rgb]
    shl rax, 8
    shr rax, 8
    mov rbx, [rel rgb]
    shl rbx, 8
    shr rbx, 8
    cmp rax, rbx
    jne fail
    mov edi, 0x89abcdef
    lea rsi, [rel public_rgba]
    mov edx, 9
    call nebo_color_to_hex_with_alpha
    test eax, eax
    jnz fail
    cmp rdx, 9
    jne fail
    mov rax, [rel expected_public_rgba]
    cmp rax, [rel public_rgba]
    jne fail
    mov al, [rel expected_public_rgba + 8]
    cmp al, [rel public_rgba + 8]
    jne fail
    mov edi, 0x89abcdef
    lea rsi, [rel public_rgb]
    mov edx, 7
    call nebo_color_to_hex
    test eax, eax
    jnz fail
    cmp rdx, 7
    jne fail
    mov rax, [rel expected_public_rgb]
    shl rax, 8
    shr rax, 8
    mov rbx, [rel public_rgb]
    shl rbx, 8
    shr rbx, 8
    cmp rax, rbx
    jne fail
    mov edi, 0
    lea rsi, [rel untouched]
    mov edx, 6
    xor ecx, ecx
    call nebo_color_serialize_hex
    cmp eax, NEBO_COLOR_CAPACITY
    jne fail
    mov rax, 0xaaaaaaaaaaaaaaaa
    cmp qword [rel untouched], rax
    jne fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .rodata
expected_rgba: db "#12ABCDEF"
expected_rgb: db "#12ABCD", 0
expected_public_rgba: db "#89ABCDEF"
expected_public_rgb: db "#89ABCD", 0
section .bss
rgba: resb 9
rgb: resb 8
public_rgba: resb 9
public_rgb: resb 8
section .data
untouched: times 9 db 0xaa
section .note.GNU-stack noalloc noexec nowrite progbits
