bits 64
default rel
%include "runtime/workflow/statechart.inc"
extern nebo_statechart_microstep
section .data
active dq 0x5,0x2
exits dq 0x1,0x2
enters dq 0x8,0x4
bad_exits dq 0x20,0
section .bss
result resq 3
section .text
global _start
_start:
 lea rdi,[active]
 lea rsi,[exits]
 lea rdx,[enters]
 mov ecx,2
 lea r8,[result]
 call nebo_statechart_microstep
 test eax,eax
 jnz fail
 cmp qword [result],0xc
 jne fail
 cmp qword [result+8],4
 jne fail
 cmp qword [result+16],NEBO_STATECHART_ORDER_EXIT_ACTION_ENTRY
 jne fail
 lea rsi,[bad_exits]
 mov ecx,2
 call nebo_statechart_microstep
 cmp eax,NEBO_STATECHART_EXIT_NOT_ACTIVE
 jne fail
 cmp qword [result],0xc
 jne fail
 mov ecx,9
 call nebo_statechart_microstep
 cmp eax,NEBO_STATECHART_LIMIT
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
