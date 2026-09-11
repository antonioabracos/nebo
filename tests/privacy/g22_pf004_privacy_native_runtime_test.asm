; PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-PF004 native-plan and payload-free runtime tests
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/privacy/privacy_native.inc"
%include "runtime/privacy/privacy_runtime.inc"

extern neboc_privacy_semantic_analyze
extern neboc_privacy_ir_lower
extern neboc_privacy_native_lower
extern neboc_privacy_runtime_check
extern neboc_host_process_exit

section .bss align=16
ir_envelope: resb neboc_privacidade_dados_sensiveis_e_zero_trust_IR_REQUEST_SIZE
native_request: resb neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_REQUEST_SIZE
runtime_request: resb neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_REQUEST_SIZE
saved_hash: resq 1

section .text

clear_all:
    cld
    lea rdi, [rel ir_envelope]
    mov ecx, neboc_privacidade_dados_sensiveis_e_zero_trust_IR_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    lea rdi, [rel native_request]
    mov ecx, neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    lea rdi, [rel runtime_request]
    mov ecx, neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    ret

; Build the canonical PF003 PersonalData<Int> preserve permit.
prepare_ir:
    call clear_all
    mov qword [rel ir_envelope + NEBOC_PRIVACY_RESULT_WRAPPER_KIND_OFFSET], NEBOC_PRIVACY_WRAPPER_PERSONAL_DATA
    mov qword [rel ir_envelope + NEBOC_PRIVACY_RESULT_PAYLOAD_TYPE_ID_OFFSET], NEBOC_PRIVACY_PAYLOAD_TYPE_INT
    mov qword [rel ir_envelope + NEBOC_PRIVACY_RESULT_DIRECT_LABEL_OFFSET], NEBOC_LABEL_PERSONAL
    mov qword [rel ir_envelope + NEBOC_PRIVACY_RESULT_FLAGS_OFFSET], NEBOC_PRIVACY_FLAG_CANONICAL
    mov qword [rel ir_envelope + NEBOC_PRIVACY_RESULT_WRAPPER_SPAN_OFFSET], 8
    mov qword [rel ir_envelope + NEBOC_PRIVACY_RESULT_WRAPPER_SPAN_LENGTH_OFFSET], 12
    mov qword [rel ir_envelope + NEBOC_PRIVACY_RESULT_TYPE_SPAN_OFFSET], 21
    mov qword [rel ir_envelope + NEBOC_PRIVACY_RESULT_TYPE_SPAN_LENGTH_OFFSET], 3
    mov qword [rel ir_envelope + NEBOC_PRIVACY_RESULT_STATEMENT_SPAN_LENGTH_OFFSET], 18
    mov rax, 0xda4eb06e737beee7
    mov [rel ir_envelope + NEBOC_PRIVACY_RESULT_SHAPE_HASH_OFFSET], rax
    mov qword [rel ir_envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_POLICY_PERMIT_OFFSET], 22
    mov qword [rel ir_envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_SINK_CLEARANCE_OFFSET], NEBOC_LABEL_PERSONAL
    mov qword [rel ir_envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_SOURCE_TRUST_OFFSET], NEBOC_TRUST_RESTRICTED
    mov qword [rel ir_envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_TARGET_TRUST_OFFSET], NEBOC_TRUST_RESTRICTED
    mov qword [rel ir_envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_RETENTION_LIMIT_OFFSET], 10
    lea rdi, [rel ir_envelope]
    call neboc_privacy_semantic_analyze
    test eax, eax
    jnz fail
    lea rdi, [rel ir_envelope]
    call neboc_privacy_ir_lower
    test eax, eax
    jnz fail
    lea rax, [rel ir_envelope]
    mov [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_IR_POINTER_OFFSET], rax
    mov qword [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_TARGET_ID_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_TARGET_X86_64_SYSV_ELF_LINUX
    mov qword [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_ABI_VERSION_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_ABI_VERSION
    ret

lower_native:
    lea rdi, [rel native_request]
    jmp neboc_privacy_native_lower

prepare_runtime:
    lea rax, [rel native_request + NEBOC_NATIVE_PRIVACY_RECORD_OFFSET]
    mov [rel runtime_request + NEBOC_RUNTIME_PRIVACY_RECORD_OFFSET], rax
    mov qword [rel runtime_request + NEBOC_RUNTIME_REQUESTED_LABELS_OFFSET], NEBOC_LABEL_PERSONAL
    ret

check_runtime:
    lea rdi, [rel runtime_request]
    jmp neboc_privacy_runtime_check

native_hash_oracle:
    lea rsi, [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_HASH_START_OFFSET]
    mov ecx, neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_HASHED_BYTES
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor edx, edx
.loop:
    cmp rdx, rcx
    jae .done
    movzx r9d, byte [rsi + rdx]
    xor rax, r9
    imul rax, r8
    inc rdx
    jmp .loop
.done:
    ret

assert_native_success:
    test eax, eax
    jnz fail
    cmp qword [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_RECORD_SIZE_OFFSET], NEBOC_PRIVACY_REQUEST_SIZE
    jne fail
    cmp qword [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_RECORD_ALIGNMENT_OFFSET], 8
    jne fail
    cmp qword [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_RECORD_PASSING_OFFSET], NEBOC_NATIVE_PASSING_BY_REFERENCE
    jne fail
    cmp qword [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_RUNTIME_GUARD_OFFSET], NEBOC_NATIVE_RUNTIME_GUARD_PRIVACY_CHECK
    jne fail
    cmp qword [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_FLAGS_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_FLAGS_REQUIRED
    jne fail
    cmp qword [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_RESULT_TYPE_OFFSET], NEBOC_PRIVACY_PAYLOAD_TYPE_INT
    jne fail
    cmp qword [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_DIAGNOSTIC_OFFSET], 0
    jne fail
    cmp qword [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_ALLOCATIONS_OFFSET], 0
    jne fail
    mov r10, [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_HASH_OFFSET]
    test r10, r10
    jz fail
    call native_hash_oracle
    cmp rax, r10
    jne fail
    ret

assert_native_failure:
    test eax, eax
    jz fail
    cmp qword [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_RECORD_SIZE_OFFSET], 0
    jne fail
    cmp qword [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_HASH_OFFSET], 0
    jne fail
    cmp qword [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_DIAGNOSTIC_OFFSET], 0
    je fail
    ret

assert_runtime_success:
    test eax, eax
    jnz fail
    cmp qword [rel runtime_request + neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_DECISION_OFFSET], NEBOC_PRIVACY_DECISION_PERMIT
    jne fail
    cmp qword [rel runtime_request + NEBOC_RUNTIME_EFFECTIVE_LABELS_OFFSET], NEBOC_LABEL_PERSONAL
    jne fail
    cmp qword [rel runtime_request + neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_DIAGNOSTIC_OFFSET], 0
    jne fail
    cmp qword [rel runtime_request + neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_ALLOCATIONS_OFFSET], 0
    jne fail
    cmp qword [rel runtime_request + neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_EVENT_HASH_OFFSET], 0
    je fail
    ret

global _start
_start:
    ; 1. Transport failures are no-write and overlap is rejected.
    xor edi, edi
    call neboc_privacy_native_lower
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    call clear_all
    mov qword [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_HASH_OFFSET], 0x1234
    lea rdi, [rel native_request + 1]
    call neboc_privacy_native_lower
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    cmp qword [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_HASH_OFFSET], 0x1234
    jne fail
    lea rax, [rel native_request]
    mov [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_IR_POINTER_OFFSET], rax
    lea rdi, [rel native_request]
    call neboc_privacy_native_lower
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail

    ; 2. Exact PF003 IR produces the frozen native plan and record copy.
    call prepare_ir
    call lower_native
    call assert_native_success
    cmp qword [rel native_request + NEBOC_NATIVE_PRIVACY_RECORD_OFFSET + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET], NEBOC_LABEL_PERSONAL
    jne fail
    mov rax, [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_HASH_OFFSET]
    mov [rel saved_hash], rax
    call lower_native
    call assert_native_success
    mov rax, [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_HASH_OFFSET]
    cmp rax, [rel saved_hash]
    jne fail

    ; 3. Target/ABI and forged abstract IR fail transactionally.
    call prepare_ir
    mov qword [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_TARGET_ID_OFFSET], 2
    call lower_native
    cmp eax, NEBOC_STATUS_UNSUPPORTED_TARGET
    jne fail
    call assert_native_failure
    cmp qword [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_DIAGNOSTIC_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_CODEGEN_codegen_privacy_x86_64
    jne fail
    call prepare_ir
    mov qword [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_ABI_VERSION_OFFSET], 2
    call lower_native
    call assert_native_failure
    call prepare_ir
    xor qword [rel ir_envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_HASH_OFFSET], 1
    call lower_native
    call assert_native_failure
    cmp qword [rel native_request + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_DIAGNOSTIC_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_codegen_privacy_x86_64
    jne fail

    ; 4. Runtime reauthenticates the frozen record and allows only narrowing.
    call prepare_ir
    call lower_native
    call assert_native_success
    call prepare_runtime
    call check_runtime
    call assert_runtime_success
    mov rax, [rel runtime_request + neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_EVENT_HASH_OFFSET]
    mov [rel saved_hash], rax
    call check_runtime
    call assert_runtime_success
    mov rax, [rel runtime_request + neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_EVENT_HASH_OFFSET]
    cmp rax, [rel saved_hash]
    jne fail
    mov qword [rel runtime_request + NEBOC_RUNTIME_REQUESTED_LABELS_OFFSET], NEBOC_LABEL_SECRET
    call check_runtime
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel runtime_request + neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_DIAGNOSTIC_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_SECURITY_driver_cli_linux_x86_64
    jne fail
    mov qword [rel runtime_request + NEBOC_RUNTIME_REQUESTED_LABELS_OFFSET], 0x10
    call check_runtime
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel runtime_request + neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_DIAGNOSTIC_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_codegen_privacy_x86_64
    jne fail

    ; 5. Record forgery and runtime overlap fail closed.
    xor qword [rel native_request + NEBOC_NATIVE_PRIVACY_RECORD_OFFSET + NEBOC_PRIVACY_METADATA_HASH_OFFSET], 1
    mov qword [rel runtime_request + NEBOC_RUNTIME_REQUESTED_LABELS_OFFSET], 0
    call check_runtime
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel runtime_request + neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_DIAGNOSTIC_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_codegen_privacy_x86_64
    jne fail
    mov qword [rel runtime_request + neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_EVENT_HASH_OFFSET], 0x5678
    lea rax, [rel runtime_request]
    mov [rel runtime_request + NEBOC_RUNTIME_PRIVACY_RECORD_OFFSET], rax
    call check_runtime
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    cmp qword [rel runtime_request + neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_EVENT_HASH_OFFSET], 0x5678
    jne fail

    ; 6. SysV callee-saved registers and DF survive both successful gates.
    call prepare_ir
    mov rbx, 0x1111222233334444
    mov rbp, 0x2222333344445555
    mov r12, 0x3333444455556666
    mov r13, 0x4444555566667777
    mov r14, 0x5555666677778888
    mov r15, 0x6666777788889999
    std
    call lower_native
    call assert_native_success
    pushfq
    pop rax
    test rax, 1 << 10
    jnz fail
    mov rax, 0x1111222233334444
    cmp rbx, rax
    jne fail
    mov rax, 0x2222333344445555
    cmp rbp, rax
    jne fail
    mov rax, 0x3333444455556666
    cmp r12, rax
    jne fail
    mov rax, 0x4444555566667777
    cmp r13, rax
    jne fail
    mov rax, 0x5555666677778888
    cmp r14, rax
    jne fail
    mov rax, 0x6666777788889999
    cmp r15, rax
    jne fail
    call prepare_runtime
    std
    call check_runtime
    call assert_runtime_success
    pushfq
    pop rax
    test rax, 1 << 10
    jnz fail

success:
    xor edi, edi
    jmp neboc_host_process_exit
fail:
    cld
    mov edi, 1
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
