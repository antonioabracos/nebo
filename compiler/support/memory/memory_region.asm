; Nebo Assembly — HostServices-backed MemoryRegion v0
;
; Purpose:
;   Own one checked contiguous host reservation without a general allocator.
;
; Inputs:
;   Per-function arguments follow NEBOC_INTERNAL_ABI_v0.
;
; Outputs:
;   StatusCode in EAX and explicit structure fields/out parameters.
;
; Status:
;   INVALID_ARGUMENT, OUT_OF_MEMORY, LIMIT_EXCEEDED or adapter status.
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
;   MemoryRegion owns its HostServices reservation until destroy succeeds.
;
; Thread safety:
;   Mutations require the exact non-zero owner token frozen at init.
;
; Errors:
;   Arithmetic and configured limits are checked before host reservation.
;
; Tests:
;   NEBO-MEM-UNIT_ASM-001, NEBO-MEM-NEG-002, NEBO-MEM-SECURITY-008.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/host/contracts/host_services.inc"
%include "compiler/support/memory/memory_region.inc"

extern neboc_host_memory_reserve
extern neboc_host_memory_release

section .text

; region_init(region*, host*, reserve_bytes, maximum_bytes, owner_token)
NEBOC_ABI_FUNCTION neboc_memory_region_init
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    test r8, r8
    jz .invalid
    cmp qword [rdi + NEBOC_MEMORY_REGION_ACTIVE_OFFSET], 0
    jne .invalid
    cmp rdx, rcx
    ja .limit
    cmp rcx, NEBOC_MEMORY_REGION_HARD_MAXIMUM_BYTES
    ja .limit

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

    mov rdi, r12
    mov rsi, r13
    lea rdx, [rsp]
    call neboc_host_memory_reserve
    test eax, eax
    jne .finish_status

    mov rax, [rsp]
    test rax, rax
    jz .internal

    mov rdx, [rbx + NEBOC_MEMORY_REGION_GENERATION_OFFSET]
    inc rdx
    jnz .generation_ready
    mov edx, 1
.generation_ready:
    mov [rbx + NEBOC_MEMORY_REGION_HOST_OFFSET], r12
    mov [rbx + NEBOC_MEMORY_REGION_BASE_OFFSET], rax
    mov [rbx + NEBOC_MEMORY_REGION_RESERVED_OFFSET], r13
    mov [rbx + NEBOC_MEMORY_REGION_COMMITTED_OFFSET], r13
    mov [rbx + NEBOC_MEMORY_REGION_MAXIMUM_OFFSET], r14
    mov [rbx + NEBOC_MEMORY_REGION_OWNER_OFFSET], r15
    mov [rbx + NEBOC_MEMORY_REGION_GENERATION_OFFSET], rdx
    mov qword [rbx + NEBOC_MEMORY_REGION_ACTIVE_OFFSET], 1
    mov qword [rbx + NEBOC_MEMORY_REGION_FLAGS_OFFSET], NEBOC_MEMORY_REGION_FLAG_NONE
    xor r11d, r11d
    jmp .finish

.internal:
    mov r11d, NEBOC_STATUS_INTERNAL_ERROR
    jmp .finish
.finish_status:
    mov r11d, eax
.finish:
    mov eax, r11d
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; region_validate(region*, owner_token)
NEBOC_ABI_FUNCTION neboc_memory_region_validate
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp qword [rdi + NEBOC_MEMORY_REGION_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_MEMORY_REGION_OWNER_OFFSET], rsi
    jne .invalid
    cmp qword [rdi + NEBOC_MEMORY_REGION_HOST_OFFSET], 0
    je .invalid
    cmp qword [rdi + NEBOC_MEMORY_REGION_BASE_OFFSET], 0
    je .invalid
    mov rax, [rdi + NEBOC_MEMORY_REGION_RESERVED_OFFSET]
    test rax, rax
    jz .invalid
    cmp rax, [rdi + NEBOC_MEMORY_REGION_COMMITTED_OFFSET]
    jne .invalid
    cmp rax, [rdi + NEBOC_MEMORY_REGION_MAXIMUM_OFFSET]
    ja .invalid
    cmp qword [rdi + NEBOC_MEMORY_REGION_GENERATION_OFFSET], 0
    je .invalid
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; region_destroy(region*, owner_token)
NEBOC_ABI_FUNCTION neboc_memory_region_destroy
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp qword [rdi + NEBOC_MEMORY_REGION_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_MEMORY_REGION_OWNER_OFFSET], rsi
    jne .invalid

    push rbx
    push r12
    push r13

    mov rbx, rdi
    mov r12, [rdi + NEBOC_MEMORY_REGION_HOST_OFFSET]
    mov r13, rsi

    mov rdi, r12
    mov rsi, [rbx + NEBOC_MEMORY_REGION_BASE_OFFSET]
    mov rdx, [rbx + NEBOC_MEMORY_REGION_RESERVED_OFFSET]
    call neboc_host_memory_release
    test eax, eax
    jne .destroy_finish

    mov qword [rbx + NEBOC_MEMORY_REGION_HOST_OFFSET], 0
    mov qword [rbx + NEBOC_MEMORY_REGION_BASE_OFFSET], 0
    mov qword [rbx + NEBOC_MEMORY_REGION_RESERVED_OFFSET], 0
    mov qword [rbx + NEBOC_MEMORY_REGION_COMMITTED_OFFSET], 0
    mov qword [rbx + NEBOC_MEMORY_REGION_MAXIMUM_OFFSET], 0
    mov [rbx + NEBOC_MEMORY_REGION_OWNER_OFFSET], r13
    mov qword [rbx + NEBOC_MEMORY_REGION_ACTIVE_OFFSET], 0
    mov qword [rbx + NEBOC_MEMORY_REGION_FLAGS_OFFSET], 0
    mov rax, [rbx + NEBOC_MEMORY_REGION_GENERATION_OFFSET]
    inc rax
    jnz .store_generation
    mov eax, 1
.store_generation:
    mov [rbx + NEBOC_MEMORY_REGION_GENERATION_OFFSET], rax
    xor eax, eax
.destroy_finish:
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
