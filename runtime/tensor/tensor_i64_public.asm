; C12 CPU_I64_SMALL_V1 Tensor owner materialization over the frozen 168-byte ABI.
bits 64
default rel
%define NEBO_TENSOR_I64_PUBLIC_IMPLEMENTATION 1
%include "runtime/tensor/tensor_i64_public.inc"

section .text
global nebo_tensor_i64_owner_init
global nebo_tensor_i64_owner_validate
global nebo_tensor_i64_owner_invalidate
global nebo_tensor_i64_rank
global nebo_tensor_i64_dimension
global nebo_tensor_i64_element_count
global nebo_tensor_i64_stride
global nebo_tensor_i64_is_contiguous
global nebo_tensor_i64_zeros
global nebo_tensor_i64_filled
global nebo_tensor_i64_from_buffer
global nebo_tensor_i64_at
global nebo_tensor_i64_set
global nebo_tensor_i64_narrow_view
global nebo_tensor_i64_select_view
global nebo_tensor_i64_view_validate_owner
global nebo_tensor_i64_view_at
global nebo_tensor_i64_reshape_view
global nebo_tensor_i64_permute_view
global nebo_tensor_i64_transpose_view
global nebo_tensor_i64_broadcast_view
global nebo_tensor_i64_add
global nebo_tensor_i64_multiply
global nebo_tensor_i64_sum_axes
global nebo_tensor_i64_sum_all
global nebo_tensor_i64_min
global nebo_tensor_i64_max
global nebo_tensor_i64_contiguous
global nebo_tensor_i64_borrow_sum
global nebo_tensor_i64_sret_filled
global nebo_tensor_i64_serialized_size
global nebo_tensor_i64_serialize
global nebo_tensor_i64_deserialize
global nebo_tensor_i64_headless_shape

; Validate a complete owner plan without changing descriptor or payload.
; rdi descriptor, rsi payload, rdx payload capacity (elements), rcx rank,
; r8 shape pointer (nullable only for rank 0), r9 nonzero storage identity.
; Success returns eax=0 and r10=logical element count.
tensor_i64_owner_plan:
 test rdi,rdi
 jz .argument
 test rdi,7
 jnz .argument
 test r9,r9
 jz .argument
 cmp rdx,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 ja .workspace
 cmp rcx,NEBO_TENSOR_I64_PUBLIC_MAX_RANK
 ja .shape
 test rcx,rcx
 jz .rank_zero
 test r8,r8
 jz .argument
 test r8,7
 jnz .argument
 mov r10,1
 xor r11d,r11d
.dimension:
 cmp r11,rcx
 jae .count_ready
 mov rax,[r8+r11*8]
 cmp rax,NEBO_TENSOR_I64_PUBLIC_MAX_DIMENSION
 ja .shape
 imul r10,rax
 jo .overflow
 cmp r10,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 ja .shape
 inc r11
 jmp .dimension
.rank_zero:
 mov r10,1
.count_ready:
 cmp r10,rdx
 ja .workspace
 test rdx,rdx
 jz .payload_ready
 test rsi,rsi
 jz .argument
 test rsi,7
 jnz .argument
.payload_ready:
 ; Check descriptor and the entire explicit payload span for nonoverlap.
 mov rax,rdi
 add rax,NEBO_TENSOR_SIZE
 jc .overflow
 mov r11,rdx
 shl r11,3
 jc .overflow
 test r11,r11
 jz .ok
 mov rdx,rsi
 add rdx,r11
 jc .overflow
 cmp rdi,rdx
 jae .ok
 cmp rsi,rax
 jae .ok
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 ret
.ok:
 xor eax,eax
 ret
.argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
.shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 ret
.overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
 ret
.workspace:
 mov eax,NEBO_NUMERIC_ERROR_WORKSPACE
 ret

; rdi owner, rsi indices, rdx index count. Success returns offset in r10.
tensor_i64_offset_plan:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .offset_done
 cmp r14,[r12+NEBO_TENSOR_RANK]
 jne .offset_shape
 test r14,r14
 jz .offset_rank_zero
 test r13,r13
 jz .offset_argument
 test r13,7
 jnz .offset_argument
 xor r10d,r10d
 xor ecx,ecx
.offset_axis:
 cmp rcx,r14
 jae .offset_ready
 mov rax,[r13+rcx*8]
 cmp rax,[r12+NEBO_TENSOR_SHAPE+rcx*8]
 jae .offset_bounds
 imul rax,[r12+NEBO_TENSOR_STRIDES+rcx*8]
 jo .offset_overflow
 add r10,rax
 jc .offset_overflow
 inc rcx
 jmp .offset_axis
.offset_rank_zero:
 xor r10d,r10d
.offset_ready:
 cmp r10,[r12+NEBO_TENSOR_CAPACITY]
 jae .offset_bounds
 xor eax,eax
 jmp .offset_done
.offset_argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .offset_done
.offset_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .offset_done
.offset_bounds:
 mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .offset_done
.offset_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
.offset_done:
 pop r14
 pop r13
 pop r12
 ret
; Public fixed/caller-storage owner materialization. Payload bytes are untouched.
nebo_tensor_i64_owner_init:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov [rsp],r9
 call tensor_i64_owner_plan
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r13
 mov rdx,r15
 mov rcx,rbx
 mov r8d,NEBO_TENSOR_DTYPE_I64
 mov r9,[rsp]
 call nebo_tensor_init_owned
 test eax,eax
 jnz .done
 ; The historical descriptor reserves six slots. Public unused slots are zero.
 mov rcx,r15
.clear_unused:
 cmp rcx,NEBO_TENSOR_MAX_RANK
 jae .published
 mov qword [r12+NEBO_TENSOR_SHAPE+rcx*8],0
 mov qword [r12+NEBO_TENSOR_STRIDES+rcx*8],0
 inc rcx
 jmp .clear_unused
