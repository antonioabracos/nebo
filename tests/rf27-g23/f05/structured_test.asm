bits 64
default rel
%include "runtime/ai/structured.inc"
section .data
schema dq 1,2,3
values dq 1,2,3
bad dq 1,4,3
prov dq 0x1122334455667788,0x99aabbccddeeff00
section .bss
state resq 1
outv resq 2
section .text
global _start
_start:
 mov edi,100
 mov esi,200
 lea rdx,[rel outv]
 call nebo_prompt_validate
 test eax,eax
 jne .f1
 cmp qword [rel outv],300
 jne .f2
 mov edi,4096
 mov esi,1
 lea rdx,[rel outv]
 call nebo_prompt_validate
 cmp eax,NEBO_STRUCT_E_LIMIT
 jne .f3
 lea rdi,[rel values]
 mov esi,3
 lea rdx,[rel schema]
 mov ecx,3
 call nebo_structured_schema_validate
 test eax,eax
 jne .f4
 lea rdi,[rel bad]
 mov esi,3
 lea rdx,[rel schema]
 mov ecx,3
 call nebo_structured_schema_validate
 cmp eax,NEBO_STRUCT_E_SCHEMA
 jne .f5
 lea rdi,[rel state]
 xor esi,esi
 lea rdx,[rel outv]
 call nebo_structured_repair
 test eax,eax
 jne .f6
 cmp qword [rel outv],1
 jne .f7
 lea rdi,[rel state]
 xor esi,esi
 lea rdx,[rel outv]
 call nebo_structured_repair
 cmp eax,NEBO_STRUCT_E_REPAIR
 jne .f8
 lea rdi,[rel prov]
 lea rsi,[rel outv]
 call nebo_provenance_copy
 test eax,eax
 jne .f9
 mov rax,[rel prov]
 cmp [rel outv],rax
 jne .f10
 mov rax,[rel prov+8]
 cmp [rel outv+8],rax
 jne .f11
 mov ecx,5000
.repeat:
 lea rdi,[rel values]
 mov esi,3
 lea rdx,[rel schema]
 mov r10,rcx
 mov ecx,3
 call nebo_structured_schema_validate
 mov rcx,r10
 test eax,eax
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
