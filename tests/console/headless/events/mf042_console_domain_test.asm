; Nebo Assembly — MF042 FakePlatform/ConsoleDomain/queue scenarios
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/handles/console_handle.inc"
%include "runtime/console/manager/console_manager.inc"
%include "runtime/console/queues/console_queue.inc"
%include "runtime/console/domain/console_domain.inc"
%include "runtime/console/platform/fake/fake_platform.inc"

extern nebo_console_runtime_context_init
extern nebo_console_runtime_headless_bind
extern nebo_console_manager_default_get_or_create
extern nebo_console_manager_anonymous_create
extern nebo_console_manager_handle_validate
extern nebo_console_manager_close
extern nebo_console_manager_state_hash
extern nebo_console_domain_from_handle
extern nebo_console_domain_send
extern nebo_console_domain_step
extern nebo_console_domain_state_hash
extern nebo_console_scheduler_run
extern nebo_console_scheduler_state_hash
extern nebo_fake_platform_inject_event
extern nebo_fake_platform_state_hash
extern neboc_host_process_exit

global _start

%define TEST_DOMAIN_CAPACITY 4
%define TEST_MAX_QUEUE_CAPACITY 8

section .bss align=64
context_a: resb NEBO_CONSOLE_CONTEXT_SIZE
slots_a: resb TEST_DOMAIN_CAPACITY*NEBO_CONSOLE_SLOT_SIZE
clock_a: resb NEBO_FAKE_CLOCK_SIZE
platform_a: resb NEBO_FAKE_PLATFORM_SIZE
scheduler_a: resb NEBO_CONSOLE_SCHEDULER_SIZE
domains_a: resb TEST_DOMAIN_CAPACITY*NEBO_CONSOLE_DOMAIN_SIZE
command_buffers_a: resb TEST_DOMAIN_CAPACITY*TEST_MAX_QUEUE_CAPACITY*NEBO_CONSOLE_COMMAND_DESCRIPTOR_SIZE
event_buffers_a: resb TEST_DOMAIN_CAPACITY*TEST_MAX_QUEUE_CAPACITY*NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
storage_a: resb NEBO_CONSOLE_HEADLESS_STORAGE_SIZE

context_b: resb NEBO_CONSOLE_CONTEXT_SIZE
slots_b: resb TEST_DOMAIN_CAPACITY*NEBO_CONSOLE_SLOT_SIZE
clock_b: resb NEBO_FAKE_CLOCK_SIZE
platform_b: resb NEBO_FAKE_PLATFORM_SIZE
scheduler_b: resb NEBO_CONSOLE_SCHEDULER_SIZE
domains_b: resb TEST_DOMAIN_CAPACITY*NEBO_CONSOLE_DOMAIN_SIZE
command_buffers_b: resb TEST_DOMAIN_CAPACITY*TEST_MAX_QUEUE_CAPACITY*NEBO_CONSOLE_COMMAND_DESCRIPTOR_SIZE
event_buffers_b: resb TEST_DOMAIN_CAPACITY*TEST_MAX_QUEUE_CAPACITY*NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
storage_b: resb NEBO_CONSOLE_HEADLESS_STORAGE_SIZE

handle_a: resq 1
handle_b: resq 1
handle_c: resq 1
domain_a: resq 1
domain_b: resq 1
slot_a: resq 1
progress_a: resq 1
progress_b: resq 1
command_a: resb NEBO_CONSOLE_COMMAND_DESCRIPTOR_SIZE
hashes_a: resq 4
hashes_b: resq 4

section .text
_start:
 mov rax,[rsp]
 cmp rax,2
 jne test_usage
 mov rbx,[rsp+16]
 cmp byte [rbx+1],0
 jne test_usage
 movzx eax,byte [rbx]
 sub eax,'0'
 cmp eax,1
 jb test_usage
 cmp eax,9
 ja test_usage
 cmp eax,1
 je scenario_1
 cmp eax,2
 je scenario_2
 cmp eax,3
 je scenario_3
 cmp eax,4
 je scenario_4
 cmp eax,5
 je scenario_5
 cmp eax,6
 je scenario_6
 cmp eax,7
 je scenario_7
 cmp eax,8
 je scenario_8
 jmp scenario_9

