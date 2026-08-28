; cli_driver-controlo_de_fluxo_estruturado-F09 compact bounded-native numeric/visual program.
; It composes representative tree_graph_node_e_edge-controlo_de_fluxo_estruturado surfaces without activating public .no
; syntax.  The program renders deterministically through the F04 headless
; backend and writes a versioned 160-byte pointer-free summary to stdout.
bits 64
default rel

%include "runtime/math/scalar.inc"
%include "runtime/matrix/matrix_core.inc"
%include "runtime/tensor/tensor_core.inc"
%include "runtime/kernel/kernel_planner.inc"
%include "runtime/kernel/scalar_kernels.inc"
%include "runtime/console/document/linear_console_document.inc"
%include "runtime/window/headless/headless_window.inc"
%include "runtime/widgets/widgets.inc"
%include "runtime/charts/charts.inc"

%define APP_OWNER 0x1809
%define APP_WIDTH 160
%define APP_HEIGHT 120
%define APP_SUMMARY_MAGIC 0x4e42504631384639
%define APP_SUMMARY_QWORDS 20
%define APP_SUMMARY_BYTES (APP_SUMMARY_QWORDS*8)

%macro CHECK_EAX_ZERO 0
    test eax,eax
    jnz .fail
%endmacro

section .rodata align=16
f09_value_9: dq 9.0
f09_value_3: dq 3.0
kernel_a: dq 1.0,2.0,3.0,4.0
kernel_b: dq 5.0,4.0,3.0,2.0
matrix_values: dq 0.5,2.0,1.5,3.0,2.5,1.0,3.5,4.0
tensor_shape: dq 2,3
tensor_values: dq 1.0,2.0,3.0,4.0,5.0,6.0
line_x: dq 0.0,1.0,2.0,3.0,4.0
line_y: dq 1.0,4.0,2.0,5.0,3.0
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
chart_title: db 'NEBO NUMERIC VISUAL'
x_label: db 'X'
y_label: db 'Y'
window_title: db 'Nebo F09'
console_title: db 'Nebo F09'
console_line: db 'numeric visual program green'
ui_name_status: db 'Status'
ui_text_status: db 'Ready'
ui_name_action: db 'Action'
ui_text_action: db 'Close'
ui_name_input: db 'Filter'

section .bss align=64
; tree_graph_node_e_edge-operadores_de_fluxo_e_branching_pipelines numeric state.
kernel_result: resq 4
matrix_desc: resb NEBO_MATRIX_SIZE
tensor_desc: resb NEBO_TENSOR_SIZE
tensor_storage: resq 6
plan_request: resb nebo_kernel_planner_REQUEST_SIZE
plan_result: resb NEBO_PLAN_SIZE

; F02 Console document.
console_doc: resb NEBO_CONSOLE_SIZE
console_text_storage: resb 256
console_title_storage: resb 64

; F04 headless Window and stream_event_e_processamento_continuo ownership/cancellation state.
window_runtime: resb NEBO_HEADLESS_RUNTIME_SIZE
window_record: resb NEBO_WINDOW_SIZE
window_options: resb NEBO_WINDOW_OPTIONS_SIZE
window_title_storage: resb 256
window_events: resb NEBO_WINDOW_EVENT_SIZE*16
scheduler_budget: resb NEBO_SCHEDULER_BUDGET_SIZE
task_group: resb NEBO_TASK_GROUP_SIZE
task_storage: resb nebo_concurrency_contract_TASK_SIZE
cancel_budget: resb NEBO_CANCELLATION_BUDGET_SIZE
cancel_token: resb NEBO_CANCELLATION_TOKEN_SIZE
window_stream: resb NEBO_HEADLESS_STREAM_SIZE
window_event: resb NEBO_WINDOW_EVENT_SIZE
window_handle: resq 1

