; RELEASE-GOVERNANCE-E-ENCERRAMENTO-DE-PROGRAMAS-F04 bounded immutable-by-session warning policy values.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/warning_policy.inc"
%include "compiler/diagnostics/warning_registry.inc"
extern neboc_warning_registry_lookup
section .rodata
group_unused: db "unused"
group_unused_len equ $-group_unused
group_portability: db "portability"
group_portability_len equ $-group_portability
group_performance: db "performance"
group_performance_len equ $-group_performance
group_deprecated: db "deprecated"
group_deprecated_len equ $-group_deprecated
group_experimental: db "experimental"
group_experimental_len equ $-group_experimental
section .text
bytes_equal:
 cmp rsi,rcx
 jne .be_no
 xor eax,eax
.be_loop:
 cmp rax,rsi
 jae .be_yes
 mov r8b,[rdi+rax]
 cmp r8b,[rdx+rax]
 jne .be_no
 inc rax
 jmp .be_loop
.be_yes: mov eax,1
 ret
.be_no: xor eax,eax
 ret

; WarningPolicy.new(policy*, rules*, capacity, default_level)
NEBOC_ABI_FUNCTION neboc_warning_policy_new
 test rdi,rdi
 jz .new_invalid
 test rsi,rsi
 jz .new_invalid
 test rdx,rdx
 jz .new_invalid
 cmp rdx,NEBOC_WARNING_MAX_RULES
 ja .new_limit
 cmp rcx,NEBOC_WARNING_LEVEL_ALLOW
 jb .new_invalid
 cmp rcx,NEBOC_WARNING_LEVEL_FORBID
 ja .new_invalid
 push rdi
 push rcx
 mov rdi,rsi
 mov rcx,rdx
 imul rcx,NEBOC_WARNING_RULE_SIZE/8
 xor eax,eax
 rep stosq
 pop rcx
 pop rdi
 mov [rdi+NEBOC_WARNING_RULES_OFFSET],rsi
 mov [rdi+NEBOC_WARNING_CAPACITY_OFFSET],rdx
 mov [rdi+NEBOC_WARNING_DEFAULT_OFFSET],rcx
 mov qword [rdi+NEBOC_WARNING_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.new_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.new_invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; warningPolicy.group(name*, len, out_group*)
NEBOC_ABI_FUNCTION neboc_warning_policy_group
 test rdi,rdi
 jz .group_invalid
 test rsi,rsi
 jz .group_invalid
 test rdx,rdx
 jz .group_invalid
 push rbx
 mov rbx,rdx
 lea rdx,[rel group_unused]
 mov ecx,group_unused_len
 call bytes_equal
 test eax,eax
 jnz .g_unused
 lea rdx,[rel group_portability]
 mov ecx,group_portability_len
 call bytes_equal
 test eax,eax
 jnz .g_portability
 lea rdx,[rel group_performance]
 mov ecx,group_performance_len
 call bytes_equal
 test eax,eax
 jnz .g_performance
 lea rdx,[rel group_deprecated]
 mov ecx,group_deprecated_len
 call bytes_equal
 test eax,eax
 jnz .g_deprecated
 lea rdx,[rel group_experimental]
 mov ecx,group_experimental_len
 call bytes_equal
 test eax,eax
 jnz .g_experimental
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .group_finish
.g_unused: mov qword [rbx],NEBOC_WARNING_GROUP_UNUSED
 jmp .group_ok
.g_portability: mov qword [rbx],NEBOC_WARNING_GROUP_PORTABILITY
 jmp .group_ok
.g_performance: mov qword [rbx],NEBOC_WARNING_GROUP_PERFORMANCE
 jmp .group_ok
.g_deprecated: mov qword [rbx],NEBOC_WARNING_GROUP_DEPRECATED
 jmp .group_ok
.g_experimental: mov qword [rbx],NEBOC_WARNING_GROUP_EXPERIMENTAL
.group_ok: xor eax,eax
.group_finish:
 pop rbx
 ret
.group_invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; warningPolicy.set(policy*, key*, key_len, level)
NEBOC_ABI_FUNCTION neboc_warning_policy_set
 test rdi,rdi
 jz .set_invalid
 test rsi,rsi
 jz .set_invalid
 test rdx,rdx
 jz .set_invalid
 cmp rcx,NEBOC_WARNING_LEVEL_ALLOW
 jb .set_invalid
 cmp rcx,NEBOC_WARNING_LEVEL_FORBID
 ja .set_invalid
 cmp qword [rdi+NEBOC_WARNING_ACTIVE_OFFSET],1
 jne .set_invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,144
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,[rbx+NEBOC_WARNING_RULES_OFFSET]
 mov qword [rsp+128],0
 mov qword [rsp+136],NEBOC_WARNING_RULE_CODE
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rsp+128]
 call neboc_warning_policy_group
 test eax,eax
 jnz .set_validate_code
 mov qword [rsp+136],NEBOC_WARNING_RULE_GROUP
 jmp .set_validated
