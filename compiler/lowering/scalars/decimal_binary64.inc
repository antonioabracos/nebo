; Strict positive decimal -> correctly rounded binary64, without ambient FP
; rounding state. Input RDI bytes, RSI length; EAX status, RDX bits,
; RCX integer digit count, R8 fractional digit count.
;
; Every binary64 rounding boundary has fewer than 1100 significant decimal
; digits (the smallest is 2^-1075). Retain 1100 significant digits and a sticky
; discarded-nonzero bit. A boundary cannot lie strictly within a retained
; decimal grid cell; the sticky bit therefore changes only an exact tie.
; Decimal orders outside [-324,308] round immediately to zero/infinity after
; complete syntax validation. The exact numerator, denominator, scaling and
; division then fit 96 little-endian qword limbs, independently of source size.
%define DBC_LIMBS 96
%define DBC_N 128
%define DBC_D 896
%define DBC_A 1664
%define DBC_T 2432
%define DBC_FRAME 3288
section .text
global neboc_decimal_binary64_exact
neboc_decimal_binary64_exact:
 push rbx
 push r12
 push r13
 push r14
 push r15
 push rbp
 sub rsp,DBC_FRAME
 mov rbp,rsp
 mov r12,rdi
 mov r13,rsi
 mov rdi,rsp
 xor eax,eax
 mov ecx,DBC_FRAME/8
 rep stosq
 mov qword [rbp+16],-1
 test r12,r12
 jz .invalid
 test r13,r13
 jz .invalid
 cmp r13,NEBOC_FLOAT_LOWERING_MAX_TOTAL_DIGITS+1
 ja .limit
 xor r15d,r15d
 xor r14d,r14d
.parse:
 cmp r15,r13
 jae .parsed
 movzx r10d,byte [r12+r15]
 inc r15
 cmp r10b,'.'
 je .dot
 sub r10d,'0'
 cmp r10d,9
 ja .invalid
 cmp qword [rbp+104],0
 jne .fraction_digit
 inc qword [rbp]
 jmp .digit_counted
.fraction_digit:
 inc qword [rbp+8]
.digit_counted:
 cmp qword [rbp+16],-1
 jne .significant
 test r10d,r10d
 jz .next_digit
 mov [rbp+16],r14
.significant:
 cmp qword [rbp+24],1100
 jae .discarded
 inc qword [rbp+24]
 lea rdi,[rbp+DBC_N]
 mov rsi,r10
 call dbc_mul10_add
 jmp .next_digit
.discarded:
 test r10d,r10d
 jz .next_digit
 mov qword [rbp+32],1
.next_digit:
 inc r14
 jmp .parse
.dot:
 cmp qword [rbp+104],0
 jne .invalid
 cmp qword [rbp],0
 je .invalid
 mov qword [rbp+104],1
 jmp .parse
.parsed:
 cmp qword [rbp+8],0
 je .invalid
 cmp qword [rbp+16],-1
 je .zero
 mov rax,[rbp]
 sub rax,[rbp+16]
 dec rax
 mov [rbp+88],rax
 cmp rax,308
 jg .infinity
 cmp rax,-324
 jl .zero
 ; Exact decimal value N / 10^(retained_digits - 1 - decimal_order).
 mov r14,[rbp+24]
 dec r14
 sub r14,rax
 mov qword [rbp+DBC_D],1
.denominator:
 test r14,r14
 jz .exponent
 lea rdi,[rbp+DBC_D]
 xor esi,esi
 call dbc_mul10_add
 dec r14
 jmp .denominator
.exponent:
 lea rdi,[rbp+DBC_N]
 call dbc_bit_length
 mov [rbp+72],rax
 lea rdi,[rbp+DBC_D]
 call dbc_bit_length
 mov [rbp+80],rax
 mov rdx,[rbp+72]
 sub rdx,rax
 mov [rbp+40],rdx
 test rdx,rdx
 js .negative_exponent
 lea rdi,[rbp+DBC_T]
 lea rsi,[rbp+DBC_D]
 call dbc_shift_left
 lea rdi,[rbp+DBC_N]
 lea rsi,[rbp+DBC_T]
 call dbc_compare
 jmp .exponent_compared
.negative_exponent:
 neg rdx
 lea rdi,[rbp+DBC_A]
 lea rsi,[rbp+DBC_N]
 call dbc_shift_left
 lea rdi,[rbp+DBC_A]
 lea rsi,[rbp+DBC_D]
 call dbc_compare
.exponent_compared:
 test eax,eax
 jns .exponent_ready
 dec qword [rbp+40]
.exponent_ready:
 mov rax,[rbp+40]
 cmp rax,1023
 jg .infinity
 cmp rax,-1075
 jl .zero
 cmp rax,-1022
 jl .subnormal
 mov edx,52
 sub rdx,rax
 jmp .scale
.subnormal:
 mov qword [rbp+48],1
 mov edx,1074
.scale:
 test rdx,rdx
 js .scale_denominator
 lea rdi,[rbp+DBC_A]
 lea rsi,[rbp+DBC_N]
 call dbc_shift_left
 jmp .divide
