; MEDIA-IMAGEM-AUDIO-E-VIDEO-F01 bounded cells and failure-atomic reactive transactions.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/reactive/transaction.inc"
section .text
NEBOC_ABI_FUNCTION nebo_cell_init
 test rdi,rdi
 jz .invalid_cell
 mov [rdi+NEBO_CELL_VALUE],rsi
 mov qword [rdi+NEBO_CELL_VERSION],1
 xor eax,eax
 ret
.invalid_cell: mov eax,NEBO_REACTIVE_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_transaction_init
 test rdi,rdi
 jz .invalid_tx
 mov qword [rdi+NEBO_TX_ENTRIES],0
 mov qword [rdi+NEBO_TX_CAPACITY],0
 mov qword [rdi+NEBO_TX_COUNT],0
 mov qword [rdi+NEBO_TX_ACTIVE],0
 test rsi,rsi
 jz .invalid_tx
 test rdx,rdx
 jz .invalid_tx
 cmp rdx,NEBO_REACTIVE_MAX_CHANGED_CELLS
 ja .limit_tx
 mov [rdi+NEBO_TX_ENTRIES],rsi
 mov [rdi+NEBO_TX_CAPACITY],rdx
 mov qword [rdi+NEBO_TX_ACTIVE],1
 xor eax,eax
 ret
.invalid_tx: mov eax,NEBO_REACTIVE_STATUS_INVALID
 ret
.limit_tx: mov eax,NEBO_REACTIVE_STATUS_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_transaction_set
 ; transaction, cell, pending value
 test rdi,rdi
 jz .invalid_set
 test rsi,rsi
 jz .invalid_set
 cmp qword [rdi+NEBO_TX_ACTIVE],1
 jne .state_set
 mov r8,[rdi+NEBO_TX_ENTRIES]
 mov rcx,[rdi+NEBO_TX_COUNT]
 xor eax,eax
.scan:
 cmp rax,rcx
 jae .append
 mov r9,rax
 imul r9,NEBO_TX_ENTRY_SIZE
 cmp [r8+r9+NEBO_TX_ENTRY_CELL],rsi
 je .replace
 inc rax
 jmp .scan
.replace:
 mov [r8+r9+NEBO_TX_ENTRY_PENDING],rdx
 xor eax,eax
 ret
.append:
 cmp rcx,[rdi+NEBO_TX_CAPACITY]
 jae .limit_set
 mov r9,rcx
 imul r9,NEBO_TX_ENTRY_SIZE
 mov [r8+r9+NEBO_TX_ENTRY_CELL],rsi
 mov rax,[rsi+NEBO_CELL_VALUE]
 mov [r8+r9+NEBO_TX_ENTRY_ORIGINAL],rax
 mov [r8+r9+NEBO_TX_ENTRY_PENDING],rdx
 inc rcx
 mov [rdi+NEBO_TX_COUNT],rcx
 xor eax,eax
 ret
.invalid_set: mov eax,NEBO_REACTIVE_STATUS_INVALID
 ret
.state_set: mov eax,NEBO_REACTIVE_STATUS_STATE
 ret
.limit_set: mov eax,NEBO_REACTIVE_STATUS_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_transaction_commit
 test rdi,rdi
 jz .invalid_commit
 cmp qword [rdi+NEBO_TX_ACTIVE],1
 jne .state_commit
 mov r8,[rdi+NEBO_TX_ENTRIES]
 mov rcx,[rdi+NEBO_TX_COUNT]
 xor eax,eax
.commit_loop:
 cmp rax,rcx
 jae .commit_done
 mov r9,rax
 imul r9,NEBO_TX_ENTRY_SIZE
 mov r10,[r8+r9+NEBO_TX_ENTRY_CELL]
 mov r11,[r8+r9+NEBO_TX_ENTRY_PENDING]
 mov [r10+NEBO_CELL_VALUE],r11
 inc qword [r10+NEBO_CELL_VERSION]
 inc rax
 jmp .commit_loop
.commit_done:
 mov qword [rdi+NEBO_TX_ACTIVE],0
 xor eax,eax
 ret
.invalid_commit: mov eax,NEBO_REACTIVE_STATUS_INVALID
 ret
.state_commit: mov eax,NEBO_REACTIVE_STATUS_STATE
 ret

NEBOC_ABI_FUNCTION nebo_transaction_rollback
 test rdi,rdi
 jz .invalid_rollback
 cmp qword [rdi+NEBO_TX_ACTIVE],1
 jne .state_rollback
 mov qword [rdi+NEBO_TX_COUNT],0
 mov qword [rdi+NEBO_TX_ACTIVE],0
 xor eax,eax
 ret
.invalid_rollback: mov eax,NEBO_REACTIVE_STATUS_INVALID
 ret
.state_rollback: mov eax,NEBO_REACTIVE_STATUS_STATE
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
