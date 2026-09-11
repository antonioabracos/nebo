; RF46-G32-F04 failure-atomic local transaction and savepoint core.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/database/db_tx.inc"
section .text
NEBOC_ABI_FUNCTION nebo_db_tx_begin
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 test r8,r8
 jz .invalid
 cmp r8,NEBO_DB_TX_MAX_OPS
 ja .limit
 mov [rdi+NEBO_DB_TX_CURRENT],rsi
 mov [rdi+NEBO_DB_TX_SHADOW],rdx
 mov [rdi+NEBO_DB_TX_SAVE],rcx
 mov [rdi+NEBO_DB_TX_COUNT],r8
 mov qword [rdi+NEBO_DB_TX_ACTIVE],1
 mov qword [rdi+NEBO_DB_TX_HAS_SAVE],0
 xor eax,eax
.copy:
 cmp rax,r8
 jae .ok
 mov r9,[rsi+rax*8]
 mov [rdx+rax*8],r9
 inc rax
 jmp .copy
.ok:
 xor eax,eax
 ret
.invalid: mov eax,NEBO_DB_TX_INVALID
 ret
.limit: mov eax,NEBO_DB_TX_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_db_tx_set
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBO_DB_TX_ACTIVE],1
 jne .state
 cmp rsi,[rdi+NEBO_DB_TX_COUNT]
 jae .limit
 mov rax,[rdi+NEBO_DB_TX_SHADOW]
 mov [rax+rsi*8],rdx
 xor eax,eax
 ret
.invalid: mov eax,NEBO_DB_TX_INVALID
 ret
.state: mov eax,NEBO_DB_TX_STATE
 ret
.limit: mov eax,NEBO_DB_TX_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_db_tx_savepoint
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBO_DB_TX_ACTIVE],1
 jne .state
 mov rsi,[rdi+NEBO_DB_TX_SHADOW]
 mov rdx,[rdi+NEBO_DB_TX_SAVE]
 mov rcx,[rdi+NEBO_DB_TX_COUNT]
 xor eax,eax
.copy:
 cmp rax,rcx
 jae .done
 mov r8,[rsi+rax*8]
 mov [rdx+rax*8],r8
 inc rax
 jmp .copy
.done:
 mov qword [rdi+NEBO_DB_TX_HAS_SAVE],1
 xor eax,eax
 ret
.invalid: mov eax,NEBO_DB_TX_INVALID
 ret
.state: mov eax,NEBO_DB_TX_STATE
 ret

NEBOC_ABI_FUNCTION nebo_db_tx_rollback_savepoint
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBO_DB_TX_ACTIVE],1
 jne .state
 cmp qword [rdi+NEBO_DB_TX_HAS_SAVE],1
 jne .state
 mov rsi,[rdi+NEBO_DB_TX_SAVE]
 mov rdx,[rdi+NEBO_DB_TX_SHADOW]
 mov rcx,[rdi+NEBO_DB_TX_COUNT]
 xor eax,eax
.copy:
 cmp rax,rcx
 jae .done
 mov r8,[rsi+rax*8]
 mov [rdx+rax*8],r8
 inc rax
 jmp .copy
.done:
 xor eax,eax
 ret
.invalid: mov eax,NEBO_DB_TX_INVALID
 ret
.state: mov eax,NEBO_DB_TX_STATE
 ret

NEBOC_ABI_FUNCTION nebo_db_tx_commit
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBO_DB_TX_ACTIVE],1
 jne .state
 mov rsi,[rdi+NEBO_DB_TX_SHADOW]
 mov rdx,[rdi+NEBO_DB_TX_CURRENT]
 mov rcx,[rdi+NEBO_DB_TX_COUNT]
 xor eax,eax
.copy:
 cmp rax,rcx
 jae .done
 mov r8,[rsi+rax*8]
 mov [rdx+rax*8],r8
 inc rax
 jmp .copy
.done:
 mov qword [rdi+NEBO_DB_TX_ACTIVE],0
 xor eax,eax
 ret
.invalid: mov eax,NEBO_DB_TX_INVALID
 ret
.state: mov eax,NEBO_DB_TX_STATE
 ret

NEBOC_ABI_FUNCTION nebo_db_tx_abort
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBO_DB_TX_ACTIVE],1
 jne .state
 mov qword [rdi+NEBO_DB_TX_ACTIVE],0
 xor eax,eax
 ret
.invalid: mov eax,NEBO_DB_TX_INVALID
 ret
.state: mov eax,NEBO_DB_TX_STATE
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
