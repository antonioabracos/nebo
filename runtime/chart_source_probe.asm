; G095 source-to-effect probe over the target-neutral chart model.
bits 64
default rel
%define NEBO_G095_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/chart_source_probe.inc"
%include "runtime/console/chart_model.inc"

global nebo_g095_source_probe
global nebo_g095_negative_probe

section .bss align=16
g95_request: resb NEBO_G095_REQUEST_SIZE
g95_headless: resb NEBO_G095_RESULT_SIZE
g95_visual: resb NEBO_G095_RESULT_SIZE
g95_x: resq 255
g95_y: resq 255
g95_missing: resb 255

section .text
g95_clear:
    lea rdi,[rel g95_request]
    mov ecx,NEBO_G095_REQUEST_SIZE/8
    xor eax,eax
    cld
    rep stosq
    lea rdi,[rel g95_headless]
    mov ecx,NEBO_G095_RESULT_SIZE/8
    rep stosq
    lea rdi,[rel g95_visual]
    mov ecx,NEBO_G095_RESULT_SIZE/8
    rep stosq
    lea rdi,[rel g95_missing]
    mov ecx,255
    rep stosb
    ret

; EDI=subgroup 1..10, ESI=data extent 1..255 -> EAX=observed extent.
nebo_g095_source_probe:
    push rbx
    push r12
    push r13
    push r14
    mov r12d,edi
    mov r13d,esi
    cmp r12d,1
    jb .failure
    cmp r12d,10
    ja .failure
    test r13d,r13d
    jz .failure
    cmp r13d,255
    ja .failure
    call g95_clear

    lea rbx,[rel g95_x]
    lea r14,[rel g95_y]
    xor ecx,ecx
.fill:
    mov eax,ecx
    inc eax
    cvtsi2sd xmm0,eax
    movsd [rbx+rcx*8],xmm0
    add eax,r13d
    cvtsi2sd xmm0,eax
    movsd [r14+rcx*8],xmm0
    inc ecx
    cmp ecx,r13d
    jb .fill
    lea rax,[rel g95_x]
    mov [rel g95_request+NEBO_G095_REQUEST_X_PTR_OFFSET],rax
    lea rax,[rel g95_y]
    mov [rel g95_request+NEBO_G095_REQUEST_Y_PTR_OFFSET],rax
    lea rax,[rel g95_missing]
    mov [rel g95_request+NEBO_G095_REQUEST_MISSING_PTR_OFFSET],rax
    mov [rel g95_request+NEBO_G095_REQUEST_POINTS_OFFSET],r13
    mov [rel g95_request+NEBO_G095_REQUEST_X_COUNT_OFFSET],r13
    mov [rel g95_request+NEBO_G095_REQUEST_Y_COUNT_OFFSET],r13
    mov [rel g95_request+NEBO_G095_REQUEST_GENERATION_OFFSET],r13
    mov eax,r13d
    and eax,3
    inc eax
    mov [rel g95_request+NEBO_G095_REQUEST_SERIES_OFFSET],rax

    cmp r12d,1
    je .registry
    cmp r12d,2
    je .time
    cmp r12d,3
    je .bar
    cmp r12d,4
    je .histogram
    cmp r12d,5
    je .scatter
    cmp r12d,6
    je .heatmap
    cmp r12d,7
    je .axes
    cmp r12d,8
    je .encoding
    cmp r12d,9
    je .differential
    jmp .closeout
.registry:
    mov eax,r13d
    xor edx,edx
    mov ecx,6
    div ecx
    inc edx
    mov [rel g95_request+NEBO_G095_REQUEST_KIND_OFFSET],edx
    jmp .configure_kind
.time:
    mov dword [rel g95_request+NEBO_G095_REQUEST_KIND_OFFSET],NEBO_G095_KIND_TIME_SERIES
    mov qword [rel g95_request+NEBO_G095_REQUEST_OPTIONS_OFFSET],NEBO_G095_OPTION_X | NEBO_G095_OPTION_Y
    jmp .run
