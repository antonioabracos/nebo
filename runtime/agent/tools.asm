bits 64
default rel
%define NEBO_TOOLS_IMPLEMENTATION 1
%include "runtime/agent/tools.inc"
section .text
global nebo_tool_registry_init
global nebo_tool_register
global nebo_tool_call
global nebo_tool_remaining
; Registry={count,calls,(id,cap)*16}. Only pure add(1) and xor(2).
nebo_tool_registry_init:
 test rdi,rdi
 jz .iarg
 mov qword [rdi],0
 mov qword [rdi+8],0
 xor eax,eax
 ret
.iarg: mov eax,NEBO_TOOL_E_ARGUMENT
 ret
nebo_tool_register:
 test rdi,rdi
 jz .rarg
 cmp rsi,1
 jb .runknown
 cmp rsi,2
 ja .runknown
 mov rax,[rdi]
 cmp rax,NEBO_TOOL_MAX_REGISTRY
 jae .rlimit
 xor ecx,ecx
.rscan:
 cmp rcx,rax
 jae .rput
 mov r9,rcx
 shl r9,4
 cmp [rdi+r9+16],rsi
 je .rarg
 inc rcx
 jmp .rscan
.rput:
 mov r9,rax
 shl r9,4
 mov [rdi+r9+16],rsi
 mov [rdi+r9+24],rdx
 inc rax
 mov [rdi],rax
 xor eax,eax
 ret
.rarg: mov eax,NEBO_TOOL_E_ARGUMENT
 ret
.runknown: mov eax,NEBO_TOOL_E_UNKNOWN
 ret
.rlimit: mov eax,NEBO_TOOL_E_LIMIT
 ret
; Call56={id,cap,approved,args_bytes,a,b,result}.
nebo_tool_call:
 test rdi,rdi
 jz .carg
 test rsi,rsi
 jz .carg
 cmp qword [rsi+24],NEBO_TOOL_MAX_ARGS
 ja .cschema
 cmp qword [rsi+16],1
 jne .cdenied
 cmp qword [rdi+8],NEBO_TOOL_MAX_CALLS
 jae .climit
 mov r8,[rdi]
 xor ecx,ecx
.cscan:
 cmp rcx,r8
 jae .cunknown
 mov r9,rcx
 shl r9,4
 mov rax,[rdi+r9+16]
 cmp rax,[rsi]
 je .cfound
 inc rcx
 jmp .cscan
.cfound:
 mov rax,[rdi+r9+24]
 cmp rax,[rsi+8]
 jne .cdenied
 mov rax,[rsi+32]
 cmp qword [rsi],1
 je .add
 xor rax,[rsi+40]
 jmp .publish
.add: add rax,[rsi+40]
.publish:
 mov [rsi+48],rax
 inc qword [rdi+8]
 xor eax,eax
 ret
.carg: mov eax,NEBO_TOOL_E_ARGUMENT
 ret
.cschema: mov eax,NEBO_TOOL_E_SCHEMA
 ret
.cdenied: mov eax,NEBO_TOOL_E_DENIED
 ret
.climit: mov eax,NEBO_TOOL_E_LIMIT
 ret
.cunknown: mov eax,NEBO_TOOL_E_UNKNOWN
 ret
nebo_tool_remaining:
 test rdi,rdi
 jz .marg
 test rsi,rsi
 jz .marg
 mov rax,NEBO_TOOL_MAX_CALLS
 sub rax,[rdi+8]
 mov [rsi],rax
 xor eax,eax
 ret
.marg: mov eax,NEBO_TOOL_E_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
