; Nebo Assembly — MF058 headless Console performance fixtures
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/handles/console_handle.inc"
%include "runtime/console/manager/console_manager.inc"
%include "runtime/console/queues/console_queue.inc"
%include "runtime/console/domain/console_domain.inc"
%include "runtime/console/platform/fake/fake_platform.inc"
%include "runtime/console/document/console_document.inc"
%include "runtime/console/layout/console_layout.inc"
%include "runtime/console/render/fake_glyph_provider.inc"
%include "runtime/console/render/render_tree.inc"
%include "runtime/console/render/draw_command.inc"
%include "runtime/console/render/software_surface.inc"
%include "runtime/console/input/registry/input_registry.inc"
%include "runtime/console/pending/pending_registry.inc"
%include "runtime/console/input/editing/text_editor.inc"

extern nebo_console_runtime_context_init
extern nebo_console_runtime_headless_bind
extern nebo_console_manager_anonymous_create
extern nebo_console_domain_from_handle
extern nebo_console_scheduler_run
extern nebo_fake_platform_inject_event
extern nebo_console_document_init
extern nebo_console_document_append_text
extern nebo_fake_glyph_provider_init
extern nebo_console_layout_init
extern nebo_console_layout_document
extern nebo_console_render_tree_init
extern nebo_console_render_tree_build
extern nebo_draw_command_buffer_init
extern nebo_console_draw_commands_build
extern nebo_software_surface_init
extern nebo_software_surface_execute
extern nebo_text_edit_init
extern nebo_text_edit_insert_utf8
extern nebo_text_edit_key
extern nebo_text_edit_validate
extern neboc_host_process_exit

global _start
global mf058_console_storage_begin
global mf058_console_storage_end
global mf058_input_storage_begin
global mf058_input_storage_end

%define MAX_CONSOLES 64
%define SCALE_MAX_CONSOLES 8
%define QUEUE_CAPACITY 4
%define CREATE_BATCHES 128
%define CREATE_OPERATIONS (CREATE_BATCHES*MAX_CONSOLES)
%define FIRST_FRAME_ITERATIONS 512
%define INPUT_EDIT_ITERATIONS 200000
%define SCALE_ITERATIONS 1024
%define MEMORY_NODE_CAPACITY 16
%define MEMORY_TEXT_CAPACITY 256
%define MEMORY_INPUT_CAPACITY 1
%define MEMORY_INPUT_TEXT_STRIDE 64

%define FRAME_NODE_CAPACITY 32
%define FRAME_TEXT_CAPACITY 512
%define FRAME_BOX_CAPACITY 64
%define FRAME_RENDER_CAPACITY 64
%define FRAME_COMMAND_CAPACITY 128
%define FRAME_WIDTH 160
%define FRAME_HEIGHT 100
%define FRAME_SURFACE_BYTES (FRAME_WIDTH*FRAME_HEIGHT*4)

section .rodata align=16
frame_text_bytes: db 'Nebo performance baseline'
frame_text:
    dq frame_text_bytes,25
    dd 0
    dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
input_byte: db 'a'

section .bss align=4096
; Fixed runtime overhead is excluded from the per-Console storage symbols.
context: resb NEBO_CONSOLE_CONTEXT_SIZE
clock: resb NEBO_FAKE_CLOCK_SIZE
platform: resb NEBO_FAKE_PLATFORM_SIZE
scheduler: resb NEBO_CONSOLE_SCHEDULER_SIZE
headless_storage: resb NEBO_CONSOLE_HEADLESS_STORAGE_SIZE
runtime_capacity: resq 1
progress: resq 1

times ((-($ - $$)) & 4095) resb 1
mf058_console_storage_begin:
slots: resb MAX_CONSOLES*NEBO_CONSOLE_SLOT_SIZE
domains: resb MAX_CONSOLES*NEBO_CONSOLE_DOMAIN_SIZE
command_buffers: resb MAX_CONSOLES*QUEUE_CAPACITY*NEBO_CONSOLE_COMMAND_DESCRIPTOR_SIZE
event_buffers: resb MAX_CONSOLES*QUEUE_CAPACITY*NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
memory_documents: resb MAX_CONSOLES*NEBO_CONSOLE_DOCUMENT_SIZE
memory_nodes: resb MAX_CONSOLES*MEMORY_NODE_CAPACITY*NEBO_CONSOLE_NODE_HEADER_SIZE
memory_text_store: resb MAX_CONSOLES*MEMORY_TEXT_CAPACITY
handles: resq MAX_CONSOLES
domain_ptrs: resq MAX_CONSOLES
processed_baselines: resq MAX_CONSOLES
mf058_console_storage_end:

