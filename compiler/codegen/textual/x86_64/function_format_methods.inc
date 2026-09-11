; Public Text.format uses the existing percent parser, typed argument records
; and two-pass renderer. It never reaches a seed/report program adapter.
%include "runtime/textual/percent_format.inc"
%include "runtime/textual/format_public.inc"
section .rodata
ffm_name: db 'format'
ffm_name_len equ $-ffm_name
ffm_with_name: db 'formatWith'
ffm_with_name_len equ $-ffm_with_name
ffm_unwrap_name: db 'unwrapOr'
ffm_unwrap_name_len equ $-ffm_unwrap_name
ffm_ok_name: db 'isOk'
ffm_ok_name_len equ $-ffm_ok_name
ffm_err_name: db 'isErr'
ffm_err_name_len equ $-ffm_err_name
ffm_store_template: db '    mov [r12], rax',10
ffm_store_template_len equ $-ffm_store_template
ffm_count_head: db '    mov qword [r12 + 8], '
ffm_count_head_len equ $-ffm_count_head
ffm_strict_policy: db '    mov qword [r12 + 16], 0',10
ffm_strict_policy_len equ $-ffm_strict_policy
ffm_store_policy: db '    mov [r12 + 16], rax',10
ffm_store_policy_len equ $-ffm_store_policy
ffm_scalar_value: db '    mov rdx, rax',10,'    xor ecx, ecx',10
ffm_scalar_value_len equ $-ffm_scalar_value
ffm_text_value: db '    mov rdx, [rax]',10,'    mov rcx, [rax + 8]',10
ffm_text_value_len equ $-ffm_text_value
ffm_slot_head: db '    lea r11, [r12 + '
ffm_slot_head_len equ $-ffm_slot_head
ffm_slot_tail: db ']',10,'    mov [r11 + 8], rdx',10,'    mov [r11 + 16], rcx',10,'    mov qword [r11 + 24], 0',10,'    mov qword [r11], '
ffm_slot_tail_len equ $-ffm_slot_tail
ffm_name_head: db '    mov r10, '
ffm_name_head_len equ $-ffm_name_head
ffm_name_tail: db 10,'    mov [r11 + 24], r10',10
ffm_name_tail_len equ $-ffm_name_tail
ffm_plan_count: db '    mov qword [r12 + 168], '
ffm_plan_count_len equ $-ffm_plan_count
ffm_plan_slot: db ']',10
ffm_plan_slot_len equ $-ffm_plan_slot
ffm_plan_immediate: db '    mov rax, '
ffm_plan_immediate_len equ $-ffm_plan_immediate
ffm_plan_literal: db '    mov rax, [r12]',10,'    mov rax, [rax]',10,'    add rax, '
ffm_plan_literal_len equ $-ffm_plan_literal
ffm_plan_literal_symbol: db '    lea rax, [rel nebo_text_data_'
ffm_plan_literal_symbol_len equ $-ffm_plan_literal_symbol
ffm_plan_literal_symbol_end: db ']'
ffm_plan_literal_symbol_end_len equ $-ffm_plan_literal_symbol_end
ffm_plan_store: db 10,'    mov [r11 + '
ffm_plan_store_len equ $-ffm_plan_store
ffm_plan_store_end: db '], rax',10
ffm_plan_store_end_len equ $-ffm_plan_store_end
ffm_render:
 db '    mov rdi, r12',10
 db '    call nebo_runtime_textual_format_prepare_plan',10
 db '    test rax, rax',10
 db '    js nebo_runtime_textual_format_trap',10
 db '    add rax, 15',10
 db '    and rax, -16',10
 db '    mov r11, rsp',10
 db '    sub r11, rax',10
 db '    jc nebo_runtime_trap_stack_budget',10
 db '    cmp r11, [rel nebo_runtime_owned_stack_floor]',10
 db '    jb nebo_runtime_trap_stack_budget',10
 db '    mov rsp, r11',10
 db '    mov rsi, rsp',10
 db '    mov rdi, r12',10
 db '    call nebo_runtime_textual_format_render_plan',10
 db '    mov r12, [r12 + 24]',10
