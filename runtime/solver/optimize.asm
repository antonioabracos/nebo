; CONSOLE-VISUAL-DASHBOARD-E-PLOTS-F04 deterministic bounded scalar optimization and optimality report.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/solver/optimize.inc"
section .text
NEBOC_ABI_FUNCTION nebo_optimize_i64
 ; values, count, mode, evaluation budget, result
 test r8,r8
 jz .invalid
 mov qword [r8],0
 mov qword [r8+8],0
 mov qword [r8+16],0
 mov qword [r8+24],0
 mov qword [r8+32],0
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,NEBO_OPTIMIZE_MAX_CANDIDATES
 ja .limit
 cmp rdx,NEBO_OPTIMIZE_MINIMIZE
 je .mode_ok
 cmp rdx,NEBO_OPTIMIZE_MAXIMIZE
 jne .invalid
.mode_ok:
 test rcx,rcx
 jz .timeout
 mov r9,[rdi]
 xor eax,eax
 xor r10d,r10d
.loop:
 cmp rax,rsi
 jae .optimal
 cmp r10,rcx
 jae .partial
 mov r11,[rdi+rax*8]
 cmp rdx,NEBO_OPTIMIZE_MINIMIZE
 je .min
 cmp r11,r9
 jle .next
 jmp .replace
.min:
 cmp r11,r9
 jge .next
.replace:
 mov r9,r11
 mov [r8+NEBO_OPTIMIZE_RESULT_INDEX],rax
.next:
 inc rax
 inc r10
 jmp .loop
.optimal:
 mov qword [r8+NEBO_OPTIMIZE_RESULT_STATE],NEBO_OPTIMIZE_STATE_OPTIMAL
 mov [r8+NEBO_OPTIMIZE_RESULT_VALUE],r9
 mov [r8+NEBO_OPTIMIZE_RESULT_EVALUATED],r10
 xor eax,eax
 ret
.partial:
 mov qword [r8+NEBO_OPTIMIZE_RESULT_STATE],NEBO_OPTIMIZE_STATE_GAP_BOUNDED
 mov [r8+NEBO_OPTIMIZE_RESULT_VALUE],r9
 mov [r8+NEBO_OPTIMIZE_RESULT_EVALUATED],r10
 sub rsi,r10
 mov [r8+NEBO_OPTIMIZE_RESULT_REMAINING],rsi
 xor eax,eax
 ret
.timeout:
 mov qword [r8+NEBO_OPTIMIZE_RESULT_STATE],NEBO_OPTIMIZE_STATE_TIMEOUT
 xor eax,eax
 ret
.invalid: mov eax,NEBO_OPTIMIZE_STATUS_INVALID
 ret
.limit: mov eax,NEBO_OPTIMIZE_STATUS_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
