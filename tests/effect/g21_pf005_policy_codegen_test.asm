; Nebo Assembly — EFFECTS-CAPABILITIES-E-POLITICAS-PF005 authenticated policy codegen direct tests
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/semantic/effect/effect_policy.inc"
%include "compiler/lowering/effects/effect_policy_native.inc"
%include "runtime/effects/effect_policy_runtime.inc"
%include "compiler/codegen/effects/x86_64/effect_policy_codegen.inc"

extern neboc_assembly_writer_init
extern neboc_policy_codegen_emit_start
global _start

%define TEST_BUFFER_CAPACITY 256
%define TEST_REPEAT_COUNT 256
%define TEST_POISON 0xa5a5a5a5a5a5a5a5

%macro CASE 1
    mov dword [rel case_id], %1
%endmacro

%macro SNAPSHOT_CODEGEN_REQUEST 0
    lea rsi, [rel codegen_request]
    lea rdi, [rel codegen_request_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_QWORDS
    cld
    rep movsq
%endmacro

%macro REQUIRE_CODEGEN_REQUEST_UNCHANGED 0
    lea rdi, [rel codegen_request]
    lea rsi, [rel codegen_request_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_QWORDS
    cld
    repe cmpsq
    jne fail
%endmacro

; Pointer/range/overlap errors are rejected before any request output or writer
; byte is touched.  The caller snapshots after installing the invalid pointer.
%macro EXPECT_INVALID_ARGUMENT_NO_WRITE 0
    SNAPSHOT_CODEGEN_REQUEST
    lea rdi, [rel codegen_request]
    call neboc_policy_codegen_emit_start
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    REQUIRE_CODEGEN_REQUEST_UNCHANGED
    call require_writer_empty
%endmacro

; Authenticated-source failures publish only {none, diagnostic, zero hash}; the
; immutable native/runtime inputs and the Assembly writer remain unchanged.
%macro EXPECT_SOURCE_FAILURE 1
    call snapshot_sources
    call snapshot_writer_and_output
    lea rdi, [rel codegen_request]
    call neboc_policy_codegen_emit_start
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_EMITTED_OFFSET], \
        NEBOC_CODEGEN_EMITTED_NONE
    jne fail
    cmp qword [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_DIAGNOSTIC_OFFSET], %1
    jne fail
    cmp qword [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_HASH_OFFSET], 0
    jne fail
    call require_codegen_input_pointers
    call require_sources_unchanged
    call require_writer_and_output_unchanged
%endmacro

; Invalid writer descriptors and destination spans are a stronger no-write
; boundary: request inputs/outputs, both authenticated sources, the complete
; writer descriptor and the ordinary output arena must all remain bit-exact.
%macro EXPECT_WRITER_CONTRACT_INVALID_NO_WRITE 0
    call snapshot_full_state
    lea rdi, [rel codegen_request]
    call neboc_policy_codegen_emit_start
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    call require_full_state_unchanged
%endmacro

section .rodata align=16
; Exact PF004 N02 native plan.  q0 is deliberately zero: the native plan hash
; and PF005 materialization contract exclude the already-consumed PF003 IR
; pointer.  q1..q34 are the frozen x86-64/System V plan and GOLDEN hash.
native_template:
    dq 0,1,1
    dq 1,0,1,1,1,0,1,0,21,21,1,0,0,1,0
    dq 0x3772b5c5ed088704,1
    dq 136,8,1,1,8,8,1,2,1,21,1,0x3ff,0,0
    dq 0x6ad97e2082d8051a
native_template_end:

%if (native_template_end-native_template) != neboc_effects_capabilities_e_politicas_NATIVE_REQUEST_SIZE
    %error "EFFECTS-CAPABILITIES-E-POLITICAS-PF005 native GOLDEN size drift"
%endif

; q1..q5 of PF004 R02.  q0 is rebound to native_work.q3 after every reset.
runtime_template_tail:
    dq NEBOC_EFFECT_CONSOLE_WRITE
    dq NEBOC_POLICY_DECISION_PERMIT
    dq 0
    dq 0x403da4ba21376de6
    dq neboc_effects_capabilities_e_politicas_RUNTIME_ALLOCATION_NONE
runtime_template_tail_end:

%if (runtime_template_tail_end-runtime_template_tail) != \
        neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_SIZE - 8
    %error "EFFECTS-CAPABILITIES-E-POLITICAS-PF005 runtime GOLDEN size drift"
%endif

expected_assembly:
    db 10, 'section .text', 10
    db 'global nebo_fn_1', 10
    db 'nebo_fn_1:', 10
    db '    mov eax, 0x00000015', 10
    db '    ret', 10
expected_assembly_end:
expected_assembly_length equ expected_assembly_end-expected_assembly

expected_assembly_permit_zero:
    db 10, 'section .text', 10
    db 'global nebo_fn_1', 10
    db 'nebo_fn_1:', 10
    db '    mov eax, 0x00000000', 10
    db '    ret', 10
expected_assembly_permit_zero_end:

expected_assembly_permit_max:
    db 10, 'section .text', 10
    db 'global nebo_fn_1', 10
    db 'nebo_fn_1:', 10
    db '    mov eax, 0x000000ff', 10
    db '    ret', 10
expected_assembly_permit_max_end:

%if expected_assembly_length != 75
    %error "EFFECTS-CAPABILITIES-E-POLITICAS-PF005 deterministic Assembly GOLDEN length drift"
%endif
%if (expected_assembly_permit_zero_end-expected_assembly_permit_zero) != \
        expected_assembly_length
    %error "EFFECTS-CAPABILITIES-E-POLITICAS-PF005 permit-zero Assembly GOLDEN length drift"
%endif
%if (expected_assembly_permit_max_end-expected_assembly_permit_max) != \
        expected_assembly_length
    %error "EFFECTS-CAPABILITIES-E-POLITICAS-PF005 permit-max Assembly GOLDEN length drift"
%endif

section .bss align=16
native_work: resq neboc_effects_capabilities_e_politicas_NATIVE_REQUEST_QWORDS
runtime_work: resq neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS
writer_work: resq NEBOC_ASSEMBLY_WRITER_QWORDS
codegen_request: resq neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_QWORDS
; The ordinary destination starts exactly at the request's half-open end.
; Every successful case therefore also proves that exact adjacency is legal.
output_buffer: resb TEST_BUFFER_CAPACITY

%if (output_buffer-codegen_request) != neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_SIZE
    %error "EFFECTS-CAPABILITIES-E-POLITICAS-PF005 request/output exact-adjacency drift"
%endif

native_backup: resq neboc_effects_capabilities_e_politicas_NATIVE_REQUEST_QWORDS
runtime_backup: resq neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS
writer_backup: resq NEBOC_ASSEMBLY_WRITER_QWORDS
codegen_request_backup: resq neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_QWORDS

output_backup: resb TEST_BUFFER_CAPACITY
repeat_counter: resd 1
case_id: resd 1

; Kept last so no later object depends on this deliberately odd-sized region.
misaligned_request: resb neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_SIZE + 1
misaligned_request_backup: resb neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_SIZE

section .text
_start:
    ; C01 — valid authenticated plan emits one exact, adapter-free start body.
    CASE 1
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    call snapshot_sources
    lea rdi, [rel codegen_request]
    call neboc_policy_codegen_emit_start
    test eax, eax
    jnz fail
    call require_success
    call require_sources_unchanged

    ; C02 — a forged PF004 native-plan hash never reaches the writer.
    CASE 2
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    xor qword [rel native_work + neboc_effects_capabilities_e_politicas_NATIVE_HASH_OFFSET], 1
    EXPECT_SOURCE_FAILURE neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64

    ; C03 — a forged runtime event hash never reaches the writer.
    CASE 3
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    xor qword [rel runtime_work + neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASH_OFFSET], 1
    EXPECT_SOURCE_FAILURE neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64

    ; C04 — even with a recomputed outer plan hash, a forged native policy
    ; decision is rejected by the explicit permit gate.
    CASE 4
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel native_work + NEBOC_NATIVE_POLICY_DECISION_OFFSET], \
        NEBOC_POLICY_DECISION_DENY
    call recompute_native_hash
    EXPECT_SOURCE_FAILURE neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64

    ; C05 — an internally hashed runtime denial is not an emission permit.
    CASE 5
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel runtime_work + neboc_effects_capabilities_e_politicas_RUNTIME_DECISION_OFFSET], \
        NEBOC_POLICY_DECISION_DENY
    call recompute_runtime_event_hash
    EXPECT_SOURCE_FAILURE neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64

    ; C06 — a forged requested mask with a matching event hash still fails the
    ; native/runtime cross-record identity check.
    CASE 6
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel runtime_work + NEBOC_RUNTIME_REQUESTED_MASK_OFFSET], \
        NEBOC_EFFECT_CONSOLE_READ
    call recompute_runtime_event_hash
    EXPECT_SOURCE_FAILURE neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64

    ; C07 — runtime allocation metadata is excluded from the event hash but is
    ; independently required to remain the frozen allocation-free value zero.
    CASE 7
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel runtime_work + neboc_effects_capabilities_e_politicas_RUNTIME_ALLOCATIONS_OFFSET], 1
    EXPECT_SOURCE_FAILURE neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64

    ; C08 — native allocation metadata is inside the plan hash and must also be
    ; zero; a self-consistently rehashed non-zero value is a CODEGEN failure.
    CASE 8
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel native_work + neboc_effects_capabilities_e_politicas_NATIVE_ALLOCATIONS_OFFSET], 1
    call recompute_native_hash
    EXPECT_SOURCE_FAILURE neboc_effects_capabilities_e_politicas_DIAG_CODEGEN_codegen_effects_x86_64

    ; C09 — insufficient capacity is atomic: no byte and no length is appended.
    CASE 9
    mov edi, expected_assembly_length - 1
    call prepare_valid
    call snapshot_sources
    lea rsi, [rel output_buffer]
    lea rdi, [rel output_backup]
    mov ecx, TEST_BUFFER_CAPACITY
    cld
    rep movsb
    lea rdi, [rel codegen_request]
    call neboc_policy_codegen_emit_start
    cmp eax, NEBOC_STATUS_LIMIT_EXCEEDED
    jne fail
    cmp qword [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_EMITTED_OFFSET], \
        NEBOC_CODEGEN_EMITTED_NONE
    jne fail
    cmp qword [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_DIAGNOSTIC_OFFSET], \
        neboc_effects_capabilities_e_politicas_DIAG_CODEGEN_codegen_effects_x86_64
    jne fail
    cmp qword [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_HASH_OFFSET], 0
    jne fail
    cmp qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET], 0
    jne fail
    cmp qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET], \
        NEBOC_ASSEMBLY_WRITER_ERROR_LIMIT
    jne fail
    lea rax, [rel output_buffer]
    cmp [rel writer_work + NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET], rax
    jne fail
    cmp qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_CAPACITY_OFFSET], \
        expected_assembly_length - 1
    jne fail
    cmp qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_STATE_OFFSET], \
        NEBOC_ASSEMBLY_WRITER_STATE_READY
    jne fail
    cmp qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_LINE_COUNT_OFFSET], 0
    jne fail
    cmp qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_LABEL_COUNT_OFFSET], 0
    jne fail
    cmp qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_HASH_OFFSET], 0
    jne fail
    cmp qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_FLAGS_OFFSET], \
        NEBOC_ASSEMBLY_WRITER_REQUIRED_FLAGS
    jne fail
    cmp qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_RESERVED_OFFSET], 0
    jne fail
    lea rdi, [rel output_buffer]
    lea rsi, [rel output_backup]
    mov ecx, TEST_BUFFER_CAPACITY
    repe cmpsb
    jne fail
    call require_codegen_input_pointers
    call require_sources_unchanged

    ; C10-C12 — null, misaligned and wrapping top-level request pointers.
    CASE 10
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    SNAPSHOT_CODEGEN_REQUEST
    xor edi, edi
    call neboc_policy_codegen_emit_start
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    REQUIRE_CODEGEN_REQUEST_UNCHANGED
    call require_writer_empty

    CASE 11
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    lea rsi, [rel codegen_request]
    lea rdi, [rel misaligned_request + 1]
    mov ecx, neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_SIZE
    cld
    rep movsb
    lea rsi, [rel misaligned_request + 1]
    lea rdi, [rel misaligned_request_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_SIZE
    rep movsb
    lea rdi, [rel misaligned_request + 1]
    call neboc_policy_codegen_emit_start
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    lea rdi, [rel misaligned_request + 1]
    lea rsi, [rel misaligned_request_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_SIZE
    repe cmpsb
    jne fail
    call require_writer_empty

    CASE 12
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov rdi, 0xfffffffffffffff8
    call neboc_policy_codegen_emit_start
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    call require_writer_empty

    ; C13-C21 — each referenced object rejects null, misalignment and unsigned
    ; address-space wrap without publishing request outputs.
    CASE 13
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_NATIVE_OFFSET], 0
    EXPECT_INVALID_ARGUMENT_NO_WRITE

    CASE 14
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    lea rax, [rel native_work + 1]
    mov [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_NATIVE_OFFSET], rax
    EXPECT_INVALID_ARGUMENT_NO_WRITE

    CASE 15
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov rax, 0xfffffffffffffff8
    mov [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_NATIVE_OFFSET], rax
    EXPECT_INVALID_ARGUMENT_NO_WRITE

    CASE 16
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_RUNTIME_OFFSET], 0
    EXPECT_INVALID_ARGUMENT_NO_WRITE

    CASE 17
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    lea rax, [rel runtime_work + 1]
    mov [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_RUNTIME_OFFSET], rax
    EXPECT_INVALID_ARGUMENT_NO_WRITE

    CASE 18
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov rax, 0xfffffffffffffff8
    mov [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_RUNTIME_OFFSET], rax
    EXPECT_INVALID_ARGUMENT_NO_WRITE

    CASE 19
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_WRITER_OFFSET], 0
    EXPECT_INVALID_ARGUMENT_NO_WRITE

    CASE 20
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    lea rax, [rel writer_work + 1]
    mov [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_WRITER_OFFSET], rax
    EXPECT_INVALID_ARGUMENT_NO_WRITE

    CASE 21
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov rax, 0xfffffffffffffff8
    mov [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_WRITER_OFFSET], rax
    EXPECT_INVALID_ARGUMENT_NO_WRITE

    ; C22-C27 — all six unordered pairs among request/native/runtime/writer are
    ; required to be disjoint under the frozen half-open range contract.
    CASE 22
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    lea rax, [rel codegen_request]
    mov [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_NATIVE_OFFSET], rax
    EXPECT_INVALID_ARGUMENT_NO_WRITE

    CASE 23
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    lea rax, [rel codegen_request]
    mov [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_RUNTIME_OFFSET], rax
    EXPECT_INVALID_ARGUMENT_NO_WRITE

    CASE 24
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    lea rax, [rel codegen_request]
    mov [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_WRITER_OFFSET], rax
    EXPECT_INVALID_ARGUMENT_NO_WRITE

    CASE 25
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    lea rax, [rel native_work]
    mov [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_RUNTIME_OFFSET], rax
    EXPECT_INVALID_ARGUMENT_NO_WRITE

    CASE 26
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    lea rax, [rel native_work]
    mov [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_WRITER_OFFSET], rax
    EXPECT_INVALID_ARGUMENT_NO_WRITE

    CASE 27
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    lea rax, [rel runtime_work]
    mov [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_WRITER_OFFSET], rax
    EXPECT_INVALID_ARGUMENT_NO_WRITE

    ; C28-C30 — the real append destination rejects a null buffer and both
    ; buffer+length and destination+template unsigned address-space wraps.
    CASE 28
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET], 0
    EXPECT_WRITER_CONTRACT_INVALID_NO_WRITE

    CASE 29
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov rax, 0xfffffffffffffff8
    mov [rel writer_work + NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET], rax
    mov qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET], 16
    EXPECT_WRITER_CONTRACT_INVALID_NO_WRITE

    CASE 30
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov rax, 0xffffffffffffffc0
    mov [rel writer_work + NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET], rax
    EXPECT_WRITER_CONTRACT_INVALID_NO_WRITE

    ; C31-C34 — the 75-byte destination may alias none of the request, native,
    ; runtime or writer-descriptor trust inputs.
    CASE 31
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    lea rax, [rel codegen_request]
    mov [rel writer_work + NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET], rax
    EXPECT_WRITER_CONTRACT_INVALID_NO_WRITE

    CASE 32
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    lea rax, [rel native_work]
    mov [rel writer_work + NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET], rax
    EXPECT_WRITER_CONTRACT_INVALID_NO_WRITE

    CASE 33
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    lea rax, [rel runtime_work]
    mov [rel writer_work + NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET], rax
    EXPECT_WRITER_CONTRACT_INVALID_NO_WRITE

    CASE 34
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    lea rax, [rel writer_work]
    mov [rel writer_work + NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET], rax
    EXPECT_WRITER_CONTRACT_INVALID_NO_WRITE

    ; C35-C36 — descriptor state and flags are authenticated before source use.
    CASE 35
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_STATE_OFFSET], \
        NEBOC_ASSEMBLY_WRITER_STATE_SEALED
    EXPECT_WRITER_CONTRACT_INVALID_NO_WRITE

    CASE 36
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    xor qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_FLAGS_OFFSET], \
        NEBOC_ASSEMBLY_WRITER_FLAG_DETERMINISTIC
    EXPECT_WRITER_CONTRACT_INVALID_NO_WRITE

    ; C37 — exact request-end/destination-start adjacency is legal.
    CASE 37
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    lea rax, [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_SIZE]
    cmp [rel writer_work + NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET], rax
    jne fail
    call snapshot_sources
    lea rdi, [rel codegen_request]
    call neboc_policy_codegen_emit_start
    test eax, eax
    jnz fail
    call require_success
    call require_sources_unchanged

    ; C38-C39 — both frozen permit boundaries retain coherent policy, native
    ; and runtime hashes and materialize the exact zero-extended imm32.
    CASE 38
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel native_work + NEBOC_NATIVE_POLICY_PERMIT_OFFSET], 0
    mov qword [rel native_work + NEBOC_NATIVE_PERMIT_IMMEDIATE_OFFSET], 0
    call recompute_policy_audit_hash
    call recompute_native_hash
    call recompute_runtime_event_hash
    mov rax, 0x4ce479a4738ea411
    cmp [rel native_work + NEBOC_NATIVE_POLICY_AUDIT_HASH_OFFSET], rax
    jne fail
    mov rax, 0x2332a2bc6f56ca64
    cmp [rel native_work + neboc_effects_capabilities_e_politicas_NATIVE_HASH_OFFSET], rax
    jne fail
    mov rax, 0x4e95d356796c7b44
    cmp [rel runtime_work + neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASH_OFFSET], rax
    jne fail
    call snapshot_sources
    lea rdi, [rel codegen_request]
    call neboc_policy_codegen_emit_start
    test eax, eax
    jnz fail
    lea rdi, [rel expected_assembly_permit_zero]
    call require_success_expected
    call require_sources_unchanged

    CASE 39
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel native_work + NEBOC_NATIVE_POLICY_PERMIT_OFFSET], \
        NEBOC_POLICY_MAX_PERMIT
    mov qword [rel native_work + NEBOC_NATIVE_PERMIT_IMMEDIATE_OFFSET], \
        NEBOC_POLICY_MAX_PERMIT
    call recompute_policy_audit_hash
    call recompute_native_hash
    call recompute_runtime_event_hash
    mov rax, 0xb3936597a7c5f62e
    cmp [rel native_work + NEBOC_NATIVE_POLICY_AUDIT_HASH_OFFSET], rax
    jne fail
    mov rax, 0x0511ac3f360eb947
    cmp [rel native_work + neboc_effects_capabilities_e_politicas_NATIVE_HASH_OFFSET], rax
    jne fail
    mov rax, 0xecb10351ddc13bc7
    cmp [rel runtime_work + neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASH_OFFSET], rax
    jne fail
    call snapshot_sources
    lea rdi, [rel codegen_request]
    call neboc_policy_codegen_emit_start
    test eax, eax
    jnz fail
    lea rdi, [rel expected_assembly_permit_max]
    call require_success_expected
    call require_sources_unchanged

    ; C40-C41 — mutable writer counters must still describe a fresh append-only
    ; stream; non-zero line/label counts are rejected without normalization.
    CASE 40
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_LINE_COUNT_OFFSET], 1
    EXPECT_WRITER_CONTRACT_INVALID_NO_WRITE

    CASE 41
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_LABEL_COUNT_OFFSET], 1
    EXPECT_WRITER_CONTRACT_INVALID_NO_WRITE

    ; C42-C47 — every remaining bounded writer preflight field is fail-closed
    ; and transactional: invalid capacity, length, hash, error and reserved
    ; metadata are rejected without normalization or partial publication.
    CASE 42
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_CAPACITY_OFFSET], 0
    EXPECT_WRITER_CONTRACT_INVALID_NO_WRITE

    CASE 43
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_CAPACITY_OFFSET], \
        NEBOC_ASSEMBLY_WRITER_MAX_OUTPUT_BYTES + 1
    EXPECT_WRITER_CONTRACT_INVALID_NO_WRITE

    CASE 44
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET], \
        TEST_BUFFER_CAPACITY + 1
    EXPECT_WRITER_CONTRACT_INVALID_NO_WRITE

    CASE 45
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_HASH_OFFSET], 1
    EXPECT_WRITER_CONTRACT_INVALID_NO_WRITE

    CASE 46
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET], \
        NEBOC_ASSEMBLY_WRITER_ERROR_BAD_ARGUMENT
    EXPECT_WRITER_CONTRACT_INVALID_NO_WRITE

    CASE 47
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_RESERVED_OFFSET], 1
    EXPECT_WRITER_CONTRACT_INVALID_NO_WRITE

    ; C48 — recomputing the unkeyed outer native hash is not provenance: a
    ; forged embedded capability is rejected by the PF004 owner recheck.
    CASE 48
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov qword [rel native_work + \
        NEBOC_NATIVE_POLICY_CAPABILITIES_OFFSET], 0
    call recompute_native_hash
    EXPECT_SOURCE_FAILURE neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64

    ; C49 — forging the embedded PF001 audit hash and coherently rehashing both
    ; outer native and runtime event metadata is still rejected by owner replay.
    CASE 49
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    xor qword [rel native_work + \
        NEBOC_NATIVE_POLICY_AUDIT_HASH_OFFSET], 1
    call recompute_native_hash
    call recompute_runtime_event_hash
    EXPECT_SOURCE_FAILURE neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64

    ; C50 — a destination aimed at the emitter's five saved registers/return
    ; frame is rejected before one byte can corrupt control flow.
    CASE 50
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    lea rax, [rsp - 48]
    mov [rel writer_work + NEBOC_ASSEMBLY_WRITER_BUFFER_OFFSET], rax
    EXPECT_WRITER_CONTRACT_INVALID_NO_WRITE

    ; C51 — public API preserves every SysV callee-saved register and clears DF.
    CASE 51
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    mov rbx, 0x11111111
    mov rbp, 0x22222222
    mov r12, 0x33333333
    mov r13, 0x44444444
    mov r14, 0x55555555
    mov r15, 0x66666666
    std
    lea rdi, [rel codegen_request]
    call neboc_policy_codegen_emit_start
    test eax, eax
    jnz fail_abi
    cmp rbx, 0x11111111
    jne fail_abi
    cmp rbp, 0x22222222
    jne fail_abi
    cmp r12, 0x33333333
    jne fail_abi
    cmp r13, 0x44444444
    jne fail_abi
    cmp r14, 0x55555555
    jne fail_abi
    cmp r15, 0x66666666
    jne fail_abi
    pushfq
    pop rax
    test rax, 1 << 10
    jnz fail_abi
    call require_success

    ; C52 — repeated fresh writers are byte-identical and allocation-free.
    CASE 52
    mov dword [rel repeat_counter], TEST_REPEAT_COUNT
