; TIPOS-PRIMITIVOS-ESCALARES-F03 bounded immutable Bytes read/slice lowering
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/textual/bytes_access_lowering.inc"

section .text
NEBOC_ABI_FUNCTION neboc_bytes_access_lower
 test rdi,rdi
 jz .invalid
 mov qword [rdi+NEBOC_BYTES_ACCESS_RESULT_VALUE_OFFSET],0
 mov qword [rdi+NEBOC_BYTES_ACCESS_RESULT_LENGTH_OFFSET],0
 mov qword [rdi+NEBOC_BYTES_ACCESS_RESULT_PACKED_OFFSET],0
 mov qword [rdi+NEBOC_BYTES_ACCESS_OPTION_TAG_OFFSET],0
 mov qword [rdi+NEBOC_BYTES_ACCESS_ERROR_OFFSET],NEBOC_BYTES_ACCESS_ERROR_NONE
 mov rax,[rdi+NEBOC_BYTES_ACCESS_OPERATION_OFFSET]
 cmp rax,NEBOC_BYTES_ACCESS_AT
 je .at
 cmp rax,NEBOC_BYTES_ACCESS_GET
 je .get
 cmp rax,NEBOC_BYTES_ACCESS_SLICE
 je .slice
 mov qword [rdi+NEBOC_BYTES_ACCESS_ERROR_OFFSET],NEBOC_BYTES_ACCESS_ERROR_OPERATION
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.at:
 mov rcx,[rdi+NEBOC_BYTES_ACCESS_INDEX_OFFSET]
 cmp rcx,[rdi+NEBOC_BYTES_ACCESS_LENGTH_OFFSET]
 jae .bounds
 mov rax,[rdi+NEBOC_BYTES_ACCESS_PACKED_OFFSET]
 shl rcx,3
 shr rax,cl
 and eax,255
 mov [rdi+NEBOC_BYTES_ACCESS_RESULT_VALUE_OFFSET],rax
 xor eax,eax
 ret
.get:
 mov rcx,[rdi+NEBOC_BYTES_ACCESS_INDEX_OFFSET]
 cmp rcx,[rdi+NEBOC_BYTES_ACCESS_LENGTH_OFFSET]
 jae .ok
 mov rax,[rdi+NEBOC_BYTES_ACCESS_PACKED_OFFSET]
 shl rcx,3
 shr rax,cl
 and eax,255
 mov [rdi+NEBOC_BYTES_ACCESS_RESULT_VALUE_OFFSET],rax
 mov qword [rdi+NEBOC_BYTES_ACCESS_OPTION_TAG_OFFSET],1
.ok:
 xor eax,eax
 ret
.slice:
 mov rcx,[rdi+NEBOC_BYTES_ACCESS_INDEX_OFFSET]
 mov rdx,[rdi+NEBOC_BYTES_ACCESS_END_OFFSET]
 cmp rcx,rdx
 ja .range
 cmp rdx,[rdi+NEBOC_BYTES_ACCESS_LENGTH_OFFSET]
 ja .range
 sub rdx,rcx
 mov [rdi+NEBOC_BYTES_ACCESS_RESULT_LENGTH_OFFSET],rdx
 mov rax,[rdi+NEBOC_BYTES_ACCESS_PACKED_OFFSET]
 shl rcx,3
 shr rax,cl
 test rdx,rdx
 jz .slice_zero
 cmp rdx,8
 jae .slice_store
 mov rcx,rdx
 shl rcx,3
 mov r8,1
 shl r8,cl
 dec r8
 and rax,r8
.slice_store:
 mov [rdi+NEBOC_BYTES_ACCESS_RESULT_PACKED_OFFSET],rax
 xor eax,eax
 ret
.slice_zero:
 mov qword [rdi+NEBOC_BYTES_ACCESS_RESULT_PACKED_OFFSET],0
 xor eax,eax
 ret
.bounds:
 mov qword [rdi+NEBOC_BYTES_ACCESS_ERROR_OFFSET],NEBOC_BYTES_ACCESS_ERROR_BOUNDS
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.range:
 mov qword [rdi+NEBOC_BYTES_ACCESS_ERROR_OFFSET],NEBOC_BYTES_ACCESS_ERROR_RANGE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
