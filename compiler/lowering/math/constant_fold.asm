bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

%define NEBO_FOLD_ROOT2      1
%define NEBO_FOLD_ROOT3      2
%define NEBO_FOLD_ROOT4      3
%define NEBO_FOLD_FACTORIAL  4
%define NEBO_FOLD_FLOOR      5
%define NEBO_FOLD_CEIL       6

extern nebo_root_exact_u64
extern nebo_factorial_u64_checked
extern nebo_floor_rational_i64
extern nebo_ceil_rational_i64

section .text

; edi=operation, rsi=operand/numerator, rdx=denominator when relevant.
; Tail dispatch guarantees the folded result uses the runtime implementation.
global nebo_math_constant_fold_i64
nebo_math_constant_fold_i64:
    cmp edi, NEBO_FOLD_ROOT2
    je .root2
    cmp edi, NEBO_FOLD_ROOT3
    je .root3
    cmp edi, NEBO_FOLD_ROOT4
    je .root4
    cmp edi, NEBO_FOLD_FACTORIAL
    je .factorial
    cmp edi, NEBO_FOLD_FLOOR
    je .floor
    cmp edi, NEBO_FOLD_CEIL
    je .ceil
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret
.root2:
    mov rdi, rsi
    mov esi, 2
    jmp nebo_root_exact_u64
.root3:
    mov rdi, rsi
    mov esi, 3
    jmp nebo_root_exact_u64
.root4:
    mov rdi, rsi
    mov esi, 4
    jmp nebo_root_exact_u64
.factorial:
    mov rdi, rsi
    jmp nebo_factorial_u64_checked
.floor:
    mov rdi, rsi
    mov rsi, rdx
    jmp nebo_floor_rational_i64
.ceil:
    mov rdi, rsi
    mov rsi, rdx
    jmp nebo_ceil_rational_i64

section .note.GNU-stack noalloc noexec nowrite progbits
