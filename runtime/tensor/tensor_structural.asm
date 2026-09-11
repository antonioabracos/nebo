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
global nebo_tensor_concatenate_f64
global nebo_tensor_stack_f64
global nebo_tensor_split_view
global nebo_tensor_pad2d_f64
global nebo_tensor_pad_f64
global nebo_tensor_matmul2d_f64
global nebo_tensor_matmul_f64
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

; Public bounded structural wrappers. The scalar reference accepts every
; in-range axis; the historical axis-zero entry points remain stable aliases.
; outDesc,outData,a,b,axis,storageId
nebo_tensor_concatenate_f64:
 jmp tensor_concatenate_general
nebo_tensor_stack_f64:
 jmp tensor_stack_general
; outA,outB,source,splitPoint,axis
nebo_tensor_split_view:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov rdi,r14
 call nebo_tensor_validate
 test eax,eax
 jnz .split_ret
 cmp rbx,[r14+NEBO_TENSOR_RANK]
 jae .split_bounds
 cmp r15,[r14+NEBO_TENSOR_SHAPE+rbx*8]
 ja .split_bounds
 mov rdi,r12
 mov rsi,r14
 mov rdx,rbx
 xor ecx,ecx
 mov r8,r15
 call nebo_tensor_narrow_view
 test eax,eax
 jnz .split_ret
 mov r8,[r14+NEBO_TENSOR_SHAPE+rbx*8]
 sub r8,r15
 mov rdi,r13
 mov rsi,r14
 mov rdx,rbx
 mov rcx,r15
 call nebo_tensor_narrow_view
.split_ret:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.split_bounds:
 mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .split_ret
nebo_tensor_pad_f64:
 jmp tensor_pad_general
nebo_tensor_matmul_f64:
 jmp tensor_matmul_general
tensor_public_axis_bounds:
 mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 ret

