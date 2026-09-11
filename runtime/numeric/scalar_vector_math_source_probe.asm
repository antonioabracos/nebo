; Source-to-effect adapter for the corrected G014 public numerical surface.
; Every mode calls reusable runtime owners and checks observed values before
; returning the source-derived seed.
bits 64
default rel
%include "runtime/math/scalar.inc"
%include "runtime/math/transcendental.inc"
%include "runtime/numeric/vector.inc"
%include "runtime/numeric/statistics.inc"
%include "runtime/numeric/distributions.inc"
%include "runtime/system/random.inc"

section .rodata align=16
g14_zero: dq 0.0
g14_one: dq 1.0
g14_two: dq 2.0
g14_three: dq 3.0
g14_four: dq 4.0
g14_five: dq 5.0
g14_eight: dq 8.0
g14_nine: dq 9.0
g14_ten: dq 10.0
g14_twelve: dq 12.0
g14_thirteen: dq 13.0
g14_twenty: dq 20.0
g14_two_point_five: dq 2.5
g14_three_point_seven_five: dq 3.75
g14_negative_three_point_seven_five: dq -3.75
g14_negative_three: dq -3.0
g14_one_point_two_five: dq 1.25
g14_one_point_seven_five: dq 1.75
g14_point_two_five: dq 0.25
g14_point_three: dq 0.3
g14_point_six: dq 0.6
g14_point_eight: dq 0.8
g14_tolerance: dq 0.000000001
g14_near_one: dq 1.0000000001
g14_stddev_expected: dq 1.1180339887498948482
g14_nan: dq 0x7ff8000000000001
g14_infinity: dq 0x7ff0000000000000
g14_negative_zero: dq 0x8000000000000000
g14_stats_values: dq 1.0,2.0,3.0,4.0
g14_stats_correlated: dq 2.0,4.0,6.0,8.0
g14_stats_i64: dq 1,2,3,4
g14_weights: dq 1.0,2.0,3.0
g14_sample_input: dq 11,22,33,44,55

section .bss align=16
g14_vector_a: resq 4
g14_vector_b: resq 4
g14_vector_out: resq 4
g14_vector_scaled: resq 4
g14_float_vector: resq 2
g14_float_normalized: resq 2
g14_stats_workspace: resq 4
g14_random_a: resb NEBO_RANDOM_SIZE
g14_random_b: resb NEBO_RANDOM_SIZE
g14_shuffle_a: resq 5
g14_shuffle_b: resq 5
g14_sample_a: resq 3
g14_sample_b: resq 3
g14_sample_workspace_a: resq 5
g14_sample_workspace_b: resq 5

section .text

; xmm0 actual, xmm1 expected -> eax bool using the public tolerance owner.
g14_probe_close:
 movsd xmm2,[rel g14_tolerance]
 movsd xmm3,[rel g14_tolerance]
 call nebo_float_approx_equal_f64
 test eax,eax
 jnz .bad
 mov eax,edx
 ret
.bad:
 xor eax,eax
 ret

g14_probe_scalar:
 mov edi,17
 mov esi,29
 call nebo_math_max_i64
 cmp rax,29
 jne .bad
 mov edi,17
 mov esi,29
 call nebo_math_min_i64
 cmp rax,17
 jne .bad
 mov rdi,-37
 call nebo_math_abs_i64
 test eax,eax
 jnz .bad
 cmp rdx,37
 jne .bad
 mov edi,41
 mov esi,7
 mov edx,23
 call nebo_math_clamp_i64
 test eax,eax
 jnz .bad
 cmp rdx,23
 jne .bad
 movsd xmm0,[rel g14_nine]
 call nebo_math_sqrt_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_three]
 jne .bad
 movsd xmm0,[rel g14_two]
 movsd xmm1,[rel g14_five]
 call nebo_math_pow_f64
 test eax,eax
 jnz .bad
 mov rax,0x4040000000000000
 movq xmm1,rax
 ucomisd xmm0,xmm1
 jne .bad
 movsd xmm0,[rel g14_five]
 movsd xmm1,[rel g14_twelve]
 call nebo_math_hypot_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_thirteen]
 jne .bad
 xor eax,eax
 ret
.bad:
 mov eax,1
 ret

