; PATTERN-MATCHING-E-DESTRUCTURING-F09 bounded single-owner finite video queue
bits 64
default rel
%define NEBO_VIDEO_PIPELINE_IMPLEMENTATION 1
%include "runtime/video/video_pipeline.inc"
section .text
global nebo_video_frame_init
global nebo_video_frame_transform_copy
global nebo_video_pipeline_init
global nebo_video_pipeline_push
global nebo_video_pipeline_pop
global nebo_video_pipeline_cancel
global nebo_video_pipeline_close

video_validate_image:
    test rdi,rdi
    jz .stale
    cmp qword [rdi],0
    je .stale
    cmp qword [rdi+32],0
    je .stale
    test word [rdi+30],NEBO_IMAGE_FLAG_CLOSED
    jnz .stale
    xor eax,eax
    ret
.stale:
    mov eax,NEBO_VIDEO_E_STALE_IMAGE
    ret

; rdi=out frame rsi=Image* rdx=timestamp_us rcx=duration_us
nebo_video_frame_init:
    sub rsp,8
    test rdi,rdi
    jz .argument
    test rcx,rcx
    jz .timestamp
    test rdx,rdx
    js .timestamp
    mov r8,rdi
    mov rdi,rsi
    call video_validate_image
    test eax,eax
    jnz .done
    mov [r8],rsi
    mov [r8+8],rdx
    mov [r8+16],rcx
    mov qword [r8+24],0
    mov dword [r8+32],NEBO_VIDEO_FRAME_FLAG_VALID
    mov dword [r8+36],0
    xor eax,eax
.done:
    add rsp,8
    ret
.argument:
    mov eax,NEBO_VIDEO_E_ARGUMENT
    add rsp,8
    ret
.timestamp:
    mov eax,NEBO_VIDEO_E_TIMESTAMP
    add rsp,8
    ret

; rdi=out frame rsi=input frame rdx=transformed Image*
nebo_video_frame_transform_copy:
    sub rsp,8
    test rdi,rdi
    jz .argument
    test rsi,rsi
    jz .argument
    test dword [rsi+32],NEBO_VIDEO_FRAME_FLAG_VALID
    jz .argument
    cmp dword [rsi+36],0
    jne .argument
    mov r8,rdi
    mov r9,rsi
    mov rdi,rdx
    call video_validate_image
    test eax,eax
    jnz .done
    mov [r8],rdx
    mov rax,[r9+8]
    mov [r8+8],rax
    mov rax,[r9+16]
    mov [r8+16],rax
    mov rax,[r9+24]
    mov [r8+24],rax
    mov eax,[r9+32]
    or eax,NEBO_VIDEO_FRAME_FLAG_TRANSFORMED
    mov [r8+32],eax
    mov dword [r8+36],0
    xor eax,eax
.done:
    add rsp,8
    ret
.argument:
    mov eax,NEBO_VIDEO_E_ARGUMENT
    add rsp,8
    ret

; rdi=pipeline rsi=slot storage rdx=capacity 1..16
nebo_video_pipeline_init:
    test rdi,rdi
    jz .argument
    test rsi,rsi
    jz .argument
    test rdx,rdx
    jz .limit
    cmp rdx,16
    ja .limit
    imul rcx,rdx,NEBO_VIDEO_FRAME_BYTES
    mov r8,rsi
    add r8,rcx
    jc .argument
    cmp rdi,r8
    jae .zero
    lea r8,[rdi+NEBO_VIDEO_PIPELINE_BYTES]
    cmp r8,rsi
    ja .argument
.zero:
    mov r8,rdi
    mov r9,rdx
    mov rdi,rsi
    xor eax,eax
    rep stosb
    mov rdi,r8
    mov ecx,NEBO_VIDEO_PIPELINE_BYTES/8
    rep stosq
    mov [r8],rsi
    mov [r8+8],r9
    mov qword [r8+40],NEBO_VIDEO_PIPELINE_ACTIVE
    mov qword [r8+48],1
    xor eax,eax
    ret
.argument: mov eax,NEBO_VIDEO_E_ARGUMENT
    ret
.limit: mov eax,NEBO_VIDEO_E_LIMIT
    ret

video_validate_pipeline:
    test rdi,rdi
    jz .state
    cmp qword [rdi],0
    je .state
    mov rax,[rdi+8]
    test rax,rax
    jz .state
    cmp rax,16
    ja .state
    mov rax,[rdi+32]
    cmp rax,[rdi+8]
    ja .state
    xor eax,eax
    ret
.state:
    mov eax,NEBO_VIDEO_E_STATE
    ret

; rdi=pipeline rsi=frame
nebo_video_pipeline_push:
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    call video_validate_pipeline
    test eax,eax
    jnz .push_done
    cmp qword [r12+40],NEBO_VIDEO_PIPELINE_CANCELLED
    je .push_cancelled
    cmp qword [r12+40],NEBO_VIDEO_PIPELINE_CLOSED
    je .push_closed
    cmp qword [r12+40],NEBO_VIDEO_PIPELINE_ACTIVE
    jne .push_state
    test r13,r13
    jz .push_argument
    test dword [r13+32],NEBO_VIDEO_FRAME_FLAG_VALID
    jz .push_argument
    cmp dword [r13+36],0
    jne .push_argument
    mov rdi,[r13]
    call video_validate_image
    test eax,eax
    jnz .push_done
    mov rax,[r12+32]
    cmp rax,[r12+8]
    jae .push_full
    cmp qword [r12+64],0
    je .push_timestamp_ok
    mov rax,[r13+8]
    cmp rax,[r12+56]
    jb .push_timestamp
