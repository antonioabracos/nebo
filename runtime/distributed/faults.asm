; PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-F08 finite retry/checkpoint/compensation state.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/distributed/faults.inc"
section .text
NEBOC_ABI_FUNCTION nebo_fault_init
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_FAULT_INIT_RESULT],0
 mov rsi,[rdi+NEBO_FAULT_INIT_STATE]
 test rsi,rsi
 jz .bad
 cmp qword [rdi+NEBO_FAULT_INIT_CAPABILITY],0
 je .cap
 cmp qword [rdi+NEBO_FAULT_INIT_RETRIES],1
 jb .limit
 cmp qword [rdi+NEBO_FAULT_INIT_RETRIES],NEBO_FAULT_MAX_RETRIES
 ja .limit
 cmp qword [rdi+NEBO_FAULT_INIT_DELAY],1
 jb .limit
 cmp qword [rdi+NEBO_FAULT_INIT_DELAY],NEBO_FAULT_MAX_DELAY
 ja .limit
 cmp qword [rdi+NEBO_FAULT_INIT_DEADLINE],0
 je .limit
 mov r8,rdi
 mov rdi,rsi
 mov ecx,NEBO_FAULT_STATE_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,NEBO_FAULT_MAGIC
 mov [rsi+NEBO_FAULT_ST_MAGIC],rax
 mov rax,[r8+NEBO_FAULT_INIT_CAPABILITY]
 mov [rsi+NEBO_FAULT_ST_CAPABILITY],rax
 mov rax,[r8+NEBO_FAULT_INIT_RETRIES]
 mov [rsi+NEBO_FAULT_ST_MAX_RETRIES],rax
 mov rax,[r8+NEBO_FAULT_INIT_DELAY]
 mov [rsi+NEBO_FAULT_ST_BASE_DELAY],rax
 mov rax,[r8+NEBO_FAULT_INIT_DEADLINE]
 mov [rsi+NEBO_FAULT_ST_DEADLINE],rax
 mov qword [r8+NEBO_FAULT_INIT_RESULT],1
 xor eax,eax
 ret
.cap: mov eax,NEBO_FAULT_STATUS_CAPABILITY
 ret
.limit: mov eax,NEBO_FAULT_STATUS_LIMIT
 ret
.bad: mov eax,NEBO_FAULT_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_fault_next
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_FAULT_NEXT_RESULT],0
 mov rsi,[rdi+NEBO_FAULT_NEXT_STATE]
 test rsi,rsi
 jz .bad
 mov rax,[rdi+NEBO_FAULT_NEXT_CAPABILITY]
 cmp [rsi+NEBO_FAULT_ST_CAPABILITY],rax
 jne .cap
 cmp qword [rdi+NEBO_FAULT_NEXT_INJECTED],0
 je .success
 mov rax,[rdi+NEBO_FAULT_NEXT_NOW]
 cmp rax,[rsi+NEBO_FAULT_ST_DEADLINE]
 jae .timeout
 mov rax,[rsi+NEBO_FAULT_ST_ATTEMPT]
 cmp rax,[rsi+NEBO_FAULT_ST_MAX_RETRIES]
 jae .exhausted
 inc rax
 mov [rsi+NEBO_FAULT_ST_ATTEMPT],rax
 imul rax,rax,1103515245
 add rax,[rdi+NEBO_FAULT_NEXT_SEED]
 and rax,255
 add rax,[rsi+NEBO_FAULT_ST_BASE_DELAY]
 cmp rax,NEBO_FAULT_MAX_DELAY
 jbe .delay_ok
 mov eax,NEBO_FAULT_MAX_DELAY
.delay_ok:
 mov [rdi+NEBO_FAULT_NEXT_RESULT],rax
 xor eax,eax
 ret
.success:
 mov qword [rsi+NEBO_FAULT_ST_ATTEMPT],0
 mov qword [rdi+NEBO_FAULT_NEXT_RESULT],1
 xor eax,eax
 ret
.cap: mov eax,NEBO_FAULT_STATUS_CAPABILITY
 ret
.timeout: mov eax,NEBO_FAULT_STATUS_TIMEOUT
 ret
.exhausted: mov eax,NEBO_FAULT_STATUS_RETRY_EXHAUSTED
 ret
.bad: mov eax,NEBO_FAULT_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_checkpoint_apply
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_CHECKPOINT_RESULT],0
 mov rsi,[rdi+NEBO_CHECKPOINT_STATE]
 test rsi,rsi
 jz .bad
 mov rax,[rdi+NEBO_CHECKPOINT_CAPABILITY]
 cmp [rsi+NEBO_FAULT_ST_CAPABILITY],rax
 jne .cap
 cmp qword [rdi+NEBO_CHECKPOINT_VERSION],NEBO_FAULT_VERSION
 jne .version
 mov r8,[rdi+NEBO_CHECKPOINT_ID]
 test r8,r8
 jz .checkpoint
 cmp r8,[rsi+NEBO_FAULT_ST_CHECKPOINT]
 jbe .checkpoint
 mov r9,[rdi+NEBO_CHECKPOINT_DIGEST]
 test r9,r9
 jz .checkpoint
 mov r10,[rdi+NEBO_CHECKPOINT_REPLICAS]
 cmp r10,1
 jb .quorum
 cmp r10,NEBO_FAULT_MAX_REPLICAS
 ja .quorum
 mov r11,[rdi+NEBO_CHECKPOINT_QUORUM]
 test r11,r11
 jz .quorum
 cmp r11,r10
 ja .quorum
 mov rax,r10
 shr rax,1
 inc rax
 cmp r11,rax
 jb .quorum
 mov rax,[rdi+NEBO_CHECKPOINT_COMPENSATION]
 cmp rax,NEBO_FAULT_COMP_APPLIED
 ja .compensation
 mov [rsi+NEBO_FAULT_ST_CHECKPOINT],r8
 mov [rsi+NEBO_FAULT_ST_DIGEST],r9
 mov [rsi+NEBO_FAULT_ST_REPLICAS],r10
 mov [rsi+NEBO_FAULT_ST_QUORUM],r11
 mov [rsi+NEBO_FAULT_ST_COMPENSATION],rax
 inc qword [rsi+NEBO_FAULT_ST_GENERATION]
 mov qword [rdi+NEBO_CHECKPOINT_RESULT],1
 xor eax,eax
 ret
.cap: mov eax,NEBO_FAULT_STATUS_CAPABILITY
 ret
.checkpoint: mov eax,NEBO_FAULT_STATUS_CHECKPOINT
 ret
.quorum: mov eax,NEBO_FAULT_STATUS_QUORUM
 ret
.compensation: mov eax,NEBO_FAULT_STATUS_COMPENSATION
 ret
.version: mov eax,NEBO_FAULT_STATUS_VERSION
 ret
.bad: mov eax,NEBO_FAULT_STATUS_INVALID
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
