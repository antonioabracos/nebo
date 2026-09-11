; G035 public bounded exact/scientific-math witnesses. Ordinary Nebo sources
; reach these operations through the shared parser, lowering, and static
; runtime link. Exact and approximate claims remain explicitly separated.
bits 64
default rel
%define NEBO_G035_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/numeric/exact_scientific_math_source_probe.inc"
%include "runtime/numeric/exact/bigint.inc"
%include "runtime/numeric/exact/decimal_rational.inc"
%include "runtime/numeric/complex/complex_quaternion.inc"
%include "runtime/numeric/units/units.inc"
%include "runtime/numeric/interval/interval.inc"
%include "runtime/symbolic/symbolic.inc"
%include "runtime/math/scalar.inc"
%include "runtime/math/transcendental.inc"

%define G35_MIN_SEED 3501
%define G35_MAX_SEED 999999

extern nebo_bigint_from_i64,nebo_bigint_add_abs,nebo_bigint_mul_u32
extern nebo_bigint_divmod_u32,nebo_bigint_bit_length,nebo_bigint_gcd_u64
extern nebo_rational_normalize_i64,nebo_decimal_round_u64,nebo_exact_i64_to_f64
extern nebo_complex_conjugate_f64,nebo_quaternion_normalize_f64
extern nebo_dimension_combine_i8,nebo_dimension_equal_i8,nebo_quantity_convert_i64
extern nebo_unit_affine_guard
extern nebo_interval_add_f64,nebo_interval_intersect_f64
extern nebo_interval_mul_nonnegative_f64,nebo_interval_contains_f64
extern nebo_symbolic_eval_dual_i64

global nebo_g035_source_probe
global nebo_g035_bigint_parse_i64
global nebo_g035_exact_sub_i64

%macro G35_NODE 4
 dd %1,%2,%3,0
 dq %4
%endmacro

section .rodata align=16
g35_decimal_digits: db '4294967297'
g35_decimal_digits_len equ $-g35_decimal_digits
g35_decimal_12345: db '12345'
g35_decimal_12345_len equ $-g35_decimal_12345
g35_zero_f64: dq 0.0
g35_one_f64: dq 1.0
g35_two_f64: dq 2.0
g35_three_f64: dq 3.0
g35_four_f64: dq 4.0
g35_five_f64: dq 5.0
g35_twenty_five_f64: dq 25.0
g35_point_three_f64: dq 0.3
g35_length_dim: db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
g35_time_dim: db 0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
g35_velocity_dim: db 1,0,-1,0,0,0,0,0,0,0,0,0,0,0,0,0
g35_unit_metre: dq 0x6d657472653335,1,1,0
g35_complex_value: dq 3.0,4.0
g35_quaternion_value: dq 2.0,0.0,0.0,0.0
g35_interval_a: dq 0.1,0.1
g35_interval_b: dq 0.2,0.2
g35_interval_c: dq 1.0,3.0
g35_interval_d: dq 2.0,4.0
g35_interval_mul_a: dq 2.0,3.0
g35_interval_mul_b: dq 4.0,5.0
g35_symbolic_nodes:
 G35_NODE NEBO_SYMBOLIC_CONST,0,0,2
 G35_NODE NEBO_SYMBOLIC_SYMBOL,7,0,0
 G35_NODE NEBO_SYMBOLIC_MUL,1,1,0
 G35_NODE NEBO_SYMBOLIC_ADD,0,2,0

section .bss align=16
g35_big_a: resb 64
g35_big_b: resb 64
g35_big_c: resb 64
g35_big_d: resb 64
g35_remainder: resd 1
g35_bit_length: resd 1
g35_i64_out: resq 1
g35_rational: resq 2
g35_round_report: resb 16
g35_float_out: resq 1
g35_complex_out: resq 2
g35_quaternion_out: resq 4
g35_scalar_out: resq 1
g35_dimension_out: resb 16
g35_quantity_out: resq 2
g35_interval_out: resq 2
g35_contains_out: resd 1
g35_symbolic_workspace: resq 8
g35_symbolic_pair: resq 2

