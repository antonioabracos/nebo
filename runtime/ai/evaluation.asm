bits 64
default rel
%define NEBO_EVALUATION_IMPLEMENTATION 1
%include "runtime/ai/evaluation.inc"
section .text
global nebo_eval_init
global nebo_eval_record
global nebo_eval_report
global nebo_eval_provenance
global nebo_eval_policy_case
; State56={cases,passed,max_latency,max_memory,hash0,hash1,trace_bytes}.
nebo_eval_init:
 test rdi,rdi
 jz .ia
 mov qword [rdi],0
 mov qword [rdi+8],0
 mov qword [rdi+16],0
 mov qword [rdi+24],0
 mov [rdi+32],rsi
 mov [rdi+40],rdx
 mov qword [rdi+48],0
 xor eax,eax
 ret
.ia: mov eax,NEBO_EVAL_E_ARGUMENT
 ret
; state,passed,latency,memory,trace_delta.
nebo_eval_record:
 test rdi,rdi
 jz .ra
 mov rax,[rdi]
 cmp rax,NEBO_EVAL_MAX_CASES
 jae .rl
 mov rax,[rdi+48]
 add rax,r8
 jc .rl
 cmp rax,NEBO_EVAL_MAX_TRACE
 ja .rl
 cmp rdx,[rdi+16]
 jbe .mem
 mov [rdi+16],rdx
.mem:
 cmp rcx,[rdi+24]
 jbe .publish
 mov [rdi+24],rcx
.publish:
 mov [rdi+48],rax
 inc qword [rdi]
 test rsi,rsi
 jz .ok
 inc qword [rdi+8]
.ok: xor eax,eax
 ret
.ra: mov eax,NEBO_EVAL_E_ARGUMENT
 ret
.rl: mov eax,NEBO_EVAL_E_LIMIT
 ret
; state,Report32={cases,passed,scoreQ16,trace_bytes}.
nebo_eval_report:
 test rdi,rdi
 jz .oa
 test rsi,rsi
 jz .oa
 mov rax,[rdi]
 mov [rsi],rax
 mov rdx,[rdi+8]
 mov [rsi+8],rdx
 test rax,rax
 jz .zero
 shl rdx,16
 mov rax,rdx
 xor edx,edx
 div qword [rdi]
 jmp .score
.zero: xor eax,eax
.score:
 mov [rsi+16],rax
 mov rax,[rdi+48]
 mov [rsi+24],rax
 xor eax,eax
 ret
.oa: mov eax,NEBO_EVAL_E_ARGUMENT
 ret
nebo_eval_provenance:
 test rdi,rdi
 jz .pa
 cmp [rdi+32],rsi
 jne .badp
 cmp [rdi+40],rdx
 jne .badp
 xor eax,eax
 ret
.badp: mov eax,NEBO_EVAL_E_PROVENANCE
 ret
.pa: mov eax,NEBO_EVAL_E_ARGUMENT
 ret
; secret_present,policy_bypass: both denied.
nebo_eval_policy_case:
 test rdi,rdi
 jnz .pol
 test rsi,rsi
 jnz .pol
 xor eax,eax
 ret
.pol: mov eax,NEBO_EVAL_E_POLICY
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
