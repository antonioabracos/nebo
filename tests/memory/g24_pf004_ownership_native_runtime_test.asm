; MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-PF004 authenticated native plan and single-use runtime tests
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "runtime/memory/ownership_runtime.inc"

extern neboc_ownership_parse
extern neboc_ownership_transition
extern neboc_ownership_semantic_analyze
extern neboc_ownership_ir_lower
extern neboc_ownership_native_lower
extern neboc_ownership_runtime_execute
extern neboc_host_process_exit

%define TEST_CANARY 0x66778899

%if NEBOC_NATIVE_PLAN_QWORDS != 83
    %error "memoria_ownership_lifetimes_e_recursos native plan layout changed"
%endif
%if neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_REQUEST_QWORDS != 108
    %error "memoria_ownership_lifetimes_e_recursos runtime layout changed"
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
request: resb neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_REQUEST_SIZE
request_canary: resq 1
parse_request: resb neboc_memoria_ownership_lifetimes_e_recursos_PARSE_REQUEST_SIZE
saved_hash: resq 1
saved_cleanup: resq 1

section .text
reset:
    cld
    lea rdi, [rel request]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    lea rdi, [rel parse_request]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_PARSE_REQUEST_QWORDS
    rep stosq
    mov qword [rel request_canary], TEST_CANARY
    ret

; rsi=source, edx=length -> complete PF003 IR request
prepare:
    push r12
    push r13
    mov r12, rsi
    mov r13d, edx
    sub rsp, 8
    call reset
    add rsp, 8
    lea rdi, [rel request + NEBOC_SEMANTIC_STATE_OFFSET]
    mov esi, NEBOC_OP_INIT
    mov edx, 2401
    mov ecx, 24
    mov r8d, 4242
    call neboc_ownership_transition
    test eax, eax
    jnz .done
    mov [rel parse_request + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_SOURCE_OFFSET], r12
    mov [rel parse_request + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_SOURCE_LENGTH_OFFSET], r13
    lea rax, [rel request]
    mov [rel parse_request + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_OUTPUT_OFFSET], rax
    lea rdi, [rel parse_request]
    call neboc_ownership_parse
    test eax, eax
    jnz .done
    lea rdi, [rel request]
    call neboc_ownership_semantic_analyze
    test eax, eax
    jnz .done
    lea rdi, [rel request]
    call neboc_ownership_ir_lower
.done:
    pop r13
    pop r12
    ret

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

rehash_semantic:
    lea rsi, [rel request]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_HASHED_BYTES
    call fnv
    mov [rel request + neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_HASH_OFFSET], rax
    ret
rehash_ir:
    lea rsi, [rel request]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_IR_HASHED_BYTES
    call fnv
    mov [rel request + neboc_memoria_ownership_lifetimes_e_recursos_IR_HASH_OFFSET], rax
    ret
rehash_native_state:
    lea rsi, [rel request + NEBOC_NATIVE_STATE_OFFSET]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_HASHED_BYTES
    call fnv
    mov [rel request + NEBOC_NATIVE_STATE_OFFSET + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET], rax
    ret
rehash_native:
    lea rsi, [rel request]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_HASHED_BYTES
    call fnv
    mov [rel request + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_HASH_OFFSET], rax
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
    cmp [rel request + %1], rax
    jne fail
%endmacro

%macro NATIVE_SUCCESS 7
    lea rdi, [rel request]
    call neboc_ownership_native_lower
    test eax, eax
    jnz fail
    EXPECT_QWORD NEBOC_NATIVE_EXPECTED_RESULT_STATE_OFFSET, %2
    EXPECT_QWORD NEBOC_NATIVE_EXPECTED_CLEANUP_DELTA_OFFSET, %3
    EXPECT_QWORD NEBOC_NATIVE_EXPECTED_GENERATION_DELTA_OFFSET, %4
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_OPERATION_OFFSET, %1
    EXPECT_QWORD NEBOC_NATIVE_ACTOR_OFFSET, 2401
    EXPECT_QWORD NEBOC_NATIVE_REGION_OFFSET, %5
    EXPECT_QWORD NEBOC_NATIVE_AUX_TOKEN_OFFSET, %6
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_DIAGNOSTIC_OFFSET, 0
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_DECISION_OFFSET, neboc_memoria_ownership_lifetimes_e_recursos_DECISION_PERMIT
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_ALLOCATIONS_OFFSET, 0
    cmp qword [rel request + NEBOC_NATIVE_EXPECTED_PRE_HASH_OFFSET], 0
    je fail
    cmp qword [rel request + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_HASH_OFFSET], 0
    je fail
    mov rax, %7
