bits 64
default rel
%include "runtime/knowledge/fact.inc"
extern nebo_fact_init,nebo_fact_hash
section .bss
fact resb NEBO_FACT_SIZE
hash1 resq 1
hash2 resq 1
section .text
global _start
_start:
 lea rdi,[fact]
 mov esi,1
 mov edx,2
 mov ecx,3
 mov r8d,4
 mov r9d,5
 call nebo_fact_init
 test eax,eax
 jnz fail
 lea rdi,[fact]
 lea rsi,[hash1]
 call nebo_fact_hash
 lea rdi,[fact]
 lea rsi,[hash2]
 call nebo_fact_hash
 mov rax,[hash1]
 cmp rax,[hash2]
 jne fail
 cmp qword [fact+NEBO_FACT_SOURCE],4
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
