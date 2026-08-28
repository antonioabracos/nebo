; RF46-G45 bounded durable workflow operations example.
bits 64
default rel
%include "runtime/workflow/workflow.inc"
%include "runtime/workflow/workflow_ops.inc"
extern nebo_workflow_checksum
extern nebo_workflow_migrate
extern nebo_workflow_replay
section .data
record dq NEBO_WORKFLOW_MAGIC,1,1,0,0,0,0,0,0
events dq 2,3
section .bss
next_record resq 9
result resq 1
section .text
global _start
_start:
 lea rdi,[record]
 call nebo_workflow_checksum
 mov [record+64],rax
 lea rdi,[record]
 lea rsi,[next_record]
 mov edx,2
 mov ecx,1
 mov r8d,7
 call nebo_workflow_migrate
 test eax,eax
 jnz fail
 lea rdi,[events]
 mov esi,2
 mov edx,5
 lea rcx,[result]
 call nebo_workflow_replay
 test eax,eax
 jnz fail
 cmp qword [result],10
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
