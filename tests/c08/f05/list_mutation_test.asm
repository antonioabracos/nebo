bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"
extern neboc_list_init
extern neboc_list_append
extern neboc_list_insert
extern neboc_list_set
extern neboc_list_remove
extern neboc_list_pop
extern neboc_list_swap
extern neboc_list_clear
global _start
section .text
_start:
 lea rdi,[rel descriptor]
 lea rsi,[rel storage]
 mov edx,5
 mov ecx,8
 mov r8d,8
 mov r9d,1
 call neboc_list_init
 test eax,eax
 jnz fail1
 lea rdi,[rel descriptor]
 lea rsi,[rel v1]
 call neboc_list_append
 lea rdi,[rel descriptor]
 lea rsi,[rel v3]
 call neboc_list_append
 ; Alias-sensitive insert snapshots storage[0] before shifting.
 lea rdi,[rel descriptor]
 mov esi,1
 lea rdx,[rel storage]
 call neboc_list_insert
 test eax,eax
 jnz fail2
 cmp qword [rel storage],1
 jne fail2
 cmp qword [rel storage+8],1
 jne fail2
 cmp qword [rel storage+16],3
 jne fail2
 lea rdi,[rel descriptor]
 mov esi,2
 lea rdx,[rel v4]
 call neboc_list_set
 test eax,eax
 jnz fail3
 lea rdi,[rel descriptor]
 xor esi,esi
 mov edx,2
 call neboc_list_swap
 test eax,eax
 jnz fail4
 cmp qword [rel storage],4
 jne fail4
 cmp qword [rel storage+16],1
 jne fail4
 lea rdi,[rel descriptor]
 mov esi,1
 lea rdx,[rel output]
 lea rcx,[rel found]
 call neboc_list_remove
 test eax,eax
 jnz fail5
 cmp qword [rel output],1
 jne fail5
 cmp qword [rel storage],4
 jne fail5
 cmp qword [rel storage+8],1
 jne fail5
 cmp qword [rel storage+16],0
 jne fail5
 lea rdi,[rel descriptor]
 lea rsi,[rel output]
 lea rdx,[rel found]
 call neboc_list_pop
 test eax,eax
 jnz fail6
 cmp qword [rel output],1
 jne fail6
 cmp qword [rel storage+8],0
 jne fail6
 lea rdi,[rel descriptor]
 call neboc_list_clear
 test eax,eax
 jnz fail7
 cmp qword [rel descriptor+NEBOC_LIST_LENGTH_OFFSET],0
 jne fail7
 cmp qword [rel storage],0
 jne fail7
 ; OOB insert leaves the full prestate unchanged.
 lea rdi,[rel descriptor]
 mov esi,1
 lea rdx,[rel v1]
 call neboc_list_insert
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail8
 cmp qword [rel descriptor+NEBOC_LIST_LENGTH_OFFSET],0
 jne fail8
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
fail5: mov edi,5
 jmp exit
fail6: mov edi,6
 jmp exit
fail7: mov edi,7
 jmp exit
fail8: mov edi,8
exit:
 mov eax,60
 syscall
section .data
v1: dq 1
v3: dq 3
v4: dq 4
section .bss
align 8
descriptor: resb NEBOC_LIST_SIZE
storage: resq 5
output: resq 1
found: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