times ((-($ - $$)) & 4095) resb 1
mf058_input_storage_begin:
memory_input_registries: resb MAX_CONSOLES*NEBO_INPUT_REGISTRY_SIZE
memory_input_records: resb MAX_CONSOLES*MEMORY_INPUT_CAPACITY*NEBO_INPUT_RECORD_SIZE
memory_pending_registries: resb MAX_CONSOLES*NEBO_PENDING_REGISTRY_SIZE
memory_pending_records: resb MAX_CONSOLES*MEMORY_INPUT_CAPACITY*NEBO_PENDING_RECORD_SIZE
memory_editors: resb MAX_CONSOLES*MEMORY_INPUT_CAPACITY*NEBO_TEXT_EDIT_RECORD_SIZE
memory_input_text: resb MAX_CONSOLES*MEMORY_INPUT_CAPACITY*MEMORY_INPUT_TEXT_STRIDE
mf058_input_storage_end:

; First-frame singleton model.
times ((-($ - $$)) & 63) resb 1
frame_document: resb NEBO_CONSOLE_DOCUMENT_SIZE
frame_nodes: resb FRAME_NODE_CAPACITY*NEBO_CONSOLE_NODE_HEADER_SIZE
frame_text_store: resb FRAME_TEXT_CAPACITY
frame_provider: resb NEBO_FAKE_GLYPH_PROVIDER_SIZE
frame_layout: resb NEBO_LAYOUT_TREE_SIZE
frame_boxes: resb FRAME_BOX_CAPACITY*NEBO_LAYOUT_BOX_SIZE
frame_render_tree: resb NEBO_RENDER_TREE_SIZE
frame_render_nodes: resb FRAME_RENDER_CAPACITY*NEBO_RENDER_NODE_SIZE
frame_draw_buffer: resb NEBO_DRAW_BUFFER_SIZE
frame_draw_commands: resb FRAME_COMMAND_CAPACITY*NEBO_DRAW_COMMAND_SIZE
frame_surface: resb NEBO_SOFTWARE_SURFACE_SIZE
frame_pixels: resb FRAME_SURFACE_BYTES

; Input-core singleton model.
input_editor: resb NEBO_TEXT_EDIT_RECORD_SIZE
input_buffer: resb 64

section .text
_start:
    cmp qword [rsp], 2
    jb test_usage
    mov rbx, [rsp+16]
    cmp byte [rbx+1], 0
    jne test_usage
    cmp byte [rbx], '1'
    je benchmark_logical_create
    cmp byte [rbx], '2'
    je benchmark_first_frame
    cmp byte [rbx], '3'
    je benchmark_input_latency
    cmp byte [rbx], '4'
    je benchmark_multi_console
    cmp byte [rbx], '5'
    je benchmark_memory_touch
    jmp test_usage

; Fresh-runtime logical create baseline. The metric includes deterministic
; context/headless binding and exactly MAX_CONSOLES logical creates per batch.
benchmark_logical_create:
    cmp qword [rsp], 2
    jne test_usage
    mov r15d, CREATE_BATCHES
.create_batch:
    mov edi, MAX_CONSOLES
    call setup_runtime
    test eax, eax
    jnz test_fail
    xor r14d, r14d
.create_loop:
    lea rdi, [rel context]
    lea rax, [rel handles]
    lea rsi, [rax+r14*8]
    call nebo_console_manager_anonymous_create
    test eax, eax
    jnz test_fail
    inc r14d
    cmp r14d, MAX_CONSOLES
    jb .create_loop
    cmp qword [rel context+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET], MAX_CONSOLES
    jne test_fail
    dec r15d
    jnz .create_batch
    jmp test_pass

; Headless first-frame baseline: document -> layout -> render tree -> draw list
; -> software surface. Native adapter connection/present is intentionally absent.
benchmark_first_frame:
    cmp qword [rsp], 2
    jne test_usage
    mov r15d, FIRST_FRAME_ITERATIONS
