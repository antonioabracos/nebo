; ASYNC-AWAIT-E-CONCORRENCIA-ESTRUTURADA-F03 bounded scalar inference composition layers
bits 64
default rel
%define NEBO_LAYERS_IMPLEMENTATION 1
%include "runtime/ml/layers.inc"
extern nebo_dense_relu
section .rodata align=8
l_zero dq 0.0
l_exp_mask dq 0x7ff0000000000000
section .text
global nebo_layer_sequential_relu
global nebo_layer_norm
global nebo_layer_batch_norm_eval
global nebo_layer_dropout_eval
global nebo_layer_residual
global nebo_layer_flatten
global nebo_layer_embedding

; rdi=out rsi=in rdx=count; one or more ReLU layers collapse identically.
nebo_layer_sequential_relu:
    jmp nebo_dense_relu

; Common disjoint-or-exact vector validation, count <=2048.
layer_vector:
    test rdi,rdi
    jz .arg
    test rsi,rsi
    jz .arg
    test rdx,rdx
    jz .limit
    cmp rdx,2048
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
    and rax,[rel l_exp_mask]
    cmp rax,[rel l_exp_mask]
    je .nonfinite
    inc rcx
    jmp .scan
.ok: xor eax,eax
    ret
.arg: mov eax,NEBO_LAYER_E_ARGUMENT
    ret
.limit: mov eax,NEBO_LAYER_E_LIMIT
    ret
.nonfinite: mov eax,NEBO_LAYER_E_NONFINITE
    ret
.overlap: mov eax,NEBO_LAYER_E_OVERLAP
    ret

; request: out,in,count,epsilon_f64
nebo_layer_norm:
    push rbx
    push r12
    push r13
    push r14
    sub rsp,24
    mov r14,rdi
    test r14,r14
    jz .ln_arg
    mov r12,[r14]
    mov r13,[r14+8]
    mov rbx,[r14+16]
    movsd xmm4,[r14+24]
    ucomisd xmm4,[rel l_zero]
    jbe .ln_epsilon
    mov rdi,r12
    mov rsi,r13
    mov rdx,rbx
    call layer_vector
    test eax,eax
    jnz .ln_done
    xorpd xmm0,xmm0
    xor ecx,ecx
.ln_sum:
    cmp rcx,rbx
    jae .ln_mean
    addsd xmm0,[r13+rcx*8]
    inc rcx
    jmp .ln_sum
.ln_mean:
    cvtsi2sd xmm1,rbx
    divsd xmm0,xmm1
    movsd [rsp],xmm0
    xorpd xmm2,xmm2
    xor ecx,ecx
.ln_var:
    cmp rcx,rbx
    jae .ln_scale
    movsd xmm3,[r13+rcx*8]
    subsd xmm3,xmm0
    mulsd xmm3,xmm3
    addsd xmm2,xmm3
    inc rcx
    jmp .ln_var
.ln_scale:
    divsd xmm2,xmm1
    addsd xmm2,xmm4
    movsd [rsp+8],xmm2
    fld qword [rsp+8]
    fsqrt
    fstp qword [rsp+16]
    movsd xmm2,[rsp+16]
    xor ecx,ecx
.ln_write:
    cmp rcx,rbx
    jae .ln_ok
    movsd xmm3,[r13+rcx*8]
    subsd xmm3,[rsp]
    divsd xmm3,xmm2
    movsd [r12+rcx*8],xmm3
    inc rcx
    jmp .ln_write
.ln_ok: xor eax,eax
    jmp .ln_done
.ln_arg: mov eax,NEBO_LAYER_E_ARGUMENT
    jmp .ln_done
