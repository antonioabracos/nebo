; PATTERN-MATCHING-E-DESTRUCTURING-F03 bounded Image storage and generation-checked regions
bits 64
default rel
%define NEBO_IMAGE_IMPLEMENTATION 1
%include "runtime/image/image.inc"
section .text
global nebo_image_init
global nebo_image_wrap_mut
global nebo_image_width
global nebo_image_height
global nebo_image_stride
global nebo_image_pixel
global nebo_image_set_pixel
global nebo_image_region
global nebo_image_close

; rdi=desc rsi=data rdx=capacity rcx=width r8=height r9=format
nebo_image_init:
    mov [rsp-8],rdx
    test rdi,rdi
    jz .argument
    test rsi,rsi
    jz .argument
    test rcx,rcx
    jz .limit
    cmp rcx,2048
    ja .limit
    test r8,r8
    jz .limit
    cmp r8,2048
    ja .limit
    cmp r9d,NEBO_PIXEL_RGBA8
    je .rgba
    cmp r9d,NEBO_PIXEL_GRAY8
    jne .format
    mov r10d,1
    jmp .have_bpp
.rgba:
    mov r10d,4
.have_bpp:
    mov rax,rcx
    mul r10
    test rdx,rdx
    jnz .overflow
    cmp rax,65536
    ja .limit
    mov r11,rax
    mov rax,r8
    mul r11
    test rdx,rdx
    jnz .overflow
    cmp rax,16777216
    ja .limit
    cmp qword [rsp-8],rax
    jb .limit
    lea r10,[rsi+rax]
    cmp rdi,r10
    jae .no_overlap
    lea r10,[rdi+64]
    cmp r10,rsi
    ja .argument
.no_overlap:
    mov r10,rdi
    mov rdi,rsi
    mov r11,rax
    xor eax,eax
.zero:
    cmp rax,r11
    jae .publish
    mov byte [rdi+rax],0
    inc rax
    jmp .zero
.publish:
    mov [r10],rsi
    mov [r10+8],r11
    mov [r10+16],ecx
    mov [r10+20],r8d
    mov eax,ecx
    cmp r9d,NEBO_PIXEL_RGBA8
    jne .stride_ready
    shl eax,2
.stride_ready:
    mov [r10+24],eax
    mov [r10+28],r9w
    mov word [r10+30],NEBO_IMAGE_FLAG_OWNED|NEBO_IMAGE_FLAG_MUTABLE
    mov qword [r10+32],1
    mov qword [r10+40],0
    mov qword [r10+48],0
    mov qword [r10+56],0
    xor eax,eax
    ret
.argument:
    mov eax,NEBO_MEDIA_E_ARGUMENT
    ret
.format:
    mov eax,NEBO_MEDIA_E_FORMAT
    ret
.limit:
    mov eax,NEBO_MEDIA_E_LIMIT
    ret
.overflow:
    mov eax,NEBO_MEDIA_E_OVERFLOW
    ret

; rdi=desc rsi=data rdx=len rcx=width r8=height
; r9 low32=stride high32=format
nebo_image_wrap_mut:
    mov [rsp-8],rdx
    test rdi,rdi
    jz .argument
    test rsi,rsi
    jz .argument
    test rcx,rcx
    jz .limit
    cmp rcx,2048
    ja .limit
    test r8,r8
    jz .limit
    cmp r8,2048
    ja .limit
    mov r10,r9
    shr r10,32
    cmp r10d,NEBO_PIXEL_RGBA8
    je .wrap_rgba
    cmp r10d,NEBO_PIXEL_GRAY8
    jne .format
    mov r11d,1
    jmp .wrap_bpp
.wrap_rgba:
    mov r11d,4
.wrap_bpp:
    mov eax,ecx
    mul r11
    test edx,edx
    jnz .overflow
    cmp r9d,eax
    jb .limit
    cmp r9d,65536
    ja .limit
    mov eax,r9d
    mul r8
    test rdx,rdx
    jnz .overflow
    cmp rax,16777216
    ja .limit
    cmp qword [rsp-8],rax
    jb .limit
    lea r11,[rsi+rax]
    cmp rdi,r11
    jae .wrap_publish
    lea r11,[rdi+64]
    cmp r11,rsi
    ja .argument
.wrap_publish:
    mov [rdi],rsi
    mov rax,[rsp-8]
    mov [rdi+8],rax
    mov [rdi+16],ecx
    mov [rdi+20],r8d
    mov [rdi+24],r9d
    mov [rdi+28],r10w
    mov word [rdi+30],NEBO_IMAGE_FLAG_BORROWED|NEBO_IMAGE_FLAG_MUTABLE
    mov qword [rdi+32],1
    mov qword [rdi+40],0
    mov qword [rdi+48],0
    mov qword [rdi+56],0
    xor eax,eax
    ret
.argument:
    mov eax,NEBO_MEDIA_E_ARGUMENT
    ret
.format:
    mov eax,NEBO_MEDIA_E_FORMAT
    ret
.limit:
    mov eax,NEBO_MEDIA_E_LIMIT
    ret
.overflow:
    mov eax,NEBO_MEDIA_E_OVERFLOW
    ret

validate_desc:
    test rdi,rdi
    jz .argument
    test word [rdi+30],NEBO_IMAGE_FLAG_CLOSED
    jnz .stale
    cmp qword [rdi+32],0
    je .stale
    cmp qword [rdi],0
    je .stale
    mov r8,[rdi+40]
    test r8,r8
    jz .ok
    cmp qword [r8],0
    je .stale
    mov r9,[r8+32]
    cmp r9,[rdi+48]
    jne .stale
