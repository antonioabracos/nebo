; CALL-E-COMPORTAMENTOS-DE-CHAMADA-F05 deterministic Float64 axis reductions over strided Tensors.
bits 64
default rel
%define NEBO_TENSOR_AXIS_REDUCE_IMPLEMENTATION 1
%include "runtime/tensor/tensor_axis_reduce.inc"
section .rodata
align 8
positive_infinity dq 0x7ff0000000000000
negative_infinity dq 0xfff0000000000000
section .text
global nebo_tensor_reduce_axes_f64
global nebo_tensor_argmax_axis_f64
global nebo_tensor_all_axis_bool
global nebo_tensor_any_axis_bool

; outDesc rdi, outData rsi, src rdx, axes rcx, axisCount r8, op r9,
; stack: keepDims, storageId. Axes are non-negative, unique and unordered.
nebo_tensor_reduce_axes_f64:
 push rbp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,128
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 mov ebx,r9d
 mov rdi,r14
 call nebo_tensor_validate
 test eax,eax
 jnz .ret
 cmp qword [r14+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_F64
 jne .contract
 cmp ebx,NEBO_TENSOR_REDUCE_SUM
 jb .contract
 cmp ebx,NEBO_TENSOR_REDUCE_MAX
 ja .contract
 test r15,r15
 jz .argument
 test rbp,rbp
 jz .bounds
 mov rax,[r14+NEBO_TENSOR_RANK]
 cmp rbp,rax
 ja .bounds
 ; Build a reduction-axis bit mask, rejecting negative/out-of-range/duplicate.
 xor r10d,r10d
 xor r11d,r11d
.axis_check:
 cmp r10,rbp
 jae .shape_build
 mov rax,[r15+r10*8]
 test rax,rax
 js .bounds
 cmp rax,[r14+NEBO_TENSOR_RANK]
 jae .bounds
 mov rdx,1
 mov cl,al
 shl rdx,cl
 test r11,rdx
 jnz .bounds
 or r11,rdx
 inc r10
 jmp .axis_check
.shape_build:
 mov [rsp+96],r11
 mov qword [rsp+104],1
 mov qword [rsp+112],0
 xor r10d,r10d
 mov r8,[rsp+184]
.shape_axis:
 cmp r10,[r14+NEBO_TENSOR_RANK]
 jae .source_count
 mov rax,[r14+NEBO_TENSOR_SHAPE+r10*8]
 test rax,rax
 jz .domain
 mov rdx,1
 mov cl,r10b
 shl rdx,cl
 test r11,rdx
 jz .shape_keep
 mov rdx,[rsp+104]
 imul rdx,rax
 mov [rsp+104],rdx
 test r8,r8
 jz .shape_next
 mov rcx,[rsp+112]
 mov qword [rsp+rcx*8],1
 inc qword [rsp+112]
 jmp .shape_next
.shape_keep:
 mov rcx,[rsp+112]
 mov [rsp+rcx*8],rax
 inc qword [rsp+112]
.shape_next:
 inc r10
 jmp .shape_axis
.source_count:
 mov rdi,r14
 call nebo_tensor_element_count
 test edx,edx
 jnz .shape
 mov [rsp+120],rax
 test rax,rax
 jz .domain
 ; Reject exact output/source alias before any mutation.
 cmp r13,[r14+NEBO_TENSOR_DATA]
 je .alias
 ; Preflight every logical source value: NaN and infinity are refused.
 xor r10d,r10d
.finite_each:
 cmp r10,[rsp+120]
 jae .init_output
 mov rax,r10
 xor r8d,r8d
 mov rcx,[r14+NEBO_TENSOR_RANK]
.finite_offset:
 test rcx,rcx
 jz .finite_value
 dec rcx
 xor edx,edx
 div qword [r14+NEBO_TENSOR_SHAPE+rcx*8]
 imul rdx,[r14+NEBO_TENSOR_STRIDES+rcx*8]
 add r8,rdx
 jmp .finite_offset
.finite_value:
 mov rdx,[r14+NEBO_TENSOR_DATA]
 mov rax,[rdx+r8*8]
 mov rdx,rax
 shr rdx,52
 and edx,0x7ff
 cmp edx,0x7ff
 je .domain
 inc r10
 jmp .finite_each
.init_output:
 mov rdi,r12
 mov rsi,r13
 mov rdx,[rsp+112]
 lea rcx,[rsp]
 mov r8d,NEBO_TENSOR_DTYPE_F64
 mov r9,[rsp+192]
 call nebo_tensor_init_owned
 test eax,eax
 jnz .ret
 mov rcx,[r12+NEBO_TENSOR_CAPACITY]
 xor r10d,r10d
 cmp ebx,NEBO_TENSOR_REDUCE_MIN
 je .seed_min
 cmp ebx,NEBO_TENSOR_REDUCE_MAX
 je .seed_max
 pxor xmm0,xmm0
 jmp .seed_each
.seed_min: movsd xmm0,[rel positive_infinity]
 jmp .seed_each
.seed_max: movsd xmm0,[rel negative_infinity]
.seed_each:
 cmp r10,rcx
 jae .source_each_start
 movsd [r13+r10*8],xmm0
 inc r10
 jmp .seed_each
.source_each_start:
 xor r10d,r10d
.source_each:
 cmp r10,[rsp+120]
 jae .finish
 mov rax,r10
 xor r8d,r8d
 xor r9d,r9d
 mov r11,1
 mov rcx,[r14+NEBO_TENSOR_RANK]
.map_axis:
 test rcx,rcx
 jz .apply
 dec rcx
 xor edx,edx
 div qword [r14+NEBO_TENSOR_SHAPE+rcx*8]
 mov rsi,rdx
 imul rdx,[r14+NEBO_TENSOR_STRIDES+rcx*8]
 add r8,rdx
 mov rdx,1
 push rcx
 mov cl,cl
 shl rdx,cl
 pop rcx
 test [rsp+96],rdx
 jnz .map_axis
 imul rsi,r11
 add r9,rsi
 imul r11,[r14+NEBO_TENSOR_SHAPE+rcx*8]
 jmp .map_axis
.apply:
 mov rdx,[r14+NEBO_TENSOR_DATA]
 movsd xmm0,[rdx+r8*8]
 movsd xmm1,[r13+r9*8]
 cmp ebx,NEBO_TENSOR_REDUCE_SUM
 je .add
 cmp ebx,NEBO_TENSOR_REDUCE_MEAN
 je .add
 cmp ebx,NEBO_TENSOR_REDUCE_MIN
 je .minimum
 ucomisd xmm0,xmm1
 jbe .next_source
 movsd [r13+r9*8],xmm0
 jmp .next_source
.minimum:
 ucomisd xmm0,xmm1
 jae .next_source
 movsd [r13+r9*8],xmm0
 jmp .next_source
.add:
 addsd xmm1,xmm0
 movq rax,xmm1
 mov rdx,rax
 shr rdx,52
 and edx,0x7ff
 cmp edx,0x7ff
 je .domain
 movsd [r13+r9*8],xmm1
.next_source:
 inc r10
 jmp .source_each
.finish:
 cmp ebx,NEBO_TENSOR_REDUCE_MEAN
 jne .ok
 cvtsi2sd xmm1,qword [rsp+104]
 xor r10d,r10d
 mov rcx,[r12+NEBO_TENSOR_CAPACITY]
.mean_each:
 cmp r10,rcx
 jae .ok
 movsd xmm0,[r13+r10*8]
 divsd xmm0,xmm1
 movsd [r13+r10*8],xmm0
 inc r10
 jmp .mean_each
.ok: xor eax,eax
.ret:
 add rsp,128
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret
.argument: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .ret
.bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .ret
.shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .ret
.domain: mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 jmp .ret
.alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .ret
.contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .ret

; outDesc,outI64,source,axis,storageId. Removes one axis and chooses the
; first maximum on ties. NaN/Inf is rejected before output initialization.
nebo_tensor_argmax_axis_f64:
 push rbp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,88
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 mov rdi,r14
 call nebo_tensor_validate
 test eax,eax
 jnz .amax_ret
 cmp qword [r14+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_F64
 jne .amax_contract
 mov rax,[r14+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .amax_alias
 mov rcx,[r14+NEBO_TENSOR_RANK]
 test rcx,rcx
 jz .amax_bounds
 cmp r15,rcx
 jae .amax_bounds
 cmp qword [r14+NEBO_TENSOR_SHAPE+r15*8],0
 je .amax_domain
 mov rdi,r14
 call nebo_tensor_element_count
 test edx,edx
 jnz .amax_shape_error
 mov [rsp+80],rax
 ; Preflight every logical value for finite deterministic comparison.
 xor ebx,ebx
.amax_finite:
 cmp rbx,[rsp+80]
 jae .amax_shape
 mov rax,rbx
 xor r8d,r8d
 mov rcx,[r14+NEBO_TENSOR_RANK]
.amax_finite_axis:
 test rcx,rcx
 jz .amax_finite_value
 dec rcx
 xor edx,edx
 div qword [r14+NEBO_TENSOR_SHAPE+rcx*8]
 imul rdx,[r14+NEBO_TENSOR_STRIDES+rcx*8]
 add r8,rdx
 jmp .amax_finite_axis
.amax_finite_value:
 mov rdx,[r14+NEBO_TENSOR_DATA]
 mov rax,[rdx+r8*8]
 mov rdx,rax
 shr rdx,52
 and edx,0x7ff
 cmp edx,0x7ff
 je .amax_domain
 inc rbx
 jmp .amax_finite
.amax_shape:
 xor r8d,r8d
 xor r9d,r9d
 mov rcx,[r14+NEBO_TENSOR_RANK]
.amax_shape_axis:
 cmp r8,rcx
 jae .amax_init
 cmp r8,r15
 je .amax_shape_next
 mov rax,[r14+NEBO_TENSOR_SHAPE+r8*8]
 mov [rsp+r9*8],rax
 inc r9
.amax_shape_next:
 inc r8
 jmp .amax_shape_axis
.amax_init:
 mov rdi,r12
 mov rsi,r13
 mov rdx,[r14+NEBO_TENSOR_RANK]
 dec rdx
 lea rcx,[rsp]
 mov r8d,NEBO_TENSOR_DTYPE_I64
 mov r9,rbp
 call nebo_tensor_init_owned
 test eax,eax
 jnz .amax_ret
 xor ebx,ebx
.amax_each:
 cmp rbx,[rsp+80]
 jae .amax_ok
 mov rax,rbx
 xor r8d,r8d
 xor r9d,r9d
 mov r10,1
 xor r11d,r11d
 mov rcx,[r14+NEBO_TENSOR_RANK]
.amax_map_axis:
 test rcx,rcx
 jz .amax_apply
 dec rcx
 xor edx,edx
 div qword [r14+NEBO_TENSOR_SHAPE+rcx*8]
 mov rsi,rdx
 imul rdx,[r14+NEBO_TENSOR_STRIDES+rcx*8]
 add r8,rdx
 cmp rcx,r15
 je .amax_selected
 imul rsi,r10
 add r9,rsi
 imul r10,[r14+NEBO_TENSOR_SHAPE+rcx*8]
 jmp .amax_map_axis
.amax_selected:
 mov r11,rsi
 jmp .amax_map_axis
.amax_apply:
 test r11,r11
 jz .amax_seed
 mov rdx,[r14+NEBO_TENSOR_DATA]
 movsd xmm0,[rdx+r8*8]
 mov rax,r11
 imul rax,[r14+NEBO_TENSOR_STRIDES+r15*8]
 sub r8,rax
 mov rax,[r13+r9*8]
 imul rax,[r14+NEBO_TENSOR_STRIDES+r15*8]
 add r8,rax
 movsd xmm1,[rdx+r8*8]
 ucomisd xmm0,xmm1
 jbe .amax_next
 mov [r13+r9*8],r11
 jmp .amax_next
.amax_seed:
 mov qword [r13+r9*8],0
.amax_next:
 inc rbx
 jmp .amax_each
.amax_ok:
 xor eax,eax
.amax_ret:
 add rsp,88
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret
.amax_bounds:
 mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .amax_ret
.amax_domain:
 mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 jmp .amax_ret
.amax_contract:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .amax_ret
.amax_shape_error:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .amax_ret
.amax_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .amax_ret

; Public Bool wrappers: outDesc,outBytes,source,axis,storageId.
nebo_tensor_all_axis_bool:
 mov r9,r8
 mov r8d,NEBO_TENSOR_BOOL_ALL
 jmp tensor_bool_axis
nebo_tensor_any_axis_bool:
 mov r9,r8
 mov r8d,NEBO_TENSOR_BOOL_ANY
 jmp tensor_bool_axis

; outDesc,outBytes,source,axis,operation,storageId.
tensor_bool_axis:
 push rbp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,88
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov ebx,r8d
 mov rbp,r9
 mov rdi,r14
 call nebo_tensor_validate
 test eax,eax
 jnz .bool_ret
 cmp qword [r14+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_BOOL
 jne .bool_contract
 mov rax,[r14+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .bool_alias
 cmp ebx,NEBO_TENSOR_BOOL_ALL
 je .bool_axis_ok
 cmp ebx,NEBO_TENSOR_BOOL_ANY
 jne .bool_contract
.bool_axis_ok:
 mov rcx,[r14+NEBO_TENSOR_RANK]
 test rcx,rcx
 jz .bool_bounds
 cmp r15,rcx
 jae .bool_bounds
 cmp qword [r14+NEBO_TENSOR_SHAPE+r15*8],0
 je .bool_domain
 mov rdi,r14
 call nebo_tensor_element_count
 test edx,edx
 jnz .bool_shape_error
 mov [rsp+80],rax
 xor r8d,r8d
 xor r9d,r9d
.bool_shape_axis:
 cmp r8,rcx
 jae .bool_init
 cmp r8,r15
 je .bool_shape_next
 mov rax,[r14+NEBO_TENSOR_SHAPE+r8*8]
 mov [rsp+r9*8],rax
 inc r9
.bool_shape_next:
 inc r8
 jmp .bool_shape_axis
.bool_init:
 mov rdi,r12
 mov rsi,r13
 mov rdx,[r14+NEBO_TENSOR_RANK]
 dec rdx
 lea rcx,[rsp]
 mov r8d,NEBO_TENSOR_DTYPE_BOOL
 mov r9,rbp
 call nebo_tensor_init_owned
 test eax,eax
 jnz .bool_ret
 mov rcx,[r12+NEBO_TENSOR_CAPACITY]
 xor r8d,r8d
 cmp ebx,NEBO_TENSOR_BOOL_ALL
 sete al
.bool_seed:
 cmp r8,rcx
 jae .bool_source
 mov [r13+r8],al
 inc r8
 jmp .bool_seed
.bool_source:
 xor r11d,r11d
.bool_each:
 cmp r11,[rsp+80]
 jae .bool_ok
 mov rax,r11
 xor r8d,r8d
 xor r9d,r9d
 mov r10,1
 mov rcx,[r14+NEBO_TENSOR_RANK]
.bool_map_axis:
 test rcx,rcx
 jz .bool_apply
 dec rcx
 xor edx,edx
 div qword [r14+NEBO_TENSOR_SHAPE+rcx*8]
 mov rsi,rdx
 imul rdx,[r14+NEBO_TENSOR_STRIDES+rcx*8]
 add r8,rdx
 cmp rcx,r15
 je .bool_map_axis
 imul rsi,r10
 add r9,rsi
 imul r10,[r14+NEBO_TENSOR_SHAPE+rcx*8]
 jmp .bool_map_axis
.bool_apply:
 mov rdx,[r14+NEBO_TENSOR_DATA]
 cmp byte [rdx+r8],0
 setne al
 cmp ebx,NEBO_TENSOR_BOOL_ALL
 jne .bool_any
 and [r13+r9],al
 jmp .bool_next
.bool_any:
 or [r13+r9],al
.bool_next:
 inc r11
 jmp .bool_each
.bool_ok:
 xor eax,eax
.bool_ret:
 add rsp,88
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret
.bool_bounds:
 mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .bool_ret
.bool_domain:
 mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 jmp .bool_ret
.bool_contract:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .bool_ret
.bool_shape_error:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .bool_ret
.bool_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .bool_ret
section .note.GNU-stack noalloc noexec nowrite progbits
