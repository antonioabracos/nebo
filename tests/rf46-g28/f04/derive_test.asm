bits 64
default rel
%include "compiler/meta/derive.inc"
extern nebo_derive_plan
section .data
caps dq 15,31,15
section .bss
plan resq 1
section .text
global _start
_start:
 mov edi,NEBO_DERIVE_EQ|NEBO_DERIVE_HASH|NEBO_DERIVE_DEBUG
 lea rsi,[caps]
 mov edx,3
 lea rcx,[plan]
 call nebo_derive_plan
 test eax,eax
 jnz fail
 cmp qword [plan],NEBO_DERIVE_EQ|NEBO_DERIVE_HASH|NEBO_DERIVE_DEBUG
 jne fail
 mov qword [caps+16],NEBO_DERIVE_FIELD_EQ
 mov qword [plan],0x55
 mov edi,NEBO_DERIVE_HASH
 lea rsi,[caps]
 mov edx,3
 lea rcx,[plan]
 call nebo_derive_plan
 cmp eax,NEBO_DERIVE_STATUS_INELIGIBLE
 jne fail
 cmp qword [plan],0
 jne fail
 mov edi,16
 xor esi,esi
 xor edx,edx
 lea rcx,[plan]
 call nebo_derive_plan
 cmp eax,NEBO_DERIVE_STATUS_UNSUPPORTED
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail: mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
