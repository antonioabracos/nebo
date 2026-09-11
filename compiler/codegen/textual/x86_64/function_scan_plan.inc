; Public ScanPlan options retain lexical AST operands and share native owners.
section .text
; state, option call id -> static option contract pointer or zero.
fcg_scan_option_spec:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_CONTEXTUAL_OPTION
 jz .no
 mov r13,rax
 lea r12,[rel sp_option_specs]
 mov r14,sp_option_count
.loop:
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,[r12]
 mov rcx,[r12+8]
 call fcg_token_matches_literal
 test eax,eax
 jz .next_spec
 mov rax,[r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 cmp rax,[r12+24]
 je .found
.next_spec:
 add r12,48
 dec r14
 jnz .loop
.no:
 xor eax,eax
 jmp .done
.found:
 mov rax,r12
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state, full scan call -> owned=1, exact result type in RCX.
fcg_scan_public_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov r12,rsi
 mov qword [rsp+48],0
 mov qword [rsp+56],0
 inc qword [rbx+FCG_ASSOC_DEPTH]
 cmp qword [rbx+FCG_ASSOC_DEPTH],64
 ja .no
 lea rdx,[rel fcg_name_scan]
 mov ecx,fcg_name_scan_len
 call fcg_console_call_name_matches
 test eax,eax
 jz .result_method
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jbe .no
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],33
 ja .bad
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 mov rsi,r14
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .bad
 mov qword [rsp],1
 mov qword [rsp+8],0
 mov qword [rsp+16],0
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
.loop:
 test r14,r14
 jz .typed
 mov rdi,rbx
 mov rsi,r14
 call fcg_scan_option_spec
 test rax,rax
 jz .bad
 mov [rsp+24],rax
 mov rdx,[rax+16]
 cmp rdx,43
 je .repeatable_field
 cmp rdx,68
 jb .not_choice_alias
 cmp rdx,73
 ja .not_choice_alias
 cmp rdx,71
 mov edx,16
 jne .not_choice_alias
 mov edx,17
.not_choice_alias:
 cmp rdx,76
 jne .feedback_alias
 mov edx,32
.feedback_alias:
 cmp rdx,77
 jne .option_id_ready
 mov edx,46
.option_id_ready:
 cmp rdx,64
 jae .high_option
 bts qword [rsp+8],rdx
 jmp .duplicate_option
.high_option:
 sub rdx,64
 bts qword [rsp+56],rdx
.duplicate_option:
 jc .bad
.repeatable_field:
 mov rdx,[rax+40]
 test rdx,rdx
 jz .option_kind_ready
 cmp qword [rsp+16],0
 jne .bad
 mov [rsp],rdx
 mov qword [rsp+16],1
