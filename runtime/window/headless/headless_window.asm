bits 64
default rel
%define NEBO_HEADLESS_WINDOW_IMPLEMENTATION 1
%include "runtime/window/headless/headless_window.inc"

%define EINTR 4
%define EAGAIN 11
%define ETIMEDOUT 110

section .text
global nebo_headless_runtime_init
global nebo_headless_window_create
global nebo_headless_window_show
global nebo_headless_window_hide
global nebo_headless_window_resize
global nebo_headless_window_set_title
global nebo_headless_window_request_redraw
global nebo_headless_window_close
global nebo_headless_window_events
global nebo_headless_event_stream_poll
global nebo_headless_event_stream_wait
global nebo_headless_event_stream_release
global nebo_headless_window_reclaim
global nebo_headless_window_push_event
global nebo_headless_window_event_kind
global nebo_headless_window_event_key
global nebo_headless_window_event_pointer
global nebo_headless_window_event_text_input
global nebo_headless_window_event_resize
global nebo_headless_window_event_prevent_default
global nebo_headless_window_backend_close

; ---------------------------------------------------------------------------
; Internal helpers
; ---------------------------------------------------------------------------

; rdi=runtime, rsi=handle, rdx=owner (zero skips owner check)
; rax=record on success, ecx=WindowError (zero on success).
headless_resolve:
 xor ecx,ecx
 test rdi,rdi
 jz .invalid
 mov rax,NEBO_HEADLESS_RUNTIME_MAGIC
 cmp qword [rdi+NEBO_HEADLESS_RUNTIME_MAGIC_OFFSET],rax
 jne .invalid
 test rsi,rsi
 jz .stale
 mov r8,[rdi+NEBO_HEADLESS_RUNTIME_RECORDS_PTR_OFFSET]
 test r8,r8
 jz .invalid
 mov r9,[rdi+NEBO_HEADLESS_RUNTIME_CAPACITY_OFFSET]
 test r9,r9
 jz .invalid
 mov eax,esi
 test rax,rax
 jz .stale
 cmp rax,r9
 ja .stale
 dec rax
 imul rax,NEBO_WINDOW_SIZE
 add rax,r8
 cmp qword [rax+NEBO_WINDOW_HANDLE_OFFSET],rsi
 jne .stale
 mov r8d,[rax+NEBO_WINDOW_STATE_OFFSET]
 cmp r8d,NEBO_WINDOW_STATE_EMPTY
 je .stale
 cmp r8d,NEBO_WINDOW_STATE_RECLAIMED
 je .stale
 test rdx,rdx
 jz .ok
 cmp qword [rax+NEBO_WINDOW_OWNER_CONTEXT_OFFSET],rdx
 jne .owner
.ok:
 ret
.invalid:
 mov ecx,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 xor eax,eax
 ret
.stale:
 mov ecx,NEBO_WINDOW_ERROR_STALE_HANDLE
 xor eax,eax
 ret
.owner:
 mov ecx,NEBO_WINDOW_ERROR_OWNER_MISMATCH
 xor eax,eax
 ret

; rdi=destination, rsi=source, rdx=length. Bounded memmove.
headless_memmove:
 test rdx,rdx
 jz .done
 cmp rdi,rsi
 je .done
 mov rcx,rdx
 cmp rdi,rsi
 jb .forward
 lea rax,[rsi+rdx]
 cmp rdi,rax
 jae .forward
 lea rsi,[rsi+rdx-1]
 lea rdi,[rdi+rdx-1]
 std
 rep movsb
 cld
 ret
.forward:
 cld
 rep movsb
.done:
 ret

; rdi=bytes, rsi=length. Strict canonical scalar UTF-8; eax=0 or invalid.
headless_validate_utf8:
 test rsi,rsi
 jz .ok
 test rdi,rdi
 jz .invalid
 xor ecx,ecx
.loop:
 cmp rcx,rsi
 jae .ok
 movzx eax,byte [rdi+rcx]
 inc rcx
 cmp eax,0x80
 jb .loop
 cmp eax,0xc2
 jb .invalid
 cmp eax,0xdf
 jbe .two
 cmp eax,0xef
 jbe .three
 cmp eax,0xf4
 jbe .four
 jmp .invalid
.two:
 cmp rcx,rsi
 jae .invalid
 movzx edx,byte [rdi+rcx]
 and edx,0xc0
 cmp edx,0x80
 jne .invalid
 inc rcx
 jmp .loop
.three:
 mov r8d,eax
 lea r9,[rcx+2]
 cmp r9,rsi
 ja .invalid
 movzx edx,byte [rdi+rcx]
 cmp r8d,0xe0
 jne .three_not_e0
 cmp edx,0xa0
 jb .invalid
.three_not_e0:
 cmp r8d,0xed
 jne .three_second
 cmp edx,0x9f
 ja .invalid
.three_second:
 and edx,0xc0
 cmp edx,0x80
 jne .invalid
 movzx edx,byte [rdi+rcx+1]
 and edx,0xc0
 cmp edx,0x80
 jne .invalid
 add rcx,2
 jmp .loop
.four:
 mov r8d,eax
 lea r9,[rcx+3]
 cmp r9,rsi
 ja .invalid
 movzx edx,byte [rdi+rcx]
 cmp r8d,0xf0
 jne .four_not_f0
 cmp edx,0x90
 jb .invalid
.four_not_f0:
 cmp r8d,0xf4
 jne .four_second
 cmp edx,0x8f
 ja .invalid
.four_second:
 and edx,0xc0
 cmp edx,0x80
 jne .invalid
 movzx edx,byte [rdi+rcx+1]
 and edx,0xc0
 cmp edx,0x80
 jne .invalid
 movzx edx,byte [rdi+rcx+2]
 and edx,0xc0
 cmp edx,0x80
 jne .invalid
 add rcx,3
 jmp .loop
.ok:
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 ret

; Half-open range overlap with checked ends.
; rdi=a pointer, rsi=a length, rdx=b pointer, rcx=b length.
; eax=0 disjoint, 1 overlap, 2 pointer overflow.
headless_ranges_overlap:
 test rsi,rsi
 jz .disjoint
 test rcx,rcx
 jz .disjoint
 mov r8,rdi
 add r8,rsi
 jc .overflow
 mov r9,rdx
 add r9,rcx
 jc .overflow
 cmp rdi,r9
 jae .disjoint
 cmp rdx,r8
 jae .disjoint
 mov eax,1
 ret
.disjoint:
 xor eax,eax
 ret
.overflow:
 mov eax,2
 ret

; rdi=runtime, rsi=WindowOptions, rdx=out handle.
; Enforce exclusive caller-owned storage before any record/storage mutation.
headless_validate_create_ranges:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,72
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rax,[r12+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET]
 mov [rsp+0],rax
 mov rax,[r12+NEBO_WINDOW_OPTIONS_TITLE_CAPACITY_OFFSET]
 mov [rsp+8],rax
 mov rax,[r12+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET]
 mov [rsp+16],rax
 mov rax,[r12+NEBO_WINDOW_OPTIONS_EVENT_CAPACITY_OFFSET]
 shl rax,6
 mov [rsp+24],rax
 mov rax,[rbx+NEBO_HEADLESS_RUNTIME_RECORDS_PTR_OFFSET]
 mov [rsp+32],rax
 mov rax,[rbx+NEBO_HEADLESS_RUNTIME_CAPACITY_OFFSET]
 imul rax,NEBO_WINDOW_SIZE
 mov [rsp+40],rax
 mov rax,[r12+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET]
 mov [rsp+48],rax
 mov rax,[r12+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET]
 mov [rsp+56],rax

 ; Options and output must not alias runtime state or record storage.
 mov rdi,r12
 mov esi,NEBO_WINDOW_OPTIONS_SIZE
 mov rdx,rbx
 mov ecx,NEBO_HEADLESS_RUNTIME_SIZE
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid
 mov rdi,r12
 mov esi,NEBO_WINDOW_OPTIONS_SIZE
 mov rdx,[rsp+32]
 mov rcx,[rsp+40]
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid
 mov rdi,r13
 mov esi,NEBO_WINDOW_HANDLE_SIZE
 mov rdx,rbx
 mov ecx,NEBO_HEADLESS_RUNTIME_SIZE
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid
 mov rdi,r13
 mov esi,NEBO_WINDOW_HANDLE_SIZE
 mov rdx,[rsp+32]
 mov rcx,[rsp+40]
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid
 mov rdi,r12
 mov esi,NEBO_WINDOW_OPTIONS_SIZE
 mov rdx,r13
 mov ecx,NEBO_WINDOW_HANDLE_SIZE
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid

 ; New title/event storage is disjoint from descriptors and each other.
 mov rdi,[rsp+0]
 mov rsi,[rsp+8]
 mov rdx,[rsp+16]
 mov rcx,[rsp+24]
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid
 mov rdi,[rsp+0]
 mov rsi,[rsp+8]
 mov rdx,rbx
 mov ecx,NEBO_HEADLESS_RUNTIME_SIZE
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid
 mov rdi,[rsp+0]
 mov rsi,[rsp+8]
 mov rdx,[rsp+32]
 mov rcx,[rsp+40]
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid
 mov rdi,[rsp+16]
 mov rsi,[rsp+24]
 mov rdx,rbx
 mov ecx,NEBO_HEADLESS_RUNTIME_SIZE
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid
 mov rdi,[rsp+16]
 mov rsi,[rsp+24]
 mov rdx,[rsp+32]
 mov rcx,[rsp+40]
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid
 mov rdi,[rsp+0]
 mov rsi,[rsp+8]
 mov rdx,r12
 mov ecx,NEBO_WINDOW_OPTIONS_SIZE
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid
 mov rdi,[rsp+16]
 mov rsi,[rsp+24]
 mov rdx,r12
 mov ecx,NEBO_WINDOW_OPTIONS_SIZE
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid
 mov rdi,[rsp+0]
 mov rsi,[rsp+8]
 mov rdx,r13
 mov ecx,NEBO_WINDOW_HANDLE_SIZE
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid
 mov rdi,[rsp+16]
 mov rsi,[rsp+24]
 mov rdx,r13
 mov ecx,NEBO_WINDOW_HANDLE_SIZE
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid

 ; The initial title source is read after the destination record is cleared.
 mov rdi,[rsp+48]
 mov rsi,[rsp+56]
 mov rdx,rbx
 mov ecx,NEBO_HEADLESS_RUNTIME_SIZE
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid
 mov rdi,[rsp+48]
 mov rsi,[rsp+56]
 mov rdx,[rsp+32]
 mov rcx,[rsp+40]
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid

 ; Active/terminal-unreclaimed Windows retain exclusive storage borrows.
 mov r14,[rsp+32]
 mov r15,[rbx+NEBO_HEADLESS_RUNTIME_CAPACITY_OFFSET]
