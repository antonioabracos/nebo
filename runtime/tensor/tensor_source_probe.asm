; G016 public-source runtime oracle. Every source mode reaches the concrete
; Tensor owner functions and validates an observed descriptor or value.
bits 64
default rel
%include "runtime/tensor/tensor_core.inc"
%include "runtime/tensor/tensor_views.inc"
%include "runtime/tensor/tensor_ops.inc"
%include "runtime/tensor/tensor_reduce.inc"
%include "runtime/tensor/tensor_axis_reduce.inc"
%include "runtime/tensor/tensor_structural.inc"

section .rodata align=8
g16_shape23: dq 2,3
g16_shape13: dq 1,3
g16_shape22: dq 2,2
g16_shape2: dq 2
g16_shape222: dq 2,2,2
g16_shape122: dq 1,2,2
g16_shape32: dq 3,2
g16_shape_bad_rank: dq 1,1,1,1,1,1,1
g16_axes10: dq 1,0
g16_axis0: dq 0
g16_axis1: dq 1
g16_coord12: dq 1,2
g16_coord11: dq 1,1
g16_pads: dq 1,1,1,1
g16_pads3: dq 0,0,0,0,1,0
g16_values_a: dq 1.0,2.0,3.0,4.0,5.0,6.0
g16_values_b: dq 10.0,20.0,30.0
g16_values_22a: dq 1.0,2.0,3.0,4.0
g16_values_22b: dq 5.0,6.0,7.0,8.0
g16_values_batch_a: dq 1.0,2.0,3.0,4.0,2.0,0.0,1.0,3.0
g16_values_batch_b: dq 5.0,6.0,7.0,8.0
g16_values_zero_div: dq 1.0,0.0,1.0,1.0,1.0,1.0
g16_bool_values: db 1,1,0,1,1,1
align 8
g16_fill: dq 7.0
g16_zero: dq 0.0
g16_map_delta: dq 1.0

section .bss align=16
g16_seed: resq 1
g16_a: resb NEBO_TENSOR_SIZE
g16_b: resb NEBO_TENSOR_SIZE
g16_view: resb NEBO_TENSOR_SIZE
g16_view2: resb NEBO_TENSOR_SIZE
g16_out: resb NEBO_TENSOR_SIZE
g16_out2: resb NEBO_TENSOR_SIZE
g16_out3: resb NEBO_TENSOR_SIZE
g16_bool: resb NEBO_TENSOR_SIZE
g16_bool_out: resb NEBO_TENSOR_SIZE
g16_data_a: resq 64
g16_data_b: resq 64
g16_data_out: resq 128
g16_data_out2: resq 128
g16_data_out3: resq 128
g16_bool_data: resb 64
g16_bool_out_data: resb 64

section .text
global nebo_g016_source_probe
global nebo_g016_negative_probe

g16_map_add:
 addsd xmm0,[rel g16_map_delta]
 ret

; Initialize canonical [2,3] Float64 source in g16_a.
g16_init_a23:
 push qword 1601
 lea rdi,[rel g16_a]
 lea rsi,[rel g16_data_a]
 mov edx,2
 lea rcx,[rel g16_shape23]
 lea r8,[rel g16_values_a]
 call nebo_tensor_from_buffer_f64
 add rsp,8
 ret

