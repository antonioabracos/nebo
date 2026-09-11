; RELEASE-GOVERNANCE-E-ENCERRAMENTO-DE-PROGRAMAS-F09 native progress/logging/terminal/exit contract tests.
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/driver/cli/linux-x86_64/cli_driver.inc"
%include "compiler/diagnostics/renderer.inc"
%include "compiler/diagnostics/observability.inc"
global _start
extern neboc_progress_phase_started
extern neboc_progress_unit_finished
extern neboc_compiler_log_init
extern neboc_compiler_log_record
extern neboc_compiler_exit_status_from_outcome
extern neboc_terminal_capabilities
extern neboc_progress_deterministic_summary
extern neboc_host_process_exit

section .rodata
component: db 'driver'
component_len equ $-component
message: db 'build complete'
message_len equ $-message
expected_summary: db 'progress phase=13 total=3 completed=3 success=2 failed=1',10
expected_summary_len equ $-expected_summary

section .data
log_request: dq NEBOC_LOG_LEVEL_DECISION,component,component_len,message,message_len,0x52004709
terminal_policy: dq NEBOC_TERMINAL_AUTO,NEBOC_TERMINAL_UNICODE_AUTO,80

section .bss align=16
progress: resb NEBOC_PROGRESS_SIZE
log_state: resb NEBOC_LOG_SIZE
log_entries: resb NEBOC_LOG_ENTRY_SIZE*2
terminal_caps: resb NEBOC_TERMINAL_CAP_SIZE
writer: resb NEBOC_WRITER_SIZE
output: resb 256

section .text
bytes_equal:
 xor ecx,ecx
.loop:
 cmp rcx,rdx
 jae .yes
 mov al,[rdi+rcx]
 cmp al,[rsi+rcx]
 jne .no
 inc rcx
 jmp .loop
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

_start:
 sub rsp,8
 lea rdi,[rel progress]
 mov esi,13
 mov edx,3
 call neboc_progress_phase_started
 test eax,eax
 jne .fail1
 lea rdi,[rel progress]
 mov esi,2
 mov edx,NEBOC_PROGRESS_OUTCOME_SUCCESS
 call neboc_progress_unit_finished
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail2
 lea rdi,[rel progress]
 mov esi,1
 mov edx,NEBOC_PROGRESS_OUTCOME_SUCCESS
 call neboc_progress_unit_finished
 test eax,eax
 jne .fail3
 lea rdi,[rel progress]
 mov esi,2
 mov edx,NEBOC_PROGRESS_OUTCOME_FAILURE
 call neboc_progress_unit_finished
 test eax,eax
 jne .fail4
 lea rdi,[rel progress]
 mov esi,3
 mov edx,NEBOC_PROGRESS_OUTCOME_SUCCESS
 call neboc_progress_unit_finished
 test eax,eax
 jne .fail5
 lea rdi,[rel progress]
 mov esi,4
 mov edx,NEBOC_PROGRESS_OUTCOME_SUCCESS
 call neboc_progress_unit_finished
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail6

 lea rax,[rel output]
 mov [rel writer+NEBOC_WRITER_BYTES_OFFSET],rax
 mov qword [rel writer+NEBOC_WRITER_CAPACITY_OFFSET],256
 mov qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],0
 lea rdi,[rel progress]
 lea rsi,[rel writer]
 call neboc_progress_deterministic_summary
 test eax,eax
 jne .fail7
 cmp qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],expected_summary_len
 jne .fail8
 lea rdi,[rel output]
 lea rsi,[rel expected_summary]
 mov edx,expected_summary_len
 call bytes_equal
 test eax,eax
 jz .fail9

 mov qword [rel writer+NEBOC_WRITER_CAPACITY_OFFSET],5
 mov qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],2
 lea rdi,[rel progress]
 lea rsi,[rel writer]
 call neboc_progress_deterministic_summary
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail10
 cmp qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],2
 jne .fail11

 lea rdi,[rel log_state]
 lea rsi,[rel log_entries]
 mov edx,1
 mov ecx,64
 call neboc_compiler_log_init
 test eax,eax
 jne .fail12
 lea rdi,[rel log_state]
 lea rsi,[rel log_request]
 call neboc_compiler_log_record
 test eax,eax
 jne .fail13
 cmp qword [rel log_state+NEBOC_LOG_COUNT_OFFSET],1
 jne .fail14
 mov rax,component_len+message_len
 cmp [rel log_state+NEBOC_LOG_USED_OFFSET],rax
 jne .fail15
 lea rdi,[rel log_state]
 lea rsi,[rel log_request]
 call neboc_compiler_log_record
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail16
 mov qword [rel log_request+NEBOC_LOG_REQUEST_LEVEL_OFFSET],0
 lea rdi,[rel log_state]
 lea rsi,[rel log_request]
 call neboc_compiler_log_record
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail17

 mov edi,NEBOC_EXIT_OUTCOME_SUCCESS
 call neboc_compiler_exit_status_from_outcome
 cmp eax,0
 jne .fail18
 mov edi,NEBOC_EXIT_OUTCOME_SOURCE_ERROR
 call neboc_compiler_exit_status_from_outcome
 cmp eax,1
 jne .fail19
 mov edi,NEBOC_EXIT_OUTCOME_WARNING_DENIED
 call neboc_compiler_exit_status_from_outcome
 cmp eax,1
 jne .fail20
 mov edi,NEBOC_EXIT_OUTCOME_ENVIRONMENT
 call neboc_compiler_exit_status_from_outcome
 cmp eax,3
 jne .fail21
 mov edi,NEBOC_EXIT_OUTCOME_TOOLCHAIN
 call neboc_compiler_exit_status_from_outcome
 cmp eax,5
 jne .fail22
 mov edi,NEBOC_EXIT_OUTCOME_ICE
 call neboc_compiler_exit_status_from_outcome
 cmp eax,6
 jne .fail23
 mov edi,999
 call neboc_compiler_exit_status_from_outcome
 cmp eax,-1
 jne .fail24

 mov rdi,-1
 lea rsi,[rel terminal_policy]
 lea rdx,[rel terminal_caps]
 call neboc_terminal_capabilities
 test eax,eax
 jne .fail25
 cmp qword [rel terminal_caps+NEBOC_TERMINAL_CAP_TTY_OFFSET],0
 jne .fail26
 cmp qword [rel terminal_caps+NEBOC_TERMINAL_CAP_COLOR_OFFSET],0
 jne .fail27
 cmp qword [rel terminal_caps+NEBOC_TERMINAL_CAP_UNICODE_OFFSET],0
 jne .fail28
 cmp qword [rel terminal_caps+NEBOC_TERMINAL_CAP_WIDTH_OFFSET],80
 jne .fail29
 mov qword [rel terminal_policy+NEBOC_TERMINAL_POLICY_FALLBACK_WIDTH_OFFSET],20
 mov rdi,-1
 lea rsi,[rel terminal_policy]
 lea rdx,[rel terminal_caps]
 call neboc_terminal_capabilities
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail30

 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 30
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
