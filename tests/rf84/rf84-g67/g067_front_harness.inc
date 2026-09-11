bits 64
default rel
%include "runtime/textual/render_console.inc"

section .rodata
bar: db '|'
%if G67_FRONT = 1
a: db 'B'
b: db 'I'
expected: db 27,'[1mB',27,'[0m|',27,'[3mI',27,'[0m'
%elif G67_FRONT = 2
a: db 'R'
b: db 'X'
expected: db 27,'[31mR',27,'[0m|',27,'[38;2;018;052;171mX',27,'[0m'
%elif G67_FRONT = 3
a: db '[ok]'
b: db '[warning]'
c: db '[critical]'
expected: db '[ok]|[warning]|[critical]'
%elif G67_FRONT = 4
a: db 'same'
expected: db 'same'
%else
a: db 'stable'
expected: db 27,'[36mstable',27,'[0m'
%endif
expected_len equ $-expected

section .data
nodes:
%if G67_FRONT = 1
 dq RENDER_NODE_STYLE,RENDER_FLAG_FALLBACK,0,0,RENDER_STYLE_BOLD,0
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,a,1,0,0
 dq RENDER_NODE_STYLE,RENDER_FLAG_FALLBACK,0,0,RENDER_STYLE_RESET,0
 dq RENDER_NODE_SEPARATOR,RENDER_FLAG_FALLBACK,bar,1,0,0
 dq RENDER_NODE_STYLE,RENDER_FLAG_FALLBACK,0,0,RENDER_STYLE_ITALIC,0
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,b,1,0,0
 dq RENDER_NODE_STYLE,RENDER_FLAG_FALLBACK,0,0,RENDER_STYLE_RESET,0
node_count equ 7
target equ RENDER_TARGET_ANSI
%elif G67_FRONT = 2
 dq RENDER_NODE_STYLE,RENDER_FLAG_FALLBACK,0,0,RENDER_STYLE_FG_RED,0
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,a,1,0,0
 dq RENDER_NODE_STYLE,RENDER_FLAG_FALLBACK,0,0,RENDER_STYLE_RESET,0
 dq RENDER_NODE_SEPARATOR,RENDER_FLAG_FALLBACK,bar,1,0,0
 dq RENDER_NODE_STYLE,RENDER_FLAG_FALLBACK,0,0,RENDER_STYLE_FG_RGB,0x1234ab
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,b,1,0,0
 dq RENDER_NODE_STYLE,RENDER_FLAG_FALLBACK,0,0,RENDER_STYLE_RESET,0
node_count equ 7
target equ RENDER_TARGET_ANSI
%elif G67_FRONT = 3
 dq RENDER_NODE_SEMANTIC,RENDER_FLAG_FALLBACK,a,4,0,0
 dq RENDER_NODE_SEPARATOR,RENDER_FLAG_FALLBACK,bar,1,0,0
 dq RENDER_NODE_SEMANTIC,RENDER_FLAG_FALLBACK,b,9,0,0
 dq RENDER_NODE_SEPARATOR,RENDER_FLAG_FALLBACK,bar,1,0,0
 dq RENDER_NODE_SEMANTIC,RENDER_FLAG_FALLBACK,c,10,0,0
node_count equ 5
target equ RENDER_TARGET_PLAIN
%elif G67_FRONT = 4
 dq RENDER_NODE_STYLE,RENDER_FLAG_FALLBACK,0,0,RENDER_STYLE_BOLD,0
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,a,4,0,0
 dq RENDER_NODE_STYLE,RENDER_FLAG_FALLBACK,0,0,RENDER_STYLE_RESET,0
node_count equ 3
target equ RENDER_TARGET_HEADLESS
%else
 dq RENDER_NODE_STYLE,RENDER_FLAG_FALLBACK,0,0,RENDER_STYLE_THEME,0
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,a,6,0,0
 dq RENDER_NODE_STYLE,RENDER_FLAG_FALLBACK,0,0,RENDER_STYLE_RESET,0
node_count equ 3
target equ RENDER_TARGET_ANSI
%endif
buffer: times 128 db 0xaa
second_buffer: times 128 db 0x55
atomic_buffer: times 128 db 0xcc

section .text
extern neboc_render_feature_available
extern neboc_render_feature_validate
extern neboc_render_style_token_validate
extern neboc_render_plan_validate
extern neboc_render_plan_measure
extern neboc_render_plan_write
global _start
_start:
 mov edi,6700+G67_FRONT
 call neboc_render_feature_available
 cmp eax,1
 jne .fail
 mov edi,6700+G67_FRONT
 mov esi,RENDER_FLAG_FALLBACK
 mov edx,expected_len
 mov ecx,1
 mov r8d,target
 call neboc_render_feature_validate
 test eax,eax
 jnz .fail
 mov edi,RENDER_STYLE_BOLD
 xor esi,esi
 call neboc_render_style_token_validate
 test eax,eax
 jnz .fail
 xor edi,edi
 xor esi,esi
 call neboc_render_style_token_validate
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
 cmp rax,expected_len
 jne .fail
 mov rdi,nodes
 mov esi,node_count
 mov edx,target
 mov rcx,buffer
 mov r8d,128
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
 mov rcx,second_buffer
 mov r8d,128
 call neboc_render_plan_write
 cmp rax,expected_len
 jne .fail
 mov rsi,buffer
 mov rdi,second_buffer
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
 mov edi,67+G67_FRONT
 mov eax,60
 syscall
