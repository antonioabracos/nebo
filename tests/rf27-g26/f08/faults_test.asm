bits 64
default rel
%include "runtime/distributed/faults.inc"
extern nebo_fault_init,nebo_fault_next,nebo_checkpoint_apply
section .bss
state resb NEBO_FAULT_STATE_SIZE
init_req resb NEBO_FAULT_INIT_SIZE
next_req resb NEBO_FAULT_NEXT_SIZE
checkpoint_req resb nebo_faults_CHECKPOINT_SIZE
section .text
global _start
_start:
 lea rax,[state]
 mov [init_req+NEBO_FAULT_INIT_STATE],rax
 mov qword [init_req+NEBO_FAULT_INIT_CAPABILITY],0xcafe
 mov qword [init_req+NEBO_FAULT_INIT_RETRIES],2
 mov qword [init_req+NEBO_FAULT_INIT_DELAY],10
 mov qword [init_req+NEBO_FAULT_INIT_DEADLINE],100
 lea rdi,[init_req]
 call nebo_fault_init
 test eax,eax
 jnz fail
 lea rax,[state]
 mov [next_req+NEBO_FAULT_NEXT_STATE],rax
 mov qword [next_req+NEBO_FAULT_NEXT_CAPABILITY],0xcafe
 mov qword [next_req+NEBO_FAULT_NEXT_NOW],1
 mov qword [next_req+NEBO_FAULT_NEXT_SEED],7
 mov qword [next_req+NEBO_FAULT_NEXT_INJECTED],1
 lea rdi,[next_req]
 call nebo_fault_next
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_FAULT_ST_ATTEMPT],1
 jne fail
 lea rdi,[next_req]
 call nebo_fault_next
 test eax,eax
 jnz fail
 lea rdi,[next_req]
 call nebo_fault_next
 cmp eax,NEBO_FAULT_STATUS_RETRY_EXHAUSTED
 jne fail
 mov qword [next_req+NEBO_FAULT_NEXT_INJECTED],0
 lea rdi,[next_req]
 call nebo_fault_next
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_FAULT_ST_ATTEMPT],0
 jne fail
 mov qword [next_req+NEBO_FAULT_NEXT_INJECTED],1
 mov qword [next_req+NEBO_FAULT_NEXT_NOW],100
 lea rdi,[next_req]
 call nebo_fault_next
 cmp eax,NEBO_FAULT_STATUS_TIMEOUT
 jne fail
 lea rax,[state]
 mov [checkpoint_req+NEBO_CHECKPOINT_STATE],rax
 mov qword [checkpoint_req+NEBO_CHECKPOINT_CAPABILITY],0xcafe
 mov qword [checkpoint_req+NEBO_CHECKPOINT_VERSION],1
 mov qword [checkpoint_req+NEBO_CHECKPOINT_ID],1
 mov qword [checkpoint_req+NEBO_CHECKPOINT_DIGEST],0x1234
 mov qword [checkpoint_req+NEBO_CHECKPOINT_REPLICAS],3
 mov qword [checkpoint_req+NEBO_CHECKPOINT_QUORUM],2
 mov qword [checkpoint_req+NEBO_CHECKPOINT_COMPENSATION],NEBO_FAULT_COMP_PENDING
 lea rdi,[checkpoint_req]
 call nebo_checkpoint_apply
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_FAULT_ST_GENERATION],1
 jne fail
 lea rdi,[checkpoint_req]
 call nebo_checkpoint_apply
 cmp eax,NEBO_FAULT_STATUS_CHECKPOINT
 jne fail
 mov qword [checkpoint_req+NEBO_CHECKPOINT_ID],2
 mov qword [checkpoint_req+NEBO_CHECKPOINT_DIGEST],0
 lea rdi,[checkpoint_req]
 call nebo_checkpoint_apply
 cmp eax,NEBO_FAULT_STATUS_CHECKPOINT
 jne fail
 mov qword [checkpoint_req+NEBO_CHECKPOINT_DIGEST],0x5678
 mov qword [checkpoint_req+NEBO_CHECKPOINT_QUORUM],1
 lea rdi,[checkpoint_req]
 call nebo_checkpoint_apply
 cmp eax,NEBO_FAULT_STATUS_QUORUM
 jne fail
 mov qword [checkpoint_req+NEBO_CHECKPOINT_QUORUM],2
 mov qword [checkpoint_req+NEBO_CHECKPOINT_COMPENSATION],3
 lea rdi,[checkpoint_req]
 call nebo_checkpoint_apply
 cmp eax,NEBO_FAULT_STATUS_COMPENSATION
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail: mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
