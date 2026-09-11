bits 64
default rel
%include "runtime/numeric/vector.inc"
section .data
align 8
ia dq 1,2,3,4
ib dq 4,3,2,1
io dq 99,99,99,99
iov dq 0x7fffffffffffffff,2,3,4
fa dq 1.0,2.0,3.0,4.0
fb dq 4.0,3.0,2.0,1.0
fo dq 0.0,0.0,0.0,0.0
fz dq 0.0,0.0,0.0,0.0
two dq 2.0
one dq 1.0
thirty dq 30.0
section .text
global _start
_start:
 lea rdi,[io]
 lea rsi,[ia]
 lea rdx,[ib]
 mov ecx,4
 call nebo_vector_i64_add
 test eax,eax
 jnz .fail1
 cmp qword [io],5
 jne .fail2
 cmp qword [io+24],5
 jne .fail3
 lea rdi,[io]
 lea rsi,[iov]
 mov rdx,2
 mov ecx,4
 call nebo_vector_i64_scale
 cmp eax,NEBO_NUMERIC_ERROR_OVERFLOW
 jne .fail4
 cmp qword [io],5
 jne .fail5
 lea rdi,[ia]
 lea rsi,[ib]
 mov edx,4
 call nebo_vector_i64_dot
 test eax,eax
 jnz .fail6
 cmp rdx,20
 jne .fail7
 lea rdi,[ia]
 mov esi,4
 mov edx,3
 call nebo_vector_i64_at
 cmp rdx,4
 jne .fail8
 lea rdi,[ia]
 mov esi,4
 mov edx,4
 call nebo_vector_i64_at
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail9
 lea rdi,[fo]
 lea rsi,[fa]
 lea rdx,[fb]
 mov ecx,4
 call nebo_vector_f64_add
 test eax,eax
 jnz .fail10
 mov rax,0x4014000000000000
 cmp [fo],rax
 jne .fail11
 lea rdi,[fa]
 lea rsi,[fa]
 mov edx,4
 call nebo_vector_f64_dot
 test eax,eax
 jnz .fail12
 ucomisd xmm0,[rel thirty]
 jne .fail13
 lea rdi,[fo]
 lea rsi,[fa]
 movsd xmm0,[rel two]
 mov edx,4
 call nebo_vector_f64_scale
 test eax,eax
 jnz .fail14
 mov rax,0x4000000000000000
 cmp [fo],rax
 jne .fail15
 lea rdi,[fo]
 lea rsi,[fa]
 mov edx,4
 call nebo_vector_f64_normalize
 test eax,eax
 jnz .fail16
 lea rdi,[fo]
 mov esi,4
 call nebo_vector_f64_norm
 subsd xmm0,[rel one]
 movq rax,xmm0
 btr rax,63
 mov rcx,0x3d719799812dea11
 cmp rax,rcx
 ja .fail17
 lea rdi,[fo]
 lea rsi,[fz]
 mov edx,4
 call nebo_vector_f64_normalize
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail18
 xor edi,edi
 jmp .exit
%assign i 1
%rep 18
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
