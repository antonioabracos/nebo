; PATTERN-MATCHING-E-DESTRUCTURING-F08 bounded offline S16LE PCM
bits 64
default rel
%define NEBO_PCM_IMPLEMENTATION 1
%include "runtime/audio/pcm.inc"
section .text
global nebo_pcm_init
global nebo_pcm_duration_us
global nebo_pcm_mix_into
global nebo_pcm_resample_linear_into

; desc: data,capacity,frames:u32,rate:u32,channels:u16,flags:u16,format:u32,
;       generation:u64,reserved[3]
; rdi=desc rsi=data rdx=capacity rcx=frames r8=rate r9=channels
nebo_pcm_init:
    test rdi,rdi
    jz .argument
    test rsi,rsi
    jz .argument
    test rcx,rcx
    jz .limit
    cmp rcx,1000000
    ja .limit
    cmp r8,8000
    jb .range
    cmp r8,96000
    ja .range
    cmp r9,1
    je .channels_ok
    cmp r9,2
    jne .format
.channels_ok:
    mov rax,rcx
    imul rax,r9
    jo .overflow
    shl rax,1
    jc .overflow
    cmp rdx,rax
    jb .limit
    mov r10,rsi
    add r10,rax
    jc .argument
    cmp rdi,r10
    jae .publish_prepare
    lea r11,[rdi+NEBO_PCM_DESC_BYTES]
    cmp r11,rsi
    ja .argument
.publish_prepare:
    mov r10,rdi
    mov r11,rax
    mov rdi,rsi
    xor eax,eax
    mov rcx,r11
    shr rcx,1
    rep stosw
    mov [r10],rsi
    mov [r10+8],rdx
    mov [r10+16],ecx
    ; rep consumed rcx; recover frames from byte count/channels/2.
    mov rax,r11
    shr rax,1
    xor edx,edx
    div r9
    mov [r10+16],eax
    mov [r10+20],r8d
    mov [r10+24],r9w
    mov word [r10+26],NEBO_PCM_FLAG_OWNED|NEBO_PCM_FLAG_MUTABLE
    mov dword [r10+28],NEBO_PCM_FORMAT_S16LE
    mov qword [r10+32],1
    mov qword [r10+40],0
    mov qword [r10+48],0
    mov qword [r10+56],0
    xor eax,eax
    ret
.argument: mov eax,NEBO_PCM_E_ARGUMENT
    ret
.format: mov eax,NEBO_PCM_E_FORMAT
    ret
.range: mov eax,NEBO_PCM_E_RANGE
    ret
.limit: mov eax,NEBO_PCM_E_LIMIT
    ret
.overflow: mov eax,NEBO_PCM_E_OVERFLOW
    ret

pcm_validate:
    test rdi,rdi
    jz .argument
    cmp qword [rdi],0
    je .stale
    cmp qword [rdi+32],0
    je .stale
    test word [rdi+26],NEBO_PCM_FLAG_CLOSED
    jnz .stale
    cmp dword [rdi+28],NEBO_PCM_FORMAT_S16LE
    jne .format
    mov eax,[rdi+16]
    test eax,eax
    jz .limit
    cmp eax,1000000
    ja .limit
    mov ecx,[rdi+20]
    cmp ecx,8000
    jb .range
    cmp ecx,96000
    ja .range
    movzx ecx,word [rdi+24]
    cmp ecx,1
    je .size
    cmp ecx,2
    jne .format
.size:
    imul rax,rcx
    shl rax,1
    cmp [rdi+8],rax
    jb .limit
    xor eax,eax
    ret
.argument: mov eax,NEBO_PCM_E_ARGUMENT
    ret
.format: mov eax,NEBO_PCM_E_FORMAT
    ret
.range: mov eax,NEBO_PCM_E_RANGE
    ret
.limit: mov eax,NEBO_PCM_E_LIMIT
    ret
.stale: mov eax,NEBO_PCM_E_STALE
    ret

; rdi=desc -> eax=status rdx=floor microseconds
nebo_pcm_duration_us:
    sub rsp,8
    call pcm_validate
    add rsp,8
    test eax,eax
    jnz .duration_done
    mov eax,[rdi+16]
    imul rax,1000000
    xor edx,edx
    mov ecx,[rdi+20]
    div rcx
    mov rdx,rax
    xor eax,eax
.duration_done:
    ret

; rdi=mutable dst rsi=src rdx=gain_q15 [0,32768]
nebo_pcm_mix_into:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    mov rbp,rdx
    cmp rbp,32768
    ja .mix_range
    call pcm_validate
    test eax,eax
    jnz .mix_done
    mov rdi,r13
    call pcm_validate
    test eax,eax
    jnz .mix_done
    test word [r12+26],NEBO_PCM_FLAG_MUTABLE
    jz .mix_stale
    mov eax,[r12+16]
    cmp eax,[r13+16]
    jne .mix_mismatch
    mov eax,[r12+20]
    cmp eax,[r13+20]
    jne .mix_mismatch
    movzx eax,word [r12+24]
    cmp ax,[r13+24]
    jne .mix_mismatch
    imul eax,[r12+16]
    mov r14d,eax
    mov r8,[r12]
    mov r9,[r13]
    mov eax,r14d
    shl rax,1
    lea r10,[r8+rax]
    lea r11,[r9+rax]
    cmp r8,r11
    jae .mix_loop_setup
    cmp r9,r10
    jb .mix_overlap
