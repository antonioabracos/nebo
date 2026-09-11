; Public metadata and observer for the canonical ScanPlan/Console adapter.
extern nebo_runtime_textual_text_hash
extern nebo_runtime_trace_setting
section .bss align=8
sp_request_sequence: resq 1
section .text
; RDI frame, RSI source option -> EAX status.
sp_public_option:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov rax,[r12]
 cmp rax,68
 jb .not_choice
 cmp rax,75
 ja .not_choice
 mov rdi,rbx
 mov rsi,r12
 call sp_choice_option
 jmp .done
.not_choice:
 cmp rax,76
 je .retry_message
 cmp rax,77
 je .feedback_text
 cmp rax,48
 jb .ordinary_option
 cmp rax,56
 ja .ordinary_option
 mov rdi,rbx
 mov rsi,r12
 call sp_multiline_option
 jmp .done
.ordinary_option:
 cmp rax,41
 je .console
 cmp rax,42
 je .form
 cmp rax,43
 je .field
 cmp rax,44
 je .view
 cmp rax,45
 je .panel
 cmp rax,46
 je .feedback
 cmp rax,47
 je .style
 cmp rax,57
 je .secret
 cmp rax,67
 je .password
 cmp rax,58
 je .mask
 cmp rax,59
 je .redact
 cmp rax,60
 je .no_history
 cmp rax,61
 je .no_echo
 cmp rax,62
 je .confirm
 cmp rax,63
 je .sensitive
 cmp rax,65
 je .forget
 cmp rax,64
 je .strength
 cmp rax,66
 je .untrusted
 jmp .bad
.retry_message:
 mov rax,[r12+8]
 cmp word [rax+20],1
 jne .bad
 cmp qword [rax+8],4096
 ja .bad
 mov [rbx+SP_RETRY_MESSAGE],rax
 mov qword [rbx+SP_RETRY],1
 jmp .ok
.feedback_text:
 mov rdi,[r12+8]
 call sp_metadata_identity
 test rax,rax
 jz .bad
 mov eax,eax
 mov [rbx+SP_FEEDBACK],rax
 jmp .ok
.console:
 mov qword [rbx+SP_CONSOLE],1
 jmp .ok
.form:
 mov r13d,SP_FORM
 jmp .text_metadata
.view:
 mov r13d,SP_VIEW
 jmp .text_metadata
.panel:
 mov r13d,SP_PANEL
 jmp .text_metadata
.style:
 mov r13d,SP_STYLE
.text_metadata:
 mov rdi,[r12+8]
 call sp_metadata_identity
 test rax,rax
 jz .bad
 mov [rbx+r13],rax
 jmp .ok
.field:
 mov rdi,[r12+8]
 call sp_metadata_identity
 test rax,rax
 jz .bad
 mov r13,rax
 mov rdi,[r12+16]
 call sp_metadata_identity
 test rax,rax
 jz .bad
 rol r13,7
 xor rax,r13
 rol qword [rbx+SP_FIELD_DIGEST],7
 xor [rbx+SP_FIELD_DIGEST],rax
 inc qword [rbx+SP_FIELDS]
 jmp .ok
.feedback:
 mov qword [rbx+SP_FEEDBACK],1
 jmp .ok
.password:
 or qword [rbx+SP_SECURITY],NEBO_G105_SECURITY_PASSWORD
.secret:
 or qword [rbx+SP_SECURITY],NEBO_G105_SECURITY_SECRET|NEBO_G105_SECURITY_REDACT|NEBO_G105_SECURITY_NO_HISTORY|NEBO_G105_SECURITY_NO_ECHO|NEBO_G105_SECURITY_SENSITIVE
 jmp .ok
.mask:
 mov rax,[r12+8]
 cmp qword [rax+8],1
 jne .bad
 mov rax,[rax]
 movzx eax,byte [rax]
 cmp eax,33
 jb .bad
 cmp eax,126
 ja .bad
 mov [rbx+SP_MASK],rax
 or qword [rbx+SP_SECURITY],NEBO_G105_SECURITY_MASK
 jmp .ok
.redact:
 or qword [rbx+SP_SECURITY],NEBO_G105_SECURITY_REDACT
 jmp .ok
.no_history:
 or qword [rbx+SP_SECURITY],NEBO_G105_SECURITY_NO_HISTORY
 jmp .ok
.no_echo:
 or qword [rbx+SP_SECURITY],NEBO_G105_SECURITY_NO_ECHO
 jmp .ok
.confirm:
 or qword [rbx+SP_SECURITY],NEBO_G105_SECURITY_CONFIRM
 jmp .ok
