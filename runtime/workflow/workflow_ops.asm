; OBSERVABILIDADE-EXPLAIN-DEBUG-SIMULACAO-E-EVOLUCAO-F07 version migration, deterministic replay, and audited repair.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/workflow/workflow.inc"
%include "runtime/workflow/workflow_ops.inc"
extern nebo_workflow_checksum
section .text
NEBOC_ABI_FUNCTION nebo_workflow_compatibility
 ; current_version,target_version,removed_active_step
 cmp rsi,rdi
 jb .incompatible
 test rdx,rdx
 jnz .incompatible
 xor eax,eax
 ret
.incompatible: mov eax,NEBO_WORKFLOW_OPS_INCOMPATIBLE
 ret

NEBOC_ABI_FUNCTION nebo_workflow_migrate
 ; source,out,target_version,new_step,plan_id
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test r8,r8
 jz .invalid
 cmp rdx,[rdi+16]
 jbe .incompatible
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call nebo_workflow_checksum
 cmp rax,[r12+64]
 jne .checksum_pushed
 xor ebx,ebx
.copy:
 cmp ebx,8
 jae .copied
 mov rax,[r12+rbx*8]
 mov [r13+rbx*8],rax
 inc ebx
 jmp .copy
.copied:
 mov [r13+16],r14
 inc qword [r13+24]
 mov [r13+32],r15
 mov rdi,r13
 call nebo_workflow_checksum
 mov [r13+64],rax
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 xor eax,eax
 ret
.checksum_pushed:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 mov eax,NEBO_WORKFLOW_OPS_CHECKSUM
 ret
.invalid: mov eax,NEBO_WORKFLOW_OPS_INVALID
 ret
.incompatible: mov eax,NEBO_WORKFLOW_OPS_INCOMPATIBLE
 ret

NEBOC_ABI_FUNCTION nebo_workflow_replay
 ; event_deltas,count,seed,out
 test rdi,rdi
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp rsi,NEBO_WORKFLOW_REPLAY_MAX_EVENTS
 ja .limit
 mov rax,rdx
 xor r8d,r8d
.replay:
 cmp r8,rsi
 jae .replayed
 add rax,[rdi+r8*8]
 inc r8
 jmp .replay
.replayed:
 mov [rcx],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBO_WORKFLOW_OPS_INVALID
 ret
.limit: mov eax,NEBO_WORKFLOW_OPS_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_workflow_repair
 ; source,out,new_step,audit_action
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rcx,rcx
 jz .invalid
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call nebo_workflow_checksum
 cmp rax,[r12+64]
 jne .checksum_repair
 xor ecx,ecx
.repair_copy:
 cmp ecx,8
 jae .repair_copied
 mov rax,[r12+rcx*8]
 mov [r13+rcx*8],rax
 inc ecx
 jmp .repair_copy
.repair_copied:
 inc qword [r13+24]
 mov [r13+32],r14
 or qword [r13+40],NEBO_WORKFLOW_REPAIR_FLAG
 mov rdi,r13
 call nebo_workflow_checksum
 mov [r13+64],rax
 pop r14
 pop r13
 pop r12
 xor eax,eax
 ret
.checksum_repair:
 pop r14
 pop r13
 pop r12
 mov eax,NEBO_WORKFLOW_OPS_CHECKSUM
 ret
.invalid: mov eax,NEBO_WORKFLOW_OPS_INVALID
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
