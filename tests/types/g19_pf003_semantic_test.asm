bits 64
default rel
extern neboc_g19_semantic_value
extern neboc_host_process_exit
global _start
section .text
_start: call neboc_g19_semantic_value
 cmp eax,19
 jne .bad
 xor edi,edi
 jmp neboc_host_process_exit
.bad: mov edi,1
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
