; STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-PF002 isolated programmer-defined product/sum syntax contract
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/programmer_type_contract.inc"

section .text
contract_hash:
 mov r8,[rdi+NEBOC_CONTRACT_SUBJECT_PTR_OFFSET]
 mov r9,[rdi+NEBOC_CONTRACT_SUBJECT_LENGTH_OFFSET]
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
 xor rax,[rdi+NEBOC_CONTRACT_OPERATION_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_CONTRACT_FLAGS_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_CONTRACT_MEMBER_COUNT_OFFSET]
 imul rax,r10
 mov [rdi+NEBOC_CONTRACT_HASH_OFFSET],rax
 ret

contract_error:
 mov [rdi+NEBOC_CONTRACT_DIAGNOSTIC_OFFSET],rsi
 mov rax,[rdi+NEBOC_CONTRACT_ABSOLUTE_START_OFFSET]
 mov [rdi+NEBOC_CONTRACT_ERROR_START_OFFSET],rax
 add rax,[rdi+NEBOC_CONTRACT_SUBJECT_LENGTH_OFFSET]
 mov [rdi+NEBOC_CONTRACT_ERROR_END_OFFSET],rax
 call contract_hash
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

NEBOC_ABI_FUNCTION neboc_programmer_type_contract
 push r12
 mov r12,rdi
 test r12,r12
 jz .invalid
 cmp qword [r12+NEBOC_CONTRACT_SUBJECT_PTR_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_CONTRACT_SUBJECT_LENGTH_OFFSET],0
 je .invalid
 mov qword [r12+NEBOC_CONTRACT_DIAGNOSTIC_OFFSET],0
 mov rax,[r12+NEBOC_CONTRACT_OPERATION_OFFSET]
 cmp rax,NEBOC_OP_STRUCT_DECL
 jb .expected_type
 cmp rax,NEBOC_OP_GENERIC_ENUM
 ja .expected_type
 mov rax,[r12+NEBOC_CONTRACT_FLAGS_OFFSET]
 test rax,NEBOC_FLAG_TYPE_UNIQUE
 jz .duplicate_type
 test rax,NEBOC_FLAG_MEMBER_UNIQUE
 jz .duplicate_member
 test rax,NEBOC_FLAG_COMPLETE
 jz .missing
 test rax,NEBOC_FLAG_TYPE_MATCH
 jz .type_mismatch
 test rax,NEBOC_FLAG_NONEMPTY
 jz .empty
 test rax,NEBOC_FLAG_NONRECURSIVE
 jz .recursive
 test rax,NEBOC_FLAG_CANONICAL
 jz .unknown
 test rax,NEBOC_FLAG_SUPPORTED
 jz .deferred
 cmp qword [r12+NEBOC_CONTRACT_MEMBER_COUNT_OFFSET],1
 jb .empty
 cmp qword [r12+NEBOC_CONTRACT_MEMBER_COUNT_OFFSET],8
 ja .deferred
 mov rdi,r12
 call contract_hash
 xor eax,eax
 jmp .done
.expected_type: mov esi,NEBOC_DIAG_EXPECTED_TYPE_NAME
 jmp .diag
.duplicate_type: mov esi,NEBOC_DIAG_DUPLICATE_TYPE
 jmp .diag
.duplicate_member:
 mov esi,neboc_structs_enums_variants_e_tipos_do_programador_DIAG_DUPLICATE_FIELD
 mov rax,[r12+NEBOC_CONTRACT_OPERATION_OFFSET]
 cmp rax,NEBOC_OP_ENUM_DECL
 je .variant
 cmp rax,NEBOC_OP_UNIT_VARIANT
 je .variant
 cmp rax,NEBOC_OP_PAYLOAD_VARIANT
 jne .diag
.variant: mov esi,NEBOC_DIAG_DUPLICATE_VARIANT
 jmp .diag
.missing: mov esi,NEBOC_DIAG_MISSING_FIELD
 jmp .diag
.type_mismatch:
 mov esi,NEBOC_DIAG_FIELD_TYPE_MISMATCH
 mov rax,[r12+NEBOC_CONTRACT_OPERATION_OFFSET]
 cmp rax,NEBOC_OP_PAYLOAD_VARIANT
 je .payload
 cmp rax,NEBOC_OP_GENERIC_ENUM
 jne .diag
.payload: mov esi,neboc_structs_enums_variants_e_tipos_do_programador_DIAG_PAYLOAD_TYPE_MISMATCH
 jmp .diag
.empty: mov esi,NEBOC_DIAG_EMPTY_DECLARATION
 jmp .diag
.recursive: mov esi,NEBOC_DIAG_RECURSIVE_BY_VALUE
 jmp .diag
.unknown: mov esi,neboc_structs_enums_variants_e_tipos_do_programador_DIAG_UNKNOWN_FIELD
 jmp .diag
.deferred: mov esi,NEBOC_DIAG_DEFERRED_FEATURE
.diag:
 mov rdi,r12
 call contract_error
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
