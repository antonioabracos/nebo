; OBSERVABILIDADE-EXPLAIN-DEBUG-SIMULACAO-E-EVOLUCAO-F02 bounded 128-state configuration microstep.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/workflow/statechart.inc"
section .text
NEBOC_ABI_FUNCTION nebo_statechart_microstep
 ; active[2],exit[2],enter[2],regions,out[3]
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test r8,r8
 jz .invalid
 test ecx,ecx
 jz .limit
 cmp ecx,NEBO_STATECHART_MAX_REGIONS
 ja .limit
 mov r9,[rsi]
 mov r10,[rsi+8]
 mov rax,[rdi]
 mov r11,[rdi+8]
 mov rcx,r9
 not rcx
 test rax,rcx
 ; no-op: active may contain states outside exit
 mov rcx,rax
 not rcx
 test r9,rcx
 jnz .exit_missing
 mov rcx,r11
 not rcx
 test r10,rcx
 jnz .exit_missing
 not r9
 and rax,r9
 or rax,[rdx]
 not r10
 and r11,r10
 or r11,[rdx+8]
 mov [r8],rax
 mov [r8+8],r11
 mov qword [r8+16],NEBO_STATECHART_ORDER_EXIT_ACTION_ENTRY
 xor eax,eax
 ret
.exit_missing: mov eax,NEBO_STATECHART_EXIT_NOT_ACTIVE
 ret
.invalid: mov eax,NEBO_STATECHART_INVALID
 ret
.limit: mov eax,NEBO_STATECHART_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
