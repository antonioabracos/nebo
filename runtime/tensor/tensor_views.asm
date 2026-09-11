; CALL-E-COMPORTAMENTOS-DE-CHAMADA-F03 checked Tensor coordinates and readonly views
bits 64
default rel
%define NEBO_TENSOR_VIEWS_IMPLEMENTATION 1
%include "runtime/tensor/tensor_views.inc"
extern nebo_tensor_is_contiguous
section .text
global nebo_tensor_at_f64
global nebo_tensor_at_bits
global nebo_tensor_set_f64
global nebo_tensor_slice_view
global nebo_tensor_select_view
global nebo_tensor_narrow_view
global nebo_tensor_permute_view
global nebo_tensor_reshape_view
global nebo_tensor_contiguous_f64
global nebo_tensor_contiguous_bits

; Internal desc rdi coords rsi -> rax element offset, edx status.
tensor_offset:
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 call nebo_tensor_validate
 test eax,eax
 jnz .off_error
 mov rcx,[r12+NEBO_TENSOR_RANK]
 test rcx,rcx
 jz .off_scalar
 test r13,r13
 jz .off_arg
 xor eax,eax
 xor r8d,r8d
.off_loop:
 mov r9,[r13+r8*8]
 cmp r9,[r12+NEBO_TENSOR_SHAPE+r8*8]
 jae .off_bounds
 imul r9,[r12+NEBO_TENSOR_STRIDES+r8*8]
 add rax,r9
 inc r8
 cmp r8,rcx
 jb .off_loop
.off_scalar: xor edx,edx
.off_ret: pop r13
 pop r12
 ret
.off_error: mov edx,eax
 xor eax,eax
 jmp .off_ret
.off_arg: xor eax,eax
 mov edx,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .off_ret
.off_contract: xor eax,eax
 mov edx,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .off_ret
.off_bounds: xor eax,eax
 mov edx,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .off_ret

