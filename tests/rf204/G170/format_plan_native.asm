; A compiled plan remains executable after placeholder source bytes change.
; The dynamic request rejects those same bytes and leaves output untouched.
bits 64
default rel
%include "runtime/textual/percent_format.inc"

section .data
template: db '%d'
argument: dq PERCENT_ARG_INT,29,0,0
request:
 dq template,2,nodes,PERCENT_MAX_NODES,0,argument,1,0,output,16,0,0
section .bss
align 16
nodes: resb PERCENT_NODE_SIZE*PERCENT_MAX_NODES
output: resb 16
section .text
global _start
_start:
 lea rdi,[rel request]
 call neboc_percent_compile_request
 test eax,eax
 jnz .fail
 mov byte [rel template+1],'z'
 lea rdi,[rel request]
 call neboc_percent_validate_plan_request
 test eax,eax
 jnz .fail
 cmp qword [rel request+PERCENT_REQUEST_WRITTEN],2
 jne .fail
 lea rdi,[rel request]
 call neboc_percent_render_plan_request
 test eax,eax
 jnz .fail
 cmp word [rel output],0x3932
 jne .fail
 mov qword [rel output],0x17171717
 lea rdi,[rel request]
 call neboc_percent_render_request
 cmp eax,PERCENT_DIAG_UNKNOWN_PLACEHOLDER
 jne .fail
 cmp qword [rel output],0x17171717
 jne .fail
 mov eax,60
 xor edi,edi
 syscall
.fail:
 mov eax,60
 mov edi,1
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
