; PATTERN-MATCHING-E-DESTRUCTURING-F05 bounded deterministic BMP3 BI_RGB codec
bits 64
default rel
%define NEBO_BMP_IMPLEMENTATION 1
%include "runtime/image/bmp.inc"
section .text
global nebo_bmp_inspect
global nebo_bmp_decode
global nebo_bmp_encode

; rdi=bytes rsi=length rdx=out_meta[32]
; meta: width:u32 height:u32 bpp:u16 reserved:u16 row:u32 pixels:u64 file:u64
nebo_bmp_inspect:
    test rdi,rdi
    jz .argument
    test rdx,rdx
    jz .argument
    cmp rsi,NEBO_BMP_HEADER_BYTES
    jb .truncated
    cmp word [rdi],0x4d42
    jne .magic
    mov r8d,[rdi+2]
    cmp r8,rsi
    jne .header
    cmp r8d,NEBO_BMP_HEADER_BYTES
    jb .header
    cmp dword [rdi+10],NEBO_BMP_HEADER_BYTES
    jne .unsupported
    cmp dword [rdi+14],40
    jne .unsupported
    movsxd r9,dword [rdi+18]
    test r9,r9
    jle .limit
    cmp r9,2048
    ja .limit
    movsxd r10,dword [rdi+22]
    test r10,r10
    jle .unsupported
    cmp r10,2048
    ja .limit
    cmp word [rdi+26],1
    jne .unsupported
    movzx r11d,word [rdi+28]
    cmp r11d,24
    je .bpp24
    cmp r11d,32
    jne .unsupported
    mov eax,4
    jmp .have_bytes
.bpp24:
    mov eax,3
.have_bytes:
    cmp dword [rdi+30],0
    jne .unsupported
    imul rax,r9
    add rax,3
    jc .overflow
    and rax,-4
    cmp rax,8192
    ja .limit
    mov rcx,rax
    imul rax,r10
    jo .overflow
    cmp rax,16777216
    ja .limit
    mov r8d,[rdi+34]
    test r8d,r8d
    jz .image_size_ok
    cmp r8,rax
    jne .header
.image_size_ok:
    mov r8,rax
    add rax,NEBO_BMP_HEADER_BYTES
    jc .overflow
    cmp rax,rsi
    jne .header
    ; The output record must not alias the validated input buffer.
    lea rax,[rdx+NEBO_BMP_META_BYTES]
    cmp rax,rdi
    jbe .publish
    lea rax,[rdi+rsi]
    cmp rdx,rax
    jb .argument
.publish:
    mov [rdx],r9d
    mov [rdx+4],r10d
    mov [rdx+8],r11w
    mov word [rdx+10],0
    mov [rdx+12],ecx
    mov [rdx+16],r8
    mov [rdx+24],rsi
    xor eax,eax
    ret
.argument:
    mov eax,NEBO_MEDIA_E_ARGUMENT
    ret
.magic:
    mov eax,NEBO_BMP_E_MAGIC
    ret
.header:
    mov eax,NEBO_BMP_E_HEADER
    ret
.truncated:
    mov eax,NEBO_BMP_E_TRUNCATED
    ret
.unsupported:
    mov eax,NEBO_BMP_E_UNSUPPORTED
    ret
.limit:
    mov eax,NEBO_MEDIA_E_LIMIT
    ret
.overflow:
    mov eax,NEBO_MEDIA_E_OVERFLOW
    ret