g14_probe_transcendental:
 movsd xmm0,[rel g14_zero]
 call nebo_math_sin_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_zero]
 jne .bad
 movsd xmm0,[rel g14_zero]
 call nebo_math_cos_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_one]
 jne .bad
 movsd xmm0,[rel g14_zero]
 call nebo_math_tan_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_zero]
 jne .bad
 movsd xmm0,[rel g14_zero]
 movsd xmm1,[rel g14_one]
 call nebo_math_atan2_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_zero]
 jne .bad
 movsd xmm0,[rel g14_zero]
 call nebo_math_exp_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_one]
 jne .bad
 movsd xmm0,[rel g14_one]
 call nebo_math_log_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_zero]
 jne .bad
 movsd xmm0,[rel g14_eight]
 call nebo_math_log2_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_three]
 jne .bad
 xor eax,eax
 ret
.bad:
 mov eax,1
 ret

g14_probe_precision:
 movsd xmm0,[rel g14_three_point_seven_five]
 call nebo_math_floor_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_three]
 jne .bad
 movsd xmm0,[rel g14_three_point_seven_five]
 call nebo_math_ceil_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_four]
 jne .bad
 movsd xmm0,[rel g14_two_point_five]
 mov edx,NEBO_ROUND_NEAREST_EVEN
 call nebo_math_round_mode_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_two]
 jne .bad
 movsd xmm0,[rel g14_three_point_seven_five]
 mov edx,NEBO_ROUND_FLOOR
 call nebo_math_round_mode_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_three]
 jne .bad
 movsd xmm0,[rel g14_three_point_seven_five]
 mov edx,NEBO_ROUND_CEIL
 call nebo_math_round_mode_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_four]
 jne .bad
 movsd xmm0,[rel g14_negative_three_point_seven_five]
 mov edx,NEBO_ROUND_TOWARD_ZERO
 call nebo_math_round_mode_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_negative_three]
 jne .bad
 movsd xmm0,[rel g14_nan]
 call nebo_float_classify_f64
 cmp eax,NEBO_FLOAT_NAN
 jne .bad
 movsd xmm0,[rel g14_infinity]
 call nebo_float_classify_f64
 cmp eax,NEBO_FLOAT_INFINITE
 jne .bad
 movsd xmm0,[rel g14_negative_zero]
 call nebo_float_classify_f64
 cmp eax,NEBO_FLOAT_FINITE | NEBO_FLOAT_NEGATIVE_ZERO
 jne .bad
 movsd xmm0,[rel g14_one]
 movsd xmm1,[rel g14_near_one]
 call g14_probe_close
 cmp eax,1
 jne .bad
 xor eax,eax
 ret
.bad:
 mov eax,1
 ret

g14_probe_vector:
 mov rdi,g14_vector_a
 mov esi,4
 mov rdx,r13
 call nebo_vector_i64_filled
 test eax,eax
 jnz .bad
 mov rdi,g14_vector_a
 mov esi,4
 mov edx,2
 call nebo_vector_i64_at
 test eax,eax
 jnz .bad
 cmp rdx,r13
 jne .bad
 mov qword [rel g14_vector_b],1
 mov qword [rel g14_vector_b+8],2
 mov qword [rel g14_vector_b+16],3
 mov qword [rel g14_vector_b+24],4
 mov rdi,g14_vector_out
 mov rsi,g14_vector_a
 mov rdx,g14_vector_b
 mov ecx,4
 call nebo_vector_i64_add
 test eax,eax
 jnz .bad
 lea rax,[r13+3]
 cmp [rel g14_vector_out+16],rax
 jne .bad
 mov rdi,g14_vector_scaled
 mov rsi,g14_vector_b
 mov edx,3
 mov ecx,4
 call nebo_vector_i64_scale
 test eax,eax
 jnz .bad
 cmp qword [rel g14_vector_scaled+24],12
 jne .bad
 mov rdi,g14_vector_a
 mov rsi,g14_vector_b
 mov edx,4
 call nebo_vector_i64_dot
 test eax,eax
 jnz .bad
 mov rax,r13
 imul rax,10
 cmp rdx,rax
 jne .bad
 movsd xmm0,[rel g14_two]
 mov rdi,g14_float_vector
 mov esi,2
 call nebo_vector_f64_filled
 test eax,eax
 jnz .bad
 mov rdi,g14_float_vector
 mov esi,2
 mov edx,1
 call nebo_vector_f64_at
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_two]
 jne .bad
 movsd xmm0,[rel g14_three]
 movsd [rel g14_float_vector],xmm0
 movsd xmm0,[rel g14_four]
 movsd [rel g14_float_vector+8],xmm0
 mov rdi,g14_float_vector
 mov esi,2
 call nebo_vector_f64_norm
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_five]
 jne .bad
 mov rdi,g14_float_normalized
 mov rsi,g14_float_vector
 mov edx,2
 call nebo_vector_f64_normalize
 test eax,eax
 jnz .bad
 movsd xmm0,[rel g14_float_normalized]
 movsd xmm1,[rel g14_point_six]
 call g14_probe_close
 cmp eax,1
 jne .bad
 mov rdi,g14_float_normalized
 mov rsi,g14_float_normalized
 mov edx,2
 call nebo_vector_f64_dot
 test eax,eax
 jnz .bad
 movsd xmm1,[rel g14_one]
 call g14_probe_close
 cmp eax,1
 jne .bad
 xor eax,eax
 ret
