; TREE-GRAPH-NODE-E-EDGE-F05 deterministic bounded descriptive statistics
bits 64
default rel
%define NEBO_STATISTICS_IMPLEMENTATION 1
%include "runtime/numeric/statistics.inc"
section .rodata
align 8
stats_zero dq 0.0
stats_half dq 0.5
stats_one dq 1.0
section .text
global nebo_stats_sum_i64
global nebo_stats_sum_f64
global nebo_stats_mean_f64
global nebo_stats_variance_f64
global nebo_stats_stddev_f64
global nebo_stats_quantile_f64
global nebo_stats_median_f64
global nebo_stats_correlation_f64

stats_validate:
 test rdi,rdi
 jz .arg
 test rsi,rsi
 jz .domain
 cmp rsi,NEBO_NUMERIC_MAX_ELEMENTS
 ja .bounds
 xor eax,eax
 ret
.arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
.domain: mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 ret
.bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 ret

; ptr rdi, count rsi -> status eax, sum rdx
nebo_stats_sum_i64:
 call stats_validate
 test eax,eax
 jnz .sum_i_ret
 xor ecx,ecx
 xor edx,edx
.sum_i_loop:
 add rdx,[rdi+rcx*8]
 jo .sum_i_overflow
 inc rcx
 cmp rcx,rsi
 jb .sum_i_loop
 xor eax,eax
.sum_i_ret: ret
.sum_i_overflow: mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
 ret

; Kahan sum: ptr rdi, count rsi -> status eax, sum xmm0.
nebo_stats_sum_f64:
 call stats_validate
 test eax,eax
 jnz .sum_f_ret
 xorpd xmm0,xmm0
 xorpd xmm1,xmm1
 xor ecx,ecx
.sum_f_loop:
 movsd xmm2,[rdi+rcx*8]
 subsd xmm2,xmm1
 movapd xmm3,xmm0
 addsd xmm3,xmm2
 movapd xmm1,xmm3
 subsd xmm1,xmm0
 subsd xmm1,xmm2
 movapd xmm0,xmm3
 inc rcx
 cmp rcx,rsi
 jb .sum_f_loop
 xor eax,eax
.sum_f_ret: ret

nebo_stats_mean_f64:
 push r12
 mov r12,rsi
 call nebo_stats_sum_f64
 test eax,eax
 jnz .mean_ret
 cvtsi2sd xmm1,r12
 divsd xmm0,xmm1
.mean_ret: pop r12
 ret

; ptr rdi count rsi sample rdx(0 population,1 sample) -> xmm0
nebo_stats_variance_f64:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 cmp r14,1
 ja .var_domain
 test r14,r14
 jz .var_mean
 cmp r13,2
 jb .var_domain
.var_mean:
 call nebo_stats_mean_f64
 test eax,eax
 jnz .var_ret
 movapd xmm4,xmm0
 xorpd xmm0,xmm0
 xorpd xmm1,xmm1
 xor ecx,ecx
.var_loop:
 movsd xmm2,[r12+rcx*8]
 subsd xmm2,xmm4
 mulsd xmm2,xmm2
 subsd xmm2,xmm1
 movapd xmm3,xmm0
 addsd xmm3,xmm2
 movapd xmm1,xmm3
 subsd xmm1,xmm0
 subsd xmm1,xmm2
 movapd xmm0,xmm3
 inc rcx
 cmp rcx,r13
 jb .var_loop
 mov rax,r13
 sub rax,r14
 cvtsi2sd xmm1,rax
 divsd xmm0,xmm1
 xor eax,eax
.var_ret:
 pop r14
 pop r13
 pop r12
 ret
.var_domain:
 mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 jmp .var_ret

nebo_stats_stddev_f64:
 call nebo_stats_variance_f64
 test eax,eax
 jnz .std_ret
 sqrtsd xmm0,xmm0
.std_ret: ret

; ptr rdi count rsi workspace rdx, q xmm0. Method: linear (R type 7).
nebo_stats_quantile_f64:
 test rdx,rdx
 jz .quant_arg
 ucomisd xmm0,[rel stats_zero]
 jp .quant_domain
 jb .quant_domain
 ucomisd xmm0,[rel stats_one]
 ja .quant_domain
 push r12
 push r13
 push r14
 mov r12,rdx
 mov r13,rsi
 movapd xmm7,xmm0
 call stats_validate
 test eax,eax
 jnz .quant_ret
 xor ecx,ecx
.quant_copy:
 mov rax,[rdi+rcx*8]
 mov [r12+rcx*8],rax
 inc rcx
 cmp rcx,r13
 jb .quant_copy
 mov ecx,1
.quant_outer:
 cmp rcx,r13
 jae .quant_sorted
 movsd xmm0,[r12+rcx*8]
 mov rdx,rcx
.quant_inner:
 test rdx,rdx
 jz .quant_insert
 movsd xmm1,[r12+rdx*8-8]
 ucomisd xmm1,xmm0
 jbe .quant_insert
 movsd [r12+rdx*8],xmm1
 dec rdx
 jmp .quant_inner
.quant_insert:
 movsd [r12+rdx*8],xmm0
 inc rcx
 jmp .quant_outer
.quant_sorted:
 mov rax,r13
 dec rax
 cvtsi2sd xmm1,rax
 mulsd xmm1,xmm7
 cvttsd2si r14,xmm1
 cvtsi2sd xmm2,r14
 subsd xmm1,xmm2
 movsd xmm0,[r12+r14*8]
 cmp r14,rax
 je .quant_ok
 movsd xmm2,[r12+r14*8+8]
 subsd xmm2,xmm0
 mulsd xmm2,xmm1
 addsd xmm0,xmm2
.quant_ok:
 xor eax,eax
.quant_ret:
 pop r14
 pop r13
 pop r12
 ret
.quant_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
.quant_domain: mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 ret

nebo_stats_median_f64:
 movsd xmm0,[rel stats_half]
 jmp nebo_stats_quantile_f64

; x rdi, y rsi, count rdx -> Pearson correlation xmm0.
nebo_stats_correlation_f64:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rsi,rdx
 call nebo_stats_mean_f64
 test eax,eax
 jnz .corr_ret
 movapd xmm4,xmm0
 mov rdi,r13
 mov rsi,r14
 call nebo_stats_mean_f64
 test eax,eax
 jnz .corr_ret
 movapd xmm5,xmm0
 xorpd xmm0,xmm0
 xorpd xmm1,xmm1
 xorpd xmm2,xmm2
 xor ecx,ecx
.corr_loop:
 movsd xmm6,[r12+rcx*8]
 subsd xmm6,xmm4
 movsd xmm7,[r13+rcx*8]
 subsd xmm7,xmm5
 movapd xmm3,xmm6
 mulsd xmm3,xmm7
 addsd xmm0,xmm3
 mulsd xmm6,xmm6
 addsd xmm1,xmm6
 mulsd xmm7,xmm7
 addsd xmm2,xmm7
 inc rcx
 cmp rcx,r14
 jb .corr_loop
 ucomisd xmm1,[rel stats_zero]
 jbe .corr_domain
 ucomisd xmm2,[rel stats_zero]
 jbe .corr_domain
 mulsd xmm1,xmm2
 sqrtsd xmm1,xmm1
 divsd xmm0,xmm1
 xor eax,eax
.corr_ret:
 pop r14
 pop r13
 pop r12
 ret
.corr_domain:
 mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 jmp .corr_ret
section .note.GNU-stack noalloc noexec nowrite progbits
