; Nebo Assembly — TIPOS-PRIMITIVOS-ESCALARES-PF002 foundation scalar descriptor catalogue
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/foundation_scalar_descriptor.inc"

section .rodata align=16

; kind, current TypeId, canonical name id, flags, bit width, size, alignment, reserved
foundation_scalar_descriptors:
 dq NEBOC_FOUNDATION_SCALAR_KIND_VOID,NEBOC_TYPE_ID_VOID,NEBOC_FOUNDATION_SCALAR_NAME_ID_VOID
 dq NEBOC_FOUNDATION_SCALAR_FLAG_PUBLIC | NEBOC_FOUNDATION_SCALAR_FLAG_V01_CERTIFIED | NEBOC_FOUNDATION_SCALAR_FLAG_NO_RUNTIME_PAYLOAD | NEBOC_FOUNDATION_SCALAR_FLAG_TYPE_ID_ASSIGNED
 dq NEBOC_FOUNDATION_VOID_BIT_WIDTH,NEBOC_FOUNDATION_VOID_STORAGE_SIZE,NEBOC_FOUNDATION_VOID_STORAGE_ALIGNMENT,0
 dq NEBOC_FOUNDATION_SCALAR_KIND_BOOL,NEBOC_TYPE_ID_BOOL,NEBOC_FOUNDATION_SCALAR_NAME_ID_BOOL
 dq NEBOC_FOUNDATION_SCALAR_FLAG_PUBLIC | NEBOC_FOUNDATION_SCALAR_FLAG_V01_CERTIFIED | NEBOC_FOUNDATION_SCALAR_FLAG_FIXED_WIDTH | NEBOC_FOUNDATION_SCALAR_FLAG_TYPE_ID_ASSIGNED
 dq NEBOC_FOUNDATION_BOOL_BIT_WIDTH,NEBOC_FOUNDATION_BOOL_STORAGE_SIZE,NEBOC_FOUNDATION_BOOL_STORAGE_ALIGNMENT,0
 dq NEBOC_FOUNDATION_SCALAR_KIND_INT,NEBOC_TYPE_ID_INT,NEBOC_FOUNDATION_SCALAR_NAME_ID_INT
 dq NEBOC_FOUNDATION_SCALAR_FLAG_PUBLIC | NEBOC_FOUNDATION_SCALAR_FLAG_V01_CERTIFIED | NEBOC_FOUNDATION_SCALAR_FLAG_FIXED_WIDTH | NEBOC_FOUNDATION_SCALAR_FLAG_TYPE_ID_ASSIGNED
 dq NEBOC_FOUNDATION_INT_BIT_WIDTH,NEBOC_FOUNDATION_INT_STORAGE_SIZE,NEBOC_FOUNDATION_INT_STORAGE_ALIGNMENT,0
 dq NEBOC_FOUNDATION_SCALAR_KIND_TEXT,NEBOC_TYPE_ID_TEXT,NEBOC_FOUNDATION_SCALAR_NAME_ID_TEXT
 dq NEBOC_FOUNDATION_SCALAR_FLAG_PUBLIC | NEBOC_FOUNDATION_SCALAR_FLAG_V01_CERTIFIED | NEBOC_FOUNDATION_SCALAR_FLAG_DESCRIPTOR_VALUE | NEBOC_FOUNDATION_SCALAR_FLAG_TYPE_ID_ASSIGNED
 dq NEBOC_FOUNDATION_TEXT_BIT_WIDTH,NEBOC_FOUNDATION_TEXT_STORAGE_SIZE,NEBOC_FOUNDATION_TEXT_STORAGE_ALIGNMENT,0
 dq NEBOC_FOUNDATION_SCALAR_KIND_FLOAT,NEBOC_TYPE_ID_FLOAT,NEBOC_FOUNDATION_SCALAR_NAME_ID_FLOAT
 dq NEBOC_FOUNDATION_SCALAR_FLAG_PUBLIC | NEBOC_FOUNDATION_SCALAR_FLAG_V02_FOUNDATION | NEBOC_FOUNDATION_SCALAR_FLAG_FIXED_WIDTH | NEBOC_FOUNDATION_SCALAR_FLAG_IEEE754_BINARY64 | NEBOC_FOUNDATION_SCALAR_FLAG_TYPE_ID_ASSIGNED
 dq NEBOC_FOUNDATION_FLOAT_BIT_WIDTH,NEBOC_FOUNDATION_FLOAT_STORAGE_SIZE,NEBOC_FOUNDATION_FLOAT_STORAGE_ALIGNMENT,0
 dq NEBOC_FOUNDATION_SCALAR_KIND_CHAR,NEBOC_TYPE_ID_CHAR,NEBOC_FOUNDATION_SCALAR_NAME_ID_CHAR
 dq NEBOC_FOUNDATION_SCALAR_FLAG_PUBLIC | NEBOC_FOUNDATION_SCALAR_FLAG_V02_FOUNDATION | NEBOC_FOUNDATION_SCALAR_FLAG_FIXED_WIDTH | NEBOC_FOUNDATION_SCALAR_FLAG_UNICODE_SCALAR | NEBOC_FOUNDATION_SCALAR_FLAG_TYPE_ID_ASSIGNED
 dq NEBOC_FOUNDATION_CHAR_BIT_WIDTH,NEBOC_FOUNDATION_CHAR_STORAGE_SIZE,NEBOC_FOUNDATION_CHAR_STORAGE_ALIGNMENT,0
 dq NEBOC_FOUNDATION_SCALAR_KIND_BYTES,NEBOC_TYPE_ID_BYTES,NEBOC_FOUNDATION_SCALAR_NAME_ID_BYTES
 dq NEBOC_FOUNDATION_SCALAR_FLAG_PUBLIC | NEBOC_FOUNDATION_SCALAR_FLAG_V02_FOUNDATION | NEBOC_FOUNDATION_SCALAR_FLAG_DESCRIPTOR_VALUE | NEBOC_FOUNDATION_SCALAR_FLAG_BINARY_SEQUENCE | NEBOC_FOUNDATION_SCALAR_FLAG_TYPE_ID_ASSIGNED
 dq NEBOC_FOUNDATION_BYTES_BIT_WIDTH,NEBOC_FOUNDATION_BYTES_STORAGE_SIZE,NEBOC_FOUNDATION_BYTES_STORAGE_ALIGNMENT,0
 dq NEBOC_FOUNDATION_SCALAR_KIND_NEVER,NEBOC_TYPE_ID_INVALID,NEBOC_FOUNDATION_SCALAR_NAME_ID_NEVER
 dq NEBOC_FOUNDATION_SCALAR_FLAG_INTERNAL_ONLY | NEBOC_FOUNDATION_SCALAR_FLAG_V02_FOUNDATION | NEBOC_FOUNDATION_SCALAR_FLAG_NO_RUNTIME_PAYLOAD | NEBOC_FOUNDATION_SCALAR_FLAG_TYPE_ID_PENDING
 dq NEBOC_FOUNDATION_NEVER_BIT_WIDTH,NEBOC_FOUNDATION_NEVER_STORAGE_SIZE,NEBOC_FOUNDATION_NEVER_STORAGE_ALIGNMENT,0
