bits 64
default rel
%include "runtime/window/headless/headless_window.inc"

section .data
title_initial db 'Nebo'
title_next db 'Headless'
title_invalid db 0xc0,0x80

section .bss
align 8
runtime resb NEBO_HEADLESS_RUNTIME_SIZE
records resb NEBO_WINDOW_SIZE*2
options resb NEBO_WINDOW_OPTIONS_SIZE
options2 resb NEBO_WINDOW_OPTIONS_SIZE
title_storage resb 256
title_storage2 resb 256
event_storage resb NEBO_WINDOW_EVENT_SIZE*8
event_storage2 resb NEBO_WINDOW_EVENT_SIZE*8
scheduler_budget resb NEBO_SCHEDULER_BUDGET_SIZE
task_group resb NEBO_TASK_GROUP_SIZE
task_storage resb nebo_concurrency_contract_TASK_SIZE
task_group2 resb NEBO_TASK_GROUP_SIZE
task_storage2 resb nebo_concurrency_contract_TASK_SIZE
cancel_budget resb NEBO_CANCELLATION_BUDGET_SIZE
cancel_token resb NEBO_CANCELLATION_TOKEN_SIZE
cancel_token2 resb NEBO_CANCELLATION_TOKEN_SIZE
stream resb NEBO_HEADLESS_STREAM_SIZE
event resb NEBO_WINDOW_EVENT_SIZE
template_event resb NEBO_WINDOW_EVENT_SIZE
handle resq 1
handle2 resq 1
old_handle resq 1

section .text
global _start
_start:
 xor r15d,r15d
