; Nebo Assembly — MF041 Console Runtime ABI/Manager scenarios
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/handles/console_handle.inc"
%include "runtime/console/manager/console_manager.inc"

extern nebo_console_handle_pack
extern nebo_console_handle_unpack
extern nebo_console_handle_is_valid
extern nebo_console_runtime_context_init
extern nebo_console_manager_default_get_or_create
extern nebo_console_manager_named_create
extern nebo_console_manager_anonymous_create
extern nebo_console_manager_handle_validate
extern nebo_console_manager_close
extern nebo_console_manager_note_logical_command
extern nebo_console_manager_state_hash
extern nebo_console_manager_diagnostic_name
extern neboc_host_process_exit

global _start

section .rodata
name_a_data: db 'a'
name_b_data: db 'b'
name_a_descriptor:
 dq name_a_data
 dq 1
 dd 0
 dw NEBO_RUNTIME_TEXT_ENCODING_UTF8
 dw NEBO_RUNTIME_TEXT_LIFETIME_STATIC
name_b_descriptor:
 dq name_b_data
 dq 1
 dd 0
 dw NEBO_RUNTIME_TEXT_ENCODING_UTF8
 dw NEBO_RUNTIME_TEXT_LIFETIME_STATIC
expected_handle_invalid: db 'handle-invalid'
expected_handle_invalid_len equ $-expected_handle_invalid

section .bss align=64
context_a: resb NEBO_CONSOLE_CONTEXT_SIZE
context_b: resb NEBO_CONSOLE_CONTEXT_SIZE
slots_a: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_CONSOLE_SLOT_SIZE
slots_b: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_CONSOLE_SLOT_SIZE
handle_a: resq 1
handle_b: resq 1
handle_c: resq 1
handle_d: resq 1
slot_ptr_a: resq 1
slot_ptr_b: resq 1
diag_ptr: resq 1
diag_len: resq 1
hash_a: resq 1
hash_b: resq 1
unpacked_slot: resd 1
unpacked_generation: resd 1
sequence_a: resq 4
sequence_b: resq 4

section .text
_start:
 mov rax,[rsp]
 cmp rax,2
 jne test_usage
 mov rbx,[rsp+16]
 cmp byte [rbx],'1'
 jne .single_digit
 cmp byte [rbx+1],'0'
 jne .single_digit
 cmp byte [rbx+2],0
 jne test_usage
 jmp scenario_10
.single_digit:
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

; NEBO-CONSOLE-HEADLESS-001 — first default creates exactly one active slot.
scenario_1:
 call init_a_64
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 lea rsi,[rel handle_a]
 call nebo_console_manager_default_get_or_create
 test eax,eax
 jnz test_fail
 cmp qword [rel handle_a],NEBO_CONSOLE_HANDLE_INVALID
 je test_fail
 cmp qword [rel context_a+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET],1
 jne test_fail
 mov rax,[rel handle_a]
 cmp [rel context_a+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_DEFAULT_HANDLE_OFFSET],rax
 jne test_fail
 lea rdi,[rel context_a]
 mov rsi,rax
 lea rdx,[rel slot_ptr_a]
 call nebo_console_manager_handle_validate
 test eax,eax
 jnz test_fail
 mov rbx,[rel slot_ptr_a]
 cmp dword [rbx+NEBO_CONSOLE_SLOT_STATE_OFFSET],NEBO_CONSOLE_SLOT_STATE_ACTIVE
 jne test_fail
 cmp dword [rbx+NEBO_CONSOLE_SLOT_KIND_OFFSET],NEBO_CONSOLE_KIND_DEFAULT
 jne test_fail
 cmp dword [rbx+NEBO_CONSOLE_SLOT_GENERATION_OFFSET],1
 jne test_fail
 jmp test_pass

; NEBO-CONSOLE-HEADLESS-002 — default reuse preserves the same handle/generation.
scenario_2:
 call init_a_64
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 lea rsi,[rel handle_a]
 call nebo_console_manager_default_get_or_create
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 lea rsi,[rel handle_b]
 call nebo_console_manager_default_get_or_create
 test eax,eax
 jnz test_fail
 mov rax,[rel handle_a]
 cmp rax,[rel handle_b]
 jne test_fail
 cmp qword [rel context_a+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET],1
 jne test_fail
 mov rdx,rax
 shr rdx,NEBO_CONSOLE_HANDLE_GENERATION_SHIFT
 cmp edx,1
 jne test_fail
 jmp test_pass