g16_mode_1:
 lea rdi,[rel g16_a]
 lea rsi,[rel g16_data_a]
 mov edx,2
 lea rcx,[rel g16_shape23]
 mov r8d,1611
 call nebo_tensor_zeros_f64
 test eax,eax
 jnz .fail
 cmp qword [rel g16_data_a+40],0
 jne .fail
 movsd xmm0,[rel g16_fill]
 lea rdi,[rel g16_b]
 lea rsi,[rel g16_data_b]
 mov edx,2
 lea rcx,[rel g16_shape23]
 mov r8d,1612
 call nebo_tensor_filled_f64
 test eax,eax
 jnz .fail
 mov rax,[rel g16_fill]
 cmp [rel g16_data_b+40],rax
 jne .fail
 push qword 1613
 lea rdi,[rel g16_out]
 lea rsi,[rel g16_data_out]
 mov edx,2
 lea rcx,[rel g16_shape23]
 lea r8,[rel g16_values_a]
 call nebo_tensor_from_buffer_f64
 add rsp,8
 test eax,eax
 jnz .fail
 lea rdi,[rel g16_out]
 call nebo_tensor_dtype
 test edx,edx
 jnz .fail
 cmp eax,NEBO_TENSOR_DTYPE_F64
 jne .fail
 lea rdi,[rel g16_out]
 call nebo_tensor_device
 test edx,edx
 jnz .fail
 test eax,eax
 jnz .fail
 lea rdi,[rel g16_out]
 call nebo_tensor_storage_id
 test edx,edx
 jnz .fail
 cmp eax,1613
 jne .fail
 xor eax,eax
 ret
.fail: mov eax,1
 ret

g16_mode_2:
 call g16_init_a23
 test eax,eax
 jnz .fail
 lea rdi,[rel g16_a]
 call nebo_tensor_shape
 test edx,edx
 jnz .fail
 cmp qword [rax],2
 jne .fail
 cmp qword [rax+8],3
 jne .fail
 lea rdi,[rel g16_a]
 call nebo_tensor_rank
 cmp eax,2
 jne .fail
 lea rdi,[rel g16_a]
 call nebo_tensor_element_count
 test edx,edx
 jnz .fail
 cmp eax,6
 jne .fail
 lea rdi,[rel g16_a]
 call nebo_tensor_strides
 test edx,edx
 jnz .fail
 cmp qword [rax],3
 jne .fail
 cmp qword [rax+8],1
 jne .fail
 lea rdi,[rel g16_a]
 call nebo_tensor_is_contiguous
 test edx,edx
 jnz .fail
 cmp eax,1
 jne .fail
 lea rdi,[rel g16_a]
 mov esi,1
 call nebo_tensor_axis_size
 test edx,edx
 jnz .fail
 cmp eax,3
 jne .fail
 xor eax,eax
 ret
.fail: mov eax,2
 ret

g16_mode_3:
 call g16_init_a23
 test eax,eax
 jnz .fail
 lea rdi,[rel g16_a]
 lea rsi,[rel g16_coord12]
 call nebo_tensor_at_f64
 test eax,eax
 jnz .fail
 movq rax,xmm0
 cmp rax,[rel g16_values_a+40]
 jne .fail
 lea rdi,[rel g16_view]
 lea rsi,[rel g16_a]
 mov edx,1
 xor ecx,ecx
 mov r8d,2
 mov r9d,2
 call nebo_tensor_slice_view
 test eax,eax
 jnz .fail
 lea rdi,[rel g16_view]
 lea rsi,[rel g16_coord11]
 call nebo_tensor_at_f64
 test eax,eax
 jnz .fail
 movq rax,xmm0
 cmp rax,[rel g16_values_a+40]
 jne .fail
 lea rdi,[rel g16_view2]
 lea rsi,[rel g16_a]
 xor edx,edx
 mov ecx,1
 call nebo_tensor_select_view
 test eax,eax
 jnz .fail
 cmp qword [rel g16_view2+NEBO_TENSOR_RANK],1
 jne .fail
 lea rdi,[rel g16_view2]
 lea rsi,[rel g16_a]
 call nebo_tensor_validate_view_owner
 test eax,eax
 jnz .fail
 mov rax,0x123456789abcdef0
 mov [rel g16_data_out+24],rax
 lea rdi,[rel g16_out]
 lea rsi,[rel g16_data_out]
 lea rdx,[rel g16_view2]
 mov ecx,1629
 call nebo_tensor_contiguous_f64
 test eax,eax
 jnz .fail
 cmp qword [rel g16_out+NEBO_TENSOR_CAPACITY],3
 jne .fail
 mov rax,[rel g16_values_a+24]
 cmp [rel g16_data_out],rax
 jne .fail
 mov rax,[rel g16_values_a+40]
 cmp [rel g16_data_out+16],rax
 jne .fail
 mov rax,0x123456789abcdef0
 cmp [rel g16_data_out+24],rax
 jne .fail
 lea rdi,[rel g16_view]
 lea rsi,[rel g16_a]
 mov edx,1
 mov ecx,1
 mov r8d,2
 call nebo_tensor_narrow_view
 test eax,eax
 jnz .fail
 lea rdi,[rel g16_view]
 lea rsi,[rel g16_a]
 lea rdx,[rel g16_axes10]
 call nebo_tensor_permute_view
 test eax,eax
 jnz .fail
 lea rdi,[rel g16_view2]
 lea rsi,[rel g16_a]
 mov edx,2
 lea rcx,[rel g16_shape32]
 call nebo_tensor_reshape_view
 test eax,eax
 jnz .fail
 lea rdi,[rel g16_out]
 lea rsi,[rel g16_data_out]
 lea rdx,[rel g16_view]
 mov ecx,1630
 call nebo_tensor_contiguous_f64
 test eax,eax
 jnz .fail
 mov rax,[rel g16_values_a+24]
 cmp [rel g16_data_out+8],rax
 jne .fail
 mov rax,[rel g16_view+NEBO_TENSOR_STORAGE_ID]
 cmp rax,[rel g16_a+NEBO_TENSOR_STORAGE_ID]
 jne .fail
 xor eax,eax
 ret
