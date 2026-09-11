bits 64
default rel
%include "runtime/database/db_format.inc"
extern nebo_db_header_init,nebo_db_header_validate
section .bss
header resb NEBO_DB_HEADER_SIZE
section .text
global _start
_start:
 lea rdi,[header]
 mov esi,16
 mov edx,7
 mov rcx,0x12345678
 call nebo_db_header_init
 test eax,eax
 jnz fail
 mov rax,NEBO_DB_MAGIC
 cmp [header+NEBO_DB_HEADER_MAGIC],rax
 jne fail
 cmp qword [header+NEBO_DB_HEADER_PAGE_SIZE],4096
 jne fail
 lea rdi,[header]
 call nebo_db_header_validate
 test eax,eax
 jnz fail
 xor byte [header+NEBO_DB_HEADER_SCHEMA_HASH],1
 lea rdi,[header]
 call nebo_db_header_validate
 cmp eax,NEBO_DB_STATUS_CHECKSUM
 jne fail
 xor byte [header+NEBO_DB_HEADER_SCHEMA_HASH],1
 lea rdi,[header]
 mov esi,NEBO_DB_MAX_PAGES+1
 mov edx,1
 xor ecx,ecx
 call nebo_db_header_init
 cmp eax,NEBO_DB_STATUS_LIMIT
 jne fail
 xor edi,edi
 jmp exit
fail:
 mov edi,1
exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