foundation_scalar_descriptors_end:

foundation_name_blob:
foundation_name_void: db "Void"
foundation_name_bool: db "Bool"
foundation_name_int: db "Int"
foundation_name_text: db "Text"
foundation_name_float: db "Float"
foundation_name_char: db "Char"
foundation_name_bytes: db "Bytes"
foundation_name_never: db "Never"
foundation_name_blob_end:

; pointer, length, kind. The eighth entry is internal-only and excluded by public lookup.
foundation_scalar_names:
 dq foundation_name_void,4,NEBOC_FOUNDATION_SCALAR_KIND_VOID
 dq foundation_name_bool,4,NEBOC_FOUNDATION_SCALAR_KIND_BOOL
 dq foundation_name_int,3,NEBOC_FOUNDATION_SCALAR_KIND_INT
 dq foundation_name_text,4,NEBOC_FOUNDATION_SCALAR_KIND_TEXT
 dq foundation_name_float,5,NEBOC_FOUNDATION_SCALAR_KIND_FLOAT
 dq foundation_name_char,4,NEBOC_FOUNDATION_SCALAR_KIND_CHAR
 dq foundation_name_bytes,5,NEBOC_FOUNDATION_SCALAR_KIND_BYTES
 dq foundation_name_never,5,NEBOC_FOUNDATION_SCALAR_KIND_NEVER

