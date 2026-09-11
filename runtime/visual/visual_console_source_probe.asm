; G018 public-source runtime oracle. Source modes reach the existing bounded
; Console, Window, Canvas, widget and chart owners and return the source seed
; only after an independently observable state/effect succeeds.
bits 64
default rel
%include "runtime/console/document/linear_console_document.inc"
%include "runtime/core/runtime_core.inc"
%include "runtime/console/behavior/console_behavior.inc"
%include "runtime/textual/scan_plan.inc"
%include "runtime/stdlib/visual_summary_runtime.inc"
%include "runtime/window/headless/headless_window.inc"
%include "runtime/canvas/canvas.inc"
%include "runtime/canvas/canvas_image.inc"
%include "runtime/widgets/widgets.inc"
%include "runtime/charts/charts.inc"

%define G18_OWNER 0x180018
%define G18_WIDTH 160
%define G18_HEIGHT 120

section .rodata align=8
g18_console_text: db 'console-018'
g18_scan_text: db '181'
g18_title: db 'G018 window'
g18_title_next: db 'G018 active'
g18_widget_name: db 'Control'
g18_widget_label: db 'Ready'
g18_widget_button: db 'Continue'
g18_widget_input: db 'value'
g18_chart_title: db 'G018 chart'
g18_axis_x: db 'X'
g18_series_label: db 'SERIES'
g18_category_a: db 'A'
g18_category_b: db 'B'
g18_category_c: db 'C'
align 8
g18_categories:
 dq g18_category_a,1
 dq g18_category_b,1
 dq g18_category_c,1
g18_line_x: dq 0.0,1.0,2.0,3.0
g18_line_y: dq 1.0,3.0,2.0,4.0
g18_scatter_x: dq 0.5,1.5,2.5
g18_scatter_y: dq 2.0,1.0,3.0
g18_bar_y: dq 2.0,4.0,1.0
g18_hist_y: dq -1.0,-0.5,0.0,0.5,1.0

section .data align=8
g18_stroke: dd 0xffcc00ff,NEBO_CANVAS_PAINT_MODE_STROKE,1,0
g18_fill: dd 0x2060ffff,NEBO_CANVAS_PAINT_MODE_FILL,1,0
g18_image_pixel: db 0x80,0x40,0x20,0xff

section .bss align=16
g18_doc: resb NEBO_CONSOLE_SIZE
g18_doc_text: resb 256
g18_doc_title: resb 64
g18_scan_value: resq 1
g18_color: resq 1
g18_summary_native: resb neboc_console_visual_dashboard_e_plots_NATIVE_SIZE
g18_summary_runtime: resb neboc_console_visual_dashboard_e_plots_RUNTIME_SIZE
g18_runtime: resb NEBO_HEADLESS_RUNTIME_SIZE
g18_record: resb NEBO_WINDOW_SIZE
g18_options: resb NEBO_WINDOW_OPTIONS_SIZE
g18_title_storage: resb 256
g18_window_events: resb NEBO_WINDOW_EVENT_SIZE*32
g18_scheduler: resb NEBO_SCHEDULER_BUDGET_SIZE
g18_task_group: resb NEBO_TASK_GROUP_SIZE
g18_task_storage: resb nebo_concurrency_contract_TASK_SIZE
g18_cancel_budget: resb NEBO_CANCELLATION_BUDGET_SIZE
g18_cancel: resb NEBO_CANCELLATION_TOKEN_SIZE
g18_stream: resb NEBO_HEADLESS_STREAM_SIZE
g18_event: resb NEBO_WINDOW_EVENT_SIZE
g18_template_event: resb NEBO_WINDOW_EVENT_SIZE
g18_handle: resq 1
g18_canvas: resb NEBO_CANVAS_SIZE
g18_pixels: resb G18_WIDTH*G18_HEIGHT*4
g18_commands: resb NEBO_CANVAS_COMMAND_SIZE*192
g18_present: resb NEBO_CANVAS_PRESENT_RESULT_SIZE
g18_image: resb 64
g18_tree: resb NEBO_UI_TREE_SIZE
g18_nodes: resb NEBO_UI_NODE_SIZE*12
g18_ui_events: resb NEBO_UI_EVENT_SIZE*24
g18_input_storage: resb 64
g18_row_index: resq 1
g18_column_index: resq 1
g18_grid_index: resq 1
g18_label_index: resq 1
g18_button_index: resq 1
g18_input_index: resq 1
g18_ui_event: resb NEBO_UI_EVENT_SIZE
g18_access: resb NEBO_UI_ACCESS_SIZE
g18_chart: resb NEBO_CHART_SIZE
g18_series: resb NEBO_CHART_SERIES_SIZE*8
g18_series_spec: resb NEBO_CHART_SERIES_SIZE
g18_axis: resb NEBO_CHART_AXIS_SIZE
g18_legend: resb NEBO_CHART_LEGEND_SIZE
g18_render: resb NEBO_CHART_RESULT_SIZE
g18_step: resq 1

