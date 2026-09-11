bits 64
default rel
%include "runtime/workflow/workflow.inc"
extern nebo_workflow_checksum
extern nebo_workflow_resume
extern nebo_workflow_checkpoint
section .data
record dq NEBO_WORKFLOW_MAGIC,77,3,0,1,0,100,40,0
section .bss
saved resq 9
section .text
global _start
_start:
 lea rdi,[record]
 call nebo_workflow_checksum
 mov [record+64],rax
 lea rdi,[record]
 mov esi,3
 call nebo_workflow_resume
 test eax,eax
 jnz fail
 lea rdi,[record]
 lea rsi,[saved]
 xor edx,edx
 mov ecx,2
 mov r8d,200
 mov r9d,41
 call nebo_workflow_checkpoint
 test eax,eax
 jnz fail
 cmp qword [saved+24],1
 jne fail
 cmp qword [saved+32],2
 jne fail
 lea rdi,[saved]
 mov esi,3
 call nebo_workflow_resume
 test eax,eax
 jnz fail
 lea rdi,[saved]
 lea rsi,[record]
 mov edx,1
 mov ecx,3
 mov r8d,300
 mov r9d,41
 call nebo_workflow_checkpoint
 cmp eax,NEBO_WORKFLOW_DUPLICATE
 jne fail
 mov byte [saved+8],99
 lea rdi,[saved]
 mov esi,3
 call nebo_workflow_resume
 cmp eax,NEBO_WORKFLOW_CHECKSUM
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
