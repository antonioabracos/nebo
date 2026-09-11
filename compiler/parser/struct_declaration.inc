; Materialize the declaration already validated by the canonical native layout
; owner. Every field retains a normal typed parameter node and source span.
%include "compiler/semantic/types/struct_tuple.inc"
neboc_parser_parse_struct:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov r12,rdi
 mov r13,[r12+NEBOC_PARSER_TOKENS_OFFSET]
 mov r14,[r12+NEBOC_PARSER_TOKEN_COUNT_OFFSET]
 mov r15,[r12+NEBOC_PARSER_BUILDER_OFFSET]
 mov rbx,[r12+NEBOC_PARSER_STRUCT_OWNER_OFFSET]
 test rbx,rbx
 jz .invalid
 mov rax,[r12+NEBOC_PARSER_INDEX_OFFSET]
 inc rax
 mov [rsp+40],rax
 xor ecx,ecx
.declaration:
 cmp rcx,[rbx+NEBOC_ST_DECL_COUNT_OFFSET]
 jae .invalid
 imul rdx,rcx,NEBOC_DECL_SIZE
 add rdx,[rbx+NEBOC_ST_DECLS_OFFSET]
 cmp rax,[rdx+NEBOC_DECL_NAME_OFFSET]
 je .found
 inc rcx
 jmp .declaration
.found:
 mov [rsp+16],rcx
 mov [rsp+24],rdx
 mov rax,[rdx+NEBOC_DECL_FIELD_COUNT_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,NEBOC_ST_MAX_FIELDS
 ja .invalid
 dec rax
 mov rax,[rdx+NEBOC_DECL_FIELD_NAMES_OFFSET+rax*8]
 add rax,2
 cmp rax,r14
 jae .invalid
 TOKEN_PTR r11,rax
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RBRACE
 jne .invalid
 inc rax
 mov [rsp+32],rax
 mov rdi,r15
 mov esi,NEBOC_AST_STRUCT_DECL
 mov rdx,[r12+NEBOC_PARSER_SOURCE_ID_OFFSET]
 TOKEN_PTR r10,qword [r12+NEBOC_PARSER_INDEX_OFFSET]
 mov rcx,[r10+NEBOC_TOKEN_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp]
 call neboc_ast_builder_append
 test eax,eax
 jnz .done
 mov rdi,r15
 mov rsi,[rsp]
 lea rdx,[rsp+8]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov rbx,[rsp+8]
 mov rax,[rsp+16]
 mov [rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rax,[rsp+40]
 mov [rbx+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 mov qword [rsp+16],0
.field:
 mov rax,[rsp+16]
 mov rdx,[rsp+24]
 cmp rax,[rdx+NEBOC_DECL_FIELD_COUNT_OFFSET]
 jae .finished
 mov rax,[rdx+NEBOC_DECL_FIELD_NAMES_OFFSET+rax*8]
 mov [rsp+40],rax
 lea rcx,[rax-2]
 TOKEN_PTR r10,rcx
 inc rax
 TOKEN_PTR r11,rax
 mov rdi,r15
 mov esi,NEBOC_AST_PARAMETER
 mov rdx,[r12+NEBOC_PARSER_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_TOKEN_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+8]
 call neboc_ast_builder_append
 test eax,eax
 jnz .done
 cmp qword [rsp+16],0
 jne .link
 mov rax,[rsp+8]
 mov [rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 jmp .initialize
.link:
 ; Field nodes are adjacent because their type/name grammar was already
 ; consumed by the layout owner; there are no hidden expression effects.
 mov rdi,r15
 mov rsi,[rsp+8]
 dec rsi
 lea rdx,[r12+NEBOC_PARSER_SCRATCH0_OFFSET]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov r10,[r12+NEBOC_PARSER_SCRATCH0_OFFSET]
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
.initialize:
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[r12+NEBOC_PARSER_SCRATCH0_OFFSET]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov r10,[r12+NEBOC_PARSER_SCRATCH0_OFFSET]
 mov rax,[rsp+40]
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 sub rax,2
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 inc qword [rbx+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 inc qword [rsp+16]
 jmp .field
.finished:
 mov rax,[rsp]
 mov [r12+NEBOC_PARSER_LAST_NODE_ID_OFFSET],rax
 mov rax,[rsp+32]
 mov [r12+NEBOC_PARSER_INDEX_OFFSET],rax
 xor eax,eax
 jmp .done
.invalid:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_EXPECTED_TOKEN
 mov rdx,[r12+NEBOC_PARSER_INDEX_OFFSET]
 call neboc_parser_set_error
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
