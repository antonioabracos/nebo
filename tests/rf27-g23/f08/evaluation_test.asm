bits 64
default rel
%include "runtime/ai/evaluation.inc"
section .bss
state resq 7
report resq 4
section .text
global _start
_start:
 lea rdi,[rel state]
 mov rsi,0x1122
 mov rdx,0x3344
 call nebo_eval_init
 test eax,eax
 jne .f1
 lea rdi,[rel state]
 mov esi,1
 mov edx,100
 mov ecx,4096
 mov r8d,32
 call nebo_eval_record
 test eax,eax
 jne .f2
 lea rdi,[rel state]
 xor esi,esi
 mov edx,120
 mov ecx,2048
 mov r8d,16
 call nebo_eval_record
 test eax,eax
 jne .f3
 lea rdi,[rel state]
 lea rsi,[rel report]
 call nebo_eval_report
 test eax,eax
 jne .f4
 cmp qword [rel report],2
 jne .f5
 cmp qword [rel report+8],1
 jne .f6
 cmp qword [rel report+16],32768
 jne .f7
 cmp qword [rel report+24],48
 jne .f8
 lea rdi,[rel state]
 mov rsi,0x1122
 mov rdx,0x3344
 call nebo_eval_provenance
 test eax,eax
 jne .f9
 mov edi,1
 xor esi,esi
 call nebo_eval_policy_case
 cmp eax,NEBO_EVAL_E_POLICY
 jne .f10
 mov ecx,5000
.repeat:
 lea rdi,[rel state]
 mov rsi,0x1122
 mov rdx,0x3344
 mov r10,rcx
 call nebo_eval_provenance
 mov rcx,r10
 test eax,eax
 jne .f11
 loop .repeat
 xor edi,edi
 jmp .exit
%assign i 1
%rep 11
.f%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
