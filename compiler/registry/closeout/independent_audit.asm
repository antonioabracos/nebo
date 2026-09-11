; G148 independent read-only audit over already materialized evidence reports.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/registry/closeout/registry_closeout.inc"

section .text

; runIndependentOperatorAudit(coverage*, suite*, examples*, audit*).
; The three inputs are immutable.  No auto-remediation path exists.
NEBOC_ABI_FUNCTION runIndependentOperatorAudit
    test rdi,rdi
    jz .invalid_argument
    test rsi,rsi
    jz .invalid_argument
    test rdx,rdx
    jz .invalid_argument
    test rcx,rcx
    jz .invalid_argument
    mov rax,rdi
    or rax,rsi
    or rax,rdx
    or rax,rcx
    test rax,7
    jnz .invalid_argument
    cmp rcx,rdi
    je .invalid_argument
    cmp rcx,rsi
    je .invalid_argument
    cmp rcx,rdx
    je .invalid_argument
    cmp qword [rdi+NEBOC_CLOSEOUT_COVERAGE_SCHEMA_OFFSET],NEBOC_CLOSEOUT_SCHEMA_VERSION
    jne .invalid_source
    cmp qword [rdi+NEBOC_CLOSEOUT_COVERAGE_TOTAL_OFFSET],NEBOC_CLOSEOUT_ENTRY_COUNT
    jne .invalid_source
    cmp qword [rdi+NEBOC_CLOSEOUT_COVERAGE_CORE_OFFSET],NEBOC_CLOSEOUT_CORE_COUNT
    jne .invalid_source
    cmp qword [rdi+NEBOC_CLOSEOUT_COVERAGE_UNICODE_OFFSET],NEBOC_CLOSEOUT_UNICODE_COUNT
    jne .invalid_source
    cmp qword [rdi+NEBOC_CLOSEOUT_COVERAGE_DOMAIN_OFFSET],NEBOC_CLOSEOUT_DOMAIN_COUNT
    jne .invalid_source
    cmp qword [rdi+NEBOC_CLOSEOUT_COVERAGE_RESERVED_OFFSET],NEBOC_CLOSEOUT_RESERVED_COUNT
    jne .invalid_source
    cmp qword [rdi+NEBOC_CLOSEOUT_COVERAGE_REJECTED_OFFSET],NEBOC_CLOSEOUT_REJECTED_COUNT
    jne .invalid_source
    cmp qword [rdi+NEBOC_CLOSEOUT_COVERAGE_GAPS_OFFSET],0
    jne .invalid_source
    cmp qword [rdi+NEBOC_CLOSEOUT_COVERAGE_DUPLICATES_OFFSET],0
    jne .invalid_source
    cmp qword [rdi+NEBOC_CLOSEOUT_COVERAGE_GROUP_ACTIVATIONS_OFFSET],0
    jne .invalid_source
    cmp qword [rsi+NEBOC_CLOSEOUT_SUITE_SCHEMA_OFFSET],NEBOC_CLOSEOUT_SCHEMA_VERSION
    jne .invalid_source
    cmp qword [rsi+NEBOC_CLOSEOUT_SUITE_EVIDENCE_COUNT_OFFSET],NEBOC_CLOSEOUT_SUBGROUP_COUNT
    jne .invalid_source
    cmp qword [rsi+NEBOC_CLOSEOUT_SUITE_EVIDENCE_MASK_OFFSET],0x3ff
    jne .invalid_source
    cmp qword [rsi+NEBOC_CLOSEOUT_SUITE_POSITIVE_OFFSET],10
    jne .invalid_source
    cmp qword [rsi+NEBOC_CLOSEOUT_SUITE_NEGATIVE_OFFSET],17
    jne .invalid_source
    cmp qword [rsi+NEBOC_CLOSEOUT_SUITE_METAMORPHIC_OFFSET],10
    jne .invalid_source
    cmp qword [rsi+NEBOC_CLOSEOUT_SUITE_ADVERSARIAL_OFFSET],9
    jne .invalid_source
    cmp qword [rsi+NEBOC_CLOSEOUT_SUITE_COMPOSITION_OFFSET],10
    jne .invalid_source
    cmp qword [rsi+NEBOC_CLOSEOUT_SUITE_DETERMINISTIC_OFFSET],1
    jne .invalid_source
    cmp qword [rsi+NEBOC_CLOSEOUT_SUITE_AFFECTED_MASK_OFFSET],NEBOC_CLOSEOUT_AFFECTED_ALL
    jne .invalid_source
    cmp qword [rsi+NEBOC_CLOSEOUT_SUITE_OPEN_P0_OFFSET],0
    jne .invalid_source
    cmp qword [rsi+NEBOC_CLOSEOUT_SUITE_OPEN_P1_OFFSET],0
    jne .invalid_source
    cmp qword [rsi+NEBOC_CLOSEOUT_SUITE_OPEN_P2_OFFSET],0
    jne .invalid_source
    cmp qword [rdx+NEBOC_CLOSEOUT_EXAMPLES_SCHEMA_OFFSET],NEBOC_CLOSEOUT_SCHEMA_VERSION
    jne .invalid_source
    cmp qword [rdx+NEBOC_CLOSEOUT_EXAMPLES_COUNT_OFFSET],NEBOC_CLOSEOUT_SUBGROUP_COUNT
    jne .invalid_source
    cmp qword [rdx+NEBOC_CLOSEOUT_EXAMPLES_UNIQUE_OFFSET],NEBOC_CLOSEOUT_SUBGROUP_COUNT
    jne .invalid_source
    cmp qword [rdx+NEBOC_CLOSEOUT_EXAMPLES_DIGEST_OFFSET],0
    je .invalid_source
    mov r8,[rdi+NEBOC_CLOSEOUT_COVERAGE_DIGEST_OFFSET]
    rol r8,7
    xor r8,[rsi+NEBOC_CLOSEOUT_SUITE_DIGEST_OFFSET]
    rol r8,11
    xor r8,[rdx+NEBOC_CLOSEOUT_EXAMPLES_DIGEST_OFFSET]
    xor r8,0x148a11d1
    mov qword [rcx+NEBOC_CLOSEOUT_AUDIT_SCHEMA_OFFSET],NEBOC_CLOSEOUT_SCHEMA_VERSION
    mov qword [rcx+NEBOC_CLOSEOUT_AUDIT_ENTRIES_OFFSET],NEBOC_CLOSEOUT_ENTRY_COUNT
    mov qword [rcx+NEBOC_CLOSEOUT_AUDIT_SUBGROUPS_OFFSET],NEBOC_CLOSEOUT_SUBGROUP_COUNT
    mov qword [rcx+NEBOC_CLOSEOUT_AUDIT_SURFACES_OFFSET],NEBOC_CLOSEOUT_SURFACE_COUNT
    mov qword [rcx+NEBOC_CLOSEOUT_AUDIT_EXAMPLES_OFFSET],NEBOC_CLOSEOUT_SUBGROUP_COUNT
    mov qword [rcx+NEBOC_CLOSEOUT_AUDIT_OPEN_P0_OFFSET],0
    mov qword [rcx+NEBOC_CLOSEOUT_AUDIT_OPEN_P1_OFFSET],0
    mov qword [rcx+NEBOC_CLOSEOUT_AUDIT_OPEN_P2_OFFSET],0
    mov qword [rcx+NEBOC_CLOSEOUT_AUDIT_GROUP_ACTIVATIONS_OFFSET],0
    mov qword [rcx+NEBOC_CLOSEOUT_AUDIT_REMEDIATIONS_OFFSET],0
    mov qword [rcx+NEBOC_CLOSEOUT_AUDIT_MATURITY_OFFSET],NEBOC_CLOSEOUT_MATURITY_ALL_LOCAL
    mov [rcx+NEBOC_CLOSEOUT_AUDIT_DIGEST_OFFSET],r8
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid_source:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