.option_kind_ready:
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov r13,rax
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdx,[rsp+24]
 mov rcx,[rdx+24]
 cmp rcx,[rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 jne .bad
 test rcx,rcx
 jz .next
 cmp qword [rdx+32],65535
 je .choice_argument
 mov [rsp+40],rcx
.argument_type:
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_infer_type
 mov rdx,[rsp+24]
 cmp qword [rdx+32],65534
 je .next
 cmp rax,[rdx+32]
 jne .bad
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 dec qword [rsp+40]
 jnz .argument_type
 jmp .next
.choice_argument:
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ARRAY_LITERAL
 jne .bad
 mov rcx,[rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 test rcx,rcx
 jz .bad
 cmp rcx,32
 ja .bad
 mov [rsp+32],rcx
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.choice_element:
 test r15,r15
 jz .bad
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .bad
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 dec qword [rsp+32]
 jnz .choice_element
 test r15,r15
 jnz .bad
.next:
 mov r14,[r13+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .loop
.typed:
 ; A scan has exactly one explicit input provider.
 mov rax,[rsp+8]
 shr rax,30
 and eax,3
 cmp eax,3
 je .bad
 mov rax,[rsp+8]
 and eax,(1<<16)|(1<<17)
 cmp eax,(1<<16)|(1<<17)
 je .bad
 test qword [rsp+8],1<<16
 jz .choice_type_ready
 cmp qword [rsp],1
 jne .bad
.choice_type_ready:
 mov rax,[rsp+8]
 and eax,(1<<24)|(1<<25)|(1<<26)
 lea rdx,[rax-1]
 test rax,rdx
 jnz .bad
 mov rax,[rsp+8]
 and eax,(1<<11)|(1<<12)
 cmp eax,(1<<11)|(1<<12)
 je .bad
 ; Numeric constraints belong only to Int; optional uses the existing native
 ; Option<Int> layout and methods, not a second optional implementation.
 test qword [rsp+8],(1<<20)|(1<<21)|(1<<26)
 jz .result
 cmp qword [rsp],2
 jne .bad
.result:
 ; Fallback operands must match the selected value type, regardless of the
 ; lexical order of type options and policies.
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp+40],0
.fallback_check:
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r15,r15
 jz .policy_type
 mov rdi,rbx
 mov rsi,r15
 call fcg_scan_option_spec
 cmp qword [rax+16],68
 je .console_choice_context
 cmp qword [rax+16],72
 jne .fallback_operand
.console_choice_context:
 mov qword [rsp+40],1
.fallback_operand:
 cmp qword [rax+32],65534
 jne .fallback_check
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 mov edx,1
 call fcg_infer_type
 mov rcx,[rsp]
 lea rdx,[rel sp_value_types]
 cmp rax,[rdx+rcx*8]
 jne .bad
 jmp .fallback_check
.policy_type:
 cmp qword [rsp+40],0
 je .context_ready
 bt qword [rsp+8],41
 jnc .bad
.context_ready:
 mov rax,[rsp+8]
 shr rax,48
 and eax,0x1f9
 lea rdx,[rax-1]
 test rax,rdx
 jnz .bad
 test rax,rax
 jz .mode_type_ready
 cmp qword [rsp],1
 jne .bad
.mode_type_ready:
 mov rax,[rsp+8]
 bt rax,36
 jnc .not_eof_option
 cmp qword [rsp],2
 jne .bad
 bt rax,39
 jc .bad
 bts qword [rsp+8],26
.not_eof_option:
 bt rax,37
 jnc .plain_type
 test eax,1<<26
 jnz .bad
 bt rax,36
 jc .bad
 lea rdx,[rel sp_result_types]
 mov rcx,[rsp]
 mov rcx,[rdx+rcx*8]
 jmp .yes
.plain_type:
 mov ecx,NEBOC_TYPE_ID_TEXT
 cmp qword [rsp],1
 je .yes
 mov ecx,NEBOC_TYPE_ID_INT
 cmp qword [rsp],2
 je .integer
 mov ecx,NEBOC_TYPE_ID_BOOL
 cmp qword [rsp],4
 je .yes
 mov ecx,NEBOC_TYPE_ID_CHAR
 jmp .yes
.integer:
 test qword [rsp+8],1<<26
 jz .yes
 mov ecx,FCG_TYPE_OPTION_INT
.yes:
 mov rdx,[rsp+48]
 mov eax,1
 jmp .done
.result_method:
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 mov r13,rax
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rel cp_color_isOk]
 mov ecx,4
 call fcg_console_call_name_matches
 mov qword [rsp+48],100
 test eax,eax
 jnz .result_receiver
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rel cp_color_isErr]
 mov ecx,5
 call fcg_console_call_name_matches
 mov qword [rsp+48],101
 test eax,eax
 jnz .result_receiver
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rel cp_color_unwrapOr]
 mov ecx,8
 call fcg_console_call_name_matches
 mov qword [rsp+48],102
 test eax,eax
 jz .no
.result_receiver:
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov rdi,rbx
 mov edx,1
 call fcg_probe_receiver_type
 cmp rax,FCG_TYPE_SCAN_RESULT_INT
 jb .no
 cmp rax,FCG_TYPE_SCAN_RESULT_TEXT
 ja .no
 sub rax,FCG_TYPE_SCAN_RESULT_INT
 lea rdx,[rel sp_unwrapped_types]
 mov r14,[rdx+rax*8]
 mov ecx,1
 cmp qword [rsp+48],102
 jne .result_arity
 inc ecx