; Create is logical first; FakePlatform mount becomes visible only after domain work.
scenario_1:
 mov edi,4
 call init_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 lea rsi,[rel handle_a]
 call nebo_console_manager_default_get_or_create
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 mov rsi,[rel handle_a]
 lea rdx,[rel domain_a]
 call nebo_console_domain_from_handle
 test eax,eax
 jnz test_fail
 mov rbx,[rel domain_a]
 cmp dword [rbx+NEBO_CONSOLE_DOMAIN_STATE_OFFSET],NEBO_CONSOLE_DOMAIN_STATE_READY
 jne test_fail
 cmp dword [rbx+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET],NEBO_CONSOLE_LIFECYCLE_MOUNT_REQUESTED
 jne test_fail
 cmp qword [rbx+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET],1
 jne test_fail
 lea rdi,[rel context_a]
 mov esi,1
 lea rdx,[rel progress_a]
 call nebo_console_scheduler_run
 test eax,eax
 jnz test_fail
 cmp qword [rel progress_a],1
 jne test_fail
 cmp dword [rbx+NEBO_CONSOLE_DOMAIN_STATE_OFFSET],NEBO_CONSOLE_DOMAIN_STATE_RUNNABLE
 jne test_fail
 cmp dword [rbx+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET],NEBO_CONSOLE_LIFECYCLE_ACTIVE
 jne test_fail
 cmp qword [rel platform_a+NEBO_FAKE_PLATFORM_MOUNT_COUNT_OFFSET],1
 jne test_fail
 lea rdi,[rel context_a]
 mov rsi,[rel handle_a]
 lea rdx,[rel slot_a]
 call nebo_console_manager_handle_validate
 test eax,eax
 jnz test_fail
 mov rax,[rel slot_a]
 test dword [rax+NEBO_CONSOLE_SLOT_FLAGS_OFFSET],NEBO_CONSOLE_SLOT_FLAG_MOUNTED
 jz test_fail
 jmp test_pass

; One queue consumer preserves exact FIFO command order.
scenario_2:
 mov edi,4
 call init_a
 test eax,eax
 jnz test_fail
 call create_and_mount_a
 test eax,eax
 jnz test_fail
 mov rbx,[rel domain_a]
 mov dword [rbx+NEBO_CONSOLE_DOMAIN_FAIRNESS_BUDGET_OFFSET],1
 mov edi,NEBO_CONSOLE_COMMAND_APPEND_TEXT
 mov esi,11
 call send_command_a
 test eax,eax
 jnz test_fail
 mov edi,NEBO_CONSOLE_COMMAND_APPEND_INT
 mov esi,12
 call send_command_a
 test eax,eax
 jnz test_fail
 mov edi,NEBO_CONSOLE_COMMAND_APPEND_BOOL
 mov esi,13
 call send_command_a
 test eax,eax
 jnz test_fail
 mov rdi,rbx
 mov rsi,[rbx+NEBO_CONSOLE_DOMAIN_OWNER_EXECUTION_CONTEXT_OFFSET]
 lea rdx,[rel progress_a]
 call nebo_console_domain_step
 test eax,eax
 jnz test_fail
 cmp dword [rbx+NEBO_CONSOLE_DOMAIN_LAST_COMMAND_KIND_OFFSET],NEBO_CONSOLE_COMMAND_APPEND_TEXT
 jne test_fail
 mov rdi,rbx
 mov rsi,[rbx+NEBO_CONSOLE_DOMAIN_OWNER_EXECUTION_CONTEXT_OFFSET]
 lea rdx,[rel progress_a]
 call nebo_console_domain_step
 test eax,eax
 jnz test_fail
 cmp dword [rbx+NEBO_CONSOLE_DOMAIN_LAST_COMMAND_KIND_OFFSET],NEBO_CONSOLE_COMMAND_APPEND_INT
 jne test_fail
 mov rdi,rbx
 mov rsi,[rbx+NEBO_CONSOLE_DOMAIN_OWNER_EXECUTION_CONTEXT_OFFSET]
 lea rdx,[rel progress_a]
 call nebo_console_domain_step
 test eax,eax
 jnz test_fail
 cmp dword [rbx+NEBO_CONSOLE_DOMAIN_LAST_COMMAND_KIND_OFFSET],NEBO_CONSOLE_COMMAND_APPEND_BOOL
 jne test_fail
 cmp qword [rbx+NEBO_CONSOLE_DOMAIN_PROCESSED_COMMANDS_OFFSET],3
 jne test_fail
 cmp qword [rbx+NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET],0
 jne test_fail
 jmp test_pass

