bits 64
default rel
%include "runtime/workflow/workflow.inc"
%include "runtime/workflow/workflow_ops.inc"
extern nebo_workflow_checksum
extern nebo_workflow_compatibility
extern nebo_workflow_migrate
extern nebo_workflow_replay
extern nebo_workflow_repair
section .data
record dq NEBO_WORKFLOW_MAGIC,77,3,0,1,0,100,40,0
events dq 1,2,3
section .bss
migrated resq 9
repaired resq 9
replay_result resq 1
section .text
global _start
_start:
 lea rdi,[record]
 call nebo_workflow_checksum
 mov [record+64],rax
 mov edi,3
 mov esi,4
 xor edx,edx
 call nebo_workflow_compatibility
 test eax,eax
 jnz fail
 lea rdi,[record]
 lea rsi,[migrated]
 mov edx,4
 mov ecx,5
 mov r8d,900
 call nebo_workflow_migrate
 test eax,eax
 jnz fail
 cmp qword [migrated+16],4
 jne fail
 cmp qword [migrated+24],1
 jne fail
 cmp qword [migrated+32],5
 jne fail
 lea rdi,[events]
 mov esi,3
 mov edx,10
 lea rcx,[replay_result]
 call nebo_workflow_replay
 test eax,eax
 jnz fail
 cmp qword [replay_result],16
 jne fail
 lea rdi,[migrated]
 lea rsi,[repaired]
 mov edx,9
 mov ecx,55
 call nebo_workflow_repair
 test eax,eax
 jnz fail
 cmp qword [repaired+24],2
 jne fail
 cmp qword [repaired+32],9
 jne fail
 test qword [repaired+40],NEBO_WORKFLOW_REPAIR_FLAG
 jz fail
 mov edi,3
 mov esi,4
 mov edx,1
 call nebo_workflow_compatibility
 cmp eax,NEBO_WORKFLOW_OPS_INCOMPATIBLE
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
