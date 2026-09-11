; G142 integrated source owner for contextual Text interpolation, typed percent
; placeholders and bounded Slash directives.  All three source slices are
; validated into one caller-owned FormatPlan before an observer is published.

%define G142_FAMILY_KEY 0x5246323047313432
%define G142_MAX_PLAN_EXPRESSIONS 64
%define G142_ARG_TEXT 1
%define G142_ARG_INT 2
%define G142_ARG_FLOAT 3
%define G142_ARG_BOOL 4
%include "compiler/tokens/operator_registry.inc"
%define NEBO_TEMPLATE_NOTATION_PLAN_IMPLEMENTATION 1
%include "compiler/parser/text/template_notation_plan.inc"
%undef NEBO_TEMPLATE_NOTATION_PLAN_IMPLEMENTATION
%include "compiler/parser/text/interpolation_plan.inc"
%define NEBO_SLASH_DSL_IMPLEMENTATION 1
%include "runtime/textual/slash_dsl.inc"
%undef NEBO_SLASH_DSL_IMPLEMENTATION

extern nebo_template_notation_registry_lookup
extern nebo_template_context_plan
extern nebo_placeholder_plan
extern neboc_slash_parse
extern nebo_format_plan_evaluate_once
extern nebo_template_metadata

section .rodata
%macro G142_NAME 2
g142_n_%1: db %2
g142_n_%1_len equ $-g142_n_%1
%endmacro
G142_NAME FormatPlan,'formatPlan'
G142_NAME interpolation,'interpolation'
G142_NAME Text,'Text'
G142_NAME format,'format'
G142_NAME RenderPlan,'RenderPlan'
G142_NAME policy,'policy'
G142_NAME Int,'Int'
G142_NAME Float,'Float'
G142_NAME Bool,'Bool'
G142_NAME segmentCount,'segmentCount'
G142_NAME expressionCount,'expressionCount'
G142_NAME placeholderCount,'placeholderCount'
G142_NAME literalPercentCount,'literalPercentCount'
G142_NAME directiveCount,'directiveCount'
G142_NAME maxDepth,'maxDepth'
G142_NAME evaluationCount,'evaluationCount'
G142_NAME registrySum,'registrySum'
G142_NAME checksum,'checksum'
G142_NAME policyDigest,'policyDigest'
%undef G142_NAME

g142_text_sample: db 'sample'
g142_text_sample_len equ $-g142_text_sample

section .bss align=16
g142_scratch_start:
g142_interpolation_ptr: resq 1
g142_interpolation_len: resq 1
g142_percent_ptr: resq 1
g142_percent_len: resq 1
g142_slash_ptr: resq 1
g142_slash_len: resq 1
g142_arg_count: resq 1
g142_placeholder_count: resq 1
g142_literal_percent_count: resq 1
g142_evaluation_count: resq 1
g142_checksum: resq 1
g142_policy_values: resq 3
g142_policy_record: resq 5
g142_interpolation_summary: resq 7
g142_percent_args: resq 64
g142_placeholder_record: resq 3
g142_slash_summary: resq 5
g142_slash_error: resq 3
g142_format_nodes: resq 64*2
g142_format_result: resq 2
g142_scratch_end:

section .text

g142_is_program:
 lea rsi,[rel g142_n_FormatPlan]
 mov edx,g142_n_FormatPlan_len
 call ls_contains_atom
 test eax,eax
 jz .no
 lea rsi,[rel g142_n_interpolation]
 mov edx,g142_n_interpolation_len
 call ls_contains_atom
 test eax,eax
 jz .no
 lea rsi,[rel g142_n_format]
 mov edx,g142_n_format_len
 call ls_contains_atom
 test eax,eax
 jz .no
 lea rsi,[rel g142_n_RenderPlan]
 mov edx,g142_n_RenderPlan_len
 call ls_contains_atom
 test eax,eax
 setnz al
 movzx eax,al
 ret
.no:
 xor eax,eax
 ret

; EDI token kind -> RAX zero or -1.
g142_expect:
 sub rsp,8
 call ls_expect_kind
 test eax,eax
 jz .bad
 xor eax,eax
 jmp .done
.bad:
 mov rax,-1
.done:
 add rsp,8
 ret

