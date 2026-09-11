bits 64
default rel
%include "runtime/textual/render_console.inc"
%include "compiler/lsp/render_policy_completion.inc"
section .rodata
prefix: db 'str'
section .bss
ids: resq 4
info: resb NEBOC_G074_COMPLETION_INFO_SIZE
section .text
extern neboc_render_feature_available
global _start
_start:
 mov edi,7405
 call neboc_render_feature_available
 cmp eax,1
 jne .fail
 lea rdi,[rel prefix]
 mov esi,3
 lea rdx,[rel ids]
 mov ecx,4
 call neboc_render_policy_complete
 cmp eax,2
 jne .fail
 cmp qword [rel ids],1
 jne .fail
 cmp qword [rel ids+8],14
 jne .fail
 mov edi,14
 lea rsi,[rel info]
 call neboc_render_policy_completion_resolve
 test eax,eax
 jnz .fail
 xor edi,edi
 mov eax,60
 syscall
.fail: mov edi,79
 mov eax,60
 syscall
