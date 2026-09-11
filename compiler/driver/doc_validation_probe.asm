; RF166-G157 binary transport for the native DocValidator.
bits 64
default rel
%include "compiler/semantic/docs/doc_validation.inc"
global _start
extern neboc_doc_validate
section .text
_start:
 xor r12d,r12d
.read:
 cmp r12,NEBOC_DOCV_REQUEST_SIZE
 jae .validate
 xor eax,eax
 xor edi,edi
 lea rsi,[rel request]
 add rsi,r12
 mov edx,NEBOC_DOCV_REQUEST_SIZE
 sub rdx,r12
 syscall
 test rax,rax
 jle .transport
 add r12,rax
 jmp .read
.validate:
 lea rdi,[rel request]
 lea rsi,[rel report]
 call neboc_doc_validate
 test eax,eax
 jnz .semantic
 xor r12d,r12d
.write:
 cmp r12,NEBOC_DOCV_REPORT_SIZE
 jae .success
 mov eax,1
 mov edi,1
 lea rsi,[rel report]
 add rsi,r12
 mov edx,NEBOC_DOCV_REPORT_SIZE
 sub rdx,r12
 syscall
 test rax,rax
 jle .transport
 add r12,rax
 jmp .write
.success:
 xor edi,edi
 jmp .exit
.semantic:
 mov edi,1
 jmp .exit
.transport:
 mov edi,2
.exit:
 mov eax,60
 syscall
section .bss align=16
request: resb NEBOC_DOCV_REQUEST_SIZE
report: resb NEBOC_DOCV_REPORT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
