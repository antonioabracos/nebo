; POTENCIA-XOR-E-COMPARACAO-TOTAL three-way comparison returning the public Ordering scalar.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"

%define NEBOC_ORDERING_LESS 0
%define NEBOC_ORDERING_EQUAL 1
%define NEBOC_ORDERING_GREATER 2

section .text
; ordering_type(left_type, right_type, out_type*)
NEBOC_ABI_FUNCTION neboc_core_ordering_type
 test rdx,rdx
 jz .type_invalid
 cmp rdi,rsi
 jne .type_source
 cmp rdi,NEBOC_TYPE_ID_BOOL
 je .type_ok
 cmp rdi,NEBOC_TYPE_ID_INT
 je .type_ok
 cmp rdi,NEBOC_TYPE_ID_BYTES
 je .type_ok
 jmp .type_source
.type_ok:
 mov qword [rdx],NEBOC_TYPE_ID_ORDERING
 xor eax,eax
 ret
.type_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.type_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; ordering_int(left, right, out_ordering*)
NEBOC_ABI_FUNCTION neboc_core_ordering_int
 test rdx,rdx
 jz .int_invalid
 mov eax,NEBOC_ORDERING_LESS
 cmp rdi,rsi
 jl .int_store
 mov eax,NEBOC_ORDERING_EQUAL
 je .int_store
 mov eax,NEBOC_ORDERING_GREATER
.int_store:
 mov [rdx],rax
 xor eax,eax
 ret
.int_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; ordering_bytes(left*, right*, equal_length, out_ordering*)
NEBOC_ABI_FUNCTION neboc_core_ordering_bytes
 test rcx,rcx
 jz .bytes_invalid
 test rdx,rdx
 jz .bytes_equal
 test rdi,rdi
 jz .bytes_invalid
 test rsi,rsi
 jz .bytes_invalid
 xor r8d,r8d
.bytes_loop:
 cmp r8,rdx
 jae .bytes_equal
 movzx eax,byte [rdi+r8]
 movzx r9d,byte [rsi+r8]
 cmp eax,r9d
 jb .bytes_less
 ja .bytes_greater
 inc r8
 jmp .bytes_loop
.bytes_less:
 mov qword [rcx],NEBOC_ORDERING_LESS
 xor eax,eax
 ret
.bytes_greater:
 mov qword [rcx],NEBOC_ORDERING_GREATER
 xor eax,eax
 ret
.bytes_equal:
 mov qword [rcx],NEBOC_ORDERING_EQUAL
 xor eax,eax
 ret
.bytes_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