%define FOUNDATION_NAME_ENTRY_POINTER_OFFSET 0
%define FOUNDATION_NAME_ENTRY_LENGTH_OFFSET 8
%define FOUNDATION_NAME_ENTRY_KIND_OFFSET 16
%define FOUNDATION_NAME_ENTRY_SIZE 24

section .text

NEBOC_ABI_FUNCTION neboc_foundation_scalar_descriptor_count
 mov eax,NEBOC_FOUNDATION_SCALAR_COUNT
 ret

; descriptor_get(kind, out_descriptor_ptr*)
NEBOC_ABI_FUNCTION neboc_foundation_scalar_descriptor_get
 test rsi,rsi
 jz .get_invalid
 mov qword [rsi],0
 cmp rdi,NEBOC_FOUNDATION_SCALAR_KIND_VOID
 jb .get_invalid
 cmp rdi,NEBOC_FOUNDATION_SCALAR_KIND_NEVER
 ja .get_invalid
 mov rax,rdi
 dec rax
 imul rax,NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_SIZE
 lea rdx,[rel foundation_scalar_descriptors]
 add rax,rdx
 mov [rsi],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.get_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; descriptor_get_name(kind, out_name_ptr*, out_name_length*)
NEBOC_ABI_FUNCTION neboc_foundation_scalar_descriptor_get_name
 test rsi,rsi
 jz .name_invalid
 test rdx,rdx
 jz .name_invalid
 mov qword [rsi],0
 mov qword [rdx],0
 cmp rdi,NEBOC_FOUNDATION_SCALAR_KIND_VOID
 jb .name_invalid
 cmp rdi,NEBOC_FOUNDATION_SCALAR_KIND_NEVER
 ja .name_invalid
 mov rax,rdi
 dec rax
 imul rax,FOUNDATION_NAME_ENTRY_SIZE
 lea rcx,[rel foundation_scalar_names]
 add rax,rcx
 mov rcx,[rax+FOUNDATION_NAME_ENTRY_POINTER_OFFSET]
 mov [rsi],rcx
 mov rcx,[rax+FOUNDATION_NAME_ENTRY_LENGTH_OFFSET]
 mov [rdx],rcx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.name_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; descriptor_find_public_name(name_ptr, name_length, out_descriptor_ptr*)
NEBOC_ABI_FUNCTION neboc_foundation_scalar_descriptor_find_public_name
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 test r12,r12
 jz .find_invalid
 test r13,r13
 jz .find_invalid
 test r14,r14
 jz .find_invalid
 mov qword [r14],0
 lea rbx,[rel foundation_scalar_names]
 xor r15d,r15d
.find_loop:
 cmp r15,NEBOC_FOUNDATION_PUBLIC_SCALAR_COUNT
 jae .find_missing
 mov rax,r15
 imul rax,FOUNDATION_NAME_ENTRY_SIZE
 lea r8,[rbx+rax]
 cmp r13,[r8+FOUNDATION_NAME_ENTRY_LENGTH_OFFSET]
 jne .find_next
 mov rdi,r12
 mov rsi,[r8+FOUNDATION_NAME_ENTRY_POINTER_OFFSET]
 mov rdx,r13
 call foundation_scalar_name_equal
 test eax,eax
 jz .find_next
 mov rdi,[r8+FOUNDATION_NAME_ENTRY_KIND_OFFSET]
 mov rsi,r14
 call neboc_foundation_scalar_descriptor_get
 jmp .find_done
