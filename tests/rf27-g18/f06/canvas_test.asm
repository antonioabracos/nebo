bits 64
default rel
%include "runtime/canvas/canvas.inc"

%macro ASSERT_EAX 1
    inc r15d
    cmp eax,%1
    jne .fail
%endmacro
%macro ASSERT_Q 2
    inc r15d
    mov r11,%2
    cmp qword %1,r11
    jne .fail
%endmacro
%macro ASSERT_D 2
    inc r15d
    cmp dword %1,%2
    jne .fail
%endmacro
%macro ASSERT_B 2
    inc r15d
    cmp byte %1,%2
    jne .fail
%endmacro

section .data align=8
paint_stroke: dd 0xffff00ff, NEBO_CANVAS_PAINT_MODE_STROKE, 1, 0
paint_fill: dd 0x0000ffff, NEBO_CANVAS_PAINT_MODE_FILL, 1, 0
paint_red_fill: dd 0xff0000ff, NEBO_CANVAS_PAINT_MODE_FILL, 1, 0
paint_bad: dd 0xffffffff, 99, 1, 0
text_a: db 'A'
invalid_utf8: db 0xc0,0x80
window_title: db 'Canvas'
float_two: dq 0x4000000000000000
float_fraction: dq 0x3ff8000000000000
float_nan: dq 0x7ff8000000000000
float_inf: dq 0x7ff0000000000000
float_4096: dq 0x40b0000000000000

section .bss align=16
canvas: resb NEBO_CANVAS_SIZE
pixels: resb 16*16*4
commands: resb NEBO_CANVAS_COMMAND_SIZE*8
rgba: resb 16*16*4
hash_before: resq 1
hash_after: resq 1
coord_out: resq 1
present_result: resb NEBO_CANVAS_PRESENT_RESULT_SIZE

canvas2: resb NEBO_CANVAS_SIZE
pixels2: resb 4*4*4
commands2: resb NEBO_CANVAS_COMMAND_SIZE

runtime: resb NEBO_HEADLESS_RUNTIME_SIZE
record: resb NEBO_WINDOW_SIZE
options: resb NEBO_WINDOW_OPTIONS_SIZE
title_storage: resb 256
event_storage: resb NEBO_WINDOW_EVENT_SIZE*8
scheduler_budget: resb NEBO_SCHEDULER_BUDGET_SIZE
task_group: resb NEBO_TASK_GROUP_SIZE
task_storage: resb nebo_concurrency_contract_TASK_SIZE
cancel_budget: resb NEBO_CANCELLATION_BUDGET_SIZE
cancel_token: resb NEBO_CANCELLATION_TOKEN_SIZE
handle: resq 1
stream: resb NEBO_HEADLESS_STREAM_SIZE
event: resb NEBO_WINDOW_EVENT_SIZE

section .text
global _start
_start:
    xor r15d,r15d
