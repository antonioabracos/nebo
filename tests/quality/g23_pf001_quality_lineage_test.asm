; QUALITY-CONFIDENCE-E-LINEAGE-PF001 native quality/confidence/lineage foundation tests
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/quality/quality_lineage.inc"

%if NEBOC_REQUEST_QWORDS != 50
    %error "quality_confidence_e_lineage record must remain 50 qwords"
%endif
%if neboc_quality_confidence_e_lineage_REQUEST_SIZE != 400
    %error "quality_confidence_e_lineage record must remain 400 bytes"
%endif

extern neboc_quality_lineage_evaluate
extern neboc_host_process_exit

section .bss align=16
request: resb neboc_quality_confidence_e_lineage_REQUEST_SIZE
first_hash: resq 1

section .text
clear_request:
    lea rdi, [rel request]
    mov ecx, NEBOC_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    ret

prepare_valid:
    call clear_request
    ; Empty/public privacidade_dados_sensiveis_e_zero_trust predecessor with bounded retention.
    mov qword [rel request + NEBOC_POLICY_PERMIT_OFFSET], 23
    mov qword [rel request + NEBOC_PRIVACY_RETENTION_LIMIT_OFFSET], 1
    mov qword [rel request + NEBOC_DIRECT_QUALITY_OFFSET], 900000
    mov qword [rel request + NEBOC_INHERITED_QUALITY_OFFSET], 800000
    mov qword [rel request + NEBOC_DIRECT_CONFIDENCE_OFFSET], 950000
    mov qword [rel request + NEBOC_INHERITED_CONFIDENCE_OFFSET], 700000
    mov qword [rel request + NEBOC_MIN_QUALITY_OFFSET], 750000
    mov qword [rel request + NEBOC_MIN_CONFIDENCE_OFFSET], 650000
    mov qword [rel request + NEBOC_SOURCE_ID_OFFSET], 2301
    mov qword [rel request + NEBOC_TRANSFORM_ID_OFFSET], 2302
    mov rax, 0x1122334455667788
    mov [rel request + NEBOC_PARENT_LINEAGE_HASH_OFFSET], rax
    ret

evaluate:
    lea rdi, [rel request]
    jmp neboc_quality_lineage_evaluate

global _start
_start:
    ; Null and misaligned inputs are rejected without writes.
    xor edi, edi
    call neboc_quality_lineage_evaluate
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    call prepare_valid
    mov qword [rel request + NEBOC_LINEAGE_HASH_OFFSET], -1
    lea rdi, [rel request + 1]
    call neboc_quality_lineage_evaluate
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    cmp qword [rel request + NEBOC_LINEAGE_HASH_OFFSET], -1
    jne fail

    ; Valid composition takes the minimum and binds lineage deterministically.
    call prepare_valid
    call evaluate
    test eax, eax
    jnz fail
    cmp qword [rel request + NEBOC_EFFECTIVE_QUALITY_OFFSET], 800000
    jne fail
    cmp qword [rel request + NEBOC_EFFECTIVE_CONFIDENCE_OFFSET], 700000
    jne fail
    cmp qword [rel request + NEBOC_PROVENANCE_FLAGS_OFFSET], 15
    jne fail
    cmp qword [rel request + neboc_quality_confidence_e_lineage_DIAGNOSTIC_OFFSET], 0
    jne fail
    cmp qword [rel request + neboc_quality_confidence_e_lineage_DECISION_OFFSET], neboc_quality_confidence_e_lineage_DECISION_PERMIT
    jne fail
    mov rax, [rel request + NEBOC_LINEAGE_HASH_OFFSET]
    test rax, rax
    jz fail
    mov [rel first_hash], rax
    call prepare_valid
    call evaluate
    mov rax, [rel first_hash]
    cmp [rel request + NEBOC_LINEAGE_HASH_OFFSET], rax
    jne fail

    ; Neither direct input can escalate inherited quality or confidence.
    call prepare_valid
    mov qword [rel request + NEBOC_DIRECT_QUALITY_OFFSET], 1000000
    mov qword [rel request + NEBOC_DIRECT_CONFIDENCE_OFFSET], 1000000
    call evaluate
    test eax, eax
    jnz fail
    cmp qword [rel request + NEBOC_EFFECTIVE_QUALITY_OFFSET], 800000
    jne fail
    cmp qword [rel request + NEBOC_EFFECTIVE_CONFIDENCE_OFFSET], 700000
    jne fail

    ; Malformed score domains and absent identities are exact TYPE failures.
    call prepare_valid
    mov qword [rel request + NEBOC_DIRECT_QUALITY_OFFSET], 1000001
    call evaluate
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel request + neboc_quality_confidence_e_lineage_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_TYPE_codegen_quality_x86_64
    jne fail
    cmp qword [rel request + neboc_quality_confidence_e_lineage_DECISION_OFFSET], 0
    jne fail
    call prepare_valid
    mov qword [rel request + NEBOC_SOURCE_ID_OFFSET], 0
    call evaluate
    cmp qword [rel request + neboc_quality_confidence_e_lineage_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_TYPE_codegen_quality_x86_64
    jne fail

    ; Threshold failure is fail-closed SECURITY, with no score escalation.
    call prepare_valid
    mov qword [rel request + NEBOC_MIN_CONFIDENCE_OFFSET], 700001
    call evaluate
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel request + neboc_quality_confidence_e_lineage_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_SECURITY_codegen_quality_x86_64
    jne fail
    cmp qword [rel request + neboc_quality_confidence_e_lineage_DECISION_OFFSET], 0
    jne fail

    ; A forged predecessor decision cannot bypass privacidade_dados_sensiveis_e_zero_trust re-evaluation.
    call prepare_valid
    mov qword [rel request + NEBOC_POLICY_DIRECT_EFFECTS_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    mov qword [rel request + NEBOC_PRIVACY_DECISION_OFFSET], NEBOC_PRIVACY_DECISION_PERMIT
    call evaluate
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel request + neboc_quality_confidence_e_lineage_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_SECURITY_codegen_quality_x86_64
    jne fail

    ; Different parent lineage produces a different deterministic identity.
    call prepare_valid
    call evaluate
    mov rax, [rel request + NEBOC_LINEAGE_HASH_OFFSET]
    mov [rel first_hash], rax
    call prepare_valid
    inc qword [rel request + NEBOC_PARENT_LINEAGE_HASH_OFFSET]
    call evaluate
    mov rax, [rel first_hash]
    cmp [rel request + NEBOC_LINEAGE_HASH_OFFSET], rax
    je fail

    xor edi, edi
    jmp neboc_host_process_exit
fail:
    mov edi, 1
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
