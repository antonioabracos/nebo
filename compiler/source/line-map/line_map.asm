; Nebo Assembly — deterministic LineMap v0
;
; Purpose:
;   Build line-start offsets in one pass and translate byte offsets to stable
;   1-based line and Unicode-codepoint columns.
;
; Inputs:
;   Per-function arguments follow NEBOC_INTERNAL_ABI_v0.
;
; Outputs:
;   LineMap/SourceLocation structures and StatusCode in EAX.
;
; Status:
;   OK, INVALID_ARGUMENT or LIMIT_EXCEEDED.
;
; Clobbers:
;   Caller-saved registers and flags.
;
; Preserved:
;   RBX, RBP, R12, R13, R14, R15 and RSP.
;
; Stack:
;   16-byte aligned before internal calls; no red-zone dependency.
;
; Ownership:
;   The starts array is Arena-owned; source bytes are borrowed.
;
; Thread safety:
;   Build/reset require the exact owner token; lookups are read-only.
;
; Tests:
;   NEBO-SOURCE-GOLDEN-004, NEBO-SOURCE-GOLDEN-005,
;   NEBO-SOURCE-UNIT_ASM-006 and NEBO-SOURCE-DETERMINISM-008.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/support/memory/arena.inc"
%include "compiler/source/line-map/line_map.inc"

extern neboc_arena_allocate

section .text

; line_map_build(map*, source*, length, arena*, owner, source_id)
NEBOC_ABI_FUNCTION neboc_line_map_build
    test rdi, rdi
    jz .invalid_fast
    test rcx, rcx
    jz .invalid_fast
    test r8, r8
    jz .invalid_fast
    test r9, r9
    jz .invalid_fast
    test rdx, rdx
    jz .source_ready
    test rsi, rsi
    jz .invalid_fast