.scale_denominator:
 neg rdx
 lea rdi,[rbp+DBC_T]
 lea rsi,[rbp+DBC_D]
 call dbc_shift_left
 lea rdi,[rbp+DBC_D]
 lea rsi,[rbp+DBC_T]
 xor edx,edx
 call dbc_shift_left
 lea rdi,[rbp+DBC_A]
 lea rsi,[rbp+DBC_N]
 xor edx,edx
 call dbc_shift_left
.divide:
 ; A/D has at most 53 quotient bits. Long division uses exact shifts and
 ; subtraction, retaining the complete remainder for nearest-even rounding.
 lea rdi,[rbp+DBC_T]
 lea rsi,[rbp+DBC_D]
 mov edx,53
 call dbc_shift_left
 mov r14d,53
.quotient_bit:
 lea rdi,[rbp+DBC_A]
 lea rsi,[rbp+DBC_T]
 call dbc_compare
 test eax,eax
 js .quotient_next
 lea rdi,[rbp+DBC_A]
 lea rsi,[rbp+DBC_T]
 call dbc_subtract
 bts qword [rbp+56],r14
.quotient_next:
 lea rdi,[rbp+DBC_T]
 call dbc_shift_right_one
 dec r14
 jns .quotient_bit
 lea rdi,[rbp+DBC_T]
 lea rsi,[rbp+DBC_A]
 mov edx,1
 call dbc_shift_left
 lea rdi,[rbp+DBC_T]
 lea rsi,[rbp+DBC_D]
 call dbc_compare
 test eax,eax
 jg .round_up
 js .rounded
 cmp qword [rbp+32],0
 jne .round_up
 test qword [rbp+56],1
 jz .rounded
.round_up:
 inc qword [rbp+56]
.rounded:
 mov rdx,[rbp+56]
 cmp qword [rbp+48],0
 jne .success
 bt rdx,53
 jnc .normal_bits
 shr rdx,1
 inc qword [rbp+40]
 cmp qword [rbp+40],1023
 jg .infinity
.normal_bits:
 btr rdx,52
 mov rax,[rbp+40]
 add rax,1023
 shl rax,52
 or rdx,rax
 jmp .success
.zero:
 xor edx,edx
 jmp .success
.infinity:
 mov rdx,0x7ff0000000000000
.success:
 mov rcx,[rbp]
 mov r8,[rbp+8]
 xor eax,eax
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .failed
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.failed:
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
.done:
 add rsp,DBC_FRAME
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Nonnegative bounded integers; private helpers preserve every callee-saved
; register. The established decimal-order limits prove no limb truncation.
dbc_mul10_add:
 mov r8,rsi
 mov r9d,10
 xor ecx,ecx
.limb:
 mov rax,[rdi+rcx*8]
 mul r9
 add rax,r8
 adc rdx,0
 mov [rdi+rcx*8],rax
 mov r8,rdx
 inc rcx
 cmp rcx,DBC_LIMBS
 jb .limb
 ret

dbc_bit_length:
 mov ecx,DBC_LIMBS
.limb:
 dec rcx
 mov rax,[rdi+rcx*8]
 test rax,rax
 jnz .found
 test rcx,rcx
 jnz .limb
 ret
.found:
 bsr rax,rax
 shl rcx,6
 lea rax,[rax+rcx+1]
 ret

; Distinct destination/source arrays, logical zero-fill left shift.
dbc_shift_left:
 mov r8,rdi
 mov r9,rsi
 mov r10,rdx
 shr r10,6
 mov r11,rdx
 and r11d,63
 xor eax,eax
 mov ecx,DBC_LIMBS
 rep stosq
 xor esi,esi
 xor edi,edi
.limb:
 lea rax,[rsi+r10]
 cmp rax,DBC_LIMBS
 jae .done
 mov rax,[r9+rsi*8]
 mov rdx,rax
 mov rcx,r11
 shld rax,rdi,cl
 mov rdi,rdx
 lea rcx,[rsi+r10]
 mov [r8+rcx*8],rax
 inc rsi
 jmp .limb
.done:
 ret

dbc_compare:
 mov ecx,DBC_LIMBS
.limb:
 dec rcx
 mov rax,[rdi+rcx*8]
 cmp rax,[rsi+rcx*8]
 jb .less
 ja .greater
 test rcx,rcx
 jnz .limb
 xor eax,eax
 ret
.less:
 mov eax,-1
 ret
.greater:
 mov eax,1
 ret

dbc_subtract:
 mov ecx,DBC_LIMBS
 clc
.limb:
 mov rax,[rsi]
 sbb [rdi],rax
 lea rdi,[rdi+8]
 lea rsi,[rsi+8]
 dec rcx
 jnz .limb
 ret

dbc_shift_right_one:
 lea rdi,[rdi+(DBC_LIMBS-1)*8]
 mov ecx,DBC_LIMBS
 clc
.limb:
 rcr qword [rdi],1
 lea rdi,[rdi-8]
 dec rcx
 jnz .limb
 ret
