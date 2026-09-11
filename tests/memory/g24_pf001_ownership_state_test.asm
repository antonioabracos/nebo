; MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-PF001 native ownership, lifetime and exact-cleanup tests
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/memory/ownership_state.inc"

%if neboc_memoria_ownership_lifetimes_e_recursos_RECORD_QWORDS != 16
    %error "memoria_ownership_lifetimes_e_recursos record must remain 16 qwords"
%endif
%if neboc_memoria_ownership_lifetimes_e_recursos_RECORD_SIZE != 128
    %error "memoria_ownership_lifetimes_e_recursos record must remain 128 bytes"
%endif

extern neboc_ownership_transition
extern neboc_host_process_exit

section .bss align=16
record_a: resb neboc_memoria_ownership_lifetimes_e_recursos_RECORD_SIZE
record_b: resb neboc_memoria_ownership_lifetimes_e_recursos_RECORD_SIZE
saved_hash: resq 1
saved_generation: resq 1

section .text
clear_records:
    lea rdi, [rel record_a]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_RECORD_QWORDS * 2
    xor eax, eax
    rep stosq
    ret

; rdi=record, rsi=op, rdx=actor, rcx=region, r8=aux
transition:
    jmp neboc_ownership_transition

initialize_a:
    lea rdi, [rel record_a]
    mov esi, NEBOC_OP_INIT
    mov edx, 2401
    mov ecx, 24
    mov r8d, 4242
    jmp transition

initialize_b:
    lea rdi, [rel record_b]
    mov esi, NEBOC_OP_INIT
    mov edx, 2401
    mov ecx, 24
    mov r8d, 4242
    jmp transition

