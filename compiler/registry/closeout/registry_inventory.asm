; G148 canonical 185-row inventory and exact coverage verification.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/operator_registry.inc"
%include "compiler/registry/closeout/registry_closeout.inc"

section .rodata align=16
registry_closeout_inventory:
%assign logical 1
%rep NEBOC_CLOSEOUT_CORE_COUNT
    dq logical,logical,NEBOC_OPERATOR_CLASS_CORE_ALWAYS_ON,NEBOC_CLOSEOUT_POLICY_PORTABLE
%assign logical logical+1
%endrep
%rep NEBOC_CLOSEOUT_UNICODE_COUNT
    dq logical,logical,NEBOC_OPERATOR_CLASS_UNICODE_ALIAS,NEBOC_CLOSEOUT_POLICY_EXACT_ALIAS
%assign logical logical+1
%endrep
%assign domain_id 1
%rep NEBOC_CLOSEOUT_DOMAIN_COUNT
    dq logical,0x0000000100000000+domain_id,NEBOC_OPERATOR_CLASS_DOMAIN_GATED,NEBOC_CLOSEOUT_POLICY_DOMAIN_GATE
%assign logical logical+1
%assign domain_id domain_id+1
%endrep
%rep NEBOC_CLOSEOUT_RESERVED_COUNT
    dq logical,logical,NEBOC_OPERATOR_CLASS_RESERVED,NEBOC_CLOSEOUT_POLICY_NONEXECUTABLE
%assign logical logical+1
%endrep
%rep NEBOC_CLOSEOUT_REJECTED_COUNT
    dq logical,logical,NEBOC_OPERATOR_CLASS_REJECTED,NEBOC_CLOSEOUT_POLICY_NONEXECUTABLE
%assign logical logical+1
%endrep
registry_closeout_inventory_end:

%if (registry_closeout_inventory_end-registry_closeout_inventory) != (NEBOC_CLOSEOUT_ENTRY_COUNT*NEBOC_CLOSEOUT_ROW_SIZE)
%error "G148 inventory size does not equal 185 rows"
%endif

section .text

; Return RAX=immutable table, RDX=row count, RCX=schema version.
NEBOC_ABI_FUNCTION nebo_registry_closeout_inventory
    lea rax,[rel registry_closeout_inventory]
    mov edx,NEBOC_CLOSEOUT_ENTRY_COUNT
    mov ecx,NEBOC_CLOSEOUT_SCHEMA_VERSION
    ret

; verifyRegistryCoverage(rows*, count, report*).
; A row must have its exact logical ordinal, stable Registry identity, class
; and policy.  The report is published only after all 185 rows validate.
NEBOC_ABI_FUNCTION verifyRegistryCoverage
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
    cmp rsi,NEBOC_CLOSEOUT_ENTRY_COUNT
    ja .limit
    jne .invalid_source
    xor r8d,r8d
    mov r9d,1
.row:
    cmp [rdi+NEBOC_CLOSEOUT_ROW_LOGICAL_OFFSET],r9
    jne .invalid_source
    mov r10,r9
    cmp r9,56
    jbe .id_ready
    cmp r9,136
    ja .id_ready
    mov r10,r9
    sub r10,56
    bts r10,32
.id_ready:
    cmp [rdi+NEBOC_CLOSEOUT_ROW_REGISTRY_ID_OFFSET],r10
    jne .invalid_source
    mov r11d,NEBOC_OPERATOR_CLASS_CORE_ALWAYS_ON
    cmp r9,47
    jbe .class_ready
    mov r11d,NEBOC_OPERATOR_CLASS_UNICODE_ALIAS
    cmp r9,56
    jbe .class_ready
    mov r11d,NEBOC_OPERATOR_CLASS_DOMAIN_GATED
    cmp r9,136
    jbe .class_ready
    mov r11d,NEBOC_OPERATOR_CLASS_RESERVED
    cmp r9,159
    jbe .class_ready
    mov r11d,NEBOC_OPERATOR_CLASS_REJECTED
.class_ready:
    cmp [rdi+NEBOC_CLOSEOUT_ROW_CLASS_OFFSET],r11
    jne .invalid_source
    mov eax,NEBOC_CLOSEOUT_POLICY_PORTABLE
    cmp r11,NEBOC_OPERATOR_CLASS_CORE_ALWAYS_ON
    je .policy_ready
    mov eax,NEBOC_CLOSEOUT_POLICY_EXACT_ALIAS
    cmp r11,NEBOC_OPERATOR_CLASS_UNICODE_ALIAS
    je .policy_ready
    mov eax,NEBOC_CLOSEOUT_POLICY_DOMAIN_GATE
    cmp r11,NEBOC_OPERATOR_CLASS_DOMAIN_GATED
    je .policy_ready
    mov eax,NEBOC_CLOSEOUT_POLICY_NONEXECUTABLE
.policy_ready:
    cmp [rdi+NEBOC_CLOSEOUT_ROW_POLICY_OFFSET],rax
    jne .invalid_source
    rol r8,7
    xor r8,r9
    rol r8,11
    xor r8,r10
    rol r8,13
    xor r8,r11
    rol r8,17
    xor r8,rax
    add rdi,NEBOC_CLOSEOUT_ROW_SIZE
    inc r9
    cmp r9,NEBOC_CLOSEOUT_ENTRY_COUNT+1
    jb .row
    mov qword [rdx+NEBOC_CLOSEOUT_COVERAGE_SCHEMA_OFFSET],NEBOC_CLOSEOUT_SCHEMA_VERSION
    mov qword [rdx+NEBOC_CLOSEOUT_COVERAGE_TOTAL_OFFSET],NEBOC_CLOSEOUT_ENTRY_COUNT
    mov qword [rdx+NEBOC_CLOSEOUT_COVERAGE_CORE_OFFSET],NEBOC_CLOSEOUT_CORE_COUNT
    mov qword [rdx+NEBOC_CLOSEOUT_COVERAGE_UNICODE_OFFSET],NEBOC_CLOSEOUT_UNICODE_COUNT
    mov qword [rdx+NEBOC_CLOSEOUT_COVERAGE_DOMAIN_OFFSET],NEBOC_CLOSEOUT_DOMAIN_COUNT
    mov qword [rdx+NEBOC_CLOSEOUT_COVERAGE_RESERVED_OFFSET],NEBOC_CLOSEOUT_RESERVED_COUNT
    mov qword [rdx+NEBOC_CLOSEOUT_COVERAGE_REJECTED_OFFSET],NEBOC_CLOSEOUT_REJECTED_COUNT
    mov qword [rdx+NEBOC_CLOSEOUT_COVERAGE_GAPS_OFFSET],0
    mov qword [rdx+NEBOC_CLOSEOUT_COVERAGE_DUPLICATES_OFFSET],0
    mov qword [rdx+NEBOC_CLOSEOUT_COVERAGE_GROUP_ACTIVATIONS_OFFSET],0
    mov [rdx+NEBOC_CLOSEOUT_COVERAGE_DIGEST_OFFSET],r8
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.invalid_source:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
