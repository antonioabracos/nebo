; ASYNC-AWAIT-E-CONCORRENCIA-ESTRUTURADA-F04 bounded scalar NCHW convolution and pooling
bits 64
default rel
%define NEBO_CONV_IMPLEMENTATION 1
%include "runtime/ml/conv.inc"
section .rodata align=8
c_exp_mask dq 0x7ff0000000000000
section .text
global nebo_conv1d
global nebo_conv2d
global nebo_max_pool2d
global nebo_avg_pool2d
global nebo_global_avg_pool2d
global nebo_padding2d

; Conv request[128]: out,in,weights,bias,Cin,H,W,Cout,KH,KW,stride,pad,
; dilation,OH,OW,out_capacity_elements. Batch is frozen to one.
conv_validate:
    test rdi,rdi
    jz .arg
    cmp qword [rdi],0
    je .arg
    cmp qword [rdi+8],0
    je .arg
    cmp qword [rdi+16],0
    je .arg
    cmp qword [rdi+24],0
    je .arg
    mov r8,[rdi+32]
    test r8,r8
    jz .limit
    cmp r8,16
    ja .limit
    mov r9,[rdi+40]
    test r9,r9
    jz .limit
    cmp r9,32
    ja .limit
    mov r10,[rdi+48]
    test r10,r10
    jz .limit
    cmp r10,32
    ja .limit
    mov r11,[rdi+56]
    test r11,r11
    jz .limit
    cmp r11,16
    ja .limit
    mov rax,[rdi+64]
    test rax,rax
    jz .limit
    cmp rax,7
    ja .limit
    mov rcx,[rdi+72]
    test rcx,rcx
    jz .limit
    cmp rcx,7
    ja .limit
    mov rdx,[rdi+80]
    test rdx,rdx
    jz .limit
    cmp rdx,4
    ja .limit
    cmp qword [rdi+88],3
    ja .limit
    mov rsi,[rdi+96]
    test rsi,rsi
    jz .limit
    cmp rsi,2
    ja .limit
    ; OH = floor((H+2P-D*(KH-1)-1)/S)+1, same for W.
    mov rax,[rdi+64]
    dec rax
    imul rax,rsi
    inc rax
    mov rcx,r9
    mov rsi,[rdi+88]
    lea rcx,[rcx+rsi*2]
    cmp rcx,rax
    jb .shape
    sub rcx,rax
    xor edx,edx
    mov rax,rcx
    div qword [rdi+80]
    inc rax
    cmp rax,[rdi+104]
    jne .shape
    mov rax,[rdi+72]
    dec rax
    imul rax,[rdi+96]
    inc rax
    mov rcx,r10
    mov rsi,[rdi+88]
    lea rcx,[rcx+rsi*2]
    cmp rcx,rax
    jb .shape
    sub rcx,rax
    xor edx,edx
    mov rax,rcx
    div qword [rdi+80]
    inc rax
    cmp rax,[rdi+112]
    jne .shape
    imul rax,[rdi+104]
    imul rax,r11
    cmp rax,[rdi+120]
    ja .limit
    ; Output disjoint from input, weights, and bias.
    mov rdx,[rdi]
    lea rcx,[rdx+rax*8]
    mov rax,r8
    imul rax,r9
    imul rax,r10
    mov rsi,[rdi+8]
    lea rax,[rsi+rax*8]
    cmp rdx,rax
    jae .weight_alias
    cmp rsi,rcx
    jb .overlap
.weight_alias:
    mov rax,r11
    imul rax,r8
    imul rax,[rdi+64]
    imul rax,[rdi+72]
    mov rsi,[rdi+16]
    lea rax,[rsi+rax*8]
    cmp rdx,rax
    jae .bias_alias
    cmp rsi,rcx
    jb .overlap
.bias_alias:
    mov rsi,[rdi+24]
    lea rax,[rsi+r11*8]
    cmp rdx,rax
    jae .ok
    cmp rsi,rcx
    jb .overlap