section .text
global nebo_g018_source_probe
global nebo_g018_negative_probe
extern nebo_console_palette_color
extern neboc_visual_summary_runtime_execute

g18_hash_bytes:
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor edx,edx
.loop:
 cmp edx,ecx
 jae .done
 movzx r9d,byte [rsi+rdx]
 xor rax,r9
 imul rax,r8
 inc edx
 jmp .loop
.done:
 ret

g18_zero_window_event:
 lea rdi,[rel g18_template_event]
 mov ecx,NEBO_WINDOW_EVENT_QWORDS
 xor eax,eax
 rep stosq
 ret

g18_open_window:
 mov qword [rel g18_step],11
 lea rdi,[rel g18_scheduler]
 mov esi,1
 mov edx,1
 mov ecx,1
 mov r8d,4
 mov r9d,16
 call nebo_scheduler_budget_init
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],12
 lea rdi,[rel g18_task_group]
 lea rsi,[rel g18_scheduler]
 lea rdx,[rel g18_task_storage]
 mov ecx,1
 call nebo_task_group_init
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],13
 lea rdi,[rel g18_cancel_budget]
 mov esi,4
 mov edx,4
 mov ecx,1000000000
 call nebo_cancellation_budget_init
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],14
 lea rdi,[rel g18_cancel]
 lea rsi,[rel g18_cancel_budget]
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 call nebo_cancellation_token_init
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],15
 lea rdi,[rel g18_runtime]
 lea rsi,[rel g18_record]
 mov edx,1
 call nebo_headless_runtime_init
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],16
 lea rdi,[rel g18_options]
 mov ecx,NEBO_WINDOW_OPTIONS_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel g18_options+NEBO_WINDOW_OPTIONS_WIDTH_OFFSET],G18_WIDTH
 mov qword [rel g18_options+NEBO_WINDOW_OPTIONS_HEIGHT_OFFSET],G18_HEIGHT
 lea rax,[rel g18_title]
 mov [rel g18_options+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET],rax
 mov qword [rel g18_options+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET],11
 lea rax,[rel g18_title_storage]
 mov [rel g18_options+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET],rax
 mov qword [rel g18_options+NEBO_WINDOW_OPTIONS_TITLE_CAPACITY_OFFSET],256
 lea rax,[rel g18_window_events]
 mov [rel g18_options+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET],rax
 mov qword [rel g18_options+NEBO_WINDOW_OPTIONS_EVENT_CAPACITY_OFFSET],32
 lea rax,[rel g18_cancel]
 mov [rel g18_options+NEBO_WINDOW_OPTIONS_CANCELLATION_PTR_OFFSET],rax
 lea rax,[rel g18_task_group]
 mov [rel g18_options+NEBO_WINDOW_OPTIONS_TASK_GROUP_PTR_OFFSET],rax
 mov dword [rel g18_options+NEBO_WINDOW_OPTIONS_BACKEND_PREFERENCE_OFFSET],NEBO_WINDOW_BACKEND_HEADLESS
 mov dword [rel g18_options+NEBO_WINDOW_OPTIONS_FLAGS_OFFSET],NEBO_WINDOW_OPTION_RESIZABLE | NEBO_WINDOW_OPTION_DECORATED | NEBO_WINDOW_OPTION_TEXT_INPUT | NEBO_WINDOW_OPTION_CLOSE_PREVENTABLE
 mov qword [rel g18_options+NEBO_WINDOW_OPTIONS_OWNER_CONTEXT_OFFSET],G18_OWNER
 lea rdi,[rel g18_runtime]
 lea rsi,[rel g18_options]
 lea rdx,[rel g18_handle]
 call nebo_headless_window_create
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],17
 lea rdi,[rel g18_runtime]
 mov rsi,[rel g18_handle]
 mov rdx,G18_OWNER
 lea rcx,[rel g18_stream]
 call nebo_headless_window_events
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],18
 lea rdi,[rel g18_stream]
 lea rsi,[rel g18_event]
 call nebo_headless_event_stream_poll
 test eax,eax
 jnz .fail
 cmp edx,1
 jne .fail
 mov qword [rel g18_step],19
 lea rdi,[rel g18_event]
 call nebo_headless_window_event_kind
 test eax,eax
 jnz .fail
 cmp edx,NEBO_WINDOW_EVENT_CREATED
 jne .fail
 xor eax,eax
 ret
.fail:
 mov eax,1
 ret

g18_drain_events:
.loop:
 lea rdi,[rel g18_stream]
 lea rsi,[rel g18_event]
 call nebo_headless_event_stream_poll
 test eax,eax
 jnz .fail
 cmp edx,1
 jne .done
 jmp .loop
.done:
 xor eax,eax
 ret
