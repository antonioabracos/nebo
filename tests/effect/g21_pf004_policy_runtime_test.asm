bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/effect/effect_policy.inc"
%include "runtime/effects/effect_policy_runtime.inc"

extern neboc_policy_evaluate
extern neboc_policy_runtime_check

%macro CASE 1
    mov dword [rel case_id], %1
%endmacro

%macro PREPARE_REQUEST 1
    lea rdi, [rel runtime_request]
    xor eax, eax
    mov ecx, neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS
    rep stosq
    lea rax, [rel policy_record]
    mov [rel runtime_request + NEBOC_RUNTIME_POLICY_RECORD_OFFSET], rax
    mov qword [rel runtime_request + NEBOC_RUNTIME_REQUESTED_MASK_OFFSET], %1
%endmacro

%macro REQUIRE_RUNTIME 3
    cmp eax, %1
    jne fail
    cmp qword [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_DECISION_OFFSET], %2
    jne fail
    cmp qword [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_DIAGNOSTIC_OFFSET], %3
    jne fail
    cmp qword [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_ALLOCATIONS_OFFSET], 0
    jne fail
    lea rdi, [rel runtime_request]
    call check_event_hash
    test eax, eax
    jnz fail
%endmacro

%macro POISON_RUNTIME_OUTPUTS 0
    mov rax, 0xa5a5a5a5a5a5a5a5
    mov [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_DECISION_OFFSET], rax
    mov [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_DIAGNOSTIC_OFFSET], rax
    mov [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASH_OFFSET], rax
    mov [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_ALLOCATIONS_OFFSET], rax
%endmacro

section .rodata align=8
runtime_matrix_cases:
    dq matrix_r01, matrix_r02, matrix_r03, matrix_r04, matrix_r05, matrix_r06, matrix_r07
    dq matrix_r08, matrix_r09, matrix_r10, matrix_r11, matrix_r12, matrix_r13, matrix_r14
runtime_matrix_cases_end:
runtime_matrix_case_count equ (runtime_matrix_cases_end-runtime_matrix_cases)/8
%if runtime_matrix_case_count != 14
    %error "EFFECTS-CAPABILITIES-E-POLITICAS-PF004 requires exactly fourteen runtime matrix cases"
%endif

section .bss align=16
policy_record: resq NEBOC_POLICY_REQUEST_QWORDS
policy_backup: resq NEBOC_POLICY_REQUEST_QWORDS
policy_second: resq NEBOC_POLICY_REQUEST_QWORDS
runtime_request: resq neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS
runtime_second: resq neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS
request_backup: resq neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS
event_preimage: resq 4
adjacent_pair: resq neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS + NEBOC_POLICY_REQUEST_QWORDS
overlap_pair: resq 24
case_id: resd 1
misaligned_request: resb neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_SIZE + 1
misaligned_backup: resb neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_SIZE

section .text
global _start

_start:
matrix_r01:
    CASE 1
    call prepare_pure_policy
    call snapshot_policy
    PREPARE_REQUEST 0
    lea rdi, [rel runtime_request]
    call neboc_policy_runtime_check
    REQUIRE_RUNTIME NEBOC_STATUS_OK, NEBOC_POLICY_DECISION_PERMIT, 0
    mov rax, 0xde67ebde3750011d
    cmp [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASH_OFFSET], rax
    jne fail
    call require_policy_unchanged

matrix_r02:
    CASE 2
    call prepare_single_policy
    call snapshot_policy
    PREPARE_REQUEST NEBOC_EFFECT_CONSOLE_WRITE
    lea rdi, [rel runtime_request]
    call neboc_policy_runtime_check
    REQUIRE_RUNTIME NEBOC_STATUS_OK, NEBOC_POLICY_DECISION_PERMIT, 0
    mov rax, 0x403da4ba21376de6
    cmp [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASH_OFFSET], rax
    jne fail
    call require_policy_unchanged

