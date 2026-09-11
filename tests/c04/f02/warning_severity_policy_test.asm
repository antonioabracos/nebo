bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/warning_policy.inc"

global _start
extern neboc_diagnostic_new
extern neboc_warning_policy_new
extern neboc_warning_policy_set
extern neboc_warning_policy_effective_level
extern neboc_warning_policy_explain
extern neboc_host_process_exit

section .rodata
warning_id: db "NEBO-W0001"
warning_id_len equ $-warning_id
unknown_id: db "NEBO-W9999"
unknown_id_len equ $-unknown_id
portability: db "portability"
portability_len equ $-portability
unknown_group: db "unknown-group"
unknown_group_len equ $-unknown_group
warning_key: db "diagnostic.compatibility.warning"
warning_key_len equ $-warning_key
ice_id: db "NEBO-ICE-0001"
ice_id_len equ $-ice_id
ice_key: db "diagnostic.internal.invariant"
ice_key_len equ $-ice_key

section .data
warning_request:
 dq warning_id,warning_id_len
 dq NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 dq NEBOC_DIAGNOSTIC_CATEGORY_TOOLING
 dq NEBOC_DIAGNOSTIC_PHASE_TOOLCHAIN
 dq warning_key,warning_key_len
 dq 0,0,0
ice_request:
 dq ice_id,ice_id_len
 dq NEBOC_DIAGNOSTIC_SEVERITY_BUG
 dq NEBOC_DIAGNOSTIC_CATEGORY_INTERNAL
 dq NEBOC_DIAGNOSTIC_PHASE_INTERNAL
 dq ice_key,ice_key_len
 dq 0,0,0

section .bss
warning: resb NEBOC_DIAGNOSTIC_SIZE
ice: resb NEBOC_DIAGNOSTIC_SIZE
parent: resb NEBOC_WARNING_POLICY_SIZE
child: resb NEBOC_WARNING_POLICY_SIZE
parent_rules: resb NEBOC_WARNING_RULE_SIZE*8
child_rules: resb NEBOC_WARNING_RULE_SIZE*8
level: resq 1
explanation: resb NEBOC_WARNING_EXPLANATION_SIZE
guard_policy: resb NEBOC_WARNING_POLICY_SIZE
guard_rules: resb NEBOC_WARNING_RULE_SIZE
guard_after: resq 1

