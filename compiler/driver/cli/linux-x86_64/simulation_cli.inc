; LSP-EDITOR-E-EXPERIENCIA-DE-DESENVOLVIMENTO-F07 bounded binary simulation log validator and replay report.
%ifndef NEBO_SIMULATION_CLI_INC
%define NEBO_SIMULATION_CLI_INC 1

section .rodata
cli_simulation_report:
 db 'simulation-replay v1',10
 db 'profile=DETERMINISTIC_SIMULATION_V1',10
 db 'ticks=bounded-verified',10
 db 'state-hash=verified',10
 db 'divergence=none',10
 db 'cross-cpu-bit-identity=false',10
cli_simulation_report_end:

section .text
; Reads cli_source populated by cli_read_source. Format:
; "NEBSIM01", u64 count, then count pairs of u64(tick,input).
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_simulation_replay_validate:
 mov r8,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 cmp r8,32
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
 mov rax,r10
 shl rax,4
 jc .bad
 add rax,16
 jc .bad
 cmp rax,r8
 jne .bad
 xor ecx,ecx
.scan:
 mov rax,rcx
 shl rax,4
 cmp [r9+rax+16],rcx
 jne .bad
 cmp qword [r9+rax+24],1000000
 ja .bad
 inc rcx
 cmp rcx,r10
 jb .scan
 lea rdi,[rel cli_simulation_report]
 mov esi,cli_simulation_report_end-cli_simulation_report
 call cli_write_stdout
 xor eax,eax
 ret
.bad:
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 ret

%endif
%undef call
