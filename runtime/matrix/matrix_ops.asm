; FUNCOES-LAMBDAS-CALLBACKS-E-REFERENCIAS-F03 deterministic Matrix elementwise/reduction runtime
bits 64
default rel
%define NEBO_MATRIX_OPS_IMPLEMENTATION 1
%include "runtime/matrix/matrix_ops.inc"
section .rodata
align 8
matrix_ops_zero dq 0.0
section .text
global nebo_matrix_elementwise_f64
global nebo_matrix_scale_f64
global nebo_matrix_clamp_f64
global nebo_matrix_map_i64
global nebo_matrix_map_f64
global nebo_matrix_reduce_f64
global nebo_matrix_reduce_axis_i64
global nebo_matrix_reduce_axis_f64

; desc rdi, logical linear index rsi -> xmm0
matrix_load_linear:
 xor edx,edx
 mov rax,rsi
 div qword [rdi+NEBO_MATRIX_COLS]
 imul rax,[rdi+NEBO_MATRIX_ROW_STRIDE]
 imul rdx,[rdi+NEBO_MATRIX_COL_STRIDE]
 add rax,rdx
 mov rdx,[rdi+NEBO_MATRIX_DATA]
 movsd xmm0,[rdx+rax*8]
 ret

; desc rdi, logical index rsi, value xmm0
matrix_store_linear:
 xor edx,edx
 mov rax,rsi
 div qword [rdi+NEBO_MATRIX_COLS]
 imul rax,[rdi+NEBO_MATRIX_ROW_STRIDE]
 imul rdx,[rdi+NEBO_MATRIX_COL_STRIDE]
 add rax,rdx
 mov rdx,[rdi+NEBO_MATRIX_DATA]
 movsd [rdx+rax*8],xmm0
 ret

