bits 64
default rel
%include "runtime/textual/render_console.inc"

section .rodata
payload: db G70_PAYLOAD
payload_len equ $-payload

section .data
node: dq RENDER_NODE_OPERATION,RENDER_FLAG_FALLBACK,payload,payload_len,G70_TOKEN,G70_AUX
bad_node: dq RENDER_NODE_OPERATION,RENDER_FLAG_FALLBACK,payload,payload_len,G70_TOKEN,G70_BAD_AUX
private_node: dq RENDER_NODE_OPERATION,RENDER_FLAG_FALLBACK|RENDER_FLAG_PRIVATE,payload,payload_len,G70_TOKEN,G70_AUX
output: times 256 db 0xaa
atomic: times 256 db 0xcc

section .text
extern neboc_render_feature_available
extern neboc_render_feature_validate
extern neboc_render_operation_token_validate
extern neboc_render_plan_validate
extern neboc_render_plan_measure
extern neboc_render_plan_write
global _start
_start:
 mov edi,G70_FEATURE_ID
 call neboc_render_feature_available
 cmp eax,1
 jne .fail
 mov edi,G70_FEATURE_ID
 mov esi,RENDER_FLAG_FALLBACK
 mov edx,payload_len
 mov ecx,1
 mov r8d,RENDER_TARGET_HEADLESS
 call neboc_render_feature_validate
 test eax,eax
 jnz .fail
 mov edi,G70_TOKEN
 mov esi,G70_AUX
 mov edx,RENDER_FLAG_FALLBACK
 call neboc_render_operation_token_validate
 test eax,eax
 jnz .fail
 mov edi,G70_TOKEN
 mov esi,G70_BAD_AUX
 mov edx,RENDER_FLAG_FALLBACK
 call neboc_render_operation_token_validate
 cmp eax,RENDER_E_INVALID
 jne .fail
 lea rdi,[rel node]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 call neboc_render_plan_measure
 cmp eax,payload_len
 jne .fail
 lea rdi,[rel node]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 lea rcx,[rel output]
 mov r8d,256
 call neboc_render_plan_write
 cmp eax,payload_len
 jne .fail
 lea rsi,[rel payload]
 lea rdi,[rel output]
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
 cmp byte [rel atomic],0xcc
 jne .fail
 lea rdi,[rel bad_node]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 call neboc_render_plan_validate
 cmp eax,RENDER_E_INVALID
 jne .fail
 lea rdi,[rel private_node]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 call neboc_render_plan_validate
 cmp eax,RENDER_E_PRIVACY
 jne .fail
 xor edi,edi
 mov eax,60
 syscall
.fail:
 mov edi,G70_EXIT
 mov eax,60
 syscall
