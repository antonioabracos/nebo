; MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-PF003 authenticated ownership semantic and target-neutral IR tests
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/memory/ownership_ir.inc"

extern neboc_ownership_parse
extern neboc_ownership_transition
extern neboc_ownership_semantic_analyze
extern neboc_ownership_ir_lower
extern neboc_host_process_exit

%define TEST_CANARY 0x66778899

%if neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_REQUEST_QWORDS != 37
    %error "memoria_ownership_lifetimes_e_recursos semantic layout changed"
%endif
%if neboc_memoria_ownership_lifetimes_e_recursos_IR_REQUEST_QWORDS != 55
    %error "memoria_ownership_lifetimes_e_recursos IR layout changed"
%endif

section .rodata
s_access: db 'resource 4242 owner 2401 lifetime 24 action access;',10
s_access_len equ $-s_access
s_move: db 'resource 4242 owner 2401 lifetime 24 action move;',10
s_move_len equ $-s_move
s_drop: db 'resource 4242 owner 2401 lifetime 24 action drop;',10
s_drop_len equ $-s_drop
s_shared: db 'resource 4242 owner 2401 lifetime 24 action borrow shared 2501 region 25;',10
s_shared_len equ $-s_shared
s_mutable: db 'resource 4242 owner 2401 lifetime 24 action borrow mutable 2601 region 26;',10
s_mutable_len equ $-s_mutable

section .bss align=16
envelope: resb neboc_memoria_ownership_lifetimes_e_recursos_IR_REQUEST_SIZE
envelope_canary: resq 1
parse_request: resb neboc_memoria_ownership_lifetimes_e_recursos_PARSE_REQUEST_SIZE
saved_semantic_hash: resq 1
saved_ir_hash: resq 1

section .text
reset:
    cld
    lea rdi, [rel envelope]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_IR_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    lea rdi, [rel parse_request]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_PARSE_REQUEST_QWORDS
    rep stosq
    mov qword [rel envelope_canary], TEST_CANARY
    ret

; rsi=source, edx=length. Builds canonical PF002 syntax and PF001 state.
prepare:
    push r12
    push r13
    mov r12, rsi
    mov r13d, edx
    sub rsp, 8
    call reset
    add rsp, 8
    lea rdi, [rel envelope + NEBOC_SEMANTIC_STATE_OFFSET]
    mov esi, NEBOC_OP_INIT
    mov edx, 2401
    mov ecx, 24
    mov r8d, 4242
    call neboc_ownership_transition
    test eax, eax
    jnz .done
    mov [rel parse_request + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_SOURCE_OFFSET], r12
    mov [rel parse_request + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_SOURCE_LENGTH_OFFSET], r13
    lea rax, [rel envelope]
    mov [rel parse_request + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_OUTPUT_OFFSET], rax
    lea rdi, [rel parse_request]
    call neboc_ownership_parse
.done:
    pop r13
    pop r12
    ret

; esi=operation, rdx=actor, rcx=region, r8=aux
transition_state:
    lea rdi, [rel envelope + NEBOC_SEMANTIC_STATE_OFFSET]
    jmp neboc_ownership_transition

; rsi=bytes, ecx=len -> rax FNV-1a64
fnv:
    mov rax, 14695981039346656037
    mov r8, 1099511628211
    xor edx, edx
.loop:
    cmp edx, ecx
    jae .done
    movzx r9d, byte [rsi + rdx]
    xor rax, r9
    imul rax, r8
    inc edx
    jmp .loop
.done:
    ret

rehash_syntax:
    lea rsi, [rel envelope]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_HASHED_BYTES
    call fnv
    mov [rel envelope + neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_SHAPE_HASH_OFFSET], rax
    ret

rehash_state:
    lea rsi, [rel envelope + NEBOC_SEMANTIC_STATE_OFFSET]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_HASHED_BYTES
    call fnv
    mov [rel envelope + NEBOC_SEMANTIC_STATE_OFFSET + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET], rax
    ret

rehash_semantic:
    lea rsi, [rel envelope]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_HASHED_BYTES
    call fnv
    mov [rel envelope + neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_HASH_OFFSET], rax
    ret

%macro PREPARE 1
    lea rsi, [rel %1]
    mov edx, %1 %+ _len
    call prepare
    test eax, eax
    jnz fail
%endmacro

%macro EXPECT_QWORD 2
    mov rax, %2
    cmp [rel envelope + %1], rax
    jne fail
%endmacro

