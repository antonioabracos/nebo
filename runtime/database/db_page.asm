; RF46-G32-F02 checked pages, rollback journal core, and isolated file I/O.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/database/db_page.inc"
extern nebo_db_fnv1a64
section .text
NEBOC_ABI_FUNCTION nebo_db_page_seal
 test rdi,rdi
 jz .invalid
 push rbx
 mov rbx,rdi
 mov [rbx+NEBO_DB_PAGE_LSN],rsi
 mov rdi,rbx
 add rdi,NEBO_DB_PAGE_DATA
 mov esi,NEBO_DB_PAGE_DATA_SIZE
 call nebo_db_fnv1a64
 xor rax,[rbx+NEBO_DB_PAGE_LSN]
 mov [rbx+NEBO_DB_PAGE_CHECKSUM],rax
 pop rbx
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_DB_PAGE_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_db_page_validate
 test rdi,rdi
 jz .invalid
 push rbx
 mov rbx,rdi
 add rdi,NEBO_DB_PAGE_DATA
 mov esi,NEBO_DB_PAGE_DATA_SIZE
 call nebo_db_fnv1a64
 xor rax,[rbx+NEBO_DB_PAGE_LSN]
 cmp rax,[rbx+NEBO_DB_PAGE_CHECKSUM]
 pop rbx
 jne .checksum
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_DB_PAGE_STATUS_INVALID
 ret
.checksum:
 mov eax,NEBO_DB_PAGE_STATUS_CHECKSUM
 ret

NEBOC_ABI_FUNCTION nebo_db_journal_prepare
 test rdi,rdi
 jz .invalid
 mov qword [rdi+NEBO_DB_JOURNAL_STATE],NEBO_DB_JOURNAL_PREPARED
 mov [rdi+NEBO_DB_JOURNAL_PAGE_ID],rsi
 mov [rdi+NEBO_DB_JOURNAL_BEFORE],rdx
 mov [rdi+NEBO_DB_JOURNAL_AFTER],rcx
 mov qword [rdi+NEBO_DB_JOURNAL_VERSION],1
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_DB_PAGE_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_db_journal_recover
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp qword [rdi+NEBO_DB_JOURNAL_STATE],NEBO_DB_JOURNAL_PREPARED
 jne .invalid
 cmp qword [rdi+NEBO_DB_JOURNAL_VERSION],1
 jne .invalid
 mov rax,[rdi+NEBO_DB_JOURNAL_AFTER]
 cmp rsi,rax
 je .committed
 mov rax,[rdi+NEBO_DB_JOURNAL_BEFORE]
 mov [rdx],rax
 mov qword [rdi+NEBO_DB_JOURNAL_STATE],0
 mov eax,NEBO_DB_PAGE_STATUS_RECOVERED
 ret
.committed:
 mov [rdx],rax
 mov qword [rdi+NEBO_DB_JOURNAL_STATE],0
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_DB_PAGE_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_db_page_write_file
 test rdi,rdi
 jz .io
 test rsi,rsi
 jz .io
 push rbx
 push r12
 push r13
 mov r12,rsi
 mov eax,257
 mov rsi,rdi
 mov rdi,-100
 mov edx,0x80241
 mov r10d,0x180
 syscall
 test rax,rax
 js .io_saved
 mov rbx,rax
 xor r13d,r13d
.write:
 cmp r13,NEBO_DB_PAGE_SIZE
 jae .sync
 mov eax,1
 mov rdi,rbx
 lea rsi,[r12+r13]
 mov rdx,NEBO_DB_PAGE_SIZE
 sub rdx,r13
 syscall
 cmp rax,-4
 je .write
 test rax,rax
 jle .close_error
 add r13,rax
 jmp .write
.sync:
 mov eax,74
 mov rdi,rbx
 syscall
 test rax,rax
 js .close_error
 mov eax,3
 mov rdi,rbx
 syscall
 pop r13
 pop r12
 pop rbx
 xor eax,eax
 ret
.close_error:
 mov eax,3
 mov rdi,rbx
 syscall
.io_saved:
 pop r13
 pop r12
 pop rbx
.io:
 mov eax,NEBO_DB_PAGE_STATUS_IO
 ret

NEBOC_ABI_FUNCTION nebo_db_page_read_file
 test rdi,rdi
 jz .io
 test rsi,rsi
 jz .io
 push rbx
 push r12
 push r13
 mov r12,rsi
 mov eax,257
 mov rsi,rdi
 mov rdi,-100
 mov edx,0x80000
 xor r10d,r10d
 syscall
 test rax,rax
 js .io_saved
 mov rbx,rax
 xor r13d,r13d
.read:
 cmp r13,NEBO_DB_PAGE_SIZE
 jae .close_ok
 xor eax,eax
 mov rdi,rbx
 lea rsi,[r12+r13]
 mov rdx,NEBO_DB_PAGE_SIZE
 sub rdx,r13
 syscall
 cmp rax,-4
 je .read
 test rax,rax
 jle .close_error
 add r13,rax
 jmp .read
.close_ok:
 mov eax,3
 mov rdi,rbx
 syscall
 pop r13
 pop r12
 pop rbx
 xor eax,eax
 ret
.close_error:
 mov eax,3
 mov rdi,rbx
 syscall
.io_saved:
 pop r13
 pop r12
 pop rbx
.io:
 mov eax,NEBO_DB_PAGE_STATUS_IO
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
