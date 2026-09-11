; G102 deterministic logical animation/export owner. Backends may consume its
; manifest, but the core has no codec, libc, filesystem or display dependency.
bits 64
default rel
%define NEBO_G102_ANIMATION_EXPORT_IMPLEMENTATION 1
%include "runtime/console/animation_export.inc"

global nebo_g102_animation_export_model

section .rodata
g102_model_masks: dq 0x0003,0x0048,0x00a8,0x1002,0x0804
                  dq 0x0610,0x2150,0x6200,0x2214,0x7fff

section .text
; RDI=frame count, RSI=frame interval ns, RDX=seed.
g102_timeline_digest:
    mov rax,0x414e494d41544531
    xor r8d,r8d
.loop:
    cmp r8,rdi
    jae .done
    mov r9,r8
    imul r9,rsi
    xor rax,r9
    rol rax,11
    xor rax,rdx
    add rax,r8
    rol rax,7
    inc r8
    jmp .loop
.done:
    ret

; RDI=request, RSI=result. The result remains untouched on every failure.
nebo_g102_animation_export_model:
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,152
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    jz .invalid
    test r13,r13
    jz .invalid

    mov rax,[r12+NEBO_G102_REQUEST_MODE_OFFSET]
    cmp rax,1
    jb .invalid
    cmp rax,10
    ja .invalid
    lea rdx,[rel g102_model_masks]
    mov rcx,[rdx+rax*8-8]
    cmp [r12+NEBO_G102_REQUEST_OPTIONS_OFFSET],rcx
    jne .options
    test rcx,~NEBO_G102_OPTION_KNOWN
    jnz .options
    mov rax,[r12+NEBO_G102_REQUEST_TARGET_OFFSET]
    cmp rax,NEBO_G102_TARGET_HEADLESS
    jb .target
    cmp rax,NEBO_G102_TARGET_LIVE
    ja .target
    cmp qword [r12+NEBO_G102_REQUEST_SPEC_VERSION_OFFSET],NEBO_G102_SPEC_VERSION
    jne .version

    mov r14,[r12+NEBO_G102_REQUEST_FRAME_COUNT_OFFSET]
    cmp r14,1
    jb .bounds
    cmp r14,240
    ja .bounds
    mov r15,[r12+NEBO_G102_REQUEST_FPS_OFFSET]
    cmp r15,1
    jb .timing
    cmp r15,240
    ja .timing
    mov rax,r14
    imul rax,1000
    lea rax,[rax+r15-1]
    xor edx,edx
    div r15
    cmp [r12+NEBO_G102_REQUEST_DURATION_MS_OFFSET],rax
    jne .timing
    cmp rax,1
    jb .timing
    cmp rax,86400000
    ja .timing
    cmp qword [r12+NEBO_G102_REQUEST_LOOP_OFFSET],1
    ja .invalid
    mov rax,[r12+NEBO_G102_REQUEST_SEED_OFFSET]
    cmp rax,1
    jb .invalid
    cmp rax,255
    ja .invalid
    mov rax,[r12+NEBO_G102_REQUEST_WIDTH_OFFSET]
    cmp rax,64
    jb .bounds
    cmp rax,16384
    ja .bounds
    mov rax,[r12+NEBO_G102_REQUEST_HEIGHT_OFFSET]
    cmp rax,64
    jb .bounds
    cmp rax,16384
    ja .bounds

    mov rbx,[r12+NEBO_G102_REQUEST_OPTIONS_OFFSET]
    test rbx,NEBO_G102_OPTION_SCREENSHOT
    jz .capture_only
    cmp qword [r12+NEBO_G102_REQUEST_CAPTURE_MODE_OFFSET],NEBO_G102_CAPTURE_SCREENSHOT
    jne .format
    jmp .capture_capability
.capture_only:
    test rbx,NEBO_G102_OPTION_CAPTURE
    jz .no_capture
    cmp qword [r12+NEBO_G102_REQUEST_CAPTURE_MODE_OFFSET],NEBO_G102_CAPTURE_FRAME
    jne .format
.capture_capability:
    test qword [r12+NEBO_G102_REQUEST_CAPABILITIES_OFFSET],NEBO_G102_CAP_CAPTURE
    jz .capability
    jmp .format_check
.no_capture:
    cmp qword [r12+NEBO_G102_REQUEST_CAPTURE_MODE_OFFSET],NEBO_G102_CAPTURE_NONE
    jne .format

