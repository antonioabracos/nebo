; Nebo Assembly — checked Slice v0
;
; Purpose:
;   Represent a borrowed typed view with explicit length, element size, owner
;   token and Arena generation.
;
; Inputs:
;   Per-function arguments follow NEBOC_INTERNAL_ABI_v0.
;
; Outputs:
;   StatusCode in EAX and explicit out pointers.
;
; Status:
;   INVALID_ARGUMENT for stale ownership/generation; LIMIT_EXCEEDED for bounds
;   and arithmetic overflow.
;
; Clobbers:
;   Caller-saved registers and flags.
;
; Preserved:
;   RBX, RBP, R12, R13, R14, R15 and RSP.
;
; Stack:
;   No local frame and no red-zone dependency.
;
; Ownership:
;   Slice borrows memory owned by its Arena; it never releases memory.
;
; Thread safety:
;   Validation requires the exact owner token frozen in the Arena.
;
; Errors:
;   Every byte-length, offset and end pointer is checked before use.
;
; Tests:
;   NEBO-MEM-UNIT_ASM-004 and NEBO-MEM-NEG-005.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/support/memory/arena.inc"
%include "compiler/support/slice/slice.inc"

section .text

; slice_init(slice*, pointer, length, element_size, arena*, owner_token)
NEBOC_ABI_FUNCTION neboc_slice_init
    test rdi, rdi
    jz .invalid
    test rcx, rcx
    jz .invalid
    cmp rcx, NEBOC_SLICE_MAX_ELEMENT_SIZE
    ja .invalid
    test r8, r8
    jz .invalid
    test r9, r9
    jz .invalid
    cmp qword [r8 + NEBOC_ARENA_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [r8 + NEBOC_ARENA_OWNER_OFFSET], r9
    jne .invalid
    cmp qword [r8 + NEBOC_ARENA_GENERATION_OFFSET], 0
    je .invalid

    test rdx, rdx
    jz .empty
    test rsi, rsi
    jz .invalid
    mov r10, rdx
    mov rax, rdx
    mul rcx
    test rdx, rdx
    jnz .limit
    mov r11, rsi
    add r11, rax
    jc .limit
    cmp rsi, [r8 + NEBOC_ARENA_BEGIN_OFFSET]
    jb .invalid
    cmp r11, [r8 + NEBOC_ARENA_CURRENT_OFFSET]
    ja .limit
    mov rdx, r10
    jmp .store
.empty:
    test rsi, rsi
    jz .store
    cmp rsi, [r8 + NEBOC_ARENA_BEGIN_OFFSET]
    jb .invalid
    cmp rsi, [r8 + NEBOC_ARENA_CURRENT_OFFSET]
    ja .limit
.store:
    mov [rdi + NEBOC_SLICE_POINTER_OFFSET], rsi
    mov [rdi + NEBOC_SLICE_LENGTH_OFFSET], rdx
    mov [rdi + NEBOC_SLICE_ELEMENT_SIZE_OFFSET], rcx
    mov [rdi + NEBOC_SLICE_ARENA_OFFSET], r8
    mov rax, [r8 + NEBOC_ARENA_GENERATION_OFFSET]
    mov [rdi + NEBOC_SLICE_GENERATION_OFFSET], rax
    mov [rdi + NEBOC_SLICE_OWNER_OFFSET], r9
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; slice_validate(slice*, owner_token)
NEBOC_ABI_FUNCTION neboc_slice_validate
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp [rdi + NEBOC_SLICE_OWNER_OFFSET], rsi
    jne .invalid
    mov r8, [rdi + NEBOC_SLICE_ARENA_OFFSET]
    test r8, r8
    jz .invalid
    cmp qword [r8 + NEBOC_ARENA_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [r8 + NEBOC_ARENA_OWNER_OFFSET], rsi
    jne .invalid
    mov rax, [r8 + NEBOC_ARENA_GENERATION_OFFSET]
    cmp [rdi + NEBOC_SLICE_GENERATION_OFFSET], rax
    jne .invalid
    mov rcx, [rdi + NEBOC_SLICE_ELEMENT_SIZE_OFFSET]
    test rcx, rcx
    jz .invalid
    cmp rcx, NEBOC_SLICE_MAX_ELEMENT_SIZE
    ja .invalid
    mov rax, [rdi + NEBOC_SLICE_LENGTH_OFFSET]
    test rax, rax
    jz .empty
    mov r9, rax
    mul rcx
    test rdx, rdx
    jnz .limit
    mov r10, [rdi + NEBOC_SLICE_POINTER_OFFSET]
    test r10, r10
    jz .invalid
    mov r11, r10
    add r11, rax
    jc .limit
    cmp r10, [r8 + NEBOC_ARENA_BEGIN_OFFSET]
    jb .invalid
    cmp r11, [r8 + NEBOC_ARENA_CURRENT_OFFSET]
    ja .limit
    mov rax, r9
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.empty:
    mov rax, [rdi + NEBOC_SLICE_POINTER_OFFSET]
    test rax, rax
    jz .ok
    cmp rax, [r8 + NEBOC_ARENA_BEGIN_OFFSET]
    jb .invalid
    cmp rax, [r8 + NEBOC_ARENA_CURRENT_OFFSET]
    ja .limit
.ok:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; slice_at(slice*, index, owner_token, out_pointer*)
NEBOC_ABI_FUNCTION neboc_slice_at
    test rcx, rcx
    jz .invalid
    mov qword [rcx], 0
    test rdi, rdi
    jz .invalid
    test rdx, rdx
    jz .invalid
    cmp [rdi + NEBOC_SLICE_OWNER_OFFSET], rdx
    jne .invalid
    mov r8, [rdi + NEBOC_SLICE_ARENA_OFFSET]
    test r8, r8
    jz .invalid
    cmp qword [r8 + NEBOC_ARENA_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [r8 + NEBOC_ARENA_OWNER_OFFSET], rdx
    jne .invalid
    mov rax, [r8 + NEBOC_ARENA_GENERATION_OFFSET]
    cmp [rdi + NEBOC_SLICE_GENERATION_OFFSET], rax
    jne .invalid
    cmp rsi, [rdi + NEBOC_SLICE_LENGTH_OFFSET]
    jae .bounds
    mov rax, rsi
    mul qword [rdi + NEBOC_SLICE_ELEMENT_SIZE_OFFSET]
    test rdx, rdx
    jnz .bounds
    add rax, [rdi + NEBOC_SLICE_POINTER_OFFSET]
    jc .bounds
    mov [rcx], rax
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.bounds:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

section .note.GNU-stack noalloc noexec nowrite progbits