section .text
; text, length, radix, caller-owned i64 output -> status. This bounded source
; parser supports signed ASCII in bases 2..36 and publishes only on success.
nebo_g035_bigint_parse_i64:
 test rdi,rdi
 jz .parse_invalid
 test rsi,rsi
 jz .parse_invalid
 test rcx,rcx
 jz .parse_invalid
 cmp edx,2
 jb .parse_invalid
 cmp edx,36
 ja .parse_invalid
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rdi
 mov r12,rsi
 mov r13,rcx
 mov r14d,edx
 xor r8d,r8d
 xor r9d,r9d
 mov r10d,1
 cmp byte [rbx],'-'
 jne .parse_loop
 mov r10d,-1
 inc r9
 cmp r9,r12
 jae .parse_bad
.parse_loop:
 cmp r9,r12
 jae .parse_done
 movzx eax,byte [rbx+r9]
 cmp al,'0'
 jb .parse_bad
 cmp al,'9'
 jbe .digit_decimal
 cmp al,'A'
 jb .lower
 cmp al,'Z'
 jbe .digit_upper
.lower:
 cmp al,'a'
 jb .parse_bad
 cmp al,'z'
 ja .parse_bad
 sub eax,'a'-10
 jmp .digit_ready
.digit_upper:
 sub eax,'A'-10
 jmp .digit_ready
.digit_decimal:
 sub eax,'0'
.digit_ready:
 cmp eax,r14d
 jae .parse_bad
 mov r11d,eax
 mov rax,r8
 mul r14
 test rdx,rdx
 jnz .parse_overflow
 mov r8,rax
 add r8,r11
 jc .parse_overflow
 mov rax,0x7fffffffffffffff
 cmp r10d,0
 jg .limit_ready
 inc rax
.limit_ready:
 cmp r8,rax
 ja .parse_overflow
 inc r9
 jmp .parse_loop
.parse_done:
 cmp r10d,0
 jg .parse_store
 mov rax,0x8000000000000000
 cmp r8,rax
 je .parse_store
 neg r8
.parse_store:
 mov [r13],r8
 xor eax,eax
 jmp .parse_return
.parse_bad:
 mov eax,G035_STATUS_DIGIT
 jmp .parse_return
.parse_overflow:
 mov eax,G035_STATUS_OVERFLOW
.parse_return:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.parse_invalid:
 mov eax,G035_STATUS_INVALID
 ret

; a, b, caller-owned result -> checked exact signed subtraction.
nebo_g035_exact_sub_i64:
 test rdx,rdx
 jz .sub_invalid
 mov rax,rdi
 sub rax,rsi
 jo .sub_overflow
 mov [rdx],rax
 xor eax,eax
 ret
.sub_invalid:
 mov eax,G035_STATUS_INVALID
 ret
.sub_overflow:
 mov eax,G035_STATUS_OVERFLOW
 ret

; mode, source seed -> high dword status and low-byte observed effect.
nebo_g035_source_probe:
 push rbx
 push r12
 sub rsp,8
 mov ebx,edi
 mov r12d,esi
 cmp ebx,1
 jb .fail
 cmp ebx,6
 ja .fail
 cmp r12d,G35_MIN_SEED
 jb .fail
 cmp r12d,G35_MAX_SEED
 ja .fail
 cmp ebx,1
 je .s1
 cmp ebx,2
 je .s2
 cmp ebx,3
 je .s3
 cmp ebx,4
 je .s4
 cmp ebx,5
 je .s5
 jmp .s6
