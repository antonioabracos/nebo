; PATTERN-MATCHING-E-DESTRUCTURING-F07 explicit-copy RGBA8 Image to premultiplied-BGRA Canvas
bits 64
default rel
%define NEBO_CANVAS_IMAGE_IMPLEMENTATION 1
%include "runtime/canvas/canvas_image.inc"
section .text
global nebo_canvas_image

; rdi=canvas rsi=image rdx=x rcx=y
nebo_canvas_image:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    test r12,r12
    jz .argument
    test r13,r13
    jz .argument
    mov rax,NEBO_CANVAS_MAGIC
    cmp [r12+NEBO_CANVAS_MAGIC_OFFSET],rax
    jne .state
    cmp dword [r12+NEBO_CANVAS_STATE_OFFSET],NEBO_CANVAS_STATE_ACTIVE
    jne .state
    test dword [r12+NEBO_CANVAS_FLAGS_OFFSET],NEBO_CANVAS_FLAG_INITIALIZED
    jz .state
    cmp qword [r12+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET],0
    je .state
    test word [r13+30],NEBO_IMAGE_FLAG_CLOSED
    jnz .state
    cmp qword [r13+32],0
    je .state
    cmp qword [r13],0
    je .state
    cmp word [r13+28],NEBO_PIXEL_RGBA8
    jne .argument
    mov eax,[r13+16]
    add rax,r14
    jc .bounds
    cmp rax,[r12+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET]
    ja .bounds
    mov eax,[r13+20]
    add rax,r15
    jc .bounds
    cmp rax,[r12+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET]
    ja .bounds
    ; Copy mode requires disjoint source and Canvas storage.
    mov eax,[r13+24]
    mov ecx,[r13+20]
    imul rax,rcx
    mov r8,[r13]
    mov r9,r8
    add r9,rax
    jc .argument
    mov r10,[r12+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET]
    mov rax,[r12+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET]
    imul rax,[r12+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET]
    mov r11,r10
    add r11,rax
    jc .argument
    cmp r8,r11
    jae .ranges_ok
    cmp r10,r9
    jb .argument
.ranges_ok:
    xor ebx,ebx
.row:
    cmp ebx,[r13+20]
    jae .publish
    mov eax,ebx
    imul eax,[r13+24]
    mov rsi,[r13]
    add rsi,rax
    mov eax,ebx
    add rax,r15
    imul rax,[r12+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET]
    lea rdi,[r10+rax]
    lea rdi,[rdi+r14*4]
    xor ebp,ebp
.pixel:
    cmp ebp,[r13+16]
    jae .next_row
    movzx r11d,byte [rsi+3]
    movzx eax,byte [rsi+2]
    imul eax,r11d
    add eax,127
    xor edx,edx
    mov ecx,255
    div ecx
    mov [rdi],al
    movzx eax,byte [rsi+1]
    imul eax,r11d
    add eax,127
    xor edx,edx
    div ecx
    mov [rdi+1],al
    movzx eax,byte [rsi]
    imul eax,r11d
    add eax,127
    xor edx,edx
    div ecx
    mov [rdi+2],al
    mov [rdi+3],r11b
    add rsi,4
    add rdi,4
    inc ebp
    jmp .pixel
.next_row:
    inc ebx
    jmp .row
.publish:
    or dword [r12+NEBO_CANVAS_FLAGS_OFFSET],NEBO_CANVAS_FLAG_DIRTY
    xor eax,eax
    jmp .done
.argument:
    mov eax,NEBO_CANVAS_ERROR_INVALID_ARGUMENT
    jmp .done
.state:
    mov eax,NEBO_CANVAS_ERROR_BAD_STATE
    jmp .done
.bounds:
    mov eax,NEBO_CANVAS_ERROR_DIMENSION_MISMATCH
.done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
