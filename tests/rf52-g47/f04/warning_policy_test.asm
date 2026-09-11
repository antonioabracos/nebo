bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/warning_policy.inc"
global _start
extern neboc_diagnostic_new
extern neboc_warning_policy_new
extern neboc_warning_policy_set
extern neboc_warning_policy_group
extern neboc_warning_policy_effective_level
extern neboc_warning_policy_explain
extern neboc_host_process_exit
section .rodata
code: db "NEBO-W0001"
code_len equ $-code
key: db "diagnostic.compatibility.warning"
key_len equ $-key
ice_code: db "NEBO-ICE-0001"
ice_code_len equ $-ice_code
ice_key: db "diagnostic.internal.invariant"
ice_key_len equ $-ice_key
group: db "performance"
group_len equ $-group
section .data
request: dq code,code_len,NEBOC_DIAGNOSTIC_SEVERITY_WARNING,NEBOC_DIAGNOSTIC_CATEGORY_TOOLING,NEBOC_DIAGNOSTIC_PHASE_TOOLCHAIN,key,key_len,0,0,0
ice_request: dq ice_code,ice_code_len,NEBOC_DIAGNOSTIC_SEVERITY_BUG,NEBOC_DIAGNOSTIC_CATEGORY_INTERNAL,NEBOC_DIAGNOSTIC_PHASE_INTERNAL,ice_key,ice_key_len,0,0,0
section .bss
diag: resb NEBOC_DIAGNOSTIC_SIZE
ice: resb NEBOC_DIAGNOSTIC_SIZE
policy: resb NEBOC_WARNING_POLICY_SIZE
scope: resb NEBOC_WARNING_POLICY_SIZE
rules: resb NEBOC_WARNING_RULE_SIZE*4
scope_rules: resb NEBOC_WARNING_RULE_SIZE*4
level: resq 1
group_id: resq 1
explanation: resb NEBOC_WARNING_EXPLANATION_SIZE
section .text
_start:
 sub rsp,8
 lea rdi,[rel diag]
 lea rsi,[rel request]
 call neboc_diagnostic_new
 test eax,eax
 jne .fail1
 lea rdi,[rel ice]
 lea rsi,[rel ice_request]
 call neboc_diagnostic_new
 test eax,eax
 jne .fail2
 lea rdi,[rel policy]
 lea rsi,[rel rules]
 mov edx,4
 mov ecx,NEBOC_WARNING_LEVEL_WARN
 call neboc_warning_policy_new
 test eax,eax
 jne .fail3
 lea rdi,[rel scope]
 lea rsi,[rel scope_rules]
 mov edx,4
 mov ecx,NEBOC_WARNING_LEVEL_WARN
 call neboc_warning_policy_new
 test eax,eax
 jne .fail4
 lea rdi,[rel group]
 mov esi,group_len
 lea rdx,[rel group_id]
 call neboc_warning_policy_group
 test eax,eax
 jne .fail5
 cmp qword [rel group_id],NEBOC_WARNING_GROUP_PERFORMANCE
 jne .fail6
 lea rdi,[rel policy]
 lea rsi,[rel code]
 mov edx,code_len
 mov ecx,NEBOC_WARNING_LEVEL_DENY
 call neboc_warning_policy_set
 test eax,eax
 jne .fail7
 lea rdi,[rel policy]
 lea rsi,[rel diag]
 xor edx,edx
 lea rcx,[rel level]
 call neboc_warning_policy_effective_level
 test eax,eax
 jne .fail8
 cmp qword [rel level],NEBOC_WARNING_LEVEL_DENY
 jne .fail9
 lea rdi,[rel scope]
 lea rsi,[rel code]
 mov edx,code_len
 mov ecx,NEBOC_WARNING_LEVEL_ALLOW
 call neboc_warning_policy_set
 test eax,eax
 jne .fail10
 lea rdi,[rel policy]
 lea rsi,[rel diag]
 lea rdx,[rel scope]
 lea rcx,[rel level]
 call neboc_warning_policy_effective_level
 test eax,eax
 jne .fail11
 cmp qword [rel level],NEBOC_WARNING_LEVEL_ALLOW
 jne .fail12
 lea rdi,[rel policy]
 lea rsi,[rel code]
 mov edx,code_len
 mov ecx,NEBOC_WARNING_LEVEL_FORBID
 call neboc_warning_policy_set
 test eax,eax
 jne .fail13
 lea rdi,[rel policy]
 lea rsi,[rel diag]
 lea rdx,[rel scope]
 lea rcx,[rel level]
 call neboc_warning_policy_effective_level
 test eax,eax
 jne .fail14
 cmp qword [rel level],NEBOC_WARNING_LEVEL_FORBID
 jne .fail15
 lea rdi,[rel policy]
 lea rsi,[rel code]
 mov edx,code_len
 mov ecx,NEBOC_WARNING_LEVEL_ALLOW
 call neboc_warning_policy_set
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail16
 lea rdi,[rel policy]
 lea rsi,[rel ice]
 xor edx,edx
 lea rcx,[rel level]
 call neboc_warning_policy_effective_level
 test eax,eax
 jne .fail17
 cmp qword [rel level],NEBOC_WARNING_LEVEL_FORBID
 jne .fail18
 lea rdi,[rel policy]
 lea rsi,[rel diag]
 lea rdx,[rel scope]
 lea rcx,[rel explanation]
 call neboc_warning_policy_explain
 test eax,eax
 jne .fail19
 cmp qword [rel explanation],NEBOC_WARNING_LEVEL_FORBID
 jne .fail20
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 20
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
