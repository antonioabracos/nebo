; Nebo Assembly — deterministic StringPool and identifier interning v0
;
; Purpose:
;   Copy and intern byte strings in an Arena, assigning stable typed IDs that
;   depend only on pool kind and insertion ordinal.
;
; Inputs:
;   Per-function arguments follow NEBOC_INTERNAL_ABI_v0.
;
; Outputs:
;   StatusCode in EAX; IDs and StringView values use explicit out pointers.
;
; Status:
;   INVALID_ARGUMENT for stale ownership/state; INVALID_SOURCE for non-ASCII
;   identifier spelling; LIMIT_EXCEEDED for capacity or arithmetic limits.
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
;   Pool entries and copied bytes belong to the Arena. There is no individual
;   string release.
;
; Thread safety:
;   Every operation requires the exact non-zero Arena owner token.
;
; Errors:
;   Hash equality is followed by length and complete byte comparison.
;
; Tests:
;   NEBO-MEM-DETERMINISM-007.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/support/memory/arena.inc"
%include "compiler/support/hash/fnv1a.inc"
%include "compiler/support/id/typed_id.inc"
%include "compiler/support/string/string_pool.inc"

extern neboc_arena_allocate_zeroed
extern neboc_arena_allocate
extern neboc_hash_fnv1a32

section .text

; identifier_validate_ascii(bytes*, length)
NEBOC_ABI_FUNCTION neboc_identifier_validate_ascii
    test rsi, rsi
    jz .invalid_source
    test rdi, rdi
    jz .invalid

    movzx eax, byte [rdi]
    cmp al, '_'
    je .rest
    cmp al, 'A'
    jb .invalid_source
    cmp al, 'Z'
    jbe .rest
    cmp al, 'a'
    jb .invalid_source
    cmp al, 'z'
    ja .invalid_source
.rest:
    mov ecx, 1
.loop:
    cmp rcx, rsi
    jae .ok
    movzx eax, byte [rdi + rcx]
    cmp al, '_'
    je .next
    cmp al, '0'
    jb .check_upper
    cmp al, '9'
    jbe .next
.check_upper:
    cmp al, 'A'
    jb .invalid_source
    cmp al, 'Z'
    jbe .next
    cmp al, 'a'
    jb .invalid_source
    cmp al, 'z'
    ja .invalid_source
.next:
    inc rcx
    jmp .loop
.ok:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.invalid_source:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE

; string_pool_init(pool*, arena*, capacity, kind, owner_token)
NEBOC_ABI_FUNCTION neboc_string_pool_init
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
    mov r15, r8
    mov qword [rsp], 0

    test rbx, rbx
    jz .invalid
    test r12, r12
    jz .invalid
    test r13, r13
    jz .invalid
    cmp r13, NEBOC_STRING_POOL_MAX_ENTRIES
    ja .limit
    cmp r14, NEBOC_ID_KIND_STRING
    je .kind_ok
    cmp r14, NEBOC_ID_KIND_IDENTIFIER
    jne .invalid
.kind_ok:
    test r15, r15
    jz .invalid
    cmp qword [rbx + NEBOC_STRING_POOL_ACTIVE_OFFSET], 0
    jne .invalid
    cmp qword [r12 + NEBOC_ARENA_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [r12 + NEBOC_ARENA_OWNER_OFFSET], r15
    jne .invalid

    mov rax, r13
    mov ecx, NEBOC_STRING_ENTRY_SIZE
    mul rcx
    test rdx, rdx
    jnz .limit
    cmp rax, NEBOC_STRING_POOL_MAX_TABLE_BYTES
    ja .limit

    mov rdi, r12
    mov rsi, rax
    mov edx, 8
    mov rcx, r15
    lea r8, [rsp]
    call neboc_arena_allocate_zeroed
    test eax, eax
    jne .finish

    mov rax, [rsp]
    test rax, rax
    jz .internal
    mov [rbx + NEBOC_STRING_POOL_ARENA_OFFSET], r12
    mov [rbx + NEBOC_STRING_POOL_ENTRIES_OFFSET], rax
    mov qword [rbx + NEBOC_STRING_POOL_COUNT_OFFSET], 0
    mov [rbx + NEBOC_STRING_POOL_CAPACITY_OFFSET], r13
    mov [rbx + NEBOC_STRING_POOL_KIND_OFFSET], r14
    mov [rbx + NEBOC_STRING_POOL_OWNER_OFFSET], r15
    mov rax, [r12 + NEBOC_ARENA_GENERATION_OFFSET]
    mov [rbx + NEBOC_STRING_POOL_ARENA_GENERATION_OFFSET], rax
    mov qword [rbx + NEBOC_STRING_POOL_TOTAL_BYTES_OFFSET], 0
    mov qword [rbx + NEBOC_STRING_POOL_HASH_CALLS_OFFSET], 0
    mov qword [rbx + NEBOC_STRING_POOL_COLLISION_COUNT_OFFSET], 0
    mov qword [rbx + NEBOC_STRING_POOL_ACTIVE_OFFSET], 1
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

; string_pool_validate(pool*, owner_token)
NEBOC_ABI_FUNCTION neboc_string_pool_validate
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp qword [rdi + NEBOC_STRING_POOL_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_STRING_POOL_OWNER_OFFSET], rsi
    jne .invalid
    mov r8, [rdi + NEBOC_STRING_POOL_ARENA_OFFSET]
    test r8, r8
    jz .invalid
    cmp qword [r8 + NEBOC_ARENA_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [r8 + NEBOC_ARENA_OWNER_OFFSET], rsi
    jne .invalid
    mov rax, [r8 + NEBOC_ARENA_GENERATION_OFFSET]
    cmp [rdi + NEBOC_STRING_POOL_ARENA_GENERATION_OFFSET], rax
    jne .invalid
    mov rax, [rdi + NEBOC_STRING_POOL_KIND_OFFSET]
    cmp rax, NEBOC_ID_KIND_STRING
    je .kind_ok
    cmp rax, NEBOC_ID_KIND_IDENTIFIER
    jne .invalid
.kind_ok:
    mov rax, [rdi + NEBOC_STRING_POOL_CAPACITY_OFFSET]
    test rax, rax
    jz .invalid
    cmp rax, NEBOC_STRING_POOL_MAX_ENTRIES
    ja .limit
    cmp [rdi + NEBOC_STRING_POOL_COUNT_OFFSET], rax
    ja .invalid
    mov r9, [rdi + NEBOC_STRING_POOL_ENTRIES_OFFSET]
    test r9, r9
    jz .invalid

    xor r10d, r10d
.entry_loop:
    cmp r10, [rdi + NEBOC_STRING_POOL_COUNT_OFFSET]
    jae .ok
    mov r11, r10
    shl r11, 5
    add r11, r9
    jc .limit

    mov rax, [rdi + NEBOC_STRING_POOL_KIND_OFFSET]
    shl rax, NEBOC_TYPED_ID_KIND_SHIFT
    lea rcx, [r10 + 1]
    or rax, rcx
    cmp [r11 + NEBOC_STRING_ENTRY_ID_OFFSET], rax
    jne .invalid

    mov rax, [r11 + NEBOC_STRING_ENTRY_HASH_OFFSET]
    shr rax, NEBOC_FNV1A32_BITS
    jnz .invalid

    mov rcx, [r11 + NEBOC_STRING_ENTRY_LENGTH_OFFSET]
    cmp rcx, NEBOC_STRING_POOL_MAX_STRING_BYTES
    ja .limit
    test rcx, rcx
    jz .next_entry
    mov rdx, [r11 + NEBOC_STRING_ENTRY_BYTES_OFFSET]
    test rdx, rdx
    jz .invalid
    cmp rdx, [r8 + NEBOC_ARENA_BEGIN_OFFSET]
    jb .invalid
    mov rax, rdx
    add rax, rcx
    jc .limit
    cmp rax, [r8 + NEBOC_ARENA_CURRENT_OFFSET]
    ja .limit
.next_entry:
    inc r10
    jmp .entry_loop
.ok:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; string_pool_intern(pool*, bytes*, length, owner_token, out_id*)
NEBOC_ABI_FUNCTION neboc_string_pool_intern
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
    mov r15, r8
    mov qword [rsp], 0
    mov qword [rsp + 8], 0

    test r15, r15
    jz .invalid
    mov qword [r15], NEBOC_ID_INVALID

    mov rdi, rbx
    mov rsi, r14
    call neboc_string_pool_validate
    test eax, eax
    jne .finish

    cmp r13, NEBOC_STRING_POOL_MAX_STRING_BYTES
    ja .limit
    test r13, r13
    jz .length_ok
    test r12, r12
    jz .invalid
.length_ok:
    cmp qword [rbx + NEBOC_STRING_POOL_KIND_OFFSET], NEBOC_ID_KIND_IDENTIFIER
    jne .hash
    mov rdi, r12
    mov rsi, r13
    call neboc_identifier_validate_ascii
    test eax, eax
    jne .finish
.hash:
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rsp + 8]
    call neboc_hash_fnv1a32
    test eax, eax
    jne .finish
    inc qword [rbx + NEBOC_STRING_POOL_HASH_CALLS_OFFSET]

    xor r10d, r10d
.search:
    cmp r10, [rbx + NEBOC_STRING_POOL_COUNT_OFFSET]
    jae .new_entry
    mov r11, r10
    shl r11, 5
    add r11, [rbx + NEBOC_STRING_POOL_ENTRIES_OFFSET]
    jc .limit
    mov rax, [rsp + 8]
    cmp [r11 + NEBOC_STRING_ENTRY_HASH_OFFSET], rax
    jne .next
    cmp [r11 + NEBOC_STRING_ENTRY_LENGTH_OFFSET], r13
    jne .collision
    xor ecx, ecx
    mov rdx, [r11 + NEBOC_STRING_ENTRY_BYTES_OFFSET]
.compare:
    cmp rcx, r13
    jae .found
    mov al, [r12 + rcx]
    cmp al, [rdx + rcx]
    jne .collision
    inc rcx
    jmp .compare
.found:
    mov rax, [r11 + NEBOC_STRING_ENTRY_ID_OFFSET]
    mov [r15], rax
    xor eax, eax
    jmp .finish
.collision:
    inc qword [rbx + NEBOC_STRING_POOL_COLLISION_COUNT_OFFSET]
.next:
    inc r10
    jmp .search

.new_entry:
    mov r10, [rbx + NEBOC_STRING_POOL_COUNT_OFFSET]
    cmp r10, [rbx + NEBOC_STRING_POOL_CAPACITY_OFFSET]
    jae .limit
    mov rax, [rbx + NEBOC_STRING_POOL_TOTAL_BYTES_OFFSET]
    add rax, r13
    jc .limit

    test r13, r13
    jz .bytes_ready
    mov rdi, [rbx + NEBOC_STRING_POOL_ARENA_OFFSET]
    mov rsi, r13
    mov edx, 1
    mov rcx, r14
    lea r8, [rsp]
    call neboc_arena_allocate
    test eax, eax
    jne .finish
    mov rdi, [rsp]
    test rdi, rdi
    jz .internal
    mov rsi, r12
    mov rcx, r13
    cld
    rep movsb
.bytes_ready:
    mov r10, [rbx + NEBOC_STRING_POOL_COUNT_OFFSET]
    mov r11, r10
    shl r11, 5
    add r11, [rbx + NEBOC_STRING_POOL_ENTRIES_OFFSET]
    jc .limit
    mov rax, [rsp + 8]
    mov [r11 + NEBOC_STRING_ENTRY_HASH_OFFSET], rax
    mov rax, [rsp]
    mov [r11 + NEBOC_STRING_ENTRY_BYTES_OFFSET], rax
    mov [r11 + NEBOC_STRING_ENTRY_LENGTH_OFFSET], r13
    mov rax, [rbx + NEBOC_STRING_POOL_KIND_OFFSET]
    shl rax, NEBOC_TYPED_ID_KIND_SHIFT
    inc r10
    or rax, r10
    mov [r11 + NEBOC_STRING_ENTRY_ID_OFFSET], rax
    mov [r15], rax
    mov [rbx + NEBOC_STRING_POOL_COUNT_OFFSET], r10
    add [rbx + NEBOC_STRING_POOL_TOTAL_BYTES_OFFSET], r13
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

; string_pool_get_view(pool*, typed_id, owner_token, out_view*)
NEBOC_ABI_FUNCTION neboc_string_pool_get_view
    test rcx, rcx
    jz .invalid
    mov qword [rcx + NEBOC_STRING_VIEW_BYTES_OFFSET], 0
    mov qword [rcx + NEBOC_STRING_VIEW_LENGTH_OFFSET], 0
    mov qword [rcx + NEBOC_STRING_VIEW_HASH_OFFSET], 0
    mov qword [rcx + NEBOC_STRING_VIEW_ID_OFFSET], NEBOC_ID_INVALID
    test rdi, rdi
    jz .invalid
    test rdx, rdx
    jz .invalid
    cmp qword [rdi + NEBOC_STRING_POOL_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_STRING_POOL_OWNER_OFFSET], rdx
    jne .invalid
    mov r8, [rdi + NEBOC_STRING_POOL_ARENA_OFFSET]
    test r8, r8
    jz .invalid
    cmp qword [r8 + NEBOC_ARENA_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [r8 + NEBOC_ARENA_OWNER_OFFSET], rdx
    jne .invalid
    mov rax, [r8 + NEBOC_ARENA_GENERATION_OFFSET]
    cmp [rdi + NEBOC_STRING_POOL_ARENA_GENERATION_OFFSET], rax
    jne .invalid

    mov rax, rsi
    shr rax, NEBOC_TYPED_ID_KIND_SHIFT
    cmp rax, [rdi + NEBOC_STRING_POOL_KIND_OFFSET]
    jne .invalid
    mov r9, NEBOC_TYPED_ID_ORDINAL_MASK
    mov rax, rsi
    and rax, r9
    test rax, rax
    jz .invalid
    cmp rax, [rdi + NEBOC_STRING_POOL_COUNT_OFFSET]
    ja .invalid
    dec rax
    shl rax, 5
    add rax, [rdi + NEBOC_STRING_POOL_ENTRIES_OFFSET]
    jc .limit
    cmp [rax + NEBOC_STRING_ENTRY_ID_OFFSET], rsi
    jne .invalid
    mov r8, [rax + NEBOC_STRING_ENTRY_BYTES_OFFSET]
    mov [rcx + NEBOC_STRING_VIEW_BYTES_OFFSET], r8
    mov r8, [rax + NEBOC_STRING_ENTRY_LENGTH_OFFSET]
    mov [rcx + NEBOC_STRING_VIEW_LENGTH_OFFSET], r8
    mov r8, [rax + NEBOC_STRING_ENTRY_HASH_OFFSET]
    mov [rcx + NEBOC_STRING_VIEW_HASH_OFFSET], r8
    mov [rcx + NEBOC_STRING_VIEW_ID_OFFSET], rsi
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

section .note.GNU-stack noalloc noexec nowrite progbits
