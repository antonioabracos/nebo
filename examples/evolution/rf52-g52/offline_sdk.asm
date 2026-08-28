; Emits the deterministic bounded SDK archive to stdout without network.
bits 64
default rel
%include "compiler/sdk/offline_sdk.inc"
global _start
extern neboc_sdk_package_new,neboc_sdk_add_binary,neboc_sdk_add_target_pack
extern neboc_sdk_add_documentation,neboc_sdk_add_licenses,neboc_sdk_create_manifest
extern neboc_sdk_pack,neboc_host_process_exit
section .bss align=16
sdk: resb NEBOC_SDK_SIZE
image: resb NEBOC_SDK_IMAGE_SIZE
out: resq 3
section .text
_start:
 sub rsp,8
 lea rdi,[rel sdk]
 mov esi,1
 mov edx,0x11
 mov ecx,1
 call neboc_sdk_package_new
 lea rdi,[rel sdk]
 mov esi,1
 mov edx,1
 call neboc_sdk_add_binary
 lea rdi,[rel sdk]
 mov esi,0x22
 call neboc_sdk_add_target_pack
 lea rdi,[rel sdk]
 mov esi,0x33
 call neboc_sdk_add_documentation
 lea rdi,[rel sdk]
 mov esi,0x44
 call neboc_sdk_add_licenses
 lea rdi,[rel sdk]
 lea rsi,[rel out]
 call neboc_sdk_create_manifest
 lea rdi,[rel sdk]
 lea rsi,[rel image]
 mov edx,NEBOC_SDK_IMAGE_SIZE
 lea rcx,[rel out]
 call neboc_sdk_pack
 test eax,eax
 jne .fail
 mov eax,1
 mov edi,1
 lea rsi,[rel image]
 mov edx,NEBOC_SDK_IMAGE_SIZE
 syscall
 cmp rax,NEBOC_SDK_IMAGE_SIZE
 jne .fail
 xor edi,edi
 call neboc_host_process_exit
.fail: mov edi,1
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
