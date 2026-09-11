bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"
extern neboc_list_init
extern neboc_list_push
extern neboc_list_find
extern neboc_list_contains
extern neboc_list_map
extern neboc_list_filter
extern neboc_list_stable_sort
global _start
section .text
_start:
 lea rdi,[rel source]
 lea rsi,[rel source_storage]
 mov edx,4
 mov ecx,8
 mov r8d,8
 mov r9d,1
 call neboc_list_init
 test eax,eax
 jnz fail1
 lea rbx,[rel values]
 xor r12d,r12d
.push:
 lea rdi,[rel source]
 lea rsi,[rbx+r12*8]
 call neboc_list_push
 test eax,eax
 jnz fail1
 inc r12
 cmp r12,4
 jb .push
 lea rdi,[rel source]
 lea rsi,[rel needle2]
 lea rdx,[rel eq_int]
 lea rcx,[rel index]
 lea r8,[rel found]
 call neboc_list_find
 test eax,eax
 jnz fail2
 cmp qword [rel found],1
 jne fail2
 cmp qword [rel index],2
 jne fail2
 lea rdi,[rel source]
 lea rsi,[rel needle9]
 lea rdx,[rel eq_int]
 lea rcx,[rel found]
 call neboc_list_contains
 test eax,eax
 jnz fail3
 cmp qword [rel found],0
 jne fail3
 lea rdi,[rel mapped]
 lea rsi,[rel mapped_storage]
 mov edx,4
 mov ecx,8
 mov r8d,8
 mov r9d,1
 call neboc_list_init
 test eax,eax
 jnz fail4
 lea rdi,[rel source]
 lea rsi,[rel mapped]
 lea rdx,[rel double_int]
 call neboc_list_map
 test eax,eax
 jnz fail4
 cmp qword [rel mapped_storage],6
 jne fail4
 cmp qword [rel mapped_storage+8],2
 jne fail4
 cmp qword [rel mapped_storage+16],4
 jne fail4
 lea rdi,[rel filtered]
 lea rsi,[rel filtered_storage]
 mov edx,4
 mov ecx,8
 mov r8d,8
 mov r9d,1
 call neboc_list_init
 test eax,eax
 jnz fail5
 lea rdi,[rel source]
 lea rsi,[rel filtered]
 lea rdx,[rel greater_than_one]
 call neboc_list_filter
 test eax,eax
 jnz fail5
 cmp qword [rel filtered+NEBOC_LIST_LENGTH_OFFSET],3
 jne fail5
 cmp qword [rel filtered_storage],3
 jne fail5
 cmp qword [rel filtered_storage+8],2
 jne fail5
 lea rdi,[rel source]
 lea rsi,[rel compare_int]
 lea rdx,[rel scratch]
 mov ecx,32
 call neboc_list_stable_sort
 test eax,eax
 jnz fail6
 cmp qword [rel source_storage],1
 jne fail6
 cmp qword [rel source_storage+8],2
 jne fail6
 cmp qword [rel source_storage+16],2
 jne fail6
 cmp qword [rel source_storage+24],3
 jne fail6
 mov rax,[rel source+NEBOC_LIST_GENERATION_OFFSET]
 mov [rel generation],rax
 lea rdi,[rel source]
 lea rsi,[rel invalid_compare]
 lea rdx,[rel scratch]
 mov ecx,32
 call neboc_list_stable_sort
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail7
 cmp qword [rel source_storage],1
 jne fail7
 mov rax,[rel generation]
 cmp [rel source+NEBOC_LIST_GENERATION_OFFSET],rax
 jne fail7
 xor edi,edi
 mov eax,60
 syscall

eq_int:
 mov rax,[rdi]
 cmp rax,[rsi]
 sete al
 movzx rax,al
 mov [rdx],rax
 xor eax,eax
 ret
double_int:
 mov rax,[rdi]
 add rax,rax
 jo callback_error
 mov [rsi],rax
 xor eax,eax
 ret
greater_than_one:
 cmp qword [rdi],1
 setg al
 movzx rax,al
 mov [rsi],rax
 xor eax,eax
 ret
compare_int:
 mov rax,[rdi]
 cmp rax,[rsi]
 jl .less
 jg .greater
 mov qword [rdx],0
 xor eax,eax
 ret
.less:
 mov qword [rdx],-1
 xor eax,eax
 ret
.greater:
 mov qword [rdx],1
 xor eax,eax
 ret
invalid_compare:
 mov qword [rdx],2
 xor eax,eax
 ret
callback_error:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
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
exit:
 mov eax,60
 syscall
section .data
values: dq 3,1,2,2
needle2: dq 2
needle9: dq 9
section .bss
align 8
source: resb NEBOC_LIST_SIZE
mapped: resb NEBOC_LIST_SIZE
filtered: resb NEBOC_LIST_SIZE
source_storage: resq 4
mapped_storage: resq 4
filtered_storage: resq 4
scratch: resq 4
index: resq 1
found: resq 1
generation: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
