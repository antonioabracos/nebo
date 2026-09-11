; G102 source-to-effect bridge. It builds a concrete request from lowered
; operands and requires byte-identical logical results for headless and live.
bits 64
default rel
%define NEBO_G102_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/animation_export_source_probe.inc"
%include "runtime/console/animation_export.inc"

global nebo_g102_source_probe
global nebo_g102_observation_probe
global nebo_g102_counter_probe
global nebo_g102_negative_probe

section .rodata
g102_probe_masks: dq 0x0003,0x0048,0x00a8,0x1002,0x0804
                  dq 0x0610,0x2150,0x6200,0x2214,0x7fff

section .bss
align 16
g102_request: resb NEBO_G102_REQUEST_SIZE
g102_headless: resb NEBO_G102_RESULT_SIZE
g102_live: resb NEBO_G102_RESULT_SIZE
g102_negative_result: resb NEBO_G102_RESULT_SIZE

section .text
; EDI=mode, ESI=seed. Populate the canonical bounded request.
g102_prepare:
    push rbx
    mov ebx,edi
    lea rdi,[rel g102_request]
    xor eax,eax
    mov ecx,NEBO_G102_REQUEST_SIZE/8
    cld
    rep stosq
    mov [rel g102_request+NEBO_G102_REQUEST_MODE_OFFSET],rbx
    mov eax,esi
    and eax,31
    add eax,8
    mov [rel g102_request+NEBO_G102_REQUEST_FRAME_COUNT_OFFSET],rax
    mov eax,esi
    and eax,15
    add eax,24
    mov [rel g102_request+NEBO_G102_REQUEST_FPS_OFFSET],rax
    mov r8,rax
    mov rax,[rel g102_request+NEBO_G102_REQUEST_FRAME_COUNT_OFFSET]
    imul rax,1000
    lea rax,[rax+r8-1]
    xor edx,edx
    div r8
    mov [rel g102_request+NEBO_G102_REQUEST_DURATION_MS_OFFSET],rax
    xor eax,eax
    cmp ebx,3
    sete al
    cmp ebx,10
    sete dl
    or al,dl
    movzx eax,al
    mov [rel g102_request+NEBO_G102_REQUEST_LOOP_OFFSET],rax
    mov eax,esi
    mov [rel g102_request+NEBO_G102_REQUEST_SEED_OFFSET],rax
    lea rdx,[rel g102_probe_masks]
    mov rax,[rdx+rbx*8-8]
    mov [rel g102_request+NEBO_G102_REQUEST_OPTIONS_OFFSET],rax
    mov r9,rax
    xor eax,eax
    test r9,NEBO_G102_OPTION_SCREENSHOT
    jz .capture
    mov eax,NEBO_G102_CAPTURE_SCREENSHOT
    jmp .capture_ready
.capture:
    test r9,NEBO_G102_OPTION_CAPTURE
    jz .capture_ready
    mov eax,NEBO_G102_CAPTURE_FRAME
.capture_ready:
    mov [rel g102_request+NEBO_G102_REQUEST_CAPTURE_MODE_OFFSET],rax
    xor eax,eax
    test r9,NEBO_G102_OPTION_MP4
    jz .png
    mov eax,NEBO_G102_FORMAT_MP4
    jmp .format_ready
.png:
    test r9,NEBO_G102_OPTION_PNG
    jz .frames
    mov eax,NEBO_G102_FORMAT_PNG
    jmp .format_ready
.frames:
    test r9,NEBO_G102_OPTION_EXPORT
    jz .format_ready
    mov eax,NEBO_G102_FORMAT_FRAMES
.format_ready:
    mov [rel g102_request+NEBO_G102_REQUEST_FORMAT_OFFSET],rax
    xor eax,eax
    test r9,NEBO_G102_OPTION_PATH
    jz .path_ready
    lea eax,[rsi+100]
