bits 64
default rel
%include "runtime/ai/tiny_causal.inc"
section .data
tokens dq 1,2,3
section .bss
cache resq 34
logits resq 16
scratch resq 1
section .text
global _start
_start:
 lea rdi,[rel cache]
 call nebo_kv_init
 test eax,eax
 jne .fail1
 cmp qword [rel cache],0
 jne .fail2
 cmp qword [rel cache+8],1
 jne .fail3
 lea rdi,[rel cache]
 mov esi,1
 call nebo_kv_append
 test eax,eax
 jne .fail4
 lea rdi,[rel cache]
 mov esi,2
 call nebo_kv_append
 test eax,eax
 jne .fail5
 lea rdi,[rel cache]
 lea rsi,[rel scratch]
 call nebo_kv_length
 test eax,eax
 jne .fail6
 cmp qword [rel scratch],2
 jne .fail7
 lea rdi,[rel tokens]
 mov esi,3
 lea rdx,[rel logits]
 call nebo_causal_forward
 test eax,eax
 jne .fail8
 cmp qword [rel logits],2949120
 jne .fail9
 cmp qword [rel logits+120],5898240
 jne .fail10
 lea rdi,[rel cache]
 mov esi,1
 call nebo_kv_truncate
 test eax,eax
 jne .fail11
 cmp qword [rel cache],1
 jne .fail12
 cmp qword [rel cache+8],2
 jne .fail13
 lea rdi,[rel cache]
 mov esi,16
 call nebo_kv_append
 cmp eax,NEBO_CAUSAL_E_TOKEN
 jne .fail14
 lea rdi,[rel cache]
 mov esi,2
 call nebo_kv_truncate
 cmp eax,NEBO_CAUSAL_E_LIMIT
 jne .fail15
 lea rdi,[rel scratch]
 call nebo_causal_context_length
 test eax,eax
 jne .fail16
 cmp qword [rel scratch],32
 jne .fail17
 mov ecx,5000
.repeat:
 lea rdi,[rel tokens]
 mov esi,3
 lea rdx,[rel logits]
 mov r10,rcx
 call nebo_causal_forward
 mov rcx,r10
 test eax,eax
 jne .fail18
 cmp qword [rel logits],2949120
 jne .fail19
 cmp qword [rel logits+120],5898240
 jne .fail20
 loop .repeat
 xor edi,edi
 jmp .exit
%assign i 1
%rep 20
.fail%+i:
 mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
