; ABI bridge from typed source plans to the canonical Tensor owners.
bits 64
default rel
%include "runtime/tensor/tensor_core.inc"
%include "runtime/tensor/tensor_views.inc"
%include "runtime/tensor/tensor_ops.inc"
%include "runtime/tensor/tensor_i64_public.inc"
%include "runtime/tensor/tensor_axis_reduce.inc"
%include "runtime/tensor/tensor_structural.inc"
section .text
global nebo_tensor_public_borrow
global nebo_tensor_public_sret
; Snapshot descriptor provenance; the parameter only borrows readonly data.
nebo_tensor_public_borrow:
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov rdi,rsi
 mov rsi,[r13+NEBO_TENSOR_DTYPE]
 call tensor_public_validate
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r13
 mov ecx,22
 rep movsq
 and qword [r12+NEBO_TENSOR_FLAGS],~NEBO_TENSOR_FLAG_OWNED
 or qword [r12+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_VIEW|NEBO_TENSOR_FLAG_READONLY
 mov rdx,r12
.done:
 add rsp,8
 pop r13
 pop r12
 ret

; Caller storage receives an owned logical copy before a callee frame ends.
nebo_tensor_public_sret:
 push rbx
 sub rsp,64
 mov rbx,rdi
 mov [rsp],rsi
 mov rsi,rdx
 mov rdx,rbx
 mov rcx,rsp
 lea r8,[rbx+176]
 mov edi,19
 call nebo_tensor_public_dispatch
 add rsp,64
 pop rbx
 ret

global nebo_tensor_public_dispatch
; op, dtype, fresh result descriptor, ordered arguments, fresh result payload.
; Private descriptors append a live root pointer after the native 168 bytes.
nebo_tensor_public_dispatch:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,1792
 mov ebx,edi
 mov r12,rsi
 mov r13,rdx
 mov r14,r8
 mov r15,rcx
 cmp esi,1
 jb .argument
 cmp esi,3
 ja .argument
 cmp ebx,1
 je .construct
 cmp ebx,2
 je .construct
 cmp ebx,3
 je .from_buffer
 cmp ebx,40
 jae .parts
 mov rdi,[r15]
 mov rsi,r12
 call tensor_public_validate
 test eax,eax
 jnz .done
 mov rdi,[r15]
 cmp ebx,4
 je .dtype
 cmp ebx,5
 je .device
 cmp ebx,6
 je .identity
 cmp ebx,7
 je .geometry
 cmp ebx,8
 je .rank
 cmp ebx,9
 je .count
 cmp ebx,10
 je .geometry
 cmp ebx,11
 je .contiguous_query
 cmp ebx,12
 je .axis
 cmp ebx,13
 je .at
 cmp ebx,14
 je .slice
 cmp ebx,15
 je .select
 cmp ebx,16
 je .narrow
 cmp ebx,17
 je .permute
 cmp ebx,18
 je .reshape
 cmp ebx,19
 je .copy
 cmp ebx,20
 je .broadcast
 cmp ebx,24
 jbe .binary
 cmp ebx,25
 je .where
 cmp ebx,26
 je .map
 cmp ebx,30
 jbe .reduce
 cmp ebx,31
 je .argmax
 cmp ebx,33
 jbe .reduce_bool
 cmp ebx,35
 jbe .join
 cmp ebx,36
 je .split
 cmp ebx,37
 je .matmul
 cmp ebx,39
 je .pad
 jmp .argument
.construct:
 mov rax,[r15+8]
 test rax,rax
 jz .argument
 mov rcx,[rax+8]
 mov r8,[rax]
 mov rdi,r13
 mov rsi,r14
 cmp r12d,2
 jne .construct_bits
 mov edx,64
 mov r9,r13
 cmp ebx,1
 je .zeros_int
 mov rax,[r15+16]
 mov [rsp],rax
 call nebo_tensor_i64_filled
 jmp .owned
.zeros_int:
 call nebo_tensor_i64_zeros
 jmp .owned
.construct_bits:
 mov rdx,rcx
 mov rcx,r8
 mov r8,r13
 mov r9,r12
 pxor xmm0,xmm0
 cmp ebx,1
 je .fill_bits
 movq xmm0,[r15+16]
.fill_bits:
 call nebo_tensor_filled_bits
 jmp .owned
.from_buffer:
 ; The caller's real {data,count} buffer is borrowed only until this logical
 ; copy completes. Preflight output capacity with the existing dtype owner.
 mov rax,[r15+16]
 mov rcx,[rax+8]
 mov r8,[rax]
 mov rdi,r13
 mov rsi,r14
 cmp r12d,2
 jne .buffer_plan_bits
 mov edx,64
 mov r9,r13
 call nebo_tensor_i64_owner_init
 jmp .buffer_plan_ready
.buffer_plan_bits:
 mov rdx,rcx
 mov rcx,r8
 mov r8,r12
 mov r9,r13
 call nebo_tensor_init_owned
.buffer_plan_ready:
 test eax,eax
 jnz .done
 lea rdi,[rsp+64]
 mov rsi,r13
 mov ecx,21
 rep movsq
 mov rax,[r15+8]
 mov rcx,[rax+8]
 cmp rcx,4096
 ja .shape
 mov [rsp+48],rcx
 mov rdx,[rax]
 test rcx,rcx
 jz .buffer_pointer_ready
 test rdx,rdx
 jz .argument
 cmp r12d,1
 je .buffer_pointer_ready
 test rdx,7
 jnz .argument
.buffer_pointer_ready:
 cmp r12d,1
 jne .buffer_values_ready
 xor eax,eax
.buffer_bool:
 cmp rax,rcx
 jae .buffer_values_ready
 cmp byte [rdx+rax],1
 ja .argument
 inc rax
 jmp .buffer_bool
.buffer_values_ready:
 mov [rsp+64+NEBO_TENSOR_DATA],rdx
 mov [rsp+64+NEBO_TENSOR_STORAGE_ID],rdx
 mov qword [rsp+64+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_VIEW|NEBO_TENSOR_FLAG_READONLY
 mov rax,[r13+NEBO_TENSOR_CAPACITY]
 cmp rax,rcx
 cmova rcx,rax
 mov [rsp+64+NEBO_TENSOR_CAPACITY],rcx
 mov rax,[r15+32]
 test rax,rax
 jnz .buffer_strides
 mov rax,[r13+NEBO_TENSOR_CAPACITY]
 cmp rax,[rsp+48]
 jne .shape
 jmp .buffer_span
.buffer_strides:
 mov rcx,[rax+8]
 cmp rcx,[r13+NEBO_TENSOR_RANK]
 jne .shape
 mov rsi,[rax]
 lea rdi,[rsp+64+NEBO_TENSOR_STRIDES]
 rep movsq
.buffer_span:
 xor ecx,ecx
 xor r8d,r8d
.buffer_axis:
 cmp rcx,[r13+NEBO_TENSOR_RANK]
 jae .buffer_extent
 mov rdx,[rsp+64+NEBO_TENSOR_STRIDES+rcx*8]
 test rdx,rdx
 js .shape
 mov rax,[r13+NEBO_TENSOR_SHAPE+rcx*8]
 test rax,rax
 jz .buffer_axis_next
 dec rax
 imul rax,rdx
 jo .shape
 add r8,rax
 jc .shape
.buffer_axis_next:
 inc rcx
 jmp .buffer_axis
.buffer_extent:
 cmp qword [r13+NEBO_TENSOR_CAPACITY],0
 je .buffer_copy
 cmp r8,[rsp+48]
 jae .shape
.buffer_copy:
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rsp+64]
 mov rcx,r13
 call nebo_tensor_contiguous_bits
 jmp .owned
.dtype:
 call nebo_tensor_dtype
 jmp .query
.device:
 call nebo_tensor_device
 jmp .query
.identity:
 call nebo_tensor_storage_id
 jmp .query
.rank:
 mov rdx,[rdi+NEBO_TENSOR_RANK]
 xor eax,eax
 jmp .done
.count:
 call nebo_tensor_element_count
 jmp .query
.contiguous_query:
 call nebo_tensor_is_contiguous
 jmp .query
.axis:
 mov rsi,[r15+8]
 call nebo_tensor_axis_size
 jmp .query
.geometry:
 mov rax,[rdi+NEBO_TENSOR_RANK]
 mov [r13+8],rax
 cmp ebx,7
 jne .strides
 call nebo_tensor_shape
 jmp .geometry_result
.strides:
 call nebo_tensor_strides
.geometry_result:
 test edx,edx
 jnz .query
 ; The typed result is a runtime-shaped readonly Vector<Int> descriptor.
 mov [r13],rax
 mov rdx,r13
 xor eax,eax
 jmp .done
.at:
 mov rax,[r15+8]
 mov rcx,[rax+8]
 cmp rcx,[rdi+NEBO_TENSOR_RANK]
 jne .shape
 mov rsi,[rax]
.at_bits:
 call nebo_tensor_at_bits
 jmp .done
.slice:
 mov rax,[r15+8]
 cmp qword [rax+8],4
 jne .shape
 mov rax,[rax]
 mov rsi,rdi
 mov rdi,r13
 mov rdx,[rax]
 mov rcx,[rax+8]
 mov r8,[rax+16]
 mov r9,[rax+24]
 call nebo_tensor_slice_view
 jmp .view
.select:
 mov rsi,rdi
 mov rdi,r13
 mov rdx,[r15+8]
 mov rcx,[r15+16]
 call nebo_tensor_select_view
 jmp .view
.narrow:
 mov rsi,rdi
 mov rdi,r13
 mov rdx,[r15+8]
 mov rcx,[r15+16]
 mov r8,[r15+32]
 call nebo_tensor_narrow_view
 jmp .view
.permute:
 mov rax,[r15+8]
 mov rcx,[rax+8]
 cmp rcx,[rdi+NEBO_TENSOR_RANK]
 jne .shape
 mov rdx,[rax]
 mov rsi,rdi
 mov rdi,r13
 call nebo_tensor_permute_view
 jmp .view
.reshape:
 mov rax,[r15+8]
 mov rdx,[rax+8]
 mov rcx,[rax]
 mov rsi,rdi
 mov rdi,r13
 call nebo_tensor_reshape_view
 jmp .view
.broadcast:
 mov rax,[r15+8]
 mov rdx,[rax+8]
 mov rcx,[rax]
 mov rsi,rdi
 mov rdi,r13
 call nebo_tensor_broadcast_view_rank
 jmp .view
.copy:
 mov rdx,rdi
 mov rdi,r13
 mov rsi,r14
 mov rcx,r13
.copy_bits:
 call nebo_tensor_contiguous_bits
 jmp .owned
.binary:
 mov rdi,[r15+8]
 mov rsi,r12
 call tensor_public_validate
 test eax,eax
 jnz .done
 cmp r12d,2
 je .binary_int
 mov rdi,r13
 mov rsi,r14
 mov rdx,[r15]
 mov rcx,[r15+8]
 mov r9,r13
 mov r8d,NEBO_TENSOR_OP_ADD
 cmp ebx,21
 je .binary_float
 mov r8d,NEBO_TENSOR_OP_MUL
 cmp ebx,22
 je .binary_float
 mov r8d,NEBO_TENSOR_OP_DIV
 cmp ebx,23
 je .binary_float
 mov r8d,NEBO_TENSOR_OP_MAX
.binary_float:
 call nebo_tensor_binary_broadcast_f64
 jmp .owned
.binary_int:
 mov rdi,[r15]
 call tensor_public_i64_arithmetic_shape
 test eax,eax
 jnz .done
 mov rdi,[r15+8]
 call tensor_public_i64_arithmetic_shape
 test eax,eax
 jnz .done
 ; Canonical Int arithmetic already performs checked trailing broadcasting.
 ; Materialize readonly/strided inputs through the shared logical-copy owner.
 lea rdi,[rsp+64]
 lea rsi,[rsp+704]
 mov rdx,[r15]
 mov rcx,rdi
 call nebo_tensor_contiguous_bits
 test eax,eax
 jnz .done
 lea rdi,[rsp+240]
 lea rsi,[rsp+1216]
 mov rdx,[r15+8]
 mov rcx,rdi
 call nebo_tensor_contiguous_bits
 test eax,eax
 jnz .done
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rsp+64]
 lea rcx,[rsp+240]
 mov r8,r13
 cmp ebx,21
 jne .multiply_int
 call nebo_tensor_i64_add
 jmp .owned