.fail: mov eax,3
 ret

g16_mode_4:
 call g16_init_a23
 test eax,eax
 jnz .fail
 push qword 1641
 lea rdi,[rel g16_b]
 lea rsi,[rel g16_data_b]
 mov edx,2
 lea rcx,[rel g16_shape13]
 lea r8,[rel g16_values_b]
 call nebo_tensor_from_buffer_f64
 add rsp,8
 test eax,eax
 jnz .fail
 lea rdi,[rel g16_view]
 lea rsi,[rel g16_b]
 lea rdx,[rel g16_shape23]
 call nebo_tensor_broadcast_view
 test eax,eax
 jnz .fail
 lea rdi,[rel g16_out]
 lea rsi,[rel g16_data_out]
 lea rdx,[rel g16_a]
 lea rcx,[rel g16_view]
 mov r8d,1642
 call nebo_tensor_add_f64
 test eax,eax
 jnz .fail
 mov rax,__float64__(36.0)
 cmp [rel g16_data_out+40],rax
 jne .fail
 lea rdi,[rel g16_out2]
 lea rsi,[rel g16_data_out2]
 lea rdx,[rel g16_a]
 lea rcx,[rel g16_view]
 mov r8d,1643
 call nebo_tensor_multiply_f64
 test eax,eax
 jnz .fail
 lea rdi,[rel g16_out3]
 lea rsi,[rel g16_data_out3]
 lea rdx,[rel g16_out2]
 lea rcx,[rel g16_view]
 mov r8d,1644
 call nebo_tensor_divide_f64
 test eax,eax
 jnz .fail
 mov rax,[rel g16_values_a+40]
 cmp [rel g16_data_out3+40],rax
 jne .fail
 lea rdi,[rel g16_out2]
 lea rsi,[rel g16_data_out2]
 lea rdx,[rel g16_a]
 lea rcx,[rel g16_view]
 mov r8d,1645
 call nebo_tensor_maximum_f64
 test eax,eax
 jnz .fail
 mov rax,__float64__(30.0)
 cmp [rel g16_data_out2+16],rax
 jne .fail
 lea rdi,[rel g16_bool]
 lea rsi,[rel g16_bool_data]
 mov edx,2
 lea rcx,[rel g16_shape23]
 mov r8d,NEBO_TENSOR_DTYPE_BOOL
 mov r9d,1646
 call nebo_tensor_init_owned
 test eax,eax
 jnz .fail
 mov eax,dword [rel g16_bool_values]
 mov [rel g16_bool_data],eax
 mov ax,word [rel g16_bool_values+4]
 mov [rel g16_bool_data+4],ax
 lea rdi,[rel g16_out3]
 lea rsi,[rel g16_data_out3]
 lea rdx,[rel g16_bool]
 lea rcx,[rel g16_a]
 lea r8,[rel g16_view]
 mov r9d,1647
 call nebo_tensor_where_f64
 test eax,eax
 jnz .fail
 mov rax,__float64__(30.0)
 cmp [rel g16_data_out3+16],rax
 jne .fail
 lea rdi,[rel g16_out]
 lea rsi,[rel g16_data_out]
 lea rdx,[rel g16_a]
 lea rcx,[rel g16_map_add]
 xor r8d,r8d
 mov r9d,1648
 call nebo_tensor_map_f64
 test eax,eax
 jnz .fail
 mov rax,__float64__(7.0)
 cmp [rel g16_data_out+40],rax
 jne .fail
 xor eax,eax
 ret
