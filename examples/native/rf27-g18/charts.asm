bits 64
default rel
%include "runtime/charts/charts.inc"

; CONTROLO-DE-FLUXO-ESTRUTURADO-F08 public bounded-native chart composition example.
; The G018 source vertical now reaches the same bounded chart owners.
section .rodata align=8
line_x: dq 0.0,1.0,2.0,3.0,4.0
line_y: dq 1.0,4.0,2.0,5.0,3.0
scatter_x: dq 0.5,1.5,2.5,3.5
scatter_y: dq 2.0,3.0,1.0,4.0
bar_y: dq 2.0,1.0,3.0,2.0
hist_y: dq -1.0,-0.5,0.0,0.5,1.0,1.5
label_line: db 'LINE'
label_scatter: db 'SCATTER'
label_bar: db 'BAR'
label_hist: db 'HIST'
category_a: db 'A'
category_b: db 'B'
category_c: db 'C'
category_d: db 'D'
align 8
categories:
    dq category_a,1
    dq category_b,1
    dq category_c,1
    dq category_d,1
chart_title: db 'NEBO CHARTS'
x_label: db 'X'
y_label: db 'Y'

section .bss align=16
chart: resb NEBO_CHART_SIZE
series: resb NEBO_CHART_SERIES_SIZE*8
canvas: resb NEBO_CANVAS_SIZE
pixels: resb 160*120*4
commands: resb NEBO_CANVAS_COMMAND_SIZE*128
rgba: resb 160*120*4
series_spec: resb NEBO_CHART_SERIES_SIZE
axis_options: resb NEBO_CHART_AXIS_SIZE
legend_options: resb NEBO_CHART_LEGEND_SIZE
render_result: resb NEBO_CHART_RESULT_SIZE

section .text
global _start

zero_spec:
    lea rdi,[rel series_spec]
    mov ecx,NEBO_CHART_SERIES_QWORDS
    xor eax,eax
    rep stosq
    ret

zero_axis:
    lea rdi,[rel axis_options]
    mov ecx,NEBO_CHART_AXIS_SIZE/8
    xor eax,eax
    rep stosq
    ret

write_all:
    push r12
    push r13
    mov r12,rsi
    mov r13,rdx
.loop:
    test r13,r13
    jz .ok
    mov eax,1
    mov edi,1
    mov rsi,r12
    mov rdx,r13
    syscall
    test rax,rax
    jle .bad
    add r12,rax
    sub r13,rax
    jmp .loop
.ok:
    xor eax,eax
    pop r13
    pop r12
    ret
.bad:
    mov eax,1
    pop r13
    pop r12
    ret

_start:
    ; Caller-owned chart and Canvas.
    lea rdi,[rel chart]
    lea rsi,[rel series]
    mov edx,8
    mov ecx,0x1808
    call nebo_chart_init
    test eax,eax
    jnz fail

    lea rdi,[rel canvas]
    lea rsi,[rel pixels]
    mov edx,160*120*4
    mov ecx,160
    mov r8d,120
    lea r9,[rel commands]
    sub rsp,16
    mov qword [rsp],128
    call nebo_canvas_create
    add rsp,16
    test eax,eax
    jnz fail
    mov qword [rel canvas+NEBO_CANVAS_OWNER_CONTEXT_OFFSET],0x1808

    ; Line with visible point markers.
    call zero_spec
    mov dword [rel series_spec+NEBO_CHART_SERIES_SOURCE_OFFSET],NEBO_CHART_SOURCE_ARRAY
    mov dword [rel series_spec+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_SHOW_POINTS
    mov dword [rel series_spec+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET],0xff5060ff
    mov qword [rel series_spec+NEBO_CHART_SERIES_POINT_RADIUS_OFFSET],2
    lea rax,[rel line_x]
    mov [rel series_spec+NEBO_CHART_SERIES_X_PTR_OFFSET],rax
    lea rax,[rel line_y]
    mov [rel series_spec+NEBO_CHART_SERIES_Y_PTR_OFFSET],rax
    mov qword [rel series_spec+NEBO_CHART_SERIES_POINT_COUNT_OFFSET],5
    mov qword [rel series_spec+NEBO_CHART_SERIES_X_STRIDE_OFFSET],1
    mov qword [rel series_spec+NEBO_CHART_SERIES_Y_STRIDE_OFFSET],1
    lea rax,[rel label_line]
    mov [rel series_spec+NEBO_CHART_SERIES_LABEL_PTR_OFFSET],rax
    mov qword [rel series_spec+NEBO_CHART_SERIES_LABEL_LENGTH_OFFSET],4
    lea rdi,[rel chart]
    lea rsi,[rel series_spec]
    call nebo_chart_line
    test eax,eax
    jnz fail

    ; Scatter.
    call zero_spec
    mov dword [rel series_spec+NEBO_CHART_SERIES_SOURCE_OFFSET],NEBO_CHART_SOURCE_ARRAY
    mov dword [rel series_spec+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET],0x50ff80ff
    mov qword [rel series_spec+NEBO_CHART_SERIES_POINT_RADIUS_OFFSET],2
    lea rax,[rel scatter_x]
    mov [rel series_spec+NEBO_CHART_SERIES_X_PTR_OFFSET],rax
    lea rax,[rel scatter_y]
    mov [rel series_spec+NEBO_CHART_SERIES_Y_PTR_OFFSET],rax
    mov qword [rel series_spec+NEBO_CHART_SERIES_POINT_COUNT_OFFSET],4
    mov qword [rel series_spec+NEBO_CHART_SERIES_X_STRIDE_OFFSET],1
    mov qword [rel series_spec+NEBO_CHART_SERIES_Y_STRIDE_OFFSET],1
    lea rax,[rel label_scatter]
    mov [rel series_spec+NEBO_CHART_SERIES_LABEL_PTR_OFFSET],rax
    mov qword [rel series_spec+NEBO_CHART_SERIES_LABEL_LENGTH_OFFSET],7
    lea rdi,[rel chart]
    lea rsi,[rel series_spec]
    call nebo_chart_scatter
    test eax,eax
    jnz fail

    ; Bar with four deterministic category labels.
    call zero_spec
    mov dword [rel series_spec+NEBO_CHART_SERIES_SOURCE_OFFSET],NEBO_CHART_SOURCE_ARRAY
    mov dword [rel series_spec+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_AUTO_X
    mov dword [rel series_spec+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET],0x5080ffff
    lea rax,[rel bar_y]
    mov [rel series_spec+NEBO_CHART_SERIES_Y_PTR_OFFSET],rax
    mov qword [rel series_spec+NEBO_CHART_SERIES_POINT_COUNT_OFFSET],4
    mov qword [rel series_spec+NEBO_CHART_SERIES_Y_STRIDE_OFFSET],1
    lea rax,[rel label_bar]
    mov [rel series_spec+NEBO_CHART_SERIES_LABEL_PTR_OFFSET],rax
    mov qword [rel series_spec+NEBO_CHART_SERIES_LABEL_LENGTH_OFFSET],3
    lea rax,[rel categories]
    mov [rel series_spec+NEBO_CHART_SERIES_CATEGORIES_PTR_OFFSET],rax
    mov qword [rel series_spec+NEBO_CHART_SERIES_CATEGORY_COUNT_OFFSET],4
    lea rdi,[rel chart]
    lea rsi,[rel series_spec]
    call nebo_chart_bar
    test eax,eax
    jnz fail

    ; Histogram with four bins.
    call zero_spec
    mov dword [rel series_spec+NEBO_CHART_SERIES_SOURCE_OFFSET],NEBO_CHART_SOURCE_ARRAY
    mov dword [rel series_spec+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_AUTO_X
    mov dword [rel series_spec+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET],0xffc050ff
    lea rax,[rel hist_y]
    mov [rel series_spec+NEBO_CHART_SERIES_Y_PTR_OFFSET],rax
    mov qword [rel series_spec+NEBO_CHART_SERIES_POINT_COUNT_OFFSET],6
    mov qword [rel series_spec+NEBO_CHART_SERIES_Y_STRIDE_OFFSET],1
    lea rax,[rel label_hist]
    mov [rel series_spec+NEBO_CHART_SERIES_LABEL_PTR_OFFSET],rax
    mov qword [rel series_spec+NEBO_CHART_SERIES_LABEL_LENGTH_OFFSET],4
    mov qword [rel series_spec+NEBO_CHART_SERIES_BINS_OFFSET],4
    lea rdi,[rel chart]
    lea rsi,[rel series_spec]
    call nebo_chart_histogram
    test eax,eax
    jnz fail

    lea rdi,[rel chart]
    lea rsi,[rel chart_title]
    mov edx,11
    call nebo_chart_title
    test eax,eax
    jnz fail

    call zero_axis
    mov dword [rel axis_options+NEBO_CHART_AXIS_ID_OFFSET],NEBO_CHART_AXIS_X
    mov dword [rel axis_options+NEBO_CHART_AXIS_FLAGS_OFFSET],NEBO_CHART_AXIS_FLAG_GRID
    mov qword [rel axis_options+NEBO_CHART_AXIS_TICKS_OFFSET],5
    lea rax,[rel x_label]
    mov [rel axis_options+NEBO_CHART_AXIS_LABEL_PTR_OFFSET],rax
    mov qword [rel axis_options+NEBO_CHART_AXIS_LABEL_LENGTH_OFFSET],1
    lea rdi,[rel chart]
    lea rsi,[rel axis_options]
    call nebo_chart_axis
    test eax,eax
    jnz fail

    call zero_axis
    mov dword [rel axis_options+NEBO_CHART_AXIS_ID_OFFSET],NEBO_CHART_AXIS_Y
    mov dword [rel axis_options+NEBO_CHART_AXIS_FLAGS_OFFSET],NEBO_CHART_AXIS_FLAG_GRID
    mov qword [rel axis_options+NEBO_CHART_AXIS_TICKS_OFFSET],5
    lea rax,[rel y_label]
    mov [rel axis_options+NEBO_CHART_AXIS_LABEL_PTR_OFFSET],rax
    mov qword [rel axis_options+NEBO_CHART_AXIS_LABEL_LENGTH_OFFSET],1
    lea rdi,[rel chart]
    lea rsi,[rel axis_options]
    call nebo_chart_axis
    test eax,eax
    jnz fail

    lea rdi,[rel legend_options]
    mov ecx,NEBO_CHART_LEGEND_SIZE/8
    xor eax,eax
    rep stosq
    mov dword [rel legend_options+NEBO_CHART_LEGEND_OPTIONS_FLAGS_OFFSET],NEBO_CHART_LEGEND_FLAG_ENABLED
    mov qword [rel legend_options+NEBO_CHART_LEGEND_MAX_OFFSET],4
    mov qword [rel legend_options+NEBO_CHART_LEGEND_POSITION_OFFSET],NEBO_CHART_LEGEND_TOP_RIGHT
    lea rdi,[rel chart]
    lea rsi,[rel legend_options]
    call nebo_chart_legend
    test eax,eax
    jnz fail

    lea rdi,[rel chart]
    lea rsi,[rel canvas]
    lea rdx,[rel render_result]
    call nebo_chart_render
    test eax,eax
    jnz fail
    cmp qword [rel render_result+NEBO_CHART_RESULT_SERIES_OFFSET],4
    jne fail
    cmp qword [rel render_result+NEBO_CHART_RESULT_POINTS_OFFSET],19
    jne fail
    cmp qword [rel render_result+NEBO_CHART_RESULT_COMMANDS_OFFSET],61
    jne fail
    cmp qword [rel canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],61
    jne fail

    ; Close both caller-owned resources after a deterministic render.
    lea rdi,[rel chart]
    call nebo_chart_close
    test eax,eax
    jnz fail
    lea rdi,[rel canvas]
    call nebo_canvas_close
    test eax,eax
    jnz fail

    mov eax,60
    xor edi,edi
    syscall
fail:
    mov eax,60
    mov edi,1
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
