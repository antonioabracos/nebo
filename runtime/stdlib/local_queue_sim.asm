; Local deterministic queue/failure simulation. No sockets, broker or cluster.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "runtime/stdlib/local_queue_sim.inc"
section .text
NEBOC_ABI_FUNCTION neboc_local_queue_simulate
 test rdi,rdi
 jz .arg
 test rdi,7
 jnz .arg
 mov qword [rdi+DIAG],0
 mov qword [rdi+RESULT],0
 mov rax,[rdi+local_queue_sim_CAPACITY]
 test rax,rax
 jz .type
 cmp rax,64
 ja .type
 cmp [rdi+QUEUE_LEN],rax
 ja .runtime
 mov rax,[rdi+RETRY_BUDGET]
 cmp rax,8
 ja .type
 cmp [rdi+RETRIES],rax
 ja .runtime
 mov rax,[rdi+TIMEOUT]
 test rax,rax
 jz .type
 cmp [rdi+ELAPSED],rax
 ja .runtime
 cmp qword [rdi+ACK],1
 jne .runtime
 cmp qword [rdi+CLEANUP],1
 jne .security
 mov rax,SEAL_MAGIC
 xor edx,edx
 mov ecx,12
.seal: xor rax,[rdi+rdx*8]
 inc edx
 loop .seal
 cmp rax,[rdi+SEAL]
 jne .security
 mov rax,[rdi+SEQ]
 cmp rax,[rdi+EXPECTED]
 je .ordered
 jb .duplicate
 cmp qword [rdi+LOSSES],0
 je .runtime
 cmp qword [rdi+RETRIES],0
 je .runtime
 mov qword [rdi+RESULT],RESULT_LOSS_RETRIED
 jmp .ok
.duplicate:
 cmp qword [rdi+DUPLICATES],0
 je .runtime
 mov qword [rdi+RESULT],RESULT_DUPLICATE_DROPPED
 jmp .ok
.ordered:
 cmp qword [rdi+DUPLICATES],0
 jne .type
 cmp qword [rdi+LOSSES],0
 jne .type
 mov qword [rdi+RESULT],RESULT_ORDERED
.ok: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.type: mov eax,DIAG_TYPE
 jmp .fail
.runtime: mov eax,DIAG_RUNTIME
 jmp .fail
.security: mov eax,DIAG_SECURITY
.fail: mov [rdi+DIAG],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
section .note.GNU-stack noalloc noexec nowrite progbits
