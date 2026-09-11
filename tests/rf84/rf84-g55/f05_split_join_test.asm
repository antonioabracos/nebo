bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text_transform.inc"
extern neboc_text_split_byte
extern neboc_text_join_byte
section .rodata
data: db 'a',',','b',',','c'
align 8
text: dq data,5,NEBO_TEXT_FLAG_ASCII,0
section .bss
items: resb NEBO_SPLIT_ITEM_SIZE*3
joined_data: resb 8
joined: resb NEBO_TEXT_DESCRIPTOR_SIZE
section .text
global _start
_start:
 lea rdi,[rel text]
 mov esi,','
 lea rdx,[rel items]
 mov ecx,2
 call neboc_text_split_byte
 cmp rax,-NEBO_TEXT_ERROR_CAPACITY
 jne fail
 cmp qword [rel items],0
 jne fail
 lea rdi,[rel text]
 mov esi,','
 lea rdx,[rel items]
 mov ecx,3
 call neboc_text_split_byte
 cmp eax,3
 jne fail
 cmp qword [rel items+NEBO_SPLIT_ITEM_LENGTH_OFFSET],1
 jne fail
 lea rdi,[rel items]
 mov esi,3
 mov edx,'-'
 lea rcx,[rel joined_data]
 mov r8d,8
 lea r9,[rel joined]
 call neboc_text_join_byte
 test eax,eax
 jnz fail
 cmp qword [rel joined+NEBO_TEXT_LENGTH_OFFSET],5
 jne fail
 cmp dword [rel joined_data],0x2d622d61
 jne fail
 cmp byte [rel joined_data+4],'c'
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,5
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