nebo_tensor_at_f64:
 test rdi,rdi
 jz .contract
 cmp qword [rdi+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_F64
 jne .contract
 sub rsp,8
 call nebo_tensor_at_bits
 add rsp,8
 movq xmm0,rdx
 ret
.contract:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 ret
; Canonical checked coordinate read, preserving exact scalar dtype bits.
nebo_tensor_at_bits:
 push r12
 mov r12,rdi
 call tensor_offset
 test edx,edx
 jnz .at_ret
 mov rcx,[r12+NEBO_TENSOR_DATA]
 cmp qword [r12+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_BOOL
 jne .at_qword
 movzx eax,byte [rcx+rax]
 jmp .at_value
.at_qword:
 mov rax,[rcx+rax*8]
.at_value:
 mov rcx,rax
 xor eax,eax
 mov rdx,rcx
 pop r12
 ret
.at_ret: mov eax,edx
 pop r12
 ret

nebo_tensor_set_f64:
 push r12
 mov r12,rdi
 test rdi,rdi
 jz .set_contract
 cmp qword [rdi+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_F64
 jne .set_contract
 test qword [rdi+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_READONLY
 jnz .set_alias
 call tensor_offset
 test edx,edx
 jnz .set_err
 mov rcx,[r12+NEBO_TENSOR_DATA]
 movsd [rcx+rax*8],xmm0
 xor eax,eax
.set_ret: pop r12
 ret
.set_err: mov eax,edx
 jmp .set_ret
.set_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .set_ret
.set_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .set_ret

; Copy common owner descriptor into readonly view.
; out rdi owner rsi
tensor_view_base:
 mov rax,NEBO_TENSOR_MAGIC
 mov [rdi+NEBO_TENSOR_MAGIC_OFF],rax
 mov rax,[rsi+NEBO_TENSOR_DTYPE]
 mov [rdi+NEBO_TENSOR_DTYPE],rax
 mov qword [rdi+NEBO_TENSOR_DEVICE],NEBO_TENSOR_DEVICE_CPU
 mov rax,[rsi+NEBO_TENSOR_DATA]
 mov [rdi+NEBO_TENSOR_DATA],rax
 mov rax,[rsi+NEBO_TENSOR_CAPACITY]
 mov [rdi+NEBO_TENSOR_CAPACITY],rax
 mov rax,[rsi+NEBO_TENSOR_STORAGE_ID]
 mov [rdi+NEBO_TENSOR_STORAGE_ID],rax
 mov rax,[rsi+NEBO_TENSOR_GENERATION]
 mov [rdi+NEBO_TENSOR_GENERATION],rax
 mov qword [rdi+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_VIEW|NEBO_TENSOR_FLAG_READONLY
 ret

; out, owner, axis, start, count, step. A positive step scales the selected
; axis stride without copying storage; narrow remains the step-one shorthand.
nebo_tensor_slice_view:
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
 mov rbx,r8
 mov rbp,r9
 mov rdi,r13
 call nebo_tensor_validate
 test eax,eax
 jnz .slice_ret
 cmp r14,[r13+NEBO_TENSOR_RANK]
 jae .slice_bounds
 test rbp,rbp
 jz .slice_bounds
 mov rax,[r13+NEBO_TENSOR_SHAPE+r14*8]
 test rbx,rbx
 jz .slice_empty
 cmp r15,rax
 jae .slice_bounds
 mov rdx,rbx
 dec rdx
 imul rdx,rbp
 jo .slice_bounds
 add rdx,r15
 jc .slice_bounds
 cmp rdx,rax
 jae .slice_bounds
 jmp .slice_base
.slice_empty:
 cmp r15,rax
 ja .slice_bounds
.slice_base:
 mov rdi,r12
 mov rsi,r13
 call tensor_view_base
 mov rax,[r13+NEBO_TENSOR_RANK]
 mov [r12+NEBO_TENSOR_RANK],rax
 xor ecx,ecx
.slice_copy:
 cmp rcx,rax
 jae .slice_adjust
 mov rdx,[r13+NEBO_TENSOR_SHAPE+rcx*8]
 mov [r12+NEBO_TENSOR_SHAPE+rcx*8],rdx
 mov rdx,[r13+NEBO_TENSOR_STRIDES+rcx*8]
 mov [r12+NEBO_TENSOR_STRIDES+rcx*8],rdx
 inc rcx
 jmp .slice_copy
.slice_adjust:
 mov [r12+NEBO_TENSOR_SHAPE+r14*8],rbx
 mov rax,[r13+NEBO_TENSOR_STRIDES+r14*8]
 mov rdx,rax
 cmp qword [r13+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_BOOL
 je .slice_width_ready
 shl rdx,3
.slice_width_ready:
 imul rdx,r15
 add [r12+NEBO_TENSOR_DATA],rdx
 imul rax,rbp
 jo .slice_bounds
 mov [r12+NEBO_TENSOR_STRIDES+r14*8],rax
 xor eax,eax
.slice_ret:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret
.slice_bounds:
 mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .slice_ret

; out, owner, axis, index. Removes the selected axis without copying storage.
nebo_tensor_select_view:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rdi,r13
 call nebo_tensor_validate
 test eax,eax
 jnz .sel_ret
 mov rbx,[r13+NEBO_TENSOR_RANK]
 test rbx,rbx
 jz .sel_bounds
 cmp r14,rbx
 jae .sel_bounds
 cmp r15,[r13+NEBO_TENSOR_SHAPE+r14*8]
 jae .sel_bounds
 mov rdi,r12
 mov rsi,r13
 call tensor_view_base
 dec rbx
 mov [r12+NEBO_TENSOR_RANK],rbx
 xor r8d,r8d
 xor r9d,r9d
.sel_copy:
 cmp r8,[r13+NEBO_TENSOR_RANK]
 jae .sel_offset
 cmp r8,r14
 je .sel_next
 mov rax,[r13+NEBO_TENSOR_SHAPE+r8*8]
 mov [r12+NEBO_TENSOR_SHAPE+r9*8],rax
 mov rax,[r13+NEBO_TENSOR_STRIDES+r8*8]
 mov [r12+NEBO_TENSOR_STRIDES+r9*8],rax
 inc r9
.sel_next:
 inc r8
 jmp .sel_copy
.sel_offset:
 mov rax,[r13+NEBO_TENSOR_STRIDES+r14*8]
 imul rax,r15
 cmp qword [r13+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_BOOL
 je .sel_width_ready
 shl rax,3
.sel_width_ready:
 add [r12+NEBO_TENSOR_DATA],rax
 xor eax,eax
.sel_ret:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.sel_bounds:
 mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .sel_ret

; out, owner, axis, start, count
nebo_tensor_narrow_view:
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
 mov rdi,rsi
 call nebo_tensor_validate
 test eax,eax
 jnz .nar_ret
 cmp r14,[r13+NEBO_TENSOR_RANK]
 jae .nar_bounds
 mov rax,r15
 add rax,rbx
 jc .nar_bounds
 cmp rax,[r13+NEBO_TENSOR_SHAPE+r14*8]
 ja .nar_bounds
 mov rdi,r12
 mov rsi,r13
 call tensor_view_base
 mov rax,[r13+NEBO_TENSOR_RANK]
 mov [r12+NEBO_TENSOR_RANK],rax
 xor ecx,ecx
.nar_copy:
 cmp rcx,rax
 jae .nar_offset
 mov rdx,[r13+NEBO_TENSOR_SHAPE+rcx*8]
 mov [r12+NEBO_TENSOR_SHAPE+rcx*8],rdx
 mov rdx,[r13+NEBO_TENSOR_STRIDES+rcx*8]
 mov [r12+NEBO_TENSOR_STRIDES+rcx*8],rdx
 inc rcx
 jmp .nar_copy
.nar_offset:
 mov [r12+NEBO_TENSOR_SHAPE+r14*8],rbx
 mov rax,[r13+NEBO_TENSOR_STRIDES+r14*8]
 imul rax,r15
 cmp qword [r13+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_BOOL
 je .nar_width_ready
 shl rax,3
.nar_width_ready:
 add [r12+NEBO_TENSOR_DATA],rax
 xor eax,eax
.nar_ret: pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.nar_bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .nar_ret

; out, owner, axes permutation pointer
nebo_tensor_permute_view:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,rsi
 call nebo_tensor_validate
 test eax,eax
 jnz .perm_ret
 mov rcx,[r13+NEBO_TENSOR_RANK]
 test rcx,rcx
 jz .perm_base
 test r14,r14
 jz .perm_arg
 xor r8d,r8d
 xor r9d,r9d
.perm_check:
 mov rax,[r14+r8*8]
 cmp rax,rcx
 jae .perm_shape
 mov r10,1
 push rcx
 mov cl,al
 shl r10,cl
 pop rcx
 test r9,r10
 jnz .perm_shape
 or r9,r10
 inc r8
 cmp r8,rcx
 jb .perm_check
.perm_base:
 mov rdi,r12
 mov rsi,r13
 call tensor_view_base
 mov rcx,[r13+NEBO_TENSOR_RANK]
 mov [r12+NEBO_TENSOR_RANK],rcx
 xor r8d,r8d
.perm_copy:
 cmp r8,rcx
 jae .perm_ok
 mov rax,[r14+r8*8]
 mov rdx,[r13+NEBO_TENSOR_SHAPE+rax*8]
 mov [r12+NEBO_TENSOR_SHAPE+r8*8],rdx
 mov rdx,[r13+NEBO_TENSOR_STRIDES+rax*8]
 mov [r12+NEBO_TENSOR_STRIDES+r8*8],rdx
 inc r8
 jmp .perm_copy
.perm_ok: xor eax,eax
.perm_ret: pop r14
 pop r13
 pop r12
 ret
.perm_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .perm_ret
.perm_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .perm_ret

; out, owner, rank, shape (contiguous source only)
nebo_tensor_reshape_view:
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rdi,rsi
 call nebo_tensor_validate
 test eax,eax
 jnz .resh_ret
 mov rdi,r13
 call nebo_tensor_is_contiguous
 test edx,edx
 jnz .resh_shape
 test eax,eax
 jz .resh_alias
 cmp r14,NEBO_TENSOR_MAX_RANK
 ja .resh_shape
 test r14,r14
 jz .resh_dimensions
 test r15,r15
 jz .resh_shape
.resh_dimensions:
 mov r8,1
 xor r9d,r9d
.resh_count:
 cmp r9,r14
 jae .resh_compare
 mov rax,[r15+r9*8]
 cmp rax,NEBO_TENSOR_MAX_ELEMENTS
 ja .resh_shape
 imul r8,rax
 jo .resh_shape
 cmp r8,NEBO_TENSOR_MAX_ELEMENTS
 ja .resh_shape
 inc r9
 jmp .resh_count
.resh_compare:
 mov [rsp],r8
 mov rdi,r13
 call nebo_tensor_element_count
 test edx,edx
 jnz .resh_shape
 cmp rax,[rsp]
 jne .resh_shape
 mov rdi,r12
 mov rsi,r13
 call tensor_view_base
 mov [r12+NEBO_TENSOR_RANK],r14
 or qword [r12+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_CONTIGUOUS
 mov r8,1
 mov rdx,r14
.resh_copy:
 test rdx,rdx
 jz .resh_ok
 dec rdx
 mov rax,[r15+rdx*8]
 mov [r12+NEBO_TENSOR_SHAPE+rdx*8],rax
 mov [r12+NEBO_TENSOR_STRIDES+rdx*8],r8
 imul r8,rax
 jmp .resh_copy
.resh_ok: xor eax,eax
.resh_ret:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.resh_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .resh_ret
.resh_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .resh_ret

; out desc, out data, source, storage id; materializes logical order.
nebo_tensor_contiguous_f64:
 test rdx,rdx
 jz .contract
 cmp qword [rdx+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_F64
 jne .contract
 jmp nebo_tensor_contiguous_bits
.contract:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 ret
nebo_tensor_contiguous_bits:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rdi,r14
 call nebo_tensor_validate
 test eax,eax
 jnz .cont_ret
 mov rax,[r14+NEBO_TENSOR_DATA]
 cmp r13,rax
 je .cont_alias
 mov rdi,r14
 call nebo_tensor_element_count
 test edx,edx
 jnz .cont_shape
 mov rbx,rax
 mov rdi,r12
 mov rsi,r13
 mov rdx,[r14+NEBO_TENSOR_RANK]
 lea rcx,[r14+NEBO_TENSOR_SHAPE]
 mov r8,[r14+NEBO_TENSOR_DTYPE]
 mov r9,r15
 call nebo_tensor_init_owned
 test eax,eax
 jnz .cont_ret
 mov rcx,rbx
 xor r8d,r8d
.cont_linear:
 cmp r8,rcx
 jae .cont_ok
 mov rax,r8
 xor r9d,r9d
 mov r10,[r14+NEBO_TENSOR_RANK]
.cont_coord:
 test r10,r10
 jz .cont_store
 dec r10
 xor edx,edx
 div qword [r14+NEBO_TENSOR_SHAPE+r10*8]
 imul rdx,[r14+NEBO_TENSOR_STRIDES+r10*8]
 add r9,rdx
 jmp .cont_coord
.cont_store:
 mov rdx,[r14+NEBO_TENSOR_DATA]
 cmp qword [r14+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_BOOL
 jne .cont_qword
 mov al,[rdx+r9]
 mov [r13+r8],al
 jmp .cont_next
.cont_qword:
 movsd xmm0,[rdx+r9*8]
 movsd [r13+r8*8],xmm0
.cont_next:
 inc r8
 jmp .cont_linear
.cont_ok:
 xor eax,eax
.cont_ret: pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.cont_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .cont_ret
.cont_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .cont_ret
section .note.GNU-stack noalloc noexec nowrite progbits
