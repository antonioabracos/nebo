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
global nebo_matrix_map_f64
global nebo_matrix_reduce_f64

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
nebo_matrix_map_f64:
 test rdx,rdx
 jz .map_arg
 push r12
 push r13
 push r14
 push r15
 push rbx
 push rbp
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
 call r14
 mov rdi,r12
 mov rsi,rbx
 call matrix_store_linear
 inc rbx
 jmp .map_loop
.map_ok: xor eax,eax
.map_ret: pop rbp
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.map_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
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
section .note.GNU-stack noalloc noexec nowrite progbits
