; COLECOES-PRIMITIVAS-PF003 explicit allocation-free Array<Int,4> HIR/LIR contract
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/collections/array_ir.inc"
section .text
NEBOC_ABI_FUNCTION neboc_array_ir_lower
 test rdi,rdi
 jz .invalid
 mov qword [rdi+NEBOC_ARRAY_IR_OUTPUT_KIND_OFFSET],0
 mov qword [rdi+NEBOC_ARRAY_IR_BYTE_OFFSET_OFFSET],0
 mov qword [rdi+NEBOC_ARRAY_IR_CONSTANT_VALUE_OFFSET],0
 mov qword [rdi+NEBOC_ARRAY_IR_ALLOCATION_COUNT_OFFSET],0
 mov qword [rdi+NEBOC_ARRAY_IR_HASH_OFFSET],0
 mov qword [rdi+NEBOC_ARRAY_IR_DIAGNOSTIC_OFFSET],0
 cmp qword [rdi+NEBOC_ARRAY_IR_TARGET_OFFSET],NEBOC_ARRAY_IR_TARGET_X86_64_SYSV
 jne .target
 cmp qword [rdi+NEBOC_ARRAY_IR_SEMANTIC_HASH_OFFSET],0
 je .invariant
 mov rax,[rdi+NEBOC_ARRAY_IR_FLAGS_OFFSET]
 and rax,NEBOC_ARRAY_IR_FLAGS_REQUIRED
 cmp rax,NEBOC_ARRAY_IR_FLAGS_REQUIRED
 jne .invariant
 mov rax,[rdi+NEBOC_ARRAY_IR_OPERATION_OFFSET]
 cmp rax,NEBOC_ARRAY_IR_LITERAL
 je .literal
 cmp rax,NEBOC_ARRAY_IR_INDEX
 je .index
 cmp rax,NEBOC_ARRAY_IR_LEN
 je .len
 jmp .invariant
.literal: mov qword [rdi+NEBOC_ARRAY_IR_OUTPUT_KIND_OFFSET],1
 jmp .hash
.index:
 mov rax,[rdi+NEBOC_ARRAY_IR_INDEX_OFFSET]
 cmp rax,4
 jae .invariant
 shl rax,3
 mov [rdi+NEBOC_ARRAY_IR_BYTE_OFFSET_OFFSET],rax
 mov qword [rdi+NEBOC_ARRAY_IR_OUTPUT_KIND_OFFSET],2
 jmp .hash
.len:
 mov qword [rdi+NEBOC_ARRAY_IR_OUTPUT_KIND_OFFSET],3
 mov qword [rdi+NEBOC_ARRAY_IR_CONSTANT_VALUE_OFFSET],4
.hash:
 mov rax,[rdi+NEBOC_ARRAY_IR_SEMANTIC_HASH_OFFSET]
 mov r11,1099511628211
 xor rax,[rdi+NEBOC_ARRAY_IR_OPERATION_OFFSET]
 imul rax,r11
 xor rax,[rdi+NEBOC_ARRAY_IR_BYTE_OFFSET_OFFSET]
 mov [rdi+NEBOC_ARRAY_IR_HASH_OFFSET],rax
 xor eax,eax
 ret
.invariant: mov qword [rdi+NEBOC_ARRAY_IR_DIAGNOSTIC_OFFSET],NEBOC_ARRAY_IR_DIAG_INVARIANT
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.target: mov qword [rdi+NEBOC_ARRAY_IR_DIAGNOSTIC_OFFSET],NEBOC_ARRAY_IR_DIAG_TARGET
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