.fail:
 mov eax,1
 ret

g18_finish_window:
 lea rdi,[rel g18_runtime]
 mov rsi,[rel g18_handle]
 mov rdx,G18_OWNER
 call nebo_headless_window_close
 test eax,eax
 jz .drain
 cmp eax,NEBO_WINDOW_ERROR_ALREADY_CLOSED
 jne .fail
.drain:
 call g18_drain_events
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_stream]
 call nebo_headless_event_stream_release
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_runtime]
 mov rsi,[rel g18_handle]
 mov rdx,G18_OWNER
 call nebo_headless_window_reclaim
 test eax,eax
 jnz .fail
 cmp qword [rel g18_runtime+NEBO_HEADLESS_RUNTIME_ACTIVE_COUNT_OFFSET],0
 jne .fail
 xor eax,eax
 ret
.fail:
 mov eax,1
 ret

g18_canvas_create:
 lea rdi,[rel g18_canvas]
 lea rsi,[rel g18_pixels]
 mov edx,G18_WIDTH*G18_HEIGHT*4
 mov ecx,G18_WIDTH
 mov r8d,G18_HEIGHT
 lea r9,[rel g18_commands]
 sub rsp,16
 mov qword [rsp],192
 call nebo_canvas_create
 add rsp,16
 ret

g18_mode_1:
 lea rdi,[rel g18_doc]
 lea rsi,[rel g18_doc_text]
 mov edx,256
 lea rcx,[rel g18_doc_title]
 mov r8d,64
 call nebo_console_init
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_doc]
 lea rsi,[rel g18_console_text]
 mov edx,11
 call nebo_console_append_line
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_scan_text]
 mov esi,3
 lea rdx,[rel g18_scan_value]
 call neboc_scan_parse_int
 test eax,eax
 jnz .fail
 cmp qword [rel g18_scan_value],181
 jne .fail
 mov rdi,[rel g18_scan_value]
 mov esi,1
 mov edx,255
 mov ecx,SCAN_INT_POSITIVE
 call neboc_scan_validate_int
 test eax,eax
 jnz .fail
 mov edi,NEBO_COLOR_ID_RED
 lea rsi,[rel g18_color]
 call nebo_console_palette_color
 test eax,eax
 jnz .fail
 mov eax,NEBO_COLOR_BGRA_RED
 cmp [rel g18_color],rax
 jne .fail
 lea rdi,[rel g18_summary_native]
 xor eax,eax
 mov ecx,neboc_console_visual_dashboard_e_plots_NATIVE_QWORDS
 rep stosq
 lea rdi,[rel g18_summary_runtime]
 mov ecx,neboc_console_visual_dashboard_e_plots_RUNTIME_QWORDS
 rep stosq
 mov rax,neboc_console_visual_dashboard_e_plots_NATIVE_MAGIC
 mov [rel g18_summary_native+neboc_console_visual_dashboard_e_plots_NATIVE_MAGIC_OFFSET],rax
 mov qword [rel g18_summary_native+neboc_console_visual_dashboard_e_plots_NATIVE_OPERATION_OFFSET],NEBOC_OP_SUMMARIZE
 mov qword [rel g18_summary_native+neboc_console_visual_dashboard_e_plots_NATIVE_ARITY_OFFSET],1
 mov qword [rel g18_summary_native+neboc_console_visual_dashboard_e_plots_NATIVE_VALUE_OFFSET],181
 mov qword [rel g18_summary_native+neboc_console_visual_dashboard_e_plots_NATIVE_DIGIT_COUNT_OFFSET],3
 mov qword [rel g18_summary_native+neboc_console_visual_dashboard_e_plots_NATIVE_RESULT_TYPE_OFFSET],1
 mov qword [rel g18_summary_native+neboc_console_visual_dashboard_e_plots_NATIVE_EFFECT_OFFSET],1
 mov qword [rel g18_summary_native+neboc_console_visual_dashboard_e_plots_NATIVE_TARGET_OFFSET],neboc_console_visual_dashboard_e_plots_NATIVE_TARGET_X86_64_SYSV_ELF
 mov qword [rel g18_summary_native+neboc_console_visual_dashboard_e_plots_NATIVE_ABI_OFFSET],neboc_console_visual_dashboard_e_plots_NATIVE_ABI_INTERNAL_V1
 mov qword [rel g18_summary_native+neboc_console_visual_dashboard_e_plots_NATIVE_RESULT_OFFSET],181
 mov qword [rel g18_summary_native+neboc_console_visual_dashboard_e_plots_NATIVE_DECISION_OFFSET],1
 mov qword [rel g18_summary_native+neboc_console_visual_dashboard_e_plots_NATIVE_FLAGS_OFFSET],neboc_console_visual_dashboard_e_plots_NATIVE_REQUIRED_FLAGS
 lea rsi,[rel g18_summary_native]
 mov ecx,neboc_console_visual_dashboard_e_plots_NATIVE_HASHED_BYTES
 call g18_hash_bytes
 mov [rel g18_summary_native+neboc_console_visual_dashboard_e_plots_NATIVE_HASH_OFFSET],rax
 lea rdi,[rel g18_summary_native]
 lea rsi,[rel g18_summary_runtime]
 call neboc_visual_summary_runtime_execute
 test eax,eax
 jnz .fail
 cmp qword [rel g18_summary_runtime+neboc_console_visual_dashboard_e_plots_RUNTIME_RESULT_OFFSET],181
 jne .fail
 lea rdi,[rel g18_doc]
 call nebo_console_size_query
 test eax,eax
 jnz .fail
 cmp rdx,12
 jne .fail
 lea rdi,[rel g18_doc]
 call nebo_console_close
 test eax,eax
 jnz .fail
 xor eax,eax
 ret
