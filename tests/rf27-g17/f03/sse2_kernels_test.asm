bits 64
default rel
%include "runtime/kernel/sse2_kernels.inc"
section .data
align 8
a dq 1.0,2.0,3.0,4.0,5.0,6.0
b dq 6.0,5.0,4.0,3.0,2.0,1.0
i64s dq -3,0,9
section .bss
align 8
sse_out resq 8
scalar_out resq 8
converted resq 3
section .text
global _start
_start:
 lea rdi,[sse_out]
 lea rsi,[a]
 lea rdx,[b]
 mov ecx,5
 call nebo_sse2_add_f64
 test eax,eax
 jnz .fail1
 lea rdi,[scalar_out]
 lea rsi,[a]
 lea rdx,[b]
 mov ecx,5
 call nebo_scalar_add_f64
 test eax,eax
 jnz .fail2
 xor ecx,ecx
.compare: mov rax,[sse_out+rcx*8]
 cmp rax,[scalar_out+rcx*8]
 jne .fail3
 inc rcx
 cmp rcx,5
 jb .compare
 lea rdi,[a]
 lea rsi,[b]
 mov edx,5
 call nebo_sse2_dot_f64
 test eax,eax
 jnz .fail4
 movq r12,xmm0
 lea rdi,[a]
 lea rsi,[b]
 mov edx,5
 call nebo_scalar_dot_f64
 movq rax,xmm0
 cmp rax,r12
 jne .fail5
 lea rdi,[a]
 mov esi,5
 call nebo_sse2_reduce_sum_f64
 movq r12,xmm0
 lea rdi,[a]
 mov esi,5
 call nebo_scalar_reduce_sum_f64
 movq rax,xmm0
 cmp rax,r12
 jne .fail6
 lea rdi,[converted]
 lea rsi,[i64s]
 mov edx,3
 call nebo_sse2_i64_to_f64
 test eax,eax
 jnz .fail7
 mov rax,__float64__(9.0)
 cmp [converted+16],rax
 jne .fail8
 lea rdi,[sse_out]
 lea rsi,[a+8]
 lea rdx,[b+8]
 mov ecx,3
 call nebo_sse2_add_f64
 test eax,eax
 jnz .fail9
 mov rax,__float64__(7.0)
 cmp [sse_out],rax
 jne .fail10
 xor edi,edi
 xor esi,esi
 xor edx,edx
 call nebo_sse2_dot_f64
 test eax,eax
 jnz .fail11
 movq rax,xmm0
 test rax,rax
 jnz .fail12
 lea rdi,[sse_out]
 lea rsi,[a]
 lea rdx,[b]
 mov ecx,4097
 call nebo_sse2_add_f64
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail13
 lea rdi,[sse_out]
 lea rsi,[sse_out]
 lea rdx,[b]
 mov ecx,2
 call nebo_sse2_add_f64
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail14
 xor edi,edi
 lea rsi,[a]
 lea rdx,[b]
 mov ecx,1
 call nebo_sse2_add_f64
 cmp eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jne .fail15
 xor edi,edi
 jmp .exit
%assign i 1
%rep 15
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
