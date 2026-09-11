bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"
%include "compiler/semantic/collections/list_construction.inc"
extern neboc_list_construct
global _start
section .text
_start:
 ; withCapacity(4)
 lea rdi,[rel descriptor]
 lea rsi,[rel request]
 call neboc_list_construct
 test eax,eax
 jnz fail1
 cmp qword [rel descriptor+NEBOC_LIST_LENGTH_OFFSET],0
 jne fail1
 cmp qword [rel descriptor+NEBOC_LIST_CAPACITY_OFFSET],4
 jne fail1
 ; from([3,5,8])
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_MODE_OFFSET],NEBOC_LIST_CONSTRUCT_FROM
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_SOURCE_OFFSET],values
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_COUNT_OFFSET],3
 lea rdi,[rel from_descriptor]
 lea rsi,[rel request]
 call neboc_list_construct
 test eax,eax
 jnz fail2
 cmp qword [rel from_storage],3
 jne fail2
 cmp qword [rel from_storage+8],5
 jne fail2
 cmp qword [rel from_storage+16],8
 jne fail2
 ; fill(3, 9)
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_MODE_OFFSET],NEBOC_LIST_CONSTRUCT_FILL
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_SOURCE_OFFSET],0
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_FILL_OFFSET],value9
 lea rdi,[rel fill_descriptor]
 lea rsi,[rel request]
 call neboc_list_construct
 test eax,eax
 jnz fail3
 cmp qword [rel fill_storage],9
 jne fail3
 cmp qword [rel fill_storage+8],9
 jne fail3
 cmp qword [rel fill_storage+16],9
 jne fail3
 ; new() does not allocate.
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_MODE_OFFSET],NEBOC_LIST_CONSTRUCT_NEW
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_STORAGE_OFFSET],0
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_CAPACITY_OFFSET],0
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_COUNT_OFFSET],0
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_FILL_OFFSET],0
 lea rdi,[rel new_descriptor]
 lea rsi,[rel request]
 call neboc_list_construct
 test eax,eax
 jnz fail4
 cmp qword [rel new_descriptor+NEBOC_LIST_DATA_OFFSET],0
 jne fail4
 cmp qword [rel new_descriptor+NEBOC_LIST_GENERATION_OFFSET],1
 jne fail4
 ; Nontrivial/unknown element category is rejected before touching output.
 mov qword [rel request+NEBOC_LIST_CONSTRUCT_CATEGORY_OFFSET],2
 mov rax,0x1122334455667788
 mov [rel sentinel],rax
 lea rdi,[rel sentinel]
 lea rsi,[rel request]
 call neboc_list_construct
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail5
 mov rax,0x1122334455667788
 cmp [rel sentinel],rax
 jne fail5
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
exit:
 mov eax,60
 syscall
section .data
align 8
values: dq 3,5,8
value9: dq 9
request:
 dq storage,4,8,8,1,0,0,0
 dq NEBOC_LIST_CONSTRUCT_WITH_CAPACITY,NEBOC_LIST_TYPE_INT,NEBOC_LIST_ELEMENT_CATEGORY_TRIVIAL_VALUE
section .bss
align 8
descriptor: resb NEBOC_LIST_SIZE
from_descriptor: resb NEBOC_LIST_SIZE
fill_descriptor: resb NEBOC_LIST_SIZE
new_descriptor: resb NEBOC_LIST_SIZE
storage: resq 4
from_storage: equ storage
fill_storage: equ storage
sentinel: resq 8
section .note.GNU-stack noalloc noexec nowrite progbits
