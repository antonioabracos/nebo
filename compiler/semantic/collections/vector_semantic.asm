; VETORES-MATRIZES-TENSORES-E-COMPUTACAO-CIENTIFICA-PF003 dense Vector<Int> semantic identity and checked arithmetic
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/vector_contract.inc"
%include "compiler/semantic/collections/vector_semantic.inc"
section .text
NEBOC_ABI_FUNCTION neboc_vector_semantic_analyze
 test rdi,rdi
 jz .invalid
 mov qword [rdi+NEBOC_VECTOR_SEM_OUTPUT_TYPE_OFFSET],0
 mov qword [rdi+NEBOC_VECTOR_SEM_RESULT_OFFSET],0
 mov qword [rdi+NEBOC_VECTOR_SEM_HASH_OFFSET],0
 mov qword [rdi+NEBOC_VECTOR_SEM_DIAGNOSTIC_OFFSET],0
 mov rax,[rdi+NEBOC_VECTOR_SEM_SOURCE_END_OFFSET]
 cmp rax,[rdi+NEBOC_VECTOR_SEM_SOURCE_START_OFFSET]
 jb .profile
 sub rax,[rdi+NEBOC_VECTOR_SEM_SOURCE_START_OFFSET]
 cmp rax,4096
 ja .profile
 cmp qword [rdi+NEBOC_VECTOR_SEM_ELEMENT_COUNT_OFFSET],4
 jne .arity
 cmp qword [rdi+NEBOC_VECTOR_SEM_ELEMENT_TYPE_OFFSET],NEBOC_VECTOR_SEM_TYPE_INT
 jne .type
 mov rax,[rdi+NEBOC_VECTOR_SEM_FLAGS_OFFSET]
 and rax,NEBOC_VECTOR_SEM_PROFILE_FLAGS
 cmp rax,NEBOC_VECTOR_SEM_PROFILE_FLAGS
 jne .profile
 mov rcx,[rdi+NEBOC_VECTOR_SEM_KIND_OFFSET]
 cmp rcx,NEBOC_VECTOR_SEM_LITERAL
 je .vector
 cmp rcx,NEBOC_VECTOR_SEM_LEN
 je .len
 cmp rcx,NEBOC_VECTOR_SEM_INDEX
 je .index
 cmp rcx,NEBOC_VECTOR_SEM_SUM
 je .sum
 cmp rcx,NEBOC_VECTOR_SEM_DOT
 je .dot
 jmp .profile
.vector:
 mov qword [rdi+NEBOC_VECTOR_SEM_OUTPUT_TYPE_OFFSET],NEBOC_VECTOR_SEM_TYPE_VECTOR_INT_4
 jmp .hash
.len:
 mov qword [rdi+NEBOC_VECTOR_SEM_OUTPUT_TYPE_OFFSET],NEBOC_VECTOR_SEM_TYPE_INT
 mov qword [rdi+NEBOC_VECTOR_SEM_RESULT_OFFSET],4
 jmp .hash
.index:
 mov rax,[rdi+NEBOC_VECTOR_SEM_FLAGS_OFFSET]
 test rax,NEBOC_VECTOR_SEM_FLAG_CONSTANT_INDEX
 jz .constant
 mov rcx,[rdi+NEBOC_VECTOR_SEM_INDEX_OFFSET]
 test rcx,rcx
 js .bounds
 cmp rcx,4
 jae .bounds
 mov rax,[rdi+NEBOC_VECTOR_SEM_ELEMENTS_OFFSET+rcx*8]
 mov [rdi+NEBOC_VECTOR_SEM_RESULT_OFFSET],rax
 mov qword [rdi+NEBOC_VECTOR_SEM_OUTPUT_TYPE_OFFSET],NEBOC_VECTOR_SEM_TYPE_INT
 jmp .hash
.sum:
 xor r8,r8
 xor ecx,ecx
.sum_loop:
 add r8,[rdi+NEBOC_VECTOR_SEM_ELEMENTS_OFFSET+rcx*8]
 jo .overflow
 inc ecx
 cmp ecx,4
 jb .sum_loop
 mov [rdi+NEBOC_VECTOR_SEM_RESULT_OFFSET],r8
 mov qword [rdi+NEBOC_VECTOR_SEM_OUTPUT_TYPE_OFFSET],NEBOC_VECTOR_SEM_TYPE_INT
 jmp .hash
.dot:
 cmp qword [rdi+NEBOC_VECTOR_SEM_OTHER_COUNT_OFFSET],4
 jne .arity
 xor r8,r8
 xor ecx,ecx
.dot_loop:
 mov rax,[rdi+NEBOC_VECTOR_SEM_ELEMENTS_OFFSET+rcx*8]
 imul rax,qword [rdi+NEBOC_VECTOR_SEM_OTHER_ELEMENTS_OFFSET+rcx*8]
 jo .overflow
 add r8,rax
 jo .overflow
 inc ecx
 cmp ecx,4
 jb .dot_loop
 mov [rdi+NEBOC_VECTOR_SEM_RESULT_OFFSET],r8
 mov qword [rdi+NEBOC_VECTOR_SEM_OUTPUT_TYPE_OFFSET],NEBOC_VECTOR_SEM_TYPE_INT
.hash:
 mov rax,0x11a44b79
 mov r11,1099511628211
 xor rax,[rdi+NEBOC_VECTOR_SEM_KIND_OFFSET]
 imul rax,r11
 xor rax,[rdi+NEBOC_VECTOR_SEM_INDEX_OFFSET]
 imul rax,r11
 xor rax,[rdi+NEBOC_VECTOR_SEM_RESULT_OFFSET]
 imul rax,r11
 xor rax,[rdi+NEBOC_VECTOR_SEM_OUTPUT_TYPE_OFFSET]
 mov [rdi+NEBOC_VECTOR_SEM_HASH_OFFSET],rax
 xor eax,eax
 ret
.arity: mov esi,NEBOC_VECTOR_DIAG_ARITY
 jmp .error
.type: mov esi,NEBOC_VECTOR_DIAG_ELEMENT_TYPE
 jmp .error
.bounds: mov esi,NEBOC_VECTOR_DIAG_BOUNDS
 jmp .error
.constant: mov esi,NEBOC_VECTOR_DIAG_CONSTANT_INDEX
 jmp .error
.profile: mov esi,NEBOC_VECTOR_DIAG_DTYPE
 jmp .error
.overflow: mov esi,NEBOC_VECTOR_DIAG_OVERFLOW
.error:
 mov [rdi+NEBOC_VECTOR_SEM_DIAGNOSTIC_OFFSET],rsi
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