matrix_r03:
    CASE 3
    PREPARE_REQUEST 0
    lea rdi, [rel runtime_request]
    call neboc_policy_runtime_check
    REQUIRE_RUNTIME NEBOC_STATUS_OK, NEBOC_POLICY_DECISION_PERMIT, 0
    mov rax, 0xb792270e89f7b407
    cmp [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASH_OFFSET], rax
    jne fail
    call require_policy_unchanged

matrix_r04:
    CASE 4
    call prepare_green_policy
    call snapshot_policy
    PREPARE_REQUEST NEBOC_EFFECT_CONSOLE_WRITE
    lea rdi, [rel runtime_request]
    call neboc_policy_runtime_check
    REQUIRE_RUNTIME NEBOC_STATUS_OK, NEBOC_POLICY_DECISION_PERMIT, 0
    call require_policy_unchanged

    CASE 104
    PREPARE_REQUEST 0
    lea rdi, [rel runtime_request]
    call neboc_policy_runtime_check
    REQUIRE_RUNTIME NEBOC_STATUS_OK, NEBOC_POLICY_DECISION_PERMIT, 0
    call require_policy_unchanged

matrix_r05:
    CASE 5
    PREPARE_REQUEST NEBOC_EFFECT_CONSOLE_WRITE | NEBOC_EFFECT_CONSOLE_READ
    lea rdi, [rel runtime_request]
    call neboc_policy_runtime_check
    REQUIRE_RUNTIME NEBOC_STATUS_OK, NEBOC_POLICY_DECISION_PERMIT, 0
    call require_policy_unchanged

matrix_r06:
    CASE 6
    PREPARE_REQUEST NEBOC_EFFECT_FS_READ
    lea rdi, [rel runtime_request]
    call neboc_policy_runtime_check
    REQUIRE_RUNTIME NEBOC_STATUS_INVALID_SOURCE, NEBOC_POLICY_DECISION_DENY, neboc_effects_capabilities_e_politicas_DIAG_SECURITY_driver_cli_linux_x86_64
    call require_policy_unchanged

    ; A stale derived qword is rejected by the all-17-qword comparison.
    CASE 108
    call prepare_green_policy
    xor qword [rel policy_record + NEBOC_POLICY_COST_OFFSET], 1
    call snapshot_policy
    PREPARE_REQUEST 0
    lea rdi, [rel runtime_request]
    call neboc_policy_runtime_check
    REQUIRE_RUNTIME NEBOC_STATUS_INVALID_SOURCE, NEBOC_POLICY_DECISION_DENY, neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    call require_policy_unchanged

matrix_r07:
    CASE 7
    PREPARE_REQUEST 0x800
    lea rdi, [rel runtime_request]
    call neboc_policy_runtime_check
    REQUIRE_RUNTIME NEBOC_STATUS_INVALID_SOURCE, NEBOC_POLICY_DECISION_DENY, neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    call require_policy_unchanged

matrix_r08:
    CASE 8
    call prepare_single_policy
    xor qword [rel policy_record + NEBOC_POLICY_AUDIT_HASH_OFFSET], 1
    call snapshot_policy
    PREPARE_REQUEST 1
    lea rdi, [rel runtime_request]
    call neboc_policy_runtime_check
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_DECISION_OFFSET], 0
    jne fail
    cmp qword [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_DIAGNOSTIC_OFFSET], neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    jne fail
    mov rax, 0x3f46452b363b2236
    cmp [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASH_OFFSET], rax
    jne fail
    cmp qword [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_ALLOCATIONS_OFFSET], 0
    jne fail
    call require_policy_unchanged

matrix_r09:
    CASE 9
    call prepare_single_policy
    xor qword [rel policy_record + NEBOC_POLICY_DECISION_OFFSET], 1
    call snapshot_policy
    PREPARE_REQUEST 1
    lea rdi, [rel runtime_request]
    call neboc_policy_runtime_check
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_DECISION_OFFSET], 0
    jne fail
    cmp qword [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_DIAGNOSTIC_OFFSET], neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    jne fail
    mov rax, 0x3f46452b363b2236
    cmp [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASH_OFFSET], rax
    jne fail
    cmp qword [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_ALLOCATIONS_OFFSET], 0
    jne fail
    call require_policy_unchanged

    ; A canonical, internally consistent denial is still not a GREEN permit.