ffm_render_len equ $-ffm_render
ffm_render_with:
 db '%push format_checked',10
 db '    mov rdi, r12',10
 db '    call nebo_runtime_textual_format_prepare',10
 db '    mov rsi, rax',10
 db '    test rax, rax',10
 db '    js %$result',10
 db '    add rax, 15',10
 db '    and rax, -16',10
 db '    mov r11, rsp',10
 db '    sub r11, rax',10
 db '    jc %$allocation_failed',10
 db '    cmp r11, [rel nebo_runtime_owned_stack_floor]',10
 db '    jb %$allocation_failed',10
 db '    mov rsp, r11',10
 db '    mov rsi, rsp',10
 db '    mov rdi, r12',10
 db '    call nebo_runtime_textual_format_render',10
 db '    mov rsi, rax',10
 db '    jmp %$result',10
 db '%$allocation_failed:',10
 ; Capacity reservation failure is distinct from the percent output limit (8).
 db '    mov rsi, -9',10
 db '%$result:',10
 db '    mov rdi, r12',10
 db '    call nebo_runtime_textual_format_result',10
 db '    mov r12, [r12 + 24]',10
 db '%pop',10
ffm_render_with_len equ $-ffm_render_with
ffm_unwrap:
 db '    mov rsi, rax',10
 db '    mov rdi, [r12]',10
 db '    mov edx, 4',10
 db '    call nebo_runtime_textual_checked_unwrap',10
 db '    mov r12, [r12 + 24]',10
ffm_unwrap_len equ $-ffm_unwrap
ffm_result_tag: db '    cmp byte [rax], 1',10,'    ja nebo_runtime_textual_format_trap',10,'    movzx eax, byte [rax]',10
ffm_result_tag_len equ $-ffm_result_tag
ffm_result_ok: db '    xor eax, 1',10
ffm_result_ok_len equ $-ffm_result_ok
section .text

; RDI state, RSI call ID -> EAX method 1..5, RCX typed result. Recognition
; does not execute an argument or infer any output from a fixture spelling.
fcg_format_call_info:
 push rbx
 push r12
 sub rsp,24
 mov rbx,rdi
 mov r12,rsi
 call fcg_format_policy_info
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r12
 call fcg_format_template_info
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTERPOLATED_TEXT
 je .interpolated
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .no
 mov [rsp],rax
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ffm_name]
 mov ecx,ffm_name_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .strict
 mov rax,[rsp]
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ffm_with_name]
 mov ecx,ffm_with_name_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .with
 mov rax,[rsp]
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ffm_unwrap_name]
 mov ecx,ffm_unwrap_name_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .unwrap
 mov rax,[rsp]
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ffm_ok_name]
 mov ecx,ffm_ok_name_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .ok
 mov rax,[rsp]
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ffm_err_name]
 mov ecx,ffm_err_name_len
 call fcg_token_matches_literal
 test eax,eax
 jz .no
 mov qword [rsp+8],5
 jmp .receiver
.ok:
 mov qword [rsp+8],4
 jmp .receiver
.unwrap:
 mov qword [rsp+8],3
 jmp .receiver
.strict:
 mov qword [rsp+8],1
 jmp .receiver
.with:
 mov qword [rsp+8],2
.receiver:
 mov rax,[rsp]
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 mov edx,1
 call fcg_infer_type
 cmp qword [rsp+8],3
 jae .result_receiver
 cmp eax,FCG_TYPE_FORMAT_TEMPLATE
 je .configured_receiver
 cmp eax,NEBOC_TYPE_ID_TEXT
 jne .no
 mov rax,[rsp+8]
 mov ecx,NEBOC_TYPE_ID_TEXT
 cmp eax,2
 jne .done
 mov ecx,NEBOC_FUNCTION_TYPE_FORMAT_RESULT_TEXT
 jmp .done
.configured_receiver:
 cmp qword [rsp+8],1
 jne .no
 mov eax,7
 mov ecx,NEBOC_FUNCTION_TYPE_FORMAT_RESULT_TEXT
 jmp .done
.result_receiver:
 cmp eax,NEBOC_FUNCTION_TYPE_FORMAT_RESULT_TEXT
 jne .no
 mov rax,[rsp+8]
 mov ecx,NEBOC_TYPE_ID_TEXT
 cmp eax,3
 je .done
 mov ecx,NEBOC_TYPE_ID_BOOL
 jmp .done