.format_check:
    test rbx,NEBO_G102_OPTION_MP4
    jz .not_mp4
    cmp qword [r12+NEBO_G102_REQUEST_FORMAT_OFFSET],NEBO_G102_FORMAT_MP4
    jne .format
    jmp .export_capability
.not_mp4:
    test rbx,NEBO_G102_OPTION_PNG
    jz .not_png
    cmp qword [r12+NEBO_G102_REQUEST_FORMAT_OFFSET],NEBO_G102_FORMAT_PNG
    jne .format
    jmp .export_capability
.not_png:
    test rbx,NEBO_G102_OPTION_EXPORT
    jz .no_export
    cmp qword [r12+NEBO_G102_REQUEST_FORMAT_OFFSET],NEBO_G102_FORMAT_FRAMES
    jne .format
    jmp .export_capability
.no_export:
    cmp qword [r12+NEBO_G102_REQUEST_FORMAT_OFFSET],NEBO_G102_FORMAT_NONE
    jne .format
    jmp .path_check
.export_capability:
    test qword [r12+NEBO_G102_REQUEST_CAPABILITIES_OFFSET],NEBO_G102_CAP_EXPORT
    jz .capability
    test qword [r12+NEBO_G102_REQUEST_CAPABILITIES_OFFSET],NEBO_G102_CAP_ATOMIC
    jz .atomicity

.path_check:
    test rbx,NEBO_G102_OPTION_PATH
    jz .no_path
    mov rax,[r12+NEBO_G102_REQUEST_PATH_ID_OFFSET]
    cmp rax,1
    jb .path
    cmp rax,4096
    ja .path
    jmp .hide_check
.no_path:
    cmp qword [r12+NEBO_G102_REQUEST_PATH_ID_OFFSET],0
    jne .path
.hide_check:
    test rbx,NEBO_G102_OPTION_HIDE_ON_SCREEN
    jz .no_hide
    cmp qword [r12+NEBO_G102_REQUEST_HIDE_ON_SCREEN_OFFSET],1
    jne .capability
    test qword [r12+NEBO_G102_REQUEST_CAPABILITIES_OFFSET],NEBO_G102_CAP_HIDE
    jz .capability
    jmp .compute
.no_hide:
    cmp qword [r12+NEBO_G102_REQUEST_HIDE_ON_SCREEN_OFFSET],0
    jne .capability

.compute:
    mov rdi,rsp
    xor eax,eax
    mov ecx,NEBO_G102_RESULT_SIZE/8
    cld
    rep stosq
    mov [rsp+NEBO_G102_RESULT_FRAME_COUNT_OFFSET],r14
    mov rax,1000000000
    xor edx,edx
    div r15
    mov [rsp+NEBO_G102_RESULT_FRAME_INTERVAL_NS_OFFSET],rax
    mov rdi,r14
    mov rsi,rax
    mov rdx,[r12+NEBO_G102_REQUEST_SEED_OFFSET]
    call g102_timeline_digest
    mov [rsp+NEBO_G102_RESULT_TIMELINE_DIGEST_OFFSET],rax
    mov r10,rax
    mov rax,[r12+NEBO_G102_REQUEST_DURATION_MS_OFFSET]
    mov [rsp+NEBO_G102_RESULT_DURATION_MS_OFFSET],rax
    mov rax,[r12+NEBO_G102_REQUEST_LOOP_OFFSET]
    inc rax
    mov [rsp+NEBO_G102_RESULT_LOOP_COUNT_OFFSET],rax
    mov rax,[r12+NEBO_G102_REQUEST_SEED_OFFSET]
    mov [rsp+NEBO_G102_RESULT_SEED_OFFSET],rax
    mov rax,[r12+NEBO_G102_REQUEST_WIDTH_OFFSET]
    mov [rsp+NEBO_G102_RESULT_WIDTH_OFFSET],rax
    mov rdx,[r12+NEBO_G102_REQUEST_HEIGHT_OFFSET]
    mov [rsp+NEBO_G102_RESULT_HEIGHT_OFFSET],rdx
    mov rax,[r12+NEBO_G102_REQUEST_CAPTURE_MODE_OFFSET]
    test rax,rax
    jz .capture_ready
    imul rax,0x101
    xor rax,r10
    rol rax,13
    xor rax,[r12+NEBO_G102_REQUEST_WIDTH_OFFSET]
    rol rax,17
    xor rax,rdx
    mov [rsp+NEBO_G102_RESULT_CAPTURE_DIGEST_OFFSET],rax
