bits 64
default rel
%include "compiler/semantic/collections/list_core.inc"
%include "compiler/semantic/collections/list_construction.inc"
extern neboc_list_init
extern neboc_list_push
extern neboc_list_length
extern neboc_list_construct
global _start
section .text
_start:
 lea rdi,[rel source]
 lea rsi,[rel source_storage]
 mov edx,2
 mov ecx,8
 mov r8d,8
 mov r9d,51
 call neboc_list_init
 test eax,eax
 jnz fail1
 lea rdi,[rel source]
 lea rsi,[rel one]
 call neboc_list_push
 lea rdi,[rel source]
 lea rsi,[rel two]
 call neboc_list_push
 mov rax,[rel source+NEBOC_LIST_GENERATION_OFFSET]
 mov [rel source_generation],rax

 ; A lexical borrowed read crosses the native call boundary without mutation.
 lea rdi,[rel source]
 lea rsi,[rel length]
 call borrowed_length
 test eax,eax
 jnz fail2
 cmp qword [rel length],2
 jne fail2
 mov rax,[rel source_generation]
 cmp [rel source+NEBOC_LIST_GENERATION_OFFSET],rax
 jne fail2
 cmp qword [rel source_storage],1
 jne fail2
 cmp qword [rel source_storage+8],2
 jne fail2

 ; The only selected return-like form is an explicit copy to distinct storage.
 lea rax,[rel output_storage]
 mov [rel request+NEBOC_LIST_CONSTRUCT_STORAGE_OFFSET],rax
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_CAPACITY_OFFSET],2
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_ELEMENT_SIZE_OFFSET],8
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_ELEMENT_ALIGN_OFFSET],8
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_ALLOCATOR_OFFSET],52
 lea rax,[rel source_storage]
 mov [rel request+NEBOC_LIST_CONSTRUCT_SOURCE_OFFSET],rax
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_COUNT_OFFSET],2
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_FILL_OFFSET],0
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_MODE_OFFSET],NEBOC_LIST_CONSTRUCT_FROM
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_TYPE_ID_OFFSET],NEBOC_LIST_TYPE_INT
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_CATEGORY_OFFSET],NEBOC_LIST_ELEMENT_CATEGORY_TRIVIAL_VALUE
 lea rdi,[rel output]
 lea rsi,[rel request]
 call explicit_copy_result
 test eax,eax
 jnz fail3
 cmp qword [rel output_storage],1
 jne fail3
 cmp qword [rel output_storage+8],2
 jne fail3
 lea rax,[rel output_storage]
 cmp [rel output+NEBOC_LIST_DATA_OFFSET],rax
 jne fail3
 lea rax,[rel source_storage]
 cmp [rel output+NEBOC_LIST_DATA_OFFSET],rax
 je fail3
 ; Source remains independently live and unchanged.
 mov rax,[rel source_generation]
 cmp [rel source+NEBOC_LIST_GENERATION_OFFSET],rax
 jne fail3
 xor edi,edi
 jmp exit

borrowed_length:
 jmp neboc_list_length
explicit_copy_result:
 jmp neboc_list_construct
fail1: mov edi,1
 jmp exit
fail2: mov edi,2
 jmp exit
fail3: mov edi,3
exit: mov eax,60
 syscall
section .data
one: dq 1
two: dq 2
section .bss
align 8
source: resb NEBOC_LIST_SIZE
output: resb NEBOC_LIST_SIZE
request: resb NEBOC_LIST_CONSTRUCT_SIZE
source_storage: resq 2
output_storage: resq 2
source_generation: resq 1
length: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
