; RELEASE-GOVERNANCE-E-ENCERRAMENTO-DE-PROGRAMAS-F09 deterministic progress, bounded logs and exit contracts.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/driver/cli/linux-x86_64/cli_driver.inc"
%include "compiler/diagnostics/renderer.inc"
%include "compiler/diagnostics/observability.inc"

section .rodata
summary_phase: db 'progress phase='
summary_phase_len equ $-summary_phase
summary_total: db ' total='
summary_total_len equ $-summary_total
summary_completed: db ' completed='
summary_completed_len equ $-summary_completed
summary_success: db ' success='
summary_success_len equ $-summary_success
summary_failed: db ' failed='
summary_failed_len equ $-summary_failed
newline: db 10

section .text
obs_append:
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .ok
 test rsi,rsi
 jz .invalid
 mov r8,[rdi+NEBOC_WRITER_LENGTH_OFFSET]
 mov r9,r8
 add r9,rdx
 jc .limit
 cmp r9,[rdi+NEBOC_WRITER_CAPACITY_OFFSET]
 ja .limit
 mov r10,[rdi+NEBOC_WRITER_BYTES_OFFSET]
 test r10,r10
 jz .invalid
 add r10,r8
 xor ecx,ecx
.copy:
 cmp rcx,rdx
 jae .store
 mov al,[rsi+rcx]
 mov [r10+rcx],al
 inc rcx
 jmp .copy
.store:
 mov [rdi+NEBOC_WRITER_LENGTH_OFFSET],r9
.ok:
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

obs_u64:
 push rbx
 sub rsp,32
 mov rbx,rdi
 mov rax,rsi
 lea rsi,[rsp+32]
 xor ecx,ecx
 test rax,rax
 jnz .digits
 dec rsi
 mov byte [rsi],'0'
 mov ecx,1
 jmp .emit
.digits:
 mov r8d,10
.loop:
 xor edx,edx
 div r8
 add dl,'0'
 dec rsi
 mov [rsi],dl
 inc ecx
 test rax,rax
 jnz .loop
.emit:
 mov rdi,rbx
 mov edx,ecx
 call obs_append
 add rsp,32
 pop rbx
 ret