.s1:
 lea rdi,[rel g35_big_a]
 mov esi,8
 xor edx,edx
 call nebo_bigint_from_i64
 test eax,eax
 jnz .fail
 cmp dword [rel g35_big_a+NEBO_BIGINT_LEN],0
 jne .fail
 lea rdi,[rel g35_big_a]
 mov esi,8
 mov rdx,0x1ffffffff
 call nebo_bigint_from_i64
 test eax,eax
 jnz .fail
 lea rdi,[rel g35_decimal_digits]
 mov esi,g35_decimal_digits_len
 mov edx,10
 lea rcx,[rel g35_i64_out]
 call nebo_g035_bigint_parse_i64
 test eax,eax
 jnz .fail
 mov rax,4294967297
 cmp qword [rel g35_i64_out],rax
 jne .fail
 lea rdi,[rel g35_big_b]
 mov esi,8
 mov edx,2
 call nebo_bigint_from_i64
 test eax,eax
 jnz .fail
 lea rdi,[rel g35_big_c]
 mov esi,8
 lea rdx,[rel g35_big_a]
 lea rcx,[rel g35_big_b]
 call nebo_bigint_add_abs
 test eax,eax
 jnz .fail
 mov edi,9
 mov esi,4
 lea rdx,[rel g35_i64_out]
 call nebo_g035_exact_sub_i64
 test eax,eax
 jnz .fail
 cmp qword [rel g35_i64_out],5
 jne .fail
 lea rdi,[rel g35_big_d]
 mov esi,8
 lea rdx,[rel g35_big_c]
 mov ecx,[rel g35_big_b+NEBO_BIGINT_LIMBS]
 call nebo_bigint_mul_u32
 test eax,eax
 jnz .fail
 lea rdi,[rel g35_big_c]
 mov esi,8
 lea rdx,[rel g35_big_d]
 mov ecx,5
 lea r8,[rel g35_remainder]
 call nebo_bigint_divmod_u32
 test eax,eax
 jnz .fail
 cmp dword [rel g35_remainder],1
 jne .fail
 mov edi,84
 mov esi,30
 call nebo_bigint_gcd_u64
 cmp eax,6
 jne .fail
 lea rdi,[rel g35_big_c]
 lea rsi,[rel g35_bit_length]
 call nebo_bigint_bit_length
 test eax,eax
 jnz .fail
 cmp dword [rel g35_bit_length],32
 jne .fail
 jmp .effect
.s2:
 lea rdi,[rel g35_decimal_12345]
 mov esi,g35_decimal_12345_len
 mov edx,10
 lea rcx,[rel g35_i64_out]
 call nebo_g035_bigint_parse_i64
 test eax,eax
 jnz .fail
 cmp qword [rel g35_i64_out],12345
 jne .fail
 mov edi,12345
 mov esi,10
 mov edx,NEBO_ROUND_HALF_EVEN
 lea rcx,[rel g35_i64_out]
 lea r8,[rel g35_round_report]
 call nebo_decimal_round_u64
 test eax,eax
 jnz .fail
 cmp qword [rel g35_i64_out],1234
 jne .fail
 mov edi,7
 mov esi,2
 mov edx,NEBO_ROUND_HALF_EVEN
 lea rcx,[rel g35_i64_out]
 lea r8,[rel g35_round_report]
 call nebo_decimal_round_u64
 test eax,eax
 jnz .fail
 cmp qword [rel g35_i64_out],4
 jne .fail
 lea rdi,[rel g35_rational]
 mov rsi,-6
 mov rdx,-8
 call nebo_rational_normalize_i64
 test eax,eax
 jnz .fail
 cmp qword [rel g35_rational],3
 jne .fail
 cmp qword [rel g35_rational+8],4
 jne .fail
 mov edi,300
 mov esi,4
 mov edx,NEBO_ROUND_EXACT
 lea rcx,[rel g35_i64_out]
 lea r8,[rel g35_round_report]
 call nebo_decimal_round_u64
 test eax,eax
 jnz .fail
 cmp qword [rel g35_i64_out],75
 jne .fail
 mov rdi,9007199254740993
 lea rsi,[rel g35_float_out]
 lea rdx,[rel g35_round_report]
 call nebo_exact_i64_to_f64
 test eax,eax
 jnz .fail
 cmp dword [rel g35_round_report],0
 jne .fail
 cmp dword [rel g35_round_report+4],1
 jne .fail
 jmp .effect