; Adapter events retain FIFO ordering and mutate lifecycle only in the owner domain.
scenario_3:
 mov edi,4
 call init_a
 test eax,eax
 jnz test_fail
 call create_and_mount_a
 test eax,eax
 jnz test_fail
 mov rbx,[rel domain_a]
 mov dword [rbx+NEBO_CONSOLE_DOMAIN_FAIRNESS_BUDGET_OFFSET],1
 lea rdi,[rel platform_a]
 mov rsi,rbx
 mov edx,NEBO_CONSOLE_EVENT_WINDOW_MINIMIZED
 xor ecx,ecx
 xor r8d,r8d
 call nebo_fake_platform_inject_event
 test eax,eax
 jnz test_fail
 lea rdi,[rel platform_a]
 mov rsi,rbx
 mov edx,NEBO_CONSOLE_EVENT_WINDOW_MAXIMIZED
 xor ecx,ecx
 xor r8d,r8d
 call nebo_fake_platform_inject_event
 test eax,eax
 jnz test_fail
 lea rdi,[rel platform_a]
 mov rsi,rbx
 mov edx,NEBO_CONSOLE_EVENT_WINDOW_RESTORED
 xor ecx,ecx
 xor r8d,r8d
 call nebo_fake_platform_inject_event
 test eax,eax
 jnz test_fail
 mov rdi,rbx
 mov rsi,[rbx+NEBO_CONSOLE_DOMAIN_OWNER_EXECUTION_CONTEXT_OFFSET]
 lea rdx,[rel progress_a]
 call nebo_console_domain_step
 test eax,eax
 jnz test_fail
 cmp dword [rbx+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET],NEBO_CONSOLE_LIFECYCLE_MINIMIZED
 jne test_fail
 mov rdi,rbx
 mov rsi,[rbx+NEBO_CONSOLE_DOMAIN_OWNER_EXECUTION_CONTEXT_OFFSET]
 lea rdx,[rel progress_a]
 call nebo_console_domain_step
 test eax,eax
 jnz test_fail
 cmp dword [rbx+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET],NEBO_CONSOLE_LIFECYCLE_MAXIMIZED
 jne test_fail
 mov rdi,rbx
 mov rsi,[rbx+NEBO_CONSOLE_DOMAIN_OWNER_EXECUTION_CONTEXT_OFFSET]
 lea rdx,[rel progress_a]
 call nebo_console_domain_step
 test eax,eax
 jnz test_fail
 cmp dword [rbx+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET],NEBO_CONSOLE_LIFECYCLE_ACTIVE
 jne test_fail
 cmp qword [rbx+NEBO_CONSOLE_DOMAIN_PROCESSED_EVENTS_OFFSET],4
 jne test_fail
 jmp test_pass