.frame_loop:
    call build_first_frame
    test eax, eax
    jnz test_fail
    cmp qword [rel frame_surface+NEBO_SOFTWARE_SURFACE_STATE_HASH_OFFSET], 0
    je test_fail
    dec r15d
    jnz .frame_loop
    jmp test_pass

; Headless input-core latency baseline: one valid UTF-8 insert followed by one
; backspace. The buffer returns to empty after every pair.
benchmark_input_latency:
    cmp qword [rsp], 2
    jne test_usage
    lea rdi, [rel input_editor]
    mov rsi, 1
    mov rdx, 1
    lea rcx, [rel input_buffer]
    mov r8d, 64
    call nebo_text_edit_init
    test eax, eax
    jnz test_fail
    mov r15d, INPUT_EDIT_ITERATIONS
.input_loop:
    lea rdi, [rel input_editor]
    lea rsi, [rel input_byte]
    mov edx, 1
    call nebo_text_edit_insert_utf8
    test eax, eax
    jnz test_fail
    lea rdi, [rel input_editor]
    mov esi, NEBO_TEXT_EDIT_KEY_BACKSPACE
    call nebo_text_edit_key
    test eax, eax
    jnz test_fail
    dec r15d
    jnz .input_loop
    cmp qword [rel input_editor+NEBO_TEXT_EDIT_LENGTH_OFFSET], 0
    jne test_fail
    lea rdi, [rel input_editor]
    call nebo_text_edit_validate
    test eax, eax
    jnz test_fail
    jmp test_pass

; Cooperative fake-platform scaling baseline. Arg2 is 1,2,4 or 8 Consoles.
benchmark_multi_console:
    cmp qword [rsp], 3
    jne test_usage
    mov rdi, [rsp+24]
    call parse_count
    test eax, eax
    jz test_usage
    cmp eax, SCALE_MAX_CONSOLES
    ja test_usage
    mov r13d, eax
    mov edi, eax
    call setup_runtime
    test eax, eax
    jnz test_fail
    xor r14d, r14d
.scale_create:
    lea rdi, [rel context]
    lea rax, [rel handles]
    lea rsi, [rax+r14*8]
    call nebo_console_manager_anonymous_create
    test eax, eax
    jnz test_fail
    lea rdi, [rel context]
    lea rax, [rel handles]
    mov rsi, [rax+r14*8]
    lea rax, [rel domain_ptrs]
    lea rdx, [rax+r14*8]
    call nebo_console_domain_from_handle
    test eax, eax
    jnz test_fail
    inc r14d
    cmp r14d, r13d
    jb .scale_create
    mov esi, 64
    call run_scheduler
    test eax, eax
    jnz test_fail
    xor r14d, r14d
.scale_baseline:
    lea rax, [rel domain_ptrs]
    mov rbx, [rax+r14*8]
    mov rax, [rbx+NEBO_CONSOLE_DOMAIN_PROCESSED_EVENTS_OFFSET]
    lea rdx, [rel processed_baselines]
    mov [rdx+r14*8], rax
    inc r14d
    cmp r14d, r13d
    jb .scale_baseline
    mov r15d, SCALE_ITERATIONS
.scale_iteration:
    xor r14d, r14d
.scale_inject:
    lea rax, [rel domain_ptrs]
    mov rsi, [rax+r14*8]
    lea rdi, [rel platform]
    mov edx, NEBO_CONSOLE_EVENT_TIMER_TICK
    mov rcx, r15
    mov r8, r14
    call nebo_fake_platform_inject_event
    test eax, eax
    jnz test_fail
    inc r14d
    cmp r14d, r13d
    jb .scale_inject
    mov esi, 64
    call run_scheduler
    test eax, eax
    jnz test_fail
    dec r15d
    jnz .scale_iteration
    xor r14d, r14d
.scale_verify:
    lea rax, [rel domain_ptrs]
    mov rbx, [rax+r14*8]
    mov rax, [rbx+NEBO_CONSOLE_DOMAIN_PROCESSED_EVENTS_OFFSET]
    lea rdx, [rel processed_baselines]
    sub rax, [rdx+r14*8]
    cmp rax, SCALE_ITERATIONS
    jne test_fail
    inc r14d
    cmp r14d, r13d
    jb .scale_verify
    jmp test_pass

