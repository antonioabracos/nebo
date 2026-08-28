bits 64
default rel
%include "compiler/optimizer/ipo.inc"
global _start
extern neboc_ipo_context_new,neboc_host_process_exit
section .data
functions: times NEBOC_IPO_FUNC_SIZE db 0
section .bss align=16
context: resb NEBOC_IPO_CONTEXT_SIZE
limits: resb NEBOC_IPO_LIMIT_SIZE
section .text
_start:
 sub rsp,8
 mov qword [rel functions],1
 mov qword [rel limits],1
 mov qword [rel limits+8],16
 mov qword [rel limits+16],8
 mov qword [rel limits+24],8
 mov qword [rel limits+32],4
 lea rdi,[rel context]
 lea rsi,[rel functions]
 mov edx,1
 lea rcx,[rel limits]
 xor r8d,r8d
 call neboc_ipo_context_new
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
