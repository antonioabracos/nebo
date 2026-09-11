; RF27-G14-F04 bounded generic Vector<Int|Float,N> runtime
bits 64
default rel
%define NEBO_VECTOR_IMPLEMENTATION 1
%include "runtime/numeric/vector.inc"
section .text
global nebo_vector_i64_copy
global nebo_vector_i64_filled
global nebo_vector_i64_at
global nebo_vector_i64_add
global nebo_vector_i64_scale
global nebo_vector_i64_dot
global nebo_vector_f64_copy
global nebo_vector_f64_filled
global nebo_vector_f64_at
global nebo_vector_f64_add
global nebo_vector_f64_scale
global nebo_vector_f64_dot
global nebo_vector_f64_norm
global nebo_vector_f64_normalize

; Common span validation: rdi/rsi optional pointers, rdx=N.
vector_validate_two:
 test rdi,rdi
 jz .arg
 test rsi,rsi
 jz .arg
 test rdx,rdx
 jz .bounds
 cmp rdx,NEBO_NUMERIC_MAX_VECTOR
 ja .bounds
 xor eax,eax
 ret
.arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
.bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 ret

; out rdi, N rsi, value rdx. The constructor owns its output storage.
nebo_vector_i64_filled:
 test rdi,rdi
 jz .ifill_arg
 test rsi,rsi
 jz .ifill_bounds
 cmp rsi,NEBO_NUMERIC_MAX_VECTOR
 ja .ifill_bounds
 xor ecx,ecx
.ifill_loop:
 mov [rdi+rcx*8],rdx
 inc rcx
 cmp rcx,rsi
 jb .ifill_loop
 xor eax,eax
 ret
.ifill_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
.ifill_bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 ret

; out rdi, N rsi, value xmm0.
nebo_vector_f64_filled:
 test rdi,rdi
 jz .ffill_arg
 test rsi,rsi
 jz .ffill_bounds
 cmp rsi,NEBO_NUMERIC_MAX_VECTOR
 ja .ffill_bounds
 xor ecx,ecx
.ffill_loop:
 movsd [rdi+rcx*8],xmm0
 inc rcx
 cmp rcx,rsi
 jb .ffill_loop
 xor eax,eax
 ret
.ffill_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
.ffill_bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 ret

; out rdi, input rsi, N rdx
nebo_vector_i64_copy:
nebo_vector_f64_copy:
 call vector_validate_two
 test eax,eax
 jnz .ret
 xor ecx,ecx
.copy: mov rax,[rsi+rcx*8]
 mov [rdi+rcx*8],rax
 inc rcx
 cmp rcx,rdx
 jb .copy
 xor eax,eax
.ret: ret

; ptr rdi, N rsi, index rdx -> status eax, value rdx
nebo_vector_i64_at:
 test rdi,rdi
 jz .at_arg
 test rsi,rsi
 jz .at_bounds
 cmp rsi,NEBO_NUMERIC_MAX_VECTOR
 ja .at_bounds
 cmp rdx,rsi
 jae .at_bounds
 mov rdx,[rdi+rdx*8]
 xor eax,eax
 ret
.at_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
.at_bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 ret

; ptr rdi, N rsi, index rdx -> status eax, xmm0 value
nebo_vector_f64_at:
 call nebo_vector_i64_at
 test eax,eax
 jnz .fat_ret
 movq xmm0,rdx
.fat_ret: ret

; out rdi, a rsi, b rdx, N rcx. Checked preflight then write.
nebo_vector_i64_add:
 test rdi,rdi
 jz .iadd_arg
 test rsi,rsi
 jz .iadd_arg
 test rdx,rdx
 jz .iadd_arg
 test rcx,rcx
 jz .iadd_bounds
 cmp rcx,NEBO_NUMERIC_MAX_VECTOR
 ja .iadd_bounds
 xor r8d,r8d
.iadd_check:
 mov rax,[rsi+r8*8]
 add rax,[rdx+r8*8]
 jo .iadd_overflow
 inc r8
 cmp r8,rcx
 jb .iadd_check
 xor r8d,r8d
.iadd_write:
 mov rax,[rsi+r8*8]
 add rax,[rdx+r8*8]
 mov [rdi+r8*8],rax
 inc r8
 cmp r8,rcx
 jb .iadd_write
 xor eax,eax
 ret
.iadd_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
.iadd_bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 ret
.iadd_overflow: mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
 ret

