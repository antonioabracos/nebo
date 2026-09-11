bits 64
default rel
%include "compiler/verification/report.inc"
extern nebo_verification_report_init,nebo_verification_report_add,nebo_counterexample_minimize,nebo_counterexample_replay
section .data
trace dq 0,0,1,1,2
transitions dq 2,4,0
bad_trace dq 0,2
section .bss
report resb NEBO_REPORT_SIZE
minimal resq 5
written resq 1
section .text
global _start
_start:
 lea rdi,[report]
 call nebo_verification_report_init
 test eax,eax
 jnz fail
 lea rdi,[report]
 mov esi,NEBO_REPORT_STATE_PROVED
 call nebo_verification_report_add
 test eax,eax
 jnz fail
 cmp qword [report],1
 jne fail
 lea rdi,[trace]
 mov esi,5
 lea rdx,[minimal]
 mov ecx,5
 lea r8,[written]
 call nebo_counterexample_minimize
 test eax,eax
 jnz fail
 cmp qword [written],3
 jne fail
 lea rdi,[transitions]
 mov esi,3
 lea rdx,[minimal]
 mov rcx,[written]
 call nebo_counterexample_replay
 test eax,eax
 jnz fail
 lea rdi,[transitions]
 mov esi,3
 lea rdx,[bad_trace]
 mov ecx,2
 call nebo_counterexample_replay
 cmp eax,NEBO_REPORT_STATUS_REPLAY
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
