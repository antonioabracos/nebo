bits 64
default rel
%include "runtime/tokenizer/tokenizer.inc"
%include "runtime/ai/tiny_causal.inc"
%include "runtime/ai/generation.inc"
%include "runtime/ai/structured.inc"
%include "runtime/agent/tools.inc"
%include "runtime/agent/agent.inc"
%include "runtime/ai/evaluation.inc"
section .data
bytes db 1,2,3
schema dq 1,2
values dq 1,2
section .bss
tokens resq 3
countv resq 1
logits resq 16
sample_out resq 1
registry resq 34
callv resq 7
agent resq 8
evalstate resq 7
report resq 4
section .text
global _start
_start:
 lea rdi,[rel bytes]
 mov esi,3
 lea rdx,[rel tokens]
 mov ecx,3
 lea r8,[rel countv]
 call nebo_tokenizer_encode
 test eax,eax
 jne .f1
 lea rdi,[rel tokens]
 mov esi,3
 lea rdx,[rel logits]
 call nebo_causal_forward
 test eax,eax
 jne .f2
 lea rdi,[rel logits]
 mov esi,16
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 lea r9,[rel sample_out]
 call nebo_sample
 test eax,eax
 jne .f3
 cmp qword [rel sample_out],15
 jne .f4
 lea rdi,[rel values]
 mov esi,2
 lea rdx,[rel schema]
 mov ecx,2
 call nebo_structured_schema_validate
 test eax,eax
 jne .f5
 lea rdi,[rel registry]
 call nebo_tool_registry_init
 test eax,eax
 jne .f6
 lea rdi,[rel registry]
 mov esi,1
 mov edx,0x10
 call nebo_tool_register
 test eax,eax
 jne .f7
 mov qword [rel callv],1
 mov qword [rel callv+8],0x10
 mov qword [rel callv+16],1
 mov qword [rel callv+24],16
 mov qword [rel callv+32],7
 mov qword [rel callv+40],9
 lea rdi,[rel registry]
 lea rsi,[rel callv]
 call nebo_tool_call
 test eax,eax
 jne .f8
 cmp qword [rel callv+48],16
 jne .f9
 lea rdi,[rel agent]
 mov esi,16
 mov edx,8
 mov ecx,8
 call nebo_agent_begin
 test eax,eax
 jne .f10
 lea rdi,[rel agent]
 call nebo_agent_approve
 test eax,eax
 jne .f11
 lea rdi,[rel agent]
 mov esi,1
 mov edx,1
 mov ecx,1
 mov r8d,64
 call nebo_agent_step
 test eax,eax
 jne .f12
 lea rdi,[rel evalstate]
 mov rsi,0x1122
 mov rdx,0x3344
 call nebo_eval_init
 test eax,eax
 jne .f13
 lea rdi,[rel evalstate]
 mov esi,1
 mov edx,100
 mov ecx,4096
 mov r8d,64
 call nebo_eval_record
 test eax,eax
 jne .f14
 lea rdi,[rel evalstate]
 lea rsi,[rel report]
 call nebo_eval_report
 test eax,eax
 jne .f15
 cmp qword [rel report+16],65536
 jne .f16
 xor edi,edi
 jmp .exit
%assign i 1
%rep 16
.f%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
