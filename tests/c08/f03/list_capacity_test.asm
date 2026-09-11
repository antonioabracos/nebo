bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"
extern neboc_list_init
extern neboc_list_push
extern neboc_list_growth_capacity
extern neboc_list_reserve
global _start
section .text
_start:
 lea rdi,[rel descriptor]
 lea rsi,[rel storage4]
 mov edx,4
 mov ecx,8
 mov r8d,8
 mov r9d,1
 call neboc_list_init
 test eax,eax
 jnz fail1
 lea rdi,[rel descriptor]
 mov esi,5
 lea rdx,[rel planned]
 call neboc_list_growth_capacity
 test eax,eax
 jnz fail2
 cmp qword [rel planned],8
 jne fail2
 lea rdi,[rel descriptor]
 mov esi,65
 lea rdx,[rel planned]
 call neboc_list_growth_capacity
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail3
 cmp qword [rel planned],8
 jne fail3
 ; One live element makes shrink-to-zero fail atomically.
 lea rdi,[rel descriptor]
 lea rsi,[rel value]
 call neboc_list_push
 test eax,eax
 jnz fail4
 mov rax,[rel descriptor+NEBOC_LIST_GENERATION_OFFSET]
 mov [rel saved_generation],rax
 lea rdi,[rel descriptor]
 lea rsi,[rel storage8]
 xor edx,edx
 call neboc_list_reserve
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail4
 mov rax,[rel saved_generation]
 cmp [rel descriptor+NEBOC_LIST_GENERATION_OFFSET],rax
 jne fail4
 cmp qword [rel storage4],7
 jne fail4
 ; Null replacement storage is OOM and preserves the descriptor.
 lea rdi,[rel descriptor]
 xor esi,esi
 mov edx,8
 call neboc_list_reserve
 cmp eax,NEBOC_STATUS_OUT_OF_MEMORY
 jne fail5
 cmp qword [rel descriptor+NEBOC_LIST_CAPACITY_OFFSET],4
 jne fail5
 ; Successful explicit reserve copies and publishes once.
 lea rdi,[rel descriptor]
 lea rsi,[rel storage8]
 mov edx,8
 call neboc_list_reserve
 test eax,eax
 jnz fail6
 cmp qword [rel storage8],7
 jne fail6
 cmp qword [rel descriptor+NEBOC_LIST_CAPACITY_OFFSET],8
 jne fail6
 mov rax,[rel saved_generation]
 inc rax
 cmp [rel descriptor+NEBOC_LIST_GENERATION_OFFSET],rax
 jne fail6
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
exit:
 mov eax,60
 syscall
section .data
value: dq 7
section .bss
align 8
descriptor: resb NEBOC_LIST_SIZE
storage4: resq 4
storage8: resq 8
planned: resq 1
saved_generation: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
