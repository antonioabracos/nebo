; CALL-E-COMPORTAMENTOS-DE-CHAMADA-F02 bounded Tensor construction and descriptor queries
bits 64
default rel
%define NEBO_TENSOR_CORE_IMPLEMENTATION 1
%include "runtime/tensor/tensor_core.inc"
section .text
global nebo_tensor_zeros_f64
global nebo_tensor_filled_f64
global nebo_tensor_filled_bits
global nebo_tensor_from_values_f64
global nebo_tensor_from_buffer_f64
global nebo_tensor_dtype
global nebo_tensor_device
global nebo_tensor_storage_id
global nebo_tensor_shape
global nebo_tensor_strides
global nebo_tensor_rank
global nebo_tensor_size
global nebo_tensor_axis_size
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
; desc,data,rank,shape,storage_id; fill value in xmm0.
nebo_tensor_filled_f64:
 mov r9d,NEBO_TENSOR_DTYPE_F64
; Same canonical initializer for a validated dtype; XMM0 carries exact lane
; bits. Bool uses the native one-byte layout, Int/Float use eight bytes.
nebo_tensor_filled_bits:
 push r12
 sub rsp,16
 mov r12,rsi
 movsd [rsp],xmm0
 mov r10,r9
 mov r9,r8
 mov r8,r10
 call nebo_tensor_init_owned
 test eax,eax
 jnz .fill_ret
 mov rcx,[rdi+NEBO_TENSOR_CAPACITY]
 movsd xmm0,[rsp]
 cmp qword [rdi+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_BOOL
 jne .fill_loop
 movq rax,xmm0
 test rax,rax
 setnz al
.fill_bool:
 test rcx,rcx
 jz .fill_ok
 dec rcx
 mov [r12+rcx],al
 jmp .fill_bool
.fill_loop:
 test rcx,rcx
 jz .fill_ok
 dec rcx
 movsd [r12+rcx*8],xmm0
 jmp .fill_loop
.fill_ok:
 xor eax,eax
.fill_ret:
 add rsp,16
 pop r12
 ret
; desc,data,rank,shape,source,storage_id(stack first arg)
nebo_tensor_from_values_f64:
 push r12
 push r13
 mov r12,r8
 mov r13,rsi
 test r12,r12
 jz .fv_init
 cmp r12,r13
 je .fv_alias
.fv_init:
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
.fv_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .fv_ret
; Public fromBuffer uses the same validated copy contract as fromValues.
nebo_tensor_from_buffer_f64:
 jmp nebo_tensor_from_values_f64

%macro TENSOR_QUERY_QWORD 2
nebo_tensor_%1:
 push r12
 mov r12,rdi
 call nebo_tensor_validate
 test eax,eax
 jnz %%error
 mov rax,[r12+%2]
 xor edx,edx
 pop r12
 ret
%%error:
 mov edx,eax
 xor eax,eax
 pop r12
 ret
%endmacro
TENSOR_QUERY_QWORD dtype,NEBO_TENSOR_DTYPE
TENSOR_QUERY_QWORD device,NEBO_TENSOR_DEVICE
TENSOR_QUERY_QWORD storage_id,NEBO_TENSOR_STORAGE_ID
%undef TENSOR_QUERY_QWORD

%macro TENSOR_QUERY_VECTOR 2
nebo_tensor_%1:
 push r12
 mov r12,rdi
 call nebo_tensor_validate
 test eax,eax
 jnz %%error
 lea rax,[r12+%2]
 xor edx,edx
 pop r12
 ret
%%error:
 mov edx,eax
 xor eax,eax
 pop r12
 ret
%endmacro
TENSOR_QUERY_VECTOR shape,NEBO_TENSOR_SHAPE
TENSOR_QUERY_VECTOR strides,NEBO_TENSOR_STRIDES
%undef TENSOR_QUERY_VECTOR

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
nebo_tensor_axis_size:
 jmp nebo_tensor_size
; desc -> eax bool; edx status
nebo_tensor_is_contiguous:
 push r12
 mov r12,rdi
 call nebo_tensor_validate
 test eax,eax
 jnz .cont_error
 mov rdi,r12
 call nebo_tensor_element_count
 test edx,edx
 jnz .cont_status
 test rax,rax
 jz .cont_yes
 mov rcx,[r12+NEBO_TENSOR_RANK]
 mov r8d,1
.cont_axis:
 test rcx,rcx
 jz .cont_yes
 dec rcx
 mov rax,[r12+NEBO_TENSOR_SHAPE+rcx*8]
 cmp rax,1
 jbe .cont_next
 cmp r8,[r12+NEBO_TENSOR_STRIDES+rcx*8]
 jne .cont_no
.cont_next:
 imul r8,rax
 jmp .cont_axis
.cont_yes: mov eax,1
 jmp .cont_ok
.cont_no: xor eax,eax
.cont_ok:
 xor edx,edx
 pop r12
 ret
.cont_error: mov edx,eax
.cont_status:
 xor eax,eax
 pop r12
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
