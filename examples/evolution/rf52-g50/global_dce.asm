bits 64
default rel
%include "compiler/optimizer/global_dce.inc"
global _start
extern neboc_global_dce_run,neboc_host_process_exit
section .data
sections: dq 1,NEBOC_DCE_SECTION_FUNCTION,16,1,0,0,0,0,0
section .bss align=16
context: resb NEBOC_DCE_CONTEXT_SIZE
section .text
_start:
 sub rsp,8
 lea rax,[rel sections]
 mov [rel context],rax
 mov qword [rel context+8],1
 lea rdi,[rel context]
 call neboc_global_dce_run
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