; out rdi, a rsi, b rdx, op rcx
nebo_matrix_elementwise_f64:
 push r12
 push r13
 push r14
 push r15
 push rbx
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 cmp r15,NEBO_MATRIX_OP_ADD
 jb .elem_contract
 cmp r15,NEBO_MATRIX_OP_DIV
 ja .elem_contract
 mov rdi,r12
 call nebo_matrix_validate
 test eax,eax
 jnz .elem_ret
 mov rdi,r13
 call nebo_matrix_validate
 test eax,eax
 jnz .elem_ret
 mov rdi,r14
 call nebo_matrix_validate
 test eax,eax
 jnz .elem_ret
 cmp qword [r12+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 jne .elem_contract
 cmp qword [r13+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 jne .elem_contract
 cmp qword [r14+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 jne .elem_contract
 mov rax,[r13+NEBO_MATRIX_ROWS]
 cmp rax,[r14+NEBO_MATRIX_ROWS]
 jne .elem_shape
 cmp rax,[r12+NEBO_MATRIX_ROWS]
 jne .elem_shape
 mov rax,[r13+NEBO_MATRIX_COLS]
 cmp rax,[r14+NEBO_MATRIX_COLS]
 jne .elem_shape
 cmp rax,[r12+NEBO_MATRIX_COLS]
 jne .elem_shape
 test qword [r12+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_READONLY
 jnz .elem_alias
 mov rbx,[r13+NEBO_MATRIX_ROWS]
 imul rbx,[r13+NEBO_MATRIX_COLS]
 cmp r15,NEBO_MATRIX_OP_DIV
 jne .elem_run
 xor ecx,ecx
.div_preflight:
 cmp rcx,rbx
 jae .elem_run
 mov rdi,r14
 mov rsi,rcx
 call matrix_load_linear
 ucomisd xmm0,[rel matrix_ops_zero]
 je .elem_domain
 inc rcx
 jmp .div_preflight
.elem_run:
 xor ebx,ebx
 mov r11,[r13+NEBO_MATRIX_ROWS]
 imul r11,[r13+NEBO_MATRIX_COLS]
.elem_loop:
 cmp rbx,r11
 jae .elem_ok
 mov rdi,r13
 mov rsi,rbx
 call matrix_load_linear
 movapd xmm2,xmm0
 mov rdi,r14
 mov rsi,rbx
 call matrix_load_linear
 cmp r15,NEBO_MATRIX_OP_ADD
 je .do_add
 cmp r15,NEBO_MATRIX_OP_SUB
 je .do_sub
 cmp r15,NEBO_MATRIX_OP_MUL
 je .do_mul
 movapd xmm1,xmm0
 movapd xmm0,xmm2
 divsd xmm0,xmm1
 jmp .elem_store
.do_add: addsd xmm2,xmm0
 movapd xmm0,xmm2
 jmp .elem_store
.do_sub: subsd xmm2,xmm0
 movapd xmm0,xmm2
 jmp .elem_store
.do_mul: mulsd xmm2,xmm0
 movapd xmm0,xmm2
.elem_store:
 mov rdi,r12
 mov rsi,rbx
 call matrix_store_linear
 inc rbx
 jmp .elem_loop
.elem_ok: xor eax,eax
.elem_ret:
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.elem_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .elem_ret
.elem_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .elem_ret
.elem_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .elem_ret
.elem_domain: mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 jmp .elem_ret

; out rdi input rsi scalar xmm0
nebo_matrix_scale_f64:
 push r12
 push r13
 push r14
 push r15
 push rbx
 mov r12,rdi
 mov r13,rsi
 movq r14,xmm0
 mov rdi,r12
 call nebo_matrix_validate
 test eax,eax
 jnz .scale_ret
 mov rdi,r13
 call nebo_matrix_validate
 test eax,eax
 jnz .scale_ret
 mov rax,[r13+NEBO_MATRIX_ROWS]
 cmp rax,[r12+NEBO_MATRIX_ROWS]
 jne .scale_shape
 mov rax,[r13+NEBO_MATRIX_COLS]
 cmp rax,[r12+NEBO_MATRIX_COLS]
 jne .scale_shape
 mov r15,[r13+NEBO_MATRIX_ROWS]
 imul r15,[r13+NEBO_MATRIX_COLS]
 xor ebx,ebx
.scale_loop:
 cmp rbx,r15
 jae .scale_ok
 mov rdi,r13
 mov rsi,rbx
 call matrix_load_linear
 movq xmm1,r14
 mulsd xmm0,xmm1
 mov rdi,r12
 mov rsi,rbx
 call matrix_store_linear
 inc rbx
 jmp .scale_loop
.scale_ok: xor eax,eax
.scale_ret: pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.scale_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .scale_ret

; out rdi input rsi low xmm0 high xmm1
nebo_matrix_clamp_f64:
 ucomisd xmm0,xmm1
 ja .clamp_domain
 push r12
 push r13
 push r14
 push rbx
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 movsd [rsp],xmm0
 movsd [rsp+8],xmm1
 mov rdi,r12
 call nebo_matrix_validate
 test eax,eax
 jnz .clamp_ret
 mov rdi,r13
 call nebo_matrix_validate
 test eax,eax
 jnz .clamp_ret
 mov r14,[r13+NEBO_MATRIX_ROWS]
 imul r14,[r13+NEBO_MATRIX_COLS]
 xor ebx,ebx
.clamp_loop:
 cmp rbx,r14
 jae .clamp_ok
 mov rdi,r13
 mov rsi,rbx
 call matrix_load_linear
 maxsd xmm0,[rsp]
 minsd xmm0,[rsp+8]
 mov rdi,r12
 mov rsi,rbx
 call matrix_store_linear
 inc rbx
 jmp .clamp_loop
.clamp_ok: xor eax,eax
.clamp_ret: add rsp,16
 pop rbx
 pop r14
 pop r13
 pop r12
 ret
.clamp_domain: mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 ret

; out rdi input rsi callback rdx context rcx. callback(context,x)->xmm0
; Map shares the canonical stride traversal for both scalar families.
; Float callback: context RDI, value XMM0 -> XMM0.
; Int callback: context RDI, value RSI -> RAX. No implicit conversion.
nebo_matrix_map_i64:
 mov eax,NEBO_MATRIX_DTYPE_I64
 jmp matrix_map_typed
nebo_matrix_map_f64:
 mov eax,NEBO_MATRIX_DTYPE_F64
matrix_map_typed:
 test rdx,rdx
 jz .map_arg
 push r12
 push r13
 push r14
 push r15
 push rbx
 push rbp
 sub rsp,8
 mov [rsp],rax
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rdi,r12
 call nebo_matrix_validate
 test eax,eax
 jnz .map_ret
 mov rdi,r13
 call nebo_matrix_validate
 test eax,eax
 jnz .map_ret
 mov rax,[rsp]
 cmp [r12+NEBO_MATRIX_DTYPE],rax
 jne .map_contract
 cmp [r13+NEBO_MATRIX_DTYPE],rax
 jne .map_contract
 mov rax,[r13+NEBO_MATRIX_ROWS]
 cmp [r12+NEBO_MATRIX_ROWS],rax
 jne .map_shape
 mov rax,[r13+NEBO_MATRIX_COLS]
 cmp [r12+NEBO_MATRIX_COLS],rax
 jne .map_shape
 test qword [r12+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_READONLY
 jnz .map_alias
 mov rax,[r12+NEBO_MATRIX_STORAGE_ID]
 cmp [r13+NEBO_MATRIX_STORAGE_ID],rax
 je .map_alias
 mov rbp,[r13+NEBO_MATRIX_ROWS]
 imul rbp,[r13+NEBO_MATRIX_COLS]
 xor ebx,ebx
.map_loop:
 cmp rbx,rbp
 jae .map_ok
 mov rdi,r13
 mov rsi,rbx
 call matrix_load_linear
 mov rdi,r15
 cmp qword [rsp],NEBO_MATRIX_DTYPE_F64
 je .map_float_call
 movq rsi,xmm0
 call r14
 movq xmm0,rax
 jmp .map_store
.map_float_call:
 call r14
.map_store:
 mov rdi,r12
 mov rsi,rbx
 call matrix_store_linear
 inc rbx
 jmp .map_loop
.map_contract:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .map_ret
.map_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .map_ret
.map_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .map_ret
.map_ok:
 xor eax,eax
.map_ret:
 add rsp,8
 pop rbp
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.map_arg:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret

; matrix rdi, reduce op rsi -> xmm0
nebo_matrix_reduce_f64:
 push r12
 push r13
 push rbx
 mov r12,rdi
 mov r13,rsi
 call nebo_matrix_validate
 test eax,eax
 jnz .reduce_ret
 cmp r13,NEBO_MATRIX_REDUCE_SUM
 jb .reduce_contract
 cmp r13,NEBO_MATRIX_REDUCE_MAX
 ja .reduce_contract
 mov rcx,[r12+NEBO_MATRIX_ROWS]
 imul rcx,[r12+NEBO_MATRIX_COLS]
 test rcx,rcx
 jz .reduce_domain
 xor esi,esi
 mov rdi,r12
 call matrix_load_linear
 cmp r13,NEBO_MATRIX_REDUCE_MIN
 jae .reduce_minmax
 xorpd xmm2,xmm2
 xor ebx,ebx
.reduce_sum_loop:
 cmp rbx,rcx
 jae .reduce_sum_done
 mov rdi,r12
 mov rsi,rbx
 call matrix_load_linear
 addsd xmm2,xmm0
 inc rbx
 jmp .reduce_sum_loop
.reduce_sum_done:
 movapd xmm0,xmm2
 cmp r13,NEBO_MATRIX_REDUCE_MEAN
 jne .reduce_ok
 cvtsi2sd xmm1,rcx
 divsd xmm0,xmm1
 jmp .reduce_ok
.reduce_minmax:
 movapd xmm2,xmm0
 mov ebx,1
.reduce_mm_loop:
 cmp rbx,rcx
 jae .reduce_mm_done
 mov rdi,r12
 mov rsi,rbx
 call matrix_load_linear
 cmp r13,NEBO_MATRIX_REDUCE_MIN
 jne .reduce_max
 minsd xmm2,xmm0
 jmp .reduce_mm_next
.reduce_max: maxsd xmm2,xmm0
.reduce_mm_next: inc rbx
 jmp .reduce_mm_loop
.reduce_mm_done: movapd xmm0,xmm2
.reduce_ok: xor eax,eax
.reduce_ret: pop rbx
 pop r13
 pop r12
 ret
.reduce_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .reduce_ret
.reduce_domain: mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 jmp .reduce_ret

; Matrix rdi, reduce op rsi, axis rdx, output rcx, output length r8.
; axis 0 reduces rows and returns one value per column; axis 1 reduces
; columns and returns one value per row.
nebo_matrix_reduce_axis_i64:
 mov eax,NEBO_MATRIX_DTYPE_I64
 jmp matrix_reduce_axis_typed
nebo_matrix_reduce_axis_f64:
 mov eax,NEBO_MATRIX_DTYPE_F64
matrix_reduce_axis_typed:
 push r12
 push r13
 push r14
 push r15
 push rbx
 push rbp
 sub rsp,520
 mov [rsp],rax
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 test r15,r15
 jz .axis_argument
 call nebo_matrix_validate
 test eax,eax
 jnz .axis_ret
 mov rax,[rsp]
 cmp [r12+NEBO_MATRIX_DTYPE],rax
 jne .axis_contract
 cmp r13,NEBO_MATRIX_REDUCE_SUM
 jb .axis_contract
 cmp r13,NEBO_MATRIX_REDUCE_MAX
 ja .axis_contract
 cmp r14,1
 ja .axis_argument
 test r14,r14
 jnz .axis_one
 mov rax,[r12+NEBO_MATRIX_COLS]
 cmp rbx,rax
 jne .axis_shape
 cmp qword [r12+NEBO_MATRIX_ROWS],0
 jne .axis_overlap
 cmp r13,NEBO_MATRIX_REDUCE_SUM
 jne .axis_domain
 jmp .axis_overlap
.axis_one:
 mov rax,[r12+NEBO_MATRIX_ROWS]
 cmp rbx,rax
 jne .axis_shape
 cmp qword [r12+NEBO_MATRIX_COLS],0
 jne .axis_overlap
 cmp r13,NEBO_MATRIX_REDUCE_SUM
 jne .axis_domain
.axis_overlap:
 mov r8,[r12+NEBO_MATRIX_DATA]
 mov r9,[r12+NEBO_MATRIX_CAPACITY]
 shl r9,3
 add r9,r8
 lea r10,[r15+rbx*8]
 cmp r15,r9
 jae .axis_run
 cmp r8,r10
 jb .axis_alias
.axis_run:
 xor ebp,ebp
.axis_output:
 cmp rbp,rbx
 jae .axis_ok
 xorpd xmm2,xmm2
 xor r10d,r10d
 xor r9d,r9d
.axis_inner:
 test r14,r14
 jnz .axis_one_coords
 cmp r9,[r12+NEBO_MATRIX_ROWS]
 jae .axis_store
 mov rax,r9
 imul rax,[r12+NEBO_MATRIX_ROW_STRIDE]
 mov rdx,rbp
 imul rdx,[r12+NEBO_MATRIX_COL_STRIDE]
 jmp .axis_load
.axis_one_coords:
 cmp r9,[r12+NEBO_MATRIX_COLS]
 jae .axis_store
 mov rax,rbp
 imul rax,[r12+NEBO_MATRIX_ROW_STRIDE]
 mov rdx,r9
 imul rdx,[r12+NEBO_MATRIX_COL_STRIDE]
.axis_load:
 add rax,rdx
 mov rdx,[r12+NEBO_MATRIX_DATA]
 cmp qword [rsp],NEBO_MATRIX_DTYPE_I64
 jne .axis_float_load
 cmp r13,NEBO_MATRIX_REDUCE_MEAN
 jne .axis_integer_load
 cvtsi2sd xmm0,qword [rdx+rax*8]
 jmp .axis_add
.axis_integer_load:
 mov rcx,[rdx+rax*8]
 cmp r13,NEBO_MATRIX_REDUCE_SUM
 je .axis_integer_sum
 test r9,r9
 jz .axis_integer_seed
 cmp rcx,r10
 je .axis_next
 cmp r13,NEBO_MATRIX_REDUCE_MIN
 jne .axis_integer_max
 cmp rcx,r10
 cmovl r10,rcx
 jmp .axis_next
.axis_integer_max:
 cmp rcx,r10
 cmovg r10,rcx
 jmp .axis_next
.axis_integer_seed:
 mov r10,rcx
 jmp .axis_next
.axis_integer_sum:
 add r10,rcx
 jo .axis_overflow
 jmp .axis_next
.axis_float_load:
 movsd xmm0,[rdx+rax*8]
 cmp r13,NEBO_MATRIX_REDUCE_MIN
 jb .axis_add
 test r9,r9
 jz .axis_seed_minmax
 cmp r13,NEBO_MATRIX_REDUCE_MIN
 jne .axis_max
 minsd xmm2,xmm0
 jmp .axis_next
.axis_max:
 maxsd xmm2,xmm0
 jmp .axis_next
.axis_seed_minmax:
 movapd xmm2,xmm0
 jmp .axis_next
.axis_add:
 addsd xmm2,xmm0
.axis_next:
 inc r9
 jmp .axis_inner
.axis_store:
 cmp qword [rsp],NEBO_MATRIX_DTYPE_I64
 jne .axis_store_float
 cmp r13,NEBO_MATRIX_REDUCE_MEAN
 je .axis_store_float
 movq xmm2,r10
.axis_store_float:
 cmp r13,NEBO_MATRIX_REDUCE_MEAN
 jne .axis_publish
 test r14,r14
 jnz .axis_mean_columns
 cvtsi2sd xmm1,qword [r12+NEBO_MATRIX_ROWS]
 jmp .axis_mean_divide
.axis_mean_columns:
 cvtsi2sd xmm1,qword [r12+NEBO_MATRIX_COLS]
.axis_mean_divide:
 divsd xmm2,xmm1
.axis_publish:
 ; Publish only after every output lane has passed overflow/domain checks.
 movsd [rsp+8+rbp*8],xmm2
 inc rbp
 jmp .axis_output
.axis_ok:
 mov rdi,r15
 lea rsi,[rsp+8]
 mov rcx,rbx
 rep movsq
 xor eax,eax
.axis_ret:
 add rsp,520
 pop rbp
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.axis_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
 jmp .axis_ret
.axis_argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .axis_ret
.axis_contract:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .axis_ret
.axis_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .axis_ret
.axis_domain:
 mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 jmp .axis_ret
.axis_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .axis_ret
section .note.GNU-stack noalloc noexec nowrite progbits