.source_ready:
    cmp qword [rdi + NEBOC_LINE_MAP_ACTIVE_OFFSET], 0
    jne .invalid_fast

    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32

    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    mov r15, r8
    mov [rsp + 8], r9
    mov qword [rsp], 0

    cmp qword [r14 + NEBOC_ARENA_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [r14 + NEBOC_ARENA_OWNER_OFFSET], r15
    jne .invalid

    mov r10d, 1
    xor r11d, r11d
.count_loop:
    cmp r11, r13
    jae .count_done
    mov al, [r12 + r11]
    cmp al, 10
    je .count_lf
    cmp al, 13
    je .count_cr
    inc r11
    jmp .count_loop
.count_lf:
    inc r11
    inc r10
    jmp .count_loop
.count_cr:
    inc r11
    cmp r11, r13
    jae .count_cr_store
    cmp byte [r12 + r11], 10
    jne .count_cr_store
    inc r11
.count_cr_store:
    inc r10
    jmp .count_loop
.count_done:
    mov [rsp + 16], r10
    mov rax, r10
    shr rax, 61
    jnz .limit
    mov rsi, r10
    shl rsi, 3
    mov rdi, r14
    mov edx, 8
    mov rcx, r15
    lea r8, [rsp]
    call neboc_arena_allocate
    test eax, eax
    jne .finish

    mov r9, [rsp]
    mov qword [r9], 0
    xor r10d, r10d
    mov r11d, 1
.fill_loop:
    cmp r10, r13
    jae .fill_done
    mov al, [r12 + r10]
    cmp al, 10
    je .fill_lf
    cmp al, 13
    je .fill_cr
    inc r10
    jmp .fill_loop
.fill_lf:
    inc r10
    mov [r9 + r11 * 8], r10
    inc r11
    jmp .fill_loop
.fill_cr:
    inc r10
    cmp r10, r13
    jae .fill_cr_store
    cmp byte [r12 + r10], 10
    jne .fill_cr_store
    inc r10
.fill_cr_store:
    mov [r9 + r11 * 8], r10
    inc r11
    jmp .fill_loop
.fill_done:
    cmp r11, [rsp + 16]
    jne .internal

    mov rax, [rbx + NEBOC_LINE_MAP_GENERATION_OFFSET]
    inc rax
    jnz .generation_ready
    mov eax, 1
.generation_ready:
    mov [rbx + NEBOC_LINE_MAP_SOURCE_OFFSET], r12
    mov [rbx + NEBOC_LINE_MAP_SOURCE_LENGTH_OFFSET], r13
    mov rdx, [rsp]
    mov [rbx + NEBOC_LINE_MAP_STARTS_OFFSET], rdx
    mov rdx, [rsp + 16]
    mov [rbx + NEBOC_LINE_MAP_LINE_COUNT_OFFSET], rdx
    mov [rbx + NEBOC_LINE_MAP_ARENA_OFFSET], r14
    mov [rbx + NEBOC_LINE_MAP_OWNER_OFFSET], r15
    mov rdx, [rsp + 8]
    mov [rbx + NEBOC_LINE_MAP_SOURCE_ID_OFFSET], rdx
    mov rdx, [r14 + NEBOC_ARENA_GENERATION_OFFSET]
    mov [rbx + NEBOC_LINE_MAP_ARENA_GENERATION_OFFSET], rdx
    mov [rbx + NEBOC_LINE_MAP_GENERATION_OFFSET], rax
    mov qword [rbx + NEBOC_LINE_MAP_ACTIVE_OFFSET], 1
    mov rdx, [rsp + 16]
    dec rdx
    mov [rbx + NEBOC_LINE_MAP_BREAK_COUNT_OFFSET], rdx
    mov qword [rbx + NEBOC_LINE_MAP_FLAGS_OFFSET], NEBOC_LINE_MAP_FLAG_NONE
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
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid_fast:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; line_map_validate(map*, owner)
NEBOC_ABI_FUNCTION neboc_line_map_validate
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp qword [rdi + NEBOC_LINE_MAP_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_LINE_MAP_OWNER_OFFSET], rsi
    jne .invalid
    cmp qword [rdi + NEBOC_LINE_MAP_STARTS_OFFSET], 0
    je .invalid
    cmp qword [rdi + NEBOC_LINE_MAP_LINE_COUNT_OFFSET], 0
    je .invalid
    cmp qword [rdi + NEBOC_LINE_MAP_SOURCE_ID_OFFSET], 0
    je .invalid
    mov r8, [rdi + NEBOC_LINE_MAP_SOURCE_LENGTH_OFFSET]
    test r8, r8
    jz .source_ok
    cmp qword [rdi + NEBOC_LINE_MAP_SOURCE_OFFSET], 0
    je .invalid
.source_ok:
    mov r8, [rdi + NEBOC_LINE_MAP_STARTS_OFFSET]
    cmp qword [r8], 0
    jne .invalid
    mov r8, [rdi + NEBOC_LINE_MAP_ARENA_OFFSET]
    test r8, r8
    jz .invalid
    cmp qword [r8 + NEBOC_ARENA_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [r8 + NEBOC_ARENA_OWNER_OFFSET], rsi
    jne .invalid
    mov rax, [r8 + NEBOC_ARENA_GENERATION_OFFSET]
    cmp [rdi + NEBOC_LINE_MAP_ARENA_GENERATION_OFFSET], rax
    jne .invalid
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; line_map_lookup(map*, byte_offset, owner, SourceLocation*)
NEBOC_ABI_FUNCTION neboc_line_map_lookup
    test rcx, rcx
    jz .invalid
    mov qword [rcx + 0], 0
    mov qword [rcx + 8], 0
    mov qword [rcx + 16], 0
    mov qword [rcx + 24], 0
    mov qword [rcx + 32], 0
    mov qword [rcx + 40], 0
    test rdi, rdi
    jz .invalid
    test rdx, rdx
    jz .invalid
    cmp qword [rdi + NEBOC_LINE_MAP_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_LINE_MAP_OWNER_OFFSET], rdx
    jne .invalid
    cmp rsi, [rdi + NEBOC_LINE_MAP_SOURCE_LENGTH_OFFSET]
    ja .invalid
    cmp rsi, [rdi + NEBOC_LINE_MAP_SOURCE_LENGTH_OFFSET]
    jae .offset_boundary_ok
    mov r8, [rdi + NEBOC_LINE_MAP_SOURCE_OFFSET]
    mov al, [r8 + rsi]
    and al, 0xc0
    cmp al, 0x80
    je .invalid
.offset_boundary_ok:
    mov r8, [rdi + NEBOC_LINE_MAP_STARTS_OFFSET]
    mov r9, [rdi + NEBOC_LINE_MAP_LINE_COUNT_OFFSET]
    test r8, r8
    jz .invalid
    test r9, r9
    jz .invalid
    xor r10d, r10d
    mov r11, r9
.search:
    cmp r10, r11
    jae .search_done
    mov rax, r10
    add rax, r11
    shr rax, 1
    mov rdx, [r8 + rax * 8]
    cmp rdx, rsi
    jbe .search_right
    mov r11, rax
    jmp .search
.search_right:
    lea r10, [rax + 1]
    jmp .search
.search_done:
    test r10, r10
    jz .invalid
    dec r10
    lea r9, [r10 + 1]
    mov r11, [r8 + r10 * 8]
    mov rax, [rdi + NEBOC_LINE_MAP_SOURCE_LENGTH_OFFSET]
    cmp r9, [rdi + NEBOC_LINE_MAP_LINE_COUNT_OFFSET]
    jae .line_end_ready
    mov rax, [r8 + r9 * 8]
    mov r8, [rdi + NEBOC_LINE_MAP_SOURCE_OFFSET]
    cmp rax, r11
    jbe .line_end_ready
    cmp byte [r8 + rax - 1], 10
    jne .trim_cr_only
    dec rax
    cmp rax, r11
    jbe .line_end_ready
    cmp byte [r8 + rax - 1], 13
    jne .line_end_ready
    dec rax
    jmp .line_end_ready
.trim_cr_only:
    cmp byte [r8 + rax - 1], 13
    jne .line_end_ready
    dec rax
.line_end_ready:
    mov rdx, [rdi + NEBOC_LINE_MAP_SOURCE_ID_OFFSET]
    mov [rcx + NEBOC_SOURCE_LOCATION_SOURCE_ID_OFFSET], rdx
    mov [rcx + NEBOC_SOURCE_LOCATION_BYTE_OFFSET], rsi
    mov [rcx + NEBOC_SOURCE_LOCATION_LINE_OFFSET], r9
    mov [rcx + NEBOC_SOURCE_LOCATION_LINE_START_OFFSET], r11
    mov [rcx + NEBOC_SOURCE_LOCATION_LINE_END_OFFSET], rax

    mov rdx, rsi
    cmp rdx, rax
    jbe .column_target_ready
    mov rdx, rax
.column_target_ready:
    mov r8, [rdi + NEBOC_LINE_MAP_SOURCE_OFFSET]
    mov r10, r11
    mov r9d, 1
.column_loop:
    cmp r10, rdx
    jae .column_done
    movzx eax, byte [r8 + r10]
    and eax, 0xc0
    cmp eax, 0x80
    je .column_next
    inc r9
.column_next:
    inc r10
    jmp .column_loop
.column_done:
    mov [rcx + NEBOC_SOURCE_LOCATION_COLUMN_OFFSET], r9
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; line_map_reset(map*, owner)
NEBOC_ABI_FUNCTION neboc_line_map_reset
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp [rdi + NEBOC_LINE_MAP_OWNER_OFFSET], rsi
    jne .invalid
    mov r8, [rdi + NEBOC_LINE_MAP_GENERATION_OFFSET]
    inc r8
    jnz .generation_ready
    mov r8d, 1
.generation_ready:
    mov r9, rdi
    xor eax, eax
    mov ecx, NEBOC_LINE_MAP_QWORDS
    cld
    rep stosq
    mov [r9 + NEBOC_LINE_MAP_GENERATION_OFFSET], r8
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
