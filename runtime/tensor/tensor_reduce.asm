; CALL-E-COMPORTAMENTOS-DE-CHAMADA-F05 fixed logical-order Tensor reductions
bits 64
default rel
%define NEBO_TENSOR_REDUCE_IMPLEMENTATION 1
%include "runtime/tensor/tensor_reduce.inc"
section .text
global nebo_tensor_reduce_all_f64
global nebo_tensor_argmax_all_f64
global nebo_tensor_all_bool
global nebo_tensor_any_bool
; contiguous Float64 desc rdi, op esi -> xmm0, eax status
nebo_tensor_reduce_all_f64:
 push r12
 push r13
 mov r12,rdi
 mov r13d,esi
 call nebo_tensor_validate
 test eax,eax
 jnz .r_ret
 cmp qword [r12+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_F64
 jne .r_contract
 test qword [r12+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_CONTIGUOUS
 jz .r_contract
 mov rcx,[r12+NEBO_TENSOR_CAPACITY]
 test rcx,rcx
 jz .r_empty
 mov rdx,[r12+NEBO_TENSOR_DATA]
 cmp r13d,NEBO_REDUCE_MIN
 je .r_seed
 cmp r13d,NEBO_REDUCE_MAX
 je .r_seed
 pxor xmm0,xmm0
 xor r8d,r8d
 jmp .r_loop
.r_seed: movsd xmm0,[rdx]
 mov r8d,1
.r_loop: cmp r8,rcx
 jae .r_done
 cmp r13d,NEBO_REDUCE_MIN
 je .r_min
 cmp r13d,NEBO_REDUCE_MAX
 je .r_max
 cmp r13d,NEBO_REDUCE_SUM
 je .r_add
 cmp r13d,NEBO_REDUCE_MEAN
 jne .r_contract
.r_add: addsd xmm0,[rdx+r8*8]
 jmp .r_next
.r_min: minsd xmm0,[rdx+r8*8]
 jmp .r_next
.r_max: maxsd xmm0,[rdx+r8*8]
.r_next: inc r8
 jmp .r_loop
.r_done:
 cmp r13d,NEBO_REDUCE_MEAN
 jne .r_ok
 cvtsi2sd xmm1,rcx
 divsd xmm0,xmm1
.r_ok: xor eax,eax
.r_ret: pop r13
 pop r12
 ret
.r_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .r_ret
.r_empty: mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 jmp .r_ret
; first maximum index in rdx
nebo_tensor_argmax_all_f64:
 push r12
 mov r12,rdi
 mov esi,NEBO_REDUCE_MAX
 call nebo_tensor_reduce_all_f64
 test eax,eax
 jnz .a_ret
 mov rcx,[r12+NEBO_TENSOR_CAPACITY]
 mov r8,[r12+NEBO_TENSOR_DATA]
 xor edx,edx
.a_loop: ucomisd xmm0,[r8+rdx*8]
 je .a_ret
 inc rdx
 cmp rdx,rcx
 jb .a_loop
.a_ret: pop r12
 ret
nebo_tensor_all_bool:
 mov dl,1
 jmp tensor_bool_reduce
nebo_tensor_any_bool:
 xor edx,edx
tensor_bool_reduce:
 push r12
 push r13
 mov r12,rdi
 mov r13b,dl
 call nebo_tensor_validate
 test eax,eax
 jnz .b_ret
 cmp qword [r12+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_BOOL
 jne .b_contract
 mov rcx,[r12+NEBO_TENSOR_CAPACITY]
 mov rsi,[r12+NEBO_TENSOR_DATA]
 mov al,r13b
 xor r8d,r8d
.b_loop: cmp r8,rcx
 jae .b_ok
 cmp byte [rsi+r8],0
 setne r9b
 test r13b,r13b
 jz .b_any
 and al,r9b
 jmp .b_next
.b_any: or al,r9b
.b_next: inc r8
 jmp .b_loop
.b_ok: movzx eax,al
 xor edx,edx
.b_ret: pop r13
 pop r12
 ret
.b_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 mov edx,eax
 jmp .b_ret
section .note.GNU-stack noalloc noexec nowrite progbits
