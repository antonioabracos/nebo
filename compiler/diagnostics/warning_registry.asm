; C04-F01 canonical Warning metadata registry.  No warning occurrence is
; synthesized here and policy never changes program semantics.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/registry.inc"
%include "compiler/diagnostics/warning_policy.inc"
%include "compiler/diagnostics/explain.inc"
%include "compiler/diagnostics/warning_registry.inc"

extern neboc_diagnostic_code_registry_lookup

section .rodata
warning_w0001_id: db "NEBO-W0001"
warning_w0001_id_len equ $-warning_w0001_id
warning_w0001_owner: db "warning_policy"
warning_w0001_owner_len equ $-warning_w0001_owner
warning_w0001_explanation: db "diagnostic.compatibility.warning"
warning_w0001_explanation_len equ $-warning_w0001_explanation

align 8
warning_registry:
 dq warning_w0001_id,warning_w0001_id_len
 dq NEBOC_WARNING_GROUP_PORTABILITY
 dq NEBOC_WARNING_LEVEL_WARN
 dq NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 dq warning_w0001_owner,warning_w0001_owner_len
 dq warning_w0001_explanation,warning_w0001_explanation_len
 dq NEBOC_WARNING_PRIMARY_SPAN_REQUIRED
 dq NEBOC_WARNING_RELATED_INFO_OPTIONAL_BOUNDED
 dq NEBOC_FIXIT_MANUAL_ONLY
 dq NEBOC_WARNING_MATURITY_STABLE
 dq NEBOC_WARNING_REGISTRY_SCHEMA_V1
 dq 0

section .text

; warning_registry_lookup(id*, id_len, out_entry*)
NEBOC_ABI_FUNCTION neboc_warning_registry_lookup
 test rdi,rdi
 jz .lookup_invalid
 test rsi,rsi
 jz .lookup_invalid
 test rdx,rdx
 jz .lookup_invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 lea rbx,[rel warning_registry]
 xor r15d,r15d
.lookup_entry:
 cmp r15d,NEBOC_WARNING_REGISTRY_COUNT
 jae .lookup_not_found
 cmp qword [rbx+NEBOC_WARNING_ENTRY_ID_LENGTH_OFFSET],r13
 jne .lookup_next
 mov rdi,[rbx+NEBOC_WARNING_ENTRY_ID_OFFSET]
 xor ecx,ecx
.lookup_compare:
 cmp rcx,r13
 jae .lookup_found
 mov al,[r12+rcx]
 cmp al,[rdi+rcx]
 jne .lookup_next
 inc rcx
 jmp .lookup_compare
.lookup_next:
 add rbx,NEBOC_WARNING_ENTRY_SIZE
 inc r15d
 jmp .lookup_entry
.lookup_found:
 mov rdi,r14
 mov rsi,rbx
 mov ecx,NEBOC_WARNING_ENTRY_SIZE/8
 rep movsq
 xor eax,eax
 jmp .lookup_finish
.lookup_not_found:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.lookup_finish:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.lookup_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; warning_registry_count()
NEBOC_ABI_FUNCTION neboc_warning_registry_count
 mov eax,NEBOC_WARNING_REGISTRY_COUNT
 ret

; Validate descriptor completeness and its exact diagnostic-registry owner.
NEBOC_ABI_FUNCTION neboc_warning_registry_validate
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,NEBOC_DIAGNOSTIC_CODE_ENTRY_SIZE
 lea rbx,[rel warning_registry]
 xor r12d,r12d
