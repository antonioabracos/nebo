; RF166-G158 native probe for executable documentation operations.
bits 64
default rel
%include "compiler/docs/doc_examples.inc"

global _start
extern neboc_doc_example_plan
extern neboc_doc_example_compile
extern neboc_doc_example_run
extern neboc_doc_law_run
extern neboc_doc_staleness
extern neboc_doc_compatibility
extern neboc_doc_redaction

section .text
_start:
 mov edi,0
 lea rsi,[rel request]
 mov edx,NEBOC_DOCX_REQUEST_SIZE
 call read_exact
 test eax,eax
 jnz .transport
 mov rax,[rel request+NEBOC_DOCX_OPERATION_OFFSET]
 cmp rax,NEBOC_DOCX_OP_PLAN
 je .plan
 cmp rax,NEBOC_DOCX_OP_COMPILE
 je .compile
 cmp rax,NEBOC_DOCX_OP_RUN
 je .run
 cmp rax,NEBOC_DOCX_OP_LAW
 je .law
 cmp rax,NEBOC_DOCX_OP_STALENESS
 je .staleness
 cmp rax,NEBOC_DOCX_OP_COMPATIBILITY
 je .compatibility
 cmp rax,NEBOC_DOCX_OP_REDACTION
 je .redaction
 jmp .rejected
.plan:
 lea rax,[rel neboc_doc_example_plan]
 jmp .invoke
.compile:
 lea rax,[rel neboc_doc_example_compile]
 jmp .invoke
.run:
 lea rax,[rel neboc_doc_example_run]
 jmp .invoke
.law:
 lea rax,[rel neboc_doc_law_run]
 jmp .invoke
.staleness:
 lea rax,[rel neboc_doc_staleness]
 jmp .invoke
.compatibility:
 lea rax,[rel neboc_doc_compatibility]
 jmp .invoke
.redaction:
 lea rax,[rel neboc_doc_redaction]
.invoke:
 lea rdi,[rel request]
 lea rsi,[rel result]
 call rax
 test eax,eax
 jnz .rejected
 mov edi,1
 lea rsi,[rel result]
 mov edx,NEBOC_DOCX_RESULT_SIZE
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

; edi=fd, rsi=buffer, edx=bytes. eax=0 on exact transfer.
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
 mov edx,NEBOC_DOCX_REQUEST_SIZE
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
 mov edx,NEBOC_DOCX_RESULT_SIZE
 jmp .write_loop
transfer_ok:
 xor eax,eax
 ret
transfer_fail:
 mov eax,1
 ret

section .bss
align 8
request: resb NEBOC_DOCX_REQUEST_SIZE
result: resb NEBOC_DOCX_RESULT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
