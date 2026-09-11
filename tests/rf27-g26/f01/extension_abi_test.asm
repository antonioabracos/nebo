bits 64
default rel
%include "compiler/semantic/plugins/extension_abi.inc"
extern nebo_extension_validate
section .bss
desc resb NEBO_EXTENSION_DESC_SIZE
report resb NEBO_EXTENSION_REPORT_SIZE
req resb NEBO_EXTENSION_REQ_SIZE
section .text
global _start
_start:
 lea rdi,[desc]
 mov ecx,NEBO_EXTENSION_DESC_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,NEBO_EXTENSION_MAGIC
 mov [desc+NEBO_EXTENSION_DESC_MAGIC],rax
 mov qword [desc+NEBO_EXTENSION_DESC_SCHEMA],NEBO_EXTENSION_SCHEMA
 mov qword [desc+NEBO_EXTENSION_DESC_KIND],NEBO_EXTENSION_KIND_PLUGIN
 mov rax,NEBO_EXTENSION_TARGET
 mov [desc+NEBO_EXTENSION_DESC_TARGET],rax
 mov qword [desc+NEBO_EXTENSION_DESC_ABI],NEBO_EXTENSION_ABI_MAJOR
 mov qword [desc+NEBO_EXTENSION_DESC_RUNTIME],NEBO_EXTENSION_RUNTIME_MAJOR
 mov qword [desc+NEBO_EXTENSION_DESC_EFFECTS],5
 mov qword [desc+NEBO_EXTENSION_DESC_CAPABILITIES],3
 mov qword [desc+NEBO_EXTENSION_DESC_FEATURES],7
 mov qword [desc+NEBO_EXTENSION_DESC_RECORD_SIZE],NEBO_EXTENSION_DESC_SIZE
 lea rax,[desc]
 mov [req+NEBO_EXTENSION_REQ_DESC],rax
 lea rax,[report]
 mov [req+NEBO_EXTENSION_REQ_REPORT],rax
 mov qword [req+NEBO_EXTENSION_REQ_CAPACITY],NEBO_EXTENSION_REPORT_SIZE
 lea rdi,[req]
 call nebo_extension_validate
 test eax,eax
 jnz fail
 cmp qword [req+NEBO_EXTENSION_REQ_RESULT],NEBO_EXTENSION_REPORT_SIZE
 jne fail
 cmp qword [report+NEBO_EXTENSION_REPORT_KIND],NEBO_EXTENSION_KIND_PLUGIN
 jne fail
 cmp qword [report+NEBO_EXTENSION_REPORT_EFFECTS],5
 jne fail
 mov qword [report],0x55
 mov qword [desc+NEBO_EXTENSION_DESC_SCHEMA],2
 lea rdi,[req]
 call nebo_extension_validate
 cmp eax,NEBO_EXTENSION_STATUS_SCHEMA
 jne fail
 cmp qword [report],0x55
 jne fail
 mov qword [desc+NEBO_EXTENSION_DESC_SCHEMA],1
 mov qword [desc+NEBO_EXTENSION_DESC_KIND],4
 lea rdi,[req]
 call nebo_extension_validate
 cmp eax,NEBO_EXTENSION_STATUS_KIND
 jne fail
 mov qword [desc+NEBO_EXTENSION_DESC_KIND],2
 mov qword [desc+NEBO_EXTENSION_DESC_ABI],1
 lea rdi,[req]
 call nebo_extension_validate
 cmp eax,NEBO_EXTENSION_STATUS_ABI_RUNTIME
 jne fail
 mov qword [desc+NEBO_EXTENSION_DESC_ABI],0
 mov qword [desc+NEBO_EXTENSION_DESC_EFFECTS],0x4000
 lea rdi,[req]
 call nebo_extension_validate
 cmp eax,NEBO_EXTENSION_STATUS_EFFECT
 jne fail
 mov qword [desc+NEBO_EXTENSION_DESC_EFFECTS],0
 mov qword [desc+NEBO_EXTENSION_DESC_CAPABILITIES],0x80
 lea rdi,[req]
 call nebo_extension_validate
 cmp eax,NEBO_EXTENSION_STATUS_CAPABILITY
 jne fail
 mov qword [desc+NEBO_EXTENSION_DESC_CAPABILITIES],0
 mov qword [desc+NEBO_EXTENSION_DESC_FEATURES],0x20
 lea rdi,[req]
 call nebo_extension_validate
 cmp eax,NEBO_EXTENSION_STATUS_FEATURE
 jne fail
 mov qword [desc+NEBO_EXTENSION_DESC_FEATURES],0
 mov qword [desc+NEBO_EXTENSION_DESC_RECORD_SIZE],80
 lea rdi,[req]
 call nebo_extension_validate
 cmp eax,NEBO_EXTENSION_STATUS_LAYOUT
 jne fail
 mov qword [desc+NEBO_EXTENSION_DESC_RECORD_SIZE],NEBO_EXTENSION_DESC_SIZE
 mov qword [desc+NEBO_EXTENSION_DESC_MAGIC],0
 lea rdi,[req]
 call nebo_extension_validate
 cmp eax,NEBO_EXTENSION_STATUS_CORRUPT
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