section .text
_start:
 lea rdi,[rel warning]
 lea rsi,[rel warning_request]
 call neboc_diagnostic_new
 test eax,eax
 jne .fail1
 lea rdi,[rel ice]
 lea rsi,[rel ice_request]
 call neboc_diagnostic_new
 test eax,eax
 jne .fail2

 ; A group rule applies to its canonical registry member.
 lea rdi,[rel parent]
 lea rsi,[rel parent_rules]
 mov edx,8
 mov ecx,NEBOC_WARNING_LEVEL_WARN
 call neboc_warning_policy_new
 test eax,eax
 jne .fail3
 lea rdi,[rel parent]
 lea rsi,[rel portability]
 mov edx,portability_len
 mov ecx,NEBOC_WARNING_LEVEL_DENY
 call neboc_warning_policy_set
 test eax,eax
 jne .fail4
 lea rdi,[rel parent]
 lea rsi,[rel warning]
 xor edx,edx
 lea rcx,[rel level]
 call neboc_warning_policy_effective_level
 test eax,eax
 jne .fail5
 cmp qword [rel level],NEBOC_WARNING_LEVEL_DENY
 jne .fail6

 ; An exact code is more specific than a lower group rule.
 lea rdi,[rel parent]
 lea rsi,[rel warning_id]
 mov edx,warning_id_len
 mov ecx,NEBOC_WARNING_LEVEL_ALLOW
 call neboc_warning_policy_set
 test eax,eax
 jne .fail7
 lea rdi,[rel parent]
 lea rsi,[rel warning]
 xor edx,edx
 lea rcx,[rel level]
 call neboc_warning_policy_effective_level
 test eax,eax
 jne .fail8
 cmp qword [rel level],NEBOC_WARNING_LEVEL_ALLOW
 jne .fail9

 ; Reinitialize: an empty child inherits, an explicit child may lower deny.
 lea rdi,[rel parent]
 lea rsi,[rel parent_rules]
 mov edx,8
 mov ecx,NEBOC_WARNING_LEVEL_WARN
 call neboc_warning_policy_new
 test eax,eax
 jne .fail10
 lea rdi,[rel child]
 lea rsi,[rel child_rules]
 mov edx,8
 mov ecx,NEBOC_WARNING_LEVEL_ALLOW
 call neboc_warning_policy_new
 test eax,eax
 jne .fail11
 lea rdi,[rel parent]
 lea rsi,[rel portability]
 mov edx,portability_len
 mov ecx,NEBOC_WARNING_LEVEL_DENY
 call neboc_warning_policy_set
 test eax,eax
 jne .fail12
 lea rdi,[rel parent]
 lea rsi,[rel warning]
 lea rdx,[rel child]
 lea rcx,[rel level]
 call neboc_warning_policy_effective_level
 test eax,eax
 jne .fail13
 cmp qword [rel level],NEBOC_WARNING_LEVEL_DENY
 jne .fail14
 lea rdi,[rel child]
 lea rsi,[rel warning_id]
 mov edx,warning_id_len
 mov ecx,NEBOC_WARNING_LEVEL_ALLOW
 call neboc_warning_policy_set
 test eax,eax
 jne .fail15
 lea rdi,[rel parent]
 lea rsi,[rel warning]
 lea rdx,[rel child]
 lea rcx,[rel level]
 call neboc_warning_policy_effective_level
 test eax,eax
 jne .fail16
 cmp qword [rel level],NEBOC_WARNING_LEVEL_ALLOW
 jne .fail17

 ; Explain reports the exact child rule and its provenance.
 lea rdi,[rel parent]
 lea rsi,[rel warning]
 lea rdx,[rel child]
 lea rcx,[rel explanation]
 call neboc_warning_policy_explain
 test eax,eax
 jne .fail18
 cmp qword [rel explanation+NEBOC_WARNING_EXPLANATION_LEVEL_OFFSET],NEBOC_WARNING_LEVEL_ALLOW
 jne .fail19
 cmp qword [rel explanation+NEBOC_WARNING_EXPLANATION_RULE_LENGTH_OFFSET],warning_id_len
 jne .fail20
 cmp qword [rel explanation+NEBOC_WARNING_EXPLANATION_SOURCE_OFFSET],NEBOC_WARNING_SOURCE_SCOPE
 jne .fail21

 ; Forbid is monotonic across both specificity and child inheritance.
 lea rdi,[rel parent]
 lea rsi,[rel portability]
 mov edx,portability_len
 mov ecx,NEBOC_WARNING_LEVEL_FORBID
 call neboc_warning_policy_set
 test eax,eax
 jne .fail22
 lea rdi,[rel parent]
 lea rsi,[rel warning]
 lea rdx,[rel child]
 lea rcx,[rel level]
 call neboc_warning_policy_effective_level
 test eax,eax
 jne .fail23
 cmp qword [rel level],NEBOC_WARNING_LEVEL_FORBID
 jne .fail24
 lea rdi,[rel parent]
 lea rsi,[rel portability]
 mov edx,portability_len
 mov ecx,NEBOC_WARNING_LEVEL_WARN
 call neboc_warning_policy_set
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail25

 ; Unknown selectors fail closed, and BUG/ICE is never suppressible.
 lea rdi,[rel child]
 lea rsi,[rel unknown_id]
 mov edx,unknown_id_len
 mov ecx,NEBOC_WARNING_LEVEL_WARN
 call neboc_warning_policy_set
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail26
 lea rdi,[rel child]
 lea rsi,[rel unknown_group]
 mov edx,unknown_group_len
 mov ecx,NEBOC_WARNING_LEVEL_WARN
 call neboc_warning_policy_set
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail27
 lea rdi,[rel parent]
 lea rsi,[rel ice]
 lea rdx,[rel child]
 lea rcx,[rel level]
 call neboc_warning_policy_effective_level
 test eax,eax
 jne .fail28
 cmp qword [rel level],NEBOC_WARNING_LEVEL_FORBID
 jne .fail29

 ; Construction clears exactly the supplied rule storage, never adjacent data.
 mov rax,0x1122334455667788
 mov [rel guard_rules],rax
 mov rax,0x8877665544332211
 mov [rel guard_after],rax
 lea rdi,[rel guard_policy]
 lea rsi,[rel guard_rules]
 mov edx,1
 mov ecx,NEBOC_WARNING_LEVEL_WARN
 call neboc_warning_policy_new
 test eax,eax
 jne .fail30
 cmp qword [rel guard_rules],0
 jne .fail31
 mov rax,0x8877665544332211
 cmp qword [rel guard_after],rax
 jne .fail32

 xor edi,edi
 call neboc_host_process_exit

%assign n 1
%rep 32
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits
