; PATTERN-MATCHING-E-DESTRUCTURING-F04 scalar image transforms, caller-provided destinations
bits 64
default rel
%define NEBO_IMAGE_TRANSFORM_IMPLEMENTATION 1
%include "runtime/image/image.inc"
%include "runtime/image/image_transform.inc"
section .text
global nebo_image_crop_into
global nebo_image_resize_into
global nebo_image_flip_horizontal_into
global nebo_image_flip_vertical_into
global nebo_image_rotate90_into
global nebo_image_convert_into
global nebo_image_composite_over

validate_simple:
    test rdi,rdi
    jz .argument
    cmp qword [rdi],0
    je .stale
    test word [rdi+30],NEBO_IMAGE_FLAG_CLOSED
    jnz .stale
    mov r8,[rdi+40]
    test r8,r8
    jz .format
    cmp qword [r8],0
    je .stale
    mov r9,[r8+32]
    cmp r9,[rdi+48]
    jne .stale
.format:
    movzx r8d,word [rdi+28]
    cmp r8d,NEBO_PIXEL_RGBA8
    je .rgba
    cmp r8d,NEBO_PIXEL_GRAY8
    jne .bad_format
    mov r8d,1
    jmp .dimensions
.rgba:
    mov r8d,4
.dimensions:
    mov r9d,[rdi+16]
    test r9d,r9d
    jz .argument
    imul r9,r8
    cmp r9d,[rdi+24]
    ja .argument
    mov r9d,[rdi+24]
    imul r9d,[rdi+20]
    cmp r9,[rdi+8]
    ja .argument
    xor eax,eax
    ret
.argument:
    mov eax,NEBO_MEDIA_E_ARGUMENT
    ret
.bad_format:
    mov eax,NEBO_MEDIA_E_FORMAT
    ret
.stale:
    mov eax,NEBO_MEDIA_E_STALE
    ret

check_nonoverlap:
    mov r8,[rdi]
    mov r9,[rdi+8]
    add r9,r8
    mov rax,[rsi]
    cmp rax,r9
    jae .ok
    add rax,[rsi+8]
    cmp rax,r8
    jbe .ok
    mov eax,NEBO_MEDIA_E_ARGUMENT
    ret
.ok:
    xor eax,eax
    ret

nebo_image_crop_into:
    mov r8,rdx
    mov r9,rcx
    xor edx,edx
    jmp transform_copy
nebo_image_flip_horizontal_into:
    mov edx,1
    xor r8d,r8d
    xor r9d,r9d
    jmp transform_copy
nebo_image_flip_vertical_into:
    mov edx,2
    xor r8d,r8d
    xor r9d,r9d
    jmp transform_copy
nebo_image_rotate90_into:
    cmp edx,1
    jb .argument
    cmp edx,3
    ja .argument
    add edx,2
    xor r8d,r8d
    xor r9d,r9d
    jmp transform_copy
.argument:
    mov eax,NEBO_MEDIA_E_ARGUMENT
    ret

; rdi=src rsi=dst edx=op r8=offset_x r9=offset_y
transform_copy:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,32
    mov r12,rdi
    mov r13,rsi
    mov ebx,edx
    mov r14,r8
    mov r15,r9
    sub rsp,8
    call validate_simple
    add rsp,8
    test eax,eax
    jnz .return
    mov rdi,r13
    sub rsp,8
    call validate_simple
    add rsp,8
    test eax,eax
    jnz .return
    mov rdi,r12
    mov rsi,r13
    sub rsp,8
    call check_nonoverlap
    add rsp,8
    test eax,eax
    jnz .return
    mov ax,[r12+28]
    cmp ax,[r13+28]
    jne .format
    movzx eax,ax
    cmp eax,NEBO_PIXEL_RGBA8
    sete al
    movzx eax,al
    lea eax,[rax*2+1]
    cmp eax,3
    jne .bpp_ready
    inc eax
