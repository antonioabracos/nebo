bits 64
default rel
%include "runtime/ai/generation.inc"
section .data
logits dq -5,7,1,20
section .bss
state resq 4
sample resq 1
section .text
global _start
_start:
 lea rdi,[rel logits]
 mov esi,4
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 lea r9,[rel sample]
 call nebo_sample
 test eax,eax
 jne .f1
 cmp qword [rel sample],3
 jne .f2
 lea rdi,[rel logits]
 mov esi,4
 mov edx,NEBO_GEN_MODE_TOPK
 mov ecx,2
 mov r8d,1
 lea r9,[rel sample]
 call nebo_sample
 test eax,eax
 jne .f3
 cmp qword [rel sample],2
 jne .f4
 lea rdi,[rel logits]
 mov esi,4
 mov edx,NEBO_GEN_MODE_TOPP
 mov ecx,32768
 mov r8d,0
 lea r9,[rel sample]
 call nebo_sample
 test eax,eax
 jne .f5
 cmp qword [rel sample],3
 jne .f6
 lea rdi,[rel logits]
 mov esi,4
 mov edx,NEBO_GEN_MODE_REPETITION
 mov ecx,3
 xor r8d,r8d
 lea r9,[rel sample]
 call nebo_sample
 test eax,eax
 jne .f7
 cmp qword [rel sample],1
 jne .f8
 lea rdi,[rel state]
 mov esi,64
 mov edx,12345
 call nebo_generator_begin
 test eax,eax
 jne .f9
 lea rdi,[rel state]
 lea rsi,[rel sample]
 call nebo_generator_next
 test eax,eax
 jne .f10
 cmp qword [rel sample],0
 jne .f11
 lea rdi,[rel state]
 call nebo_generator_cancel
 test eax,eax
 jne .f12
 lea rdi,[rel state]
 lea rsi,[rel sample]
 call nebo_generator_next
 cmp eax,NEBO_GEN_E_CANCELLED
 jne .f13
 mov ecx,5000
.repeat:
 lea rdi,[rel logits]
 mov esi,4
 mov edx,NEBO_GEN_MODE_TOPK
 mov r10,rcx
 mov ecx,4
 mov r8,r10
 lea r9,[rel sample]
 call nebo_sample
 mov rcx,r10
 test eax,eax
 jne .f14
 cmp qword [rel sample],0
 jb .f15
 cmp qword [rel sample],3
 ja .f15
 loop .repeat
 xor edi,edi
 jmp .exit
%assign i 1
%rep 15
.f%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
