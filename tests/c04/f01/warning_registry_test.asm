bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/warning_policy.inc"
%include "compiler/diagnostics/explain.inc"
%include "compiler/diagnostics/warning_registry.inc"

global _start
extern neboc_warning_registry_lookup
extern neboc_warning_registry_count
extern neboc_warning_registry_validate
extern neboc_host_process_exit

section .rodata
warning_id: db "NEBO-W0001"
warning_id_len equ $-warning_id
unknown_id: db "NEBO-W9999"
owner: db "warning_policy"
owner_len equ $-owner
explanation: db "diagnostic.compatibility.warning"
explanation_len equ $-explanation

section .bss
entry: resb NEBOC_WARNING_ENTRY_SIZE

section .text
_start:
 call neboc_warning_registry_count
 cmp eax,NEBOC_WARNING_REGISTRY_COUNT
 jne .fail1
 call neboc_warning_registry_validate
 test eax,eax
 jne .fail2
 lea rdi,[rel warning_id]
 mov esi,warning_id_len
 lea rdx,[rel entry]
 call neboc_warning_registry_lookup
 test eax,eax
 jne .fail3
 cmp qword [rel entry+NEBOC_WARNING_ENTRY_ID_LENGTH_OFFSET],warning_id_len
 jne .fail4
 cmp qword [rel entry+NEBOC_WARNING_ENTRY_GROUP_OFFSET],NEBOC_WARNING_GROUP_PORTABILITY
 jne .fail5
 cmp qword [rel entry+NEBOC_WARNING_ENTRY_DEFAULT_LEVEL_OFFSET],NEBOC_WARNING_LEVEL_WARN
 jne .fail6
 cmp qword [rel entry+NEBOC_WARNING_ENTRY_SEVERITY_OFFSET],NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 jne .fail7
 cmp qword [rel entry+NEBOC_WARNING_ENTRY_OWNER_LENGTH_OFFSET],owner_len
 jne .fail8
 cmp qword [rel entry+NEBOC_WARNING_ENTRY_EXPLANATION_LENGTH_OFFSET],explanation_len
 jne .fail9
 cmp qword [rel entry+NEBOC_WARNING_ENTRY_PRIMARY_SPAN_POLICY_OFFSET],NEBOC_WARNING_PRIMARY_SPAN_REQUIRED
 jne .fail10
 cmp qword [rel entry+NEBOC_WARNING_ENTRY_RELATED_INFO_POLICY_OFFSET],NEBOC_WARNING_RELATED_INFO_OPTIONAL_BOUNDED
 jne .fail11
 cmp qword [rel entry+NEBOC_WARNING_ENTRY_FIXIT_APPLICABILITY_OFFSET],NEBOC_FIXIT_MANUAL_ONLY
 jne .fail12
 cmp qword [rel entry+NEBOC_WARNING_ENTRY_MATURITY_OFFSET],NEBOC_WARNING_MATURITY_STABLE
 jne .fail13
 cmp qword [rel entry+NEBOC_WARNING_ENTRY_SCHEMA_OFFSET],NEBOC_WARNING_REGISTRY_SCHEMA_V1
 jne .fail14
 cmp qword [rel entry+NEBOC_WARNING_ENTRY_RESERVED_OFFSET],0
 jne .fail15
 mov rdi,[rel entry+NEBOC_WARNING_ENTRY_OWNER_OFFSET]
 lea rsi,[rel owner]
 mov ecx,owner_len
 repe cmpsb
 jne .fail16
 mov rdi,[rel entry+NEBOC_WARNING_ENTRY_EXPLANATION_OFFSET]
 lea rsi,[rel explanation]
 mov ecx,explanation_len
 repe cmpsb
 jne .fail17
 lea rdi,[rel unknown_id]
 mov esi,warning_id_len
 lea rdx,[rel entry]
 call neboc_warning_registry_lookup
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail18
 xor edi,edi
 call neboc_host_process_exit

%assign n 1
%rep 18
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits
