bits 64
default rel
%include "runtime/numeric/statistics.inc"
section .data
align 8
iv dq 1,2,3,4
iov dq 0x7fffffffffffffff,1
fv dq 1.0,2.0,3.0,4.0
fy dq 2.0,4.0,6.0,8.0
constant dq 2.0,2.0,2.0,2.0
ten dq 10.0
twofive dq 2.5
one25 dq 1.25
one666 dq 1.6666666666666667
sqrt125 dq 1.118033988749895
one dq 1.0
q25 dq 0.25
qbad dq 1.1
section .bss
align 8
workspace resq 4096
section .text
global _start
_start:
 lea rdi,[iv]
 mov esi,4
 call nebo_stats_sum_i64
 test eax,eax
 jnz .fail1
 cmp rdx,10
 jne .fail2
 lea rdi,[iov]
 mov esi,2
 call nebo_stats_sum_i64
 cmp eax,NEBO_NUMERIC_ERROR_OVERFLOW
 jne .fail3
 lea rdi,[fv]
 mov esi,4
 call nebo_stats_sum_f64
 ucomisd xmm0,[rel ten]
 jne .fail4
 lea rdi,[fv]
 mov esi,4
 call nebo_stats_mean_f64
 ucomisd xmm0,[rel twofive]
 jne .fail5
 lea rdi,[fv]
 mov esi,4
 xor edx,edx
 call nebo_stats_variance_f64
 ucomisd xmm0,[rel one25]
 jne .fail6
 lea rdi,[fv]
 mov esi,4
 mov edx,1
 call nebo_stats_variance_f64
 ucomisd xmm0,[rel one666]
 jne .fail7
 lea rdi,[fv]
 mov esi,4
 xor edx,edx
 call nebo_stats_stddev_f64
 subsd xmm0,[rel sqrt125]
 movq rax,xmm0
 btr rax,63
 mov rcx,0x3d719799812dea11
 cmp rax,rcx
 ja .fail8
 lea rdi,[fv]
 mov esi,4
 lea rdx,[workspace]
 call nebo_stats_median_f64
 ucomisd xmm0,[rel twofive]
 jne .fail9
 lea rdi,[fv]
 mov esi,4
 lea rdx,[workspace]
 movsd xmm0,[rel q25]
 call nebo_stats_quantile_f64
 mov rax,0x3ffc000000000000
 movq xmm1,rax
 ucomisd xmm0,xmm1
 jne .fail10
 lea rdi,[fv]
 mov esi,4
 lea rdx,[workspace]
 movsd xmm0,[rel qbad]
 call nebo_stats_quantile_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail11
 lea rdi,[fv]
 lea rsi,[fy]
 mov edx,4
 call nebo_stats_correlation_f64
 ucomisd xmm0,[rel one]
 jne .fail12
 lea rdi,[fv]
 lea rsi,[constant]
 mov edx,4
 call nebo_stats_correlation_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail13
 lea rdi,[fv]
 xor esi,esi
 call nebo_stats_mean_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail14
 lea rdi,[fv]
 mov esi,4097
 call nebo_stats_sum_f64
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail15
 xor edi,edi
 call nebo_stats_sum_f64
 cmp eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jne .fail16
 lea rdi,[fv]
 mov esi,1
 mov edx,1
 call nebo_stats_variance_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail17
 lea rdi,[fv]
 mov esi,4
 xor edx,edx
 call nebo_stats_variance_f64
 test eax,eax
 jnz .fail18
 lea rdi,[fv]
 mov esi,4
 lea rdx,[workspace]
 movsd xmm0,[rel one]
 call nebo_stats_quantile_f64
 mov rax,0x4010000000000000
 movq xmm1,rax
 ucomisd xmm0,xmm1
 jne .fail19
 lea rdi,[fv]
 mov esi,4
 xor edx,edx
 movsd xmm0,[rel q25]
 call nebo_stats_quantile_f64
 cmp eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jne .fail20
 xor edi,edi
 jmp .exit
%assign i 1
%rep 20
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
