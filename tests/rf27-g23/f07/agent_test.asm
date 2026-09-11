bits 64
default rel
%include "runtime/agent/agent.inc"
section .bss
state resq 8
outv resq 1
section .text
global _start
_start:
 lea rdi,[rel state]
 mov esi,16
 mov edx,8
 mov ecx,8
 call nebo_agent_begin
 test eax,eax
 jne .f1
 lea rdi,[rel state]
 call nebo_agent_approve
 test eax,eax
 jne .f2
 lea rdi,[rel state]
 mov esi,1
 xor edx,edx
 mov ecx,1
 mov r8d,100
 call nebo_agent_step
 cmp eax,NEBO_AGENT_E_APPROVAL
 jne .f3
 cmp qword [rel state],0
 jne .f4
 lea rdi,[rel state]
 mov esi,1
 mov edx,1
 mov ecx,1
 mov r8d,100
 call nebo_agent_step
 test eax,eax
 jne .f5
 cmp qword [rel state],1
 jne .f6
 cmp qword [rel state+16],1
 jne .f7
 lea rdi,[rel state]
 xor esi,esi
 lea rdx,[rel outv]
 call nebo_agent_rollback
 cmp eax,NEBO_AGENT_E_UNCOMPENSATED
 jne .f8
 lea rdi,[rel state]
 mov esi,1
 lea rdx,[rel outv]
 call nebo_agent_rollback
 test eax,eax
 jne .f9
 cmp qword [rel outv],1
 jne .f10
 lea rdi,[rel state]
 call nebo_agent_cancel
 test eax,eax
 jne .f11
 lea rdi,[rel state]
 xor esi,esi
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 call nebo_agent_step
 cmp eax,NEBO_AGENT_E_CANCELLED
 jne .f12
 cmp qword [rel state],1
 jne .f13
 mov ecx,5000
.repeat:
 lea rdi,[rel state]
 mov esi,1
 lea rdx,[rel outv]
 mov r10,rcx
 call nebo_agent_rollback
 mov rcx,r10
 test eax,eax
 jne .f14
 loop .repeat
 xor edi,edi
 jmp .exit
%assign i 1
%rep 14
.f%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