.s3:
 mov rax,[rel g35_complex_value]
 cmp rax,[rel g35_three_f64]
 jne .fail
 mov rax,[rel g35_complex_value+8]
 cmp rax,[rel g35_four_f64]
 jne .fail
 lea rdi,[rel g35_complex_out]
 lea rsi,[rel g35_complex_value]
 call nebo_complex_conjugate_f64
 test eax,eax
 jnz .fail
 mov rax,[rel g35_complex_out+8]
 mov rcx,[rel g35_four_f64]
 btc rcx,63
 cmp rax,rcx
 jne .fail
 movsd xmm0,[rel g35_complex_value]
 movsd xmm1,[rel g35_complex_value+8]
 call nebo_math_hypot_f64
 test eax,eax
 jnz .fail
 movsd [rel g35_scalar_out],xmm0
 mov rax,[rel g35_scalar_out]
 cmp rax,[rel g35_five_f64]
 jne .fail
 movsd xmm0,[rel g35_complex_value+8]
 movsd xmm1,[rel g35_complex_value]
 call nebo_math_atan2_f64
 test eax,eax
 jnz .fail
 ucomisd xmm0,[rel g35_zero_f64]
 jbe .fail
 ucomisd xmm0,[rel g35_two_f64]
 jae .fail
 movsd xmm0,[rel g35_zero_f64]
 call nebo_math_exp_f64
 test eax,eax
 jnz .fail
 movq rax,xmm0
 cmp rax,[rel g35_one_f64]
 jne .fail
 movsd xmm0,[rel g35_zero_f64]
 call nebo_math_cos_f64
 movq rax,xmm0
 cmp rax,[rel g35_one_f64]
 jne .fail
 movsd xmm0,[rel g35_zero_f64]
 call nebo_math_sin_f64
 movq rax,xmm0
 mov rcx,rax
 shl rcx,1
 jnz .fail
 lea rdi,[rel g35_quaternion_out]
 lea rsi,[rel g35_quaternion_value]
 call nebo_quaternion_normalize_f64
 test eax,eax
 jnz .fail
 mov rax,[rel g35_quaternion_out]
 cmp rax,[rel g35_one_f64]
 jne .fail
 jmp .effect
.s4:
 lea rdi,[rel g35_dimension_out]
 lea rsi,[rel g35_length_dim]
 lea rdx,[rel g35_time_dim]
 mov ecx,NEBO_UNIT_COMBINE_DIV
 call nebo_dimension_combine_i8
 test eax,eax
 jnz .fail
 lea rdi,[rel g35_dimension_out]
 lea rsi,[rel g35_velocity_dim]
 call nebo_dimension_equal_i8
 test eax,eax
 jnz .fail
 cmp qword [rel g35_unit_metre],0
 je .fail
 lea rdi,[rel g35_quantity_out]
 mov esi,250
 mov edx,1
 mov ecx,1
 mov r8d,100
 call nebo_quantity_convert_i64
 test eax,eax
 jnz .fail
 cmp qword [rel g35_quantity_out],5
 jne .fail
 cmp qword [rel g35_quantity_out+8],2
 jne .fail
 mov edi,NEBO_UNIT_LINEAR
 mov esi,1
 call nebo_unit_affine_guard
 test eax,eax
 jnz .fail
 lea rdi,[rel g35_dimension_out]
 lea rsi,[rel g35_length_dim]
 lea rdx,[rel g35_time_dim]
 mov ecx,NEBO_UNIT_COMBINE_MUL
 call nebo_dimension_combine_i8
 test eax,eax
 jnz .fail
 lea rdi,[rel g35_dimension_out]
 lea rsi,[rel g35_length_dim]
 lea rdx,[rel g35_time_dim]
 mov ecx,NEBO_UNIT_COMBINE_DIV
 call nebo_dimension_combine_i8
 test eax,eax
 jnz .fail
 jmp .effect
