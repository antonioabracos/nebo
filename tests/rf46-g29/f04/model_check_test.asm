bits 64
default rel
%include "compiler/verification/model_check.inc"
extern nebo_model_check
section .data
transitions dq 2,4,0
model: dq transitions,3,1,4,4,NEBO_MODEL_PROPERTY_ALWAYS_SAFE,16
section .bss
result resb NEBO_MODEL_RESULT_SIZE
section .text
global _start
_start:
 lea rdi,[model]
 lea rsi,[result]
 call nebo_model_check
 test eax,eax
 jnz fail
 cmp qword [result],NEBO_MODEL_STATE_VIOLATED
 jne fail
 cmp qword [result+8],2
 jne fail
 cmp qword [result+16],2
 jne fail
 mov qword [model+NEBO_MODEL_UNSAFE_MASK],0
 lea rdi,[model]
 lea rsi,[result]
 call nebo_model_check
 test eax,eax
 jnz fail
 cmp qword [result],NEBO_MODEL_STATE_VERIFIED
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