.ln_epsilon: mov eax,NEBO_LAYER_E_EPSILON
.ln_done:
    add rsp,24
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; request[64]: out,in,mean,var,gamma,beta,count,epsilon_f64
nebo_layer_batch_norm_eval:
    push rbx
    push r12
    push r13
    push r14
    sub rsp,24
    mov r14,rdi
    test r14,r14
    jz .bn_arg
    mov r12,[r14]
    mov r13,[r14+8]
    mov rbx,[r14+48]
    movsd xmm5,[r14+56]
    ucomisd xmm5,[rel l_zero]
    jbe .bn_epsilon
    mov rdi,r12
    mov rsi,r13
    mov rdx,rbx
    call layer_vector
    test eax,eax
    jnz .bn_done
    cmp rbx,64
    ja .bn_limit
    mov r8,[r14+16]
    mov r9,[r14+24]
    mov r10,[r14+32]
    mov r11,[r14+40]
    test r8,r8
    jz .bn_arg
    test r9,r9
    jz .bn_arg
    test r10,r10
    jz .bn_arg
    test r11,r11
    jz .bn_arg
    xor ecx,ecx
.bn_loop:
    cmp rcx,rbx
    jae .bn_ok
    movsd xmm0,[r9+rcx*8]
    addsd xmm0,xmm5
    movsd [rsp],xmm0
    fld qword [rsp]
    fsqrt
    fstp qword [rsp+8]
    movsd xmm0,[r13+rcx*8]
    subsd xmm0,[r8+rcx*8]
    divsd xmm0,[rsp+8]
    mulsd xmm0,[r10+rcx*8]
    addsd xmm0,[r11+rcx*8]
    movsd [r12+rcx*8],xmm0
    inc rcx
    jmp .bn_loop
.bn_ok: xor eax,eax
    jmp .bn_done
.bn_arg: mov eax,NEBO_LAYER_E_ARGUMENT
    jmp .bn_done
.bn_limit: mov eax,NEBO_LAYER_E_LIMIT
    jmp .bn_done
.bn_epsilon: mov eax,NEBO_LAYER_E_EPSILON
.bn_done:
    add rsp,24
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; rdi=out rsi=in rdx=count rcx=training. Eval is identity.
nebo_layer_dropout_eval:
    test rcx,rcx
    jnz .training
    jmp nebo_layer_flatten
.training: mov eax,NEBO_LAYER_E_TRAINING
    ret

; rdi=out rsi=a rdx=b rcx=count
nebo_layer_residual:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov rdx,r15
    call layer_vector
    test eax,eax
    jnz .res_done
    mov rdi,r12
    mov rsi,r14
    mov rdx,r15
    call layer_vector
    test eax,eax
    jnz .res_done
    xor ebx,ebx
.res_loop:
    cmp rbx,r15
    jae .res_ok
    movsd xmm0,[r13+rbx*8]
    addsd xmm0,[r14+rbx*8]
    movsd [r12+rbx*8],xmm0
    inc rbx
    jmp .res_loop
.res_ok: xor eax,eax
.res_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; rdi=out rsi=in rdx=count
nebo_layer_flatten:
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    mov rbx,rdx
    call layer_vector
    test eax,eax
    jnz .flat_done
    cmp r12,r13
    je .flat_ok
    mov rdi,r12
    mov rsi,r13
    mov rcx,rbx
    rep movsq
.flat_ok: xor eax,eax
.flat_done:
    pop r13
    pop r12
    pop rbx
    ret

; request: out,table,vocab,dim,index,out_capacity
nebo_layer_embedding:
    test rdi,rdi
    jz .emb_arg
    mov r8,[rdi]
    mov r9,[rdi+8]
    mov r10,[rdi+16]
    mov r11,[rdi+24]
    mov rax,[rdi+32]
    test r8,r8
    jz .emb_arg
    test r9,r9
    jz .emb_arg
    test r10,r10
    jz .emb_limit
    cmp r10,4096
    ja .emb_limit
    test r11,r11
    jz .emb_limit
    cmp r11,64
    ja .emb_limit
    cmp rax,r10
    jae .emb_index
    cmp qword [rdi+40],r11
    jb .emb_limit
    imul rax,r11
    lea rsi,[r9+rax*8]
    mov rdi,r8
    mov rdx,r11
    jmp nebo_layer_flatten
.emb_arg: mov eax,NEBO_LAYER_E_ARGUMENT
    ret
.emb_limit: mov eax,NEBO_LAYER_E_LIMIT
    ret
.emb_index: mov eax,NEBO_LAYER_E_INDEX
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