g142_expect_comma:
 mov edi,NEBOC_TOKEN_COMMA
 jmp g142_expect

; Success: RDX borrowed bytes, RCX byte length; advances one TEXT token.
g142_parse_text:
 push rbx
 push r12
 sub rsp,8
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_TEXT
 jne .type
 mov rdi,[rel ls_cursor]
 call ls_token_ptr
 test rax,rax
 jz .syntax
 mov rbx,rax
 mov r8,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov r9,[rbx+NEBOC_TOKEN_END_OFFSET]
 cmp r9,r8
 jb .syntax
 sub r9,r8
 cmp r9,2
 jb .syntax
 mov r12,[rel ls_source]
 add r12,r8
 cmp byte [r12],'"'
 jne .type
 cmp byte [r12+r9-1],'"'
 jne .type
 sub r9,2
 cmp r9,4096
 ja .type
 lea rdx,[r12+1]
 mov rcx,r9
 inc qword [rel ls_cursor]
 xor eax,eax
 jmp .done
.type:
 mov eax,28
 jmp .done
.syntax:
 mov rax,-1
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; Consume one strict public placeholder argument type and append a caller-owned
; runtime record. Success EAX=0; type mismatch EAX=28.
g142_parse_argument_type:
 push rbx
 sub rsp,16
 mov qword [rsp],0
 lea rsi,[rel g142_n_Text]
 mov edx,g142_n_Text_len
 call ls_expect_atom
 test eax,eax
 jnz .text
 lea rsi,[rel g142_n_Int]
 mov edx,g142_n_Int_len
 call ls_expect_atom
 test eax,eax
 jnz .integer
 lea rsi,[rel g142_n_Float]
 mov edx,g142_n_Float_len
 call ls_expect_atom
 test eax,eax
 jnz .float
 lea rsi,[rel g142_n_Bool]
 mov edx,g142_n_Bool_len
 call ls_expect_atom
 test eax,eax
 jnz .boolean
 mov eax,28
 jmp .done
.text:
 mov qword [rsp],G142_ARG_TEXT
 jmp .append
.integer:
 mov qword [rsp],G142_ARG_INT
 jmp .append
.float:
 mov qword [rsp],G142_ARG_FLOAT
 jmp .append
.boolean:
 mov qword [rsp],G142_ARG_BOOL
.append:
 mov rax,[rel g142_arg_count]
 cmp rax,G142_MAX_PLAN_EXPRESSIONS
 jae .limit
 lea r8,[rel g142_percent_args]
 lea r8,[r8+rax*8]
 mov rax,[rsp]
 mov [r8],rax
 inc qword [rel g142_arg_count]
 xor eax,eax
 jmp .done
.limit:
 mov eax,28
.done:
 add rsp,16
 pop rbx
 ret

; Validate one Registry row and its established context.
; RDI global id, ESI context, EDX expected local suffix -> EAX zero/28.
g142_registry_require:
 push rbx
 mov ebx,edx
 sub rsp,8
 call nebo_template_notation_registry_lookup
 test eax,eax
 jz .bad
 cmp r8d,ebx
 jne .bad
 xor eax,eax
 jmp .done
.bad:
 mov eax,28
.done:
 add rsp,8
 pop rbx
 ret

g142_validate_interpolation:
 sub rsp,8
 mov rdi,NEBOC_OPERATOR_ID_NSR_DOM_077
 mov esi,TEMPLATE_NOTATION_CONTEXT_INTERPOLATED_TEXT
 mov edx,77
 call g142_registry_require
 test eax,eax
 jnz .done
 mov edi,1
 mov esi,1
 mov edx,INTERPOLATION_MAX_DEPTH
 mov ecx,INTERPOLATION_MAX_SEGMENTS
 call nebo_template_context_plan
 test edx,edx
 jnz .domain
 mov rdi,[rel g142_interpolation_ptr]
 mov rsi,[rel g142_interpolation_len]
 lea rdx,[rel g142_interpolation_summary]
 call neboc_interpolation_parse_literal
 test eax,eax
 jnz .domain
 xor eax,eax
 jmp .done
.domain:
 mov eax,28
.done:
 add rsp,8
 ret