.no:
 xor eax,eax
 xor ecx,ecx
 jmp .done
.interpolated:
 mov eax,6
 mov ecx,NEBOC_TYPE_ID_TEXT
.done:
 add rsp,24
 pop r12
 pop rbx
 ret

; A canonical type maps to one public typed argument tag, never a vararg ABI.
fcg_format_argument_kind:
 cmp eax,NEBOC_TYPE_ID_TEXT
 je .text
 cmp eax,NEBOC_TYPE_ID_INT
 je .int
 cmp eax,NEBOC_TYPE_ID_FLOAT
 je .float
 cmp eax,NEBOC_TYPE_ID_BOOL
 je .bool
 xor eax,eax
 ret
.text: mov eax,PERCENT_ARG_TEXT
 ret
.int: mov eax,PERCENT_ARG_INT
 ret
.float: mov eax,PERCENT_ARG_FLOAT
 ret
.bool: mov eax,PERCENT_ARG_BOOL
 ret

; RDI state, RSI lexical argument -> RAX native kind, RDX value node,
; RCX stable name hash (zero for a positional argument). Names carry no
; runtime effect; the one child expression retains its normal typed owner.
fcg_format_argument_info:
 push rbx
 push r12
 push r13
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 xor r13d,r13d
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTERPOLATION_VALUE
 je .interpolated_value
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_NAMED_ARGUMENT
 jne .value
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .bad
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_token_ptr
 test rax,rax
 jz .bad
 mov rsi,[rax+NEBOC_TOKEN_END_OFFSET]
 cmp rsi,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_LENGTH_OFFSET]
 ja .bad
 mov rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 sub rsi,rdx
 jbe .bad
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_OFFSET]
 add rdi,rdx
 call neboc_percent_name_hash
 mov r13,rax
 jmp .value
.interpolated_value:
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.value:
 mov rdi,rbx
 mov rsi,r12
 mov edx,1
 call fcg_infer_type
 call fcg_format_argument_kind
 mov rdx,r12
 mov rcx,r13
 jmp .done
.bad:
 xor eax,eax
 xor edx,edx
 xor ecx,ecx
.done:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 ret

; Validate the literal template and actual argument types with native owners.
; Temporary zero values only validate signatures; they are never emitted or
; used as the runtime oracle. Dynamic templates require the fallible API.
fcg_format_validate:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,TEXT_FORMAT_FRAME_SIZE+16
 mov rbx,rdi
 mov r12,rsi
 mov r15,rdx
 mov rdi,rsp
 xor eax,eax
 mov ecx,(TEXT_FORMAT_FRAME_SIZE+16)/8
 rep stosq
 mov [rsp+TEXT_FORMAT_FRAME_SIZE+8],r15
 mov rdi,rbx
 mov rsi,r12
 call fcg_format_call_info
 mov [rsp+TEXT_FORMAT_FRAME_SIZE],rax
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .syntax
 mov r13,rax
 mov r14,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 cmp qword [rsp+TEXT_FORMAT_FRAME_SIZE],2
 jne .count_ready
 test r14,r14
 jz .arity
 dec r14
.count_ready:
 cmp r14,PERCENT_MAX_ARGS
 ja .arity
 mov [rsp+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_ARG_COUNT],r14
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .syntax
 cmp qword [rsp+TEXT_FORMAT_FRAME_SIZE],2
 je .dynamic_template
 cmp qword [rsp+TEXT_FORMAT_FRAME_SIZE],7
 je .configured_template
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_TEXT_LITERAL
 jne .syntax
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov eax,ecx
 shr rcx,32
 mov rdx,rax
 add rdx,rcx
 jc .syntax
 cmp rdx,[rbx+NEBOC_FUNCTION_CODEGEN_LITERAL_LENGTH_OFFSET]
 ja .syntax
 mov [rsp+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_TEMPLATE_LEN],rax
 add rcx,[rbx+NEBOC_FUNCTION_CODEGEN_LITERAL_BYTES_OFFSET]
 mov [rsp+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_TEMPLATE],rcx
 jmp .template_ready
