; OBSERVABILIDADE-EXPLAIN-DEBUG-SIMULACAO-E-EVOLUCAO-F01 deterministic finite-state transition selection.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/workflow/fsm.inc"
section .text
NEBOC_ABI_FUNCTION nebo_fsm_step
 ; table,count,state,event,out_next
 test rdi,rdi
 jz .invalid
 test r8,r8
 jz .invalid
 cmp rsi,NEBO_FSM_MAX_TRANSITIONS
 ja .limit
 xor eax,eax
 xor r9d,r9d
 xor r10d,r10d
.loop:
 cmp rax,rsi
 jae .done
 mov r11,rax
 imul r11,NEBO_FSM_ENTRY_SIZE
 cmp [rdi+r11],rdx
 jne .next
 cmp [rdi+r11+8],rcx
 jne .next
 inc r9
 mov r10,[rdi+r11+16]
.next: inc rax
 jmp .loop
.done:
 cmp r9,0
 je .none
 cmp r9,1
 jne .ambiguous
 mov [r8],r10
 xor eax,eax
 ret
.none: mov eax,NEBO_FSM_NO_TRANSITION
 ret
.ambiguous: mov eax,NEBO_FSM_NONDETERMINISTIC
 ret
.invalid: mov eax,NEBO_FSM_INVALID
 ret
.limit: mov eax,NEBO_FSM_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
