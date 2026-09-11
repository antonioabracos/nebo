bits 64
default rel
%include "compiler/sdk/offline_sdk.inc"
global _start
extern neboc_sdk_package_new,neboc_sdk_add_binary,neboc_sdk_add_target_pack
extern neboc_sdk_add_documentation,neboc_sdk_add_licenses,neboc_sdk_create_manifest
extern neboc_sdk_pack,neboc_sdk_verify,neboc_sdk_restore,neboc_sdk_self_test
extern neboc_sdk_uninstall_manifest,neboc_cli_sdk_pack,neboc_cli_sdk_action,neboc_host_process_exit
section .bss align=16
sdk: resb NEBOC_SDK_SIZE
image: resb NEBOC_SDK_IMAGE_SIZE
out: resq 8
section .text
_start:
 sub rsp,8
 lea rdi,[rel sdk]
 mov esi,1
 mov edx,0x11
 mov ecx,1
 call neboc_sdk_package_new
 test eax,eax
 jne .f1
 lea rdi,[rel sdk]
 mov esi,1
 mov edx,1
 call neboc_sdk_add_binary
 test eax,eax
 jne .f2
 lea rdi,[rel sdk]
 mov esi,0x22
 call neboc_sdk_add_target_pack
 test eax,eax
 jne .f3
 lea rdi,[rel sdk]
 mov esi,0x33
 call neboc_sdk_add_documentation
 lea rdi,[rel sdk]
 mov esi,0x44
 call neboc_sdk_add_licenses
 lea rdi,[rel sdk]
 lea rsi,[rel out]
 call neboc_sdk_create_manifest
 test eax,eax
 jne .f4
 cmp qword [rel out],4
 jne .f5
 lea rdi,[rel sdk]
 lea rsi,[rel image]
 mov edx,NEBOC_SDK_IMAGE_SIZE
 lea rcx,[rel out]
 call neboc_sdk_pack
 test eax,eax
 jne .f6
 cmp qword [rel out],NEBOC_SDK_IMAGE_SIZE
 jne .f7
 lea rdi,[rel sdk]
 lea rsi,[rel image]
 mov edx,NEBOC_SDK_IMAGE_SIZE
 lea rcx,[rel out]
 call neboc_sdk_verify
 test eax,eax
 jne .f8
 lea rdi,[rel sdk]
 lea rsi,[rel image]
 mov edx,NEBOC_SDK_IMAGE_SIZE
 mov ecx,1
 call neboc_sdk_restore
 test eax,eax
 jne .f9
 lea rdi,[rel sdk]
 lea rsi,[rel out]
 call neboc_sdk_self_test
 cmp qword [rel out],6
 jne .f10
 cmp qword [rel out+8],0
 jne .f11
 lea rdi,[rel sdk]
 lea rsi,[rel out]
 call neboc_sdk_uninstall_manifest
 cmp qword [rel out],4
 jne .f12
 lea rdi,[rel sdk]
 lea rsi,[rel image]
 mov edx,95
 lea rcx,[rel out]
 call neboc_cli_sdk_pack
 cmp eax,8
 jne .f13
 lea rdi,[rel sdk]
 mov esi,1
 lea rdx,[rel image]
 lea rcx,[rel out]
 call neboc_cli_sdk_action
 test eax,eax
 jne .f14
 mov qword [rel image+72],0
 lea rdi,[rel sdk]
 lea rsi,[rel image]
 mov edx,NEBOC_SDK_IMAGE_SIZE
 lea rcx,[rel out]
 call neboc_sdk_verify
 cmp eax,4
 jne .f15
 lea rdi,[rel sdk]
 mov rsi,0x10000
 mov edx,1
 call neboc_sdk_add_binary
 cmp eax,4
 jne .f16
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 16
.f%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