.published:
 mov qword [r12+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_I64
 mov qword [r12+NEBO_TENSOR_DEVICE],NEBO_TENSOR_DEVICE_CPU
 mov qword [r12+NEBO_TENSOR_GENERATION],1
 mov qword [r12+NEBO_TENSOR_FLAGS],NEBO_TENSOR_I64_PUBLIC_OWNER_FLAGS
 xor eax,eax
.done:
 add rsp,8
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; Selected constructors use fixed caller storage. Their first six arguments
; match owner_init: descriptor, payload, capacity, rank, shape, storage id.
nebo_tensor_i64_zeros:
 push r12
 push r13
 mov r12,rsi
 call nebo_tensor_i64_owner_init
 test eax,eax
 jnz .zeros_done
 mov rcx,[rdi+NEBO_TENSOR_CAPACITY]
 xor eax,eax
.zeros_loop:
 test rcx,rcx
 jz .zeros_done
 dec rcx
 mov [r12+rcx*8],rax
 jmp .zeros_loop
.zeros_done:
 pop r13
 pop r12
 ret

; Seventh argument (stack) is the fill value.
nebo_tensor_i64_filled:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov rbx,[rsp+56]
 call nebo_tensor_i64_owner_init
 test eax,eax
 jnz .filled_done
 mov rcx,[r12+NEBO_TENSOR_CAPACITY]
.filled_loop:
 test rcx,rcx
 jz .filled_ok
 dec rcx
 mov [r13+rcx*8],rbx
 jmp .filled_loop
.filled_ok:
 xor eax,eax
.filled_done:
 add rsp,8
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; Seventh/eighth arguments are source pointer and exact source element count.
; This is always an explicit logical-element copy; adoption is not supported.
nebo_tensor_i64_from_buffer:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,24
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov [rsp],r9
 mov rax,[rsp+72]
 mov [rsp+8],rax
 mov rax,[rsp+80]
 mov [rsp+16],rax
 call tensor_i64_owner_plan
 test eax,eax
 jnz .from_done
 cmp [rsp+16],r10
 jne .from_shape
 test r10,r10
 jz .from_publish
 mov rax,[rsp+8]
 test rax,rax
 jz .from_argument
 test rax,7
 jnz .from_argument
 mov rcx,r10
 shl rcx,3
 jc .from_overflow
 ; Source and logical destination bytes must not overlap.
 mov rdx,r13
 add rdx,rcx
 jc .from_overflow
 mov r8,rax
 add r8,rcx
 jc .from_overflow
 cmp r13,r8
 jae .from_descriptor_check
 cmp rax,rdx
 jb .from_alias
.from_descriptor_check:
 ; Source also cannot overlap the descriptor published before the copy.
 mov rdx,r12
 add rdx,NEBO_TENSOR_SIZE
 jc .from_overflow
 cmp r12,r8
 jae .from_publish
 cmp rax,rdx
 jb .from_alias
.from_publish:
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 mov rcx,r15
 mov r8,rbx
 mov r9,[rsp]
 call nebo_tensor_i64_owner_init
 test eax,eax
 jnz .from_done
 mov rcx,[r12+NEBO_TENSOR_CAPACITY]
 mov rsi,[rsp+8]
 mov rdi,r13
 rep movsq
 xor eax,eax
 jmp .from_done
.from_argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .from_done
.from_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .from_done
.from_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .from_done
.from_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
.from_done:
 add rsp,24
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; rdi owner, rsi indices pointer, rdx index count -> value RAX, status EDX.
nebo_tensor_i64_at:
 push r12
 mov r12,rdi
 call tensor_i64_offset_plan
 test eax,eax
 jnz .at_error
 mov rdx,[r12+NEBO_TENSOR_DATA]
 mov rax,[rdx+r10*8]
 xor edx,edx
 pop r12
 ret
.at_error:
 mov edx,eax
 xor eax,eax
 pop r12
 ret

; rdi owner, rsi indices pointer, rdx index count, rcx value -> status EAX.
nebo_tensor_i64_set:
 push r12
 push r13
 mov r12,rdi
 mov r13,rcx
 call tensor_i64_offset_plan
 test eax,eax
 jnz .set_done
 mov rdx,[r12+NEBO_TENSOR_DATA]
 mov [rdx+r10*8],r13
 xor eax,eax
.set_done:
 pop r13
 pop r12
 ret

; rdi authenticated owner, rsi destination descriptor.
tensor_i64_view_destination_plan:
 test rsi,rsi
 jz .view_dest_argument
 test rsi,7
 jnz .view_dest_argument
 mov rax,rdi
 add rax,NEBO_TENSOR_SIZE
 jc .view_dest_overflow
 mov rdx,rsi
 add rdx,NEBO_TENSOR_SIZE
 jc .view_dest_overflow
 cmp rdi,rdx
 jae .view_dest_payload
 cmp rsi,rax
 jb .view_dest_alias
.view_dest_payload:
 mov rax,[rdi+NEBO_TENSOR_CAPACITY]
 shl rax,3
 jc .view_dest_overflow
 mov rcx,[rdi+NEBO_TENSOR_DATA]
 test rax,rax
 jz .view_dest_ok
 mov rdx,rcx
 add rdx,rax
 jc .view_dest_overflow
 mov rax,rsi
 add rax,NEBO_TENSOR_SIZE
 jc .view_dest_overflow
 cmp rsi,rdx
 jae .view_dest_ok
 cmp rcx,rax
 jb .view_dest_alias
.view_dest_ok:
 xor eax,eax
 ret
.view_dest_argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
.view_dest_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 ret
.view_dest_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
 ret

; Set VIEW|READONLY and derive CONTIGUOUS from active metadata in rdi.
tensor_i64_publish_view_flags:
 mov qword [rdi+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_VIEW|NEBO_TENSOR_FLAG_READONLY
 mov rcx,[rdi+NEBO_TENSOR_RANK]
 mov r8,1
.view_flag_axis:
 test rcx,rcx
 jz .view_flag_yes
 dec rcx
 cmp [rdi+NEBO_TENSOR_STRIDES+rcx*8],r8
 jne .view_flag_done
 imul r8,[rdi+NEBO_TENSOR_SHAPE+rcx*8]
 jmp .view_flag_axis
.view_flag_yes:
 or qword [rdi+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_CONTIGUOUS
.view_flag_done:
 ret

; owner rdi, destination rsi, axis rdx, start rcx, length r8.
nebo_tensor_i64_narrow_view:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .narrow_done
 mov rdi,r12
 mov rsi,r13
 call tensor_i64_view_destination_plan
 test eax,eax
 jnz .narrow_done
 cmp r14,[r12+NEBO_TENSOR_RANK]
 jae .narrow_bounds
 mov rax,[r12+NEBO_TENSOR_SHAPE+r14*8]
 cmp r15,rax
 ja .narrow_bounds
 sub rax,r15
 cmp rbx,rax
 ja .narrow_bounds
 mov rax,[r12+NEBO_TENSOR_STRIDES+r14*8]
 imul rax,r15
 jo .narrow_overflow
 cmp rax,[r12+NEBO_TENSOR_CAPACITY]
 ja .narrow_bounds
 mov [rsp],rax
 ; All checks completed: publish a descriptor copy then adjust metadata.
 mov rsi,r12
 mov rdi,r13
 mov ecx,NEBO_TENSOR_SIZE/8
 rep movsq
 mov rax,[rsp]
 mov rcx,rax
 shl rcx,3
 add [r13+NEBO_TENSOR_DATA],rcx
 sub [r13+NEBO_TENSOR_CAPACITY],rax
 mov [r13+NEBO_TENSOR_SHAPE+r14*8],rbx
 mov rdi,r13
 call tensor_i64_publish_view_flags
 xor eax,eax
 jmp .narrow_done
.narrow_bounds:
 mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .narrow_done
.narrow_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
.narrow_done:
 add rsp,8
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; owner rdi, destination rsi, axis rdx, selected index rcx.
nebo_tensor_i64_select_view:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .select_done
 mov rdi,r12
 mov rsi,r13
 call tensor_i64_view_destination_plan
 test eax,eax
 jnz .select_done
 cmp r14,[r12+NEBO_TENSOR_RANK]
 jae .select_bounds
 cmp r15,[r12+NEBO_TENSOR_SHAPE+r14*8]
 jae .select_bounds
 mov rax,[r12+NEBO_TENSOR_STRIDES+r14*8]
 imul rax,r15
 jo .select_overflow
 cmp rax,[r12+NEBO_TENSOR_CAPACITY]
 jae .select_bounds
 mov [rsp],rax
 mov rsi,r12
 mov rdi,r13
 mov ecx,NEBO_TENSOR_SIZE/8
 rep movsq
 mov rax,[rsp]
 mov rcx,rax
 shl rcx,3
 add [r13+NEBO_TENSOR_DATA],rcx
 sub [r13+NEBO_TENSOR_CAPACITY],rax
 mov rcx,r14
.select_shift:
 mov rdx,[r13+NEBO_TENSOR_RANK]
 dec rdx
 cmp rcx,rdx
 jae .select_clear
 mov rax,[r13+NEBO_TENSOR_SHAPE+rcx*8+8]
 mov [r13+NEBO_TENSOR_SHAPE+rcx*8],rax
 mov rax,[r13+NEBO_TENSOR_STRIDES+rcx*8+8]
 mov [r13+NEBO_TENSOR_STRIDES+rcx*8],rax
 inc rcx
 jmp .select_shift
.select_clear:
 mov qword [r13+NEBO_TENSOR_SHAPE+rdx*8],0
 mov qword [r13+NEBO_TENSOR_STRIDES+rdx*8],0
 mov [r13+NEBO_TENSOR_RANK],rdx
 mov rdi,r13
 call tensor_i64_publish_view_flags
 xor eax,eax
 jmp .select_done
.select_bounds:
 mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .select_done
.select_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
.select_done:
 add rsp,8
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; rdi view, rsi live owner. Validates identity and reachable address span.
nebo_tensor_i64_view_validate_owner:
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov rdi,r13
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .view_validate_done
 mov rdi,r12
 mov rsi,r13
 call nebo_tensor_validate_view_owner
 test eax,eax
 jnz .view_validate_done
 cmp qword [r12+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_I64
 jne .view_validate_contract
 cmp qword [r12+NEBO_TENSOR_DEVICE],NEBO_TENSOR_DEVICE_CPU
 jne .view_validate_contract
 mov r14,[r12+NEBO_TENSOR_RANK]
 cmp r14,NEBO_TENSOR_I64_PUBLIC_MAX_RANK
 ja .view_validate_shape
 mov rax,[r12+NEBO_TENSOR_FLAGS]
 and rax,~NEBO_TENSOR_FLAG_CONTIGUOUS
 cmp rax,NEBO_TENSOR_FLAG_VIEW|NEBO_TENSOR_FLAG_READONLY
 jne .view_validate_contract
 xor ecx,ecx
 xor r15d,r15d
.view_validate_axis:
 cmp rcx,r14
 jae .view_validate_unused
 mov rax,[r12+NEBO_TENSOR_SHAPE+rcx*8]
 cmp rax,NEBO_TENSOR_I64_PUBLIC_MAX_DIMENSION
 ja .view_validate_shape
 test rax,rax
 jz .view_validate_next
 dec rax
 imul rax,[r12+NEBO_TENSOR_STRIDES+rcx*8]
 jo .view_validate_shape
 add r15,rax
 jc .view_validate_shape
.view_validate_next:
 inc rcx
 jmp .view_validate_axis
.view_validate_unused:
 cmp rcx,NEBO_TENSOR_MAX_RANK
 jae .view_validate_address
 cmp qword [r12+NEBO_TENSOR_SHAPE+rcx*8],0
 jne .view_validate_contract
 cmp qword [r12+NEBO_TENSOR_STRIDES+rcx*8],0
 jne .view_validate_contract
 inc rcx
 jmp .view_validate_unused
.view_validate_address:
 mov rax,[r12+NEBO_TENSOR_DATA]
 mov rdx,[r13+NEBO_TENSOR_DATA]
 cmp rax,rdx
 jb .view_validate_alias
 mov rcx,[r13+NEBO_TENSOR_CAPACITY]
 shl rcx,3
 add rdx,rcx
 jc .view_validate_shape
 cmp rax,rdx
 jae .view_validate_alias
 lea rax,[rax+r15*8]
 cmp rax,rdx
 jae .view_validate_alias
 xor eax,eax
 jmp .view_validate_done
.view_validate_contract:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .view_validate_done
.view_validate_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .view_validate_done
.view_validate_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
.view_validate_done:
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; rdi view, rsi owner, rdx indices, rcx count -> RAX value, EDX status.
nebo_tensor_i64_view_at:
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call nebo_tensor_i64_view_validate_owner
 test eax,eax
 jnz .view_at_error
 cmp r15,[r12+NEBO_TENSOR_RANK]
 jne .view_at_shape
 test r15,r15
 jz .view_at_ready
 test r14,r14
 jz .view_at_argument
 test r14,7
 jnz .view_at_argument
 xor r10d,r10d
 xor ecx,ecx
.view_at_axis:
 cmp rcx,r15
 jae .view_at_ready
 mov rax,[r14+rcx*8]
 cmp rax,[r12+NEBO_TENSOR_SHAPE+rcx*8]
 jae .view_at_bounds
 imul rax,[r12+NEBO_TENSOR_STRIDES+rcx*8]
 add r10,rax
 inc rcx
 jmp .view_at_axis
.view_at_ready:
 mov rdx,[r12+NEBO_TENSOR_DATA]
 mov rax,[rdx+r10*8]
 xor edx,edx
 jmp .view_at_done
.view_at_argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .view_at_error
.view_at_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .view_at_error
.view_at_bounds:
 mov eax,NEBO_NUMERIC_ERROR_BOUNDS
.view_at_error:
 mov edx,eax
 xor eax,eax
.view_at_done:
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; owner rdi, destination rsi, new rank rdx, new shape rcx.
nebo_tensor_i64_reshape_view:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .reshape_done
 mov rdi,r12
 mov rsi,r13
 call tensor_i64_view_destination_plan
 test eax,eax
 jnz .reshape_done
 cmp r14,NEBO_TENSOR_I64_PUBLIC_MAX_RANK
 ja .reshape_shape
 test r14,r14
 jz .reshape_rank_zero
 test r15,r15
 jz .reshape_argument
 test r15,7
 jnz .reshape_argument
 mov r10,1
 xor ecx,ecx
.reshape_count:
 cmp rcx,r14
 jae .reshape_count_ready
 mov rax,[r15+rcx*8]
 cmp rax,NEBO_TENSOR_I64_PUBLIC_MAX_DIMENSION
 ja .reshape_shape
 imul r10,rax
 jo .reshape_shape
 cmp r10,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 ja .reshape_shape
 inc rcx
 jmp .reshape_count
.reshape_rank_zero:
 mov r10,1
.reshape_count_ready:
 cmp r10,[r12+NEBO_TENSOR_CAPACITY]
 jne .reshape_materialization
 mov [rsp],r10
 mov rsi,r12
 mov rdi,r13
 mov ecx,NEBO_TENSOR_SIZE/8
 rep movsq
 mov [r13+NEBO_TENSOR_RANK],r14
 xor ecx,ecx
.reshape_clear:
 cmp rcx,NEBO_TENSOR_MAX_RANK
 jae .reshape_strides
 mov qword [r13+NEBO_TENSOR_SHAPE+rcx*8],0
 mov qword [r13+NEBO_TENSOR_STRIDES+rcx*8],0
 inc rcx
 jmp .reshape_clear
.reshape_strides:
 mov rcx,r14
 mov r8,1
.reshape_axis:
 test rcx,rcx
 jz .reshape_publish
 dec rcx
 mov rax,[r15+rcx*8]
 mov [r13+NEBO_TENSOR_SHAPE+rcx*8],rax
 mov [r13+NEBO_TENSOR_STRIDES+rcx*8],r8
 imul r8,rax
 jmp .reshape_axis
.reshape_publish:
 mov rdi,r13
 call tensor_i64_publish_view_flags
 xor eax,eax
 jmp .reshape_done
.reshape_argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .reshape_done
.reshape_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .reshape_done
.reshape_materialization:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
.reshape_done:
 add rsp,8
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; owner rdi, destination rsi, axes pointer rdx, exact axes count rcx.
nebo_tensor_i64_permute_view:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .permute_done
 mov rdi,r12
 mov rsi,r13
 call tensor_i64_view_destination_plan
 test eax,eax
 jnz .permute_done
 cmp r15,[r12+NEBO_TENSOR_RANK]
 jne .permute_shape
 test r15,r15
 jz .permute_valid
 test r14,r14
 jz .permute_argument
 test r14,7
 jnz .permute_argument
 xor ebx,ebx
 xor r9d,r9d
.permute_check:
 cmp r9,r15
 jae .permute_valid
 mov rax,[r14+r9*8]
 cmp rax,r15
 jae .permute_bounds
 mov rdx,1
 mov rcx,rax
 shl rdx,cl
 test rbx,rdx
 jnz .permute_shape
 or rbx,rdx
 inc r9
 jmp .permute_check
.permute_valid:
 mov rsi,r12
 mov rdi,r13
 mov ecx,NEBO_TENSOR_SIZE/8
 rep movsq
 xor ecx,ecx
.permute_apply:
 cmp rcx,r15
 jae .permute_publish
 mov rax,[r14+rcx*8]
 mov rdx,[r12+NEBO_TENSOR_SHAPE+rax*8]
 mov [r13+NEBO_TENSOR_SHAPE+rcx*8],rdx
 mov rdx,[r12+NEBO_TENSOR_STRIDES+rax*8]
 mov [r13+NEBO_TENSOR_STRIDES+rcx*8],rdx
 inc rcx
 jmp .permute_apply
.permute_publish:
 mov rdi,r13
 call tensor_i64_publish_view_flags
 xor eax,eax
 jmp .permute_done
.permute_argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .permute_done
.permute_bounds:
 mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .permute_done
.permute_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
.permute_done:
 add rsp,8
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; Rank-2 transpose is exactly permutation [1,0].
nebo_tensor_i64_transpose_view:
 sub rsp,24
 mov qword [rsp],1
 mov qword [rsp+8],0
 cmp qword [rdi+NEBO_TENSOR_RANK],2
 jne .transpose_shape
 lea rdx,[rsp]
 mov ecx,2
 call nebo_tensor_i64_permute_view
 add rsp,24
 ret
.transpose_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 add rsp,24
 ret

; owner rdi, destination rsi, target rank rdx, target shape rcx.
nebo_tensor_i64_broadcast_view:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,24
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .broadcast_done
 mov rdi,r12
 mov rsi,r13
 call tensor_i64_view_destination_plan
 test eax,eax
 jnz .broadcast_done
 cmp r14,NEBO_TENSOR_I64_PUBLIC_MAX_RANK
 ja .broadcast_shape
 mov rax,[r12+NEBO_TENSOR_RANK]
 cmp r14,rax
 jb .broadcast_incompatible
 mov r10,1
 test r14,r14
 jz .broadcast_count_ready
 test r15,r15
 jz .broadcast_argument
 test r15,7
 jnz .broadcast_argument
 xor ecx,ecx
.broadcast_count:
 cmp rcx,r14
 jae .broadcast_count_ready
 mov rax,[r15+rcx*8]
 cmp rax,NEBO_TENSOR_I64_PUBLIC_MAX_DIMENSION
 ja .broadcast_shape
 imul r10,rax
 jo .broadcast_shape
 cmp r10,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 ja .broadcast_shape
 inc rcx
 jmp .broadcast_count
.broadcast_count_ready:
 mov [rsp+8],r10
 mov rax,[r12+NEBO_TENSOR_RANK]
 mov rbx,r14
 sub rbx,rax
 mov [rsp],rbx
 xor ecx,ecx
.broadcast_compat:
 cmp rcx,r14
 jae .broadcast_publish
 cmp rcx,rbx
 jb .broadcast_next
 mov rdx,rcx
 sub rdx,rbx
 mov rax,[r12+NEBO_TENSOR_SHAPE+rdx*8]
 cmp rax,[r15+rcx*8]
 je .broadcast_next
 cmp rax,1
 jne .broadcast_incompatible
.broadcast_next:
 inc rcx
 jmp .broadcast_compat
.broadcast_publish:
 mov rsi,r12
 mov rdi,r13
 mov ecx,NEBO_TENSOR_SIZE/8
 rep movsq
 mov [r13+NEBO_TENSOR_RANK],r14
 mov rax,[rsp+8]
 mov [r13+NEBO_TENSOR_CAPACITY],rax
 xor ecx,ecx
.broadcast_clear:
 cmp rcx,NEBO_TENSOR_MAX_RANK
 jae .broadcast_apply_start
 mov qword [r13+NEBO_TENSOR_SHAPE+rcx*8],0
 mov qword [r13+NEBO_TENSOR_STRIDES+rcx*8],0
 inc rcx
 jmp .broadcast_clear
.broadcast_apply_start:
 xor ecx,ecx
.broadcast_apply:
 cmp rcx,r14
 jae .broadcast_flags
 mov rax,[r15+rcx*8]
 mov [r13+NEBO_TENSOR_SHAPE+rcx*8],rax
 cmp rcx,rbx
 jb .broadcast_stride_zero
 mov rdx,rcx
 sub rdx,rbx
 cmp qword [r12+NEBO_TENSOR_SHAPE+rdx*8],1
 je .broadcast_stride_zero
 mov rax,[r12+NEBO_TENSOR_STRIDES+rdx*8]
 mov [r13+NEBO_TENSOR_STRIDES+rcx*8],rax
 jmp .broadcast_apply_next
.broadcast_stride_zero:
 mov qword [r13+NEBO_TENSOR_STRIDES+rcx*8],0
.broadcast_apply_next:
 inc rcx
 jmp .broadcast_apply
.broadcast_flags:
 mov rdi,r13
 call tensor_i64_publish_view_flags
 xor eax,eax
 jmp .broadcast_done
.broadcast_argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .broadcast_done
.broadcast_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .broadcast_done
.broadcast_incompatible:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
.broadcast_done:
 add rsp,24
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; rdi operand owner, rsi result rank, rdx result shape, rcx flat result index.
; Descriptors and broadcast compatibility are prevalidated by the caller.
tensor_i64_broadcast_load:
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov r11,r13
 sub r11,[r12+NEBO_TENSOR_RANK]
 xor r10d,r10d
 mov r9,r13
.load_axis:
 test r9,r9
 jz .load_value
 dec r9
 mov rax,r15
 xor edx,edx
 div qword [r14+r9*8]
 mov r15,rax
 cmp r9,r11
 jb .load_axis
 mov r8,r9
 sub r8,r11
 cmp qword [r12+NEBO_TENSOR_SHAPE+r8*8],1
 je .load_axis
 imul rdx,[r12+NEBO_TENSOR_STRIDES+r8*8]
 add r10,rdx
 jmp .load_axis
.load_value:
 mov rax,[r12+NEBO_TENSOR_DATA]
 mov rax,[rax+r10*8]
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; out descriptor rdi, out payload rsi, left owner rdx, right owner rcx,
; new storage identity r8. r9 selects add(0) or multiply(1).
tensor_i64_binary:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,72
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov [rsp],r9
 mov rdi,r14
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .binary_done
 mov rdi,r15
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .binary_done
 mov rax,[r14+NEBO_TENSOR_RANK]
 mov rdx,[r15+NEBO_TENSOR_RANK]
 cmp rax,rdx
 cmovb rax,rdx
 mov [rsp+32],rax
 xor r10d,r10d
.binary_shape_axis:
 cmp r10,[rsp+32]
 jae .binary_shape_ready
 ; Left dimension aligned to trailing axes; missing leading dimension is one.
 mov r8,[rsp+32]
 sub r8,[r14+NEBO_TENSOR_RANK]
 mov rax,1
 cmp r10,r8
 jb .binary_left_ready
 mov rdx,r10
 sub rdx,r8
 mov rax,[r14+NEBO_TENSOR_SHAPE+rdx*8]
.binary_left_ready:
 mov r9,rax
 ; Right dimension.
 mov r8,[rsp+32]
 sub r8,[r15+NEBO_TENSOR_RANK]
 mov rax,1
 cmp r10,r8
 jb .binary_right_ready
 mov rdx,r10
 sub rdx,r8
 mov rax,[r15+NEBO_TENSOR_SHAPE+rdx*8]
.binary_right_ready:
 cmp r9,rax
 je .binary_dimension
 cmp r9,1
 je .binary_dimension
 cmp rax,1
 jne .binary_incompatible
 mov rax,r9
.binary_dimension:
 mov [rsp+8+r10*8],rax
 inc r10
 jmp .binary_shape_axis
.binary_shape_ready:
 mov r10,1
 xor ecx,ecx
.binary_count:
 cmp rcx,[rsp+32]
 jae .binary_count_ready
 imul r10,[rsp+8+rcx*8]
 jo .binary_shape
 cmp r10,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 ja .binary_shape
 inc rcx
 jmp .binary_count
.binary_count_ready:
 mov [rsp+40],r10
 mov rdi,r12
 mov rsi,r13
 mov edx,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 mov rcx,[rsp+32]
 lea r8,[rsp+8]
 mov r9,rbx
 call tensor_i64_owner_plan
 test eax,eax
 jnz .binary_done
 mov rdi,r12
 mov rsi,r13
 mov rdx,[rsp+40]
 mov rcx,r14
 call tensor_i64_output_nonoverlap
 test eax,eax
 jnz .binary_done
 mov rdi,r12
 mov rsi,r13
 mov rdx,[rsp+40]
 mov rcx,r15
 call tensor_i64_output_nonoverlap
 test eax,eax
 jnz .binary_done
 ; Pass one: full arithmetic overflow preflight, zero result writes.
 mov qword [rsp+56],0
.binary_preflight:
 mov rcx,[rsp+56]
 cmp rcx,[rsp+40]
 jae .binary_commit_start
 mov rdi,r14
 mov rsi,[rsp+32]
 lea rdx,[rsp+8]
 call tensor_i64_broadcast_load
 mov [rsp+48],rax
 mov rdi,r15
 mov rsi,[rsp+32]
 lea rdx,[rsp+8]
 mov rcx,[rsp+56]
 call tensor_i64_broadcast_load
 mov r10,[rsp+48]
 cmp qword [rsp],0
 jne .binary_preflight_multiply
 add r10,rax
 jo .binary_overflow
 jmp .binary_preflight_next
.binary_preflight_multiply:
 imul r10,rax
 jo .binary_overflow
.binary_preflight_next:
 inc qword [rsp+56]
 jmp .binary_preflight
.binary_commit_start:
 mov qword [rsp+56],0
.binary_commit:
 mov rcx,[rsp+56]
 cmp rcx,[rsp+40]
 jae .binary_publish
 mov rdi,r14
 mov rsi,[rsp+32]
 lea rdx,[rsp+8]
 call tensor_i64_broadcast_load
 mov [rsp+48],rax
 mov rdi,r15
 mov rsi,[rsp+32]
 lea rdx,[rsp+8]
 mov rcx,[rsp+56]
 call tensor_i64_broadcast_load
 mov r10,[rsp+48]
 cmp qword [rsp],0
 jne .binary_commit_multiply
 add r10,rax
 jmp .binary_store
.binary_commit_multiply:
 imul r10,rax
.binary_store:
 mov rcx,[rsp+56]
 mov [r13+rcx*8],r10
 inc qword [rsp+56]
 jmp .binary_commit
.binary_publish:
 mov rdi,r12
 mov rsi,r13
 mov edx,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 mov rcx,[rsp+32]
 lea r8,[rsp+8]
 mov r9,rbx
 call nebo_tensor_i64_owner_init
 jmp .binary_done
.binary_incompatible:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .binary_done
.binary_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .binary_done
.binary_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .binary_done
.binary_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
.binary_done:
 add rsp,72
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

nebo_tensor_i64_add:
 xor r9d,r9d
 jmp tensor_i64_binary

nebo_tensor_i64_multiply:
 mov r9d,1
 jmp tensor_i64_binary

; rdi owner, rsi reduced-axis bitmask, rdx keepDimensions, rcx output flat.
; Returns one checked sum in RAX and status in EDX.
tensor_i64_reduce_sum_value:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,24
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 xor ebx,ebx
 xor r9d,r9d
.reduce_input:
 cmp r9,[r12+NEBO_TENSOR_CAPACITY]
 jae .reduce_ok
 mov rax,r9
 mov rcx,[r12+NEBO_TENSOR_RANK]
.reduce_coordinates:
 test rcx,rcx
 jz .reduce_output_index
 dec rcx
 xor edx,edx
 div qword [r12+NEBO_TENSOR_SHAPE+rcx*8]
 mov [rsp+rcx*8],rdx
 jmp .reduce_coordinates
.reduce_output_index:
 xor r10d,r10d
 xor ecx,ecx
.reduce_map:
 cmp rcx,[r12+NEBO_TENSOR_RANK]
 jae .reduce_match
 bt r13,rcx
 jc .reduce_map_next
 imul r10,[r12+NEBO_TENSOR_SHAPE+rcx*8]
 add r10,[rsp+rcx*8]
.reduce_map_next:
 inc rcx
 jmp .reduce_map
.reduce_match:
 cmp r10,r15
 jne .reduce_input_next
 mov rax,[r12+NEBO_TENSOR_DATA]
 add rbx,[rax+r9*8]
 jo .reduce_overflow
.reduce_input_next:
 inc r9
 jmp .reduce_input
.reduce_ok:
 mov rax,rbx
 xor edx,edx
 jmp .reduce_done
.reduce_overflow:
 xor eax,eax
 mov edx,NEBO_NUMERIC_ERROR_OVERFLOW
.reduce_done:
 add rsp,24
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; out descriptor rdi, out payload rsi, input owner rdx, axes rcx,
; axis count r8, keepDimensions r9, storage identity stack arg 7.
nebo_tensor_i64_sum_axes:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,72
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov [rsp],r9
 mov rax,[rsp+120]
 mov [rsp+64],rax
 cmp qword [rsp],1
 ja .sum_argument
 mov rdi,r14
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .sum_done
 test rbx,rbx
 jz .sum_shape
 cmp rbx,[r14+NEBO_TENSOR_RANK]
 ja .sum_shape
 test r15,r15
 jz .sum_argument
 test r15,7
 jnz .sum_argument
 xor r10d,r10d
 xor ecx,ecx
.sum_axes_check:
 cmp rcx,rbx
 jae .sum_axes_ready
 mov rax,[r15+rcx*8]
 cmp rax,[r14+NEBO_TENSOR_RANK]
 jae .sum_bounds
 bt r10,rax
 jc .sum_shape
 bts r10,rax
 inc rcx
 jmp .sum_axes_check
.sum_axes_ready:
 mov [rsp+8],r10
 mov rax,[r14+NEBO_TENSOR_RANK]
 cmp qword [rsp],0
 jne .sum_keep_rank
 sub rax,rbx
.sum_keep_rank:
 mov [rsp+16],rax
 xor r8d,r8d
 xor ecx,ecx
.sum_shape_build:
 cmp rcx,[r14+NEBO_TENSOR_RANK]
 jae .sum_shape_ready
 bt r10,rcx
 jnc .sum_shape_copy
 cmp qword [rsp],0
 je .sum_shape_next
 mov qword [rsp+24+r8*8],1
 inc r8
 jmp .sum_shape_next
.sum_shape_copy:
 mov rax,[r14+NEBO_TENSOR_SHAPE+rcx*8]
 mov [rsp+24+r8*8],rax
 inc r8
.sum_shape_next:
 inc rcx
 jmp .sum_shape_build
.sum_shape_ready:
 mov r10,1
 xor ecx,ecx
.sum_count:
 cmp rcx,[rsp+16]
 jae .sum_count_ready
 imul r10,[rsp+24+rcx*8]
 inc rcx
 jmp .sum_count
.sum_count_ready:
 mov [rsp+48],r10
 cmp r12,r14
 je .sum_alias
 cmp r13,[r14+NEBO_TENSOR_DATA]
 je .sum_alias
 mov rdi,r12
 mov rsi,r13
 mov edx,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 mov rcx,[rsp+16]
 lea r8,[rsp+24]
 mov r9,[rsp+64]
 call tensor_i64_owner_plan
 test eax,eax
 jnz .sum_done
 mov rdi,r12
 mov rsi,r13
 mov rdx,[rsp+48]
 mov rcx,r14
 call tensor_i64_output_nonoverlap
 test eax,eax
 jnz .sum_done
 mov qword [rsp+56],0
.sum_preflight:
 mov rcx,[rsp+56]
 cmp rcx,[rsp+48]
 jae .sum_commit_start
 mov rdi,r14
 mov rsi,[rsp+8]
 mov rdx,[rsp]
 call tensor_i64_reduce_sum_value
 test edx,edx
 jnz .sum_overflow
 inc qword [rsp+56]
 jmp .sum_preflight
.sum_commit_start:
 mov qword [rsp+56],0
.sum_commit:
 mov rcx,[rsp+56]
 cmp rcx,[rsp+48]
 jae .sum_publish
 mov rdi,r14
 mov rsi,[rsp+8]
 mov rdx,[rsp]
 call tensor_i64_reduce_sum_value
 mov rcx,[rsp+56]
 mov [r13+rcx*8],rax
 inc qword [rsp+56]
 jmp .sum_commit
.sum_publish:
 mov rdi,r12
 mov rsi,r13
 mov edx,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 mov rcx,[rsp+16]
 lea r8,[rsp+24]
 mov r9,[rsp+64]
 call nebo_tensor_i64_owner_init
 jmp .sum_done
.sum_argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .sum_done
.sum_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .sum_done
.sum_bounds:
 mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .sum_done
.sum_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .sum_done
.sum_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
.sum_done:
 add rsp,72
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; Scalar total sum: RAX value, EDX status. Empty total is zero.
nebo_tensor_i64_sum_all:
 push r12
 mov r12,rdi
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .sum_all_error
 xor ecx,ecx
 xor eax,eax
 mov rsi,[r12+NEBO_TENSOR_DATA]
.sum_all_loop:
 cmp rcx,[r12+NEBO_TENSOR_CAPACITY]
 jae .sum_all_ok
 add rax,[rsi+rcx*8]
 jo .sum_all_overflow
 inc rcx
 jmp .sum_all_loop
.sum_all_ok:
 xor edx,edx
 pop r12
 ret
.sum_all_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
.sum_all_error:
 mov edx,eax
 xor eax,eax
 pop r12
 ret

; rdi owner, rsi selector (0=min, 1=max). RAX value, EDX status.
tensor_i64_extreme:
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .extreme_error
 mov rcx,[r12+NEBO_TENSOR_CAPACITY]
 test rcx,rcx
 jz .extreme_empty
 mov rdx,[r12+NEBO_TENSOR_DATA]
 mov rax,[rdx]
 mov r8,1
.extreme_loop:
 cmp r8,rcx
 jae .extreme_ok
 mov r9,[rdx+r8*8]
 test r13,r13
 jnz .extreme_max
 cmp r9,rax
 cmovl rax,r9
 jmp .extreme_next
.extreme_max:
 cmp r9,rax
 cmovg rax,r9
.extreme_next:
 inc r8
 jmp .extreme_loop
.extreme_ok:
 xor edx,edx
 pop r13
 pop r12
 ret
.extreme_empty:
 mov eax,NEBO_NUMERIC_ERROR_DOMAIN
.extreme_error:
 mov edx,eax
 xor eax,eax
 pop r13
 pop r12
 ret

nebo_tensor_i64_min:
 xor esi,esi
 jmp tensor_i64_extreme

nebo_tensor_i64_max:
 mov esi,1
 jmp tensor_i64_extreme

; rdi output descriptor, rsi output payload, rdx output logical elements,
; rcx authenticated operand owner. Reject every descriptor/payload overlap.
tensor_i64_output_nonoverlap:
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov r8,r12
 add r8,NEBO_TENSOR_SIZE
 jc .nonoverlap_overflow
 mov r9,r15
 add r9,NEBO_TENSOR_SIZE
 jc .nonoverlap_overflow
 cmp r12,r9
 jae .nonoverlap_output_payload
 cmp r15,r8
 jb .nonoverlap_alias
.nonoverlap_output_payload:
 mov r10,r14
 shl r10,3
 jc .nonoverlap_overflow
 mov r11,r13
 add r11,r10
 jc .nonoverlap_overflow
 cmp r13,r9
 jae .nonoverlap_operand_payload
 cmp r15,r11
 jb .nonoverlap_alias
.nonoverlap_operand_payload:
 mov r8,[r15+NEBO_TENSOR_DATA]
 mov r9,[r15+NEBO_TENSOR_CAPACITY]
 shl r9,3
 jc .nonoverlap_overflow
 add r9,r8
 jc .nonoverlap_overflow
 mov r10,r12
 add r10,NEBO_TENSOR_SIZE
 jc .nonoverlap_overflow
 cmp r12,r9
 jae .nonoverlap_payload_payload
 cmp r8,r10
 jb .nonoverlap_alias
.nonoverlap_payload_payload:
 mov r10,r14
 shl r10,3
 mov r11,r13
 add r11,r10
 jc .nonoverlap_overflow
 cmp r13,r9
 jae .nonoverlap_ok
 cmp r8,r11
 jb .nonoverlap_alias
.nonoverlap_ok:
 xor eax,eax
 jmp .nonoverlap_done
.nonoverlap_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .nonoverlap_done
.nonoverlap_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
.nonoverlap_done:
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; out descriptor rdi, out payload rsi, input descriptor rdx,
; live owner rcx, fresh storage identity r8.
nebo_tensor_i64_contiguous:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 cmp r14,r15
 jne .contiguous_view
 mov rdi,r15
 call nebo_tensor_i64_owner_validate
 jmp .contiguous_validated
.contiguous_view:
 mov rdi,r14
 mov rsi,r15
 call nebo_tensor_i64_view_validate_owner
.contiguous_validated:
 test eax,eax
 jnz .contiguous_done
 mov rdi,r12
 mov rsi,r13
 mov edx,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 mov rcx,[r14+NEBO_TENSOR_RANK]
 lea r8,[r14+NEBO_TENSOR_SHAPE]
 mov r9,rbx
 call tensor_i64_owner_plan
 test eax,eax
 jnz .contiguous_done
 mov rdi,r12
 mov rsi,r13
 mov rdx,[r14+NEBO_TENSOR_CAPACITY]
 mov rcx,r15
 call tensor_i64_output_nonoverlap
 test eax,eax
 jnz .contiguous_done
 mov qword [rsp],0
.contiguous_copy:
 mov rcx,[rsp]
 cmp rcx,[r14+NEBO_TENSOR_CAPACITY]
 jae .contiguous_publish
 mov rdi,r14
 mov rsi,[r14+NEBO_TENSOR_RANK]
 lea rdx,[r14+NEBO_TENSOR_SHAPE]
 call tensor_i64_broadcast_load
 mov rcx,[rsp]
 mov [r13+rcx*8],rax
 inc qword [rsp]
 jmp .contiguous_copy
.contiguous_publish:
 mov rdi,r12
 mov rsi,r13
 mov edx,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 mov rcx,[r14+NEBO_TENSOR_RANK]
 lea r8,[r14+NEBO_TENSOR_SHAPE]
 mov r9,rbx
 call nebo_tensor_i64_owner_init
.contiguous_done:
 add rsp,8
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; One borrowed descriptor pointer. Snapshot 168 descriptor bytes exactly once;
; payload remains borrowed and is never copied or retained. RAX value, EDX status.
nebo_tensor_i64_borrow_sum:
 push r12
 sub rsp,176
 mov r12,rsp
 test rdi,rdi
 jz .borrow_argument
 test rdi,7
 jnz .borrow_argument
 mov rsi,rdi
 mov rdi,r12
 mov ecx,NEBO_TENSOR_SIZE/8
 rep movsq
 mov rdi,r12
 call nebo_tensor_i64_sum_all
 add rsp,176
 pop r12
 ret
.borrow_argument:
 xor eax,eax
 mov edx,NEBO_NUMERIC_ERROR_ARGUMENT
 add rsp,176
 pop r12
 ret

; Hidden sret descriptor RDI, explicit fixed payload RSI, then rank RDX,
; shape RCX, fill value R8 and fresh storage identity R9.
; Success returns the identical sret pointer in RAX with EDX=0.
nebo_tensor_i64_sret_filled:
 push r12
 push r13
 push r14
 push r15
 push rbx
 mov r12,rdi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 mov rbx,r9
 push r15
 mov edx,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 mov rcx,r13
 mov r8,r14
 mov r9,rbx
 call nebo_tensor_i64_filled
 add rsp,8
 test eax,eax
 jnz .sret_error
 mov rax,r12
 xor edx,edx
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.sret_error:
 mov edx,eax
 xor eax,eax
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret
; Validate the exact selected public owner identity.
nebo_tensor_i64_owner_validate:
 push r12
 push r13
 mov r12,rdi
 call nebo_tensor_validate
 test eax,eax
 jnz .done
 cmp qword [r12+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_I64
 jne .contract
 cmp qword [r12+NEBO_TENSOR_DEVICE],NEBO_TENSOR_DEVICE_CPU
 jne .contract
 mov r13,[r12+NEBO_TENSOR_RANK]
 cmp r13,NEBO_TENSOR_I64_PUBLIC_MAX_RANK
 ja .shape
 cmp qword [r12+NEBO_TENSOR_STORAGE_ID],0
 je .contract
 cmp qword [r12+NEBO_TENSOR_GENERATION],0
 je .contract
 cmp qword [r12+NEBO_TENSOR_FLAGS],NEBO_TENSOR_I64_PUBLIC_OWNER_FLAGS
 jne .contract
 mov rcx,r13
.unused:
 cmp rcx,NEBO_TENSOR_MAX_RANK
 jae .active
 cmp qword [r12+NEBO_TENSOR_SHAPE+rcx*8],0
 jne .contract
 cmp qword [r12+NEBO_TENSOR_STRIDES+rcx*8],0
 jne .contract
 inc rcx
 jmp .unused
.active:
 xor ecx,ecx
 mov r8,1
.dimension:
 cmp rcx,r13
 jae .count
 mov rax,[r12+NEBO_TENSOR_SHAPE+rcx*8]
 cmp rax,NEBO_TENSOR_I64_PUBLIC_MAX_DIMENSION
 ja .shape
 imul r8,rax
 jo .shape
 cmp r8,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 ja .shape
 inc rcx
 jmp .dimension
.count:
 cmp r8,[r12+NEBO_TENSOR_CAPACITY]
 jne .shape
 cmp r8,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 ja .shape
 test r8,r8
 jz .valid
 mov rsi,[r12+NEBO_TENSOR_DATA]
 test rsi,rsi
 jz .argument
 test rsi,7
 jnz .argument
 mov rax,r12
 add rax,NEBO_TENSOR_SIZE
 jc .shape
 mov rdx,r8
 shl rdx,3
 jc .shape
 mov rcx,rsi
 add rcx,rdx
 jc .shape
 cmp r12,rcx
 jae .valid
 cmp rsi,rax
 jae .valid
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .done
.valid:
 xor eax,eax
 jmp .done
.argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .done
.contract:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .done
.shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
.done:
 pop r13
 pop r12
 ret

; Logical cleanup: invalidate once without freeing caller-owned payload.
nebo_tensor_i64_owner_invalidate:
 push r12
 mov r12,rdi
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .done
 mov rdx,[r12+NEBO_TENSOR_GENERATION]
 inc rdx
 jz .overflow
 mov rdi,r12
 mov rcx,NEBO_TENSOR_SIZE/8
 xor eax,eax
 rep stosq
 mov [r12+NEBO_TENSOR_GENERATION],rdx
 xor eax,eax
 jmp .done
.overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
.done:
 pop r12
 ret

; Validated metadata queries return the value in RAX and status in EDX.
nebo_tensor_i64_rank:
 push r12
 mov r12,rdi
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .rank_error
 mov rax,[r12+NEBO_TENSOR_RANK]
 xor edx,edx
 pop r12
 ret
.rank_error:
 mov edx,eax
 xor eax,eax
 pop r12
 ret

; rdi owner, rsi axis.
nebo_tensor_i64_dimension:
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .dimension_error
 cmp r13,[r12+NEBO_TENSOR_RANK]
 jae .dimension_bounds
 mov rax,[r12+NEBO_TENSOR_SHAPE+r13*8]
 xor edx,edx
 pop r13
 pop r12
 ret
.dimension_bounds:
 xor eax,eax
 mov edx,NEBO_NUMERIC_ERROR_BOUNDS
 pop r13
 pop r12
 ret
.dimension_error:
 mov edx,eax
 xor eax,eax
 pop r13
 pop r12
 ret

nebo_tensor_i64_element_count:
 push r12
 mov r12,rdi
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .count_error
 mov rax,[r12+NEBO_TENSOR_CAPACITY]
 xor edx,edx
 pop r12
 ret
.count_error:
 mov edx,eax
 xor eax,eax
 pop r12
 ret

; rdi owner, rsi axis. Strides are measured in elements.
nebo_tensor_i64_stride:
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .stride_error
 cmp r13,[r12+NEBO_TENSOR_RANK]
 jae .stride_bounds
 mov rax,[r12+NEBO_TENSOR_STRIDES+r13*8]
 xor edx,edx
 pop r13
 pop r12
 ret
.stride_bounds:
 xor eax,eax
 mov edx,NEBO_NUMERIC_ERROR_BOUNDS
 pop r13
 pop r12
 ret
.stride_error:
 mov edx,eax
 xor eax,eax
 pop r13
 pop r12
 ret

; Compute contiguity from active shape/strides; never trust the flag alone.
; rdi owner -> eax bool, edx status.
nebo_tensor_i64_is_contiguous:
 push r12
 mov r12,rdi
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .contiguous_error
 mov rcx,[r12+NEBO_TENSOR_RANK]
 mov r8,1
.contiguous_axis:
 test rcx,rcx
 jz .contiguous_yes
 dec rcx
 cmp [r12+NEBO_TENSOR_STRIDES+rcx*8],r8
 jne .contiguous_no
 imul r8,[r12+NEBO_TENSOR_SHAPE+rcx*8]
 jo .contiguous_contract
 jmp .contiguous_axis
.contiguous_yes:
 mov eax,1
 xor edx,edx
 pop r12
 ret
.contiguous_no:
 xor eax,eax
 xor edx,edx
 pop r12
 ret
.contiguous_contract:
 xor eax,eax
 mov edx,NEBO_NUMERIC_ERROR_CONTRACT
 pop r12
 ret
.contiguous_error:
 mov edx,eax
 xor eax,eax
 pop r12
 ret

; Canonical owner descriptor -> status EAX, exact NBT1 bytes RDX.
nebo_tensor_i64_serialized_size:
 push r12
 mov r12,rdi
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .tensor_size_done
 test qword [r12+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_OWNED
 jz .tensor_size_contract
 test qword [r12+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_CONTIGUOUS
 jz .tensor_size_contract
 mov rdx,[r12+NEBO_TENSOR_CAPACITY]
 shl rdx,3
 add rdx,NEBO_TENSOR_I64_NBT1_HEADER_BYTES
 xor eax,eax
.tensor_size_done:
 pop r12
 ret
.tensor_size_contract:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .tensor_size_done

; Descriptor, output bytes, output capacity -> status EAX, written bytes RDX.
; The wire representation is explicitly little-endian on the selected x86_64
; target and never aliases its descriptor or caller payload.
nebo_tensor_i64_serialize:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call nebo_tensor_i64_serialized_size
 test eax,eax
 jnz .tensor_serialize_done
 test r13,r13
 jz .tensor_serialize_argument
 cmp r14,rdx
 jb .tensor_serialize_workspace
 mov rax,r13
 add rax,rdx
 jc .tensor_serialize_overflow
 cmp r13,r12
 jae .tensor_serialize_descriptor_after
 cmp rax,r12
 ja .tensor_serialize_alias
 jmp .tensor_serialize_payload
.tensor_serialize_descriptor_after:
 lea rcx,[r12+NEBO_TENSOR_SIZE]
 cmp r13,rcx
 jb .tensor_serialize_alias
.tensor_serialize_payload:
 mov rcx,[r12+NEBO_TENSOR_DATA]
 mov r8,[r12+NEBO_TENSOR_CAPACITY]
 shl r8,3
 add r8,rcx
 jc .tensor_serialize_overflow
 cmp r13,rcx
 jae .tensor_serialize_payload_after
 cmp rax,rcx
 ja .tensor_serialize_alias
 jmp .tensor_serialize_write
.tensor_serialize_payload_after:
 cmp r13,r8
 jb .tensor_serialize_alias
.tensor_serialize_write:
 mov dword [r13],0x3154424e
 mov word [r13+4],1
 mov word [r13+6],0
 mov qword [r13+8],NEBO_TENSOR_DTYPE_I64
 mov qword [r13+16],NEBO_TENSOR_DEVICE_CPU
 mov rax,[r12+NEBO_TENSOR_RANK]
 mov [r13+24],rax
 xor ecx,ecx
.tensor_serialize_shape:
 cmp ecx,NEBO_TENSOR_MAX_RANK
 jae .tensor_serialize_count
 mov rax,[r12+NEBO_TENSOR_SHAPE+rcx*8]
 mov [r13+32+rcx*8],rax
 mov rax,[r12+NEBO_TENSOR_STRIDES+rcx*8]
 mov [r13+80+rcx*8],rax
 inc ecx
 jmp .tensor_serialize_shape
.tensor_serialize_count:
 mov rax,[r12+NEBO_TENSOR_CAPACITY]
 mov [r13+128],rax
 mov rcx,rax
 shl rax,3
 mov [r13+136],rax
 mov rsi,[r12+NEBO_TENSOR_DATA]
 lea rdi,[r13+NEBO_TENSOR_I64_NBT1_HEADER_BYTES]
 rep movsq
 mov rdx,[r13+136]
 add rdx,NEBO_TENSOR_I64_NBT1_HEADER_BYTES
 xor eax,eax
 jmp .tensor_serialize_done
.tensor_serialize_argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .tensor_serialize_done
.tensor_serialize_workspace:
 mov eax,NEBO_NUMERIC_ERROR_WORKSPACE
 jmp .tensor_serialize_done
.tensor_serialize_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .tensor_serialize_done
.tensor_serialize_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
.tensor_serialize_done:
 pop r14
 pop r13
 pop r12
 ret

; Destination descriptor, 512-byte destination payload, exact NBT1 bytes,
; byte length, and fresh storage identity. Every wire and alias gate completes
; before the existing explicit-copy constructor publishes one owner.
nebo_tensor_i64_deserialize:
 push r12
 push r13
 push r14
 push r15
 push rbx
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 test r14,r14
 jz .tensor_deserialize_argument
 cmp r15,NEBO_TENSOR_I64_NBT1_HEADER_BYTES
 jb .tensor_deserialize_contract
 cmp dword [r14],0x3154424e
 jne .tensor_deserialize_contract
 cmp word [r14+4],1
 jne .tensor_deserialize_contract
 cmp word [r14+6],0
 jne .tensor_deserialize_contract
 cmp qword [r14+8],NEBO_TENSOR_DTYPE_I64
 jne .tensor_deserialize_contract
 cmp qword [r14+16],NEBO_TENSOR_DEVICE_CPU
 jne .tensor_deserialize_contract
 mov rcx,[r14+24]
 cmp rcx,NEBO_TENSOR_I64_PUBLIC_MAX_RANK
 ja .tensor_deserialize_shape
 mov r10,1
 mov r11,rcx
.tensor_deserialize_active:
 test r11,r11
 jz .tensor_deserialize_unused
 dec r11
 mov rax,[r14+32+r11*8]
 cmp rax,NEBO_TENSOR_I64_PUBLIC_MAX_DIMENSION
 ja .tensor_deserialize_shape
 cmp [r14+80+r11*8],r10
 jne .tensor_deserialize_contract
 imul r10,rax
 jo .tensor_deserialize_overflow
 cmp r10,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 ja .tensor_deserialize_shape
 jmp .tensor_deserialize_active
.tensor_deserialize_unused:
 mov r11,rcx
.tensor_deserialize_unused_loop:
 cmp r11,NEBO_TENSOR_MAX_RANK
 jae .tensor_deserialize_lengths
 cmp qword [r14+32+r11*8],0
 jne .tensor_deserialize_contract
 cmp qword [r14+80+r11*8],0
 jne .tensor_deserialize_contract
 inc r11
 jmp .tensor_deserialize_unused_loop
.tensor_deserialize_lengths:
 cmp r10,[r14+128]
 jne .tensor_deserialize_contract
 mov rax,r10
 shl rax,3
 jc .tensor_deserialize_overflow
 cmp rax,[r14+136]
 jne .tensor_deserialize_contract
 add rax,NEBO_TENSOR_I64_NBT1_HEADER_BYTES
 jc .tensor_deserialize_overflow
 cmp rax,r15
 jne .tensor_deserialize_contract
 mov rdx,r14
 add rdx,r15
 jc .tensor_deserialize_overflow
 cmp r12,rdx
 jae .tensor_deserialize_descriptor_ok
 lea rax,[r12+NEBO_TENSOR_SIZE]
 cmp r14,rax
 jb .tensor_deserialize_alias
.tensor_deserialize_descriptor_ok:
 mov rax,r13
 add rax,NEBO_TENSOR_I64_PUBLIC_MAX_BYTES
 jc .tensor_deserialize_overflow
 cmp r13,rdx
 jae .tensor_deserialize_publish
 cmp r14,rax
 jb .tensor_deserialize_alias
.tensor_deserialize_publish:
 mov rcx,[r14+128]
 push rcx
 lea rax,[r14+NEBO_TENSOR_I64_NBT1_HEADER_BYTES]
 push rax
 mov rdi,r12
 mov rsi,r13
 mov edx,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 mov rcx,[r14+24]
 lea r8,[r14+32]
 mov r9,rbx
 call nebo_tensor_i64_from_buffer
 add rsp,16
 jmp .tensor_deserialize_done
.tensor_deserialize_argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .tensor_deserialize_done
.tensor_deserialize_contract:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .tensor_deserialize_done
.tensor_deserialize_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .tensor_deserialize_done
.tensor_deserialize_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .tensor_deserialize_done
.tensor_deserialize_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
.tensor_deserialize_done:
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; Stable no-I/O adapter. Success returns rank RDX, active dimensions (or zero)
; in RCX/R8/R9, logical element count R10 and contiguous-layout tag 1 in R11.
nebo_tensor_i64_headless_shape:
 push r12
 mov r12,rdi
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .tensor_headless_done
 mov rdx,[r12+NEBO_TENSOR_RANK]
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 test rdx,rdx
 jz .tensor_headless_count
 mov rcx,[r12+NEBO_TENSOR_SHAPE]
 cmp rdx,1
 je .tensor_headless_count
 mov r8,[r12+NEBO_TENSOR_SHAPE+8]
 cmp rdx,2
 je .tensor_headless_count
 mov r9,[r12+NEBO_TENSOR_SHAPE+16]
.tensor_headless_count:
 mov r10,[r12+NEBO_TENSOR_CAPACITY]
 mov r11d,1
 xor eax,eax
.tensor_headless_done:
 pop r12
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