%if NEBO_HEADLESS_RUNTIME_SIZE != 64
%error runtime_size
%endif
%if NEBO_HEADLESS_STREAM_SIZE != 64
%error stream_size
%endif
%if NEBO_WINDOW_SIZE != 192
%error record_size
%endif
%if NEBO_WINDOW_EVENT_SIZE != 64
%error event_size
%endif
 lea rdi,[rel scheduler_budget]
 mov esi,1
 mov edx,1
 mov ecx,1
 mov r8d,8
 mov r9d,32
 call nebo_scheduler_budget_init
 inc r15d ; scheduler_budget_init
 test eax,eax
 jne .fail
 lea rdi,[rel cancel_budget]
 mov esi,8
 mov edx,8
 mov ecx,1000000000
 call nebo_cancellation_budget_init
 inc r15d ; cancel_budget_init
 test eax,eax
 jne .fail
 xor edi,edi
 lea rsi,[rel records]
 mov edx,2
 call nebo_headless_runtime_init
 inc r15d ; runtime_null
 cmp eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 jne .fail
 lea rdi,[rel runtime]
 lea rsi,[rel records]
 xor edx,edx
 call nebo_headless_runtime_init
 inc r15d ; runtime_cap0
 cmp eax,NEBO_WINDOW_ERROR_LIMIT_EXCEEDED
 jne .fail
 lea rdi,[rel runtime]
 lea rsi,[rel records]
 mov edx,17
 call nebo_headless_runtime_init
 inc r15d ; runtime_cap17
 cmp eax,NEBO_WINDOW_ERROR_LIMIT_EXCEEDED
 jne .fail
 mov rax,0x1122334455667788
 mov [rel runtime],rax
 lea rdi,[rel runtime]
 lea rsi,[rel runtime]
 mov edx,1
 call nebo_headless_runtime_init
 inc r15d ; runtime_records_overlap
 cmp eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 jne .fail
 inc r15d ; runtime_overlap_atomic
 mov rax,0x1122334455667788
 cmp [rel runtime],rax
 jne .fail
 lea rdi,[rel runtime]
 lea rsi,[rel records]
 mov edx,2
 call nebo_headless_runtime_init
 inc r15d ; runtime_init
 test eax,eax
 jne .fail
 inc r15d ; runtime_active0
 cmp qword [rel runtime+NEBO_HEADLESS_RUNTIME_ACTIVE_COUNT_OFFSET],0
 jne .fail
 inc r15d ; generation_slot1
 cmp qword [rel records+nebo_canvas_WINDOW_GENERATION_OFFSET],1
 jne .fail
 inc r15d ; generation_slot2
 cmp qword [rel records+NEBO_WINDOW_SIZE+nebo_canvas_WINDOW_GENERATION_OFFSET],1
 jne .fail
 lea rdi,[rel task_group]
 lea rsi,[rel scheduler_budget]
 lea rdx,[rel task_storage]
 mov ecx,1
 call nebo_task_group_init
 inc r15d ; first_task_group_init
 test eax,eax
 jne .fail
 lea rdi,[rel cancel_token]
 lea rsi,[rel cancel_budget]
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 call nebo_cancellation_token_init
 inc r15d ; first_cancel_token_init
 test eax,eax
 jne .fail
 lea rdi,[rel options]
 mov ecx,NEBO_WINDOW_OPTIONS_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel options+NEBO_WINDOW_OPTIONS_WIDTH_OFFSET],640
 mov qword [rel options+NEBO_WINDOW_OPTIONS_HEIGHT_OFFSET],480
 lea rax,[rel title_initial]
 mov [rel options+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET],rax
 mov qword [rel options+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET],4
 lea rax,[rel title_storage]
 mov [rel options+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET],rax
 mov qword [rel options+NEBO_WINDOW_OPTIONS_TITLE_CAPACITY_OFFSET],256
 lea rax,[rel event_storage]
 mov [rel options+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET],rax
 mov qword [rel options+NEBO_WINDOW_OPTIONS_EVENT_CAPACITY_OFFSET],8
 lea rax,[rel cancel_token]
 mov [rel options+NEBO_WINDOW_OPTIONS_CANCELLATION_PTR_OFFSET],rax
 lea rax,[rel task_group]
 mov [rel options+NEBO_WINDOW_OPTIONS_TASK_GROUP_PTR_OFFSET],rax
 mov dword [rel options+NEBO_WINDOW_OPTIONS_BACKEND_PREFERENCE_OFFSET],2
 mov dword [rel options+NEBO_WINDOW_OPTIONS_FLAGS_OFFSET],15
 mov qword [rel options+NEBO_WINDOW_OPTIONS_OWNER_CONTEXT_OFFSET],0x1111
 mov qword [rel handle],0x11223344
 lea rdi,[rel runtime]
 lea rsi,[rel options]
 lea rdx,[rel handle]
 call nebo_headless_window_create
 inc r15d ; window_create_error
 cmp eax,NEBO_WINDOW_ERROR_BACKEND_UNAVAILABLE
 jne .fail
 inc r15d ; x11_out_unchanged
 cmp qword [rel handle],0x11223344
 jne .fail
 inc r15d ; x11_active_unchanged
 cmp qword [rel runtime+NEBO_HEADLESS_RUNTIME_ACTIVE_COUNT_OFFSET],0
 jne .fail
 lea rdi,[rel options]
 mov ecx,NEBO_WINDOW_OPTIONS_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel options+NEBO_WINDOW_OPTIONS_WIDTH_OFFSET],640
 mov qword [rel options+NEBO_WINDOW_OPTIONS_HEIGHT_OFFSET],480
 lea rax,[rel title_initial]
 mov [rel options+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET],rax
 mov qword [rel options+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET],4
 lea rax,[rel title_storage]
 mov [rel options+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET],rax
 mov qword [rel options+NEBO_WINDOW_OPTIONS_TITLE_CAPACITY_OFFSET],256
 lea rax,[rel event_storage]
 mov [rel options+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET],rax
 mov qword [rel options+NEBO_WINDOW_OPTIONS_EVENT_CAPACITY_OFFSET],8
 lea rax,[rel cancel_token]
 mov [rel options+NEBO_WINDOW_OPTIONS_CANCELLATION_PTR_OFFSET],rax
 lea rax,[rel task_group]
 mov [rel options+NEBO_WINDOW_OPTIONS_TASK_GROUP_PTR_OFFSET],rax
 mov dword [rel options+NEBO_WINDOW_OPTIONS_BACKEND_PREFERENCE_OFFSET],0
 mov dword [rel options+NEBO_WINDOW_OPTIONS_FLAGS_OFFSET],15
 mov qword [rel options+NEBO_WINDOW_OPTIONS_OWNER_CONTEXT_OFFSET],0x1111
 lea rdi,[rel runtime]
 lea rsi,[rel options]
 lea rdx,[rel handle]
 call nebo_headless_window_create
 inc r15d ; window_create
 test eax,eax
 jne .fail
 inc r15d ; handle_generation1_slot1
 mov rax,0x0000000100000001
 cmp qword [rel handle],rax
 jne .fail
 mov rax,[rel handle]
 mov [rel old_handle],rax
 inc r15d ; created_state
 cmp dword [rel records+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_CREATED
 jne .fail
 inc r15d ; headless_backend
 cmp dword [rel records+NEBO_WINDOW_BACKEND_OFFSET],NEBO_WINDOW_BACKEND_HEADLESS
 jne .fail
 inc r15d ; created_event_count
 cmp qword [rel records+NEBO_WINDOW_EVENT_COUNT_OFFSET],1
 jne .fail
 inc r15d ; title_copied
 cmp dword [rel title_storage],0x6f62654e
 jne .fail
 inc r15d ; active1
 cmp qword [rel runtime+NEBO_HEADLESS_RUNTIME_ACTIVE_COUNT_OFFSET],1
 jne .fail
 lea rdi,[rel task_group2]
 lea rsi,[rel scheduler_budget]
 lea rdx,[rel task_storage2]
 mov ecx,1
 call nebo_task_group_init
 inc r15d ; second_task_group_init
 test eax,eax
 jne .fail
 lea rdi,[rel cancel_token2]
 lea rsi,[rel cancel_budget]
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 call nebo_cancellation_token_init
 inc r15d ; second_cancel_token_init
 test eax,eax
 jne .fail
 lea rdi,[rel options2]
 mov ecx,NEBO_WINDOW_OPTIONS_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel options2+NEBO_WINDOW_OPTIONS_WIDTH_OFFSET],320
 mov qword [rel options2+NEBO_WINDOW_OPTIONS_HEIGHT_OFFSET],200
 lea rax,[rel title_initial]
 mov [rel options2+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET],rax
 mov qword [rel options2+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET],4
 lea rax,[rel title_storage2]
 mov [rel options2+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET],rax
 mov qword [rel options2+NEBO_WINDOW_OPTIONS_TITLE_CAPACITY_OFFSET],256
 lea rax,[rel event_storage]
 mov [rel options2+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET],rax
 mov qword [rel options2+NEBO_WINDOW_OPTIONS_EVENT_CAPACITY_OFFSET],8
 lea rax,[rel cancel_token2]
 mov [rel options2+NEBO_WINDOW_OPTIONS_CANCELLATION_PTR_OFFSET],rax
 lea rax,[rel task_group2]
 mov [rel options2+NEBO_WINDOW_OPTIONS_TASK_GROUP_PTR_OFFSET],rax
 mov dword [rel options2+NEBO_WINDOW_OPTIONS_BACKEND_PREFERENCE_OFFSET],1
 mov dword [rel options2+NEBO_WINDOW_OPTIONS_FLAGS_OFFSET],15
 mov qword [rel options2+NEBO_WINDOW_OPTIONS_OWNER_CONTEXT_OFFSET],0x2222
 mov rax,0xaabbccddeeff0011
 mov [rel handle2],rax
 lea rdi,[rel runtime]
 lea rsi,[rel options2]
 lea rdx,[rel handle2]
 call nebo_headless_window_create
 inc r15d ; shared_event_storage_rejected
 cmp eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 jne .fail
 inc r15d ; shared_event_out_atomic
 mov rax,0xaabbccddeeff0011
 cmp [rel handle2],rax
 jne .fail
 inc r15d ; shared_event_active_atomic
 cmp qword [rel runtime+NEBO_HEADLESS_RUNTIME_ACTIVE_COUNT_OFFSET],1
 jne .fail
 lea rax,[rel event_storage2]
 mov [rel options2+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET],rax
 lea rax,[rel title_storage]
 mov [rel options2+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET],rax
 lea rdi,[rel runtime]
 lea rsi,[rel options2]
 lea rdx,[rel handle2]
 call nebo_headless_window_create
 inc r15d ; shared_title_storage_rejected
 cmp eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 jne .fail
 inc r15d ; shared_title_out_atomic
 mov rax,0xaabbccddeeff0011
 cmp [rel handle2],rax
 jne .fail
 inc r15d ; shared_title_active_atomic
 cmp qword [rel runtime+NEBO_HEADLESS_RUNTIME_ACTIVE_COUNT_OFFSET],1
 jne .fail
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x2222
 call nebo_headless_window_show
 inc r15d ; owner_mismatch
 cmp eax,NEBO_WINDOW_ERROR_OWNER_MISMATCH
 jne .fail
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 lea rcx,[rel stream]
 call nebo_headless_window_events
 inc r15d ; events_acquire
 test eax,eax
 jne .fail
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 lea rcx,[rel template_event]
 call nebo_headless_window_events
 inc r15d ; second_stream_rejected
 cmp eax,NEBO_WINDOW_ERROR_BAD_STATE
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_event_stream_poll
 inc r15d ; poll_status
 test eax,eax
 jne .fail
 inc r15d ; poll_ready_1
 cmp edx,1
 jne .fail
 inc r15d ; poll_kind_NEBO_WINDOW_EVENT_CREATED
 cmp dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_CREATED
 jne .fail
 inc r15d ; created_seq1
 cmp qword [rel event+NEBO_WINDOW_EVENT_SEQUENCE_OFFSET],1
 jne .fail
 inc r15d ; created_timestamp1
 cmp qword [rel event+NEBO_WINDOW_EVENT_TIMESTAMP_OFFSET],1
 jne .fail
 inc r15d ; created_backend_payload
 cmp qword [rel event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],NEBO_WINDOW_BACKEND_HEADLESS
 jne .fail
 inc r15d ; created_width_payload
 cmp qword [rel event+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],640
 jne .fail
 inc r15d ; created_height_payload
 cmp qword [rel event+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],480
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_event_stream_poll
 inc r15d ; poll_status
 test eax,eax
 jne .fail
 inc r15d ; poll_ready_0
 cmp edx,0
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 mov edx,1
 call nebo_headless_event_stream_wait
 inc r15d ; wait_empty_status
 test eax,eax
 jne .fail
 inc r15d ; wait_empty_ready0
 test edx,edx
 jne .fail
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 call nebo_headless_window_show
 inc r15d ; show
 test eax,eax
 jne .fail
 inc r15d ; visible_state
 cmp dword [rel records+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_VISIBLE
 jne .fail
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 call nebo_headless_window_show
 inc r15d ; duplicate_show
 cmp eax,NEBO_WINDOW_ERROR_BAD_STATE
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_event_stream_poll
 inc r15d ; poll_status
 test eax,eax
 jne .fail
 inc r15d ; poll_ready_1
 cmp edx,1
 jne .fail
 inc r15d ; poll_kind_NEBO_WINDOW_EVENT_SHOWN
 cmp dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_SHOWN
 jne .fail
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 xor ecx,ecx
 mov r8d,600
 call nebo_headless_window_resize
 inc r15d ; resize_invalid
 cmp eax,NEBO_WINDOW_ERROR_DIMENSION_OUT_OF_RANGE
 jne .fail
 inc r15d ; resize_atomic_width
 cmp qword [rel records+NEBO_WINDOW_WIDTH_OFFSET],640
 jne .fail
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 mov ecx,800
 mov r8d,600
 call nebo_headless_window_resize
 inc r15d ; resize_valid
 test eax,eax
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_event_stream_poll
 inc r15d ; poll_status
 test eax,eax
 jne .fail
 inc r15d ; poll_ready_1
 cmp edx,1
 jne .fail
 inc r15d ; poll_kind_NEBO_WINDOW_EVENT_RESIZED
 cmp dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_RESIZED
 jne .fail
 lea rdi,[rel event]
 call nebo_headless_window_event_resize
 inc r15d ; resize_accessor_status
 test eax,eax
 jne .fail
 inc r15d ; resize_accessor_present
 cmp edx,1
 jne .fail
 inc r15d ; resize_accessor_width
 cmp r8,800
 jne .fail
 inc r15d ; resize_accessor_height
 cmp r9,600
 jne .fail
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 lea rcx,[rel title_next]
 mov r8d,8
 call nebo_headless_window_set_title
 inc r15d ; set_title
 test eax,eax
 jne .fail
 inc r15d ; title_len8
 cmp qword [rel records+NEBO_WINDOW_TITLE_LENGTH_OFFSET],8
 jne .fail
 inc r15d ; title_bytes_headless
 mov rax,0x7373656c64616548
 cmp qword [rel title_storage],rax
 jne .fail
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 lea rcx,[rel title_invalid]
 mov r8d,2
 call nebo_headless_window_set_title
 inc r15d ; invalid_title_utf8_rejected
 cmp eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 jne .fail
 inc r15d ; invalid_title_length_atomic
 cmp qword [rel records+NEBO_WINDOW_TITLE_LENGTH_OFFSET],8
 jne .fail
 inc r15d ; invalid_title_bytes_atomic
 mov rax,0x7373656c64616548
 cmp qword [rel title_storage],rax
 jne .fail
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 call nebo_headless_window_request_redraw
 inc r15d ; redraw_request
 test eax,eax
 jne .fail
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 call nebo_headless_window_request_redraw
 inc r15d ; redraw_request
 test eax,eax
 jne .fail
 inc r15d ; redraw_coalesced
 cmp qword [rel records+NEBO_WINDOW_EVENT_COUNT_OFFSET],1
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_event_stream_poll
 inc r15d ; poll_status
 test eax,eax
 jne .fail
 inc r15d ; poll_ready_1
 cmp edx,1
 jne .fail
 inc r15d ; poll_kind_NEBO_WINDOW_EVENT_REDRAW_REQUESTED
 cmp dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_REDRAW_REQUESTED
 jne .fail
 inc r15d ; redraw_flag_cleared
 test dword [rel records+NEBO_WINDOW_FLAGS_OFFSET],NEBO_HEADLESS_FLAG_REDRAW_PENDING
 jne .fail
 lea rdi,[rel template_event]
 mov ecx,NEBO_WINDOW_EVENT_QWORDS
 xor eax,eax
 rep stosq
 mov dword [rel template_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_KEY_DOWN
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],65
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],30
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],1
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 lea rcx,[rel template_event]
 call nebo_headless_window_push_event
 inc r15d ; push_event
 test eax,eax
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_event_stream_poll
 inc r15d ; poll_status
 test eax,eax
 jne .fail
 inc r15d ; poll_ready_1
 cmp edx,1
 jne .fail
 inc r15d ; poll_kind_NEBO_WINDOW_EVENT_KEY_DOWN
 cmp dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_KEY_DOWN
 jne .fail
 inc r15d ; key_native
 test dword [rel event+NEBO_WINDOW_EVENT_FLAGS_OFFSET],NEBO_WINDOW_EVENT_FLAG_NATIVE
 jz .fail
 lea rdi,[rel event]
 call nebo_headless_window_event_key
 inc r15d ; key_accessor_status
 test eax,eax
 jne .fail
 inc r15d ; key_present
 cmp edx,1
 jne .fail
 inc r15d ; key_logical
 cmp r8,65
 jne .fail
 inc r15d ; key_native_code
 cmp r9,30
 jne .fail
 inc r15d ; key_modifiers
 cmp r10,1
 jne .fail
 lea rdi,[rel template_event]
 mov ecx,NEBO_WINDOW_EVENT_QWORDS
 xor eax,eax
 rep stosq
 mov dword [rel template_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_TEXT_INPUT
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],233
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],2
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],43459
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 lea rcx,[rel template_event]
 call nebo_headless_window_push_event
 inc r15d ; push_event
 test eax,eax
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_event_stream_poll
 inc r15d ; poll_status
 test eax,eax
 jne .fail
 inc r15d ; poll_ready_1
 cmp edx,1
 jne .fail
 inc r15d ; poll_kind_NEBO_WINDOW_EVENT_TEXT_INPUT
 cmp dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_TEXT_INPUT
 jne .fail
 lea rdi,[rel event]
 call nebo_headless_window_event_text_input
 inc r15d ; text_accessor_status
 test eax,eax
 jne .fail
 inc r15d ; text_present
 cmp edx,1
 jne .fail
 inc r15d ; text_scalar
 cmp r8,0xE9
 jne .fail
 inc r15d ; text_len
 cmp r9,2
 jne .fail
 inc r15d ; text_bytes
 cmp r10,0xA9C3
 jne .fail
 lea rdi,[rel template_event]
 mov ecx,NEBO_WINDOW_EVENT_QWORDS
 xor eax,eax
 rep stosq
 mov dword [rel template_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_TEXT_INPUT
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],233
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],2
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],65535
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 lea rcx,[rel template_event]
 call nebo_headless_window_push_event
 inc r15d ; push_event_error
 cmp eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 jne .fail
 inc r15d ; invalid_text_no_event
 cmp qword [rel records+NEBO_WINDOW_EVENT_COUNT_OFFSET],0
 jne .fail
 lea rdi,[rel template_event]
 mov ecx,NEBO_WINDOW_EVENT_QWORDS
 xor eax,eax
 rep stosq
 mov dword [rel template_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_CLOSE_REQUESTED
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],0
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],0
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],0
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 lea rcx,[rel template_event]
 call nebo_headless_window_push_event
 inc r15d ; push_event
 test eax,eax
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_event_stream_poll
 inc r15d ; poll_status
 test eax,eax
 jne .fail
 inc r15d ; poll_ready_1
 cmp edx,1
 jne .fail
 inc r15d ; poll_kind_NEBO_WINDOW_EVENT_CLOSE_REQUESTED
 cmp dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_CLOSE_REQUESTED
 jne .fail
 inc r15d ; close_preventable
 test dword [rel event+NEBO_WINDOW_EVENT_FLAGS_OFFSET],NEBO_WINDOW_EVENT_FLAG_PREVENTABLE
 jz .fail
 inc r15d ; close_request_not_closed
 cmp dword [rel records+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_VISIBLE
 jne .fail
 inc r15d ; dispatch_token_matches_event_sequence
 mov rax,[rel event+NEBO_WINDOW_EVENT_SEQUENCE_OFFSET]
 cmp [rel stream+NEBO_HEADLESS_STREAM_DISPATCH_TOKEN_OFFSET],rax
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel template_event]
 call nebo_headless_window_event_prevent_default
 inc r15d ; prevent_wrong_event_pointer
 cmp eax,NEBO_WINDOW_ERROR_NOT_PREVENTABLE
 jne .fail
 inc r15d ; wrong_pointer_did_not_prevent
 test dword [rel event+NEBO_WINDOW_EVENT_FLAGS_OFFSET],NEBO_WINDOW_EVENT_FLAG_PREVENTED
 jnz .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_window_event_prevent_default
 inc r15d ; prevent_default
 test eax,eax
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_event_stream_poll
 inc r15d ; poll_status
 test eax,eax
 jne .fail
 inc r15d ; poll_ready_0
 cmp edx,0
 jne .fail
 inc r15d ; prevented_stays_visible
 cmp dword [rel records+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_VISIBLE
 jne .fail
 lea rdi,[rel template_event]
 mov ecx,NEBO_WINDOW_EVENT_QWORDS
 xor eax,eax
 rep stosq
 mov dword [rel template_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_CLOSE_REQUESTED
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],0
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],0
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],0
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 lea rcx,[rel template_event]
 call nebo_headless_window_push_event
 inc r15d ; push_event
 test eax,eax
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_event_stream_poll
 inc r15d ; poll_status
 test eax,eax
 jne .fail
 inc r15d ; poll_ready_1
 cmp edx,1
 jne .fail
 inc r15d ; poll_kind_NEBO_WINDOW_EVENT_CLOSE_REQUESTED
 cmp dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_CLOSE_REQUESTED
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_event_stream_poll
 inc r15d ; poll_status
 test eax,eax
 jne .fail
 inc r15d ; poll_ready_1
 cmp edx,1
 jne .fail
 inc r15d ; poll_kind_NEBO_WINDOW_EVENT_CLOSED
 cmp dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_CLOSED
 jne .fail
 inc r15d ; default_close_state
 cmp dword [rel records+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_CLOSED
 jne .fail
 inc r15d ; default_close_cleanup1
 cmp qword [rel records+NEBO_WINDOW_CLEANUP_COUNT_OFFSET],1
 jne .fail
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 call nebo_headless_window_close
 inc r15d ; double_close
 cmp eax,NEBO_WINDOW_ERROR_ALREADY_CLOSED
 jne .fail
 lea rdi,[rel stream]
 call nebo_headless_event_stream_release
 inc r15d ; stream_release
 test eax,eax
 jne .fail
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 call nebo_headless_window_reclaim
 inc r15d ; window_reclaim
 test eax,eax
 jne .fail
 inc r15d ; reclaimed_state
 cmp dword [rel records+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_RECLAIMED
 jne .fail
 inc r15d ; active_after_reclaim
 cmp qword [rel runtime+NEBO_HEADLESS_RUNTIME_ACTIVE_COUNT_OFFSET],0
 jne .fail
 lea rdi,[rel runtime]
 mov rsi,[rel old_handle]
 mov rdx,0x1111
 call nebo_headless_window_show
 inc r15d ; old_handle_stale
 cmp eax,NEBO_WINDOW_ERROR_STALE_HANDLE
 jne .fail
 lea rdi,[rel task_group]
 lea rsi,[rel scheduler_budget]
 lea rdx,[rel task_storage]
 mov ecx,1
 call nebo_task_group_init
 inc r15d ; cancel_task_group_init
 test eax,eax
 jne .fail
 lea rdi,[rel cancel_token]
 lea rsi,[rel cancel_budget]
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 call nebo_cancellation_token_init
 inc r15d ; cancel_cancel_token_init
 test eax,eax
 jne .fail
 lea rdi,[rel options]
 mov ecx,NEBO_WINDOW_OPTIONS_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel options+NEBO_WINDOW_OPTIONS_WIDTH_OFFSET],640
 mov qword [rel options+NEBO_WINDOW_OPTIONS_HEIGHT_OFFSET],480
 lea rax,[rel title_initial]
 mov [rel options+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET],rax
 mov qword [rel options+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET],4
 lea rax,[rel title_storage]
 mov [rel options+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET],rax
 mov qword [rel options+NEBO_WINDOW_OPTIONS_TITLE_CAPACITY_OFFSET],256
 lea rax,[rel event_storage]
 mov [rel options+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET],rax
 mov qword [rel options+NEBO_WINDOW_OPTIONS_EVENT_CAPACITY_OFFSET],8
 lea rax,[rel cancel_token]
 mov [rel options+NEBO_WINDOW_OPTIONS_CANCELLATION_PTR_OFFSET],rax
 lea rax,[rel task_group]
 mov [rel options+NEBO_WINDOW_OPTIONS_TASK_GROUP_PTR_OFFSET],rax
 mov dword [rel options+NEBO_WINDOW_OPTIONS_BACKEND_PREFERENCE_OFFSET],0
 mov dword [rel options+NEBO_WINDOW_OPTIONS_FLAGS_OFFSET],15
 mov qword [rel options+NEBO_WINDOW_OPTIONS_OWNER_CONTEXT_OFFSET],0x1111
 lea rdi,[rel runtime]
 lea rsi,[rel options]
 lea rdx,[rel handle]
 call nebo_headless_window_create
 inc r15d ; window_create
 test eax,eax
 jne .fail
 inc r15d ; handle_generation2
 mov rax,0x0000000200000001
 cmp qword [rel handle],rax
 jne .fail
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 lea rcx,[rel stream]
 call nebo_headless_window_events
 inc r15d ; events_acquire
 test eax,eax
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_event_stream_poll
 inc r15d ; poll_status
 test eax,eax
 jne .fail
 inc r15d ; poll_ready_1
 cmp edx,1
 jne .fail
 inc r15d ; poll_kind_NEBO_WINDOW_EVENT_CREATED
 cmp dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_CREATED
 jne .fail
 lea rdi,[rel cancel_token]
 call nebo_cancellation_cancel
 inc r15d ; cancel_token_cancel
 test eax,eax
 jne .fail
 inc r15d ; cancel_first
 cmp edx,1
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 xor edx,edx
 call nebo_headless_event_stream_wait
 inc r15d ; cancel_wait_status
 test eax,eax
 jne .fail
 inc r15d ; cancel_wait_ready
 cmp edx,1
 jne .fail
 inc r15d ; cancel_event
 cmp dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_CANCELLED
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_event_stream_poll
 inc r15d ; poll_status
 test eax,eax
 jne .fail
 inc r15d ; poll_ready_1
 cmp edx,1
 jne .fail
 inc r15d ; poll_kind_NEBO_WINDOW_EVENT_CLOSED
 cmp dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_CLOSED
 jne .fail
 inc r15d ; cancel_cleanup1
 cmp qword [rel records+NEBO_WINDOW_CLEANUP_COUNT_OFFSET],1
 jne .fail
 lea rdi,[rel stream]
 call nebo_headless_event_stream_release
 inc r15d ; stream_release
 test eax,eax
 jne .fail
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 call nebo_headless_window_reclaim
 inc r15d ; window_reclaim
 test eax,eax
 jne .fail
 lea rdi,[rel task_group]
 lea rsi,[rel scheduler_budget]
 lea rdx,[rel task_storage]
 mov ecx,1
 call nebo_task_group_init
 inc r15d ; overflow_task_group_init
 test eax,eax
 jne .fail
 lea rdi,[rel cancel_token]
 lea rsi,[rel cancel_budget]
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 call nebo_cancellation_token_init
 inc r15d ; overflow_cancel_token_init
 test eax,eax
 jne .fail
 lea rdi,[rel options]
 mov ecx,NEBO_WINDOW_OPTIONS_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel options+NEBO_WINDOW_OPTIONS_WIDTH_OFFSET],640
 mov qword [rel options+NEBO_WINDOW_OPTIONS_HEIGHT_OFFSET],480
 lea rax,[rel title_initial]
 mov [rel options+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET],rax
 mov qword [rel options+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET],4
 lea rax,[rel title_storage]
 mov [rel options+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET],rax
 mov qword [rel options+NEBO_WINDOW_OPTIONS_TITLE_CAPACITY_OFFSET],256
 lea rax,[rel event_storage]
 mov [rel options+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET],rax
 mov qword [rel options+NEBO_WINDOW_OPTIONS_EVENT_CAPACITY_OFFSET],4
 lea rax,[rel cancel_token]
 mov [rel options+NEBO_WINDOW_OPTIONS_CANCELLATION_PTR_OFFSET],rax
 lea rax,[rel task_group]
 mov [rel options+NEBO_WINDOW_OPTIONS_TASK_GROUP_PTR_OFFSET],rax
 mov dword [rel options+NEBO_WINDOW_OPTIONS_BACKEND_PREFERENCE_OFFSET],0
 mov dword [rel options+NEBO_WINDOW_OPTIONS_FLAGS_OFFSET],15
 mov qword [rel options+NEBO_WINDOW_OPTIONS_OWNER_CONTEXT_OFFSET],0x1111
 lea rdi,[rel runtime]
 lea rsi,[rel options]
 lea rdx,[rel handle]
 call nebo_headless_window_create
 inc r15d ; window_create
 test eax,eax
 jne .fail
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 lea rcx,[rel stream]
 call nebo_headless_window_events
 inc r15d ; events_acquire
 test eax,eax
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_event_stream_poll
 inc r15d ; poll_status
 test eax,eax
 jne .fail
 inc r15d ; poll_ready_1
 cmp edx,1
 jne .fail
 inc r15d ; poll_kind_NEBO_WINDOW_EVENT_CREATED
 cmp dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_CREATED
 jne .fail
 lea rdi,[rel template_event]
 mov ecx,NEBO_WINDOW_EVENT_QWORDS
 xor eax,eax
 rep stosq
 mov dword [rel template_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_FOCUS_GAINED
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],0
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],0
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],0
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 lea rcx,[rel template_event]
 call nebo_headless_window_push_event
 inc r15d ; push_event
 test eax,eax
 jne .fail
 lea rdi,[rel template_event]
 mov ecx,NEBO_WINDOW_EVENT_QWORDS
 xor eax,eax
 rep stosq
 mov dword [rel template_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_KEY_DOWN
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],66
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],48
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],0
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 lea rcx,[rel template_event]
 call nebo_headless_window_push_event
 inc r15d ; push_event
 test eax,eax
 jne .fail
 lea rdi,[rel template_event]
 mov ecx,NEBO_WINDOW_EVENT_QWORDS
 xor eax,eax
 rep stosq
 mov dword [rel template_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_FOCUS_LOST
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],0
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],0
 mov qword [rel template_event+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],0
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 lea rcx,[rel template_event]
 call nebo_headless_window_push_event
 inc r15d ; push_event_error
 cmp eax,NEBO_WINDOW_ERROR_QUEUE_FULL
 jne .fail
 inc r15d ; overflow_failed_state
 cmp dword [rel records+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_FAILED
 jne .fail
 inc r15d ; overflow_cleanup1
 cmp qword [rel records+NEBO_WINDOW_CLEANUP_COUNT_OFFSET],1
 jne .fail
 inc r15d ; overflow_last_error
 cmp qword [rel records+NEBO_WINDOW_LAST_ERROR_OFFSET],NEBO_WINDOW_ERROR_QUEUE_FULL
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_event_stream_poll
 inc r15d ; poll_status
 test eax,eax
 jne .fail
 inc r15d ; poll_ready_1
 cmp edx,1
 jne .fail
 inc r15d ; poll_kind_NEBO_WINDOW_EVENT_FOCUS_GAINED
 cmp dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_FOCUS_GAINED
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_event_stream_poll
 inc r15d ; poll_status
 test eax,eax
 jne .fail
 inc r15d ; poll_ready_1
 cmp edx,1
 jne .fail
 inc r15d ; poll_kind_NEBO_WINDOW_EVENT_KEY_DOWN
 cmp dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_KEY_DOWN
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_event_stream_poll
 inc r15d ; poll_status
 test eax,eax
 jne .fail
 inc r15d ; poll_ready_1
 cmp edx,1
 jne .fail
 inc r15d ; poll_kind_NEBO_WINDOW_EVENT_QUEUE_OVERFLOW
 cmp dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_QUEUE_OVERFLOW
 jne .fail
 lea rdi,[rel stream]
 call nebo_headless_event_stream_release
 inc r15d ; stream_release
 test eax,eax
 jne .fail
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 call nebo_headless_window_reclaim
 inc r15d ; window_reclaim
 test eax,eax
 jne .fail
 lea rdi,[rel task_group]
 lea rsi,[rel scheduler_budget]
 lea rdx,[rel task_storage]
 mov ecx,1
 call nebo_task_group_init
 inc r15d ; sequence_task_group_init
 test eax,eax
 jne .fail
 lea rdi,[rel cancel_token]
 lea rsi,[rel cancel_budget]
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 call nebo_cancellation_token_init
 inc r15d ; sequence_cancel_token_init
 test eax,eax
 jne .fail
 lea rdi,[rel options]
 mov ecx,NEBO_WINDOW_OPTIONS_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel options+NEBO_WINDOW_OPTIONS_WIDTH_OFFSET],640
 mov qword [rel options+NEBO_WINDOW_OPTIONS_HEIGHT_OFFSET],480
 lea rax,[rel title_initial]
 mov [rel options+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET],rax
 mov qword [rel options+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET],4
 lea rax,[rel title_storage]
 mov [rel options+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET],rax
 mov qword [rel options+NEBO_WINDOW_OPTIONS_TITLE_CAPACITY_OFFSET],256
 lea rax,[rel event_storage]
 mov [rel options+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET],rax
 mov qword [rel options+NEBO_WINDOW_OPTIONS_EVENT_CAPACITY_OFFSET],8
 lea rax,[rel cancel_token]
 mov [rel options+NEBO_WINDOW_OPTIONS_CANCELLATION_PTR_OFFSET],rax
 lea rax,[rel task_group]
 mov [rel options+NEBO_WINDOW_OPTIONS_TASK_GROUP_PTR_OFFSET],rax
 mov dword [rel options+NEBO_WINDOW_OPTIONS_BACKEND_PREFERENCE_OFFSET],0
 mov dword [rel options+NEBO_WINDOW_OPTIONS_FLAGS_OFFSET],15
 mov qword [rel options+NEBO_WINDOW_OPTIONS_OWNER_CONTEXT_OFFSET],0x1111
 lea rdi,[rel runtime]
 lea rsi,[rel options]
 lea rdx,[rel handle]
 call nebo_headless_window_create
 inc r15d ; window_create
 test eax,eax
 jne .fail
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 lea rcx,[rel stream]
 call nebo_headless_window_events
 inc r15d ; events_acquire
 test eax,eax
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_event_stream_poll
 inc r15d ; poll_status
 test eax,eax
 jne .fail
 inc r15d ; poll_ready_1
 cmp edx,1
 jne .fail
 inc r15d ; poll_kind_NEBO_WINDOW_EVENT_CREATED
 cmp dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_CREATED
 jne .fail
 mov qword [rel records+NEBO_WINDOW_NEXT_EVENT_SEQUENCE_OFFSET],-1
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 call nebo_headless_window_show
 inc r15d ; sequence_exhaustion
 cmp eax,NEBO_WINDOW_ERROR_SEQUENCE_EXHAUSTED
 jne .fail
 inc r15d ; sequence_state_atomic
 cmp dword [rel records+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_CREATED
 jne .fail
 inc r15d ; sequence_queue_atomic
 cmp qword [rel records+NEBO_WINDOW_EVENT_COUNT_OFFSET],0
 jne .fail
 mov qword [rel records+NEBO_WINDOW_NEXT_EVENT_SEQUENCE_OFFSET],1
 mov qword [rel runtime+NEBO_HEADLESS_RUNTIME_LOGICAL_CLOCK_OFFSET],-1
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 call nebo_headless_window_close
 inc r15d ; close_clock_exhaustion
 cmp eax,NEBO_WINDOW_ERROR_SEQUENCE_EXHAUSTED
 jne .fail
 inc r15d ; close_clock_state_atomic
 cmp dword [rel records+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_CREATED
 jne .fail
 inc r15d ; close_clock_cleanup_atomic
 cmp qword [rel records+NEBO_WINDOW_CLEANUP_COUNT_OFFSET],0
 jne .fail
 inc r15d ; close_clock_queue_atomic
 cmp qword [rel records+NEBO_WINDOW_EVENT_COUNT_OFFSET],0
 jne .fail
 mov qword [rel runtime+NEBO_HEADLESS_RUNTIME_LOGICAL_CLOCK_OFFSET],1
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 call nebo_headless_window_close
 inc r15d ; sequence_cleanup_close
 test eax,eax
 jne .fail
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_event_stream_poll
 inc r15d ; poll_status
 test eax,eax
 jne .fail
 inc r15d ; poll_ready_1
 cmp edx,1
 jne .fail
 inc r15d ; poll_kind_NEBO_WINDOW_EVENT_CLOSED
 cmp dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_CLOSED
 jne .fail
 lea rdi,[rel stream]
 call nebo_headless_event_stream_release
 inc r15d ; stream_release
 test eax,eax
 jne .fail
 lea rdi,[rel runtime]
 mov rsi,[rel handle]
 mov rdx,0x1111
 call nebo_headless_window_reclaim
 inc r15d ; window_reclaim
 test eax,eax
 jne .fail
 lea rdi,[rel task_group]
 lea rsi,[rel scheduler_budget]
 lea rdx,[rel task_storage]
 mov ecx,1
 call nebo_task_group_init
 inc r15d ; clock_task_group_init
 test eax,eax
 jne .fail
 lea rdi,[rel cancel_token]
 lea rsi,[rel cancel_budget]
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 call nebo_cancellation_token_init
 inc r15d ; clock_cancel_token_init
 test eax,eax
 jne .fail
 lea rdi,[rel options]
 mov ecx,NEBO_WINDOW_OPTIONS_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel options+NEBO_WINDOW_OPTIONS_WIDTH_OFFSET],640
 mov qword [rel options+NEBO_WINDOW_OPTIONS_HEIGHT_OFFSET],480
 lea rax,[rel title_initial]
 mov [rel options+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET],rax
 mov qword [rel options+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET],4
 lea rax,[rel title_storage]
 mov [rel options+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET],rax
 mov qword [rel options+NEBO_WINDOW_OPTIONS_TITLE_CAPACITY_OFFSET],256
 lea rax,[rel event_storage]
 mov [rel options+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET],rax
 mov qword [rel options+NEBO_WINDOW_OPTIONS_EVENT_CAPACITY_OFFSET],8
 lea rax,[rel cancel_token]
 mov [rel options+NEBO_WINDOW_OPTIONS_CANCELLATION_PTR_OFFSET],rax
 lea rax,[rel task_group]
 mov [rel options+NEBO_WINDOW_OPTIONS_TASK_GROUP_PTR_OFFSET],rax
 mov dword [rel options+NEBO_WINDOW_OPTIONS_BACKEND_PREFERENCE_OFFSET],0
 mov dword [rel options+NEBO_WINDOW_OPTIONS_FLAGS_OFFSET],15
 mov qword [rel options+NEBO_WINDOW_OPTIONS_OWNER_CONTEXT_OFFSET],0x1111
 mov qword [rel runtime+NEBO_HEADLESS_RUNTIME_LOGICAL_CLOCK_OFFSET],-1
 mov rax,0x0000000088776655
 mov qword [rel handle],rax
 lea rdi,[rel runtime]
 lea rsi,[rel options]
 lea rdx,[rel handle]
 call nebo_headless_window_create
 inc r15d ; window_create_error
 cmp eax,NEBO_WINDOW_ERROR_SEQUENCE_EXHAUSTED
 jne .fail
 inc r15d ; clock_out_atomic
 mov rax,0x0000000088776655
 cmp qword [rel handle],rax
 jne .fail
 inc r15d ; clock_active_atomic
 cmp qword [rel runtime+NEBO_HEADLESS_RUNTIME_ACTIVE_COUNT_OFFSET],0
 jne .fail
 lea rdi,[rel event]
 mov ecx,NEBO_WINDOW_EVENT_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel event+NEBO_WINDOW_EVENT_SEQUENCE_OFFSET],1
 mov rax,0x0000000100000001
 mov qword [rel event+NEBO_WINDOW_EVENT_HANDLE_OFFSET],rax
 mov qword [rel event+NEBO_WINDOW_EVENT_TIMESTAMP_OFFSET],1
 mov dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_KEY_DOWN
 lea rdi,[rel event]
 call nebo_headless_window_event_kind
 inc r15d ; malformed_origin_rejected
 cmp eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 jne .fail
 or dword [rel event+NEBO_WINDOW_EVENT_FLAGS_OFFSET],NEBO_WINDOW_EVENT_FLAG_SYNTHETIC
 mov dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_TEXT_INPUT
 mov qword [rel event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],233
 mov qword [rel event+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],2
 mov qword [rel event+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],0x80c3
 lea rdi,[rel event]
 call nebo_headless_window_event_text_input
 inc r15d ; malformed_text_bytes_rejected
 cmp eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 jne .fail
 mov dword [rel event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_SHOWN
 lea rdi,[rel stream]
 lea rsi,[rel event]
 call nebo_headless_window_event_prevent_default
 inc r15d ; prevent_without_active_dispatch
 cmp eax,NEBO_WINDOW_ERROR_NOT_PREVENTABLE
 jne .fail
 xor edi,edi
 jmp .exit
.fail:
 mov edi,r15d
.exit:
 mov eax,60
 syscall