; NEBO-CONSOLE-HEADLESS-003 — named a/b own independent slots and state.
scenario_3:
 call init_a_64
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 lea rsi,[rel name_a_descriptor]
 lea rdx,[rel handle_a]
 call nebo_console_manager_named_create
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 lea rsi,[rel name_b_descriptor]
 lea rdx,[rel handle_b]
 call nebo_console_manager_named_create
 test eax,eax
 jnz test_fail
 mov rax,[rel handle_a]
 cmp rax,[rel handle_b]
 je test_fail
 cmp eax,[rel handle_b]
 je test_fail
 cmp qword [rel context_a+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET],2
 jne test_fail
 lea rdi,[rel context_a]
 mov rsi,[rel handle_a]
 lea rdx,[rel slot_ptr_a]
 call nebo_console_manager_handle_validate
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 mov rsi,[rel handle_b]
 lea rdx,[rel slot_ptr_b]
 call nebo_console_manager_handle_validate
 test eax,eax
 jnz test_fail
 mov rbx,[rel slot_ptr_a]
 mov r12,[rel slot_ptr_b]
 cmp dword [rbx+NEBO_CONSOLE_SLOT_KIND_OFFSET],NEBO_CONSOLE_KIND_NAMED
 jne test_fail
 cmp dword [r12+NEBO_CONSOLE_SLOT_KIND_OFFSET],NEBO_CONSOLE_KIND_NAMED
 jne test_fail
 cmp qword [rbx+NEBO_CONSOLE_SLOT_NAME_LENGTH_OFFSET],1
 jne test_fail
 cmp qword [r12+NEBO_CONSOLE_SLOT_NAME_LENGTH_OFFSET],1
 jne test_fail
 lea rdi,[rel context_a]
 mov rsi,[rel handle_a]
 call nebo_console_manager_note_logical_command
 test eax,eax
 jnz test_fail
 cmp qword [rbx+NEBO_CONSOLE_SLOT_PREMOUNT_COMMAND_COUNT_OFFSET],1
 jne test_fail
 cmp qword [r12+NEBO_CONSOLE_SLOT_PREMOUNT_COMMAND_COUNT_OFFSET],0
 jne test_fail
 jmp test_pass

; NEBO-CONSOLE-HEADLESS-004 — anonymous creations never alias one another.
scenario_4:
 call init_a_64
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
 mov rax,[rel handle_a]
 cmp rax,[rel handle_b]
 je test_fail
 cmp eax,[rel handle_b]
 je test_fail
 cmp qword [rel context_a+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET],2
 jne test_fail
 cmp qword [rel context_a+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_ANONYMOUS_COUNT_OFFSET],2
 jne test_fail
 jmp test_pass

; NEBO-CONSOLE-HEADLESS-005 — stale generation cannot alias a reused slot.
scenario_5:
 call init_a_64
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 lea rsi,[rel handle_a]
 call nebo_console_manager_anonymous_create
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 mov rsi,[rel handle_a]
 call nebo_console_manager_close
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 lea rsi,[rel handle_b]
 call nebo_console_manager_anonymous_create
 test eax,eax
 jnz test_fail
 mov eax,[rel handle_a]
 cmp eax,[rel handle_b]
 jne test_fail
 mov rax,[rel handle_a]
 shr rax,NEBO_CONSOLE_HANDLE_GENERATION_SHIFT
 mov rdx,[rel handle_b]
 shr rdx,NEBO_CONSOLE_HANDLE_GENERATION_SHIFT
 cmp eax,edx
 je test_fail
 lea rdi,[rel context_a]
 mov rsi,[rel handle_a]
 lea rdx,[rel slot_ptr_a]
 call nebo_console_manager_handle_validate
 cmp eax,NEBO_CONSOLE_STATUS_HANDLE_CLOSED
 jne test_fail
 cmp qword [rel slot_ptr_a],0
 jne test_fail
 lea rdi,[rel context_a]
 mov rsi,[rel handle_b]
 lea rdx,[rel slot_ptr_b]
 call nebo_console_manager_handle_validate
 test eax,eax
 jnz test_fail
 jmp test_pass