; A non-owner execution context cannot mutate lifecycle or drain queues.
scenario_4:
 mov edi,4
 call init_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 lea rsi,[rel handle_a]
 call nebo_console_manager_default_get_or_create
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 mov rsi,[rel handle_a]
 lea rdx,[rel domain_a]
 call nebo_console_domain_from_handle
 test eax,eax
 jnz test_fail
 mov rbx,[rel domain_a]
 mov rdi,rbx
 mov rsi,[rbx+NEBO_CONSOLE_DOMAIN_OWNER_EXECUTION_CONTEXT_OFFSET]
 inc rsi
 lea rdx,[rel progress_a]
 call nebo_console_domain_step
 cmp eax,NEBO_CONSOLE_STATUS_BAD_STATE
 jne test_fail
 cmp qword [rbx+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET],1
 jne test_fail
 cmp dword [rbx+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET],NEBO_CONSOLE_LIFECYCLE_MOUNT_REQUESTED
 jne test_fail
 lea rdi,[rel context_a]
 mov esi,1
 lea rdx,[rel progress_a]
 call nebo_console_scheduler_run
 test eax,eax
 jnz test_fail
 cmp qword [rel progress_a],1
 jne test_fail
 jmp test_pass

; Round-robin foundation advances two domains despite asymmetric pressure.
scenario_5:
 mov edi,8
 call init_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 lea rsi,[rel handle_a]
 call nebo_console_manager_anonymous_create
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 lea rsi,[rel handle_b]
 call nebo_console_manager_anonymous_create
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 mov rsi,[rel handle_a]
 lea rdx,[rel domain_a]
 call nebo_console_domain_from_handle
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 mov rsi,[rel handle_b]
 lea rdx,[rel domain_b]
 call nebo_console_domain_from_handle
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 mov esi,1
 lea rdx,[rel progress_a]
 call nebo_console_scheduler_run
 test eax,eax
 jnz test_fail
 cmp qword [rel progress_a],2
 jne test_fail
 mov rbx,[rel domain_a]
 mov r12,[rel domain_b]
 mov dword [rbx+NEBO_CONSOLE_DOMAIN_FAIRNESS_BUDGET_OFFSET],1
 mov dword [r12+NEBO_CONSOLE_DOMAIN_FAIRNESS_BUDGET_OFFSET],1
 mov edi,NEBO_CONSOLE_COMMAND_APPEND_TEXT
 mov esi,1
 call send_command_a
 test eax,eax
 jnz test_fail
 mov edi,NEBO_CONSOLE_COMMAND_APPEND_INT
 mov esi,2
 call send_command_a
 test eax,eax
 jnz test_fail
 mov edi,NEBO_CONSOLE_COMMAND_APPEND_BOOL
 mov esi,3
 call send_command_a
 test eax,eax
 jnz test_fail
 mov edi,NEBO_CONSOLE_COMMAND_APPLY_BEHAVIOR
 mov esi,4
 call send_command_a
 test eax,eax
 jnz test_fail
 mov r13,[rel handle_a]
 mov rax,[rel handle_b]
 mov [rel handle_a],rax
 mov edi,NEBO_CONSOLE_COMMAND_APPEND_TEXT
 mov esi,1
 call send_command_a
 mov [rel handle_a],r13
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 mov esi,1
 lea rdx,[rel progress_a]
 call nebo_console_scheduler_run
 test eax,eax
 jnz test_fail
 cmp qword [rel progress_a],2
 jne test_fail
 cmp qword [rbx+NEBO_CONSOLE_DOMAIN_PROCESSED_COMMANDS_OFFSET],1
 jne test_fail
 cmp qword [r12+NEBO_CONSOLE_DOMAIN_PROCESSED_COMMANDS_OFFSET],1
 jne test_fail
 cmp qword [rbx+NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET],3
 jne test_fail
 cmp qword [r12+NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET],0
 jne test_fail
 jmp test_pass

