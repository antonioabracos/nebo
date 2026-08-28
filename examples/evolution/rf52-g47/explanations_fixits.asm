; RELEASE-GOVERNANCE-E-ENCERRAMENTO-DE-PROGRAMAS-F07 native composition: render one offline explanation.
bits 64
default rel
%include "compiler/diagnostics/renderer.inc"
%include "compiler/diagnostics/explain.inc"
global _start
extern neboc_diagnostic_explanation_load
extern neboc_diagnostic_explanation_render
extern neboc_host_process_exit
section .rodata
code: db 'NEBO-E0001'
code_len equ $-code
section .bss align=16
explanation: resb NEBOC_EXPLANATION_SIZE
writer: resb NEBOC_WRITER_SIZE
output: resb 2048
section .text
_start:
 sub rsp,8
 lea rdi,[rel code]
 mov esi,code_len
 lea rdx,[rel explanation]
 call neboc_diagnostic_explanation_load
 test eax,eax
 jne .fail
 lea rax,[rel output]
 mov [rel writer+NEBOC_WRITER_BYTES_OFFSET],rax
 mov qword [rel writer+NEBOC_WRITER_CAPACITY_OFFSET],2048
 lea rdi,[rel explanation]
 lea rsi,[rel writer]
 call neboc_diagnostic_explanation_render
 test eax,eax
 jne .fail
 cmp qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],0
 je .fail
 xor edi,edi
 call neboc_host_process_exit
.fail:
 mov edi,1
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
