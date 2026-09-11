bits 64
default rel
%include "compiler/meta/compile_eval.inc"
extern nebo_compile_eval_binary,nebo_compile_resource_validate,nebo_compile_cache_key
section .data
bytes db 1,2,3,4
section .bss
result_value resq 1
resource_desc resb NEBO_RESOURCE_DESC_SIZE
section .text
global _start
_start:
 mov edi,NEBO_EVAL_ADD
 mov esi,40
 mov edx,2
 lea rcx,[result_value]
 mov r8d,1
 call nebo_compile_eval_binary
 test eax,eax
 jnz fail
 cmp qword [result_value],42
 jne fail
 mov edi,NEBO_EVAL_ADD
 mov rsi,0x7fffffffffffffff
 mov edx,1
 lea rcx,[result_value]
 mov r8d,1
 call nebo_compile_eval_binary
 cmp eax,NEBO_EVAL_STATUS_OVERFLOW
 jne fail
 cmp qword [result_value],0
 jne fail
 lea rax,[bytes]
 mov [resource_desc+NEBO_RESOURCE_DATA],rax
 mov qword [resource_desc+NEBO_RESOURCE_SIZE],4
 mov qword [resource_desc+NEBO_RESOURCE_HASH_LO],0x1234
 mov qword [resource_desc+NEBO_RESOURCE_HASH_HI],0x5678
 mov qword [resource_desc+NEBO_RESOURCE_MEDIA_TYPE],1
 mov qword [resource_desc+NEBO_RESOURCE_CAPABILITY],1
 lea rdi,[resource_desc]
 call nebo_compile_resource_validate
 test eax,eax
 jnz fail
 mov qword [resource_desc+NEBO_RESOURCE_CAPABILITY],0
 lea rdi,[resource_desc]
 call nebo_compile_resource_validate
 cmp eax,NEBO_EVAL_STATUS_CAPABILITY
 jne fail
 mov edi,1
 mov esi,2
 mov edx,3
 call nebo_compile_cache_key
 test rax,rax
 jz fail
 xor edi,edi
 mov eax,60
 syscall
fail: mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