.bpp_ready:
    mov [rsp],rax
    cmp ebx,0
    je .crop_dims
    cmp ebx,3
    jb .same_dims
    test ebx,1
    jz .same_dims
    mov eax,[r12+20]
    cmp eax,[r13+16]
    jne .bounds
    mov eax,[r12+16]
    cmp eax,[r13+20]
    jne .bounds
    jmp .loops
.same_dims:
    mov eax,[r12+16]
    cmp eax,[r13+16]
    jne .bounds
    mov eax,[r12+20]
    cmp eax,[r13+20]
    jne .bounds
    jmp .loops
.crop_dims:
    mov eax,[r12+16]
    sub rax,r14
    jb .bounds
    mov ecx,[r13+16]
    cmp rcx,rax
    ja .bounds
    mov eax,[r12+20]
    sub rax,r15
    jb .bounds
    mov ecx,[r13+20]
    cmp rcx,rax
    ja .bounds
.loops:
    mov qword [rsp+8],0
.yloop:
    mov eax,[r13+20]
    cmp [rsp+8],rax
    jae .ok
    mov qword [rsp+16],0
.xloop:
    mov eax,[r13+16]
    cmp [rsp+16],rax
    jae .next_y
    mov r8,[rsp+16]
    mov r9,[rsp+8]
    cmp ebx,0
    je .map_crop
    cmp ebx,1
    je .map_h
    cmp ebx,2
    je .map_v
    cmp ebx,3
    je .map_r1
    cmp ebx,4
    je .map_r2
    mov eax,[r12+16]
    dec rax
    sub rax,r9
    mov r9,r8
    mov r8,rax
    jmp .copy
.map_crop:
    add r8,r14
    add r9,r15
    jmp .copy
.map_h:
    mov eax,[r12+16]
    dec rax
    sub rax,r8
    mov r8,rax
    jmp .copy
.map_v:
    mov eax,[r12+20]
    dec rax
    sub rax,r9
    mov r9,rax
    jmp .copy
.map_r1:
    mov rax,r9
    mov r9d,[r12+20]
    dec r9
    sub r9,r8
    mov r8,rax
    jmp .copy
.map_r2:
    mov eax,[r12+16]
    dec rax
    sub rax,r8
    mov r8,rax
    mov eax,[r12+20]
    dec rax
    sub rax,r9
    mov r9,rax
.copy:
    mov eax,[r12+24]
    imul r9,rax
    imul r8,[rsp]
    add r9,r8
    mov r10,[r12]
    add r10,r9
    mov r8,[rsp+16]
    mov r9,[rsp+8]
    mov eax,[r13+24]
    imul r9,rax
    imul r8,[rsp]
    add r9,r8
    mov r11,[r13]
    add r11,r9
    cmp qword [rsp],4
    jne .copy_gray
    mov eax,[r10]
    mov [r11],eax
    jmp .advance_x
.copy_gray:
    mov al,[r10]
    mov [r11],al
.advance_x:
    inc qword [rsp+16]
    jmp .xloop
.next_y:
    inc qword [rsp+8]
    jmp .yloop
.format:
    mov eax,NEBO_MEDIA_E_FORMAT
    jmp .return
.bounds:
    mov eax,NEBO_MEDIA_E_BOUNDS
    jmp .return
.ok:
    xor eax,eax
.return:
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; rdi=src rsi=dst edx=filter
nebo_image_resize_into:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,144
    mov r12,rdi
    mov r13,rsi
    mov ebx,edx
    cmp ebx,NEBO_IMAGE_FILTER_BILINEAR
    ja .argument
    sub rsp,8
    call validate_simple
    add rsp,8
    test eax,eax
    jnz .return
    mov rdi,r13
    sub rsp,8
    call validate_simple
    add rsp,8
    test eax,eax
    jnz .return
    mov rdi,r12
    mov rsi,r13
    sub rsp,8
    call check_nonoverlap
    add rsp,8
    test eax,eax
    jnz .return
    mov ax,[r12+28]
    cmp ax,[r13+28]
    jne .format
    movzx eax,ax
    cmp eax,NEBO_PIXEL_RGBA8
    jne .resize_gray
    mov qword [rsp],4
    jmp .resize_meta
