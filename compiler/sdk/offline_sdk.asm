; OFFLINE-SDK-F10 deterministic offline SDK manifest/archive and bounded memory restore.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/sdk/offline_sdk.inc"
section .text
NEBOC_ABI_FUNCTION neboc_sdk_package_new
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 test rdx,rdx
 jz .source
 test rcx,rcx
 jz .source
 mov [rdi],rsi
 mov [rdi+8],rdx
 mov [rdi+16],rcx
 mov ecx,8
 lea rdi,[rdi+24]
 xor eax,eax
 rep stosq
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_sdk_add_binary
 ; rsi=normalized path token 1..65535, rdx=role token.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 cmp rsi,65535
 ja .source
 test rdx,rdx
 jz .source
 cmp qword [rdi+24],NEBOC_SDK_MAX_BINARIES
 jae .limit
 inc qword [rdi+24]
 xor [rdi+56],rsi
 xor [rdi+56],rdx
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_sdk_add_target_pack
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 cmp qword [rdi+16],NEBOC_SDK_MAX_PACKS
 ja .limit
 xor [rdi+56],rsi
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_sdk_add_documentation
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 mov [rdi+32],rsi
 xor [rdi+56],rsi
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_sdk_add_licenses
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 mov [rdi+40],rsi
 xor [rdi+56],rsi
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_sdk_create_manifest
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+24],0
 je .source
 cmp qword [rdi+32],0
 je .source
 cmp qword [rdi+40],0
 je .source
 mov rax,[rdi+24]
 add rax,[rdi+16]
 add rax,2
 mov [rdi+48],rax
 mov [rsi],rax
 mov rax,[rdi+56]
 xor rax,[rdi]
 xor rax,[rdi+8]
 mov [rdi+56],rax
 mov [rsi+8],rax
 mov qword [rsi+16],0x1ed
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_sdk_pack
 ; rsi=buffer, rdx=capacity, rcx=written. No timestamp/path/source bytes.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rcx,rcx
 jz .invalid
 mov qword [rcx],0
 cmp qword [rdi+48],0
 je .source
 cmp rdx,NEBOC_SDK_IMAGE_SIZE
 jb .limit
 mov r10,rdi
 mov r9,rcx
 mov r8,rsi
 mov rdi,rsi
 xor eax,eax
 mov ecx,12
 rep stosq
 mov rsi,r8
 mov rax,NEBOC_SDK_MAGIC
 mov [rsi],rax
 mov qword [rsi+8],1
 mov qword [rsi+16],NEBOC_SDK_IMAGE_SIZE
 mov rax,[r10]
 mov [rsi+24],rax
 mov rax,[r10+8]
 mov [rsi+32],rax
 mov rax,[r10+16]
 mov [rsi+40],rax
 mov rax,[r10+48]
 mov [rsi+48],rax
 mov rax,[r10+56]
 mov [rsi+56],rax
 mov qword [rsi+64],0x1ed
 mov qword [rsi+72],1
 mov qword [rsi+80],0
 mov qword [rsi+88],0
 mov qword [r9],NEBOC_SDK_IMAGE_SIZE
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_sdk_verify
 ; rsi=image, rdx=size, rcx=report.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp rdx,NEBOC_SDK_IMAGE_SIZE
 jne .source
 mov rax,NEBOC_SDK_MAGIC
 cmp [rsi],rax
 jne .source
 cmp qword [rsi+16],NEBOC_SDK_IMAGE_SIZE
 jne .source
 cmp qword [rsi+72],1
 jne .source
 mov rax,[rdi+56]
 cmp [rsi+56],rax
 jne .source
 mov qword [rdi+64],1
 mov qword [rcx],1
 mov qword [rcx+8],0
 xor eax,eax
 ret
.source: mov qword [rcx],0
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_sdk_restore
 ; Bounded memory restore: rsi=image, rdx=size, rcx=destination token.
 test rdi,rdi
 jz .invalid
 test rcx,rcx
 jz .source
 cmp rcx,65535
 ja .source
 cmp qword [rdi+64],1
 jne .source
 test rsi,rsi
 jz .invalid
 cmp rdx,NEBOC_SDK_IMAGE_SIZE
 jne .source
 mov qword [rdi+72],1
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_sdk_self_test
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+72],1
 jne .source
 mov qword [rdi+80],6
 mov qword [rsi],6
 mov qword [rsi+8],0
 mov qword [rsi+16],1
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_sdk_uninstall_manifest
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+48]
 mov [rsi],rax
 mov qword [rsi+8],0
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_sdk_pack
 jmp neboc_sdk_pack
NEBOC_ABI_FUNCTION neboc_cli_sdk_action
 ; rdi=sdk rsi=action rdx=image rcx=report_or_destination; image size is fixed.
 cmp rsi,NEBOC_SDK_ACTION_VERIFY
 je .verify
 cmp rsi,NEBOC_SDK_ACTION_RESTORE
 je .restore
 cmp rsi,NEBOC_SDK_ACTION_SELFTEST
 je .selftest
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.verify:
 mov rsi,rdx
 mov edx,NEBOC_SDK_IMAGE_SIZE
 jmp neboc_sdk_verify
.restore:
 mov rsi,rdx
 mov edx,NEBOC_SDK_IMAGE_SIZE
 jmp neboc_sdk_restore
.selftest:
 mov rsi,rcx
 jmp neboc_sdk_self_test
section .note.GNU-stack noalloc noexec nowrite progbits