.validate_entry:
 cmp r12d,NEBOC_WARNING_REGISTRY_COUNT
 jae .validate_ok
 mov rdi,[rbx+NEBOC_WARNING_ENTRY_ID_OFFSET]
 mov rsi,[rbx+NEBOC_WARNING_ENTRY_ID_LENGTH_OFFSET]
 test rdi,rdi
 jz .validate_invalid
 cmp rsi,10
 jne .validate_invalid
 cmp dword [rdi],"NEBO"
 jne .validate_invalid
 cmp word [rdi+4],"-W"
 jne .validate_invalid
 cmp byte [rdi+6],'0'
 jb .validate_invalid
 cmp byte [rdi+6],'9'
 ja .validate_invalid
 cmp byte [rdi+7],'0'
 jb .validate_invalid
 cmp byte [rdi+7],'9'
 ja .validate_invalid
 cmp byte [rdi+8],'0'
 jb .validate_invalid
 cmp byte [rdi+8],'9'
 ja .validate_invalid
 cmp byte [rdi+9],'0'
 jb .validate_invalid
 cmp byte [rdi+9],'9'
 ja .validate_invalid
 cmp qword [rbx+NEBOC_WARNING_ENTRY_GROUP_OFFSET],NEBOC_WARNING_GROUP_UNUSED
 jb .validate_invalid
 cmp qword [rbx+NEBOC_WARNING_ENTRY_GROUP_OFFSET],NEBOC_WARNING_GROUP_EXPERIMENTAL
 ja .validate_invalid
 cmp qword [rbx+NEBOC_WARNING_ENTRY_DEFAULT_LEVEL_OFFSET],NEBOC_WARNING_LEVEL_ALLOW
 jb .validate_invalid
 cmp qword [rbx+NEBOC_WARNING_ENTRY_DEFAULT_LEVEL_OFFSET],NEBOC_WARNING_LEVEL_FORBID
 ja .validate_invalid
 cmp qword [rbx+NEBOC_WARNING_ENTRY_SEVERITY_OFFSET],NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 jne .validate_invalid
 cmp qword [rbx+NEBOC_WARNING_ENTRY_OWNER_OFFSET],0
 je .validate_invalid
 cmp qword [rbx+NEBOC_WARNING_ENTRY_OWNER_LENGTH_OFFSET],0
 je .validate_invalid
 cmp qword [rbx+NEBOC_WARNING_ENTRY_EXPLANATION_OFFSET],0
 je .validate_invalid
 cmp qword [rbx+NEBOC_WARNING_ENTRY_EXPLANATION_LENGTH_OFFSET],0
 je .validate_invalid
 mov rax,[rbx+NEBOC_WARNING_ENTRY_PRIMARY_SPAN_POLICY_OFFSET]
 cmp rax,NEBOC_WARNING_PRIMARY_SPAN_REQUIRED
 jb .validate_invalid
 cmp rax,NEBOC_WARNING_PRIMARY_SPAN_GLOBAL_ONLY
 ja .validate_invalid
 mov rax,[rbx+NEBOC_WARNING_ENTRY_RELATED_INFO_POLICY_OFFSET]
 cmp rax,NEBOC_WARNING_RELATED_INFO_NONE
 jb .validate_invalid
 cmp rax,NEBOC_WARNING_RELATED_INFO_REQUIRED
 ja .validate_invalid
 mov rax,[rbx+NEBOC_WARNING_ENTRY_FIXIT_APPLICABILITY_OFFSET]
 cmp rax,NEBOC_FIXIT_MACHINE_APPLICABLE
 jb .validate_invalid
 cmp rax,NEBOC_FIXIT_MANUAL_ONLY
 ja .validate_invalid
 mov rax,[rbx+NEBOC_WARNING_ENTRY_MATURITY_OFFSET]
 cmp rax,NEBOC_WARNING_MATURITY_EXPERIMENTAL
 jb .validate_invalid
 cmp rax,NEBOC_WARNING_MATURITY_DEPRECATED
 ja .validate_invalid
 cmp qword [rbx+NEBOC_WARNING_ENTRY_SCHEMA_OFFSET],NEBOC_WARNING_REGISTRY_SCHEMA_V1
 jne .validate_invalid
 cmp qword [rbx+NEBOC_WARNING_ENTRY_RESERVED_OFFSET],0
 jne .validate_invalid
 mov rdi,[rbx+NEBOC_WARNING_ENTRY_ID_OFFSET]
 mov rsi,[rbx+NEBOC_WARNING_ENTRY_ID_LENGTH_OFFSET]
 lea rdx,[rsp]
 call neboc_diagnostic_code_registry_lookup
 test eax,eax
 jne .validate_finish
 cmp qword [rsp+NEBOC_DIAGNOSTIC_CODE_ENTRY_SEVERITY_OFFSET],NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 jne .validate_invalid
 inc r12d
 add rbx,NEBOC_WARNING_ENTRY_SIZE
 jmp .validate_entry
.validate_ok:
 xor eax,eax
 jmp .validate_finish
.validate_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.validate_finish:
 add rsp,NEBOC_DIAGNOSTIC_CODE_ENTRY_SIZE
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