.bar:
    mov dword [rel g95_request+NEBO_G095_REQUEST_KIND_OFFSET],NEBO_G095_KIND_BAR
    mov qword [rel g95_request+NEBO_G095_REQUEST_OPTIONS_OFFSET],NEBO_G095_OPTION_Y | NEBO_G095_OPTION_LABELS | NEBO_G095_OPTION_LEGEND
    jmp .run
.histogram:
    mov dword [rel g95_request+NEBO_G095_REQUEST_KIND_OFFSET],NEBO_G095_KIND_HISTOGRAM
    mov qword [rel g95_request+NEBO_G095_REQUEST_OPTIONS_OFFSET],NEBO_G095_OPTION_Y | NEBO_G095_OPTION_BINS
    jmp .set_bins
.scatter:
    mov dword [rel g95_request+NEBO_G095_REQUEST_KIND_OFFSET],NEBO_G095_KIND_SCATTER
    mov qword [rel g95_request+NEBO_G095_REQUEST_OPTIONS_OFFSET],NEBO_G095_OPTION_X | NEBO_G095_OPTION_Y | NEBO_G095_OPTION_COLOR_BY | NEBO_G095_OPTION_SIZE_BY
    jmp .run
.heatmap:
    mov dword [rel g95_request+NEBO_G095_REQUEST_KIND_OFFSET],NEBO_G095_KIND_HEATMAP
    mov qword [rel g95_request+NEBO_G095_REQUEST_OPTIONS_OFFSET],NEBO_G095_OPTION_Y | NEBO_G095_OPTION_COLOR_BY
    mov qword [rel g95_request+NEBO_G095_REQUEST_ROWS_OFFSET],1
    mov [rel g95_request+NEBO_G095_REQUEST_COLUMNS_OFFSET],r13
    jmp .run
.axes:
    mov dword [rel g95_request+NEBO_G095_REQUEST_KIND_OFFSET],NEBO_G095_KIND_LINE
    mov qword [rel g95_request+NEBO_G095_REQUEST_OPTIONS_OFFSET],NEBO_G095_OPTION_X | NEBO_G095_OPTION_Y | NEBO_G095_OPTION_X_LABEL | NEBO_G095_OPTION_Y_LABEL
    jmp .run
.encoding:
    mov dword [rel g95_request+NEBO_G095_REQUEST_KIND_OFFSET],NEBO_G095_KIND_HISTOGRAM
    mov qword [rel g95_request+NEBO_G095_REQUEST_OPTIONS_OFFSET],NEBO_G095_OPTION_Y | NEBO_G095_OPTION_BINS | NEBO_G095_OPTION_LABELS | NEBO_G095_OPTION_COLOR_BY | NEBO_G095_OPTION_SIZE_BY | NEBO_G095_OPTION_LEGEND
    jmp .set_bins
.differential:
    mov dword [rel g95_request+NEBO_G095_REQUEST_KIND_OFFSET],NEBO_G095_KIND_SCATTER
    mov qword [rel g95_request+NEBO_G095_REQUEST_OPTIONS_OFFSET],NEBO_G095_OPTION_X | NEBO_G095_OPTION_Y | NEBO_G095_OPTION_COLOR_BY
    jmp .run
.closeout:
    mov dword [rel g95_request+NEBO_G095_REQUEST_KIND_OFFSET],NEBO_G095_KIND_TIME_SERIES
    mov qword [rel g95_request+NEBO_G095_REQUEST_OPTIONS_OFFSET],NEBO_G095_OPTION_X | NEBO_G095_OPTION_Y | NEBO_G095_OPTION_X_LABEL | NEBO_G095_OPTION_Y_LABEL | NEBO_G095_OPTION_LABELS | NEBO_G095_OPTION_LEGEND
    jmp .run
.set_bins:
    mov eax,r13d
    cmp eax,NEBO_G095_MAX_BINS
    jbe .bins_ready
    mov eax,NEBO_G095_MAX_BINS
