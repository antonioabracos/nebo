bits 64
default rel
%include "runtime/textual/text_core.inc"

extern neboc_text_view
extern neboc_text_copy
extern neboc_text_runtime_contract

section .rodata
data: db 'a','b','c','d','e'
align 8
source: dq data,5,NEBO_TEXT_FLAG_ASCII | NEBO_TEXT_FLAG_VALID_UTF8,0

section .bss
align 8
view: resb NEBO_TEXT_DESCRIPTOR_SIZE
copy: resb NEBO_TEXT_DESCRIPTOR_SIZE

section .text
%macro REQUIRE_EQ 2
 cmp %1,%2
 jne fail
%endmacro

global _start
_start:
 mov eax,NEBO_TEXT_DATA_OFFSET
 cmp eax,0
 jne fail
 mov eax,NEBO_TEXT_LENGTH_OFFSET
 cmp eax,8
 jne fail
 mov eax,NEBO_TEXT_FLAGS_OFFSET
 cmp eax,16
 jne fail
 mov eax,NEBO_TEXT_AUX_OFFSET
 cmp eax,24
 jne fail
 mov eax,NEBO_TEXT_DESCRIPTOR_SIZE
 cmp eax,32
 jne fail
 mov eax,MAX_TEXT_BYTES
 cmp eax,NEBO_TEXT_LIMIT_BYTES
 jne fail
 call neboc_text_runtime_contract
 REQUIRE_EQ eax,NEBO_TEXT_ABI_VERSION
 REQUIRE_EQ edx,NEBO_TEXT_DESCRIPTOR_SIZE
 REQUIRE_EQ ecx,NEBO_TEXT_ENCODING_UTF8
 REQUIRE_EQ r8d,NEBO_TEXT_RUNTIME_FEATURES
 REQUIRE_EQ r9,MAX_TEXT_BYTES

 mov qword [rel view],0x11111111
 lea rdi,[rel source]
 mov esi,1
 mov edx,3
 lea rcx,[rel view]
 call neboc_text_view
 REQUIRE_EQ eax,NEBO_TEXT_OK
 lea rax,[rel data+1]
 cmp [rel view+NEBO_TEXT_DATA_OFFSET],rax
 jne fail
 cmp qword [rel view+NEBO_TEXT_LENGTH_OFFSET],3
 jne fail
 lea rax,[rel source]
 cmp [rel view+NEBO_TEXT_VIEW_SOURCE_OFFSET],rax
 jne fail

 mov r10,[rel view]
 lea rdi,[rel source]
 mov esi,4
 mov edx,2
 lea rcx,[rel view]
 call neboc_text_view
 REQUIRE_EQ eax,NEBO_TEXT_ERROR_BOUNDS
 cmp [rel view],r10
 jne fail

 lea rdi,[rel source]
 mov rsi,-1
 mov edx,1
 lea rcx,[rel view]
 call neboc_text_view
 REQUIRE_EQ eax,NEBO_TEXT_ERROR_BOUNDS
 xor ecx,ecx
 call neboc_text_view
 REQUIRE_EQ eax,NEBO_TEXT_ERROR_NULL

 lea rdi,[rel source]
 lea rsi,[rel copy]
 call neboc_text_copy
 REQUIRE_EQ eax,NEBO_TEXT_OK
 lea rax,[rel data]
 cmp [rel copy+NEBO_TEXT_DATA_OFFSET],rax
 jne fail
 cmp qword [rel copy+NEBO_TEXT_LENGTH_OFFSET],5
 jne fail
 cmp qword [rel copy+NEBO_TEXT_AUX_OFFSET],0
 jne fail

 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,2
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
