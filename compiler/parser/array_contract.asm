; COLECOES-PRIMITIVAS-PF002 isolated immutable Array<Int,4> syntax/API contract
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/array_contract.inc"

section .text
array_hash:
 mov r8,[rdi+NEBOC_ARRAY_CONTRACT_SUBJECT_PTR_OFFSET]
 mov r9,[rdi+NEBOC_ARRAY_CONTRACT_SUBJECT_LENGTH_OFFSET]
 mov rax,1469598103934665603
 mov r10,1099511628211
 xor ecx,ecx
.bytes:
 cmp rcx,r9
 jae .fields
 movzx edx,byte [r8+rcx]
 xor rax,rdx
 imul rax,r10
 inc rcx
 jmp .bytes
.fields:
 xor rax,[rdi+NEBOC_ARRAY_CONTRACT_OPERATION_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_ARRAY_CONTRACT_ELEMENT_COUNT_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_ARRAY_CONTRACT_INDEX_OFFSET]
 mov [rdi+NEBOC_ARRAY_CONTRACT_HASH_OFFSET],rax
 ret

array_error:
 mov [rdi+NEBOC_ARRAY_CONTRACT_DIAGNOSTIC_OFFSET],rsi
 mov rax,[rdi+NEBOC_ARRAY_CONTRACT_ABSOLUTE_START_OFFSET]
 mov [rdi+NEBOC_ARRAY_CONTRACT_ERROR_START_OFFSET],rax
 add rax,[rdi+NEBOC_ARRAY_CONTRACT_SUBJECT_LENGTH_OFFSET]
 mov [rdi+NEBOC_ARRAY_CONTRACT_ERROR_END_OFFSET],rax
 call array_hash
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

NEBOC_ABI_FUNCTION neboc_array_api_contract
 push r12
 mov r12,rdi
 test r12,r12
 jz .invalid
 cmp qword [r12+NEBOC_ARRAY_CONTRACT_SUBJECT_PTR_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_ARRAY_CONTRACT_SUBJECT_LENGTH_OFFSET],0
 je .invalid
 mov qword [r12+NEBOC_ARRAY_CONTRACT_DIAGNOSTIC_OFFSET],0
 cmp qword [r12+NEBOC_ARRAY_CONTRACT_SUBJECT_LENGTH_OFFSET],4096
 ja .capacity
 mov rax,[r12+NEBOC_ARRAY_CONTRACT_OPERATION_OFFSET]
 cmp rax,NEBOC_ARRAY_OP_MUTATION
 je .mutation
 cmp rax,NEBOC_ARRAY_OP_LIST
 je .list
 cmp rax,NEBOC_ARRAY_OP_DICT
 je .dict
 cmp rax,NEBOC_ARRAY_OP_CAPACITY
 je .capacity
 cmp rax,NEBOC_ARRAY_OP_LITERAL
 jb .list
 cmp rax,NEBOC_ARRAY_OP_LEN
 ja .list
 mov rax,[r12+NEBOC_ARRAY_CONTRACT_FLAGS_OFFSET]
 test rax,NEBOC_ARRAY_FLAG_IMMUTABLE
 jz .mutation
 test rax,NEBOC_ARRAY_FLAG_CANONICAL
 jz .list
 cmp qword [r12+NEBOC_ARRAY_CONTRACT_ELEMENT_COUNT_OFFSET],4
 jne .arity
 cmp qword [r12+NEBOC_ARRAY_CONTRACT_ELEMENT_TYPE_OFFSET],NEBOC_ARRAY_TYPE_INT
 jne .element_type
 cmp qword [r12+NEBOC_ARRAY_CONTRACT_OPERATION_OFFSET],NEBOC_ARRAY_OP_INDEX
 jne .ok
 test rax,NEBOC_ARRAY_FLAG_CONSTANT_INDEX
 jz .constant_index
 mov rax,[r12+NEBOC_ARRAY_CONTRACT_INDEX_OFFSET]
 test rax,rax
 js .bounds
 cmp rax,4
 jae .bounds
.ok:
 mov rdi,r12
 call array_hash
 xor eax,eax
 jmp .done
.arity: mov esi,NEBOC_ARRAY_DIAG_ARITY
 jmp .diag
.element_type: mov esi,NEBOC_ARRAY_DIAG_ELEMENT_TYPE
 jmp .diag
.bounds: mov esi,NEBOC_ARRAY_DIAG_BOUNDS
 jmp .diag
.constant_index: mov esi,NEBOC_ARRAY_DIAG_CONSTANT_INDEX
 jmp .diag
.mutation: mov esi,NEBOC_ARRAY_DIAG_MUTATION
 jmp .diag
.list: mov esi,NEBOC_ARRAY_DIAG_LIST
 jmp .diag
.dict: mov esi,NEBOC_ARRAY_DIAG_DICT
 jmp .diag
.capacity: mov esi,NEBOC_ARRAY_DIAG_CAPACITY
.diag:
 mov rdi,r12
 call array_error
 jmp .done
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
