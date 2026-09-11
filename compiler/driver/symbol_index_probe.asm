; RF166-G160 native transport for ProjectSymbolIndex facts.
bits 64
default rel
%include "compiler/semantic/index/symbol_index.inc"

global _start
extern neboc_symbol_index_new
extern neboc_index_source
extern neboc_index_interface
extern neboc_index_workspace
extern neboc_index_update
extern neboc_index_filter
extern neboc_index_cache

section .text
_start:
 mov edi,0
 lea rsi,[rel request]
 mov edx,NEBOC_INDEX_REQUEST_SIZE
 call read_exact
 test eax,eax
 jnz .transport
 ; The transport is an exact-size value message; trailing bytes are rejected.
 xor edi,edi
 lea rsi,[rel trailing]
 mov edx,1
 xor eax,eax
 syscall
 test rax,rax
 jnz .transport
 mov rax,[rel request+NEBOC_INDEX_OPERATION_OFFSET]
 cmp rax,NEBOC_INDEX_OP_NEW
 je .new
 cmp rax,NEBOC_INDEX_OP_SOURCE
 je .source
 cmp rax,NEBOC_INDEX_OP_INTERFACE
 je .interface
 cmp rax,NEBOC_INDEX_OP_WORKSPACE
 je .workspace
 cmp rax,NEBOC_INDEX_OP_INCREMENTAL
 je .incremental
 cmp rax,NEBOC_INDEX_OP_FILTER
 je .filter
 cmp rax,NEBOC_INDEX_OP_CACHE
 je .cache
 jmp .rejected
.new:
 lea rax,[rel neboc_symbol_index_new]
 jmp .invoke
.source:
 lea rax,[rel neboc_index_source]
 jmp .invoke
.interface:
 lea rax,[rel neboc_index_interface]
 jmp .invoke
.workspace:
 lea rax,[rel neboc_index_workspace]
 jmp .invoke
.incremental:
 lea rax,[rel neboc_index_update]
 jmp .invoke
.filter:
 lea rax,[rel neboc_index_filter]
 jmp .invoke
.cache:
 lea rax,[rel neboc_index_cache]
.invoke:
 lea rdi,[rel request]
 lea rsi,[rel result]
 call rax
 test eax,eax
 jnz .rejected
 mov edi,1
 lea rsi,[rel result]
 mov edx,NEBOC_INDEX_RESULT_SIZE
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
 mov edx,NEBOC_INDEX_REQUEST_SIZE
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
 mov edx,NEBOC_INDEX_RESULT_SIZE
 jmp .write_loop
transfer_ok:
 xor eax,eax
 ret
transfer_fail:
 mov eax,1
 ret

section .bss
align 8
request: resb NEBOC_INDEX_REQUEST_SIZE
result: resb NEBOC_INDEX_RESULT_SIZE
trailing: resb 1
section .note.GNU-stack noalloc noexec nowrite progbits
