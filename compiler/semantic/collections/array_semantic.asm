; COLECOES-PRIMITIVAS-PF003 immutable Array<Int,4> semantic identity and bounds
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/array_contract.inc"
%include "compiler/semantic/collections/array_semantic.inc"
section .text
NEBOC_ABI_FUNCTION neboc_array_semantic_analyze
 test rdi,rdi
 jz .invalid
 mov qword [rdi+NEBOC_ARRAY_SEM_OUTPUT_TYPE_OFFSET],0
 mov qword [rdi+NEBOC_ARRAY_SEM_HASH_OFFSET],0
 mov qword [rdi+NEBOC_ARRAY_SEM_DIAGNOSTIC_OFFSET],0
 mov rax,[rdi+NEBOC_ARRAY_SEM_SOURCE_END_OFFSET]
 cmp rax,[rdi+NEBOC_ARRAY_SEM_SOURCE_START_OFFSET]
 jb .resource
 sub rax,[rdi+NEBOC_ARRAY_SEM_SOURCE_START_OFFSET]
 cmp rax,4096
 ja .resource
 cmp qword [rdi+NEBOC_ARRAY_SEM_ELEMENT_COUNT_OFFSET],4
 jne .arity
 cmp qword [rdi+NEBOC_ARRAY_SEM_ELEMENT_TYPE_OFFSET],NEBOC_ARRAY_SEM_TYPE_INT
 jne .type
 mov rax,[rdi+NEBOC_ARRAY_SEM_FLAGS_OFFSET]
 test rax,NEBOC_ARRAY_SEM_FLAG_IMMUTABLE
 jz .mutation
 test rax,NEBOC_ARRAY_SEM_FLAG_CANONICAL
 jz .resource
 mov rcx,[rdi+NEBOC_ARRAY_SEM_KIND_OFFSET]
 cmp rcx,NEBOC_ARRAY_SEM_LITERAL
 je .array
 cmp rcx,NEBOC_ARRAY_SEM_LEN
 je .int
 cmp rcx,NEBOC_ARRAY_SEM_INDEX
 jne .resource
 test rax,NEBOC_ARRAY_SEM_FLAG_CONSTANT_INDEX
 jz .constant
 mov rdx,[rdi+NEBOC_ARRAY_SEM_INDEX_OFFSET]
 test rdx,rdx
 js .bounds
 cmp rdx,4
 jae .bounds
.int: mov qword [rdi+NEBOC_ARRAY_SEM_OUTPUT_TYPE_OFFSET],NEBOC_ARRAY_SEM_TYPE_INT
 jmp .hash
.array: mov qword [rdi+NEBOC_ARRAY_SEM_OUTPUT_TYPE_OFFSET],NEBOC_ARRAY_SEM_TYPE_ARRAY_INT_4
.hash:
 mov rax,0x10a44a79
 mov r11,1099511628211
 xor rax,[rdi+NEBOC_ARRAY_SEM_KIND_OFFSET]
 imul rax,r11
 xor rax,[rdi+NEBOC_ARRAY_SEM_INDEX_OFFSET]
 imul rax,r11
 xor rax,[rdi+NEBOC_ARRAY_SEM_OUTPUT_TYPE_OFFSET]
 mov [rdi+NEBOC_ARRAY_SEM_HASH_OFFSET],rax
 xor eax,eax
 ret
.arity: mov esi,NEBOC_ARRAY_DIAG_ARITY
 jmp .error
.type: mov esi,NEBOC_ARRAY_DIAG_ELEMENT_TYPE
 jmp .error
.bounds: mov esi,NEBOC_ARRAY_DIAG_BOUNDS
 jmp .error
.constant: mov esi,NEBOC_ARRAY_DIAG_CONSTANT_INDEX
 jmp .error
.mutation: mov esi,NEBOC_ARRAY_DIAG_MUTATION
 jmp .error
.resource: mov esi,NEBOC_ARRAY_DIAG_CAPACITY
.error:
 mov [rdi+NEBOC_ARRAY_SEM_DIAGNOSTIC_OFFSET],rsi
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
