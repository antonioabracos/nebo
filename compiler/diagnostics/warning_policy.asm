; RELEASE-GOVERNANCE-E-ENCERRAMENTO-DE-PROGRAMAS-F04 bounded immutable-by-session warning policy values.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/warning_policy.inc"
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
 mov rcx,rdx
 shl rcx,2
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
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,[rbx+NEBOC_WARNING_RULES_OFFSET]
 xor r10d,r10d
.set_find:
 cmp r10,[rbx+NEBOC_WARNING_COUNT_OFFSET]
 jae .set_append
 mov rax,r10
 shl rax,5
 add rax,r15
 mov rdi,r12
 mov rsi,r13
 mov rdx,[rax+NEBOC_WARNING_RULE_KEY_OFFSET]
 mov rcx,[rax+NEBOC_WARNING_RULE_KEY_LENGTH_OFFSET]
 push rax
 NEBOC_ABI_ALIGNED_CALL bytes_equal
 pop r11
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
 shl rax,5
 add rax,r15
 mov [rax],r12
 mov [rax+8],r13
 mov [rax+16],r14
 mov qword [rax+24],NEBOC_WARNING_RULE_CODE
 sub rsp,16
 mov [rsp+8],rax
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rsp]
 call neboc_warning_policy_group
 mov r11,[rsp+8]
 add rsp,16
 test eax,eax
 jne .set_count
 mov qword [r11+24],NEBOC_WARNING_RULE_GROUP
.set_count:
 inc qword [rbx+NEBOC_WARNING_COUNT_OFFSET]
 xor eax,eax
 jmp .set_finish
.set_forbidden: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .set_finish
.set_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.set_finish:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.set_invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; Internal evaluation of one policy for exact diagnostic code.
; rdi policy, rsi diag, rdx inout explanation source id.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
evaluate_policy:
 mov r8,[rdi+NEBOC_WARNING_DEFAULT_OFFSET]
 mov r9,[rdi+NEBOC_WARNING_RULES_OFFSET]
 mov r10,[rdi+NEBOC_WARNING_COUNT_OFFSET]
 xor r11d,r11d
.eval_loop:
 cmp r11,r10
 jae .eval_done
 mov rax,r11
 shl rax,5
 add rax,r9
 cmp qword [rax+NEBOC_WARNING_RULE_KIND_OFFSET],NEBOC_WARNING_RULE_CODE
 jne .eval_next
 push rdi
 push rsi
 push rdx
 push rax
 mov rdi,[rsi+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rsi,[rsi+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 mov rdx,[rax+NEBOC_WARNING_RULE_KEY_OFFSET]
 mov rcx,[rax+NEBOC_WARNING_RULE_KEY_LENGTH_OFFSET]
 call bytes_equal
 pop rcx
 pop rdx
 pop rsi
 pop rdi
 test eax,eax
 jz .eval_next
 mov r8,[rcx+NEBOC_WARNING_RULE_LEVEL_OFFSET]
 mov [rdx],rcx
.eval_next:
 inc r11
 jmp .eval_loop
.eval_done:
 mov rax,r8
 ret

; effectiveLevel(policy*, diagnostic*, scope_policy_or_null*, out_level*)
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_warning_policy_effective_level
 test rdi,rdi
 jz .effective_invalid
 test rsi,rsi
 jz .effective_invalid
 test rcx,rcx
 jz .effective_invalid
 cmp qword [rsi+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET],NEBOC_DIAGNOSTIC_SEVERITY_BUG
 jne .effective_warning
 mov qword [rcx],NEBOC_WARNING_LEVEL_FORBID
 xor eax,eax
 ret
.effective_warning:
 cmp qword [rsi+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET],NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 jne .effective_invalid
 push rbx
 push r12
 sub rsp,16
 mov rbx,rdx
 mov r12,rcx
 lea rdx,[rsp]
 mov qword [rsp],0
 call evaluate_policy
 mov r8,rax
 cmp r8,NEBOC_WARNING_LEVEL_FORBID
 je .effective_store
 test rbx,rbx
 jz .effective_store
 mov rdi,rbx
 lea rdx,[rsp+8]
 mov qword [rsp+8],0
 call evaluate_policy
 mov r8,rax
.effective_store:
 mov [r12],r8
 xor eax,eax
 add rsp,16
 pop r12
 pop rbx
 ret
.effective_invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; explain(policy*, diagnostic*, scope*, explanation*)
%undef call
NEBOC_ABI_FUNCTION neboc_warning_policy_explain
 test rcx,rcx
 jz .explain_invalid
 push rbx
 mov rbx,rcx
 sub rsp,16
 lea rcx,[rsp]
 call neboc_warning_policy_effective_level
 test eax,eax
 jne .explain_finish
 mov rax,[rsp]
 mov [rbx+NEBOC_WARNING_EXPLANATION_LEVEL_OFFSET],rax
 mov qword [rbx+NEBOC_WARNING_EXPLANATION_SOURCE_OFFSET],NEBOC_WARNING_SOURCE_DEFAULT
 xor eax,eax
.explain_finish:
 add rsp,16
 pop rbx
 ret
.explain_invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
