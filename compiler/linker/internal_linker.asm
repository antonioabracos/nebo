; INTERNAL-LINKER-F05 bounded internal static ELF64 linker for a fixed exit-zero payload.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/linker/internal_linker.inc"
section .text
NEBOC_ABI_FUNCTION neboc_internal_linker_new
 test rdi,rdi
 jz .invalid
 cmp rsi,1
 jne .target
 cmp rdx,NEBOC_LINK_PROFILE_STATIC_X86_64
 jne .target
 test rcx,rcx
 jz .limit
 cmp rcx,16
 ja .limit
 mov [rdi],rsi
 mov [rdi+8],rdx
 mov [rdi+16],rcx
 mov ecx,6
 lea rdi,[rdi+24]
 xor eax,eax
 rep stosq
 ret
.target: mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_linker_add_object
 ; rsi=image, rdx=size, rcx=digest token.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rdx,64
 jb .source
 cmp dword [rsi],0x464c457f
 jne .source
 cmp word [rsi+16],1
 jne .source
 cmp word [rsi+18],62
 jne .target
 mov rax,[rdi+24]
 cmp rax,[rdi+16]
 jae .limit
 inc qword [rdi+24]
 xor [rdi+56],rcx
 xor eax,eax
 ret
.target: mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_linker_add_archive
 ; Bounded verified archive descriptor token; one lazy archive maximum.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 cmp rdx,1
 jne .source
 cmp qword [rdi+32],1
 jae .limit
 inc qword [rdi+32]
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_linker_resolve_symbols
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+24],0
 je .source
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_linker_build_reachability
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 cmp rsi,16
 ja .limit
 mov [rdi+40],rsi
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_linker_layout
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+24],0
 je .source
 cmp rsi,1
 jne .source
 mov qword [rdi+48],NEBOC_LINK_IMAGE_SIZE
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_linker_apply_relocations
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+48],NEBOC_LINK_IMAGE_SIZE
 jne .source
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_linker_emit_executable
 ; rsi=buffer, rdx=capacity, rcx=written. Fixed bounded _start exits zero.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rcx,rcx
 jz .invalid
 mov qword [rcx],0
 cmp qword [rdi+48],NEBOC_LINK_IMAGE_SIZE
 jne .source
 cmp rdx,NEBOC_LINK_IMAGE_SIZE
 jb .limit
 mov r9,rcx
 mov r8,rsi
 mov rdi,rsi
 xor eax,eax
 mov ecx,17
 rep stosq
 mov rsi,r8
 mov dword [rsi],0x464c457f
 mov byte [rsi+4],2
 mov byte [rsi+5],1
 mov byte [rsi+6],1
 mov word [rsi+16],2
 mov word [rsi+18],62
 mov dword [rsi+20],1
 mov qword [rsi+24],NEBOC_LINK_ENTRY
 mov qword [rsi+32],64
 mov word [rsi+52],64
 mov word [rsi+54],56
 mov word [rsi+56],1
 mov dword [rsi+64],1
 mov dword [rsi+68],5
 mov qword [rsi+72],0
 mov qword [rsi+80],0x400000
 mov qword [rsi+88],0x400000
 mov qword [rsi+96],NEBOC_LINK_IMAGE_SIZE
 mov qword [rsi+104],NEBOC_LINK_IMAGE_SIZE
 mov qword [rsi+112],4096
 mov byte [rsi+120],0xb8
 mov dword [rsi+121],60
 mov word [rsi+125],0xff31
 mov word [rsi+127],0x050f
 mov qword [r9],NEBOC_LINK_IMAGE_SIZE
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_linker_map_file
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov ecx,9
.copy:
 mov rax,[rdi]
 mov [rsi],rax
 add rdi,8
 add rsi,8
 loop .copy
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_linker_verify
 ; rsi=image, rdx=size.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rdx,NEBOC_LINK_IMAGE_SIZE
 jb .source
 cmp dword [rsi],0x464c457f
 jne .source
 cmp word [rsi+16],2
 jne .source
 cmp word [rsi+18],62
 jne .source
 cmp dword [rsi+64],1
 jne .source
 cmp dword [rsi+68],5
 jne .source
 cmp qword [rsi+32],64
 jne .source
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_linker_compare_external_oracle
 ; rsi=internal semantic digest, rdx=external semantic digest, rcx=result.
 test rdi,rdi
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp rsi,rdx
 jne .mismatch
 mov qword [rcx],1
 xor eax,eax
 ret
.mismatch: inc qword [rdi+64]
 mov qword [rcx],0
 mov eax,NEBOC_STATUS_TOOLCHAIN_ERROR
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_link_internal
 jmp neboc_linker_emit_executable
section .note.GNU-stack noalloc noexec nowrite progbits