.ok: xor eax,eax
    ret
.arg: mov eax,NEBO_CONV_E_ARGUMENT
    ret
.limit: mov eax,NEBO_CONV_E_LIMIT
    ret
.shape: mov eax,NEBO_CONV_E_SHAPE
    ret
.overlap: mov eax,NEBO_CONV_E_OVERLAP
    ret

nebo_conv1d:
    test rdi,rdi
    jz .call
    cmp qword [rdi+40],1
    jne .shape
    cmp qword [rdi+64],1
    jne .shape
    cmp qword [rdi+104],1
    jne .shape
.call: jmp nebo_conv2d
.shape: mov eax,NEBO_CONV_E_SHAPE
    ret

nebo_conv2d:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,104
    mov r12,rdi
    call conv_validate
    test eax,eax
    jnz .conv_done
    mov r13,[r12]
    mov r14,[r12+8]
    mov r15,[r12+16]
    mov rbp,[r12+24]
    mov qword [rsp],0                 ; oc
.oc:
    mov rax,[rsp]
    cmp rax,[r12+56]
    jae .conv_ok
    mov qword [rsp+8],0               ; oy
.oy:
    mov rax,[rsp+8]
    cmp rax,[r12+104]
    jae .next_oc
    mov qword [rsp+16],0              ; ox
.ox:
    mov rax,[rsp+16]
    cmp rax,[r12+112]
    jae .next_oy
    mov rax,[rsp]
    movsd xmm0,[rbp+rax*8]
    mov qword [rsp+24],0              ; ic
.ic:
    mov rax,[rsp+24]
    cmp rax,[r12+32]
    jae .store
    mov qword [rsp+32],0              ; ky
.ky:
    mov rax,[rsp+32]
    cmp rax,[r12+64]
    jae .next_ic
    imul rax,[r12+96]
    mov rcx,[rsp+8]
    imul rcx,[r12+80]
    add rax,rcx
    sub rax,[r12+88]
    js .next_ky
    cmp rax,[r12+40]
    jae .next_ky
    mov [rsp+48],rax                  ; iy
    mov qword [rsp+40],0              ; kx
.kx:
    mov rax,[rsp+40]
    cmp rax,[r12+72]
    jae .next_ky
    imul rax,[r12+96]
    mov rcx,[rsp+16]
    imul rcx,[r12+80]
    add rax,rcx
    sub rax,[r12+88]
    js .next_kx
    cmp rax,[r12+48]
    jae .next_kx
    mov rdx,[rsp+24]
    imul rdx,[r12+40]
    add rdx,[rsp+48]
    imul rdx,[r12+48]
    add rdx,rax
    movsd xmm1,[r14+rdx*8]
    mov rdx,[rsp]
    imul rdx,[r12+32]
    add rdx,[rsp+24]
    imul rdx,[r12+64]
    add rdx,[rsp+32]
    imul rdx,[r12+72]
    add rdx,[rsp+40]
    mulsd xmm1,[r15+rdx*8]
    addsd xmm0,xmm1
.next_kx:
    inc qword [rsp+40]
    jmp .kx
.next_ky:
    inc qword [rsp+32]
    jmp .ky
.next_ic:
    inc qword [rsp+24]
    jmp .ic
.store:
    mov rax,[rsp]
    imul rax,[r12+104]
    add rax,[rsp+8]
    imul rax,[r12+112]
    add rax,[rsp+16]
    movsd [r13+rax*8],xmm0
    inc qword [rsp+16]
    jmp .ox
.next_oy:
    inc qword [rsp+8]
    jmp .oy
.next_oc:
    inc qword [rsp]
    jmp .oc
.conv_ok: xor eax,eax
.conv_done:
    add rsp,104
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; Pool request[64]: out,in,C,H,W,kernel,stride,out_capacity.
nebo_max_pool2d: mov esi,1
    jmp pool2d
