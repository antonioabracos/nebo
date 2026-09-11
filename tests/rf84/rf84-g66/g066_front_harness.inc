bits 64
default rel
%include "runtime/textual/render_console.inc"

section .rodata
%if G66_FRONT = 1
a: db '['
b: db 'value'
c: db ']'
expected: db '[value]',10
%elif G66_FRONT = 2
a: db 'red'
b: db ','
c: db 'blue'
expected: db 'red,blue'
%elif G66_FRONT = 3
a: db '<',0xc3,0xa9,'&','>'
expected: db '&lt;',0xc3,0xa9,'&amp;&gt;'
%elif G66_FRONT = 4
a: db '  left'
b: db '    '
c: db 'right'
expected: db '  left    right'
%else
a: db 'stable'
expected: db 'stable',10
%endif
expected_len equ $-expected

section .data
nodes:
%if G66_FRONT = 1
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,a,1,0,0
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,b,5,0,0
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,c,1,0,0
 dq RENDER_NODE_BREAK,RENDER_FLAG_FALLBACK,0,0,0,0
node_count equ 4
target equ RENDER_TARGET_PLAIN
%elif G66_FRONT = 2
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,a,3,0,0
 dq RENDER_NODE_SEPARATOR,RENDER_FLAG_FALLBACK,b,1,0,0
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,c,4,0,0
node_count equ 3
target equ RENDER_TARGET_PLAIN
%elif G66_FRONT = 3
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,a,5,0,0
node_count equ 1
target equ RENDER_TARGET_HTML
%elif G66_FRONT = 4
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,a,6,0,0
 dq RENDER_NODE_SEPARATOR,RENDER_FLAG_FALLBACK,b,4,0,0
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,c,5,0,0
node_count equ 3
target equ RENDER_TARGET_PLAIN
%else
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,a,6,0,0
 dq RENDER_NODE_BREAK,RENDER_FLAG_FALLBACK,0,0,0,0
node_count equ 2
target equ RENDER_TARGET_HEADLESS
%endif
buffer: times 64 db 0xaa
atomic_buffer: times 64 db 0xcc

section .text
extern neboc_render_feature_available
extern neboc_render_feature_validate
extern neboc_render_plan_validate
extern neboc_render_plan_measure
extern neboc_render_plan_write
global _start
_start:
 mov edi,6600+G66_FRONT
 call neboc_render_feature_available
 cmp eax,1
 jne .fail
 mov edi,6600+G66_FRONT
 mov esi,RENDER_FLAG_FALLBACK
 mov edx,expected_len
 mov ecx,1
 mov r8d,target
 call neboc_render_feature_validate
 test eax,eax
 jnz .fail
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
 cmp rax,expected_len
 jne .fail
 mov rdi,nodes
 mov esi,node_count
 mov edx,target
 mov rcx,buffer
 mov r8d,64
 call neboc_render_plan_write
 cmp rax,expected_len
 jne .fail
 mov rsi,buffer
 mov rdi,expected
 mov ecx,expected_len
 repe cmpsb
 jne .fail
 mov rdi,nodes
 mov esi,node_count
 mov edx,target
 mov rcx,atomic_buffer
 mov r8d,expected_len-1
 call neboc_render_plan_write
 cmp rax,-RENDER_E_CAPACITY
 jne .fail
 cmp byte [atomic_buffer],0xcc
 jne .fail
 xor edi,edi
 mov eax,60
 syscall
.fail:
 mov edi,66+G66_FRONT
 mov eax,60
 syscall