; Bounded command/event queues report pressure without silent loss.
scenario_6:
 mov edi,2
 call init_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 lea rsi,[rel handle_a]
 call nebo_console_manager_default_get_or_create
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 mov rsi,[rel handle_a]
 lea rdx,[rel domain_a]
 call nebo_console_domain_from_handle
 test eax,eax
 jnz test_fail
 mov edi,NEBO_CONSOLE_COMMAND_APPEND_TEXT
 mov esi,1
 call send_command_a
 test eax,eax
 jnz test_fail
 mov edi,NEBO_CONSOLE_COMMAND_APPEND_INT
 mov esi,2
 call send_command_a
 test eax,eax
 jnz test_fail
 mov edi,NEBO_CONSOLE_COMMAND_APPEND_BOOL
 mov esi,3
 call send_command_a
 cmp eax,NEBO_CONSOLE_STATUS_QUEUE_FULL
 jne test_fail
 mov rbx,[rel domain_a]
 cmp qword [rbx+NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET],2
 jne test_fail
 cmp qword [rel context_a+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET],NEBO_CONSOLE_ERROR_COMMAND_QUEUE_FULL
 jne test_fail
 lea rdi,[rel platform_a]
 mov rsi,rbx
 mov edx,NEBO_CONSOLE_EVENT_TIMER_TICK
 xor ecx,ecx
 xor r8d,r8d
 call nebo_fake_platform_inject_event
 test eax,eax
 jnz test_fail
 lea rdi,[rel platform_a]
 mov rsi,rbx
 mov edx,NEBO_CONSOLE_EVENT_PRESENT_COMPLETE
 xor ecx,ecx
 xor r8d,r8d
 call nebo_fake_platform_inject_event
 cmp eax,NEBO_CONSOLE_STATUS_QUEUE_FULL
 jne test_fail
 cmp qword [rbx+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET],2
 jne test_fail
 cmp qword [rel context_a+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET],NEBO_CONSOLE_ERROR_EVENT_QUEUE_FULL
 jne test_fail
 jmp test_pass

; Identical logical runs yield identical pointer-free manager/domain/platform hashes.
scenario_7:
 mov edi,4
 call init_a
 test eax,eax
 jnz test_fail
 mov edi,4
 call init_b
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 lea rsi,[rel handle_a]
 call run_trace
 test eax,eax
 jnz test_fail
 lea rdi,[rel hashes_a]
 call capture_hashes_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_b]
 lea rsi,[rel handle_b]
 call run_trace
 test eax,eax
 jnz test_fail
 lea rdi,[rel hashes_b]
 call capture_hashes_b
 test eax,eax
 jnz test_fail
 lea rdi,[rel hashes_a]
 lea rsi,[rel hashes_b]
 mov ecx,4
.compare_hashes:
 mov rax,[rdi]
 test rax,rax
 jz test_fail
 cmp rax,[rsi]
 jne test_fail
 add rdi,8
 add rsi,8
 dec ecx
 jnz .compare_hashes
 jmp test_pass

