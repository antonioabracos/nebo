; Nebo Assembly — MF016 recursive-descent parser skeleton
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/parser/parser.inc"

extern neboc_ast_builder_append
extern neboc_ast_builder_node

%macro TOKEN_PTR 2
 mov %1,%2
 imul %1,NEBOC_TOKEN_SIZE
 add %1,[r12+NEBOC_PARSER_TOKENS_OFFSET]
%endmacro

section .text
; parser_set_error(request*, diagnostic_code, token_index)
NEBOC_ABI_FUNCTION neboc_parser_set_error
 test rdi,rdi
 jz .bad
 mov [rdi+NEBOC_PARSER_ERROR_CODE_OFFSET],rsi
 mov [rdi+NEBOC_PARSER_ERROR_TOKEN_OFFSET],rdx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.bad:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; parser_parse(ParserRequest*)
NEBOC_ABI_FUNCTION neboc_parser_parse
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 test r12,r12
 jz parser_invalid
 mov r13,[r12+NEBOC_PARSER_TOKENS_OFFSET]
 mov r14,[r12+NEBOC_PARSER_TOKEN_COUNT_OFFSET]
 mov r15,[r12+NEBOC_PARSER_BUILDER_OFFSET]
 test r13,r13
 jz parser_invalid
 test r14,r14
 jz parser_invalid
 test r15,r15
 jz parser_invalid
 cmp qword [r12+NEBOC_PARSER_MAX_NESTING_OFFSET],0
 jne parser_max_ready
 mov qword [r12+NEBOC_PARSER_MAX_NESTING_OFFSET],NEBOC_PARSER_DEFAULT_MAX_NESTING
