; VETORES-MATRIZES-TENSORES-E-COMPUTACAO-CIENTIFICA-PF002 isolated dense CPU-only Vector<Int> syntax/API contract
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/vector_contract.inc"

section .text
vector_hash:
 mov r8,[rdi+NEBOC_VECTOR_CONTRACT_SUBJECT_PTR_OFFSET]
 mov r9,[rdi+NEBOC_VECTOR_CONTRACT_SUBJECT_LENGTH_OFFSET]
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
 xor rax,[rdi+NEBOC_VECTOR_CONTRACT_OPERATION_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_VECTOR_CONTRACT_ELEMENT_COUNT_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_VECTOR_CONTRACT_OTHER_COUNT_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_VECTOR_CONTRACT_INDEX_OFFSET]
 mov [rdi+NEBOC_VECTOR_CONTRACT_HASH_OFFSET],rax
 ret

vector_error:
 mov [rdi+NEBOC_VECTOR_CONTRACT_DIAGNOSTIC_OFFSET],rsi
 mov rax,[rdi+NEBOC_VECTOR_CONTRACT_ABSOLUTE_START_OFFSET]
 mov [rdi+NEBOC_VECTOR_CONTRACT_ERROR_START_OFFSET],rax
 add rax,[rdi+NEBOC_VECTOR_CONTRACT_SUBJECT_LENGTH_OFFSET]
 mov [rdi+NEBOC_VECTOR_CONTRACT_ERROR_END_OFFSET],rax
 call vector_hash
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

NEBOC_ABI_FUNCTION neboc_vector_api_contract
 push r12
 mov r12,rdi
 test r12,r12
 jz .invalid
 cmp qword [r12+NEBOC_VECTOR_CONTRACT_SUBJECT_PTR_OFFSET],0
 je .invalid
 mov rax,[r12+NEBOC_VECTOR_CONTRACT_SUBJECT_LENGTH_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,4096
 ja .invalid
 mov qword [r12+NEBOC_VECTOR_CONTRACT_DIAGNOSTIC_OFFSET],0
 mov rax,[r12+NEBOC_VECTOR_CONTRACT_OPERATION_OFFSET]
 cmp rax,NEBOC_VECTOR_OP_MATRIX
 je .matrix
 cmp rax,NEBOC_VECTOR_OP_TENSOR
 je .tensor
 cmp rax,NEBOC_VECTOR_OP_DEVICE
 je .device
 cmp rax,NEBOC_VECTOR_OP_SPARSE
 je .sparse
 cmp rax,NEBOC_VECTOR_OP_OVERFLOW
 je .overflow
 cmp rax,NEBOC_VECTOR_OP_LITERAL
 jb .dtype
 cmp rax,NEBOC_VECTOR_OP_DOT
 ja .dtype
 mov rax,[r12+NEBOC_VECTOR_CONTRACT_FLAGS_OFFSET]
 and rax,NEBOC_VECTOR_PROFILE_FLAGS_REQUIRED
 cmp rax,NEBOC_VECTOR_PROFILE_FLAGS_REQUIRED
 jne .dtype
 cmp qword [r12+NEBOC_VECTOR_CONTRACT_ELEMENT_COUNT_OFFSET],4
 jne .arity
 cmp qword [r12+NEBOC_VECTOR_CONTRACT_ELEMENT_TYPE_OFFSET],NEBOC_VECTOR_TYPE_INT
 jne .element_type
 cmp qword [r12+NEBOC_VECTOR_CONTRACT_OPERATION_OFFSET],NEBOC_VECTOR_OP_DOT
 jne .not_dot
 cmp qword [r12+NEBOC_VECTOR_CONTRACT_OTHER_COUNT_OFFSET],4
 jne .arity
.not_dot:
 cmp qword [r12+NEBOC_VECTOR_CONTRACT_OPERATION_OFFSET],NEBOC_VECTOR_OP_INDEX
 jne .ok
 mov rax,[r12+NEBOC_VECTOR_CONTRACT_FLAGS_OFFSET]
 test rax,NEBOC_VECTOR_FLAG_CONSTANT_INDEX
 jz .constant_index
 mov rax,[r12+NEBOC_VECTOR_CONTRACT_INDEX_OFFSET]
 test rax,rax
 js .bounds
 cmp rax,4
 jae .bounds
.ok:
 mov rdi,r12
 call vector_hash
 xor eax,eax
 jmp .done
.arity: mov esi,NEBOC_VECTOR_DIAG_ARITY
 jmp .diag
.element_type: mov esi,NEBOC_VECTOR_DIAG_ELEMENT_TYPE
 jmp .diag
.bounds: mov esi,NEBOC_VECTOR_DIAG_BOUNDS
 jmp .diag
.constant_index: mov esi,NEBOC_VECTOR_DIAG_CONSTANT_INDEX
 jmp .diag
.dtype: mov esi,NEBOC_VECTOR_DIAG_DTYPE
 jmp .diag
.matrix: mov esi,NEBOC_VECTOR_DIAG_MATRIX
 jmp .diag
.tensor: mov esi,NEBOC_VECTOR_DIAG_TENSOR
 jmp .diag
.device: mov esi,NEBOC_VECTOR_DIAG_DEVICE
 jmp .diag
.sparse: mov esi,NEBOC_VECTOR_DIAG_SPARSE
 jmp .diag
.overflow: mov esi,NEBOC_VECTOR_DIAG_OVERFLOW
.diag:
 mov rdi,r12
 call vector_error
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
