; RF166-G159 native transport for deterministic local-documentation operations.
bits 64
default rel
%include "compiler/docs/docs.inc"

global _start
extern neboc_docs_graph
extern neboc_docs_render
extern neboc_docs_search
extern neboc_docs_links
extern neboc_docs_views
extern neboc_docs_cli
extern neboc_docs_archive

section .text
_start:
 mov edi,0
 lea rsi,[rel request]
 mov edx,NEBOC_DOCS_REQUEST_SIZE
 call read_exact
 test eax,eax
 jnz .transport
 mov rax,[rel request+NEBOC_DOCS_OPERATION_OFFSET]
 cmp rax,NEBOC_DOCS_OP_GRAPH
 je .graph
 cmp rax,NEBOC_DOCS_OP_RENDER
 je .render
 cmp rax,NEBOC_DOCS_OP_SEARCH
 je .search
 cmp rax,NEBOC_DOCS_OP_LINKS
 je .links
 cmp rax,NEBOC_DOCS_OP_VIEWS
 je .views
 cmp rax,NEBOC_DOCS_OP_CLI
 je .cli
 cmp rax,NEBOC_DOCS_OP_ARCHIVE
 je .archive
 jmp .rejected
.graph:
 lea rax,[rel neboc_docs_graph]
 jmp .invoke
.render:
 lea rax,[rel neboc_docs_render]
 jmp .invoke
.search:
 lea rax,[rel neboc_docs_search]
 jmp .invoke
.links:
 lea rax,[rel neboc_docs_links]
 jmp .invoke
.views:
 lea rax,[rel neboc_docs_views]
 jmp .invoke
.cli:
 lea rax,[rel neboc_docs_cli]
 jmp .invoke
.archive:
 lea rax,[rel neboc_docs_archive]
.invoke:
 lea rdi,[rel request]
 lea rsi,[rel result]
 call rax
 test eax,eax
 jnz .rejected
 mov edi,1
 lea rsi,[rel result]
 mov edx,NEBOC_DOCS_RESULT_SIZE
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

; edi=fd, rsi=buffer, edx=bytes. eax=0 after an exact transfer.
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
 mov edx,NEBOC_DOCS_REQUEST_SIZE
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
 mov edx,NEBOC_DOCS_RESULT_SIZE
 jmp .write_loop
transfer_ok:
 xor eax,eax
 ret
transfer_fail:
 mov eax,1
 ret

section .bss
align 8
request: resb NEBOC_DOCS_REQUEST_SIZE
result: resb NEBOC_DOCS_RESULT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