.scan:
 test r15,r15
 jz .ok
 mov eax,[r14+NEBO_WINDOW_STATE_OFFSET]
 cmp eax,NEBO_WINDOW_STATE_EMPTY
 je .next
 cmp eax,NEBO_WINDOW_STATE_RECLAIMED
 je .next
 mov rdi,[rsp+0]
 mov rsi,[rsp+8]
 mov rdx,[r14+NEBO_WINDOW_TITLE_PTR_OFFSET]
 mov rcx,[r14+NEBO_WINDOW_TITLE_CAPACITY_OFFSET]
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid
 mov rdi,[rsp+0]
 mov rsi,[rsp+8]
 mov rdx,[r14+NEBO_WINDOW_EVENT_STORAGE_PTR_OFFSET]
 mov rcx,[r14+NEBO_WINDOW_EVENT_CAPACITY_OFFSET]
 shl rcx,6
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid
 mov rdi,[rsp+16]
 mov rsi,[rsp+24]
 mov rdx,[r14+NEBO_WINDOW_TITLE_PTR_OFFSET]
 mov rcx,[r14+NEBO_WINDOW_TITLE_CAPACITY_OFFSET]
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid
 mov rdi,[rsp+16]
 mov rsi,[rsp+24]
 mov rdx,[r14+NEBO_WINDOW_EVENT_STORAGE_PTR_OFFSET]
 mov rcx,[r14+NEBO_WINDOW_EVENT_CAPACITY_OFFSET]
 shl rcx,6
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid
.next:
 add r14,NEBO_WINDOW_SIZE
 dec r15
 jmp .scan
.ok:
 xor eax,eax
 jmp .return
.invalid:
 mov eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
.return:
 add rsp,72
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

; rdi=runtime, rsi=record, edx=kind, ecx=flags,
; r8=payload0, r9=payload1, r11=payload2. eax=WindowError.
headless_enqueue:
 push rbx
 push r12
 push r13
 mov r12,r11
 mov rax,[rsi+NEBO_WINDOW_NEXT_EVENT_SEQUENCE_OFFSET]
 cmp rax,-1
 je .sequence
 mov r13,[rdi+NEBO_HEADLESS_RUNTIME_LOGICAL_CLOCK_OFFSET]
 cmp r13,-1
 je .sequence
 mov r10,[rsi+NEBO_WINDOW_EVENT_COUNT_OFFSET]
 mov r11,[rsi+NEBO_WINDOW_EVENT_CAPACITY_OFFSET]
 test ecx,NEBO_WINDOW_EVENT_FLAG_TERMINAL
 jnz .terminal_capacity
 sub r11,NEBO_WINDOW_TERMINAL_EVENT_RESERVE
 cmp r10,r11
 jae .full
 jmp .capacity_ok
.terminal_capacity:
 mov r11,[rsi+NEBO_WINDOW_EVENT_CAPACITY_OFFSET]
 cmp r10,r11
 jae .full
.capacity_ok:
 inc rax
 inc r13
 mov r10,[rsi+NEBO_WINDOW_EVENT_TAIL_OFFSET]
 shl r10,6
 add r10,[rsi+NEBO_WINDOW_EVENT_STORAGE_PTR_OFFSET]
 mov rbx,r10
 mov [rbx+NEBO_WINDOW_EVENT_SEQUENCE_OFFSET],rax
 mov r10,[rsi+NEBO_WINDOW_HANDLE_OFFSET]
 mov [rbx+NEBO_WINDOW_EVENT_HANDLE_OFFSET],r10
 mov [rbx+NEBO_WINDOW_EVENT_KIND_OFFSET],edx
 mov [rbx+NEBO_WINDOW_EVENT_FLAGS_OFFSET],ecx
 mov [rbx+NEBO_WINDOW_EVENT_TIMESTAMP_OFFSET],r13
 mov [rbx+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],r8
 mov [rbx+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],r9
 mov [rbx+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],r12
 mov qword [rbx+NEBO_WINDOW_EVENT_RESERVED_OFFSET],0
 mov [rsi+NEBO_WINDOW_NEXT_EVENT_SEQUENCE_OFFSET],rax
 mov [rdi+NEBO_HEADLESS_RUNTIME_LOGICAL_CLOCK_OFFSET],r13
 inc qword [rdi+NEBO_HEADLESS_RUNTIME_WAKE_GENERATION_OFFSET]
 mov rax,[rsi+NEBO_WINDOW_EVENT_TAIL_OFFSET]
 inc rax
 cmp rax,[rsi+NEBO_WINDOW_EVENT_CAPACITY_OFFSET]
 jb .tail_store
 xor eax,eax
.tail_store:
 mov [rsi+NEBO_WINDOW_EVENT_TAIL_OFFSET],rax
 inc qword [rsi+NEBO_WINDOW_EVENT_COUNT_OFFSET]
 mov eax,NEBO_LINUX_X86_64_SYS_FUTEX
 lea rdi,[rsi+NEBO_WINDOW_NEXT_EVENT_SEQUENCE_OFFSET]
 mov esi,NEBO_FUTEX_WAKE_PRIVATE
 mov edx,0x7fffffff
 xor r10d,r10d
 xor r8d,r8d
 xor r9d,r9d
 syscall
 xor eax,eax
 jmp .return
.sequence:
 mov eax,NEBO_WINDOW_ERROR_SEQUENCE_EXHAUSTED
 jmp .return
.full:
 mov eax,NEBO_WINDOW_ERROR_QUEUE_FULL
.return:
 pop r13
 pop r12
 pop rbx
 ret

