bits 64
default rel
%include "runtime/database/db_migrate.inc"
extern nebo_db_migrate_v1_v2,nebo_db_transfer_chunk
section .data
old dq 10,20,30
bytes db 1,2,3,4,5
section .bss
new resq 4
chunk resb 3
count resq 1
section .text
global _start
_start:
 lea rdi,[old]
 lea rsi,[new]
 mov edx,3
 mov ecx,4
 mov r8d,99
 call nebo_db_migrate_v1_v2
 cmp rax,4
 jne fail
 cmp qword [new+24],99
 jne fail
 lea rdi,[old]
 lea rsi,[new]
 mov edx,3
 mov ecx,3
 mov r8d,99
 call nebo_db_migrate_v1_v2
 cmp rax,-4
 jne fail
 lea rdi,[bytes]
 lea rsi,[chunk]
 mov edx,1
 mov ecx,5
 mov r8d,3
 lea r9,[count]
 call nebo_db_transfer_chunk
 test eax,eax
 jnz fail
 cmp qword [count],3
 jne fail
 cmp byte [chunk],2
 jne fail
 cmp byte [chunk+2],4
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
