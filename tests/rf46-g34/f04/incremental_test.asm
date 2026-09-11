bits 64
default rel
%include "runtime/reasoning/incremental.inc"
extern nebo_inference_apply_delta,nebo_explanation_init
section .bss
state resq 1
proof resb NEBO_EXPLAIN_SIZE
section .text
global _start
_start:
 mov edi,7
 mov esi,8
 mov edx,2
 lea rcx,[state]
 call nebo_inference_apply_delta
 test eax,eax
 jnz fail
 cmp qword [state],13
 jne fail
 lea rdi,[proof]
 mov esi,8
 mov edx,103
 mov ecx,6
 mov r8d,1
 call nebo_explanation_init
 cmp qword [proof+NEBO_EXPLAIN_RULE],103
 jne fail
 cmp qword [proof+NEBO_EXPLAIN_PREMISES],6
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