.find_next:
 inc r15
 jmp .find_loop
.find_missing:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .find_done
.find_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.find_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; descriptor_hash() -> stable FNV-1a 64-bit in RAX.
NEBOC_ABI_FUNCTION neboc_foundation_scalar_descriptor_hash
 mov rax,NEBOC_FOUNDATION_SCALAR_HASH_FNV1A64_OFFSET_BASIS
 mov r10,NEBOC_FOUNDATION_SCALAR_HASH_FNV1A64_PRIME
 lea rsi,[rel foundation_scalar_descriptors]
 mov ecx,foundation_scalar_descriptors_end-foundation_scalar_descriptors
.hash_descriptors:
 test ecx,ecx
 jz .hash_names_begin
 movzx edx,byte [rsi]
 xor rax,rdx
 imul rax,r10
 inc rsi
 dec ecx
 jmp .hash_descriptors
.hash_names_begin:
 lea rsi,[rel foundation_name_blob]
 mov ecx,foundation_name_blob_end-foundation_name_blob
.hash_names:
 test ecx,ecx
 jz .hash_done
 movzx edx,byte [rsi]
 xor rax,rdx
 imul rax,r10
 inc rsi
 dec ecx
 jmp .hash_names
.hash_done:
 cld
 ret

; descriptor_validate_contract() performs side-effect-free static catalogue checks.
NEBOC_ABI_FUNCTION neboc_foundation_scalar_descriptor_validate_contract
 lea r8,[rel foundation_scalar_descriptors]
 mov r9d,1
.validate_loop:
 cmp r9d,NEBOC_FOUNDATION_SCALAR_COUNT
 ja .validate_ok
 mov eax,r9d
 dec eax
 imul rax,NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_SIZE
 lea r10,[r8+rax]
 cmp [r10+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_KIND_OFFSET],r9
 jne .validate_internal
 cmp [r10+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_NAME_ID_OFFSET],r9
 jne .validate_internal
 mov rax,[r10+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_STORAGE_ALIGNMENT_OFFSET]
 test rax,rax
 jz .validate_internal
 mov rcx,rax
 dec rcx
 test rax,rcx
 jnz .validate_internal
 mov rax,[r10+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_FLAGS_OFFSET]
 mov rdx,rax
 and rax,NEBOC_FOUNDATION_SCALAR_FLAG_PUBLIC
 and rdx,NEBOC_FOUNDATION_SCALAR_FLAG_INTERNAL_ONLY
 test rax,rax
 jz .validate_internal_required
 test rdx,rdx
 jnz .validate_internal
 jmp .validate_type_id
.validate_internal_required:
 test rdx,rdx
 jz .validate_internal
.validate_type_id:
 mov rax,[r10+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_TYPE_ID_OFFSET]
 mov rdx,[r10+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_FLAGS_OFFSET]
 test rax,rax
 jz .validate_pending
 test rdx,NEBOC_FOUNDATION_SCALAR_FLAG_TYPE_ID_ASSIGNED
 jz .validate_internal
 test rdx,NEBOC_FOUNDATION_SCALAR_FLAG_TYPE_ID_PENDING
 jnz .validate_internal
 jmp .validate_next
.validate_pending:
 test rdx,NEBOC_FOUNDATION_SCALAR_FLAG_TYPE_ID_PENDING
 jz .validate_internal
 test rdx,NEBOC_FOUNDATION_SCALAR_FLAG_TYPE_ID_ASSIGNED
 jnz .validate_internal
.validate_next:
 inc r9d
 jmp .validate_loop
.validate_ok:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.validate_internal:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INTERNAL_ERROR

; name_equal(lhs, rhs, length) -> EAX=1 when equal, otherwise 0.
foundation_scalar_name_equal:
 test rdx,rdx
 jz .equal_yes
 mov rcx,rdx
 cld
 repe cmpsb
 jne .equal_no
.equal_yes:
 mov eax,1
 ret
.equal_no:
 xor eax,eax
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