; rdi=bytes rsi=length rdx=out_desc rcx=out_pixels r8=capacity
nebo_bmp_decode:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,40
    mov r14,rdi
    mov [rsp+32],rsi
    mov r12,rdx
    mov r13,rcx
    mov rbp,r8
    test r12,r12
    jz .decode_argument
    test r13,r13
    jz .decode_argument
    lea rdx,[rsp]
    call nebo_bmp_inspect
    test eax,eax
    jnz .decode_done
    mov r15d,[rsp]
    mov ebx,[rsp+4]
    mov eax,r15d
    imul rax,rbx
    shl rax,2
    cmp rax,16777216
    ja .decode_limit
    cmp rbp,rax
    jb .decode_capacity
    ; Reject every input/output overlap before writing either object.
    lea rcx,[r13+rax]
    jc .decode_argument
    mov rdx,[rsp+32]
    lea rsi,[r14+rdx]
    jc .decode_argument
    cmp r13,rsi
    jae .decode_check_desc_pixels
    cmp r14,rcx
    jb .decode_argument
.decode_check_desc_pixels:
    cmp r12,rcx
    jae .decode_no_overlap
    lea rcx,[r12+NEBO_IMAGE_DESC_BYTES]
    cmp rcx,r13
    ja .decode_argument
.decode_no_overlap:
    lea rcx,[r12+NEBO_IMAGE_DESC_BYTES]
    jc .decode_argument
    cmp r12,rsi
    jae .decode_ranges_safe
    cmp r14,rcx
    jb .decode_argument
.decode_ranges_safe:
    xor r8d,r8d                 ; logical destination y
.decode_y:
    cmp r8d,ebx
    jae .decode_publish
    mov eax,ebx
    dec eax
    sub eax,r8d
    mov ecx,[rsp+12]
    imul rax,rcx
    lea r9,[r14+NEBO_BMP_HEADER_BYTES]
    add r9,rax
    mov eax,r8d
    imul eax,r15d
    shl rax,2
    lea r10,[r13+rax]
    xor ecx,ecx
.decode_x:
    cmp ecx,r15d
    jae .decode_next_y
    movzx eax,byte [r9+2]
    mov [r10],al
    movzx eax,byte [r9+1]
    mov [r10+1],al
    movzx eax,byte [r9]
    mov [r10+2],al
    movzx eax,word [rsp+8]
    cmp eax,32
    jne .decode_opaque
    mov al,[r9+3]
    jmp .decode_alpha
.decode_opaque:
    mov al,255
.decode_alpha:
    mov [r10+3],al
    movzx eax,word [rsp+8]
    shr eax,3
    add r9,rax
    add r10,4
    inc ecx
    jmp .decode_x
.decode_next_y:
    inc r8d
    jmp .decode_y
.decode_publish:
    mov [r12],r13
    mov eax,r15d
    imul rax,rbx
    shl rax,2
    mov [r12+8],rax
    mov [r12+16],r15d
    mov [r12+20],ebx
    mov eax,r15d
    shl eax,2
    mov [r12+24],eax
    mov word [r12+28],NEBO_PIXEL_RGBA8
    mov word [r12+30],NEBO_IMAGE_FLAG_OWNED|NEBO_IMAGE_FLAG_MUTABLE
    mov qword [r12+32],1
    mov qword [r12+40],0
    mov qword [r12+48],0
    mov qword [r12+56],0
    xor eax,eax
    jmp .decode_done
.decode_argument:
    mov eax,NEBO_MEDIA_E_ARGUMENT
    jmp .decode_done
.decode_capacity:
    mov eax,NEBO_BMP_E_CAPACITY
    jmp .decode_done
.decode_limit:
    mov eax,NEBO_MEDIA_E_LIMIT
.decode_done:
    add rsp,40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; rdi=image_desc rsi=out_bytes rdx=capacity rcx=out_length