.set_validate_code:
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rsp]
 call neboc_warning_registry_lookup
 test eax,eax
 jnz .set_unknown
.set_validated:
 xor r10d,r10d
.set_find:
 cmp r10,[rbx+NEBOC_WARNING_COUNT_OFFSET]
 jae .set_append
 mov rax,r10
 imul rax,NEBOC_WARNING_RULE_SIZE
 add rax,r15
 mov rdi,r12
 mov rsi,r13
 mov rdx,[rax+NEBOC_WARNING_RULE_KEY_OFFSET]
 mov rcx,[rax+NEBOC_WARNING_RULE_KEY_LENGTH_OFFSET]
 mov [rsp+120],rax
 call bytes_equal
 mov r11,[rsp+120]
 test eax,eax
 jz .set_next
 cmp qword [r11+NEBOC_WARNING_RULE_LEVEL_OFFSET],NEBOC_WARNING_LEVEL_FORBID
 jne .set_replace
 cmp r14,NEBOC_WARNING_LEVEL_FORBID
 jne .set_forbidden
.set_replace:
 mov [r11+NEBOC_WARNING_RULE_LEVEL_OFFSET],r14
 xor eax,eax
 jmp .set_finish
.set_next:
 inc r10
 jmp .set_find
.set_append:
 mov r10,[rbx+NEBOC_WARNING_COUNT_OFFSET]
 cmp r10,[rbx+NEBOC_WARNING_CAPACITY_OFFSET]
 jae .set_limit
 mov rax,r10
 imul rax,NEBOC_WARNING_RULE_SIZE
 add rax,r15
 mov [rax],r12
 mov [rax+8],r13
 mov [rax+16],r14
 mov r11,[rsp+136]
 mov [rax+NEBOC_WARNING_RULE_KIND_OFFSET],r11
 mov r11,[rsp+128]
 mov [rax+NEBOC_WARNING_RULE_GROUP_ID_OFFSET],r11
.set_count:
 inc qword [rbx+NEBOC_WARNING_COUNT_OFFSET]
 xor eax,eax
 jmp .set_finish
