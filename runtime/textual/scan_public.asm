; Typed public ScanPlan execution. Caller-owned source operands and result;
; normalization, parsing and constraints reuse the canonical ScanPlan kernels.
bits 64
default rel
%include "runtime/textual/scan_plan.inc"
%include "runtime/textual/scan_privacy_source_probe.inc"
%include "runtime/scan_console.inc"
%include "runtime/core/runtime_core.inc"
extern nebo_runtime_trap
extern nebo_g075_validate_kind
extern nebo_g075_plan_init
extern nebo_runtime_textual_text_is_utf8
extern nebo_runtime_process_stack
extern nebo_runtime_live_available

%define SP_KIND 9328
%define SP_MIN 9336
%define SP_MAX 9344
%define SP_MINLEN 9352
%define SP_MAXLEN 9360
%define SP_FLAGS 9368
%define SP_MOCK 9376
%define SP_REQUIRED 9384
%define SP_OPTIONAL 9392
%define SP_VALUE 9400
%define SP_LENGTH 9408
%define SP_INPUT 9416
%define SP_PRESENT 9424
%define SP_CHOICES 9432
%define SP_INDEX_CHOICE 9440
%define SP_REPLAY 10400
%define SP_RETRY 10408
%define SP_MAX_ATTEMPTS 10416
%define SP_ATTEMPTS 10424
%define SP_SOURCE_LENGTH 10432
%define SP_SOURCE_CURSOR 10440
%define SP_SOURCE_LOADED 10448
%define SP_ERROR 10456
%define SP_CANCEL 10464
%define SP_EOF_FALLBACK 10472
%define SP_CANCEL_FALLBACK 10480
%define SP_POLICY 10488
%define SP_RESULT 10496
%define SP_SELECTION_COUNT 10504
%define SP_CONSOLE 10816
%define SP_FORM 10824
%define SP_FIELDS 10832
%define SP_VIEW 10840
%define SP_PANEL 10848
%define SP_FEEDBACK 10856
%define SP_STYLE 10864
%define SP_SECURITY 10872
%define SP_STRENGTH 10880
%define SP_MASK 10888
%define SP_RECORDED 10896
%define SP_REQUEST_ID 10904
%define SP_FIELD_DIGEST 10912
%define SP_RETRY_MESSAGE 10920
%define SP_INPUT_MODE 10928
%define SP_MAX_LINES 10936
%define SP_DELIMITER 10944
%define SP_LANGUAGE 10952
%define SP_MAX_LINES_ACTIVE 10960
%define SP_CHOICE_FLAGS 10968
%define SP_SECRET_WIPED 10976
%define SP_ZERO_REMAINS 10984
%define SP_SKIP_WIPE 10992
%define SP_ADAPTER_PLAN 11008
%define SP_REQUEST 11152
%define SP_RESPONSE 11200
%define SP_EVENT 11248
%define SP_EVIDENCE 11296
section .text
global nebo_runtime_scan_public
nebo_runtime_scan_public:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 lea rdi,[rbx+9312]
 mov ecx,24
 xor eax,eax
 rep stosq
 lea rdi,[rbx+10400]
 mov ecx,16
 rep stosq
 lea rdi,[rbx+10816]
 mov ecx,160
 rep stosq
 mov qword [rbx+SP_INPUT_MODE],NEBO_G105_INPUT_LINE
 mov qword [rbx+SP_MAX_LINES],256
 mov qword [rbx+SP_KIND],SCAN_KIND_TEXT
 mov rax,0x8000000000000000
 mov [rbx+SP_MIN],rax
 mov rax,0x7fffffffffffffff
 mov [rbx+SP_MAX],rax
 mov qword [rbx+SP_MAXLEN],4096
 mov qword [rbx+SP_FLAGS],SCAN_FLAG_CHOMP
 mov qword [rbx+SP_PRESENT],1
 mov qword [rbx+SP_SELECTION_COUNT],1
 mov r12,[rbx+8]
 test r12,r12
 jz .trap
 cmp r12,32
 ja .trap
 lea r13,[rbx+32]
