bits 64
default rel
extern nebo_g15_runtime_value
extern neboc_host_process_exit
global _start
section .text
_start: call nebo_g15_runtime_value
 cmp eax,15
 jne .bad
 xor edi,edi
 jmp neboc_host_process_exit
.bad: mov edi,1
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
