bits 64
default rel
%include "runtime/reactive/delta.inc"
extern nebo_list_init,nebo_list_patch,nebo_delta_invert
section .data
values dq 10,20,30,0
update dq NEBO_DELTA_UPDATE,1,0,20,25
insert dq NEBO_DELTA_INSERT,2,0,0,22
section .bss
list resb NEBO_LIST_SIZE
inverse resb NEBO_DELTA_SIZE
section .text
global _start
_start:
 lea rdi,[list]
 lea rsi,[values]
 mov edx,4
 mov ecx,3
 call nebo_list_init
 test eax,eax
 jnz fail
 lea rdi,[list]
 lea rsi,[update]
 call nebo_list_patch
 test eax,eax
 jnz fail
 cmp qword [values+8],25
 jne fail
 lea rdi,[update]
 lea rsi,[inverse]
 call nebo_delta_invert
 test eax,eax
 jnz fail
 lea rdi,[list]
 lea rsi,[inverse]
 call nebo_list_patch
 test eax,eax
 jnz fail
 cmp qword [values+8],20
 jne fail
 lea rdi,[list]
 lea rsi,[insert]
 call nebo_list_patch
 test eax,eax
 jnz fail
 cmp qword [list+NEBO_LIST_COUNT],4
 jne fail
 cmp qword [values+16],22
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
