; G095 target-neutral chart semantic model and numeric validation owner.
bits 64
default rel
%define NEBO_G095_CHART_MODEL_IMPLEMENTATION 1
%include "runtime/console/chart_model.inc"

section .text
global nebo_g095_chart_model

; chart_model(request*, result*) -> status.  The result is published only after
; complete validation, which makes every failure path atomic.
nebo_g095_chart_model:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,80
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    jz .invalid
    test r13,r13
    jz .invalid
    test r12,7
    jnz .invalid
    test r13,7
    jnz .invalid

    mov ebx,[r12+NEBO_G095_REQUEST_KIND_OFFSET]
    cmp ebx,NEBO_G095_KIND_LINE
    jb .kind
    cmp ebx,NEBO_G095_KIND_TIME_SERIES
    ja .kind
    mov eax,[r12+NEBO_G095_REQUEST_TARGET_OFFSET]
    cmp eax,NEBO_G095_TARGET_HEADLESS
    jb .target
    cmp eax,NEBO_G095_TARGET_VISUAL
    ja .target
    mov r14,[r12+NEBO_G095_REQUEST_POINTS_OFFSET]
    test r14,r14
    jz .invalid
    cmp r14,NEBO_G095_MAX_POINTS
    ja .bounds
    mov rax,[r12+NEBO_G095_REQUEST_SERIES_OFFSET]
    test rax,rax
    jz .invalid
    cmp rax,NEBO_G095_MAX_SERIES
    ja .bounds
    cmp qword [r12+NEBO_G095_REQUEST_GENERATION_OFFSET],0
    je .invalid
    mov rax,[r12+NEBO_G095_REQUEST_OPTIONS_OFFSET]
    mov rcx,rax
    and rcx,~NEBO_G095_OPTION_KNOWN
    jnz .options
    mov rax,[r12+NEBO_G095_REQUEST_MISSING_POLICY_OFFSET]
    cmp rax,NEBO_G095_MISSING_ZERO
    ja .options
    mov rax,[r12+NEBO_G095_REQUEST_Y_PTR_OFFSET]
    test rax,rax
    jz .invalid
    test rax,7
    jnz .invalid
    cmp qword [r12+NEBO_G095_REQUEST_Y_COUNT_OFFSET],r14
    jne .shape

    cmp ebx,NEBO_G095_KIND_LINE
    je .xy_kind
    cmp ebx,NEBO_G095_KIND_SCATTER
    je .xy_kind
    cmp ebx,NEBO_G095_KIND_TIME_SERIES
    je .xy_kind
    jmp .kind_specific
.xy_kind:
    mov rax,[r12+NEBO_G095_REQUEST_X_PTR_OFFSET]
    test rax,rax
    jz .invalid
    test rax,7
    jnz .invalid
    cmp qword [r12+NEBO_G095_REQUEST_X_COUNT_OFFSET],r14
    jne .shape
    mov rax,[r12+NEBO_G095_REQUEST_OPTIONS_OFFSET]
    and eax,NEBO_G095_OPTION_X | NEBO_G095_OPTION_Y
    cmp eax,NEBO_G095_OPTION_X | NEBO_G095_OPTION_Y
    jne .options
.kind_specific:
    cmp ebx,NEBO_G095_KIND_HISTOGRAM
    jne .not_histogram
    mov rax,[r12+NEBO_G095_REQUEST_BINS_OFFSET]
    test rax,rax
    jz .bins
    cmp rax,NEBO_G095_MAX_BINS
    ja .bins
    cmp rax,r14
    ja .bins
    test qword [r12+NEBO_G095_REQUEST_OPTIONS_OFFSET],NEBO_G095_OPTION_BINS
    jz .options
    jmp .shape_ready
.not_histogram:
    cmp qword [r12+NEBO_G095_REQUEST_BINS_OFFSET],0
    jne .bins
    cmp ebx,NEBO_G095_KIND_HEATMAP
    jne .shape_ready
    mov rax,[r12+NEBO_G095_REQUEST_ROWS_OFFSET]
    test rax,rax
    jz .shape
    cmp rax,NEBO_G095_MAX_MATRIX_AXIS
    ja .bounds
    mov rcx,[r12+NEBO_G095_REQUEST_COLUMNS_OFFSET]
    test rcx,rcx
    jz .shape
    cmp rcx,NEBO_G095_MAX_MATRIX_AXIS
    ja .bounds
    mul rcx
    test rdx,rdx
    jnz .bounds
    cmp rax,r14
    jne .shape

