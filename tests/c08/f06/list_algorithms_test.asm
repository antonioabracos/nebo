bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"
extern neboc_list_init
extern neboc_list_push
extern neboc_list_find
extern neboc_list_map
extern neboc_list_filter
extern neboc_list_stable_sort
global _start

section .text
_start:
 lea rdi,[rel source]
 lea rsi,[rel source_storage]
 mov edx,3
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
 cmp r12,3
 jb .push

 ; An equality callback may only produce a canonical Bool.
 mov qword [rel found],77
 mov qword [rel index],88
 lea rdi,[rel source]
 lea rsi,[rel needle]
 lea rdx,[rel invalid_equality]
 lea rcx,[rel index]
 lea r8,[rel found]
 call neboc_list_find
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail2

 ; A failing map does not commit destination length/generation and clears work.
 lea rdi,[rel mapped]
 lea rsi,[rel mapped_storage]
 mov edx,3
 mov ecx,8
 mov r8d,8
 mov r9d,2
 call neboc_list_init
 test eax,eax
 jnz fail3
 mov qword [rel callback_count],0
 lea rdi,[rel source]
 lea rsi,[rel mapped]
 lea rdx,[rel fail_second_map]
 call neboc_list_map
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail3
 cmp qword [rel mapped+NEBOC_LIST_LENGTH_OFFSET],0
 jne fail3
 cmp qword [rel mapped+NEBOC_LIST_GENERATION_OFFSET],1
 jne fail3
 cmp qword [rel mapped_storage],0
 jne fail3

 ; A non-canonical predicate is rejected without committing output metadata.
 lea rdi,[rel filtered]
 lea rsi,[rel filtered_storage]
 mov edx,3
 mov ecx,8
 mov r8d,8
 mov r9d,3
 call neboc_list_init
 test eax,eax
 jnz fail4
 lea rdi,[rel source]
 lea rsi,[rel filtered]
 lea rdx,[rel invalid_predicate]
 call neboc_list_filter
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail4
 cmp qword [rel filtered+NEBOC_LIST_LENGTH_OFFSET],0
 jne fail4
 cmp qword [rel filtered+NEBOC_LIST_GENERATION_OFFSET],1
 jne fail4

 ; Insufficient caller scratch and invalid comparator preserve source exactly.
 mov rax,[rel source+NEBOC_LIST_GENERATION_OFFSET]
 mov [rel generation],rax
 lea rdi,[rel source]
 lea rsi,[rel compare_int]
 lea rdx,[rel scratch]
 mov ecx,23
 call neboc_list_stable_sort
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail5
 cmp qword [rel source_storage],3
 jne fail5
 mov rax,[rel generation]
 cmp [rel source+NEBOC_LIST_GENERATION_OFFSET],rax
 jne fail5
 lea rdi,[rel source]
 lea rsi,[rel invalid_compare]
 lea rdx,[rel scratch]
 mov ecx,24
 call neboc_list_stable_sort
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail6
 cmp qword [rel source_storage],3
 jne fail6
 mov rax,[rel generation]
 cmp [rel source+NEBOC_LIST_GENERATION_OFFSET],rax
 jne fail6
 xor edi,edi
 jmp exit

invalid_equality:
 mov qword [rdx],2
 xor eax,eax
 ret
invalid_predicate:
 mov qword [rsi],2
 xor eax,eax
 ret
fail_second_map:
 inc qword [rel callback_count]
 cmp qword [rel callback_count],2
 je .map_fail
 mov rax,[rdi]
 mov [rsi],rax
 xor eax,eax
 ret
.map_fail:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
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
values: dq 3,1,2
needle: dq 1
section .bss
align 8
source: resb NEBOC_LIST_SIZE
mapped: resb NEBOC_LIST_SIZE
filtered: resb NEBOC_LIST_SIZE
source_storage: resq 3
mapped_storage: resq 3
filtered_storage: resq 3
scratch: resq 3
index: resq 1
found: resq 1
generation: resq 1
callback_count: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
