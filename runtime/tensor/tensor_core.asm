; CALL-E-COMPORTAMENTOS-DE-CHAMADA-F02 bounded Tensor construction and descriptor queries
bits 64
default rel
%define NEBO_TENSOR_CORE_IMPLEMENTATION 1
%include "runtime/tensor/tensor_core.inc"
section .text
global nebo_tensor_zeros_f64
global nebo_tensor_from_values_f64
global nebo_tensor_rank
global nebo_tensor_size
global nebo_tensor_is_contiguous
; desc,data,rank,shape,storage_id
nebo_tensor_zeros_f64:
 push r12
 mov r12,rsi
 mov r9,r8
 mov r8d,NEBO_TENSOR_DTYPE_F64
 call nebo_tensor_init_owned
 test eax,eax
 jnz .z_ret
 mov rcx,[rdi+NEBO_TENSOR_CAPACITY]
 xor eax,eax
.z_loop: test rcx,rcx
 jz .z_ok
 dec rcx
 mov [r12+rcx*8],rax
 jmp .z_loop
.z_ok: xor eax,eax
.z_ret: pop r12
 ret
; desc,data,rank,shape,source,storage_id(stack first arg)
nebo_tensor_from_values_f64:
 push r12
 push r13
 mov r12,r8
 mov r13,rsi
 mov r9,[rsp+24]
 mov r8d,NEBO_TENSOR_DTYPE_F64
 call nebo_tensor_init_owned
 test eax,eax
 jnz .fv_ret
 mov rcx,[rdi+NEBO_TENSOR_CAPACITY]
 test rcx,rcx
 jz .fv_ok
 test r12,r12
 jz .fv_arg
 mov rdi,r13
 mov rsi,r12
 rep movsq
.fv_ok: xor eax,eax
.fv_ret: pop r13
 pop r12
 ret
.fv_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .fv_ret
nebo_tensor_rank:
 push r12
 mov r12,rdi
 call nebo_tensor_validate
 test eax,eax
 jnz .rank_ret
 mov rax,[r12+NEBO_TENSOR_RANK]
.rank_ret: pop r12
 ret
; desc,axis -> rax size; edx status
nebo_tensor_size:
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 call nebo_tensor_validate
 test eax,eax
 jnz .size_error
 cmp r13,[r12+NEBO_TENSOR_RANK]
 jae .size_bounds
 mov rax,[r12+NEBO_TENSOR_SHAPE+r13*8]
 xor edx,edx
.size_ret: pop r13
 pop r12
 ret
.size_error: mov edx,eax
 xor eax,eax
 jmp .size_ret
.size_bounds: xor eax,eax
 mov edx,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .size_ret
; desc -> eax bool; edx status
nebo_tensor_is_contiguous:
 call nebo_tensor_validate
 test eax,eax
 jnz .cont_error
 test qword [rdi+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_CONTIGUOUS
 setnz al
 movzx eax,al
 xor edx,edx
 ret
.cont_error: mov edx,eax
 xor eax,eax
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
