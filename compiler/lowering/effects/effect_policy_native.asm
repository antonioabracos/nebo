; Nebo Assembly — EFFECTS-CAPABILITIES-E-POLITICAS-PF004 deterministic x86-64 System V native policy plan
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/effects/effect_policy_native.inc"

section .text

extern neboc_policy_ir_lower

%define neboc_effects_capabilities_e_politicas_NATIVE_IR_LOCAL_STACK_SIZE 304

; neboc_policy_native_lower(request*) -> StatusCode
;
; q0 points at a complete PF003 IR envelope, q1 selects the sole certified
; target and q2 selects this internal native ABI version.  q3..q34 are cleared
; transactionally after pointer/alignment/disjointness checks.  PF004 copies
; the IR locally, delegates its revalidation to PF003, and accepts it only when
; the original q25..q36 exactly match the recomputed lowering outputs.
NEBOC_ABI_FUNCTION neboc_policy_native_lower
    test rdi, rdi
    jz .invalid_argument_direct
    test rdi, neboc_effects_capabilities_e_politicas_NATIVE_ALIGNMENT - 1
    jnz .invalid_argument_direct

    ; Prove the complete request range before a push or the first q0 load.
    mov rax, rdi
    add rax, neboc_effects_capabilities_e_politicas_NATIVE_REQUEST_SIZE
    jc .invalid_argument_direct

    push r12
    push r13
    push r14
    sub rsp, neboc_effects_capabilities_e_politicas_NATIVE_IR_LOCAL_STACK_SIZE
    mov r12, rdi
    mov r14, rax
    mov r13, [r12 + neboc_effects_capabilities_e_politicas_NATIVE_IR_POINTER_OFFSET]

    ; Pointer failures, range wrap and request/IR overlap are no-write errors.
    test r13, r13
    jz .invalid_argument
    test r13, neboc_effects_capabilities_e_politicas_IR_ALIGNMENT - 1
    jnz .invalid_argument
    mov rdx, r13
    add rdx, neboc_effects_capabilities_e_politicas_IR_REQUEST_SIZE
    jc .invalid_argument
    cmp r12, rdx
    jae .disjoint
    cmp r13, r14
    jae .disjoint
    jmp .invalid_argument

