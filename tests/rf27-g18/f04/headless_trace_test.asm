bits 64
default rel
%include "runtime/window/headless/headless_window.inc"

section .data
trace_title db 'Trace'

section .bss
align 8
trace_runtime resb NEBO_HEADLESS_RUNTIME_SIZE
trace_record resb NEBO_WINDOW_SIZE
trace_options resb NEBO_WINDOW_OPTIONS_SIZE
trace_title_storage resb 256
trace_event_storage resb NEBO_WINDOW_EVENT_SIZE*16
trace_scheduler_budget resb NEBO_SCHEDULER_BUDGET_SIZE
trace_task_group resb NEBO_TASK_GROUP_SIZE
trace_task_storage resb nebo_concurrency_contract_TASK_SIZE
trace_cancel_budget resb NEBO_CANCELLATION_BUDGET_SIZE
trace_cancel_token resb NEBO_CANCELLATION_TOKEN_SIZE
trace_stream resb NEBO_HEADLESS_STREAM_SIZE
trace_event resb NEBO_WINDOW_EVENT_SIZE
trace_template resb NEBO_WINDOW_EVENT_SIZE
trace_handle resq 1

section .text
global _start
_start:
 lea rdi,[rel trace_scheduler_budget]
 mov esi,1
 mov edx,1
 mov ecx,1
 mov r8d,8
 mov r9d,32
 call nebo_scheduler_budget_init
 test eax,eax
 jne .fail
 lea rdi,[rel trace_task_group]
 lea rsi,[rel trace_scheduler_budget]
 lea rdx,[rel trace_task_storage]
 mov ecx,1
 call nebo_task_group_init
 test eax,eax
 jne .fail
 lea rdi,[rel trace_cancel_budget]
 mov esi,1
 mov edx,1
 mov ecx,1000000000
 call nebo_cancellation_budget_init
 test eax,eax
 jne .fail
 lea rdi,[rel trace_cancel_token]
 lea rsi,[rel trace_cancel_budget]
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 call nebo_cancellation_token_init
 test eax,eax
 jne .fail
 lea rdi,[rel trace_runtime]
 lea rsi,[rel trace_record]
 mov edx,1
 call nebo_headless_runtime_init
 test eax,eax
 jne .fail

 lea rdi,[rel trace_options]
 mov ecx,NEBO_WINDOW_OPTIONS_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel trace_options+NEBO_WINDOW_OPTIONS_WIDTH_OFFSET],320
 mov qword [rel trace_options+NEBO_WINDOW_OPTIONS_HEIGHT_OFFSET],200
 lea rax,[rel trace_title]
 mov [rel trace_options+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET],rax
 mov qword [rel trace_options+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET],5
 lea rax,[rel trace_title_storage]
 mov [rel trace_options+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET],rax
 mov qword [rel trace_options+NEBO_WINDOW_OPTIONS_TITLE_CAPACITY_OFFSET],256
 lea rax,[rel trace_event_storage]
 mov [rel trace_options+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET],rax
 mov qword [rel trace_options+NEBO_WINDOW_OPTIONS_EVENT_CAPACITY_OFFSET],16
 lea rax,[rel trace_cancel_token]
 mov [rel trace_options+NEBO_WINDOW_OPTIONS_CANCELLATION_PTR_OFFSET],rax
 lea rax,[rel trace_task_group]
 mov [rel trace_options+NEBO_WINDOW_OPTIONS_TASK_GROUP_PTR_OFFSET],rax
 mov dword [rel trace_options+NEBO_WINDOW_OPTIONS_BACKEND_PREFERENCE_OFFSET],NEBO_WINDOW_BACKEND_HEADLESS
 mov dword [rel trace_options+NEBO_WINDOW_OPTIONS_FLAGS_OFFSET],NEBO_WINDOW_OPTION_RESIZABLE | NEBO_WINDOW_OPTION_DECORATED | NEBO_WINDOW_OPTION_TEXT_INPUT
 mov qword [rel trace_options+NEBO_WINDOW_OPTIONS_OWNER_CONTEXT_OFFSET],0x4242
 lea rdi,[rel trace_runtime]
 lea rsi,[rel trace_options]
 lea rdx,[rel trace_handle]
 call nebo_headless_window_create
 test eax,eax
 jne .fail

 lea rdi,[rel trace_runtime]
 mov rsi,[rel trace_handle]
 mov rdx,0x4242
 lea rcx,[rel trace_stream]
 call nebo_headless_window_events
 test eax,eax
 jne .fail

 lea rdi,[rel trace_runtime]
 mov rsi,[rel trace_handle]
 mov rdx,0x4242
 call nebo_headless_window_show
 test eax,eax
 jne .fail
 lea rdi,[rel trace_runtime]
 mov rsi,[rel trace_handle]
 mov rdx,0x4242
 mov ecx,640
 mov r8d,360
 call nebo_headless_window_resize
 test eax,eax
 jne .fail
 lea rdi,[rel trace_runtime]
 mov rsi,[rel trace_handle]
 mov rdx,0x4242
 call nebo_headless_window_request_redraw
 test eax,eax
 jne .fail

 lea rdi,[rel trace_template]
 mov ecx,NEBO_WINDOW_EVENT_QWORDS
 xor eax,eax
 rep stosq
 mov dword [rel trace_template+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_KEY_DOWN
 mov qword [rel trace_template+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],65
 mov qword [rel trace_template+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],30
 mov qword [rel trace_template+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],1
 lea rdi,[rel trace_runtime]
 mov rsi,[rel trace_handle]
 mov rdx,0x4242
 lea rcx,[rel trace_template]
 call nebo_headless_window_push_event
 test eax,eax
 jne .fail

 lea rdi,[rel trace_template]
 mov ecx,NEBO_WINDOW_EVENT_QWORDS
 xor eax,eax
 rep stosq
 mov dword [rel trace_template+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_TEXT_INPUT
 mov qword [rel trace_template+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],233
 mov qword [rel trace_template+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],2
 mov qword [rel trace_template+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],0xA9C3
 lea rdi,[rel trace_runtime]
 mov rsi,[rel trace_handle]
 mov rdx,0x4242
 lea rcx,[rel trace_template]
 call nebo_headless_window_push_event
 test eax,eax
 jne .fail

 lea rdi,[rel trace_runtime]
 mov rsi,[rel trace_handle]
 mov rdx,0x4242
 call nebo_headless_window_hide
 test eax,eax
 jne .fail
 lea rdi,[rel trace_runtime]
 mov rsi,[rel trace_handle]
 mov rdx,0x4242
 call nebo_headless_window_close
 test eax,eax
 jne .fail

 mov r12d,8
.drain:
 lea rdi,[rel trace_stream]
 lea rsi,[rel trace_event]
 call nebo_headless_event_stream_poll
 test eax,eax
 jne .fail
 cmp edx,1
 jne .fail
 mov eax,1
 mov edi,1
 lea rsi,[rel trace_event]
 mov edx,NEBO_WINDOW_EVENT_SIZE
 syscall
 cmp rax,NEBO_WINDOW_EVENT_SIZE
 jne .fail
 dec r12d
 jnz .drain

 lea rdi,[rel trace_stream]
 lea rsi,[rel trace_event]
 call nebo_headless_event_stream_poll
 test eax,eax
 jne .fail
 test edx,edx
 jne .fail
 lea rdi,[rel trace_stream]
 call nebo_headless_event_stream_release
 test eax,eax
 jne .fail
 lea rdi,[rel trace_runtime]
 mov rsi,[rel trace_handle]
 mov rdx,0x4242
 call nebo_headless_window_reclaim
 test eax,eax
 jne .fail
 xor edi,edi
 jmp .exit
.fail:
 mov edi,1
.exit:
 mov eax,60
 syscall