.multiply_int:
 call nebo_tensor_i64_multiply
 jmp .owned
.where:
 mov rdi,[r15+8]
 mov esi,1
 call tensor_public_validate
 test eax,eax
 jnz .done
 mov rdi,[r15+16]
 mov rsi,r12
 call tensor_public_validate
 test eax,eax
 jnz .done
 mov rdi,r13
 mov rsi,r14
 mov rdx,[r15+8]
 mov rcx,[r15]
 mov r8,[r15+16]
 mov r9,r13
 call nebo_tensor_where_f64
 jmp .owned
.map:
 mov rdi,r13
 mov rsi,r14
 mov rdx,[r15]
 mov rcx,[r15+8]
 xor r8d,r8d
 mov r9,r13
 call nebo_tensor_map_f64
 jmp .owned
.reduce:
 cmp r12d,2
 je .reduce_int
 mov rax,[r15+8]
 mov rcx,[rax]
 mov r8,[rax+8]
 mov r9d,ebx
 sub r9d,26
 mov rax,[r15+16]
 mov [rsp],rax
 mov [rsp+8],r13
 mov rdi,r13
 mov rsi,r14
 mov rdx,[r15]
 call nebo_tensor_reduce_axes_f64
 jmp .owned
.reduce_int:
 mov rdi,[r15]
 call tensor_public_i64_arithmetic_shape
 test eax,eax
 jnz .done
 lea rdi,[rsp+64]
 lea rsi,[rsp+704]
 mov rdx,[r15]
 mov rcx,rdi
 call nebo_tensor_contiguous_bits
 test eax,eax
 jnz .done
 mov rax,[r15+8]
 mov rcx,[rax]
 mov r8,[rax+8]
 mov r9,[r15+16]
 mov [rsp],r13
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rsp+64]
 call nebo_tensor_i64_sum_axes
 jmp .owned