.resize_gray:
    mov qword [rsp],1
.resize_meta:
    mov eax,[r12+16]
    mov [rsp+8],rax
    mov eax,[r12+20]
    mov [rsp+16],rax
    mov eax,[r13+16]
    mov [rsp+24],rax
    mov eax,[r13+20]
    mov [rsp+32],rax
    mov [rsp+104],rbx
    mov qword [rsp+40],0
.resize_y:
    mov rax,[rsp+40]
    cmp rax,[rsp+32]
    jae .ok
    cmp qword [rsp+104],0
    jne .bilinear_y
    imul rax,[rsp+16]
    xor edx,edx
    div qword [rsp+32]
    mov [rsp+48],rax
    mov [rsp+56],rax
    mov qword [rsp+64],0
    jmp .x_start
.bilinear_y:
    cmp qword [rsp+32],1
    je .zero_y
    cmp qword [rsp+16],1
    je .zero_y
    mov rax,[rsp+40]
    mov rcx,[rsp+16]
    dec rcx
    imul rax,rcx
    mov rcx,[rsp+32]
    dec rcx
    xor edx,edx
    div rcx
    mov [rsp+48],rax
    lea r8,[rax+1]
    mov [rsp+56],r8
    mov rax,rdx
    shl rax,16
    xor edx,edx
    div rcx
    mov [rsp+64],rax
    jmp .x_start
.zero_y:
    mov qword [rsp+48],0
    mov qword [rsp+56],0
    mov qword [rsp+64],0
.x_start:
    mov qword [rsp+96],0
.resize_x:
    mov rax,[rsp+96]
    cmp rax,[rsp+24]
    jae .resize_next_y
    cmp qword [rsp+104],0
    jne .bilinear_x
    imul rax,[rsp+8]
    xor edx,edx
    div qword [rsp+24]
    mov [rsp+72],rax
    mov [rsp+80],rax
    mov qword [rsp+88],0
    jmp .channels
.bilinear_x:
    cmp qword [rsp+24],1
    je .zero_x
    cmp qword [rsp+8],1
    je .zero_x
    mov rax,[rsp+96]
    mov rcx,[rsp+8]
    dec rcx
    imul rax,rcx
    mov rcx,[rsp+24]
    dec rcx
    xor edx,edx
    div rcx
    mov [rsp+72],rax
    lea r8,[rax+1]
    mov [rsp+80],r8
    mov rax,rdx
    shl rax,16
    xor edx,edx
    div rcx
    mov [rsp+88],rax
    jmp .channels
.zero_x:
    mov qword [rsp+72],0
    mov qword [rsp+80],0
    mov qword [rsp+88],0
.channels:
    xor r15d,r15d
