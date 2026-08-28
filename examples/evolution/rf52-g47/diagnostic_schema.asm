bits 64
default rel
%include "compiler/diagnostics/diagnostic.inc"

global _start
extern neboc_diagnostic_new
extern neboc_diagnostic_code
extern neboc_host_process_exit

section .rodata
code: db "NEBO-W0001"
code_len equ $-code
key: db "diagnostic.compatibility.warning"
key_len equ $-key

section .data
request:
 dq code,code_len
 dq NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 dq NEBOC_DIAGNOSTIC_CATEGORY_TOOLING
 dq NEBOC_DIAGNOSTIC_PHASE_TOOLCHAIN
 dq key,key_len
 dq 0
 dq 0,0

section .bss align=16
diagnostic: resb NEBOC_DIAGNOSTIC_SIZE
slice: resb NEBOC_DIAGNOSTIC_SLICE_SIZE

section .text
_start:
 sub rsp,8
 lea rdi,[rel diagnostic]
 lea rsi,[rel request]
 call neboc_diagnostic_new
 test eax,eax
 jne .fail
 lea rdi,[rel diagnostic]
 lea rsi,[rel slice]
 call neboc_diagnostic_code
 test eax,eax
 jne .fail
 cmp qword [rel slice+NEBOC_DIAGNOSTIC_SLICE_LENGTH_OFFSET],code_len
 jne .fail
 xor edi,edi
 call neboc_host_process_exit
.fail:
 mov edi,1
 call neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