.path_ready:
    mov [rel g102_request+NEBO_G102_REQUEST_PATH_ID_OFFSET],rax
    xor eax,eax
    test r9,NEBO_G102_OPTION_HIDE_ON_SCREEN
    setnz al
    mov [rel g102_request+NEBO_G102_REQUEST_HIDE_ON_SCREEN_OFFSET],rax
    mov qword [rel g102_request+NEBO_G102_REQUEST_CAPABILITIES_OFFSET],NEBO_G102_CAP_ALL
    mov qword [rel g102_request+NEBO_G102_REQUEST_SPEC_VERSION_OFFSET],NEBO_G102_SPEC_VERSION
    mov eax,esi
    and eax,7
    shl eax,4
    add eax,640
    mov [rel g102_request+NEBO_G102_REQUEST_WIDTH_OFFSET],rax
    mov eax,esi
    and eax,3
    shl eax,4
    add eax,360
    mov [rel g102_request+NEBO_G102_REQUEST_HEIGHT_OFFSET],rax
    pop rbx
    ret

; EDI=mode, ESI=seed. Return the source seed after target parity succeeds.
nebo_g102_source_probe:
    push rbx
    push r12
    push r13
    mov r12d,edi
    mov r13d,esi
    cmp r12d,1
    jb .invalid
    cmp r12d,10
    ja .invalid
    cmp r13d,1
    jb .invalid
    cmp r13d,255
    ja .invalid
    call g102_prepare
    mov qword [rel g102_request+NEBO_G102_REQUEST_TARGET_OFFSET],NEBO_G102_TARGET_HEADLESS
    lea rdi,[rel g102_request]
    lea rsi,[rel g102_headless]
    call nebo_g102_animation_export_model
    test eax,eax
    jnz .done
    mov qword [rel g102_request+NEBO_G102_REQUEST_TARGET_OFFSET],NEBO_G102_TARGET_LIVE
    lea rdi,[rel g102_request]
    lea rsi,[rel g102_live]
    call nebo_g102_animation_export_model
    test eax,eax
    jnz .done
    lea rsi,[rel g102_headless]
    lea rdi,[rel g102_live]
    mov ecx,NEBO_G102_RESULT_SIZE/8
    cld
    repe cmpsq
    jne .effect
    mov eax,r13d
    jmp .done
.invalid:
    mov eax,NEBO_G102_ERROR_INVALID
    jmp .done
.effect:
    mov eax,-99
.done:
    pop r13
    pop r12
    pop rbx
    ret

; RDI=mode, RSI=seed -> deterministic report observation.
nebo_g102_observation_probe:
    push rbx
    mov rbx,rsi
    call nebo_g102_source_probe
    cmp eax,ebx
    jne .failed
    mov rax,[rel g102_headless+NEBO_G102_RESULT_REPORT_DIGEST_OFFSET]
    xor rax,[rel g102_headless+NEBO_G102_RESULT_TIMELINE_DIGEST_OFFSET]
    xor rax,[rel g102_headless+NEBO_G102_RESULT_EXPORT_DIGEST_OFFSET]
    pop rbx
    ret
.failed:
    cdqe
    pop rbx
    ret

; RDI=mode, RSI=seed, RDX=selector -> selected factual result field.
nebo_g102_counter_probe:
    push rbx
    push r12
    mov rbx,rsi
    mov r12,rdx
    call nebo_g102_source_probe
    cmp eax,ebx
    jne .done
    cmp r12,1
    je .frames
    cmp r12,2
    je .interval
    cmp r12,3
    je .duration
    cmp r12,4
    je .capture
    cmp r12,5
    je .bytes
    cmp r12,6
    je .commits
    cmp r12,7
    je .partials
    mov eax,NEBO_G102_ERROR_INVALID
    jmp .done
.frames: mov rax,[rel g102_headless+NEBO_G102_RESULT_FRAME_COUNT_OFFSET]
    jmp .done
.interval: mov rax,[rel g102_headless+NEBO_G102_RESULT_FRAME_INTERVAL_NS_OFFSET]
    jmp .done
.duration: mov rax,[rel g102_headless+NEBO_G102_RESULT_DURATION_MS_OFFSET]
    jmp .done
.capture: mov rax,[rel g102_headless+NEBO_G102_RESULT_CAPTURE_DIGEST_OFFSET]
    jmp .done
.bytes: mov rax,[rel g102_headless+NEBO_G102_RESULT_ARTIFACT_BYTES_OFFSET]
    jmp .done
.commits: mov rax,[rel g102_headless+NEBO_G102_RESULT_COMMIT_COUNT_OFFSET]
    jmp .done
.partials: mov rax,[rel g102_headless+NEBO_G102_RESULT_PARTIAL_COUNT_OFFSET]
.done:
    pop r12
    pop rbx
    ret

