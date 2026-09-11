bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/warning_policy.inc"
%include "compiler/diagnostics/warning_registry.inc"
%include "compiler/diagnostics/renderer.inc"
%include "compiler/diagnostics/explain.inc"
%include "compiler/diagnostics/warning_guidance.inc"
%include "compiler/source/source_map.inc"

global _start
extern neboc_diagnostic_new
extern neboc_warning_policy_new
extern neboc_warning_policy_set
extern neboc_warning_policy_explain
extern neboc_warning_suppression_record
extern neboc_warning_explanation_load
extern neboc_warning_fixit_preview
extern neboc_source_map_new
extern neboc_source_map_add_file
extern neboc_fix_it_new
extern neboc_fix_it_add_edit
extern neboc_host_process_exit

section .rodata
code: db "NEBO-W0001"
code_len equ $-code
message_key: db "diagnostic.compatibility.warning"
message_key_len equ $-message_key
reason: db "reviewed portability boundary"
reason_len equ $-reason
blank_reason: db "   "
blank_reason_len equ $-blank_reason
path: db "src/main.no"
path_len equ $-path
source: db "let value = 1",10
source_len equ $-source
description: db "replace the literal"
description_len equ $-description
replacement: db "2"
replacement_len equ $-replacement

section .data
primary_span: dq 1,12,13,source_len
warning_request:
 dq code,code_len
 dq NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 dq NEBOC_DIAGNOSTIC_CATEGORY_TOOLING
 dq NEBOC_DIAGNOSTIC_PHASE_TOOLCHAIN
 dq message_key,message_key_len
 dq primary_span,0,0
source_request: dq path,path_len,source,source_len,0xc04f08
edit_span: dq 1,12,13,source_len,0xc04f08,1

section .bss align=16
warning: resb NEBOC_DIAGNOSTIC_SIZE
policy: resb NEBOC_WARNING_POLICY_SIZE
forbid_policy: resb NEBOC_WARNING_POLICY_SIZE
rules: resb NEBOC_WARNING_RULE_SIZE*2
forbid_rules: resb NEBOC_WARNING_RULE_SIZE*2
policy_explanation: resb NEBOC_WARNING_EXPLANATION_SIZE
forbid_explanation: resb NEBOC_WARNING_EXPLANATION_SIZE
suppression: resb NEBOC_WARNING_SUPPRESSION_SIZE
offline_explanation: resb NEBOC_EXPLANATION_SIZE
source_map: resb NEBOC_SOURCE_MAP_SIZE
source_entries: resb NEBOC_SOURCE_ENTRY_SIZE
file_id: resq 1
fix_manual: resb NEBOC_FIXIT_SIZE
fix_machine: resb NEBOC_FIXIT_SIZE
manual_edits: resb NEBOC_FIXIT_EDIT_SIZE
machine_edits: resb NEBOC_FIXIT_EDIT_SIZE
writer: resb NEBOC_WRITER_SIZE
output: resb 4096

