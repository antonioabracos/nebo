; Nebo Assembly — EFFECTS-CAPABILITIES-E-POLITICAS-PF005 authenticated bounded policy program emitter
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/lowering/effects/effect_policy_native.inc"
%include "runtime/effects/effect_policy_runtime.inc"
%include "compiler/codegen/effects/x86_64/effect_policy_codegen.inc"

extern neboc_assembly_writer_append_bytes
extern neboc_policy_runtime_check

section .rodata
codegen_template:
    db 10, 'section .text', 10
    db 'global nebo_fn_1', 10
    db 'nebo_fn_1:', 10
    db '    mov eax, 0x'
codegen_hex_offset equ $ - codegen_template
    db '00000000', 10
    db '    ret', 10
codegen_template_length equ $ - codegen_template
codegen_hex_digits: db '0123456789abcdef'

%define NEBOC_CODEGEN_TEMPLATE_BYTES 80
%define NEBOC_CODEGEN_RECHECK_OFFSET NEBOC_CODEGEN_TEMPLATE_BYTES
%define NEBOC_CODEGEN_LOCAL_BYTES \
    (NEBOC_CODEGEN_TEMPLATE_BYTES + neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_SIZE)
%define NEBOC_CODEGEN_ACTIVE_STACK_BYTES \
    (NEBOC_CODEGEN_LOCAL_BYTES + 5 * 8 + 8)

; Reject overlap between two half-open, already range-proved spans.
%macro CODEGEN_REQUIRE_DISJOINT 5
    cmp %2, %3
    jbe %%disjoint
    cmp %4, %1
    jbe %%disjoint
    jmp %5
%%disjoint:
%endmacro

; Extend the FNV-1a64 state in RAX/R8 with one little-endian qword.
%macro CODEGEN_HASH_QWORD 1
    mov rdx, %1
    mov ecx, 8
%%byte_loop:
    movzx r11d, dl
    xor rax, r11
    imul rax, r8
    shr rdx, 8
    dec ecx
    jnz %%byte_loop
%endmacro

section .text

