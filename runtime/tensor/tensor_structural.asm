; CALL-E-COMPORTAMENTOS-DE-CHAMADA-F06 bounded structural Tensor operations and rank-2 matmul.
bits 64
default rel
%define NEBO_TENSOR_STRUCTURAL_IMPLEMENTATION 1
%include "runtime/tensor/tensor_structural.inc"
%include "runtime/tensor/tensor_views.inc"
section .text
global nebo_tensor_concat0_f64
global nebo_tensor_stack0_f64
global nebo_tensor_split0_view
global nebo_tensor_pad2d_f64
global nebo_tensor_matmul2d_f64
global nebo_tensor_einsum_reject

; Validate two equal-tail contiguous Float64 tensors. a rdi b rsi.
tensor_pair_tail:
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 call nebo_tensor_validate
 test eax,eax
 jnz .pt_ret
 mov rdi,r13
 call nebo_tensor_validate
 test eax,eax
 jnz .pt_ret
 cmp qword [r12+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_F64
 jne .pt_contract
 cmp qword [r13+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_F64
 jne .pt_contract
 mov rcx,[r12+NEBO_TENSOR_RANK]
 test rcx,rcx
 jz .pt_shape
 cmp rcx,[r13+NEBO_TENSOR_RANK]
 jne .pt_shape
 test qword [r12+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_CONTIGUOUS
 jz .pt_contract
 test qword [r13+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_CONTIGUOUS
 jz .pt_contract
 mov r8,1
.pt_axis:
 cmp r8,rcx
 jae .pt_ok
 mov rax,[r12+NEBO_TENSOR_SHAPE+r8*8]
 cmp rax,[r13+NEBO_TENSOR_SHAPE+r8*8]
 jne .pt_shape
 inc r8
 jmp .pt_axis
.pt_ok: xor eax,eax
.pt_ret: pop r13
 pop r12
 ret
.pt_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .pt_ret
.pt_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .pt_ret

; outDesc,outData,a,b,storageId. Concatenates leading axis.
nebo_tensor_concat0_f64:
 push r12
 push r13
 push r14
 push r15
 sub rsp,56
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov [rsp+48],r8
 mov rdi,r14
 mov rsi,r15
 call tensor_pair_tail
 test eax,eax
 jnz .c_ret
 mov rcx,[r14+NEBO_TENSOR_RANK]
 xor r8d,r8d
.c_shape:
 cmp r8,rcx
 jae .c_axis0
 mov rax,[r14+NEBO_TENSOR_SHAPE+r8*8]
 mov [rsp+r8*8],rax
 inc r8
 jmp .c_shape
.c_axis0:
 mov rax,[r15+NEBO_TENSOR_SHAPE]
 add [rsp],rax
 jc .c_bad_shape
 mov rdi,r12
 mov rsi,r13
 mov rdx,rcx
 lea rcx,[rsp]
 mov r8d,NEBO_TENSOR_DTYPE_F64
 mov r9,[rsp+48]
 call nebo_tensor_init_owned
 test eax,eax
 jnz .c_ret
 mov rcx,[r14+NEBO_TENSOR_CAPACITY]
 mov rsi,[r14+NEBO_TENSOR_DATA]
 mov rdi,r13
 rep movsq
 mov rcx,[r15+NEBO_TENSOR_CAPACITY]
 mov rsi,[r15+NEBO_TENSOR_DATA]
 rep movsq
 xor eax,eax
.c_ret: add rsp,56
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.c_bad_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .c_ret

; outDesc,outData,a,b,storageId. Inserts leading axis of size two.
nebo_tensor_stack0_f64:
 push r12
 push r13
 push r14
 push r15
 sub rsp,56
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov [rsp+48],r8
 mov rdi,r14
 mov rsi,r15
 call tensor_pair_tail
 test eax,eax
 jnz .s_ret
 mov rcx,[r14+NEBO_TENSOR_RANK]
 cmp rcx,NEBO_TENSOR_MAX_RANK
 jae .s_shape_bad
 mov qword [rsp],2
 xor r8d,r8d
.s_shape:
 cmp r8,rcx
 jae .s_init
 mov rax,[r14+NEBO_TENSOR_SHAPE+r8*8]
 mov [rsp+8+r8*8],rax
 inc r8
 jmp .s_shape
.s_init:
 inc rcx
 mov rdi,r12
 mov rsi,r13
 mov rdx,rcx
 lea rcx,[rsp]
 mov r8d,NEBO_TENSOR_DTYPE_F64
 mov r9,[rsp+48]
 call nebo_tensor_init_owned
 test eax,eax
 jnz .s_ret
 mov rcx,[r14+NEBO_TENSOR_CAPACITY]
 mov rsi,[r14+NEBO_TENSOR_DATA]
 mov rdi,r13
 rep movsq
 mov rcx,[r15+NEBO_TENSOR_CAPACITY]
 mov rsi,[r15+NEBO_TENSOR_DATA]
 rep movsq
 xor eax,eax
.s_ret: add rsp,56
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.s_shape_bad: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .s_ret

; outA,outB,source,index. Produces readonly leading-axis views.
nebo_tensor_split0_view:
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rdi,r12
 mov rsi,r14
 xor edx,edx
 xor ecx,ecx
 mov r8,r15
 call nebo_tensor_narrow_view
 test eax,eax
 jnz .sp_ret
 mov r8,[r14+NEBO_TENSOR_SHAPE]
 sub r8,r15
 jc .sp_bounds
 mov rdi,r13
 mov rsi,r14
 xor edx,edx
 mov rcx,r15
 call nebo_tensor_narrow_view
.sp_ret: pop r15
 pop r14
 pop r13
 pop r12
 ret
.sp_bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .sp_ret

; outDesc,outData,source,pads[4]=top,bottom,left,right,storageId; fill xmm0.
nebo_tensor_pad2d_f64:
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov [rsp+24],r8
 movsd [rsp+16],xmm0
 mov rdi,r14
 call nebo_tensor_validate
 test eax,eax
 jnz .p_ret
 cmp qword [r14+NEBO_TENSOR_RANK],2
 jne .p_shape
 test r15,r15
 jz .p_arg
 mov rax,[r14+NEBO_TENSOR_SHAPE]
 add rax,[r15]
 add rax,[r15+8]
 jc .p_shape
 mov [rsp],rax
 mov rax,[r14+NEBO_TENSOR_SHAPE+8]
 add rax,[r15+16]
 add rax,[r15+24]
 jc .p_shape
 mov [rsp+8],rax
 mov rdi,r12
 mov rsi,r13
 mov edx,2
 lea rcx,[rsp]
 mov r8d,NEBO_TENSOR_DTYPE_F64
 mov r9,[rsp+24]
 call nebo_tensor_init_owned
 test eax,eax
 jnz .p_ret
 mov rcx,[r12+NEBO_TENSOR_CAPACITY]
 movsd xmm0,[rsp+16]
 xor r8d,r8d
.p_fill: cmp r8,rcx
 jae .p_copy_rows
 movsd [r13+r8*8],xmm0
 inc r8
 jmp .p_fill
.p_copy_rows:
 xor r8d,r8d
 mov r9,[r14+NEBO_TENSOR_SHAPE]
 mov r10,[r14+NEBO_TENSOR_SHAPE+8]
 mov r11,[r12+NEBO_TENSOR_SHAPE+8]
.p_row: cmp r8,r9
 jae .p_ok
 mov rax,r8
 add rax,[r15]
 imul rax,r11
 add rax,[r15+16]
 lea rdi,[r13+rax*8]
 mov rax,r8
 imul rax,r10
 mov rsi,[r14+NEBO_TENSOR_DATA]
 lea rsi,[rsi+rax*8]
 mov rcx,r10
 rep movsq
 inc r8
 jmp .p_row
.p_ok: xor eax,eax
.p_ret: add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.p_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .p_ret
.p_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .p_ret

; outDesc,outData,a,b,storageId; rank-2 scalar reference matmul.
nebo_tensor_matmul2d_f64:
 push r12
 push r13
 push r14
 push r15
 sub rsp,24
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov [rsp+16],r8
 mov rdi,r14
 call nebo_tensor_validate
 test eax,eax
 jnz .m_ret
 mov rdi,r15
 call nebo_tensor_validate
 test eax,eax
 jnz .m_ret
 cmp qword [r14+NEBO_TENSOR_RANK],2
 jne .m_shape
 cmp qword [r15+NEBO_TENSOR_RANK],2
 jne .m_shape
 mov rax,[r14+NEBO_TENSOR_SHAPE+8]
 cmp rax,[r15+NEBO_TENSOR_SHAPE]
 jne .m_shape
 mov rax,[r14+NEBO_TENSOR_SHAPE]
 mov [rsp],rax
 mov rax,[r15+NEBO_TENSOR_SHAPE+8]
 mov [rsp+8],rax
 mov rdi,r12
 mov rsi,r13
 mov edx,2
 lea rcx,[rsp]
 mov r8d,NEBO_TENSOR_DTYPE_F64
 mov r9,[rsp+16]
 call nebo_tensor_init_owned
 test eax,eax
 jnz .m_ret
 xor r8d,r8d
.m_i: cmp r8,[r12+NEBO_TENSOR_SHAPE]
 jae .m_ok
 xor r9d,r9d
.m_j: cmp r9,[r12+NEBO_TENSOR_SHAPE+8]
 jae .m_next_i
 pxor xmm0,xmm0
 xor r10d,r10d
.m_k: cmp r10,[r14+NEBO_TENSOR_SHAPE+8]
 jae .m_store
 mov rax,r8
 imul rax,[r14+NEBO_TENSOR_STRIDES]
 mov rcx,r10
 imul rcx,[r14+NEBO_TENSOR_STRIDES+8]
 add rax,rcx
 mov rdx,[r14+NEBO_TENSOR_DATA]
 movsd xmm1,[rdx+rax*8]
 mov rax,r10
 imul rax,[r15+NEBO_TENSOR_STRIDES]
 mov rcx,r9
 imul rcx,[r15+NEBO_TENSOR_STRIDES+8]
 add rax,rcx
 mov rdx,[r15+NEBO_TENSOR_DATA]
 mulsd xmm1,[rdx+rax*8]
 addsd xmm0,xmm1
 inc r10
 jmp .m_k
.m_store:
 mov rax,r8
 imul rax,[r12+NEBO_TENSOR_SHAPE+8]
 add rax,r9
 movsd [r13+rax*8],xmm0
 inc r9
 jmp .m_j
.m_next_i: inc r8
 jmp .m_i
.m_ok: xor eax,eax
.m_ret: add rsp,24
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.m_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .m_ret

nebo_tensor_einsum_reject:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