; out rdi, a rsi, scalar rdx, N rcx, checked two-pass.
nebo_vector_i64_scale:
 test rdi,rdi
 jz .iscale_arg
 test rsi,rsi
 jz .iscale_arg
 test rcx,rcx
 jz .iscale_bounds
 cmp rcx,NEBO_NUMERIC_MAX_VECTOR
 ja .iscale_bounds
 xor r8d,r8d
.iscale_check:
 mov rax,[rsi+r8*8]
 imul rax,rdx
 jo .iscale_overflow
 inc r8
 cmp r8,rcx
 jb .iscale_check
 xor r8d,r8d
.iscale_write:
 mov rax,[rsi+r8*8]
 imul rax,rdx
 mov [rdi+r8*8],rax
 inc r8
 cmp r8,rcx
 jb .iscale_write
 xor eax,eax
 ret
.iscale_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
.iscale_bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 ret
.iscale_overflow: mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
 ret

; a rdi, b rsi, N rdx -> status eax, result rdx
nebo_vector_i64_dot:
 push rbx
 call vector_validate_two
 test eax,eax
 jnz .idot_ret
 xor ecx,ecx
 xor ebx,ebx
.idot:
 mov rax,[rdi+rcx*8]
 imul rax,[rsi+rcx*8]
 jo .idot_overflow
 add rbx,rax
 jo .idot_overflow
 inc rcx
 cmp rcx,rdx
 jb .idot
 mov rdx,rbx
 xor eax,eax
.idot_ret: pop rbx
 ret
.idot_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
 pop rbx
 ret

; Float add: out rdi, a rsi, b rdx, N rcx.
nebo_vector_f64_add:
 test rdi,rdi
 jz vector_fop_arg
 test rsi,rsi
 jz vector_fop_arg
 test rdx,rdx
 jz vector_fop_arg
 test rcx,rcx
 jz vector_fop_bounds
 cmp rcx,NEBO_NUMERIC_MAX_VECTOR
 ja vector_fop_bounds
 xor r8d,r8d
.fadd_loop:
 movsd xmm0,[rsi+r8*8]
 addsd xmm0,[rdx+r8*8]
 movsd [rdi+r8*8],xmm0
 inc r8
 cmp r8,rcx
 jb .fadd_loop
 xor eax,eax
 ret

; out rdi, a rsi, scalar xmm0, N rdx.
nebo_vector_f64_scale:
 test rdi,rdi
 jz vector_fop_arg
 test rsi,rsi
 jz vector_fop_arg
 test rdx,rdx
 jz vector_fop_bounds
 cmp rdx,NEBO_NUMERIC_MAX_VECTOR
 ja vector_fop_bounds
 xor ecx,ecx
.fscale_loop:
 movsd xmm1,[rsi+rcx*8]
 mulsd xmm1,xmm0
 movsd [rdi+rcx*8],xmm1
 inc rcx
 cmp rcx,rdx
 jb .fscale_loop
 xor eax,eax
 ret
vector_fop_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
vector_fop_bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 ret

; a rdi, b rsi, N rdx -> status eax, result xmm0.
nebo_vector_f64_dot:
 call vector_validate_two
 test eax,eax
 jnz .fdot_ret
 xorpd xmm0,xmm0
 xor ecx,ecx
.fdot_loop:
 movsd xmm1,[rdi+rcx*8]
 mulsd xmm1,[rsi+rcx*8]
 addsd xmm0,xmm1
 inc rcx
 cmp rcx,rdx
 jb .fdot_loop
 xor eax,eax
.fdot_ret: ret

; ptr rdi, N rsi -> status eax, norm xmm0.
nebo_vector_f64_norm:
 mov rdx,rsi
 mov rsi,rdi
 call nebo_vector_f64_dot
 test eax,eax
 jnz .norm_ret
 sqrtsd xmm0,xmm0
.norm_ret: ret

; out rdi, input rsi, N rdx.
nebo_vector_f64_normalize:
 push r12
 push r13
 mov r12,rdi
 mov r13,rdx
 mov rdi,rsi
 mov rsi,rdx
 call nebo_vector_f64_norm
 test eax,eax
 jnz .normalize_ret
 xorpd xmm1,xmm1
 ucomisd xmm0,xmm1
 jbe .normalize_domain
 movsd xmm1,xmm0
 movsd xmm0,[rel vector_one]
 divsd xmm0,xmm1
 mov rdi,r12
 mov rdx,r13
 call nebo_vector_f64_scale
.normalize_ret:
 pop r13
 pop r12
 ret
.normalize_domain:
 mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 jmp .normalize_ret

section .rodata
align 8
vector_one dq 1.0
section .note.GNU-stack noalloc noexec nowrite progbits