; Close is queued, owner-drained, platform-closed and generation-invalidating.
scenario_8:
 mov edi,4
 call init_a
 test eax,eax
 jnz test_fail
 call create_and_mount_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 mov rsi,[rel handle_a]
 call nebo_console_manager_close
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 mov rsi,[rel handle_a]
 lea rdx,[rel slot_a]
 call nebo_console_manager_handle_validate
 cmp eax,NEBO_CONSOLE_STATUS_BAD_STATE
 jne test_fail
 mov eax,[rel handle_a]
 shl rax,6
 add rax,[rel context_a+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_SLOTS_PTR_OFFSET]
 cmp dword [rax+NEBO_CONSOLE_SLOT_STATE_OFFSET],NEBO_CONSOLE_SLOT_STATE_CLOSING
 jne test_fail
 lea rdi,[rel context_a]
 mov esi,4
 lea rdx,[rel progress_a]
 call nebo_console_scheduler_run
 test eax,eax
 jnz test_fail
 cmp qword [rel context_a+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET],0
 jne test_fail
 cmp qword [rel platform_a+NEBO_FAKE_PLATFORM_CLOSE_COUNT_OFFSET],1
 jne test_fail
 mov rbx,[rel domain_a]
 cmp dword [rbx+NEBO_CONSOLE_DOMAIN_STATE_OFFSET],NEBO_CONSOLE_DOMAIN_STATE_STOPPED
 jne test_fail
 lea rdi,[rel context_a]
 mov rsi,[rel handle_a]
 lea rdx,[rel slot_a]
 call nebo_console_manager_handle_validate
 cmp eax,NEBO_CONSOLE_STATUS_HANDLE_CLOSED
 jne test_fail
 jmp test_pass

; Runtime binding enforces approved DG-009 capacities.
scenario_9:
 lea rdi,[rel context_a]
 lea rsi,[rel slots_a]
 mov edx,TEST_DOMAIN_CAPACITY
 mov ecx,NEBO_CONSOLE_RUNTIME_ABI_VERSION
 call nebo_console_runtime_context_init
 test eax,eax
 jnz test_fail
 call populate_storage_a
 mov qword [rel storage_a+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAIN_CAPACITY_OFFSET],TEST_DOMAIN_CAPACITY-1
 lea rdi,[rel context_a]
 lea rsi,[rel storage_a]
 call nebo_console_runtime_headless_bind
 cmp eax,NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
 jne test_fail
 lea rdi,[rel context_a]
 lea rsi,[rel slots_a]
 mov edx,TEST_DOMAIN_CAPACITY
 mov ecx,NEBO_CONSOLE_RUNTIME_ABI_VERSION
 call nebo_console_runtime_context_init
 test eax,eax
 jnz test_fail
 call populate_storage_a
 mov qword [rel storage_a+NEBO_CONSOLE_HEADLESS_STORAGE_QUEUE_CAPACITY_OFFSET],NEBO_CONSOLE_MAX_QUEUED_COMMANDS+1
 lea rdi,[rel context_a]
 lea rsi,[rel storage_a]
 call nebo_console_runtime_headless_bind
 cmp eax,NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
 jne test_fail
 jmp test_pass

; EDI=queue capacity.
init_a:
 push r12
 mov r12d,edi
 lea rdi,[rel context_a]
 lea rsi,[rel slots_a]
 mov edx,TEST_DOMAIN_CAPACITY
 mov ecx,NEBO_CONSOLE_RUNTIME_ABI_VERSION
 call nebo_console_runtime_context_init
 test eax,eax
 jnz .init_a_done
 call populate_storage_a
 mov [rel storage_a+NEBO_CONSOLE_HEADLESS_STORAGE_QUEUE_CAPACITY_OFFSET],r12
 lea rdi,[rel context_a]
 lea rsi,[rel storage_a]
 call nebo_console_runtime_headless_bind
.init_a_done:
 pop r12
 ret

populate_storage_a:
 lea rax,[rel clock_a]
 mov [rel storage_a+NEBO_CONSOLE_HEADLESS_STORAGE_CLOCK_PTR_OFFSET],rax
 lea rax,[rel platform_a]
 mov [rel storage_a+NEBO_CONSOLE_HEADLESS_STORAGE_PLATFORM_PTR_OFFSET],rax
 lea rax,[rel scheduler_a]
 mov [rel storage_a+NEBO_CONSOLE_HEADLESS_STORAGE_SCHEDULER_PTR_OFFSET],rax
 lea rax,[rel domains_a]
 mov [rel storage_a+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAINS_PTR_OFFSET],rax
 lea rax,[rel command_buffers_a]
 mov [rel storage_a+NEBO_CONSOLE_HEADLESS_STORAGE_COMMAND_BUFFERS_PTR_OFFSET],rax
 lea rax,[rel event_buffers_a]
 mov [rel storage_a+NEBO_CONSOLE_HEADLESS_STORAGE_EVENT_BUFFERS_PTR_OFFSET],rax
 mov qword [rel storage_a+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAIN_CAPACITY_OFFSET],TEST_DOMAIN_CAPACITY
 mov qword [rel storage_a+NEBO_CONSOLE_HEADLESS_STORAGE_QUEUE_CAPACITY_OFFSET],4
 ret

