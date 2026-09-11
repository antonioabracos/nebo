bits 64
default rel
%include "runtime/charts/charts.inc"

%macro ASSERT_EAX 1
    inc r15d
    cmp eax,%1
    jne fail
%endmacro
%macro ASSERT_Q 2
    inc r15d
    mov r11,%2
    cmp qword %1,r11
    jne fail
%endmacro
%macro ASSERT_D 2
    inc r15d
    cmp dword %1,%2
    jne fail
%endmacro
%macro ASSERT_NONZERO_Q 1
    inc r15d
    cmp qword %1,0
    je fail
%endmacro
%macro CHECK_Q 2
    mov r11,%2
    cmp qword %1,r11
    jne fail
%endmacro

section .rodata align=8
line_x: dq 0.0,1.0,2.0,3.0,4.0
line_y: dq 1.0,4.0,2.0,5.0,3.0
scatter_matrix_data: dq 0.5,2.0,1.5,3.0,2.5,1.0,3.5,4.0
bar_y: dq 2.0,1.0,3.0,2.0
hist_y: dq -1.0,-0.5,0.0,0.5,1.0,1.5
single_y: dq 1.0
nan_y: dq 0x7ff8000000000000
inf_y: dq 0x7ff0000000000000
label_line: db 'LINE'
label_scatter: db 'SCATTER'
label_bar: db 'BAR'
label_hist: db 'HIST'
label_one: db 'ONE'
invalid_utf8: db 0xc0,0x80
chart_title: db 'NEBO CHARTS'
x_label: db 'X'
y_label: db 'Y'
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

section .bss align=16
chart: resb NEBO_CHART_SIZE
series: resb NEBO_CHART_SERIES_SIZE*8
small_chart: resb NEBO_CHART_SIZE
small_series: resb NEBO_CHART_SERIES_SIZE
empty_chart: resb NEBO_CHART_SIZE
empty_series: resb NEBO_CHART_SERIES_SIZE
empty_canvas: resb NEBO_CANVAS_SIZE
empty_pixels: resb 160*120*4
empty_commands: resb NEBO_CANVAS_COMMAND_SIZE*32
empty_result: resb NEBO_CHART_RESULT_SIZE
canvas: resb NEBO_CANVAS_SIZE
pixels: resb 160*120*4
commands: resb NEBO_CANVAS_COMMAND_SIZE*256
small_canvas: resb NEBO_CANVAS_SIZE
small_pixels: resb 100*100*4
small_commands: resb NEBO_CANVAS_COMMAND_SIZE*2
budget_canvas: resb NEBO_CANVAS_SIZE
budget_pixels: resb 160*120*4
budget_commands: resb NEBO_CANVAS_COMMAND_SIZE*2
series_spec: resb NEBO_CHART_SERIES_SIZE
axis_options: resb NEBO_CHART_AXIS_SIZE
legend_options: resb NEBO_CHART_LEGEND_SIZE
render_result: resb NEBO_CHART_RESULT_SIZE
matrix_desc: resb NEBO_MATRIX_SIZE
saved_command_count: resq 1
saved_total_points: resq 1

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
zero_legend:
    lea rdi,[rel legend_options]
    mov ecx,NEBO_CHART_LEGEND_SIZE/8
    xor eax,eax
    rep stosq
    ret

