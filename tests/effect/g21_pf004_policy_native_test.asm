bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/effects/effect_policy_native.inc"

extern neboc_policy_native_lower
global _start

%macro VALID_IR 0
    dq 1,1,1,0,1,0,21,21
    dq 0xd76cc3ae969d8624,0x7f,1,0,0,100,7
    dq 1,0,0,1,0,0x3772b5c5ed088704,1,3
    dq 0x3992a1784fe0977a,0
    dq 2101,2102,2103,2111,2112,2113,3,21,1,0,0
    dq 0x97c382e5a7819ceb
%endmacro

%macro NATIVE_REQUEST 3
    dq %1,%2,%3
    times neboc_effects_capabilities_e_politicas_NATIVE_OUTPUT_QWORDS dq 0xa5a5a5a5a5a5a5a5
%endmacro

%macro CHECK_FAILURE_OUTPUTS 2
    lea rsi, [rel %1 + neboc_effects_capabilities_e_politicas_NATIVE_OUTPUT_OFFSET]
    xor ecx, ecx
%%loop:
    cmp ecx, (neboc_effects_capabilities_e_politicas_NATIVE_DIAGNOSTIC_OFFSET - neboc_effects_capabilities_e_politicas_NATIVE_OUTPUT_OFFSET) / 8
    jne %%zero
    cmp qword [rsi], %2
    jne fail
    jmp %%next
%%zero:
    cmp qword [rsi], 0
    jne fail
%%next:
    add rsi, 8
    inc ecx
    cmp ecx, neboc_effects_capabilities_e_politicas_NATIVE_OUTPUT_QWORDS
    jb %%loop
%endmacro

%macro CHECK_UNCHANGED_OUTPUTS 1
    lea rsi, [rel %1 + neboc_effects_capabilities_e_politicas_NATIVE_OUTPUT_OFFSET]
    mov ecx, neboc_effects_capabilities_e_politicas_NATIVE_OUTPUT_QWORDS
    mov rax, 0xa5a5a5a5a5a5a5a5
%%loop:
    cmp [rsi], rax
    jne fail
    add rsi, 8
    dec ecx
    jnz %%loop
%endmacro

