; Nebo Assembly — provisional MF016 AST builder
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/ast/ast_node.inc"

section .text
; ast_builder_init(builder*, nodes*, capacity)
NEBOC_ABI_FUNCTION neboc_ast_builder_init
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov [rdi+NEBOC_AST_BUILDER_DATA_OFFSET],rsi
 mov qword [rdi+NEBOC_AST_BUILDER_COUNT_OFFSET],0
 mov [rdi+NEBOC_AST_BUILDER_CAPACITY_OFFSET],rdx
 mov qword [rdi+NEBOC_AST_BUILDER_FINALIZED_OFFSET],0
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; ast_builder_append(builder*, kind, source_id, start, end, out_node_id*)
NEBOC_ABI_FUNCTION neboc_ast_builder_append
 test rdi,rdi
 jz .append_invalid
 test rsi,rsi
 jz .append_invalid
 test r9,r9
 jz .append_invalid
 cmp qword [rdi+NEBOC_AST_BUILDER_FINALIZED_OFFSET],0
 jne .append_invalid
 mov r10,[rdi+NEBOC_AST_BUILDER_COUNT_OFFSET]
 cmp r10,[rdi+NEBOC_AST_BUILDER_CAPACITY_OFFSET]
 jae .append_limit
 mov r11,[rdi+NEBOC_AST_BUILDER_DATA_OFFSET]
 mov rax,r10
 imul rax,NEBOC_AST_NODE_SIZE
 add r11,rax
 mov [r11+NEBOC_AST_NODE_KIND_OFFSET],rsi
 mov qword [r11+NEBOC_AST_NODE_FLAGS_OFFSET],0
 mov [r11+NEBOC_AST_NODE_SOURCE_ID_OFFSET],rdx
 mov [r11+NEBOC_AST_NODE_START_OFFSET],rcx
 mov [r11+NEBOC_AST_NODE_END_OFFSET],r8
 mov qword [r11+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],0
 mov qword [r11+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],0
 mov qword [r11+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],0
 mov qword [r11+NEBOC_AST_NODE_PAYLOAD0_OFFSET],0
 mov qword [r11+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 inc r10
 mov [rdi+NEBOC_AST_BUILDER_COUNT_OFFSET],r10
 mov [r9],r10
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.append_limit:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.append_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; ast_builder_node(builder*, node_id, out_node_ptr*)
NEBOC_ABI_FUNCTION neboc_ast_builder_node
 test rdi,rdi
 jz .node_invalid
 test rdx,rdx
 jz .node_invalid
 mov qword [rdx],0
 test rsi,rsi
 jz .node_invalid
 cmp rsi,[rdi+NEBOC_AST_BUILDER_COUNT_OFFSET]
 ja .node_invalid
 dec rsi
 imul rsi,NEBOC_AST_NODE_SIZE
 add rsi,[rdi+NEBOC_AST_BUILDER_DATA_OFFSET]
 mov [rdx],rsi
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.node_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; ast_builder_finalize(builder*)
NEBOC_ABI_FUNCTION neboc_ast_builder_finalize
 test rdi,rdi
 jz .final_invalid
 mov qword [rdi+NEBOC_AST_BUILDER_FINALIZED_OFFSET],1
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.final_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