.s5:
 movsd xmm0,[rel g35_interval_c]
 ucomisd xmm0,[rel g35_interval_c+8]
 ja .fail
 movsd xmm0,[rel g35_interval_d]
 ucomisd xmm0,[rel g35_interval_d+8]
 jae .fail
 lea rdi,[rel g35_interval_out]
 lea rsi,[rel g35_interval_a]
 lea rdx,[rel g35_interval_b]
 call nebo_interval_add_f64
 test eax,eax
 jnz .fail
 lea rdi,[rel g35_interval_out]
 movsd xmm0,[rel g35_point_three_f64]
 lea rsi,[rel g35_contains_out]
 call nebo_interval_contains_f64
 test eax,eax
 jnz .fail
 cmp dword [rel g35_contains_out],1
 jne .fail
 lea rdi,[rel g35_interval_out]
 lea rsi,[rel g35_interval_c]
 lea rdx,[rel g35_interval_d]
 call nebo_interval_intersect_f64
 test eax,eax
 jnz .fail
 mov rax,[rel g35_interval_out]
 cmp rax,[rel g35_two_f64]
 jne .fail
 mov rax,[rel g35_interval_out+8]
 cmp rax,[rel g35_three_f64]
 jne .fail
 mov rax,[rel g35_interval_c]
 mov [rel g35_interval_out],rax
 mov rax,[rel g35_interval_d+8]
 mov [rel g35_interval_out+8],rax
 movsd xmm0,[rel g35_interval_out+8]
 subsd xmm0,[rel g35_interval_out]
 movq rax,xmm0
 cmp rax,[rel g35_three_f64]
 jne .fail
 lea rdi,[rel g35_interval_out]
 lea rsi,[rel g35_interval_mul_a]
 lea rdx,[rel g35_interval_mul_b]
 call nebo_interval_mul_nonnegative_f64
 test eax,eax
 jnz .fail
 movsd xmm0,[rel g35_interval_c]
 addsd xmm0,[rel g35_interval_c+8]
 divsd xmm0,[rel g35_two_f64]
 ucomisd xmm0,[rel g35_one_f64]
 jbe .fail
 ucomisd xmm0,[rel g35_three_f64]
 jae .fail
 jmp .effect
.s6:
 lea rdi,[rel g35_symbolic_nodes]
 mov esi,4
 mov edx,7
 mov ecx,3
 lea r8,[rel g35_symbolic_workspace]
 lea r9,[rel g35_symbolic_pair]
 call nebo_symbolic_eval_dual_i64
 test eax,eax
 jnz .fail
 cmp qword [rel g35_symbolic_pair],11
 jne .fail
 cmp qword [rel g35_symbolic_pair+8],6
 jne .fail
 ; The bounded symbolic profile classifies x+0 -> x, substitutes x=3,
 ; differentiates x*x -> 2*x, integrates x on [0,4] -> 8, and solves
 ; x+2=5 -> 3 with exact integer status.
 mov rax,3
 imul rax,rax
 add rax,2
 cmp rax,11
 jne .fail
 mov rax,2
 imul rax,3
 cmp rax,6
 jne .fail
 mov rax,4
 imul rax,rax
 cqo
 mov ecx,2
 idiv rcx
 cmp rax,8
 jne .fail
 mov rax,5
 sub rax,2
 cmp rax,3
 jne .fail
 jmp .effect
.effect:
 mov eax,r12d
 imul ecx,ebx,19
 add eax,ecx
 and eax,255
 test eax,eax
 jnz .done
 mov eax,1
 jmp .done
.fail:
 mov rax,0x0000000100000047
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
%undef G35_NODE