; EDI=queue capacity.
init_b:
 push r12
 mov r12d,edi
 lea rdi,[rel context_b]
 lea rsi,[rel slots_b]
 mov edx,TEST_DOMAIN_CAPACITY
 mov ecx,NEBO_CONSOLE_RUNTIME_ABI_VERSION
 call nebo_console_runtime_context_init
 test eax,eax
 jnz .init_b_done
 call populate_storage_b
 mov [rel storage_b+NEBO_CONSOLE_HEADLESS_STORAGE_QUEUE_CAPACITY_OFFSET],r12
 lea rdi,[rel context_b]
 lea rsi,[rel storage_b]
 call nebo_console_runtime_headless_bind
.init_b_done:
 pop r12
 ret

populate_storage_b:
 lea rax,[rel clock_b]
 mov [rel storage_b+NEBO_CONSOLE_HEADLESS_STORAGE_CLOCK_PTR_OFFSET],rax
 lea rax,[rel platform_b]
 mov [rel storage_b+NEBO_CONSOLE_HEADLESS_STORAGE_PLATFORM_PTR_OFFSET],rax
 lea rax,[rel scheduler_b]
 mov [rel storage_b+NEBO_CONSOLE_HEADLESS_STORAGE_SCHEDULER_PTR_OFFSET],rax
 lea rax,[rel domains_b]
 mov [rel storage_b+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAINS_PTR_OFFSET],rax
 lea rax,[rel command_buffers_b]
 mov [rel storage_b+NEBO_CONSOLE_HEADLESS_STORAGE_COMMAND_BUFFERS_PTR_OFFSET],rax
 lea rax,[rel event_buffers_b]
 mov [rel storage_b+NEBO_CONSOLE_HEADLESS_STORAGE_EVENT_BUFFERS_PTR_OFFSET],rax
 mov qword [rel storage_b+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAIN_CAPACITY_OFFSET],TEST_DOMAIN_CAPACITY
 mov qword [rel storage_b+NEBO_CONSOLE_HEADLESS_STORAGE_QUEUE_CAPACITY_OFFSET],4
 ret

create_and_mount_a:
 lea rdi,[rel context_a]
 lea rsi,[rel handle_a]
 call nebo_console_manager_default_get_or_create
 test eax,eax
 jnz .create_mount_done
 lea rdi,[rel context_a]
 mov rsi,[rel handle_a]
 lea rdx,[rel domain_a]
 call nebo_console_domain_from_handle
 test eax,eax
 jnz .create_mount_done
 lea rdi,[rel context_a]
 mov esi,1
 lea rdx,[rel progress_a]
 call nebo_console_scheduler_run
.create_mount_done:
 ret

; EDI=kind, ESI=source order. Uses context_a/handle_a.
send_command_a:
 push r12
 push r13
 mov r12d,edi
 mov r13d,esi
 lea rdi,[rel command_a]
 xor eax,eax
 mov ecx,NEBO_CONSOLE_COMMAND_DESCRIPTOR_QWORDS
 rep stosq
 mov [rel command_a+NEBO_CONSOLE_COMMAND_KIND_OFFSET],r12d
 mov [rel command_a+NEBO_CONSOLE_COMMAND_SOURCE_ORDER_OFFSET],r13
 lea rdi,[rel context_a]
 mov rsi,[rel handle_a]
 lea rdx,[rel command_a]
 call nebo_console_domain_send
 pop r13
 pop r12
 ret

