; CONTROLO-DE-FLUXO-ESTRUTURADO-F06 compact bounded native Canvas + headless Window composition.
bits 64
default rel
%include "runtime/canvas/canvas.inc"

%define EX_WIDTH 64
%define EX_HEIGHT 48
%define EX_OWNER 0x43414e564153

section .rodata
ex_title: db 'Canvas 2D'
ex_text: db 'NEBO'
section .data align=8
ex_stroke: dd 0xffcc00ff,NEBO_CANVAS_PAINT_MODE_STROKE,1,0
ex_fill: dd 0x2060ffff,NEBO_CANVAS_PAINT_MODE_FILL,1,0
ex_text_paint: dd 0xffffffff,NEBO_CANVAS_PAINT_MODE_FILL,1,0
section .bss align=16
ex_canvas: resb NEBO_CANVAS_SIZE
ex_pixels: resb EX_WIDTH*EX_HEIGHT*4
ex_commands: resb NEBO_CANVAS_COMMAND_SIZE*16
ex_result: resb NEBO_CANVAS_PRESENT_RESULT_SIZE
ex_runtime: resb NEBO_HEADLESS_RUNTIME_SIZE
ex_record: resb NEBO_WINDOW_SIZE
ex_options: resb NEBO_WINDOW_OPTIONS_SIZE
ex_title_storage: resb 256
ex_events: resb NEBO_WINDOW_EVENT_SIZE*8
ex_scheduler: resb NEBO_SCHEDULER_BUDGET_SIZE
ex_group: resb NEBO_TASK_GROUP_SIZE
ex_tasks: resb nebo_concurrency_contract_TASK_SIZE
ex_cancel_budget: resb NEBO_CANCELLATION_BUDGET_SIZE
ex_cancel: resb NEBO_CANCELLATION_TOKEN_SIZE
ex_stream: resb NEBO_HEADLESS_STREAM_SIZE
ex_event: resb NEBO_WINDOW_EVENT_SIZE
ex_handle: resq 1