section .text
_start:
 lea rdi,[rel warning]
 lea rsi,[rel warning_request]
 call neboc_diagnostic_new
 test eax,eax
 jne .fail1

 ; Explicit allow plus nonblank rationale yields an auditable record.
 lea rdi,[rel policy]
 lea rsi,[rel rules]
 mov edx,2
 mov ecx,NEBOC_WARNING_LEVEL_WARN
 call neboc_warning_policy_new
 test eax,eax
 jne .fail2
 lea rdi,[rel policy]
 lea rsi,[rel code]
 mov edx,code_len
 mov ecx,NEBOC_WARNING_LEVEL_ALLOW
 call neboc_warning_policy_set
 test eax,eax
 jne .fail3
 lea rdi,[rel policy]
 lea rsi,[rel warning]
 xor edx,edx
 lea rcx,[rel policy_explanation]
 call neboc_warning_policy_explain
 test eax,eax
 jne .fail4
 lea rdi,[rel suppression]
 lea rsi,[rel warning]
 lea rdx,[rel policy_explanation]
 lea rcx,[rel reason]
 mov r8d,reason_len
 mov r9d,0xc04f0801
 call neboc_warning_suppression_record
 test eax,eax
 jne .fail5
 cmp qword [rel suppression+NEBOC_WARNING_SUPPRESSION_ACTIVE_OFFSET],1
 jne .fail6
 cmp qword [rel suppression+NEBOC_WARNING_SUPPRESSION_SOURCE_OFFSET],NEBOC_WARNING_SOURCE_POLICY
 jne .fail7
 mov eax,0xc04f0801
 cmp [rel suppression+NEBOC_WARNING_SUPPRESSION_IDENTITY_DIGEST_OFFSET],rax
 jne .fail8

 ; Blank reasons and non-allow policies fail closed.
 lea rdi,[rel suppression]
 lea rsi,[rel warning]
 lea rdx,[rel policy_explanation]
 lea rcx,[rel blank_reason]
 mov r8d,blank_reason_len
 mov r9d,0xc04f0801
 call neboc_warning_suppression_record
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail9
 lea rdi,[rel forbid_policy]
 lea rsi,[rel forbid_rules]
 mov edx,2
 mov ecx,NEBOC_WARNING_LEVEL_WARN
 call neboc_warning_policy_new
 test eax,eax
 jne .fail10
 lea rdi,[rel forbid_policy]
 lea rsi,[rel code]
 mov edx,code_len
 mov ecx,NEBOC_WARNING_LEVEL_FORBID
 call neboc_warning_policy_set
 test eax,eax
 jne .fail11
 lea rdi,[rel forbid_policy]
 lea rsi,[rel warning]
 xor edx,edx
 lea rcx,[rel forbid_explanation]
 call neboc_warning_policy_explain
 test eax,eax
 jne .fail12
 lea rdi,[rel suppression]
 lea rsi,[rel warning]
 lea rdx,[rel forbid_explanation]
 lea rcx,[rel reason]
 mov r8d,reason_len
 mov r9d,0xc04f0801
 call neboc_warning_suppression_record
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail13

 ; WarningId loads its versioned offline explanation from the local catalog.
 lea rdi,[rel warning]
 lea rsi,[rel offline_explanation]
 call neboc_warning_explanation_load
 test eax,eax
 jne .fail14
 cmp qword [rel offline_explanation+NEBOC_EXPLANATION_VERSION_OFFSET],NEBOC_EXPLANATION_VERSION_V1
 jne .fail15
 cmp qword [rel offline_explanation+NEBOC_EXPLANATION_CODE_LENGTH_OFFSET],code_len
 jne .fail16

 ; A registry-authorized manual fix is previewed without changing source bytes.
 lea rdi,[rel source_map]
 lea rsi,[rel source_entries]
 mov edx,1
 mov ecx,NEBOC_PATH_POLICY_RELATIVE
 call neboc_source_map_new
 test eax,eax
 jne .fail17
 lea rdi,[rel source_map]
 lea rsi,[rel source_request]
 lea rdx,[rel file_id]
 call neboc_source_map_add_file
 test eax,eax
 jne .fail18
 lea rdi,[rel fix_manual]
 lea rsi,[rel description]
 mov edx,description_len
 mov ecx,NEBOC_FIXIT_MANUAL_ONLY
 lea r8,[rel manual_edits]
 mov r9d,1
 call neboc_fix_it_new
 test eax,eax
 jne .fail19
 lea rdi,[rel fix_manual]
 mov esi,1
 lea rdx,[rel edit_span]
 lea rcx,[rel replacement]
 mov r8d,replacement_len
 mov r9d,0xc04f08
 call neboc_fix_it_add_edit
 test eax,eax
 jne .fail20
 lea rax,[rel output]
 mov [rel writer+NEBOC_WRITER_BYTES_OFFSET],rax
 mov qword [rel writer+NEBOC_WRITER_CAPACITY_OFFSET],4096
 mov qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],0
 lea rdi,[rel warning]
 lea rsi,[rel fix_manual]
 lea rdx,[rel source_map]
 lea rcx,[rel writer]
 call neboc_warning_fixit_preview
 test eax,eax
 jne .fail21
 cmp qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],0
 je .fail22
 cmp byte [rel source+12],'1'
 jne .fail23

 ; Applicability is registry-owned; a silent promotion is rejected.
 lea rdi,[rel fix_machine]
 lea rsi,[rel description]
 mov edx,description_len
 mov ecx,NEBOC_FIXIT_MACHINE_APPLICABLE
 lea r8,[rel machine_edits]
 mov r9d,1
 call neboc_fix_it_new
 test eax,eax
 jne .fail24
 lea rdi,[rel fix_machine]
 mov esi,1
 lea rdx,[rel edit_span]
 lea rcx,[rel replacement]
 mov r8d,replacement_len
 mov r9d,0xc04f08
 call neboc_fix_it_add_edit
 test eax,eax
 jne .fail25
 mov qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],3
 lea rdi,[rel warning]
 lea rsi,[rel fix_machine]
 lea rdx,[rel source_map]
 lea rcx,[rel writer]
 call neboc_warning_fixit_preview
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail26
 cmp qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],3
 jne .fail27

 ; BUG/error-class diagnostics can never enter warning suppression/guidance.
 mov qword [rel warning+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET],NEBOC_DIAGNOSTIC_SEVERITY_BUG
 lea rdi,[rel suppression]
 lea rsi,[rel warning]
 lea rdx,[rel policy_explanation]
 lea rcx,[rel reason]
 mov r8d,reason_len
 mov r9d,0xc04f0801
 call neboc_warning_suppression_record
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail28
 lea rdi,[rel warning]
 lea rsi,[rel offline_explanation]
 call neboc_warning_explanation_load
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail29

 xor edi,edi
 call neboc_host_process_exit

%assign n 1
%rep 29
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits
