; TIPOS-PRIMITIVOS-ESCALARES-F02 bounded non-empty Bytes constructor lowering
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/textual/bytes_constructor_lowering.inc"

section .text
NEBOC_ABI_FUNCTION neboc_bytes_constructor_lower
 test rdi,rdi
 jz .invalid
 mov qword [rdi+NEBOC_BYTES_LOWER_LENGTH_OFFSET],0
 mov qword [rdi+NEBOC_BYTES_LOWER_PACKED_OFFSET],0
 mov qword [rdi+NEBOC_BYTES_LOWER_FLAGS_OFFSET],0
 mov qword [rdi+NEBOC_BYTES_LOWER_ERROR_OFFSET],NEBOC_BYTES_LOWER_ERROR_NONE
 mov rax,[rdi+NEBOC_BYTES_LOWER_KIND_OFFSET]
 cmp rax,NEBOC_BYTES_LOWER_FROM_BYTE
 je .one
 cmp rax,NEBOC_BYTES_LOWER_FROM_VALUES
 je .four
 mov qword [rdi+NEBOC_BYTES_LOWER_ERROR_OFFSET],NEBOC_BYTES_LOWER_ERROR_KIND
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.one:
 cmp qword [rdi+NEBOC_BYTES_LOWER_COUNT_OFFSET],1
 jne .arity
 mov ecx,1
 jmp .values
.four:
 cmp qword [rdi+NEBOC_BYTES_LOWER_COUNT_OFFSET],4
 jne .arity
 mov ecx,4
.values:
 xor eax,eax
.loop:
 cmp eax,ecx
 jae .ok
 mov rdx,[rdi+NEBOC_BYTES_LOWER_VALUE0_OFFSET+rax*8]
 cmp rdx,255
 ja .range
 mov byte [rdi+NEBOC_BYTES_LOWER_PACKED_OFFSET+rax],dl
 inc eax
 jmp .loop
.ok:
 mov [rdi+NEBOC_BYTES_LOWER_LENGTH_OFFSET],rcx
 mov qword [rdi+NEBOC_BYTES_LOWER_FLAGS_OFFSET],NEBOC_BYTES_LOWER_FLAGS_STATIC_IMMUTABLE
 xor eax,eax
 ret
.arity:
 mov qword [rdi+NEBOC_BYTES_LOWER_ERROR_OFFSET],NEBOC_BYTES_LOWER_ERROR_ARITY
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.range:
 mov qword [rdi+NEBOC_BYTES_LOWER_ERROR_OFFSET],NEBOC_BYTES_LOWER_ERROR_RANGE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
