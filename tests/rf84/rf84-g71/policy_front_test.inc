%ifndef G071_FEATURE_ID
%error "G071_FEATURE_ID required"
%endif
%ifndef G071_POLICY_TOKEN
%error "G071_POLICY_TOKEN required"
%endif
%ifndef G071_POLICY_AUX
%error "G071_POLICY_AUX required"
%endif

bits 64
default rel
%include "runtime/textual/render_console.inc"

section .rodata
payload: db 'g','7','1','-','p','o','l','i','c','y'
payload_len equ $-payload

section .data
node: dq RENDER_NODE_POLICY,RENDER_FLAG_FALLBACK,payload,payload_len,G071_POLICY_TOKEN,G071_POLICY_AUX
bad_node: dq RENDER_NODE_POLICY,0,payload,payload_len,G071_POLICY_TOKEN,G071_POLICY_AUX
buffer: times 32 db 0xaa
atomic: times 32 db 0xaa

section .text
extern neboc_render_feature_available
extern neboc_render_feature_validate
extern neboc_render_policy_token_validate
extern neboc_render_plan_validate
extern neboc_render_plan_measure
extern neboc_render_plan_write
global _start
_start:
 mov edi,G071_FEATURE_ID
 call neboc_render_feature_available
 cmp eax,1
 jne .fail
 mov edi,G071_FEATURE_ID
 mov esi,RENDER_FLAG_FALLBACK
 mov edx,payload_len
 mov ecx,1
 mov r8d,RENDER_TARGET_HEADLESS
 call neboc_render_feature_validate
 test eax,eax
 jnz .fail
 mov edi,G071_FEATURE_ID
 xor esi,esi
 mov edx,payload_len
 mov ecx,1
 mov r8d,RENDER_TARGET_HEADLESS
 call neboc_render_feature_validate
 cmp eax,RENDER_E_INVALID
 jne .fail
 mov edi,G071_POLICY_TOKEN
 mov esi,G071_POLICY_AUX
 mov edx,RENDER_FLAG_FALLBACK
 call neboc_render_policy_token_validate
 test eax,eax
 jnz .fail
 lea rdi,[rel node]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 call neboc_render_plan_validate
 test eax,eax
 jnz .fail
 lea rdi,[rel bad_node]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 call neboc_render_plan_validate
 test eax,eax
 jz .fail
 lea rdi,[rel node]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 call neboc_render_plan_measure
 cmp rax,payload_len
 jne .fail
 lea rdi,[rel node]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 lea rcx,[rel buffer]
 mov r8d,32
 call neboc_render_plan_write
 cmp rax,payload_len
 jne .fail
 lea rsi,[rel buffer]
 lea rdi,[rel payload]
 mov ecx,payload_len
 repe cmpsb
 jne .fail
 lea rdi,[rel node]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 lea rcx,[rel atomic]
 mov r8d,payload_len-1
 call neboc_render_plan_write
 cmp rax,-RENDER_E_CAPACITY
 jne .fail
 cmp byte [rel atomic],0xaa
 jne .fail
 xor edi,edi
 mov eax,60
 syscall
.fail:
 mov edi,71
 mov eax,60
 syscall
