bits 64
default rel
extern neboc_g15_bounded_contract
extern neboc_host_process_exit
global _start
section .text
_start: mov edi,15
 call neboc_g15_bounded_contract
 cmp eax,1
 jne .bad
 xor edi,edi
 jmp neboc_host_process_exit
.bad: mov edi,1
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