%endmacro

%macro RUNTIME_SUCCESS 4
    lea rdi, [rel request]
    call neboc_ownership_runtime_execute
    test eax, eax
    jnz fail
    EXPECT_QWORD NEBOC_RUNTIME_EXECUTED_OFFSET, 1
    EXPECT_QWORD NEBOC_RUNTIME_STATUS_OFFSET, NEBOC_STATUS_OK
    EXPECT_QWORD NEBOC_RUNTIME_OBSERVED_STATE_OFFSET, %1
    EXPECT_QWORD NEBOC_RUNTIME_CLEANUP_DELTA_OFFSET, %2
    EXPECT_QWORD NEBOC_RUNTIME_GENERATION_DELTA_OFFSET, %3
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_DIAGNOSTIC_OFFSET, 0
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_DECISION_OFFSET, neboc_memoria_ownership_lifetimes_e_recursos_DECISION_PERMIT
    cmp qword [rel request + NEBOC_RUNTIME_FINAL_STATE_HASH_OFFSET], 0
    je fail
    cmp qword [rel request + neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_EVENT_HASH_OFFSET], 0
    je fail
    cmp qword [rel request_canary], TEST_CANARY
    jne fail
    mov rax, %4
%endmacro

%macro NATIVE_FAILURE 0
    lea rdi, [rel request]
    call neboc_ownership_native_lower
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    EXPECT_QWORD NEBOC_NATIVE_EXPECTED_PRE_HASH_OFFSET, 0
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_OPERATION_OFFSET, 0
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_DIAGNOSTIC_OFFSET, neboc_memoria_ownership_lifetimes_e_recursos_DIAG_TYPE_codegen_memory_x86_64
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_DECISION_OFFSET, neboc_memoria_ownership_lifetimes_e_recursos_DECISION_DENY
    cmp qword [rel request + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_HASH_OFFSET], 0
    je fail
    cmp qword [rel request_canary], TEST_CANARY
    jne fail
%endmacro

