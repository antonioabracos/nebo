bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/scalars/foundation_float_lowering.inc"
%include "runtime/scalars/float/foundation_float_runtime.inc"

extern neboc_foundation_float_materialize_literal
extern neboc_foundation_float_runtime_layout_get
extern neboc_foundation_float_runtime_classify
extern neboc_foundation_float_runtime_identity
extern neboc_host_process_exit

section .rodata
literal_3_5_explicit: db '3.5'
literal_3_5_explicit_len equ $-literal_3_5_explicit
literal_3_5_implicit: db '3.5'
literal_3_5_implicit_len equ $-literal_3_5_implicit
literal_42_25: db '42.25'
literal_42_25_len equ $-literal_42_25
literal_0_0: db '0.0'
literal_0_0_len equ $-literal_0_0
literal_0_125: db '0.125'
literal_0_125_len equ $-literal_0_125
invalid_trailing_dot: db '1.'
invalid_trailing_dot_len equ $-invalid_trailing_dot
invalid_leading_dot: db '.5'
invalid_leading_dot_len equ $-invalid_leading_dot
invalid_exponent: db '1e2'
invalid_exponent_len equ $-invalid_exponent
invalid_sign: db '-1.5'
invalid_sign_len equ $-invalid_sign
long_literal: db '123456789012345678901234567890.625'
long_literal_len equ $-long_literal

section .bss align=16
request: resb NEBOC_FLOAT_LOWERING_REQUEST_SIZE
out_bits_a: resq 1
out_bits_b: resq 1
out_layout: resq 1
out_class: resq 1
out_flags: resq 1

section .text
global _start
_start:
 mov rax,[rsp]
 cmp rax,2
 jne test_usage
 mov rsi,[rsp+16]
 movzx ecx,byte [rsi]
 sub ecx,'0'
 cmp ecx,1
 jb test_usage
 cmp ecx,9
 ja test_usage
 call reset_all
 cmp ecx,1
 je scenario_1
 cmp ecx,2
 je scenario_2
 cmp ecx,3
 je scenario_3
 cmp ecx,4
 je scenario_4
 cmp ecx,5
 je scenario_5
 cmp ecx,6
 je scenario_6
 cmp ecx,7
 je scenario_7
 cmp ecx,8
 je scenario_8
 jmp scenario_9

; Concrete layout and System V XMM contract.
scenario_1:
 lea rdi,[rel out_layout]
 call neboc_foundation_float_runtime_layout_get
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_layout]
 test rbx,rbx
 jz test_fail
 cmp qword [rbx+NEBOC_FLOAT_RUNTIME_LAYOUT_CONTRACT_VERSION_OFFSET],NEBOC_FLOAT_RUNTIME_CONTRACT_VERSION
 jne test_fail
 cmp qword [rbx+NEBOC_FLOAT_RUNTIME_LAYOUT_TARGET_ID_OFFSET],NEBOC_FLOAT_RUNTIME_TARGET_X86_64_SYSTEMV_ELF_LINUX
 jne test_fail
 cmp qword [rbx+NEBOC_FLOAT_RUNTIME_LAYOUT_FORMAT_OFFSET],NEBOC_FLOAT_RUNTIME_FORMAT_IEEE754_BINARY64
 jne test_fail
 cmp qword [rbx+NEBOC_FLOAT_RUNTIME_LAYOUT_BIT_WIDTH_OFFSET],64
 jne test_fail
 cmp qword [rbx+NEBOC_FLOAT_RUNTIME_LAYOUT_STORAGE_SIZE_OFFSET],8
 jne test_fail
 cmp qword [rbx+NEBOC_FLOAT_RUNTIME_LAYOUT_STORAGE_ALIGNMENT_OFFSET],8
 jne test_fail
 cmp qword [rbx+NEBOC_FLOAT_RUNTIME_LAYOUT_PARAMETER_CLASS_OFFSET],NEBOC_FLOAT_RUNTIME_REGISTER_CLASS_XMM
 jne test_fail
 cmp qword [rbx+NEBOC_FLOAT_RUNTIME_LAYOUT_RETURN_CLASS_OFFSET],NEBOC_FLOAT_RUNTIME_REGISTER_CLASS_XMM
 jne test_fail
 cmp qword [rbx+NEBOC_FLOAT_RUNTIME_LAYOUT_FLAGS_OFFSET],NEBOC_FLOAT_RUNTIME_REQUIRED_FLAGS
 jne test_fail
 cmp qword [rbx+NEBOC_FLOAT_RUNTIME_LAYOUT_ABI_VERSION_OFFSET],NEBOC_FLOAT_RUNTIME_ABI_VERSION
 jne test_fail
 cmp qword [rbx+NEBOC_FLOAT_RUNTIME_LAYOUT_STATE_OFFSET],NEBOC_FLOAT_RUNTIME_STATE_FROZEN
 jne test_fail
 jmp test_pass

