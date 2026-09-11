bits 64
default rel
%include "runtime/textual/render_console.inc"

section .rodata
%if G68_FRONT = 1
payload: db '# Layout'
structure_token equ RENDER_STRUCTURE_TITLE
structure_aux equ 0
target equ RENDER_TARGET_PLAIN
%elif G68_FRONT = 2
payload: db 'name | score',10,'Ada | 7'
structure_token equ RENDER_STRUCTURE_TABLE
structure_aux equ 0
target equ RENDER_TARGET_MARKDOWN
%elif G68_FRONT = 3
payload: db '1. alpha',10,'2. beta'
structure_token equ RENDER_STRUCTURE_LIST
structure_aux equ 0
target equ RENDER_TARGET_PLAIN
%elif G68_FRONT = 4
payload: db 'count=3',10,'first=21'
structure_token equ RENDER_STRUCTURE_COLLECTION
structure_aux equ 0
target equ RENDER_TARGET_HEADLESS
%elif G68_FRONT = 5
payload: db '# Guide',10,'> Note'
structure_token equ RENDER_STRUCTURE_DOCUMENTATION
structure_aux equ 0
target equ RENDER_TARGET_MARKDOWN
%elif G68_FRONT = 6
payload: db 'width=24'
structure_token equ RENDER_STRUCTURE_WIDTH
structure_aux equ 24
target equ RENDER_TARGET_HEADLESS
%else
payload: db 'layout-conformance:75/75'
structure_token equ RENDER_STRUCTURE_CONFORMANCE
structure_aux equ 0
target equ RENDER_TARGET_HEADLESS
%endif
payload_len equ $-payload

section .data
nodes:
 dq RENDER_NODE_STRUCTURE,RENDER_FLAG_FALLBACK,payload,payload_len,structure_token,structure_aux
node_count equ 1
buffer: times 128 db 0xaa
second_buffer: times 128 db 0x55
atomic_buffer: times 128 db 0xcc

section .text
extern neboc_render_feature_available
extern neboc_render_feature_validate
extern neboc_render_structure_token_validate
extern neboc_render_plan_validate
extern neboc_render_plan_measure
extern neboc_render_plan_write
global _start
_start:
 mov edi,6800+G68_FRONT
 call neboc_render_feature_available
 cmp eax,1
 jne .fail
 mov edi,6800+G68_FRONT
 mov esi,RENDER_FLAG_FALLBACK
 mov edx,payload_len
 mov ecx,2
 mov r8d,target
 call neboc_render_feature_validate
 test eax,eax
 jnz .fail
 mov edi,structure_token
 mov esi,structure_aux
 call neboc_render_structure_token_validate
 test eax,eax
 jnz .fail
 mov edi,RENDER_STRUCTURE_MAX+1
 xor esi,esi
 call neboc_render_structure_token_validate
 cmp eax,RENDER_E_INVALID
 jne .fail
 mov rdi,nodes
 mov esi,node_count
 mov edx,target
 call neboc_render_plan_validate
 test eax,eax
 jnz .fail
 mov rdi,nodes
 mov esi,node_count
 mov edx,target
 call neboc_render_plan_measure
 cmp rax,payload_len
 jne .fail
 mov rdi,nodes
 mov esi,node_count
 mov edx,target
 mov rcx,buffer
 mov r8d,128
 call neboc_render_plan_write
 cmp rax,payload_len
 jne .fail
 mov rsi,buffer
 mov rdi,payload
 mov ecx,payload_len
 repe cmpsb
 jne .fail
 mov rdi,nodes
 mov esi,node_count
 mov edx,target
 mov rcx,second_buffer
 mov r8d,128
 call neboc_render_plan_write
 cmp rax,payload_len
 jne .fail
 mov rsi,buffer
 mov rdi,second_buffer
 mov ecx,payload_len
 repe cmpsb
 jne .fail
 mov rdi,nodes
 mov esi,node_count
 mov edx,target
 mov rcx,atomic_buffer
 mov r8d,payload_len-1
 call neboc_render_plan_write
 cmp rax,-RENDER_E_CAPACITY
 jne .fail
 cmp byte [atomic_buffer],0xcc
 jne .fail
 xor edi,edi
 mov eax,60
 syscall
.fail:
 mov edi,68+G68_FRONT
 mov eax,60
 syscall