.bad:
 mov eax,1
 ret

g14_probe_statistics:
 mov rdi,g14_stats_i64
 mov esi,4
 call nebo_stats_sum_i64
 test eax,eax
 jnz .bad
 cmp rdx,10
 jne .bad
 mov rdi,g14_stats_values
 mov esi,4
 call nebo_stats_sum_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_ten]
 jne .bad
 mov rdi,g14_stats_values
 mov esi,4
 call nebo_stats_mean_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_two_point_five]
 jne .bad
 mov rdi,g14_stats_values
 mov esi,4
 xor edx,edx
 call nebo_stats_variance_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_one_point_two_five]
 jne .bad
 mov rdi,g14_stats_values
 mov esi,4
 xor edx,edx
 call nebo_stats_stddev_f64
 test eax,eax
 jnz .bad
 movsd xmm1,[rel g14_stddev_expected]
 call g14_probe_close
 cmp eax,1
 jne .bad
 mov rdi,g14_stats_values
 mov esi,4
 mov rdx,g14_stats_workspace
 movsd xmm0,[rel g14_point_two_five]
 call nebo_stats_quantile_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_one_point_seven_five]
 jne .bad
 mov rdi,g14_stats_values
 mov esi,4
 mov rdx,g14_stats_workspace
 call nebo_stats_median_f64
 test eax,eax
 jnz .bad
 ucomisd xmm0,[rel g14_two_point_five]
 jne .bad
 mov rdi,g14_stats_values
 mov rsi,g14_stats_correlated
 mov edx,4
 call nebo_stats_correlation_f64
 test eax,eax
 jnz .bad
 movsd xmm1,[rel g14_one]
 call g14_probe_close
 cmp eax,1
 jne .bad
 xor eax,eax
 ret
.bad:
 mov eax,1
 ret

