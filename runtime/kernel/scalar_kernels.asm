; OPERADORES-DE-FLUXO-E-BRANCHING-PIPELINES-F02 scalar numeric kernel registry and reference oracle
bits 64
default rel
%define NEBO_SCALAR_KERNELS_IMPLEMENTATION 1
%include "runtime/kernel/scalar_kernels.inc"
section .text
global nebo_kernel_resolve_scalar
global nebo_scalar_add_f64
global nebo_scalar_dot_f64
global nebo_scalar_reduce_sum_f64
global nebo_scalar_relu_f64
global nebo_scalar_i64_to_f64
global nebo_scalar_matmul_f64
nebo_kernel_resolve_scalar:
 cmp edi,NEBO_KERNEL_ADD_F64
 je .add
 cmp edi,NEBO_KERNEL_DOT_F64
 je .dot
 cmp edi,NEBO_KERNEL_REDUCE_SUM_F64
 je .sum
 cmp edi,NEBO_KERNEL_RELU_F64
 je .relu
 cmp edi,NEBO_KERNEL_I64_TO_F64
 je .convert
 cmp edi,NEBO_KERNEL_MATMUL_F64
 je .matmul
 xor eax,eax
 ret
.add: lea rax,[rel nebo_scalar_add_f64]
 ret
.dot: lea rax,[rel nebo_scalar_dot_f64]
 ret
.sum: lea rax,[rel nebo_scalar_reduce_sum_f64]
 ret
.relu: lea rax,[rel nebo_scalar_relu_f64]
 ret
.convert: lea rax,[rel nebo_scalar_i64_to_f64]
 ret
.matmul: lea rax,[rel nebo_scalar_matmul_f64]
 ret
; out,a,b,count; exact overlap rejected.
nebo_scalar_add_f64:
 cmp rcx,NEBO_NUMERIC_MAX_ELEMENTS
 ja kernel_bounds_error
 test rcx,rcx
 jz .add_ok
 test rdi,rdi
 jz kernel_argument_error
 test rsi,rsi
 jz kernel_argument_error
 test rdx,rdx
 jz kernel_argument_error
 mov rax,rcx
 shl rax,3
 lea r8,[rdi+rax]
 lea r9,[rsi+rax]
 cmp rdi,r9
 jae .add_b_alias
 cmp rsi,r8
 jb kernel_alias_error
.add_b_alias:
 lea r9,[rdx+rax]
 cmp rdi,r9
 jae .add_begin
 cmp rdx,r8
 jb kernel_alias_error
.add_begin:
 xor r8d,r8d
.add_loop: movsd xmm0,[rsi+r8*8]
 addsd xmm0,[rdx+r8*8]
 movsd [rdi+r8*8],xmm0
 inc r8
 cmp r8,rcx
 jb .add_loop
.add_ok: xor eax,eax
 ret
; a,b,count -> xmm0, eax
nebo_scalar_dot_f64:
 cmp rdx,NEBO_NUMERIC_MAX_ELEMENTS
 ja kernel_bounds_error
 test rdx,rdx
 jz .dot_empty
 test rdi,rdi
 jz kernel_argument_error
 test rsi,rsi
 jz kernel_argument_error
 pxor xmm0,xmm0
 xor ecx,ecx
.dot_loop: movsd xmm1,[rdi+rcx*8]
 mulsd xmm1,[rsi+rcx*8]
 addsd xmm0,xmm1
 inc rcx
 cmp rcx,rdx
 jb .dot_loop
 xor eax,eax
 ret
.dot_empty: pxor xmm0,xmm0
 xor eax,eax
 ret
; values,count -> xmm0,eax
nebo_scalar_reduce_sum_f64:
 cmp rsi,NEBO_NUMERIC_MAX_ELEMENTS
 ja kernel_bounds_error
 test rsi,rsi
 jz .sum_zero
 test rdi,rdi
 jz kernel_argument_error
 pxor xmm0,xmm0
 xor ecx,ecx
.sum_loop: addsd xmm0,[rdi+rcx*8]
 inc rcx
 cmp rcx,rsi
 jb .sum_loop
 xor eax,eax
 ret
.sum_zero: pxor xmm0,xmm0
 xor eax,eax
 ret
; out,input,count
nebo_scalar_relu_f64:
 cmp rdx,NEBO_NUMERIC_MAX_ELEMENTS
 ja kernel_bounds_error
 test rdx,rdx
 jz .relu_ok
 test rdi,rdi
 jz kernel_argument_error
 test rsi,rsi
 jz kernel_argument_error
 pxor xmm1,xmm1
 xor ecx,ecx
.relu_loop: movsd xmm0,[rsi+rcx*8]
 maxsd xmm0,xmm1
 movsd [rdi+rcx*8],xmm0
 inc rcx
 cmp rcx,rdx
 jb .relu_loop
.relu_ok: xor eax,eax
 ret
; out f64,input i64,count
nebo_scalar_i64_to_f64:
 cmp rdx,NEBO_NUMERIC_MAX_ELEMENTS
 ja kernel_bounds_error
 test rdx,rdx
 jz .convert_ok
 test rdi,rdi
 jz kernel_argument_error
 test rsi,rsi
 jz kernel_argument_error
 xor ecx,ecx
.convert_loop: cvtsi2sd xmm0,qword [rsi+rcx*8]
 movsd [rdi+rcx*8],xmm0
 inc rcx
 cmp rcx,rdx
 jb .convert_loop
.convert_ok: xor eax,eax
 ret
; out,a,b,M,N,K passed rdi,rsi,rdx,rcx,r8,r9
nebo_scalar_matmul_f64:
 cmp rcx,64
 ja kernel_bounds_error
 cmp r8,64
 ja kernel_bounds_error
 cmp r9,64
 ja kernel_bounds_error
 test rcx,rcx
 jz .mm_ok
 test r8,r8
 jz .mm_ok
 test r9,r9
 jz .mm_ok
 test rdi,rdi
 jz kernel_argument_error
 test rsi,rsi
 jz kernel_argument_error
 test rdx,rdx
 jz kernel_argument_error
 push r12
 xor r10d,r10d
.mm_i: xor r11d,r11d
.mm_j: pxor xmm0,xmm0
 xor r12d,r12d
.mm_k: mov rax,r10
 imul rax,r9
 add rax,r12
 movsd xmm1,[rsi+rax*8]
 mov rax,r12
 imul rax,r8
 add rax,r11
 mulsd xmm1,[rdx+rax*8]
 addsd xmm0,xmm1
 inc r12
 cmp r12,r9
 jb .mm_k
 mov rax,r10
 imul rax,r8
 add rax,r11
 movsd [rdi+rax*8],xmm0
 inc r11
 cmp r11,r8
 jb .mm_j
 inc r10
 cmp r10,rcx
 jb .mm_i
 pop r12
.mm_ok: xor eax,eax
 ret
kernel_argument_error: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
kernel_alias_error: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 ret
kernel_bounds_error: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