.sensitive:
 or qword [rbx+SP_SECURITY],NEBO_G105_SECURITY_SENSITIVE
 jmp .ok
.forget:
 or qword [rbx+SP_SECURITY],NEBO_G105_SECURITY_FORGET
 jmp .ok
.strength:
 mov rax,[r12+8]
 test rax,rax
 jz .bad
 cmp rax,4
 ja .bad
 mov [rbx+SP_STRENGTH],rax
 jmp .ok
.untrusted:
 or qword [rbx+SP_SECURITY],NEBO_G105_SECURITY_UNTRUSTED
.ok:
 xor eax,eax
 jmp .done
.bad:
 mov eax,SCAN_E_INVALID
.done:
 pop r13
 pop r12
 pop rbx
 ret

; Validated metadata is a stable content identity, never a runtime pointer.
sp_metadata_identity:
 test rdi,rdi
 jz .no
 cmp word [rdi+20],1
 jne .no
 cmp qword [rdi+8],0
 je .no
 cmp qword [rdi+8],4096
 ja .no
 jmp nebo_runtime_textual_text_hash
.no:
 xor eax,eax
 ret

sp_public_plan:
 push rbx
 mov rbx,rdi
 test qword [rbx+SP_SECURITY],NEBO_G105_SECURITY_SECRET|NEBO_G105_SECURITY_PASSWORD
 jz .not_secret
 cmp qword [rbx+SP_KIND],SCAN_KIND_TEXT
 jne .invalid
 cmp qword [rbx+SP_STRENGTH],0
 jne .not_secret
 mov qword [rbx+SP_STRENGTH],1
.not_secret:
 test qword [rbx+SP_SECURITY],NEBO_G105_SECURITY_MASK|NEBO_G105_SECURITY_CONFIRM|NEBO_G105_SECURITY_FORGET
 jz .privacy_ready
 test qword [rbx+SP_SECURITY],NEBO_G105_SECURITY_SECRET|NEBO_G105_SECURITY_PASSWORD
 jz .invalid
.privacy_ready:
 lea rdi,[rbx+SP_ADAPTER_PLAN]
 mov rsi,[rbx+SP_MAX_ATTEMPTS]
 mov edx,NEBO_G105_CAP_ALL
 call nebo_scan_console_plan_init
 test eax,eax
 jnz .done
 lea rdi,[rbx+SP_ADAPTER_PLAN]
 mov rsi,[rbx+SP_SECURITY]
 mov rdx,[rbx+SP_STRENGTH]
 call nebo_scan_console_plan_security
 test eax,eax
 jnz .done
 mov rsi,[rbx+SP_FORM]
 mov rdx,[rbx+SP_FIELDS]
 mov rcx,[rbx+SP_VIEW]
 mov r8,[rbx+SP_PANEL]
 mov r9,[rbx+SP_STYLE]
 shl r9,32
 mov eax,[rbx+SP_FEEDBACK]
 or r9,rax
 lea rdi,[rbx+SP_ADAPTER_PLAN]
 call nebo_scan_console_plan_metadata_sparse
 test eax,eax
 jnz .done
 mov rdi,rbx
 call sp_multiline_plan
 test eax,eax
 jnz .done
 mov rax,[rbx+SP_CHOICES]
 test rax,rax
 jz .boolean_choices
 mov rsi,[rax]
 jmp .choice_plan
.boolean_choices:
 test qword [rbx+SP_CHOICE_FLAGS],NEBO_G105_CHOICE_BOOLEAN|NEBO_G105_CHOICE_CONFIRM
 jz .done
 mov esi,2
.choice_plan:
 lea rdi,[rbx+SP_ADAPTER_PLAN]
 mov rdx,[rbx+SP_CHOICE_FLAGS]
 call nebo_scan_console_plan_choices
 jmp .done
.invalid:
 mov eax,SCAN_E_INVALID
.done:
 pop rbx
 ret

sp_public_request:
 push rbx
 mov rbx,rdi
 mov qword [rbx+SP_SECRET_WIPED],0
 cmp qword [rbx+SP_CONSOLE],0
 je .ok
 mov qword [rbx+SP_RECORDED],0
 inc qword [rel sp_request_sequence]
 jz .bad
 mov rdx,[rel sp_request_sequence]
 mov [rbx+SP_REQUEST_ID],rdx
 mov rcx,[rbx+SP_ATTEMPTS]
 dec rcx
 mov r8d,NEBO_G105_SOURCE_LIVE
 cmp qword [rbx+SP_MOCK],0
 je .not_mock
 mov r8d,NEBO_G105_SOURCE_MOCK
.not_mock:
 cmp qword [rbx+SP_REPLAY],0
 je .source
 mov r8d,NEBO_G105_SOURCE_REPLAY
