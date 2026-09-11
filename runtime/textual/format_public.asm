bits 64
default rel
%include "runtime/textual/percent_format.inc"
%include "runtime/textual/format_public.inc"
global nebo_runtime_textual_format_prepare
global nebo_runtime_textual_format_render
global nebo_runtime_textual_format_trap
global nebo_runtime_textual_format_result
global nebo_runtime_textual_format_prepare_plan
global nebo_runtime_textual_format_render_plan
extern nebo_runtime_trap

section .text
; RDI private frame containing an evaluated public Text and typed arguments.
; RAX exact output size, or negative native diagnostic. No output is written.
nebo_runtime_textual_format_prepare:
 xor esi,esi
 jmp text_format_prepare_common
nebo_runtime_textual_format_prepare_plan:
 mov esi,1
text_format_prepare_common:
 push rbx
 sub rsp,16
 mov [rsp],rsi
 mov rbx,rdi
 lea rdi,[rbx+TEXT_FORMAT_REQUEST]
 mov ecx,PERCENT_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,[rbx+TEXT_FORMAT_TEMPLATE]
 test rax,rax
 jz .invalid
 cmp word [rax+20],1
 jne .invalid
 mov rdx,[rax]
 mov [rbx+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_TEMPLATE],rdx
 mov rdx,[rax+8]
 mov [rbx+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_TEMPLATE_LEN],rdx
 lea rax,[rbx+TEXT_FORMAT_NODES]
 mov [rbx+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_NODES],rax
 mov qword [rbx+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_NODE_CAP],PERCENT_MAX_NODES
 lea rax,[rbx+TEXT_FORMAT_ARGS]
 mov [rbx+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_ARGS],rax
 mov rax,[rbx+TEXT_FORMAT_ARG_COUNT]
 mov [rbx+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_ARG_COUNT],rax
 mov rax,[rbx+TEXT_FORMAT_POLICY]
 mov [rbx+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_POLICY],rax
 mov qword [rbx+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_CAPACITY],PERCENT_MAX_OUTPUT
 lea rdi,[rbx+TEXT_FORMAT_REQUEST]
 cmp qword [rsp],2
 je .compile_template_only
 cmp qword [rsp],0
 jne .validate_plan
 call neboc_percent_validate_request
 jmp .validated
 .compile_template_only:
 call neboc_percent_compile_request
 jmp .validated
.validate_plan:
 mov rax,[rbx+TEXT_FORMAT_NODE_COUNT]
 mov [rbx+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_NODE_COUNT],rax
 call neboc_percent_validate_plan_request
.validated:
 test eax,eax
 jnz .error
 test qword [rbx+TEXT_FORMAT_POLICY],PERCENT_POLICY_VALIDATE_ONLY
 jnz .measured
 mov rax,[rbx+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_WRITTEN]
.measured:
 add rsp,16
 pop rbx
 ret
.invalid:
 mov eax,PERCENT_DIAG_TYPE_MISMATCH
.error:
 neg rax
 add rsp,16
 pop rbx
 ret

; RDI frame, RSI exact-sized output. Existing renderer preflights all aliases
; and types before writing; only success publishes a public Text descriptor.
nebo_runtime_textual_format_render:
 xor edx,edx
 jmp text_format_render_common
nebo_runtime_textual_format_render_plan:
 mov edx,1
text_format_render_common:
 push rbx
 sub rsp,16
 mov [rsp],rdx
 mov rbx,rdi
 mov [rbx+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_OUTPUT],rsi
 mov rax,[rbx+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_WRITTEN]
 mov [rbx+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_CAPACITY],rax
 lea rdi,[rbx+TEXT_FORMAT_REQUEST]
 cmp qword [rsp],0
 jne .render_plan
 call neboc_percent_render_request
 jmp .rendered
.render_plan:
 call neboc_percent_render_plan_request
.rendered:
 test eax,eax
 jnz .error
 lea rax,[rbx+TEXT_FORMAT_RESULT]
 mov rdx,[rbx+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_OUTPUT]
 mov [rax],rdx
 mov rdx,[rbx+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_WRITTEN]
 test qword [rbx+TEXT_FORMAT_POLICY],PERCENT_POLICY_VALIDATE_ONLY
 jz .length_ready
 xor edx,edx
.length_ready:
 mov [rax+8],rdx
 mov dword [rax+16],5
 mov word [rax+20],1
 mov word [rax+22],0
 add rsp,16
 pop rbx
 ret
.error:
 add rsp,16
 pop rbx
 jmp nebo_runtime_textual_format_trap

