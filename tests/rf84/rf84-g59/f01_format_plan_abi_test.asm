bits 64
default rel
%include "runtime/textual/format_language.inc"
section .rodata
left: db "alpha"
right: db "beta"
section .data
nodes:
    dq FORMAT_NODE_LITERAL, left, 5, 0
    dq FORMAT_NODE_VALUE, right, 4, 0
canary: times 16 db 0xa5
section .bss
output: resb 16
section .text
extern neboc_format_plan_validate
extern neboc_format_plan_measure
extern neboc_format_plan_write
extern neboc_format_feature_validate
global _start
_start:
    mov r15d, 1
    mov rdi, nodes
    mov esi, 2
    call neboc_format_plan_validate
    test eax, eax
    jnz .fail
    inc r15d
    mov rdi, nodes
    mov esi, 2
    call neboc_format_plan_measure
    cmp rax, 9
    jne .fail
    inc r15d
    mov rdi, nodes
    mov esi, 2
    mov rdx, output
    mov ecx, 8
    call neboc_format_plan_write
    cmp rax, -FORMAT_E_CAPACITY
    jne .fail
    inc r15d
    cmp byte [output], 0
    jne .fail
    inc r15d
    mov rdi, nodes
    mov esi, 2
    mov rdx, output
    mov ecx, 16
    call neboc_format_plan_write
    cmp rax, 9
    jne .fail
    inc r15d
    cmp dword [output], 'alph'
    jne .fail
    inc r15d
    cmp byte [output + 4], 'a'
    jne .fail
    inc r15d
    cmp dword [output + 5], 'beta'
    jne .fail
    inc r15d
    mov edi, 5901
    mov rsi, feature_input
    mov edx, feature_input_len
    call neboc_format_feature_validate
    test eax, eax
    jnz .fail
    xor edi, edi
    mov eax, 60
    syscall
.fail:
    mov edi, r15d
    mov eax, 60
    syscall
section .rodata
feature_input: db "format-plan"
feature_input_len equ $ - feature_input