; F06/F08 chart Canvas.
chart: resb NEBO_CHART_SIZE
chart_series: resb NEBO_CHART_SERIES_SIZE*8
chart_series_spec: resb NEBO_CHART_SERIES_SIZE
chart_axis_options: resb NEBO_CHART_AXIS_SIZE
chart_legend_options: resb NEBO_CHART_LEGEND_SIZE
chart_render_result: resb NEBO_CHART_RESULT_SIZE
chart_canvas: resb NEBO_CANVAS_SIZE
chart_pixels: resb APP_WIDTH*APP_HEIGHT*4
chart_commands: resb NEBO_CANVAS_COMMAND_SIZE*128
chart_present_result: resb NEBO_CANVAS_PRESENT_RESULT_SIZE

; F07 semantic accessibility and widget Canvas.
ui_tree: resb NEBO_UI_TREE_SIZE
ui_nodes: resb NEBO_UI_NODE_SIZE*8
ui_events: resb NEBO_UI_EVENT_SIZE*16
ui_input_storage: resb 64
ui_row_index: resq 1
ui_label_index: resq 1
ui_button_index: resq 1
ui_input_index: resq 1
ui_access: resb NEBO_UI_ACCESS_SIZE
ui_window_event: resb NEBO_WINDOW_EVENT_SIZE
ui_canvas: resb NEBO_CANVAS_SIZE
ui_pixels: resb APP_WIDTH*APP_HEIGHT*4
ui_commands: resb NEBO_CANVAS_COMMAND_SIZE*64

app_summary: resb APP_SUMMARY_BYTES

section .text
global _start

zero_chart_spec:
    lea rdi,[rel chart_series_spec]
    mov ecx,NEBO_CHART_SERIES_QWORDS
    xor eax,eax
    rep stosq
    ret

zero_chart_axis:
    lea rdi,[rel chart_axis_options]
    mov ecx,NEBO_CHART_AXIS_SIZE/8
    xor eax,eax
    rep stosq
    ret

