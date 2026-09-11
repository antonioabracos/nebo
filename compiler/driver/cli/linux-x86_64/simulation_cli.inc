; LSP-EDITOR-E-EXPERIENCIA-DE-DESENVOLVIMENTO-F07 bounded binary simulation log validator and replay report.
%ifndef NEBO_SIMULATION_CLI_INC
%define NEBO_SIMULATION_CLI_INC 1

section .rodata
cli_simulation_report_prefix:
 db 'simulation-replay v1',10
 db 'profile=DETERMINISTIC_SIMULATION_V1',10
 db 'ticks='
cli_simulation_report_prefix_end:
cli_simulation_state_prefix: db 10,'final-state='
cli_simulation_state_prefix_end:
cli_simulation_report_suffix:
 db 'state-hash=verified',10
 db 'divergence=none',10
 db 'cross-cpu-bit-identity=false',10
cli_simulation_report_suffix_end:
cli_simulation_error:
 db 'NEBO-G043-SIMULATION-REPLAY-001: invalid log or state hash mismatch',10
cli_simulation_error_end:

section .text
; Reads cli_source populated by cli_read_source. Format:
; "NEBSIM01", u64 count, count pairs of u64(tick,input), final u64 state.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_simulation_replay_validate:
 push rbx
 push r12
 mov r8,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 cmp r8,40
 jb .bad
 lea r9,[rel cli_source]
 mov rax,0x31304d495342454e
 cmp [r9],rax
 jne .bad
 mov r10,[r9+8]
 test r10,r10
 jz .bad
 cmp r10,64
 ja .bad
 mov rbx,r10
 mov rax,r10
 shl rax,4
 jc .bad
 add rax,24
 jc .bad
 cmp rax,r8
 jne .bad
 mov r12,0xcbf29ce484222325
 xor ecx,ecx
.scan:
 mov rax,rcx
 shl rax,4
 cmp [r9+rax+16],rcx
 jne .bad
 cmp qword [r9+rax+24],1000000
 ja .bad
 mov rax,r12
 mov rdx,0x100000001b3
 mul rdx
 mov rdx,rcx
 shl rdx,4
 xor rax,[r9+rdx+24]
 xor rax,rcx
 mov r12,rax
 inc rcx
 cmp rcx,r10
 jb .scan
 mov rax,rbx
 shl rax,4
 cmp [r9+rax+16],r12
 jne .bad
 lea rdi,[rel cli_simulation_report_prefix]
 mov esi,cli_simulation_report_prefix_end-cli_simulation_report_prefix
 call cli_write_stdout
 mov rdi,rbx
 call cli_write_u64_stdout
 lea rdi,[rel cli_simulation_state_prefix]
 mov esi,cli_simulation_state_prefix_end-cli_simulation_state_prefix
 call cli_write_stdout
 mov rdi,r12
 call cli_write_hex_line
 lea rdi,[rel cli_simulation_report_suffix]
 mov esi,cli_simulation_report_suffix_end-cli_simulation_report_suffix
 call cli_write_stdout
 xor eax,eax
 pop r12
 pop rbx
 ret
.bad:
 lea rdi,[rel cli_simulation_error]
 mov esi,cli_simulation_error_end-cli_simulation_error
 call cli_write_stderr
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 pop r12
 pop rbx
 ret

%endif
%undef call
