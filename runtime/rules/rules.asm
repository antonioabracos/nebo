; OBSERVABILIDADE-EXPLAIN-DEBUG-SIMULACAO-E-EVOLUCAO-F05 bounded priority rules with explicit explanations.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/rules/rules.inc"
section .text
NEBOC_ABI_FUNCTION nebo_rules_validate
 ; entries,count; action == matched fact is a prohibited immediate cycle
 test rdi,rdi
 jz .invalid
 cmp rsi,NEBO_RULE_MAX
 ja .limit
 xor eax,eax
.vloop:
 cmp rax,rsi
 jae .valid
 mov rcx,rax
 shl rcx,5
 mov rdx,[rdi+rcx]
 cmp [rdi+rcx+16],rdx
 je .cycle
 inc rax
 jmp .vloop
.valid: xor eax,eax
 ret
.invalid: mov eax,NEBO_RULE_INVALID
 ret
.limit: mov eax,NEBO_RULE_LIMIT
 ret
.cycle: mov eax,NEBO_RULE_CYCLE
 ret

NEBOC_ABI_FUNCTION nebo_rules_evaluate
 ; entries,count,fact_id,value,out[action,priority,index]
 test rdi,rdi
 jz .invalid
 test r8,r8
 jz .invalid
 cmp rsi,NEBO_RULE_MAX
 ja .limit
 xor eax,eax
 xor r9d,r9d
 xor r10d,r10d
 xor r11d,r11d
 push r12
 push r13
 xor r13d,r13d
.loop:
 cmp rax,rsi
 jae .done
 push rax
 shl rax,5
 cmp [rdi+rax],rdx
 jne .next
 cmp [rdi+rax+8],rcx
 jne .next
 mov r12,[rdi+rax+16]
 mov rax,[rdi+rax+24]
 test r9,r9
 jz .select
 cmp rax,r10
 jb .next
 ja .select
 cmp r12,r11
 jne .conflict_pop
 jmp .next
.select:
 mov r9,1
 mov r10,rax
 mov r11,r12
 mov r13,[rsp]
.next:
 pop rax
 inc rax
 jmp .loop
.done:
 test r9,r9
 jz .no_match
 mov [r8],r11
 mov [r8+8],r10
 mov [r8+16],r13
 pop r13
 pop r12
 xor eax,eax
 ret
.conflict_pop:
 pop rax
 pop r13
 pop r12
 mov eax,NEBO_RULE_CONFLICT
 ret
.no_match:
 pop r13
 pop r12
 mov eax,NEBO_RULE_NO_MATCH
 ret
.invalid: mov eax,NEBO_RULE_INVALID
 ret
.limit: mov eax,NEBO_RULE_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