.fail:
 mov eax,1
 ret

g18_mode_2:
 lea rdi,[rel g18_doc]
 lea rsi,[rel g18_doc_text]
 mov edx,256
 lea rcx,[rel g18_doc_title]
 mov r8d,64
 call nebo_console_init
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_doc]
 lea rsi,[rel g18_title_next]
 mov edx,11
 call nebo_console_set_title
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_doc]
 mov esi,7
 call nebo_console_set_style
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_doc]
 lea rsi,[rel g18_console_text]
 mov edx,11
 call nebo_console_append
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_doc]
 mov esi,99
 call nebo_console_scroll
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_doc]
 call nebo_console_size_query
 test eax,eax
 jnz .fail
 cmp rdx,11
 jne .fail
 cmp r8,7
 jne .fail
 lea rdi,[rel g18_doc]
 call nebo_console_clear
 test eax,eax
 jnz .fail
 cmp qword [rel g18_doc+NEBO_CONSOLE_LENGTH],0
 jne .fail
 lea rdi,[rel g18_doc]
 call nebo_console_close
 test eax,eax
 jnz .fail
 xor eax,eax
 ret
.fail:
 mov eax,2
 ret

g18_mode_3:
 mov qword [rel g18_step],1
 call g18_open_window
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],2
 lea rdi,[rel g18_runtime]
 mov rsi,[rel g18_handle]
 mov rdx,G18_OWNER
 call nebo_headless_window_show
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],3
 lea rdi,[rel g18_runtime]
 mov rsi,[rel g18_handle]
 mov rdx,G18_OWNER
 mov ecx,641
 mov r8d,361
 call nebo_headless_window_resize
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],4
 lea rdi,[rel g18_runtime]
 mov rsi,[rel g18_handle]
 mov rdx,G18_OWNER
 lea rcx,[rel g18_title_next]
 mov r8d,11
 call nebo_headless_window_set_title
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],5
 lea rdi,[rel g18_runtime]
 mov rsi,[rel g18_handle]
 mov rdx,G18_OWNER
 call nebo_headless_window_request_redraw
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],6
 lea rdi,[rel g18_runtime]
 mov rsi,[rel g18_handle]
 mov rdx,G18_OWNER
 call nebo_headless_window_hide
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],7
 cmp qword [rel g18_record+NEBO_WINDOW_WIDTH_OFFSET],641
 jne .fail
 mov qword [rel g18_step],8
 cmp qword [rel g18_record+NEBO_WINDOW_TITLE_LENGTH_OFFSET],11
 jne .fail
 mov qword [rel g18_step],9
 call g18_finish_window
 test eax,eax
 jnz .fail
 xor eax,eax
 ret
.fail:
 mov edx,eax
 mov eax,[rel g18_step]
 shl eax,4
 or eax,edx
 ret

