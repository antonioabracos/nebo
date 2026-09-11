bits 64
default rel
%include "runtime/window/window_contract.inc"

; Assembly-time ABI/layout guards.
%if NEBO_WINDOW_OPTIONS_SIZE != 96
%error WindowOptions_size
%endif
%if NEBO_WINDOW_OPTIONS_OWNER_CONTEXT_OFFSET != 88
%error WindowOptions_last_offset
%endif
%if NEBO_WINDOW_SIZE != 192
%error Window_size
%endif
%if NEBO_WINDOW_RESERVED_OFFSET != 184
%error Window_last_offset
%endif
%if NEBO_WINDOW_EVENT_SIZE != 64
%error WindowEvent_size
%endif
%if NEBO_WINDOW_EVENT_RESERVED_OFFSET != 56
%error WindowEvent_last_offset
%endif
%if NEBO_WINDOW_MAX_WINDOWS != 16
%error Window_limit
%endif
%if NEBO_WINDOW_MAX_EVENTS != 4096
%error Event_limit
%endif
%if NEBO_WINDOW_MAX_WIDTH != 2048
%error Width_limit
%endif
%if NEBO_WINDOW_MAX_HEIGHT != 2048
%error Height_limit
%endif
%if NEBO_WINDOW_TERMINAL_EVENT_RESERVE != 2
%error Terminal_reserve
%endif
%if NEBO_WINDOW_EVENT_KIND_COUNT != 20
%error Event_kind_count
%endif
%if NEBO_WINDOW_ERROR_COUNT != 17
%error Error_count
%endif
%if NEBO_WINDOW_REQUIRED_CAPABILITIES != 255
%error Backend_capabilities
%endif

section .text
global _start
_start:
 ; 1-4: handle pack/unpack and invalid-zero rules.
 mov eax,7
 shl rax,NEBO_WINDOW_HANDLE_GENERATION_SHIFT
 or rax,16
 mov rbx,rax
 and eax,NEBO_WINDOW_HANDLE_SLOT_MASK
 cmp eax,16
 jne .fail1
 mov rax,rbx
 shr rax,NEBO_WINDOW_HANDLE_GENERATION_SHIFT
 cmp eax,7
 jne .fail2
 test rbx,rbx
 jz .fail3
 cmp qword [rel invalid_handle],NEBO_WINDOW_HANDLE_INVALID
 jne .fail4

 ; 5-10: bounded dimensions, title and queue profile.
 cmp qword [rel max_width],NEBO_WINDOW_MAX_WIDTH
 jne .fail5
 cmp qword [rel max_height],NEBO_WINDOW_MAX_HEIGHT
 jne .fail6
 cmp qword [rel max_title],NEBO_WINDOW_MAX_TITLE_BYTES
 jne .fail7
 mov rax,NEBO_WINDOW_MIN_EVENT_CAPACITY
 sub rax,NEBO_WINDOW_TERMINAL_EVENT_RESERVE
 cmp rax,2
 jne .fail8
 mov rax,NEBO_WINDOW_MAX_EVENTS
 sub rax,NEBO_WINDOW_TERMINAL_EVENT_RESERVE
 cmp rax,4094
 jne .fail9
 cmp qword [rel max_windows],16
 jne .fail10

 ; 11-18: state and backend identities remain distinct and bounded.
 cmp dword [rel state_created],NEBO_WINDOW_STATE_CREATED
 jne .fail11
 cmp dword [rel state_visible],NEBO_WINDOW_STATE_VISIBLE
 jne .fail12
 cmp dword [rel state_hidden],NEBO_WINDOW_STATE_HIDDEN
 jne .fail13
 cmp dword [rel state_closing],NEBO_WINDOW_STATE_CLOSING
 jne .fail14
 cmp dword [rel state_closed],NEBO_WINDOW_STATE_CLOSED
 jne .fail15
 cmp dword [rel state_failed],NEBO_WINDOW_STATE_FAILED
 jne .fail16
 cmp dword [rel backend_headless],NEBO_WINDOW_BACKEND_HEADLESS
 jne .fail17
 cmp dword [rel backend_x11],NEBO_WINDOW_BACKEND_X11_DIRECT
 jne .fail18

 ; 19-25: typed event identities and flags.
 cmp dword [rel event_close],NEBO_WINDOW_EVENT_CLOSE_REQUESTED
 jne .fail19
 cmp dword [rel event_cancel],NEBO_WINDOW_EVENT_CANCELLED
 jne .fail20
 cmp dword [rel event_closed],NEBO_WINDOW_EVENT_CLOSED
 jne .fail21
 cmp dword [rel event_backend_failed],NEBO_WINDOW_EVENT_BACKEND_FAILED
 jne .fail22
 cmp dword [rel event_overflow],NEBO_WINDOW_EVENT_QUEUE_OVERFLOW
 jne .fail23
 mov eax,NEBO_WINDOW_EVENT_FLAG_PREVENTABLE
 or eax,NEBO_WINDOW_EVENT_FLAG_NATIVE
 cmp eax,5
 jne .fail24
 test dword [rel event_terminal_flags],NEBO_WINDOW_EVENT_FLAG_TERMINAL
 jz .fail25

 ; 26-32: stable failure and structured-scope identities.
 cmp dword [rel error_bad_state],NEBO_WINDOW_ERROR_BAD_STATE
 jne .fail26
 cmp dword [rel error_queue_full],NEBO_WINDOW_ERROR_QUEUE_FULL
 jne .fail27
 cmp dword [rel error_already_closed],NEBO_WINDOW_ERROR_ALREADY_CLOSED
 jne .fail28
 cmp dword [rel error_cancelled],NEBO_WINDOW_ERROR_CANCELLED
 jne .fail29
 cmp dword [rel error_owner],NEBO_WINDOW_ERROR_OWNER_MISMATCH
 jne .fail30
 cmp dword [rel error_task_group],NEBO_WINDOW_ERROR_TASK_GROUP_REQUIRED
 jne .fail31
 cmp dword [rel error_cancel_token],NEBO_WINDOW_ERROR_CANCELLATION_REQUIRED
 jne .fail32

 xor edi,edi
 jmp .exit
%assign i 1
%rep 32
.fail%+i:
 mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall

section .rodata
align 8
invalid_handle dq 0
max_width dq 2048
max_height dq 2048
max_title dq 256
max_windows dq 16
state_created dd 1
state_visible dd 2
state_hidden dd 3
state_closing dd 4
state_closed dd 5
state_failed dd 6
backend_headless dd 1
backend_x11 dd 2
event_close dd 15
event_cancel dd 16
event_closed dd 17
event_backend_failed dd 18
event_overflow dd 19
event_terminal_flags dd 16
error_bad_state dd 2
error_queue_full dd 4
error_already_closed dd 5
error_cancelled dd 6
error_owner dd 10
error_task_group dd 15
error_cancel_token dd 16