; General contiguous concatenate: outDesc,outData,a,b,axis,storageId.
tensor_concatenate_general:
 push rbp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,96
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov rbp,r9
 mov rdi,r14
 call nebo_tensor_validate
 test eax,eax
 jnz .gc_ret
 mov rdi,r15
 call nebo_tensor_validate
 test eax,eax
 jnz .gc_ret
 cmp qword [r14+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_F64
 jne .gc_contract
 cmp qword [r15+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_F64
 jne .gc_contract
 test qword [r14+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_CONTIGUOUS
 jz .gc_contract
 test qword [r15+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_CONTIGUOUS
 jz .gc_contract
 mov rax,[r14+NEBO_TENSOR_RANK]
 test rax,rax
 jz .gc_bounds
 cmp rax,[r15+NEBO_TENSOR_RANK]
 jne .gc_shape
 cmp rbx,rax
 jae .gc_bounds
 mov [rsp+48],rax
 xor r10d,r10d
.gc_shape_loop:
 cmp r10,[rsp+48]
 jae .gc_shape_done
 mov rax,[r14+NEBO_TENSOR_SHAPE+r10*8]
 mov [rsp+r10*8],rax
 cmp r10,rbx
 je .gc_shape_next
 cmp rax,[r15+NEBO_TENSOR_SHAPE+r10*8]
 jne .gc_shape
.gc_shape_next:
 inc r10
 jmp .gc_shape_loop
.gc_shape_done:
 mov rax,[r15+NEBO_TENSOR_SHAPE+rbx*8]
 add [rsp+rbx*8],rax
 jc .gc_shape
 mov qword [rsp+56],1
 mov r10,[rsp+48]
.gc_inner:
 dec r10
 cmp r10,rbx
 jbe .gc_blocks
 mov rax,[r14+NEBO_TENSOR_SHAPE+r10*8]
 imul rax,[rsp+56]
 mov [rsp+56],rax
 jmp .gc_inner
.gc_blocks:
 mov rax,[r14+NEBO_TENSOR_SHAPE+rbx*8]
 imul rax,[rsp+56]
 mov [rsp+64],rax
 mov rax,[r15+NEBO_TENSOR_SHAPE+rbx*8]
 imul rax,[rsp+56]
 mov [rsp+72],rax
 mov qword [rsp+80],1
 xor r10d,r10d
.gc_outer:
 cmp r10,rbx
 jae .gc_alias
 mov rax,[r14+NEBO_TENSOR_SHAPE+r10*8]
 imul rax,[rsp+80]
 mov [rsp+80],rax
 inc r10
 jmp .gc_outer
.gc_alias:
 mov rax,[r14+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .gc_alias_error
 mov rax,[r15+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .gc_alias_error
 mov rdi,r12
 mov rsi,r13
 mov rdx,[rsp+48]
 lea rcx,[rsp]
 mov r8d,NEBO_TENSOR_DTYPE_F64
 mov r9,rbp
 call nebo_tensor_init_owned
 test eax,eax
 jnz .gc_ret
 mov rdi,r13
 xor r11d,r11d
.gc_copy:
 cmp r11,[rsp+80]
 jae .gc_ok
 mov rax,r11
 imul rax,[rsp+64]
 mov rsi,[r14+NEBO_TENSOR_DATA]
 lea rsi,[rsi+rax*8]
 mov rcx,[rsp+64]
 rep movsq
 mov rax,r11
 imul rax,[rsp+72]
 mov rsi,[r15+NEBO_TENSOR_DATA]
 lea rsi,[rsi+rax*8]
 mov rcx,[rsp+72]
 rep movsq
 inc r11
 jmp .gc_copy
.gc_ok: xor eax,eax
.gc_ret:
 add rsp,96
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret
.gc_bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .gc_ret
.gc_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .gc_ret
.gc_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .gc_ret
.gc_alias_error: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .gc_ret

; General contiguous stack: outDesc,outData,a,b,axis,storageId, where axis may
; equal the source rank and the inserted extent is two.
tensor_stack_general:
 push rbp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,96
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov rbp,r9
 mov rdi,r14
 call nebo_tensor_validate
 test eax,eax
 jnz .gs_ret
 mov rdi,r15
 call nebo_tensor_validate
 test eax,eax
 jnz .gs_ret
 cmp qword [r14+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_F64
 jne .gs_contract
 cmp qword [r15+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_F64
 jne .gs_contract
 test qword [r14+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_CONTIGUOUS
 jz .gs_contract
 test qword [r15+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_CONTIGUOUS
 jz .gs_contract
 mov rax,[r14+NEBO_TENSOR_RANK]
 cmp rax,NEBO_TENSOR_MAX_RANK
 jae .gs_shape
 cmp rax,[r15+NEBO_TENSOR_RANK]
 jne .gs_shape
 cmp rbx,rax
 ja .gs_bounds
 mov [rsp+48],rax
 xor r10d,r10d
.gs_equal:
 cmp r10,[rsp+48]
 jae .gs_build
 mov rax,[r14+NEBO_TENSOR_SHAPE+r10*8]
 cmp rax,[r15+NEBO_TENSOR_SHAPE+r10*8]
 jne .gs_shape
 inc r10
 jmp .gs_equal
.gs_build:
 xor r10d,r10d
 xor r11d,r11d
.gs_build_loop:
 cmp r11,[rsp+48]
 jae .gs_insert_tail
 cmp r10,rbx
 jne .gs_copy_dim
 mov qword [rsp+r10*8],2
 inc r10
.gs_copy_dim:
 mov rax,[r14+NEBO_TENSOR_SHAPE+r11*8]
 mov [rsp+r10*8],rax
 inc r10
 inc r11
 jmp .gs_build_loop
.gs_insert_tail:
 cmp r10,rbx
 jne .gs_products
 mov qword [rsp+r10*8],2
.gs_products:
 mov qword [rsp+56],1
 mov r10,[rsp+48]
.gs_inner:
 cmp r10,rbx
 jbe .gs_outer_start
 dec r10
 mov rax,[r14+NEBO_TENSOR_SHAPE+r10*8]
 imul rax,[rsp+56]
 mov [rsp+56],rax
 jmp .gs_inner
.gs_outer_start:
 mov qword [rsp+64],1
 xor r10d,r10d
.gs_outer:
 cmp r10,rbx
 jae .gs_alias
 mov rax,[r14+NEBO_TENSOR_SHAPE+r10*8]
 imul rax,[rsp+64]
 mov [rsp+64],rax
 inc r10
 jmp .gs_outer
.gs_alias:
 mov rax,[r14+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .gs_alias_error
 mov rax,[r15+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .gs_alias_error
 mov rdi,r12
 mov rsi,r13
 mov rdx,[rsp+48]
 inc rdx
 lea rcx,[rsp]
 mov r8d,NEBO_TENSOR_DTYPE_F64
 mov r9,rbp
 call nebo_tensor_init_owned
 test eax,eax
 jnz .gs_ret
 mov rdi,r13
 xor r11d,r11d
.gs_copy:
 cmp r11,[rsp+64]
 jae .gs_ok
 mov rax,r11
 imul rax,[rsp+56]
 mov rsi,[r14+NEBO_TENSOR_DATA]
 lea rsi,[rsi+rax*8]
 mov rcx,[rsp+56]
 rep movsq
 mov rax,r11
 imul rax,[rsp+56]
 mov rsi,[r15+NEBO_TENSOR_DATA]
 lea rsi,[rsi+rax*8]
 mov rcx,[rsp+56]
 rep movsq
 inc r11
 jmp .gs_copy
.gs_ok: xor eax,eax
.gs_ret:
 add rsp,96
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret
.gs_bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .gs_ret
.gs_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .gs_ret
.gs_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .gs_ret
.gs_alias_error: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .gs_ret

; General padding for rank 0..6. Padding is [before,after] per axis.
tensor_pad_general:
 push rbp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,112
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 movsd [rsp+96],xmm0
 mov rdi,r14
 call nebo_tensor_validate
 test eax,eax
 jnz .gp_ret
 cmp qword [r14+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_F64
 jne .gp_contract
 mov rax,[r14+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .gp_alias
 mov rbx,[r14+NEBO_TENSOR_RANK]
 test rbx,rbx
 jz .gp_init
 test r15,r15
 jz .gp_argument
 xor r10d,r10d
.gp_shape:
 cmp r10,rbx
 jae .gp_init
 mov rax,[r14+NEBO_TENSOR_SHAPE+r10*8]
 mov rdx,r10
 shl rdx,4
 add rax,[r15+rdx]
 jc .gp_shape_error
 add rax,[r15+rdx+8]
 jc .gp_shape_error
 mov [rsp+r10*8],rax
 inc r10
 jmp .gp_shape
.gp_init:
 mov rdi,r12
 mov rsi,r13
 mov rdx,rbx
 lea rcx,[rsp]
 mov r8d,NEBO_TENSOR_DTYPE_F64
 mov r9,rbp
 call nebo_tensor_init_owned
 test eax,eax
 jnz .gp_ret
 mov rcx,[r12+NEBO_TENSOR_CAPACITY]
 movsd xmm0,[rsp+96]
 xor r10d,r10d
.gp_fill:
 cmp r10,rcx
 jae .gp_source_count
 movsd [r13+r10*8],xmm0
 inc r10
 jmp .gp_fill
.gp_source_count:
 mov rdi,r14
 call nebo_tensor_element_count
 test edx,edx
 jnz .gp_shape_error
 mov [rsp+88],rax
 xor r11d,r11d
.gp_copy:
 cmp r11,[rsp+88]
 jae .gp_ok
 mov rax,r11
 xor r8d,r8d
 xor r9d,r9d
 mov rcx,rbx
.gp_coord:
 test rcx,rcx
 jz .gp_store
 dec rcx
 xor edx,edx
 div qword [r14+NEBO_TENSOR_SHAPE+rcx*8]
 mov r10,rdx
 imul rdx,[r14+NEBO_TENSOR_STRIDES+rcx*8]
 add r8,rdx
 mov rsi,rcx
 shl rsi,4
 add r10,[r15+rsi]
 imul r10,[r12+NEBO_TENSOR_STRIDES+rcx*8]
 add r9,r10
 jmp .gp_coord
.gp_store:
 mov rdx,[r14+NEBO_TENSOR_DATA]
 movsd xmm0,[rdx+r8*8]
 movsd [r13+r9*8],xmm0
 inc r11
 jmp .gp_copy
.gp_ok: xor eax,eax
.gp_ret:
 add rsp,112
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret
.gp_argument: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .gp_ret
.gp_shape_error: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .gp_ret
.gp_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .gp_ret
.gp_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .gp_ret

; Rank-aware scalar matmul with NumPy-like vector promotion and broadcasting
; across trailing-aligned batch dimensions.
; outDesc,outData,a,b,storageId.
tensor_matmul_general:
 push rbp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,224
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 mov rdi,r14
 call nebo_tensor_validate
 test eax,eax
 jnz .gm_ret
 mov rdi,r15
 call nebo_tensor_validate
 test eax,eax
 jnz .gm_ret
 cmp qword [r14+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_F64
 jne .gm_contract
 cmp qword [r15+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_F64
 jne .gm_contract
 mov rax,[r14+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .gm_alias
 mov rax,[r15+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .gm_alias
 mov rax,[r14+NEBO_TENSOR_RANK]
 test rax,rax
 jz .gm_shape
 mov [rsp+112],rax
 mov rdx,[r15+NEBO_TENSOR_RANK]
 test rdx,rdx
 jz .gm_shape
 mov [rsp+120],rdx
 ; Batch ranks exclude the final matrix pair, or the promoted vector axis.
 xor r8d,r8d
 cmp rax,1
 je .gm_a_batch
 mov r8,rax
 sub r8,2
.gm_a_batch:
 mov [rsp+128],r8
 xor r9d,r9d
 cmp rdx,1
 je .gm_b_batch
 mov r9,rdx
 sub r9,2
.gm_b_batch:
 mov [rsp+136],r9
 mov rcx,r8
 cmp rcx,r9
 cmovb rcx,r9
 mov [rsp+104],rcx
 ; M, K and N after vector promotion.
 mov qword [rsp+144],1
 mov rcx,rax
 dec rcx
 mov rbx,[r14+NEBO_TENSOR_SHAPE+rcx*8]
 mov [rsp+152],rbx
 cmp rax,1
 je .gm_have_m
 dec rcx
 mov rbx,[r14+NEBO_TENSOR_SHAPE+rcx*8]
 mov [rsp+144],rbx
.gm_have_m:
 mov qword [rsp+160],1
 cmp rdx,1
 je .gm_b_vector
 mov rcx,rdx
 sub rcx,2
 mov rax,[r15+NEBO_TENSOR_SHAPE+rcx*8]
 cmp rax,[rsp+152]
 jne .gm_shape
 inc rcx
 mov rax,[r15+NEBO_TENSOR_SHAPE+rcx*8]
 mov [rsp+160],rax
 jmp .gm_build_batches
.gm_b_vector:
 mov rax,[r15+NEBO_TENSOR_SHAPE]
 cmp rax,[rsp+152]
 jne .gm_shape
.gm_build_batches:
 xor r10d,r10d
.gm_batch_axis:
 cmp r10,[rsp+104]
 jae .gm_append_matrix
 mov rax,1
 mov rcx,[rsp+104]
 sub rcx,[rsp+128]
 cmp r10,rcx
 jb .gm_a_dim_ready
 mov r11,r10
 sub r11,rcx
 mov rax,[r14+NEBO_TENSOR_SHAPE+r11*8]
.gm_a_dim_ready:
 mov rdx,1
 mov rcx,[rsp+104]
 sub rcx,[rsp+136]
 cmp r10,rcx
 jb .gm_b_dim_ready
 mov r11,r10
 sub r11,rcx
 mov rdx,[r15+NEBO_TENSOR_SHAPE+r11*8]
.gm_b_dim_ready:
 cmp rax,rdx
 je .gm_store_batch
 cmp rax,1
 je .gm_take_b
 cmp rdx,1
 jne .gm_shape
 jmp .gm_store_batch
.gm_take_b:
 mov rax,rdx
.gm_store_batch:
 mov [rsp+r10*8],rax
 inc r10
 jmp .gm_batch_axis
.gm_append_matrix:
 mov rax,[rsp+112]
 cmp rax,1
 je .gm_append_n
 mov rax,[rsp+144]
 mov [rsp+r10*8],rax
 inc r10
.gm_append_n:
 mov rax,[rsp+120]
 cmp rax,1
 je .gm_shape_ready
 mov rax,[rsp+160]
 mov [rsp+r10*8],rax
 inc r10
.gm_shape_ready:
 cmp r10,NEBO_TENSOR_MAX_RANK
 ja .gm_shape
 mov [rsp+96],r10
 mov rdi,r12
 mov rsi,r13
 mov rdx,r10
 lea rcx,[rsp]
 mov r8d,NEBO_TENSOR_DTYPE_F64
 mov r9,rbp
 call nebo_tensor_init_owned
 test eax,eax
 jnz .gm_ret
 mov rax,[r12+NEBO_TENSOR_CAPACITY]
 mov [rsp+168],rax
 ; Cache reduction-axis strides.
 mov rcx,[rsp+112]
 dec rcx
 mov rax,[r14+NEBO_TENSOR_STRIDES+rcx*8]
 mov [rsp+200],rax
 mov rcx,[rsp+120]
 cmp rcx,1
 jne .gm_b_k_matrix
 xor ecx,ecx
 jmp .gm_b_k_axis
.gm_b_k_matrix:
 sub rcx,2
.gm_b_k_axis:
 mov rax,[r15+NEBO_TENSOR_STRIDES+rcx*8]
 mov [rsp+208],rax
 xor r10d,r10d
.gm_output:
 cmp r10,[rsp+168]
 jae .gm_ok
 ; Decode the output linear index into coordinates.
 mov rax,r10
 mov rcx,[rsp+96]
.gm_decode:
 test rcx,rcx
 jz .gm_offsets
 dec rcx
 xor edx,edx
 div qword [rsp+rcx*8]
 mov [rsp+48+rcx*8],rdx
 jmp .gm_decode
.gm_offsets:
 xor r8d,r8d
 xor r9d,r9d
 ; A batch offset.
 xor r11d,r11d
.gm_a_batch_offset:
 cmp r11,[rsp+128]
 jae .gm_b_batch_start
 mov rcx,[rsp+104]
 sub rcx,[rsp+128]
 add rcx,r11
 mov rax,[rsp+48+rcx*8]
 cmp qword [r14+NEBO_TENSOR_SHAPE+r11*8],1
 jne .gm_a_batch_use
 xor eax,eax
.gm_a_batch_use:
 imul rax,[r14+NEBO_TENSOR_STRIDES+r11*8]
 add r8,rax
 inc r11
 jmp .gm_a_batch_offset
.gm_b_batch_start:
 xor r11d,r11d
.gm_b_batch_offset:
 cmp r11,[rsp+136]
 jae .gm_matrix_offsets
 mov rcx,[rsp+104]
 sub rcx,[rsp+136]
 add rcx,r11
 mov rax,[rsp+48+rcx*8]
 cmp qword [r15+NEBO_TENSOR_SHAPE+r11*8],1
 jne .gm_b_batch_use
 xor eax,eax
.gm_b_batch_use:
 imul rax,[r15+NEBO_TENSOR_STRIDES+r11*8]
 add r9,rax
 inc r11
 jmp .gm_b_batch_offset
.gm_matrix_offsets:
 mov rax,[rsp+112]
 cmp rax,1
 je .gm_b_column
 mov rcx,[rsp+104]
 mov rax,[rsp+48+rcx*8]
 mov rdx,[rsp+112]
 sub rdx,2
 imul rax,[r14+NEBO_TENSOR_STRIDES+rdx*8]
 add r8,rax
.gm_b_column:
 mov rax,[rsp+120]
 cmp rax,1
 je .gm_reduce
 mov rcx,[rsp+104]
 cmp qword [rsp+112],1
 je .gm_column_ready
 inc rcx
.gm_column_ready:
 mov rax,[rsp+48+rcx*8]
 mov rdx,[rsp+120]
 dec rdx
 imul rax,[r15+NEBO_TENSOR_STRIDES+rdx*8]
 add r9,rax
.gm_reduce:
 mov [rsp+184],r8
 mov [rsp+192],r9
 pxor xmm0,xmm0
 xor r11d,r11d
.gm_k:
 cmp r11,[rsp+152]
 jae .gm_store
 mov rax,r11
 imul rax,[rsp+200]
 add rax,[rsp+184]
 mov rdx,[r14+NEBO_TENSOR_DATA]
 movsd xmm1,[rdx+rax*8]
 mov rax,r11
 imul rax,[rsp+208]
 add rax,[rsp+192]
 mov rdx,[r15+NEBO_TENSOR_DATA]
 mulsd xmm1,[rdx+rax*8]
 addsd xmm0,xmm1
 inc r11
 jmp .gm_k
.gm_store:
 movsd [r13+r10*8],xmm0
 inc r10
 jmp .gm_output
.gm_ok: xor eax,eax
.gm_ret:
 add rsp,224
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret
.gm_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .gm_ret
.gm_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .gm_ret
.gm_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .gm_ret

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
 mov rax,[r14+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .c_alias
 mov rax,[r15+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .c_alias
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
.c_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
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
 mov rax,[r14+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .s_alias
 mov rax,[r15+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .s_alias
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
.s_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
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
 mov rax,[r14+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .p_alias
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
.p_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
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
 mov rax,[r14+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .m_alias
 mov rax,[r15+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .m_alias
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
.m_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .m_ret

nebo_tensor_einsum_reject:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