.ok:
    xor eax,eax
    ret
.argument:
    mov eax,NEBO_MEDIA_E_ARGUMENT
    ret
.stale:
    mov eax,NEBO_MEDIA_E_STALE
    ret

nebo_image_width:
    sub rsp,8
    call validate_desc
    add rsp,8
    test eax,eax
    jnz .done
    mov edx,[rdi+16]
.done:
    ret
nebo_image_height:
    sub rsp,8
    call validate_desc
    add rsp,8
    test eax,eax
    jnz .done
    mov edx,[rdi+20]
.done:
    ret
nebo_image_stride:
    sub rsp,8
    call validate_desc
    add rsp,8
    test eax,eax
    jnz .done
    mov edx,[rdi+24]
.done:
    ret

; rdi=desc rsi=x rdx=y -> eax=status edx=packed pixel
nebo_image_pixel:
    sub rsp,8
    call validate_desc
    add rsp,8
    test eax,eax
    jnz .done
    mov eax,[rdi+16]
    cmp rsi,rax
    jae .bounds
    mov eax,[rdi+20]
    cmp rdx,rax
    jae .bounds
    mov eax,[rdi+24]
    imul rdx,rax
    movzx eax,word [rdi+28]
    cmp eax,NEBO_PIXEL_RGBA8
    jne .gray
    lea rsi,[rdx+rsi*4]
    mov rax,[rdi]
    mov edx,[rax+rsi]
    xor eax,eax
    ret
.gray:
    add rdx,rsi
    mov rax,[rdi]
    movzx edx,byte [rax+rdx]
    xor eax,eax
    ret
.bounds:
    mov eax,NEBO_MEDIA_E_BOUNDS
    xor edx,edx
.done:
    ret

; rdi=desc rsi=x rdx=y rcx=packed RGBA
nebo_image_set_pixel:
    sub rsp,8
    call validate_desc
    add rsp,8
    test eax,eax
    jnz .done
    test word [rdi+30],NEBO_IMAGE_FLAG_MUTABLE
    jz .argument
    mov eax,[rdi+16]
    cmp rsi,rax
    jae .bounds
    mov eax,[rdi+20]
    cmp rdx,rax
    jae .bounds
    mov eax,[rdi+24]
    imul rdx,rax
    movzx eax,word [rdi+28]
    mov r8,[rdi]
    cmp eax,NEBO_PIXEL_RGBA8
    jne .gray
    lea rsi,[rdx+rsi*4]
    mov [r8+rsi],ecx
    xor eax,eax
    ret
.gray:
    movzx eax,cl
    imul eax,eax,13933
    mov r9d,ecx
    shr r9d,8
    movzx r9d,r9b
    imul r9d,r9d,46871
    add eax,r9d
    mov r9d,ecx
    shr r9d,16
    movzx r9d,r9b
    imul r9d,r9d,4732
    add eax,r9d
    add eax,32768
    shr eax,16
    add rdx,rsi
    mov [r8+rdx],al
    xor eax,eax
    ret
.argument:
    mov eax,NEBO_MEDIA_E_ARGUMENT
    ret
.bounds:
    mov eax,NEBO_MEDIA_E_BOUNDS
.done:
    ret

; rdi=dst rsi=source rdx=x rcx=y r8=width r9=height
nebo_image_region:
    test rdi,rdi
    jz .argument
    cmp rdi,rsi
    je .argument
    mov r10,r8
    mov r11,r9
    xchg rdi,rsi
    sub rsp,8
    call validate_desc
    add rsp,8
    xchg rdi,rsi
    test eax,eax
    jnz .done
    test r10,r10
    jz .bounds
    test r11,r11
    jz .bounds
    mov eax,[rsi+16]
    sub rax,rdx
    jb .bounds
    cmp r10,rax
    ja .bounds
    mov eax,[rsi+20]
    sub rax,rcx
    jb .bounds
    cmp r11,rax
    ja .bounds
    mov eax,[rsi+24]
    imul rcx,rax
    movzx r8d,word [rsi+28]
    cmp r8d,NEBO_PIXEL_RGBA8
    jne .region_gray
    lea rdx,[rdx*4]
.region_gray:
    add rcx,rdx
    mov rax,[rsi]
    add rax,rcx
    mov [rdi],rax
    mov rax,[rsi+8]
    sub rax,rcx
    mov [rdi+8],rax
    mov [rdi+16],r10d
    mov [rdi+20],r11d
    mov eax,[rsi+24]
    mov [rdi+24],eax
    mov ax,[rsi+28]
    mov [rdi+28],ax
    mov word [rdi+30],NEBO_IMAGE_FLAG_BORROWED|NEBO_IMAGE_FLAG_MUTABLE
    mov qword [rdi+32],1
    mov [rdi+40],rsi
    mov rax,[rsi+32]
    mov [rdi+48],rax
    mov qword [rdi+56],0
    xor eax,eax
    ret
.argument:
    mov eax,NEBO_MEDIA_E_ARGUMENT
    ret
.bounds:
    mov eax,NEBO_MEDIA_E_BOUNDS
.done:
    ret

nebo_image_close:
    test rdi,rdi
    jz .argument
    test word [rdi+30],NEBO_IMAGE_FLAG_CLOSED
    jnz .stale
    inc qword [rdi+32]
    mov qword [rdi],0
    or word [rdi+30],NEBO_IMAGE_FLAG_CLOSED
    xor eax,eax
    ret
.argument:
    mov eax,NEBO_MEDIA_E_ARGUMENT
    ret
.stale:
    mov eax,NEBO_MEDIA_E_STALE
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