.argmax:
 mov rdi,r13
 mov rsi,r14
 mov rdx,[r15]
 mov rcx,[r15+8]
 mov r8,r13
 call nebo_tensor_argmax_axis_f64
 mov r12d,2
 jmp .owned
.reduce_bool:
 mov rdi,r13
 mov rsi,r14
 mov rdx,[r15]
 mov rcx,[r15+8]
 mov r8,r13
 cmp ebx,32
 jne .any
 call nebo_tensor_all_axis_bool
 jmp .owned
.any:
 call nebo_tensor_any_axis_bool
 jmp .owned
.matmul:
 mov rdi,[r15+8]
 mov rsi,r12
 call tensor_public_validate
 test eax,eax
 jnz .done
 mov rdi,r13
 mov rsi,r14
 mov rdx,[r15]
 mov rcx,[r15+8]
 mov r8,r13
 call nebo_tensor_matmul_f64
 jmp .owned
.pad:
 mov rdx,[r15]
 mov rax,[r15+8]
 mov rcx,[rdx+NEBO_TENSOR_RANK]
 add rcx,rcx
 cmp rcx,[rax+8]
 jne .shape
 mov rcx,[rax]
 movq xmm0,[r15+16]
 mov rdi,r13
 mov rsi,r14
 mov r8,r13
 call nebo_tensor_pad_f64
 jmp .owned