nebo_avg_pool2d: mov esi,2
pool2d:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,40
    mov r12,rdi
    mov rbp,rsi
    test r12,r12
    jz .pool_arg
    mov r13,[r12]
    mov r14,[r12+8]
    test r13,r13
    jz .pool_arg
    test r14,r14
    jz .pool_arg
    mov r8,[r12+16]
    test r8,r8
    jz .pool_limit
    cmp r8,16
    ja .pool_limit
    mov r9,[r12+24]
    test r9,r9
    jz .pool_limit
    cmp r9,32
    ja .pool_limit
    mov r10,[r12+32]
    test r10,r10
    jz .pool_limit
    cmp r10,32
    ja .pool_limit
    mov r11,[r12+40]
    test r11,r11
    jz .pool_limit
    cmp r11,7
    ja .pool_limit
    cmp r11,r9
    ja .pool_shape
    cmp r11,r10
    ja .pool_shape
    mov rcx,[r12+48]
    test rcx,rcx
    jz .pool_limit
    cmp rcx,4
    ja .pool_limit
    mov rax,r9
    sub rax,r11
    xor edx,edx
    div rcx
    inc rax
    mov [rsp+24],rax                 ; OH
    mov rax,r10
    sub rax,r11
    xor edx,edx
    div rcx
    inc rax
    mov [rsp+32],rax                 ; OW
    imul rax,[rsp+24]
    imul rax,r8
    cmp rax,[r12+56]
    ja .pool_limit
    xor ebx,ebx                      ; c
.pool_c:
    cmp rbx,r8
    jae .pool_ok
    mov qword [rsp],0
.pool_y:
    mov rax,[rsp]
    cmp rax,[rsp+24]
    jae .pool_next_c
    mov qword [rsp+8],0
.pool_x:
    mov rax,[rsp+8]
    cmp rax,[rsp+32]
    jae .pool_next_y
    xorpd xmm0,xmm0
    mov qword [rsp+16],0
.pool_window:
    mov rax,[rsp+16]
    mov rcx,r11
    imul rcx,r11
    cmp rax,rcx
    jae .pool_store
    xor edx,edx
    div r11
    mov rcx,[rsp]
    imul rcx,[r12+48]
    add rcx,rax
    mov rax,rbx
    imul rax,r9
    add rax,rcx
    imul rax,r10
    mov rcx,[rsp+8]
    imul rcx,[r12+48]
    add rcx,rdx
    add rax,rcx
    movsd xmm1,[r14+rax*8]
    cmp qword [rsp+16],0
    je .pool_first
    cmp rbp,1
    jne .pool_sum
    maxsd xmm0,xmm1
    jmp .pool_advance
.pool_first:
    cmp rbp,1
    je .pool_set
.pool_sum:
    addsd xmm0,xmm1
    jmp .pool_advance
.pool_set: movapd xmm0,xmm1
.pool_advance:
    inc qword [rsp+16]
    jmp .pool_window
.pool_store:
    cmp rbp,1
    je .pool_write
    mov rax,r11
    imul rax,r11
    cvtsi2sd xmm1,rax
    divsd xmm0,xmm1
.pool_write:
    mov rax,rbx
    imul rax,[rsp+24]
    add rax,[rsp]
    imul rax,[rsp+32]
    add rax,[rsp+8]
    movsd [r13+rax*8],xmm0
    inc qword [rsp+8]
    jmp .pool_x
.pool_next_y: inc qword [rsp]
    jmp .pool_y
.pool_next_c: inc rbx
    jmp .pool_c
.pool_ok: xor eax,eax
    jmp .pool_done
.pool_arg: mov eax,NEBO_CONV_E_ARGUMENT
    jmp .pool_done
.pool_limit: mov eax,NEBO_CONV_E_LIMIT
    jmp .pool_done
.pool_shape: mov eax,NEBO_CONV_E_SHAPE
.pool_done:
    add rsp,40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; request: out,in,C,H,W,out_capacity