.shape_ready:
    ; Digest the target-neutral public schema before inspecting borrowed data.
    mov r15,0xcbf29ce484222325
    mov eax,ebx
    xor r15,rax
    rol r15,13
    xor r15,r14
    rol r15,17
    xor r15,[r12+NEBO_G095_REQUEST_SERIES_OFFSET]
    rol r15,19
    xor r15,[r12+NEBO_G095_REQUEST_BINS_OFFSET]
    rol r15,23
    xor r15,[r12+NEBO_G095_REQUEST_OPTIONS_OFFSET]
    rol r15,29
    xor r15,[r12+NEBO_G095_REQUEST_GENERATION_OFFSET]
    xor r10d,r10d                         ; finite observations
    xor r11d,r11d                         ; missing observations
    xor ecx,ecx
.data_loop:
    cmp rcx,r14
    jae .publish
    mov rax,[r12+NEBO_G095_REQUEST_MISSING_PTR_OFFSET]
    test rax,rax
    jz .not_missing
    cmp byte [rax+rcx],0
    je .not_missing
    inc r11
    mov rax,[r12+NEBO_G095_REQUEST_MISSING_POLICY_OFFSET]
    cmp eax,NEBO_G095_MISSING_REJECT
    je .missing
    cmp eax,NEBO_G095_MISSING_SKIP
    je .next_value
    ; ZERO policy contributes one canonical finite zero.
    inc r10
    rol r15,7
    jmp .next_value
.not_missing:
    mov rax,[r12+NEBO_G095_REQUEST_Y_PTR_OFFSET]
    mov rdx,[rax+rcx*8]
    mov rax,rdx
    shr rax,52
    and eax,0x7ff
    cmp eax,0x7ff
    je .nonfinite
    xor r15,rdx
    rol r15,11
    cmp ebx,NEBO_G095_KIND_LINE
    je .check_x
    cmp ebx,NEBO_G095_KIND_SCATTER
    je .check_x
    cmp ebx,NEBO_G095_KIND_TIME_SERIES
    jne .finite_value
.check_x:
    mov rax,[r12+NEBO_G095_REQUEST_X_PTR_OFFSET]
    mov rdx,[rax+rcx*8]
    mov rax,rdx
    shr rax,52
    and eax,0x7ff
    cmp eax,0x7ff
    je .nonfinite
    xor r15,rdx
    rol r15,11
.finite_value:
    inc r10
.next_value:
    inc rcx
    jmp .data_loop

.publish:
    mov dword [rbp-120+NEBO_G095_RESULT_KIND_OFFSET],ebx
    mov eax,[r12+NEBO_G095_REQUEST_TARGET_OFFSET]
    mov dword [rbp-120+NEBO_G095_RESULT_TARGET_OFFSET],eax
    mov [rbp-120+NEBO_G095_RESULT_POINTS_OFFSET],r14
    mov rax,[r12+NEBO_G095_REQUEST_SERIES_OFFSET]
    mov [rbp-120+NEBO_G095_RESULT_SERIES_OFFSET],rax
    mov rax,[r12+NEBO_G095_REQUEST_BINS_OFFSET]
    mov [rbp-120+NEBO_G095_RESULT_BINS_OFFSET],rax
    mov rax,[r12+NEBO_G095_REQUEST_OPTIONS_OFFSET]
    mov [rbp-120+NEBO_G095_RESULT_OPTIONS_OFFSET],rax
    mov [rbp-120+NEBO_G095_RESULT_FINITE_OFFSET],r10
    mov [rbp-120+NEBO_G095_RESULT_MISSING_OFFSET],r11
    mov [rbp-120+NEBO_G095_RESULT_DIGEST_OFFSET],r15
    mov rax,[r12+NEBO_G095_REQUEST_GENERATION_OFFSET]
    mov [rbp-120+NEBO_G095_RESULT_GENERATION_OFFSET],rax
    lea rsi,[rbp-120]
    mov rdi,r13
    mov ecx,NEBO_G095_RESULT_SIZE/8
    cld
    rep movsq
    xor eax,eax
    jmp .done
.invalid:
    mov eax,NEBO_G095_ERROR_INVALID
    jmp .done
.bounds:
    mov eax,NEBO_G095_ERROR_BOUNDS
    jmp .done
.kind:
    mov eax,NEBO_G095_ERROR_KIND
    jmp .done
.shape:
    mov eax,NEBO_G095_ERROR_SHAPE
    jmp .done
.nonfinite:
    mov eax,NEBO_G095_ERROR_NONFINITE
    jmp .done
.missing:
    mov eax,NEBO_G095_ERROR_MISSING
    jmp .done
.bins:
    mov eax,NEBO_G095_ERROR_BINS
    jmp .done
.target:
    mov eax,NEBO_G095_ERROR_TARGET
    jmp .done
.options:
    mov eax,NEBO_G095_ERROR_OPTIONS
.done:
    add rsp,80
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