NEBOC_ABI_FUNCTION neboc_progress_phase_started
 test rdi,rdi
 jz .phase_invalid
 test rsi,rsi
 jz .phase_invalid
 test rdx,rdx
 jz .phase_invalid
 cmp rdx,NEBOC_PROGRESS_MAX_UNITS
 ja .phase_limit
 mov [rdi+NEBOC_PROGRESS_PHASE_OFFSET],rsi
 mov [rdi+NEBOC_PROGRESS_UNIT_COUNT_OFFSET],rdx
 mov qword [rdi+NEBOC_PROGRESS_COMPLETED_OFFSET],0
 mov qword [rdi+NEBOC_PROGRESS_SUCCESS_OFFSET],0
 mov qword [rdi+NEBOC_PROGRESS_FAILED_OFFSET],0
 mov qword [rdi+NEBOC_PROGRESS_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.phase_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.phase_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_progress_unit_finished
 test rdi,rdi
 jz .unit_invalid
 cmp qword [rdi+NEBOC_PROGRESS_ACTIVE_OFFSET],1
 jne .unit_invalid
 mov rax,[rdi+NEBOC_PROGRESS_COMPLETED_OFFSET]
 inc rax
 cmp rsi,rax
 jne .unit_invalid
 cmp rsi,[rdi+NEBOC_PROGRESS_UNIT_COUNT_OFFSET]
 ja .unit_invalid
 cmp rdx,NEBOC_PROGRESS_OUTCOME_SUCCESS
 je .unit_success
 cmp rdx,NEBOC_PROGRESS_OUTCOME_FAILURE
 jne .unit_invalid
 inc qword [rdi+NEBOC_PROGRESS_FAILED_OFFSET]
 jmp .unit_store
.unit_success:
 inc qword [rdi+NEBOC_PROGRESS_SUCCESS_OFFSET]
.unit_store:
 mov [rdi+NEBOC_PROGRESS_COMPLETED_OFFSET],rsi
 xor eax,eax
 ret
.unit_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_compiler_log_init
 test rdi,rdi
 jz .log_init_invalid
 test rsi,rsi
 jz .log_init_invalid
 test rdx,rdx
 jz .log_init_invalid
 cmp rdx,NEBOC_LOG_MAX_ENTRIES
 ja .log_init_limit
 test rcx,rcx
 jz .log_init_invalid
 cmp rcx,NEBOC_LOG_MAX_BUDGET_BYTES
 ja .log_init_limit
 mov [rdi+NEBOC_LOG_ENTRIES_OFFSET],rsi
 mov [rdi+NEBOC_LOG_CAPACITY_OFFSET],rdx
 mov qword [rdi+NEBOC_LOG_COUNT_OFFSET],0
 mov [rdi+NEBOC_LOG_BUDGET_OFFSET],rcx
 mov qword [rdi+NEBOC_LOG_USED_OFFSET],0
 mov qword [rdi+NEBOC_LOG_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.log_init_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.log_init_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; CompilerLog.record(state*, request*) stores borrowed slices and never emits.
NEBOC_ABI_FUNCTION neboc_compiler_log_record
 test rdi,rdi
 jz .log_invalid
 test rsi,rsi
 jz .log_invalid
 cmp qword [rdi+NEBOC_LOG_ACTIVE_OFFSET],1
 jne .log_invalid
 mov rax,[rsi+NEBOC_LOG_REQUEST_LEVEL_OFFSET]
 cmp rax,NEBOC_LOG_LEVEL_DEBUG
 jb .log_invalid
 cmp rax,NEBOC_LOG_LEVEL_DECISION
 ja .log_invalid
 mov rdx,[rsi+NEBOC_LOG_REQUEST_COMPONENT_LENGTH_OFFSET]
 test rdx,rdx
 jz .log_invalid
 cmp rdx,NEBOC_LOG_MAX_COMPONENT_BYTES
 ja .log_limit
 cmp qword [rsi+NEBOC_LOG_REQUEST_COMPONENT_OFFSET],0
 je .log_invalid
 mov rcx,[rsi+NEBOC_LOG_REQUEST_MESSAGE_LENGTH_OFFSET]
 test rcx,rcx
 jz .log_invalid
 cmp rcx,NEBOC_LOG_MAX_MESSAGE_BYTES
 ja .log_limit
 cmp qword [rsi+NEBOC_LOG_REQUEST_MESSAGE_OFFSET],0
 je .log_invalid
 mov r8,rdx
 add r8,rcx
 jc .log_limit
 add r8,[rdi+NEBOC_LOG_USED_OFFSET]
 cmp r8,[rdi+NEBOC_LOG_BUDGET_OFFSET]
 ja .log_limit
 mov r9,[rdi+NEBOC_LOG_COUNT_OFFSET]
 cmp r9,[rdi+NEBOC_LOG_CAPACITY_OFFSET]
 jae .log_limit
 imul r9,NEBOC_LOG_ENTRY_SIZE
 add r9,[rdi+NEBOC_LOG_ENTRIES_OFFSET]
 mov [r9+NEBOC_LOG_ENTRY_LEVEL_OFFSET],rax
 mov rax,[rsi+NEBOC_LOG_REQUEST_COMPONENT_OFFSET]
 mov [r9+NEBOC_LOG_ENTRY_COMPONENT_OFFSET],rax
 mov [r9+NEBOC_LOG_ENTRY_COMPONENT_LENGTH_OFFSET],rdx
 mov rax,[rsi+NEBOC_LOG_REQUEST_MESSAGE_OFFSET]
 mov [r9+NEBOC_LOG_ENTRY_MESSAGE_OFFSET],rax
 mov [r9+NEBOC_LOG_ENTRY_MESSAGE_LENGTH_OFFSET],rcx
 mov rax,[rsi+NEBOC_LOG_REQUEST_FIELDS_DIGEST_OFFSET]
 mov [r9+NEBOC_LOG_ENTRY_FIELDS_DIGEST_OFFSET],rax
 inc qword [rdi+NEBOC_LOG_COUNT_OFFSET]
 mov [rdi+NEBOC_LOG_USED_OFFSET],r8
 xor eax,eax
 ret
.log_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.log_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; Stable public CLI exit mapping.
NEBOC_ABI_FUNCTION neboc_compiler_exit_status_from_outcome
 cmp rdi,NEBOC_EXIT_OUTCOME_SUCCESS
 je .exit_success
 cmp rdi,NEBOC_EXIT_OUTCOME_SOURCE_ERROR
 je .exit_source
 cmp rdi,NEBOC_EXIT_OUTCOME_WARNING_DENIED
 je .exit_source
 cmp rdi,NEBOC_EXIT_OUTCOME_ENVIRONMENT
 je .exit_environment
 cmp rdi,NEBOC_EXIT_OUTCOME_TOOLCHAIN
 je .exit_toolchain
 cmp rdi,NEBOC_EXIT_OUTCOME_ICE
 je .exit_ice
 mov eax,-1
 ret
.exit_success:
 mov eax,NEBOC_CLI_EXIT_SUCCESS
 ret
.exit_source:
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 ret
.exit_environment:
 mov eax,NEBOC_CLI_EXIT_IO_ERROR
 ret
.exit_toolchain:
 mov eax,NEBOC_CLI_EXIT_TOOLCHAIN_ERROR
 ret
.exit_ice:
 mov eax,NEBOC_CLI_EXIT_INTERNAL_ERROR
 ret

; terminal.capabilities(fd, policy*, out*) uses ioctl only for presentation.
NEBOC_ABI_FUNCTION neboc_terminal_capabilities
 test rsi,rsi
 jz .terminal_invalid
 test rdx,rdx
 jz .terminal_invalid
 mov rax,[rsi+NEBOC_TERMINAL_POLICY_COLOR_OFFSET]
 cmp rax,NEBOC_TERMINAL_AUTO
 jb .terminal_invalid
 cmp rax,NEBOC_TERMINAL_NEVER
 ja .terminal_invalid
 mov rcx,[rsi+NEBOC_TERMINAL_POLICY_UNICODE_OFFSET]
 cmp rcx,NEBOC_TERMINAL_UNICODE_AUTO
 jb .terminal_invalid
 cmp rcx,NEBOC_TERMINAL_UNICODE_FULL
 ja .terminal_invalid
 mov r8,[rsi+NEBOC_TERMINAL_POLICY_FALLBACK_WIDTH_OFFSET]
 cmp r8,40
 jb .terminal_invalid
 cmp r8,240
 ja .terminal_invalid
 push rbx
 push r12
 push r13
 sub rsp,16
 mov rbx,rsi
 mov r12,rdx
 mov r13,r8
 mov qword [rsp],0
 mov eax,16
 mov rsi,0x5413
 mov rdx,rsp
 syscall
 xor r8d,r8d
 test rax,rax
 js .terminal_width
 mov r8d,1
 movzx r13d,word [rsp+2]
 cmp r13,40
 jb .terminal_fallback
 cmp r13,240
 jbe .terminal_width
.terminal_fallback:
 mov r13,[rbx+NEBOC_TERMINAL_POLICY_FALLBACK_WIDTH_OFFSET]
.terminal_width:
 mov [r12+NEBOC_TERMINAL_CAP_TTY_OFFSET],r8
 mov qword [r12+NEBOC_TERMINAL_CAP_COLOR_OFFSET],0
 mov rax,[rbx+NEBOC_TERMINAL_POLICY_COLOR_OFFSET]
 cmp rax,NEBOC_TERMINAL_ALWAYS
 je .terminal_color
 cmp rax,NEBOC_TERMINAL_AUTO
 jne .terminal_unicode
 test r8,r8
 jz .terminal_unicode
.terminal_color:
 mov qword [r12+NEBOC_TERMINAL_CAP_COLOR_OFFSET],1
.terminal_unicode:
 mov qword [r12+NEBOC_TERMINAL_CAP_UNICODE_OFFSET],0
 mov rax,[rbx+NEBOC_TERMINAL_POLICY_UNICODE_OFFSET]
 cmp rax,NEBOC_TERMINAL_UNICODE_FULL
 je .terminal_unicode_on
 cmp rax,NEBOC_TERMINAL_UNICODE_AUTO
 jne .terminal_store
 test r8,r8
 jz .terminal_store
.terminal_unicode_on:
 mov qword [r12+NEBOC_TERMINAL_CAP_UNICODE_OFFSET],1
.terminal_store:
 mov [r12+NEBOC_TERMINAL_CAP_WIDTH_OFFSET],r13
 xor eax,eax
 add rsp,16
 pop r13
 pop r12
 pop rbx
 ret
.terminal_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

%macro SUMMARY_LITERAL 2
 mov rdi,r13
 lea rsi,[rel %1]
 mov edx,%2
 call obs_append
 test eax,eax
 jnz .summary_rollback
%endmacro

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_progress_deterministic_summary
 test rdi,rdi
 jz .summary_invalid
 test rsi,rsi
 jz .summary_invalid
 cmp qword [rdi+NEBOC_PROGRESS_ACTIVE_OFFSET],1
 jne .summary_invalid
 push rbx
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov rbx,[r13+NEBOC_WRITER_LENGTH_OFFSET]
 SUMMARY_LITERAL summary_phase,summary_phase_len
 mov rdi,r13
 mov rsi,[r12+NEBOC_PROGRESS_PHASE_OFFSET]
 call obs_u64
 test eax,eax
 jnz .summary_rollback
 SUMMARY_LITERAL summary_total,summary_total_len
 mov rdi,r13
 mov rsi,[r12+NEBOC_PROGRESS_UNIT_COUNT_OFFSET]
 call obs_u64
 test eax,eax
 jnz .summary_rollback
 SUMMARY_LITERAL summary_completed,summary_completed_len
 mov rdi,r13
 mov rsi,[r12+NEBOC_PROGRESS_COMPLETED_OFFSET]
 call obs_u64
 test eax,eax
 jnz .summary_rollback
 SUMMARY_LITERAL summary_success,summary_success_len
 mov rdi,r13
 mov rsi,[r12+NEBOC_PROGRESS_SUCCESS_OFFSET]
 call obs_u64
 test eax,eax
 jnz .summary_rollback
 SUMMARY_LITERAL summary_failed,summary_failed_len
 mov rdi,r13
 mov rsi,[r12+NEBOC_PROGRESS_FAILED_OFFSET]
 call obs_u64
 test eax,eax
 jnz .summary_rollback
 SUMMARY_LITERAL newline,1
 xor eax,eax
 jmp .summary_done
.summary_rollback:
 mov [r13+NEBOC_WRITER_LENGTH_OFFSET],rbx
.summary_done:
 add rsp,8
 pop r13
 pop r12
 pop rbx
 ret
.summary_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
%undef call
