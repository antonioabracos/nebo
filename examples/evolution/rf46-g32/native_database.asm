bits 64
default rel
%include "runtime/database/db_format.inc"
%include "runtime/query/query.inc"
extern nebo_db_header_init,nebo_db_header_validate,nebo_query_filter_sum
section .data
values dq 2,4,8
section .bss
header resb NEBO_DB_HEADER_SIZE
count resq 1
sum resq 1
section .text
global _start
_start:
 lea rdi,[header]
 mov esi,4
 mov edx,1
 mov ecx,123
 call nebo_db_header_init
 test eax,eax
 jnz fail
 lea rdi,[header]
 call nebo_db_header_validate
 test eax,eax
 jnz fail
 lea rdi,[values]
 mov esi,3
 mov edx,4
 mov ecx,3
 lea r8,[count]
 lea r9,[sum]
 call nebo_query_filter_sum
 test eax,eax
 jnz fail
 cmp qword [sum],12
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
