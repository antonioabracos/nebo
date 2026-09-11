; Nebo Assembly — TIPOS-PRIMITIVOS-ESCALARES-PF002 foundation scalar descriptor scenarios
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/foundation_scalar_descriptor.inc"

extern neboc_foundation_scalar_descriptor_count
extern neboc_foundation_scalar_descriptor_get
extern neboc_foundation_scalar_descriptor_get_name
extern neboc_foundation_scalar_descriptor_find_public_name
extern neboc_foundation_scalar_descriptor_hash
extern neboc_foundation_scalar_descriptor_validate_contract
extern neboc_host_process_exit

global _start

section .rodata
name_void: db "Void"
name_bool: db "Bool"
name_int: db "Int"
name_text: db "Text"
name_float: db "Float"
name_char: db "Char"
name_bytes: db "Bytes"
name_never: db "Never"
name_number: db "Number"
name_bin: db "Bin"

section .bss align=16
out_descriptor: resq 1
out_name: resq 1
out_length: resq 1

section .text
_start:
 mov rax,[rsp]
 cmp rax,2
 jne test_usage
 mov rax,[rsp+16]
 cmp byte [rax+1],0
 jne test_usage
 movzx eax,byte [rax]
 sub eax,'0'
 cmp eax,1
 jb test_usage
 cmp eax,8
 ja test_usage
 cmp eax,1
 je scenario_1
 cmp eax,2
 je scenario_2
 cmp eax,3
 je scenario_3
 cmp eax,4
 je scenario_4
 cmp eax,5
 je scenario_5
 cmp eax,6
 je scenario_6
 cmp eax,7
 je scenario_7
 jmp scenario_8

scenario_1:
 call neboc_foundation_scalar_descriptor_count
 cmp eax,NEBOC_FOUNDATION_SCALAR_COUNT
 jne test_fail
 call neboc_foundation_scalar_descriptor_validate_contract
 test eax,eax
 jnz test_fail
 call neboc_foundation_scalar_descriptor_hash
 mov rbx,0xa769399e9dc15480
 cmp rax,rbx
 jne test_fail
 call neboc_foundation_scalar_descriptor_hash
 cmp rax,rbx
 jne test_fail
 jmp test_pass

scenario_2:
 mov edi,NEBOC_FOUNDATION_SCALAR_KIND_VOID
 call get_descriptor
 cmp qword [rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_TYPE_ID_OFFSET],NEBOC_TYPE_ID_VOID
 jne test_fail
 test qword [rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_FLAGS_OFFSET],NEBOC_FOUNDATION_SCALAR_FLAG_TYPE_ID_ASSIGNED
 jz test_fail
 mov edi,NEBOC_FOUNDATION_SCALAR_KIND_BOOL
 call get_descriptor
 cmp qword [rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_STORAGE_SIZE_OFFSET],1
 jne test_fail
 mov edi,NEBOC_FOUNDATION_SCALAR_KIND_INT
 call get_descriptor
 cmp qword [rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_BIT_WIDTH_OFFSET],64
 jne test_fail
 mov edi,NEBOC_FOUNDATION_SCALAR_KIND_TEXT
 call get_descriptor
 cmp qword [rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_STORAGE_SIZE_OFFSET],24
 jne test_fail
 jmp test_pass

scenario_3:
 mov edi,NEBOC_FOUNDATION_SCALAR_KIND_FLOAT
 call get_descriptor
 cmp qword [rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_TYPE_ID_OFFSET],NEBOC_TYPE_ID_FLOAT
 jne test_fail
 mov rbx,[rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_FLAGS_OFFSET]
 test rbx,NEBOC_FOUNDATION_SCALAR_FLAG_IEEE754_BINARY64
 jz test_fail
 test rbx,NEBOC_FOUNDATION_SCALAR_FLAG_TYPE_ID_ASSIGNED
 jz test_fail
 test rbx,NEBOC_FOUNDATION_SCALAR_FLAG_TYPE_ID_PENDING
 jnz test_fail
 cmp qword [rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_BIT_WIDTH_OFFSET],64
 jne test_fail
 cmp qword [rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_STORAGE_SIZE_OFFSET],8
 jne test_fail
 cmp qword [rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_STORAGE_ALIGNMENT_OFFSET],8
 jne test_fail
 jmp test_pass

scenario_4:
 mov edi,NEBOC_FOUNDATION_SCALAR_KIND_CHAR
 call get_descriptor
 cmp qword [rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_TYPE_ID_OFFSET],NEBOC_TYPE_ID_CHAR
 jne test_fail
 mov rbx,[rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_FLAGS_OFFSET]
 test rbx,NEBOC_FOUNDATION_SCALAR_FLAG_UNICODE_SCALAR
 jz test_fail
 cmp qword [rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_BIT_WIDTH_OFFSET],32
 jne test_fail
 cmp qword [rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_STORAGE_SIZE_OFFSET],4
 jne test_fail
 cmp qword [rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_STORAGE_ALIGNMENT_OFFSET],4
 jne test_fail
 jmp test_pass

