; CONSOLE-VISUAL-DASHBOARD-E-PLOTS-F06 incremental contexts, cancellation, checkpoints and unsat cores.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/solver/incremental.inc"
section .text
NEBOC_ABI_FUNCTION nebo_incremental_init
 test rdi,rdi
 jz .invalid_init
 test rsi,rsi
 jz .invalid_init
 mov [rdi+NEBO_INCREMENTAL_STATE_MARKS],rsi
 mov qword [rdi+NEBO_INCREMENTAL_STATE_DEPTH],0
 mov qword [rdi+NEBO_INCREMENTAL_STATE_CONSTRAINTS],0
 mov [rdi+NEBO_INCREMENTAL_STATE_GENERATION],rdx
 mov qword [rdi+NEBO_INCREMENTAL_STATE_CANCELLED],0
 xor eax,eax
 ret
.invalid_init: mov eax,NEBO_INCREMENTAL_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_incremental_push
 test rdi,rdi
 jz .invalid_push
 mov rax,[rdi+NEBO_INCREMENTAL_STATE_DEPTH]
 cmp rax,NEBO_INCREMENTAL_MAX_DEPTH
 jae .limit_push
 mov rdx,[rdi+NEBO_INCREMENTAL_STATE_MARKS]
 mov rcx,[rdi+NEBO_INCREMENTAL_STATE_CONSTRAINTS]
 mov [rdx+rax*8],rcx
 inc rax
 mov [rdi+NEBO_INCREMENTAL_STATE_DEPTH],rax
 xor eax,eax
 ret
.invalid_push: mov eax,NEBO_INCREMENTAL_STATUS_INVALID
 ret
.limit_push: mov eax,NEBO_INCREMENTAL_STATUS_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_incremental_add
 test rdi,rdi
 jz .invalid_add
 test rsi,rsi
 jz .invalid_add
 add [rdi+NEBO_INCREMENTAL_STATE_CONSTRAINTS],rsi
 jc .limit_add
 xor eax,eax
 ret
.invalid_add: mov eax,NEBO_INCREMENTAL_STATUS_INVALID
 ret
.limit_add: sub [rdi+NEBO_INCREMENTAL_STATE_CONSTRAINTS],rsi
 mov eax,NEBO_INCREMENTAL_STATUS_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_incremental_pop
 test rdi,rdi
 jz .invalid_pop
 mov rax,[rdi+NEBO_INCREMENTAL_STATE_DEPTH]
 test rax,rax
 jz .empty_pop
 dec rax
 mov rdx,[rdi+NEBO_INCREMENTAL_STATE_MARKS]
 mov rcx,[rdx+rax*8]
 mov [rdi+NEBO_INCREMENTAL_STATE_CONSTRAINTS],rcx
 mov [rdi+NEBO_INCREMENTAL_STATE_DEPTH],rax
 xor eax,eax
 ret
.invalid_pop: mov eax,NEBO_INCREMENTAL_STATUS_INVALID
 ret
.empty_pop: mov eax,NEBO_INCREMENTAL_STATUS_EMPTY
 ret

NEBOC_ABI_FUNCTION nebo_incremental_cancel
 test rdi,rdi
 jz .invalid_cancel
 mov qword [rdi+NEBO_INCREMENTAL_STATE_CANCELLED],1
 xor eax,eax
 ret
.invalid_cancel: mov eax,NEBO_INCREMENTAL_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_incremental_checkpoint
 ; state, checkpoint output
 test rsi,rsi
 jz .invalid_checkpoint
 mov qword [rsi],0
 mov qword [rsi+8],0
 mov qword [rsi+16],0
 mov qword [rsi+24],0
 test rdi,rdi
 jz .invalid_checkpoint
 cmp qword [rdi+NEBO_INCREMENTAL_STATE_CANCELLED],0
 jne .cancelled_checkpoint
 mov rax,[rdi+NEBO_INCREMENTAL_STATE_GENERATION]
 mov [rsi+NEBO_CHECKPOINT_GENERATION],rax
 mov rcx,[rdi+NEBO_INCREMENTAL_STATE_CONSTRAINTS]
 mov [rsi+NEBO_CHECKPOINT_CONSTRAINTS],rcx
 mov rdx,[rdi+NEBO_INCREMENTAL_STATE_DEPTH]
 mov [rsi+NEBO_CHECKPOINT_DEPTH],rdx
 rol rax,13
 xor rax,rcx
 rol rax,17
 xor rax,rdx
 test rax,rax
 jnz .hash_ok
 mov eax,1
.hash_ok: mov [rsi+NEBO_CHECKPOINT_HASH],rax
 xor eax,eax
 ret
.invalid_checkpoint: mov eax,NEBO_INCREMENTAL_STATUS_INVALID
 ret
.cancelled_checkpoint: mov eax,NEBO_INCREMENTAL_STATUS_CANCELLED
 ret

NEBOC_ABI_FUNCTION nebo_incremental_resume_validate
 ; checkpoint, expected generation
 test rdi,rdi
 jz .invalid_resume
 cmp [rdi+NEBO_CHECKPOINT_GENERATION],rsi
 jne .checkpoint_bad
 cmp qword [rdi+NEBO_CHECKPOINT_HASH],0
 je .checkpoint_bad
 cmp qword [rdi+NEBO_CHECKPOINT_DEPTH],NEBO_INCREMENTAL_MAX_DEPTH
 ja .checkpoint_bad
 xor eax,eax
 ret
.invalid_resume: mov eax,NEBO_INCREMENTAL_STATUS_INVALID
 ret
.checkpoint_bad: mov eax,NEBO_INCREMENTAL_STATUS_CHECKPOINT
 ret

NEBOC_ABI_FUNCTION nebo_solver_unsat_core
 ; required mask, forbidden mask, output conflict mask
 test rdx,rdx
 jz .invalid_core
 mov qword [rdx],0
 and rdi,rsi
 jz .not_unsat
 mov [rdx],rdi
 xor eax,eax
 ret
.invalid_core: mov eax,NEBO_INCREMENTAL_STATUS_INVALID
 ret
.not_unsat: mov eax,NEBO_INCREMENTAL_STATUS_UNSAT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
