; Source profile spellings resolve to the canonical G062 registry, then the
; same immutable typed nodes consumed by formatting A and interpolation B.
%include "runtime/textual/format_profiles.inc"
extern neboc_format_profile_validate
section .rodata
fip_text: db 'text'
fip_quote: db 'quote'
fip_json: db 'json'
fip_fixed: db 'fixed'
fip_scientific: db 'scientific'
fip_hex: db 'hex'
fip_octal: db 'octal'
fip_binary: db 'binary'
fip_decimal: db 'decimal'
fip_align: db 'align'
fip_width: db 'width'
fip_left: db 'left'
fip_right: db 'right'
fip_center: db 'center'
align 8
fip_rows:
 dq fip_text,4,FORMAT_PROFILE_TEXT,PERCENT_TYPE_TEXT,0
 dq fip_quote,5,FORMAT_PROFILE_QUOTE,PERCENT_TYPE_QUOTE,0
 dq fip_json,4,FORMAT_PROFILE_JSON,PERCENT_TYPE_JSON,0
 dq fip_fixed,5,FORMAT_PROFILE_FIXED,PERCENT_TYPE_FLOAT,1
 dq fip_scientific,10,FORMAT_PROFILE_SCIENTIFIC,PERCENT_TYPE_SCIENTIFIC,1
 dq fip_hex,3,FORMAT_PROFILE_HEX,PERCENT_TYPE_HEX,2
 dq fip_octal,5,FORMAT_PROFILE_OCTAL,PERCENT_TYPE_OCTAL,2
 dq fip_binary,6,FORMAT_PROFILE_BINARY,PERCENT_TYPE_BINARY,2
 dq fip_decimal,7,FORMAT_PROFILE_DECIMAL,PERCENT_TYPE_INT,2
 dq fip_align,5,FORMAT_PROFILE_ALIGN,PERCENT_TYPE_TEXT,3
fip_rows_end:
section .text

; RDI state, RSI value wrapper, RDX percent node, RCX actual argument kind.
; Profile parameters are compile-time Int literals within the native bounds.
fcg_interpolation_profile:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov [rsp],rcx
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 je .success
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .arity
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .unknown
 mov r12,rax
 mov rax,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_IDENTIFIER_EXPR
 je .bare
 cmp rax,NEBOC_AST_CALL_EXPR
 jne .unknown
 test qword [r12+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .unknown
 mov rax,[r12+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 mov [rsp+8],rax
 mov r15,[r12+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 jmp .lookup
.bare:
 mov qword [rsp+8],0
 xor r15d,r15d
.lookup:
 lea r14,[rel fip_rows]
.row:
 mov rdi,rbx
 mov rsi,[r12+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,[r14]
 mov rcx,[r14+8]
 call fcg_token_matches_literal
 test eax,eax
 jnz .typed
 add r14,40
 lea rax,[rel fip_rows_end]
 cmp r14,rax
 jb .row
 jmp .unknown
.typed:
 mov rdi,[r14+16]
 mov rsi,[rsp]
 call neboc_format_profile_validate
 test eax,eax
 jnz .type
 mov rax,[r14+24]
 mov [r13+PERCENT_NODE_TYPE],rax
 mov rax,[r14+32]
 cmp eax,3
 je .alignment
 cmp eax,1
 je .precision
 cmp eax,2
 je .width
 cmp qword [rsp+8],0
 jne .arity
 jmp .success
.precision:
 cmp qword [rsp+8],1
 jne .arity
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .type
 mov rax,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,PERCENT_MAX_PRECISION
 ja .bounds
 mov [r13+PERCENT_NODE_PRECISION],rax
 jmp .success
.width:
 cmp qword [rsp+8],0
 je .success
 cmp qword [rsp+8],1
 jne .arity
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_NAMED_ARGUMENT
 jne .width_value
 mov [rsp+16],rax
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel fip_width]
 mov ecx,5
 call fcg_token_matches_literal
 test eax,eax
 jz .named
 mov rax,[rsp+16]
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
.width_value:
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .type
 mov rax,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,PERCENT_MAX_WIDTH
 ja .bounds
 mov [r13+PERCENT_NODE_WIDTH],rax
 jmp .success
.alignment:
 cmp qword [rsp+8],2
 jne .arity
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .type
 mov r12,rax
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel fip_right]
 mov ecx,5
 call fcg_token_matches_literal
 test eax,eax
 jnz .aligned
 mov rdi,rbx
 mov rsi,[r12+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel fip_left]
 mov ecx,4
 call fcg_token_matches_literal
 test eax,eax
 jz .center
 mov qword [r13+PERCENT_NODE_FLAGS],PERCENT_FLAG_LEFT
 jmp .aligned
.center:
 mov rdi,rbx
 mov rsi,[r12+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel fip_center]
 mov ecx,6
 call fcg_token_matches_literal
 test eax,eax
 jz .type
 mov qword [r13+PERCENT_NODE_FLAGS],PERCENT_FLAG_CENTER
.aligned:
 mov rdi,rbx
 mov rsi,[r12+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 call fcg_node_ptr
 jmp .width_value
.success: xor eax,eax
 jmp .done
.unknown: mov eax,PERCENT_DIAG_UNKNOWN_PLACEHOLDER
 jmp .done
.type: mov eax,PERCENT_DIAG_TYPE_MISMATCH
 jmp .done
.arity: mov eax,PERCENT_DIAG_ARITY_MISMATCH
 jmp .done
.bounds: mov eax,PERCENT_DIAG_WIDTH_PRECISION
 jmp .done
.named: mov eax,PERCENT_DIAG_NAMED_ARGUMENT
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
