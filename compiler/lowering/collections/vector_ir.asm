; VETORES-MATRIZES-TENSORES-E-COMPUTACAO-CIENTIFICA-PF003 explicit allocation-free Vector<Int> HIR/LIR contract
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/collections/vector_ir.inc"
section .text
NEBOC_ABI_FUNCTION neboc_vector_ir_lower
 test rdi,rdi
 jz .invalid
 mov qword [rdi+NEBOC_VECTOR_IR_OUTPUT_KIND_OFFSET],0
 mov qword [rdi+NEBOC_VECTOR_IR_BYTE_OFFSET_OFFSET],0
 mov qword [rdi+NEBOC_VECTOR_IR_CONSTANT_VALUE_OFFSET],0
 mov qword [rdi+NEBOC_VECTOR_IR_ALLOCATION_COUNT_OFFSET],0
 mov qword [rdi+NEBOC_VECTOR_IR_HASH_OFFSET],0
 mov qword [rdi+NEBOC_VECTOR_IR_DIAGNOSTIC_OFFSET],0
 cmp qword [rdi+NEBOC_VECTOR_IR_TARGET_OFFSET],NEBOC_VECTOR_IR_TARGET_X86_64_SYSV
 jne .target
 cmp qword [rdi+NEBOC_VECTOR_IR_SEMANTIC_HASH_OFFSET],0
 je .invariant
 mov rax,[rdi+NEBOC_VECTOR_IR_FLAGS_OFFSET]
 and rax,NEBOC_VECTOR_IR_FLAGS_REQUIRED
 cmp rax,NEBOC_VECTOR_IR_FLAGS_REQUIRED
 jne .invariant
 mov rax,[rdi+NEBOC_VECTOR_IR_OPERATION_OFFSET]
 cmp rax,NEBOC_VECTOR_IR_LITERAL
 je .literal
 cmp rax,NEBOC_VECTOR_IR_INDEX
 je .index
 cmp rax,NEBOC_VECTOR_IR_LEN
 je .len
 cmp rax,NEBOC_VECTOR_IR_SUM
 je .sum
 cmp rax,NEBOC_VECTOR_IR_DOT
 je .dot
 jmp .invariant
.literal:
 mov qword [rdi+NEBOC_VECTOR_IR_OUTPUT_KIND_OFFSET],1
 jmp .hash
.index:
 mov rax,[rdi+NEBOC_VECTOR_IR_INDEX_OFFSET]
 cmp rax,4
 jae .invariant
 shl rax,3
 mov [rdi+NEBOC_VECTOR_IR_BYTE_OFFSET_OFFSET],rax
 mov qword [rdi+NEBOC_VECTOR_IR_OUTPUT_KIND_OFFSET],2
 jmp .hash
.len:
 mov qword [rdi+NEBOC_VECTOR_IR_OUTPUT_KIND_OFFSET],3
 mov qword [rdi+NEBOC_VECTOR_IR_CONSTANT_VALUE_OFFSET],4
 jmp .hash
.sum:
 mov qword [rdi+NEBOC_VECTOR_IR_OUTPUT_KIND_OFFSET],4
 mov rax,[rdi+NEBOC_VECTOR_IR_SEMANTIC_RESULT_OFFSET]
 mov [rdi+NEBOC_VECTOR_IR_CONSTANT_VALUE_OFFSET],rax
 jmp .hash
.dot:
 mov qword [rdi+NEBOC_VECTOR_IR_OUTPUT_KIND_OFFSET],5
 mov rax,[rdi+NEBOC_VECTOR_IR_SEMANTIC_RESULT_OFFSET]
 mov [rdi+NEBOC_VECTOR_IR_CONSTANT_VALUE_OFFSET],rax
.hash:
 mov rax,[rdi+NEBOC_VECTOR_IR_SEMANTIC_HASH_OFFSET]
 mov r11,1099511628211
 xor rax,[rdi+NEBOC_VECTOR_IR_OPERATION_OFFSET]
 imul rax,r11
 xor rax,[rdi+NEBOC_VECTOR_IR_BYTE_OFFSET_OFFSET]
 imul rax,r11
 xor rax,[rdi+NEBOC_VECTOR_IR_CONSTANT_VALUE_OFFSET]
 mov [rdi+NEBOC_VECTOR_IR_HASH_OFFSET],rax
 xor eax,eax
 ret
.invariant:
 mov qword [rdi+NEBOC_VECTOR_IR_DIAGNOSTIC_OFFSET],NEBOC_VECTOR_IR_DIAG_INVARIANT
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.target:
 mov qword [rdi+NEBOC_VECTOR_IR_DIAGNOSTIC_OFFSET],NEBOC_VECTOR_IR_DIAG_TARGET
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