global _start
_start:
    call clear_records

    ; Transport rejection performs no writes.
    xor edi, edi
    mov esi, NEBOC_OP_INIT
    call transition
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    lea rdi, [rel record_a + 1]
    mov esi, NEBOC_OP_INIT
    mov edx, 2401
    mov ecx, 24
    mov r8d, 4242
    call transition
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    cmp qword [rel record_a + neboc_memoria_ownership_lifetimes_e_recursos_MAGIC_OFFSET], 0
    jne fail

    ; Initialization publishes an owned, cleanup-free deterministic record.
    call initialize_a
    test eax, eax
    jnz fail
    cmp qword [rel record_a + NEBOC_STATE_OFFSET], NEBOC_STATE_OWNED
    jne fail
    cmp qword [rel record_a + NEBOC_CLEANUP_COUNT_OFFSET], 0
    jne fail
    mov rax, [rel record_a + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET]
    test rax, rax
    jz fail
    mov [rel saved_hash], rax
    call initialize_a
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel record_a + neboc_memoria_ownership_lifetimes_e_recursos_DIAGNOSTIC_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DIAG_RUNTIME_driver_cli_linux_x86_64
    jne fail
    mov rax, [rel saved_hash]
    cmp [rel record_a + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET], rax
    jne fail

    ; Shared borrows may coexist only for the exact token and finite region.
    lea rdi, [rel record_a]
    mov esi, NEBOC_OP_BORROW_SHARED
    mov edx, 2401
    mov ecx, 25
    mov r8d, 2501
    call transition
    test eax, eax
    jnz fail
    cmp qword [rel record_a + NEBOC_STATE_OFFSET], NEBOC_STATE_BORROWED
    jne fail
    cmp qword [rel record_a + NEBOC_BORROW_MODE_OFFSET], NEBOC_BORROW_SHARED
    jne fail
    cmp qword [rel record_a + NEBOC_BORROW_COUNT_OFFSET], 1
    jne fail
    lea rdi, [rel record_a]
    mov esi, NEBOC_OP_BORROW_SHARED
    mov edx, 2401
    mov ecx, 25
    mov r8d, 2501
    call transition
    test eax, eax
    jnz fail
    cmp qword [rel record_a + NEBOC_BORROW_COUNT_OFFSET], 2
    jne fail

    ; Owner mutation and incompatible aliasing fail closed and atomically.
    mov rax, [rel record_a + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET]
    mov [rel saved_hash], rax
    mov rax, [rel record_a + NEBOC_GENERATION_OFFSET]
    mov [rel saved_generation], rax
    lea rdi, [rel record_a]
    mov esi, NEBOC_OP_BORROW_MUTABLE
    mov edx, 2401
    mov ecx, 26
    mov r8d, 2601
    call transition
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel record_a + neboc_memoria_ownership_lifetimes_e_recursos_DIAGNOSTIC_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DIAG_SECURITY_codegen_memory_x86_64
    jne fail
    mov rax, [rel saved_hash]
    cmp [rel record_a + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET], rax
    jne fail
    mov rax, [rel saved_generation]
    cmp [rel record_a + NEBOC_GENERATION_OFFSET], rax
    jne fail
    lea rdi, [rel record_a]
    mov esi, NEBOC_OP_ACCESS_OWNER
    mov edx, 2401
    xor ecx, ecx
    xor r8d, r8d
    call transition
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail

    ; Borrower access is region-bound; releases restore ownership at zero.
    lea rdi, [rel record_a]
    mov esi, NEBOC_OP_ACCESS_BORROW
    mov edx, 2501
    mov ecx, 25
    call transition
    test eax, eax
    jnz fail
    lea rdi, [rel record_a]
    mov esi, NEBOC_OP_ACCESS_BORROW
    mov edx, 2501
    mov ecx, 26
    call transition
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    lea rdi, [rel record_a]
    mov esi, NEBOC_OP_RELEASE_SHARED
    mov edx, 2501
    mov ecx, 25
    call transition
    test eax, eax
    jnz fail
    cmp qword [rel record_a + NEBOC_BORROW_COUNT_OFFSET], 1
    jne fail
    lea rdi, [rel record_a]
    mov esi, NEBOC_OP_RELEASE_SHARED
    mov edx, 2501
    mov ecx, 25
    call transition
    test eax, eax
    jnz fail
    cmp qword [rel record_a + NEBOC_STATE_OFFSET], NEBOC_STATE_OWNED
    jne fail

    ; One mutable borrower is exclusive and requires its exact token/region.
    lea rdi, [rel record_a]
    mov esi, NEBOC_OP_BORROW_MUTABLE
    mov edx, 2401
    mov ecx, 27
    mov r8d, 2701
    call transition
    test eax, eax
    jnz fail
    lea rdi, [rel record_a]
    mov esi, NEBOC_OP_RELEASE_MUTABLE
    mov edx, 2702
    mov ecx, 27
    call transition
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    lea rdi, [rel record_a]
    mov esi, NEBOC_OP_RELEASE_MUTABLE
    mov edx, 2701
    mov ecx, 27
    call transition
    test eax, eax
    jnz fail

    ; Lifetime end performs cleanup exactly once; UAF/double-drop is denied.
    lea rdi, [rel record_a]
    mov esi, NEBOC_OP_END_LIFETIME
    mov edx, 2401
    mov ecx, 24
    call transition
    test eax, eax
    jnz fail
    cmp qword [rel record_a + NEBOC_STATE_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_STATE_DROPPED
    jne fail
    cmp qword [rel record_a + NEBOC_CLEANUP_COUNT_OFFSET], 1
    jne fail
    mov rax, [rel record_a + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET]
    mov [rel saved_hash], rax
    lea rdi, [rel record_a]
    mov esi, NEBOC_OP_DROP
    mov edx, 2401
    call transition
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel record_a + neboc_memoria_ownership_lifetimes_e_recursos_DIAGNOSTIC_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DIAG_RUNTIME_driver_cli_linux_x86_64
    jne fail
    cmp qword [rel record_a + NEBOC_CLEANUP_COUNT_OFFSET], 1
    jne fail
    mov rax, [rel saved_hash]
    cmp [rel record_a + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET], rax
    jne fail
    lea rdi, [rel record_a]
    mov esi, NEBOC_OP_ACCESS_OWNER
    mov edx, 2401
    call transition
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail

    ; Move consumes the source binding but never runs its cleanup.
    lea rdi, [rel record_b]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_RECORD_QWORDS
    xor eax, eax
    rep stosq
    call initialize_b
    test eax, eax
    jnz fail
    lea rdi, [rel record_b]
    mov esi, NEBOC_OP_MOVE_OUT
    mov edx, 2401
    call transition
    test eax, eax
    jnz fail
    cmp qword [rel record_b + NEBOC_STATE_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_STATE_MOVED
    jne fail
    cmp qword [rel record_b + NEBOC_CLEANUP_COUNT_OFFSET], 0
    jne fail
    lea rdi, [rel record_b]
    mov esi, NEBOC_OP_ACCESS_OWNER
    mov edx, 2401
    call transition
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail

    ; Identical transition histories produce identical state hashes.
    call clear_records
    call initialize_a
    test eax, eax
    jnz fail
    call initialize_b
    test eax, eax
    jnz fail
    mov rax, [rel record_a + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET]
    cmp [rel record_b + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET], rax
    jne fail
    lea rdi, [rel record_a]
    mov esi, NEBOC_OP_DROP
    mov edx, 2401
    call transition
    test eax, eax
    jnz fail
    lea rdi, [rel record_b]
    mov esi, NEBOC_OP_DROP
    mov edx, 2401
    call transition
    test eax, eax
    jnz fail
    mov rax, [rel record_a + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET]
    cmp [rel record_b + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET], rax
    jne fail

    xor edi, edi
    jmp neboc_host_process_exit
fail:
    mov edi, 1
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