_start:
    ; tree_graph_node_e_edge scalar math.
    mov rdi,-9
    call nebo_math_abs_i64
    CHECK_EAX_ZERO
    cmp rdx,9
    jne .fail
    mov [rel app_summary+16],rdx

    movsd xmm0,[rel f09_value_9]
    call nebo_math_sqrt_f64
    CHECK_EAX_ZERO
    ucomisd xmm0,[rel f09_value_3]
    jne .fail
    movq rax,xmm0
    mov [rel app_summary+24],rax

    ; funcoes_lambdas_callbacks_e_referencias caller-owned F64 Matrix reused directly by the scatter series.
    lea rdi,[rel matrix_desc]
    lea rsi,[rel matrix_values]
    mov edx,4
    mov ecx,2
    mov r8d,NEBO_MATRIX_DTYPE_F64
    mov r9d,APP_OWNER
    call nebo_matrix_init_owned
    CHECK_EAX_ZERO
    lea rdi,[rel matrix_desc]
    call nebo_matrix_validate
    CHECK_EAX_ZERO

    ; call_e_comportamentos_de_chamada bounded Tensor from values.
    sub rsp,16
    mov qword [rsp],8
    lea rdi,[rel tensor_desc]
    lea rsi,[rel tensor_storage]
    mov edx,2
    lea rcx,[rel tensor_shape]
    lea r8,[rel tensor_values]
    call nebo_tensor_from_values_f64
    add rsp,16
    CHECK_EAX_ZERO
    lea rdi,[rel tensor_desc]
    call nebo_tensor_rank
    cmp rax,2
    jne .fail
    mov [rel app_summary+48],rax
    lea rdi,[rel tensor_desc]
    mov esi,1
    call nebo_tensor_size
    test edx,edx
    jnz .fail
    cmp rax,3
    jne .fail
    mov [rel app_summary+56],rax

    ; operadores_de_fluxo_e_branching_pipelines reference kernel plus deterministic scalar plan.
    lea rdi,[rel kernel_result]
    lea rsi,[rel kernel_a]
    lea rdx,[rel kernel_b]
    mov ecx,4
    call nebo_scalar_add_f64
    CHECK_EAX_ZERO
    mov rax,__float64__(6.0)
    cmp [rel kernel_result],rax
    jne .fail
    cmp [rel kernel_result+24],rax
    jne .fail
    mov [rel app_summary+64],rax

    lea rdi,[rel plan_request]
    mov ecx,nebo_kernel_planner_REQUEST_SIZE/8
    xor eax,eax
    rep stosq
    mov qword [rel plan_request+NEBO_REQUEST_OP],NEBO_KERNEL_OP_ADD
    mov qword [rel plan_request+NEBO_REQUEST_DTYPE],NEBO_KERNEL_DTYPE_F64
    mov qword [rel plan_request+NEBO_REQUEST_ELEMENTS],4
    mov qword [rel plan_request+NEBO_REQUEST_ALIGNMENT],8
    mov qword [rel plan_request+NEBO_REQUEST_WORKSPACE],65536
    lea rdi,[rel plan_request]
    lea rsi,[rel plan_result]
    call nebo_kernel_plan
    CHECK_EAX_ZERO
    cmp qword [rel plan_result+NEBO_PLAN_TIER],NEBO_KERNEL_SCALAR
    jne .fail

    ; F02 bounded Console document remains separate from Window.
    lea rdi,[rel console_doc]
    lea rsi,[rel console_text_storage]
    mov edx,256
    lea rcx,[rel console_title_storage]
    mov r8d,64
    call nebo_console_init
    CHECK_EAX_ZERO
    lea rdi,[rel console_doc]
    lea rsi,[rel console_title]
    mov edx,8
    call nebo_console_set_title
    CHECK_EAX_ZERO
    lea rdi,[rel console_doc]
    lea rsi,[rel console_line]
    mov edx,28
    call nebo_console_append_line
    CHECK_EAX_ZERO
    cmp qword [rel console_doc+NEBO_CONSOLE_LENGTH],29
    jne .fail
    cmp qword [rel console_doc+NEBO_CONSOLE_LINES],2
    jne .fail

    ; stream_event_e_processamento_continuo-owned deterministic F04 headless Window.
    lea rdi,[rel scheduler_budget]
    mov esi,1
    mov edx,1
    mov ecx,1
    mov r8d,4
    mov r9d,16
    call nebo_scheduler_budget_init
    CHECK_EAX_ZERO
    lea rdi,[rel task_group]
    lea rsi,[rel scheduler_budget]
    lea rdx,[rel task_storage]
    mov ecx,1
    call nebo_task_group_init
    CHECK_EAX_ZERO
    lea rdi,[rel cancel_budget]
    mov esi,4
    mov edx,4
    mov ecx,1000000000
    call nebo_cancellation_budget_init
    CHECK_EAX_ZERO
    lea rdi,[rel cancel_token]
    lea rsi,[rel cancel_budget]
    xor edx,edx
    xor ecx,ecx
    xor r8d,r8d
    xor r9d,r9d
    call nebo_cancellation_token_init
    CHECK_EAX_ZERO
    lea rdi,[rel window_runtime]
    lea rsi,[rel window_record]
    mov edx,1
    call nebo_headless_runtime_init
    CHECK_EAX_ZERO

    lea rdi,[rel window_options]
    mov ecx,NEBO_WINDOW_OPTIONS_QWORDS
    xor eax,eax
    rep stosq
    mov qword [rel window_options+NEBO_WINDOW_OPTIONS_WIDTH_OFFSET],APP_WIDTH
    mov qword [rel window_options+NEBO_WINDOW_OPTIONS_HEIGHT_OFFSET],APP_HEIGHT
    lea rax,[rel window_title]
    mov [rel window_options+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET],rax
    mov qword [rel window_options+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET],8
    lea rax,[rel window_title_storage]
    mov [rel window_options+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET],rax
    mov qword [rel window_options+NEBO_WINDOW_OPTIONS_TITLE_CAPACITY_OFFSET],256
    lea rax,[rel window_events]
    mov [rel window_options+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET],rax
    mov qword [rel window_options+NEBO_WINDOW_OPTIONS_EVENT_CAPACITY_OFFSET],16
    lea rax,[rel cancel_token]
    mov [rel window_options+NEBO_WINDOW_OPTIONS_CANCELLATION_PTR_OFFSET],rax
    lea rax,[rel task_group]
    mov [rel window_options+NEBO_WINDOW_OPTIONS_TASK_GROUP_PTR_OFFSET],rax
    mov dword [rel window_options+NEBO_WINDOW_OPTIONS_BACKEND_PREFERENCE_OFFSET],NEBO_WINDOW_BACKEND_HEADLESS
    mov dword [rel window_options+NEBO_WINDOW_OPTIONS_FLAGS_OFFSET],NEBO_WINDOW_OPTION_RESIZABLE | NEBO_WINDOW_OPTION_DECORATED
    mov qword [rel window_options+NEBO_WINDOW_OPTIONS_OWNER_CONTEXT_OFFSET],APP_OWNER
    lea rdi,[rel window_runtime]
    lea rsi,[rel window_options]
    lea rdx,[rel window_handle]
    call nebo_headless_window_create
    CHECK_EAX_ZERO
    lea rdi,[rel window_runtime]
    mov rsi,[rel window_handle]
    mov rdx,APP_OWNER
    lea rcx,[rel window_stream]
    call nebo_headless_window_events
    CHECK_EAX_ZERO
    lea rdi,[rel window_runtime]
    mov rsi,[rel window_handle]
    mov rdx,APP_OWNER
    call nebo_headless_window_show
    CHECK_EAX_ZERO

    ; F07 bounded semantic layout/widgets and accessibility snapshot.
    lea rdi,[rel ui_tree]
    lea rsi,[rel ui_nodes]
    mov edx,8
    lea rcx,[rel ui_events]
    mov r8d,16
    mov r9d,APP_WIDTH
    sub rsp,16
    mov qword [rsp],APP_HEIGHT
    mov qword [rsp+8],APP_OWNER
    call nebo_ui_tree_init
    add rsp,16
    CHECK_EAX_ZERO
    lea rdi,[rel ui_tree]
    xor esi,esi
    mov edx,2
    lea rcx,[rel ui_row_index]
    call nebo_ui_row
    CHECK_EAX_ZERO
    lea rdi,[rel ui_tree]
    mov rsi,[rel ui_row_index]
    lea rdx,[rel ui_name_status]
    mov ecx,6
    lea r8,[rel ui_text_status]
    mov r9d,5
    sub rsp,16
    lea rax,[rel ui_label_index]
    mov [rsp],rax
    call nebo_ui_label
    add rsp,16
    CHECK_EAX_ZERO
    lea rdi,[rel ui_tree]
    mov rsi,[rel ui_row_index]
    lea rdx,[rel ui_name_action]
    mov ecx,6
    lea r8,[rel ui_text_action]
    mov r9d,5
    sub rsp,16
    lea rax,[rel ui_button_index]
    mov [rsp],rax
    call nebo_ui_button
    add rsp,16
    CHECK_EAX_ZERO
    lea rdi,[rel ui_tree]
    mov rsi,[rel ui_row_index]
    lea rdx,[rel ui_name_input]
    mov ecx,6
    lea r8,[rel ui_input_storage]
    mov r9d,64
    sub rsp,16
    mov qword [rsp],0
    lea rax,[rel ui_input_index]
    mov [rsp+8],rax
    call nebo_ui_text_input
    add rsp,16
    CHECK_EAX_ZERO
    lea rdi,[rel ui_tree]
    call nebo_ui_layout
    CHECK_EAX_ZERO
    lea rdi,[rel ui_canvas]
    lea rsi,[rel ui_pixels]
    mov edx,APP_WIDTH*APP_HEIGHT*4
    mov ecx,APP_WIDTH
    mov r8d,APP_HEIGHT
    lea r9,[rel ui_commands]
    sub rsp,16
    mov qword [rsp],64
    call nebo_canvas_create
    add rsp,16
    CHECK_EAX_ZERO
    mov qword [rel ui_canvas+NEBO_CANVAS_OWNER_CONTEXT_OFFSET],APP_OWNER
    lea rdi,[rel ui_tree]
    lea rsi,[rel ui_canvas]
    call nebo_ui_render
    CHECK_EAX_ZERO
    lea rdi,[rel ui_tree]
    call nebo_ui_focus_next
    CHECK_EAX_ZERO
    lea rdi,[rel ui_tree]
    mov rsi,[rel ui_button_index]
    lea rdx,[rel ui_access]
    call nebo_ui_accessibility_snapshot
    CHECK_EAX_ZERO
    cmp dword [rel ui_access+NEBO_UI_ACCESS_ROLE_OFFSET],NEBO_UI_ROLE_BUTTON
    jne .fail

    ; Typed input routing reaches the bounded TextInput as one canonical scalar.
    lea rdi,[rel ui_tree]
    call nebo_ui_focus_next
    CHECK_EAX_ZERO
    lea rdi,[rel ui_window_event]
    mov ecx,NEBO_WINDOW_EVENT_QWORDS
    xor eax,eax
    rep stosq
    mov dword [rel ui_window_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_TEXT_INPUT
    mov qword [rel ui_window_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],'N'
    mov qword [rel ui_window_event+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],1
    mov qword [rel ui_window_event+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],'N'
    lea rdi,[rel ui_tree]
    lea rsi,[rel ui_window_event]
    call nebo_ui_dispatch_window_event
    CHECK_EAX_ZERO
    cmp byte [rel ui_input_storage],'N'
    jne .fail
    mov rax,[rel ui_input_index]
    imul rax,NEBO_UI_NODE_SIZE
    lea rdx,[rel ui_nodes]
    cmp qword [rdx+rax+NEBO_UI_NODE_TEXT_LENGTH_OFFSET],1
    jne .fail

    ; F08 line/scatter(Matrix)/bar/histogram over F06 Canvas.
    lea rdi,[rel chart]
    lea rsi,[rel chart_series]
    mov edx,8
    mov ecx,APP_OWNER
    call nebo_chart_init
    CHECK_EAX_ZERO
    lea rdi,[rel chart_canvas]
    lea rsi,[rel chart_pixels]
    mov edx,APP_WIDTH*APP_HEIGHT*4
    mov ecx,APP_WIDTH
    mov r8d,APP_HEIGHT
    lea r9,[rel chart_commands]
    sub rsp,16
    mov qword [rsp],128
    call nebo_canvas_create
    add rsp,16
    CHECK_EAX_ZERO
    mov qword [rel chart_canvas+NEBO_CANVAS_OWNER_CONTEXT_OFFSET],APP_OWNER

    call zero_chart_spec
    mov dword [rel chart_series_spec+NEBO_CHART_SERIES_SOURCE_OFFSET],NEBO_CHART_SOURCE_ARRAY
    mov dword [rel chart_series_spec+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_SHOW_POINTS
    mov dword [rel chart_series_spec+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET],0xff5060ff
    mov qword [rel chart_series_spec+NEBO_CHART_SERIES_POINT_RADIUS_OFFSET],2
    lea rax,[rel line_x]
    mov [rel chart_series_spec+NEBO_CHART_SERIES_X_PTR_OFFSET],rax
    lea rax,[rel line_y]
    mov [rel chart_series_spec+NEBO_CHART_SERIES_Y_PTR_OFFSET],rax
    mov qword [rel chart_series_spec+NEBO_CHART_SERIES_POINT_COUNT_OFFSET],5
    mov qword [rel chart_series_spec+NEBO_CHART_SERIES_X_STRIDE_OFFSET],1
    mov qword [rel chart_series_spec+NEBO_CHART_SERIES_Y_STRIDE_OFFSET],1
    lea rax,[rel label_line]
    mov [rel chart_series_spec+NEBO_CHART_SERIES_LABEL_PTR_OFFSET],rax
    mov qword [rel chart_series_spec+NEBO_CHART_SERIES_LABEL_LENGTH_OFFSET],4
    lea rdi,[rel chart]
    lea rsi,[rel chart_series_spec]
    call nebo_chart_line
    CHECK_EAX_ZERO

    call zero_chart_spec
    mov dword [rel chart_series_spec+NEBO_CHART_SERIES_SOURCE_OFFSET],NEBO_CHART_SOURCE_MATRIX
    mov dword [rel chart_series_spec+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET],0x50ff80ff
    mov qword [rel chart_series_spec+NEBO_CHART_SERIES_POINT_RADIUS_OFFSET],2
    lea rax,[rel label_scatter]
    mov [rel chart_series_spec+NEBO_CHART_SERIES_LABEL_PTR_OFFSET],rax
    mov qword [rel chart_series_spec+NEBO_CHART_SERIES_LABEL_LENGTH_OFFSET],7
    lea rax,[rel matrix_desc]
    mov [rel chart_series_spec+NEBO_CHART_SERIES_MATRIX_PTR_OFFSET],rax
    mov qword [rel chart_series_spec+NEBO_CHART_SERIES_X_COLUMN_OFFSET],0
    mov qword [rel chart_series_spec+NEBO_CHART_SERIES_Y_COLUMN_OFFSET],1
    lea rdi,[rel chart]
    lea rsi,[rel chart_series_spec]
    call nebo_chart_scatter
    CHECK_EAX_ZERO

    call zero_chart_spec
    mov dword [rel chart_series_spec+NEBO_CHART_SERIES_SOURCE_OFFSET],NEBO_CHART_SOURCE_ARRAY
    mov dword [rel chart_series_spec+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_AUTO_X
    mov dword [rel chart_series_spec+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET],0x5080ffff
    lea rax,[rel bar_y]
    mov [rel chart_series_spec+NEBO_CHART_SERIES_Y_PTR_OFFSET],rax
    mov qword [rel chart_series_spec+NEBO_CHART_SERIES_POINT_COUNT_OFFSET],4
    mov qword [rel chart_series_spec+NEBO_CHART_SERIES_Y_STRIDE_OFFSET],1
    lea rax,[rel label_bar]
    mov [rel chart_series_spec+NEBO_CHART_SERIES_LABEL_PTR_OFFSET],rax
    mov qword [rel chart_series_spec+NEBO_CHART_SERIES_LABEL_LENGTH_OFFSET],3
    lea rax,[rel categories]
    mov [rel chart_series_spec+NEBO_CHART_SERIES_CATEGORIES_PTR_OFFSET],rax
    mov qword [rel chart_series_spec+NEBO_CHART_SERIES_CATEGORY_COUNT_OFFSET],4
    lea rdi,[rel chart]
    lea rsi,[rel chart_series_spec]
    call nebo_chart_bar
    CHECK_EAX_ZERO

    call zero_chart_spec
    mov dword [rel chart_series_spec+NEBO_CHART_SERIES_SOURCE_OFFSET],NEBO_CHART_SOURCE_ARRAY
    mov dword [rel chart_series_spec+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_AUTO_X
    mov dword [rel chart_series_spec+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET],0xffc050ff
    lea rax,[rel hist_y]
    mov [rel chart_series_spec+NEBO_CHART_SERIES_Y_PTR_OFFSET],rax
    mov qword [rel chart_series_spec+NEBO_CHART_SERIES_POINT_COUNT_OFFSET],6
    mov qword [rel chart_series_spec+NEBO_CHART_SERIES_Y_STRIDE_OFFSET],1
    lea rax,[rel label_hist]
    mov [rel chart_series_spec+NEBO_CHART_SERIES_LABEL_PTR_OFFSET],rax
    mov qword [rel chart_series_spec+NEBO_CHART_SERIES_LABEL_LENGTH_OFFSET],4
    mov qword [rel chart_series_spec+NEBO_CHART_SERIES_BINS_OFFSET],4
    lea rdi,[rel chart]
    lea rsi,[rel chart_series_spec]
    call nebo_chart_histogram
    CHECK_EAX_ZERO

    lea rdi,[rel chart]
    lea rsi,[rel chart_title]
    mov edx,19
    call nebo_chart_title
    CHECK_EAX_ZERO
    call zero_chart_axis
    mov dword [rel chart_axis_options+NEBO_CHART_AXIS_ID_OFFSET],NEBO_CHART_AXIS_X
    mov dword [rel chart_axis_options+NEBO_CHART_AXIS_FLAGS_OFFSET],NEBO_CHART_AXIS_FLAG_GRID
    mov qword [rel chart_axis_options+NEBO_CHART_AXIS_TICKS_OFFSET],5
    lea rax,[rel x_label]
    mov [rel chart_axis_options+NEBO_CHART_AXIS_LABEL_PTR_OFFSET],rax
    mov qword [rel chart_axis_options+NEBO_CHART_AXIS_LABEL_LENGTH_OFFSET],1
    lea rdi,[rel chart]
    lea rsi,[rel chart_axis_options]
    call nebo_chart_axis
    CHECK_EAX_ZERO
    call zero_chart_axis
    mov dword [rel chart_axis_options+NEBO_CHART_AXIS_ID_OFFSET],NEBO_CHART_AXIS_Y
    mov dword [rel chart_axis_options+NEBO_CHART_AXIS_FLAGS_OFFSET],NEBO_CHART_AXIS_FLAG_GRID
    mov qword [rel chart_axis_options+NEBO_CHART_AXIS_TICKS_OFFSET],5
    lea rax,[rel y_label]
    mov [rel chart_axis_options+NEBO_CHART_AXIS_LABEL_PTR_OFFSET],rax
    mov qword [rel chart_axis_options+NEBO_CHART_AXIS_LABEL_LENGTH_OFFSET],1
    lea rdi,[rel chart]
    lea rsi,[rel chart_axis_options]
    call nebo_chart_axis
    CHECK_EAX_ZERO
    lea rdi,[rel chart_legend_options]
    mov ecx,NEBO_CHART_LEGEND_SIZE/8
    xor eax,eax
    rep stosq
    mov dword [rel chart_legend_options+NEBO_CHART_LEGEND_OPTIONS_FLAGS_OFFSET],NEBO_CHART_LEGEND_FLAG_ENABLED
    mov qword [rel chart_legend_options+NEBO_CHART_LEGEND_MAX_OFFSET],4
    mov qword [rel chart_legend_options+NEBO_CHART_LEGEND_POSITION_OFFSET],NEBO_CHART_LEGEND_TOP_RIGHT
    lea rdi,[rel chart]
    lea rsi,[rel chart_legend_options]
    call nebo_chart_legend
    CHECK_EAX_ZERO
    lea rdi,[rel chart]
    lea rsi,[rel chart_canvas]
    lea rdx,[rel chart_render_result]
    call nebo_chart_render
    CHECK_EAX_ZERO
    cmp qword [rel chart_render_result+NEBO_CHART_RESULT_SERIES_OFFSET],4
    jne .fail
    cmp qword [rel chart_render_result+NEBO_CHART_RESULT_POINTS_OFFSET],19
    jne .fail
    cmp qword [rel chart_render_result+NEBO_CHART_RESULT_COMMANDS_OFFSET],61
    jne .fail

    ; F04 headless present proves a deterministic Window/Canvas frame.
    lea rdi,[rel chart_canvas]
    lea rsi,[rel window_runtime]
    mov rdx,[rel window_handle]
    mov rcx,APP_OWNER
    lea r8,[rel chart_present_result]
    call nebo_canvas_present_headless
    CHECK_EAX_ZERO
    cmp qword [rel chart_present_result+NEBO_CANVAS_PRESENT_FRAME_SEQUENCE_OFFSET],1
    jne .fail
    cmp qword [rel chart_present_result+NEBO_CANVAS_PRESENT_COMMAND_COUNT_OFFSET],61
    jne .fail

    ; Capture deterministic cross-program facts before terminal cleanup.
    mov rax,APP_SUMMARY_MAGIC
    mov [rel app_summary],rax
    mov qword [rel app_summary+8],1
    mov rax,[rel matrix_desc+NEBO_MATRIX_ROWS]
    mov [rel app_summary+32],rax
    mov rax,[rel matrix_desc+NEBO_MATRIX_COLS]
    mov [rel app_summary+40],rax
    mov rax,[rel plan_result+NEBO_PLAN_TIER]
    mov [rel app_summary+72],rax
    mov rax,[rel console_doc+NEBO_CONSOLE_LENGTH]
    mov [rel app_summary+80],rax
    mov rax,[rel console_doc+NEBO_CONSOLE_LINES]
    mov [rel app_summary+88],rax
    mov rax,[rel ui_tree+NEBO_UI_TREE_NODE_COUNT_OFFSET]
    mov [rel app_summary+96],rax
    mov eax,[rel ui_access+NEBO_UI_ACCESS_ROLE_OFFSET]
    mov [rel app_summary+104],rax
    mov rax,[rel chart_render_result+NEBO_CHART_RESULT_SERIES_OFFSET]
    mov [rel app_summary+112],rax
    mov rax,[rel chart_render_result+NEBO_CHART_RESULT_POINTS_OFFSET]
    mov [rel app_summary+120],rax
    mov rax,[rel chart_render_result+NEBO_CHART_RESULT_COMMANDS_OFFSET]
    mov [rel app_summary+128],rax
    mov rax,[rel chart_present_result+NEBO_CANVAS_PRESENT_FRAME_SEQUENCE_OFFSET]
    mov [rel app_summary+136],rax
    mov rax,[rel chart_present_result+NEBO_CANVAS_PRESENT_COMMAND_COUNT_OFFSET]
    mov [rel app_summary+144],rax

    ; Terminal cleanup is exact and ordered.
    lea rdi,[rel chart]
    call nebo_chart_close
    CHECK_EAX_ZERO
    lea rdi,[rel chart_canvas]
    call nebo_canvas_close
    CHECK_EAX_ZERO
    lea rdi,[rel ui_tree]
    call nebo_ui_close
    CHECK_EAX_ZERO
    lea rdi,[rel ui_canvas]
    call nebo_canvas_close
    CHECK_EAX_ZERO
    lea rdi,[rel window_runtime]
    mov rsi,[rel window_handle]
    mov rdx,APP_OWNER
    call nebo_headless_window_close
    CHECK_EAX_ZERO
    mov r12d,3
.drain_window:
    lea rdi,[rel window_stream]
    lea rsi,[rel window_event]
    call nebo_headless_event_stream_poll
    CHECK_EAX_ZERO
    cmp edx,1
    jne .fail
    dec r12d
    jnz .drain_window
    cmp dword [rel window_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_CLOSED
    jne .fail
    lea rdi,[rel window_stream]
    call nebo_headless_event_stream_release
    CHECK_EAX_ZERO
    lea rdi,[rel window_runtime]
    mov rsi,[rel window_handle]
    mov rdx,APP_OWNER
    call nebo_headless_window_reclaim
    CHECK_EAX_ZERO
    lea rdi,[rel console_doc]
    call nebo_console_close
    CHECK_EAX_ZERO
    mov qword [rel app_summary+152],63

    ; The closeout summary is the headless golden authority.
    mov eax,1
    mov edi,1
    lea rsi,[rel app_summary]
    mov edx,APP_SUMMARY_BYTES
    syscall
    cmp rax,APP_SUMMARY_BYTES
    jne .fail
    mov eax,60
    xor edi,edi
    syscall

.fail:
    mov eax,60
    mov edi,1
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