.result_arity:
 cmp rcx,[r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 jne .bad
 mov ecx,NEBOC_TYPE_ID_BOOL
 cmp qword [rsp+48],102
 jne .yes
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov edx,1
 call fcg_infer_type
 cmp rax,r14
 jne .bad
 mov rcx,r14
 jmp .yes
.bad:
 mov rdi,rbx
 mov rsi,r12
 mov edx,1
 call fcg_vector_error
.no:
 xor eax,eax
 xor ecx,ecx
.done:
 dec qword [rbx+FCG_ASSOC_DEPTH]
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

fcg_scan_public_emit:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 call fcg_scan_public_info
 test eax,eax
 jz .bad
 mov [rsp],rcx
 cmp rdx,100
 jae .emit_result_method
 CP_APPEND sp_extern
 CP_APPEND ftm_frame_head
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov esi,16384
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND ftm_frame_tail
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 CP_APPEND sp_prompt
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 xor r15d,r15d
.option:
 test r14,r14
 jz .invoke
 mov rdi,rbx
 mov rsi,r14
 call fcg_scan_option_spec
 mov [rsp+8],rax
 CP_APPEND sp_store_head
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 imul rsi,r15,32
 add rsi,32
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND sp_store_op
 mov rax,[rsp+8]
 mov rsi,[rax+16]
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND fcg_newline
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp+16],0
.option_argument:
 test rsi,rsi
 jz .next
 mov [rsp+24],rsi
 mov rax,[rsp+8]
 cmp qword [rax+32],65535
 je .choice_emit
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 jmp .save_argument
.choice_emit:
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_scan_emit_choices
 test eax,eax
 jnz .done
.save_argument:
 CP_APPEND cp_color_save
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 imul rsi,r15,32
 add rsi,40
 mov rax,[rsp+16]
 lea rsi,[rsi+rax*8]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND cp_color_save_tail
 mov rdi,rbx
 mov rsi,[rsp+24]
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc qword [rsp+16]
 jmp .option_argument
.next:
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc r15
 jmp .option
.invoke:
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov rax,[rax+NEBOC_AST_NODE_START_OFFSET]
 mov [rsp+16],rax
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov rax,[rax+NEBOC_AST_NODE_END_OFFSET]
 mov [rsp+24],rax
 CP_APPEND sp_span_start
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+16]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND sp_span_end
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+24]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND fcg_newline
 CP_APPEND sp_count
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r15
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND sp_call
 cmp qword [rsp],NEBOC_TYPE_ID_TEXT
 je .done
 cmp qword [rsp],FCG_TYPE_OPTION_INT
 je .done
 cmp qword [rsp],FCG_TYPE_SCAN_RESULT_INT
 jae .done
 CP_APPEND sp_scalar_release
 jmp .done
.emit_result_method:
 mov [rsp+8],rdx
 CP_APPEND ftm_frame_head
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov esi,64
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND ftm_frame_tail
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 CP_APPEND sp_prompt
 cmp qword [rsp+8],100
 je .emit_is_ok
 cmp qword [rsp+8],101
 je .emit_is_err
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 CP_APPEND sp_result_fallback
 CP_APPEND ftm_code_62
 jmp .done
.emit_is_ok:
 CP_APPEND ftm_code_60
 jmp .done