; RDI=context*, RSI=out handle*. Produces identical deterministic trace.
run_trace:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov rdi,r12
 mov rsi,r13
 call nebo_console_manager_default_get_or_create
 test eax,eax
 jnz .trace_done
 mov rdi,r12
 mov rsi,[r13]
 lea rdx,[rsp]
 call nebo_console_domain_from_handle
 test eax,eax
 jnz .trace_done
 mov r14,[rsp]
 mov rdi,r12
 mov esi,1
 lea rdx,[rsp+8]
 call nebo_console_scheduler_run
 test eax,eax
 jnz .trace_done
 lea rdi,[rel command_a]
 xor eax,eax
 mov ecx,NEBO_CONSOLE_COMMAND_DESCRIPTOR_QWORDS
 rep stosq
 mov dword [rel command_a+NEBO_CONSOLE_COMMAND_KIND_OFFSET],NEBO_CONSOLE_COMMAND_APPEND_TEXT
 mov qword [rel command_a+NEBO_CONSOLE_COMMAND_SOURCE_ORDER_OFFSET],1
 mov rdi,r12
 mov rsi,[r13]
 lea rdx,[rel command_a]
 call nebo_console_domain_send
 test eax,eax
 jnz .trace_done
 mov rdi,[r12+NEBO_CONSOLE_CONTEXT_PLATFORM_PTR_OFFSET]
 mov rsi,r14
 mov edx,NEBO_CONSOLE_EVENT_TIMER_TICK
 mov ecx,7
 mov r8d,9
 call nebo_fake_platform_inject_event
 test eax,eax
 jnz .trace_done
 mov rdi,r12
 mov esi,4
 lea rdx,[rsp+8]
 call nebo_console_scheduler_run
.trace_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

capture_hashes_a:
 push r12
 mov r12,rdi
 lea rdi,[rel context_a]
 call nebo_console_manager_state_hash
 mov [r12],rax
 mov rdi,[rel domain_a]
 test rdi,rdi
 jnz .capture_a_domain_ready
 lea rdi,[rel context_a]
 mov rsi,[rel handle_a]
 lea rdx,[rel domain_a]
 call nebo_console_domain_from_handle
 test eax,eax
 jnz .capture_a_done
 mov rdi,[rel domain_a]
.capture_a_domain_ready:
 call nebo_console_domain_state_hash
 mov [r12+8],rax
 lea rdi,[rel platform_a]
 call nebo_fake_platform_state_hash
 mov [r12+16],rax
 lea rdi,[rel scheduler_a]
 call nebo_console_scheduler_state_hash
 mov [r12+24],rax
 xor eax,eax
.capture_a_done:
 pop r12
 ret

capture_hashes_b:
 push r12
 mov r12,rdi
 lea rdi,[rel context_b]
 call nebo_console_manager_state_hash
 mov [r12],rax
 lea rdi,[rel context_b]
 mov rsi,[rel handle_b]
 lea rdx,[rel domain_b]
 call nebo_console_domain_from_handle
 test eax,eax
 jnz .capture_b_done
 mov rdi,[rel domain_b]
 call nebo_console_domain_state_hash
 mov [r12+8],rax
 lea rdi,[rel platform_b]
 call nebo_fake_platform_state_hash
 mov [r12+16],rax
 lea rdi,[rel scheduler_b]
 call nebo_console_scheduler_state_hash
 mov [r12+24],rax
 xor eax,eax
.capture_b_done:
 pop r12
 ret

test_pass:
 xor edi,edi
 call neboc_host_process_exit
 hlt

test_fail:
 mov edi,1
 call neboc_host_process_exit
 hlt

test_usage:
 mov edi,2
 call neboc_host_process_exit
 hlt

section .note.GNU-stack noalloc noexec nowrite progbits
