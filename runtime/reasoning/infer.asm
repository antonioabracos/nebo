; RUNTIME-DISTRIBUIDO-E-STREAMING-DISTRIBUIDO-F03 finite monotonic forward chaining over a 64-fact bitset.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/reasoning/infer.inc"
section .text
NEBOC_ABI_FUNCTION nebo_infer_fixpoint
 ; rules[premise_mask,conclusion_mask],count,initial,max_rounds,out_state,out_rounds
 test rdi,rdi
 jz .invalid
 test r8,r8
 jz .invalid
 test r9,r9
 jz .invalid
 cmp rsi,NEBO_INFER_MAX_RULES
 ja .limit
 test rcx,rcx
 jz .limit
 cmp rcx,NEBO_INFER_MAX_ROUNDS
 ja .limit
 push rbx
 push r12
 push r13
 mov r12,r8
 mov r13,r9
 mov r10,rdx
 xor r11d,r11d
.round:
 cmp r11,rcx
 jae .budget
 mov rdx,r10
 xor eax,eax
.rules:
 cmp rax,rsi
 jae .round_done
 mov r8,rax
 shl r8,4
 mov r9,[rdi+r8]
 mov rbx,r10
 and rbx,r9
 cmp rbx,r9
 jne .next
 or r10,[rdi+r8+8]
.next:
 inc rax
 jmp .rules
.round_done:
 inc r11
 cmp r10,rdx
 jne .round
 mov [r12],r10
 mov [r13],r11
 pop r13
 pop r12
 pop rbx
 xor eax,eax
 ret
.budget:
 mov [r12],r10
 mov [r13],r11
 pop r13
 pop r12
 pop rbx
 mov eax,NEBO_INFER_BUDGET
 ret
.invalid: mov eax,NEBO_INFER_INVALID
 ret
.limit: mov eax,NEBO_INFER_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
