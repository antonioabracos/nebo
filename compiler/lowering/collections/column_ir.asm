; COLUMN-ROW-TABLE-E-DATASET-PF003 explicit zero-allocation Column IR mapping
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/column_contract.inc"
%include "compiler/lowering/collections/column_ir.inc"
section .text
NEBOC_ABI_FUNCTION neboc_column_ir_lower
 test rdi,rdi
 jz .invalid
 mov qword [rdi+NEBOC_COLUMN_IR_ALLOCATION_COUNT_OFFSET],0
 mov rax,[rdi+NEBOC_COLUMN_IR_OPERATION_OFFSET]
 cmp rax,NEBOC_COLUMN_OP_COUNT_MISSING
 ja .source
 add rax,NEBOC_COLUMN_IR_BASE
 mov [rdi+NEBOC_COLUMN_IR_OPCODE_OFFSET],rax
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