; RDI frame, RSI successful public Text or negative native diagnostic.
; Result<Text,FormatError> has distinct typing and preserves the native error
; identity. Failed formatting publishes no partial Text and has no effect.
nebo_runtime_textual_format_result:
 lea rax,[rdi+TEXT_FORMAT_RESULT]
 test rsi,rsi
 js .failed
 ; Move backwards: the strict Text prefix overlaps the Result payload.
 mov rdx,[rsi+16]
 mov [rax+32],rdx
 mov rdx,[rsi+8]
 mov [rax+24],rdx
 mov rdx,[rsi]
 mov [rax+16],rdx
 mov qword [rax],0
 mov qword [rax+8],0
 ret
.failed:
 neg rsi
 mov qword [rax],1
 mov [rax+8],rsi
 mov qword [rax+16],0
 mov qword [rax+24],0
 mov qword [rax+32],0
 ret
nebo_runtime_textual_format_trap:
 mov edi,42
 jmp nebo_runtime_trap
section .note.GNU-stack noalloc noexec nowrite progbits

section .text
global nebo_runtime_textual_format_policy
; operation, input Text/configuration, input-kind, policy argument, output.
; No allocation, rendering or output occurs while immutable policy is built.
nebo_runtime_textual_format_policy:
 push rbx
 push r12
 push r13
 mov r12,r8
 mov r13,rsi
 xor ebx,ebx
 test edx,edx
 jz .text
 mov rbx,[rsi+8]
 mov r13,[rsi]
.text:
 cmp edi,8
 je .strict
 cmp edi,9
 je .loose
 cmp edi,10
 je .coerce
 cmp edi,11
 je .no_coerce
 cmp edi,12
 je .validate
 cmp edi,13
 je .format
 cmp edi,14
 je .mode
 cmp rcx,1
 ja .bad
 cmp edi,15
 je .unknown
 cmp edi,16
 je .missing
 cmp edi,17
 jne .bad
 and ebx,~PERCENT_POLICY_ALLOW_EXTRA
 shl ecx,2
 or rbx,rcx
 jmp .ready
.strict: xor ebx,ebx
 jmp .ready
.loose: mov ebx,PERCENT_POLICY_LOOSE
 jmp .ready
.coerce: or ebx,PERCENT_POLICY_ALLOW_COERCE
 jmp .ready
.no_coerce: and ebx,~PERCENT_POLICY_ALLOW_COERCE
 jmp .ready
.validate: or ebx,PERCENT_POLICY_VALIDATE_ONLY
 jmp .ready
.format: and ebx,~PERCENT_POLICY_VALIDATE_ONLY
 jmp .ready
.mode:
 cmp rcx,2
 ja .bad
 and ebx,~(PERCENT_POLICY_NAMED_ONLY|PERCENT_POLICY_POSITIONAL_ONLY)
 test rcx,rcx
 jz .ready
 mov eax,PERCENT_POLICY_NAMED_ONLY
 cmp ecx,1
 je .mode_apply
 mov eax,PERCENT_POLICY_POSITIONAL_ONLY
.mode_apply: or ebx,eax
 jmp .ready
.unknown:
 and ebx,~PERCENT_POLICY_UNKNOWN_LITERAL
 shl ecx,3
 or rbx,rcx
 jmp .ready
.missing:
 and ebx,~PERCENT_POLICY_ALLOW_MISSING
 shl ecx,1
 or rbx,rcx
.ready:
 mov rdi,rbx
 call neboc_percent_policy_validate
 test eax,eax
 jnz .done
 mov [r12],r13
 mov [r12+8],rbx
 mov rdx,r12
 jmp .done
.bad:
 mov eax,PERCENT_DIAG_TYPE_MISMATCH
.done:
 pop r13
 pop r12
 pop rbx
 ret

section .text
global nebo_runtime_textual_template_parse
global nebo_runtime_textual_template_validate
; Compile the actual template syntax into the existing percent plan. The
; successful Result carries an immutable template, not a fabricated Text.
nebo_runtime_textual_template_parse:
 push rbx
 mov rbx,rdi
 mov esi,2
 call text_format_prepare_common
 lea rdx,[rbx+TEXT_FORMAT_RESULT]
 mov qword [rdx],1
 mov qword [rdx+16],0
 mov qword [rdx+24],0
 test rax,rax
 js .error
 mov qword [rdx],0
 mov qword [rdx+8],0
 mov rcx,[rbx+TEXT_FORMAT_TEMPLATE]
 mov [rdx+16],rcx
 jmp .done
.error:
 neg rax
 mov [rdx+8],rax
.done:
 mov rax,rdx
 pop rbx
 ret
; Typed signature records contain no executable expressions. Validation
; measures with canonical finite placeholders and never publishes output.
nebo_runtime_textual_template_validate:
 push rbx
 mov rbx,rdi
 or qword [rbx+TEXT_FORMAT_POLICY],PERCENT_POLICY_VALIDATE_ONLY
 call nebo_runtime_textual_format_prepare
 test rax,rax
 setns al
 movzx eax,al
 pop rbx
 ret