.options:
 mov rax,[r13]
 cmp rax,5
 jbe .kind
 cmp rax,10
 je .trim
 cmp rax,11
 je .lower
 cmp rax,12
 je .upper
 cmp rax,13
 je .next
 cmp rax,16
 je .choice
 cmp rax,17
 je .index_choice
 cmp rax,20
 je .min
 cmp rax,21
 je .max
 cmp rax,22
 je .minlen
 cmp rax,23
 je .maxlen
 cmp rax,24
 je .required
 cmp rax,25
 je .allow
 cmp rax,26
 je .optional
 cmp rax,31
 je .replay
 cmp rax,32
 je .retry
 cmp rax,33
 je .max_attempts
 cmp rax,35
 je .cancel_on
 cmp rax,36
 je .eof_none
 cmp rax,37
 je .result_policy
 cmp rax,39
 je .eof_as
 cmp rax,40
 je .on_cancel
 cmp rax,41
 jb .last_option
 mov rdi,rbx
 mov rsi,r13
 call sp_public_option
 test eax,eax
 jnz .trap
 jmp .next
.last_option:
 cmp rax,30
 jne .trap
 mov rax,[r13+8]
 mov [rbx+SP_MOCK],rax
 jmp .next
.cancel_on:
 mov rax,[r13+8]
 mov [rbx+SP_CANCEL],rax
 or qword [rbx+SP_POLICY],G077_RESOLVE_INTERRUPTIBLE
 jmp .next
.eof_none:
 or qword [rbx+SP_POLICY],G077_RESOLVE_EOF_NONE
 or qword [rbx+SP_OPTIONAL],2
 jmp .next
.result_policy:
 mov qword [rbx+SP_RESULT],1
 or qword [rbx+SP_POLICY],G077_RESOLVE_RESULT
 jmp .next
.eof_as:
 mov rax,[r13+8]
 mov [rbx+SP_EOF_FALLBACK],rax
 or qword [rbx+SP_POLICY],G077_RESOLVE_EOF_FALLBACK
 jmp .next
.on_cancel:
 mov rax,[r13+8]
 mov [rbx+SP_CANCEL_FALLBACK],rax
 or qword [rbx+SP_POLICY],G077_RESOLVE_CANCEL_FALLBACK
 jmp .next
.replay:
 mov rax,[r13+8]
 mov [rbx+SP_REPLAY],rax
 jmp .next
.retry:
 mov qword [rbx+SP_RETRY],1
 jmp .next
.max_attempts:
 mov rax,[r13+8]
 test rax,rax
 jz .trap
 cmp rax,8
 ja .trap
 mov [rbx+SP_MAX_ATTEMPTS],rax
 jmp .next
.kind:
 cmp rax,SCAN_KIND_TEXT
 jb .trap
 cmp rax,SCAN_KIND_NUMBER
 je .trap
 mov [rbx+SP_KIND],rax
 jmp .next
.index_choice:
 mov qword [rbx+SP_CHOICE_FLAGS],NEBO_G105_CHOICE_INDEX
 mov qword [rbx+SP_INDEX_CHOICE],1
 mov qword [rbx+SP_KIND],SCAN_KIND_INT
.choice:
 cmp qword [rbx+SP_CHOICE_FLAGS],0
 jne .choice_flag_ready
 mov qword [rbx+SP_CHOICE_FLAGS],NEBO_G105_CHOICE_ONE
.choice_flag_ready:
 mov rax,[r13+8]
 mov [rbx+SP_CHOICES],rax
 jmp .next
.trim:
 or qword [rbx+SP_FLAGS],SCAN_FLAG_TRIM
 jmp .next
.lower:
 or qword [rbx+SP_FLAGS],SCAN_FLAG_LOWER
 jmp .next
.upper:
 or qword [rbx+SP_FLAGS],SCAN_FLAG_UPPER
 jmp .next
.min:
 mov rax,[r13+8]
 mov [rbx+SP_MIN],rax
 jmp .next
.max:
 mov rax,[r13+8]
 mov [rbx+SP_MAX],rax
 jmp .next
.minlen:
 mov rax,[r13+8]
 mov [rbx+SP_MINLEN],rax
 jmp .next
.maxlen:
 mov rax,[r13+8]
 mov [rbx+SP_MAXLEN],rax
 jmp .next
.required:
 mov qword [rbx+SP_REQUIRED],1
 jmp .next
.allow:
 mov qword [rbx+SP_REQUIRED],0
 jmp .next
.optional:
 or qword [rbx+SP_OPTIONAL],1