.disjoint:
    lea rdi, [r12 + neboc_effects_capabilities_e_politicas_NATIVE_OUTPUT_OFFSET]
    mov ecx, neboc_effects_capabilities_e_politicas_NATIVE_OUTPUT_QWORDS
    xor eax, eax
    rep stosq

    cmp qword [r12 + neboc_effects_capabilities_e_politicas_NATIVE_TARGET_ID_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_TARGET_X86_64_SYSV_ELF_LINUX
    jne .unsupported_target
    cmp qword [r12 + neboc_effects_capabilities_e_politicas_NATIVE_ABI_VERSION_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_ABI_VERSION
    jne .unsupported_target

    ; The only delegated operation is the already-certified PF003 lowerer.
    mov rsi, r13
    mov rdi, rsp
    mov ecx, neboc_effects_capabilities_e_politicas_IR_REQUEST_QWORDS
    cld
    rep movsq
    mov rdi, rsp
    call neboc_policy_ir_lower
    mov r14d, eax
    test eax, eax
    jnz .delegated_failure

    ; Authenticate the original abstract IR by exact output comparison.
    lea rsi, [rsp + neboc_effects_capabilities_e_politicas_IR_OUTPUT_OFFSET]
    lea rdi, [r13 + neboc_effects_capabilities_e_politicas_IR_OUTPUT_OFFSET]
    mov ecx, neboc_effects_capabilities_e_politicas_IR_OUTPUT_QWORDS
    cld
    repe cmpsq
    jne .invalid_source

    ; q3..q19 are the exact PF001 record, remapped from the stable local IR.
    mov rax, [rsp + NEBOC_IR_DIRECT_EFFECTS_OFFSET]
    mov [r12 + NEBOC_NATIVE_POLICY_DIRECT_EFFECTS_OFFSET], rax
    mov rax, [rsp + NEBOC_IR_CALLEE_EFFECTS_OFFSET]
    mov [r12 + NEBOC_NATIVE_POLICY_CALLEE_EFFECTS_OFFSET], rax
    mov rax, [rsp + NEBOC_IR_DECLARED_EFFECTS_OFFSET]
    mov [r12 + NEBOC_NATIVE_POLICY_DECLARED_EFFECTS_OFFSET], rax
    mov rax, [rsp + NEBOC_IR_CAPABILITIES_OFFSET]
    mov [r12 + NEBOC_NATIVE_POLICY_CAPABILITIES_OFFSET], rax
    mov rax, [rsp + NEBOC_IR_ALLOW_OFFSET]
    mov [r12 + NEBOC_NATIVE_POLICY_ALLOW_OFFSET], rax
    mov rax, [rsp + NEBOC_IR_DENY_OFFSET]
    mov [r12 + NEBOC_NATIVE_POLICY_DENY_OFFSET], rax
    mov rax, [rsp + NEBOC_IR_BUDGET_OFFSET]
    mov [r12 + NEBOC_NATIVE_POLICY_BUDGET_OFFSET], rax
    mov rax, [rsp + NEBOC_IR_TRUST_OFFSET]
    mov [r12 + NEBOC_NATIVE_POLICY_TRUST_OFFSET], rax
    mov rax, [rsp + NEBOC_IR_AUDIT_ID_OFFSET]
    mov [r12 + NEBOC_NATIVE_POLICY_AUDIT_ID_OFFSET], rax
    mov rax, [rsp + NEBOC_IR_PERMIT_OFFSET]
    mov [r12 + NEBOC_NATIVE_POLICY_PERMIT_OFFSET], rax
    mov rax, [rsp + NEBOC_IR_INFERRED_EFFECTS_OFFSET]
    mov [r12 + NEBOC_NATIVE_POLICY_INFERRED_EFFECTS_OFFSET], rax
    mov rax, [rsp + NEBOC_IR_MISSING_EFFECTS_OFFSET]
    mov [r12 + NEBOC_NATIVE_POLICY_MISSING_EFFECTS_OFFSET], rax
    mov rax, [rsp + NEBOC_IR_REJECTED_EFFECTS_OFFSET]
    mov [r12 + NEBOC_NATIVE_POLICY_REJECTED_EFFECTS_OFFSET], rax
    mov rax, [rsp + NEBOC_IR_COST_OFFSET]
    mov [r12 + NEBOC_NATIVE_POLICY_COST_OFFSET], rax
    mov rax, [rsp + NEBOC_IR_SEMANTIC_DIAGNOSTIC_OFFSET]
    mov [r12 + NEBOC_NATIVE_POLICY_DIAGNOSTIC_OFFSET], rax
    mov rax, [rsp + NEBOC_IR_AUDIT_HASH_OFFSET]
    mov [r12 + NEBOC_NATIVE_POLICY_AUDIT_HASH_OFFSET], rax
    mov rax, [rsp + neboc_effects_capabilities_e_politicas_IR_DECISION_OFFSET]
    mov [r12 + NEBOC_NATIVE_POLICY_DECISION_OFFSET], rax

    ; Frozen data layout, call ABI, constant permit materialization and guard.
    mov qword [r12 + neboc_effects_capabilities_e_politicas_NATIVE_RECORD_SIZE_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_RECORD_SIZE
    mov qword [r12 + neboc_effects_capabilities_e_politicas_NATIVE_RECORD_ALIGNMENT_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_RECORD_ALIGNMENT
    mov qword [r12 + neboc_effects_capabilities_e_politicas_NATIVE_RECORD_PASSING_OFFSET], \
        NEBOC_NATIVE_RECORD_PASSING_BY_REFERENCE
    mov qword [r12 + NEBOC_NATIVE_RECORD_ARGUMENT_REGISTER_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_REGISTER_RDI
    mov qword [r12 + neboc_effects_capabilities_e_politicas_NATIVE_RESULT_SIZE_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_RESULT_SIZE
    mov qword [r12 + neboc_effects_capabilities_e_politicas_NATIVE_RESULT_ALIGNMENT_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_RESULT_ALIGNMENT
    mov qword [r12 + neboc_effects_capabilities_e_politicas_NATIVE_RESULT_ABI_CLASS_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_ABI_CLASS_INTEGER
    mov qword [r12 + neboc_effects_capabilities_e_politicas_NATIVE_RESULT_REGISTER_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_REGISTER_RAX
    mov qword [r12 + neboc_effects_capabilities_e_politicas_NATIVE_INSTRUCTION_OFFSET], \
        NEBOC_NATIVE_INSTRUCTION_MOV_EAX_IMM32
    mov rax, [rsp + NEBOC_IR_PERMIT_CONSTANT_OFFSET]
    mov [r12 + NEBOC_NATIVE_PERMIT_IMMEDIATE_OFFSET], rax
    mov qword [r12 + neboc_effects_capabilities_e_politicas_NATIVE_RUNTIME_GUARD_OFFSET], \
        NEBOC_NATIVE_RUNTIME_GUARD_POLICY_CHECK
    mov qword [r12 + neboc_effects_capabilities_e_politicas_NATIVE_FLAGS_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_FLAGS_REQUIRED
    mov qword [r12 + neboc_effects_capabilities_e_politicas_NATIVE_DIAGNOSTIC_OFFSET], 0
    mov qword [r12 + neboc_effects_capabilities_e_politicas_NATIVE_ALLOCATIONS_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_ALLOCATION_NONE

    ; Pointer-independent FNV-1a64 over q1..q33, bytewise in address order.
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.native_hash_loop:
    cmp rcx, neboc_effects_capabilities_e_politicas_NATIVE_HASHED_BYTES
    jae .native_hash_done
    movzx edx, byte [r12 + neboc_effects_capabilities_e_politicas_NATIVE_HASH_START_OFFSET + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .native_hash_loop
.native_hash_done:
    mov [r12 + neboc_effects_capabilities_e_politicas_NATIVE_HASH_OFFSET], rax
    xor eax, eax
    jmp .done

.delegated_failure:
    mov rdx, [rsp + neboc_effects_capabilities_e_politicas_IR_DIAGNOSTIC_OFFSET]
    test rdx, rdx
    jnz .transactional_failure
    mov edx, neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    jmp .transactional_failure

.invalid_source:
    mov r14d, NEBOC_STATUS_INVALID_SOURCE
    mov edx, neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    jmp .transactional_failure

.unsupported_target:
    mov r14d, NEBOC_STATUS_UNSUPPORTED_TARGET
    mov edx, neboc_effects_capabilities_e_politicas_DIAG_CODEGEN_codegen_effects_x86_64

.transactional_failure:
    lea rdi, [r12 + neboc_effects_capabilities_e_politicas_NATIVE_OUTPUT_OFFSET]
    mov ecx, neboc_effects_capabilities_e_politicas_NATIVE_OUTPUT_QWORDS
    xor eax, eax
    rep stosq
    mov [r12 + neboc_effects_capabilities_e_politicas_NATIVE_DIAGNOSTIC_OFFSET], rdx
    mov eax, r14d
    jmp .done

.invalid_argument:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT

.done:
    add rsp, neboc_effects_capabilities_e_politicas_NATIVE_IR_LOCAL_STACK_SIZE
    pop r14
    pop r13
    pop r12
    cld
    ret

.invalid_argument_direct:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

%if neboc_effects_capabilities_e_politicas_NATIVE_IR_LOCAL_STACK_SIZE < neboc_effects_capabilities_e_politicas_IR_REQUEST_SIZE
    %error "effects_capabilities_e_politicas native local IR snapshot is too small"
%endif
%if neboc_effects_capabilities_e_politicas_NATIVE_IR_LOCAL_STACK_SIZE % NEBOC_ABI_STACK_ALIGNMENT
    %error "effects_capabilities_e_politicas native local IR snapshot breaks SysV call alignment"
%endif

section .note.GNU-stack noalloc noexec nowrite progbits
