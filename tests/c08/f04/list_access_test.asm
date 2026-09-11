bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"
extern neboc_list_init
extern neboc_list_push
extern neboc_list_at
extern neboc_list_get
extern neboc_list_length
extern neboc_list_capacity
extern neboc_list_is_empty
extern neboc_list_first
extern neboc_list_last
global _start
section .text
_start:
 lea rdi,[rel descriptor]
 lea rsi,[rel storage]
 mov edx,3
 mov ecx,8
 mov r8d,8
 mov r9d,1
 call neboc_list_init
 test eax,eax
 jnz fail1
 lea rdi,[rel descriptor]
 lea rsi,[rel scalar]
 call neboc_list_is_empty
 test eax,eax
 jnz fail1
 cmp qword [rel scalar],1
 jne fail1
 mov qword [rel output],77
 lea rdi,[rel descriptor]
 lea rsi,[rel output]
 lea rdx,[rel found]
 call neboc_list_first
 test eax,eax
 jnz fail2
 cmp qword [rel found],0
 jne fail2
 cmp qword [rel output],77
 jne fail2
 lea rbx,[rel values]
 xor r12d,r12d
.push:
 lea rdi,[rel descriptor]
 lea rsi,[rbx+r12*8]
 call neboc_list_push
 test eax,eax
 jnz fail3
 inc r12
 cmp r12,3
 jb .push
 lea rdi,[rel descriptor]
 lea rsi,[rel scalar]
 call neboc_list_length
 test eax,eax
 jnz fail4
 cmp qword [rel scalar],3
 jne fail4
 lea rdi,[rel descriptor]
 xor esi,esi
 lea rdx,[rel output]
 call neboc_list_at
 test eax,eax
 jnz fail41
 cmp qword [rel output],11
 jne fail42
 lea rdi,[rel descriptor]
 lea rsi,[rel scalar]
 call neboc_list_capacity
 test eax,eax
 jnz fail4
 cmp qword [rel scalar],3
 jne fail4
 lea rdi,[rel descriptor]
 lea rsi,[rel output]
 lea rdx,[rel found]
 call neboc_list_first
 test eax,eax
 jnz fail53
 cmp qword [rel output],11
 jne fail54
 lea rdi,[rel descriptor]
 lea rsi,[rel output]
 lea rdx,[rel found]
 call neboc_list_last
 test eax,eax
 jnz fail52
 cmp qword [rel output],33
 jne fail52
 mov qword [rel output],99
 lea rdi,[rel descriptor]
 mov esi,8
 lea rdx,[rel output]
 call neboc_list_at
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail6
 cmp qword [rel output],99
 jne fail6
 lea rdi,[rel descriptor]
 mov rsi,-1
 lea rdx,[rel output]
 lea rcx,[rel found]
 call neboc_list_get
 test eax,eax
 jnz fail7
 cmp qword [rel found],0
 jne fail7
 cmp qword [rel output],99
 jne fail7
 xor edi,edi
 jmp exit
fail1: mov edi,1
 jmp exit
fail2: mov edi,2
 jmp exit
fail3: mov edi,3
 jmp exit
fail4: mov edi,4
 jmp exit
fail41: mov edi,41
 jmp exit
fail42: mov edi,42
 jmp exit
fail51: mov edi,51
 jmp exit
fail52: mov edi,52
 jmp exit
fail53: mov edi,53
 jmp exit
fail54: mov edi,54
 jmp exit
fail6: mov edi,6
 jmp exit
fail7: mov edi,7
exit:
 mov eax,60
 syscall
section .data
values: dq 11,22,33
section .bss
align 8
descriptor: resb NEBOC_LIST_SIZE
storage: resq 3
output: resq 1
found: resq 1
scalar: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
