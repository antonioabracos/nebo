; Typed Vector-to-statistics ABI bridge. Numeric algorithms remain in this
; canonical statistics owner. Compiler-owned workspace is 3 * 64 * 8 bytes.
; RDI op 9..15, RSI lanes, RDX policy/other lanes, RCX N, R8 dtype 0 Int/1 Float,
; R9 workspace; quantile q XMM0. Return status EAX, sum Int RDX/Float XMM0.
section .text
global nebo_vector_statistics_call
nebo_vector_statistics_call:
 cmp edi,9
 jb .argument
 cmp edi,15
 ja .argument
 test rsi,rsi
 jz .argument
 test r9,r9
 jz .argument
 cmp rcx,1
 jb .bounds
 cmp rcx,NEBO_NUMERIC_MAX_VECTOR
 ja .bounds
 cmp r8,1
 ja .argument
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 movq [rsp],xmm0
 mov [rsp+8],r8
 mov r15,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov rbx,r9
 cmp r15,9
 jne .convert
 test r8,r8
 jnz .convert
 mov rdi,r12
 mov rsi,r14
 call nebo_stats_sum_i64
 jmp .done
.convert:
 cmp r15,15
 jne .input_ready
 test r13,r13
 jz .argument_owned
.input_ready:
 cmp qword [rsp+8],0
 jne .dispatch
 ; Preserve signed Int lanes until the ordinary binary64 statistical
 ; conversion. The checked Int sum above never goes through Float.
 xor ecx,ecx
.int_lanes:
 cvtsi2sd xmm0,qword [r12+rcx*8]
 movsd [rbx+rcx*8],xmm0
 inc rcx
 cmp rcx,r14
 jb .int_lanes
 mov r12,rbx
 cmp r15,15
 jne .dispatch
 xor ecx,ecx
.int_other:
 cvtsi2sd xmm0,qword [r13+rcx*8]
 movsd [rbx+512+rcx*8],xmm0
 inc rcx
 cmp rcx,r14
 jb .int_other
 lea r13,[rbx+512]
.dispatch:
 mov rdi,r12
 mov rsi,r14
 cmp r15,9
 je .sum
 cmp r15,10
 je .mean
 cmp r15,11
 je .variance
 cmp r15,12
 je .stddev
 cmp r15,13
 je .quantile
 cmp r15,14
 je .median
 mov rsi,r13
 mov rdx,r14
 call nebo_stats_correlation_f64
 jmp .done
.sum:
 call nebo_stats_sum_f64
 jmp .done
.mean:
 call nebo_stats_mean_f64
 jmp .done
.variance:
 mov rdx,r13
 call nebo_stats_variance_f64
 jmp .done
.stddev:
 mov rdx,r13
 call nebo_stats_stddev_f64
 jmp .done
.quantile:
 lea rdx,[rbx+1024]
 movq xmm0,[rsp]
 call nebo_stats_quantile_f64
 jmp .done
.median:
 lea rdx,[rbx+1024]
 call nebo_stats_median_f64
 jmp .done
.argument_owned:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
.bounds:
 mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 ret