; Explicit and implicit source forms materialize to identical binary64 bits.
scenario_2:
 lea rdi,[rel literal_3_5_explicit]
 mov esi,literal_3_5_explicit_len
 lea rdx,[rel out_bits_a]
 call setup_request
 call expect_materialize_ok
 mov rax,0x400c000000000000
 cmp [rel out_bits_a],rax
 jne test_fail
 call reset_request_only
 lea rdi,[rel literal_3_5_implicit]
 mov esi,literal_3_5_implicit_len
 lea rdx,[rel out_bits_b]
 call setup_request
 call expect_materialize_ok
 mov rax,[rel out_bits_a]
 cmp rax,[rel out_bits_b]
 jne test_fail
 jmp test_pass

scenario_3:
 lea rdi,[rel literal_42_25]
 mov esi,literal_42_25_len
 lea rdx,[rel out_bits_a]
 call setup_request
 call expect_materialize_ok
 mov rax,0x4045200000000000
 cmp [rel out_bits_a],rax
 jne test_fail
 cmp qword [rel request+NEBOC_FLOAT_LOWERING_REQUEST_INTEGER_DIGITS_OFFSET],2
 jne test_fail
 cmp qword [rel request+NEBOC_FLOAT_LOWERING_REQUEST_FRACTION_DIGITS_OFFSET],2
 jne test_fail
 jmp test_pass

scenario_4:
 lea rdi,[rel literal_0_0]
 mov esi,literal_0_0_len
 lea rdx,[rel out_bits_a]
 call setup_request
 call expect_materialize_ok
 cmp qword [rel out_bits_a],0
 jne test_fail
 xor edi,edi
 lea rsi,[rel out_class]
 lea rdx,[rel out_flags]
 call neboc_foundation_float_runtime_classify
 test eax,eax
 jnz test_fail
 cmp qword [rel out_class],NEBOC_FLOAT_RUNTIME_CLASS_ZERO
 jne test_fail
 cmp qword [rel out_flags],0
 jne test_fail
 jmp test_pass

scenario_5:
 lea rdi,[rel literal_0_125]
 mov esi,literal_0_125_len
 lea rdx,[rel out_bits_a]
 call setup_request
 call expect_materialize_ok
 mov rax,[rel out_bits_a]
 mov rdx,0x3fc0000000000000
 cmp rax,rdx
 jne test_fail
 movq xmm0,rax
 call neboc_foundation_float_runtime_identity
 movq rdx,xmm0
 cmp rdx,rax
 jne test_fail
 jmp test_pass

scenario_6:
 ; Positive infinity.
 mov rdi,0x7ff0000000000000
 lea rsi,[rel out_class]
 lea rdx,[rel out_flags]
 call neboc_foundation_float_runtime_classify
 test eax,eax
 jnz test_fail
 cmp qword [rel out_class],NEBOC_FLOAT_RUNTIME_CLASS_INFINITY
 jne test_fail
 cmp qword [rel out_flags],0
 jne test_fail
 ; Quiet NaN.
 mov rdi,0x7ff8000000000001
 lea rsi,[rel out_class]
 lea rdx,[rel out_flags]
 call neboc_foundation_float_runtime_classify
 test eax,eax
 jnz test_fail
 cmp qword [rel out_class],NEBOC_FLOAT_RUNTIME_CLASS_NAN
 jne test_fail
 cmp qword [rel out_flags],NEBOC_FLOAT_RUNTIME_VALUE_FLAG_QUIET_NAN
 jne test_fail
 ; Signalling NaN.
 mov rdi,0x7ff0000000000001
 lea rsi,[rel out_class]
 lea rdx,[rel out_flags]
 call neboc_foundation_float_runtime_classify
 test eax,eax
 jnz test_fail
 cmp qword [rel out_class],NEBOC_FLOAT_RUNTIME_CLASS_NAN
 jne test_fail
 cmp qword [rel out_flags],NEBOC_FLOAT_RUNTIME_VALUE_FLAG_SIGNALING_NAN
 jne test_fail
 ; Smallest positive subnormal.
 mov edi,1
 lea rsi,[rel out_class]
 lea rdx,[rel out_flags]
 call neboc_foundation_float_runtime_classify
 test eax,eax
 jnz test_fail
 cmp qword [rel out_class],NEBOC_FLOAT_RUNTIME_CLASS_SUBNORMAL
 jne test_fail
 cmp qword [rel out_flags],0
 jne test_fail
 ; Negative zero preserves sign.
 mov rdi,0x8000000000000000
 lea rsi,[rel out_class]
 lea rdx,[rel out_flags]
 call neboc_foundation_float_runtime_classify
 test eax,eax
 jnz test_fail
 cmp qword [rel out_class],NEBOC_FLOAT_RUNTIME_CLASS_ZERO
 jne test_fail
 cmp qword [rel out_flags],NEBOC_FLOAT_RUNTIME_VALUE_FLAG_NEGATIVE
 jne test_fail
 jmp test_pass