.bins_ready:
    mov [rel g95_request+NEBO_G095_REQUEST_BINS_OFFSET],rax
    jmp .run
.configure_kind:
    cmp edx,NEBO_G095_KIND_HISTOGRAM
    je .histogram
    cmp edx,NEBO_G095_KIND_HEATMAP
    je .heatmap
    cmp edx,NEBO_G095_KIND_BAR
    je .bar
    cmp edx,NEBO_G095_KIND_SCATTER
    je .scatter
    mov qword [rel g95_request+NEBO_G095_REQUEST_OPTIONS_OFFSET],NEBO_G095_OPTION_X | NEBO_G095_OPTION_Y

.run:
    mov dword [rel g95_request+NEBO_G095_REQUEST_TARGET_OFFSET],NEBO_G095_TARGET_HEADLESS
    lea rdi,[rel g95_request]
    lea rsi,[rel g95_headless]
    call nebo_g095_chart_model
    test eax,eax
    jnz .failure
    mov dword [rel g95_request+NEBO_G095_REQUEST_TARGET_OFFSET],NEBO_G095_TARGET_VISUAL
    lea rdi,[rel g95_request]
    lea rsi,[rel g95_visual]
    call nebo_g095_chart_model
    test eax,eax
    jnz .failure
%macro G95_COMPARE_QWORD 1
    mov rax,[rel g95_headless+%1]
    cmp rax,[rel g95_visual+%1]
    jne .failure
%endmacro
    G95_COMPARE_QWORD NEBO_G095_RESULT_POINTS_OFFSET
    G95_COMPARE_QWORD NEBO_G095_RESULT_SERIES_OFFSET
    G95_COMPARE_QWORD NEBO_G095_RESULT_BINS_OFFSET
    G95_COMPARE_QWORD NEBO_G095_RESULT_OPTIONS_OFFSET
    G95_COMPARE_QWORD NEBO_G095_RESULT_FINITE_OFFSET
    G95_COMPARE_QWORD NEBO_G095_RESULT_MISSING_OFFSET
    G95_COMPARE_QWORD NEBO_G095_RESULT_DIGEST_OFFSET
    G95_COMPARE_QWORD NEBO_G095_RESULT_GENERATION_OFFSET
%undef G95_COMPARE_QWORD
    mov eax,[rel g95_headless+NEBO_G095_RESULT_KIND_OFFSET]
    cmp eax,[rel g95_visual+NEBO_G095_RESULT_KIND_OFFSET]
    jne .failure
    mov eax,[rel g95_headless+NEBO_G095_RESULT_POINTS_OFFSET]
    cmp eax,r13d
    jne .failure
    jmp .done