.configured_template:
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .template_ready
.dynamic_template:
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 mov rsi,r13
 mov edx,1
 call fcg_infer_type
 cmp eax,NEBOC_TYPE_ID_INT
 jne .type
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 test rax,rax
 jz .syntax
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
.template_ready:
 lea rax,[rsp+TEXT_FORMAT_NODES]
 mov [rsp+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_NODES],rax
 mov qword [rsp+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_NODE_CAP],PERCENT_MAX_NODES
 lea rax,[rsp+TEXT_FORMAT_ARGS]
 mov [rsp+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_ARGS],rax
 mov qword [rsp+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_CAPACITY],PERCENT_MAX_OUTPUT
 xor r15d,r15d
.argument:
 cmp r15,r14
 jae .compile
 test r13,r13
 jz .arity
 mov rdi,rbx
 mov rsi,r13
 call fcg_format_argument_info
 test eax,eax
 jz .type
 mov rdx,r15
 shl rdx,5
 mov [rsp+rdx+TEXT_FORMAT_ARGS+PERCENT_ARG_KIND],rax
 mov [rsp+rdx+TEXT_FORMAT_ARGS+PERCENT_ARG_NAME_HASH],rcx
 ; A finite nonzero Float inhabits every numeric profile during signature
 ; validation, including scientific notation. Actual values are evaluated
 ; and checked separately by the runtime owner.
 cmp eax,PERCENT_ARG_FLOAT
 jne .argument_signature_ready
 mov rax,0x3ff0000000000000
 mov [rsp+rdx+TEXT_FORMAT_ARGS+PERCENT_ARG_DATA],rax
.argument_signature_ready:
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 test rax,rax
 jz .syntax
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc r15
 jmp .argument
.compile:
 test r13,r13
 jnz .arity
 xor eax,eax
 cmp qword [rsp+TEXT_FORMAT_FRAME_SIZE],2
 je .done
 cmp qword [rsp+TEXT_FORMAT_FRAME_SIZE],7
 je .done
 lea rdi,[rsp+TEXT_FORMAT_REQUEST]
 call neboc_percent_compile_request
 test eax,eax
 jnz .error
 lea rdi,[rsp+TEXT_FORMAT_REQUEST]
 call neboc_percent_validate_request
 test eax,eax
 jnz .error
 jmp .done
.syntax: mov eax,PERCENT_DIAG_UNKNOWN_PLACEHOLDER
 jmp .error
.arity: mov eax,PERCENT_DIAG_ARITY_MISMATCH
 jmp .error
.type: mov eax,PERCENT_DIAG_TYPE_MISMATCH
.error:
 mov rdi,rbx
 mov rsi,r12
 call fcg_format_record_error
.done:
 test eax,eax
 jnz .release
 ; The caller retains the authenticated static plan until code emission.
 mov rdi,[rsp+TEXT_FORMAT_FRAME_SIZE+8]
 mov rsi,rsp
 mov ecx,TEXT_FORMAT_FRAME_SIZE/8
 rep movsq
.release:
 add rsp,TEXT_FORMAT_FRAME_SIZE+16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; First typed-format error owns the call span through check/emit/build.
; RDI state, RSI call, EAX stable percent diagnostic -> invalid source.
fcg_format_record_error:
 push rbx
 mov rbx,rdi
 ; A field/type failure predates formatting; retain its canonical source span.
 cmp qword [rbx+FCG_VECTOR_ERROR],0
 jne .done
 cmp qword [rbx+FCG_STRUCT_ERROR],0
 jne .done
 cmp qword [rbx+FCG_FORMAT_ERROR],0
 jne .done
 mov [rbx+FCG_FORMAT_ERROR],rax
 call fcg_node_ptr
 test rax,rax
 jz .done
 mov rdx,[rax+NEBOC_AST_NODE_START_OFFSET]
 mov [rbx+FCG_FORMAT_ERROR_START],rdx
 mov rdx,[rax+NEBOC_AST_NODE_END_OFFSET]
 mov [rbx+FCG_FORMAT_ERROR_END],rdx
.done:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 pop rbx
 ret

%macro FFM_APPEND 1
 mov rdi,rbx
 lea rsi,[rel %1]
 mov edx,%1_len
 call fcg_append
 test eax,eax
 jnz .done
