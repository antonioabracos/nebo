; OBSERVABILIDADE-EXPLAIN-DEBUG-SIMULACAO-E-EVOLUCAO-F06 bounded interval decision tables.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/rules/decision_table.inc"
section .text
NEBOC_ABI_FUNCTION nebo_decision_table_decide
 ; rows,count,input,hit_policy,out[result,index]
 test rdi,rdi
 jz .invalid
 test r8,r8
 jz .invalid
 cmp rsi,NEBO_DECISION_MAX_ROWS
 ja .limit
 cmp ecx,NEBO_DECISION_HIT_FIRST
 ja .invalid
 push r12
 mov r12d,ecx
 xor eax,eax
 xor r9d,r9d
 xor r10d,r10d
 xor r11d,r11d
.loop:
 cmp rax,rsi
 jae .done
 mov rcx,rax
 imul rcx,NEBO_DECISION_ROW_SIZE
 cmp rdx,[rdi+rcx]
 jb .next
 cmp rdx,[rdi+rcx+8]
 ja .next
 test r9,r9
 jz .select
 cmp r12d,NEBO_DECISION_HIT_FIRST
 je .next
 jmp .conflict_pushed
.select:
 mov r9,1
 mov r10,[rdi+rcx+16]
 mov r11,rax
.next:
 inc rax
 jmp .loop
.done:
 test r9,r9
 jz .gap_pushed
 mov [r8],r10
 mov [r8+8],r11
 pop r12
 xor eax,eax
 ret
.invalid: mov eax,NEBO_DECISION_TABLE_DECISION_INVALID
 ret
.limit: mov eax,NEBO_DECISION_TABLE_DECISION_LIMIT
 ret
.gap_pushed:
 pop r12
 mov eax,NEBO_DECISION_GAP
 ret
.conflict_pushed:
 pop r12
 mov eax,NEBO_DECISION_CONFLICT
 ret

NEBOC_ABI_FUNCTION nebo_decision_table_coverage
 ; rows,count,domain_min,domain_max
 test rdi,rdi
 jz .invalid
 cmp rsi,NEBO_DECISION_MAX_ROWS
 ja .limit
 cmp rdx,rcx
 ja .invalid
 mov rax,rcx
 sub rax,rdx
 cmp rax,NEBO_DECISION_MAX_DOMAIN-1
 ja .limit
.value:
 xor r8d,r8d
 xor eax,eax
.rows:
 cmp rax,rsi
 jae .checked
 mov r9,rax
 imul r9,NEBO_DECISION_ROW_SIZE
 cmp rdx,[rdi+r9]
 jb .row_next
 cmp rdx,[rdi+r9+8]
 ja .row_next
 mov r8,1
.row_next:
 inc rax
 jmp .rows
.checked:
 test r8,r8
 jz .gap
 cmp rdx,rcx
 je .covered
 inc rdx
 jmp .value
.covered: xor eax,eax
 ret
.invalid: mov eax,NEBO_DECISION_TABLE_DECISION_INVALID
 ret
.limit: mov eax,NEBO_DECISION_TABLE_DECISION_LIMIT
 ret
.gap: mov eax,NEBO_DECISION_GAP
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