.failure:
    mov eax,-1
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; EDI=case 1..10 -> EAX=stable error code, also verifies failure atomicity.
nebo_g095_negative_probe:
    push rbx
    push r12
    mov r12d,edi
    call g95_clear
    mov dword [rel g95_request+NEBO_G095_REQUEST_KIND_OFFSET],NEBO_G095_KIND_LINE
    mov dword [rel g95_request+NEBO_G095_REQUEST_TARGET_OFFSET],NEBO_G095_TARGET_HEADLESS
    mov qword [rel g95_request+NEBO_G095_REQUEST_POINTS_OFFSET],4
    mov qword [rel g95_request+NEBO_G095_REQUEST_SERIES_OFFSET],1
    mov qword [rel g95_request+NEBO_G095_REQUEST_X_COUNT_OFFSET],4
    mov qword [rel g95_request+NEBO_G095_REQUEST_Y_COUNT_OFFSET],4
    mov qword [rel g95_request+NEBO_G095_REQUEST_OPTIONS_OFFSET],NEBO_G095_OPTION_X | NEBO_G095_OPTION_Y
    mov qword [rel g95_request+NEBO_G095_REQUEST_GENERATION_OFFSET],1
    lea rax,[rel g95_x]
    mov [rel g95_request+NEBO_G095_REQUEST_X_PTR_OFFSET],rax
    lea rax,[rel g95_y]
    mov [rel g95_request+NEBO_G095_REQUEST_Y_PTR_OFFSET],rax
    lea rax,[rel g95_missing]
    mov [rel g95_request+NEBO_G095_REQUEST_MISSING_PTR_OFFSET],rax
    mov rax,0x3ff0000000000000
    mov [rel g95_x],rax
    mov rax,0x4000000000000000
    mov [rel g95_x+8],rax
    mov rax,0x4008000000000000
    mov [rel g95_x+16],rax
    mov rax,0x4010000000000000
    mov [rel g95_x+24],rax
    mov rax,0x4014000000000000
    mov [rel g95_y],rax
    mov rax,0x4018000000000000
    mov [rel g95_y+8],rax
    mov rax,0x401c000000000000
    mov [rel g95_y+16],rax
    mov rax,0x4020000000000000
    mov [rel g95_y+24],rax
    mov rax,0x6a6a6a6a6a6a6a6a
    mov [rel g95_headless],rax
    cmp r12d,1
    je .bad_kind
    cmp r12d,2
    je .bad_target
    cmp r12d,3
    je .zero_points
    cmp r12d,4
    je .too_many
    cmp r12d,5
    je .bad_shape
    cmp r12d,6
    je .bad_bins
    cmp r12d,7
    je .bad_heatmap
    cmp r12d,8
    je .bad_nan
    cmp r12d,9
    je .bad_missing
    cmp r12d,10
    je .bad_options
    mov eax,-1
    jmp .negative_done
.bad_kind:
    mov dword [rel g95_request+NEBO_G095_REQUEST_KIND_OFFSET],0
    jmp .negative_run
.bad_target:
    mov dword [rel g95_request+NEBO_G095_REQUEST_TARGET_OFFSET],0
    jmp .negative_run
.zero_points:
    mov qword [rel g95_request+NEBO_G095_REQUEST_POINTS_OFFSET],0
    jmp .negative_run
.too_many:
    mov qword [rel g95_request+NEBO_G095_REQUEST_POINTS_OFFSET],NEBO_G095_MAX_POINTS+1
    jmp .negative_run
.bad_shape:
    mov qword [rel g95_request+NEBO_G095_REQUEST_X_COUNT_OFFSET],3
    jmp .negative_run
.bad_bins:
    mov dword [rel g95_request+NEBO_G095_REQUEST_KIND_OFFSET],NEBO_G095_KIND_HISTOGRAM
    mov qword [rel g95_request+NEBO_G095_REQUEST_OPTIONS_OFFSET],NEBO_G095_OPTION_Y | NEBO_G095_OPTION_BINS
    jmp .negative_run
.bad_heatmap:
    mov dword [rel g95_request+NEBO_G095_REQUEST_KIND_OFFSET],NEBO_G095_KIND_HEATMAP
    mov qword [rel g95_request+NEBO_G095_REQUEST_OPTIONS_OFFSET],NEBO_G095_OPTION_Y
    mov qword [rel g95_request+NEBO_G095_REQUEST_ROWS_OFFSET],2
    mov qword [rel g95_request+NEBO_G095_REQUEST_COLUMNS_OFFSET],3
    jmp .negative_run
.bad_nan:
    mov rax,0x7ff8000000000001
    mov [rel g95_y],rax
    jmp .negative_run
.bad_missing:
    mov byte [rel g95_missing],1
    jmp .negative_run
.bad_options:
    mov qword [rel g95_request+NEBO_G095_REQUEST_OPTIONS_OFFSET],0x200
.negative_run:
    lea rdi,[rel g95_request]
    lea rsi,[rel g95_headless]
    call nebo_g095_chart_model
    mov ebx,eax
    mov rax,0x6a6a6a6a6a6a6a6a
    cmp [rel g95_headless],rax
    jne .atomicity_failed
    mov eax,ebx
    jmp .negative_done
.atomicity_failed:
    mov eax,-1
.negative_done:
    pop r12
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
