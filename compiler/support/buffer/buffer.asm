; Nebo Assembly — deterministic checked Buffer v0
;
; Purpose:
;   Grow and append typed elements inside an Arena while preserving content.
;
; Inputs:
;   Per-function arguments follow NEBOC_INTERNAL_ABI_v0.
;
; Outputs:
;   StatusCode in EAX; finalize writes a checked Slice.
;
; Status:
;   INVALID_ARGUMENT for stale/finalized/ownership failures;
;   LIMIT_EXCEEDED for capacity, byte-size or pointer overflow.
;
; Clobbers:
;   Caller-saved registers and flags.
;
; Preserved:
;   RBX, RBP, R12, R13, R14, R15 and RSP.
;
; Stack:
;   16-byte aligned before every internal CALL; no red-zone dependency.
;
; Ownership:
;   Buffer borrows its Arena. Growth leaves superseded blocks in the Arena.
;
; Thread safety:
;   Every mutation requires the exact non-zero owner token.
;
; Errors:
;   Failed reserve/append leaves Buffer fields unchanged.
;
; Tests:
;   NEBO-MEM-UNIT_ASM-004 and NEBO-MEM-NEG-005.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/support/memory/arena.inc"
%include "compiler/support/slice/slice.inc"
%include "compiler/support/buffer/buffer.inc"

extern neboc_arena_validate
extern neboc_arena_allocate
extern neboc_slice_init

section .text

