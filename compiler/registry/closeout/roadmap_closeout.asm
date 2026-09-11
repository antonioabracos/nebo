; G148 terminal RF148 gate materialization.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/registry/closeout/registry_closeout.inc"

section .text

; RoadmapCloseoutReport(audit*, closeout*).
NEBOC_ABI_FUNCTION RoadmapCloseoutReport
    test rdi,rdi
    jz .invalid_argument
    test rsi,rsi
    jz .invalid_argument
    mov rax,rdi
    or rax,rsi
    test rax,7
    jnz .invalid_argument
    cmp rdi,rsi
    je .invalid_argument
    cmp qword [rdi+NEBOC_CLOSEOUT_AUDIT_SCHEMA_OFFSET],NEBOC_CLOSEOUT_SCHEMA_VERSION
    jne .invalid_source
    cmp qword [rdi+NEBOC_CLOSEOUT_AUDIT_ENTRIES_OFFSET],NEBOC_CLOSEOUT_ENTRY_COUNT
    jne .invalid_source
    cmp qword [rdi+NEBOC_CLOSEOUT_AUDIT_SUBGROUPS_OFFSET],NEBOC_CLOSEOUT_SUBGROUP_COUNT
    jne .invalid_source
    cmp qword [rdi+NEBOC_CLOSEOUT_AUDIT_SURFACES_OFFSET],NEBOC_CLOSEOUT_SURFACE_COUNT
    jne .invalid_source
    cmp qword [rdi+NEBOC_CLOSEOUT_AUDIT_EXAMPLES_OFFSET],NEBOC_CLOSEOUT_SUBGROUP_COUNT
    jne .invalid_source
    cmp qword [rdi+NEBOC_CLOSEOUT_AUDIT_OPEN_P0_OFFSET],0
    jne .invalid_source
    cmp qword [rdi+NEBOC_CLOSEOUT_AUDIT_OPEN_P1_OFFSET],0
    jne .invalid_source
    cmp qword [rdi+NEBOC_CLOSEOUT_AUDIT_OPEN_P2_OFFSET],0
    jne .invalid_source
    cmp qword [rdi+NEBOC_CLOSEOUT_AUDIT_GROUP_ACTIVATIONS_OFFSET],0
    jne .invalid_source
    cmp qword [rdi+NEBOC_CLOSEOUT_AUDIT_REMEDIATIONS_OFFSET],0
    jne .invalid_source
    cmp qword [rdi+NEBOC_CLOSEOUT_AUDIT_MATURITY_OFFSET],NEBOC_CLOSEOUT_MATURITY_ALL_LOCAL
    jne .invalid_source
    mov r8,[rdi+NEBOC_CLOSEOUT_AUDIT_DIGEST_OFFSET]
    rol r8,17
    xor r8,NEBOC_CLOSEOUT_ENTRY_COUNT
    mov rax,NEBOC_CLOSEOUT_SUBGROUP_COUNT
    shl rax,16
    xor r8,rax
    xor r8,NEBOC_CLOSEOUT_SURFACE_COUNT
    xor r8,NEBOC_CLOSEOUT_MATURITY_ALL_LOCAL
    mov qword [rsi+NEBOC_CLOSEOUT_ROADMAP_SCHEMA_OFFSET],NEBOC_CLOSEOUT_SCHEMA_VERSION
    mov qword [rsi+NEBOC_CLOSEOUT_ROADMAP_GATE_OFFSET],NEBOC_CLOSEOUT_GATE_RF148
    mov qword [rsi+NEBOC_CLOSEOUT_ROADMAP_PHASE_OFFSET],NEBOC_CLOSEOUT_PHASE_P07
    mov qword [rsi+NEBOC_CLOSEOUT_ROADMAP_ENTRIES_OFFSET],NEBOC_CLOSEOUT_ENTRY_COUNT
    mov qword [rsi+NEBOC_CLOSEOUT_ROADMAP_SUBGROUPS_OFFSET],NEBOC_CLOSEOUT_SUBGROUP_COUNT
    mov qword [rsi+NEBOC_CLOSEOUT_ROADMAP_SURFACES_OFFSET],NEBOC_CLOSEOUT_SURFACE_COUNT
    mov qword [rsi+NEBOC_CLOSEOUT_ROADMAP_MATURITY_OFFSET],NEBOC_CLOSEOUT_MATURITY_ALL_LOCAL
    mov qword [rsi+NEBOC_CLOSEOUT_ROADMAP_OPEN_P0_OFFSET],0
    mov qword [rsi+NEBOC_CLOSEOUT_ROADMAP_OPEN_P1_OFFSET],0
    mov qword [rsi+NEBOC_CLOSEOUT_ROADMAP_OPEN_P2_OFFSET],0
    mov qword [rsi+NEBOC_CLOSEOUT_ROADMAP_NEXT_GROUP_OFFSET],NEBOC_CLOSEOUT_NEXT_GROUP_G149
    mov qword [rsi+NEBOC_CLOSEOUT_ROADMAP_NEXT_STARTED_OFFSET],0
    mov [rsi+NEBOC_CLOSEOUT_ROADMAP_DIGEST_OFFSET],r8
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid_source:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