.next:
 add r13,32
 dec r12
 jnz .options
 cmp qword [rbx+SP_MAX_ATTEMPTS],0
 jne .attempt_limit
 mov qword [rbx+SP_MAX_ATTEMPTS],1
 cmp qword [rbx+SP_RETRY],0
 je .attempt_limit
 mov qword [rbx+SP_MAX_ATTEMPTS],8
.attempt_limit:
 mov rax,[rbx+SP_MIN]
 cmp rax,[rbx+SP_MAX]
 jg .trap
 mov rax,[rbx+SP_MAXLEN]
 cmp rax,4096
 ja .trap
 cmp [rbx+SP_MINLEN],rax
 ja .trap
 mov rdi,rbx
 call sp_public_plan
 test eax,eax
 jnz .trap
 lea rdi,[rbx+9472]
 mov rsi,[rbx+SP_KIND]
 mov rdx,[rbx+SP_FLAGS]
 cmp qword [rbx+SP_REQUIRED],0
 je .not_required
 or edx,SCAN_FLAG_REQUIRED
.not_required:
 cmp qword [rbx+SP_OPTIONAL],0
 je .plan_flags
 or edx,SCAN_FLAG_OPTIONAL
.plan_flags:
 mov rcx,[rbx+9800]
 mov r8,[rbx+9808]
 call nebo_g075_plan_init
 test eax,eax
 jnz .trap
 mov rax,[rbx]
 test rax,rax
 jz .trap
 cmp word [rax+20],1
 jne .trap
 cmp qword [rax+8],4096
 ja .trap
.attempt:
 inc qword [rbx+SP_ATTEMPTS]
 mov rdi,rbx
 call sp_public_request
 test eax,eax
 jnz .trap
 mov rdi,rbx
 call sp_read_source
 test eax,eax
 jnz .source_failure
 mov rdi,rbx
 mov rsi,rdx
 mov rdx,rcx
 call sp_multiline_finish
 test rax,rax
 js .failed
 mov rdi,rsi
 mov rsi,rax
 lea rdx,[rbx+1120]
 mov ecx,4096
 mov r8,[rbx+SP_FLAGS]
 call neboc_scan_normalize_ascii
 test rax,rax
 js .failed
 mov [rbx+SP_LENGTH],rax
 lea rdi,[rbx+1120]
 mov [rbx+SP_INPUT],rdi
 mov rsi,rax
 lea rdx,[rbx+1088]
 mov [rdx],rdi
 mov [rdx+8],rsi
 mov dword [rdx+16],5
 mov word [rdx+20],1
 mov word [rdx+22],0
 mov rdi,rdx
 call nebo_runtime_textual_text_is_utf8
 cmp eax,1
 jne .failed
 mov rax,[rbx+SP_CANCEL]
 test rax,rax
 jz .not_cancelled
 cmp word [rax+20],1
 jne .trap
 mov rcx,[rax+8]
 test rcx,rcx
 jz .trap
 cmp rcx,4096
 ja .trap
 mov [rbx+10632],rcx
 mov rdx,[rax]
 mov [rbx+10624],rdx
 mov rdi,[rbx+SP_INPUT]
 mov rsi,[rbx+SP_LENGTH]
 lea rdx,[rbx+10624]
 lea rcx,[rbx+10632]
 mov r8d,1
 call nebo_g077_cancel_match
 test rax,rax
 jns .cancel_event
.not_cancelled:
 cmp qword [rbx+SP_STRENGTH],0
 je .strength_ready
 mov rdi,[rbx+SP_INPUT]
 mov rsi,[rbx+SP_LENGTH]
 mov rdx,[rbx+SP_STRENGTH]
 call nebo_g077_secret_strength
 test eax,eax
 jnz .failed
.strength_ready:
 mov rdi,rbx
 call sp_multiline_validate
 test eax,eax
 jnz .failed
 mov rdi,[rbx+SP_INPUT]
 mov rsi,[rbx+SP_LENGTH]
 mov rdx,[rbx+SP_MINLEN]
 mov rcx,[rbx+SP_MAXLEN]
 xor r8d,r8d
 call neboc_scan_validate_text
 test eax,eax
 jnz .failed
 cmp qword [rbx+SP_LENGTH],0
 jne .parse
 cmp qword [rbx+SP_REQUIRED],0
 jne .failed
 test qword [rbx+SP_OPTIONAL],1
 jnz .none
 cmp qword [rbx+SP_CHOICES],0
 jne .choose
 cmp qword [rbx+SP_KIND],SCAN_KIND_TEXT
 jne .failed
 jmp .text