; buffer_init(buffer*, arena*, element_size, alignment, owner_token)
NEBOC_ABI_FUNCTION neboc_buffer_init
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    cmp rdx, NEBOC_BUFFER_MAX_ELEMENT_SIZE
    ja .invalid
    test rcx, rcx
    jz .invalid
    cmp rcx, NEBOC_ARENA_MAX_ALIGNMENT
    ja .invalid
    lea rax, [rcx - 1]
    test rcx, rax
    jnz .invalid
    test r8, r8
    jz .invalid
    cmp qword [rsi + NEBOC_ARENA_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [rsi + NEBOC_ARENA_OWNER_OFFSET], r8
    jne .invalid
    cmp qword [rdi + NEBOC_BUFFER_ARENA_OFFSET], 0
    jne .invalid

    mov [rdi + NEBOC_BUFFER_ARENA_OFFSET], rsi
    mov qword [rdi + NEBOC_BUFFER_DATA_OFFSET], 0
    mov qword [rdi + NEBOC_BUFFER_LENGTH_OFFSET], 0
    mov qword [rdi + NEBOC_BUFFER_CAPACITY_OFFSET], 0
    mov [rdi + NEBOC_BUFFER_ELEMENT_SIZE_OFFSET], rdx
    mov [rdi + NEBOC_BUFFER_ALIGNMENT_OFFSET], rcx
    mov [rdi + NEBOC_BUFFER_OWNER_OFFSET], r8
    mov rax, [rsi + NEBOC_ARENA_GENERATION_OFFSET]
    mov [rdi + NEBOC_BUFFER_ARENA_GENERATION_OFFSET], rax
    mov qword [rdi + NEBOC_BUFFER_FINALIZED_OFFSET], 0
    mov qword [rdi + NEBOC_BUFFER_GROWTH_COUNT_OFFSET], 0
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; buffer_validate(buffer*, owner_token)
NEBOC_ABI_FUNCTION neboc_buffer_validate
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp [rdi + NEBOC_BUFFER_OWNER_OFFSET], rsi
    jne .invalid
    mov r8, [rdi + NEBOC_BUFFER_ARENA_OFFSET]
    test r8, r8
    jz .invalid
    cmp qword [r8 + NEBOC_ARENA_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [r8 + NEBOC_ARENA_OWNER_OFFSET], rsi
    jne .invalid
    mov rax, [r8 + NEBOC_ARENA_GENERATION_OFFSET]
    cmp [rdi + NEBOC_BUFFER_ARENA_GENERATION_OFFSET], rax
    jne .invalid
    mov rcx, [rdi + NEBOC_BUFFER_ELEMENT_SIZE_OFFSET]
    test rcx, rcx
    jz .invalid
    cmp rcx, NEBOC_BUFFER_MAX_ELEMENT_SIZE
    ja .invalid
    mov rdx, [rdi + NEBOC_BUFFER_ALIGNMENT_OFFSET]
    test rdx, rdx
    jz .invalid
    cmp rdx, NEBOC_ARENA_MAX_ALIGNMENT
    ja .invalid
    lea rax, [rdx - 1]
    test rdx, rax
    jnz .invalid
    mov rax, [rdi + NEBOC_BUFFER_LENGTH_OFFSET]
    cmp rax, [rdi + NEBOC_BUFFER_CAPACITY_OFFSET]
    ja .invalid
    cmp qword [rdi + NEBOC_BUFFER_FINALIZED_OFFSET], 1
    ja .invalid
    mov rax, [rdi + NEBOC_BUFFER_CAPACITY_OFFSET]
    test rax, rax
    jz .empty
    mul rcx
    test rdx, rdx
    jnz .limit
    cmp rax, NEBOC_BUFFER_HARD_MAX_BYTES
    ja .limit
    mov r9, [rdi + NEBOC_BUFFER_DATA_OFFSET]
    test r9, r9
    jz .invalid
    mov r10, r9
    add r10, rax
    jc .limit
    cmp r9, [r8 + NEBOC_ARENA_BEGIN_OFFSET]
    jb .invalid
    cmp r10, [r8 + NEBOC_ARENA_CURRENT_OFFSET]
    ja .limit
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.empty:
    cmp qword [rdi + NEBOC_BUFFER_DATA_OFFSET], 0
    jne .invalid
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; buffer_reserve(buffer*, minimum_capacity, owner_token)
NEBOC_ABI_FUNCTION neboc_buffer_reserve
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16

    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov qword [rsp], 0

    mov rdi, rbx
    mov rsi, r13
    call neboc_buffer_validate
    test eax, eax
    jne .finish
    cmp qword [rbx + NEBOC_BUFFER_FINALIZED_OFFSET], 0
    jne .invalid
    cmp r12, [rbx + NEBOC_BUFFER_CAPACITY_OFFSET]
    jbe .ok

    mov rcx, [rbx + NEBOC_BUFFER_ELEMENT_SIZE_OFFSET]
    mov rax, NEBOC_BUFFER_HARD_MAX_BYTES
    xor edx, edx
    div rcx
    mov r15, rax
    cmp r12, r15
    ja .limit

    mov r14, [rbx + NEBOC_BUFFER_CAPACITY_OFFSET]
    test r14, r14
    jnz .growth_loop
    mov r14d, NEBOC_BUFFER_MIN_CAPACITY
.growth_loop:
    cmp r14, r12
    jae .capacity_ready
    mov rax, r15
    shr rax, 1
    cmp r14, rax
    ja .use_required
    shl r14, 1
    jc .limit
    jmp .growth_loop
.use_required:
    mov r14, r12
.capacity_ready:
    mov rax, r14
    mul qword [rbx + NEBOC_BUFFER_ELEMENT_SIZE_OFFSET]
    test rdx, rdx
    jnz .limit
    cmp rax, NEBOC_BUFFER_HARD_MAX_BYTES
    ja .limit

    mov rdi, [rbx + NEBOC_BUFFER_ARENA_OFFSET]
    mov rsi, rax
    mov rdx, [rbx + NEBOC_BUFFER_ALIGNMENT_OFFSET]
    mov rcx, r13
    lea r8, [rsp]
    call neboc_arena_allocate
    test eax, eax
    jne .finish

    mov r15, [rsp]
    mov rax, [rbx + NEBOC_BUFFER_LENGTH_OFFSET]
    mul qword [rbx + NEBOC_BUFFER_ELEMENT_SIZE_OFFSET]
    test rdx, rdx
    jnz .internal
    mov rcx, rax
    test rcx, rcx
    jz .store
    mov rsi, [rbx + NEBOC_BUFFER_DATA_OFFSET]
    mov rdi, r15
    cld
    rep movsb
.store:
    mov [rbx + NEBOC_BUFFER_DATA_OFFSET], r15
    mov [rbx + NEBOC_BUFFER_CAPACITY_OFFSET], r14
    inc qword [rbx + NEBOC_BUFFER_GROWTH_COUNT_OFFSET]
.ok:
    xor eax, eax
    jmp .finish
.invalid:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
    jmp .finish
.limit:
    mov eax, NEBOC_STATUS_LIMIT_EXCEEDED
    jmp .finish
.internal:
    mov eax, NEBOC_STATUS_INTERNAL_ERROR
.finish:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret

; buffer_append(buffer*, source*, element_count, owner_token)
NEBOC_ABI_FUNCTION neboc_buffer_append
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16

    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx

    mov rdi, rbx
    mov rsi, r14
    call neboc_buffer_validate
    test eax, eax
    jne .finish
    cmp qword [rbx + NEBOC_BUFFER_FINALIZED_OFFSET], 0
    jne .invalid
    test r13, r13
    jz .ok
    test r12, r12
    jz .invalid

    mov r15, [rbx + NEBOC_BUFFER_LENGTH_OFFSET]
    add r15, r13
    jc .limit

    mov rdi, rbx
    mov rsi, r15
    mov rdx, r14
    call neboc_buffer_reserve
    test eax, eax
    jne .finish

    mov rax, [rbx + NEBOC_BUFFER_LENGTH_OFFSET]
    mul qword [rbx + NEBOC_BUFFER_ELEMENT_SIZE_OFFSET]
    test rdx, rdx
    jnz .internal
    mov rdi, [rbx + NEBOC_BUFFER_DATA_OFFSET]
    add rdi, rax
    jc .limit

    mov rax, r13
    mul qword [rbx + NEBOC_BUFFER_ELEMENT_SIZE_OFFSET]
    test rdx, rdx
    jnz .limit
    mov rcx, rax
    mov rsi, r12
    cld
    rep movsb
    mov [rbx + NEBOC_BUFFER_LENGTH_OFFSET], r15
.ok:
    xor eax, eax
    jmp .finish
.invalid:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
    jmp .finish
.limit:
    mov eax, NEBOC_STATUS_LIMIT_EXCEEDED
    jmp .finish
.internal:
    mov eax, NEBOC_STATUS_INTERNAL_ERROR
.finish:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret

; buffer_finalize(buffer*, out_slice*, owner_token)
NEBOC_ABI_FUNCTION neboc_buffer_finalize
    push rbx
    push r12
    push r13

    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    test r12, r12
    jz .invalid

    mov rdi, rbx
    mov rsi, r13
    call neboc_buffer_validate
    test eax, eax
    jne .finish
    cmp qword [rbx + NEBOC_BUFFER_FINALIZED_OFFSET], 0
    jne .invalid

    mov rdi, r12
    mov rsi, [rbx + NEBOC_BUFFER_DATA_OFFSET]
    mov rdx, [rbx + NEBOC_BUFFER_LENGTH_OFFSET]
    mov rcx, [rbx + NEBOC_BUFFER_ELEMENT_SIZE_OFFSET]
    mov r8, [rbx + NEBOC_BUFFER_ARENA_OFFSET]
    mov r9, r13
    call neboc_slice_init
    test eax, eax
    jne .finish
    mov qword [rbx + NEBOC_BUFFER_FINALIZED_OFFSET], 1
    xor eax, eax
    jmp .finish
.invalid:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
.finish:
    pop r13
    pop r12
    pop rbx
    cld
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
