bits 64
default rel
%include "runtime/textual/text_core.inc"

extern neboc_text_copy
extern neboc_text_clone
extern neboc_text_borrow
extern neboc_text_drop
extern neboc_text_storage_class

section .rodata
source_data: db 'o','w','n'
align 8
source: dq source_data,3,NEBO_TEXT_FLAG_STATIC | NEBO_TEXT_FLAG_ASCII | NEBO_TEXT_FLAG_VALID_UTF8,NEBO_TEXT_STORAGE_STATIC

section .bss
dest: resb 8
desc: resb NEBO_TEXT_DESCRIPTOR_SIZE
borrowed: resb NEBO_TEXT_DESCRIPTOR_SIZE
copied: resb NEBO_TEXT_DESCRIPTOR_SIZE

section .text
global _start
_start:
 lea rdi,[rel source]
 lea rsi,[rel copied]
 call neboc_text_copy
 test eax,eax
 jnz fail
 cmp qword [rel copied+NEBO_TEXT_LENGTH_OFFSET],3
 jne fail

 lea rdi,[rel source]
 lea rsi,[rel dest]
 mov edx,2
 lea rcx,[rel desc]
 call neboc_text_clone
 cmp eax,NEBO_TEXT_ERROR_CAPACITY
 jne fail
 cmp qword [rel desc],0
 jne fail

 lea rdi,[rel source]
 lea rsi,[rel dest]
 mov edx,8
 lea rcx,[rel desc]
 call neboc_text_clone
 test eax,eax
 jnz fail
 cmp dword [rel dest],0x006e776f
 jne fail
 lea rdi,[rel desc]
 call neboc_text_storage_class
 cmp eax,NEBO_TEXT_STORAGE_OWNED
 jne fail
 lea rdi,[rel source]
 call neboc_text_storage_class
 cmp eax,NEBO_TEXT_STORAGE_STATIC
 jne fail

 lea rdi,[rel source]
 lea rsi,[rel borrowed]
 call neboc_text_borrow
 test eax,eax
 jnz fail
 cmp qword [rel borrowed+NEBO_TEXT_LENGTH_OFFSET],3
 jne fail
 lea rax,[rel source]
 cmp [rel borrowed+NEBO_TEXT_VIEW_SOURCE_OFFSET],rax
 jne fail
 lea rdi,[rel borrowed]
 call neboc_text_storage_class
 cmp eax,NEBO_TEXT_STORAGE_BORROWED
 jne fail

 lea rdi,[rel source]
 call neboc_text_drop
 test eax,eax
 jnz fail
 lea rax,[rel source_data]
 cmp [rel source],rax
 jne fail
 lea rdi,[rel borrowed]
 call neboc_text_drop
 test eax,eax
 jnz fail
 lea rax,[rel source_data]
 cmp [rel borrowed],rax
 jne fail

 mov qword [rel copied],0x22222222
 lea rdi,[rel desc]
 lea rsi,[rel copied]
 call neboc_text_copy
 cmp eax,NEBO_TEXT_ERROR_POLICY
 jne fail
 cmp qword [rel copied],0x22222222
 jne fail

 lea rdi,[rel desc]
 call neboc_text_drop
 test eax,eax
 jnz fail
 cmp qword [rel desc],0
 jne fail
 cmp qword [rel desc+24],0
 jne fail
 call neboc_text_drop
 test eax,eax
 jnz fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,5
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
