; RELEASE-GOVERNANCE-E-ENCERRAMENTO-DE-PROGRAMAS-F06 native composition: encode one canonical Diagnostic as JSON.
bits 64
default rel
%include "compiler/source/span/source_span.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/renderer.inc"
%include "compiler/diagnostics/machine.inc"
global _start
extern neboc_diagnostic_new
extern neboc_diagnostic_encoder_json
extern neboc_host_process_exit
section .rodata
code: db "NEBO-E0001"
code_len equ $-code
key: db "diagnostic.schema.invalid"
key_len equ $-key
section .data
span: dq 1,0,1,1
request: dq code,code_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_CATEGORY_TOOLING,NEBOC_DIAGNOSTIC_PHASE_TOOLCHAIN,key,key_len,span,0,0
section .bss align=16
diagnostic: resb NEBOC_DIAGNOSTIC_SIZE
writer: resb NEBOC_WRITER_SIZE
output: resb 1024
section .text
_start:
 sub rsp,8
 lea rdi,[rel diagnostic]
 lea rsi,[rel request]
 call neboc_diagnostic_new
 test eax,eax
 jne .fail
 lea rax,[rel output]
 mov [rel writer+NEBOC_WRITER_BYTES_OFFSET],rax
 mov qword [rel writer+NEBOC_WRITER_CAPACITY_OFFSET],1024
 lea rdi,[rel diagnostic]
 mov esi,NEBOC_MACHINE_SCHEMA_V1
 lea rdx,[rel writer]
 call neboc_diagnostic_encoder_json
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