g18_mode_4:
 call g18_open_window
 test eax,eax
 jnz .fail
 ; Key payload.
 call g18_zero_window_event
 mov dword [rel g18_template_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_KEY_DOWN
 mov qword [rel g18_template_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],65
 mov qword [rel g18_template_event+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],30
 mov qword [rel g18_template_event+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],1
 call g18_push_and_poll
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_event]
 call nebo_headless_window_event_key
 test eax,eax
 jnz .fail
 cmp edx,1
 jne .fail
 cmp r8,65
 jne .fail
 ; Pointer payload.
 call g18_zero_window_event
 mov dword [rel g18_template_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_POINTER_MOVED
 mov qword [rel g18_template_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],640
 mov qword [rel g18_template_event+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],320
 mov qword [rel g18_template_event+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],1
 call g18_push_and_poll
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_event]
 call nebo_headless_window_event_pointer
 test eax,eax
 jnz .fail
 cmp edx,1
 jne .fail
 ; Text input payload.
 call g18_zero_window_event
 mov dword [rel g18_template_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_TEXT_INPUT
 mov qword [rel g18_template_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],233
 mov qword [rel g18_template_event+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],2
 mov qword [rel g18_template_event+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],0xa9c3
 call g18_push_and_poll
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_event]
 call nebo_headless_window_event_text_input
 test eax,eax
 jnz .fail
 cmp edx,1
 jne .fail
 ; Resize event and accessor.
 lea rdi,[rel g18_runtime]
 mov rsi,[rel g18_handle]
 mov rdx,G18_OWNER
 mov ecx,700
 mov r8d,400
 call nebo_headless_window_resize
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_stream]
 lea rsi,[rel g18_event]
 call nebo_headless_event_stream_poll
 test eax,eax
 jnz .fail
 cmp edx,1
 jne .fail
 lea rdi,[rel g18_event]
 call nebo_headless_window_event_resize
 test eax,eax
 jnz .fail
 cmp edx,1
 jne .fail
 cmp r8,700
 jne .fail
 ; Prevent a close request, then close explicitly.
 call g18_zero_window_event
 mov dword [rel g18_template_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_CLOSE_REQUESTED
 call g18_push_and_poll
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_stream]
 lea rsi,[rel g18_event]
 call nebo_headless_window_event_prevent_default
 test eax,eax
 jnz .fail
 call g18_finish_window
 ret
.fail:
 mov eax,4
 ret

g18_push_and_poll:
 lea rdi,[rel g18_runtime]
 mov rsi,[rel g18_handle]
 mov rdx,G18_OWNER
 lea rcx,[rel g18_template_event]
 call nebo_headless_window_push_event
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_stream]
 lea rsi,[rel g18_event]
 call nebo_headless_event_stream_poll
 test eax,eax
 jnz .fail
 cmp edx,1
 jne .fail
 xor eax,eax
 ret
.fail:
 mov eax,1
 ret

g18_mode_5:
 mov qword [rel g18_step],1
 call g18_open_window
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_runtime]
 mov rsi,[rel g18_handle]
 mov rdx,G18_OWNER
 call nebo_headless_window_show
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],2
 call g18_canvas_create
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],3
 lea rdi,[rel g18_canvas]
 mov esi,0x102030ff
 call nebo_canvas_clear
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],4
 lea rdi,[rel g18_canvas]
 xor esi,esi
 xor edx,edx
 mov ecx,159
 mov r8d,119
 lea r9,[rel g18_stroke]
 call nebo_canvas_line
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],5
 lea rdi,[rel g18_canvas]
 mov esi,8
 mov edx,8
 mov ecx,40
 mov r8d,24
 lea r9,[rel g18_fill]
 call nebo_canvas_rectangle
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],6
 lea rdi,[rel g18_canvas]
 mov esi,80
 mov edx,60
 mov ecx,12
 lea r8,[rel g18_stroke]
 call nebo_canvas_circle
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],7
 lea rdi,[rel g18_canvas]
 lea rsi,[rel g18_console_text]
 mov edx,11
 mov ecx,12
 mov r8d,44
 lea r9,[rel g18_fill]
 call nebo_canvas_text
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],8
 lea rdi,[rel g18_image]
 mov ecx,8
 xor eax,eax
 rep stosq
 lea rax,[rel g18_image_pixel]
 mov [rel g18_image],rax
 mov dword [rel g18_image+16],1
 mov dword [rel g18_image+20],1
 mov dword [rel g18_image+24],4
 mov word [rel g18_image+28],NEBO_PIXEL_RGBA8
 mov word [rel g18_image+30],NEBO_IMAGE_FLAG_BORROWED
 mov qword [rel g18_image+32],G18_OWNER
 lea rdi,[rel g18_canvas]
 lea rsi,[rel g18_image]
 mov edx,4
 mov ecx,4
 call nebo_canvas_image
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],9
 lea rdi,[rel g18_canvas]
 lea rsi,[rel g18_runtime]
 mov rdx,[rel g18_handle]
 mov rcx,G18_OWNER
 lea r8,[rel g18_present]
 call nebo_canvas_present_headless
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],10
 cmp qword [rel g18_present+NEBO_CANVAS_PRESENT_COMMAND_COUNT_OFFSET],5
 jne .fail
 mov qword [rel g18_step],11
 lea rdi,[rel g18_canvas]
 call nebo_canvas_close
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],12
 call g18_finish_window
 test eax,eax
 jnz .fail
 xor eax,eax
 ret
.fail:
 mov edx,eax
 mov eax,[rel g18_step]
 shl eax,4
 or eax,edx
 ret