.channel:
    cmp r15,[rsp]
    jae .resize_advance
    mov rax,[rsp+48]
    imul eax,[r12+24]
    mov rdx,[rsp+72]
    imul rdx,[rsp]
    add rax,rdx
    add rax,r15
    mov rdx,[r12]
    movzx r8d,byte [rdx+rax]
    mov rax,[rsp+48]
    imul eax,[r12+24]
    mov rdx,[rsp+80]
    imul rdx,[rsp]
    add rax,rdx
    add rax,r15
    mov rdx,[r12]
    movzx r9d,byte [rdx+rax]
    mov rax,[rsp+56]
    imul eax,[r12+24]
    mov rdx,[rsp+72]
    imul rdx,[rsp]
    add rax,rdx
    add rax,r15
    mov rdx,[r12]
    movzx r10d,byte [rdx+rax]
    mov rax,[rsp+56]
    imul eax,[r12+24]
    mov rdx,[rsp+80]
    imul rdx,[rsp]
    add rax,rdx
    add rax,r15
    mov rdx,[r12]
    movzx r11d,byte [rdx+rax]
    mov rcx,65536
    sub rcx,[rsp+88]
    imul r8,rcx
    mov rdx,[rsp+88]
    imul r9,rdx
    add r8,r9
    add r8,32768
    shr r8,16
    imul r10,rcx
    imul r11,rdx
    add r10,r11
    add r10,32768
    shr r10,16
    mov rcx,65536
    sub rcx,[rsp+64]
    imul r8,rcx
    mov rdx,[rsp+64]
    imul r10,rdx
    add r8,r10
    add r8,32768
    shr r8,16
    mov rax,[rsp+40]
    imul eax,[r13+24]
    mov rdx,[rsp+96]
    imul rdx,[rsp]
    add rax,rdx
    add rax,r15
    mov rdx,[r13]
    mov [rdx+rax],r8b
    inc r15
    jmp .channel
.resize_advance:
    inc qword [rsp+96]
    jmp .resize_x
.resize_next_y:
    inc qword [rsp+40]
    jmp .resize_y
.argument:
    mov eax,NEBO_MEDIA_E_ARGUMENT
    jmp .return
.format:
    mov eax,NEBO_MEDIA_E_FORMAT
    jmp .return
.ok:
    xor eax,eax
.return:
    add rsp,144
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; rdi=src rsi=dst, equal dimensions, explicit format conversion
nebo_image_convert_into:
    push rbx
    push r12
    push r13
    sub rsp,32
    mov r12,rdi
    mov r13,rsi
    sub rsp,8
    call validate_simple
    add rsp,8
    test eax,eax
    jnz .return
    mov rdi,r13
    sub rsp,8
    call validate_simple
    add rsp,8
    test eax,eax
    jnz .return
    mov eax,[r12+16]
    cmp eax,[r13+16]
    jne .bounds
    mov eax,[r12+20]
    cmp eax,[r13+20]
    jne .bounds
    mov qword [rsp],0
.y:
    mov eax,[r12+20]
    cmp [rsp],rax
    jae .ok
    mov qword [rsp+8],0
.x:
    mov eax,[r12+16]
    cmp [rsp+8],rax
    jae .next_y
    mov rax,[rsp]
    imul eax,[r12+24]
    mov rdx,[rsp+8]
    movzx ecx,word [r12+28]
    cmp ecx,NEBO_PIXEL_RGBA8
    jne .gray_to_rgba
    lea rax,[rax+rdx*4]
    mov r8,[r12]
    mov ebx,[r8+rax]
    movzx eax,bl
    imul eax,eax,13933
    mov r8d,ebx
    shr r8d,8
    movzx r8d,r8b
    imul r8d,r8d,46871
    add eax,r8d
    mov r8d,ebx
    shr r8d,16
    movzx r8d,r8b
    imul r8d,r8d,4732
    add eax,r8d
    add eax,32768
    shr eax,16
    mov rdx,[rsp]
    imul edx,[r13+24]
    add rdx,[rsp+8]
    mov r8,[r13]
    mov [r8+rdx],al
    jmp .advance
.gray_to_rgba:
    add rax,rdx
    mov r8,[r12]
    movzx ebx,byte [r8+rax]
    imul ebx,0x00010101
    or ebx,0xff000000
    mov rax,[rsp]
    imul eax,[r13+24]
    mov rdx,[rsp+8]
    lea rax,[rax+rdx*4]
    mov r8,[r13]
    mov [r8+rax],ebx
.advance:
    inc qword [rsp+8]
    jmp .x
.next_y:
    inc qword [rsp]
    jmp .y
.bounds:
    mov eax,NEBO_MEDIA_E_BOUNDS
    jmp .return
.ok:
    xor eax,eax
.return:
    add rsp,32
    pop r13
    pop r12
    pop rbx
    ret

