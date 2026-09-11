bits 64
default rel
%include "runtime/kernel/numeric_benchmark.inc"
section .data
request dq 10,2,0
section .bss
result resb NEBO_BENCH_RESULT_SIZE
section .text
global _start
_start:
 lea rdi,[request]
 lea rsi,[result]
 call nebo_numeric_benchmark_run
 test eax,eax
 jnz .fail1
 mov rax,__float64__(2080.0)
 cmp [result+NEBO_BENCH_RESULT_CHECKSUM],rax
 jne .fail2
 cmp qword [result+NEBO_BENCH_RESULT_ITERATIONS],10
 jne .fail3
 cmp qword [result+NEBO_BENCH_RESULT_WARMUP],2
 jne .fail4
 cmp qword [result+NEBO_BENCH_RESULT_ELAPSED_NS],0
 jle .fail5
 mov r12,[result+NEBO_BENCH_RESULT_CHECKSUM]
 lea rdi,[request]
 lea rsi,[result]
 call nebo_numeric_benchmark_run
 cmp [result+NEBO_BENCH_RESULT_CHECKSUM],r12
 jne .fail6
 mov qword [request],1001
 call .run
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail7
 cmp qword [result],0
 jne .fail8
 mov qword [request],1
 mov qword [request+8],101
 call .run
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail9
 mov qword [request+8],0
 mov qword [request+16],65537
 call .run
 cmp eax,NEBO_NUMERIC_ERROR_WORKSPACE
 jne .fail10
 lea rdi,[request]
 xor esi,esi
 call nebo_numeric_benchmark_run
 cmp eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jne .fail11
 xor edi,edi
 lea rsi,[result]
 call nebo_numeric_benchmark_run
 cmp eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jne .fail12
 xor edi,edi
 jmp .exit
.run:
 lea rdi,[request]
 lea rsi,[result]
 call nebo_numeric_benchmark_run
 ret
%assign i 1
%rep 12
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
