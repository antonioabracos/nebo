bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/interface/interface_v1.inc"
section .text
NEBOC_ABI_FUNCTION neboc_interface_write
 test rdi,rdi
 jz .arg
 cmp rsi,NEBOC_NI_HEADER_SIZE
 jb .limit
 cmp r9,NEBOC_NI_MAX_SECTIONS
 ja .limit
 mov rax,NEBOC_NI_MAGIC
 mov [rdi],rax
 mov word [rdi+8],NEBOC_NI_VERSION
 mov word [rdi+10],NEBOC_NI_HEADER_SIZE
 mov dword [rdi+12],0
 mov [rdi+24],rdx
 mov [rdi+32],rcx
 mov [rdi+40],r8
 mov [rdi+48],r9d
 mov dword [rdi+52],NEBOC_NI_HEADER_SIZE
 mov qword [rdi+56],0
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
