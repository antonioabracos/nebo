; Checked dynamic templates and compiler-owned typed argument signatures.
section .rodata
ftp_namespace: db 'FormatString'
ftp_parse: db 'parseChecked'
ftp_validate: db 'validate'
ftp_get: db 'get'
ftp_parse_call:
 db '%ifndef NEBO_FORMAT_TEMPLATE_EXTERN',10,'%define NEBO_FORMAT_TEMPLATE_EXTERN 1',10
 db 'extern nebo_runtime_textual_template_parse',10,'extern nebo_runtime_textual_template_validate',10,'%endif',10
 db '    mov [r12], rax',10,'    mov qword [r12 + 8], 0',10,'    mov qword [r12 + 16], 0',10
 db '    mov rdi, r12',10,'    call nebo_runtime_textual_template_parse',10,'    mov r12, [r12 + 24]',10
ftp_parse_call_len equ $-ftp_parse_call
ftp_signature_head:
 db '%ifndef NEBO_FORMAT_TEMPLATE_EXTERN',10,'%define NEBO_FORMAT_TEMPLATE_EXTERN 1',10
 db 'extern nebo_runtime_textual_template_parse',10,'extern nebo_runtime_textual_template_validate',10,'%endif',10
 db '    mov r11, [rax]',10,'    mov [r12], r11',10,'    mov r11, [rax + 8]',10,'    mov [r12 + 16], r11',10
 db '    mov qword [r12 + 8], '
ftp_signature_head_len equ $-ftp_signature_head
ftp_signature_slot: db '    lea r11, [r12 + '
ftp_signature_slot_len equ $-ftp_signature_slot
ftp_signature_kind: db ']',10,'    mov qword [r11], '
ftp_signature_kind_len equ $-ftp_signature_kind
ftp_signature_tail:
 db 10,'    mov qword [r11 + 8], 0',10,'    mov qword [r11 + 16], 0',10,'    mov qword [r11 + 24], 0',10
 db '    xor eax, eax',10,'    mov rdx, 0x3ff0000000000000',10,'    cmp qword [r11], 3',10,'    cmove rax, rdx',10,'    mov [r11 + 8], rax',10
ftp_signature_tail_len equ $-ftp_signature_tail
ftp_signature_name: db '    mov rax, '
ftp_signature_name_len equ $-ftp_signature_name
ftp_signature_name_end: db 10,'    mov [r11 + 24], rax',10
ftp_signature_name_end_len equ $-ftp_signature_name_end
ftp_validate_call:
 db '    mov rdi, r12',10,'    call nebo_runtime_textual_template_validate',10,'    lea rsp, [r12 + 11440]',10,'    mov r12, [r12 + 24]',10
ftp_validate_call_len equ $-ftp_validate_call
ftp_get_call:
 db '    cmp byte [rax], 0',10,'    jne nebo_runtime_textual_format_trap',10,'    lea rax, [rax + 16]',10
ftp_get_call_len equ $-ftp_get_call
ftp_unwrap_call:
 db '    mov rsi, rax',10,'    mov rdi, [r12]',10,'    xor edx, edx',10,'    call nebo_runtime_textual_checked_unwrap',10
 db '    mov r12, [r12 + 24]',10
ftp_unwrap_call_len equ $-ftp_unwrap_call
section .text

; State, signature member -> EAX argument kind, RCX stable named identity.
; A type signature contains metadata, never an evaluated replacement value.
fcg_format_signature_argument:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 xor r13d,r13d
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_NAMED_ARGUMENT
 jne .type_node
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_token_ptr
 test rax,rax
 jz .no
 mov rsi,[rax+NEBOC_TOKEN_END_OFFSET]
 mov rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 sub rsi,rdx
 jbe .no
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_OFFSET]
 add rdi,rdx
 call neboc_percent_name_hash
 mov r13,rax
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
.type_node:
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov r12,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 mov rsi,r12
 call fcg_resolve_identifier
 test rax,rax
 jnz .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_type_from_token
 call fcg_format_argument_kind
 mov rcx,r13
 jmp .done
.no: xor eax,eax
 xor ecx,ecx
.done:
 pop r13
 pop r12
 pop rbx
 ret

; State, Tuple type signature -> EAX success, RDX count, RCX first type node.
; Bare type names are metadata only if no lexical binding shadows them.
fcg_format_signature_info:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,24
 mov rbx,rdi
 call fcg_tuple_call_shape
 test eax,eax
 jz .no
 cmp rdx,6
 ja .no
 mov [rsp],rdx
 mov [rsp+8],rcx
 mov r12,rcx
 mov r13,rdx
.type:
 test r13,r13
 jz .yes
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov r14,r12
 mov r12,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 mov rsi,r14
 call fcg_format_signature_argument
 test eax,eax
 jz .no
 dec r13
 jmp .type
.yes:
 mov eax,1
 mov rdx,[rsp]
 mov rcx,[rsp+8]
 jmp .done
.no: xor eax,eax
.done:
 add rsp,24
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