.mix_loop_setup:
    xor ebx,ebx
.mix_loop:
    cmp ebx,r14d
    jae .mix_ok
    movsx eax,word [r9+rbx*2]
    imul eax,ebp
    test eax,eax
    js .mix_negative
    add eax,16384
    jmp .mix_shift
.mix_negative:
    add eax,16383
.mix_shift:
    sar eax,15
    movsx edx,word [r8+rbx*2]
    add eax,edx
    cmp eax,32767
    jle .mix_low
    mov eax,32767
    jmp .mix_store
.mix_low:
    cmp eax,-32768
    jge .mix_store
    mov eax,-32768
.mix_store:
    mov [r8+rbx*2],ax
    inc ebx
    jmp .mix_loop
.mix_ok:
    xor eax,eax
    jmp .mix_done
.mix_range: mov eax,NEBO_PCM_E_RANGE
    jmp .mix_done
.mix_stale: mov eax,NEBO_PCM_E_STALE
    jmp .mix_done
.mix_mismatch: mov eax,NEBO_PCM_E_MISMATCH
    jmp .mix_done
.mix_overlap: mov eax,NEBO_PCM_E_OVERLAP
.mix_done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; rdi=preinitialized mutable dst rsi=src. Output frame count must equal
; ceil(src_frames * dst_rate / src_rate).
nebo_pcm_resample_linear_into:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    call pcm_validate
    test eax,eax
    jnz .res_done
    mov rdi,r13
    call pcm_validate
    test eax,eax
    jnz .res_done
    test word [r12+26],NEBO_PCM_FLAG_MUTABLE
    jz .res_stale
    movzx eax,word [r12+24]
    cmp ax,[r13+24]
    jne .res_mismatch
    mov eax,[r13+16]
    mov ecx,[r12+20]
    imul rax,rcx
    mov ecx,[r13+20]
    lea rax,[rax+rcx-1]
    xor edx,edx
    div rcx
    cmp eax,[r12+16]
    jne .res_mismatch
    mov r14,[r12]
    mov r15,[r13]
    mov eax,[r12+16]
    movzx ecx,word [r12+24]
    imul rax,rcx
    shl rax,1
    lea r8,[r14+rax]
    mov eax,[r13+16]
    movzx ecx,word [r13+24]
    imul rax,rcx
    shl rax,1
    lea r9,[r15+rax]
    cmp r14,r9
    jae .res_loop_setup
    cmp r15,r8
    jb .res_overlap
.res_loop_setup:
    xor ebx,ebx
.res_frame:
    cmp ebx,[r12+16]
    jae .res_ok
    mov rax,rbx
    mov ecx,[r13+20]
    imul rax,rcx
    shl rax,16
    xor edx,edx
    mov ecx,[r12+20]
    div rcx
    mov r8,rax
    shr r8,16
    movzx r9d,ax
    mov eax,[r13+16]
    dec eax
    cmp r8,rax
    jb .res_have_pair
    mov r8,rax
    xor r9d,r9d
.res_have_pair:
    xor ebp,ebp
.res_channel:
    movzx ecx,word [r12+24]
    cmp ebp,ecx
    jae .res_next_frame
    mov rax,r8
    imul rax,rcx
    add rax,rbp
    movsx r10,word [r15+rax*2]
    mov r11,r8
    inc r11
    cmp r11,[r13+16]
    jb .res_second
    mov r11,r8
.res_second:
    imul r11,rcx
    add r11,rbp
    movsx r11,word [r15+r11*2]
    mov ecx,65536
    sub ecx,r9d
    imul r10,rcx
    imul r11,r9
    add r10,r11
    test r10,r10
    js .res_negative
    add r10,32768
    jmp .res_shift
.res_negative:
    add r10,32767
.res_shift:
    sar r10,16
    mov eax,ebx
    movzx ecx,word [r12+24]
    imul rax,rcx
    add rax,rbp
    mov [r14+rax*2],r10w
    inc ebp
    jmp .res_channel
.res_next_frame:
    inc ebx
    jmp .res_frame
.res_ok:
    xor eax,eax
    jmp .res_done
.res_stale: mov eax,NEBO_PCM_E_STALE
    jmp .res_done
.res_mismatch: mov eax,NEBO_PCM_E_MISMATCH
    jmp .res_done
.res_overlap: mov eax,NEBO_PCM_E_OVERLAP
.res_done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