g18_mode_6:
 lea rdi,[rel g18_tree]
 lea rsi,[rel g18_nodes]
 mov edx,12
 lea rcx,[rel g18_ui_events]
 mov r8d,24
 mov r9d,G18_WIDTH
 sub rsp,16
 mov qword [rsp],G18_HEIGHT
 mov qword [rsp+8],G18_OWNER
 call nebo_ui_tree_init
 add rsp,16
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_tree]
 xor esi,esi
 mov edx,2
 lea rcx,[rel g18_row_index]
 call nebo_ui_row
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_tree]
 xor esi,esi
 mov edx,2
 lea rcx,[rel g18_column_index]
 call nebo_ui_column
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_tree]
 xor esi,esi
 mov edx,1
 mov ecx,2
 lea r8,[rel g18_grid_index]
 call nebo_ui_grid
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_tree]
 mov rsi,[rel g18_row_index]
 lea rdx,[rel g18_widget_name]
 mov ecx,7
 lea r8,[rel g18_widget_label]
 mov r9d,5
 sub rsp,16
 lea rax,[rel g18_label_index]
 mov [rsp],rax
 call nebo_ui_label
 add rsp,16
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_tree]
 mov rsi,[rel g18_column_index]
 lea rdx,[rel g18_widget_name]
 mov ecx,7
 lea r8,[rel g18_widget_button]
 mov r9d,8
 sub rsp,16
 lea rax,[rel g18_button_index]
 mov [rsp],rax
 call nebo_ui_button
 add rsp,16
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_tree]
 mov rsi,[rel g18_grid_index]
 lea rdx,[rel g18_widget_name]
 mov ecx,7
 lea r8,[rel g18_input_storage]
 mov r9d,64
 sub rsp,16
 mov qword [rsp],0
 lea rax,[rel g18_input_index]
 mov [rsp+8],rax
 call nebo_ui_text_input
 add rsp,16
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_tree]
 call nebo_ui_layout
 test eax,eax
 jnz .fail
 call g18_canvas_create
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_tree]
 lea rsi,[rel g18_canvas]
 call nebo_ui_render
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_tree]
 call nebo_ui_focus_next
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_tree]
 lea rsi,[rel g18_ui_event]
 call nebo_ui_event_poll
 test eax,eax
 jnz .fail
 cmp edx,1
 jne .fail
 lea rdi,[rel g18_tree]
 mov rsi,[rel g18_input_index]
 lea rdx,[rel g18_access]
 call nebo_ui_accessibility_snapshot
 test eax,eax
 jnz .fail
 cmp dword [rel g18_access+NEBO_UI_ACCESS_ROLE_OFFSET],NEBO_UI_ROLE_TEXTBOX
 jne .fail
 lea rdi,[rel g18_tree]
 call nebo_ui_close
 test eax,eax
 jnz .fail
 lea rdi,[rel g18_canvas]
 call nebo_canvas_close
 test eax,eax
 jnz .fail
 xor eax,eax
 ret
.fail:
 mov eax,6
 ret

g18_zero_series:
 lea rdi,[rel g18_series_spec]
 mov ecx,NEBO_CHART_SERIES_QWORDS
 xor eax,eax
 rep stosq
 ret