.emit_is_err:
 CP_APPEND ftm_code_61
 jmp .done
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .rodata
sp_extern: db '%ifndef NEBO_SCAN_PUBLIC_DECLARED',10,'%define NEBO_SCAN_PUBLIC_DECLARED 1',10,'extern nebo_runtime_scan_public',10,'%endif',10
sp_extern_len equ $-sp_extern
sp_prompt: db '    mov [r12], rax',10
sp_prompt_len equ $-sp_prompt
sp_store_head: db '    mov qword [r12+'
sp_store_head_len equ $-sp_store_head
sp_store_op: db '], '
sp_store_op_len equ $-sp_store_op
sp_count: db '    mov qword [r12+8], '
sp_count_len equ $-sp_count
sp_call: db 10,'    mov rdi, r12',10,'    call nebo_runtime_scan_public',10,'    mov rsp, r12',10,'    mov r12, [r12+24]',10
sp_call_len equ $-sp_call
sp_scalar_release: db '    add rsp, 16384',10
sp_scalar_release_len equ $-sp_scalar_release
sp_span_start: db '    mov qword [r12+9800], '
sp_span_start_len equ $-sp_span_start
sp_span_end: db 10,'    mov qword [r12+9808], '
sp_span_end_len equ $-sp_span_end
sp_result_fallback: db '    mov [r12+8], rax',10
sp_result_fallback_len equ $-sp_result_fallback
align 8
sp_value_types: dq 0,NEBOC_TYPE_ID_TEXT,NEBOC_TYPE_ID_INT,0,NEBOC_TYPE_ID_BOOL,NEBOC_TYPE_ID_CHAR
sp_result_types: dq 0,FCG_TYPE_SCAN_RESULT_TEXT,FCG_TYPE_SCAN_RESULT_INT,0,FCG_TYPE_SCAN_RESULT_BOOL,FCG_TYPE_SCAN_RESULT_CHAR
sp_unwrapped_types: dq NEBOC_TYPE_ID_INT,NEBOC_TYPE_ID_BOOL,NEBOC_TYPE_ID_CHAR,NEBOC_TYPE_ID_TEXT
sp_name_text: db 'text'
sp_name_int: db 'int'
sp_name_bool: db 'bool'
sp_name_char: db 'char'
sp_name_trim: db 'trim'
sp_name_lower: db 'lower'
sp_name_upper: db 'upper'
sp_name_chomp: db 'chomp'
sp_name_min: db 'min'
sp_name_max: db 'max'
sp_name_minLen: db 'minLen'
sp_name_maxLen: db 'maxLen'
sp_name_required: db 'required'
sp_name_allowEmpty: db 'allowEmpty'
sp_name_optional: db 'optional'
sp_name_mock: db 'mock'
sp_name_choice: db 'choice'
sp_name_indexChoice: db 'indexChoice'
sp_name_replay: db 'replay'
sp_name_retry: db 'retry'
sp_name_maxAttempts: db 'maxAttempts'
sp_name_cancelOn: db 'cancelOn'
sp_name_eofAsNone: db 'eofAsNone'
sp_name_result: db 'result'
sp_name_eofAs: db 'eofAs'
sp_name_onCancel: db 'onCancel'
sp_name_console: db 'console'
sp_name_form: db 'form'
sp_name_field: db 'field'
sp_name_view: db 'view'
sp_name_panel: db 'panel'
sp_name_feedback: db 'feedback'
sp_name_style: db 'style'
sp_name_secret: db 'secret'
sp_name_mask: db 'mask'
sp_name_redact: db 'redact'
sp_name_noHistory: db 'noHistory'
sp_name_noEcho: db 'noEcho'
sp_name_sensitive: db 'sensitive'
sp_name_minStrength: db 'minStrength'
sp_name_untrusted: db 'untrusted'
sp_name_password: db 'password'
sp_name_multiline: db 'multiline'
sp_name_until: db 'until'
sp_name_maxLines: db 'maxLines'
sp_name_paragraph: db 'paragraph'
sp_name_block: db 'block'
sp_name_markdown: db 'markdown'
sp_name_code: db 'code'
sp_name_jsonBlock: db 'jsonBlock'
sp_name_rawBlock: db 'rawBlock'
sp_name_confirmSecret: db 'confirmSecret'
sp_name_forgetAfterUse: db 'forgetAfterUse'
sp_name_oneOf: db 'oneOf'
sp_name_menu: db 'menu'
sp_name_select: db 'select'
sp_name_multiSelect: db 'multiSelect'
sp_name_enum: db 'enum'
sp_name_autocomplete: db 'autocomplete'
sp_name_yesNo: db 'yesNo'
sp_name_confirm: db 'confirm'
align 8
sp_option_specs:
dq sp_name_text,4,1,0,0,1
dq sp_name_int,3,2,0,0,2
dq sp_name_bool,4,4,0,0,4
dq sp_name_char,4,5,0,0,5
dq sp_name_trim,4,10,0,0,0
dq sp_name_lower,5,11,0,0,0
dq sp_name_upper,5,12,0,0,0
dq sp_name_chomp,5,13,0,0,0
dq sp_name_min,3,20,1,NEBOC_TYPE_ID_INT,0
dq sp_name_max,3,21,1,NEBOC_TYPE_ID_INT,0
dq sp_name_minLen,6,22,1,NEBOC_TYPE_ID_INT,0
dq sp_name_maxLen,6,23,1,NEBOC_TYPE_ID_INT,0
dq sp_name_required,8,24,0,0,0
dq sp_name_allowEmpty,10,25,0,0,0
dq sp_name_optional,8,26,0,0,0
dq sp_name_mock,4,30,1,NEBOC_TYPE_ID_TEXT,0
dq sp_name_choice,6,16,1,65535,0
dq sp_name_indexChoice,11,17,1,65535,2
dq sp_name_replay,6,31,1,NEBOC_TYPE_ID_TEXT,0
dq sp_name_retry,5,32,0,0,0
dq sp_name_maxAttempts,11,33,1,NEBOC_TYPE_ID_INT,0
dq sp_name_cancelOn,8,35,1,NEBOC_TYPE_ID_TEXT,0
dq sp_name_eofAsNone,9,36,0,0,0
dq sp_name_result,6,37,0,0,0
dq sp_name_eofAs,5,39,1,65534,0
dq sp_name_onCancel,8,40,1,65534,0
dq sp_name_console,7,41,0,0,0
dq sp_name_form,4,42,1,NEBOC_TYPE_ID_TEXT,0
dq sp_name_field,5,43,2,NEBOC_TYPE_ID_TEXT,0
dq sp_name_view,4,44,1,NEBOC_TYPE_ID_TEXT,0
dq sp_name_panel,5,45,1,NEBOC_TYPE_ID_TEXT,0
dq sp_name_feedback,8,46,0,0,0
dq sp_name_style,5,47,1,NEBOC_TYPE_ID_TEXT,0
dq sp_name_secret,6,57,0,0,0
dq sp_name_mask,4,58,1,NEBOC_TYPE_ID_TEXT,0
dq sp_name_redact,6,59,0,0,0
dq sp_name_noHistory,9,60,0,0,0
dq sp_name_noEcho,6,61,0,0,0
dq sp_name_sensitive,9,63,0,0,0
dq sp_name_minStrength,11,64,1,NEBOC_TYPE_ID_INT,0
dq sp_name_untrusted,9,66,0,0,0
dq sp_name_password,8,67,0,0,0
dq sp_name_retry,5,76,1,NEBOC_TYPE_ID_TEXT,0
dq sp_name_feedback,8,77,1,NEBOC_TYPE_ID_TEXT,0
dq sp_name_multiline,9,48,0,0,0
dq sp_name_until,5,49,1,NEBOC_TYPE_ID_TEXT,0
dq sp_name_maxLines,8,50,1,NEBOC_TYPE_ID_INT,0
dq sp_name_paragraph,9,51,0,0,0
dq sp_name_block,5,52,1,NEBOC_TYPE_ID_TEXT,0
dq sp_name_markdown,8,53,0,0,0
dq sp_name_code,4,54,1,NEBOC_TYPE_ID_TEXT,0
dq sp_name_jsonBlock,9,55,0,0,0
dq sp_name_rawBlock,8,56,0,0,0
dq sp_name_confirmSecret,13,62,0,0,0
dq sp_name_forgetAfterUse,14,65,0,0,0
dq sp_name_oneOf,5,68,1,65535,0
dq sp_name_menu,4,69,1,65535,0
dq sp_name_select,6,70,1,65535,0
dq sp_name_multiSelect,11,71,1,65535,2
dq sp_name_enum,4,72,1,65535,0
dq sp_name_autocomplete,12,73,1,65535,0
dq sp_name_yesNo,5,74,0,0,4
dq sp_name_confirm,7,75,0,0,4
sp_option_count equ ($-sp_option_specs)/48
section .text
fcg_scan_emit_choices:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rax,[rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 mov [rsp],rax
 CP_APPEND ftm_frame_head
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov esi,288
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND ftm_frame_tail
 xor r15d,r15d
.element:
 test r14,r14
 jz .finish
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 CP_APPEND cp_color_save
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 lea rsi,[r15*8+32]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND cp_color_save_tail
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc r15
 jmp .element
.finish:
 CP_APPEND sp_choice_count
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND sp_choice_finish
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .rodata
sp_choice_count: db '    mov qword [r12], '
sp_choice_count_len equ $-sp_choice_count
sp_choice_finish: db 10,'    mov rax, r12',10,'    mov rsp, r12',10,'    mov r12, [r12+24]',10
sp_choice_finish_len equ $-sp_choice_finish
section .text
