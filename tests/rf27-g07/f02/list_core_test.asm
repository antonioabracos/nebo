bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"
%include "compiler/lowering/collections/list_plan.inc"
extern neboc_list_init
extern neboc_list_reserve
extern neboc_list_push
extern neboc_list_at
extern neboc_list_get
extern neboc_list_set
extern neboc_list_pop
extern neboc_list_clear
extern neboc_list_state
extern neboc_list_lower
extern neboc_list_codegen_descriptor
global _start
section .text
_start:
 lea rdi,[rel descriptor]
 lea rsi,[rel storage_a]
 mov edx,4
 mov ecx,8
 mov r8d,8
 mov r9d,1
 call neboc_list_init
 test eax,eax
 jnz fail1
 lea rdi,[rel descriptor]
 lea rsi,[rel value10]
 call neboc_list_push
 test eax,eax
 jnz fail2
 lea rdi,[rel descriptor]
 lea rsi,[rel value20]
 call neboc_list_push
 test eax,eax
 jnz fail3
 lea rdi,[rel descriptor]
 mov esi,1
 lea rdx,[rel output]
 call neboc_list_at
 test eax,eax
 jnz fail4
 cmp qword [rel output],20
 jne fail4
 lea rdi,[rel descriptor]
 mov esi,1
 lea rdx,[rel value30]
 call neboc_list_set
 test eax,eax
 jnz fail5
 lea rdi,[rel descriptor]
 mov esi,9
 lea rdx,[rel output]
 lea rcx,[rel found]
 call neboc_list_get
 test eax,eax
 jnz fail6
 cmp qword [rel found],0
 jne fail6
 lea rdi,[rel descriptor]
 lea rsi,[rel storage_b]
 mov edx,8
 call neboc_list_reserve
 test eax,eax
 jnz fail7
 cmp qword [rel storage_b],10
 jne fail7
 cmp qword [rel storage_b+8],30
 jne fail7
 lea rdi,[rel descriptor]
 lea rsi,[rel output]
 lea rdx,[rel found]
 call neboc_list_pop
 test eax,eax
 jnz fail8
 cmp qword [rel found],1
 jne fail8
 cmp qword [rel output],30
 jne fail8
 lea rdi,[rel descriptor]
 lea rsi,[rel length]
 lea rdx,[rel capacity]
 call neboc_list_state
 test eax,eax
 jnz fail9
 cmp qword [rel length],1
 jne fail9
 cmp qword [rel capacity],8
 jne fail9
 lea rdi,[rel descriptor]
 lea rsi,[rel plan]
 call neboc_list_lower
 test eax,eax
 jnz fail10
 lea rdi,[rel plan]
 lea rsi,[rel emitted]
 call neboc_list_codegen_descriptor
 test eax,eax
 jnz fail10
 cmp qword [rel emitted+NEBOC_LIST_LENGTH_OFFSET],1
 jne fail10
 cmp qword [rel emitted+NEBOC_LIST_CAPACITY_OFFSET],8
 jne fail10
 lea rdi,[rel descriptor]
 call neboc_list_clear
 test eax,eax
 jnz fail11
 cmp qword [rel descriptor+NEBOC_LIST_LENGTH_OFFSET],0
 jne fail11
 cmp qword [rel storage_b],0
 jne fail11
 ; A failed shrink below length is atomic.
 lea rdi,[rel descriptor2]
 lea rsi,[rel storage_c]
 mov edx,1
 mov ecx,8
 mov r8d,8
 mov r9d,1
 call neboc_list_init
 test eax,eax
 jnz fail12
 lea rdi,[rel descriptor2]
 lea rsi,[rel value10]
 call neboc_list_push
 test eax,eax
 jnz fail12
 mov rax,[rel descriptor2+NEBOC_LIST_GENERATION_OFFSET]
 mov [rel generation],rax
 lea rdi,[rel descriptor2]
 lea rsi,[rel storage_d]
 xor edx,edx
 call neboc_list_reserve
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail12
 mov rax,[rel generation]
 cmp [rel descriptor2+NEBOC_LIST_GENERATION_OFFSET],rax
 jne fail12
 xor edi,edi
 mov eax,60
 syscall
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
 jmp exit
fail9: mov edi,9
 jmp exit
fail10: mov edi,10
 jmp exit
fail11: mov edi,11
 jmp exit
fail12: mov edi,12
exit:
 mov eax,60
 syscall
section .data
value10: dq 10
value20: dq 20
value30: dq 30
section .bss
align 8
descriptor: resb NEBOC_LIST_SIZE
descriptor2: resb NEBOC_LIST_SIZE
storage_a: resq 4
storage_b: resq 8
storage_c: resq 1
storage_d: resq 1
output: resq 1
found: resq 1
length: resq 1
capacity: resq 1
generation: resq 1
plan: resb NEBOC_LIST_PLAN_SIZE
emitted: resb NEBOC_LIST_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