; Touch exactly the configured per-Console and per-Input storage for arg2
; Consoles (1,8,64). /usr/bin/time records the host-specific RSS baseline.
benchmark_memory_touch:
    cmp qword [rsp], 3
    jne test_usage
    mov rdi, [rsp+24]
    call parse_count
    test eax, eax
    jz test_usage
    cmp eax, MAX_CONSOLES
    ja test_usage
    mov r13, rax

    lea rdi, [rel slots]
    mov rsi, r13
    imul rsi, NEBO_CONSOLE_SLOT_SIZE
    call touch_range
    lea rdi, [rel domains]
    mov rsi, r13
    imul rsi, NEBO_CONSOLE_DOMAIN_SIZE
    call touch_range
    lea rdi, [rel command_buffers]
    mov rsi, r13
    imul rsi, QUEUE_CAPACITY*NEBO_CONSOLE_COMMAND_DESCRIPTOR_SIZE
    call touch_range
    lea rdi, [rel event_buffers]
    mov rsi, r13
    imul rsi, QUEUE_CAPACITY*NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
    call touch_range
    lea rdi, [rel memory_documents]
    mov rsi, r13
    imul rsi, NEBO_CONSOLE_DOCUMENT_SIZE
    call touch_range
    lea rdi, [rel memory_nodes]
    mov rsi, r13
    imul rsi, MEMORY_NODE_CAPACITY*NEBO_CONSOLE_NODE_HEADER_SIZE
    call touch_range
    lea rdi, [rel memory_text_store]
    mov rsi, r13
    imul rsi, MEMORY_TEXT_CAPACITY
    call touch_range
    lea rdi, [rel handles]
    mov rsi, r13
    imul rsi, 8
    call touch_range
    lea rdi, [rel domain_ptrs]
    mov rsi, r13
    imul rsi, 8
    call touch_range
    lea rdi, [rel processed_baselines]
    mov rsi, r13
    imul rsi, 8
    call touch_range

    lea rdi, [rel memory_input_registries]
    mov rsi, r13
    imul rsi, NEBO_INPUT_REGISTRY_SIZE
    call touch_range
    lea rdi, [rel memory_input_records]
    mov rsi, r13
    imul rsi, MEMORY_INPUT_CAPACITY*NEBO_INPUT_RECORD_SIZE
    call touch_range
    lea rdi, [rel memory_pending_registries]
    mov rsi, r13
    imul rsi, NEBO_PENDING_REGISTRY_SIZE
    call touch_range
    lea rdi, [rel memory_pending_records]
    mov rsi, r13
    imul rsi, MEMORY_INPUT_CAPACITY*NEBO_PENDING_RECORD_SIZE
    call touch_range
    lea rdi, [rel memory_editors]
    mov rsi, r13
    imul rsi, MEMORY_INPUT_CAPACITY*NEBO_TEXT_EDIT_RECORD_SIZE
    call touch_range
    lea rdi, [rel memory_input_text]
    mov rsi, r13
    imul rsi, MEMORY_INPUT_CAPACITY*MEMORY_INPUT_TEXT_STRIDE
    call touch_range
    jmp test_pass

; EDI=capacity.
setup_runtime:
    push r12
    mov r12d, edi
    mov [rel runtime_capacity], r12
    lea rdi, [rel context]
    lea rsi, [rel slots]
    mov edx, r12d
    mov ecx, NEBO_CONSOLE_RUNTIME_ABI_VERSION
    call nebo_console_runtime_context_init
    test eax, eax
    jnz .done
    lea rax, [rel clock]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_CLOCK_PTR_OFFSET], rax
    lea rax, [rel platform]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_PLATFORM_PTR_OFFSET], rax
    lea rax, [rel scheduler]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_SCHEDULER_PTR_OFFSET], rax
    lea rax, [rel domains]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAINS_PTR_OFFSET], rax
    lea rax, [rel command_buffers]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_COMMAND_BUFFERS_PTR_OFFSET], rax
    lea rax, [rel event_buffers]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_EVENT_BUFFERS_PTR_OFFSET], rax
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAIN_CAPACITY_OFFSET], r12
    mov qword [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_QUEUE_CAPACITY_OFFSET], QUEUE_CAPACITY
    mov qword [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_FLAGS_OFFSET], 0
    lea rdi, [rel context]
    lea rsi, [rel headless_storage]
    call nebo_console_runtime_headless_bind
.done:
    pop r12
    ret

run_scheduler:
    sub rsp, 8
    lea rdi, [rel context]
    lea rdx, [rel progress]
    call nebo_console_scheduler_run
    add rsp, 8
    ret