; NEBO-CONSOLE-HEADLESS-006 — closing/recreating default advances generation.
scenario_6:
 call init_a_64
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 lea rsi,[rel handle_a]
 call nebo_console_manager_default_get_or_create
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 mov rsi,[rel handle_a]
 call nebo_console_manager_close
 test eax,eax
 jnz test_fail
 cmp qword [rel context_a+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_DEFAULT_HANDLE_OFFSET],0
 jne test_fail
 lea rdi,[rel context_a]
 lea rsi,[rel handle_b]
 call nebo_console_manager_default_get_or_create
 test eax,eax
 jnz test_fail
 mov eax,[rel handle_a]
 cmp eax,[rel handle_b]
 jne test_fail
 mov rax,[rel handle_a]
 shr rax,NEBO_CONSOLE_HANDLE_GENERATION_SHIFT
 mov rdx,[rel handle_b]
 shr rdx,NEBO_CONSOLE_HANDLE_GENERATION_SHIFT
 cmp eax,edx
 je test_fail
 jmp test_pass

; NEBO-CONSOLE-NEG-007 — zero/out-of-range handles have stable diagnostic.
scenario_7:
 ; DG-006 helper boundary: generation zero/handle zero are invalid, while
 ; slot zero with generation one is a valid physical handle.
 xor edi,edi
 xor esi,esi
 call nebo_console_handle_pack
 test rax,rax
 jnz test_fail
 xor edi,edi
 call nebo_console_handle_is_valid
 test eax,eax
 jnz test_fail
 xor edi,edi
 mov esi,1
 call nebo_console_handle_pack
 mov rdx,0x0000000100000000
 cmp rax,rdx
 jne test_fail
 mov rdi,rax
 call nebo_console_handle_is_valid
 cmp eax,1
 jne test_fail
 mov rdi,0x0000000100000000
 lea rsi,[rel unpacked_slot]
 lea rdx,[rel unpacked_generation]
 call nebo_console_handle_unpack
 test eax,eax
 jnz test_fail
 cmp dword [rel unpacked_slot],0
 jne test_fail
 cmp dword [rel unpacked_generation],1
 jne test_fail
 xor edi,edi
 lea rsi,[rel unpacked_slot]
 lea rdx,[rel unpacked_generation]
 call nebo_console_handle_unpack
 cmp eax,NEBO_CONSOLE_STATUS_HANDLE_INVALID
 jne test_fail
 cmp dword [rel unpacked_slot],0
 jne test_fail
 cmp dword [rel unpacked_generation],0
 jne test_fail

 call init_a_64
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 xor esi,esi
 lea rdx,[rel slot_ptr_a]
 call nebo_console_manager_handle_validate
 cmp eax,NEBO_CONSOLE_STATUS_HANDLE_INVALID
 jne test_fail
 cmp qword [rel context_a+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET],NEBO_CONSOLE_ERROR_HANDLE_INVALID
 jne test_fail
 mov edi,NEBO_CONSOLE_ERROR_HANDLE_INVALID
 lea rsi,[rel diag_ptr]
 lea rdx,[rel diag_len]
 call nebo_console_manager_diagnostic_name
 test eax,eax
 jnz test_fail
 cmp qword [rel diag_len],expected_handle_invalid_len
 jne test_fail
 mov rdi,[rel diag_ptr]
 lea rsi,[rel expected_handle_invalid]
 mov rcx,expected_handle_invalid_len
 cld
 repe cmpsb
 jne test_fail
 lea rdi,[rel context_a]
 mov rsi,0x0000000100000040
 lea rdx,[rel slot_ptr_a]
 call nebo_console_manager_handle_validate
 cmp eax,NEBO_CONSOLE_STATUS_HANDLE_INVALID
 jne test_fail
 jmp test_pass

; NEBO-CONSOLE-HEADLESS-008 — the 65th active Console is rejected.
scenario_8:
 call init_a_64
 test eax,eax
 jnz test_fail
 xor r12d,r12d
.limit_loop:
 cmp r12d,NEBO_CONSOLE_MAX_ACTIVE
 jae .limit_probe
 lea rdi,[rel context_a]
 lea rsi,[rel handle_a]
 call nebo_console_manager_anonymous_create
 test eax,eax
 jnz test_fail
 inc r12d
 jmp .limit_loop
