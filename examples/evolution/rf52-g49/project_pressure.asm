bits 64
default rel
%include "compiler/memory/project_pressure.inc"
global _start
extern neboc_project_synthetic_corpus,neboc_host_process_exit
section .bss align=16
modules: resb NEBOC_PROJECT_MODULE_SIZE*4
section .text
_start:
 sub rsp,8
 lea rdi,[rel modules]
 mov esi,4
 mov edx,32
 mov ecx,1
 call neboc_project_synthetic_corpus
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
