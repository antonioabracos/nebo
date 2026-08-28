bits 64
default rel
%include "runtime/window/headless/headless_window.inc"

section .data
example_title db 'Nebo headless'

section .bss
align 8
example_runtime resb NEBO_HEADLESS_RUNTIME_SIZE
example_record resb NEBO_WINDOW_SIZE
example_options resb NEBO_WINDOW_OPTIONS_SIZE
example_title_storage resb 256
example_event_storage resb NEBO_WINDOW_EVENT_SIZE*8
example_scheduler_budget resb NEBO_SCHEDULER_BUDGET_SIZE
example_task_group resb NEBO_TASK_GROUP_SIZE
example_task_storage resb nebo_concurrency_contract_TASK_SIZE
example_cancel_budget resb NEBO_CANCELLATION_BUDGET_SIZE
example_cancel_token resb NEBO_CANCELLATION_TOKEN_SIZE
example_stream resb NEBO_HEADLESS_STREAM_SIZE
example_event resb NEBO_WINDOW_EVENT_SIZE
example_handle resq 1

section .text
global _start
_start:
 lea rdi,[rel example_scheduler_budget]
 mov esi,1
 mov edx,1
 mov ecx,1
 mov r8d,4
 mov r9d,16
 call nebo_scheduler_budget_init
 test eax,eax
 jne .fail
 lea rdi,[rel example_task_group]
 lea rsi,[rel example_scheduler_budget]
 lea rdx,[rel example_task_storage]
 mov ecx,1
 call nebo_task_group_init
 test eax,eax
 jne .fail
 lea rdi,[rel example_cancel_budget]
 mov esi,1
 mov edx,1
 mov ecx,1000000000
 call nebo_cancellation_budget_init
 test eax,eax
 jne .fail
 lea rdi,[rel example_cancel_token]
 lea rsi,[rel example_cancel_budget]
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 call nebo_cancellation_token_init
 test eax,eax
 jne .fail
 lea rdi,[rel example_runtime]
 lea rsi,[rel example_record]
 mov edx,1
 call nebo_headless_runtime_init
 test eax,eax
 jne .fail
 lea rdi,[rel example_options]
 mov ecx,NEBO_WINDOW_OPTIONS_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel example_options+NEBO_WINDOW_OPTIONS_WIDTH_OFFSET],640
 mov qword [rel example_options+NEBO_WINDOW_OPTIONS_HEIGHT_OFFSET],360
 lea rax,[rel example_title]
 mov [rel example_options+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET],rax
 mov qword [rel example_options+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET],13
 lea rax,[rel example_title_storage]
 mov [rel example_options+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET],rax
 mov qword [rel example_options+NEBO_WINDOW_OPTIONS_TITLE_CAPACITY_OFFSET],256
 lea rax,[rel example_event_storage]
 mov [rel example_options+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET],rax
 mov qword [rel example_options+NEBO_WINDOW_OPTIONS_EVENT_CAPACITY_OFFSET],8
 lea rax,[rel example_cancel_token]
 mov [rel example_options+NEBO_WINDOW_OPTIONS_CANCELLATION_PTR_OFFSET],rax
 lea rax,[rel example_task_group]
 mov [rel example_options+NEBO_WINDOW_OPTIONS_TASK_GROUP_PTR_OFFSET],rax
 mov dword [rel example_options+NEBO_WINDOW_OPTIONS_BACKEND_PREFERENCE_OFFSET],NEBO_WINDOW_BACKEND_HEADLESS
 mov dword [rel example_options+NEBO_WINDOW_OPTIONS_FLAGS_OFFSET],NEBO_WINDOW_OPTION_RESIZABLE | NEBO_WINDOW_OPTION_DECORATED
 mov qword [rel example_options+NEBO_WINDOW_OPTIONS_OWNER_CONTEXT_OFFSET],0x4e45424f
 lea rdi,[rel example_runtime]
 lea rsi,[rel example_options]
 lea rdx,[rel example_handle]
 call nebo_headless_window_create
 test eax,eax
 jne .fail
 lea rdi,[rel example_runtime]
 mov rsi,[rel example_handle]
 mov rdx,0x4e45424f
 lea rcx,[rel example_stream]
 call nebo_headless_window_events
 test eax,eax
 jne .fail
 lea rdi,[rel example_runtime]
 mov rsi,[rel example_handle]
 mov rdx,0x4e45424f
 call nebo_headless_window_show
 test eax,eax
 jne .fail

 ; CREATED and SHOWN arrive in deterministic order.
 lea rdi,[rel example_stream]
 lea rsi,[rel example_event]
 xor edx,edx
 call nebo_headless_event_stream_wait
 test eax,eax
 jne .fail
 cmp edx,1
 jne .fail
 cmp dword [rel example_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_CREATED
 jne .fail
 lea rdi,[rel example_stream]
 lea rsi,[rel example_event]
 call nebo_headless_event_stream_poll
 test eax,eax
 jne .fail
 cmp edx,1
 jne .fail
 cmp dword [rel example_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_SHOWN
 jne .fail

 lea rdi,[rel example_runtime]
 mov rsi,[rel example_handle]
 mov rdx,0x4e45424f
 call nebo_headless_window_close
 test eax,eax
 jne .fail
 lea rdi,[rel example_stream]
 lea rsi,[rel example_event]
 xor edx,edx
 call nebo_headless_event_stream_wait
 test eax,eax
 jne .fail
 cmp edx,1
 jne .fail
 cmp dword [rel example_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_CLOSED
 jne .fail
 lea rdi,[rel example_stream]
 call nebo_headless_event_stream_release
 test eax,eax
 jne .fail
 lea rdi,[rel example_runtime]
 mov rsi,[rel example_handle]
 mov rdx,0x4e45424f
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