.fail: mov eax,4
 ret

g16_mode_5:
 call g16_init_a23
 test eax,eax
 jnz .fail
 push qword 1650
 push qword 0
 lea rdi,[rel g16_out]
 lea rsi,[rel g16_data_out]
 lea rdx,[rel g16_a]
 lea rcx,[rel g16_axis1]
 mov r8d,1
 mov r9d,NEBO_TENSOR_REDUCE_SUM
 call nebo_tensor_reduce_axes_f64
 add rsp,16
 test eax,eax
 jnz .fail
 mov rax,__float64__(6.0)
 cmp [rel g16_data_out],rax
 jne .fail
 push qword 1651
 push qword 1
 lea rdi,[rel g16_out]
 lea rsi,[rel g16_data_out]
 lea rdx,[rel g16_a]
 lea rcx,[rel g16_axis0]
 mov r8d,1
 mov r9d,NEBO_TENSOR_REDUCE_MEAN
 call nebo_tensor_reduce_axes_f64
 add rsp,16
 test eax,eax
 jnz .fail
 mov rax,__float64__(2.5)
 cmp [rel g16_data_out],rax
 jne .fail
 push qword 1652
 push qword 0
 lea rdi,[rel g16_out]
 lea rsi,[rel g16_data_out]
 lea rdx,[rel g16_a]
 lea rcx,[rel g16_axis1]
 mov r8d,1
 mov r9d,NEBO_TENSOR_REDUCE_MIN
 call nebo_tensor_reduce_axes_f64
 add rsp,16
 test eax,eax
 jnz .fail
 mov rax,__float64__(1.0)
 cmp [rel g16_data_out],rax
 jne .fail
 push qword 1653
 push qword 0
 lea rdi,[rel g16_out]
 lea rsi,[rel g16_data_out]
 lea rdx,[rel g16_a]
 lea rcx,[rel g16_axis0]
 mov r8d,1
 mov r9d,NEBO_TENSOR_REDUCE_MAX
 call nebo_tensor_reduce_axes_f64
 add rsp,16
 test eax,eax
 jnz .fail
 mov rax,__float64__(4.0)
 cmp [rel g16_data_out],rax
 jne .fail
 lea rdi,[rel g16_out]
 lea rsi,[rel g16_data_out]
 lea rdx,[rel g16_a]
 mov ecx,1
 mov r8d,1654
 call nebo_tensor_argmax_axis_f64
 test eax,eax
 jnz .fail
 cmp qword [rel g16_data_out],2
 jne .fail
 ; A permuted readonly view has owner capacity six but logical shape [3,2].
 ; Axis reduction must iterate its logical element count through strides.
 lea rdi,[rel g16_view]
 lea rsi,[rel g16_a]
 lea rdx,[rel g16_axes10]
 call nebo_tensor_permute_view
 test eax,eax
 jnz .fail
 lea rdi,[rel g16_out]
 lea rsi,[rel g16_data_out]
 lea rdx,[rel g16_view]
 mov ecx,1
 mov r8d,1655
 call nebo_tensor_argmax_axis_f64
 test eax,eax
 jnz .fail
 cmp qword [rel g16_data_out],1
 jne .fail
 lea rdi,[rel g16_bool]
 lea rsi,[rel g16_bool_data]
 mov edx,2
 lea rcx,[rel g16_shape23]
 mov r8d,NEBO_TENSOR_DTYPE_BOOL
 mov r9d,1656
 call nebo_tensor_init_owned
 test eax,eax
 jnz .fail
 mov eax,dword [rel g16_bool_values]
 mov [rel g16_bool_data],eax
 mov ax,word [rel g16_bool_values+4]
 mov [rel g16_bool_data+4],ax
 lea rdi,[rel g16_bool_out]
 lea rsi,[rel g16_bool_out_data]
 lea rdx,[rel g16_bool]
 mov ecx,1
 mov r8d,1657
 call nebo_tensor_all_axis_bool
 test eax,eax
 jnz .fail
 cmp byte [rel g16_bool_out_data],0
 jne .fail
 lea rdi,[rel g16_bool_out]
 lea rsi,[rel g16_bool_out_data]
 lea rdx,[rel g16_bool]
 mov ecx,1
 mov r8d,1658
 call nebo_tensor_any_axis_bool
 test eax,eax
 jnz .fail
 cmp byte [rel g16_bool_out_data],1
 jne .fail
 xor eax,eax
 ret
