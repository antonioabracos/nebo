; REDE-E-PROTOCOLOS-F06 bounded reports, trace minimization and replay.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/verification/report.inc"
section .text
NEBOC_ABI_FUNCTION nebo_verification_report_init
 test rdi,rdi
 jz .invalid_init
 mov qword [rdi],0
 mov qword [rdi+8],0
 mov qword [rdi+16],0
 mov qword [rdi+24],0
 mov qword [rdi+32],0
 xor eax,eax
 ret
.invalid_init: mov eax,NEBO_REPORT_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_verification_report_add
 test rdi,rdi
 jz .invalid_add
 cmp rsi,NEBO_REPORT_STATE_PROVED
 je .proved
 cmp rsi,NEBO_REPORT_STATE_RUNTIME
 je .runtime
 cmp rsi,NEBO_REPORT_STATE_UNKNOWN
 je .unknown
 cmp rsi,NEBO_REPORT_STATE_TIMEOUT
 je .timeout
 cmp rsi,NEBO_REPORT_STATE_FAILED
 je .failed
 jmp .invalid_add
.proved: inc qword [rdi+NEBO_REPORT_PROVED]
 jmp .ok
.runtime: inc qword [rdi+NEBO_REPORT_RUNTIME]
 jmp .ok
.unknown: inc qword [rdi+NEBO_REPORT_UNKNOWN]
 jmp .ok
.timeout: inc qword [rdi+NEBO_REPORT_TIMEOUT]
 jmp .ok
.failed: inc qword [rdi+NEBO_REPORT_FAILED]
.ok: xor eax,eax
 ret
.invalid_add: mov eax,NEBO_REPORT_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_counterexample_minimize
 ; trace, count, output, capacity, written pointer
 test r8,r8
 jz .invalid_min
 mov qword [r8],0
 test rdi,rdi
 jz .invalid_min
 test rdx,rdx
 jz .invalid_min
 test rsi,rsi
 jz .invalid_min
 cmp rsi,NEBO_COUNTEREXAMPLE_MAX_STEPS
 ja .limit_min
 cmp rcx,rsi
 jb .limit_min
 xor eax,eax
 xor r9d,r9d
 xor r10d,r10d
.min_loop:
 cmp rax,rsi
 jae .min_done
 mov r11,[rdi+rax*8]
 test r9,r9
 jz .keep
 cmp r11,r10
 je .skip
.keep:
 mov [rdx+r9*8],r11
 mov r10,r11
 inc r9
.skip: inc rax
 jmp .min_loop
.min_done:
 mov [r8],r9
 xor eax,eax
 ret
.invalid_min: mov eax,NEBO_REPORT_STATUS_INVALID
 ret
.limit_min: mov eax,NEBO_REPORT_STATUS_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_counterexample_replay
 ; transitions bitmask table, state count, trace, trace count
 test rdi,rdi
 jz .invalid_replay
 test rdx,rdx
 jz .invalid_replay
 test rsi,rsi
 jz .invalid_replay
 cmp rsi,64
 ja .limit_replay
 cmp rcx,2
 jb .invalid_replay
 cmp rcx,NEBO_COUNTEREXAMPLE_MAX_STEPS
 ja .limit_replay
 xor eax,eax
.replay_loop:
 mov r8,rcx
 dec r8
 cmp rax,r8
 jae .replay_ok
 mov r9,[rdx+rax*8]
 cmp r9,rsi
 jae .replay_bad
 mov r10,[rdx+rax*8+8]
 cmp r10,rsi
 jae .replay_bad
 mov r11,[rdi+r9*8]
 bt r11,r10
 jnc .replay_bad
 inc rax
 jmp .replay_loop
.replay_ok: xor eax,eax
 ret
.invalid_replay: mov eax,NEBO_REPORT_STATUS_INVALID
 ret
.limit_replay: mov eax,NEBO_REPORT_STATUS_LIMIT
 ret
.replay_bad: mov eax,NEBO_REPORT_STATUS_REPLAY
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