.join:
 mov rdi,r13
 mov rsi,r14
 mov rdx,[r15]
 mov rcx,[r15+8]
 mov r8,[r15+16]
 mov r9,rbx
 call tensor_public_join
 jmp .owned
.split:
 ; Validate all sizes before publishing any readonly view.
 mov rax,[r15+8]
 mov rcx,[rax+8]
 test rcx,rcx
 jz .shape
 cmp rcx,6
 ja .shape
 mov [rsp+16],rcx
 mov rax,[rax]
 mov [rsp+24],rax
 mov rdx,[r15+16]
 mov rdi,[r15]
 cmp rdx,[rdi+NEBO_TENSOR_RANK]
 jae .shape
 xor r8d,r8d
 xor r9d,r9d
.split_sum:
 cmp r9,rcx
 jae .split_total
 mov r10,[rax+r9*8]
 test r10,r10
 js .shape
 add r8,r10
 jc .shape
 inc r9
 jmp .split_sum
.split_total:
 cmp r8,[rdi+NEBO_TENSOR_SHAPE+rdx*8]
 jne .shape
 mov [rsp+32],rdi
 mov qword [rsp+40],0
.split_each:
 mov rax,[rsp+40]
 cmp rax,[rsp+16]
 jae .split_result
 imul rdi,rax,176
 add rdi,r14
 mov rsi,rax
 and esi,1
 imul rsi,176
 lea rsi,[rsp+rsi+64]
 mov rdx,[rsp+32]
 mov rcx,[rsp+24]
 mov rcx,[rcx+rax*8]
 mov r8,[r15+16]
 mov [rsp+48],rsi
 call nebo_tensor_split_view
 test eax,eax
 jnz .done
 mov rax,[rsp+40]
 imul rax,176
 lea rdi,[r14+rax]
 mov rax,[r15]
 mov rax,[rax+168]
 mov [rdi+168],rax
 mov rsi,[rsp+48]
 mov [rsi+168],rax
 mov [rsp+32],rsi
 inc qword [rsp+40]
 jmp .split_each
