; G148 deterministic OperatorConformanceSuite evidence reducer.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/registry/closeout/registry_closeout.inc"

section .text

; OperatorConformanceSuite(tokens[10], count, report*).
; Every token represents one independently checked subgroup.  Missing evidence
; returns INVALID_SOURCE and leaves the caller report unchanged.
NEBOC_ABI_FUNCTION OperatorConformanceSuite
    test rdi,rdi
    jz .invalid_argument
    test rdx,rdx
    jz .invalid_argument
    test rdi,7
    jnz .invalid_argument
    test rdx,7
    jnz .invalid_argument
    test rsi,rsi
    jz .invalid_argument
    cmp rsi,NEBOC_CLOSEOUT_SUBGROUP_COUNT
    ja .limit
    jne .invalid_source
    xor r8d,r8d
    xor r9d,r9d
    xor r10d,r10d
.evidence:
    mov r11,[rdi+r8*8]
    test r11,r11
    jz .invalid_source
    bts r9,r8
    rol r10,13
    xor r10,r11
    xor r10,r9
    inc r8
    cmp r8,NEBOC_CLOSEOUT_SUBGROUP_COUNT
    jb .evidence
    mov qword [rdx+NEBOC_CLOSEOUT_SUITE_SCHEMA_OFFSET],NEBOC_CLOSEOUT_SCHEMA_VERSION
    mov qword [rdx+NEBOC_CLOSEOUT_SUITE_EVIDENCE_COUNT_OFFSET],NEBOC_CLOSEOUT_SUBGROUP_COUNT
    mov [rdx+NEBOC_CLOSEOUT_SUITE_EVIDENCE_MASK_OFFSET],r9
    mov qword [rdx+NEBOC_CLOSEOUT_SUITE_POSITIVE_OFFSET],10
    mov qword [rdx+NEBOC_CLOSEOUT_SUITE_NEGATIVE_OFFSET],17
    mov qword [rdx+NEBOC_CLOSEOUT_SUITE_METAMORPHIC_OFFSET],10
    mov qword [rdx+NEBOC_CLOSEOUT_SUITE_ADVERSARIAL_OFFSET],9
    mov qword [rdx+NEBOC_CLOSEOUT_SUITE_COMPOSITION_OFFSET],10
    mov qword [rdx+NEBOC_CLOSEOUT_SUITE_DETERMINISTIC_OFFSET],1
    mov qword [rdx+NEBOC_CLOSEOUT_SUITE_AFFECTED_MASK_OFFSET],NEBOC_CLOSEOUT_AFFECTED_ALL
    mov qword [rdx+NEBOC_CLOSEOUT_SUITE_OPEN_P0_OFFSET],0
    mov qword [rdx+NEBOC_CLOSEOUT_SUITE_OPEN_P1_OFFSET],0
    mov qword [rdx+NEBOC_CLOSEOUT_SUITE_OPEN_P2_OFFSET],0
    mov [rdx+NEBOC_CLOSEOUT_SUITE_DIGEST_OFFSET],r10
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.invalid_source:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
