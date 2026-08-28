; Native composition example: transaction publication feeds a bounded computed node.
bits 64
default rel
%include "runtime/reactive/transaction.inc"
%include "runtime/reactive/computed.inc"
extern nebo_cell_init,nebo_transaction_init,nebo_transaction_set,nebo_transaction_commit
extern nebo_computed_init,nebo_computed_add_dependency,nebo_computed_invalidate,nebo_computed_recompute_sum
section .bss
cell resb nebo_transaction_CELL_SIZE
tx resb NEBO_TX_SIZE
entries resb NEBO_TX_ENTRY_SIZE
node resb NEBO_COMPUTED_SIZE
report resb NEBO_COMPUTED_REPORT_SIZE
inputs resq 1
section .text
global _start
_start:
 lea rdi,[cell]
 mov esi,5
 call nebo_cell_init
 test eax,eax
 jnz fail
 lea rdi,[tx]
 lea rsi,[entries]
 mov edx,1
 call nebo_transaction_init
 test eax,eax
 jnz fail
 lea rdi,[tx]
 lea rsi,[cell]
 mov edx,7
 call nebo_transaction_set
 test eax,eax
 jnz fail
 lea rdi,[tx]
 call nebo_transaction_commit
 test eax,eax
 jnz fail
 lea rdi,[node]
 xor esi,esi
 call nebo_computed_init
 test eax,eax
 jnz fail
 lea rdi,[node]
 xor esi,esi
 call nebo_computed_add_dependency
 test eax,eax
 jnz fail
 lea rdi,[node]
 mov esi,1
 call nebo_computed_invalidate
 test eax,eax
 jnz fail
 mov rax,[cell+NEBO_CELL_VALUE]
 mov [inputs],rax
 lea rdi,[node]
 lea rsi,[inputs]
 mov edx,1
 lea rcx,[report]
 call nebo_computed_recompute_sum
 test eax,eax
 jnz fail
 cmp qword [node+NEBO_COMPUTED_VALUE],7
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