g142_validate_percent:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov rdi,NEBOC_OPERATOR_ID_NSR_DOM_078
 mov esi,TEMPLATE_NOTATION_CONTEXT_FORMAT_TEXT
 mov edx,78
 call g142_registry_require
 test eax,eax
 jnz .done
 mov edi,2
 mov esi,1
 mov edx,1
 mov ecx,128
 call nebo_template_context_plan
 test edx,edx
 jnz .domain
 xor ebx,ebx
 xor r12d,r12d
 xor r13d,r13d
 mov r14,[rel g142_percent_ptr]
 mov r15,[rel g142_percent_len]
.percent_scan:
 cmp rbx,r15
 jae .percent_done
 cmp byte [r14+rbx],'%'
 jne .percent_next
 lea rax,[rbx+1]
 cmp rax,r15
 jae .domain
 movzx edi,byte [r14+rax]
 cmp dil,'%'
 jne .typed_percent
 inc r13
 inc rbx
 jmp .percent_next
.typed_percent:
 cmp r12,[rel g142_arg_count]
 jae .domain
 lea rax,[rel g142_percent_args]
 mov rsi,[rax+r12*8]
 xor edx,edx
 lea rcx,[rel g142_placeholder_record]
 call nebo_placeholder_plan
 test eax,eax
 jnz .domain
 cmp qword [rel g142_placeholder_record],78
 jne .domain
 inc r12
 inc rbx
.percent_next:
 inc rbx
 jmp .percent_scan
.percent_done:
 cmp r12,[rel g142_arg_count]
 jne .domain
 mov [rel g142_placeholder_count],r12
 mov [rel g142_literal_percent_count],r13
 xor eax,eax
 jmp .done
.domain:
 mov eax,28
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

g142_validate_slash:
 sub rsp,8
 mov rdi,NEBOC_OPERATOR_ID_NSR_DOM_079
 mov esi,TEMPLATE_NOTATION_CONTEXT_SLASH_TEXT
 mov edx,79
 call g142_registry_require
 test eax,eax
 jnz .done
 mov edi,3
 mov esi,1
 mov edx,SLASH_MAX_DEPTH
 mov ecx,SLASH_MAX_TOKENS
 call nebo_template_context_plan
 test edx,edx
 jnz .domain
 mov rdi,[rel g142_slash_ptr]
 mov rsi,[rel g142_slash_len]
 lea rdx,[rel g142_slash_summary]
 lea rcx,[rel g142_slash_error]
 call neboc_slash_parse
 test eax,eax
 jnz .domain
 xor eax,eax
 jmp .done
.domain:
 mov eax,28
.done:
 add rsp,8
 ret

; RDI bytes, RSI length. Update the 32-bit FNV-1a checksum.
g142_checksum_bytes:
 mov eax,[rel g142_checksum]
 xor ecx,ecx
.loop:
 cmp rcx,rsi
 jae .done
 movzx edx,byte [rdi+rcx]
 xor eax,edx
 imul eax,eax,16777619
 inc rcx
 jmp .loop
.done:
 mov [rel g142_checksum],rax
 ret

; Construct one unique expression node per interpolation/placeholder value.
g142_validate_exactly_once:
 push rbx
 sub rsp,16
 mov rax,[rel g142_interpolation_summary+INTERPOLATION_SUMMARY_EXPRESSION_COUNT]
 add rax,[rel g142_placeholder_count]
 mov [rel g142_evaluation_count],rax
 test rax,rax
 jz .domain
 cmp rax,G142_MAX_PLAN_EXPRESSIONS
 ja .domain
 mov [rsp],rax
 xor ebx,ebx
.node:
 cmp rbx,[rsp]
 jae .validate
 mov rax,rbx
 shl rax,4
 lea rdx,[rel g142_format_nodes]
 add rdx,rax
 mov qword [rdx],1
 mov [rdx+8],rbx
 inc rbx
 jmp .node
.validate:
 lea rdi,[rel g142_format_nodes]
 mov rsi,[rsp]
 mov rdx,[rsp]
 mov rcx,[rsp]
 lea r8,[rel g142_format_result]
 call nebo_format_plan_evaluate_once
 test eax,eax
 jnz .domain
 xor eax,eax
 jmp .done
.domain:
 mov eax,28
.done:
 add rsp,16
 pop rbx
 ret