matrix_r10:
    CASE 10
    call prepare_denied_policy
    call snapshot_policy
    PREPARE_REQUEST 0
    lea rdi, [rel runtime_request]
    call neboc_policy_runtime_check
    REQUIRE_RUNTIME NEBOC_STATUS_INVALID_SOURCE, NEBOC_POLICY_DECISION_DENY, neboc_effects_capabilities_e_politicas_DIAG_SECURITY_driver_cli_linux_x86_64
    call require_policy_unchanged

matrix_r11:
    CASE 11
    xor edi, edi
    call neboc_policy_runtime_check
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    ; The 48-byte request range itself must wrap-reject before reading q0.
    mov rdi, -8
    call neboc_policy_runtime_check
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    lea rdi, [rel misaligned_request]
    mov ecx, neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_SIZE + 1
    mov al, 0x5a
    rep stosb
    lea rsi, [rel misaligned_request + 1]
    lea rdi, [rel misaligned_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_SIZE
    rep movsb
    lea rdi, [rel misaligned_request + 1]
    call neboc_policy_runtime_check
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    lea rdi, [rel misaligned_request + 1]
    lea rsi, [rel misaligned_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_SIZE
    repe cmpsb
    jne fail

    ; R12 and supplemental address failures preserve all six request qwords.
matrix_r12:
    CASE 12
    call prepare_green_policy
    PREPARE_REQUEST 0
    mov qword [rel runtime_request + NEBOC_RUNTIME_POLICY_RECORD_OFFSET], 0
    POISON_RUNTIME_OUTPUTS
    call snapshot_request
    lea rdi, [rel runtime_request]
    call neboc_policy_runtime_check
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    call require_request_unchanged

    CASE 109
    PREPARE_REQUEST 0
    lea rax, [rel policy_record + 1]
    mov [rel runtime_request + NEBOC_RUNTIME_POLICY_RECORD_OFFSET], rax
    POISON_RUNTIME_OUTPUTS
    call snapshot_request
    lea rdi, [rel runtime_request]
    call neboc_policy_runtime_check
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    call require_request_unchanged

    CASE 110
    PREPARE_REQUEST 0
    mov rax, -8
    mov [rel runtime_request + NEBOC_RUNTIME_POLICY_RECORD_OFFSET], rax
    POISON_RUNTIME_OUTPUTS
    call snapshot_request
    lea rdi, [rel runtime_request]
    call neboc_policy_runtime_check
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    call require_request_unchanged

    CASE 111
    lea rdi, [rel overlap_pair]
    xor eax, eax
    mov ecx, 24
    rep stosq
    lea rax, [rel overlap_pair]
    mov [rel overlap_pair + NEBOC_RUNTIME_POLICY_RECORD_OFFSET], rax
    mov rax, 0x1122334455667788
    mov [rel overlap_pair + neboc_effects_capabilities_e_politicas_RUNTIME_DECISION_OFFSET], rax
    mov [rel overlap_pair + neboc_effects_capabilities_e_politicas_RUNTIME_DIAGNOSTIC_OFFSET], rax
    mov [rel overlap_pair + neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASH_OFFSET], rax
    mov [rel overlap_pair + neboc_effects_capabilities_e_politicas_RUNTIME_ALLOCATIONS_OFFSET], rax
    lea rsi, [rel overlap_pair]
    lea rdi, [rel request_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS
    rep movsq
    lea rdi, [rel overlap_pair]
    call neboc_policy_runtime_check
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    lea rdi, [rel overlap_pair]
    lea rsi, [rel request_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS
    repe cmpsq
    jne fail

    ; Endpoint adjacency is legal: [request, request+48) then policy.
    CASE 112
    call prepare_green_policy
    lea rdi, [rel adjacent_pair]
    xor eax, eax
    mov ecx, neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS + NEBOC_POLICY_REQUEST_QWORDS
    rep stosq
    lea rax, [rel adjacent_pair + neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_SIZE]
    mov [rel adjacent_pair + NEBOC_RUNTIME_POLICY_RECORD_OFFSET], rax
    mov qword [rel adjacent_pair + NEBOC_RUNTIME_REQUESTED_MASK_OFFSET], 3
    lea rsi, [rel policy_record]
    lea rdi, [rel adjacent_pair + neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_SIZE]
    mov ecx, NEBOC_POLICY_REQUEST_QWORDS
    rep movsq
    lea rdi, [rel adjacent_pair]
    call neboc_policy_runtime_check
    cmp eax, NEBOC_STATUS_OK
    jne fail
    cmp qword [rel adjacent_pair + neboc_effects_capabilities_e_politicas_RUNTIME_DECISION_OFFSET], 1
    jne fail
    cmp qword [rel adjacent_pair + neboc_effects_capabilities_e_politicas_RUNTIME_DIAGNOSTIC_OFFSET], 0
    jne fail
    cmp qword [rel adjacent_pair + neboc_effects_capabilities_e_politicas_RUNTIME_ALLOCATIONS_OFFSET], 0
    jne fail
    lea rdi, [rel adjacent_pair]
    call check_event_hash
    test eax, eax
    jnz fail
    lea rdi, [rel adjacent_pair + neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_SIZE]
    lea rsi, [rel policy_record]
    mov ecx, NEBOC_POLICY_REQUEST_QWORDS
    repe cmpsq
    jne fail

matrix_r13:
    CASE 13
    call prepare_single_policy
    lea rsi, [rel policy_record]
    lea rdi, [rel policy_second]
    mov ecx, NEBOC_POLICY_REQUEST_QWORDS
    rep movsq
    PREPARE_REQUEST 1
    lea rdi, [rel runtime_request]
    call neboc_policy_runtime_check
    cmp eax, NEBOC_STATUS_OK
    jne fail
    mov rax, 0x403da4ba21376de6
    cmp [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASH_OFFSET], rax
    jne fail
    lea rdi, [rel runtime_second]
    xor eax, eax
    mov ecx, neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS
    rep stosq
    lea rax, [rel policy_second]
    mov [rel runtime_second + NEBOC_RUNTIME_POLICY_RECORD_OFFSET], rax
    mov qword [rel runtime_second + NEBOC_RUNTIME_REQUESTED_MASK_OFFSET], 1
    lea rdi, [rel runtime_second]
    call neboc_policy_runtime_check
    cmp eax, NEBOC_STATUS_OK
    jne fail
    mov rax, [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASH_OFFSET]
    cmp [rel runtime_second + neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASH_OFFSET], rax
    jne fail

    ; R14: poisoned repeated calls are deterministic; ABI and DF survive.
matrix_r14:
    CASE 14
    call prepare_single_policy
    call snapshot_policy
    PREPARE_REQUEST 1
    POISON_RUNTIME_OUTPUTS
    lea rdi, [rel runtime_request]
    call neboc_policy_runtime_check
    REQUIRE_RUNTIME NEBOC_STATUS_OK, NEBOC_POLICY_DECISION_PERMIT, 0
    mov rax, 0x403da4ba21376de6
    cmp [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASH_OFFSET], rax
    jne fail
    call require_policy_unchanged
    call snapshot_request

    mov rax, 0xb6b6b6b6b6b6b6b6
    mov [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_DECISION_OFFSET], rax
    mov [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_DIAGNOSTIC_OFFSET], rax
    mov [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASH_OFFSET], rax
    mov [rel runtime_request + neboc_effects_capabilities_e_politicas_RUNTIME_ALLOCATIONS_OFFSET], rax
    lea rdi, [rel runtime_request]
    call neboc_policy_runtime_check
    cmp eax, NEBOC_STATUS_OK
    jne fail
    call require_request_unchanged
    call require_policy_unchanged

    mov rbx, 0x1122334455667788
    mov rbp, 0x2233445566778899
    mov r12, 0x33445566778899aa
    mov r13, 0x445566778899aabb
    mov r14, 0x5566778899aabbcc
    mov r15, 0x66778899aabbccdd
    std
    lea rdi, [rel runtime_request]
    call neboc_policy_runtime_check
    cmp eax, NEBOC_STATUS_OK
    jne fail
    call require_request_unchanged
    call require_policy_unchanged
    mov rax, 0x1122334455667788
    cmp rbx, rax
    jne fail
    mov rax, 0x2233445566778899
    cmp rbp, rax
    jne fail
    mov rax, 0x33445566778899aa
    cmp r12, rax
    jne fail
    mov rax, 0x445566778899aabb
    cmp r13, rax
    jne fail
    mov rax, 0x5566778899aabbcc
    cmp r14, rax
    jne fail
    mov rax, 0x66778899aabbccdd
    cmp r15, rax
    jne fail
    pushfq
    pop rax
    test rax, 0x400
    jnz fail

    xor edi, edi
    mov eax, 60
    syscall

prepare_pure_policy:
    lea rdi, [rel policy_record]
    xor eax, eax
    mov ecx, NEBOC_POLICY_REQUEST_QWORDS
    rep stosq
    mov qword [rel policy_record + NEBOC_POLICY_PERMIT_OFFSET], 22
    sub rsp, 8
    lea rdi, [rel policy_record]
    call neboc_policy_evaluate
    add rsp, 8
    test eax, eax
    jnz fail
    mov rax, 0xdc46f55909eac513
    cmp [rel policy_record + NEBOC_POLICY_AUDIT_HASH_OFFSET], rax
    jne fail
    ret

prepare_single_policy:
    lea rdi, [rel policy_record]
    xor eax, eax
    mov ecx, NEBOC_POLICY_REQUEST_QWORDS
    rep stosq
    mov qword [rel policy_record + NEBOC_POLICY_DIRECT_EFFECTS_OFFSET], 1
    mov qword [rel policy_record + NEBOC_POLICY_DECLARED_EFFECTS_OFFSET], 1
    mov qword [rel policy_record + NEBOC_POLICY_CAPABILITIES_OFFSET], 1
    mov qword [rel policy_record + NEBOC_POLICY_ALLOW_OFFSET], 1
    mov qword [rel policy_record + NEBOC_POLICY_BUDGET_OFFSET], 1
    mov qword [rel policy_record + NEBOC_POLICY_AUDIT_ID_OFFSET], 21
    mov qword [rel policy_record + NEBOC_POLICY_PERMIT_OFFSET], 21
    sub rsp, 8
    lea rdi, [rel policy_record]
    call neboc_policy_evaluate
    add rsp, 8
    test eax, eax
    jnz fail
    mov rax, 0x3772b5c5ed088704
    cmp [rel policy_record + NEBOC_POLICY_AUDIT_HASH_OFFSET], rax
    jne fail
    ret

; Green policy: inferred/declared/capability/allow mask 3, cost 2.
prepare_green_policy:
    lea rdi, [rel policy_record]
    xor eax, eax
    mov ecx, NEBOC_POLICY_REQUEST_QWORDS
    rep stosq
    mov qword [rel policy_record + NEBOC_POLICY_DIRECT_EFFECTS_OFFSET], 1
    mov qword [rel policy_record + NEBOC_POLICY_CALLEE_EFFECTS_OFFSET], 2
    mov qword [rel policy_record + NEBOC_POLICY_DECLARED_EFFECTS_OFFSET], 3
    mov qword [rel policy_record + NEBOC_POLICY_CAPABILITIES_OFFSET], 3
    mov qword [rel policy_record + NEBOC_POLICY_ALLOW_OFFSET], 3
    mov qword [rel policy_record + NEBOC_POLICY_BUDGET_OFFSET], 2
    mov qword [rel policy_record + NEBOC_POLICY_TRUST_OFFSET], NEBOC_TRUST_PUBLIC
    mov qword [rel policy_record + NEBOC_POLICY_AUDIT_ID_OFFSET], 42
    mov qword [rel policy_record + NEBOC_POLICY_PERMIT_OFFSET], 7
    sub rsp, 8
    lea rdi, [rel policy_record]
    call neboc_policy_evaluate
    add rsp, 8
    test eax, eax
    jnz fail
    ret

prepare_denied_policy:
    lea rdi, [rel policy_record]
    xor eax, eax
    mov ecx, NEBOC_POLICY_REQUEST_QWORDS
    rep stosq
    mov qword [rel policy_record + NEBOC_POLICY_DIRECT_EFFECTS_OFFSET], 1
    mov qword [rel policy_record + NEBOC_POLICY_DECLARED_EFFECTS_OFFSET], 1
    mov qword [rel policy_record + NEBOC_POLICY_CAPABILITIES_OFFSET], 1
    mov qword [rel policy_record + NEBOC_POLICY_ALLOW_OFFSET], 1
    mov qword [rel policy_record + NEBOC_POLICY_BUDGET_OFFSET], 1
    ; audit_id remains zero: canonical SECURITY-006 denial.
    sub rsp, 8
    lea rdi, [rel policy_record]
    call neboc_policy_evaluate
    add rsp, 8
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel policy_record + NEBOC_POLICY_DIAGNOSTIC_OFFSET], neboc_effects_capabilities_e_politicas_DIAG_SECURITY_driver_cli_linux_x86_64
    jne fail
    ret

snapshot_policy:
    lea rsi, [rel policy_record]
    lea rdi, [rel policy_backup]
    mov ecx, NEBOC_POLICY_REQUEST_QWORDS
    rep movsq
    ret

require_policy_unchanged:
    lea rdi, [rel policy_record]
    lea rsi, [rel policy_backup]
    mov ecx, NEBOC_POLICY_REQUEST_QWORDS
    repe cmpsq
    jne fail
    ret

snapshot_request:
    lea rsi, [rel runtime_request]
    lea rdi, [rel request_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS
    rep movsq
    ret

require_request_unchanged:
    lea rdi, [rel runtime_request]
    lea rsi, [rel request_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS
    repe cmpsq
    jne fail
    ret

; rdi = runtime request; returns eax=0 iff q4 is exact FNV-1a64 over
; [record.audit_hash, requested_mask, decision, diagnostic].
check_event_hash:
    mov r10, rdi
    mov rsi, [r10 + NEBOC_RUNTIME_POLICY_RECORD_OFFSET]
    mov rdx, [rsi + NEBOC_POLICY_AUDIT_HASH_OFFSET]
    mov [rel event_preimage], rdx
    mov rdx, [r10 + NEBOC_RUNTIME_REQUESTED_MASK_OFFSET]
    mov [rel event_preimage + 8], rdx
    mov rdx, [r10 + neboc_effects_capabilities_e_politicas_RUNTIME_DECISION_OFFSET]
    mov [rel event_preimage + 16], rdx
    mov rdx, [r10 + neboc_effects_capabilities_e_politicas_RUNTIME_DIAGNOSTIC_OFFSET]
    mov [rel event_preimage + 24], rdx
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    lea rsi, [rel event_preimage]
    xor ecx, ecx
.hash_loop:
    cmp ecx, neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASHED_BYTES
    jae .hash_done
    movzx edx, byte [rsi + rcx]
    xor rax, rdx
    imul rax, r8
    inc ecx
    jmp .hash_loop
.hash_done:
    cmp rax, [r10 + neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASH_OFFSET]
    setne al
    movzx eax, al
    ret

fail:
    cld
    mov edi, [rel case_id]
    test edi, edi
    jnz .exit
    mov edi, 255
.exit:
    mov eax, 60
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
