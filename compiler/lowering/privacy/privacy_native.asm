; Nebo Assembly — PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-PF004 deterministic x86-64 SysV privacy native plan
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/privacy/privacy_native.inc"

extern neboc_privacy_ir_lower

%define neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_IR_LOCAL_STACK_SIZE 528

section .text

NEBOC_ABI_FUNCTION neboc_privacy_native_lower
    test rdi, rdi
    jz .invalid_argument_direct
    test rdi, neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_ALIGNMENT - 1
    jnz .invalid_argument_direct
    mov rax, rdi
    add rax, neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_REQUEST_SIZE
    jc .invalid_argument_direct

    cld
    push r12
    push r13
    push r14
    sub rsp, neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_IR_LOCAL_STACK_SIZE
    mov r12, rdi
    mov r14, rax
    mov r13, [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_IR_POINTER_OFFSET]
    test r13, r13
    jz .invalid_argument
    test r13, neboc_privacidade_dados_sensiveis_e_zero_trust_IR_ALIGNMENT - 1
    jnz .invalid_argument
    mov rdx, r13
    add rdx, neboc_privacidade_dados_sensiveis_e_zero_trust_IR_REQUEST_SIZE
    jc .invalid_argument
    cmp r12, rdx
    jae .disjoint
    cmp r13, r14
    jae .disjoint
    jmp .invalid_argument
.disjoint:
    lea rdi, [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_OUTPUT_OFFSET]
    mov ecx, neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_OUTPUT_QWORDS
    xor eax, eax
    rep stosq
    cmp qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_TARGET_ID_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_TARGET_X86_64_SYSV_ELF_LINUX
    jne .unsupported
    cmp qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_ABI_VERSION_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_ABI_VERSION
    jne .unsupported

    mov rsi, r13
    mov rdi, rsp
    mov ecx, neboc_privacidade_dados_sensiveis_e_zero_trust_IR_REQUEST_QWORDS
    rep movsq
    mov rdi, rsp
    call neboc_privacy_ir_lower
    mov r14d, eax
    test eax, eax
    jnz .delegated_failure
    lea rsi, [rsp + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_OUTPUT_OFFSET]
    lea rdi, [r13 + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_OUTPUT_OFFSET]
    mov ecx, neboc_privacidade_dados_sensiveis_e_zero_trust_IR_OUTPUT_QWORDS
    repe cmpsq
    jne .invalid_source

    lea rsi, [rsp + NEBOC_SEMANTIC_PRIVACY_OFFSET]
    lea rdi, [r12 + NEBOC_NATIVE_PRIVACY_RECORD_OFFSET]
    mov ecx, NEBOC_PRIVACY_REQUEST_QWORDS
    rep movsq
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_RECORD_SIZE_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_RECORD_SIZE
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_RECORD_ALIGNMENT_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_RECORD_ALIGNMENT
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_RECORD_PASSING_OFFSET], NEBOC_NATIVE_PASSING_BY_REFERENCE
    mov qword [r12 + NEBOC_NATIVE_ARGUMENT_REGISTER_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_REGISTER_RDI
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_RESULT_SIZE_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_RESULT_SIZE
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_RESULT_ALIGNMENT_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_RESULT_ALIGNMENT
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_RESULT_ABI_CLASS_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_ABI_CLASS_INTEGER
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_RESULT_REGISTER_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_REGISTER_RAX
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_RUNTIME_GUARD_OFFSET], NEBOC_NATIVE_RUNTIME_GUARD_PRIVACY_CHECK
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_FLAGS_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_FLAGS_REQUIRED
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_DIAGNOSTIC_OFFSET], 0
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_ALLOCATIONS_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_ALLOCATION_NONE
    mov rax, [rsp + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_RESULT_TYPE_OFFSET]
    mov [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_RESULT_TYPE_OFFSET], rax
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.hash_loop:
    cmp rcx, neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_HASHED_BYTES
    jae .hash_done
    movzx edx, byte [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_HASH_START_OFFSET + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .hash_loop
.hash_done:
    mov [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_HASH_OFFSET], rax
    xor eax, eax
    jmp .done

.delegated_failure:
    mov rdx, [rsp + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_DIAGNOSTIC_OFFSET]
    test rdx, rdx
    jnz .transactional_failure
    mov edx, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_codegen_privacy_x86_64
    jmp .transactional_failure
.invalid_source:
    mov r14d, NEBOC_STATUS_INVALID_SOURCE
    mov edx, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_codegen_privacy_x86_64
    jmp .transactional_failure
.unsupported:
    mov r14d, NEBOC_STATUS_UNSUPPORTED_TARGET
    mov edx, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_CODEGEN_codegen_privacy_x86_64
.transactional_failure:
    lea rdi, [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_OUTPUT_OFFSET]
    mov ecx, neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_OUTPUT_QWORDS
    xor eax, eax
    rep stosq
    mov [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_DIAGNOSTIC_OFFSET], rdx
    mov eax, r14d
    jmp .done
.invalid_argument:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
.done:
    add rsp, neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_IR_LOCAL_STACK_SIZE
    pop r14
    pop r13
    pop r12
    cld
    ret
.invalid_argument_direct:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

%if neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_IR_LOCAL_STACK_SIZE < neboc_privacidade_dados_sensiveis_e_zero_trust_IR_REQUEST_SIZE
    %error "privacidade_dados_sensiveis_e_zero_trust native IR snapshot too small"
%endif
%if neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_IR_LOCAL_STACK_SIZE % 16
    %error "privacidade_dados_sensiveis_e_zero_trust native local stack alignment drift"
%endif

section .note.GNU-stack noalloc noexec nowrite progbits