g18_mode_7:
 mov qword [rel g18_step],1
 lea rdi,[rel g18_chart]
 lea rsi,[rel g18_series]
 mov edx,8
 mov ecx,G18_OWNER
 call nebo_chart_init
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],2
 call g18_canvas_create
 test eax,eax
 jnz .fail
 mov qword [rel g18_canvas+NEBO_CANVAS_OWNER_CONTEXT_OFFSET],G18_OWNER
 ; Line.
 mov qword [rel g18_step],3
 call g18_zero_series
 mov dword [rel g18_series_spec+NEBO_CHART_SERIES_SOURCE_OFFSET],NEBO_CHART_SOURCE_ARRAY
 mov dword [rel g18_series_spec+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_SHOW_POINTS
 mov dword [rel g18_series_spec+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET],0xff5060ff
 mov qword [rel g18_series_spec+NEBO_CHART_SERIES_POINT_RADIUS_OFFSET],2
 lea rax,[rel g18_line_x]
 mov [rel g18_series_spec+NEBO_CHART_SERIES_X_PTR_OFFSET],rax
 lea rax,[rel g18_line_y]
 mov [rel g18_series_spec+NEBO_CHART_SERIES_Y_PTR_OFFSET],rax
 mov qword [rel g18_series_spec+NEBO_CHART_SERIES_POINT_COUNT_OFFSET],4
 mov qword [rel g18_series_spec+NEBO_CHART_SERIES_X_STRIDE_OFFSET],1
 mov qword [rel g18_series_spec+NEBO_CHART_SERIES_Y_STRIDE_OFFSET],1
 lea rax,[rel g18_series_label]
 mov [rel g18_series_spec+NEBO_CHART_SERIES_LABEL_PTR_OFFSET],rax
 mov qword [rel g18_series_spec+NEBO_CHART_SERIES_LABEL_LENGTH_OFFSET],6
 lea rdi,[rel g18_chart]
 lea rsi,[rel g18_series_spec]
 call nebo_chart_line
 test eax,eax
 jnz .fail
 ; Scatter.
 mov qword [rel g18_step],4
 call g18_zero_series
 mov dword [rel g18_series_spec+NEBO_CHART_SERIES_SOURCE_OFFSET],NEBO_CHART_SOURCE_ARRAY
 mov dword [rel g18_series_spec+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET],0x50ff80ff
 mov qword [rel g18_series_spec+NEBO_CHART_SERIES_POINT_RADIUS_OFFSET],2
 lea rax,[rel g18_scatter_x]
 mov [rel g18_series_spec+NEBO_CHART_SERIES_X_PTR_OFFSET],rax
 lea rax,[rel g18_scatter_y]
 mov [rel g18_series_spec+NEBO_CHART_SERIES_Y_PTR_OFFSET],rax
 mov qword [rel g18_series_spec+NEBO_CHART_SERIES_POINT_COUNT_OFFSET],3
 mov qword [rel g18_series_spec+NEBO_CHART_SERIES_X_STRIDE_OFFSET],1
 mov qword [rel g18_series_spec+NEBO_CHART_SERIES_Y_STRIDE_OFFSET],1
 lea rax,[rel g18_series_label]
 mov [rel g18_series_spec+NEBO_CHART_SERIES_LABEL_PTR_OFFSET],rax
 mov qword [rel g18_series_spec+NEBO_CHART_SERIES_LABEL_LENGTH_OFFSET],6
 lea rdi,[rel g18_chart]
 lea rsi,[rel g18_series_spec]
 call nebo_chart_scatter
 test eax,eax
 jnz .fail
 ; Bar.
 mov qword [rel g18_step],5
 call g18_zero_series
 mov dword [rel g18_series_spec+NEBO_CHART_SERIES_SOURCE_OFFSET],NEBO_CHART_SOURCE_ARRAY
 mov dword [rel g18_series_spec+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_AUTO_X
 mov dword [rel g18_series_spec+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET],0x5080ffff
 lea rax,[rel g18_bar_y]
 mov [rel g18_series_spec+NEBO_CHART_SERIES_Y_PTR_OFFSET],rax
 mov qword [rel g18_series_spec+NEBO_CHART_SERIES_POINT_COUNT_OFFSET],3
 mov qword [rel g18_series_spec+NEBO_CHART_SERIES_Y_STRIDE_OFFSET],1
 lea rax,[rel g18_categories]
 mov [rel g18_series_spec+NEBO_CHART_SERIES_CATEGORIES_PTR_OFFSET],rax
 mov qword [rel g18_series_spec+NEBO_CHART_SERIES_CATEGORY_COUNT_OFFSET],3
 lea rax,[rel g18_series_label]
 mov [rel g18_series_spec+NEBO_CHART_SERIES_LABEL_PTR_OFFSET],rax
 mov qword [rel g18_series_spec+NEBO_CHART_SERIES_LABEL_LENGTH_OFFSET],6
 lea rdi,[rel g18_chart]
 lea rsi,[rel g18_series_spec]
 call nebo_chart_bar
 test eax,eax
 jnz .fail
 ; Histogram.
 mov qword [rel g18_step],6
 call g18_zero_series
 mov dword [rel g18_series_spec+NEBO_CHART_SERIES_SOURCE_OFFSET],NEBO_CHART_SOURCE_ARRAY
 mov dword [rel g18_series_spec+NEBO_CHART_SERIES_FLAGS_OFFSET],NEBO_CHART_SERIES_FLAG_AUTO_X
 mov dword [rel g18_series_spec+NEBO_CHART_SERIES_COLOR_RGBA_OFFSET],0xffc050ff
 lea rax,[rel g18_hist_y]
 mov [rel g18_series_spec+NEBO_CHART_SERIES_Y_PTR_OFFSET],rax
 mov qword [rel g18_series_spec+NEBO_CHART_SERIES_POINT_COUNT_OFFSET],5
 mov qword [rel g18_series_spec+NEBO_CHART_SERIES_Y_STRIDE_OFFSET],1
 mov qword [rel g18_series_spec+NEBO_CHART_SERIES_BINS_OFFSET],4
 lea rax,[rel g18_series_label]
 mov [rel g18_series_spec+NEBO_CHART_SERIES_LABEL_PTR_OFFSET],rax
 mov qword [rel g18_series_spec+NEBO_CHART_SERIES_LABEL_LENGTH_OFFSET],6
 lea rdi,[rel g18_chart]
 lea rsi,[rel g18_series_spec]
 call nebo_chart_histogram
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],7
 lea rdi,[rel g18_chart]
 lea rsi,[rel g18_chart_title]
 mov edx,10
 call nebo_chart_title
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],8
 lea rdi,[rel g18_axis]
 mov ecx,NEBO_CHART_AXIS_SIZE/8
 xor eax,eax
 rep stosq
 mov dword [rel g18_axis+NEBO_CHART_AXIS_ID_OFFSET],NEBO_CHART_AXIS_X
 mov dword [rel g18_axis+NEBO_CHART_AXIS_FLAGS_OFFSET],NEBO_CHART_AXIS_FLAG_GRID
 mov qword [rel g18_axis+NEBO_CHART_AXIS_TICKS_OFFSET],5
 lea rax,[rel g18_axis_x]
 mov [rel g18_axis+NEBO_CHART_AXIS_LABEL_PTR_OFFSET],rax
 mov qword [rel g18_axis+NEBO_CHART_AXIS_LABEL_LENGTH_OFFSET],1
 lea rdi,[rel g18_chart]
 lea rsi,[rel g18_axis]
 call nebo_chart_axis
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],9
 lea rdi,[rel g18_legend]
 mov ecx,NEBO_CHART_LEGEND_SIZE/8
 xor eax,eax
 rep stosq
 mov dword [rel g18_legend+NEBO_CHART_LEGEND_OPTIONS_FLAGS_OFFSET],NEBO_CHART_LEGEND_FLAG_ENABLED
 mov qword [rel g18_legend+NEBO_CHART_LEGEND_MAX_OFFSET],4
 mov qword [rel g18_legend+NEBO_CHART_LEGEND_POSITION_OFFSET],NEBO_CHART_LEGEND_TOP_RIGHT
 lea rdi,[rel g18_chart]
 lea rsi,[rel g18_legend]
 call nebo_chart_legend
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],10
 lea rdi,[rel g18_chart]
 lea rsi,[rel g18_canvas]
 lea rdx,[rel g18_render]
 call nebo_chart_render
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],11
 cmp qword [rel g18_render+NEBO_CHART_RESULT_SERIES_OFFSET],4
 jne .fail
 cmp qword [rel g18_render+NEBO_CHART_RESULT_POINTS_OFFSET],15
 jne .fail
 mov qword [rel g18_step],12
 lea rdi,[rel g18_chart]
 call nebo_chart_close
 test eax,eax
 jnz .fail
 mov qword [rel g18_step],13
 lea rdi,[rel g18_canvas]
 call nebo_canvas_close
 test eax,eax
 jnz .fail
 xor eax,eax
 ret