%endmacro
%macro FFM_NUMBER 1
 mov rsi,%1
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
%endmacro

fcg_format_emit:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,TEXT_FORMAT_FRAME_SIZE+32
 mov rbx,rdi
 mov r12,rsi
 call fcg_format_call_info
 mov [rsp+8],rax
 cmp eax,18
 jae .template
 cmp eax,8
 jae .policy
 cmp eax,7
 je .format_validate
 cmp eax,6
 je .interpolation_validate
 cmp eax,4
 jae .tag
 cmp eax,3
 je .unwrap
.format_validate:
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rsp+32]
 call fcg_format_validate
 jmp .validated
.interpolation_validate:
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rsp+32]
 call fcg_interpolation_plan
.validated:
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 cmp qword [rsp+8],6
 jne .not_interpolation_count
 mov r14,[rsp+32+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_ARG_COUNT]
.not_interpolation_count:
 cmp qword [rsp+8],2
 jne .emit_count_ready
 dec r14
.emit_count_ready:
 mov r13,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 FFM_APPEND ftm_frame_head
 FFM_NUMBER TEXT_FORMAT_FRAME_SIZE
 FFM_APPEND ftm_frame_tail
 FFM_APPEND ffm_strict_policy
 FFM_APPEND ffm_count_head
 FFM_NUMBER r14
 FFM_APPEND fcg_newline
 mov rdi,rbx
 mov rsi,r13
 mov edx,1
 call fcg_emit_expr
 test eax,eax
 jnz .done
 cmp qword [rsp+8],7
 jne .store_plain_template
 FFM_APPEND ffm_configured_template
.store_plain_template:
 FFM_APPEND ffm_store_template
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 cmp qword [rsp+8],2
 jne .arguments_ready
 mov rdi,rbx
 mov rsi,r13
 mov edx,1
 call fcg_emit_expr
 test eax,eax
 jnz .done
 FFM_APPEND ffm_store_policy
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
.arguments_ready:
 xor r15d,r15d
.argument:
 cmp r15,r14
 jae .render
 mov rdi,rbx
 mov rsi,r13
 call fcg_format_argument_info
 mov [rsp],rax
 mov [rsp+16],rcx
 mov rdi,rbx
 mov rsi,rdx
 mov edx,1
 call fcg_emit_expr
 test eax,eax
 jnz .done
 cmp qword [rsp],PERCENT_ARG_TEXT
 je .text
 FFM_APPEND ffm_scalar_value
 jmp .store
.text:
 FFM_APPEND ffm_text_value
.store:
 FFM_APPEND ffm_slot_head
 mov rax,r15
 shl rax,5
 add rax,TEXT_FORMAT_ARGS
 FFM_NUMBER rax
 FFM_APPEND ffm_slot_tail
 FFM_NUMBER [rsp]
 FFM_APPEND fcg_newline
 FFM_APPEND ffm_name_head
 FFM_NUMBER [rsp+16]
 FFM_APPEND ffm_name_tail
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc r15
 cmp qword [rsp+8],6
 jne .argument
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 test rax,rax
 jz .arity
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .argument
.render:
 cmp qword [rsp+8],2
 je .render_with
 cmp qword [rsp+8],7
 je .render_with
 mov r14,[rsp+32+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_NODE_COUNT]
 FFM_APPEND ffm_plan_count
 FFM_NUMBER r14
 FFM_APPEND fcg_newline
 lea r13,[rsp+32+TEXT_FORMAT_NODES]
 mov qword [rsp+24],TEXT_FORMAT_NODES
.plan_node:
 test r14,r14
 jz .plan_ready
 FFM_APPEND ffm_slot_head
 FFM_NUMBER [rsp+24]
 FFM_APPEND ffm_plan_slot
 xor r15d,r15d
.plan_field:
 cmp r15,PERCENT_NODE_DATA
 jne .plan_immediate
 cmp qword [r13+PERCENT_NODE_KIND],PERCENT_NODE_LITERAL
 jne .plan_immediate
 cmp qword [rsp+32+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_TEMPLATE],0
 je .plan_literal_symbol
 FFM_APPEND ffm_plan_literal
 mov rax,[r13+PERCENT_NODE_DATA]
 sub rax,[rsp+32+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_TEMPLATE]
 FFM_NUMBER rax
 jmp .plan_store
