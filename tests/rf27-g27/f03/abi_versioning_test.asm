bits 64
default rel
%include "compiler/abi/abi_versioning.inc"
extern nebo_abi_metadata_init,nebo_abi_validate,nebo_abi_link_check
section .bss
align 16
metadata resb NEBO_ABI_METADATA_SIZE*2
report resb NEBO_ABI_REPORT_SIZE
init_req resb NEBO_ABI_INIT_SIZE
validate_req resb NEBO_ABI_VALIDATE_SIZE
link_req resb NEBO_ABI_LINK_SIZE
section .text
global _start
_start:
 lea rdi,[init_req]
 mov ecx,NEBO_ABI_INIT_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[metadata]
 mov [init_req+NEBO_ABI_INIT_OUTPUT],rax
 mov qword [init_req+NEBO_ABI_INIT_CAPACITY],NEBO_ABI_METADATA_SIZE
 mov qword [init_req+NEBO_ABI_INIT_FEATURES],3
 lea rdi,[init_req]
 call nebo_abi_metadata_init
 test eax,eax
 jnz fail
 cmp qword [init_req+NEBO_ABI_INIT_RESULT],NEBO_ABI_METADATA_SIZE
 jne fail
 mov rax,NEBO_ABI_METADATA_MAGIC
 cmp [metadata+NEBO_ABI_METADATA_MAGIC_OFF],rax
 jne fail
 cmp qword [metadata+NEBO_ABI_METADATA_ABI_MAJOR],0
 jne fail
 lea rax,[metadata+NEBO_ABI_METADATA_SIZE]
 mov [init_req+NEBO_ABI_INIT_OUTPUT],rax
 mov qword [init_req+NEBO_ABI_INIT_FEATURES],5
 lea rdi,[init_req]
 call nebo_abi_metadata_init
 test eax,eax
 jnz fail
 lea rdi,[validate_req]
 mov ecx,NEBO_ABI_VALIDATE_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[metadata]
 mov [validate_req+NEBO_ABI_VALIDATE_METADATA],rax
 lea rax,[report]
 mov [validate_req+NEBO_ABI_VALIDATE_REPORT],rax
 mov qword [validate_req+NEBO_ABI_VALIDATE_CAPACITY],NEBO_ABI_REPORT_SIZE
 mov qword [validate_req+NEBO_ABI_VALIDATE_SUPPORTED],NEBO_ABI_FEATURE_KNOWN_MASK
 lea rdi,[validate_req]
 call nebo_abi_validate
 test eax,eax
 jnz fail
 cmp qword [validate_req+NEBO_ABI_VALIDATE_RESULT],NEBO_ABI_REPORT_SIZE
 jne fail
 cmp qword [report+NEBO_ABI_REPORT_OBJECT_COUNT],1
 jne fail
 cmp qword [report+NEBO_ABI_REPORT_FEATURES],3
 jne fail
 lea rdi,[link_req]
 mov ecx,NEBO_ABI_LINK_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[metadata]
 mov [link_req+NEBO_ABI_LINK_OBJECTS],rax
 mov qword [link_req+NEBO_ABI_LINK_COUNT],2
 mov qword [link_req+NEBO_ABI_LINK_STRIDE],NEBO_ABI_METADATA_SIZE
 lea rax,[report]
 mov [link_req+NEBO_ABI_LINK_REPORT],rax
 mov qword [link_req+NEBO_ABI_LINK_CAPACITY],NEBO_ABI_REPORT_SIZE
 mov qword [link_req+NEBO_ABI_LINK_SUPPORTED],NEBO_ABI_FEATURE_KNOWN_MASK
 lea rdi,[link_req]
 call nebo_abi_link_check
 test eax,eax
 jnz fail
 cmp qword [report+NEBO_ABI_REPORT_OBJECT_COUNT],2
 jne fail
 cmp qword [report+NEBO_ABI_REPORT_FEATURES],7
 jne fail
 cmp qword [link_req+NEBO_ABI_LINK_RESULT],NEBO_ABI_REPORT_SIZE
 jne fail
 mov qword [report],0x55
 mov qword [metadata+NEBO_ABI_METADATA_ABI_MAJOR],1
 lea rdi,[validate_req]
 call nebo_abi_validate
 cmp eax,NEBO_ABI_STATUS_ABI_VERSION
 jne fail
 cmp qword [report],0x55
 jne fail
 mov qword [metadata+NEBO_ABI_METADATA_ABI_MAJOR],0
 mov qword [metadata+NEBO_ABI_METADATA_RUNTIME_MAJOR],1
 lea rdi,[validate_req]
 call nebo_abi_validate
 cmp eax,NEBO_ABI_STATUS_RUNTIME_VERSION
 jne fail
 mov qword [metadata+NEBO_ABI_METADATA_RUNTIME_MAJOR],0
 mov qword [metadata+NEBO_ABI_METADATA_OBJECT_VERSION],2
 lea rdi,[validate_req]
 call nebo_abi_validate
 cmp eax,NEBO_ABI_STATUS_OBJECT_VERSION
 jne fail
 mov qword [metadata+NEBO_ABI_METADATA_OBJECT_VERSION],NEBO_OBJECT_METADATA_VERSION
 mov qword [metadata+NEBO_ABI_METADATA_SCHEMA],2
 lea rdi,[validate_req]
 call nebo_abi_validate
 cmp eax,NEBO_ABI_STATUS_SCHEMA
 jne fail
 mov qword [metadata+NEBO_ABI_METADATA_SCHEMA],NEBO_ABI_SCHEMA_VERSION
 mov rax,0x616172636836346c
 mov [metadata+NEBO_ABI_METADATA_TARGET],rax
 lea rdi,[validate_req]
 call nebo_abi_validate
 cmp eax,NEBO_ABI_STATUS_TARGET
 jne fail
 mov rax,NEBO_ABI_TARGET_X86_64_SYSTEMV_ELF_LINUX
 mov [metadata+NEBO_ABI_METADATA_TARGET],rax
 mov qword [metadata+NEBO_ABI_METADATA_MAGIC_OFF],0
 lea rdi,[validate_req]
 call nebo_abi_validate
 cmp eax,NEBO_ABI_STATUS_CORRUPT
 jne fail
 mov rax,NEBO_ABI_METADATA_MAGIC
 mov [metadata+NEBO_ABI_METADATA_MAGIC_OFF],rax
 mov qword [metadata+NEBO_ABI_METADATA_REQUIRED_FEATURES],32
 lea rdi,[validate_req]
 call nebo_abi_validate
 cmp eax,NEBO_ABI_STATUS_FEATURE
 jne fail
 mov qword [metadata+NEBO_ABI_METADATA_REQUIRED_FEATURES],3
 mov qword [validate_req+NEBO_ABI_VALIDATE_SUPPORTED],1
 lea rdi,[validate_req]
 call nebo_abi_validate
 cmp eax,NEBO_ABI_STATUS_FEATURE
 jne fail
 mov qword [validate_req+NEBO_ABI_VALIDATE_SUPPORTED],NEBO_ABI_FEATURE_KNOWN_MASK
 mov qword [metadata+NEBO_ABI_METADATA_DATALAYOUT],0
 lea rdi,[validate_req]
 call nebo_abi_validate
 cmp eax,NEBO_ABI_STATUS_DATALAYOUT
 jne fail
 mov qword [metadata+NEBO_ABI_METADATA_DATALAYOUT],NEBO_ABI_DATALAYOUT_X86_64_SYSTEMV_ELF
 mov qword [metadata],0x77
 mov qword [init_req+NEBO_ABI_INIT_FEATURES],32
 lea rax,[metadata]
 mov [init_req+NEBO_ABI_INIT_OUTPUT],rax
 lea rdi,[init_req]
 call nebo_abi_metadata_init
 cmp eax,NEBO_ABI_STATUS_FEATURE
 jne fail
 cmp qword [metadata],0x77
 jne fail
 mov qword [link_req+NEBO_ABI_LINK_COUNT],65
 mov qword [report],0x66
 lea rdi,[link_req]
 call nebo_abi_link_check
 cmp eax,NEBO_ABI_STATUS_LIMIT
 jne fail
 cmp qword [report],0x66
 jne fail
 mov qword [link_req+NEBO_ABI_LINK_COUNT],2
 mov qword [metadata+NEBO_ABI_METADATA_ABI_MAJOR],0
 mov qword [metadata+NEBO_ABI_METADATA_MAGIC_OFF],0
 lea rdi,[link_req]
 call nebo_abi_link_check
 cmp eax,NEBO_ABI_STATUS_CORRUPT
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