g142_parse_policy:
 push rbx
 sub rsp,16
 mov qword [rel g142_policy_values],1
 mov qword [rel g142_policy_values+8],0
 mov qword [rel g142_policy_values+16],0
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_DOT
 jne .validate
 mov rbx,[rel ls_cursor]
 lea rdi,[rbx+1]
 lea rsi,[rel g142_n_policy]
 mov edx,g142_n_policy_len
 call ls_token_match
 test eax,eax
 jz .validate
 add qword [rel ls_cursor],2
 mov edi,NEBOC_TOKEN_LPAREN
 call g142_expect
 test eax,eax
 jnz .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov [rel g142_policy_values],rdx
 call g142_expect_comma
 test eax,eax
 jnz .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov [rel g142_policy_values+8],rdx
 call g142_expect_comma
 test eax,eax
 jnz .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov [rel g142_policy_values+16],rdx
 mov edi,NEBOC_TOKEN_RPAREN
 call g142_expect
 test eax,eax
 jnz .syntax
.validate:
 mov rdi,[rel g142_policy_values]
 mov rsi,[rel g142_policy_values+8]
 mov rdx,[rel g142_policy_values+16]
 lea rcx,[rel g142_policy_record]
 call nebo_template_metadata
 test eax,eax
 jnz .domain
 xor eax,eax
 jmp .done
.domain:
 mov eax,28
 jmp .done
.syntax:
 mov rax,-1
.done:
 add rsp,16
 pop rbx
 ret

g142_parse_plan:
 sub rsp,8
 lea rsi,[rel g142_n_FormatPlan]
 mov edx,g142_n_FormatPlan_len
 call ls_expect_atom
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_LPAREN
 call g142_expect
 test eax,eax
 jnz .done
 lea rsi,[rel g142_n_interpolation]
 mov edx,g142_n_interpolation_len
 call ls_expect_atom
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_LPAREN
 call g142_expect
 test eax,eax
 jnz .done
 call g142_parse_text
 test eax,eax
 jnz .done
 mov [rel g142_interpolation_ptr],rdx
 mov [rel g142_interpolation_len],rcx
 mov edi,NEBOC_TOKEN_RPAREN
 call g142_expect
 test eax,eax
 jnz .done
 call g142_validate_interpolation
 test eax,eax
 jnz .done
 call g142_expect_comma
 test eax,eax
 jnz .done
 lea rsi,[rel g142_n_Text]
 mov edx,g142_n_Text_len
 call ls_expect_atom
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_DOT
 call g142_expect
 test eax,eax
 jnz .done
 lea rsi,[rel g142_n_format]
 mov edx,g142_n_format_len
 call ls_expect_atom
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_LPAREN
 call g142_expect
 test eax,eax
 jnz .done
 call g142_parse_text
 test eax,eax
 jnz .done
 mov [rel g142_percent_ptr],rdx
 mov [rel g142_percent_len],rcx
.arg_loop:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .percent_close
 inc qword [rel ls_cursor]
 call g142_parse_argument_type
 test eax,eax
 jnz .done
 jmp .arg_loop
.percent_close:
 mov edi,NEBOC_TOKEN_RPAREN
 call g142_expect
 test eax,eax
 jnz .done
 call g142_validate_percent
 test eax,eax
 jnz .done
 call g142_expect_comma
 test eax,eax
 jnz .done
 lea rsi,[rel g142_n_RenderPlan]
 mov edx,g142_n_RenderPlan_len
 call ls_expect_atom
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_LPAREN
 call g142_expect
 test eax,eax
 jnz .done
 call g142_parse_text
 test eax,eax
 jnz .done
 mov [rel g142_slash_ptr],rdx
 mov [rel g142_slash_len],rcx
 mov edi,NEBOC_TOKEN_RPAREN
 call g142_expect
 test eax,eax
 jnz .done
 call g142_validate_slash
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call g142_expect
 test eax,eax
 jnz .done
 call g142_parse_policy
 test eax,eax
 jnz .done
 call g142_validate_exactly_once
 test eax,eax
 jnz .done
 mov eax,2166136261
 mov [rel g142_checksum],rax
 mov rdi,[rel g142_interpolation_ptr]
 mov rsi,[rel g142_interpolation_len]
 call g142_checksum_bytes
 mov rdi,[rel g142_percent_ptr]
 mov rsi,[rel g142_percent_len]
 call g142_checksum_bytes
 mov rdi,[rel g142_slash_ptr]
 mov rsi,[rel g142_slash_len]
 call g142_checksum_bytes
 mov eax,[rel g142_checksum]
 xor edx,edx
 mov ecx,251
 div ecx
 inc edx
 mov [rel g142_checksum],rdx
 xor eax,eax
 jmp .done