%macro EXPECT_SEMANTIC_SUCCESS 7
    call neboc_ownership_semantic_analyze
    test eax, eax
    jnz fail
    EXPECT_QWORD NEBOC_SEMANTIC_OPERATION_OFFSET, %1
    EXPECT_QWORD NEBOC_SEMANTIC_ACTOR_OFFSET, 2401
    EXPECT_QWORD NEBOC_SEMANTIC_REGION_OFFSET, %2
    EXPECT_QWORD NEBOC_SEMANTIC_AUX_TOKEN_OFFSET, %3
    EXPECT_QWORD NEBOC_SEMANTIC_REQUIRED_STATE_OFFSET, %4
    EXPECT_QWORD NEBOC_SEMANTIC_RESULT_STATE_OFFSET, %5
    EXPECT_QWORD NEBOC_SEMANTIC_EFFECTS_OFFSET, %6
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_DIAGNOSTIC_OFFSET, 0
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_DECISION_OFFSET, neboc_memoria_ownership_lifetimes_e_recursos_DECISION_PERMIT
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_ALLOCATIONS_OFFSET, 0
    cmp qword [rel envelope + neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_HASH_OFFSET], 0
    je fail
    cmp qword [rel envelope_canary], TEST_CANARY
    jne fail
    mov rdi, %7
%endmacro

%macro EXPECT_IR_SUCCESS 6
    lea rdi, [rel envelope]
    call neboc_ownership_ir_lower
    test eax, eax
    jnz fail
    EXPECT_QWORD NEBOC_IR_HIR_RESOURCE_BIND_OFFSET, NEBOC_HIR_RESOURCE_BIND
    EXPECT_QWORD NEBOC_IR_HIR_OWNER_BIND_OFFSET, NEBOC_HIR_OWNER_BIND
    EXPECT_QWORD NEBOC_IR_HIR_LIFETIME_GUARD_OFFSET, NEBOC_HIR_LIFETIME_GUARD
    EXPECT_QWORD NEBOC_IR_HIR_ACTION_OFFSET, NEBOC_HIR_ACTION
    EXPECT_QWORD NEBOC_IR_LIR_STATE_HASH_ASSERT_OFFSET, NEBOC_LIR_STATE_HASH_ASSERT
    EXPECT_QWORD NEBOC_IR_LIR_AUTHORITY_ASSERT_OFFSET, NEBOC_LIR_AUTHORITY_ASSERT
    EXPECT_QWORD NEBOC_IR_LIR_TRANSITION_CALL_OFFSET, NEBOC_LIR_TRANSITION_CALL
    EXPECT_QWORD NEBOC_IR_LIR_EXACT_CLEANUP_OFFSET, NEBOC_LIR_EXACT_CLEANUP
    EXPECT_QWORD NEBOC_IR_RESOURCE_ID_OFFSET, 4242
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_IR_OPERATION_OFFSET, %1
    EXPECT_QWORD NEBOC_IR_ACTOR_OFFSET, 2401
    EXPECT_QWORD NEBOC_IR_REGION_OFFSET, %2
    EXPECT_QWORD NEBOC_IR_AUX_TOKEN_OFFSET, %3
    EXPECT_QWORD NEBOC_IR_EFFECTS_OFFSET, %4
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_IR_DECISION_OFFSET, neboc_memoria_ownership_lifetimes_e_recursos_DECISION_PERMIT
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_IR_DIAGNOSTIC_OFFSET, 0
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_IR_ALLOCATIONS_OFFSET, 0
    cmp qword [rel envelope + neboc_memoria_ownership_lifetimes_e_recursos_IR_HASH_OFFSET], 0
    je fail
    cmp qword [rel envelope_canary], TEST_CANARY
    jne fail
    mov rax, %5
    add rax, %6
%endmacro

%macro EXPECT_SEMANTIC_FAILURE 1
    lea rdi, [rel envelope]
    call neboc_ownership_semantic_analyze
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    EXPECT_QWORD NEBOC_SEMANTIC_OPERATION_OFFSET, 0
    EXPECT_QWORD NEBOC_SEMANTIC_EFFECTS_OFFSET, 0
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_DIAGNOSTIC_OFFSET, %1
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_DECISION_OFFSET, neboc_memoria_ownership_lifetimes_e_recursos_DECISION_DENY
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_ALLOCATIONS_OFFSET, 0
    cmp qword [rel envelope + neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_HASH_OFFSET], 0
    je fail
    cmp qword [rel envelope_canary], TEST_CANARY
    jne fail
%endmacro

%macro EXPECT_IR_FAILURE 0
    lea rdi, [rel envelope]
    call neboc_ownership_ir_lower
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    EXPECT_QWORD NEBOC_IR_HIR_RESOURCE_BIND_OFFSET, 0
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_IR_OPERATION_OFFSET, 0
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_IR_DECISION_OFFSET, 0
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_IR_DIAGNOSTIC_OFFSET, neboc_memoria_ownership_lifetimes_e_recursos_DIAG_TYPE_codegen_memory_x86_64
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_IR_ALLOCATIONS_OFFSET, 0
    cmp qword [rel envelope + neboc_memoria_ownership_lifetimes_e_recursos_IR_HASH_OFFSET], 0
    je fail
    cmp qword [rel envelope_canary], TEST_CANARY
    jne fail
%endmacro

global _start
_start:
    ; S01/I01 access.
    PREPARE s_access
    lea rdi, [rel envelope]
    EXPECT_SEMANTIC_SUCCESS NEBOC_OP_ACCESS_OWNER,24,0,NEBOC_STATE_OWNED,NEBOC_STATE_OWNED,NEBOC_EFFECT_READ,0
    mov rax, [rel envelope + neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_HASH_OFFSET]
    mov [rel saved_semantic_hash], rax
    EXPECT_IR_SUCCESS NEBOC_OP_ACCESS_OWNER,24,0,NEBOC_EFFECT_READ,0,0
    mov rax, [rel envelope + neboc_memoria_ownership_lifetimes_e_recursos_IR_HASH_OFFSET]
    mov [rel saved_ir_hash], rax

    ; S02/I02 move planning.
    PREPARE s_move
    lea rdi, [rel envelope]
    EXPECT_SEMANTIC_SUCCESS NEBOC_OP_MOVE_OUT,24,0,NEBOC_STATE_OWNED,neboc_memoria_ownership_lifetimes_e_recursos_STATE_MOVED,NEBOC_EFFECT_CONSUME,0
    EXPECT_IR_SUCCESS NEBOC_OP_MOVE_OUT,24,0,NEBOC_EFFECT_CONSUME,0,0

    ; S03/I03 drop planning.
    PREPARE s_drop
    lea rdi, [rel envelope]
    EXPECT_SEMANTIC_SUCCESS NEBOC_OP_DROP,24,0,NEBOC_STATE_OWNED,neboc_memoria_ownership_lifetimes_e_recursos_STATE_DROPPED,NEBOC_EFFECT_CLEANUP,0
    EXPECT_IR_SUCCESS NEBOC_OP_DROP,24,0,NEBOC_EFFECT_CLEANUP,0,0

    ; S04/I04 shared borrow planning.
    PREPARE s_shared
    lea rdi, [rel envelope]
    EXPECT_SEMANTIC_SUCCESS NEBOC_OP_BORROW_SHARED,25,2501,NEBOC_STATE_OWNED,NEBOC_STATE_BORROWED,NEBOC_EFFECT_BORROW_SHARED,0
    EXPECT_IR_SUCCESS NEBOC_OP_BORROW_SHARED,25,2501,NEBOC_EFFECT_BORROW_SHARED,0,0

    ; S05/I05 mutable borrow planning.
    PREPARE s_mutable
    lea rdi, [rel envelope]
    EXPECT_SEMANTIC_SUCCESS NEBOC_OP_BORROW_MUTABLE,26,2601,NEBOC_STATE_OWNED,NEBOC_STATE_BORROWED,NEBOC_EFFECT_BORROW_MUTABLE,0
    EXPECT_IR_SUCCESS NEBOC_OP_BORROW_MUTABLE,26,2601,NEBOC_EFFECT_BORROW_MUTABLE,0,0

    ; S06 repeated identical shared borrow is the only borrowed-state addition.
    PREPARE s_shared
    mov esi, NEBOC_OP_BORROW_SHARED
    mov edx, 2401
    mov ecx, 25
    mov r8d, 2501
    call transition_state
    test eax, eax
    jnz fail
    lea rdi, [rel envelope]
    EXPECT_SEMANTIC_SUCCESS NEBOC_OP_BORROW_SHARED,25,2501,NEBOC_STATE_BORROWED,NEBOC_STATE_BORROWED,NEBOC_EFFECT_BORROW_SHARED,0

    ; S07 syntax hash tamper.
    PREPARE s_access
    inc qword [rel envelope + neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_SHAPE_HASH_OFFSET]
    EXPECT_SEMANTIC_FAILURE neboc_memoria_ownership_lifetimes_e_recursos_DIAG_TYPE_codegen_memory_x86_64

    ; S08 state hash tamper.
    PREPARE s_access
    inc qword [rel envelope + NEBOC_SEMANTIC_STATE_OFFSET + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET]
    EXPECT_SEMANTIC_FAILURE neboc_memoria_ownership_lifetimes_e_recursos_DIAG_SECURITY_codegen_memory_x86_64

    ; S09 resource substitution with a recomputed syntax hash.
    PREPARE s_access
    inc qword [rel envelope + NEBOC_SYNTAX_RESOURCE_ID_OFFSET]
    call rehash_syntax
    EXPECT_SEMANTIC_FAILURE neboc_memoria_ownership_lifetimes_e_recursos_DIAG_SECURITY_codegen_memory_x86_64

    ; S10 owner substitution.
    PREPARE s_access
    inc qword [rel envelope + NEBOC_SYNTAX_OWNER_TOKEN_OFFSET]
    call rehash_syntax
    EXPECT_SEMANTIC_FAILURE neboc_memoria_ownership_lifetimes_e_recursos_DIAG_SECURITY_codegen_memory_x86_64

    ; S11 lifetime substitution.
    PREPARE s_access
    inc qword [rel envelope + NEBOC_SYNTAX_OWNER_REGION_OFFSET]
    call rehash_syntax
    EXPECT_SEMANTIC_FAILURE neboc_memoria_ownership_lifetimes_e_recursos_DIAG_SECURITY_codegen_memory_x86_64

    ; S12 a state carrying a denied observation cannot authorize semantics.
    PREPARE s_access
    mov qword [rel envelope + NEBOC_SEMANTIC_STATE_OFFSET + neboc_memoria_ownership_lifetimes_e_recursos_DIAGNOSTIC_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DIAG_SECURITY_codegen_memory_x86_64
    mov qword [rel envelope + NEBOC_SEMANTIC_STATE_OFFSET + neboc_memoria_ownership_lifetimes_e_recursos_DECISION_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DECISION_DENY
    EXPECT_SEMANTIC_FAILURE neboc_memoria_ownership_lifetimes_e_recursos_DIAG_SECURITY_codegen_memory_x86_64

    ; S13 use after move.
    PREPARE s_access
    mov esi, NEBOC_OP_MOVE_OUT
    mov edx, 2401
    xor ecx, ecx
    xor r8d, r8d
    call transition_state
    test eax, eax
    jnz fail
    EXPECT_SEMANTIC_FAILURE neboc_memoria_ownership_lifetimes_e_recursos_DIAG_SECURITY_codegen_memory_x86_64

    ; S14 borrow after drop.
    PREPARE s_shared
    mov esi, NEBOC_OP_DROP
    mov edx, 2401
    xor ecx, ecx
    xor r8d, r8d
    call transition_state
    test eax, eax
    jnz fail
    EXPECT_SEMANTIC_FAILURE neboc_memoria_ownership_lifetimes_e_recursos_DIAG_SECURITY_codegen_memory_x86_64

    ; S15 mutable borrow while shared borrow exists.
    PREPARE s_mutable
    mov esi, NEBOC_OP_BORROW_SHARED
    mov edx, 2401
    mov ecx, 25
    mov r8d, 2501
    call transition_state
    test eax, eax
    jnz fail
    EXPECT_SEMANTIC_FAILURE neboc_memoria_ownership_lifetimes_e_recursos_DIAG_SECURITY_codegen_memory_x86_64

    ; S16 shared borrower mismatch against an existing shared state.
    PREPARE s_shared
    mov esi, NEBOC_OP_BORROW_SHARED
    mov edx, 2401
    mov ecx, 25
    mov r8d, 2501
    call transition_state
    test eax, eax
    jnz fail
    inc qword [rel envelope + NEBOC_SYNTAX_BORROW_TOKEN_OFFSET]
    call rehash_syntax
    EXPECT_SEMANTIC_FAILURE neboc_memoria_ownership_lifetimes_e_recursos_DIAG_SECURITY_codegen_memory_x86_64

    ; S17 shared region mismatch.
    PREPARE s_shared
    mov esi, NEBOC_OP_BORROW_SHARED
    mov edx, 2401
    mov ecx, 25
    mov r8d, 2501
    call transition_state
    test eax, eax
    jnz fail
    inc qword [rel envelope + NEBOC_SYNTAX_BORROW_REGION_OFFSET]
    call rehash_syntax
    EXPECT_SEMANTIC_FAILURE neboc_memoria_ownership_lifetimes_e_recursos_DIAG_SECURITY_codegen_memory_x86_64

    ; S18 shared-count overflow is a runtime failure.
    PREPARE s_shared
    mov esi, NEBOC_OP_BORROW_SHARED
    mov edx, 2401
    mov ecx, 25
    mov r8d, 2501
    call transition_state
    test eax, eax
    jnz fail
    mov qword [rel envelope + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_BORROW_COUNT_OFFSET], -1
    call rehash_state
    EXPECT_SEMANTIC_FAILURE neboc_memoria_ownership_lifetimes_e_recursos_DIAG_RUNTIME_driver_cli_linux_x86_64

    ; S19 unknown operation cannot be smuggled with a fresh shape hash.
    PREPARE s_access
    mov qword [rel envelope + NEBOC_SYNTAX_ACTION_OFFSET], NEBOC_OP_RELEASE_SHARED
    call rehash_syntax
    EXPECT_SEMANTIC_FAILURE neboc_memoria_ownership_lifetimes_e_recursos_DIAG_TYPE_codegen_memory_x86_64

    ; S20 borrower cannot alias owner even with a recomputed shape hash.
    PREPARE s_shared
    mov qword [rel envelope + NEBOC_SYNTAX_BORROW_TOKEN_OFFSET], 2401
    call rehash_syntax
    EXPECT_SEMANTIC_FAILURE neboc_memoria_ownership_lifetimes_e_recursos_DIAG_TYPE_codegen_memory_x86_64

    ; I06 semantic hash substitution.
    PREPARE s_access
    lea rdi, [rel envelope]
    call neboc_ownership_semantic_analyze
    test eax, eax
    jnz fail
    inc qword [rel envelope + neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_HASH_OFFSET]
    EXPECT_IR_FAILURE

    ; I07 authenticated semantic diagnostic still denies lowering.
    PREPARE s_access
    lea rdi, [rel envelope]
    call neboc_ownership_semantic_analyze
    test eax, eax
    jnz fail
    mov qword [rel envelope + neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_DIAGNOSTIC_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DIAG_TYPE_codegen_memory_x86_64
    call rehash_semantic
    EXPECT_IR_FAILURE

    ; I08 authenticated deny decision.
    PREPARE s_access
    lea rdi, [rel envelope]
    call neboc_ownership_semantic_analyze
    test eax, eax
    jnz fail
    mov qword [rel envelope + neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_DECISION_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DECISION_DENY
    call rehash_semantic
    EXPECT_IR_FAILURE

    ; I09 allocation spoof.
    PREPARE s_access
    lea rdi, [rel envelope]
    call neboc_ownership_semantic_analyze
    test eax, eax
    jnz fail
    mov qword [rel envelope + neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_ALLOCATIONS_OFFSET], 1
    call rehash_semantic
    EXPECT_IR_FAILURE

    ; I10 operation substitution after semantic analysis.
    PREPARE s_access
    lea rdi, [rel envelope]
    call neboc_ownership_semantic_analyze
    test eax, eax
    jnz fail
    mov qword [rel envelope + NEBOC_SEMANTIC_OPERATION_OFFSET], NEBOC_OP_MOVE_OUT
    call rehash_semantic
    EXPECT_IR_FAILURE

    ; Determinism and ABI/DF preservation for both PF003 owners.
    PREPARE s_access
    mov rbx, 0x11111111
    mov rbp, 0x22222222
    mov r12, 0x33333333
    mov r13, 0x44444444
    mov r14, 0x55555555
    mov r15, 0x66666666
    std
    lea rdi, [rel envelope]
    call neboc_ownership_semantic_analyze
    test eax, eax
    jnz fail
    lea rdi, [rel envelope]
    call neboc_ownership_ir_lower
    test eax, eax
    jnz fail
    cmp rbx, 0x11111111
    jne fail
    cmp rbp, 0x22222222
    jne fail
    cmp r12, 0x33333333
    jne fail
    cmp r13, 0x44444444
    jne fail
    cmp r14, 0x55555555
    jne fail
    cmp r15, 0x66666666
    jne fail
    pushfq
    pop rax
    test rax, 1 << 10
    jnz fail
    cmp qword [rel envelope + neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_HASH_OFFSET], 0
    je fail
    cmp qword [rel envelope + neboc_memoria_ownership_lifetimes_e_recursos_IR_HASH_OFFSET], 0
    je fail

pass:
    xor edi, edi
    jmp neboc_host_process_exit
fail:
    cld
    mov edi, 1
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
