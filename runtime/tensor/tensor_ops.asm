; CALL-E-COMPORTAMENTOS-DE-CHAMADA-F04 bounded broadcasting and Float64 elementwise operations
bits 64
default rel
%define NEBO_TENSOR_OPS_IMPLEMENTATION 1
%include "runtime/tensor/tensor_ops.inc"
section .text
global nebo_tensor_broadcast_view
global nebo_tensor_binary_f64
global nebo_tensor_clamp_f64

; out, source, target shape (same rank)
nebo_tensor_broadcast_view:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,rsi
 call nebo_tensor_validate
 test eax,eax
 jnz .bv_ret
 test r14,r14
 jz .bv_arg
 mov rcx,[r13+NEBO_TENSOR_RANK]
 mov rax,NEBO_TENSOR_MAGIC
 mov [r12+NEBO_TENSOR_MAGIC_OFF],rax
 mov rax,[r13+NEBO_TENSOR_DTYPE]
 mov [r12+NEBO_TENSOR_DTYPE],rax
 mov qword [r12+NEBO_TENSOR_DEVICE],0
 mov [r12+NEBO_TENSOR_RANK],rcx
 xor r8d,r8d
 mov r9,1
.bv_axis:
 cmp r8,rcx
 jae .bv_tail
 mov rax,[r13+NEBO_TENSOR_SHAPE+r8*8]
 mov rdx,[r14+r8*8]
 cmp rax,rdx
 je .bv_same
 cmp rax,1
 jne .bv_shape
 mov qword [r12+NEBO_TENSOR_STRIDES+r8*8],0
 jmp .bv_store
.bv_same:
 mov rax,[r13+NEBO_TENSOR_STRIDES+r8*8]
 mov [r12+NEBO_TENSOR_STRIDES+r8*8],rax
.bv_store:
 mov [r12+NEBO_TENSOR_SHAPE+r8*8],rdx
 imul r9,rdx
 cmp r9,NEBO_TENSOR_MAX_ELEMENTS
 ja .bv_shape
 inc r8
 jmp .bv_axis