section .text
global _start
_start:
    lea rdi,[rel ex_scheduler]
    mov esi,1
    mov edx,1
    mov ecx,1
    mov r8d,4
    mov r9d,16
    call nebo_scheduler_budget_init
    test eax,eax
    jnz .fail
    lea rdi,[rel ex_group]
    lea rsi,[rel ex_scheduler]
    lea rdx,[rel ex_tasks]
    mov ecx,1
    call nebo_task_group_init
    test eax,eax
    jnz .fail
    lea rdi,[rel ex_cancel_budget]
    mov esi,4
    mov edx,4
    mov ecx,1000000000
    call nebo_cancellation_budget_init
    test eax,eax
    jnz .fail
    lea rdi,[rel ex_cancel]
    lea rsi,[rel ex_cancel_budget]
    xor edx,edx
    xor ecx,ecx
    xor r8d,r8d
    xor r9d,r9d
    call nebo_cancellation_token_init
    test eax,eax
    jnz .fail
    lea rdi,[rel ex_runtime]
    lea rsi,[rel ex_record]
    mov edx,1
    call nebo_headless_runtime_init
    test eax,eax
    jnz .fail

    lea rdi,[rel ex_options]
    mov ecx,NEBO_WINDOW_OPTIONS_QWORDS
    xor eax,eax
    rep stosq
    mov qword [rel ex_options+NEBO_WINDOW_OPTIONS_WIDTH_OFFSET],EX_WIDTH
    mov qword [rel ex_options+NEBO_WINDOW_OPTIONS_HEIGHT_OFFSET],EX_HEIGHT
    lea rax,[rel ex_title]
    mov [rel ex_options+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET],rax
    mov qword [rel ex_options+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET],9
    lea rax,[rel ex_title_storage]
    mov [rel ex_options+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET],rax
    mov qword [rel ex_options+NEBO_WINDOW_OPTIONS_TITLE_CAPACITY_OFFSET],256
    lea rax,[rel ex_events]
    mov [rel ex_options+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET],rax
    mov qword [rel ex_options+NEBO_WINDOW_OPTIONS_EVENT_CAPACITY_OFFSET],8
    lea rax,[rel ex_cancel]
    mov [rel ex_options+NEBO_WINDOW_OPTIONS_CANCELLATION_PTR_OFFSET],rax
    lea rax,[rel ex_group]
    mov [rel ex_options+NEBO_WINDOW_OPTIONS_TASK_GROUP_PTR_OFFSET],rax
    mov dword [rel ex_options+NEBO_WINDOW_OPTIONS_BACKEND_PREFERENCE_OFFSET],NEBO_WINDOW_BACKEND_HEADLESS
    mov dword [rel ex_options+NEBO_WINDOW_OPTIONS_FLAGS_OFFSET],NEBO_WINDOW_OPTION_RESIZABLE | NEBO_WINDOW_OPTION_DECORATED
    mov rax,EX_OWNER
    mov [rel ex_options+NEBO_WINDOW_OPTIONS_OWNER_CONTEXT_OFFSET],rax
    lea rdi,[rel ex_runtime]
    lea rsi,[rel ex_options]
    lea rdx,[rel ex_handle]
    call nebo_headless_window_create
    test eax,eax
    jnz .fail
    lea rdi,[rel ex_runtime]
    mov rsi,[rel ex_handle]
    mov rdx,EX_OWNER
    lea rcx,[rel ex_stream]
    call nebo_headless_window_events
    test eax,eax
    jnz .fail
    lea rdi,[rel ex_runtime]
    mov rsi,[rel ex_handle]
    mov rdx,EX_OWNER
    call nebo_headless_window_show
    test eax,eax
    jnz .fail

    lea rdi,[rel ex_canvas]
    lea rsi,[rel ex_pixels]
    mov edx,EX_WIDTH*EX_HEIGHT*4
    mov ecx,EX_WIDTH
    mov r8d,EX_HEIGHT
    lea r9,[rel ex_commands]
    sub rsp,16
    mov qword [rsp],16
    call nebo_canvas_create
    add rsp,16
    test eax,eax
    jnz .fail
    lea rdi,[rel ex_canvas]
    mov esi,0x102030ff
    call nebo_canvas_clear
    test eax,eax
    jnz .fail
    lea rdi,[rel ex_canvas]
    mov rsi,-8
    xor edx,edx
    mov ecx,63
    mov r8d,47
    lea r9,[rel ex_stroke]
    call nebo_canvas_line
    test eax,eax
    jnz .fail
    lea rdi,[rel ex_canvas]
    mov esi,6
    mov edx,6
    mov ecx,28
    mov r8d,18
    lea r9,[rel ex_fill]
    call nebo_canvas_rectangle
    test eax,eax
    jnz .fail
    lea rdi,[rel ex_canvas]
    mov esi,48
    mov edx,30
    mov ecx,10
    lea r8,[rel ex_stroke]
    call nebo_canvas_circle
    test eax,eax
    jnz .fail
    lea rdi,[rel ex_canvas]
    lea rsi,[rel ex_text]
    mov edx,4
    mov ecx,8
    mov r8d,28
    lea r9,[rel ex_text_paint]
    call nebo_canvas_text
    test eax,eax
    jnz .fail
    lea rdi,[rel ex_canvas]
    lea rsi,[rel ex_runtime]
    mov rdx,[rel ex_handle]
    mov rcx,EX_OWNER
    lea r8,[rel ex_result]
    call nebo_canvas_present_headless
    test eax,eax
    jnz .fail
    cmp qword [rel ex_result+NEBO_CANVAS_PRESENT_COMMAND_COUNT_OFFSET],5
    jne .fail

    lea rdi,[rel ex_canvas]
    call nebo_canvas_close
    test eax,eax
    jnz .fail
    lea rdi,[rel ex_runtime]
    mov rsi,[rel ex_handle]
    mov rdx,EX_OWNER
    call nebo_headless_window_close
    test eax,eax
    jnz .fail
    mov r12d,3
.drain:
    lea rdi,[rel ex_stream]
    lea rsi,[rel ex_event]
    call nebo_headless_event_stream_poll
    test eax,eax
    jnz .fail
    cmp edx,1
    jne .fail
    dec r12d
    jnz .drain
    lea rdi,[rel ex_stream]
    call nebo_headless_event_stream_release
    test eax,eax
    jnz .fail
    lea rdi,[rel ex_runtime]
    mov rsi,[rel ex_handle]
    mov rdx,EX_OWNER
    call nebo_headless_window_reclaim
    test eax,eax
    jnz .fail
    xor edi,edi
    jmp .exit
.fail:
    mov edi,1
.exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