; rdi=record, rsi=out event. eax=status, edx=ready.
headless_dequeue:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rsi,7
 jnz .invalid
 cmp qword [rdi+NEBO_WINDOW_EVENT_COUNT_OFFSET],0
 je .empty
 mov rax,[rdi+NEBO_WINDOW_EVENT_HEAD_OFFSET]
 cmp rax,[rdi+NEBO_WINDOW_EVENT_CAPACITY_OFFSET]
 jae .state
 shl rax,6
 add rax,[rdi+NEBO_WINDOW_EVENT_STORAGE_PTR_OFFSET]
 mov r8,rax
 mov rax,[r8+0]
 mov [rsi+0],rax
 mov rax,[r8+8]
 mov [rsi+8],rax
 mov eax,[r8+16]
 mov [rsi+16],eax
 mov ecx,[r8+20]
 mov [rsi+20],ecx
 mov rax,[r8+24]
 mov [rsi+24],rax
 mov rax,[r8+32]
 mov [rsi+32],rax
 mov rax,[r8+40]
 mov [rsi+40],rax
 mov rax,[r8+48]
 mov [rsi+48],rax
 mov rax,[r8+56]
 mov [rsi+56],rax
 cmp dword [r8+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_REDRAW_REQUESTED
 jne .not_redraw
 and dword [rdi+NEBO_WINDOW_FLAGS_OFFSET],~NEBO_HEADLESS_FLAG_REDRAW_PENDING
.not_redraw:
 mov qword [r8+0],0
 mov qword [r8+8],0
 mov qword [r8+16],0
 mov qword [r8+24],0
 mov qword [r8+32],0
 mov qword [r8+40],0
 mov qword [r8+48],0
 mov qword [r8+56],0
 mov rax,[rdi+NEBO_WINDOW_EVENT_HEAD_OFFSET]
 inc rax
 cmp rax,[rdi+NEBO_WINDOW_EVENT_CAPACITY_OFFSET]
 jb .head_store
 xor eax,eax
.head_store:
 mov [rdi+NEBO_WINDOW_EVENT_HEAD_OFFSET],rax
 dec qword [rdi+NEBO_WINDOW_EVENT_COUNT_OFFSET]
 mov edx,1
 xor eax,eax
 ret
.empty:
 xor edx,edx
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 xor edx,edx
 ret
.state:
 mov eax,NEBO_WINDOW_ERROR_BAD_STATE
 xor edx,edx
 ret

; rdi=runtime, rsi=record, edx=reason, rcx=detail. eax=WindowError.
headless_close_barrier:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13d,edx
 mov r14,rcx
 mov eax,[r12+NEBO_WINDOW_STATE_OFFSET]
 cmp eax,NEBO_WINDOW_STATE_CLOSING
 je .already
 cmp eax,NEBO_WINDOW_STATE_CLOSED
 je .already
 cmp eax,NEBO_WINDOW_STATE_FAILED
 je .already
 cmp eax,NEBO_WINDOW_STATE_CREATED
 je .state_ok
 cmp eax,NEBO_WINDOW_STATE_VISIBLE
 je .state_ok
 cmp eax,NEBO_WINDOW_STATE_HIDDEN
 jne .bad_state
.state_ok:
 cmp qword [r12+NEBO_WINDOW_CLEANUP_COUNT_OFFSET],0
 jne .already
 mov r15d,1
 cmp r13d,NEBO_HEADLESS_CLOSE_CANCELLED
 jne .required_known
 mov r15d,2
.required_known:
 mov rax,[r12+NEBO_WINDOW_EVENT_COUNT_OFFSET]
 add rax,r15
 jc .queue_full
 cmp rax,[r12+NEBO_WINDOW_EVENT_CAPACITY_OFFSET]
 ja .queue_full
 mov rcx,-1
 sub rcx,r15
 mov rax,[r12+NEBO_WINDOW_NEXT_EVENT_SEQUENCE_OFFSET]
 cmp rax,rcx
 ja .sequence
 mov rax,[rbx+NEBO_HEADLESS_RUNTIME_LOGICAL_CLOCK_OFFSET]
 cmp rax,rcx
 ja .sequence
 and dword [r12+NEBO_WINDOW_FLAGS_OFFSET],~(NEBO_HEADLESS_FLAG_ACCEPTING_EVENTS | NEBO_HEADLESS_FLAG_REDRAW_PENDING)
 cmp r13d,NEBO_HEADLESS_CLOSE_BACKEND_FAILED
 je .terminal_failure_state
 cmp r13d,NEBO_HEADLESS_CLOSE_QUEUE_OVERFLOW
 je .terminal_failure_state
 mov dword [r12+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_CLOSING
 cmp r13d,NEBO_HEADLESS_CLOSE_CANCELLED
 jne .join
 mov rdi,rbx
 mov rsi,r12
 mov edx,NEBO_WINDOW_EVENT_CANCELLED
 mov ecx,NEBO_WINDOW_EVENT_FLAG_SYNTHETIC | NEBO_WINDOW_EVENT_FLAG_TERMINAL
 mov r8,r14
 xor r9d,r9d
 xor r11d,r11d
 call headless_enqueue
 test eax,eax
 jnz .return
 jmp .join
.terminal_failure_state:
 mov dword [r12+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_CLOSING
.join:
 mov rdi,[r12+NEBO_WINDOW_TASK_GROUP_PTR_OFFSET]
 call nebo_task_group_join_all
 mov [r12+NEBO_WINDOW_LAST_STATUS_OFFSET],rax
 mov qword [r12+NEBO_WINDOW_TITLE_PTR_OFFSET],0
 mov qword [r12+NEBO_WINDOW_TITLE_LENGTH_OFFSET],0
 mov qword [r12+NEBO_WINDOW_TITLE_CAPACITY_OFFSET],0
 mov qword [r12+NEBO_WINDOW_CANCELLATION_PTR_OFFSET],0
 mov qword [r12+NEBO_WINDOW_TASK_GROUP_PTR_OFFSET],0
 mov qword [r12+NEBO_WINDOW_BACKEND_CONTEXT_PTR_OFFSET],0
 mov qword [r12+NEBO_WINDOW_CLEANUP_COUNT_OFFSET],1
 or dword [r12+NEBO_WINDOW_FLAGS_OFFSET],NEBO_HEADLESS_FLAG_CLEANUP_DONE
 cmp r13d,NEBO_HEADLESS_CLOSE_BACKEND_FAILED
 je .backend_failed
 cmp r13d,NEBO_HEADLESS_CLOSE_QUEUE_OVERFLOW
 je .overflow
 mov rdi,rbx
 mov rsi,r12
 mov edx,NEBO_WINDOW_EVENT_CLOSED
 mov ecx,NEBO_WINDOW_EVENT_FLAG_SYNTHETIC | NEBO_WINDOW_EVENT_FLAG_TERMINAL
 mov r8d,1
 xor r9d,r9d
 xor r11d,r11d
 call headless_enqueue
 test eax,eax
 jnz .return
 mov dword [r12+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_CLOSED
 mov qword [r12+NEBO_WINDOW_LAST_ERROR_OFFSET],0
 jmp .closed_sequence
.backend_failed:
 mov rdi,rbx
 mov rsi,r12
 mov edx,NEBO_WINDOW_EVENT_BACKEND_FAILED
 mov ecx,NEBO_WINDOW_EVENT_FLAG_SYNTHETIC | NEBO_WINDOW_EVENT_FLAG_TERMINAL
 mov r8,r14
 xor r9d,r9d
 xor r11d,r11d
 call headless_enqueue
 test eax,eax
 jnz .return
 mov dword [r12+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_FAILED
 mov qword [r12+NEBO_WINDOW_LAST_ERROR_OFFSET],NEBO_WINDOW_ERROR_BACKEND_FAILURE
 jmp .closed_sequence
.overflow:
 mov rdi,rbx
 mov rsi,r12
 mov edx,NEBO_WINDOW_EVENT_QUEUE_OVERFLOW
 mov ecx,NEBO_WINDOW_EVENT_FLAG_SYNTHETIC | NEBO_WINDOW_EVENT_FLAG_TERMINAL
 mov r8,r14
 mov r9,[r12+NEBO_WINDOW_EVENT_COUNT_OFFSET]
 xor r11d,r11d
 call headless_enqueue
 test eax,eax
 jnz .return
 mov dword [r12+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_FAILED
 mov qword [r12+NEBO_WINDOW_LAST_ERROR_OFFSET],NEBO_WINDOW_ERROR_QUEUE_FULL
.closed_sequence:
 mov rax,[r12+NEBO_WINDOW_NEXT_EVENT_SEQUENCE_OFFSET]
 mov [r12+NEBO_WINDOW_CLOSE_SEQUENCE_OFFSET],rax
 xor eax,eax
 jmp .return
.already:
 mov eax,NEBO_WINDOW_ERROR_ALREADY_CLOSED
 jmp .return
.bad_state:
 mov eax,NEBO_WINDOW_ERROR_BAD_STATE
 jmp .return
.queue_full:
 mov eax,NEBO_WINDOW_ERROR_QUEUE_FULL
 jmp .return
.sequence:
 mov eax,NEBO_WINDOW_ERROR_SEQUENCE_EXHAUSTED
.return:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

; rdi=stream. Complete the previous CLOSE_REQUESTED dispatch before
; another stream operation. The caller-owned event is valid until the next
; poll, wait or release and may only change through preventDefault.
headless_finish_dispatch:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rdi
 test rbx,rbx
 jz .invalid
 mov r13,[rbx+NEBO_HEADLESS_STREAM_DISPATCH_EVENT_PTR_OFFSET]
 test r13,r13
 jz .success
 test r13,7
 jnz .bad_state
 cmp qword [r13+NEBO_WINDOW_EVENT_RESERVED_OFFSET],0
 jne .bad_state
 cmp dword [r13+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_CLOSE_REQUESTED
 jne .bad_state
 mov rax,[r13+NEBO_WINDOW_EVENT_SEQUENCE_OFFSET]
 cmp rax,[rbx+NEBO_HEADLESS_STREAM_DISPATCH_TOKEN_OFFSET]
 jne .bad_state
 mov rax,[r13+NEBO_WINDOW_EVENT_HANDLE_OFFSET]
 cmp rax,[rbx+NEBO_HEADLESS_STREAM_HANDLE_OFFSET]
 jne .bad_state
 mov eax,[r13+NEBO_WINDOW_EVENT_FLAGS_OFFSET]
 test eax,~NEBO_WINDOW_EVENT_KNOWN_FLAGS
 jnz .bad_state
 test eax,NEBO_WINDOW_EVENT_FLAG_NATIVE
 jz .bad_state
 test eax,NEBO_WINDOW_EVENT_FLAG_PREVENTED
 jz .default_close
 test eax,NEBO_WINDOW_EVENT_FLAG_PREVENTABLE
 jz .bad_state
 jmp .clear
.default_close:
 mov r14,[rbx+NEBO_HEADLESS_STREAM_RUNTIME_PTR_OFFSET]
 mov rdi,r14
 mov rsi,[rbx+NEBO_HEADLESS_STREAM_HANDLE_OFFSET]
 mov rdx,[rbx+NEBO_HEADLESS_STREAM_OWNER_CONTEXT_OFFSET]
 call headless_resolve
 test ecx,ecx
 jnz .resolve_fail
 mov r12,rax
 mov rdi,r14
 mov rsi,r12
 mov edx,NEBO_HEADLESS_CLOSE_DIRECT
 xor ecx,ecx
 call headless_close_barrier
 cmp eax,NEBO_WINDOW_ERROR_ALREADY_CLOSED
 je .clear
 test eax,eax
 jnz .return
.clear:
 mov qword [rbx+NEBO_HEADLESS_STREAM_DISPATCH_EVENT_PTR_OFFSET],0
 mov qword [rbx+NEBO_HEADLESS_STREAM_DISPATCH_TOKEN_OFFSET],0
.success:
 xor eax,eax
 jmp .return
.resolve_fail:
 mov eax,ecx
 jmp .return
.invalid:
 mov eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 jmp .return
.bad_state:
 mov eax,NEBO_WINDOW_ERROR_BAD_STATE
.return:
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

; rdi=record, rsi=event template. eax=WindowError.
headless_validate_backend_event:
 test rsi,rsi
 jz .invalid
 test rsi,7
 jnz .invalid
 cmp qword [rsi+NEBO_WINDOW_EVENT_RESERVED_OFFSET],0
 jne .invalid
 mov rax,[rsi+NEBO_WINDOW_EVENT_SEQUENCE_OFFSET]
 or rax,[rsi+NEBO_WINDOW_EVENT_HANDLE_OFFSET]
 or rax,[rsi+NEBO_WINDOW_EVENT_TIMESTAMP_OFFSET]
 jnz .invalid
 mov eax,[rsi+NEBO_WINDOW_EVENT_FLAGS_OFFSET]
 test eax,eax
 jnz .invalid
 mov eax,[rsi+NEBO_WINDOW_EVENT_KIND_OFFSET]
 cmp eax,NEBO_WINDOW_EVENT_SHOWN
 je .zero_payload
 cmp eax,NEBO_WINDOW_EVENT_HIDDEN
 je .zero_payload
 cmp eax,NEBO_WINDOW_EVENT_REDRAW_REQUESTED
 je .zero_payload
 cmp eax,NEBO_WINDOW_EVENT_RESIZED
 je .resize_payload
 cmp eax,NEBO_WINDOW_EVENT_FOCUS_GAINED
 je .zero_payload
 cmp eax,NEBO_WINDOW_EVENT_FOCUS_LOST
 je .zero_payload
 cmp eax,NEBO_WINDOW_EVENT_POINTER_MOVED
 je .ok
 cmp eax,NEBO_WINDOW_EVENT_POINTER_DOWN
 je .ok
 cmp eax,NEBO_WINDOW_EVENT_POINTER_UP
 je .ok
 cmp eax,NEBO_WINDOW_EVENT_POINTER_WHEEL
 je .ok
 cmp eax,NEBO_WINDOW_EVENT_KEY_DOWN
 je .ok
 cmp eax,NEBO_WINDOW_EVENT_KEY_UP
 je .ok
 cmp eax,NEBO_WINDOW_EVENT_CLOSE_REQUESTED
 je .zero_payload
 cmp eax,NEBO_WINDOW_EVENT_TEXT_INPUT
 jne .invalid
 mov rax,[rsi+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET]
 mov rcx,[rsi+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET]
 mov rdx,[rsi+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET]
 cmp rax,0x10ffff
 ja .invalid
 cmp rax,0xd800
 jb .scalar_len
 cmp rax,0xdfff
 jbe .invalid
.scalar_len:
 cmp rax,0x7f
 jbe .len1
 cmp rax,0x7ff
 jbe .len2
 cmp rax,0xffff
 jbe .len3
 cmp rcx,4
 jne .invalid
 mov r8,rax
 shr r8,18
 or r8,0xf0
 mov r9,rax
 shr r9,12
 and r9,0x3f
 or r9,0x80
 shl r9,8
 or r8,r9
 mov r9,rax
 shr r9,6
 and r9,0x3f
 or r9,0x80
 shl r9,16
 or r8,r9
 mov r9,rax
 and r9,0x3f
 or r9,0x80
 shl r9,24
 or r8,r9
 cmp rdx,r8
 jne .invalid
 jmp .ok
.len1:
 cmp rcx,1
 jne .invalid
 cmp rdx,rax
 jne .invalid
 jmp .ok
.len2:
 cmp rcx,2
 jne .invalid
 mov r8,rax
 shr r8,6
 or r8,0xc0
 mov r9,rax
 and r9,0x3f
 or r9,0x80
 shl r9,8
 or r8,r9
 cmp rdx,r8
 jne .invalid
 jmp .ok
.len3:
 cmp rcx,3
 jne .invalid
 mov r8,rax
 shr r8,12
 or r8,0xe0
 mov r9,rax
 shr r9,6
 and r9,0x3f
 or r9,0x80
 shl r9,8
 or r8,r9
 mov r9,rax
 and r9,0x3f
 or r9,0x80
 shl r9,16
 or r8,r9
 cmp rdx,r8
 jne .invalid
 jmp .ok
.resize_payload:
 mov r8,[rsi+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET]
 mov r9,[rsi+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET]
 cmp r8,NEBO_WINDOW_MIN_WIDTH
 jb .invalid
 cmp r8,NEBO_WINDOW_MAX_WIDTH
 ja .invalid
 cmp r9,NEBO_WINDOW_MIN_HEIGHT
 jb .invalid
 cmp r9,NEBO_WINDOW_MAX_HEIGHT
 ja .invalid
 cmp qword [rsi+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],0
 jne .invalid
 jmp .ok
.zero_payload:
 mov r8,[rsi+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET]
 or r8,[rsi+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET]
 or r8,[rsi+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET]
 jnz .invalid
.ok:
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 ret

; rdi=WindowEvent. Validate the pointer-free event value before typed access.
headless_validate_event_value:
 test rdi,rdi
 jz .invalid
 test rdi,7
 jnz .invalid
 cmp qword [rdi+NEBO_WINDOW_EVENT_RESERVED_OFFSET],0
 jne .invalid
 cmp qword [rdi+NEBO_WINDOW_EVENT_SEQUENCE_OFFSET],0
 je .invalid
 mov rax,[rdi+NEBO_WINDOW_EVENT_HANDLE_OFFSET]
 test rax,rax
 jz .invalid
 mov ecx,eax
 test ecx,ecx
 jz .invalid
 cmp ecx,NEBO_WINDOW_MAX_WINDOWS
 ja .invalid
 shr rax,NEBO_WINDOW_HANDLE_GENERATION_SHIFT
 test eax,eax
 jz .invalid
 cmp qword [rdi+NEBO_WINDOW_EVENT_TIMESTAMP_OFFSET],0
 je .invalid
 mov edx,[rdi+NEBO_WINDOW_EVENT_KIND_OFFSET]
 test edx,edx
 jz .invalid
 cmp edx,NEBO_WINDOW_EVENT_KIND_COUNT
 jae .invalid
 mov eax,[rdi+NEBO_WINDOW_EVENT_FLAGS_OFFSET]
 test eax,~NEBO_WINDOW_EVENT_KNOWN_FLAGS
 jnz .invalid
 mov ecx,eax
 and ecx,NEBO_WINDOW_EVENT_FLAG_NATIVE | NEBO_WINDOW_EVENT_FLAG_SYNTHETIC
 cmp ecx,NEBO_WINDOW_EVENT_FLAG_NATIVE
 je .origin_ok
 cmp ecx,NEBO_WINDOW_EVENT_FLAG_SYNTHETIC
 jne .invalid
.origin_ok:
 test eax,NEBO_WINDOW_EVENT_FLAG_PREVENTED
 jz .prevented_ok
 test eax,NEBO_WINDOW_EVENT_FLAG_PREVENTABLE
 jz .invalid
.prevented_ok:
 test eax,NEBO_WINDOW_EVENT_FLAG_PREVENTABLE
 jz .terminal_check
 cmp edx,NEBO_WINDOW_EVENT_CLOSE_REQUESTED
 jne .invalid
 test eax,NEBO_WINDOW_EVENT_FLAG_NATIVE
 jz .invalid
.terminal_check:
 cmp edx,NEBO_WINDOW_EVENT_CANCELLED
 jb .ordinary
 cmp edx,NEBO_WINDOW_EVENT_QUEUE_OVERFLOW
 ja .invalid
 test eax,NEBO_WINDOW_EVENT_FLAG_TERMINAL
 jz .invalid
 jmp .ok
.ordinary:
 test eax,NEBO_WINDOW_EVENT_FLAG_TERMINAL
 jnz .invalid
.ok:
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 ret

; ---------------------------------------------------------------------------
; Public bounded native headless API
; ---------------------------------------------------------------------------

; rdi=runtime, rsi=WindowRecord storage, rdx=slot capacity (1..16).
nebo_headless_runtime_init:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 test rbx,rbx
 jz .invalid
 test r12,r12
 jz .invalid
 test rbx,7
 jnz .invalid
 test r12,7
 jnz .invalid
 test r13,r13
 jz .limit
 cmp r13,NEBO_WINDOW_MAX_WINDOWS
 ja .limit
 mov rdi,rbx
 mov esi,NEBO_HEADLESS_RUNTIME_SIZE
 mov rdx,r12
 mov rcx,r13
 imul rcx,NEBO_WINDOW_SIZE
 call headless_ranges_overlap
 test eax,eax
 jnz .invalid
 mov rdi,rbx
 xor eax,eax
 mov ecx,NEBO_HEADLESS_RUNTIME_QWORDS
 rep stosq
 mov [rbx+NEBO_HEADLESS_RUNTIME_RECORDS_PTR_OFFSET],r12
 mov [rbx+NEBO_HEADLESS_RUNTIME_CAPACITY_OFFSET],r13
 mov rax,NEBO_HEADLESS_RUNTIME_MAGIC
 mov [rbx+NEBO_HEADLESS_RUNTIME_MAGIC_OFFSET],rax
 mov rdi,r12
 mov rax,r13
 imul rax,NEBO_WINDOW_QWORDS
 mov rcx,rax
 xor eax,eax
 rep stosq
 mov rdi,r12
 mov rcx,r13
.init_generation:
 mov qword [rdi+nebo_canvas_WINDOW_GENERATION_OFFSET],1
 add rdi,NEBO_WINDOW_SIZE
 loop .init_generation
 xor eax,eax
 jmp .return
.invalid:
 mov eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 jmp .return
.limit:
 mov eax,NEBO_WINDOW_ERROR_LIMIT_EXCEEDED
.return:
 pop r13
 pop r12
 pop rbx
 ret

; rdi=runtime, rsi=WindowOptions, rdx=out WindowHandle.
nebo_headless_window_create:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 test rbx,rbx
 jz .invalid
 test r12,r12
 jz .invalid
 test r12,7
 jnz .invalid
 test r13,r13
 jz .invalid
 test r13,7
 jnz .invalid
 mov rax,NEBO_HEADLESS_RUNTIME_MAGIC
 cmp qword [rbx+NEBO_HEADLESS_RUNTIME_MAGIC_OFFSET],rax
 jne .invalid
 mov rax,[r12+NEBO_WINDOW_OPTIONS_WIDTH_OFFSET]
 cmp rax,NEBO_WINDOW_MIN_WIDTH
 jb .dimension
 cmp rax,NEBO_WINDOW_MAX_WIDTH
 ja .dimension
 mov rax,[r12+NEBO_WINDOW_OPTIONS_HEIGHT_OFFSET]
 cmp rax,NEBO_WINDOW_MIN_HEIGHT
 jb .dimension
 cmp rax,NEBO_WINDOW_MAX_HEIGHT
 ja .dimension
 mov rax,[r12+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET]
 cmp rax,NEBO_WINDOW_MAX_TITLE_BYTES
 ja .title
 mov rcx,[r12+NEBO_WINDOW_OPTIONS_TITLE_CAPACITY_OFFSET]
 cmp rcx,rax
 jb .title
 cmp rcx,NEBO_WINDOW_MAX_TITLE_BYTES
 ja .title
 mov rcx,[r12+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET]
 test rcx,rcx
 jz .invalid
 test rax,rax
 jz .event_storage
 cmp qword [r12+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET],0
 je .invalid
 mov rdi,[r12+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET]
 mov rsi,[r12+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET]
 call headless_validate_utf8
 test eax,eax
 jnz .invalid
.event_storage:
 mov rcx,[r12+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET]
 test rcx,rcx
 jz .invalid
 test rcx,7
 jnz .invalid
 mov rcx,[r12+NEBO_WINDOW_OPTIONS_EVENT_CAPACITY_OFFSET]
 cmp rcx,NEBO_WINDOW_MIN_EVENT_CAPACITY
 jb .limit
 cmp rcx,NEBO_WINDOW_MAX_EVENTS
 ja .limit
 mov rcx,[r12+NEBO_WINDOW_OPTIONS_CANCELLATION_PTR_OFFSET]
 test rcx,rcx
 jz .cancel_required
 test rcx,7
 jnz .invalid
 mov rcx,[r12+NEBO_WINDOW_OPTIONS_TASK_GROUP_PTR_OFFSET]
 test rcx,rcx
 jz .task_required
 test rcx,7
 jnz .invalid
 cmp qword [rcx+NEBO_TASK_GROUP_JOINED],0
 jne .task_required
 cmp qword [rcx+NEBO_TASK_GROUP_COUNT],0
 jne .task_required
 cmp qword [r12+NEBO_WINDOW_OPTIONS_OWNER_CONTEXT_OFFSET],0
 je .invalid
 mov eax,[r12+NEBO_WINDOW_OPTIONS_BACKEND_PREFERENCE_OFFSET]
 cmp eax,NEBO_WINDOW_BACKEND_AUTO
 je .backend_ok
 cmp eax,NEBO_WINDOW_BACKEND_HEADLESS
 je .backend_ok
 cmp eax,NEBO_WINDOW_BACKEND_X11_DIRECT
 je .backend_unavailable
 jmp .invalid
.backend_ok:
 mov eax,[r12+NEBO_WINDOW_OPTIONS_FLAGS_OFFSET]
 test eax,~NEBO_WINDOW_OPTION_KNOWN_FLAGS
 jnz .invalid
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call headless_validate_create_ranges
 test eax,eax
 jnz .return
 mov rdi,[r12+NEBO_WINDOW_OPTIONS_CANCELLATION_PTR_OFFSET]
 call nebo_cancellation_check
 test eax,eax
 jz .find_slot
 cmp eax,NEBO_CONCURRENCY_ERROR_CANCELLED
 je .cancelled
 cmp eax,NEBO_CONCURRENCY_ERROR_TIMEOUT
 je .cancelled
 jmp .invalid
.find_slot:
 cmp qword [rbx+NEBO_HEADLESS_RUNTIME_LOGICAL_CLOCK_OFFSET],-1
 je .sequence
 mov r14,[rbx+NEBO_HEADLESS_RUNTIME_RECORDS_PTR_OFFSET]
 mov rcx,[rbx+NEBO_HEADLESS_RUNTIME_CAPACITY_OFFSET]
 xor r15d,r15d
.slot_loop:
 mov eax,[r14+NEBO_WINDOW_STATE_OFFSET]
 cmp eax,NEBO_WINDOW_STATE_EMPTY
 je .slot_found
 cmp eax,NEBO_WINDOW_STATE_RECLAIMED
 je .slot_found
 add r14,NEBO_WINDOW_SIZE
 inc r15
 loop .slot_loop
 jmp .limit
.slot_found:
 mov rax,[r14+nebo_canvas_WINDOW_GENERATION_OFFSET]
 test eax,eax
 jnz .generation_ok
 mov eax,1
.generation_ok:
 mov rcx,0xffffffff
 cmp rax,rcx
 ja .sequence
 mov r10,rax
 shl rax,NEBO_WINDOW_HANDLE_GENERATION_SHIFT
 lea rcx,[r15+1]
 or rax,rcx
 mov r15,rax
 mov rdi,r14
 mov ecx,NEBO_WINDOW_QWORDS
 xor eax,eax
 rep stosq
 mov [r14+nebo_canvas_WINDOW_GENERATION_OFFSET],r10
 mov rdx,[r12+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET]
 test rdx,rdx
 jz .title_copied
 mov rdi,[r12+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET]
 mov rsi,[r12+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET]
 call headless_memmove
.title_copied:
 mov rdi,[r12+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET]
 mov rcx,[r12+NEBO_WINDOW_OPTIONS_EVENT_CAPACITY_OFFSET]
 shl rcx,3
 xor eax,eax
 rep stosq
 mov [r14+NEBO_WINDOW_HANDLE_OFFSET],r15
 mov dword [r14+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_CREATED
 mov dword [r14+NEBO_WINDOW_BACKEND_OFFSET],NEBO_WINDOW_BACKEND_HEADLESS
 mov eax,[r12+NEBO_WINDOW_OPTIONS_FLAGS_OFFSET]
 or eax,NEBO_HEADLESS_FLAG_ACCEPTING_EVENTS | NEBO_HEADLESS_FLAG_ACTIVE
 mov [r14+NEBO_WINDOW_FLAGS_OFFSET],eax
 mov rax,[r12+NEBO_WINDOW_OPTIONS_OWNER_CONTEXT_OFFSET]
 mov [r14+NEBO_WINDOW_OWNER_CONTEXT_OFFSET],rax
 mov rax,[r12+NEBO_WINDOW_OPTIONS_WIDTH_OFFSET]
 mov [r14+NEBO_WINDOW_WIDTH_OFFSET],rax
 mov rax,[r12+NEBO_WINDOW_OPTIONS_HEIGHT_OFFSET]
 mov [r14+NEBO_WINDOW_HEIGHT_OFFSET],rax
 mov rax,[r12+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET]
 mov [r14+NEBO_WINDOW_TITLE_PTR_OFFSET],rax
 mov rax,[r12+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET]
 mov [r14+NEBO_WINDOW_TITLE_LENGTH_OFFSET],rax
 mov rax,[r12+NEBO_WINDOW_OPTIONS_TITLE_CAPACITY_OFFSET]
 mov [r14+NEBO_WINDOW_TITLE_CAPACITY_OFFSET],rax
 mov rax,[r12+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET]
 mov [r14+NEBO_WINDOW_EVENT_STORAGE_PTR_OFFSET],rax
 mov rax,[r12+NEBO_WINDOW_OPTIONS_EVENT_CAPACITY_OFFSET]
 mov [r14+NEBO_WINDOW_EVENT_CAPACITY_OFFSET],rax
 mov rax,[r12+NEBO_WINDOW_OPTIONS_CANCELLATION_PTR_OFFSET]
 mov [r14+NEBO_WINDOW_CANCELLATION_PTR_OFFSET],rax
 mov rax,[r12+NEBO_WINDOW_OPTIONS_TASK_GROUP_PTR_OFFSET]
 mov [r14+NEBO_WINDOW_TASK_GROUP_PTR_OFFSET],rax
 mov [r14+NEBO_WINDOW_BACKEND_CONTEXT_PTR_OFFSET],rbx
 mov qword [r14+NEBO_WINDOW_RESERVED_OFFSET],0
 inc qword [rbx+NEBO_HEADLESS_RUNTIME_ACTIVE_COUNT_OFFSET]
 mov rdi,rbx
 mov rsi,r14
 mov edx,NEBO_WINDOW_EVENT_CREATED
 mov ecx,NEBO_WINDOW_EVENT_FLAG_SYNTHETIC
 mov r8d,NEBO_WINDOW_BACKEND_HEADLESS
 mov r9,[r14+NEBO_WINDOW_WIDTH_OFFSET]
 mov r11,[r14+NEBO_WINDOW_HEIGHT_OFFSET]
 call headless_enqueue
 test eax,eax
 jnz .create_rollback
 mov [r13],r15
 xor eax,eax
 jmp .return
.create_rollback:
 dec qword [rbx+NEBO_HEADLESS_RUNTIME_ACTIVE_COUNT_OFFSET]
 mov dword [r14+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_EMPTY
 mov qword [r14+NEBO_WINDOW_HANDLE_OFFSET],0
 jmp .return
.invalid:
 mov eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 jmp .return
.dimension:
 mov eax,NEBO_WINDOW_ERROR_DIMENSION_OUT_OF_RANGE
 jmp .return
.title:
 mov eax,NEBO_WINDOW_ERROR_TITLE_TOO_LONG
 jmp .return
.limit:
 mov eax,NEBO_WINDOW_ERROR_LIMIT_EXCEEDED
 jmp .return
.cancel_required:
 mov eax,NEBO_WINDOW_ERROR_CANCELLATION_REQUIRED
 jmp .return
.task_required:
 mov eax,NEBO_WINDOW_ERROR_TASK_GROUP_REQUIRED
 jmp .return
.backend_unavailable:
 mov eax,NEBO_WINDOW_ERROR_BACKEND_UNAVAILABLE
 jmp .return
.cancelled:
 mov eax,NEBO_WINDOW_ERROR_CANCELLED
 jmp .return
.sequence:
 mov eax,NEBO_WINDOW_ERROR_SEQUENCE_EXHAUSTED
.return:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

; rdi=runtime, rsi=handle, rdx=owner.
nebo_headless_window_show:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov rdi,rbx
 call headless_resolve
 test ecx,ecx
 jnz .resolve_fail
 mov r12,rax
 mov eax,[r12+NEBO_WINDOW_STATE_OFFSET]
 cmp eax,NEBO_WINDOW_STATE_CREATED
 je .state_ok
 cmp eax,NEBO_WINDOW_STATE_HIDDEN
 jne .bad_state
.state_ok:
 mov rdi,rbx
 mov rsi,r12
 mov edx,NEBO_WINDOW_EVENT_SHOWN
 mov ecx,NEBO_WINDOW_EVENT_FLAG_SYNTHETIC
 xor r8d,r8d
 xor r9d,r9d
 xor r11d,r11d
 call headless_enqueue
 test eax,eax
 jnz .return
 mov dword [r12+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_VISIBLE
 jmp .return
.resolve_fail:
 mov eax,ecx
 jmp .return
.bad_state:
 mov eax,NEBO_WINDOW_ERROR_BAD_STATE
.return:
 add rsp,8
 pop r12
 pop rbx
 ret

; rdi=runtime, rsi=handle, rdx=owner.
nebo_headless_window_hide:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov rdi,rbx
 call headless_resolve
 test ecx,ecx
 jnz .resolve_fail
 mov r12,rax
 cmp dword [r12+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_VISIBLE
 jne .bad_state
 mov rdi,rbx
 mov rsi,r12
 mov edx,NEBO_WINDOW_EVENT_HIDDEN
 mov ecx,NEBO_WINDOW_EVENT_FLAG_SYNTHETIC
 xor r8d,r8d
 xor r9d,r9d
 xor r11d,r11d
 call headless_enqueue
 test eax,eax
 jnz .return
 mov dword [r12+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_HIDDEN
 jmp .return
.resolve_fail:
 mov eax,ecx
 jmp .return
.bad_state:
 mov eax,NEBO_WINDOW_ERROR_BAD_STATE
.return:
 add rsp,8
 pop r12
 pop rbx
 ret

; rdi=runtime, rsi=handle, rdx=owner, rcx=width, r8=height.
nebo_headless_window_resize:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rdi
 mov r13,rcx
 mov r14,r8
 cmp r13,NEBO_WINDOW_MIN_WIDTH
 jb .dimension
 cmp r13,NEBO_WINDOW_MAX_WIDTH
 ja .dimension
 cmp r14,NEBO_WINDOW_MIN_HEIGHT
 jb .dimension
 cmp r14,NEBO_WINDOW_MAX_HEIGHT
 ja .dimension
 mov rdi,rbx
 call headless_resolve
 test ecx,ecx
 jnz .resolve_fail
 mov r12,rax
 mov eax,[r12+NEBO_WINDOW_STATE_OFFSET]
 cmp eax,NEBO_WINDOW_STATE_CREATED
 je .state_ok
 cmp eax,NEBO_WINDOW_STATE_VISIBLE
 je .state_ok
 cmp eax,NEBO_WINDOW_STATE_HIDDEN
 jne .bad_state
.state_ok:
 mov rdi,rbx
 mov rsi,r12
 mov edx,NEBO_WINDOW_EVENT_RESIZED
 mov ecx,NEBO_WINDOW_EVENT_FLAG_SYNTHETIC
 mov r8,r13
 mov r9,r14
 xor r11d,r11d
 call headless_enqueue
 test eax,eax
 jnz .return
 mov [r12+NEBO_WINDOW_WIDTH_OFFSET],r13
 mov [r12+NEBO_WINDOW_HEIGHT_OFFSET],r14
 jmp .return
.resolve_fail:
 mov eax,ecx
 jmp .return
.dimension:
 mov eax,NEBO_WINDOW_ERROR_DIMENSION_OUT_OF_RANGE
 jmp .return
.bad_state:
 mov eax,NEBO_WINDOW_ERROR_BAD_STATE
.return:
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

; rdi=runtime, rsi=handle, rdx=owner, rcx=text pointer, r8=byte length.
nebo_headless_window_set_title:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r15,rdx
 mov r13,rcx
 mov r14,r8
 cmp r14,NEBO_WINDOW_MAX_TITLE_BYTES
 ja .title
 test r14,r14
 jz .resolve
 test r13,r13
 jz .invalid
.resolve:
 mov rax,r13
 add rax,r14
 jc .invalid
 mov rdi,r13
 mov rsi,r14
 call headless_validate_utf8
 test eax,eax
 jnz .invalid
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r15
 call headless_resolve
 test ecx,ecx
 jnz .resolve_fail
 mov r12,rax
 mov eax,[r12+NEBO_WINDOW_STATE_OFFSET]
 cmp eax,NEBO_WINDOW_STATE_CREATED
 je .state_ok
 cmp eax,NEBO_WINDOW_STATE_VISIBLE
 je .state_ok
 cmp eax,NEBO_WINDOW_STATE_HIDDEN
 jne .bad_state
.state_ok:
 cmp r14,[r12+NEBO_WINDOW_TITLE_CAPACITY_OFFSET]
 ja .title
 test r14,r14
 jz .store_len
 mov rdi,[r12+NEBO_WINDOW_TITLE_PTR_OFFSET]
 mov rsi,r13
 mov rdx,r14
 call headless_memmove
.store_len:
 mov [r12+NEBO_WINDOW_TITLE_LENGTH_OFFSET],r14
 xor eax,eax
 jmp .return
.resolve_fail:
 mov eax,ecx
 jmp .return
.invalid:
 mov eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 jmp .return
.title:
 mov eax,NEBO_WINDOW_ERROR_TITLE_TOO_LONG
 jmp .return
.bad_state:
 mov eax,NEBO_WINDOW_ERROR_BAD_STATE
.return:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

; rdi=runtime, rsi=handle, rdx=owner.
nebo_headless_window_request_redraw:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov rdi,rbx
 call headless_resolve
 test ecx,ecx
 jnz .resolve_fail
 mov r12,rax
 mov eax,[r12+NEBO_WINDOW_STATE_OFFSET]
 cmp eax,NEBO_WINDOW_STATE_CREATED
 je .state_ok
 cmp eax,NEBO_WINDOW_STATE_VISIBLE
 je .state_ok
 cmp eax,NEBO_WINDOW_STATE_HIDDEN
 jne .bad_state
.state_ok:
 test dword [r12+NEBO_WINDOW_FLAGS_OFFSET],NEBO_HEADLESS_FLAG_REDRAW_PENDING
 jnz .coalesced
 mov rdi,rbx
 mov rsi,r12
 mov edx,NEBO_WINDOW_EVENT_REDRAW_REQUESTED
 mov ecx,NEBO_WINDOW_EVENT_FLAG_SYNTHETIC
 xor r8d,r8d
 xor r9d,r9d
 xor r11d,r11d
 call headless_enqueue
 test eax,eax
 jnz .return
 or dword [r12+NEBO_WINDOW_FLAGS_OFFSET],NEBO_HEADLESS_FLAG_REDRAW_PENDING
.coalesced:
 xor eax,eax
 jmp .return
.resolve_fail:
 mov eax,ecx
 jmp .return
.bad_state:
 mov eax,NEBO_WINDOW_ERROR_BAD_STATE
.return:
 add rsp,8
 pop r12
 pop rbx
 ret

; rdi=runtime, rsi=handle, rdx=owner.
nebo_headless_window_close:
 push rbx
 mov rbx,rdi
 mov rdi,rbx
 call headless_resolve
 test ecx,ecx
 jnz .resolve_fail
 mov rsi,rax
 mov rdi,rbx
 mov edx,NEBO_HEADLESS_CLOSE_DIRECT
 xor ecx,ecx
 call headless_close_barrier
 jmp .return
.resolve_fail:
 mov eax,ecx
.return:
 pop rbx
 ret

; rdi=runtime, rsi=handle, rdx=owner, rcx=out stream.
nebo_headless_window_events:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r13,rdx
 mov r14,rcx
 test r14,r14
 jz .invalid
 test r14,7
 jnz .invalid
 mov rdi,rbx
 call headless_resolve
 test ecx,ecx
 jnz .resolve_fail
 mov r12,rax
 test dword [r12+NEBO_WINDOW_FLAGS_OFFSET],NEBO_HEADLESS_FLAG_STREAM_BORROWED
 jnz .bad_state
 mov rdi,r14
 mov ecx,NEBO_HEADLESS_STREAM_QWORDS
 xor eax,eax
 rep stosq
 mov [r14+NEBO_HEADLESS_STREAM_RUNTIME_PTR_OFFSET],rbx
 mov rax,[r12+NEBO_WINDOW_HANDLE_OFFSET]
 mov [r14+NEBO_HEADLESS_STREAM_HANDLE_OFFSET],rax
 mov [r14+NEBO_HEADLESS_STREAM_OWNER_CONTEXT_OFFSET],r13
 mov rax,[r12+nebo_canvas_WINDOW_GENERATION_OFFSET]
 mov [r14+NEBO_HEADLESS_STREAM_GENERATION_OFFSET],rax
 mov qword [r14+NEBO_HEADLESS_STREAM_ACTIVE_OFFSET],1
 or dword [r12+NEBO_WINDOW_FLAGS_OFFSET],NEBO_HEADLESS_FLAG_STREAM_BORROWED
 xor eax,eax
 jmp .return
.resolve_fail:
 mov eax,ecx
 jmp .return
.invalid:
 mov eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 jmp .return
.bad_state:
 mov eax,NEBO_WINDOW_ERROR_BAD_STATE
.return:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=stream, rsi=out event. eax=status, edx=ready.
nebo_headless_event_stream_poll:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 test rbx,rbx
 jz .invalid
 test r12,r12
 jz .invalid
 test r12,7
 jnz .invalid
 cmp qword [rbx+NEBO_HEADLESS_STREAM_ACTIVE_OFFSET],1
 jne .bad_state
 cmp qword [rbx+NEBO_HEADLESS_STREAM_RESERVED_OFFSET],0
 jne .bad_state
 mov rdi,rbx
 call headless_finish_dispatch
 test eax,eax
 jnz .poll_fail
 mov rdi,[rbx+NEBO_HEADLESS_STREAM_RUNTIME_PTR_OFFSET]
 mov rsi,[rbx+NEBO_HEADLESS_STREAM_HANDLE_OFFSET]
 mov rdx,[rbx+NEBO_HEADLESS_STREAM_OWNER_CONTEXT_OFFSET]
 call headless_resolve
 test ecx,ecx
 jnz .resolve_fail
 cmp qword [rbx+NEBO_HEADLESS_STREAM_GENERATION_OFFSET],0
 je .bad_state
 mov rcx,[rax+nebo_canvas_WINDOW_GENERATION_OFFSET]
 cmp rcx,[rbx+NEBO_HEADLESS_STREAM_GENERATION_OFFSET]
 jne .stale
 mov rdi,rax
 mov rsi,r12
 call headless_dequeue
 test eax,eax
 jnz .return
 test edx,edx
 jz .return
 cmp dword [r12+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_CLOSE_REQUESTED
 jne .return
 mov [rbx+NEBO_HEADLESS_STREAM_DISPATCH_EVENT_PTR_OFFSET],r12
 mov rax,[r12+NEBO_WINDOW_EVENT_SEQUENCE_OFFSET]
 mov [rbx+NEBO_HEADLESS_STREAM_DISPATCH_TOKEN_OFFSET],rax
 xor eax,eax
 jmp .return
.poll_fail:
 xor edx,edx
 jmp .return
.resolve_fail:
 mov eax,ecx
 xor edx,edx
 jmp .return
.invalid:
 mov eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 xor edx,edx
 jmp .return
.bad_state:
 mov eax,NEBO_WINDOW_ERROR_BAD_STATE
 xor edx,edx
 jmp .return
.stale:
 mov eax,NEBO_WINDOW_ERROR_STALE_HANDLE
 xor edx,edx
.return:
 add rsp,8
 pop r12
 pop rbx
 ret

; rdi=stream, rsi=out event, rdx=max one-ms waits. eax=status, edx=ready.
nebo_headless_event_stream_wait:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,24
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBO_HEADLESS_MAX_WAIT_CYCLES
 ja .limit
 mov rdi,rbx
 mov rsi,r12
 call nebo_headless_event_stream_poll
 test eax,eax
 jnz .return
 test edx,edx
 jnz .return
 mov r14,[rbx+NEBO_HEADLESS_STREAM_RUNTIME_PTR_OFFSET]
 cmp qword [r14+NEBO_HEADLESS_RUNTIME_WAITER_COUNT_OFFSET],0
 jne .bad_state
 mov rdi,r14
 mov rsi,[rbx+NEBO_HEADLESS_STREAM_HANDLE_OFFSET]
 mov rdx,[rbx+NEBO_HEADLESS_STREAM_OWNER_CONTEXT_OFFSET]
 call headless_resolve
 test ecx,ecx
 jnz .resolve_fail
 mov r15,rax
 mov eax,[r15+NEBO_WINDOW_STATE_OFFSET]
 cmp eax,NEBO_WINDOW_STATE_CLOSED
 je .empty
 cmp eax,NEBO_WINDOW_STATE_FAILED
 je .empty
 mov rdi,[r15+NEBO_WINDOW_CANCELLATION_PTR_OFFSET]
 test rdi,rdi
 jz .after_cancel_check
 call nebo_cancellation_check
 test eax,eax
 jz .after_cancel_check
 cmp eax,NEBO_CONCURRENCY_ERROR_CANCELLED
 je .cancel_close
 cmp eax,NEBO_CONCURRENCY_ERROR_TIMEOUT
 jne .invalid
.cancel_close:
 mov rcx,rax
 mov rdi,r14
 mov rsi,r15
 mov edx,NEBO_HEADLESS_CLOSE_CANCELLED
 call headless_close_barrier
 cmp eax,NEBO_WINDOW_ERROR_ALREADY_CLOSED
 je .poll_after_cancel
 test eax,eax
 jnz .return
.poll_after_cancel:
 mov rdi,rbx
 mov rsi,r12
 call nebo_headless_event_stream_poll
 jmp .return
.after_cancel_check:
 test r13,r13
 jz .empty
 mov qword [r14+NEBO_HEADLESS_RUNTIME_WAITER_COUNT_OFFSET],1
 mov qword [rsp],0
 mov qword [rsp+8],NEBO_HEADLESS_WAIT_SLICE_NS
.wait_loop:
 mov edx,[r15+NEBO_WINDOW_NEXT_EVENT_SEQUENCE_OFFSET]
 mov eax,NEBO_LINUX_X86_64_SYS_FUTEX
 lea rdi,[r15+NEBO_WINDOW_NEXT_EVENT_SEQUENCE_OFFSET]
 mov esi,NEBO_FUTEX_WAIT_PRIVATE
 lea r10,[rsp]
 xor r8d,r8d
 xor r9d,r9d
 syscall
 test rax,rax
 jns .poll_wait
 cmp rax,-EINTR
 je .poll_wait
 cmp rax,-EAGAIN
 je .poll_wait
 cmp rax,-ETIMEDOUT
 jne .wait_io
.poll_wait:
 mov rdi,rbx
 mov rsi,r12
 call nebo_headless_event_stream_poll
 test eax,eax
 jnz .wait_return_clear
 test edx,edx
 jnz .wait_return_clear
 mov rdi,[r15+NEBO_WINDOW_CANCELLATION_PTR_OFFSET]
 test rdi,rdi
 jz .next_wait
 call nebo_cancellation_check
 test eax,eax
 jz .next_wait
 cmp eax,NEBO_CONCURRENCY_ERROR_CANCELLED
 je .wait_cancel
 cmp eax,NEBO_CONCURRENCY_ERROR_TIMEOUT
 jne .wait_invalid
.wait_cancel:
 mov rcx,rax
 mov rdi,r14
 mov rsi,r15
 mov edx,NEBO_HEADLESS_CLOSE_CANCELLED
 call headless_close_barrier
 cmp eax,NEBO_WINDOW_ERROR_ALREADY_CLOSED
 je .wait_poll_cancelled
 test eax,eax
 jnz .wait_return_clear
.wait_poll_cancelled:
 mov rdi,rbx
 mov rsi,r12
 call nebo_headless_event_stream_poll
 jmp .wait_return_clear
.next_wait:
 dec r13
 jnz .wait_loop
 xor eax,eax
 xor edx,edx
.wait_return_clear:
 mov qword [r14+NEBO_HEADLESS_RUNTIME_WAITER_COUNT_OFFSET],0
 jmp .return
.wait_io:
 mov eax,NEBO_WINDOW_ERROR_BACKEND_FAILURE
 xor edx,edx
 jmp .wait_return_clear
.wait_invalid:
 mov eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 xor edx,edx
 jmp .wait_return_clear
.resolve_fail:
 mov eax,ecx
 xor edx,edx
 jmp .return
.limit:
 mov eax,NEBO_WINDOW_ERROR_LIMIT_EXCEEDED
 xor edx,edx
 jmp .return
.invalid:
 mov eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 xor edx,edx
 jmp .return
.bad_state:
 mov eax,NEBO_WINDOW_ERROR_BAD_STATE
 xor edx,edx
 jmp .return
.empty:
 xor eax,eax
 xor edx,edx
.return:
 add rsp,24
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

; rdi=stream.
nebo_headless_event_stream_release:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 test rbx,rbx
 jz .invalid
 cmp qword [rbx+NEBO_HEADLESS_STREAM_ACTIVE_OFFSET],1
 jne .bad_state
 cmp qword [rbx+NEBO_HEADLESS_STREAM_RESERVED_OFFSET],0
 jne .bad_state
 mov rdi,rbx
 call headless_finish_dispatch
 test eax,eax
 jnz .return
 mov rdi,[rbx+NEBO_HEADLESS_STREAM_RUNTIME_PTR_OFFSET]
 mov rsi,[rbx+NEBO_HEADLESS_STREAM_HANDLE_OFFSET]
 mov rdx,[rbx+NEBO_HEADLESS_STREAM_OWNER_CONTEXT_OFFSET]
 call headless_resolve
 test ecx,ecx
 jnz .resolve_fail
 mov r12,rax
 and dword [r12+NEBO_WINDOW_FLAGS_OFFSET],~NEBO_HEADLESS_FLAG_STREAM_BORROWED
 mov qword [rbx+NEBO_HEADLESS_STREAM_ACTIVE_OFFSET],0
 mov qword [rbx+NEBO_HEADLESS_STREAM_RUNTIME_PTR_OFFSET],0
 mov qword [rbx+NEBO_HEADLESS_STREAM_HANDLE_OFFSET],0
 mov qword [rbx+NEBO_HEADLESS_STREAM_OWNER_CONTEXT_OFFSET],0
 mov qword [rbx+NEBO_HEADLESS_STREAM_GENERATION_OFFSET],0
 mov qword [rbx+NEBO_HEADLESS_STREAM_DISPATCH_EVENT_PTR_OFFSET],0
 mov qword [rbx+NEBO_HEADLESS_STREAM_DISPATCH_TOKEN_OFFSET],0
 xor eax,eax
 jmp .return
.resolve_fail:
 mov eax,ecx
 jmp .return
.invalid:
 mov eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 jmp .return
.bad_state:
 mov eax,NEBO_WINDOW_ERROR_BAD_STATE
.return:
 add rsp,8
 pop r12
 pop rbx
 ret

; rdi=runtime, rsi=handle, rdx=owner.
nebo_headless_window_reclaim:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov rdi,rbx
 call headless_resolve
 test ecx,ecx
 jnz .resolve_fail
 mov r12,rax
 mov eax,[r12+NEBO_WINDOW_STATE_OFFSET]
 cmp eax,NEBO_WINDOW_STATE_CLOSED
 je .state_ok
 cmp eax,NEBO_WINDOW_STATE_FAILED
 jne .bad_state
.state_ok:
 test dword [r12+NEBO_WINDOW_FLAGS_OFFSET],NEBO_HEADLESS_FLAG_STREAM_BORROWED
 jnz .bad_state
 cmp qword [r12+NEBO_WINDOW_CLEANUP_COUNT_OFFSET],1
 jne .bad_state
 cmp qword [r12+NEBO_WINDOW_EVENT_COUNT_OFFSET],0
 jne .bad_state
 cmp qword [rbx+NEBO_HEADLESS_RUNTIME_ACTIVE_COUNT_OFFSET],0
 je .bad_state
 mov r8,[r12+nebo_canvas_WINDOW_GENERATION_OFFSET]
 mov rcx,0xffffffff
 cmp r8,rcx
 jae .sequence
 inc r8
 mov rdi,r12
 mov ecx,NEBO_WINDOW_QWORDS
 xor eax,eax
 rep stosq
 mov [r12+nebo_canvas_WINDOW_GENERATION_OFFSET],r8
 mov dword [r12+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_RECLAIMED
 dec qword [rbx+NEBO_HEADLESS_RUNTIME_ACTIVE_COUNT_OFFSET]
 xor eax,eax
 jmp .return
.resolve_fail:
 mov eax,ecx
 jmp .return
.bad_state:
 mov eax,NEBO_WINDOW_ERROR_BAD_STATE
 jmp .return
.sequence:
 mov eax,NEBO_WINDOW_ERROR_SEQUENCE_EXHAUSTED
.return:
 add rsp,8
 pop r12
 pop rbx
 ret

; rdi=runtime, rsi=handle, rdx=owner, rcx=pointer-free event template.
nebo_headless_window_push_event:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rdi
 mov r13,rcx
 test r13,r13
 jz .invalid
 mov rdi,rbx
 call headless_resolve
 test ecx,ecx
 jnz .resolve_fail
 mov r12,rax
 mov eax,[r12+NEBO_WINDOW_STATE_OFFSET]
 cmp eax,NEBO_WINDOW_STATE_CREATED
 je .state_ok
 cmp eax,NEBO_WINDOW_STATE_VISIBLE
 je .state_ok
 cmp eax,NEBO_WINDOW_STATE_HIDDEN
 jne .bad_state
.state_ok:
 test dword [r12+NEBO_WINDOW_FLAGS_OFFSET],NEBO_HEADLESS_FLAG_ACCEPTING_EVENTS
 jz .bad_state
 mov rdi,r12
 mov rsi,r13
 call headless_validate_backend_event
 test eax,eax
 jnz .return
 mov r14d,[r13+NEBO_WINDOW_EVENT_KIND_OFFSET]
 mov rdi,rbx
 mov rsi,r12
 mov edx,r14d
 mov ecx,NEBO_WINDOW_EVENT_FLAG_NATIVE
 cmp r14d,NEBO_WINDOW_EVENT_CLOSE_REQUESTED
 jne .event_flags_ready
 test dword [r12+NEBO_WINDOW_FLAGS_OFFSET],NEBO_WINDOW_OPTION_CLOSE_PREVENTABLE
 jz .event_flags_ready
 or ecx,NEBO_WINDOW_EVENT_FLAG_PREVENTABLE
.event_flags_ready:
 mov r8,[r13+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET]
 mov r9,[r13+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET]
 mov r11,[r13+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET]
 call headless_enqueue
 cmp eax,NEBO_WINDOW_ERROR_QUEUE_FULL
 jne .after_enqueue
 mov rdi,rbx
 mov rsi,r12
 mov edx,NEBO_HEADLESS_CLOSE_QUEUE_OVERFLOW
 mov ecx,r14d
 call headless_close_barrier
 mov eax,NEBO_WINDOW_ERROR_QUEUE_FULL
 jmp .return
.after_enqueue:
 test eax,eax
 jnz .return
 xor eax,eax
 jmp .return
.resolve_fail:
 mov eax,ecx
 jmp .return
.invalid:
 mov eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 jmp .return
.bad_state:
 mov eax,NEBO_WINDOW_ERROR_BAD_STATE
.return:
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

; Internal F05 backend close seam.
; rdi=runtime, rsi=handle, rdx=owner, ecx=close reason, r8=detail.
; The caller must release its native resources before invoking this function.
nebo_headless_window_backend_close:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14d,ecx
 mov r15,r8
 cmp r14d,NEBO_HEADLESS_CLOSE_QUEUE_OVERFLOW
 ja .backend_close_invalid
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call headless_resolve
 test ecx,ecx
 jnz .backend_close_resolve
 mov rsi,rax
 mov rdi,rbx
 mov edx,r14d
 mov rcx,r15
 call headless_close_barrier
 jmp .backend_close_return
.backend_close_resolve:
 mov eax,ecx
 jmp .backend_close_return
.backend_close_invalid:
 mov eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
.backend_close_return:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

; rdi=WindowEvent. eax=status, edx=kind.
nebo_headless_window_event_kind:
 sub rsp,8
 call headless_validate_event_value
 add rsp,8
 test eax,eax
 jnz .invalid
 mov edx,[rdi+NEBO_WINDOW_EVENT_KIND_OFFSET]
 xor eax,eax
 ret
.invalid:
 xor edx,edx
 ret

; rdi=WindowEvent. eax=status, edx=present, r8..r10=payload.
nebo_headless_window_event_key:
 sub rsp,8
 call headless_validate_event_value
 add rsp,8
 test eax,eax
 jnz .invalid
 mov ecx,[rdi+NEBO_WINDOW_EVENT_KIND_OFFSET]
 cmp ecx,NEBO_WINDOW_EVENT_KEY_DOWN
 je .present
 cmp ecx,NEBO_WINDOW_EVENT_KEY_UP
 jne .absent
.present:
 mov r8,[rdi+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET]
 mov r9,[rdi+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET]
 mov r10,[rdi+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET]
 mov edx,1
 xor eax,eax
 ret
.absent:
 xor edx,edx
 xor eax,eax
 ret
.invalid:
 xor edx,edx
 ret

; rdi=WindowEvent. eax=status, edx=present, r8..r10=payload.
nebo_headless_window_event_pointer:
 sub rsp,8
 call headless_validate_event_value
 add rsp,8
 test eax,eax
 jnz .invalid
 mov ecx,[rdi+NEBO_WINDOW_EVENT_KIND_OFFSET]
 cmp ecx,NEBO_WINDOW_EVENT_POINTER_MOVED
 jb .absent
 cmp ecx,NEBO_WINDOW_EVENT_POINTER_WHEEL
 ja .absent
 mov r8,[rdi+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET]
 mov r9,[rdi+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET]
 mov r10,[rdi+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET]
 mov edx,1
 xor eax,eax
 ret
.absent:
 xor edx,edx
 xor eax,eax
 ret
.invalid:
 xor edx,edx
 ret

; rdi=WindowEvent. eax=status, edx=present, r8=scalar, r9=len, r10=bytes.
nebo_headless_window_event_text_input:
 sub rsp,8
 call headless_validate_event_value
 add rsp,8
 test eax,eax
 jnz .invalid
 cmp dword [rdi+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_TEXT_INPUT
 jne .absent
 mov r8,[rdi+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET]
 mov r9,[rdi+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET]
 mov r10,[rdi+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET]
 cmp r8,0x10ffff
 ja .malformed
 cmp r8,0xd800
 jb .scalar_len
 cmp r8,0xdfff
 jbe .malformed
.scalar_len:
 cmp r8,0x7f
 jbe .expect1
 cmp r8,0x7ff
 jbe .expect2
 cmp r8,0xffff
 jbe .expect3
 cmp r9,4
 jne .malformed
 mov r11,r8
 shr r11,18
 or r11,0xf0
 mov rcx,r8
 shr rcx,12
 and rcx,0x3f
 or rcx,0x80
 shl rcx,8
 or r11,rcx
 mov rcx,r8
 shr rcx,6
 and rcx,0x3f
 or rcx,0x80
 shl rcx,16
 or r11,rcx
 mov rcx,r8
 and rcx,0x3f
 or rcx,0x80
 shl rcx,24
 or r11,rcx
 cmp r10,r11
 jne .malformed
 jmp .present
.expect1:
 cmp r9,1
 jne .malformed
 cmp r10,r8
 jne .malformed
 jmp .present
.expect2:
 cmp r9,2
 jne .malformed
 mov r11,r8
 shr r11,6
 or r11,0xc0
 mov rcx,r8
 and rcx,0x3f
 or rcx,0x80
 shl rcx,8
 or r11,rcx
 cmp r10,r11
 jne .malformed
 jmp .present
.expect3:
 cmp r9,3
 jne .malformed
 mov r11,r8
 shr r11,12
 or r11,0xe0
 mov rcx,r8
 shr rcx,6
 and rcx,0x3f
 or rcx,0x80
 shl rcx,8
 or r11,rcx
 mov rcx,r8
 and rcx,0x3f
 or rcx,0x80
 shl rcx,16
 or r11,rcx
 cmp r10,r11
 jne .malformed
.present:
 mov edx,1
 xor eax,eax
 ret
.absent:
 xor edx,edx
 xor eax,eax
 ret
.malformed:
 mov eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 xor edx,edx
 ret
.invalid:
 xor edx,edx
 ret

; rdi=WindowEvent. eax=status, edx=present, r8=width, r9=height.
nebo_headless_window_event_resize:
 sub rsp,8
 call headless_validate_event_value
 add rsp,8
 test eax,eax
 jnz .invalid
 cmp dword [rdi+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_RESIZED
 jne .absent
 mov r8,[rdi+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET]
 mov r9,[rdi+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET]
 cmp r8,NEBO_WINDOW_MIN_WIDTH
 jb .malformed
 cmp r8,NEBO_WINDOW_MAX_WIDTH
 ja .malformed
 cmp r9,NEBO_WINDOW_MIN_HEIGHT
 jb .malformed
 cmp r9,NEBO_WINDOW_MAX_HEIGHT
 ja .malformed
 mov edx,1
 xor eax,eax
 ret
.absent:
 xor edx,edx
 xor eax,eax
 ret
.malformed:
 mov eax,NEBO_WINDOW_ERROR_INVALID_ARGUMENT
 xor edx,edx
 ret
.invalid:
 xor edx,edx
 ret

; rdi=active stream, rsi=WindowEvent returned by its last poll/wait.
; The event remains active only until the next stream operation.
nebo_headless_window_event_prevent_default:
 push rbx
 mov rbx,rdi
 test rbx,rbx
 jz .not_preventable
 test rbx,7
 jnz .not_preventable
 test rsi,rsi
 jz .not_preventable
 test rsi,7
 jnz .not_preventable
 cmp qword [rbx+NEBO_HEADLESS_STREAM_ACTIVE_OFFSET],1
 jne .not_preventable
 cmp [rbx+NEBO_HEADLESS_STREAM_DISPATCH_EVENT_PTR_OFFSET],rsi
 jne .not_preventable
 mov rax,[rsi+NEBO_WINDOW_EVENT_SEQUENCE_OFFSET]
 cmp rax,[rbx+NEBO_HEADLESS_STREAM_DISPATCH_TOKEN_OFFSET]
 jne .not_preventable
 mov rdi,rsi
 call headless_validate_event_value
 test eax,eax
 jnz .return
 cmp dword [rdi+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_CLOSE_REQUESTED
 jne .not_preventable
 mov eax,[rdi+NEBO_WINDOW_EVENT_FLAGS_OFFSET]
 mov ecx,NEBO_WINDOW_EVENT_FLAG_NATIVE | NEBO_WINDOW_EVENT_FLAG_PREVENTABLE
 and eax,ecx
 cmp eax,ecx
 jne .not_preventable
 or dword [rdi+NEBO_WINDOW_EVENT_FLAGS_OFFSET],NEBO_WINDOW_EVENT_FLAG_PREVENTED
 xor eax,eax
 jmp .return
.not_preventable:
 mov eax,NEBO_WINDOW_ERROR_NOT_PREVENTABLE
.return:
 pop rbx
 ret
