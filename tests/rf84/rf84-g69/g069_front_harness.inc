%ifndef G069_FEATURE
 %error "G069_FEATURE is required"
%endif
%ifndef G069_TOKEN
 %error "G069_TOKEN is required"
%endif
%ifndef G069_FLAGS
 %define G069_FLAGS RENDER_FLAG_FALLBACK
%endif

bits 64
default rel
%include "runtime/textual/render_console.inc"

section .rodata
payload: db 'developer-token-',('0' + (G069_FEATURE - 6900))
payload_len equ $-payload

section .data
node:
 dq RENDER_NODE_DEVELOPER,G069_FLAGS,payload,payload_len,G069_TOKEN,2
private_node:
 dq RENDER_NODE_DEVELOPER,G069_FLAGS|RENDER_FLAG_PRIVATE,payload,payload_len,G069_TOKEN,2
atomic_buffer: times 64 db 0xaa
output: times 64 db 0

section .text
extern neboc_render_feature_available
extern neboc_render_feature_validate
extern neboc_render_plan_validate
extern neboc_render_plan_measure
extern neboc_render_plan_write
extern neboc_render_developer_token_validate
global _start
_start:
 mov edi,G069_FEATURE
 call neboc_render_feature_available
 cmp eax,1
 jne .fail

 mov edi,G069_FEATURE
 mov esi,RENDER_FLAG_FALLBACK
 mov edx,payload_len
 mov ecx,2
 mov r8d,RENDER_TARGET_HEADLESS
 call neboc_render_feature_validate
 test eax,eax
 jnz .fail

 mov edi,G069_TOKEN
 mov esi,2
 mov edx,G069_FLAGS
 call neboc_render_developer_token_validate
 test eax,eax
 jnz .fail

 lea rdi,[rel node]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 call neboc_render_plan_validate
 test eax,eax
 jnz .fail
 lea rdi,[rel node]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 call neboc_render_plan_measure
 cmp rax,payload_len
 jne .fail
 lea rdi,[rel node]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 lea rcx,[rel output]
 mov r8d,64
 call neboc_render_plan_write
 cmp rax,payload_len
 jne .fail
 lea rsi,[rel output]
 lea rdi,[rel payload]
 mov ecx,payload_len
 repe cmpsb
 jne .fail

 lea rdi,[rel node]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 lea rcx,[rel atomic_buffer]
 mov r8d,payload_len-1
 call neboc_render_plan_write
 cmp rax,-RENDER_E_CAPACITY
 jne .fail
 cmp byte [rel atomic_buffer],0xaa
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
 mov edi,69
 mov eax,60
 syscall
