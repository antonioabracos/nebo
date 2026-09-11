bits 64
default rel
%include "runtime/agent/tools.inc"
section .bss
registry resq 34
callv resq 7
outv resq 1
section .text
global _start
_start:
 lea rdi,[rel registry]
 call nebo_tool_registry_init
 test eax,eax
 jne .f1
 lea rdi,[rel registry]
 mov esi,1
 mov edx,0x10
 call nebo_tool_register
 test eax,eax
 jne .f2
 mov qword [rel callv],1
 mov qword [rel callv+8],0x10
 mov qword [rel callv+16],1
 mov qword [rel callv+24],16
 mov qword [rel callv+32],7
 mov qword [rel callv+40],9
 lea rdi,[rel registry]
 lea rsi,[rel callv]
 call nebo_tool_call
 test eax,eax
 jne .f3
 cmp qword [rel callv+48],16
 jne .f4
 cmp qword [rel registry+8],1
 jne .f5
 mov qword [rel callv+16],0
 lea rdi,[rel registry]
 lea rsi,[rel callv]
 call nebo_tool_call
 cmp eax,NEBO_TOOL_E_DENIED
 jne .f6
 cmp qword [rel registry+8],1
 jne .f7
 mov qword [rel callv],99
 mov qword [rel callv+16],1
 lea rdi,[rel registry]
 lea rsi,[rel callv]
 call nebo_tool_call
 cmp eax,NEBO_TOOL_E_UNKNOWN
 jne .f8
 lea rdi,[rel registry]
 lea rsi,[rel outv]
 call nebo_tool_remaining
 test eax,eax
 jne .f9
 cmp qword [rel outv],7
 jne .f10
 mov ecx,5000
.repeat:
 lea rdi,[rel registry]
 lea rsi,[rel outv]
 mov r10,rcx
 call nebo_tool_remaining
 mov rcx,r10
 test eax,eax
 jne .f11
 cmp qword [rel outv],7
 jne .f12
 loop .repeat
 xor edi,edi
 jmp .exit
%assign i 1
%rep 12
.f%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
