; LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-F06 authenticated pointerless loop CFG/cleanup lowering plan
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/lowering/bindings/loop_plan.inc"

section .text

; builder*, plan* -> Status. The semantic pass has already validated lexical
; targets and Bool conditions; this lowering records the bounded CFG shape and
; one cleanup obligation for every consumed break/continue edge.
NEBOC_ABI_FUNCTION neboc_loop_plan_lower
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 test r12,r12
 jz .invalid
 test r13,r13
 jz .invalid
 mov rdi,r13
 mov ecx,NEBOC_LOOP_PLAN_QWORDS
 xor eax,eax
 rep stosq
 mov qword [r13+NEBOC_LOOP_PLAN_SCHEMA_OFFSET],NEBOC_LOOP_PLAN_SCHEMA
 mov rax,NEBOC_LOOP_PLAN_LAYOUT
 mov [r13+NEBOC_LOOP_PLAN_LAYOUT_OFFSET],rax
 mov qword [r13+NEBOC_LOOP_PLAN_FLAGS_OFFSET],NEBOC_LOOP_PLAN_FLAGS
 mov ebx,1
.scan:
 cmp rbx,[r12+NEBOC_AST_BUILDER_COUNT_OFFSET]
 ja .counts
 mov rax,rbx
 dec rax
 imul rax,NEBOC_AST_NODE_SIZE
 add rax,[r12+NEBOC_AST_BUILDER_DATA_OFFSET]
 mov rcx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rcx,NEBOC_AST_WHILE_STMT
 je .while
 cmp rcx,NEBOC_AST_LOOP_STMT
 je .loop
 cmp rcx,NEBOC_AST_BREAK_STMT
 je .break
 cmp rcx,NEBOC_AST_CONTINUE_STMT
 je .continue
 jmp .next
.while:
 inc qword [r13+NEBOC_LOOP_PLAN_WHILE_COUNT_OFFSET]
 add qword [r13+NEBOC_LOOP_PLAN_CFG_EDGE_COUNT_OFFSET],5
 jmp .next
.loop:
 inc qword [r13+NEBOC_LOOP_PLAN_LOOP_COUNT_OFFSET]
 add qword [r13+NEBOC_LOOP_PLAN_CFG_EDGE_COUNT_OFFSET],4
 jmp .next
.break:
 inc qword [r13+NEBOC_LOOP_PLAN_BREAK_COUNT_OFFSET]
 inc qword [r13+NEBOC_LOOP_PLAN_CFG_EDGE_COUNT_OFFSET]
 inc qword [r13+NEBOC_LOOP_PLAN_CLEANUP_EDGE_COUNT_OFFSET]
 jmp .next
.continue:
 inc qword [r13+NEBOC_LOOP_PLAN_CONTINUE_COUNT_OFFSET]
 inc qword [r13+NEBOC_LOOP_PLAN_CFG_EDGE_COUNT_OFFSET]
 inc qword [r13+NEBOC_LOOP_PLAN_CLEANUP_EDGE_COUNT_OFFSET]
.next:
 inc rbx
 jmp .scan
.counts:
 mov rax,[r13+NEBOC_LOOP_PLAN_BREAK_COUNT_OFFSET]
 add rax,[r13+NEBOC_LOOP_PLAN_CONTINUE_COUNT_OFFSET]
 cmp rax,[r13+NEBOC_LOOP_PLAN_CLEANUP_EDGE_COUNT_OFFSET]
 jne .internal
 mov rax,1469598103934665603
 lea rsi,[r13+NEBOC_LOOP_PLAN_SCHEMA_OFFSET]
 mov ecx,11
.hash:
 xor rax,[rsi]
 mov rdx,1099511628211
 imul rax,rdx
 add rsi,8
 loop .hash
 test rax,rax
 jnz .hash_ready
 mov eax,1
.hash_ready:
 mov [r13+NEBOC_LOOP_PLAN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.internal:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
