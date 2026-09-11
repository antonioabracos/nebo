; CALL-E-COMPORTAMENTOS-DE-CHAMADA-F04 bounded broadcasting and Float64 elementwise operations
bits 64
default rel
%define NEBO_TENSOR_OPS_IMPLEMENTATION 1
%include "runtime/tensor/tensor_ops.inc"
section .text
global nebo_tensor_broadcast_view
global nebo_tensor_broadcast_view_rank
global nebo_tensor_binary_f64
global nebo_tensor_binary_broadcast_f64
global nebo_tensor_add_f64
global nebo_tensor_multiply_f64
global nebo_tensor_divide_f64
global nebo_tensor_maximum_f64
global nebo_tensor_where_f64
global nebo_tensor_map_f64
global nebo_tensor_clamp_f64

 ; out, source, target shape. Preserve the existing same-rank native ABI.
nebo_tensor_broadcast_view:
 test rsi,rsi
 jz .argument
 mov rcx,rdx
 mov rdx,[rsi+NEBO_TENSOR_RANK]
 jmp nebo_tensor_broadcast_view_rank
.argument: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret

; out, source, target rank, target shape. Trailing alignment adds implicit
; singleton axes. Validate all shapes before publishing any output field.
nebo_tensor_broadcast_view_rank:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 test r12,r12
 jz .argument
 test r12,7
 jnz .argument
 cmp r12,r13
 je .alias
 mov rdi,r13
 call nebo_tensor_validate
 test eax,eax
 jnz .done
 cmp r14,NEBO_TENSOR_MAX_RANK
 ja .shape
 cmp r14,[r13+NEBO_TENSOR_RANK]
 jb .shape
 mov rbx,r14
 sub rbx,[r13+NEBO_TENSOR_RANK]
 test r14,r14
 jz .preflight
 test r15,r15
 jz .argument
.preflight:
 xor ecx,ecx
 mov r8d,1
.axis:
 cmp rcx,r14
 jae .publish
 mov rdx,[r15+rcx*8]
 cmp rdx,NEBO_TENSOR_MAX_ELEMENTS
 ja .shape
 imul r8,rdx
 jo .shape
 cmp r8,NEBO_TENSOR_MAX_ELEMENTS
 ja .shape
 mov rax,rcx
 sub rax,rbx
 js .next
 mov rax,[r13+NEBO_TENSOR_SHAPE+rax*8]
 cmp rax,rdx
 je .next
 cmp rax,1
 jne .shape
.next:
 inc rcx
 jmp .axis
.publish:
 mov [rsp],r8
 mov rdi,r12
 mov rsi,r13
 mov ecx,NEBO_TENSOR_SIZE/8
 rep movsq
 mov [r12+NEBO_TENSOR_RANK],r14
 xor ecx,ecx
.copy_axis:
 cmp rcx,r14
 jae .tail
 mov rdx,[r15+rcx*8]
 mov [r12+NEBO_TENSOR_SHAPE+rcx*8],rdx
 xor r8d,r8d
 mov rax,rcx
 sub rax,rbx
 js .store_stride
 cmp rdx,[r13+NEBO_TENSOR_SHAPE+rax*8]
 jne .store_stride
 mov r8,[r13+NEBO_TENSOR_STRIDES+rax*8]
.store_stride:
 mov [r12+NEBO_TENSOR_STRIDES+rcx*8],r8
 inc rcx
 jmp .copy_axis