; RDI=negative case 1..16. Verify stable error and unchanged result sentinel.
nebo_g102_negative_probe:
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov edi,10
    mov esi,53
    call g102_prepare
    mov qword [rel g102_request+NEBO_G102_REQUEST_TARGET_OFFSET],NEBO_G102_TARGET_HEADLESS
    cmp r12,1
    je .bad_mode
    cmp r12,2
    je .bad_target
    cmp r12,3
    je .bad_frames
    cmp r12,4
    je .bad_fps
    cmp r12,5
    je .bad_duration
    cmp r12,6
    je .bad_loop
    cmp r12,7
    je .bad_seed
    cmp r12,8
    je .bad_capture
    cmp r12,9
    je .bad_format
    cmp r12,10
    je .bad_path
    cmp r12,11
    je .bad_hide_cap
    cmp r12,12
    je .bad_export_cap
    cmp r12,13
    je .bad_atomic_cap
    cmp r12,14
    je .bad_options
    cmp r12,15
    je .bad_version
    cmp r12,16
    je .bad_width
    mov eax,NEBO_G102_ERROR_INVALID
    jmp .return
.bad_mode: mov qword [rel g102_request+NEBO_G102_REQUEST_MODE_OFFSET],0
    jmp .invoke
.bad_target: mov qword [rel g102_request+NEBO_G102_REQUEST_TARGET_OFFSET],3
    jmp .invoke
.bad_frames: mov qword [rel g102_request+NEBO_G102_REQUEST_FRAME_COUNT_OFFSET],0
    jmp .invoke
.bad_fps: mov qword [rel g102_request+NEBO_G102_REQUEST_FPS_OFFSET],0
    jmp .invoke
.bad_duration: inc qword [rel g102_request+NEBO_G102_REQUEST_DURATION_MS_OFFSET]
    jmp .invoke
.bad_loop: mov qword [rel g102_request+NEBO_G102_REQUEST_LOOP_OFFSET],2
    jmp .invoke
.bad_seed: mov qword [rel g102_request+NEBO_G102_REQUEST_SEED_OFFSET],0
    jmp .invoke
.bad_capture: mov qword [rel g102_request+NEBO_G102_REQUEST_CAPTURE_MODE_OFFSET],9
    jmp .invoke
.bad_format: mov qword [rel g102_request+NEBO_G102_REQUEST_FORMAT_OFFSET],9
    jmp .invoke
.bad_path: mov qword [rel g102_request+NEBO_G102_REQUEST_PATH_ID_OFFSET],0
    jmp .invoke
.bad_hide_cap: and qword [rel g102_request+NEBO_G102_REQUEST_CAPABILITIES_OFFSET],~NEBO_G102_CAP_HIDE
    jmp .invoke
.bad_export_cap: and qword [rel g102_request+NEBO_G102_REQUEST_CAPABILITIES_OFFSET],~NEBO_G102_CAP_EXPORT
    jmp .invoke
.bad_atomic_cap: and qword [rel g102_request+NEBO_G102_REQUEST_CAPABILITIES_OFFSET],~NEBO_G102_CAP_ATOMIC
    jmp .invoke
.bad_options: or qword [rel g102_request+NEBO_G102_REQUEST_OPTIONS_OFFSET],1 << 20
    jmp .invoke
.bad_version: mov qword [rel g102_request+NEBO_G102_REQUEST_SPEC_VERSION_OFFSET],2
    jmp .invoke
.bad_width: mov qword [rel g102_request+NEBO_G102_REQUEST_WIDTH_OFFSET],0
.invoke:
    lea rdi,[rel g102_negative_result]
    mov rax,0x5a5a5a5a5a5a5a5a
    mov ecx,NEBO_G102_RESULT_SIZE/8
    cld
    rep stosq
    lea rdi,[rel g102_request]
    lea rsi,[rel g102_negative_result]
    call nebo_g102_animation_export_model
    mov ebx,eax
    lea rdi,[rel g102_negative_result]
    mov rax,0x5a5a5a5a5a5a5a5a
    mov ecx,NEBO_G102_RESULT_SIZE/8
.sentinel:
    cmp [rdi],rax
    jne .effect
    add rdi,8
    loop .sentinel
    mov eax,ebx
    jmp .return
.effect:
    mov eax,-99
.return:
    pop r13
    pop r12
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