%macro SNAPSHOT_NATIVE_REQUEST 1
    lea rsi, [rel %1]
    lea rdi, [rel native_request_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_NATIVE_REQUEST_QWORDS
    cld
    rep movsq
%endmacro

%macro CHECK_NATIVE_REQUEST_SNAPSHOT 1
    lea rdi, [rel %1]
    lea rsi, [rel native_request_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_NATIVE_REQUEST_QWORDS
    cld
    repe cmpsq
    jne fail
%endmacro

section .rodata align=8
native_matrix_cases:
    dq native_case_n01, native_case_n02, native_case_n03, native_case_n04
    dq native_case_n05, native_case_n06, native_case_n07, native_case_n08
    dq native_case_n09, native_case_n10, native_case_n11, native_case_n12
    dq native_case_n13, native_case_n14, native_case_n15, native_case_n16
    dq native_case_n17, native_case_n18
native_matrix_cases_end:
native_matrix_case_count equ (native_matrix_cases_end-native_matrix_cases)/8
%if native_matrix_case_count != 18
    %error "EFFECTS-CAPABILITIES-E-POLITICAS-PF004 requires exactly eighteen native matrix cases"
%endif

section .data align=16
ir_valid:
    VALID_IR
ir_valid_second:
    VALID_IR
ir_forged:
    VALID_IR

; N01 pure permit=0, N03 transitive union, N04 all effects and N05 permit=255.
ir_pure_zero:
    dq 0,0,0,0,0,0,0,0
    dq 0xf14b84b8290b8965,0x7f,0,0,0,100,7
    dq 0,0,0,0,0,0xde9fa0da6fc22a85,1,3
    dq 0xee14cf1a2855214e,0
    dq 2101,2102,2103,2111,2112,2113,3,0,0,0,0
    dq 0x72e7b6a061beece2
ir_transitive:
    dq 3,3,3,0,2,0,2701,27
    dq 0x0f2c843bc964bf07,0x7f,1,2,0,100,7
    dq 3,0,0,2,0,0x45135efab35bd4c6,1,3
    dq 0x68f150b242eb2637,0
    dq 2101,2102,2103,2111,2112,2113,3,27,3,0,0
    dq 0xc03f2f7e1ae86c09
ir_all_effects:
    dq 0x7ff,0x7ff,0x7ff,0,11,3,2801,28
    dq 0x1182195480383f1e,0x7f,0x7ff,0,0,100,7
    dq 0x7ff,0,0,11,0,0xb859396417dc0d97,1,3
    dq 0xdfbe52702e8a530b,0
    dq 2101,2102,2103,2111,2112,2113,3,28,0x7ff,0,0
    dq 0xa73cda9829d92b47
ir_permit_255:
    dq 0,0,0,0,0,0,0,255
    dq 0x1f2172cf391e497a,0x7f,0,0,0,100,7
    dq 0,0,0,0,0,0x3f0ffe83be5399ba,1,3
    dq 0xc50adc58cfdaecd2,0
    dq 2101,2102,2103,2111,2112,2113,3,255,0,0,0
    dq 0x0fddf8d740875d34
ir_semantic_forged:
    VALID_IR
ir_hash_forged:
    VALID_IR
ir_deny:
    VALID_IR

native_success:
    NATIVE_REQUEST ir_valid,1,1
native_second:
    NATIVE_REQUEST ir_valid_second,1,1
native_target:
    NATIVE_REQUEST ir_valid,2,1
native_abi:
    NATIVE_REQUEST ir_valid,1,2
native_forged:
    NATIVE_REQUEST ir_forged,1,1
native_overlap:
    NATIVE_REQUEST native_overlap,1,1
native_bad_ir_alignment:
    NATIVE_REQUEST ir_valid + 1,1,1
native_pure_zero:
    NATIVE_REQUEST ir_pure_zero,1,1
native_transitive:
    NATIVE_REQUEST ir_transitive,1,1
native_all_effects:
    NATIVE_REQUEST ir_all_effects,1,1
native_permit_255:
    NATIVE_REQUEST ir_permit_255,1,1
native_semantic_forged:
    NATIVE_REQUEST ir_semantic_forged,1,1
native_hash_forged:
    NATIVE_REQUEST ir_hash_forged,1,1
native_deny:
    NATIVE_REQUEST ir_deny,1,1
native_null_ir:
    NATIVE_REQUEST 0,1,1
native_wrap_ir:
    NATIVE_REQUEST -8,1,1

expected_record:
    dq 1,0,1,1,1,0,1,0,21,21,1,0,0,1,0
    dq 0x3772b5c5ed088704,1
expected_metadata:
    dq 136,8,1,1,8,8,1,2,1,21,1,0x3ff,0,0
    dq 0x6ad97e2082d8051a
expected_pure_record:
    dq 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dq 0xde9fa0da6fc22a85,1

align 16
misaligned_native:
    times neboc_effects_capabilities_e_politicas_NATIVE_REQUEST_SIZE + 1 db 0x5a

section .bss align=16
native_request_backup: resq neboc_effects_capabilities_e_politicas_NATIVE_REQUEST_QWORDS

section .text
_start:
    ; Canonical direct-console native plan and exact pointer-independent hash.
native_case_n02:
    mov r15d, 2
    lea rdi, [rel native_success]
    call neboc_policy_native_lower
    test eax, eax
    jnz fail
    lea rsi, [rel native_success + NEBOC_NATIVE_POLICY_RECORD_OFFSET]
    lea rdi, [rel expected_record]
    mov ecx, 17
    cld
    repe cmpsq
    jne fail
    lea rsi, [rel native_success + neboc_effects_capabilities_e_politicas_NATIVE_RECORD_SIZE_OFFSET]
    lea rdi, [rel expected_metadata]
    mov ecx, 15
    repe cmpsq
    jne fail

native_case_n06:
    mov r15d, 6
    lea rdi, [rel native_second]
    call neboc_policy_native_lower
    test eax, eax
    jnz fail
    mov rax, [rel native_success + neboc_effects_capabilities_e_politicas_NATIVE_HASH_OFFSET]
    cmp [rel native_second + neboc_effects_capabilities_e_politicas_NATIVE_HASH_OFFSET], rax
    jne fail

    ; N01/N03/N04/N05: independent boundary fixtures and exact GOLDEN hashes.
native_case_n01:
    mov r15d, 1
    lea rdi, [rel native_pure_zero]
    call neboc_policy_native_lower
    test eax, eax
    jnz fail
    cmp qword [rel native_pure_zero + NEBOC_NATIVE_POLICY_INFERRED_EFFECTS_OFFSET], 0
    jne fail
    cmp qword [rel native_pure_zero + NEBOC_NATIVE_POLICY_PERMIT_OFFSET], 0
    jne fail
    cmp qword [rel native_pure_zero + NEBOC_NATIVE_PERMIT_IMMEDIATE_OFFSET], 0
    jne fail
    lea rsi, [rel native_pure_zero + NEBOC_NATIVE_POLICY_RECORD_OFFSET]
    lea rdi, [rel expected_pure_record]
    mov ecx, NEBOC_POLICY_REQUEST_QWORDS
    repe cmpsq
    jne fail
    mov rax, 0x7d9a14c9b41354ae
    cmp [rel native_pure_zero + neboc_effects_capabilities_e_politicas_NATIVE_HASH_OFFSET], rax
    jne fail

native_case_n03:
    mov r15d, 3
    lea rdi, [rel native_transitive]
    call neboc_policy_native_lower
    test eax, eax
    jnz fail
    cmp qword [rel native_transitive + NEBOC_NATIVE_POLICY_DIRECT_EFFECTS_OFFSET], 1
    jne fail
    cmp qword [rel native_transitive + NEBOC_NATIVE_POLICY_CALLEE_EFFECTS_OFFSET], 2
    jne fail
    cmp qword [rel native_transitive + NEBOC_NATIVE_POLICY_INFERRED_EFFECTS_OFFSET], 3
    jne fail
    mov rax, 0xedf05703f396b9a5
    cmp [rel native_transitive + neboc_effects_capabilities_e_politicas_NATIVE_HASH_OFFSET], rax
    jne fail

native_case_n04:
    mov r15d, 4
    lea rdi, [rel native_all_effects]
    call neboc_policy_native_lower
    test eax, eax
    jnz fail
    cmp qword [rel native_all_effects + NEBOC_NATIVE_POLICY_INFERRED_EFFECTS_OFFSET], 0x7ff
    jne fail
    cmp qword [rel native_all_effects + NEBOC_NATIVE_POLICY_COST_OFFSET], 11
    jne fail
    mov rax, 0xbf6cac58049bf220
    cmp [rel native_all_effects + neboc_effects_capabilities_e_politicas_NATIVE_HASH_OFFSET], rax
    jne fail

native_case_n05:
    mov r15d, 5
    lea rdi, [rel native_permit_255]
    call neboc_policy_native_lower
    test eax, eax
    jnz fail
    cmp qword [rel native_permit_255 + NEBOC_NATIVE_PERMIT_IMMEDIATE_OFFSET], 255
    jne fail
    mov rax, 0x27178d44abbb4942
    cmp [rel native_permit_255 + neboc_effects_capabilities_e_politicas_NATIVE_HASH_OFFSET], rax
    jne fail

    ; N07/N08/N10: authenticate semantic hash, final IR hash and decision.
native_case_n07:
    mov r15d, 7
    xor qword [rel ir_semantic_forged + neboc_effects_capabilities_e_politicas_IR_SEMANTIC_HASH_OFFSET], 1
    lea rdi, [rel native_semantic_forged]
    call neboc_policy_native_lower
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    CHECK_FAILURE_OUTPUTS native_semantic_forged, neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64

native_case_n08:
    mov r15d, 8
    xor qword [rel ir_hash_forged + neboc_effects_capabilities_e_politicas_IR_HASH_OFFSET], 1
    lea rdi, [rel native_hash_forged]
    call neboc_policy_native_lower
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    CHECK_FAILURE_OUTPUTS native_hash_forged, neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64

native_case_n10:
    mov r15d, 10
    mov qword [rel ir_deny + neboc_effects_capabilities_e_politicas_IR_DECISION_OFFSET], 0
    mov rax, 0x288a19c252aa137b
    mov [rel ir_deny + neboc_effects_capabilities_e_politicas_IR_SEMANTIC_HASH_OFFSET], rax
    lea rdi, [rel native_deny]
    call neboc_policy_native_lower
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    CHECK_FAILURE_OUTPUTS native_deny, neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64

    ; Unsupported target and ABI select the stable CODEGEN diagnostic.
native_case_n11:
    mov r15d, 11
    lea rdi, [rel native_target]
    call neboc_policy_native_lower
    cmp eax, NEBOC_STATUS_UNSUPPORTED_TARGET
    jne fail
    CHECK_FAILURE_OUTPUTS native_target, neboc_effects_capabilities_e_politicas_DIAG_CODEGEN_codegen_effects_x86_64

    mov r15d, 11
    lea rdi, [rel native_abi]
    call neboc_policy_native_lower
    cmp eax, NEBOC_STATUS_UNSUPPORTED_TARGET
    jne fail
    CHECK_FAILURE_OUTPUTS native_abi, neboc_effects_capabilities_e_politicas_DIAG_CODEGEN_codegen_effects_x86_64

    ; Original q25..q36 must match PF003's independently regenerated outputs.
native_case_n09:
    mov r15d, 9
    xor qword [rel ir_forged + NEBOC_IR_HIR_EFFECT_UNION_OFFSET], 1
    lea rdi, [rel native_forged]
    call neboc_policy_native_lower
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    CHECK_FAILURE_OUTPUTS native_forged, neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64

    ; N14-N17: null, misaligned, overlapping and wrapping IR spans are no-write.
native_case_n14:
    mov r15d, 14
    SNAPSHOT_NATIVE_REQUEST native_null_ir
    lea rdi, [rel native_null_ir]
    call neboc_policy_native_lower
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    CHECK_NATIVE_REQUEST_SNAPSHOT native_null_ir

native_case_n17:
    mov r15d, 17
    SNAPSHOT_NATIVE_REQUEST native_wrap_ir
    lea rdi, [rel native_wrap_ir]
    call neboc_policy_native_lower
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    CHECK_NATIVE_REQUEST_SNAPSHOT native_wrap_ir

    ; The 280-byte request range itself must be proved before q0 is loaded.
    mov rdi, -8
    call neboc_policy_native_lower
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail

    ; Request/IR overlap and IR misalignment fail before touching all outputs.
native_case_n16:
    mov r15d, 16
    SNAPSHOT_NATIVE_REQUEST native_overlap
    mov rax, [rel native_overlap + neboc_effects_capabilities_e_politicas_NATIVE_OUTPUT_OFFSET]
    lea rdi, [rel native_overlap]
    call neboc_policy_native_lower
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    CHECK_NATIVE_REQUEST_SNAPSHOT native_overlap

native_case_n15:
    mov r15d, 15
    SNAPSHOT_NATIVE_REQUEST native_bad_ir_alignment
    mov rax, [rel native_bad_ir_alignment + neboc_effects_capabilities_e_politicas_NATIVE_OUTPUT_OFFSET]
    lea rdi, [rel native_bad_ir_alignment]
    call neboc_policy_native_lower
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    CHECK_NATIVE_REQUEST_SNAPSHOT native_bad_ir_alignment

    ; Null/misaligned request rejection is also no-write.
native_case_n12:
    mov r15d, 12
    xor edi, edi
    call neboc_policy_native_lower
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
native_case_n13:
    mov r15d, 13
    lea rsi, [rel misaligned_native + 1]
    lea rdi, [rel native_request_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_NATIVE_REQUEST_QWORDS
    rep movsq
    lea rdi, [rel misaligned_native + 1]
    call neboc_policy_native_lower
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    lea rdi, [rel misaligned_native + 1]
    lea rsi, [rel native_request_backup]
    mov ecx, neboc_effects_capabilities_e_politicas_NATIVE_REQUEST_QWORDS
    repe cmpsq
    jne fail

    ; SysV callee-saved registers and a clear DF hold on the public API.
native_case_n18:
    mov r15d, 18
    mov rbx, 0x11111111
    mov rbp, 0x22222222
    mov r12, 0x33333333
    mov r13, 0x44444444
    mov r14, 0x55555555
    mov r15, 0x66666666
    std
    lea rdi, [rel native_second]
    call neboc_policy_native_lower
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

    xor edi, edi
    jmp exit

fail_abi:
    cld
    mov edi, 18
    jmp exit
fail:
    cld
    mov edi, r15d
exit:
    mov eax, 60
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
