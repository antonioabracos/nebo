; PATTERN-MATCHING-E-DESTRUCTURING-F07 capability-file BMP-only Image I/O adapter
bits 64
default rel
%define NEBO_IMAGE_IO_IMPLEMENTATION 1
%include "runtime/image/image_io.inc"
section .text
global nebo_image_load
global nebo_image_save

; load request[64]: File*, file_bytes, scratch*, scratch_cap, Image*, pixels*,
;                   pixel_cap, reserved_zero
nebo_image_load:
    push r12
    mov r12,rdi
    test r12,r12
    jz .load_argument
    cmp qword [r12+56],0
    jne .load_argument
    cmp qword [r12],0
    je .load_argument
    mov rdx,[r12+8]
    cmp rdx,NEBO_BMP_HEADER_BYTES
    jb .load_limit
    cmp rdx,16777270
    ja .load_limit
    cmp qword [r12+16],0
    je .load_argument
    cmp qword [r12+24],rdx
    jb .load_capacity
    cmp qword [r12+32],0
    je .load_argument
    cmp qword [r12+40],0
    je .load_argument
    cmp qword [r12+48],0
    je .load_capacity
    mov rdi,[r12]
    mov rsi,[r12+16]
    call nebo_file_read_exact
    test eax,eax
    jnz .load_file
    cmp rdx,[r12+8]
    jne .load_file_short
    mov rdi,[r12+16]
    mov rsi,[r12+8]
    mov rdx,[r12+32]
    mov rcx,[r12+40]
    mov r8,[r12+48]
    call nebo_bmp_decode
    jmp .load_done
.load_argument:
    mov eax,NEBO_MEDIA_E_ARGUMENT
    jmp .load_done
.load_limit:
    mov eax,NEBO_MEDIA_E_LIMIT
    jmp .load_done
.load_capacity:
    mov eax,NEBO_BMP_E_CAPACITY
    jmp .load_done
.load_file_short:
    mov eax,NEBO_FILE_ERROR_EOF
.load_file:
    add eax,NEBO_IMAGE_IO_E_FILE_BASE
.load_done:
    pop r12
    ret

; save request[64]: File*, Image*, scratch*, scratch_cap, out_len*, reserved...
nebo_image_save:
    push r12
    sub rsp,16
    mov r12,rdi
    test r12,r12
    jz .save_argument
    cmp qword [r12+40],0
    jne .save_argument
    cmp qword [r12+48],0
    jne .save_argument
    cmp qword [r12+56],0
    jne .save_argument
    cmp qword [r12],0
    je .save_argument
    cmp qword [r12+8],0
    je .save_argument
    cmp qword [r12+16],0
    je .save_argument
    cmp qword [r12+32],0
    je .save_argument
    mov rdi,[r12+8]
    mov rsi,[r12+16]
    mov rdx,[r12+24]
    lea rcx,[rsp]
    call nebo_bmp_encode
    test eax,eax
    jnz .save_done
    mov rdi,[r12]
    mov rsi,[r12+16]
    mov rdx,[rsp]
    call nebo_file_write_all
    test eax,eax
    jnz .save_file
    cmp rdx,[rsp]
    jne .save_file_short
    mov rcx,[r12+32]
    mov rax,[rsp]
    mov [rcx],rax
    xor eax,eax
    jmp .save_done
.save_argument:
    mov eax,NEBO_MEDIA_E_ARGUMENT
    jmp .save_done
.save_file_short:
    mov eax,NEBO_FILE_ERROR_IO
.save_file:
    add eax,NEBO_IMAGE_IO_E_FILE_BASE
.save_done:
    add rsp,16
    pop r12
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