fcg_format_template_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 mov r13,rax
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ftp_parse]
 mov ecx,12
 call fcg_token_matches_literal
 test eax,eax
 jz .instance
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov r14,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[rel ftp_namespace]
 mov ecx,12
 call fcg_token_matches_literal
 test eax,eax
 jz .no
 mov rdi,rbx
 mov rsi,r14
 call fcg_resolve_identifier
 test rax,rax
 jnz .no
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .arity
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_infer_type
 cmp eax,NEBOC_TYPE_ID_TEXT
 jne .type
 mov eax,18
 mov ecx,FCG_TYPE_FORMAT_PARSE_RESULT
 jmp .done
.instance:
 ; Probe spelling before recursive inference: unrelated methods remain with
 ; their existing owners and do not acquire format diagnostics.
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ftp_validate]
 mov ecx,8
 call fcg_token_matches_literal
 mov r14,rax
 test eax,eax
 jnz .infer_receiver
%macro FTP_CANDIDATE 2
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel %1]
 mov ecx,%2
 call fcg_token_matches_literal
 test eax,eax
 jnz .infer_receiver
%endmacro
 FTP_CANDIDATE ftp_get,3
 FTP_CANDIDATE ffm_unwrap_name,ffm_unwrap_name_len
 FTP_CANDIDATE ffm_ok_name,ffm_ok_name_len
 FTP_CANDIDATE ffm_err_name,ffm_err_name_len
%undef FTP_CANDIDATE
 jmp .no
.infer_receiver:
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov edx,1
 call fcg_infer_type
 cmp rax,FCG_TYPE_FORMAT_TEMPLATE
 je .validate
 cmp rax,FCG_TYPE_FORMAT_PARSE_RESULT
 jne .no
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ftp_get]
 mov ecx,3
 call fcg_token_matches_literal
 test eax,eax
 jnz .get
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ffm_unwrap_name]
 mov ecx,ffm_unwrap_name_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .unwrap
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ffm_ok_name]
 mov ecx,ffm_ok_name_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .ok
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ffm_err_name]
 mov ecx,ffm_err_name_len
 call fcg_token_matches_literal
 test eax,eax
 jz .no
 mov eax,5
 jmp .predicate
.ok: mov eax,4
.predicate:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .arity
 mov ecx,NEBOC_TYPE_ID_BOOL
 jmp .done
.get:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .arity
 mov eax,20
 mov ecx,FCG_TYPE_FORMAT_TEMPLATE
 jmp .done
.unwrap:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .arity
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov edx,1
 call fcg_infer_type
 cmp eax,FCG_TYPE_FORMAT_TEMPLATE
 jne .type
 mov eax,21
 mov ecx,FCG_TYPE_FORMAT_TEMPLATE
 jmp .done
.validate:
 test r14,r14
 jz .no
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .arity
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 call fcg_format_signature_info
 test eax,eax
 jz .type
 mov eax,19
 mov ecx,NEBOC_TYPE_ID_BOOL
 jmp .done
.arity: mov eax,PERCENT_DIAG_ARITY_MISMATCH
 jmp .error
.type: mov eax,PERCENT_DIAG_TYPE_MISMATCH
.error:
 mov rdi,rbx
 mov rsi,r12
 call fcg_format_record_error
.no: xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

fcg_format_template_emit:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 call fcg_format_template_info
 mov [rsp],rax
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov r13,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 cmp qword [rsp],20
 je .get
 FFM_APPEND ftm_frame_head
 mov esi,TEXT_FORMAT_FRAME_SIZE
 cmp qword [rsp],21
 jne .frame_size
 mov esi,64
.frame_size:
 FFM_NUMBER rsi
 FFM_APPEND ftm_frame_tail
 cmp qword [rsp],18
 jne .receiver
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
.receiver:
 mov rdi,rbx
 mov rsi,r13
 mov edx,1
 call fcg_emit_expr
 test eax,eax
 jnz .done
 cmp qword [rsp],18
 jne .not_parse
 FFM_APPEND ftp_parse_call
 jmp .success
.not_parse:
 cmp qword [rsp],21
 je .unwrap
 FFM_APPEND ftp_signature_head
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 call fcg_format_signature_info
 mov r14,rdx
 mov r13,rcx
 FFM_NUMBER r14
 FFM_APPEND fcg_newline
 xor r15d,r15d
.signature:
 cmp r15,r14
 jae .validate
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 mov rcx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+8],rcx
 mov rdi,rbx
 mov rsi,r13
 call fcg_format_signature_argument
 mov [rsp+16],rax
 mov [rsp+24],rcx
 FFM_APPEND ftp_signature_slot
 mov rax,r15
 shl rax,5
 add rax,TEXT_FORMAT_ARGS
 FFM_NUMBER rax
 FFM_APPEND ftp_signature_kind
 FFM_NUMBER [rsp+16]
 FFM_APPEND ftp_signature_tail
 FFM_APPEND ftp_signature_name
 FFM_NUMBER [rsp+24]
 FFM_APPEND ftp_signature_name_end
 mov r13,[rsp+8]
 inc r15
 jmp .signature
.validate:
 FFM_APPEND ftp_validate_call
 jmp .success
.get:
 mov rdi,rbx
 mov rsi,r13
 mov edx,1
 call fcg_emit_expr
 test eax,eax
 jnz .done
 FFM_APPEND ftp_get_call
 jmp .success
.unwrap:
 FFM_APPEND ffm_store_template
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov edx,1
 call fcg_emit_expr
 test eax,eax
 jnz .done
 FFM_APPEND ftp_unwrap_call
.success: xor eax,eax
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