.repeat:
    mov edi, TEST_BUFFER_CAPACITY
    call prepare_valid
    lea rdi, [rel codegen_request]
    call neboc_policy_codegen_emit_start
    test eax, eax
    jnz fail
    call require_success
    cmp qword [rel native_work + neboc_effects_capabilities_e_politicas_NATIVE_ALLOCATIONS_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_ALLOCATION_NONE
    jne fail
    cmp qword [rel runtime_work + neboc_effects_capabilities_e_politicas_RUNTIME_ALLOCATIONS_OFFSET], \
        neboc_effects_capabilities_e_politicas_RUNTIME_ALLOCATION_NONE
    jne fail
    dec dword [rel repeat_counter]
    jnz .repeat

    xor edi, edi
    jmp exit

; prepare_valid(capacity): install the exact immutable PF004 source records,
; initialize one fresh bounded writer and poison all transactional outputs.
prepare_valid:
    push rbx
    mov ebx, edi
    cld
    lea rsi, [rel native_template]
    lea rdi, [rel native_work]
    mov ecx, neboc_effects_capabilities_e_politicas_NATIVE_REQUEST_QWORDS
    rep movsq

    lea rdi, [rel runtime_work]
    lea rax, [rel native_work + NEBOC_NATIVE_POLICY_RECORD_OFFSET]
    stosq
    lea rsi, [rel runtime_template_tail]
    mov ecx, neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS - 1
    rep movsq

    lea rdi, [rel writer_work]
    xor eax, eax
    mov ecx, NEBOC_ASSEMBLY_WRITER_QWORDS
    rep stosq
    lea rdi, [rel output_buffer]
    mov al, 0xa5
    mov ecx, TEST_BUFFER_CAPACITY
    rep stosb

    lea rdi, [rel writer_work]
    lea rsi, [rel output_buffer]
    mov edx, ebx
    call neboc_assembly_writer_init
    test eax, eax
    jnz fail

    lea rax, [rel native_work]
    mov [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_NATIVE_OFFSET], rax
    lea rax, [rel runtime_work]
    mov [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_RUNTIME_OFFSET], rax
    lea rax, [rel writer_work]
    mov [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_WRITER_OFFSET], rax
    mov rax, TEST_POISON
    mov [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_EMITTED_OFFSET], rax
    mov [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_DIAGNOSTIC_OFFSET], rax
    mov [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_HASH_OFFSET], rax
    pop rbx
    ret

snapshot_sources:
    lea rsi, [rel native_work]
    lea rdi, [rel native_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_NATIVE_REQUEST_QWORDS
    cld
    rep movsq
    lea rsi, [rel runtime_work]
    lea rdi, [rel runtime_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS
    rep movsq
    ret

require_sources_unchanged:
    lea rdi, [rel native_work]
    lea rsi, [rel native_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_NATIVE_REQUEST_QWORDS
    cld
    repe cmpsq
    jne fail
    lea rdi, [rel runtime_work]
    lea rsi, [rel runtime_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS
    repe cmpsq
    jne fail
    ret

snapshot_writer_and_output:
    lea rsi, [rel writer_work]
    lea rdi, [rel writer_backup]
    mov ecx, NEBOC_ASSEMBLY_WRITER_QWORDS
    cld
    rep movsq
    lea rsi, [rel output_buffer]
    lea rdi, [rel output_backup]
    mov ecx, TEST_BUFFER_CAPACITY
    rep movsb
    ret

require_writer_and_output_unchanged:
    lea rdi, [rel writer_work]
    lea rsi, [rel writer_backup]
    mov ecx, NEBOC_ASSEMBLY_WRITER_QWORDS
    cld
    repe cmpsq
    jne fail
    lea rdi, [rel output_buffer]
    lea rsi, [rel output_backup]
    mov ecx, TEST_BUFFER_CAPACITY
    repe cmpsb
    jne fail
    ret

snapshot_full_state:
    lea rsi, [rel codegen_request]
    lea rdi, [rel codegen_request_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_QWORDS
    cld
    rep movsq
    lea rsi, [rel native_work]
    lea rdi, [rel native_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_NATIVE_REQUEST_QWORDS
    rep movsq
    lea rsi, [rel runtime_work]
    lea rdi, [rel runtime_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS
    rep movsq
    lea rsi, [rel writer_work]
    lea rdi, [rel writer_backup]
    mov ecx, NEBOC_ASSEMBLY_WRITER_QWORDS
    rep movsq
    lea rsi, [rel output_buffer]
    lea rdi, [rel output_backup]
    mov ecx, TEST_BUFFER_CAPACITY
    rep movsb
    ret

require_full_state_unchanged:
    lea rdi, [rel codegen_request]
    lea rsi, [rel codegen_request_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_QWORDS
    cld
    repe cmpsq
    jne fail
    lea rdi, [rel native_work]
    lea rsi, [rel native_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_NATIVE_REQUEST_QWORDS
    repe cmpsq
    jne fail
    lea rdi, [rel runtime_work]
    lea rsi, [rel runtime_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS
    repe cmpsq
    jne fail
    lea rdi, [rel writer_work]
    lea rsi, [rel writer_backup]
    mov ecx, NEBOC_ASSEMBLY_WRITER_QWORDS
    repe cmpsq
    jne fail
    lea rdi, [rel output_buffer]
    lea rsi, [rel output_backup]
    mov ecx, TEST_BUFFER_CAPACITY
    repe cmpsb
    jne fail
    ret

require_writer_empty:
    cmp qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET], 0
    jne fail
    cmp qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_STATE_OFFSET], \
        NEBOC_ASSEMBLY_WRITER_STATE_READY
    jne fail
    cmp qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET], \
        NEBOC_ASSEMBLY_WRITER_ERROR_NONE
    jne fail
    lea rdi, [rel output_buffer]
    mov al, 0xa5
    mov ecx, TEST_BUFFER_CAPACITY
    cld
    repe scasb
    jne fail
    ret

require_codegen_input_pointers:
    lea rax, [rel native_work]
    cmp [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_NATIVE_OFFSET], rax
    jne fail
    lea rax, [rel runtime_work]
    cmp [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_RUNTIME_OFFSET], rax
    jne fail
    lea rax, [rel writer_work]
    cmp [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_WRITER_OFFSET], rax
    jne fail
    ret

require_success:
    mov rax, 0x6ad97e2082d8051a
    cmp [rel native_work + neboc_effects_capabilities_e_politicas_NATIVE_HASH_OFFSET], rax
    jne fail
    lea rdi, [rel expected_assembly]
    jmp require_success_expected

; require_success_expected(expected_text*) validates common success state while
; allowing the coherent permit-boundary fixtures to select their exact GOLDEN.
require_success_expected:
    push rbx
    mov rbx, rdi
    call require_codegen_input_pointers
    cmp qword [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_EMITTED_OFFSET], \
        neboc_effects_capabilities_e_politicas_CODEGEN_EMITTED_START
    jne fail
    cmp qword [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_DIAGNOSTIC_OFFSET], 0
    jne fail
    mov rax, [rel native_work + neboc_effects_capabilities_e_politicas_NATIVE_HASH_OFFSET]
    cmp [rel codegen_request + neboc_effects_capabilities_e_politicas_CODEGEN_HASH_OFFSET], rax
    jne fail
    cmp qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET], \
        expected_assembly_length
    jne fail
    cmp qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_STATE_OFFSET], \
        NEBOC_ASSEMBLY_WRITER_STATE_READY
    jne fail
    cmp qword [rel writer_work + NEBOC_ASSEMBLY_WRITER_LAST_ERROR_OFFSET], \
        NEBOC_ASSEMBLY_WRITER_ERROR_NONE
    jne fail
    lea rdi, [rel output_buffer]
    mov rsi, rbx
    mov ecx, expected_assembly_length
    cld
    repe cmpsb
    jne fail
    cmp byte [rel output_buffer + expected_assembly_length], 0xa5
    jne fail
    cmp qword [rel native_work + neboc_effects_capabilities_e_politicas_NATIVE_ALLOCATIONS_OFFSET], \
        neboc_effects_capabilities_e_politicas_NATIVE_ALLOCATION_NONE
    jne fail
    cmp qword [rel runtime_work + neboc_effects_capabilities_e_politicas_RUNTIME_ALLOCATIONS_OFFSET], \
        neboc_effects_capabilities_e_politicas_RUNTIME_ALLOCATION_NONE
    jne fail
    pop rbx
    ret

; Recompute the embedded PF001 audit hash over q0..q14 after changing only the
; permit input at its frozen lower/upper boundaries.
recompute_policy_audit_hash:
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    lea rsi, [rel native_work + NEBOC_NATIVE_POLICY_RECORD_OFFSET]
    xor ecx, ecx
.loop:
    cmp ecx, NEBOC_POLICY_HASHED_BYTES
    jae .done
    movzx edx, byte [rsi + rcx]
    xor rax, rdx
    imul rax, r8
    inc ecx
    jmp .loop
.done:
    mov [rel native_work + NEBOC_NATIVE_POLICY_AUDIT_HASH_OFFSET], rax
    ret

; Recompute the pointer-independent PF004 q1..q33 native-plan hash after a
; controlled negative-fixture mutation.  This lets the test reach the field
; gate instead of merely exercising a stale outer hash.
recompute_native_hash:
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    lea rsi, [rel native_work + neboc_effects_capabilities_e_politicas_NATIVE_HASH_START_OFFSET]
    xor ecx, ecx
.loop:
    cmp ecx, neboc_effects_capabilities_e_politicas_NATIVE_HASHED_BYTES
    jae .done
    movzx edx, byte [rsi + rcx]
    xor rax, rdx
    imul rax, r8
    inc ecx
    jmp .loop
.done:
    mov [rel native_work + neboc_effects_capabilities_e_politicas_NATIVE_HASH_OFFSET], rax
    ret

; Recompute the exact runtime event hash over
; [native.policy.audit_hash, requested, decision, diagnostic].
recompute_runtime_event_hash:
    sub rsp, 8
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    mov rdx, [rel native_work + NEBOC_NATIVE_POLICY_AUDIT_HASH_OFFSET]
    call extend_hash_qword
    mov rdx, [rel runtime_work + NEBOC_RUNTIME_REQUESTED_MASK_OFFSET]
    call extend_hash_qword
    mov rdx, [rel runtime_work + neboc_effects_capabilities_e_politicas_RUNTIME_DECISION_OFFSET]
    call extend_hash_qword
    mov rdx, [rel runtime_work + neboc_effects_capabilities_e_politicas_RUNTIME_DIAGNOSTIC_OFFSET]
    call extend_hash_qword
    mov [rel runtime_work + neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASH_OFFSET], rax
    add rsp, 8
    ret

; RAX=current FNV-1a64 state, R8=prime, RDX=little-endian qword.
extend_hash_qword:
    mov ecx, 8
.loop:
    movzx r9d, dl
    xor rax, r9
    imul rax, r8
    shr rdx, 8
    dec ecx
    jnz .loop
    ret

fail_abi:
    cld
    mov dword [rel case_id], 51
fail:
    cld
    mov edi, [rel case_id]
    test edi, edi
    jnz exit
    mov edi, 255
exit:
    mov eax, 60
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
