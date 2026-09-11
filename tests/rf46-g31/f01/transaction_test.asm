bits 64
default rel
%include "runtime/reactive/transaction.inc"
extern nebo_cell_init,nebo_transaction_init,nebo_transaction_set,nebo_transaction_commit,nebo_transaction_rollback
section .bss
cell resb nebo_transaction_CELL_SIZE
tx resb NEBO_TX_SIZE
entries resb NEBO_TX_ENTRY_SIZE*2
section .text
global _start
_start:
 lea rdi,[cell]
 mov esi,10
 call nebo_cell_init
 test eax,eax
 jnz fail
 lea rdi,[tx]
 lea rsi,[entries]
 mov edx,2
 call nebo_transaction_init
 test eax,eax
 jnz fail
 lea rdi,[tx]
 lea rsi,[cell]
 mov edx,20
 call nebo_transaction_set
 test eax,eax
 jnz fail
 cmp qword [cell],10
 jne fail
 lea rdi,[tx]
 lea rsi,[cell]
 mov edx,30
 call nebo_transaction_set
 test eax,eax
 jnz fail
 cmp qword [tx+NEBO_TX_COUNT],1
 jne fail
 lea rdi,[tx]
 call nebo_transaction_commit
 test eax,eax
 jnz fail
 cmp qword [cell],30
 jne fail
 cmp qword [cell+NEBO_CELL_VERSION],2
 jne fail
 lea rdi,[tx]
 call nebo_transaction_commit
 cmp eax,NEBO_REACTIVE_STATUS_STATE
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
