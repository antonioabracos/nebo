; ASSEMBLER-IR-F04 internal bounded ELF64 relocatable header writer.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/assembler/assembler_ir.inc"
%include "compiler/format/internal_object_writer.inc"
section .text
NEBOC_ABI_FUNCTION neboc_internal_object_writer_new
 test rdi,rdi
 jz .invalid
 cmp rsi,NEBOC_ASM_TARGET_X86_64_ELF
 jne .target
 cmp rdx,NEBOC_IOW_ELF64
 jne .target
 mov [rdi],rsi
 mov [rdi+8],rdx
 mov qword [rdi+16],0
 mov qword [rdi+24],0
 mov qword [rdi+32],0
 mov qword [rdi+40],0
 mov rax,NEBOC_IOW_DIGEST_SEED
 mov [rdi+48],rax
 mov qword [rdi+56],0
 xor eax,eax
 ret
.target: mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_object_writer_consume
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rsi],NEBOC_ASM_TARGET_X86_64_ELF
 jne .target
 cmp qword [rsi+16],0
 je .source
 mov rax,[rsi+16]
 cmp rax,32
 ja .limit
 mov [rdi+16],rax
 mov rax,[rsi+24]
 mov [rdi+24],rax
 mov rax,[rsi+64]
 mov [rdi+32],rax
 mov rax,[rsi+32]
 add rax,[rsi+40]
 jc .limit
 add rax,[rsi+48]
 jc .limit
 mov [rdi+40],rax
 xor [rdi+48],rax
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
NEBOC_ABI_FUNCTION neboc_object_writer_layout_sections
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+16],0
 je .source
 mov qword [rdi+56],NEBOC_IOW_IMAGE_SIZE
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_object_writer_build_symbol_table
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+24],128
 ja .limit
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_object_writer_build_relocations
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+32],256
 ja .limit
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_object_writer_emit_bytes
 ; rsi=buffer, rdx=capacity, rcx=written. Failure leaves written=0.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rcx,rcx
 jz .invalid
 mov qword [rcx],0
 cmp qword [rdi+56],NEBOC_IOW_IMAGE_SIZE
 jne .source
 cmp rdx,NEBOC_IOW_IMAGE_SIZE
 jb .limit
 mov r9,rcx
 xor eax,eax
 mov r8,rsi
 mov rdi,rsi
 mov ecx,8
 rep stosq
 mov rsi,r8
 mov dword [rsi],0x464c457f
 mov byte [rsi+4],2
 mov byte [rsi+5],1
 mov byte [rsi+6],1
 mov byte [rsi+7],0
 mov word [rsi+16],1
 mov word [rsi+18],62
 mov dword [rsi+20],1
 mov word [rsi+52],64
 mov word [rsi+54],0
 mov word [rsi+56],0
 mov word [rsi+58],0
 mov word [rsi+60],0
 mov word [rsi+62],0
 mov qword [r9],NEBOC_IOW_IMAGE_SIZE
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_object_writer_verify_roundtrip
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rdx,NEBOC_IOW_IMAGE_SIZE
 jb .source
 cmp dword [rsi],0x464c457f
 jne .source
 cmp byte [rsi+4],2
 jne .source
 cmp word [rsi+16],1
 jne .source
 cmp word [rsi+18],62
 jne .source
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_object_writer_normalized_digest
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+48]
 rol rax,17
 xor rax,[rdi+16]
 xor rax,[rdi+24]
 xor rax,[rdi+32]
 mov [rsi],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_object_writer_report
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov ecx,8
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
NEBOC_ABI_FUNCTION neboc_cli_object_build
 jmp neboc_object_writer_emit_bytes
NEBOC_ABI_FUNCTION neboc_cli_object_verify
 ; rdi=image rsi=size; use a dummy non-null writer token.
 test rdi,rdi
 jz .invalid
 mov rdx,rsi
 mov rsi,rdi
 mov rdi,1
 jmp neboc_object_writer_verify_roundtrip
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