scenario_5:
 mov edi,NEBOC_FOUNDATION_SCALAR_KIND_BYTES
 call get_descriptor
 mov rbx,[rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_FLAGS_OFFSET]
 test rbx,NEBOC_FOUNDATION_SCALAR_FLAG_BINARY_SEQUENCE
 jz test_fail
 test rbx,NEBOC_FOUNDATION_SCALAR_FLAG_TYPE_ID_ASSIGNED
 jz test_fail
 test rbx,NEBOC_FOUNDATION_SCALAR_FLAG_LAYOUT_DEFERRED
 jnz test_fail
 cmp qword [rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_TYPE_ID_OFFSET],NEBOC_TYPE_ID_BYTES
 jne test_fail
 cmp qword [rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_STORAGE_SIZE_OFFSET],24
 jne test_fail
 cmp qword [rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_STORAGE_ALIGNMENT_OFFSET],8
 jne test_fail
 jmp test_pass

scenario_6:
 mov edi,NEBOC_FOUNDATION_SCALAR_KIND_NEVER
 call get_descriptor
 mov rbx,[rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_FLAGS_OFFSET]
 test rbx,NEBOC_FOUNDATION_SCALAR_FLAG_INTERNAL_ONLY
 jz test_fail
 test rbx,NEBOC_FOUNDATION_SCALAR_FLAG_PUBLIC
 jnz test_fail
 test rbx,NEBOC_FOUNDATION_SCALAR_FLAG_NO_RUNTIME_PAYLOAD
 jz test_fail
 lea rdi,[rel name_never]
 mov esi,5
 lea rdx,[rel out_descriptor]
 call neboc_foundation_scalar_descriptor_find_public_name
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel out_descriptor],0
 jne test_fail
 jmp test_pass

scenario_7:
 lea rdi,[rel name_void]
 mov esi,4
 mov edx,NEBOC_FOUNDATION_SCALAR_KIND_VOID
 call expect_public_name
 lea rdi,[rel name_bool]
 mov esi,4
 mov edx,NEBOC_FOUNDATION_SCALAR_KIND_BOOL
 call expect_public_name
 lea rdi,[rel name_int]
 mov esi,3
 mov edx,NEBOC_FOUNDATION_SCALAR_KIND_INT
 call expect_public_name
 lea rdi,[rel name_text]
 mov esi,4
 mov edx,NEBOC_FOUNDATION_SCALAR_KIND_TEXT
 call expect_public_name
 lea rdi,[rel name_float]
 mov esi,5
 mov edx,NEBOC_FOUNDATION_SCALAR_KIND_FLOAT
 call expect_public_name
 lea rdi,[rel name_char]
 mov esi,4
 mov edx,NEBOC_FOUNDATION_SCALAR_KIND_CHAR
 call expect_public_name
 lea rdi,[rel name_bytes]
 mov esi,5
 mov edx,NEBOC_FOUNDATION_SCALAR_KIND_BYTES
 call expect_public_name
 jmp test_pass

scenario_8:
 lea rdi,[rel name_number]
 mov esi,6
 call expect_missing_public_name
 lea rdi,[rel name_bin]
 mov esi,3
 call expect_missing_public_name
 xor edi,edi
 lea rsi,[rel out_descriptor]
 call neboc_foundation_scalar_descriptor_get
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne test_fail
 mov edi,NEBOC_FOUNDATION_SCALAR_KIND_NEVER+1
 lea rsi,[rel out_descriptor]
 call neboc_foundation_scalar_descriptor_get
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne test_fail
 mov edi,NEBOC_FOUNDATION_SCALAR_KIND_FLOAT
 xor esi,esi
 call neboc_foundation_scalar_descriptor_get
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne test_fail
 mov edi,NEBOC_FOUNDATION_SCALAR_KIND_FLOAT
 lea rsi,[rel out_name]
 lea rdx,[rel out_length]
 call neboc_foundation_scalar_descriptor_get_name
 test eax,eax
 jnz test_fail
 cmp qword [rel out_length],5
 jne test_fail
 jmp test_pass

get_descriptor:
 lea rsi,[rel out_descriptor]
 call neboc_foundation_scalar_descriptor_get
 test eax,eax
 jnz test_fail
 mov rax,[rel out_descriptor]
 test rax,rax
 jz test_fail
 ret

; rdi=name, rsi=length, rdx=expected kind
expect_public_name:
 push rdx
 lea rdx,[rel out_descriptor]
 call neboc_foundation_scalar_descriptor_find_public_name
 pop rdx
 test eax,eax
 jnz test_fail
 mov rax,[rel out_descriptor]
 test rax,rax
 jz test_fail
 cmp [rax+NEBOC_FOUNDATION_SCALAR_DESCRIPTOR_KIND_OFFSET],rdx
 jne test_fail
 ret

; rdi=name, rsi=length
expect_missing_public_name:
 lea rdx,[rel out_descriptor]
 call neboc_foundation_scalar_descriptor_find_public_name
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel out_descriptor],0
 jne test_fail
 ret

test_pass:
 xor edi,edi
 call neboc_host_process_exit
test_fail:
 mov edi,1
 call neboc_host_process_exit
test_usage:
 mov edi,64
 call neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