.none:
 mov qword [rbx+SP_PRESENT],0
 jmp .option
.parse:
 cmp qword [rbx+SP_CHOICES],0
 jne .choose
 cmp qword [rbx+SP_KIND],SCAN_KIND_TEXT
 je .text
 cmp qword [rbx+SP_KIND],SCAN_KIND_INT
 je .integer
 test qword [rbx+SP_CHOICE_FLAGS],NEBO_G105_CHOICE_BOOLEAN|NEBO_G105_CHOICE_CONFIRM
 jnz .yes_no
 mov rdi,[rbx+SP_KIND]
 mov rsi,[rbx+SP_INPUT]
 mov rdx,[rbx+SP_LENGTH]
 call nebo_g075_validate_kind
 test eax,eax
 jnz .parse_failed
 mov rdx,[rbx+SP_INPUT]
 movzx eax,byte [rdx]
 cmp qword [rbx+SP_KIND],SCAN_KIND_CHAR
 je .done
 xor eax,eax
 cmp byte [rdx],'t'
 sete al
 jmp .done
.yes_no:
 mov rdi,[rbx+SP_INPUT]
 mov rsi,[rbx+SP_LENGTH]
 call nebo_g076_yes_no
 test eax,eax
 js .failed
 jmp .done
.integer:
 mov rdi,[rbx+SP_INPUT]
 mov rsi,[rbx+SP_LENGTH]
 lea rdx,[rbx+SP_VALUE]
 call neboc_scan_parse_int
 test eax,eax
 jnz .parse_failed
.integer_validated:
 mov rdi,[rbx+SP_VALUE]
 mov rsi,[rbx+SP_MIN]
 mov rdx,[rbx+SP_MAX]
 xor ecx,ecx
 call neboc_scan_validate_int
 test eax,eax
 jnz .failed
 cmp qword [rbx+SP_OPTIONAL],0
 jne .option
 mov rax,[rbx+SP_VALUE]
 jmp .done
.choose:
 mov r12,[rbx+SP_CHOICES]
 mov r13,[r12]
 test r13,r13
 jz .failed
 cmp r13,32
 ja .failed
 xor r14d,r14d
.choice_descriptors:
 mov rax,[r12+r14*8+32]
 test rax,rax
 jz .failed
 cmp word [rax+20],1
 jne .failed
 mov rdx,[rax+8]
 cmp rdx,4096
 ja .failed
 mov [rbx+r14*8+10144],rdx
 mov rax,[rax]
 mov [rbx+r14*8+9888],rax
 inc r14
 cmp r14,r13
 jb .choice_descriptors
 test qword [rbx+SP_CHOICE_FLAGS],NEBO_G105_CHOICE_MULTI
 jnz .multi_selection
 mov rdi,[rbx+SP_INPUT]
 mov rsi,[rbx+SP_LENGTH]
 lea rdx,[rbx+9888]
 lea rcx,[rbx+10144]
 mov r8,r13
 test qword [rbx+SP_CHOICE_FLAGS],NEBO_G105_CHOICE_AUTOCOMPLETE
 jz .exact_choice
 call nebo_g076_prefix_index
 test rax,rax
 js .failed
 mov r12,[rbx+SP_CHOICES]
 mov rax,[r12+rax*8+32]
 mov rsi,[rax]
 mov rcx,[rax+8]
 mov [rbx+SP_LENGTH],rcx
 lea rdi,[rbx+1120]
 rep movsb
 jmp .text
.exact_choice:
 call neboc_scan_choice_index
 test rax,rax
 js .failed
 cmp qword [rbx+SP_INDEX_CHOICE],0
 je .text
 mov [rbx+SP_VALUE],rax
 jmp .integer_validated
.multi_selection:
 mov rdi,rbx
 call sp_multi_selection
 test eax,eax
 jnz .failed
 jmp .integer_validated
.option:
 lea rax,[rbx+1088]
 mov rdx,[rbx+SP_PRESENT]
 mov [rax],rdx
 mov rdx,[rbx+SP_VALUE]
 mov [rax+8],rdx
 jmp .done
