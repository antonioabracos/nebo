bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/module_init.inc"

section .text

; Compatibility helper: validate that every required bit is explicitly
; granted. Imports never modify either mask.
NEBOC_ABI_FUNCTION neboc_module_init_effects
 test rdx,rdx
 jz .arg
 mov rax,rdi
 not rsi
 test rax,rsi
 jnz .source
 mov [rdx],rdi
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE

NEBOC_ABI_FUNCTION neboc_init_required_effects
 test rdi,rdi
 jz .effects_arg
 test rsi,rsi
 jz .effects_arg
 mov rdx,[rdi+NEBOC_INIT_PLAN_NODES]
 xor eax,eax
 xor ecx,ecx
.effects_loop:
 cmp rcx,[rdi+NEBOC_INIT_PLAN_COUNT]
 jae .effects_done
 mov r8,rcx
 shl r8,6
 cmp qword [rdx+r8+NEBOC_INIT_NODE_KIND],NEBOC_INIT_KIND_PURE
 je .effects_next
 or rax,[rdx+r8+NEBOC_INIT_NODE_EFFECTS]
.effects_next:
 inc rcx
 jmp .effects_loop
.effects_done:
 mov [rsi],rax
 xor eax,eax
 ret
.effects_arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION neboc_init_required_capabilities
 test rdi,rdi
 jz .caps_arg
 test rsi,rsi
 jz .caps_arg
 mov rdx,[rdi+NEBOC_INIT_PLAN_NODES]
 xor eax,eax
 xor ecx,ecx
.caps_loop:
 cmp rcx,[rdi+NEBOC_INIT_PLAN_COUNT]
 jae .caps_done
 mov r8,rcx
 shl r8,6
 cmp qword [rdx+r8+NEBOC_INIT_NODE_KIND],NEBOC_INIT_KIND_PURE
 je .caps_next
 or rax,[rdx+r8+NEBOC_INIT_NODE_CAPABILITIES]
.caps_next:
 inc rcx
 jmp .caps_loop
.caps_done:
 mov [rsi],rax
 xor eax,eax
 ret
.caps_arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