g14_probe_random:
 mov rdi,g14_random_a
 mov rsi,r13
 call nebo_random_seed
 test eax,eax
 jnz .bad
 mov rdi,g14_random_b
 mov rsi,r13
 call nebo_random_seed
 test eax,eax
 jnz .bad
 mov rdi,g14_random_a
 movsd xmm0,[rel g14_ten]
 movsd xmm1,[rel g14_twenty]
 call nebo_distribution_uniform_f64
 test eax,eax
 jnz .bad
 movq r12,xmm0
 mov rdi,g14_random_b
 movsd xmm0,[rel g14_ten]
 movsd xmm1,[rel g14_twenty]
 call nebo_distribution_uniform_f64
 test eax,eax
 jnz .bad
 movq rax,xmm0
 cmp rax,r12
 jne .bad
 ucomisd xmm0,[rel g14_ten]
 jb .bad
 ucomisd xmm0,[rel g14_twenty]
 jae .bad
 mov rdi,g14_random_a
 movsd xmm0,[rel g14_five]
 movsd xmm1,[rel g14_two]
 call nebo_distribution_normal_params_f64
 test eax,eax
 jnz .bad
 movq r12,xmm0
 call nebo_float_classify_f64
 test eax,NEBO_FLOAT_FINITE
 jz .bad
 mov rdi,g14_random_b
 movsd xmm0,[rel g14_five]
 movsd xmm1,[rel g14_two]
 call nebo_distribution_normal_params_f64
 test eax,eax
 jnz .bad
 movq rax,xmm0
 cmp rax,r12
 jne .bad
 mov rdi,g14_random_a
 movsd xmm0,[rel g14_point_three]
 call nebo_distribution_bernoulli
 test eax,eax
 jnz .bad
 mov r12,rdx
 mov rdi,g14_random_b
 movsd xmm0,[rel g14_point_three]
 call nebo_distribution_bernoulli
 test eax,eax
 jnz .bad
 cmp rdx,r12
 jne .bad
 cmp rdx,1
 ja .bad
 mov rdi,g14_random_a
 mov rsi,g14_weights
 mov edx,3
 call nebo_distribution_categorical
 test eax,eax
 jnz .bad
 mov r12,rdx
 mov rdi,g14_random_b
 mov rsi,g14_weights
 mov edx,3
 call nebo_distribution_categorical
 test eax,eax
 jnz .bad
 cmp rdx,r12
 jne .bad
 cmp rdx,3
 jae .bad
 mov qword [rel g14_shuffle_a],1
 mov qword [rel g14_shuffle_a+8],2
 mov qword [rel g14_shuffle_a+16],3
 mov qword [rel g14_shuffle_a+24],4
 mov qword [rel g14_shuffle_a+32],5
 mov qword [rel g14_shuffle_b],1
 mov qword [rel g14_shuffle_b+8],2
 mov qword [rel g14_shuffle_b+16],3
 mov qword [rel g14_shuffle_b+24],4
 mov qword [rel g14_shuffle_b+32],5
 mov rdi,g14_random_a
 mov rsi,g14_shuffle_a
 mov edx,5
 call nebo_distribution_shuffle_i64
 test eax,eax
 jnz .bad
 mov rdi,g14_random_b
 mov rsi,g14_shuffle_b
 mov edx,5
 call nebo_distribution_shuffle_i64
 test eax,eax
 jnz .bad
 xor ecx,ecx
.compare_shuffle:
 mov rax,[g14_shuffle_a+rcx*8]
 cmp rax,[g14_shuffle_b+rcx*8]
 jne .bad
 inc rcx
 cmp rcx,5
 jb .compare_shuffle
 mov rdi,g14_random_a
 mov rsi,g14_sample_input
 mov edx,5
 mov ecx,3
 mov r8,g14_sample_a
 mov r9,g14_sample_workspace_a
 call nebo_distribution_sample_i64
 test eax,eax
 jnz .bad
 mov rdi,g14_random_b
 mov rsi,g14_sample_input
 mov edx,5
 mov ecx,3
 mov r8,g14_sample_b
 mov r9,g14_sample_workspace_b
 call nebo_distribution_sample_i64
 test eax,eax
 jnz .bad
 xor ecx,ecx
.compare_sample:
 mov rax,[g14_sample_a+rcx*8]
 cmp rax,[g14_sample_b+rcx*8]
 jne .bad
 inc rcx
 cmp rcx,3
 jb .compare_sample
 mov rax,[rel g14_sample_a]
 cmp rax,[rel g14_sample_a+8]
 je .bad
 cmp rax,[rel g14_sample_a+16]
 je .bad
 mov rax,[rel g14_sample_a+8]
 cmp rax,[rel g14_sample_a+16]
 je .bad
 xor eax,eax
 ret
.bad:
 mov eax,1
 ret

global nebo_g014_source_probe
nebo_g014_source_probe:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12d,edi
 mov r13d,esi
 test r13d,r13d
 jz .bad
 cmp r12d,1
 je .scalar
 cmp r12d,2
 je .transcendental
 cmp r12d,3
 je .precision
 cmp r12d,4
 je .vector
 cmp r12d,5
 je .statistics
 cmp r12d,6
 je .random
 jmp .bad
.scalar: call g14_probe_scalar
 jmp .checked
.transcendental: call g14_probe_transcendental
 jmp .checked
.precision: call g14_probe_precision
 jmp .checked
.vector: call g14_probe_vector
 jmp .checked
.statistics: call g14_probe_statistics
 jmp .checked
.random: call g14_probe_random
.checked:
 test eax,eax
 jnz .bad
 mov eax,r13d
 jmp .done
.bad:
 mov eax,1
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
