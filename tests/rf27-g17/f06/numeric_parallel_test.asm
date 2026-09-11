bits 64
default rel
%include "runtime/kernel/numeric_parallel.inc"
section .bss
align 32
a resq 1025
b resq 1025
parallel_out resq 1025
serial resq 1025
plan resb NEBO_PARALLEL_PLAN_SIZE
cancelled resq 1
section .text
global _start
_start:
 ; Deterministic bounded partitioning and no oversubscription.
 mov edi,1025
 mov esi,8
 lea rdx,[plan]
 call nebo_parallel_plan
 test eax,eax
 jnz .fail1
 cmp qword [plan+NEBO_PARALLEL_PLAN_CHUNKS],5
 jne .fail2
 cmp qword [plan+NEBO_PARALLEL_PLAN_WORKERS],5
 jne .fail3
 cmp qword [plan+NEBO_PARALLEL_PLAN_LAST_CHUNK],1
 jne .fail4
 mov r12,[plan+NEBO_PARALLEL_PLAN_TRACE]
 mov edi,1025
 mov esi,8
 lea rdx,[plan]
 call nebo_parallel_plan
 cmp [plan+NEBO_PARALLEL_PLAN_TRACE],r12
 jne .fail5
 mov edi,4096
 mov esi,8
 lea rdx,[plan]
 call nebo_parallel_plan
 cmp qword [plan+NEBO_PARALLEL_PLAN_CHUNKS],16
 jne .fail6
 cmp qword [plan+NEBO_PARALLEL_PLAN_WORKERS],8
 jne .fail7
 xor edi,edi
 mov esi,8
 lea rdx,[plan]
 call nebo_parallel_plan
 cmp qword [plan+NEBO_PARALLEL_PLAN_WORKERS],1
 jne .fail8
 ; Initialize stable values and compare add with scalar reference.
 xor ecx,ecx
.init: mov rax,rcx
 cvtsi2sd xmm0,rax
 movsd [a+rcx*8],xmm0
 mov rax,__float64__(2.0)
 mov [b+rcx*8],rax
 inc rcx
 cmp rcx,1025
 jb .init
 lea rdi,[parallel_out]
 lea rsi,[a]
 lea rdx,[b]
 mov ecx,1025
 mov r8d,8
 xor r9d,r9d
 call nebo_parallel_add_f64
 test eax,eax
 jnz .fail9
 lea rdi,[serial]
 lea rsi,[a]
 lea rdx,[b]
 mov ecx,1025
 call nebo_scalar_add_f64
 test eax,eax
 jnz .fail10
 xor ecx,ecx
.compare: mov rax,[parallel_out+rcx*8]
 cmp rax,[serial+rcx*8]
 jne .fail11
 inc rcx
 cmp rcx,1025
 jb .compare
 ; Reduction uses fixed chunk and ascending partial order.
 lea rdi,[b]
 mov esi,1025
 mov edx,8
 xor ecx,ecx
 call nebo_parallel_reduce_sum_f64
 test eax,eax
 jnz .fail12
 mov rax,__float64__(2050.0)
 movq rcx,xmm0
 cmp rcx,rax
 jne .fail13
 ; Pre-cancelled work mutates no output and returns a stable status.
 mov qword [cancelled],1
 mov rax,0x1122334455667788
 mov [parallel_out],rax
 lea rdi,[parallel_out]
 lea rsi,[a]
 lea rdx,[b]
 mov ecx,1025
 mov r8d,8
 lea r9,[cancelled]
 call nebo_parallel_add_f64
 cmp eax,NEBO_NUMERIC_ERROR_CANCELLED
 jne .fail14
 mov rax,0x1122334455667788
 cmp [parallel_out],rax
 jne .fail15
 lea rdi,[b]
 mov esi,1025
 mov edx,8
 lea rcx,[cancelled]
 call nebo_parallel_reduce_sum_f64
 cmp eax,NEBO_NUMERIC_ERROR_CANCELLED
 jne .fail16
 movq rax,xmm0
 test rax,rax
 jnz .fail17
 ; Limits, invalid worker counts and aliases fail before execution.
 mov edi,1
 xor esi,esi
 lea rdx,[plan]
 call nebo_parallel_plan
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail18
 mov edi,4097
 mov esi,1
 lea rdx,[plan]
 call nebo_parallel_plan
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail19
 lea rdi,[a]
 lea rsi,[a]
 lea rdx,[b]
 mov ecx,4
 mov r8d,1
 xor r9d,r9d
 call nebo_parallel_add_f64
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail20
 xor edi,edi
 xor esi,esi
 mov edx,1
 xor ecx,ecx
 call nebo_parallel_reduce_sum_f64
 test eax,eax
 jnz .fail21
 movq rax,xmm0
 test rax,rax
 jnz .fail22
 xor edi,edi
 jmp .exit
%assign i 1
%rep 22
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