_start:
    xor r15d,r15d

    ; Init validates argument, capacity, owner and storage disjointness atomically.
    lea rdi,[rel chart]
    mov rax,0x1122334455667788
    mov [rdi],rax
    xor edi,edi
    lea rsi,[rel series]
    mov edx,8
    mov ecx,0x1808
    call nebo_chart_init
    ASSERT_EAX NEBO_CHART_ERROR_INVALID_ARGUMENT
    ASSERT_Q [rel chart],0x1122334455667788

    lea rdi,[rel chart]
    lea rsi,[rel chart]
    mov edx,8
    mov ecx,0x1808
    call nebo_chart_init
    ASSERT_EAX NEBO_CHART_ERROR_STORAGE_OVERLAP
    ASSERT_Q [rel chart],0x1122334455667788

    lea rdi,[rel chart]
    lea rsi,[rel series]
    xor edx,edx
    mov ecx,0x1808
    call nebo_chart_init
    ASSERT_EAX NEBO_CHART_ERROR_LIMIT_EXCEEDED
    lea rdi,[rel chart]
    lea rsi,[rel series]
    mov edx,33
    mov ecx,0x1808
    call nebo_chart_init
    ASSERT_EAX NEBO_CHART_ERROR_LIMIT_EXCEEDED
    lea rdi,[rel chart]
    lea rsi,[rel series]
    mov edx,8
    xor ecx,ecx
    call nebo_chart_init
    ASSERT_EAX NEBO_CHART_ERROR_OWNER_MISMATCH

    lea rdi,[rel chart]
    lea rsi,[rel series]
    mov edx,8
    mov ecx,0x1808
    call nebo_chart_init
    ASSERT_EAX 0
    ASSERT_Q [rel chart+NEBO_CHART_SERIES_CAPACITY_OFFSET],8
    ASSERT_Q [rel chart+NEBO_CHART_SERIES_COUNT_OFFSET],0
    ASSERT_Q [rel chart+NEBO_CHART_TOTAL_POINTS_OFFSET],0
    ASSERT_D [rel chart+NEBO_CHART_STATE_OFFSET],NEBO_CHART_STATE_ACTIVE
    ASSERT_Q [rel chart+NEBO_CHART_OWNER_CONTEXT_OFFSET],0x1808
    ASSERT_Q [rel chart+NEBO_CHART_X_TICKS_OFFSET],5
    ASSERT_Q [rel chart+NEBO_CHART_Y_TICKS_OFFSET],5
    ASSERT_Q [rel chart+NEBO_CHART_MAGIC_OFFSET],NEBO_CHART_MAGIC
    lea rdi,[rel chart]
    call nebo_chart_validate
    ASSERT_EAX 0

    ; A zero-series chart is valid: it renders deterministic default [-1,+1]
    ; axes and binds an unowned caller-owned Canvas only after all preflights.
    lea rdi,[rel empty_chart]
    lea rsi,[rel empty_series]
    mov edx,1
    mov ecx,0x1809
    call nebo_chart_init
    ASSERT_EAX 0
    lea rdi,[rel empty_canvas]
    lea rsi,[rel empty_pixels]
    mov edx,160*120*4
    mov ecx,160
    mov r8d,120
    lea r9,[rel empty_commands]
    sub rsp,16
    mov qword [rsp],32
    call nebo_canvas_create
    add rsp,16
    ASSERT_EAX 0
    ASSERT_Q [rel empty_canvas+NEBO_CANVAS_OWNER_CONTEXT_OFFSET],0
    lea rdi,[rel empty_chart]
    lea rsi,[rel empty_canvas]
    lea rdx,[rel empty_result]
    call nebo_chart_render
    ASSERT_EAX 0
    ASSERT_Q [rel empty_result+NEBO_CHART_RESULT_SERIES_OFFSET],0
    ASSERT_Q [rel empty_result+NEBO_CHART_RESULT_POINTS_OFFSET],0
    ASSERT_Q [rel empty_result+NEBO_CHART_RESULT_COMMANDS_OFFSET],24
    ASSERT_Q [rel empty_result+NEBO_CHART_RESULT_X_MIN_OFFSET],0xbff0000000000000
    ASSERT_Q [rel empty_result+NEBO_CHART_RESULT_X_MAX_OFFSET],0x3ff0000000000000
    ASSERT_Q [rel empty_result+NEBO_CHART_RESULT_Y_MIN_OFFSET],0xbff0000000000000
    ASSERT_Q [rel empty_result+NEBO_CHART_RESULT_Y_MAX_OFFSET],0x3ff0000000000000
    ASSERT_Q [rel empty_canvas+NEBO_CANVAS_OWNER_CONTEXT_OFFSET],0x1809
    ASSERT_Q [rel empty_canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],24
    lea rdi,[rel empty_chart]
    call nebo_chart_close
    ASSERT_EAX 0

    ; Invalid series are rejected without changing the chart.
    call zero_spec
    mov dword [rel series_spec+NEBO_CHART_SERIES_SOURCE_OFFSET],NEBO_CHART_SOURCE_ARRAY
    mov dword [rel series_spec+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_SHOW_POINTS
    mov dword [rel series_spec+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET],0xff5060ff
    mov qword [rel series_spec+NEBO_CHART_SERIES_POINT_RADIUS_OFFSET],2
    lea rax,[rel line_x]
    mov [rel series_spec+NEBO_CHART_SERIES_X_PTR_OFFSET],rax
    lea rax,[rel single_y]
    mov [rel series_spec+NEBO_CHART_SERIES_Y_PTR_OFFSET],rax
    mov qword [rel series_spec+NEBO_CHART_SERIES_POINT_COUNT_OFFSET],1
    mov qword [rel series_spec+NEBO_CHART_SERIES_X_STRIDE_OFFSET],1
    mov qword [rel series_spec+NEBO_CHART_SERIES_Y_STRIDE_OFFSET],1
    lea rax,[rel label_line]
    mov [rel series_spec+NEBO_CHART_SERIES_LABEL_PTR_OFFSET],rax
    mov qword [rel series_spec+NEBO_CHART_SERIES_LABEL_LENGTH_OFFSET],4
    lea rdi,[rel chart]
    lea rsi,[rel series_spec]
    call nebo_chart_line
    ASSERT_EAX NEBO_CHART_ERROR_EMPTY_DATA
    ASSERT_Q [rel chart+NEBO_CHART_SERIES_COUNT_OFFSET],0

    mov qword [rel series_spec+NEBO_CHART_SERIES_POINT_COUNT_OFFSET],4097
    lea rdi,[rel chart]
    lea rsi,[rel series_spec]
    call nebo_chart_line
    ASSERT_EAX NEBO_CHART_ERROR_LIMIT_EXCEEDED
    ASSERT_Q [rel chart+NEBO_CHART_SERIES_COUNT_OFFSET],0

    mov qword [rel series_spec+NEBO_CHART_SERIES_POINT_COUNT_OFFSET],5
    lea rax,[rel invalid_utf8]
    mov [rel series_spec+NEBO_CHART_SERIES_LABEL_PTR_OFFSET],rax
    mov qword [rel series_spec+NEBO_CHART_SERIES_LABEL_LENGTH_OFFSET],2
    lea rdi,[rel chart]
    lea rsi,[rel series_spec]
    call nebo_chart_line
    ASSERT_EAX NEBO_CHART_ERROR_INVALID_UTF8
    ASSERT_Q [rel chart+NEBO_CHART_SERIES_COUNT_OFFSET],0

    ; Valid line array.
    lea rax,[rel label_line]
    mov [rel series_spec+NEBO_CHART_SERIES_LABEL_PTR_OFFSET],rax
    mov qword [rel series_spec+NEBO_CHART_SERIES_LABEL_LENGTH_OFFSET],4
    lea rax,[rel line_y]
    mov [rel series_spec+NEBO_CHART_SERIES_Y_PTR_OFFSET],rax
    lea rdi,[rel chart]
    lea rsi,[rel series_spec]
    call nebo_chart_line
    ASSERT_EAX 0
    ASSERT_Q [rel chart+NEBO_CHART_SERIES_COUNT_OFFSET],1
    ASSERT_Q [rel chart+NEBO_CHART_TOTAL_POINTS_OFFSET],5
    ASSERT_D [rel series+NEBO_CHART_SERIES_KIND_OFFSET],NEBO_CHART_KIND_LINE
    ASSERT_Q [rel series+NEBO_CHART_SERIES_POINT_COUNT_OFFSET],5

    ; Matrix F64 scatter reuses funcoes_lambdas_callbacks_e_referencias storage and validates columns.
    lea rdi,[rel matrix_desc]
    lea rsi,[rel scatter_matrix_data]
    mov edx,4
    mov ecx,2
    mov r8d,NEBO_MATRIX_DTYPE_F64
    mov r9d,0x1508
    call nebo_matrix_init_owned
    ASSERT_EAX 0
    call zero_spec
    mov dword [rel series_spec+NEBO_CHART_SERIES_SOURCE_OFFSET],NEBO_CHART_SOURCE_MATRIX
    mov dword [rel series_spec+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET],0x50ff80ff
    mov qword [rel series_spec+NEBO_CHART_SERIES_POINT_RADIUS_OFFSET],2
    lea rax,[rel label_scatter]
    mov [rel series_spec+NEBO_CHART_SERIES_LABEL_PTR_OFFSET],rax
    mov qword [rel series_spec+NEBO_CHART_SERIES_LABEL_LENGTH_OFFSET],7
    lea rax,[rel matrix_desc]
    mov [rel series_spec+NEBO_CHART_SERIES_MATRIX_PTR_OFFSET],rax
    mov qword [rel series_spec+NEBO_CHART_SERIES_X_COLUMN_OFFSET],0
    mov qword [rel series_spec+NEBO_CHART_SERIES_Y_COLUMN_OFFSET],1
    lea rdi,[rel chart]
    lea rsi,[rel series_spec]
    call nebo_chart_scatter
    ASSERT_EAX 0
    ASSERT_Q [rel chart+NEBO_CHART_SERIES_COUNT_OFFSET],2
    ASSERT_Q [rel chart+NEBO_CHART_TOTAL_POINTS_OFFSET],9
    ASSERT_D [rel series+NEBO_CHART_SERIES_SIZE+NEBO_CHART_SERIES_SOURCE_OFFSET],NEBO_CHART_SOURCE_MATRIX
    ASSERT_Q [rel series+NEBO_CHART_SERIES_SIZE+NEBO_CHART_SERIES_POINT_COUNT_OFFSET],4

    mov qword [rel series_spec+NEBO_CHART_SERIES_Y_COLUMN_OFFSET],2
    lea rdi,[rel chart]
    lea rsi,[rel series_spec]
    call nebo_chart_scatter
    ASSERT_EAX NEBO_CHART_ERROR_MATRIX
    ASSERT_Q [rel chart+NEBO_CHART_SERIES_COUNT_OFFSET],2

    ; Bar category cardinality and valid auto-X series.
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
    mov qword [rel series_spec+NEBO_CHART_SERIES_CATEGORY_COUNT_OFFSET],3
    lea rdi,[rel chart]
    lea rsi,[rel series_spec]
    call nebo_chart_bar
    ASSERT_EAX NEBO_CHART_ERROR_CATEGORY_MISMATCH
    ASSERT_Q [rel chart+NEBO_CHART_SERIES_COUNT_OFFSET],2
    mov qword [rel series_spec+NEBO_CHART_SERIES_CATEGORY_COUNT_OFFSET],4
    lea rdi,[rel chart]
    lea rsi,[rel series_spec]
    call nebo_chart_bar
    ASSERT_EAX 0
    ASSERT_Q [rel chart+NEBO_CHART_SERIES_COUNT_OFFSET],3
    ASSERT_Q [rel chart+NEBO_CHART_TOTAL_POINTS_OFFSET],13

    ; Histogram rejects empty, NaN, infinity and invalid bins.
    call zero_spec
    mov dword [rel series_spec+NEBO_CHART_SERIES_SOURCE_OFFSET],NEBO_CHART_SOURCE_ARRAY
    mov dword [rel series_spec+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_AUTO_X
    mov dword [rel series_spec+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET],0xffc050ff
    lea rax,[rel hist_y]
    mov [rel series_spec+NEBO_CHART_SERIES_Y_PTR_OFFSET],rax
    mov qword [rel series_spec+NEBO_CHART_SERIES_Y_STRIDE_OFFSET],1
    lea rax,[rel label_hist]
    mov [rel series_spec+NEBO_CHART_SERIES_LABEL_PTR_OFFSET],rax
    mov qword [rel series_spec+NEBO_CHART_SERIES_LABEL_LENGTH_OFFSET],4
    mov qword [rel series_spec+NEBO_CHART_SERIES_BINS_OFFSET],4
    lea rdi,[rel chart]
    lea rsi,[rel series_spec]
    call nebo_chart_histogram
    ASSERT_EAX NEBO_CHART_ERROR_EMPTY_DATA

    mov qword [rel series_spec+NEBO_CHART_SERIES_POINT_COUNT_OFFSET],1
    lea rax,[rel nan_y]
    mov [rel series_spec+NEBO_CHART_SERIES_Y_PTR_OFFSET],rax
    lea rdi,[rel chart]
    lea rsi,[rel series_spec]
    call nebo_chart_histogram
    ASSERT_EAX NEBO_CHART_ERROR_NONFINITE_DATA
    lea rax,[rel inf_y]
    mov [rel series_spec+NEBO_CHART_SERIES_Y_PTR_OFFSET],rax
    lea rdi,[rel chart]
    lea rsi,[rel series_spec]
    call nebo_chart_histogram
    ASSERT_EAX NEBO_CHART_ERROR_NONFINITE_DATA
    lea rax,[rel hist_y]
    mov [rel series_spec+NEBO_CHART_SERIES_Y_PTR_OFFSET],rax
    mov qword [rel series_spec+NEBO_CHART_SERIES_POINT_COUNT_OFFSET],6
    mov qword [rel series_spec+NEBO_CHART_SERIES_BINS_OFFSET],0
    lea rdi,[rel chart]
    lea rsi,[rel series_spec]
    call nebo_chart_histogram
    ASSERT_EAX NEBO_CHART_ERROR_INVALID_BINS
    mov qword [rel series_spec+NEBO_CHART_SERIES_BINS_OFFSET],65
    lea rdi,[rel chart]
    lea rsi,[rel series_spec]
    call nebo_chart_histogram
    ASSERT_EAX NEBO_CHART_ERROR_INVALID_BINS
    mov qword [rel series_spec+NEBO_CHART_SERIES_BINS_OFFSET],4
    lea rdi,[rel chart]
    lea rsi,[rel series_spec]
    call nebo_chart_histogram
    ASSERT_EAX 0
    ASSERT_Q [rel chart+NEBO_CHART_SERIES_COUNT_OFFSET],4
    ASSERT_Q [rel chart+NEBO_CHART_TOTAL_POINTS_OFFSET],19

    ; Capacity is independent from global limits.
    lea rdi,[rel small_chart]
    lea rsi,[rel small_series]
    mov edx,1
    mov ecx,0x1808
    call nebo_chart_init
    ASSERT_EAX 0
    call zero_spec
    mov dword [rel series_spec+NEBO_CHART_SERIES_SOURCE_OFFSET],NEBO_CHART_SOURCE_ARRAY
    mov dword [rel series_spec+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_AUTO_X
    mov dword [rel series_spec+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET],0x010203ff
    lea rax,[rel hist_y]
    mov [rel series_spec+NEBO_CHART_SERIES_Y_PTR_OFFSET],rax
    mov qword [rel series_spec+NEBO_CHART_SERIES_POINT_COUNT_OFFSET],6
    mov qword [rel series_spec+NEBO_CHART_SERIES_Y_STRIDE_OFFSET],1
    lea rax,[rel label_one]
    mov [rel series_spec+NEBO_CHART_SERIES_LABEL_PTR_OFFSET],rax
    mov qword [rel series_spec+NEBO_CHART_SERIES_LABEL_LENGTH_OFFSET],3
    mov qword [rel series_spec+NEBO_CHART_SERIES_BINS_OFFSET],2
    lea rdi,[rel small_chart]
    lea rsi,[rel series_spec]
    call nebo_chart_histogram
    ASSERT_EAX 0
    lea rdi,[rel small_chart]
    lea rsi,[rel series_spec]
    call nebo_chart_histogram
    ASSERT_EAX NEBO_CHART_ERROR_SERIES_FULL
    ASSERT_Q [rel small_chart+NEBO_CHART_SERIES_COUNT_OFFSET],1

    ; Title, axes and legend configuration.
    lea rdi,[rel chart]
    lea rsi,[rel chart_title]
    xor edx,edx
    call nebo_chart_title
    ASSERT_EAX NEBO_CHART_ERROR_INVALID_UTF8
    lea rdi,[rel chart]
    lea rsi,[rel invalid_utf8]
    mov edx,2
    call nebo_chart_title
    ASSERT_EAX NEBO_CHART_ERROR_INVALID_UTF8
    lea rdi,[rel chart]
    lea rsi,[rel chart_title]
    mov edx,11
    call nebo_chart_title
    ASSERT_EAX 0
    ASSERT_Q [rel chart+NEBO_CHART_TITLE_LENGTH_OFFSET],11
    ASSERT_D [rel chart+NEBO_CHART_FLAGS_OFFSET],NEBO_CHART_FLAG_TITLE

    call zero_axis
    mov dword [rel axis_options+NEBO_CHART_AXIS_ID_OFFSET],9
    mov qword [rel axis_options+NEBO_CHART_AXIS_TICKS_OFFSET],5
    lea rdi,[rel chart]
    lea rsi,[rel axis_options]
    call nebo_chart_axis
    ASSERT_EAX NEBO_CHART_ERROR_INVALID_ARGUMENT
    mov dword [rel axis_options+NEBO_CHART_AXIS_ID_OFFSET],NEBO_CHART_AXIS_X
    mov qword [rel axis_options+NEBO_CHART_AXIS_TICKS_OFFSET],1
    lea rdi,[rel chart]
    lea rsi,[rel axis_options]
    call nebo_chart_axis
    ASSERT_EAX NEBO_CHART_ERROR_LIMIT_EXCEEDED
    mov qword [rel axis_options+NEBO_CHART_AXIS_TICKS_OFFSET],5
    mov dword [rel axis_options+NEBO_CHART_AXIS_FLAGS_OFFSET],NEBO_CHART_AXIS_FLAG_MANUAL_RANGE
    mov rax,0x3ff0000000000000
    mov [rel axis_options+NEBO_CHART_AXIS_MIN_OFFSET],rax
    mov rax,0x3ff0000000000000
    mov [rel axis_options+NEBO_CHART_AXIS_MAX_OFFSET],rax
    lea rdi,[rel chart]
    lea rsi,[rel axis_options]
    call nebo_chart_axis
    ASSERT_EAX NEBO_CHART_ERROR_INVALID_RANGE
    mov rax,0x7ff8000000000000
    mov [rel axis_options+NEBO_CHART_AXIS_MIN_OFFSET],rax
    mov rax,0x4000000000000000
    mov [rel axis_options+NEBO_CHART_AXIS_MAX_OFFSET],rax
    lea rdi,[rel chart]
    lea rsi,[rel axis_options]
    call nebo_chart_axis
    ASSERT_EAX NEBO_CHART_ERROR_INVALID_RANGE

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
    ASSERT_EAX 0
    ASSERT_Q [rel chart+NEBO_CHART_X_TICKS_OFFSET],5
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
    ASSERT_EAX 0
    ASSERT_Q [rel chart+NEBO_CHART_Y_TICKS_OFFSET],5

    call zero_legend
    mov dword [rel legend_options+NEBO_CHART_LEGEND_OPTIONS_FLAGS_OFFSET],NEBO_CHART_LEGEND_FLAG_ENABLED
    mov qword [rel legend_options+NEBO_CHART_LEGEND_MAX_OFFSET],4
    mov qword [rel legend_options+NEBO_CHART_LEGEND_POSITION_OFFSET],2
    lea rdi,[rel chart]
    lea rsi,[rel legend_options]
    call nebo_chart_legend
    ASSERT_EAX NEBO_CHART_ERROR_UNSUPPORTED
    mov qword [rel legend_options+NEBO_CHART_LEGEND_POSITION_OFFSET],NEBO_CHART_LEGEND_TOP_RIGHT
    mov qword [rel legend_options+NEBO_CHART_LEGEND_MAX_OFFSET],3
    lea rdi,[rel chart]
    lea rsi,[rel legend_options]
    call nebo_chart_legend
    ASSERT_EAX 0

    ; Canvas and render preflights.
    lea rdi,[rel canvas]
    lea rsi,[rel pixels]
    mov edx,160*120*4
    mov ecx,160
    mov r8d,120
    lea r9,[rel commands]
    sub rsp,16
    mov qword [rsp],256
    call nebo_canvas_create
    add rsp,16
    ASSERT_EAX 0
    ASSERT_Q [rel canvas+NEBO_CANVAS_OWNER_CONTEXT_OFFSET],0

    ; Legend capacity smaller than active series is rejected before Canvas mutation.
    mov rax,[rel canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET]
    mov [rel saved_command_count],rax
    lea rdi,[rel chart]
    lea rsi,[rel canvas]
    lea rdx,[rel render_result]
    call nebo_chart_render
    ASSERT_EAX NEBO_CHART_ERROR_LIMIT_EXCEEDED
    mov rax,[rel saved_command_count]
    ASSERT_Q [rel canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],rax
    ASSERT_Q [rel canvas+NEBO_CANVAS_OWNER_CONTEXT_OFFSET],0
    mov qword [rel legend_options+NEBO_CHART_LEGEND_MAX_OFFSET],4
    lea rdi,[rel chart]
    lea rsi,[rel legend_options]
    call nebo_chart_legend
    ASSERT_EAX 0

    ; Tampered point aggregate is detected before Canvas mutation.
    mov rax,[rel chart+NEBO_CHART_TOTAL_POINTS_OFFSET]
    mov [rel saved_total_points],rax
    inc qword [rel chart+NEBO_CHART_TOTAL_POINTS_OFFSET]
    lea rdi,[rel chart]
    lea rsi,[rel canvas]
    lea rdx,[rel render_result]
    call nebo_chart_render
    ASSERT_EAX NEBO_CHART_ERROR_BAD_STATE
    ASSERT_Q [rel canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],0
    mov rax,[rel saved_total_points]
    mov [rel chart+NEBO_CHART_TOTAL_POINTS_OFFSET],rax

    ; Result overlap is rejected before drawing.
    lea rdi,[rel chart]
    lea rsi,[rel canvas]
    lea rdx,[rel chart]
    call nebo_chart_render
    ASSERT_EAX NEBO_CHART_ERROR_STORAGE_OVERLAP
    ASSERT_Q [rel canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],0

    ; Valid deterministic composite render.
    lea rdi,[rel chart]
    lea rsi,[rel canvas]
    lea rdx,[rel render_result]
    call nebo_chart_render
    ASSERT_EAX 0
    ASSERT_Q [rel render_result+NEBO_CHART_RESULT_SERIES_OFFSET],4
    ASSERT_Q [rel render_result+NEBO_CHART_RESULT_POINTS_OFFSET],19
    ASSERT_Q [rel render_result+NEBO_CHART_RESULT_COMMANDS_OFFSET],61
    ASSERT_Q [rel render_result+NEBO_CHART_RESULT_PIXEL_HASH_OFFSET],0xcf14ea3a30ecbcc0
    ASSERT_Q [rel render_result+NEBO_CHART_RESULT_X_MIN_OFFSET],0xbff0000000000000
    ASSERT_Q [rel render_result+NEBO_CHART_RESULT_X_MAX_OFFSET],0x4010000000000000
    ASSERT_Q [rel render_result+NEBO_CHART_RESULT_Y_MIN_OFFSET],0
    ASSERT_Q [rel render_result+NEBO_CHART_RESULT_Y_MAX_OFFSET],0x4018000000000000
    ASSERT_Q [rel canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],61
    ASSERT_Q [rel canvas+NEBO_CANVAS_OWNER_CONTEXT_OFFSET],0x1808
    ASSERT_Q [rel chart+NEBO_CHART_RENDER_GENERATION_OFFSET],1
    ASSERT_Q [rel chart+NEBO_CHART_LAST_COMMAND_COUNT_OFFSET],61
    ASSERT_Q [rel chart+NEBO_CHART_LAST_PIXEL_HASH_OFFSET],0xcf14ea3a30ecbcc0
    ASSERT_D [rel chart+NEBO_CHART_FLAGS_OFFSET],NEBO_CHART_FLAG_TITLE | NEBO_CHART_FLAG_X_AXIS | NEBO_CHART_FLAG_Y_AXIS | NEBO_CHART_FLAG_LEGEND | NEBO_CHART_FLAG_RENDERED
    ASSERT_Q [rel chart+NEBO_CHART_LAST_STATUS_OFFSET],0
    ASSERT_Q [rel chart+NEBO_CHART_LAST_ERROR_OFFSET],0

    ; Canvas size, command budget and owner mismatch are atomic.
    lea rdi,[rel small_canvas]
    lea rsi,[rel small_pixels]
    mov edx,100*100*4
    mov ecx,100
    mov r8d,100
    lea r9,[rel small_commands]
    sub rsp,16
    mov qword [rsp],2
    call nebo_canvas_create
    add rsp,16
    ASSERT_EAX 0
    mov qword [rel small_canvas+NEBO_CANVAS_OWNER_CONTEXT_OFFSET],0x1808
    lea rdi,[rel chart]
    lea rsi,[rel small_canvas]
    lea rdx,[rel render_result]
    call nebo_chart_render
    ASSERT_EAX NEBO_CHART_ERROR_CANVAS_SIZE
    ASSERT_Q [rel small_canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],0

    ; Valid dimensions with only two command records hit the exact budget gate.
    lea rdi,[rel budget_canvas]
    lea rsi,[rel budget_pixels]
    mov edx,160*120*4
    mov ecx,160
    mov r8d,120
    lea r9,[rel budget_commands]
    sub rsp,16
    mov qword [rsp],2
    call nebo_canvas_create
    add rsp,16
    ASSERT_EAX 0
    mov qword [rel budget_canvas+NEBO_CANVAS_OWNER_CONTEXT_OFFSET],0x1808
    lea rdi,[rel chart]
    lea rsi,[rel budget_canvas]
    lea rdx,[rel render_result]
    call nebo_chart_render
    ASSERT_EAX NEBO_CHART_ERROR_COMMAND_BUDGET
    ASSERT_Q [rel budget_canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],0
    mov qword [rel budget_canvas+NEBO_CANVAS_OWNER_CONTEXT_OFFSET],0x9999
    lea rdi,[rel chart]
    lea rsi,[rel budget_canvas]
    lea rdx,[rel render_result]
    call nebo_chart_render
    ASSERT_EAX NEBO_CHART_ERROR_OWNER_MISMATCH

    ; Close is terminal and exact.
    lea rdi,[rel chart]
    call nebo_chart_close
    ASSERT_EAX 0
    ASSERT_D [rel chart+NEBO_CHART_STATE_OFFSET],NEBO_CHART_STATE_CLOSED
    lea rdi,[rel chart]
    call nebo_chart_validate
    ASSERT_EAX 0
    lea rdi,[rel chart]
    call nebo_chart_close
    ASSERT_EAX NEBO_CHART_ERROR_CLOSED
    lea rdi,[rel chart]
    lea rsi,[rel series_spec]
    call nebo_chart_histogram
    ASSERT_EAX NEBO_CHART_ERROR_CLOSED
    lea rdi,[rel chart]
    lea rsi,[rel canvas]
    lea rdx,[rel render_result]
    call nebo_chart_render
    ASSERT_EAX NEBO_CHART_ERROR_CLOSED

    ; The exact focused assertion contract is frozen by the validator.
    cmp r15d,122
    jne fail
    mov eax,60
    xor edi,edi
    syscall
fail:
    mov eax,60
    mov edi,1
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