scenario_7:
 lea rdi,[rel invalid_trailing_dot]
 mov esi,invalid_trailing_dot_len
 call expect_invalid_shape
 lea rdi,[rel invalid_leading_dot]
 mov esi,invalid_leading_dot_len
 call expect_invalid_shape
 lea rdi,[rel invalid_exponent]
 mov esi,invalid_exponent_len
 call expect_invalid_shape
 lea rdi,[rel invalid_sign]
 mov esi,invalid_sign_len
 call expect_invalid_shape
 jmp test_pass

scenario_8:
 ; PF005 supersedes the PF004 fifteen-digit prototype bound. Long strict
 ; decimals now materialize deterministically under the source-size bound.
 lea rdi,[rel long_literal]
 mov esi,long_literal_len
 lea rdx,[rel out_bits_a]
 call setup_request
 call expect_materialize_ok
 cmp qword [rel request+NEBOC_FLOAT_LOWERING_REQUEST_INTEGER_DIGITS_OFFSET],30
 jne test_fail
 cmp qword [rel request+NEBOC_FLOAT_LOWERING_REQUEST_FRACTION_DIGITS_OFFSET],3
 jne test_fail
 cmp qword [rel out_bits_a],0
 je test_fail
 jmp test_pass

scenario_9:
 xor edi,edi
 call neboc_foundation_float_materialize_literal
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne test_fail
 lea rdi,[rel request]
 mov qword [rel out_bits_a],-1
 lea rax,[rel out_bits_a]
 mov [rel request+NEBOC_FLOAT_LOWERING_REQUEST_OUT_BITS_OFFSET],rax
 call neboc_foundation_float_materialize_literal
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne test_fail
 cmp qword [rel request+NEBOC_FLOAT_LOWERING_REQUEST_ERROR_CODE_OFFSET],NEBOC_FLOAT_LOWERING_ERROR_BAD_REQUEST
 jne test_fail
 cmp qword [rel out_bits_a],0
 jne test_fail
 call reset_request_only
 lea rdi,[rel literal_3_5_explicit]
 mov esi,literal_3_5_explicit_len
 lea rdx,[rel out_bits_a]
 call setup_request
 call expect_materialize_ok
 mov rax,[rel out_bits_a]
 mov [rel out_bits_b],rax
 call reset_request_only
 lea rdi,[rel literal_3_5_explicit]
 mov esi,literal_3_5_explicit_len
 lea rdx,[rel out_bits_a]
 call setup_request
 call expect_materialize_ok
 mov rax,[rel out_bits_b]
 cmp rax,[rel out_bits_a]
 jne test_fail
 xor edi,edi
 xor esi,esi
 xor edx,edx
 call neboc_foundation_float_runtime_classify
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne test_fail
 jmp test_pass

; rdi=source, rsi=length, rdx=out_bits
setup_request:
 mov [rel request+NEBOC_FLOAT_LOWERING_REQUEST_SOURCE_OFFSET],rdi
 mov [rel request+NEBOC_FLOAT_LOWERING_REQUEST_LENGTH_OFFSET],rsi
 mov [rel request+NEBOC_FLOAT_LOWERING_REQUEST_OUT_BITS_OFFSET],rdx
 ret

expect_materialize_ok:
 sub rsp,8
 lea rdi,[rel request]
 call neboc_foundation_float_materialize_literal
 add rsp,8
 test eax,eax
 jnz test_fail
 cmp qword [rel request+NEBOC_FLOAT_LOWERING_REQUEST_ERROR_CODE_OFFSET],NEBOC_FLOAT_LOWERING_ERROR_NONE
 jne test_fail
 cmp qword [rel request+NEBOC_FLOAT_LOWERING_REQUEST_FLAGS_OFFSET],NEBOC_FLOAT_LOWERING_REQUIRED_FLAGS
 jne test_fail
 ret

; rdi=source, rsi=length
expect_invalid_shape:
 sub rsp,8
 lea rdx,[rel out_bits_a]
 call setup_request
 lea rdi,[rel request]
 call neboc_foundation_float_materialize_literal
 add rsp,8
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request+NEBOC_FLOAT_LOWERING_REQUEST_ERROR_CODE_OFFSET],NEBOC_FLOAT_LOWERING_ERROR_INVALID_SHAPE
 jne test_fail
 cmp qword [rel out_bits_a],0
 jne test_fail
 call reset_request_only
 ret

reset_request_only:
 lea rdi,[rel request]
 mov ecx,NEBOC_FLOAT_LOWERING_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 ret

reset_all:
 push rcx
 call reset_request_only
 mov qword [rel out_bits_a],0
 mov qword [rel out_bits_b],0
 mov qword [rel out_layout],0
 mov qword [rel out_class],0
 mov qword [rel out_flags],0
 pop rcx
 ret

test_pass:
 xor edi,edi
 call neboc_host_process_exit
test_fail:
 mov edi,1
 call neboc_host_process_exit
test_usage:
 mov edi,64
 call neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