%if NEBO_CANVAS_SIZE != 208
%error canvas_size
%endif
%if NEBO_CANVAS_COMMAND_SIZE != 64
%error command_size
%endif
%if NEBO_CANVAS_MAX_AXIS != 2048
%error max_axis
%endif
%if NEBO_CANVAS_MAX_COMMANDS != 8192
%error max_commands
%endif

    ; Creation rejects overlap and preserves the caller descriptor atomically.
    mov rax,0x1122334455667788
    mov [rel canvas],rax
    lea rdi,[rel canvas]
    lea rsi,[rel canvas]
    mov edx,1024
    mov ecx,1
    mov r8d,1
    lea r9,[rel commands]
    sub rsp,16
    mov qword [rsp],8
    call nebo_canvas_create
    add rsp,16
    ASSERT_EAX NEBO_CANVAS_ERROR_STORAGE_OVERLAP
    ASSERT_Q [rel canvas],0x1122334455667788

    ; Dimension and command-budget bounds are atomic.
    lea rdi,[rel canvas]
    lea rsi,[rel pixels]
    mov edx,16*16*4
    mov ecx,2049
    mov r8d,1
    lea r9,[rel commands]
    sub rsp,16
    mov qword [rsp],8
    call nebo_canvas_create
    add rsp,16
    ASSERT_EAX NEBO_CANVAS_ERROR_LIMIT_EXCEEDED
    ASSERT_Q [rel canvas],0x1122334455667788

    lea rdi,[rel canvas]
    lea rsi,[rel pixels]
    mov edx,16*16*4
    mov ecx,16
    mov r8d,16
    lea r9,[rel commands]
    sub rsp,16
    mov qword [rsp],8
    call nebo_canvas_create
    add rsp,16
    ASSERT_EAX 0
    ASSERT_Q [rel canvas+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET],16
    ASSERT_Q [rel canvas+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET],16
    ASSERT_Q [rel canvas+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET],64
    ASSERT_Q [rel canvas+NEBO_CANVAS_COMMAND_CAPACITY_OFFSET],8
    ASSERT_D [rel canvas+NEBO_CANVAS_STATE_OFFSET],NEBO_CANVAS_STATE_ACTIVE
    ASSERT_D [rel canvas+NEBO_CANVAS_FLAGS_OFFSET],NEBO_CANVAS_FLAG_INITIALIZED
    ASSERT_Q [rel canvas+NEBO_SOFTWARE_SURFACE_GENERATION_OFFSET],1
    ASSERT_Q [rel canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],0
    ASSERT_D [rel pixels],0

    lea rdi,[rel canvas]
    call nebo_canvas_validate
    ASSERT_EAX 0

    ; Premultiplied RGBA8 conversion is exact and deterministic.
    lea rdi,[rel canvas]
    mov esi,0xff000080
    call nebo_canvas_clear
    ASSERT_EAX 0
    ASSERT_D [rel pixels],0x80800000
    ASSERT_Q [rel canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],1

    lea rdi,[rel canvas]
    mov esi,0x102030ff
    call nebo_canvas_clear
    ASSERT_EAX 0
    ASSERT_D [rel pixels],0xff102030
    ASSERT_Q [rel canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],2

    ; A zero-length line is a true no-op and consumes no command.
    lea rdi,[rel canvas]
    mov esi,2
    mov edx,2
    mov ecx,2
    mov r8d,2
    lea r9,[rel paint_stroke]
    call nebo_canvas_line
    ASSERT_EAX 0
    ASSERT_Q [rel canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],2

    ; Clipped Bresenham line reaches only in-bounds pixels.
    lea rdi,[rel canvas]
    mov rsi,-2
    mov rdx,-2
    mov ecx,3
    mov r8d,3
    lea r9,[rel paint_stroke]
    call nebo_canvas_line
    ASSERT_EAX 0
    ASSERT_Q [rel canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],3
    ASSERT_D [rel pixels],0xffffff00
    ASSERT_D [rel pixels+3*64+3*4],0xffffff00
    ASSERT_D [rel pixels+4*64+4*4],0xff102030

    ; Invalid coordinate and paint fail before raster/command mutation.
    lea rdi,[rel canvas]
    mov esi,4096
    xor edx,edx
    mov ecx,1
    mov r8d,1
    lea r9,[rel paint_stroke]
    call nebo_canvas_line
    ASSERT_EAX NEBO_CANVAS_ERROR_COORDINATE_RANGE
    ASSERT_Q [rel canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],3

    lea rdi,[rel canvas]
    xor esi,esi
    xor edx,edx
    mov ecx,1
    mov r8d,1
    lea r9,[rel paint_bad]
    call nebo_canvas_line
    ASSERT_EAX NEBO_CANVAS_ERROR_INVALID_PAINT
    ASSERT_Q [rel canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],3

    ; Fill and stroke rectangles share the exact clipping raster.
    lea rdi,[rel canvas]
    mov esi,1
    mov edx,1
    mov ecx,3
    mov r8d,2
    lea r9,[rel paint_fill]
    call nebo_canvas_rectangle
    ASSERT_EAX 0
    ASSERT_Q [rel canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],4
    ASSERT_D [rel pixels+1*64+1*4],0xff0000ff
    ASSERT_D [rel pixels+2*64+3*4],0xff0000ff

    lea rdi,[rel canvas]
    mov esi,10
    mov edx,1
    mov ecx,4
    mov r8d,3
    lea r9,[rel paint_stroke]
    call nebo_canvas_rectangle
    ASSERT_EAX 0
    ASSERT_Q [rel canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],5
    ASSERT_D [rel pixels+1*64+10*4],0xffffff00
    ASSERT_D [rel pixels+2*64+11*4],0xff102030
    ASSERT_D [rel pixels+3*64+13*4],0xffffff00

    ; Midpoint fill circle and built-in text.
    lea rdi,[rel canvas]
    mov esi,8
    mov edx,10
    mov ecx,3
    lea r8,[rel paint_red_fill]
    call nebo_canvas_circle
    ASSERT_EAX 0
    ASSERT_Q [rel canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],6
    ASSERT_D [rel pixels+10*64+8*4],0xffff0000
    ASSERT_D [rel pixels+10*64+11*4],0xffff0000

    lea rdi,[rel canvas]
    lea rsi,[rel text_a]
    mov edx,1
    mov ecx,1
    mov r8d,7
    lea r9,[rel paint_red_fill]
    call nebo_canvas_text
    ASSERT_EAX 0
    ASSERT_Q [rel canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],7
    ASSERT_D [rel pixels+7*64+2*4],0xffff0000
    ASSERT_D [rel pixels+10*64+1*4],0xffff0000

    ; Strict UTF-8 failure is atomic with respect to the stable state hash.
    lea rdi,[rel canvas]
    lea rsi,[rel hash_before]
    call nebo_canvas_state_hash
    ASSERT_EAX 0
    lea rdi,[rel canvas]
    lea rsi,[rel invalid_utf8]
    mov edx,2
    mov ecx,1
    mov r8d,1
    lea r9,[rel paint_red_fill]
    call nebo_canvas_text
    ASSERT_EAX NEBO_CANVAS_ERROR_INVALID_UTF8
    ASSERT_Q [rel canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],7
    lea rdi,[rel canvas]
    lea rsi,[rel hash_after]
    call nebo_canvas_state_hash
    ASSERT_EAX 0
    mov rax,[rel hash_before]
    inc r15d
    cmp [rel hash_after],rax
    jne .fail

    ; Canonical premultiplied RGBA channel order export.
    lea rdi,[rel canvas]
    lea rsi,[rel rgba]
    mov edx,16*16*4
    call nebo_canvas_export_rgba
    ASSERT_EAX 0
    ASSERT_B [rel rgba],0xff
    ASSERT_B [rel rgba+1],0xff
    ASSERT_B [rel rgba+2],0x00
    ASSERT_B [rel rgba+3],0xff

    ; Float64 coordinates accept only finite exact integers in range.
    lea rdi,[rel float_two]
    lea rsi,[rel coord_out]
    call nebo_canvas_coord_from_float_exact
    ASSERT_EAX 0
    ASSERT_Q [rel coord_out],2
    lea rdi,[rel float_fraction]
    lea rsi,[rel coord_out]
    call nebo_canvas_coord_from_float_exact
    ASSERT_EAX NEBO_CANVAS_ERROR_NON_INTEGER_FLOAT
    lea rdi,[rel float_nan]
    lea rsi,[rel coord_out]
    call nebo_canvas_coord_from_float_exact
    ASSERT_EAX NEBO_CANVAS_ERROR_NON_INTEGER_FLOAT
    lea rdi,[rel float_inf]
    lea rsi,[rel coord_out]
    call nebo_canvas_coord_from_float_exact
    ASSERT_EAX NEBO_CANVAS_ERROR_COORDINATE_RANGE
    lea rdi,[rel float_4096]
    lea rsi,[rel coord_out]
    call nebo_canvas_coord_from_float_exact
    ASSERT_EAX NEBO_CANVAS_ERROR_COORDINATE_RANGE

    ; Compose with the deterministic F04 Window runtime.
    lea rdi,[rel scheduler_budget]
    mov esi,1
    mov edx,1
    mov ecx,1
    mov r8d,8
    mov r9d,32
    call nebo_scheduler_budget_init
    ASSERT_EAX 0
    lea rdi,[rel task_group]
    lea rsi,[rel scheduler_budget]
    lea rdx,[rel task_storage]
    mov ecx,1
    call nebo_task_group_init
    ASSERT_EAX 0
    lea rdi,[rel cancel_budget]
    mov esi,8
    mov edx,8
    mov ecx,1000000000
    call nebo_cancellation_budget_init
    ASSERT_EAX 0
    lea rdi,[rel cancel_token]
    lea rsi,[rel cancel_budget]
    xor edx,edx
    xor ecx,ecx
    xor r8d,r8d
    xor r9d,r9d
    call nebo_cancellation_token_init
    ASSERT_EAX 0
    lea rdi,[rel runtime]
    lea rsi,[rel record]
    mov edx,1
    call nebo_headless_runtime_init
    ASSERT_EAX 0

    lea rdi,[rel options]
    mov ecx,NEBO_WINDOW_OPTIONS_QWORDS
    xor eax,eax
    rep stosq
    mov qword [rel options+NEBO_WINDOW_OPTIONS_WIDTH_OFFSET],16
    mov qword [rel options+NEBO_WINDOW_OPTIONS_HEIGHT_OFFSET],16
    lea rax,[rel window_title]
    mov [rel options+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET],rax
    mov qword [rel options+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET],6
    lea rax,[rel title_storage]
    mov [rel options+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET],rax
    mov qword [rel options+NEBO_WINDOW_OPTIONS_TITLE_CAPACITY_OFFSET],256
    lea rax,[rel event_storage]
    mov [rel options+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET],rax
    mov qword [rel options+NEBO_WINDOW_OPTIONS_EVENT_CAPACITY_OFFSET],8
    lea rax,[rel cancel_token]
    mov [rel options+NEBO_WINDOW_OPTIONS_CANCELLATION_PTR_OFFSET],rax
    lea rax,[rel task_group]
    mov [rel options+NEBO_WINDOW_OPTIONS_TASK_GROUP_PTR_OFFSET],rax
    mov dword [rel options+NEBO_WINDOW_OPTIONS_BACKEND_PREFERENCE_OFFSET],NEBO_WINDOW_BACKEND_HEADLESS
    mov dword [rel options+NEBO_WINDOW_OPTIONS_FLAGS_OFFSET],NEBO_WINDOW_OPTION_RESIZABLE | NEBO_WINDOW_OPTION_DECORATED
    mov qword [rel options+NEBO_WINDOW_OPTIONS_OWNER_CONTEXT_OFFSET],0x606
    lea rdi,[rel runtime]
    lea rsi,[rel options]
    lea rdx,[rel handle]
    call nebo_headless_window_create
    ASSERT_EAX 0
    lea rdi,[rel runtime]
    mov rsi,[rel handle]
    mov rdx,0x606
    lea rcx,[rel stream]
    call nebo_headless_window_events
    ASSERT_EAX 0
    lea rdi,[rel runtime]
    mov rsi,[rel handle]
    mov rdx,0x606
    call nebo_headless_window_show
    ASSERT_EAX 0

    mov rax,0xaaaaaaaaaaaaaaaa
    mov [rel present_result],rax
    lea rdi,[rel canvas]
    lea rsi,[rel runtime]
    mov rdx,[rel handle]
    mov rcx,0x606
    lea r8,[rel present_result]
    call nebo_canvas_present_headless
    ASSERT_EAX 0
    ASSERT_Q [rel present_result+NEBO_CANVAS_PRESENT_FRAME_SEQUENCE_OFFSET],1
    ASSERT_Q [rel present_result+NEBO_CANVAS_PRESENT_COMMAND_COUNT_OFFSET],7
    ASSERT_Q [rel canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],0
    ASSERT_Q [rel canvas+NEBO_CANVAS_OWNER_CONTEXT_OFFSET],0x606
    inc r15d
    test dword [rel canvas+NEBO_CANVAS_FLAGS_OFFSET],NEBO_CANVAS_FLAG_PRESENTED
    jz .fail

    ; Owner and dimension failures leave the result untouched.
    mov rax,0xaaaaaaaaaaaaaaaa
    mov [rel present_result],rax
    lea rdi,[rel canvas]
    lea rsi,[rel runtime]
    mov rdx,[rel handle]
    mov rcx,0x607
    lea r8,[rel present_result]
    call nebo_canvas_present_headless
    ASSERT_EAX NEBO_CANVAS_ERROR_OWNER_MISMATCH
    ASSERT_Q [rel present_result],0xaaaaaaaaaaaaaaaa
    mov qword [rel record+NEBO_WINDOW_WIDTH_OFFSET],15
    lea rdi,[rel canvas]
    lea rsi,[rel runtime]
    mov rdx,[rel handle]
    mov rcx,0x606
    lea r8,[rel present_result]
    call nebo_canvas_present_headless
    ASSERT_EAX NEBO_CANVAS_ERROR_DIMENSION_MISMATCH
    mov qword [rel record+NEBO_WINDOW_WIDTH_OFFSET],16

    ; Missing caller-owned record storage is rejected before result mutation.
    mov rax,[rel runtime+NEBO_HEADLESS_RUNTIME_RECORDS_PTR_OFFSET]
    mov [rel hash_before],rax
    mov qword [rel runtime+NEBO_HEADLESS_RUNTIME_RECORDS_PTR_OFFSET],0
    mov rax,0xaaaaaaaaaaaaaaaa
    mov [rel present_result],rax
    lea rdi,[rel canvas]
    lea rsi,[rel runtime]
    mov rdx,[rel handle]
    mov rcx,0x606
    lea r8,[rel present_result]
    call nebo_canvas_present_headless
    ASSERT_EAX NEBO_CANVAS_ERROR_INVALID_ARGUMENT
    ASSERT_Q [rel present_result],0xaaaaaaaaaaaaaaaa
    mov rax,[rel hash_before]
    mov [rel runtime+NEBO_HEADLESS_RUNTIME_RECORDS_PTR_OFFSET],rax

    lea rdi,[rel canvas]
    lea rsi,[rel runtime]
    mov rdx,[rel handle]
    mov rcx,0x606
    lea r8,[rel present_result]
    call nebo_canvas_present_headless
    ASSERT_EAX 0
    ASSERT_Q [rel present_result+NEBO_CANVAS_PRESENT_FRAME_SEQUENCE_OFFSET],2
    ASSERT_Q [rel present_result+NEBO_CANVAS_PRESENT_COMMAND_COUNT_OFFSET],0
    ASSERT_Q [rel canvas+NEBO_CANVAS_LAST_STATUS_OFFSET],0
    ASSERT_Q [rel canvas+NEBO_CANVAS_LAST_ERROR_OFFSET],0

    ; A one-command canvas rejects the second command before pixel mutation.
    lea rdi,[rel canvas2]
    lea rsi,[rel pixels2]
    mov edx,4*4*4
    mov ecx,4
    mov r8d,4
    lea r9,[rel commands2]
    sub rsp,16
    mov qword [rsp],1
    call nebo_canvas_create
    add rsp,16
    ASSERT_EAX 0
    lea rdi,[rel canvas2]
    mov esi,0xff0000ff
    call nebo_canvas_clear
    ASSERT_EAX 0
    lea rdi,[rel canvas2]
    mov esi,0x0000ffff
    call nebo_canvas_clear
    ASSERT_EAX NEBO_CANVAS_ERROR_COMMAND_LIMIT
    ASSERT_D [rel pixels2],0xffff0000
    ASSERT_Q [rel canvas2+NEBO_CANVAS_COMMAND_COUNT_OFFSET],1

    ; Closed is terminal for drawing and presentation.
    lea rdi,[rel canvas]
    call nebo_canvas_close
    ASSERT_EAX 0
    ASSERT_D [rel canvas+NEBO_CANVAS_STATE_OFFSET],NEBO_CANVAS_STATE_CLOSED
    lea rdi,[rel canvas]
    mov esi,0
    call nebo_canvas_clear
    ASSERT_EAX NEBO_CANVAS_ERROR_CLOSED
    lea rdi,[rel canvas]
    lea rsi,[rel runtime]
    mov rdx,[rel handle]
    mov rcx,0x606
    lea r8,[rel present_result]
    call nebo_canvas_present_headless
    ASSERT_EAX NEBO_CANVAS_ERROR_CLOSED
    lea rdi,[rel canvas]
    call nebo_canvas_close
    ASSERT_EAX NEBO_CANVAS_ERROR_CLOSED

    ; Exact cleanup of the predecessor Window remains composable.
    lea rdi,[rel runtime]
    mov rsi,[rel handle]
    mov rdx,0x606
    call nebo_headless_window_close
    ASSERT_EAX 0
    mov r14d,3
.drain_window_events:
    lea rdi,[rel stream]
    lea rsi,[rel event]
    call nebo_headless_event_stream_poll
    ASSERT_EAX 0
    inc r15d
    cmp edx,1
    jne .fail
    dec r14d
    jnz .drain_window_events
    lea rdi,[rel stream]
    lea rsi,[rel event]
    call nebo_headless_event_stream_poll
    ASSERT_EAX 0
    inc r15d
    test edx,edx
    jne .fail
    lea rdi,[rel stream]
    call nebo_headless_event_stream_release
    ASSERT_EAX 0
    lea rdi,[rel runtime]
    mov rsi,[rel handle]
    mov rdx,0x606
    call nebo_headless_window_reclaim
    ASSERT_EAX 0

    xor edi,edi
    jmp .exit
.fail:
    mov edi,1
.exit:
    mov eax,60
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