.fail: mov eax,5
 ret

g16_mode_6:
 push qword 1661
 lea rdi,[rel g16_a]
 lea rsi,[rel g16_data_a]
 mov edx,2
 lea rcx,[rel g16_shape22]
 lea r8,[rel g16_values_22a]
 call nebo_tensor_from_buffer_f64
 add rsp,8
 test eax,eax
 jnz .fail1
 push qword 1662
 lea rdi,[rel g16_b]
 lea rsi,[rel g16_data_b]
 mov edx,2
 lea rcx,[rel g16_shape22]
 lea r8,[rel g16_values_22b]
 call nebo_tensor_from_buffer_f64
 add rsp,8
 test eax,eax
 jnz .fail2
 lea rdi,[rel g16_out]
 lea rsi,[rel g16_data_out]
 lea rdx,[rel g16_a]
 lea rcx,[rel g16_b]
 mov r8d,1
 mov r9d,1663
 call nebo_tensor_concatenate_f64
 test eax,eax
 jnz .fail3
 cmp qword [rel g16_out+NEBO_TENSOR_SHAPE+8],4
 jne .fail4
 lea rdi,[rel g16_out2]
 lea rsi,[rel g16_data_out2]
 lea rdx,[rel g16_a]
 lea rcx,[rel g16_b]
 mov r8d,1
 mov r9d,1664
 call nebo_tensor_stack_f64
 test eax,eax
 jnz .fail5
 cmp qword [rel g16_out2+NEBO_TENSOR_RANK],3
 jne .fail6
 lea rdi,[rel g16_view]
 lea rsi,[rel g16_view2]
 lea rdx,[rel g16_a]
 mov ecx,1
 mov r8d,1
 call nebo_tensor_split_view
 test eax,eax
 jnz .fail7
 pxor xmm0,xmm0
 lea rdi,[rel g16_out3]
 lea rsi,[rel g16_data_out3]
 lea rdx,[rel g16_a]
 lea rcx,[rel g16_pads]
 mov r8d,1665
 call nebo_tensor_pad_f64
 test eax,eax
 jnz .fail8
 lea rdi,[rel g16_out]
 lea rsi,[rel g16_data_out]
 lea rdx,[rel g16_a]
 lea rcx,[rel g16_b]
 mov r8d,1666
 call nebo_tensor_matmul_f64
 test eax,eax
 jnz .fail9
 mov rax,__float64__(19.0)
 cmp [rel g16_data_out],rax
 jne .fail10
 call nebo_tensor_einsum_reject
 cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail11
 ; Vector promotion: [2] @ [2] -> scalar 17.
 push qword 1667
 lea rdi,[rel g16_a]
 lea rsi,[rel g16_data_a]
 mov edx,1
 lea rcx,[rel g16_shape2]
 lea r8,[rel g16_values_22a]
 call nebo_tensor_from_buffer_f64
 add rsp,8
 test eax,eax
 jnz .fail12
 push qword 1668
 lea rdi,[rel g16_b]
 lea rsi,[rel g16_data_b]
 mov edx,1
 lea rcx,[rel g16_shape2]
 lea r8,[rel g16_values_22b]
 call nebo_tensor_from_buffer_f64
 add rsp,8
 test eax,eax
 jnz .fail13
 lea rdi,[rel g16_out]
 lea rsi,[rel g16_data_out]
 lea rdx,[rel g16_a]
 lea rcx,[rel g16_b]
 mov r8d,1669
 call nebo_tensor_matmul_f64
 test eax,eax
 jnz .fail14
 cmp qword [rel g16_out+NEBO_TENSOR_RANK],0
 jne .fail15
 mov rax,__float64__(17.0)
 cmp [rel g16_data_out],rax
 jne .fail16
 ; Batch dimensions broadcast from [2,2,2] and [1,2,2].
 push qword 1670
 lea rdi,[rel g16_a]
 lea rsi,[rel g16_data_a]
 mov edx,3
 lea rcx,[rel g16_shape222]
 lea r8,[rel g16_values_batch_a]
 call nebo_tensor_from_buffer_f64
 add rsp,8
 test eax,eax
 jnz .fail17
 push qword 1671
 lea rdi,[rel g16_b]
 lea rsi,[rel g16_data_b]
 mov edx,3
 lea rcx,[rel g16_shape122]
 lea r8,[rel g16_values_batch_b]
 call nebo_tensor_from_buffer_f64
 add rsp,8
 test eax,eax
 jnz .fail18
 lea rdi,[rel g16_out]
 lea rsi,[rel g16_data_out]
 lea rdx,[rel g16_a]
 lea rcx,[rel g16_b]
 mov r8d,1672
 call nebo_tensor_matmul_f64
 test eax,eax
 jnz .fail19
 cmp qword [rel g16_out+NEBO_TENSOR_RANK],3
 jne .fail20
 mov rax,__float64__(19.0)
 cmp [rel g16_data_out],rax
 jne .fail21
 mov rax,__float64__(10.0)
 cmp [rel g16_data_out+32],rax
 jne .fail22
 ; Rank-three padding changes only the last axis.
 pxor xmm0,xmm0
 lea rdi,[rel g16_out3]
 lea rsi,[rel g16_data_out3]
 lea rdx,[rel g16_a]
 lea rcx,[rel g16_pads3]
 mov r8d,1673
 call nebo_tensor_pad_f64
 test eax,eax
 jnz .fail23
 cmp qword [rel g16_out3+NEBO_TENSOR_SHAPE+16],3
 jne .fail24
 mov rax,__float64__(1.0)
 cmp [rel g16_data_out3+8],rax
 jne .fail25
 xor eax,eax
 ret