build_first_frame:
    push r12
    lea rdi, [rel frame_document]
    mov rsi, 0x0000000100000000
    lea rdx, [rel frame_nodes]
    mov ecx, FRAME_NODE_CAPACITY
    lea r8, [rel frame_text_store]
    mov r9d, FRAME_TEXT_CAPACITY
    call nebo_console_document_init
    test eax, eax
    jnz .done
    lea rdi, [rel frame_document]
    lea rsi, [rel frame_text]
    call nebo_console_document_append_text
    test eax, eax
    jnz .done
    lea rdi, [rel frame_provider]
    call nebo_fake_glyph_provider_init
    test eax, eax
    jnz .done
    lea rdi, [rel frame_layout]
    lea rsi, [rel frame_boxes]
    mov edx, FRAME_BOX_CAPACITY
    mov ecx, FRAME_WIDTH*NEBO_LAYOUT_ONE
    mov r8d, FRAME_HEIGHT*NEBO_LAYOUT_ONE
    lea r9, [rel frame_provider]
    call nebo_console_layout_init
    test eax, eax
    jnz .done
    lea rdi, [rel frame_layout]
    lea rsi, [rel frame_document]
    call nebo_console_layout_document
    test eax, eax
    jnz .done
    lea rdi, [rel frame_render_tree]
    lea rsi, [rel frame_render_nodes]
    mov edx, FRAME_RENDER_CAPACITY
    call nebo_console_render_tree_init
    test eax, eax
    jnz .done
    lea rdi, [rel frame_render_tree]
    lea rsi, [rel frame_layout]
    lea rdx, [rel frame_document]
    call nebo_console_render_tree_build
    test eax, eax
    jnz .done
    lea rdi, [rel frame_draw_buffer]
    lea rsi, [rel frame_draw_commands]
    mov edx, FRAME_COMMAND_CAPACITY
    lea rcx, [rel frame_document]
    call nebo_draw_command_buffer_init
    test eax, eax
    jnz .done
    lea rdi, [rel frame_draw_buffer]
    lea rsi, [rel frame_layout]
    lea rdx, [rel frame_render_tree]
    call nebo_console_draw_commands_build
    test eax, eax
    jnz .done
    lea rdi, [rel frame_surface]
    lea rsi, [rel frame_pixels]
    mov edx, FRAME_SURFACE_BYTES
    mov ecx, FRAME_WIDTH
    mov r8d, FRAME_HEIGHT
    call nebo_software_surface_init
    test eax, eax
    jnz .done
    lea rdi, [rel frame_surface]
    lea rsi, [rel frame_draw_buffer]
    lea rdx, [rel frame_provider]
    call nebo_software_surface_execute
.done:
    pop r12
    ret

; RDI=NUL-terminated count. Returns EAX=count or 0.
parse_count:
    cmp byte [rdi], '1'
    jne .not_one
    cmp byte [rdi+1], 0
    jne .invalid
    mov eax, 1
    ret
.not_one:
    cmp byte [rdi], '2'
    jne .not_two
    cmp byte [rdi+1], 0
    jne .invalid
    mov eax, 2
    ret
.not_two:
    cmp byte [rdi], '4'
    jne .not_four
    cmp byte [rdi+1], 0
    jne .invalid
    mov eax, 4
    ret
.not_four:
    cmp byte [rdi], '8'
    jne .not_eight
    cmp byte [rdi+1], 0
    jne .invalid
    mov eax, 8
    ret
.not_eight:
    cmp byte [rdi], '6'
    jne .invalid
    cmp byte [rdi+1], '4'
    jne .invalid
    cmp byte [rdi+2], 0
    jne .invalid
    mov eax, 64
    ret
.invalid:
    xor eax, eax
    ret

; RDI=begin, RSI=bytes. Touch one byte per page and the final byte.
touch_range:
    test rsi, rsi
    jz .done
    xor rax, rax
.loop:
    cmp rax, rsi
    jae .last
    mov byte [rdi+rax], 1
    add rax, 4096
    jmp .loop
.last:
    dec rsi
    mov byte [rdi+rsi], 1
.done:
    ret

test_pass:
    xor edi, edi
    jmp neboc_host_process_exit

test_fail:
    mov edi, 1
    jmp neboc_host_process_exit

test_usage:
    mov edi, 2
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
