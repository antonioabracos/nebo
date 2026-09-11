bits 64
default rel
%include "runtime/database/db_tx.inc"
extern nebo_db_tx_begin,nebo_db_tx_set,nebo_db_tx_savepoint
extern nebo_db_tx_rollback_savepoint,nebo_db_tx_commit,nebo_db_tx_abort
section .data
current dq 10,20,30
section .bss
shadow resq 3
save resq 3
tx resb NEBO_DB_TX_SIZE
section .text
global _start
_start:
 lea rdi,[tx]
 lea rsi,[current]
 lea rdx,[shadow]
 lea rcx,[save]
 mov r8d,3
 call nebo_db_tx_begin
 test eax,eax
 jnz fail
 lea rdi,[tx]
 mov esi,1
 mov edx,99
 call nebo_db_tx_set
 test eax,eax
 jnz fail
 cmp qword [current+8],20
 jne fail
 lea rdi,[tx]
 call nebo_db_tx_savepoint
 test eax,eax
 jnz fail
 lea rdi,[tx]
 mov esi,2
 mov edx,77
 call nebo_db_tx_set
 lea rdi,[tx]
 call nebo_db_tx_rollback_savepoint
 cmp qword [shadow+16],30
 jne fail
 lea rdi,[tx]
 call nebo_db_tx_commit
 cmp qword [current+8],99
 jne fail
 cmp qword [current+16],30
 jne fail
 lea rdi,[tx]
 call nebo_db_tx_commit
 cmp eax,NEBO_DB_TX_STATE
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