.limit_probe:
 lea rdi,[rel context_a]
 lea rsi,[rel handle_b]
 call nebo_console_manager_anonymous_create
 cmp eax,NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
 jne test_fail
 cmp qword [rel handle_b],NEBO_CONSOLE_HANDLE_INVALID
 jne test_fail
 cmp qword [rel context_a+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET],NEBO_CONSOLE_MAX_ACTIVE
 jne test_fail
 cmp qword [rel context_a+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_ANONYMOUS_COUNT_OFFSET],NEBO_CONSOLE_MAX_ACTIVE
 jne test_fail
 cmp qword [rel context_a+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET],NEBO_CONSOLE_ERROR_LIMIT
 jne test_fail
 jmp test_pass

; NEBO-CONSOLE-HEADLESS-009 — logical create accepts pre-mount work.
scenario_9:
 call init_a_64
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 lea rsi,[rel name_a_descriptor]
 lea rdx,[rel handle_a]
 call nebo_console_manager_named_create
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 mov rsi,[rel handle_a]
 lea rdx,[rel slot_ptr_a]
 call nebo_console_manager_handle_validate
 test eax,eax
 jnz test_fail
 mov rbx,[rel slot_ptr_a]
 test dword [rbx+NEBO_CONSOLE_SLOT_FLAGS_OFFSET],NEBO_CONSOLE_SLOT_FLAG_LOGICAL_READY
 jz test_fail
 test dword [rbx+NEBO_CONSOLE_SLOT_FLAGS_OFFSET],NEBO_CONSOLE_SLOT_FLAG_MOUNTED
 jnz test_fail
 lea rdi,[rel context_a]
 mov rsi,[rel handle_a]
 call nebo_console_manager_note_logical_command
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 mov rsi,[rel handle_a]
 call nebo_console_manager_note_logical_command
 test eax,eax
 jnz test_fail
 cmp qword [rbx+NEBO_CONSOLE_SLOT_PREMOUNT_COMMAND_COUNT_OFFSET],2
 jne test_fail
 jmp test_pass

; NEBO-CONSOLE-DETERMINISM-010 — pointer-free state and logical IDs repeat.
scenario_10:
 call init_a_64
 test eax,eax
 jnz test_fail
 call init_b_64
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_a]
 lea rsi,[rel sequence_a]
 call run_deterministic_sequence
 test eax,eax
 jnz test_fail
 lea rdi,[rel context_b]
 lea rsi,[rel sequence_b]
 call run_deterministic_sequence
 test eax,eax
 jnz test_fail
 lea rdi,[rel sequence_a]
 lea rsi,[rel sequence_b]
 mov ecx,4
.compare_sequence:
 mov rax,[rdi]
 cmp rax,[rsi]
 jne test_fail
 add rdi,8
 add rsi,8
 dec ecx
 jnz .compare_sequence
 lea rdi,[rel context_a]
 call nebo_console_manager_state_hash
 test eax,eax
 jz test_fail
 mov [rel hash_a],rax
 lea rdi,[rel context_b]
 call nebo_console_manager_state_hash
 test eax,eax
 jz test_fail
 mov [rel hash_b],rax
 mov rax,[rel hash_a]
 cmp rax,[rel hash_b]
 jne test_fail
 jmp test_pass

init_a_64:
 lea rdi,[rel context_a]
 lea rsi,[rel slots_a]
 mov edx,NEBO_CONSOLE_MAX_ACTIVE
 mov ecx,NEBO_CONSOLE_RUNTIME_ABI_VERSION
 jmp nebo_console_runtime_context_init

init_b_64:
 lea rdi,[rel context_b]
 lea rsi,[rel slots_b]
 mov edx,NEBO_CONSOLE_MAX_ACTIVE
 mov ecx,NEBO_CONSOLE_RUNTIME_ABI_VERSION
 jmp nebo_console_runtime_context_init

; context*, output_handles[4]
run_deterministic_sequence:
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
 jnz .sequence_done
 mov rdi,r12
 lea rsi,[rel name_a_descriptor]
 lea rdx,[r13+8]
 call nebo_console_manager_named_create
 test eax,eax
 jnz .sequence_done
 mov rdi,r12
 lea rsi,[r13+16]
 call nebo_console_manager_anonymous_create
 test eax,eax
 jnz .sequence_done
 mov rdi,r12
 mov rsi,[r13+8]
 call nebo_console_manager_close
 test eax,eax
 jnz .sequence_done
 mov rdi,r12
 lea rsi,[rel name_b_descriptor]
 lea rdx,[r13+24]
 call nebo_console_manager_named_create
.sequence_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
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
