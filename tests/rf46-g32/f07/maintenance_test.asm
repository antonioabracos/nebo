bits 64
default rel
%include "runtime/database/db_maintenance.inc"
extern nebo_db_backup_copy,nebo_db_backup_verify,nebo_db_compact_nonzero
section .data
source db 1,2,3,4,5,6,7,8
rows dq 0,10,0,20,30,0
section .bss
backup resb 8
hash resq 1
dense resq 3
count resq 1
section .text
global _start
_start:
 lea rdi,[source]
 lea rsi,[backup]
 mov edx,8
 lea rcx,[hash]
 call nebo_db_backup_copy
 test eax,eax
 jnz fail
 lea rdi,[source]
 lea rsi,[backup]
 mov edx,8
 call nebo_db_backup_verify
 test eax,eax
 jnz fail
 xor byte [backup+3],1
 lea rdi,[source]
 lea rsi,[backup]
 mov edx,8
 call nebo_db_backup_verify
 cmp eax,NEBO_DB_MAINT_MISMATCH
 jne fail
 lea rdi,[rows]
 mov esi,6
 lea rdx,[dense]
 mov ecx,3
 lea r8,[count]
 call nebo_db_compact_nonzero
 test eax,eax
 jnz fail
 cmp qword [count],3
 jne fail
 cmp qword [dense+16],30
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
