; C04-F03 deterministic warning configuration stack.  Configuration front ends
; provide already parsed policies; this module introduces no source syntax.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/warning_policy.inc"
%include "compiler/diagnostics/warning_registry.inc"
%include "compiler/diagnostics/warning_config.inc"

extern neboc_warning_registry_lookup
extern neboc_warning_policy_explain

section .text

; warning_config_new(config*, profile)
NEBOC_ABI_FUNCTION neboc_warning_config_new
 test rdi,rdi
 jz .new_invalid
 cmp rsi,NEBOC_WARNING_PROFILE_DEVELOPMENT
 jb .new_invalid
 cmp rsi,NEBOC_WARNING_PROFILE_CI
 ja .new_invalid
 push rdi
 push rsi
 mov ecx,NEBOC_WARNING_CONFIG_SIZE/8
 xor eax,eax
 rep stosq
 pop rsi
 pop rdi
 mov [rdi+NEBOC_WARNING_CONFIG_PROFILE_OFFSET],rsi
 xor eax,eax
 ret
.new_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; warning_config_set_layer(config*, origin, policy*, use_policy_default)
NEBOC_ABI_FUNCTION neboc_warning_config_set_layer
 test rdi,rdi
 jz .set_invalid
 cmp qword [rdi+NEBOC_WARNING_CONFIG_PROFILE_OFFSET],NEBOC_WARNING_PROFILE_DEVELOPMENT
 jb .set_invalid
 cmp qword [rdi+NEBOC_WARNING_CONFIG_PROFILE_OFFSET],NEBOC_WARNING_PROFILE_CI
 ja .set_invalid
 cmp rsi,NEBOC_WARNING_CONFIG_LAYER_WORKSPACE
 jb .set_invalid
 cmp rsi,NEBOC_WARNING_CONFIG_LAYER_CLI
 ja .set_invalid
 test rdx,rdx
 jz .set_invalid
 cmp qword [rdx+NEBOC_WARNING_ACTIVE_OFFSET],1
 jne .set_invalid
 cmp rcx,1
 ja .set_invalid
 mov rax,rsi
 dec rax
 cmp qword [rdi+NEBOC_WARNING_CONFIG_LAYERS_OFFSET+rax*8],0
 jne .set_invalid
 mov [rdi+NEBOC_WARNING_CONFIG_LAYERS_OFFSET+rax*8],rdx
 mov [rdi+NEBOC_WARNING_CONFIG_LAYER_DEFAULT_FLAGS_OFFSET+rax*8],rcx
 xor eax,eax
 ret
.set_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; warning_config_resolve(config*, diagnostic*, out_resolution*)
; Precedence is registry < workspace < package < module < source < CLI.
NEBOC_ABI_FUNCTION neboc_warning_config_resolve
 test rdi,rdi
 jz .resolve_invalid
 test rsi,rsi
 jz .resolve_invalid
 test rdx,rdx
 jz .resolve_invalid
 mov rax,[rdi+NEBOC_WARNING_CONFIG_PROFILE_OFFSET]
 cmp rax,NEBOC_WARNING_PROFILE_DEVELOPMENT
 jb .resolve_invalid
 cmp rax,NEBOC_WARNING_PROFILE_CI
 ja .resolve_invalid
 cmp qword [rsi+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET],NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 jne .resolve_invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,192
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rdi,[r12+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rsi,[r12+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 lea rdx,[rsp]
 call neboc_warning_registry_lookup
 test eax,eax
 jnz .resolve_finish
 mov rax,[rsp+NEBOC_WARNING_ENTRY_DEFAULT_LEVEL_OFFSET]
 cmp qword [rbx+NEBOC_WARNING_CONFIG_PROFILE_OFFSET],NEBOC_WARNING_PROFILE_CI
 jne .resolve_seed
 cmp rax,NEBOC_WARNING_LEVEL_WARN
 jne .resolve_seed
 mov eax,NEBOC_WARNING_LEVEL_DENY
.resolve_seed:
 mov [rsp+120],rax
 mov qword [rsp+128],NEBOC_WARNING_CONFIG_ORIGIN_REGISTRY
 mov qword [rsp+136],0
 mov qword [rsp+144],0
 mov qword [rsp+152],1
 mov r14d,NEBOC_WARNING_CONFIG_LAYER_WORKSPACE
.resolve_layer:
 cmp r14d,NEBOC_WARNING_CONFIG_LAYER_CLI
 ja .resolve_store
 mov eax,r14d
 dec eax
 mov r15,[rbx+NEBOC_WARNING_CONFIG_LAYERS_OFFSET+rax*8]
 test r15,r15
 jz .resolve_next
 mov rdi,r15
 mov rsi,r12
 xor edx,edx
 lea rcx,[rsp+160]
 call neboc_warning_policy_explain
 test eax,eax
 jnz .resolve_finish
 cmp qword [rsp+160+NEBOC_WARNING_EXPLANATION_RULE_OFFSET],0
 jne .resolve_candidate
 mov eax,r14d
 dec eax
 cmp qword [rbx+NEBOC_WARNING_CONFIG_LAYER_DEFAULT_FLAGS_OFFSET+rax*8],1
 jne .resolve_next
.resolve_candidate:
 mov rax,[rsp+160+NEBOC_WARNING_EXPLANATION_LEVEL_OFFSET]
 cmp qword [rsp+120],NEBOC_WARNING_LEVEL_FORBID
 jne .resolve_select
 cmp rax,NEBOC_WARNING_LEVEL_FORBID
 jne .resolve_next
.resolve_select:
 mov [rsp+120],rax
 mov [rsp+128],r14
 mov rax,[rsp+160+NEBOC_WARNING_EXPLANATION_RULE_OFFSET]
 mov [rsp+136],rax
 mov rax,[rsp+160+NEBOC_WARNING_EXPLANATION_RULE_LENGTH_OFFSET]
 mov [rsp+144],rax
 xor eax,eax
 cmp qword [rsp+136],0
 setz al
 mov [rsp+152],rax
.resolve_next:
 inc r14d
 jmp .resolve_layer
.resolve_store:
 mov rdi,r13
 lea rsi,[rsp+120]
 mov ecx,NEBOC_WARNING_CONFIG_RESOLUTION_SIZE/8
 rep movsq
 xor eax,eax
.resolve_finish:
 add rsp,192
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.resolve_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
