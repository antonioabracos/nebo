; Nebo Assembly — checked Arena and bump allocation v0
;
; Purpose:
;   Allocate monotonically inside one active MemoryRegion and support checked
;   marks, rewind, reset, accounting and stale-generation detection.
;
; Inputs:
;   Per-function arguments follow NEBOC_INTERNAL_ABI_v0.
;
; Outputs:
;   StatusCode in EAX and explicit out pointers/marks.
;
; Status:
;   INVALID_ARGUMENT for ownership/generation errors; LIMIT_EXCEEDED for bounds
;   or arithmetic overflow.
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
;   Arena borrows its region; arena_destroy never releases the region.
;
; Thread safety:
;   Every mutation requires the exact non-zero owner token.
;
; Errors:
;   All pointer arithmetic, alignment and bounds calculations are checked.
;
; Tests:
;   NEBO-MEM-UNIT_ASM-001, NEBO-MEM-NEG-002, NEBO-MEM-UNIT_ASM-003,
;   NEBO-MEM-UNIT_ASM-006 and NEBO-MEM-SECURITY-008.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/support/memory/memory_region.inc"
%include "compiler/support/memory/arena.inc"

section .text

; arena_init(arena*, region*, capacity_bytes, owner_token)
NEBOC_ABI_FUNCTION neboc_arena_init
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    test rcx, rcx
    jz .invalid
    cmp qword [rdi + NEBOC_ARENA_ACTIVE_OFFSET], 0
    jne .invalid
    cmp qword [rsi + NEBOC_MEMORY_REGION_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [rsi + NEBOC_MEMORY_REGION_OWNER_OFFSET], rcx
    jne .invalid
    cmp rdx, [rsi + NEBOC_MEMORY_REGION_COMMITTED_OFFSET]
    ja .limit
    cmp rdx, [rsi + NEBOC_MEMORY_REGION_MAXIMUM_OFFSET]
    ja .limit
    mov rax, [rsi + NEBOC_MEMORY_REGION_BASE_OFFSET]
    test rax, rax
    jz .invalid
    mov r8, rax
    add r8, rdx
    jc .limit

    mov r9, [rdi + NEBOC_ARENA_GENERATION_OFFSET]
    inc r9
    jnz .generation_ready
    mov r9d, 1
.generation_ready:
    mov [rdi + NEBOC_ARENA_REGION_OFFSET], rsi
    mov [rdi + NEBOC_ARENA_BEGIN_OFFSET], rax
    mov [rdi + NEBOC_ARENA_CURRENT_OFFSET], rax
    mov [rdi + NEBOC_ARENA_END_OFFSET], r8
    mov [rdi + NEBOC_ARENA_MAXIMUM_OFFSET], rdx
    mov [rdi + NEBOC_ARENA_OWNER_OFFSET], rcx
    mov [rdi + NEBOC_ARENA_GENERATION_OFFSET], r9
    mov rax, [rsi + NEBOC_MEMORY_REGION_GENERATION_OFFSET]
    mov [rdi + NEBOC_ARENA_REGION_GENERATION_OFFSET], rax
    mov qword [rdi + NEBOC_ARENA_ACTIVE_OFFSET], 1
    mov qword [rdi + NEBOC_ARENA_ALLOCATED_BYTES_OFFSET], 0
    mov qword [rdi + NEBOC_ARENA_HIGH_WATER_OFFSET], 0
    mov qword [rdi + NEBOC_ARENA_ALLOCATION_COUNT_OFFSET], 0
    mov qword [rdi + NEBOC_ARENA_REWIND_COUNT_OFFSET], 0
    mov qword [rdi + NEBOC_ARENA_RESET_COUNT_OFFSET], 0
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; arena_validate(arena*, owner_token)
NEBOC_ABI_FUNCTION neboc_arena_validate
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp qword [rdi + NEBOC_ARENA_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_ARENA_OWNER_OFFSET], rsi
    jne .invalid
    mov rax, [rdi + NEBOC_ARENA_REGION_OFFSET]
    test rax, rax
    jz .invalid
    cmp qword [rax + NEBOC_MEMORY_REGION_ACTIVE_OFFSET], 1
    jne .invalid
    mov rcx, [rax + NEBOC_MEMORY_REGION_GENERATION_OFFSET]
    cmp [rdi + NEBOC_ARENA_REGION_GENERATION_OFFSET], rcx
    jne .invalid
    mov rcx, [rdi + NEBOC_ARENA_BEGIN_OFFSET]
    cmp rcx, [rdi + NEBOC_ARENA_CURRENT_OFFSET]
    ja .invalid
    mov rcx, [rdi + NEBOC_ARENA_CURRENT_OFFSET]
    cmp rcx, [rdi + NEBOC_ARENA_END_OFFSET]
    ja .invalid
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; arena_allocate(arena*, size, alignment, owner_token, out_pointer*)
NEBOC_ABI_FUNCTION neboc_arena_allocate
    test r8, r8
    jz .invalid
    mov qword [r8], 0
    test rdi, rdi
    jz .invalid
    test rcx, rcx
    jz .invalid
    cmp qword [rdi + NEBOC_ARENA_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_ARENA_OWNER_OFFSET], rcx
    jne .invalid
    mov r10, [rdi + NEBOC_ARENA_REGION_OFFSET]
    test r10, r10
    jz .invalid
    cmp qword [r10 + NEBOC_MEMORY_REGION_ACTIVE_OFFSET], 1
    jne .invalid
    mov rax, [r10 + NEBOC_MEMORY_REGION_GENERATION_OFFSET]
    cmp [rdi + NEBOC_ARENA_REGION_GENERATION_OFFSET], rax
    jne .invalid

    test rdx, rdx
    jz .invalid
    cmp rdx, NEBOC_ARENA_MAX_ALIGNMENT
    ja .invalid
    lea rax, [rdx - 1]
    test rdx, rax
    jnz .invalid

    mov r11, [rdi + NEBOC_ARENA_CURRENT_OFFSET]
    add r11, rax
    jc .limit
    not rax
    and r11, rax
    mov r9, r11
    add r9, rsi
    jc .limit
    cmp r9, [rdi + NEBOC_ARENA_END_OFFSET]
    ja .limit

    mov [r8], r11
    test rsi, rsi
    jz .zero_size
    mov [rdi + NEBOC_ARENA_CURRENT_OFFSET], r9
    mov rax, r9
    sub rax, [rdi + NEBOC_ARENA_BEGIN_OFFSET]
    mov [rdi + NEBOC_ARENA_ALLOCATED_BYTES_OFFSET], rax
    cmp rax, [rdi + NEBOC_ARENA_HIGH_WATER_OFFSET]
    jbe .count
    mov [rdi + NEBOC_ARENA_HIGH_WATER_OFFSET], rax
.count:
    inc qword [rdi + NEBOC_ARENA_ALLOCATION_COUNT_OFFSET]
.zero_size:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; arena_allocate_zeroed(arena*, size, alignment, owner_token, out_pointer*)
NEBOC_ABI_FUNCTION neboc_arena_allocate_zeroed
    push rbx
    push r12
    push r13
    mov rbx, rsi
    mov r12, r8
    call neboc_arena_allocate
    test eax, eax
    jne .zero_finish
    mov rdi, [r12]
    mov rcx, rbx
    xor eax, eax
    rep stosb
    xor eax, eax
.zero_finish:
    pop r13
    pop r12
    pop rbx
    cld
    ret

; arena_align(arena*, alignment, owner_token, out_pointer*)
NEBOC_ABI_FUNCTION neboc_arena_align
    test rcx, rcx
    jz .invalid
    push rbx
    push r12
    push r13
    mov rbx, rdi
    mov r12, rcx
    mov r8, rcx
    mov rcx, rdx
    mov rdx, rsi
    xor esi, esi
    call neboc_arena_allocate
    test eax, eax
    jne .align_finish
    mov rax, [r12]
    mov rdx, rax
    sub rdx, [rbx + NEBOC_ARENA_BEGIN_OFFSET]
    jc .align_internal
    mov [rbx + NEBOC_ARENA_CURRENT_OFFSET], rax
    mov [rbx + NEBOC_ARENA_ALLOCATED_BYTES_OFFSET], rdx
    cmp rdx, [rbx + NEBOC_ARENA_HIGH_WATER_OFFSET]
    jbe .align_ok
    mov [rbx + NEBOC_ARENA_HIGH_WATER_OFFSET], rdx
.align_ok:
    xor eax, eax
    jmp .align_finish
.align_internal:
    mov eax, NEBOC_STATUS_INTERNAL_ERROR
.align_finish:
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; arena_mark(arena*, owner_token, mark*)
NEBOC_ABI_FUNCTION neboc_arena_mark
    test rdx, rdx
    jz .invalid
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp qword [rdi + NEBOC_ARENA_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_ARENA_OWNER_OFFSET], rsi
    jne .invalid
    mov rax, [rdi + NEBOC_ARENA_REGION_OFFSET]
    test rax, rax
    jz .invalid
    mov rcx, [rax + NEBOC_MEMORY_REGION_GENERATION_OFFSET]
    cmp [rdi + NEBOC_ARENA_REGION_GENERATION_OFFSET], rcx
    jne .invalid
    mov rax, [rdi + NEBOC_ARENA_CURRENT_OFFSET]
    sub rax, [rdi + NEBOC_ARENA_BEGIN_OFFSET]
    jc .invalid
    mov [rdx + NEBOC_ARENA_MARK_ARENA_OFFSET], rdi
    mov [rdx + NEBOC_ARENA_MARK_OFFSET_OFFSET], rax
    mov rax, [rdi + NEBOC_ARENA_GENERATION_OFFSET]
    mov [rdx + NEBOC_ARENA_MARK_GENERATION_OFFSET], rax
    mov rax, [rdi + NEBOC_ARENA_REGION_GENERATION_OFFSET]
    mov [rdx + NEBOC_ARENA_MARK_REGION_GENERATION_OFFSET], rax
    mov [rdx + NEBOC_ARENA_MARK_OWNER_OFFSET], rsi
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; arena_rewind(arena*, owner_token, mark*)
NEBOC_ABI_FUNCTION neboc_arena_rewind
    test rdx, rdx
    jz .invalid
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp qword [rdi + NEBOC_ARENA_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_ARENA_OWNER_OFFSET], rsi
    jne .invalid
    cmp [rdx + NEBOC_ARENA_MARK_ARENA_OFFSET], rdi
    jne .invalid
    cmp [rdx + NEBOC_ARENA_MARK_OWNER_OFFSET], rsi
    jne .invalid
    mov rax, [rdi + NEBOC_ARENA_GENERATION_OFFSET]
    cmp [rdx + NEBOC_ARENA_MARK_GENERATION_OFFSET], rax
    jne .invalid
    mov rcx, [rdi + NEBOC_ARENA_REGION_GENERATION_OFFSET]
    cmp [rdx + NEBOC_ARENA_MARK_REGION_GENERATION_OFFSET], rcx
    jne .invalid
    mov rax, [rdi + NEBOC_ARENA_REGION_OFFSET]
    test rax, rax
    jz .invalid
    cmp qword [rax + NEBOC_MEMORY_REGION_ACTIVE_OFFSET], 1
    jne .invalid
    mov rax, [rax + NEBOC_MEMORY_REGION_GENERATION_OFFSET]
    cmp rax, rcx
    jne .invalid
    mov rax, [rdx + NEBOC_ARENA_MARK_OFFSET_OFFSET]
    cmp rax, [rdi + NEBOC_ARENA_ALLOCATED_BYTES_OFFSET]
    ja .invalid
    cmp rax, [rdi + NEBOC_ARENA_MAXIMUM_OFFSET]
    ja .invalid
    mov rcx, [rdi + NEBOC_ARENA_BEGIN_OFFSET]
    add rcx, rax
    jc .invalid
    mov [rdi + NEBOC_ARENA_CURRENT_OFFSET], rcx
    mov [rdi + NEBOC_ARENA_ALLOCATED_BYTES_OFFSET], rax
    inc qword [rdi + NEBOC_ARENA_REWIND_COUNT_OFFSET]
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; arena_reset(arena*, owner_token)
NEBOC_ABI_FUNCTION neboc_arena_reset
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp qword [rdi + NEBOC_ARENA_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_ARENA_OWNER_OFFSET], rsi
    jne .invalid
    mov rax, [rdi + NEBOC_ARENA_REGION_OFFSET]
    test rax, rax
    jz .invalid
    cmp qword [rax + NEBOC_MEMORY_REGION_ACTIVE_OFFSET], 1
    jne .invalid
    mov rcx, [rax + NEBOC_MEMORY_REGION_GENERATION_OFFSET]
    cmp [rdi + NEBOC_ARENA_REGION_GENERATION_OFFSET], rcx
    jne .invalid
    mov rax, [rdi + NEBOC_ARENA_BEGIN_OFFSET]
    mov [rdi + NEBOC_ARENA_CURRENT_OFFSET], rax
    mov qword [rdi + NEBOC_ARENA_ALLOCATED_BYTES_OFFSET], 0
    mov rax, [rdi + NEBOC_ARENA_GENERATION_OFFSET]
    inc rax
    jnz .reset_generation_ready
    mov eax, 1
.reset_generation_ready:
    mov [rdi + NEBOC_ARENA_GENERATION_OFFSET], rax
    inc qword [rdi + NEBOC_ARENA_RESET_COUNT_OFFSET]
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; arena_destroy(arena*, owner_token)
NEBOC_ABI_FUNCTION neboc_arena_destroy
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp qword [rdi + NEBOC_ARENA_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_ARENA_OWNER_OFFSET], rsi
    jne .invalid
    mov rax, [rdi + NEBOC_ARENA_GENERATION_OFFSET]
    inc rax
    jnz .destroy_generation_ready
    mov eax, 1
.destroy_generation_ready:
    mov qword [rdi + NEBOC_ARENA_REGION_OFFSET], 0
    mov qword [rdi + NEBOC_ARENA_BEGIN_OFFSET], 0
    mov qword [rdi + NEBOC_ARENA_CURRENT_OFFSET], 0
    mov qword [rdi + NEBOC_ARENA_END_OFFSET], 0
    mov qword [rdi + NEBOC_ARENA_MAXIMUM_OFFSET], 0
    mov qword [rdi + NEBOC_ARENA_REGION_GENERATION_OFFSET], 0
    mov qword [rdi + NEBOC_ARENA_ACTIVE_OFFSET], 0
    mov qword [rdi + NEBOC_ARENA_ALLOCATED_BYTES_OFFSET], 0
    mov [rdi + NEBOC_ARENA_GENERATION_OFFSET], rax
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; memory_span_at(span*, byte_index, width, out_pointer*)
NEBOC_ABI_FUNCTION neboc_memory_span_at
    test rcx, rcx
    jz .invalid
    mov qword [rcx], 0
    test rdi, rdi
    jz .invalid
    mov r8, [rdi + NEBOC_MEMORY_SPAN_ARENA_OFFSET]
    test r8, r8
    jz .invalid
    cmp qword [r8 + NEBOC_ARENA_ACTIVE_OFFSET], 1
    jne .invalid
    mov rax, [r8 + NEBOC_ARENA_GENERATION_OFFSET]
    cmp [rdi + NEBOC_MEMORY_SPAN_GENERATION_OFFSET], rax
    jne .invalid
    mov rax, [rdi + NEBOC_MEMORY_SPAN_LENGTH_OFFSET]
    cmp rsi, rax
    ja .bounds
    sub rax, rsi
    cmp rdx, rax
    ja .bounds
    mov rax, [rdi + NEBOC_MEMORY_SPAN_POINTER_OFFSET]
    test rax, rax
    jnz .pointer_ready
    cmp qword [rdi + NEBOC_MEMORY_SPAN_LENGTH_OFFSET], 0
    jne .invalid
.pointer_ready:
    add rax, rsi
    jc .bounds
    mov [rcx], rax
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.bounds:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

section .note.GNU-stack noalloc noexec nowrite progbits