; Canonical encoder: BMP3 BI_RGB 32-bit bottom-up BGRA, exact file length.
nebo_bmp_encode:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    test rdi,rdi
    jz .encode_argument
    test rsi,rsi
    jz .encode_argument
    test rcx,rcx
    jz .encode_argument
    test word [rdi+30],NEBO_IMAGE_FLAG_CLOSED
    jnz .encode_stale
    cmp qword [rdi+32],0
    je .encode_stale
    mov r12,[rdi]
    test r12,r12
    jz .encode_stale
    cmp word [rdi+28],NEBO_PIXEL_RGBA8
    jne .encode_format
    mov r13d,[rdi+16]
    test r13d,r13d
    jz .encode_limit
    cmp r13d,2048
    ja .encode_limit
    mov r14d,[rdi+20]
    test r14d,r14d
    jz .encode_limit
    cmp r14d,2048
    ja .encode_limit
    mov r15d,r13d
    shl r15d,2
    cmp [rdi+24],r15d
    jb .encode_header
    mov eax,[rdi+24]
    imul rax,r14
    cmp rax,[rdi+8]
    ja .encode_header
    mov eax,r15d
    imul rax,r14
    cmp rax,16777216
    ja .encode_limit
    lea rbx,[rax+NEBO_BMP_HEADER_BYTES]
    cmp rdx,rbx
    jb .encode_capacity
    mov rbp,rsi
    ; Destination may not alias the descriptor, source pixels, or length cell.
    lea r8,[rsi+rbx]
    cmp rdi,r8
    jae .encode_check_source
    lea r9,[rdi+NEBO_IMAGE_DESC_BYTES]
    cmp r9,rsi
    ja .encode_argument
.encode_check_source:
    mov eax,[rdi+24]
    imul rax,r14
    lea r9,[r12+rax]
    cmp rsi,r9
    jae .encode_check_len
    cmp r12,r8
    jb .encode_argument
.encode_check_len:
    lea r9,[rcx+8]
    cmp r9,rsi
    jbe .encode_ready
    cmp rcx,r8
    jb .encode_argument
.encode_ready:
    xor eax,eax
    xor r8d,r8d
.encode_zero_header:
    cmp r8d,NEBO_BMP_HEADER_BYTES
    jae .encode_header_fields
    mov [rbp+r8],al
    inc r8d
    jmp .encode_zero_header
.encode_header_fields:
    mov word [rbp],0x4d42
    mov [rbp+2],ebx
    mov dword [rbp+10],NEBO_BMP_HEADER_BYTES
    mov dword [rbp+14],40
    mov [rbp+18],r13d
    mov [rbp+22],r14d
    mov word [rbp+26],1
    mov word [rbp+28],32
    mov dword [rbp+30],0
    mov eax,r15d
    imul eax,r14d
    mov [rbp+34],eax
    xor r8d,r8d
.encode_y:
    cmp r8d,r14d
    jae .encode_publish
    mov eax,r14d
    dec eax
    sub eax,r8d
    mov r9d,[rdi+24]
    imul rax,r9
    lea r10,[r12+rax]
    mov eax,r8d
    imul eax,r15d
    lea r11,[rbp+NEBO_BMP_HEADER_BYTES]
    add r11,rax
    xor r9d,r9d
.encode_x:
    cmp r9d,r13d
    jae .encode_next_y
    mov al,[r10+2]
    mov [r11],al
    mov al,[r10+1]
    mov [r11+1],al
    mov al,[r10]
    mov [r11+2],al
    mov al,[r10+3]
    mov [r11+3],al
    add r10,4
    add r11,4
    inc r9d
    jmp .encode_x
.encode_next_y:
    inc r8d
    jmp .encode_y
.encode_publish:
    mov [rcx],rbx
    xor eax,eax
    jmp .encode_done
.encode_argument:
    mov eax,NEBO_MEDIA_E_ARGUMENT
    jmp .encode_done
.encode_stale:
    mov eax,NEBO_MEDIA_E_STALE
    jmp .encode_done
.encode_format:
    mov eax,NEBO_MEDIA_E_FORMAT
    jmp .encode_done
.encode_header:
    mov eax,NEBO_BMP_E_HEADER
    jmp .encode_done
.encode_limit:
    mov eax,NEBO_MEDIA_E_LIMIT
    jmp .encode_done
.encode_capacity:
    mov eax,NEBO_BMP_E_CAPACITY
.encode_done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
