bits 64
default rel
%define NEBO_AGENT_IMPLEMENTATION 1
%include "runtime/agent/agent.inc"
section .text
global nebo_agent_begin
global nebo_agent_approve
global nebo_agent_step
global nebo_agent_cancel
global nebo_agent_rollback
; State64={steps,max_steps,calls,max_calls,approvals,max_approvals,cancelled,trace_bytes}.
nebo_agent_begin:
 test rdi,rdi
 jz .ba
 test rsi,rsi
 jz .ba
 cmp rsi,NEBO_AGENT_MAX_STEPS
 ja .bl
 cmp rdx,NEBO_AGENT_MAX_CALLS
 ja .bl
 cmp rcx,NEBO_AGENT_MAX_APPROVALS
 ja .bl
 mov qword [rdi],0
 mov [rdi+8],rsi
 mov qword [rdi+16],0
 mov [rdi+24],rdx
 mov qword [rdi+32],0
 mov [rdi+40],rcx
 mov qword [rdi+48],0
 mov qword [rdi+56],0
 xor eax,eax
 ret
.ba: mov eax,NEBO_AGENT_E_ARGUMENT
 ret
.bl: mov eax,NEBO_AGENT_E_LIMIT
 ret
nebo_agent_approve:
 test rdi,rdi
 jz .aa
 cmp qword [rdi+48],0
 jne .ac
 mov rax,[rdi+32]
 cmp rax,[rdi+40]
 jae .al
 inc rax
 mov [rdi+32],rax
 xor eax,eax
 ret
.aa: mov eax,NEBO_AGENT_E_ARGUMENT
 ret
.al: mov eax,NEBO_AGENT_E_LIMIT
 ret
.ac: mov eax,NEBO_AGENT_E_CANCELLED
 ret
; state,requires_approval,is_approved,is_tool_call,trace_bytes.
nebo_agent_step:
 test rdi,rdi
 jz .sa
 cmp qword [rdi+48],0
 jne .sc
 test rsi,rsi
 jz .budget
 test rdx,rdx
 jz .sap
.budget:
 mov rax,[rdi]
 cmp rax,[rdi+8]
 jae .sl
 test rcx,rcx
 jz .trace
 mov rax,[rdi+16]
 cmp rax,[rdi+24]
 jae .sl
.trace:
 mov rax,[rdi+56]
 add rax,r8
 jc .sl
 cmp rax,NEBO_AGENT_MAX_TRACE
 ja .sl
 mov [rdi+56],rax
 inc qword [rdi]
 test rcx,rcx
 jz .sok
 inc qword [rdi+16]
.sok: xor eax,eax
 ret
.sa: mov eax,NEBO_AGENT_E_ARGUMENT
 ret
.sl: mov eax,NEBO_AGENT_E_LIMIT
 ret
.sap: mov eax,NEBO_AGENT_E_APPROVAL
 ret
.sc: mov eax,NEBO_AGENT_E_CANCELLED
 ret
nebo_agent_cancel:
 test rdi,rdi
 jz .ca
 mov qword [rdi+48],1
 xor eax,eax
 ret
.ca: mov eax,NEBO_AGENT_E_ARGUMENT
 ret
; state,registered_compensations,out_count. Never invents undo.
nebo_agent_rollback:
 test rdi,rdi
 jz .ra
 test rdx,rdx
 jz .ra
 mov rax,[rdi+16]
 cmp rsi,rax
 jb .ru
 mov [rdx],rax
 xor eax,eax
 ret
.ru: mov eax,NEBO_AGENT_E_UNCOMPENSATED
 ret
.ra: mov eax,NEBO_AGENT_E_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