.bv_tail:
 mov rax,[r13+NEBO_TENSOR_DATA]
 mov [r12+NEBO_TENSOR_DATA],rax
 mov [r12+NEBO_TENSOR_CAPACITY],r9
 mov rax,[r13+NEBO_TENSOR_STORAGE_ID]
 mov [r12+NEBO_TENSOR_STORAGE_ID],rax
 mov rax,[r13+NEBO_TENSOR_GENERATION]
 mov [r12+NEBO_TENSOR_GENERATION],rax
 mov qword [r12+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_VIEW|NEBO_TENSOR_FLAG_READONLY
 xor eax,eax
.bv_ret: pop r14
 pop r13
 pop r12
 ret
.bv_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .bv_ret
.bv_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .bv_ret

; Compute descriptor offset for output linear index: desc rdi, linear rsi.
tensor_linear_offset:
 mov rax,rsi
 xor r8d,r8d
 mov rcx,[rdi+NEBO_TENSOR_RANK]
.lo_loop:
 test rcx,rcx
 jz .lo_done
 dec rcx
 xor edx,edx
 div qword [rdi+NEBO_TENSOR_SHAPE+rcx*8]
 imul rdx,[rdi+NEBO_TENSOR_STRIDES+rcx*8]
 add r8,rdx
 jmp .lo_loop
.lo_done: mov rax,r8
 ret

; out desc, out data, a, b, op, storage id
nebo_tensor_binary_f64:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov ebx,r8d
 mov rbp,r9
 mov rdi,r14
 call nebo_tensor_validate
 test eax,eax
 jnz .bin_ret
 mov rdi,r15
 call nebo_tensor_validate
 test eax,eax
 jnz .bin_ret
 cmp qword [r14+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_F64
 jne .bin_contract
 cmp qword [r15+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_F64
 jne .bin_contract
 mov rcx,[r14+NEBO_TENSOR_RANK]
 cmp rcx,[r15+NEBO_TENSOR_RANK]
 jne .bin_shape
 xor r8d,r8d
.bin_shapes:
 cmp r8,rcx
 jae .bin_preflight
 mov rax,[r14+NEBO_TENSOR_SHAPE+r8*8]
 cmp rax,[r15+NEBO_TENSOR_SHAPE+r8*8]
 jne .bin_shape
 inc r8
 jmp .bin_shapes
.bin_preflight:
 cmp ebx,NEBO_TENSOR_OP_DIV
 jne .bin_init
 xor r10d,r10d
 mov r11,[r14+NEBO_TENSOR_CAPACITY]
.bin_zero:
 cmp r10,r11
 jae .bin_init
 mov rdi,r15
 mov rsi,r10
 call tensor_linear_offset
 mov rdx,[r15+NEBO_TENSOR_DATA]
 pxor xmm0,xmm0
 ucomisd xmm0,[rdx+rax*8]
 je .bin_domain
 inc r10
 jmp .bin_zero
.bin_init:
 mov rdi,r12
 mov rsi,r13
 mov rdx,[r14+NEBO_TENSOR_RANK]
 lea rcx,[r14+NEBO_TENSOR_SHAPE]
 mov r8d,NEBO_TENSOR_DTYPE_F64
 mov r9,rbp
 call nebo_tensor_init_owned
 test eax,eax
 jnz .bin_ret
 xor r10d,r10d
 mov r11,[r12+NEBO_TENSOR_CAPACITY]
.bin_loop:
 cmp r10,r11
 jae .bin_ok
 mov rdi,r14
 mov rsi,r10
 call tensor_linear_offset
 mov rdx,[r14+NEBO_TENSOR_DATA]
 movsd xmm0,[rdx+rax*8]
 mov rdi,r15
 mov rsi,r10
 call tensor_linear_offset
 mov rdx,[r15+NEBO_TENSOR_DATA]
 movsd xmm1,[rdx+rax*8]
 cmp ebx,NEBO_TENSOR_OP_ADD
 je .do_add
 cmp ebx,NEBO_TENSOR_OP_SUB
 je .do_sub
 cmp ebx,NEBO_TENSOR_OP_MUL
 je .do_mul
 cmp ebx,NEBO_TENSOR_OP_DIV
 jne .bin_contract
 divsd xmm0,xmm1
 jmp .bin_store
.do_add: addsd xmm0,xmm1
 jmp .bin_store
.do_sub: subsd xmm0,xmm1
 jmp .bin_store
.do_mul: mulsd xmm0,xmm1
.bin_store: movsd [r13+r10*8],xmm0
 inc r10
 jmp .bin_loop
.bin_ok: xor eax,eax
.bin_ret: pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret
.bin_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .bin_ret
.bin_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .bin_ret
.bin_domain: mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 jmp .bin_ret

; in-place owned Float64 clamp(desc, low xmm0, high xmm1)
nebo_tensor_clamp_f64:
 ucomisd xmm0,xmm1
 ja .cl_domain
 push r12
 mov r12,rdi
 call nebo_tensor_validate
 test eax,eax
 jnz .cl_ret
 test qword [r12+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_READONLY
 jnz .cl_alias
 mov rcx,[r12+NEBO_TENSOR_CAPACITY]
 mov rdx,[r12+NEBO_TENSOR_DATA]
 xor r8d,r8d
.cl_loop: cmp r8,rcx
 jae .cl_ok
 movsd xmm2,[rdx+r8*8]
 maxsd xmm2,xmm0
 minsd xmm2,xmm1
 movsd [rdx+r8*8],xmm2
 inc r8
 jmp .cl_loop
.cl_ok: xor eax,eax
.cl_ret: pop r12
 ret
.cl_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .cl_ret
.cl_domain: mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
