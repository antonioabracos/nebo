bits 64
default rel
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/renderer.inc"
global _start
extern neboc_diagnostic_new
extern neboc_diagnostic_renderer_short
extern neboc_renderer_render
extern neboc_host_process_exit
section .rodata
code: db "NEBO-W0001"
code_len equ $-code
key: db "diagnostic.compatibility.warning"
key_len equ $-key
section .data
request: dq code,code_len,NEBOC_DIAGNOSTIC_SEVERITY_WARNING,NEBOC_DIAGNOSTIC_CATEGORY_TOOLING,NEBOC_DIAGNOSTIC_PHASE_TOOLCHAIN,key,key_len,0,0,0
options: dq 0,NEBOC_THEME_MONO,NEBOC_COLOR_NEVER,NEBOC_UNICODE_ASCII,80,0,0,0,1,1
section .bss
diagnostic: resb NEBOC_DIAGNOSTIC_SIZE
renderer: resb NEBOC_RENDERER_SIZE
writer: resb NEBOC_WRITER_SIZE
output: resb 128
source_map: resq 1
section .text
_start:
 sub rsp,8
 lea rdi,[rel diagnostic]
 lea rsi,[rel request]
 call neboc_diagnostic_new
 test eax,eax
 jne .fail
 lea rdi,[rel renderer]
 lea rsi,[rel options]
 call neboc_diagnostic_renderer_short
 test eax,eax
 jne .fail
 lea rax,[rel output]
 mov [rel writer],rax
 mov qword [rel writer+8],128
 lea rdi,[rel renderer]
 lea rsi,[rel diagnostic]
 lea rdx,[rel source_map]
 lea rcx,[rel writer]
 call neboc_renderer_render
 test eax,eax
 jne .fail
 xor edi,edi
 call neboc_host_process_exit
.fail:
 mov edi,1
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