parser_max_ready:
 mov qword [r12+NEBOC_PARSER_INDEX_OFFSET],0
 mov qword [r12+NEBOC_PARSER_START_COUNT_OFFSET],0
 mov qword [r12+NEBOC_PARSER_ERROR_CODE_OFFSET],0
 mov qword [r12+NEBOC_PARSER_ERROR_TOKEN_OFFSET],0
 mov qword [r12+NEBOC_PARSER_ROOT_ID_OFFSET],0
 mov qword [r12+NEBOC_PARSER_LAST_NODE_ID_OFFSET],0
 mov qword [rsp],0
 mov qword [rsp+8],0

 ; Program span covers first token start through final token end.
 mov rax,r14
 dec rax
 TOKEN_PTR r11,rax
 TOKEN_PTR r10,0
 mov rdi,r15
 mov esi,NEBOC_AST_PROGRAM
 mov rdx,[r12+NEBOC_PARSER_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_TOKEN_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[r12+NEBOC_PARSER_ROOT_ID_OFFSET]
 call neboc_ast_builder_append
 test eax,eax
 jnz parser_done
 mov rdi,r15
 mov rsi,[r12+NEBOC_PARSER_ROOT_ID_OFFSET]
 lea rdx,[r12+NEBOC_PARSER_SCRATCH0_OFFSET]
 call neboc_ast_builder_node
 test eax,eax
 jnz parser_done
 mov rbx,[r12+NEBOC_PARSER_SCRATCH0_OFFSET]

parser_top_loop:
 mov rax,[r12+NEBOC_PARSER_INDEX_OFFSET]
 cmp rax,r14
 jae parser_missing_start
 TOKEN_PTR r11,rax
 mov rcx,[r11+NEBOC_TOKEN_KIND_OFFSET]
 cmp rcx,NEBOC_TOKEN_EOF
 je parser_finish
 cmp rcx,NEBOC_TOKEN_KW_START
 jne parser_check_function
 test qword [r12+NEBOC_PARSER_FLAGS_OFFSET],NEBOC_PARSER_FLAG_FORBID_START
 jnz parser_forbidden_start
 jmp parser_call_start
parser_check_function:
 cmp rcx,NEBOC_TOKEN_LPAREN
 je parser_call_function
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_TOP_LEVEL_STATEMENT
 mov rdx,rax
 call neboc_parser_set_error
 jmp parser_done

parser_forbidden_start:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_ENTRYPOINT_FORBIDDEN_FOR_TARGET
 mov rdx,rax
 call neboc_parser_set_error
 jmp parser_done

parser_call_start:
 mov rdi,r12
 call neboc_parser_parse_start
 test eax,eax
 jnz parser_done
 jmp parser_link_child

parser_call_function:
 mov rdi,r12
 call neboc_parser_parse_function
 test eax,eax
 jnz parser_done

parser_link_child:
 mov rax,[r12+NEBOC_PARSER_LAST_NODE_ID_OFFSET]
 mov [r12+NEBOC_PARSER_SCRATCH2_OFFSET],rax
 cmp qword [rsp],0
 jne parser_link_after_first
 mov [rsp],rax
 mov [rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 jmp parser_link_count
parser_link_after_first:
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[r12+NEBOC_PARSER_SCRATCH0_OFFSET]
 call neboc_ast_builder_node
 test eax,eax
 jnz parser_done
 mov r11,[r12+NEBOC_PARSER_SCRATCH0_OFFSET]
 mov rax,[r12+NEBOC_PARSER_SCRATCH2_OFFSET]
 mov [r11+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
parser_link_count:
 mov rax,[r12+NEBOC_PARSER_SCRATCH2_OFFSET]
 mov [rsp+8],rax
 inc qword [rbx+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 jmp parser_top_loop

parser_finish:
 cmp qword [r12+NEBOC_PARSER_START_COUNT_OFFSET],1
 je parser_success
 test qword [r12+NEBOC_PARSER_FLAGS_OFFSET],NEBOC_PARSER_FLAG_ALLOW_ZERO_START
 jz parser_missing_start
 cmp qword [r12+NEBOC_PARSER_START_COUNT_OFFSET],0
 jne parser_missing_start
parser_success:
 xor eax,eax
 jmp parser_done
parser_missing_start:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_MISSING_START
 mov rdx,[r12+NEBOC_PARSER_INDEX_OFFSET]
 call neboc_parser_set_error
 jmp parser_done
parser_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
parser_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; parser_parse_start(ParserRequest*)
NEBOC_ABI_FUNCTION neboc_parser_parse_start
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov r12,rdi
 mov r13,[r12+NEBOC_PARSER_TOKENS_OFFSET]
 mov r14,[r12+NEBOC_PARSER_TOKEN_COUNT_OFFSET]
 mov r15,[r12+NEBOC_PARSER_BUILDER_OFFSET]
 mov rbx,[r12+NEBOC_PARSER_INDEX_OFFSET]
 mov [rsp],rbx
 cmp qword [r12+NEBOC_PARSER_START_COUNT_OFFSET],0
 jne start_duplicate
 lea rax,[rbx+3]
 cmp rax,r14
 jae start_expected
 TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_START
 jne start_expected
 lea rax,[rbx+1]
 TOKEN_PTR r11,rax
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne start_expected
 lea rax,[rbx+2]
 TOKEN_PTR r11,rax
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne start_expected
 lea rax,[rbx+3]
 TOKEN_PTR r11,rax
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LBRACE
 jne start_expected
 mov [rsp+16],rax
 lea r11,[rbx+4]
 mov [rsp+24],r11
 mov r10,1
start_scan:
 cmp r11,r14
 jae start_expected_at_scan
 TOKEN_PTR rax,r11
 mov rcx,[rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp rcx,NEBOC_TOKEN_EOF
 je start_expected_at_scan
 cmp rcx,NEBOC_TOKEN_LBRACE
 jne start_scan_close
 inc r10
 cmp r10,[r12+NEBOC_PARSER_MAX_NESTING_OFFSET]
 ja start_nesting
 jmp start_scan_next
start_scan_close:
 cmp rcx,NEBOC_TOKEN_RBRACE
 jne start_scan_next
 dec r10
 jz start_scan_done
start_scan_next:
 inc r11
 jmp start_scan
start_scan_done:
 mov [rsp+8],r11
 ; append StartDecl
 TOKEN_PTR r10,qword [rsp]
 TOKEN_PTR r11,qword [rsp+8]
 mov rdi,r15
 mov esi,NEBOC_AST_START_DECL
 mov rdx,[r12+NEBOC_PARSER_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_TOKEN_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[r12+NEBOC_PARSER_LAST_NODE_ID_OFFSET]
 call neboc_ast_builder_append
 test eax,eax
 jnz start_done
 ; append Block
 TOKEN_PTR r10,qword [rsp+16]
 TOKEN_PTR r11,qword [rsp+8]
 mov rdi,r15
 mov esi,NEBOC_AST_BLOCK
 mov rdx,[r12+NEBOC_PARSER_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_TOKEN_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[r12+NEBOC_PARSER_SCRATCH0_OFFSET]
 call neboc_ast_builder_append
 test eax,eax
 jnz start_done
 mov rdi,r15
 mov rsi,[r12+NEBOC_PARSER_LAST_NODE_ID_OFFSET]
 lea rdx,[r12+NEBOC_PARSER_SCRATCH1_OFFSET]
 call neboc_ast_builder_node
 test eax,eax
 jnz start_done
 mov r10,[r12+NEBOC_PARSER_SCRATCH1_OFFSET]
 mov rax,[r12+NEBOC_PARSER_SCRATCH0_OFFSET]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 mov rdi,r15
 mov rsi,rax
 lea rdx,[r12+NEBOC_PARSER_SCRATCH1_OFFSET]
 call neboc_ast_builder_node
 test eax,eax
 jnz start_done
 mov r10,[r12+NEBOC_PARSER_SCRATCH1_OFFSET]
 or qword [r10+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_BODY_OPAQUE
 mov rax,[rsp+24]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rcx,[rsp+8]
 sub rcx,rax
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rcx
 mov rax,[rsp+8]
 inc rax
 mov [r12+NEBOC_PARSER_INDEX_OFFSET],rax
 mov qword [r12+NEBOC_PARSER_START_COUNT_OFFSET],1
 xor eax,eax
 jmp start_done
start_duplicate:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_DUPLICATE_START
 mov rdx,rbx
 call neboc_parser_set_error
 jmp start_done
start_nesting:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_NESTING_LIMIT
 mov rdx,r11
 call neboc_parser_set_error
 jmp start_done
start_expected_at_scan:
 mov rbx,r11
start_expected:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_EXPECTED_TOKEN
 mov rdx,rbx
 call neboc_parser_set_error
start_done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; parser_parse_function(ParserRequest*)
NEBOC_ABI_FUNCTION neboc_parser_parse_function
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,96
 mov r12,rdi
 mov r13,[r12+NEBOC_PARSER_TOKENS_OFFSET]
 mov r14,[r12+NEBOC_PARSER_TOKEN_COUNT_OFFSET]
 mov r15,[r12+NEBOC_PARSER_BUILDER_OFFSET]
 mov rbx,[r12+NEBOC_PARSER_INDEX_OFFSET]
 mov [rsp],rbx
 lea rax,[rbx+6]
 cmp rax,r14
 jae function_expected
 ; fixed receiver/function prefix
 TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne function_expected
 lea rax,[rbx+1]
 TOKEN_PTR r11,rax
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne function_expected
 lea rax,[rbx+2]
 TOKEN_PTR r11,rax
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne function_expected
 lea rax,[rbx+3]
 TOKEN_PTR r11,rax
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne function_expected
 lea rax,[rbx+4]
 TOKEN_PTR r11,rax
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne function_expected
 lea rax,[rbx+5]
 TOKEN_PTR r11,rax
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne function_expected
 lea rax,[rbx+6]
 TOKEN_PTR r11,rax
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne function_expected
 lea r11,[rbx+7]
 mov [rsp+8],r11
 mov qword [rsp+40],0
 ; scan parameter list
function_param_scan:
 cmp r11,r14
 jae function_expected_at_index
 TOKEN_PTR rax,r11
 mov rcx,[rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp rcx,NEBOC_TOKEN_RPAREN
 je function_params_done
 cmp rcx,NEBOC_TOKEN_IDENTIFIER
 jne function_expected_at_index
 lea rax,[r11+2]
 cmp rax,r14
 jae function_expected_at_index
 lea rax,[r11+1]
 TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LESS
 je function_param_generic_scan
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne function_expected_at_index
 lea rax,[r11+2]
 TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne function_expected_at_index
 inc qword [rsp+40]
 add r11,3
 jmp function_param_separator
function_param_generic_scan:
 ; Exact material generic parameter shape: Outer<Element>.name.  Semantic
 ; owners later restrict Outer to Slice and Element to Int/Bool/Char.
 lea rax,[r11+5]
 cmp rax,r14
 jae function_expected_at_index
 lea rax,[r11+2]
 TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne function_expected_at_index
 lea rax,[r11+3]
 TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_GREATER
 jne function_expected_at_index
 lea rax,[r11+4]
 TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne function_expected_at_index
 lea rax,[r11+5]
 TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne function_expected_at_index
 inc qword [rsp+40]
 add r11,6
function_param_separator:
 cmp r11,r14
 jae function_expected_at_index
 TOKEN_PTR rax,r11
 mov rcx,[rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp rcx,NEBOC_TOKEN_COMMA
 jne function_param_scan
 inc r11
 jmp function_param_scan
function_params_done:
 mov [rsp+16],r11
 lea rax,[r11+1]
 cmp rax,r14
 jae function_expected_at_index
 mov [rsp+24],rax
 TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LBRACE
 jne function_expected_at_index
 lea r11,[rax+1]
 mov [rsp+80],r11
 mov r10,1
function_block_scan:
 cmp r11,r14
 jae function_expected_at_index
 TOKEN_PTR rax,r11
 mov rcx,[rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp rcx,NEBOC_TOKEN_EOF
 je function_expected_at_index
 cmp rcx,NEBOC_TOKEN_LBRACE
 jne function_block_close
 inc r10
 cmp r10,[r12+NEBOC_PARSER_MAX_NESTING_OFFSET]
 ja function_nesting
 jmp function_block_next
function_block_close:
 cmp rcx,NEBOC_TOKEN_RBRACE
 jne function_block_next
 dec r10
 jz function_block_done
function_block_next:
 inc r11
 jmp function_block_scan
function_block_done:
 mov [rsp+32],r11
 ; append FunctionDecl
 TOKEN_PTR r10,qword [rsp]
 TOKEN_PTR r11,qword [rsp+32]
 mov rdi,r15
 mov esi,NEBOC_AST_FUNCTION_DECL
 mov rdx,[r12+NEBOC_PARSER_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_TOKEN_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[r12+NEBOC_PARSER_LAST_NODE_ID_OFFSET]
 call neboc_ast_builder_append
 test eax,eax
 jnz function_done
 mov rax,[r12+NEBOC_PARSER_LAST_NODE_ID_OFFSET]
 mov [rsp+48],rax
 ; receiver
 mov rax,[rsp]
 inc rax
 TOKEN_PTR r10,rax
 mov rax,[rsp]
 add rax,3
 TOKEN_PTR r11,rax
 mov rdi,r15
 mov esi,NEBOC_AST_RECEIVER
 mov rdx,[r12+NEBOC_PARSER_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_TOKEN_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[r12+NEBOC_PARSER_SCRATCH0_OFFSET]
 call neboc_ast_builder_append
 test eax,eax
 jnz function_done
 mov rax,[r12+NEBOC_PARSER_SCRATCH0_OFFSET]
 mov [rsp+56],rax
 mov [rsp+64],rax
 mov rdi,r15
 mov rsi,rax
 lea rdx,[r12+NEBOC_PARSER_SCRATCH1_OFFSET]
 call neboc_ast_builder_node
 test eax,eax
 jnz function_done
 mov r10,[r12+NEBOC_PARSER_SCRATCH1_OFFSET]
 mov rax,[rsp]
 inc rax
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rax,[rsp]
 add rax,3
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 ; parameters, second pass
 mov r11,[rsp+8]
function_append_params:
 cmp r11,[rsp+16]
 jae function_append_block
 mov [rsp+72],r11
 mov qword [rsp+88],3
 lea rax,[r11+1]
 TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LESS
 jne function_append_param_width_ready
 mov qword [rsp+88],6
function_append_param_width_ready:
 TOKEN_PTR r10,r11
 mov rdi,r15
 mov esi,NEBOC_AST_PARAMETER
 mov rdx,[r12+NEBOC_PARSER_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_TOKEN_START_OFFSET]
 mov rax,[rsp+88]
 dec rax
 add rax,r11
 TOKEN_PTR r10,rax
 mov r8,[r10+NEBOC_TOKEN_END_OFFSET]
 lea r9,[r12+NEBOC_PARSER_SCRATCH0_OFFSET]
 call neboc_ast_builder_append
 test eax,eax
 jnz function_done
 ; link previous child to parameter
 mov rdi,r15
 mov rsi,[rsp+64]
 lea rdx,[r12+NEBOC_PARSER_SCRATCH1_OFFSET]
 call neboc_ast_builder_node
 test eax,eax
 jnz function_done
 mov r10,[r12+NEBOC_PARSER_SCRATCH1_OFFSET]
 mov rax,[r12+NEBOC_PARSER_SCRATCH0_OFFSET]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
 mov [rsp+64],rax
 mov rdi,r15
 mov rsi,rax
 lea rdx,[r12+NEBOC_PARSER_SCRATCH1_OFFSET]
 call neboc_ast_builder_node
 test eax,eax
 jnz function_done
 mov r10,[r12+NEBOC_PARSER_SCRATCH1_OFFSET]
 mov r11,[rsp+72]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],r11
 mov rax,[rsp+88]
 cmp rax,6
 jne function_append_param_payload_name
 or qword [r10+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_GENERIC_PARAMETER
function_append_param_payload_name:
 dec rax
 add rax,r11
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 add r11,[rsp+88]
 cmp r11,[rsp+16]
 jae function_append_params
 inc r11
 jmp function_append_params
function_append_block:
 TOKEN_PTR r10,qword [rsp+24]
 TOKEN_PTR r11,qword [rsp+32]
 mov rdi,r15
 mov esi,NEBOC_AST_BLOCK
 mov rdx,[r12+NEBOC_PARSER_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_TOKEN_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[r12+NEBOC_PARSER_SCRATCH0_OFFSET]
 call neboc_ast_builder_append
 test eax,eax
 jnz function_done
 mov rdi,r15
 mov rsi,[rsp+64]
 lea rdx,[r12+NEBOC_PARSER_SCRATCH1_OFFSET]
 call neboc_ast_builder_node
 test eax,eax
 jnz function_done
 mov r10,[r12+NEBOC_PARSER_SCRATCH1_OFFSET]
 mov rax,[r12+NEBOC_PARSER_SCRATCH0_OFFSET]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
 mov rdi,r15
 mov rsi,rax
 lea rdx,[r12+NEBOC_PARSER_SCRATCH1_OFFSET]
 call neboc_ast_builder_node
 test eax,eax
 jnz function_done
 mov r10,[r12+NEBOC_PARSER_SCRATCH1_OFFSET]
 or qword [r10+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_BODY_OPAQUE
 mov rax,[rsp+80]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rcx,[rsp+32]
 sub rcx,rax
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rcx
 ; finalize function node
 mov rdi,r15
 mov rsi,[rsp+48]
 lea rdx,[r12+NEBOC_PARSER_SCRATCH1_OFFSET]
 call neboc_ast_builder_node
 test eax,eax
 jnz function_done
 mov r10,[r12+NEBOC_PARSER_SCRATCH1_OFFSET]
 mov rax,[rsp+56]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov rax,[rsp+40]
 add rax,2
 mov [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],rax
 mov rax,[rsp]
 add rax,5
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rax,[rsp+40]
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 mov rax,[rsp+32]
 inc rax
 mov [r12+NEBOC_PARSER_INDEX_OFFSET],rax
 xor eax,eax
 jmp function_done
function_nesting:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_NESTING_LIMIT
 mov rdx,r11
 call neboc_parser_set_error
 jmp function_done
function_expected_at_index:
 mov rbx,r11
function_expected:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_EXPECTED_TOKEN
 mov rdx,rbx
 call neboc_parser_set_error
function_done:
 add rsp,96
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