.tail:
 mov rax,[rsp]
 cmp rax,[r12+NEBO_TENSOR_CAPACITY]
 cmovb rax,[r12+NEBO_TENSOR_CAPACITY]
 mov [r12+NEBO_TENSOR_CAPACITY],rax
 mov qword [r12+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_VIEW|NEBO_TENSOR_FLAG_READONLY
 xor eax,eax
 jmp .done
.argument: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .done
.alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .done
.shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

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
 mov rax,[r14+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .bin_alias
 mov rax,[r15+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .bin_alias
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
 mov rdi,r14
 call nebo_tensor_element_count
 test edx,edx
 jnz .bin_shape
 xor r10d,r10d
 mov r11,rax
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
 je .do_div
 cmp ebx,NEBO_TENSOR_OP_MAX
 je .do_max
 jmp .bin_contract
.do_div:
 divsd xmm0,xmm1
 jmp .bin_store
.do_add: addsd xmm0,xmm1
 jmp .bin_store
.do_sub: subsd xmm0,xmm1
 jmp .bin_store
.do_mul: mulsd xmm0,xmm1
 jmp .bin_store
.do_max:
 maxsd xmm0,xmm1
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
.bin_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .bin_ret

; Public method wrappers: outDesc,outData,a,b,storageId.
nebo_tensor_add_f64:
 mov r9,r8
 mov r8d,NEBO_TENSOR_OP_ADD
 jmp nebo_tensor_binary_broadcast_f64
nebo_tensor_multiply_f64:
 mov r9,r8
 mov r8d,NEBO_TENSOR_OP_MUL
 jmp nebo_tensor_binary_broadcast_f64
nebo_tensor_divide_f64:
 mov r9,r8
 mov r8d,NEBO_TENSOR_OP_DIV
 jmp nebo_tensor_binary_broadcast_f64
nebo_tensor_maximum_f64:
 mov r9,r8
 mov r8d,NEBO_TENSOR_OP_MAX
 jmp nebo_tensor_binary_broadcast_f64

; Same native binary ABI, with trailing-aligned public broadcasting. The
; existing same-shape numeric loop remains the sole arithmetic owner.
nebo_tensor_binary_broadcast_f64:
 push rbp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,440
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov rbp,r9
 mov rdi,r14
 call nebo_tensor_validate
 test eax,eax
 jnz .done
 mov rdi,r15
 call nebo_tensor_validate
 test eax,eax
 jnz .done
 mov rax,[r14+NEBO_TENSOR_RANK]
 cmp rax,[r15+NEBO_TENSOR_RANK]
 cmovb rax,[r15+NEBO_TENSOR_RANK]
 mov [rsp+48],rax
 xor ecx,ecx
 mov r11d,1
.axis:
 cmp rcx,[rsp+48]
 jae .views
 mov rax,rcx
 add rax,[r14+NEBO_TENSOR_RANK]
 sub rax,[rsp+48]
 mov r8d,1
 js .left_ready
 mov r8,[r14+NEBO_TENSOR_SHAPE+rax*8]
.left_ready:
 mov rax,rcx
 add rax,[r15+NEBO_TENSOR_RANK]
 sub rax,[rsp+48]
 mov r9d,1
 js .right_ready
 mov r9,[r15+NEBO_TENSOR_SHAPE+rax*8]
.right_ready:
 cmp r8,r9
 je .dimension
 cmp r9,1
 je .dimension
 cmp r8,1
 jne .shape
 mov r8,r9
.dimension:
 mov [rsp+rcx*8],r8
 imul r11,r8
 jo .shape
 cmp r11,NEBO_TENSOR_MAX_ELEMENTS
 ja .shape
 inc rcx
 jmp .axis
.views:
 lea rdi,[rsp+64]
 mov rsi,r14
 mov rdx,[rsp+48]
 mov rcx,rsp
 call nebo_tensor_broadcast_view_rank
 test eax,eax
 jnz .done
 lea rdi,[rsp+240]
 mov rsi,r15
 mov rdx,[rsp+48]
 mov rcx,rsp
 call nebo_tensor_broadcast_view_rank
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rsp+64]
 lea rcx,[rsp+240]
 mov r8,rbx
 mov r9,rbp
 call nebo_tensor_binary_f64
 jmp .done
.shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
.done:
 add rsp,440
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

; outDesc,outData,condition(Bool),whenTrue(Float64),whenFalse(Float64),storageId.
; Inputs must already have one equal logical shape; broadcastTo constructs the
; zero-stride readonly views used for broadcasting before selection.
nebo_tensor_where_f64:
 push rbp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov rbp,r9
 mov rdi,r14
 call nebo_tensor_validate
 test eax,eax
 jnz .where_ret
 mov rdi,r15
 call nebo_tensor_validate
 test eax,eax
 jnz .where_ret
 mov rdi,rbx
 call nebo_tensor_validate
 test eax,eax
 jnz .where_ret
 cmp qword [r14+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_BOOL
 jne .where_contract
 cmp qword [r15+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_F64
 jne .where_contract
 cmp qword [rbx+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_F64
 jne .where_contract
 mov rax,[r14+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .where_alias
 mov rax,[r15+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .where_alias
 mov rax,[rbx+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .where_alias
 mov rcx,[r15+NEBO_TENSOR_RANK]
 cmp rcx,[r14+NEBO_TENSOR_RANK]
 jne .where_shape
 cmp rcx,[rbx+NEBO_TENSOR_RANK]
 jne .where_shape
 xor r8d,r8d
.where_shapes:
 cmp r8,rcx
 jae .where_init
 mov rax,[r15+NEBO_TENSOR_SHAPE+r8*8]
 cmp rax,[r14+NEBO_TENSOR_SHAPE+r8*8]
 jne .where_shape
 cmp rax,[rbx+NEBO_TENSOR_SHAPE+r8*8]
 jne .where_shape
 inc r8
 jmp .where_shapes
.where_init:
 mov rdi,r12
 mov rsi,r13
 mov rdx,rcx
 lea rcx,[r15+NEBO_TENSOR_SHAPE]
 mov r8d,NEBO_TENSOR_DTYPE_F64
 mov r9,rbp
 call nebo_tensor_init_owned
 test eax,eax
 jnz .where_ret
 mov qword [rsp],0
.where_loop:
 mov rsi,[rsp]
 cmp rsi,[r12+NEBO_TENSOR_CAPACITY]
 jae .where_ok
 mov rdi,r14
 call tensor_linear_offset
 mov rdx,[r14+NEBO_TENSOR_DATA]
 cmp byte [rdx+rax],0
 je .where_false
 mov rdi,r15
 mov rsi,[rsp]
 call tensor_linear_offset
 mov rdx,[r15+NEBO_TENSOR_DATA]
 jmp .where_store
.where_false:
 mov rdi,rbx
 mov rsi,[rsp]
 call tensor_linear_offset
 mov rdx,[rbx+NEBO_TENSOR_DATA]
.where_store:
 movsd xmm0,[rdx+rax*8]
 mov rax,[rsp]
 movsd [r13+rax*8],xmm0
 inc qword [rsp]
 jmp .where_loop
.where_ok:
 xor eax,eax
.where_ret:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret
.where_contract:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .where_ret
.where_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .where_ret
.where_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .where_ret

; outDesc,outData,source,kernel,context,storageId. Kernel ABI is
; xmm0=value,rdi=context -> xmm0=result and must be deterministic.
nebo_tensor_map_f64:
 push rbp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,24
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov [rsp],r8
 mov [rsp+8],r9
 test r15,r15
 jz .map_arg
 mov rdi,r14
 call nebo_tensor_validate
 test eax,eax
 jnz .map_ret
 cmp qword [r14+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_F64
 jne .map_contract
 mov rax,[r14+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .map_alias
 mov rdi,r12
 mov rsi,r13
 mov rdx,[r14+NEBO_TENSOR_RANK]
 lea rcx,[r14+NEBO_TENSOR_SHAPE]
 mov r8d,NEBO_TENSOR_DTYPE_F64
 mov r9,[rsp+8]
 call nebo_tensor_init_owned
 test eax,eax
 jnz .map_ret
 xor ebx,ebx
 mov rbp,[r12+NEBO_TENSOR_CAPACITY]
.map_loop:
 cmp rbx,rbp
 jae .map_ok
 mov rdi,r14
 mov rsi,rbx
 call tensor_linear_offset
 mov rdx,[r14+NEBO_TENSOR_DATA]
 movsd xmm0,[rdx+rax*8]
 mov rdi,[rsp]
 call r15
 movsd [r13+rbx*8],xmm0
 inc rbx
 jmp .map_loop
.map_ok:
 xor eax,eax
.map_ret:
 add rsp,24
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret
.map_arg:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .map_ret
.map_contract:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .map_ret
.map_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .map_ret

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
