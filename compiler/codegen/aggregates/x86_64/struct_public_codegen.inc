; Named products share the canonical declaration/type/layout owner. Only the
; ordinary expression backend evaluates initializers and projects live fields.
%include "compiler/semantic/types/struct_tuple.inc"
section .text

; state, name token -> declaration pointer, private material type id.
fcg_struct_decl:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,[rbx+FCG_STRUCT_OWNER]
 test r13,r13
 jz .no
 xor r14d,r14d
.loop:
 cmp r14,[r13+NEBOC_ST_DECL_COUNT_OFFSET]
 jae .no
 imul r15,r14,NEBOC_DECL_SIZE
 add r15,[r13+NEBOC_ST_DECLS_OFFSET]
 mov rdi,rbx
 mov rsi,r12
 mov rdx,[r15+NEBOC_DECL_NAME_OFFSET]
 call fcg_names_equal
 test eax,eax
 jnz .found
 inc r14
 jmp .loop
.found:
 mov rax,r15
 lea rdx,[r14+FCG_TYPE_STRUCT_BASE]
 jmp .done
.no:
 xor eax,eax
 xor edx,edx
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state, declaration, field name token -> field ordinal + 1, or zero.
fcg_struct_field_named:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 xor r14d,r14d
.loop:
 cmp r14,[r12+NEBOC_DECL_FIELD_COUNT_OFFSET]
 jae .no
 mov rdi,rbx
 mov rsi,r13
 mov rdx,[r12+r14*8+NEBOC_DECL_FIELD_NAMES_OFFSET]
 call fcg_names_equal
 test eax,eax
 jnz .found
 inc r14
 jmp .loop
.found:
 lea rax,[r14+1]
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Native scalar/layout type -> canonical expression type. No erased fields.
fcg_struct_native_type:
 mov rax,rdi
 cmp rax,NEBOC_TYPE_STRUCT_BASE
 jae .product
 cmp eax,1
 je .int
 cmp eax,2
 je .done
 cmp eax,3
 je .char
 cmp eax,4
 je .done
 xor eax,eax
 ret
.int:
 mov eax,NEBOC_TYPE_ID_INT
 ret
.char:
 mov eax,NEBOC_TYPE_ID_CHAR
 ret
.product:
 sub rax,NEBOC_TYPE_STRUCT_BASE
 cmp rax,NEBOC_ST_MAX_DECLS
 jae .bad
 add rax,FCG_TYPE_STRUCT_BASE
.done:
 ret
.bad:
 xor eax,eax
 ret