nebo_global_avg_pool2d:
    test rdi,rdi
    jz .ga_arg
    mov r8,[rdi]
    mov r9,[rdi+8]
    mov r10,[rdi+16]
    mov r11,[rdi+24]
    mov rdx,[rdi+32]
    test r8,r8
    jz .ga_arg
    test r9,r9
    jz .ga_arg
    test r10,r10
    jz .ga_limit
    cmp r10,16
    ja .ga_limit
    test r11,r11
    jz .ga_limit
    cmp r11,32
    ja .ga_limit
    test rdx,rdx
    jz .ga_limit
    cmp rdx,32
    ja .ga_limit
    cmp qword [rdi+40],r10
    jb .ga_limit
    xor ecx,ecx
.ga_c:
    cmp rcx,r10
    jae .ga_ok
    xorpd xmm0,xmm0
    mov rax,r11
    imul rax,rdx
    mov rsi,rcx
    imul rsi,rax
    xor edi,edi
.ga_sum:
    cmp rdi,rax
    jae .ga_store
    addsd xmm0,[r9+rsi*8]
    inc rsi
    inc rdi
    jmp .ga_sum
.ga_store:
    cvtsi2sd xmm1,rax
    divsd xmm0,xmm1
    movsd [r8+rcx*8],xmm0
    inc rcx
    jmp .ga_c
.ga_ok: xor eax,eax
    ret
.ga_arg: mov eax,NEBO_CONV_E_ARGUMENT
    ret
.ga_limit: mov eax,NEBO_CONV_E_LIMIT
    ret

; request: out,in,C,H,W,pad,out_capacity. Zero padding.
nebo_padding2d:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,24
    mov r12,rdi
    test r12,r12
    jz .pad_arg
    mov r8,[r12]
    mov r9,[r12+8]
    mov r10,[r12+16]
    mov r11,[r12+24]
    mov rbx,[r12+32]
    mov rbp,[r12+40]
    test r8,r8
    jz .pad_arg
    test r9,r9
    jz .pad_arg
    test r10,r10
    jz .pad_limit
    cmp r10,16
    ja .pad_limit
    cmp r11,32
    ja .pad_limit
    cmp rbx,32
    ja .pad_limit
    cmp rbp,3
    ja .pad_limit
    lea r13,[r11+rbp*2]
    lea r14,[rbx+rbp*2]
    mov rax,r13
    imul rax,r14
    imul rax,r10
    cmp rax,[r12+48]
    ja .pad_limit
    mov rdi,r8
    xor eax,eax
    mov rcx,r13
    imul rcx,r14
    imul rcx,r10
    rep stosq
    mov qword [rsp],0
.pad_c:
    mov rax,[rsp]
    cmp rax,r10
    jae .pad_ok
    mov qword [rsp+8],0
.pad_y:
    mov rax,[rsp+8]
    cmp rax,r11
    jae .pad_next_c
    mov qword [rsp+16],0
.pad_x:
    mov rax,[rsp+16]
    cmp rax,rbx
    jae .pad_next_y
    mov rax,[rsp]
    imul rax,r11
    add rax,[rsp+8]
    imul rax,rbx
    add rax,[rsp+16]
    movsd xmm0,[r9+rax*8]
    mov rax,[rsp]
    imul rax,r13
    mov rcx,[rsp+8]
    add rcx,rbp
    add rax,rcx
    imul rax,r14
    mov rcx,[rsp+16]
    add rcx,rbp
    add rax,rcx
    movsd [r8+rax*8],xmm0
    inc qword [rsp+16]
    jmp .pad_x
.pad_next_y: inc qword [rsp+8]
    jmp .pad_y
.pad_next_c: inc qword [rsp]
    jmp .pad_c
.pad_ok:
    xor eax,eax
    jmp .pad_done
.pad_arg: mov eax,NEBO_CONV_E_ARGUMENT
    jmp .pad_done
.pad_limit: mov eax,NEBO_CONV_E_LIMIT
.pad_done:
    add rsp,24
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