.text:
 mov rdi,rbx
 call sp_confirm_secret
 test eax,eax
 jz .confirmed_text
 cmp eax,SCAN_E_VALIDATE
 je .failed
 jmp .source_failure
.confirmed_text:
 lea rax,[rbx+1088]
 mov rdx,[rbx+SP_INPUT]
 mov [rax],rdx
 mov rdx,[rbx+SP_LENGTH]
 mov [rax+8],rdx
 mov dword [rax+16],5
 mov word [rax+20],1
 mov word [rax+22],0
.done:
 mov rsi,rax
 mov rdi,rbx
 call sp_secret_prepare_result
 mov r15,rax
 mov rdi,rbx
 call sp_public_complete
 test eax,eax
 jnz .trap
 mov rax,r15
 cmp qword [rbx+SP_RESULT],0
 je .return
 lea rdx,[rbx+10528]
 mov qword [rdx],0
 cmp qword [rbx+SP_ERROR],0
 je .result_value
 mov qword [rdx],1
 mov rax,[rbx+SP_ERROR]
.result_value:
 mov [rdx+8],rax
 mov rax,rdx
.return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.source_failure:
 mov [rbx+SP_ERROR],rax
 cmp eax,SCAN_E_EOF
 jne .terminal_error
 mov edi,G077_EVENT_EOF
 mov r8,[rbx+SP_EOF_FALLBACK]
 jmp .event
.cancel_event:
 mov qword [rbx+SP_ERROR],SCAN_E_CANCEL
 mov edi,G077_EVENT_CANCEL
 mov r8,[rbx+SP_CANCEL_FALLBACK]
.event:
 mov r12,rdi
 mov r13,r8
 mov rdi,rbx
 call sp_public_complete
 test eax,eax
 jnz .trap
 mov rdi,r12
 mov r8,r13
 xor esi,esi
 xor edx,edx
 mov rcx,[rbx+SP_POLICY]
 lea r9,[rbx+10752]
 call nebo_g077_event_resolve
 test eax,eax
 jnz .terminal_error
 cmp qword [rbx+10752],G077_OUTCOME_ERROR
 je .terminal_error
 mov qword [rbx+SP_ERROR],0
 cmp qword [rbx+10752],G077_OUTCOME_NONE
 je .none
 mov rax,[rbx+10760]
 cmp qword [rbx+SP_OPTIONAL],0
 je .done
 mov [rbx+SP_VALUE],rax
 jmp .option
.parse_failed:
 mov qword [rbx+SP_ERROR],SCAN_E_PARSE
 jmp .failure_ready
.failed:
 mov qword [rbx+SP_ERROR],SCAN_E_VALIDATE
.failure_ready:
 mov rdi,rbx
 call sp_public_complete
 test eax,eax
 jnz .trap
 cmp qword [rbx+SP_RETRY],0
 je .terminal_error
 mov rdi,[rbx+SP_ATTEMPTS]
 mov rsi,[rbx+SP_MAX_ATTEMPTS]
 call neboc_scan_should_retry
 cmp eax,1
 jne .terminal_error
 mov rdi,[rbx+SP_RETRY_MESSAGE]
 test rdi,rdi
 jz .retry_ready
 cmp qword [rbx+SP_CONSOLE],0
 je .write_retry
 cmp qword [rbx+SP_MOCK],0
 jne .write_retry
 cmp qword [rbx+SP_REPLAY],0
 jne .write_retry
 mov rdi,[rel nebo_runtime_process_stack]
 call nebo_runtime_live_available
 test eax,eax
 jz .retry_ready
.write_retry:
 mov rdi,[rbx+SP_RETRY_MESSAGE]
 call sp_write_text
 test eax,eax
 jnz .trap
.retry_ready:
 mov qword [rbx+SP_ERROR],0
 jmp .attempt
.terminal_error:
 cmp qword [rbx+SP_RESULT],0
 jne .done
.trap:
 mov rdi,rbx
 call sp_public_complete
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 call nebo_runtime_trap
 ud2
%include "runtime/textual/scan_public_source.inc"
%include "runtime/textual/scan_public_console.inc"
%include "runtime/textual/scan_public_multiline.inc"
%include "runtime/textual/scan_public_secret.inc"
%include "runtime/textual/scan_public_choices.inc"
section .note.GNU-stack noalloc noexec nowrite progbits
