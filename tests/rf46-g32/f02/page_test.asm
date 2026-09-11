bits 64
default rel
%include "runtime/database/db_page.inc"
extern nebo_db_page_seal,nebo_db_page_validate
extern nebo_db_journal_prepare,nebo_db_journal_recover
extern nebo_db_page_write_file,nebo_db_page_read_file
section .bss
page resb NEBO_DB_PAGE_SIZE
copy resb NEBO_DB_PAGE_SIZE
journal resb NEBO_DB_JOURNAL_SIZE
recovered resq 1
section .text
global _start
_start:
 cmp qword [rsp],2
 jne fail
 mov r14,[rsp+16]
 mov byte [page+NEBO_DB_PAGE_DATA],42
 lea rdi,[page]
 mov esi,9
 call nebo_db_page_seal
 test eax,eax
 jnz fail
 lea rdi,[page]
 call nebo_db_page_validate
 test eax,eax
 jnz fail
 mov rdi,r14
 lea rsi,[page]
 call nebo_db_page_write_file
 test eax,eax
 jnz fail
 mov rdi,r14
 lea rsi,[copy]
 call nebo_db_page_read_file
 test eax,eax
 jnz fail
 lea rdi,[copy]
 call nebo_db_page_validate
 test eax,eax
 jnz fail
 cmp byte [copy+NEBO_DB_PAGE_DATA],42
 jne fail
 mov r12,[page+NEBO_DB_PAGE_CHECKSUM]
 mov r13,r12
 xor r13,123
 lea rdi,[journal]
 mov esi,3
 mov rdx,r12
 mov rcx,r13
 call nebo_db_journal_prepare
 test eax,eax
 jnz fail
 lea rdi,[journal]
 mov rsi,999
 lea rdx,[recovered]
 call nebo_db_journal_recover
 cmp eax,NEBO_DB_PAGE_STATUS_RECOVERED
 jne fail
 cmp [recovered],r12
 jne fail
 xor byte [copy+NEBO_DB_PAGE_DATA],1
 lea rdi,[copy]
 call nebo_db_page_validate
 cmp eax,NEBO_DB_PAGE_STATUS_CHECKSUM
 jne fail
 xor edi,edi
 jmp exit
fail:
 mov edi,1
exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