.capture_ready:
    mov rax,[r12+NEBO_G102_REQUEST_FORMAT_OFFSET]
    mov [rsp+NEBO_G102_RESULT_FORMAT_OFFSET],rax
    cmp rax,NEBO_G102_FORMAT_FRAMES
    je .frames_bytes
    cmp rax,NEBO_G102_FORMAT_PNG
    je .png_bytes
    cmp rax,NEBO_G102_FORMAT_MP4
    je .mp4_bytes
    jmp .bytes_ready
.frames_bytes:
    mov rax,r14
    imul rax,24
    add rax,64
    jmp .store_bytes
.png_bytes:
    mov rax,[r12+NEBO_G102_REQUEST_WIDTH_OFFSET]
    imul rax,[r12+NEBO_G102_REQUEST_HEIGHT_OFFSET]
    shl rax,2
    add rax,32
    jmp .store_bytes
.mp4_bytes:
    mov rax,r14
    imul rax,24
    add rax,128
.store_bytes:
    mov [rsp+NEBO_G102_RESULT_ARTIFACT_BYTES_OFFSET],rax
    mov rax,r10
    xor rax,[rsp+NEBO_G102_RESULT_CAPTURE_DIGEST_OFFSET]
    rol rax,19
    xor rax,[r12+NEBO_G102_REQUEST_FORMAT_OFFSET]
    rol rax,11
    xor rax,[r12+NEBO_G102_REQUEST_PATH_ID_OFFSET]
    xor rax,[rsp+NEBO_G102_RESULT_ARTIFACT_BYTES_OFFSET]
    mov [rsp+NEBO_G102_RESULT_EXPORT_DIGEST_OFFSET],rax
.bytes_ready:
    mov rax,[r12+NEBO_G102_REQUEST_PATH_ID_OFFSET]
    mov [rsp+NEBO_G102_RESULT_PATH_ID_OFFSET],rax
    mov rax,[r12+NEBO_G102_REQUEST_HIDE_ON_SCREEN_OFFSET]
    mov [rsp+NEBO_G102_RESULT_HIDE_ON_SCREEN_OFFSET],rax
    mov rax,[r12+NEBO_G102_REQUEST_CAPTURE_MODE_OFFSET]
    or rax,[r12+NEBO_G102_REQUEST_FORMAT_OFFSET]
    setnz al
    movzx eax,al
    mov [rsp+NEBO_G102_RESULT_COMMIT_COUNT_OFFSET],rax
    mov qword [rsp+NEBO_G102_RESULT_PARTIAL_COUNT_OFFSET],0
    mov rax,[rsp+NEBO_G102_RESULT_TIMELINE_DIGEST_OFFSET]
    xor rax,[rsp+NEBO_G102_RESULT_CAPTURE_DIGEST_OFFSET]
    rol rax,7
    xor rax,[rsp+NEBO_G102_RESULT_EXPORT_DIGEST_OFFSET]
    rol rax,23
    xor rax,[rsp+NEBO_G102_RESULT_DURATION_MS_OFFSET]
    xor rax,[rsp+NEBO_G102_RESULT_LOOP_COUNT_OFFSET]
    xor rax,[rsp+NEBO_G102_RESULT_HIDE_ON_SCREEN_OFFSET]
    mov [rsp+NEBO_G102_RESULT_REPORT_DIGEST_OFFSET],rax
    mov qword [rsp+NEBO_G102_RESULT_SPEC_VERSION_OFFSET],NEBO_G102_SPEC_VERSION
    mov rsi,rsp
    mov rdi,r13
    mov ecx,NEBO_G102_RESULT_SIZE/8
    cld
    rep movsq
    xor eax,eax
    jmp .done
.invalid: mov eax,NEBO_G102_ERROR_INVALID
    jmp .done
.options: mov eax,NEBO_G102_ERROR_OPTIONS
    jmp .done
.target: mov eax,NEBO_G102_ERROR_TARGET
    jmp .done
.timing: mov eax,NEBO_G102_ERROR_TIMING
    jmp .done
.capability: mov eax,NEBO_G102_ERROR_CAPABILITY
    jmp .done
.path: mov eax,NEBO_G102_ERROR_PATH
    jmp .done
.format: mov eax,NEBO_G102_ERROR_FORMAT
    jmp .done
.bounds: mov eax,NEBO_G102_ERROR_BOUNDS
    jmp .done
.version: mov eax,NEBO_G102_ERROR_VERSION
    jmp .done
.atomicity: mov eax,NEBO_G102_ERROR_ATOMICITY
.done:
    add rsp,152
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
