; Nebo Assembly — MF031 first-target DataLayout
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/data-layout/data_layout.inc"

extern neboc_hash_fnv1a32

section .text

; data_layout_init_first_target(layout*)
NEBOC_ABI_FUNCTION neboc_data_layout_init_first_target
 push rbx
 mov rbx,rdi
 test rbx,rbx
 jz .invalid
 mov rdi,rbx
 xor eax,eax
 mov ecx,NEBOC_DATA_LAYOUT_QWORDS
.zero:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .zero
 mov qword [rbx+NEBOC_DATA_LAYOUT_VERSION_OFFSET],NEBOC_DATA_LAYOUT_VERSION
 mov qword [rbx+NEBOC_DATA_LAYOUT_POINTER_SIZE_OFFSET],8
 mov qword [rbx+NEBOC_DATA_LAYOUT_POINTER_ALIGNMENT_OFFSET],8
 mov qword [rbx+NEBOC_DATA_LAYOUT_INT_SIZE_OFFSET],8
 mov qword [rbx+NEBOC_DATA_LAYOUT_INT_ALIGNMENT_OFFSET],8
 mov qword [rbx+NEBOC_DATA_LAYOUT_BOOL_SIZE_OFFSET],1
 mov qword [rbx+NEBOC_DATA_LAYOUT_BOOL_ALIGNMENT_OFFSET],1
 mov qword [rbx+NEBOC_DATA_LAYOUT_BOOL_REPRESENTATION_OFFSET],NEBOC_DATA_LAYOUT_BOOL_ZERO_ONE
 mov qword [rbx+NEBOC_DATA_LAYOUT_SLICE_SIZE_OFFSET],16
 mov qword [rbx+NEBOC_DATA_LAYOUT_SLICE_ALIGNMENT_OFFSET],8
 mov qword [rbx+NEBOC_DATA_LAYOUT_CONSOLE_HANDLE_SIZE_OFFSET],8
 mov qword [rbx+NEBOC_DATA_LAYOUT_CONSOLE_HANDLE_ALIGNMENT_OFFSET],8
 mov qword [rbx+NEBOC_DATA_LAYOUT_PENDING_HANDLE_SIZE_OFFSET],8
 mov qword [rbx+NEBOC_DATA_LAYOUT_PENDING_HANDLE_ALIGNMENT_OFFSET],8
 mov qword [rbx+NEBOC_DATA_LAYOUT_STACK_ALIGNMENT_OFFSET],16
 mov qword [rbx+NEBOC_DATA_LAYOUT_ENDIANNESS_OFFSET],NEBOC_DATA_LAYOUT_ENDIAN_LITTLE
 mov qword [rbx+NEBOC_DATA_LAYOUT_FLAGS_OFFSET],NEBOC_DATA_LAYOUT_REQUIRED_FLAGS
 mov rdi,rbx
 mov esi,NEBOC_DATA_LAYOUT_HASHED_BYTES
 lea rdx,[rbx+NEBOC_DATA_LAYOUT_HASH_OFFSET]
 call neboc_hash_fnv1a32
 test eax,eax
 jnz .hash_failure
 mov qword [rbx+NEBOC_DATA_LAYOUT_STATE_OFFSET],NEBOC_DATA_LAYOUT_STATE_FROZEN
 mov qword [rbx+NEBOC_DATA_LAYOUT_LAST_ERROR_OFFSET],NEBOC_DATA_LAYOUT_ERROR_NONE
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.hash_failure:
 mov qword [rbx+NEBOC_DATA_LAYOUT_LAST_ERROR_OFFSET],NEBOC_DATA_LAYOUT_ERROR_HASH_FAILURE
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INTERNAL_ERROR
.invalid:
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; data_layout_validate(layout*)
NEBOC_ABI_FUNCTION neboc_data_layout_validate
 push rbx
 sub rsp,16
 mov rbx,rdi
 test rbx,rbx
 jz .invalid
 cmp qword [rbx+NEBOC_DATA_LAYOUT_VERSION_OFFSET],NEBOC_DATA_LAYOUT_VERSION
 jne .unsupported
 cmp qword [rbx+NEBOC_DATA_LAYOUT_POINTER_SIZE_OFFSET],8
 jne .unsupported
 cmp qword [rbx+NEBOC_DATA_LAYOUT_POINTER_ALIGNMENT_OFFSET],8
 jne .unsupported
 cmp qword [rbx+NEBOC_DATA_LAYOUT_INT_SIZE_OFFSET],8
 jne .unsupported
 cmp qword [rbx+NEBOC_DATA_LAYOUT_INT_ALIGNMENT_OFFSET],8
 jne .unsupported
 cmp qword [rbx+NEBOC_DATA_LAYOUT_BOOL_SIZE_OFFSET],1
 jne .unsupported
 cmp qword [rbx+NEBOC_DATA_LAYOUT_BOOL_ALIGNMENT_OFFSET],1
 jne .unsupported
 cmp qword [rbx+NEBOC_DATA_LAYOUT_BOOL_REPRESENTATION_OFFSET],NEBOC_DATA_LAYOUT_BOOL_ZERO_ONE
 jne .unsupported
 cmp qword [rbx+NEBOC_DATA_LAYOUT_SLICE_SIZE_OFFSET],16
 jne .unsupported
 cmp qword [rbx+NEBOC_DATA_LAYOUT_SLICE_ALIGNMENT_OFFSET],8
 jne .unsupported
 cmp qword [rbx+NEBOC_DATA_LAYOUT_CONSOLE_HANDLE_SIZE_OFFSET],8
 jne .unsupported
 cmp qword [rbx+NEBOC_DATA_LAYOUT_CONSOLE_HANDLE_ALIGNMENT_OFFSET],8
 jne .unsupported
 cmp qword [rbx+NEBOC_DATA_LAYOUT_PENDING_HANDLE_SIZE_OFFSET],8
 jne .unsupported
 cmp qword [rbx+NEBOC_DATA_LAYOUT_PENDING_HANDLE_ALIGNMENT_OFFSET],8
 jne .unsupported
 cmp qword [rbx+NEBOC_DATA_LAYOUT_STACK_ALIGNMENT_OFFSET],16
 jne .unsupported
 cmp qword [rbx+NEBOC_DATA_LAYOUT_ENDIANNESS_OFFSET],NEBOC_DATA_LAYOUT_ENDIAN_LITTLE
 jne .unsupported
 cmp qword [rbx+NEBOC_DATA_LAYOUT_FLAGS_OFFSET],NEBOC_DATA_LAYOUT_REQUIRED_FLAGS
 jne .unsupported
 cmp qword [rbx+NEBOC_DATA_LAYOUT_STATE_OFFSET],NEBOC_DATA_LAYOUT_STATE_FROZEN
 jne .unsupported
 cmp qword [rbx+NEBOC_DATA_LAYOUT_HASH_OFFSET],0
 je .unsupported
 mov qword [rsp],0
 mov rdi,rbx
 mov esi,NEBOC_DATA_LAYOUT_HASHED_BYTES
 lea rdx,[rsp]
 call neboc_hash_fnv1a32
 test eax,eax
 jnz .internal_error
 mov rax,[rsp]
 cmp rax,[rbx+NEBOC_DATA_LAYOUT_HASH_OFFSET]
 jne .unsupported
 add rsp,16
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.unsupported:
 add rsp,16
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_UNSUPPORTED_TARGET
.invalid:
 add rsp,16
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.internal_error:
 add rsp,16
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INTERNAL_ERROR

section .note.GNU-stack noalloc noexec nowrite progbits