; rdi=dst RGBA rsi=src RGBA rdx=x rcx=y
nebo_image_composite_over:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,64
    mov r13,rdi
    mov r12,rsi
    mov r14,rdx
    mov r15,rcx
    mov rdi,r12
    sub rsp,8
    call validate_simple
    add rsp,8
    test eax,eax
    jnz .return
    mov rdi,r13
    sub rsp,8
    call validate_simple
    add rsp,8
    test eax,eax
    jnz .return
    cmp word [r12+28],NEBO_PIXEL_RGBA8
    jne .format
    cmp word [r13+28],NEBO_PIXEL_RGBA8
    jne .format
    mov eax,[r13+16]
    sub rax,r14
    jb .bounds
    mov ecx,[r12+16]
    cmp rcx,rax
    ja .bounds
    mov eax,[r13+20]
    sub rax,r15
    jb .bounds
    mov ecx,[r12+20]
    cmp rcx,rax
    ja .bounds
    mov qword [rsp],0
.cy:
    mov eax,[r12+20]
    cmp [rsp],rax
    jae .ok
    mov qword [rsp+8],0
.cx:
    mov eax,[r12+16]
    cmp [rsp+8],rax
    jae .cnext_y
    mov rax,[rsp]
    imul eax,[r12+24]
    mov rdx,[rsp+8]
    lea rax,[rax+rdx*4]
    mov rdx,[r12]
    mov eax,[rdx+rax]
    mov [rsp+16],rax
    mov rax,[rsp]
    add rax,r15
    imul eax,[r13+24]
    mov rdx,[rsp+8]
    add rdx,r14
    lea rax,[rax+rdx*4]
    mov rdx,[r13]
    mov ecx,[rdx+rax]
    mov [rsp+24],rcx
    mov edx,eax
    shr edx,24
    mov r8d,ecx
    shr r8d,24
    mov r9d,255
    sub r9d,edx
    imul r8d,r9d
    mov r10d,edx
    imul r10d,255
    add r10d,r8d
    mov [rsp+32],r10
    test r10d,r10d
    jz .transparent
    mov eax,r10d
    add eax,127
    xor edx,edx
    mov r11d,255
    div r11d
    shl eax,24
    mov [rsp+40],rax
    mov qword [rsp+48],0
.cchannel:
    cmp qword [rsp+48],3
    jae .store
    mov rcx,[rsp+48]
    shl ecx,3
    mov rax,[rsp+16]
    shr rax,cl
    movzx eax,al
    mov r8,[rsp+16]
    shr r8,24
    imul eax,r8d
    imul eax,255
    mov rdx,[rsp+24]
    shr rdx,cl
    movzx edx,dl
    mov r9,[rsp+24]
    shr r9,24
    imul edx,r9d
    mov r11d,255
    sub r11d,r8d
    imul edx,r11d
    add rax,rdx
    mov rdx,[rsp+32]
    shr rdx,1
    add rax,rdx
    xor edx,edx
    div qword [rsp+32]
    mov rcx,[rsp+48]
    shl ecx,3
    shl rax,cl
    or [rsp+40],rax
    inc qword [rsp+48]
    jmp .cchannel
.transparent:
    mov qword [rsp+40],0
.store:
    mov rax,[rsp]
    add rax,r15
    imul eax,[r13+24]
    mov rdx,[rsp+8]
    add rdx,r14
    lea rax,[rax+rdx*4]
    mov rdx,[r13]
    mov rcx,[rsp+40]
    mov [rdx+rax],ecx
    inc qword [rsp+8]
    jmp .cx
.cnext_y:
    inc qword [rsp]
    jmp .cy
.format:
    mov eax,NEBO_MEDIA_E_FORMAT
    jmp .return
.bounds:
    mov eax,NEBO_MEDIA_E_BOUNDS
    jmp .return
.ok:
    xor eax,eax
.return:
    add rsp,64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
