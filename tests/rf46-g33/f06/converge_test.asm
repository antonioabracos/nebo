bits 64
default rel
%include "runtime/replication/converge.inc"
extern nebo_replica_state_hash,nebo_compact_stable_dots
section .data
state dq 2,3,4
same dq 2,3,4
dots dq 1,2,3,4,5
section .bss
hash1 resq 1
hash2 resq 1
kept resq 2
count resq 1
section .text
global _start
_start:
 lea rdi,[state]
 mov esi,3
 lea rdx,[hash1]
 call nebo_replica_state_hash
 lea rdi,[same]
 mov esi,3
 lea rdx,[hash2]
 call nebo_replica_state_hash
 mov rax,[hash1]
 cmp rax,[hash2]
 jne fail
 lea rdi,[dots]
 mov esi,5
 mov edx,3
 lea rcx,[kept]
 mov r8d,2
 lea r9,[count]
 call nebo_compact_stable_dots
 test eax,eax
 jnz fail
 cmp qword [count],2
 jne fail
 cmp qword [kept],4
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
