; Nebo Assembly — checked TypedArray v0
;
; Purpose:
;   Add an explicit stable type ID to Buffer storage without templates or
;   opaque universal collections.
;
; Inputs:
;   Per-function arguments follow NEBOC_INTERNAL_ABI_v0.
;
; Outputs:
;   StatusCode in EAX and explicit out pointers/Slices.
;
; Status:
;   INVALID_ARGUMENT for type, ownership or lifecycle mismatches;
;   LIMIT_EXCEEDED for checked capacity/bounds failures.
;
; Clobbers:
;   Caller-saved registers and flags.
;
; Preserved:
;   RBX, RBP, R12, R13, R14, R15 and RSP.
;
; Stack:
;   16-byte aligned before internal CALLs; no red-zone dependency.
;
; Ownership:
;   TypedArray borrows its Arena through the embedded Buffer.
;
; Thread safety:
;   Mutations require the Buffer owner token.
;
; Errors:
;   Type mismatch is rejected before any mutation.
;
; Tests:
;   NEBO-MEM-UNIT_ASM-004 and NEBO-MEM-NEG-005.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/support/memory/arena.inc"
%include "compiler/support/buffer/buffer.inc"
%include "compiler/support/array/typed_array.inc"

extern neboc_buffer_init
extern neboc_buffer_validate
extern neboc_buffer_append
extern neboc_buffer_finalize

section .text

; typed_array_init(array*, arena*, type_id, element_size, alignment, owner_token)
NEBOC_ABI_FUNCTION neboc_typed_array_init
    test rdi, rdi
    jz .invalid
    test rdx, rdx
    jz .invalid
    push rbx
    push r12
    push r13
    mov rbx, rdi
    mov r12, rdx
    mov r13, r9
    mov rdx, rcx
    mov rcx, r8
    mov r8, r13
    call neboc_buffer_init
    test eax, eax
    jne .finish
    mov [rbx + NEBOC_TYPED_ARRAY_TYPE_ID_OFFSET], r12
    xor eax, eax
    jmp .finish
.invalid:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
    cld
    ret
.finish:
    pop r13
    pop r12
    pop rbx
    cld
    ret

; typed_array_validate(array*, type_id, owner_token)
NEBOC_ABI_FUNCTION neboc_typed_array_validate
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp [rdi + NEBOC_TYPED_ARRAY_TYPE_ID_OFFSET], rsi
    jne .invalid
    mov rsi, rdx
    jmp neboc_buffer_validate
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; typed_array_push(array*, type_id, element*, owner_token)
NEBOC_ABI_FUNCTION neboc_typed_array_push
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp [rdi + NEBOC_TYPED_ARRAY_TYPE_ID_OFFSET], rsi
    jne .invalid
    mov rsi, rdx
    mov edx, 1
    jmp neboc_buffer_append
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; typed_array_at(array*, type_id, index, owner_token, out_pointer*)
NEBOC_ABI_FUNCTION neboc_typed_array_at
    test r8, r8
    jz .invalid
    mov qword [r8], 0
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp [rdi + NEBOC_TYPED_ARRAY_TYPE_ID_OFFSET], rsi
    jne .invalid
    cmp rdx, [rdi + NEBOC_BUFFER_LENGTH_OFFSET]
    jae .bounds
    mov rax, rdx
    mul qword [rdi + NEBOC_BUFFER_ELEMENT_SIZE_OFFSET]
    test rdx, rdx
    jnz .bounds
    add rax, [rdi + NEBOC_BUFFER_DATA_OFFSET]
    jc .bounds
    cmp [rdi + NEBOC_BUFFER_OWNER_OFFSET], rcx
    jne .invalid
    mov r9, [rdi + NEBOC_BUFFER_ARENA_OFFSET]
    test r9, r9
    jz .invalid
    cmp qword [r9 + NEBOC_ARENA_ACTIVE_OFFSET], 1
    jne .invalid
    mov r10, [r9 + NEBOC_ARENA_GENERATION_OFFSET]
    cmp [rdi + NEBOC_BUFFER_ARENA_GENERATION_OFFSET], r10
    jne .invalid
    mov [r8], rax
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.bounds:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; typed_array_finalize(array*, type_id, out_slice*, owner_token)
NEBOC_ABI_FUNCTION neboc_typed_array_finalize
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp [rdi + NEBOC_TYPED_ARRAY_TYPE_ID_OFFSET], rsi
    jne .invalid
    mov rsi, rdx
    mov rdx, rcx
    jmp neboc_buffer_finalize
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