.source:
 lea rdi,[rbx+SP_ADAPTER_PLAN]
 lea rsi,[rbx+SP_REQUEST]
 call nebo_scan_console_request_build
 test eax,eax
 jnz .done
 lea rsi,[rbx+SP_REQUEST]
 mov rdi,[rbx+SP_EVIDENCE+NEBO_G105_EVIDENCE_LAST_REQUEST_ID_OFFSET]
 call nebo_scan_console_replay_validate
 jmp .done
.ok:
 xor eax,eax
 jmp .done
.bad:
 mov eax,SCAN_E_LIMIT
.done:
 pop rbx
 ret

sp_public_complete:
 push rbx
 mov rbx,rdi
 cmp qword [rbx+SP_CONSOLE],0
 je .ok
 cmp qword [rbx+SP_REQUEST_ID],0
 je .ok
 cmp qword [rbx+SP_RECORDED],0
 jne .ok
 mov qword [rbx+SP_RECORDED],1
 lea rdi,[rbx+SP_ADAPTER_PLAN]
 lea rsi,[rbx+SP_REQUEST]
 lea rdx,[rbx+1120]
 mov rcx,[rbx+SP_LENGTH]
 cmp rcx,4096
 jbe .length
 xor ecx,ecx
.length:
 lea r8,[rbx+SP_RESPONSE]
 lea r9,[rbx+SP_EVENT]
 mov r10,[rbx+SP_ERROR]
 mov r11,[rbx+SP_SELECTION_COUNT]
 call nebo_scan_console_response_commit
 test eax,eax
 jz .observe
 cmp eax,-NEBO_G105_STATUS_VALIDATION
 jne .done
.observe:
 lea rdi,[rbx+SP_EVIDENCE]
 lea rsi,[rbx+SP_REQUEST]
 lea rdx,[rbx+SP_RESPONSE]
 lea rcx,[rbx+SP_EVENT]
 call nebo_scan_console_evidence_observe
 test eax,eax
 jnz .done
 mov rdi,rbx
 call sp_secret_wipe
 test eax,eax
 jnz .done
 mov rdi,rbx
 call sp_public_trace
 jmp .done
.ok:
 mov rdi,rbx
 call sp_secret_wipe
.done:
 pop rbx
 ret

; Emit only native metadata and public event fields. No input pointer or bytes,
; private response digest or private response length enters this record.
sp_public_trace:
 push rbx
 push r12
 push r13
 sub rsp,224
 mov rbx,rdi
 lea rsi,[rel sp_trace_setting]
 mov edx,sp_trace_setting_len
 call nebo_runtime_trace_setting
 test eax,eax
 jz .ok
 mov rax,0x314e43534f42454e
 mov [rsp],rax
 lea r12,[rel sp_trace_offsets]
 xor r13d,r13d
.field:
 mov rax,[r12+r13*8]
 mov rax,[rbx+rax]
 mov [rsp+r13*8+8],rax
 inc r13
 cmp r13,26
 jb .field
 mov r12,rsp
 mov r13d,216
 mov ebx,64
.write:
 dec ebx
 jz .bad
 mov eax,1
 mov edi,1
 mov rsi,r12
 mov rdx,r13
 syscall
 cmp rax,-4
 je .write
 test rax,rax
 jle .bad
 add r12,rax
 sub r13,rax
 jnz .write
.ok:
 xor eax,eax
 jmp .done
.bad:
 mov eax,SCAN_E_IO
.done:
 add rsp,224
 pop r13
 pop r12
 pop rbx
 ret
section .rodata
sp_trace_setting: db 'NEBO_SCAN_TRACE=1',0
sp_trace_setting_len equ $-sp_trace_setting
align 8
sp_trace_offsets:
 dq SP_REQUEST,SP_REQUEST+8,SP_REQUEST+16,SP_ADAPTER_PLAN+128
 dq SP_ADAPTER_PLAN+8,SP_ADAPTER_PLAN+16,SP_ADAPTER_PLAN+24,SP_ADAPTER_PLAN+32
 dq SP_ADAPTER_PLAN+40,SP_ADAPTER_PLAN+48,SP_ADAPTER_PLAN+96,SP_ADAPTER_PLAN+56
 dq SP_ADAPTER_PLAN+80,SP_EVENT+8,SP_EVENT+16,SP_EVENT+24,SP_EVENT+32,SP_EVENT+40
 dq SP_RESPONSE+40,SP_EVIDENCE+16,SP_ERROR,SP_FIELD_DIGEST,SP_MASK,SP_LANGUAGE,SP_ZERO_REMAINS,SP_RESPONSE+32
section .text