.split_result:
 mov [r13],r14
 mov rax,[rsp+16]
 mov [r13+8],rax
 mov rdx,r13
 xor eax,eax
 jmp .done
.parts:
 mov rax,[r15]
 cmp ebx,41
 je .parts_length
 cmp ebx,40
 jne .argument
 mov rcx,[r15+8]
 cmp rcx,[rax+8]
 jae .shape
 imul rcx,176
 add rcx,[rax]
 mov [rsp+16],rcx
 mov rdi,rcx
 mov esi,3
 call tensor_public_validate
 mov rdx,[rsp+16]
 jmp .done
.parts_length:
 mov rdx,[rax+8]
 xor eax,eax
 jmp .done
.view:
 test eax,eax
 jnz .done
 mov rax,[r15]
 mov rax,[rax+168]
 mov [r13+168],rax
 jmp .validate_result
.owned:
 test eax,eax
 jnz .done
 mov [r13+168],r13
.validate_result:
 mov rdi,r13
 mov rsi,r12
 call tensor_public_validate
 test eax,eax
 jnz .done
 mov rdx,r13
 xor eax,eax
 jmp .done
.query:
 mov rcx,rax
 mov eax,edx
 mov rdx,rcx
 jmp .done
.argument: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .done
.shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
.done:
 add rsp,1792
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Validate public provenance and the entire reachable byte span before a
; native read. Logical element count is not the backing size of a broadcast.
tensor_public_validate:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 call nebo_tensor_validate
 test eax,eax
 jnz .done
 cmp [r12+NEBO_TENSOR_DTYPE],r13
 jne .contract
 mov rbx,[r12+168]
 test rbx,rbx
 jz .argument
 mov rdi,rbx
 call nebo_tensor_validate
 test eax,eax
 jnz .done
 test qword [rbx+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_OWNED
 jz .contract
 mov rax,[r12+NEBO_TENSOR_STORAGE_ID]
 cmp rax,[rbx+NEBO_TENSOR_STORAGE_ID]
 jne .contract
 mov rax,[r12+NEBO_TENSOR_GENERATION]
 cmp rax,[rbx+NEBO_TENSOR_GENERATION]
 jne .contract
 mov rax,[r12+NEBO_TENSOR_RANK]
.geometry:
 xor r8d,r8d
 xor r9d,r9d
 mov r11d,1
.axis:
 cmp r8,rax
 jae .span
 mov rcx,[r12+NEBO_TENSOR_SHAPE+r8*8]
.dimension:
 cmp rcx,4096
 ja .shape
 imul r11,rcx
 jo .shape
 test rcx,rcx
 jz .next
 dec rcx
 mov rdx,[r12+NEBO_TENSOR_STRIDES+r8*8]
 test rdx,rdx
 js .shape
 imul rcx,rdx
 jo .shape
 add r9,rcx
 jc .shape
.next:
 inc r8
 jmp .axis
.span:
 cmp r11,4096
 ja .shape
.count_ready:
 mov rax,[r12+NEBO_TENSOR_DATA]
 sub rax,[rbx+NEBO_TENSOR_DATA]
 jc .shape
 cmp r13d,NEBO_TENSOR_DTYPE_BOOL
 je .element_offset
 test rax,7
 jnz .shape
 shr rax,3
.element_offset:
 test r11,r11
 jz .empty
 add rax,r9
 jc .shape
 cmp rax,[rbx+NEBO_TENSOR_CAPACITY]
 jae .shape
 jmp .ok
.empty:
 cmp rax,[rbx+NEBO_TENSOR_CAPACITY]
 ja .shape
.ok: xor eax,eax
 jmp .done
.argument: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .done
.contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .done
.shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
.done:
 pop r13
 pop r12
 pop rbx
 ret
; Ordered multi-input composition reuses native logical copy, stack and
; concatenate. Two bounded work payloads keep every source descriptor intact.
; out, output payload, first, peers {data,count}, axis, operation(34/35).
tensor_public_join:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,66240
 mov r12,rdi
 mov r13,rsi
 mov r14,rcx
 mov [rsp],r8
 mov [rsp+8],r9
 mov qword [rsp+16],0
 mov r15,rdx
 mov rax,[r14+8]
 test rax,rax
 jz .shape
 cmp rax,6
 ja .shape
 lea rdi,[rsp+64]
 lea rsi,[rsp+704]
 mov rdx,r15
 mov rcx,rdi
 call nebo_tensor_contiguous_bits
 test eax,eax
 jnz .done
.next:
 mov rax,[rsp+16]
 cmp rax,[r14+8]
 jae .ok
 mov rcx,[r14]
 mov rbx,[rcx+rax*8]
 mov rdi,rbx
 mov esi,3
 call tensor_public_validate
 test eax,eax
 jnz .done
 lea rdi,[rsp+240]
 lea rsi,[rsp+33472]
 mov rdx,rbx
 mov rcx,rdi
 call nebo_tensor_contiguous_bits
 test eax,eax
 jnz .done
 cmp qword [rsp+8],35
 jne .concatenate
 cmp qword [rsp+16],0
 je .first_stack
 ; A subsequent stack component contributes one element on the inserted
 ; axis; reshape its contiguous copy and concatenate on that same axis.
 mov r8,[rsp]
 mov r9,[rsp+240+NEBO_TENSOR_RANK]
 cmp r8,r9
 ja .shape
 cmp r9,6
 jae .shape
 xor ecx,ecx
 xor edx,edx
.stack_shape:
 cmp rcx,r8
 jne .stack_original
 mov qword [rsp+608+rcx*8],1
 inc rcx
.stack_original:
 cmp rdx,r9
 jae .stack_shape_ready
 mov rax,[rsp+240+NEBO_TENSOR_SHAPE+rdx*8]
 mov [rsp+608+rcx*8],rax
 inc rcx
 inc rdx
 jmp .stack_shape
.stack_shape_ready:
 lea rdi,[rsp+416]
 lea rsi,[rsp+240]
 lea rdx,[r9+1]
 lea rcx,[rsp+608]
 call nebo_tensor_reshape_view
 test eax,eax
 jnz .done
 lea rcx,[rsp+416]
 jmp .concat_invoke
.concatenate:
 lea rcx,[rsp+240]
.concat_invoke:
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rsp+64]
 mov r8,[rsp]
 mov r9,r12
 call nebo_tensor_concatenate_f64
 jmp .joined