; neboc_policy_codegen_emit_start(request*) -> StatusCode
;
; q0 points at an immutable PF004 35-qword native plan, q1 at its completed
; six-qword runtime check and q2 at a ready Assembly writer.  The emitter
; authenticates both pointer-independent PF004 hashes, checks the complete
; frozen native ABI plan and their cross-record identity, then performs one
; writer append.  No runtime policy call or external-effect adapter is emitted.
NEBOC_ABI_FUNCTION neboc_policy_codegen_emit_start
    test rdi, rdi
    jz .invalid_argument_direct
    test rdi, neboc_effects_capabilities_e_politicas_CODEGEN_ALIGNMENT - 1
    jnz .invalid_argument_direct

    ; Prove the caller request before reading q0.  Pointer/range/overlap errors
    ; are no-write failures, matching the PF003/PF004 transactional boundary.
    mov rax, rdi
    add rax, neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_SIZE
    jc .invalid_argument_direct

    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, NEBOC_CODEGEN_LOCAL_BYTES
    mov r12, rdi
    mov rbx, rax
    mov r13, [r12 + neboc_effects_capabilities_e_politicas_CODEGEN_NATIVE_OFFSET]
    mov r14, [r12 + neboc_effects_capabilities_e_politicas_CODEGEN_RUNTIME_OFFSET]
    mov r15, [r12 + neboc_effects_capabilities_e_politicas_CODEGEN_WRITER_OFFSET]

    test r13, r13
    jz .invalid_argument_saved
    test r13, neboc_effects_capabilities_e_politicas_NATIVE_ALIGNMENT - 1
    jnz .invalid_argument_saved
    mov r8, r13
    add r8, neboc_effects_capabilities_e_politicas_NATIVE_REQUEST_SIZE
    jc .invalid_argument_saved

    test r14, r14
    jz .invalid_argument_saved
    test r14, neboc_effects_capabilities_e_politicas_RUNTIME_ALIGNMENT - 1
    jnz .invalid_argument_saved
    mov r9, r14
    add r9, neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_SIZE
    jc .invalid_argument_saved

    test r15, r15
    jz .invalid_argument_saved
    test r15, neboc_effects_capabilities_e_politicas_CODEGEN_ALIGNMENT - 1
    jnz .invalid_argument_saved
    mov r10, r15
    add r10, NEBOC_ASSEMBLY_WRITER_SIZE
    jc .invalid_argument_saved

    CODEGEN_REQUIRE_DISJOINT r12, rbx, r13, r8, .invalid_argument_saved
    CODEGEN_REQUIRE_DISJOINT r12, rbx, r14, r9, .invalid_argument_saved
    CODEGEN_REQUIRE_DISJOINT r12, rbx, r15, r10, .invalid_argument_saved
    CODEGEN_REQUIRE_DISJOINT r13, r8, r14, r9, .invalid_argument_saved
    CODEGEN_REQUIRE_DISJOINT r13, r8, r15, r10, .invalid_argument_saved
    CODEGEN_REQUIRE_DISJOINT r14, r9, r15, r10, .invalid_argument_saved
    lea rax, [rsp + NEBOC_CODEGEN_ACTIVE_STACK_BYTES]
    CODEGEN_REQUIRE_DISJOINT r12, rbx, rsp, rax, .invalid_argument_saved
    CODEGEN_REQUIRE_DISJOINT r13, r8, rsp, rax, .invalid_argument_saved
    CODEGEN_REQUIRE_DISJOINT r14, r9, rsp, rax, .invalid_argument_saved
    CODEGEN_REQUIRE_DISJOINT r15, r10, rsp, rax, .invalid_argument_saved

    ; The writer descriptor alone is not the write boundary.  Authenticate its
    ; ready-state contract and prove the exact append destination range before
    ; trusting any input that the append could otherwise overwrite.  A genuine
    ; capacity failure is deferred to the writer so its documented error state
    ; remains observable, but that path performs no destination write.
    cmp qword [r15 + NEBOC_ASSEMBLY_WRITER_STATE_OFFSET], \
        NEBOC_ASSEMBLY_WRITER_STATE_READY
    jne .invalid_argument_saved
    cmp qword [r15 + NEBOC_ASSEMBLY_WRITER_FLAGS_OFFSET], \
        NEBOC_ASSEMBLY_WRITER_REQUIRED_FLAGS
    jne .invalid_argument_saved
    cmp qword [r15 + NEBOC_ASSEMBLY_WRITER_RESERVED_OFFSET], 0
    jne .invalid_argument_saved
    cmp qword [r15 + NEBOC_ASSEMBLY_WRITER_HASH_OFFSET], 0
    jne .invalid_argument_saved
    cmp qword [r15 + NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET], \
        NEBOC_ASSEMBLY_WRITER_ERROR_NONE
    jne .invalid_argument_saved
    cmp qword [r15 + NEBOC_ASSEMBLY_WRITER_LINE_COUNT_OFFSET], 0
    jne .invalid_argument_saved
    cmp qword [r15 + NEBOC_ASSEMBLY_WRITER_LABEL_COUNT_OFFSET], 0
    jne .invalid_argument_saved
    mov rax, [r15 + NEBOC_ASSEMBLY_WRITER_CAPACITY_OFFSET]
    test rax, rax
    jz .invalid_argument_saved
    cmp rax, NEBOC_ASSEMBLY_WRITER_MAX_OUTPUT_BYTES
    ja .invalid_argument_saved
    mov rcx, [r15 + NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
    cmp rcx, rax
    ja .invalid_argument_saved
    mov rdx, [r15 + NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET]
    test rdx, rdx
    jz .invalid_argument_saved
    mov r9, rdx
    add r9, rcx
    jc .invalid_argument_saved
    mov r11, rcx
    add r11, codegen_template_length
    jc .invalid_argument_saved
    cmp r11, rax
    ja .writer_capacity_deferred
    mov r11, r9
    add r11, codegen_template_length
    jc .invalid_argument_saved

    lea r8, [r13 + neboc_effects_capabilities_e_politicas_NATIVE_REQUEST_SIZE]
    lea r10, [r14 + neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_SIZE]
    CODEGEN_REQUIRE_DISJOINT r9, r11, r12, rbx, .invalid_argument_saved
    CODEGEN_REQUIRE_DISJOINT r9, r11, r13, r8, .invalid_argument_saved
    CODEGEN_REQUIRE_DISJOINT r9, r11, r14, r10, .invalid_argument_saved
    lea rax, [r15 + NEBOC_ASSEMBLY_WRITER_SIZE]
    CODEGEN_REQUIRE_DISJOINT r9, r11, r15, rax, .invalid_argument_saved
    lea rcx, [rsp + NEBOC_CODEGEN_ACTIVE_STACK_BYTES]
    CODEGEN_REQUIRE_DISJOINT r9, r11, rsp, rcx, .invalid_argument_saved
.writer_capacity_deferred:

    ; Authenticate every native-plan byte except its deliberately excluded IR
    ; pointer and hash slot before interpreting the selected instruction.
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.native_hash_loop:
    cmp rcx, neboc_effects_capabilities_e_politicas_NATIVE_HASHED_BYTES
    jae .native_hash_done
    movzx edx, byte [r13 + neboc_effects_capabilities_e_politicas_NATIVE_HASH_START_OFFSET + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .native_hash_loop
.native_hash_done:
    cmp rax, [r13 + neboc_effects_capabilities_e_politicas_NATIVE_HASH_OFFSET]
    jne .authentication_failure

    cmp qword [r13 + neboc_effects_capabilities_e_politicas_NATIVE_TARGET_ID_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_TARGET_X86_64_SYSV_ELF_LINUX
    jne .unsupported_target
    cmp qword [r13 + neboc_effects_capabilities_e_politicas_NATIVE_ABI_VERSION_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_ABI_VERSION
    jne .unsupported_target

    ; Exact PF004 x86-64 System V data, result and instruction selection.
    cmp qword [r13 + neboc_effects_capabilities_e_politicas_NATIVE_RECORD_SIZE_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_RECORD_SIZE
    jne .native_codegen_failure
    cmp qword [r13 + neboc_effects_capabilities_e_politicas_NATIVE_RECORD_ALIGNMENT_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_RECORD_ALIGNMENT
    jne .native_codegen_failure
    cmp qword [r13 + neboc_effects_capabilities_e_politicas_NATIVE_RECORD_PASSING_OFFSET], \
        NEBOC_NATIVE_RECORD_PASSING_BY_REFERENCE
    jne .native_codegen_failure
    cmp qword [r13 + NEBOC_NATIVE_RECORD_ARGUMENT_REGISTER_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_REGISTER_RDI
    jne .native_codegen_failure
    cmp qword [r13 + neboc_effects_capabilities_e_politicas_NATIVE_RESULT_SIZE_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_RESULT_SIZE
    jne .native_codegen_failure
    cmp qword [r13 + neboc_effects_capabilities_e_politicas_NATIVE_RESULT_ALIGNMENT_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_RESULT_ALIGNMENT
    jne .native_codegen_failure
    cmp qword [r13 + neboc_effects_capabilities_e_politicas_NATIVE_RESULT_ABI_CLASS_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_ABI_CLASS_INTEGER
    jne .native_codegen_failure
    cmp qword [r13 + neboc_effects_capabilities_e_politicas_NATIVE_RESULT_REGISTER_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_REGISTER_RAX
    jne .native_codegen_failure
    cmp qword [r13 + neboc_effects_capabilities_e_politicas_NATIVE_INSTRUCTION_OFFSET], \
        NEBOC_NATIVE_INSTRUCTION_MOV_EAX_IMM32
    jne .native_codegen_failure
    cmp qword [r13 + neboc_effects_capabilities_e_politicas_NATIVE_RUNTIME_GUARD_OFFSET], \
        NEBOC_NATIVE_RUNTIME_GUARD_POLICY_CHECK
    jne .native_codegen_failure
    cmp qword [r13 + neboc_effects_capabilities_e_politicas_NATIVE_FLAGS_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_FLAGS_REQUIRED
    jne .native_codegen_failure
    cmp qword [r13 + neboc_effects_capabilities_e_politicas_NATIVE_DIAGNOSTIC_OFFSET], 0
    jne .native_codegen_failure
    cmp qword [r13 + neboc_effects_capabilities_e_politicas_NATIVE_ALLOCATIONS_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_ALLOCATION_NONE
    jne .native_codegen_failure

    ; Only a policy-authenticated Int permit can reach materialization.
    cmp qword [r13 + NEBOC_NATIVE_POLICY_DECISION_OFFSET], \
        NEBOC_POLICY_DECISION_PERMIT
    jne .policy_failure
    cmp qword [r13 + NEBOC_NATIVE_POLICY_DIAGNOSTIC_OFFSET], 0
    jne .policy_failure
    mov rax, [r13 + NEBOC_NATIVE_POLICY_PERMIT_OFFSET]
    cmp rax, NEBOC_POLICY_MAX_PERMIT
    ja .policy_failure
    cmp rax, [r13 + NEBOC_NATIVE_PERMIT_IMMEDIATE_OFFSET]
    jne .authentication_failure
    mov rdx, [r13 + NEBOC_NATIVE_POLICY_INFERRED_EFFECTS_OFFSET]
    test rdx, ~NEBOC_EFFECT_MASK_KNOWN
    jnz .authentication_failure

    ; The runtime guard must describe this exact embedded policy and the full
    ; statically inferred mask.  Re-execute the PF004 owner on a private
    ; request before trusting either unkeyed metadata hash: its PF001-owned
    ; full-record comparison prevents a rehashed trusted-constructor bypass.
    lea rax, [r13 + NEBOC_NATIVE_POLICY_RECORD_OFFSET]
    cmp rax, [r14 + NEBOC_RUNTIME_POLICY_PTR_OFFSET]
    jne .authentication_failure

    lea rdi, [rsp + NEBOC_CODEGEN_RECHECK_OFFSET]
    mov ecx, neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS
    xor eax, eax
    cld
    rep stosq
    lea rax, [r13 + NEBOC_NATIVE_POLICY_RECORD_OFFSET]
    mov [rsp + NEBOC_CODEGEN_RECHECK_OFFSET + \
        NEBOC_RUNTIME_POLICY_PTR_OFFSET], rax
    mov rax, [r14 + NEBOC_RUNTIME_REQUESTED_MASK_OFFSET]
    mov [rsp + NEBOC_CODEGEN_RECHECK_OFFSET + \
        NEBOC_RUNTIME_REQUESTED_MASK_OFFSET], rax
    lea rdi, [rsp + NEBOC_CODEGEN_RECHECK_OFFSET]
    call neboc_policy_runtime_check
    test eax, eax
    jnz .authentication_failure
    lea rdi, [rsp + NEBOC_CODEGEN_RECHECK_OFFSET + 8]
    lea rsi, [r14 + 8]
    mov ecx, neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS - 1
    repe cmpsq
    jne .authentication_failure

    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    CODEGEN_HASH_QWORD [r13 + NEBOC_NATIVE_POLICY_AUDIT_HASH_OFFSET]
    CODEGEN_HASH_QWORD [r14 + NEBOC_RUNTIME_REQUESTED_MASK_OFFSET]
    CODEGEN_HASH_QWORD [r14 + neboc_effects_capabilities_e_politicas_RUNTIME_DECISION_OFFSET]
    CODEGEN_HASH_QWORD [r14 + neboc_effects_capabilities_e_politicas_RUNTIME_DIAGNOSTIC_OFFSET]
    cmp rax, [r14 + neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASH_OFFSET]
    jne .authentication_failure

    mov rax, [r13 + NEBOC_NATIVE_POLICY_INFERRED_EFFECTS_OFFSET]
    cmp rax, [r14 + NEBOC_RUNTIME_REQUESTED_MASK_OFFSET]
    jne .authentication_failure
    cmp qword [r14 + neboc_effects_capabilities_e_politicas_RUNTIME_DECISION_OFFSET], \
        NEBOC_POLICY_DECISION_PERMIT
    jne .runtime_policy_failure
    cmp qword [r14 + neboc_effects_capabilities_e_politicas_RUNTIME_DIAGNOSTIC_OFFSET], 0
    jne .runtime_policy_failure
    cmp qword [r14 + neboc_effects_capabilities_e_politicas_RUNTIME_ALLOCATIONS_OFFSET], \
        neboc_effects_capabilities_e_politicas_RUNTIME_ALLOCATION_NONE
    jne .authentication_failure

    ; Build the complete output in private stack storage.  A single writer
    ; append makes capacity/state failure atomic with respect to Assembly text.
    lea rsi, [rel codegen_template]
    mov rdi, rsp
    mov ecx, codegen_template_length
    cld
    rep movsb

    mov rax, [r13 + NEBOC_NATIVE_PERMIT_IMMEDIATE_OFFSET]
    lea rdi, [rsp + codegen_hex_offset + 8]
    lea rsi, [rel codegen_hex_digits]
    mov ecx, 8
.format_hex_loop:
    mov rdx, rax
    and edx, 15
    mov dl, [rsi + rdx]
    dec rdi
    mov [rdi], dl
    shr rax, 4
    dec ecx
    jnz .format_hex_loop

    mov rdi, r15
    mov rsi, rsp
    mov edx, codegen_template_length
    call neboc_assembly_writer_append_bytes
    test eax, eax
    jnz .writer_failure

    mov qword [r12 + neboc_effects_capabilities_e_politicas_CODEGEN_EMITTED_OFFSET], \
        neboc_effects_capabilities_e_politicas_CODEGEN_EMITTED_START
    mov qword [r12 + neboc_effects_capabilities_e_politicas_CODEGEN_DIAGNOSTIC_OFFSET], 0
    mov rax, [r13 + neboc_effects_capabilities_e_politicas_NATIVE_HASH_OFFSET]
    mov [r12 + neboc_effects_capabilities_e_politicas_CODEGEN_HASH_OFFSET], rax
    xor eax, eax
    jmp .done

.policy_failure:
    mov rdx, [r13 + NEBOC_NATIVE_POLICY_DIAGNOSTIC_OFFSET]
    test rdx, rdx
    jnz .invalid_source
    mov edx, neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    jmp .invalid_source

.runtime_policy_failure:
    mov rdx, [r14 + neboc_effects_capabilities_e_politicas_RUNTIME_DIAGNOSTIC_OFFSET]
    test rdx, rdx
    jnz .invalid_source
    mov edx, neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    jmp .invalid_source

.authentication_failure:
    mov edx, neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    jmp .invalid_source

.native_codegen_failure:
    mov edx, neboc_effects_capabilities_e_politicas_DIAG_CODEGEN_codegen_effects_x86_64
.invalid_source:
    mov qword [r12 + neboc_effects_capabilities_e_politicas_CODEGEN_EMITTED_OFFSET], \
        NEBOC_CODEGEN_EMITTED_NONE
    mov [r12 + neboc_effects_capabilities_e_politicas_CODEGEN_DIAGNOSTIC_OFFSET], rdx
    mov qword [r12 + neboc_effects_capabilities_e_politicas_CODEGEN_HASH_OFFSET], 0
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    jmp .done

.unsupported_target:
    mov qword [r12 + neboc_effects_capabilities_e_politicas_CODEGEN_EMITTED_OFFSET], \
        NEBOC_CODEGEN_EMITTED_NONE
    mov qword [r12 + neboc_effects_capabilities_e_politicas_CODEGEN_DIAGNOSTIC_OFFSET], \
        neboc_effects_capabilities_e_politicas_DIAG_CODEGEN_codegen_effects_x86_64
    mov qword [r12 + neboc_effects_capabilities_e_politicas_CODEGEN_HASH_OFFSET], 0
    mov eax, NEBOC_STATUS_UNSUPPORTED_TARGET
    jmp .done

.writer_failure:
    mov r11d, eax
    mov qword [r12 + neboc_effects_capabilities_e_politicas_CODEGEN_EMITTED_OFFSET], \
        NEBOC_CODEGEN_EMITTED_NONE
    mov qword [r12 + neboc_effects_capabilities_e_politicas_CODEGEN_DIAGNOSTIC_OFFSET], \
        neboc_effects_capabilities_e_politicas_DIAG_CODEGEN_codegen_effects_x86_64
    mov qword [r12 + neboc_effects_capabilities_e_politicas_CODEGEN_HASH_OFFSET], 0
    mov eax, r11d
    jmp .done

.invalid_argument_saved:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT

.done:
    add rsp, NEBOC_CODEGEN_LOCAL_BYTES
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret

.invalid_argument_direct:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

%if codegen_template_length > NEBOC_CODEGEN_TEMPLATE_BYTES
    %error "effects_capabilities_e_politicas codegen local template buffer is too small"
%endif
%if NEBOC_CODEGEN_LOCAL_BYTES % NEBOC_ABI_STACK_ALIGNMENT
    %error "effects_capabilities_e_politicas codegen local stack breaks SysV call alignment"
%endif

section .note.GNU-stack noalloc noexec nowrite progbits
