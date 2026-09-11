bits 64
default rel
%include "runtime/kernel/scalar_kernels.inc"
section .data
a dq 1.0,2.0,3.0,4.0,5.0
b dq 5.0,4.0,3.0,2.0,1.0
activation_input dq -2.0,-0.0,3.0
integers dq -2,0,7
ma dq 1.0,2.0,3.0,4.0
mb dq 5.0,6.0,7.0,8.0
section .bss
align 8
result resq 8
boundary_a resq 4096
boundary_b resq 4096
boundary_out resq 4096
section .text
global _start
_start:
 mov edi,1
.registry_loop:
 call nebo_kernel_resolve_scalar
 test rax,rax
 jz .fail1
 inc edi
 cmp edi,7
 jb .registry_loop
 mov edi,99
 call nebo_kernel_resolve_scalar
 test rax,rax
 jnz .fail2
 lea rdi,[result]
 lea rsi,[a]
 lea rdx,[b]
 mov ecx,5
 call nebo_scalar_add_f64
 test eax,eax
 jnz .fail3
 mov rax,__float64__(6.0)
 cmp [result],rax
 jne .fail4
 cmp [result+32],rax
 jne .fail5
 lea rdi,[result]
 lea rsi,[result]
 lea rdx,[b]
 mov ecx,5
 call nebo_scalar_add_f64
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail6
 lea rdi,[a]
 lea rsi,[b]
 mov edx,5
 call nebo_scalar_dot_f64
 test eax,eax
 jnz .fail7
 movq rax,xmm0
 mov rdx,__float64__(35.0)
 cmp rax,rdx
 jne .fail8
 lea rdi,[a]
 mov esi,5
 call nebo_scalar_reduce_sum_f64
 test eax,eax
 jnz .fail9
 movq rax,xmm0
 mov rdx,__float64__(15.0)
 cmp rax,rdx
 jne .fail10
 xor edi,edi
 xor esi,esi
 call nebo_scalar_reduce_sum_f64
 test eax,eax
 jnz .fail11
 movq rax,xmm0
 test rax,rax
 jnz .fail12
 lea rdi,[result]
 lea rsi,[activation_input]
 mov edx,3
 call nebo_scalar_relu_f64
 test eax,eax
 jnz .fail13
 cmp qword [result],0
 jne .fail14
 mov rax,__float64__(3.0)
 cmp [result+16],rax
 jne .fail15
 lea rdi,[result]
 lea rsi,[integers]
 mov edx,3
 call nebo_scalar_i64_to_f64
 test eax,eax
 jnz .fail16
 mov rax,__float64__(-2.0)
 cmp [result],rax
 jne .fail17
 mov rax,__float64__(7.0)
 cmp [result+16],rax
 jne .fail18
 lea rdi,[result]
 lea rsi,[ma]
 lea rdx,[mb]
 mov ecx,2
 mov r8d,2
 mov r9d,2
 call nebo_scalar_matmul_f64
 test eax,eax
 jnz .fail19
 mov rax,__float64__(19.0)
 cmp [result],rax
 jne .fail20
 mov rax,__float64__(50.0)
 cmp [result+24],rax
 jne .fail21
 lea rdi,[boundary_out]
 lea rsi,[boundary_a]
 lea rdx,[boundary_b]
 mov ecx,4096
 call nebo_scalar_add_f64
 test eax,eax
 jnz .fail22
 lea rdi,[boundary_out]
 lea rsi,[boundary_a]
 lea rdx,[boundary_b]
 mov ecx,4097
 call nebo_scalar_add_f64
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail23
 xor edi,edi
 xor esi,esi
 xor edx,edx
 xor ecx,ecx
 call nebo_scalar_add_f64
 test eax,eax
 jnz .fail24
 xor edi,edi
 lea rsi,[a]
 lea rdx,[b]
 mov ecx,1
 call nebo_scalar_add_f64
 cmp eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jne .fail25
 xor edi,edi
 jmp .exit
%assign i 1
%rep 25
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
