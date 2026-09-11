bits 64
default rel
%include "runtime/tensor/tensor_core.inc"
%include "runtime/tensor/tensor_views.inc"
%include "runtime/tensor/tensor_reduce.inc"
%include "runtime/tensor/tensor_axis_reduce.inc"
section .data
shape23 dq 2,3
shape32 dq 3,2
shape03 dq 0,3
axis0 dq 0
axis1 dq 1
dup_axes dq 1,1
negative_axis dq -1
axes_swap dq 1,0
values dq 1.0,2.0,3.0,4.0,5.0,6.0
nan_values dq 1.0,0x7ff8000000000000,3.0,4.0,5.0,6.0
bool_values db 1,1,0,1,1,1
section .bss
align 8
src resb NEBO_TENSOR_SIZE
view resb NEBO_TENSOR_SIZE
result resb NEBO_TENSOR_SIZE
empty resb NEBO_TENSOR_SIZE
bool_desc resb NEBO_TENSOR_SIZE
source_data resq 6
result_data resq 6
section .text
global _start
_start:
 push qword 101
 lea rdi,[src]
 lea rsi,[source_data]
 mov edx,2
 lea rcx,[shape23]
 lea r8,[values]
 call nebo_tensor_from_values_f64
 add rsp,8
 test eax,eax
 jnz .fail1
 ; sum axis 1 => [6,15]
 push qword 201
 push qword 0
 lea rdi,[result]
 lea rsi,[result_data]
 lea rdx,[src]
 lea rcx,[axis1]
 mov r8d,1
 mov r9d,NEBO_TENSOR_REDUCE_SUM
 call nebo_tensor_reduce_axes_f64
 add rsp,16
 test eax,eax
 jnz .fail2
 cmp qword [result+NEBO_TENSOR_RANK],1
 jne .fail3
 cmp qword [result+NEBO_TENSOR_SHAPE],2
 jne .fail4
 mov rax,__float64__(6.0)
 cmp [result_data],rax
 jne .fail5
 mov rax,__float64__(15.0)
 cmp [result_data+8],rax
 jne .fail6
 ; mean axis 0 with keepDims => [1,3], [2.5,3.5,4.5]
 push qword 202
 push qword 1
 lea rdi,[result]
 lea rsi,[result_data]
 lea rdx,[src]
 lea rcx,[axis0]
 mov r8d,1
 mov r9d,NEBO_TENSOR_REDUCE_MEAN
 call nebo_tensor_reduce_axes_f64
 add rsp,16
 test eax,eax
 jnz .fail7
 cmp qword [result+NEBO_TENSOR_RANK],2
 jne .fail8
 cmp qword [result+NEBO_TENSOR_SHAPE],1
 jne .fail9
 mov rax,__float64__(2.5)
 cmp [result_data],rax
 jne .fail10
 mov rax,__float64__(4.5)
 cmp [result_data+16],rax
 jne .fail11
 ; transpose view is non-contiguous; axis 1 sum => [5,7,9].
 lea rdi,[view]
 lea rsi,[src]
 lea rdx,[axes_swap]
 call nebo_tensor_permute_view
 test eax,eax
 jnz .fail12
 push qword 203
 push qword 0
 lea rdi,[result]
 lea rsi,[result_data]
 lea rdx,[view]
 lea rcx,[axis1]
 mov r8d,1
 mov r9d,NEBO_TENSOR_REDUCE_SUM
 call nebo_tensor_reduce_axes_f64
 add rsp,16
 test eax,eax
 jnz .fail13
 mov rax,__float64__(5.0)
 cmp [result_data],rax
 jne .fail14
 mov rax,__float64__(9.0)
 cmp [result_data+16],rax
 jne .fail15
 ; duplicate and negative axes are rejected before output mutation.
 mov qword [result_data],0x11223344
 push qword 204
 push qword 0
 lea rdi,[result]
 lea rsi,[result_data]
 lea rdx,[src]
 lea rcx,[dup_axes]
 mov r8d,2
 mov r9d,NEBO_TENSOR_REDUCE_SUM
 call nebo_tensor_reduce_axes_f64
 add rsp,16
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail16
 cmp qword [result_data],0x11223344
 jne .fail17
 push qword 204
 push qword 0
 lea rdi,[result]
 lea rsi,[result_data]
 lea rdx,[src]
 lea rcx,[negative_axis]
 mov r8d,1
 mov r9d,NEBO_TENSOR_REDUCE_SUM
 call nebo_tensor_reduce_axes_f64
 add rsp,16
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail18
 ; global argMax chooses first maximum.
 lea rdi,[src]
 call nebo_tensor_argmax_all_f64
 test eax,eax
 jnz .fail19
 cmp rdx,5
 jne .fail20
 ; Bool all/any policies use identity values and exact bytes.
 lea rdi,[bool_desc]
 lea rsi,[bool_values]
 mov edx,2
 lea rcx,[shape23]
 mov r8d,NEBO_TENSOR_DTYPE_BOOL
 mov r9d,301
 call nebo_tensor_init_owned
 test eax,eax
 jnz .fail21
 lea rdi,[bool_desc]
 call nebo_tensor_all_bool
 test edx,edx
 jnz .fail22
 test eax,eax
 jnz .fail23
 lea rdi,[bool_desc]
 call nebo_tensor_any_bool
 test edx,edx
 jnz .fail24
 cmp eax,1
 jne .fail25
 ; Empty reduced dimension is rejected.
 lea rdi,[empty]
 xor esi,esi
 mov edx,2
 lea rcx,[shape03]
 mov r8d,NEBO_TENSOR_DTYPE_F64
 mov r9d,401
 call nebo_tensor_init_owned
 test eax,eax
 jnz .fail26
 push qword 402
 push qword 0
 lea rdi,[result]
 lea rsi,[result_data]
 lea rdx,[empty]
 lea rcx,[axis0]
 mov r8d,1
 mov r9d,NEBO_TENSOR_REDUCE_SUM
 call nebo_tensor_reduce_axes_f64
 add rsp,16
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail27
 ; NaN is rejected before any output write.
 push qword 102
 lea rdi,[src]
 lea rsi,[source_data]
 mov edx,2
 lea rcx,[shape23]
 lea r8,[nan_values]
 call nebo_tensor_from_values_f64
 add rsp,8
 mov qword [result_data],0x55667788
 push qword 403
 push qword 0
 lea rdi,[result]
 lea rsi,[result_data]
 lea rdx,[src]
 lea rcx,[axis1]
 mov r8d,1
 mov r9d,NEBO_TENSOR_REDUCE_MAX
 call nebo_tensor_reduce_axes_f64
 add rsp,16
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail28
 cmp qword [result_data],0x55667788
 jne .fail29
 xor edi,edi
 jmp .exit
%assign i 1
%rep 29
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
