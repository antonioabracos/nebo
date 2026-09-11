bits 64
default rel
%include "runtime/textual/text_core.inc"

extern neboc_text_builder_with_capacity
extern neboc_text_builder_append_text
extern neboc_text_builder_append_char
extern neboc_text_builder_reserve
extern neboc_text_builder_clear
extern neboc_text_builder_freeze
extern neboc_text_freeze

section .rodata
ab_data: db 'a','b'
cde_data: db 'c','d','e'
align 8
ab: dq ab_data,2,NEBO_TEXT_FLAG_STATIC | NEBO_TEXT_FLAG_ASCII | NEBO_TEXT_FLAG_VALID_UTF8,NEBO_TEXT_STORAGE_STATIC
cde: dq cde_data,3,NEBO_TEXT_FLAG_STATIC | NEBO_TEXT_FLAG_ASCII | NEBO_TEXT_FLAG_VALID_UTF8,NEBO_TEXT_STORAGE_STATIC

section .bss
buffer: resb 16
builder: resb NEBO_BUILDER_SIZE
frozen: resb NEBO_TEXT_DESCRIPTOR_SIZE
second_buffer: resb 8
second_builder: resb NEBO_BUILDER_SIZE
second_frozen: resb NEBO_TEXT_DESCRIPTOR_SIZE

section .text
global _start
_start:
 lea rdi,[rel builder]
 lea rsi,[rel buffer]
 mov edx,8
 call neboc_text_builder_with_capacity
 test eax,eax
 jnz fail

 lea rdi,[rel builder]
 lea rsi,[rel ab]
 call neboc_text_builder_append_text
 test eax,eax
 jnz fail
 lea rdi,[rel builder]
 mov esi,0x00e9
 call neboc_text_builder_append_char
 test eax,eax
 jnz fail
 cmp dword [rel buffer],0xa9c36261
 jne fail
 cmp qword [rel builder+NEBO_BUILDER_LENGTH_OFFSET],4
 jne fail

 lea rdi,[rel builder]
 mov esi,8
 call neboc_text_builder_reserve
 test eax,eax
 jnz fail
 lea rdi,[rel builder]
 mov esi,9
 call neboc_text_builder_reserve
 cmp eax,NEBO_TEXT_ERROR_CAPACITY
 jne fail
 cmp qword [rel builder+NEBO_BUILDER_LENGTH_OFFSET],4
 jne fail

 lea rdi,[rel builder]
 mov esi,0xd800
 call neboc_text_builder_append_char
 cmp eax,NEBO_TEXT_ERROR_INVALID_CHAR
 jne fail
 cmp qword [rel builder+NEBO_BUILDER_LENGTH_OFFSET],4
 jne fail

 lea rdi,[rel builder]
 lea rsi,[rel cde]
 call neboc_text_builder_append_text
 test eax,eax
 jnz fail
 lea rdi,[rel builder]
 lea rsi,[rel ab]
 call neboc_text_builder_append_text
 cmp eax,NEBO_TEXT_ERROR_CAPACITY
 jne fail
 cmp qword [rel builder+NEBO_BUILDER_LENGTH_OFFSET],7
 jne fail
 cmp byte [rel buffer+7],0
 jne fail

 lea rdi,[rel builder]
 call neboc_text_builder_clear
 test eax,eax
 jnz fail
 cmp qword [rel builder+NEBO_BUILDER_LENGTH_OFFSET],0
 jne fail
 cmp qword [rel builder+NEBO_BUILDER_CAPACITY_OFFSET],8
 jne fail

 lea rdi,[rel builder]
 lea rsi,[rel cde]
 call neboc_text_builder_append_text
 test eax,eax
 jnz fail
 lea rdi,[rel builder]
 lea rsi,[rel frozen]
 call neboc_text_builder_freeze
 test eax,eax
 jnz fail
 cmp qword [rel frozen+NEBO_TEXT_LENGTH_OFFSET],3
 jne fail
 cmp qword [rel frozen+NEBO_TEXT_AUX_OFFSET],NEBO_TEXT_STORAGE_OWNED
 jne fail
 cmp qword [rel builder+NEBO_BUILDER_DATA_OFFSET],0
 jne fail
 cmp byte [rel buffer],'c'
 jne fail
 cmp byte [rel buffer+1],'d'
 jne fail
 cmp byte [rel buffer+2],'e'
 jne fail

 lea rdi,[rel second_builder]
 lea rsi,[rel second_buffer]
 mov edx,8
 call neboc_text_builder_with_capacity
 test eax,eax
 jnz fail
 lea rdi,[rel second_builder]
 lea rsi,[rel ab]
 call neboc_text_builder_append_text
 test eax,eax
 jnz fail
 lea rdi,[rel second_builder]
 lea rsi,[rel second_buffer]
 call neboc_text_builder_freeze
 cmp eax,NEBO_TEXT_ERROR_NULL
 jne fail
 cmp qword [rel second_builder+NEBO_BUILDER_LENGTH_OFFSET],2
 jne fail
 cmp word [rel second_buffer],0x6261
 jne fail
 lea rdi,[rel second_builder]
 lea rsi,[rel second_frozen]
 call neboc_text_freeze
 test eax,eax
 jnz fail
 cmp qword [rel second_frozen+NEBO_TEXT_LENGTH_OFFSET],2
 jne fail

 mov qword [rel second_builder],0x33333333
 lea rdi,[rel second_builder]
 lea rsi,[rel second_buffer]
 mov edx,NEBO_TEXT_LIMIT_BUILDER_BYTES+1
 call neboc_text_builder_with_capacity
 cmp eax,NEBO_TEXT_ERROR_CAPACITY
 jne fail
 cmp qword [rel second_builder],0x33333333
 jne fail

 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,6
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
