; ASYNC-AWAIT-E-CONCORRENCIA-ESTRUTURADA-F02 bounded scalar F64 dense inference and stable activations
bits 64
default rel
%define NEBO_DENSE_IMPLEMENTATION 1
%include "runtime/ml/dense.inc"
extern nebo_math_exp_f64
section .rodata align=8
d_one dq 1.0
d_two dq 2.0
d_half dq 0.5
d_gelu_a dq 0.7978845608028654
d_gelu_b dq 0.044715
d_limit dq 1000000.0
d_abs_mask dq 0x7fffffffffffffff
d_exp_mask dq 0x7ff0000000000000
section .text
global nebo_dense_linear
global nebo_dense_relu
global nebo_dense_gelu
global nebo_dense_sigmoid
global nebo_dense_tanh
global nebo_dense_softmax

; rdi=out rsi=in rdx=count. Exact in-place or disjoint only.
dense_validate_vector:
    test rdi,rdi
    jz .argument
    test rsi,rsi
    jz .argument
    test rdx,rdx
    jz .limit
    cmp rdx,1024
    ja .limit
    cmp rdi,rsi
    je .finite
    lea r8,[rdi+rdx*8]
    lea r9,[rsi+rdx*8]
    cmp rdi,r9
    jae .finite
    cmp rsi,r8
    jb .overlap
.finite:
    xor ecx,ecx
.scan:
    cmp rcx,rdx
    jae .ok
    mov rax,[rsi+rcx*8]
    and rax,[rel d_exp_mask]
    cmp rax,[rel d_exp_mask]
    je .nonfinite
    inc rcx
    jmp .scan
.ok: xor eax,eax
    ret
.argument: mov eax,NEBO_DENSE_E_ARGUMENT
    ret
.limit: mov eax,NEBO_DENSE_E_LIMIT
    ret
.nonfinite: mov eax,NEBO_DENSE_E_NONFINITE
    ret
.overlap: mov eax,NEBO_DENSE_E_OVERLAP
    ret

; Stable scalar sigmoid in xmm0.
dense_sigmoid_scalar:
    sub rsp,8
    xorpd xmm1,xmm1
    ucomisd xmm0,xmm1
    jb .negative
    movapd xmm2,xmm0
    xorpd xmm0,xmm0
    subsd xmm0,xmm2
    call nebo_math_exp_f64
    addsd xmm0,[rel d_one]
    movsd xmm1,[rel d_one]
    divsd xmm1,xmm0
    movapd xmm0,xmm1
    add rsp,8
    ret
.negative:
    call nebo_math_exp_f64
    movapd xmm1,xmm0
    addsd xmm1,[rel d_one]
    divsd xmm0,xmm1
    add rsp,8
    ret

nebo_dense_relu:
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    mov rbx,rdx
    call dense_validate_vector
    test eax,eax
    jnz .relu_done
    xor ecx,ecx
    xorpd xmm1,xmm1
.relu_loop:
    cmp rcx,rbx
    jae .relu_ok
    movsd xmm0,[r13+rcx*8]
    maxsd xmm0,xmm1
    movsd [r12+rcx*8],xmm0
    inc rcx
    jmp .relu_loop
.relu_ok: xor eax,eax
.relu_done:
    pop r13
    pop r12
    pop rbx
    ret

%macro SIGMOID_VECTOR 1
%1:
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    mov rbx,rdx
    call dense_validate_vector
    test eax,eax
    jnz %%done
    xor ecx,ecx
%%loop:
    cmp rcx,rbx
    jae %%ok
    movsd xmm0,[r13+rcx*8]
    call dense_sigmoid_scalar
    movsd [r12+rcx*8],xmm0
    inc rcx
    jmp %%loop
%%ok: xor eax,eax
%%done:
    pop r13
    pop r12
    pop rbx
    ret
%endmacro
SIGMOID_VECTOR nebo_dense_sigmoid

nebo_dense_tanh:
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    mov rbx,rdx
    call dense_validate_vector
    test eax,eax
    jnz .tanh_done
    xor ecx,ecx