.push_timestamp_ok:
    mov rax,[r12+24]
    imul rax,NEBO_VIDEO_FRAME_BYTES
    add rax,[r12]
    mov rbx,rax
    mov rcx,NEBO_VIDEO_FRAME_BYTES/8
    mov rsi,r13
    mov rdi,rbx
    rep movsq
    mov rax,[r12+48]
    mov [rbx+24],rax
    inc qword [r12+48]
    mov rax,[r13+8]
    mov [r12+56],rax
    inc qword [r12+64]
    inc qword [r12+32]
    inc qword [r12+24]
    mov rax,[r12+24]
    cmp rax,[r12+8]
    jb .push_ok
    mov qword [r12+24],0
.push_ok:
    xor eax,eax
    jmp .push_done
.push_argument: mov eax,NEBO_VIDEO_E_ARGUMENT
    jmp .push_done
.push_state: mov eax,NEBO_VIDEO_E_STATE
    jmp .push_done
.push_full: mov eax,NEBO_VIDEO_E_FULL
    jmp .push_done
.push_timestamp: mov eax,NEBO_VIDEO_E_TIMESTAMP
    jmp .push_done
.push_cancelled: mov eax,NEBO_VIDEO_E_CANCELLED
    jmp .push_done
.push_closed: mov eax,NEBO_VIDEO_E_CLOSED
.push_done:
    pop r13
    pop r12
    pop rbx
    ret

; rdi=pipeline rsi=out_frame
nebo_video_pipeline_pop:
    push r12
    push r13
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    call video_validate_pipeline
    test eax,eax
    jnz .pop_done
    cmp qword [r12+40],NEBO_VIDEO_PIPELINE_CANCELLED
    je .pop_cancelled
    cmp qword [r12+40],NEBO_VIDEO_PIPELINE_CLOSED
    je .pop_closed
    test r13,r13
    jz .pop_argument
    cmp qword [r12+32],0
    je .pop_empty
    mov rax,[r12+16]
    imul rax,NEBO_VIDEO_FRAME_BYTES
    add rax,[r12]
    mov r8,rax
    mov rsi,r8
    mov rdi,r13
    mov ecx,NEBO_VIDEO_FRAME_BYTES/8
    rep movsq
    mov rdi,r8
    xor eax,eax
    mov ecx,NEBO_VIDEO_FRAME_BYTES/8
    rep stosq
    inc qword [r12+16]
    mov rax,[r12+16]
    cmp rax,[r12+8]
    jb .pop_count
    mov qword [r12+16],0
.pop_count:
    dec qword [r12+32]
    inc qword [r12+72]
    xor eax,eax
    jmp .pop_done
.pop_argument: mov eax,NEBO_VIDEO_E_ARGUMENT
    jmp .pop_done
.pop_empty: mov eax,NEBO_VIDEO_E_EMPTY
    jmp .pop_done
.pop_cancelled: mov eax,NEBO_VIDEO_E_CANCELLED
    jmp .pop_done
.pop_closed: mov eax,NEBO_VIDEO_E_CLOSED
.pop_done:
    add rsp,8
    pop r13
    pop r12
    ret

pipeline_zero_slots:
    mov rcx,[rdi+8]
    imul rcx,NEBO_VIDEO_FRAME_BYTES/8
    mov rdi,[rdi]
    xor eax,eax
    rep stosq
    ret

nebo_video_pipeline_cancel:
    push r12
    mov r12,rdi
    call video_validate_pipeline
    test eax,eax
    jnz .cancel_done
    cmp qword [r12+40],NEBO_VIDEO_PIPELINE_CLOSED
    je .cancel_closed
    mov rdi,r12
    call pipeline_zero_slots
    mov qword [r12+16],0
    mov qword [r12+24],0
    mov qword [r12+32],0
    mov qword [r12+40],NEBO_VIDEO_PIPELINE_CANCELLED
    inc qword [r12+80]
    xor eax,eax
    jmp .cancel_done
.cancel_closed: mov eax,NEBO_VIDEO_E_CLOSED
.cancel_done:
    pop r12
    ret

nebo_video_pipeline_close:
    push r12
    mov r12,rdi
    call video_validate_pipeline
    test eax,eax
    jnz .close_done
    cmp qword [r12+40],NEBO_VIDEO_PIPELINE_CLOSED
    je .close_closed
    mov rdi,r12
    call pipeline_zero_slots
    mov qword [r12+16],0
    mov qword [r12+24],0
    mov qword [r12+32],0
    mov qword [r12+40],NEBO_VIDEO_PIPELINE_CLOSED
    xor eax,eax
    jmp .close_done
.close_closed: mov eax,NEBO_VIDEO_E_CLOSED
.close_done:
    pop r12
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