.plan_literal_symbol:
 FFM_APPEND ffm_plan_literal_symbol
 FFM_NUMBER [r13+PERCENT_NODE_KEY]
 FFM_APPEND ffm_plan_literal_symbol_end
 jmp .plan_store
.plan_immediate:
 FFM_APPEND ffm_plan_immediate
 FFM_NUMBER [r13+r15]
.plan_store:
 FFM_APPEND ffm_plan_store
 FFM_NUMBER r15
 FFM_APPEND ffm_plan_store_end
 add r15,8
 cmp r15,PERCENT_NODE_SIZE
 jb .plan_field
 add r13,PERCENT_NODE_SIZE
 add qword [rsp+24],PERCENT_NODE_SIZE
 dec r14
 jmp .plan_node
.plan_ready:
 FFM_APPEND ffm_render
 jmp .success
.render_with:
 FFM_APPEND ffm_render_with
.success:
 xor eax,eax
 jmp .done
.template:
 mov rdi,rbx
 mov rsi,r12
 call fcg_format_template_emit
 jmp .done
.policy:
 mov rdi,rbx
 mov rsi,r12
 call fcg_format_policy_emit
 jmp .done
.unwrap:
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .arity
 mov r13,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 mov rsi,r14
 mov edx,1
 call fcg_infer_type
 cmp eax,NEBOC_TYPE_ID_TEXT
 jne .type
 FFM_APPEND ftm_frame_head
 FFM_NUMBER 160
 FFM_APPEND ftm_frame_tail
 mov rdi,rbx
 mov rsi,r13
 mov edx,1
 call fcg_emit_expr
 test eax,eax
 jnz .done
 FFM_APPEND ffm_store_template
 mov rdi,rbx
 mov rsi,r14
 mov edx,1
 call fcg_emit_expr
 test eax,eax
 jnz .done
 FFM_APPEND ffm_unwrap
 jmp .success
.arity:
 mov eax,PERCENT_DIAG_ARITY_MISMATCH
 jmp .invalid
.type:
 mov eax,PERCENT_DIAG_TYPE_MISMATCH
.invalid:
 mov rdi,rbx
 mov rsi,r12
 call fcg_format_record_error
 jmp .done
.tag:
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .arity
 mov r13,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 FFM_APPEND ftm_frame_head
 FFM_NUMBER 32
 FFM_APPEND ftm_frame_tail
 mov rdi,rbx
 mov rsi,r13
 mov edx,1
 call fcg_emit_expr
 test eax,eax
 jnz .done
 FFM_APPEND ffm_result_tag
 cmp qword [rsp+8],4
 jne .tag_cleanup
 FFM_APPEND ffm_result_ok
.tag_cleanup:
 FFM_APPEND ffm_tag_cleanup
 jmp .success
.done:
 add rsp,TEXT_FORMAT_FRAME_SIZE+32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
%include "compiler/codegen/textual/x86_64/function_interpolation.inc"

section .rodata
ffm_configured_template: db '    mov r11, [rax + 8]',10,'    mov [r12 + 16], r11',10,'    mov rax, [rax]',10
ffm_configured_template_len equ $-ffm_configured_template
%macro FORMAT_POLICY 3
fp_name_%1: db %2
align 8
%endmacro
FORMAT_POLICY strict,'strict',8
FORMAT_POLICY loose,'loose',9
FORMAT_POLICY allowCoerce,'allowCoerce',10
FORMAT_POLICY noCoerce,'noCoerce',11
FORMAT_POLICY validateOnly,'validateOnly',12
FORMAT_POLICY formatOnly,'formatOnly',13
FORMAT_POLICY placeholderMode,'placeholderMode',14
FORMAT_POLICY unknownPlaceholder,'unknownPlaceholder',15
FORMAT_POLICY missingArgs,'missingArgs',16
FORMAT_POLICY extraArgs,'extraArgs',17
%undef FORMAT_POLICY
fp_table:
 dq fp_name_strict,6,8,0
 dq fp_name_loose,5,9,0
 dq fp_name_allowCoerce,11,10,0
 dq fp_name_noCoerce,8,11,0
 dq fp_name_validateOnly,12,12,0
 dq fp_name_formatOnly,10,13,0
 dq fp_name_placeholderMode,15,14,1
 dq fp_name_unknownPlaceholder,18,15,1
 dq fp_name_missingArgs,11,16,1
 dq fp_name_extraArgs,9,17,1
