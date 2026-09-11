; RF166-G161 exact-size native transport for receiver-completion facts.
bits 64
default rel
%include "compiler/lsp/completion.inc"

global _start
extern neboc_completion_context
extern neboc_completion_receiver
extern neboc_completion_members
extern neboc_completion_auto_import
extern neboc_completion_filter
extern neboc_completion_rank
extern neboc_completion_resolve

section .text
_start:
 xor edi,edi
 lea rsi,[rel request]
 mov edx,NEBOC_COMPLETION_REQUEST_SIZE
 call read_exact
 test eax,eax
 jnz .transport
 xor edi,edi
 lea rsi,[rel trailing]
 mov edx,1
 xor eax,eax
 syscall
 test rax,rax
 jnz .transport
 mov rax,[rel request+NEBOC_COMPLETION_OPERATION_OFFSET]
 cmp rax,NEBOC_COMPLETION_OP_CONTEXT
 je .context
 cmp rax,NEBOC_COMPLETION_OP_RECEIVER
 je .receiver
 cmp rax,NEBOC_COMPLETION_OP_MEMBERS
 je .members
 cmp rax,NEBOC_COMPLETION_OP_AUTO_IMPORT
 je .auto_import
 cmp rax,NEBOC_COMPLETION_OP_FILTER
 je .filter
 cmp rax,NEBOC_COMPLETION_OP_RANK
 je .rank
 cmp rax,NEBOC_COMPLETION_OP_RESOLVE
 je .resolve
 jmp .rejected
.context:
 lea rax,[rel neboc_completion_context]
 jmp .invoke
.receiver:
 lea rax,[rel neboc_completion_receiver]
 jmp .invoke
.members:
 lea rax,[rel neboc_completion_members]
 jmp .invoke
.auto_import:
 lea rax,[rel neboc_completion_auto_import]
 jmp .invoke
.filter:
 lea rax,[rel neboc_completion_filter]
 jmp .invoke
.rank:
 lea rax,[rel neboc_completion_rank]
 jmp .invoke
.resolve:
 lea rax,[rel neboc_completion_resolve]
.invoke:
 lea rdi,[rel request]
 lea rsi,[rel result]
 call rax
 test eax,eax
 jnz .rejected
 mov edi,1
 lea rsi,[rel result]
 mov edx,NEBOC_COMPLETION_RESULT_SIZE
 call write_exact
 test eax,eax
 jnz .transport
 xor edi,edi
 jmp .exit
.rejected:
 mov edi,1
 jmp .exit
.transport:
 mov edi,2
.exit:
 mov eax,60
 syscall

read_exact:
 xor r8d,r8d
.read_loop:
 cmp r8,rdx
 je transfer_ok
 xor eax,eax
 lea rsi,[rsi+r8]
 sub rdx,r8
 syscall
 test rax,rax
 jle transfer_fail
 add r8,rax
 lea rsi,[rel request]
 mov edx,NEBOC_COMPLETION_REQUEST_SIZE
 jmp .read_loop
write_exact:
 xor r8d,r8d
.write_loop:
 cmp r8,rdx
 je transfer_ok
 mov eax,1
 lea rsi,[rsi+r8]
 sub rdx,r8
 syscall
 test rax,rax
 jle transfer_fail
 add r8,rax
 lea rsi,[rel result]
 mov edx,NEBOC_COMPLETION_RESULT_SIZE
 jmp .write_loop
transfer_ok:
 xor eax,eax
 ret
transfer_fail:
 mov eax,1
 ret

section .bss
align 8
request: resb NEBOC_COMPLETION_REQUEST_SIZE
result: resb NEBOC_COMPLETION_RESULT_SIZE
trailing: resb 1
section .note.GNU-stack noalloc noexec nowrite progbits
