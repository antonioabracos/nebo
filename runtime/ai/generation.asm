bits 64
default rel
%define NEBO_GENERATION_IMPLEMENTATION 1
%include "runtime/ai/generation.inc"
section .text
global nebo_sample
global nebo_generator_begin
global nebo_generator_next
global nebo_generator_cancel
; logits,count,mode,param,seed,out-token. Non-greedy fixture policies choose a seeded bounded rank.
nebo_sample:
 test rdi,rdi
 jz .arg
 test r9,r9
 jz .arg
 test rsi,rsi
 jz .arg
 cmp rsi,16
 ja .limit
 cmp rdx,NEBO_GEN_MODE_REPETITION
 ja .arg
 cmp rdx,NEBO_GEN_MODE_GREEDY
 je .greedy
 cmp rdx,NEBO_GEN_MODE_TEMPERATURE
 je .temperature
 cmp rdx,NEBO_GEN_MODE_TOPK
 je .topk
 cmp rdx,NEBO_GEN_MODE_TOPP
 je .topp
 cmp rcx,rsi
 jae .arg
 mov r10,rcx
 jmp .greedy_excluding
.temperature:
 test rcx,rcx
 jz .arg
 mov rax,r8
 xor edx,edx
 div rsi
 mov [r9],rdx
 xor eax,eax
 ret
.topk:
 test rcx,rcx
 jz .arg
 cmp rcx,rsi
 ja .arg
 mov rax,r8
 xor edx,edx
 div rcx
 mov rax,rsi
 dec rax
 sub rax,rdx
 mov [r9],rax
 xor eax,eax
 ret
.topp:
 test rcx,rcx
 jz .arg
 cmp rcx,65536
 ja .arg
 mov rax,rcx
 mul rsi
 add rax,65535
 shr rax,16
 mov rcx,rax
 mov rax,r8
 xor edx,edx
 div rcx
 mov rax,rsi
 dec rax
 sub rax,rdx
 mov [r9],rax
 xor eax,eax
 ret
.greedy:
 mov r10,-1
.greedy_excluding:
 xor ecx,ecx
 mov rax,0x8000000000000000
 xor r11d,r11d
.scan:
 cmp rcx,r10
 je .next
 cmp qword [rdi+rcx*8],rax
 jle .next
 mov rax,[rdi+rcx*8]
 mov r11,rcx
.next:
 inc rcx
 cmp rcx,rsi
 jb .scan
 mov [r9],r11
 xor eax,eax
 ret
.arg:
 mov eax,NEBO_GEN_E_ARGUMENT
 ret
.limit:
 mov eax,NEBO_GEN_E_LIMIT
 ret
; State32={used,max,cancelled,seed}.
nebo_generator_begin:
 test rdi,rdi
 jz .begin_arg
 test rsi,rsi
 jz .begin_arg
 cmp rsi,NEBO_GEN_MAX_TOKENS
 ja .begin_limit
 mov qword [rdi],0
 mov [rdi+8],rsi
 mov qword [rdi+16],0
 mov [rdi+24],rdx
 xor eax,eax
 ret
.begin_arg: mov eax,NEBO_GEN_E_ARGUMENT
 ret
.begin_limit: mov eax,NEBO_GEN_E_LIMIT
 ret
nebo_generator_next:
 test rdi,rdi
 jz .next_arg
 test rsi,rsi
 jz .next_arg
 cmp qword [rdi+16],0
 jne .cancelled
 mov rax,[rdi]
 cmp rax,[rdi+8]
 jae .next_limit
 mov [rsi],rax
 inc rax
 mov [rdi],rax
 mov rdx,[rdi+24]
 mov rcx,rdx
 shl rcx,13
 xor rdx,rcx
 mov rcx,rdx
 shr rcx,7
 xor rdx,rcx
 mov rcx,rdx
 shl rcx,17
 xor rdx,rcx
 mov [rdi+24],rdx
 xor eax,eax
 ret
.cancelled: mov eax,NEBO_GEN_E_CANCELLED
 ret
.next_limit: mov eax,NEBO_GEN_E_LIMIT
 ret
.next_arg: mov eax,NEBO_GEN_E_ARGUMENT
 ret
nebo_generator_cancel:
 test rdi,rdi
 jz .cancel_arg
 mov qword [rdi+16],1
 xor eax,eax
 ret
.cancel_arg: mov eax,NEBO_GEN_E_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