; state, constructor AST id, recursion depth -> type id, declaration pointer.
; Validate every initializer against its named native field before emission.
fcg_struct_constructor_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .bad
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_STRUCT_CONSTRUCTOR
 jne .bad
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_struct_decl
 test rax,rax
 jz .bad
 mov r15,rax
 mov [rsp],rdx
 mov rax,[r15+NEBOC_DECL_FIELD_COUNT_OFFSET]
 cmp rax,[r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 jne .bad
 mov qword [rsp+8],0
 mov r14,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.field:
 test r14,r14
 jz .complete
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov [rsp+16],rax
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_NAMED_ARGUMENT
 jne .bad
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 mov rsi,r15
 call fcg_struct_field_named
 test rax,rax
 jz .bad
 dec rax
 bts qword [rsp+8],rax
 jc .bad
 mov rdi,[r15+rax*8+NEBOC_DECL_FIELD_TYPES_OFFSET]
 call fcg_struct_native_type
 mov [rsp+24],rax
 mov rax,[rsp+16]
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_infer_type
 test rax,rax
 jz .bad
 cmp rax,[rsp+24]
 jne .bad
 mov rax,[rsp+16]
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .field
.complete:
 mov rcx,[r15+NEBOC_DECL_FIELD_COUNT_OFFSET]
 mov eax,1
 shl rax,cl
 dec rax
 cmp rax,[rsp+8]
 jne .bad
 mov rax,[rsp]
 mov rdx,r15
 jmp .done
.bad:
 mov rdi,rbx
 mov rsi,r12
 call fcg_struct_error
 xor eax,eax
 xor edx,edx
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state, projection node, depth -> canonical type, byte offset, receiver id.
; The receiver is resolved in the current lexical scope; a spelling alone
; cannot turn an ordinary binding or enum into a struct field.
fcg_struct_field_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .no
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,rax
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 je .ordinary
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_NOMINAL_VARIANT_RECEIVER
 jz .no
 mov rax,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 jmp .name
.ordinary:
 mov rax,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
.name:
 mov [rsp],rax
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov [rsp+8],rsi
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_infer_type
 sub rax,FCG_TYPE_STRUCT_BASE
 cmp rax,NEBOC_ST_MAX_DECLS
 jae .no
 mov r15,[rbx+FCG_STRUCT_OWNER]
 test r15,r15
 jz .no
 cmp rax,[r15+NEBOC_ST_DECL_COUNT_OFFSET]
 jae .no
 imul rax,NEBOC_DECL_SIZE
 add rax,[r15+NEBOC_ST_DECLS_OFFSET]
 mov r15,rax
 mov rdi,rbx
 mov rsi,r15
 mov rdx,[rsp]
 call fcg_struct_field_named
 test rax,rax
 jz .no
 dec rax
 mov rdx,[r15+rax*8+NEBOC_DECL_FIELD_OFFSETS_OFFSET]
 mov [rsp+16],rdx
 mov rdi,[r15+rax*8+NEBOC_DECL_FIELD_TYPES_OFFSET]
 call fcg_struct_native_type
 mov rdx,[rsp+16]
 mov rcx,[rsp+8]
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

fcg_struct_expr_type:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_STRUCT_CONSTRUCTOR
 je .constructor
 call fcg_struct_field_info
 test rax,rax
 jnz .done
.bad:
 mov rdi,rbx
 mov rsi,r12
 call fcg_struct_error
 xor eax,eax
 jmp .done
.constructor:
 call fcg_struct_constructor_info
.done:
 pop r13
 pop r12
 pop rbx
 ret

fcg_struct_error:
 push rbx
 mov rbx,rdi
 cmp qword [rbx+FCG_STRUCT_ERROR],0
 jne .done
 mov qword [rbx+FCG_STRUCT_ERROR],1
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],0
 jne .span
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ASSIGNMENT_TYPE
.span:
 call fcg_capture_node_span
.done:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 pop rbx
 ret

%macro FSP_APPEND 1
 mov rdi,rbx
 lea rsi,[rel %1]
 mov edx,%1 %+ _len
 call fcg_append
 test eax,eax
 jnz .done
%endmacro
%macro FSP_NUMBER 1
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,%1
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
%endmacro

fcg_emit_struct_expr:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_STRUCT_CONSTRUCTOR
 jne .projection
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_struct_constructor_info
 test rax,rax
 jz .bad
 mov r15,rdx
 mov rax,[r15+NEBOC_DECL_SIZE_OFFSET]
 add rax,47
 and rax,-16
 mov [rsp],rax
 FSP_APPEND ftm_frame_head
 FSP_NUMBER [rsp]
 FSP_APPEND ftm_frame_tail
 ; Zero native padding and fields, then evaluate each source child once.
 FSP_APPEND fsp_zero_head
 FSP_NUMBER [r15+NEBOC_DECL_SIZE_OFFSET]
 FSP_APPEND fsp_zero_tail
 mov r14,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.field:
 test r14,r14
 jz .constructed
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov [rsp+8],rax
 mov rdi,rbx
 mov rsi,r15
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_struct_field_named
 test rax,rax
 jz .bad
 dec rax
 mov rdx,[r15+rax*8+NEBOC_DECL_FIELD_OFFSETS_OFFSET]
 add rdx,32
 mov [rsp+16],rdx
 mov rax,[r15+rax*8+NEBOC_DECL_FIELD_TYPES_OFFSET]
 mov [rsp+24],rax
 mov rax,[rsp+8]
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 FSP_APPEND fsp_destination
 FSP_NUMBER [rsp+16]
 FSP_APPEND fsp_bracket
 cmp qword [rsp+24],1
 je .store_int
 cmp qword [rsp+24],2
 je .store_bool
 cmp qword [rsp+24],3
 je .store_char
 cmp qword [rsp+24],4
 je .store_text
 mov rax,[rsp+24]
 sub rax,NEBOC_TYPE_STRUCT_BASE
 imul rax,NEBOC_DECL_SIZE
 mov rdx,[rbx+FCG_STRUCT_OWNER]
 add rax,[rdx+NEBOC_ST_DECLS_OFFSET]
 mov rax,[rax+NEBOC_DECL_SIZE_OFFSET]
 mov [rsp+32],rax
 FSP_APPEND fsp_copy_head
 FSP_NUMBER [rsp+32]
 FSP_APPEND fsp_copy_tail
 jmp .next