.fail1: mov eax,1
 ret
.fail2: mov eax,2
 ret
.fail3: mov eax,3
 ret
.fail4: mov eax,4
 ret
.fail5: mov eax,5
 ret
.fail6: mov eax,6
 ret
.fail7: mov eax,7
 ret
.fail8: mov eax,8
 ret
.fail9: mov eax,9
 ret
.fail10: mov eax,10
 ret
.fail11: mov eax,11
 ret
.fail12: mov eax,12
 ret
.fail13: mov eax,13
 ret
.fail14: mov eax,14
 ret
.fail15: mov eax,15
 ret
.fail16: mov eax,16
 ret
.fail17: mov eax,17
 ret
.fail18: mov eax,18
 ret
.fail19: mov eax,19
 ret
.fail20: mov eax,20
 ret
.fail21: mov eax,21
 ret
.fail22: mov eax,22
 ret
.fail23: mov eax,23
 ret
.fail24: mov eax,24
 ret
.fail25: mov eax,25
 ret

; mode, seed -> seed on success; a stable non-seed failure code otherwise.
nebo_g016_source_probe:
 mov [rel g16_seed],rsi
 cmp edi,1
 je .m1
 cmp edi,2
 je .m2
 cmp edi,3
 je .m3
 cmp edi,4
 je .m4
 cmp edi,5
 je .m5
 cmp edi,6
 je .m6
 mov eax,206
 ret