.syntax:
 mov rax,-1
.done:
 add rsp,8
 ret

g142_parse_observer:
 sub rsp,8
 mov edi,NEBOC_TOKEN_DOT
 call g142_expect
 test eax,eax
 jnz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
%macro G142_OBSERVER 2
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g142_n_%1]
 mov edx,g142_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .%2
%endmacro
 G142_OBSERVER segmentCount,segments
 G142_OBSERVER expressionCount,expressions
 G142_OBSERVER placeholderCount,placeholders
 G142_OBSERVER literalPercentCount,literal_percents
 G142_OBSERVER directiveCount,directives
 G142_OBSERVER maxDepth,max_depth
 G142_OBSERVER evaluationCount,evaluations
 G142_OBSERVER registrySum,registry_sum
 G142_OBSERVER checksum,checksum_value
 G142_OBSERVER policyDigest,policy_digest
 mov eax,28
 jmp .done
.segments:
 mov rdx,[rel g142_interpolation_summary+INTERPOLATION_SUMMARY_SEGMENT_COUNT]
 jmp .consume
.expressions:
 mov rdx,[rel g142_interpolation_summary+INTERPOLATION_SUMMARY_EXPRESSION_COUNT]
 jmp .consume
.placeholders:
 mov rdx,[rel g142_placeholder_count]
 jmp .consume
.literal_percents:
 mov rdx,[rel g142_literal_percent_count]
 jmp .consume
.directives:
 mov rdx,[rel g142_slash_summary+SLASH_PARSE_DIRECTIVES]
 jmp .consume
.max_depth:
 mov rdx,[rel g142_interpolation_summary+INTERPOLATION_SUMMARY_MAX_DEPTH]
 mov rax,[rel g142_slash_summary+SLASH_PARSE_MAX_DEPTH]
 cmp rdx,rax
 cmovb rdx,rax
 jmp .consume
.evaluations:
 mov rdx,[rel g142_evaluation_count]
 jmp .consume
.registry_sum:
 mov edx,77+78+79
 jmp .consume
.checksum_value:
 mov rdx,[rel g142_checksum]
 jmp .consume
.policy_digest:
 mov rdx,[rel g142_policy_values+8]
 shl rdx,2
 mov rax,[rel g142_policy_values+16]
 shl rax,4
 or rdx,rax
 or rdx,[rel g142_policy_values]
.consume:
 push rdx
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call g142_expect
 test eax,eax
 jnz .consume_bad
 mov edi,NEBOC_TOKEN_RPAREN
 call g142_expect
.consume_bad:
 pop rdx
 jmp .done
.syntax:
 mov rax,-1
.done:
 add rsp,8
 ret
%undef G142_OBSERVER

g142_parse_program:
 push rbx
 sub rsp,16
 lea rdi,[rel g142_scratch_start]
 mov ecx,(g142_scratch_end-g142_scratch_start)/8
 xor eax,eax
 rep stosq
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g142_parse_plan
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 call g142_parse_observer
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 mov [rsp],rdx
 call ls_finish_program
 test eax,eax
 jz .syntax
 mov rdi,[rsp]
 mov esi,NEBOC_VECTOR_VERTICAL_FLAGS_REQUIRED
 mov rdx,G142_FAMILY_KEY
 call ls_success
 jmp .done
.semantic:
 mov r8,rax
 call .record_error_token
 mov edi,r8d
 call ls_error
 jmp .done
.syntax:
 call .record_error_token
 mov edi,24
 call ls_error
 jmp .done
.record_error_token:
 mov rcx,[rel ls_cursor]
 cmp rcx,[rel ls_token_count]
 jb .record
 mov rcx,[rel ls_token_count]
 test rcx,rcx
 jz .record
 dec rcx
.record:
 mov rax,[rel ls_request]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_ERROR_TOKEN_OFFSET],rcx
 ret
.done:
 add rsp,16
 pop rbx
 ret
