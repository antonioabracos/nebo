; Emit pointer-relocatable runtime reflection only from authenticated native
; product declarations. Field offsets and native types are never recomputed.
section .text
fcg_emit_struct_render_metadata:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,[rbx+FCG_STRUCT_OWNER]
 test r12,r12
 jz .ok
 cmp qword [r12+NEBOC_ST_DECL_COUNT_OFFSET],0
 je .ok
 FSP_APPEND fsv_header
 FSP_NUMBER [r12+NEBOC_ST_DECL_COUNT_OFFSET]
 FSP_APPEND fcg_newline
 xor r13d,r13d
.pointers:
 cmp r13,[r12+NEBOC_ST_DECL_COUNT_OFFSET]
 jae .declarations
 FSP_APPEND fsv_pointer
 FSP_NUMBER r13
 FSP_APPEND fcg_newline
 inc r13
 jmp .pointers
.declarations:
 xor r13d,r13d
.declaration:
 cmp r13,[r12+NEBOC_ST_DECL_COUNT_OFFSET]
 jae .ok
 imul r14,r13,NEBOC_DECL_SIZE
 add r14,[r12+NEBOC_ST_DECLS_OFFSET]
 FSP_APPEND fsv_label
 FSP_NUMBER r13
 FSP_APPEND fsv_colon_dq
 FSP_NUMBER [r14+NEBOC_DECL_SIZE_OFFSET]
 FSP_APPEND fcg_comma
 FSP_NUMBER [r14+NEBOC_DECL_FIELD_COUNT_OFFSET]
 FSP_APPEND fsv_name_reference
 FSP_NUMBER [r14+NEBOC_DECL_NAME_OFFSET]
 FSP_APPEND fcg_newline
 xor r15d,r15d
.field:
 cmp r15,[r14+NEBOC_DECL_FIELD_COUNT_OFFSET]
 jae .names
 FSP_APPEND fsv_dq_name
 FSP_NUMBER [r14+r15*8+NEBOC_DECL_FIELD_NAMES_OFFSET]
 FSP_APPEND fcg_comma
 FSP_NUMBER [r14+r15*8+NEBOC_DECL_FIELD_TYPES_OFFSET]
 FSP_APPEND fcg_comma
 FSP_NUMBER [r14+r15*8+NEBOC_DECL_FIELD_OFFSETS_OFFSET]
 FSP_APPEND fcg_newline
 inc r15
 jmp .field
.names:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_DECL_NAME_OFFSET]
 call fcg_emit_struct_render_name
 test eax,eax
 jnz .done
 xor r15d,r15d
.field_name:
 cmp r15,[r14+NEBOC_DECL_FIELD_COUNT_OFFSET]
 jae .next
 mov rdi,rbx
 mov rsi,[r14+r15*8+NEBOC_DECL_FIELD_NAMES_OFFSET]
 call fcg_emit_struct_render_name
 test eax,eax
 jnz .done
 inc r15
 jmp .field_name
.next:
 inc r13
 jmp .declaration
.ok:
 xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Identifier bytes are emitted as decimal bytes; source text cannot inject
; assembly syntax. The parser/semantic declaration owns this exact token.
fcg_emit_struct_render_name:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 call fcg_token_ptr
 test rax,rax
 jz .bad
 mov r13,[rax+NEBOC_TOKEN_START_OFFSET]
 mov r14,[rax+NEBOC_TOKEN_END_OFFSET]
 sub r14,r13
 jc .bad
 add r13,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_OFFSET]
 FSP_APPEND fsv_name_label
 FSP_NUMBER r12
 FSP_APPEND fsv_colon_name_data
 FSP_NUMBER r12
 FSP_APPEND fcg_comma
 FSP_NUMBER r14
 FSP_APPEND fcg_newline
 FSP_APPEND fsv_name_data
 FSP_NUMBER r12
 FSP_APPEND fsv_colon_db
 xor r15d,r15d
.byte:
 cmp r15,r14
 jae .end
 movzx esi,byte [r13+r15]
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 FSP_APPEND fcg_comma
 inc r15
 jmp .byte
.end:
 FSP_APPEND fsv_zero_newline
 xor eax,eax
 jmp .done
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .rodata
fsv_header: db 'section .rodata',10,'align 8',10,'nebo_struct_render_metadata: dq '
fsv_header_len equ $-fsv_header
fsv_pointer: db '    dq nebo_struct_render_decl_'
fsv_pointer_len equ $-fsv_pointer
fsv_label: db 'align 8',10,'nebo_struct_render_decl_'
fsv_label_len equ $-fsv_label
fsv_colon_dq: db ': dq '
fsv_colon_dq_len equ $-fsv_colon_dq
fsv_name_reference: db ',nebo_struct_render_name_'
fsv_name_reference_len equ $-fsv_name_reference
fsv_dq_name: db '    dq nebo_struct_render_name_'
fsv_dq_name_len equ $-fsv_dq_name
fsv_name_label: db 'align 8',10,'nebo_struct_render_name_'
fsv_name_label_len equ $-fsv_name_label
fsv_colon_name_data: db ': dq nebo_struct_render_bytes_'
fsv_colon_name_data_len equ $-fsv_colon_name_data
fsv_name_data: db 'nebo_struct_render_bytes_'
fsv_name_data_len equ $-fsv_name_data
fsv_colon_db: db ': db '
fsv_colon_db_len equ $-fsv_colon_db
fsv_zero_newline: db '0',10
fsv_zero_newline_len equ $-fsv_zero_newline
fsv_publish: db '%ifndef NEBO_PUBLIC_STRUCTURED_DECLARED',10,'%define NEBO_PUBLIC_STRUCTURED_DECLARED 1',10,'extern nebo_runtime_console_publish_structured',10,'%endif',10,'    mov rdi, rax',10,'    mov esi, 12',10,'    mov edx, '
fsv_publish_len equ $-fsv_publish
fsv_publish_tail: db 10,'    lea rcx, [rel nebo_struct_render_metadata]',10,'    call nebo_runtime_console_publish_structured',10
fsv_publish_tail_len equ $-fsv_publish_tail
