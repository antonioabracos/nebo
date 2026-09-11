bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/module_init.inc"

extern neboc_module_init_plan

section .text
; Bounded compile-time fold retained for the internal semantic pipeline.
NEBOC_ABI_FUNCTION neboc_pure_constants
 test rdi,rdi
 jz .arg
 test rdx,rdx
 jz .arg
 test rsi,rsi
 jz .source
 cmp rsi,NEBOC_INIT_MAX
 ja .limit
 xor ecx,ecx
 xor eax,eax
.loop:
 cmp rcx,rsi
 jae .put
 add rax,[rdi+rcx*8]
 inc rcx
 jmp .loop
.put:
 mov [rdx],rax
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; init.addPureConstant(plan, SymbolId, value) -> status. The node is selected
; by SymbolId and the complete plan is re-derived after the constant changes.
NEBOC_ABI_FUNCTION neboc_init_add_pure_constant
 test rdi,rdi
 jz .add_arg
 test rsi,rsi
 jz .add_source
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,[rbx+NEBOC_INIT_PLAN_NODES]
 mov r15,[rbx+NEBOC_INIT_PLAN_COUNT]
 xor ecx,ecx
.add_find:
 cmp rcx,r15
 jae .add_missing
 mov rax,rcx
 shl rax,6
 cmp [r14+rax+NEBOC_INIT_NODE_SYMBOL],r12
 jne .add_next
 cmp qword [r14+rax+NEBOC_INIT_NODE_KIND],NEBOC_INIT_KIND_PURE
 jne .add_missing
 mov [r14+rax+NEBOC_INIT_NODE_VALUE],r13
 mov rdi,r14
 mov rsi,r15
 mov rdx,[rbx+NEBOC_INIT_PLAN_TARGET]
 mov rcx,rbx
 call neboc_module_init_plan
 jmp .add_done
.add_next:
 inc rcx
 jmp .add_find
.add_missing:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.add_done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.add_arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.add_source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