.tanh_loop:
    cmp rcx,rbx
    jae .tanh_ok
    movsd xmm0,[r13+rcx*8]
    mulsd xmm0,[rel d_two]
    call dense_sigmoid_scalar
    mulsd xmm0,[rel d_two]
    subsd xmm0,[rel d_one]
    movsd [r12+rcx*8],xmm0
    inc rcx
    jmp .tanh_loop
.tanh_ok: xor eax,eax
.tanh_done:
    pop r13
    pop r12
    pop rbx
    ret

nebo_dense_gelu:
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    mov rbx,rdx
    call dense_validate_vector
    test eax,eax
    jnz .gelu_done
    ; Bound approximation input to prevent cubic overflow and freeze accuracy.
    xor ecx,ecx
.gelu_range:
    cmp rcx,rbx
    jae .gelu_compute
    mov rax,[r13+rcx*8]
    and rax,[rel d_abs_mask]
    movq xmm0,rax
    ucomisd xmm0,[rel d_limit]
    ja .gelu_bad_range
    inc rcx
    jmp .gelu_range
.gelu_compute:
    xor ecx,ecx
.gelu_loop:
    cmp rcx,rbx
    jae .gelu_ok
    movsd xmm3,[r13+rcx*8]
    movapd xmm0,xmm3
    mulsd xmm0,xmm0
    mulsd xmm0,xmm3
    mulsd xmm0,[rel d_gelu_b]
    addsd xmm0,xmm3
    mulsd xmm0,[rel d_gelu_a]
    mulsd xmm0,[rel d_two]
    call dense_sigmoid_scalar
    mulsd xmm0,[rel d_two]
    subsd xmm0,[rel d_one]
    addsd xmm0,[rel d_one]
    mulsd xmm0,[rel d_half]
    mulsd xmm0,xmm3
    movsd [r12+rcx*8],xmm0
    inc rcx
    jmp .gelu_loop
.gelu_ok: xor eax,eax
    jmp .gelu_done
.gelu_bad_range: mov eax,NEBO_DENSE_E_RANGE
.gelu_done:
    pop r13
    pop r12
    pop rbx
    ret

nebo_dense_softmax:
    push rbx
    push r12
    push r13
    push r14
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    mov rbx,rdx
    call dense_validate_vector
    test eax,eax
    jnz .soft_done
    movsd xmm2,[r13]
    mov ecx,1
.max_loop:
    cmp rcx,rbx
    jae .exp_setup
    maxsd xmm2,[r13+rcx*8]
    inc rcx
    jmp .max_loop
.exp_setup:
    xorpd xmm3,xmm3
    xor r14d,r14d
.exp_loop:
    cmp r14,rbx
    jae .normalize
    movsd xmm0,[r13+r14*8]
    subsd xmm0,xmm2
    call nebo_math_exp_f64
    movsd [r12+r14*8],xmm0
    addsd xmm3,xmm0
    inc r14
    jmp .exp_loop
.normalize:
    xor ecx,ecx
.norm_loop:
    cmp rcx,rbx
    jae .soft_ok
    movsd xmm0,[r12+rcx*8]
    divsd xmm0,xmm3
    movsd [r12+rcx*8],xmm0
    inc rcx
    jmp .norm_loop
.soft_ok: xor eax,eax
.soft_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; request[64]: out,in,weights,bias,batch,in_features,out_features,out_capacity
nebo_dense_linear:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov r12,rdi
    test r12,r12
    jz .lin_argument
    mov r13,[r12]
    mov r14,[r12+8]
    mov r15,[r12+16]
    mov rbp,[r12+24]
    test r13,r13
    jz .lin_argument
    test r14,r14
    jz .lin_argument
    test r15,r15
    jz .lin_argument
    test rbp,rbp
    jz .lin_argument
    mov r8,[r12+32]
    test r8,r8
    jz .lin_limit
    cmp r8,16
    ja .lin_limit
    mov r9,[r12+40]
    test r9,r9
    jz .lin_limit
    cmp r9,64
    ja .lin_limit
    mov r10,[r12+48]
    test r10,r10
    jz .lin_limit
    cmp r10,64
    ja .lin_limit
    mov rax,r8
    imul rax,r10
    cmp rax,[r12+56]
    ja .lin_limit
    ; Output must be disjoint from every input region.
    lea r11,[r13+rax*8]
    mov rcx,r8
    imul rcx,r9
    lea rdx,[r14+rcx*8]
    cmp r13,rdx
    jae .lin_weights_overlap
    cmp r14,r11
    jb .lin_overlap