.first_stack:
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rsp+64]
 lea rcx,[rsp+240]
 mov r8,[rsp]
 mov r9,r12
 call nebo_tensor_stack_f64
.joined:
 test eax,eax
 jnz .done
 inc qword [rsp+16]
 mov rax,[rsp+16]
 cmp rax,[r14+8]
 jae .ok
 lea rdi,[rsp+64]
 lea rsi,[rsp+704]
 mov rdx,r12
 mov rcx,rdi
 call nebo_tensor_contiguous_bits
 test eax,eax
 jnz .done
 jmp .next
.ok:
 xor eax,eax
 jmp .done
.shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
.done:
 add rsp,66240
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Checked Int arithmetic uses the existing C12 bounded owner. Metadata,
; views and indexing also admit larger Int values produced by argMax.
tensor_public_i64_arithmetic_shape:
 cmp qword [rdi+NEBO_TENSOR_RANK],3
 ja .shape
 xor ecx,ecx
 mov r8d,1
.axis:
 cmp rcx,[rdi+NEBO_TENSOR_RANK]
 jae .count
 mov rax,[rdi+NEBO_TENSOR_SHAPE+rcx*8]
 cmp rax,8
 ja .shape
 imul r8,rax
 inc rcx
 jmp .axis
.count:
 cmp r8,64
 ja .shape
 xor eax,eax
 ret
.shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