fp_table_end:
fp_receiver: db '    mov [r12], rax',10,'    mov qword [r12 + 8], 0',10
fp_receiver_len equ $-fp_receiver
fp_argument: db '    mov [r12 + 8], rax',10
fp_argument_len equ $-fp_argument
fp_invoke: db '%ifndef NEBO_FORMAT_POLICY_EXTERN',10,'%define NEBO_FORMAT_POLICY_EXTERN 1',10,'extern nebo_runtime_textual_format_policy',10,'%endif',10,'    mov edi, '
fp_invoke_len equ $-fp_invoke
fp_kind: db 10,'    mov edx, '
fp_kind_len equ $-fp_kind
fp_call: db 10,'    mov rsi, [r12]',10,'    mov rcx, [r12 + 8]',10,'    lea r8, [r12 + 32]',10,'    call nebo_runtime_textual_format_policy',10,'    test eax, eax',10,'    jnz nebo_runtime_textual_format_trap',10,'    mov rax, rdx',10,'    mov r12, [r12 + 24]',10
fp_call_len equ $-fp_call
section .text
; Text or an immutable configured template -> new configured template.
; The receiver, every policy operand and all formatting arguments are values.
fcg_format_policy_info:
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
 lea r14,[rel fp_table]
.lookup:
 lea rax,[rel fp_table_end]
 cmp r14,rax
 jae .no
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,[r14]
 mov rcx,[r14+8]
 call fcg_token_matches_literal
 test eax,eax
 jnz .receiver
 add r14,32
 jmp .lookup
.receiver:
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov edx,1
 call fcg_infer_type
 xor r15d,r15d
 cmp rax,NEBOC_TYPE_ID_TEXT
 je .arity
 inc r15
 cmp rax,FCG_TYPE_FORMAT_TEMPLATE
 jne .no
.arity:
 mov rax,[r14+24]
 cmp rax,[r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 jne .bad_arity
 inc rax
 cmp rax,[r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 jne .bad_arity
 cmp qword [r14+24],0
 je .yes
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .bad_type
.yes:
 mov rax,[r14+16]
 mov rdx,r15
 mov ecx,FCG_TYPE_FORMAT_TEMPLATE
 jmp .done
.bad_arity:
 mov eax,PERCENT_DIAG_ARITY_MISMATCH
 jmp .error
.bad_type:
 mov eax,PERCENT_DIAG_TYPE_MISMATCH
.error:
 mov rdi,rbx
 mov rsi,r12
 call fcg_format_record_error
.no:
 xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

fcg_format_policy_emit:
 push rbx
 push r12
 push r13
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 call fcg_format_policy_info
 mov [rsp],rax
 mov [rsp+8],rdx
 FFM_APPEND ftm_frame_head
 FFM_NUMBER 64
 FFM_APPEND ftm_frame_tail
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov r13,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 mov rsi,r13
 mov edx,1
 call fcg_emit_expr
 test eax,eax
 jnz .done
 FFM_APPEND fp_receiver
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r13,r13
 jz .invoke
 mov rdi,rbx
 mov rsi,r13
 mov edx,1
 call fcg_emit_expr
 test eax,eax
 jnz .done
 FFM_APPEND fp_argument
.invoke:
 FFM_APPEND fp_invoke
 FFM_NUMBER [rsp]
 FFM_APPEND fp_kind
 FFM_NUMBER [rsp+8]
 FFM_APPEND fp_call
 xor eax,eax
.done:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 ret

%include "compiler/codegen/textual/x86_64/function_format_templates.inc"
%unmacro FFM_APPEND 1
%unmacro FFM_NUMBER 1

section .rodata
ffm_tag_cleanup: db "    lea rsp, [r12 + 32]",10,"    mov r12, [r12 + 24]",10
ffm_tag_cleanup_len equ $-ffm_tag_cleanup