.lin_weights_overlap:
    mov rcx,r9
    imul rcx,r10
    lea rdx,[r15+rcx*8]
    cmp r13,rdx
    jae .lin_bias_overlap
    cmp r15,r11
    jb .lin_overlap
.lin_bias_overlap:
    lea rdx,[rbp+r10*8]
    cmp r13,rdx
    jae .lin_finite
    cmp rbp,r11
    jb .lin_overlap
.lin_finite:
    ; Prevalidate finite, bounded input, weights, and bias.
    xor ecx,ecx
    mov rax,r8
    imul rax,r9
.scan_input:
    cmp rcx,rax
    jae .scan_weights_setup
    mov rdx,[r14+rcx*8]
    mov rsi,rdx
    and rdx,[rel d_exp_mask]
    cmp rdx,[rel d_exp_mask]
    je .lin_nonfinite
    and rsi,[rel d_abs_mask]
    movq xmm0,rsi
    ucomisd xmm0,[rel d_limit]
    ja .lin_range
    inc rcx
    jmp .scan_input
.scan_weights_setup:
    xor ecx,ecx
    mov rax,r9
    imul rax,r10
.scan_weights:
    cmp rcx,rax
    jae .scan_bias
    mov rdx,[r15+rcx*8]
    mov rsi,rdx
    and rdx,[rel d_exp_mask]
    cmp rdx,[rel d_exp_mask]
    je .lin_nonfinite
    and rsi,[rel d_abs_mask]
    movq xmm0,rsi
    ucomisd xmm0,[rel d_limit]
    ja .lin_range
    inc rcx
    jmp .scan_weights
.scan_bias:
    xor ecx,ecx
.scan_bias_loop:
    cmp rcx,r10
    jae .lin_compute
    mov rdx,[rbp+rcx*8]
    and rdx,[rel d_exp_mask]
    cmp rdx,[rel d_exp_mask]
    je .lin_nonfinite
    inc rcx
    jmp .scan_bias_loop
.lin_compute:
    xor ebx,ebx
.batch_loop:
    cmp rbx,r8
    jae .lin_ok
    xor ecx,ecx
.out_loop:
    cmp rcx,r10
    jae .next_batch
    movsd xmm0,[rbp+rcx*8]
    xor edx,edx
.dot:
    cmp rdx,r9
    jae .store
    mov rax,rbx
    imul rax,r9
    add rax,rdx
    movsd xmm1,[r14+rax*8]
    mov rax,rcx
    imul rax,r9
    add rax,rdx
    mulsd xmm1,[r15+rax*8]
    addsd xmm0,xmm1
    inc rdx
    jmp .dot
.store:
    mov rax,rbx
    imul rax,r10
    add rax,rcx
    movsd [r13+rax*8],xmm0
    inc rcx
    jmp .out_loop
.next_batch:
    inc rbx
    jmp .batch_loop
.lin_ok: xor eax,eax
    jmp .lin_done
.lin_argument: mov eax,NEBO_DENSE_E_ARGUMENT
    jmp .lin_done
.lin_limit: mov eax,NEBO_DENSE_E_LIMIT
    jmp .lin_done
.lin_nonfinite: mov eax,NEBO_DENSE_E_NONFINITE
    jmp .lin_done
.lin_range: mov eax,NEBO_DENSE_E_RANGE
    jmp .lin_done
.lin_overlap: mov eax,NEBO_DENSE_E_OVERLAP
.lin_done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
