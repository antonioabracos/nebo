; GPU-E-COMPUTACAO-ACELERADA-F05 bounded resumable sync session planner.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/replication/sync.inc"
section .text
NEBOC_ABI_FUNCTION nebo_sync_plan_batch
 ; total_changes,total_bytes,acked,max_batch,out_send,out_resume
 cmp rdi,NEBO_SYNC_MAX_CHANGES
 ja .limit
 cmp rsi,NEBO_SYNC_MAX_BYTES
 ja .limit
 cmp rdx,rdi
 ja .invalid
 test rcx,rcx
 jz .limit
 cmp rcx,NEBO_SYNC_MAX_BATCH
 ja .limit
 test r8,r8
 jz .invalid
 test r9,r9
 jz .invalid
 mov rax,rdi
 sub rax,rdx
 cmp rax,rcx
 jbe .size
 mov rax,rcx
.size:
 mov [r8],rax
 add rdx,rax
 mov [r9],rdx
 xor eax,eax
 ret
.invalid: mov eax,NEBO_SYNC_INVALID
 ret
.limit: mov eax,NEBO_SYNC_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