.store_int:
 FSP_APPEND fsp_store_int
 jmp .next
.store_bool:
 FSP_APPEND fsp_store_bool
 jmp .next
.store_char:
 FSP_APPEND fsp_store_char
 jmp .next
.store_text:
 FSP_APPEND fsp_store_text
.next:
 mov rax,[rsp+8]
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .field
.constructed:
 FSP_APPEND fsp_constructed
 xor eax,eax
 jmp .done
.projection:
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_struct_field_info
 test rax,rax
 jz .bad
 mov [rsp],rax
 mov [rsp+8],rdx
 mov rdi,rbx
 mov rsi,rcx
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 FSP_APPEND fsp_project_head
 FSP_NUMBER [rsp+8]
 FSP_APPEND fcg_newline
 cmp qword [rsp],NEBOC_TYPE_ID_INT
 je .load_int
 cmp qword [rsp],NEBOC_TYPE_ID_BOOL
 je .load_bool
 cmp qword [rsp],NEBOC_TYPE_ID_CHAR
 je .load_char
 cmp qword [rsp],NEBOC_TYPE_ID_TEXT
 je .load_text
 xor eax,eax
 jmp .done
.load_int:
 FSP_APPEND fsp_load_int
 jmp .done
.load_bool:
 FSP_APPEND fsp_load_bool
 jmp .done
.load_char:
 FSP_APPEND fsp_load_char
 jmp .done
.load_text:
 FSP_APPEND ftm_frame_head
 FSP_NUMBER 64
 FSP_APPEND ftm_frame_tail
 FSP_APPEND fsp_load_text
 jmp .done
.bad:
 mov rdi,rbx
 mov rsi,r12
 call fcg_struct_error
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .rodata
fsp_zero_head: db '    lea rdi, [r12 + 32]',10,'    xor eax, eax',10,'    mov ecx, '
fsp_zero_head_len equ $-fsp_zero_head
fsp_zero_tail: db 10,'    rep stosb',10
fsp_zero_tail_len equ $-fsp_zero_tail
fsp_destination: db '    lea rdi, [r12 + '
fsp_destination_len equ $-fsp_destination
fsp_bracket: db ']',10
fsp_bracket_len equ $-fsp_bracket
fsp_store_int: db '    mov [rdi], rax',10
fsp_store_int_len equ $-fsp_store_int
fsp_store_bool: db '    mov [rdi], al',10
fsp_store_bool_len equ $-fsp_store_bool
fsp_store_char: db '    mov [rdi], eax',10
fsp_store_char_len equ $-fsp_store_char
fsp_store_text: db '    mov rcx, [rax]',10,'    mov [rdi], rcx',10,'    mov rcx, [rax + 8]',10,'    mov [rdi + 8], rcx',10
fsp_store_text_len equ $-fsp_store_text
fsp_copy_head: db '    mov rsi, rax',10,'    mov ecx, '
fsp_copy_head_len equ $-fsp_copy_head
fsp_copy_tail: db 10,'    rep movsb',10
fsp_copy_tail_len equ $-fsp_copy_tail
fsp_constructed: db '    lea rax, [r12 + 32]',10,'    mov r12, [r12 + 24]',10
fsp_constructed_len equ $-fsp_constructed
fsp_project_head: db '    add rax, '
fsp_project_head_len equ $-fsp_project_head
fsp_load_int: db '    mov rax, [rax]',10
fsp_load_int_len equ $-fsp_load_int
fsp_load_bool: db '    movzx eax, byte [rax]',10
fsp_load_bool_len equ $-fsp_load_bool
fsp_load_char: db '    mov eax, [rax]',10
fsp_load_char_len equ $-fsp_load_char
; Native Text fields are ptr/length pairs. Bridge to the ordinary Text ABI in
; a distinct owned frame; never reinterpret the following field as flags.
fsp_load_text: db '    mov rcx, [rax]',10,'    mov [r12 + 32], rcx',10,'    mov rcx, [rax + 8]',10,'    mov [r12 + 40], rcx',10,'    mov dword [r12 + 48], 0',10,'    mov word [r12 + 52], 1',10,'    mov word [r12 + 54], 1',10,'    lea rax, [r12 + 32]',10,'    mov r12, [r12 + 24]',10
fsp_load_text_len equ $-fsp_load_text
section .text