.set_forbidden: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .set_finish
.set_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .set_finish
.set_unknown: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.set_finish:
 add rsp,144
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.set_invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; Internal evaluation of one policy. Exact code rules outrank their group.
; evaluate_policy(policy*, diagnostic*, out_level*, out_rule*) -> status
evaluate_policy:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,144
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,[rbx+NEBOC_WARNING_RULES_OFFSET]
 mov rdi,[r12+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rsi,[r12+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 lea rdx,[rsp]
 call neboc_warning_registry_lookup
 test eax,eax
 jnz .eval_finish
 mov rax,[rbx+NEBOC_WARNING_DEFAULT_OFFSET]
 mov [rsp+120],rax
 mov qword [rsp+128],0
 xor r10d,r10d
.eval_group_loop:
 cmp r10,[rbx+NEBOC_WARNING_COUNT_OFFSET]
 jae .eval_code_start
 mov rax,r10
 imul rax,NEBOC_WARNING_RULE_SIZE
 add rax,r15
 cmp qword [rax+NEBOC_WARNING_RULE_KIND_OFFSET],NEBOC_WARNING_RULE_GROUP
 jne .eval_group_next
 mov r11,[rsp+NEBOC_WARNING_ENTRY_GROUP_OFFSET]
 cmp [rax+NEBOC_WARNING_RULE_GROUP_ID_OFFSET],r11
 jne .eval_group_next
 mov r11,[rax+NEBOC_WARNING_RULE_LEVEL_OFFSET]
 mov [rsp+120],r11
 mov [rsp+128],rax
.eval_group_next:
 inc r10
 jmp .eval_group_loop
.eval_code_start:
 xor r10d,r10d
.eval_code_loop:
 cmp r10,[rbx+NEBOC_WARNING_COUNT_OFFSET]
 jae .eval_store
 mov rax,r10
 imul rax,NEBOC_WARNING_RULE_SIZE
 add rax,r15
 cmp qword [rax+NEBOC_WARNING_RULE_KIND_OFFSET],NEBOC_WARNING_RULE_CODE
 jne .eval_code_next
 mov [rsp+136],rax
 mov rdi,[r12+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rsi,[r12+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 mov rdx,[rax+NEBOC_WARNING_RULE_KEY_OFFSET]
 mov rcx,[rax+NEBOC_WARNING_RULE_KEY_LENGTH_OFFSET]
 call bytes_equal
 test eax,eax
 jz .eval_code_next
 mov rax,[rsp+136]
 mov r11,[rax+NEBOC_WARNING_RULE_LEVEL_OFFSET]
 cmp qword [rsp+120],NEBOC_WARNING_LEVEL_FORBID
 jne .eval_code_select
 cmp r11,NEBOC_WARNING_LEVEL_FORBID
 jne .eval_store
.eval_code_select:
 mov [rsp+120],r11
 mov [rsp+128],rax
 jmp .eval_store
.eval_code_next:
 inc r10
 jmp .eval_code_loop
.eval_store:
 mov rax,[rsp+120]
 mov [r13],rax
 mov rax,[rsp+128]
 mov [r14],rax
 xor eax,eax
.eval_finish:
 add rsp,144
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Resolve inheritance while preserving a parent forbid. A child default is not
; a rule and therefore cannot replace the inherited level.
; resolve_policy(parent*, diagnostic*, child_or_null*, out_level*, out_rule*, out_source*)
resolve_policy:
 test rdi,rdi
 jz .resolve_invalid
 test rsi,rsi
 jz .resolve_invalid
 test rcx,rcx
 jz .resolve_invalid
 test r8,r8
 jz .resolve_invalid
 test r9,r9
 jz .resolve_invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 mov [rsp+32],r9
 cmp qword [rsi+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET],NEBOC_DIAGNOSTIC_SEVERITY_BUG
 jne .resolve_warning
 mov qword [r14],NEBOC_WARNING_LEVEL_FORBID
 mov qword [r15],0
 mov rax,[rsp+32]
 mov qword [rax],NEBOC_WARNING_SOURCE_BUG
 xor eax,eax
 jmp .resolve_finish
.resolve_warning:
 cmp qword [rsi+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET],NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 jne .resolve_invalid_finish
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rsp]
 lea rcx,[rsp+8]
 call evaluate_policy
 test eax,eax
 jnz .resolve_finish
 cmp qword [rsp],NEBOC_WARNING_LEVEL_FORBID
 je .resolve_parent
 test r13,r13
 jz .resolve_parent
 mov rdi,r13
 mov rsi,r12
 lea rdx,[rsp+16]
 lea rcx,[rsp+24]
 call evaluate_policy
 test eax,eax
 jnz .resolve_finish
 cmp qword [rsp+24],0
 je .resolve_parent
 mov rax,[rsp+16]
 mov [r14],rax
 mov rax,[rsp+24]
 mov [r15],rax
 mov rax,[rsp+32]
 mov qword [rax],NEBOC_WARNING_SOURCE_SCOPE
 xor eax,eax
 jmp .resolve_finish
.resolve_parent:
 mov rax,[rsp]
 mov [r14],rax
 mov rax,[rsp+8]
 mov [r15],rax
 mov rax,[rsp+32]
 cmp qword [rsp+8],0
 je .resolve_default_source
 mov qword [rax],NEBOC_WARNING_SOURCE_POLICY
 xor eax,eax
 jmp .resolve_finish
.resolve_default_source:
 mov qword [rax],NEBOC_WARNING_SOURCE_DEFAULT
 xor eax,eax
.resolve_finish:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.resolve_invalid_finish:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .resolve_finish
.resolve_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; effectiveLevel(policy*, diagnostic*, scope_policy_or_null*, out_level*)
NEBOC_ABI_FUNCTION neboc_warning_policy_effective_level
 test rcx,rcx
 jz .effective_invalid
 push rbx
 sub rsp,16
 mov rbx,rcx
 mov rcx,rbx
 lea r8,[rsp]
 lea r9,[rsp+8]
 call resolve_policy
 add rsp,16
 pop rbx
 ret
.effective_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; explain(policy*, diagnostic*, scope*, explanation*)
NEBOC_ABI_FUNCTION neboc_warning_policy_explain
 test rcx,rcx
 jz .explain_invalid
 push rbx
 mov rbx,rcx
 mov rcx,rbx
 lea r8,[rbx+NEBOC_WARNING_EXPLANATION_RULE_OFFSET]
 lea r9,[rbx+NEBOC_WARNING_EXPLANATION_SOURCE_OFFSET]
 call resolve_policy
 test eax,eax
 jne .explain_finish
 mov rax,[rbx+NEBOC_WARNING_EXPLANATION_RULE_OFFSET]
 test rax,rax
 jz .explain_no_rule
 mov rdx,[rax+NEBOC_WARNING_RULE_KEY_OFFSET]
 mov [rbx+NEBOC_WARNING_EXPLANATION_RULE_OFFSET],rdx
 mov rdx,[rax+NEBOC_WARNING_RULE_KEY_LENGTH_OFFSET]
 mov [rbx+NEBOC_WARNING_EXPLANATION_RULE_LENGTH_OFFSET],rdx
 jmp .explain_ok
.explain_no_rule:
 mov qword [rbx+NEBOC_WARNING_EXPLANATION_RULE_OFFSET],0
 mov qword [rbx+NEBOC_WARNING_EXPLANATION_RULE_LENGTH_OFFSET],0
.explain_ok:
 xor eax,eax
.explain_finish:
 pop rbx
 ret
.explain_invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