global _start
_start:
    ; N01/R01 access.
    PREPARE s_access
    NATIVE_SUCCESS NEBOC_OP_ACCESS_OWNER,NEBOC_STATE_OWNED,0,0,24,0,0
    RUNTIME_SUCCESS NEBOC_STATE_OWNED,0,0,0

    ; N02/R02 move.
    PREPARE s_move
    NATIVE_SUCCESS NEBOC_OP_MOVE_OUT,neboc_memoria_ownership_lifetimes_e_recursos_STATE_MOVED,0,1,24,0,0
    RUNTIME_SUCCESS neboc_memoria_ownership_lifetimes_e_recursos_STATE_MOVED,0,1,0

    ; N03/R03 drop and exact cleanup.
    PREPARE s_drop
    NATIVE_SUCCESS NEBOC_OP_DROP,neboc_memoria_ownership_lifetimes_e_recursos_STATE_DROPPED,1,1,24,0,0
    RUNTIME_SUCCESS neboc_memoria_ownership_lifetimes_e_recursos_STATE_DROPPED,1,1,0

    ; N04/R04 shared borrow.
    PREPARE s_shared
    NATIVE_SUCCESS NEBOC_OP_BORROW_SHARED,NEBOC_STATE_BORROWED,0,1,25,2501,0
    RUNTIME_SUCCESS NEBOC_STATE_BORROWED,0,1,0

    ; N05/R05 mutable borrow.
    PREPARE s_mutable
    NATIVE_SUCCESS NEBOC_OP_BORROW_MUTABLE,NEBOC_STATE_BORROWED,0,1,26,2601,0
    RUNTIME_SUCCESS NEBOC_STATE_BORROWED,0,1,0

    ; N06 IR hash tamper.
    PREPARE s_access
    inc qword [rel request + neboc_memoria_ownership_lifetimes_e_recursos_IR_HASH_OFFSET]
    NATIVE_FAILURE

    ; N07 semantic hash tamper with refreshed IR hash.
    PREPARE s_access
    inc qword [rel request + neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_HASH_OFFSET]
    call rehash_ir
    NATIVE_FAILURE

    ; N08 syntax hash tamper with refreshed outer hashes.
    PREPARE s_access
    inc qword [rel request + neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_SHAPE_HASH_OFFSET]
    call rehash_semantic
    call rehash_ir
    NATIVE_FAILURE

    ; N09 state hash tamper with refreshed outer hashes.
    PREPARE s_access
    inc qword [rel request + NEBOC_SEMANTIC_STATE_OFFSET + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET]
    call rehash_semantic
    call rehash_ir
    NATIVE_FAILURE

    ; N10 authenticated IR diagnostic.
    PREPARE s_access
    mov qword [rel request + neboc_memoria_ownership_lifetimes_e_recursos_IR_DIAGNOSTIC_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DIAG_TYPE_codegen_memory_x86_64
    call rehash_ir
    NATIVE_FAILURE

    ; N11 authenticated IR deny.
    PREPARE s_access
    mov qword [rel request + neboc_memoria_ownership_lifetimes_e_recursos_IR_DECISION_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DECISION_DENY
    call rehash_ir
    NATIVE_FAILURE

    ; N12 allocation spoof.
    PREPARE s_access
    mov qword [rel request + neboc_memoria_ownership_lifetimes_e_recursos_IR_ALLOCATIONS_OFFSET], 1
    call rehash_ir
    NATIVE_FAILURE

    ; N13 operation substitution.
    PREPARE s_access
    mov qword [rel request + neboc_memoria_ownership_lifetimes_e_recursos_IR_OPERATION_OFFSET], NEBOC_OP_MOVE_OUT
    call rehash_ir
    NATIVE_FAILURE

    ; N14 actor substitution.
    PREPARE s_access
    inc qword [rel request + NEBOC_IR_ACTOR_OFFSET]
    call rehash_ir
    NATIVE_FAILURE

    ; N15 region substitution.
    PREPARE s_access
    inc qword [rel request + NEBOC_IR_REGION_OFFSET]
    call rehash_ir
    NATIVE_FAILURE

    ; N16 auxiliary-token substitution.
    PREPARE s_shared
    inc qword [rel request + NEBOC_IR_AUX_TOKEN_OFFSET]
    call rehash_ir
    NATIVE_FAILURE

    ; N17 invalid native transports are untouched.
    xor edi, edi
    call neboc_ownership_native_lower
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    lea rdi, [rel request + 1]
    call neboc_ownership_native_lower
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail

    ; N18 failure-owned output is deterministic and canary-safe.
    PREPARE s_access
    inc qword [rel request + neboc_memoria_ownership_lifetimes_e_recursos_IR_HASH_OFFSET]
    NATIVE_FAILURE
    mov rax, [rel request + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_HASH_OFFSET]
    mov [rel saved_hash], rax
    PREPARE s_access
    inc qword [rel request + neboc_memoria_ownership_lifetimes_e_recursos_IR_HASH_OFFSET]
    NATIVE_FAILURE
    mov rax, [rel request + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_HASH_OFFSET]
    cmp rax, [rel saved_hash]
    jne fail

    ; R06 single-use prevents double drop and preserves successful evidence.
    PREPARE s_drop
    NATIVE_SUCCESS NEBOC_OP_DROP,neboc_memoria_ownership_lifetimes_e_recursos_STATE_DROPPED,1,1,24,0,0
    RUNTIME_SUCCESS neboc_memoria_ownership_lifetimes_e_recursos_STATE_DROPPED,1,1,0
    mov rax, [rel request + NEBOC_RUNTIME_FINAL_STATE_HASH_OFFSET]
    mov [rel saved_hash], rax
    mov rax, [rel request + NEBOC_RUNTIME_STATE_OFFSET + NEBOC_CLEANUP_COUNT_OFFSET]
    mov [rel saved_cleanup], rax
    lea rdi, [rel request]
    call neboc_ownership_runtime_execute
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    mov rax, [rel request + NEBOC_RUNTIME_FINAL_STATE_HASH_OFFSET]
    cmp rax, [rel saved_hash]
    jne fail
    mov rax, [rel request + NEBOC_RUNTIME_STATE_OFFSET + NEBOC_CLEANUP_COUNT_OFFSET]
    cmp rax, [rel saved_cleanup]
    jne fail

    ; R07 native hash tamper is rejected before output mutation.
    PREPARE s_access
    NATIVE_SUCCESS NEBOC_OP_ACCESS_OWNER,NEBOC_STATE_OWNED,0,0,24,0,0
    inc qword [rel request + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_HASH_OFFSET]
    lea rdi, [rel request]
    call neboc_ownership_runtime_execute
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    EXPECT_QWORD NEBOC_RUNTIME_EXECUTED_OFFSET, 0

    ; R08 native diagnostic.
    PREPARE s_access
    NATIVE_SUCCESS NEBOC_OP_ACCESS_OWNER,NEBOC_STATE_OWNED,0,0,24,0,0
    mov qword [rel request + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_DIAGNOSTIC_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DIAG_TYPE_codegen_memory_x86_64
    call rehash_native
    lea rdi, [rel request]
    call neboc_ownership_runtime_execute
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail

    ; R09 native deny.
    PREPARE s_access
    NATIVE_SUCCESS NEBOC_OP_ACCESS_OWNER,NEBOC_STATE_OWNED,0,0,24,0,0
    mov qword [rel request + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_DECISION_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DECISION_DENY
    call rehash_native
    lea rdi, [rel request]
    call neboc_ownership_runtime_execute
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail

    ; R10 native allocation spoof.
    PREPARE s_access
    NATIVE_SUCCESS NEBOC_OP_ACCESS_OWNER,NEBOC_STATE_OWNED,0,0,24,0,0
    mov qword [rel request + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_ALLOCATIONS_OFFSET], 1
    call rehash_native
    lea rdi, [rel request]
    call neboc_ownership_runtime_execute
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail

    ; R11 native operation mismatch against IR.
    PREPARE s_access
    NATIVE_SUCCESS NEBOC_OP_ACCESS_OWNER,NEBOC_STATE_OWNED,0,0,24,0,0
    mov qword [rel request + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_OPERATION_OFFSET], NEBOC_OP_MOVE_OUT
    call rehash_native
    lea rdi, [rel request]
    call neboc_ownership_runtime_execute
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail

    ; R12 native actor mismatch against IR.
    PREPARE s_access
    NATIVE_SUCCESS NEBOC_OP_ACCESS_OWNER,NEBOC_STATE_OWNED,0,0,24,0,0
    inc qword [rel request + NEBOC_NATIVE_ACTOR_OFFSET]
    call rehash_native
    lea rdi, [rel request]
    call neboc_ownership_runtime_execute
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail

    ; R13 a rehashed moved pre-state still fails inside PF001 atomically.
    PREPARE s_access
    NATIVE_SUCCESS NEBOC_OP_ACCESS_OWNER,NEBOC_STATE_OWNED,0,0,24,0,0
    mov qword [rel request + NEBOC_NATIVE_STATE_OFFSET + NEBOC_STATE_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_STATE_MOVED
    call rehash_native_state
    mov rax, [rel request + NEBOC_NATIVE_STATE_OFFSET + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET]
    mov [rel request + NEBOC_NATIVE_EXPECTED_PRE_HASH_OFFSET], rax
    call rehash_native
    lea rdi, [rel request]
    call neboc_ownership_runtime_execute
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    EXPECT_QWORD NEBOC_RUNTIME_EXECUTED_OFFSET, 1
    EXPECT_QWORD NEBOC_RUNTIME_STATUS_OFFSET, NEBOC_STATUS_INVALID_SOURCE
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_DIAGNOSTIC_OFFSET, neboc_memoria_ownership_lifetimes_e_recursos_DIAG_SECURITY_codegen_memory_x86_64
    EXPECT_QWORD neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_DECISION_OFFSET, neboc_memoria_ownership_lifetimes_e_recursos_DECISION_DENY

    ; R14 invalid transport and ABI/DF preservation.
    xor edi, edi
    call neboc_ownership_runtime_execute
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    PREPARE s_access
    NATIVE_SUCCESS NEBOC_OP_ACCESS_OWNER,NEBOC_STATE_OWNED,0,0,24,0,0
    mov rbx, 0x11111111
    mov rbp, 0x22222222
    mov r12, 0x33333333
    mov r13, 0x44444444
    mov r14, 0x55555555
    mov r15, 0x66666666
    std
    lea rdi, [rel request]
    call neboc_ownership_runtime_execute
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
    cmp qword [rel request_canary], TEST_CANARY
    jne fail

pass:
    xor edi, edi
    jmp neboc_host_process_exit
fail:
    cld
    mov edi, 1
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