.fail:
 mov edx,eax
 mov eax,[rel g18_step]
 shl eax,4
 or eax,edx
 ret

; (mode, seed) -> seed on success, stable non-seed failure otherwise.
nebo_g018_source_probe:
 push rbx
 mov ebx,esi
 cmp edi,1
 je .m1
 cmp edi,2
 je .m2
 cmp edi,3
 je .m3
 cmp edi,4
 je .m4
 cmp edi,5
 je .m5
 cmp edi,6
 je .m6
 cmp edi,7
 je .m7
 mov eax,208
 jmp .done
.m1: call g18_mode_1
 jmp .result
.m2: call g18_mode_2
 jmp .result
.m3: call g18_mode_3
 jmp .result
.m4: call g18_mode_4
 jmp .result
.m5: call g18_mode_5
 jmp .result
.m6: call g18_mode_6
 jmp .result
.m7: call g18_mode_7
.result:
 test eax,eax
 jnz .failed
 mov eax,ebx
 jmp .done
.failed:
 ; Internal failures encode the failing substep and structured owner status.
.done:
 pop rbx
 ret

; Cross-owner negative/failure-atomicity oracle. Returns zero only when stable
; structured failures preserve caller-owned sentinels.
nebo_g018_negative_probe:
 mov rax,0x1122334455667788
 mov [rel g18_doc+NEBO_CONSOLE_STATE],rax
 lea rdi,[rel g18_doc]
 lea rsi,[rel g18_doc_text]
 mov edx,NEBO_CONSOLE_MAX_TEXT+1
 lea rcx,[rel g18_doc_title]
 mov r8d,64
 call nebo_console_init
 cmp eax,NEBO_LINEAR_CONSOLE_DOCUMENT_CONSOLE_ERROR_LIMIT
 jne .fail
 mov rax,0x1122334455667788
 cmp [rel g18_doc+NEBO_CONSOLE_STATE],rax
 jne .fail
 lea rdi,[rel g18_chart]
 lea rsi,[rel g18_series]
 mov edx,8
 xor ecx,ecx
 call nebo_chart_init
 cmp eax,NEBO_CHART_ERROR_OWNER_MISMATCH
 jne .fail
 lea rdi,[rel g18_canvas]
 lea rsi,[rel g18_pixels]
 mov edx,16
 xor ecx,ecx
 mov r8d,1
 lea r9,[rel g18_commands]
 sub rsp,16
 mov qword [rsp],4
 call nebo_canvas_create
 add rsp,16
 cmp eax,NEBO_CANVAS_ERROR_LIMIT_EXCEEDED
 jne .fail
 xor eax,eax
 ret
.fail:
 mov eax,1
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