.m1: call g16_mode_1
 jmp .finish
.m2: call g16_mode_2
 jmp .finish
.m3: call g16_mode_3
 jmp .finish
.m4: call g16_mode_4
 jmp .finish
.m5: call g16_mode_5
 jmp .finish
.m6: call g16_mode_6
.finish:
 test eax,eax
 jnz .bad
 mov eax,[rel g16_seed]
 ret
.bad:
 add eax,210
 ret

; Independent adversarial entry: invalid rank, bounds, failure atomicity,
; unsupported structural axis and explicit einsum contract diagnostic.
nebo_g016_negative_probe:
 lea rdi,[rel g16_a]
 lea rsi,[rel g16_data_a]
 mov edx,7
 lea rcx,[rel g16_shape_bad_rank]
 mov r8d,1691
 call nebo_tensor_zeros_f64
 cmp eax,NEBO_NUMERIC_ERROR_SHAPE
 jne .fail1
 call g16_init_a23
 test eax,eax
 jnz .fail2
 lea rdi,[rel g16_view]
 lea rsi,[rel g16_a]
 mov edx,2
 xor ecx,ecx
 call nebo_tensor_select_view
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail3
 push qword 1692
 lea rdi,[rel g16_b]
 lea rsi,[rel g16_data_b]
 mov edx,2
 lea rcx,[rel g16_shape23]
 lea r8,[rel g16_values_zero_div]
 call nebo_tensor_from_buffer_f64
 add rsp,8
 test eax,eax
 jnz .fail4
 mov rax,0x1122334455667788
 mov [rel g16_data_out],rax
 lea rdi,[rel g16_out]
 lea rsi,[rel g16_data_out]
 lea rdx,[rel g16_a]
 lea rcx,[rel g16_b]
 mov r8d,1693
 call nebo_tensor_divide_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail5
 mov rax,0x1122334455667788
 cmp [rel g16_data_out],rax
 jne .fail6
 lea rdi,[rel g16_out]
 lea rsi,[rel g16_data_out]
 lea rdx,[rel g16_a]
 lea rcx,[rel g16_a]
 mov r8d,2
 mov r9d,1694
 call nebo_tensor_concatenate_f64
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail7
 call nebo_tensor_einsum_reject
 cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail8
 lea rdi,[rel g16_out]
 lea rsi,[rel g16_data_a]
 lea rdx,[rel g16_a]
 lea rcx,[rel g16_a]
 mov r8d,1695
 call nebo_tensor_add_f64
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail9
 mov rax,__float64__(1.0)
 cmp [rel g16_data_a],rax
 jne .fail10
 xor eax,eax
 ret
.fail1: mov eax,1
 ret
.fail2: mov eax,2
 ret
.fail3: mov eax,3
 ret
.fail4: mov eax,4
 ret
.fail5: mov eax,5
 ret
.fail6: mov eax,6
 ret
.fail7: mov eax,7
 ret
.fail8: mov eax,8
 ret
.fail9: mov eax,9
 ret
.fail10: mov eax,10
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
