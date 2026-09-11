; Nebo Assembly — MF045 headless output conformance scenarios
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/document/console_document.inc"
%include "runtime/console/layout/console_layout.inc"
%include "runtime/console/behavior/console_behavior.inc"
%include "runtime/console/renderer-registry/renderer_registry.inc"
%include "runtime/console/render/fake_glyph_provider.inc"
%include "runtime/console/render/render_tree.inc"
%include "runtime/console/render/draw_command.inc"
%include "runtime/console/render/software_surface.inc"
%include "runtime/console/render/output_conformance.inc"

extern nebo_console_document_init
extern nebo_console_document_append_text
extern nebo_console_document_append_int
extern nebo_console_document_append_bool
extern nebo_console_document_set_behavior_set
extern nebo_console_behavior_set_build
extern nebo_console_behavior_store_init
extern nebo_console_behavior_store_register
extern nebo_console_renderer_registry_init
extern nebo_console_renderer_registry_lookup
extern nebo_fake_glyph_provider_init
extern nebo_console_layout_init
extern nebo_console_layout_document
extern nebo_console_render_tree_init
extern nebo_console_render_tree_build
extern nebo_console_output_apply_styles
extern nebo_draw_command_buffer_init
extern nebo_console_draw_commands_build
extern nebo_console_output_append_chrome_controls
extern nebo_console_visual_state_init
extern nebo_console_output_append_visual_state
extern nebo_software_surface_init
extern nebo_software_surface_execute
extern nebo_console_output_state_hash
extern neboc_host_process_exit

global _start

%define TEST_NODE_CAPACITY 32
%define TEST_TEXT_CAPACITY 512
%define TEST_BOX_CAPACITY 64
%define TEST_RENDER_CAPACITY 64
%define TEST_COMMAND_CAPACITY 128
%define TEST_BEHAVIOR_CAPACITY 4
%define TEST_RENDERER_CAPACITY 4
%define TEST_SURFACE_WIDTH 192
%define TEST_SURFACE_HEIGHT 112
%define TEST_SURFACE_BYTES (TEST_SURFACE_WIDTH*TEST_SURFACE_HEIGHT*4)

section .rodata align=8
text_a_bytes: db 'A'
text_a: dq text_a_bytes,1
        dd 0
        dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC

red_descriptor:
    dd NEBO_BEHAVIOR_KIND_FOREGROUND_COLOR
    dd NEBO_BEHAVIOR_VERSION_V0
    dq NEBO_COLOR_ID_RED

section .data align=8
visual_geometry:
    dq 40*NEBO_LAYOUT_ONE, 54*NEBO_LAYOUT_ONE
    dq 1*NEBO_LAYOUT_ONE, 14*NEBO_LAYOUT_ONE
    dq 32*NEBO_LAYOUT_ONE, 50*NEBO_LAYOUT_ONE
    dq 80*NEBO_LAYOUT_ONE, 18*NEBO_LAYOUT_ONE

section .bss align=64
document: resb NEBO_CONSOLE_DOCUMENT_SIZE
nodes: resb TEST_NODE_CAPACITY*NEBO_CONSOLE_NODE_HEADER_SIZE
text_store: resb TEST_TEXT_CAPACITY
provider: resb NEBO_FAKE_GLYPH_PROVIDER_SIZE
layout_tree: resb NEBO_LAYOUT_TREE_SIZE
layout_boxes: resb TEST_BOX_CAPACITY*NEBO_LAYOUT_BOX_SIZE
render_tree: resb NEBO_RENDER_TREE_SIZE
render_nodes: resb TEST_RENDER_CAPACITY*NEBO_RENDER_NODE_SIZE
draw_buffer: resb NEBO_DRAW_BUFFER_SIZE
draw_commands: resb TEST_COMMAND_CAPACITY*NEBO_DRAW_COMMAND_SIZE
surface: resb NEBO_SOFTWARE_SURFACE_SIZE
surface_pixels: resb TEST_SURFACE_BYTES
behavior_set_temp: resb NEBO_BEHAVIOR_SET_SIZE
behavior_sets: resb TEST_BEHAVIOR_CAPACITY*NEBO_BEHAVIOR_SET_SIZE
behavior_store: resb NEBO_BEHAVIOR_STORE_SIZE
renderer_registry: resb NEBO_RENDERER_REGISTRY_SIZE
renderer_entries: resb TEST_RENDERER_CAPACITY*NEBO_RENDERER_ENTRY_SIZE
visual_state: resb NEBO_OUTPUT_VISUAL_STATE_SIZE
output_hash_a: resq 1
output_hash_b: resq 1

section .text
_start:
    mov rax, [rsp]
    cmp rax, 2
    jne test_fail
    mov rbx, [rsp+16]
    cmp byte [rbx+1], 0
    jne test_fail
    movzx eax, byte [rbx]
    sub eax, '0'
    cmp eax, 1
    jb test_fail
    cmp eax, 8
    ja test_fail
    cmp eax, 1
    je scenario_1
    cmp eax, 2
    je scenario_2
    cmp eax, 3
    je scenario_3
    cmp eax, 4
    je scenario_4
    cmp eax, 5
    je scenario_5
    cmp eax, 6
    je scenario_6
    cmp eax, 7
    je scenario_7
    jmp scenario_8

; 006 — canonical output starts with CLEAR black.
scenario_1:
    mov esi, NEBO_OUTPUT_VISUAL_FLAG_INITIALIZED
    call init_conformant_pipeline
    test eax, eax
    jnz test_fail
    lea rbx, [rel draw_commands]
    cmp dword [rbx+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_CLEAR
    jne test_fail
    mov eax, NEBO_COLOR_BGRA_BLACK
    cmp [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    jne test_fail
    cmp dword [rel surface_pixels + (100*TEST_SURFACE_WIDTH+100)*4], NEBO_COLOR_BGRA_BLACK
    jne test_fail
    jmp test_pass

; 007 — whole Console border remains deterministic grey.
scenario_2:
    mov esi, NEBO_OUTPUT_VISUAL_FLAG_INITIALIZED
    call init_conformant_pipeline
    test eax, eax
    jnz test_fail
    lea rbx, [rel draw_commands+2*NEBO_DRAW_COMMAND_SIZE]
    cmp dword [rbx+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_STROKE_RECT
    jne test_fail
    mov eax, NEBO_COLOR_BGRA_GREY
    cmp [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    jne test_fail
    cmp dword [rel surface_pixels], NEBO_COLOR_BGRA_GREY
    jne test_fail
    jmp test_pass

; 008 — headless chrome contains exactly three deterministic controls.
scenario_3:
    mov esi, NEBO_OUTPUT_VISUAL_FLAG_INITIALIZED
    call init_conformant_pipeline
    test eax, eax
    jnz test_fail
    cmp qword [rel draw_buffer+NEBO_DRAW_BUFFER_COUNT_OFFSET], 11
    jne test_fail
    lea rbx, [rel draw_commands+8*NEBO_DRAW_COMMAND_SIZE]
    mov ecx, 3
.controls_check:
    cmp dword [rbx+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_STROKE_RECT
    jne test_fail
    mov eax, NEBO_COLOR_BGRA_CHROME_FOREGROUND
    cmp [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    jne test_fail
    add rbx, NEBO_DRAW_COMMAND_SIZE
    dec ecx
    jnz .controls_check
    jmp test_pass

; 009 — RED.color applies only to the selected Int receiver node.
scenario_4:
    mov esi, NEBO_OUTPUT_VISUAL_FLAG_INITIALIZED
    call init_conformant_pipeline
    test eax, eax
    jnz test_fail
    lea rbx, [rel render_nodes]
    mov eax, NEBO_COLOR_BGRA_WHITE
    cmp [rbx+NEBO_RENDER_NODE_FOREGROUND_OFFSET], rax
    jne test_fail
    add rbx, NEBO_RENDER_NODE_SIZE
    mov eax, NEBO_COLOR_BGRA_RED
    cmp [rbx+NEBO_RENDER_NODE_FOREGROUND_OFFSET], rax
    jne test_fail
    add rbx, NEBO_RENDER_NODE_SIZE
    mov eax, NEBO_COLOR_BGRA_WHITE
    cmp [rbx+NEBO_RENDER_NODE_FOREGROUND_OFFSET], rax
    jne test_fail
    ; Glyph commands start at order 4 and preserve receiver-local colors.
    lea rbx, [rel draw_commands+4*NEBO_DRAW_COMMAND_SIZE]
    mov eax, NEBO_COLOR_BGRA_WHITE
    cmp [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    jne test_fail
    add rbx, NEBO_DRAW_COMMAND_SIZE
    mov eax, NEBO_COLOR_BGRA_RED
    cmp [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    jne test_fail
    add rbx, NEBO_DRAW_COMMAND_SIZE
    mov eax, NEBO_COLOR_BGRA_WHITE
    cmp [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    jne test_fail
    jmp test_pass

; 010 — missing renderer returns a controlled registry diagnostic.
scenario_5:
    mov esi, NEBO_OUTPUT_VISUAL_FLAG_INITIALIZED
    call init_conformant_pipeline
    test eax, eax
    jnz test_fail
    lea rax, [rel nodes+NEBO_CONSOLE_NODE_HEADER_SIZE]
    mov dword [rax+NEBO_CONSOLE_NODE_KIND_OFFSET], 99
    lea rdi, [rel renderer_registry]
    mov esi, 99
    lea rdx, [rel output_hash_a]
    call nebo_console_renderer_registry_lookup
    cmp eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jne test_fail
    cmp qword [rel renderer_registry+NEBO_RENDERER_REGISTRY_LAST_ERROR_OFFSET], NEBO_RENDERER_ERROR_MISSING
    jne test_fail
    cmp qword [rel renderer_registry+NEBO_RENDERER_REGISTRY_MISSING_TYPE_OFFSET], 99
    jne test_fail
    lea rdi, [rel render_tree]
    lea rsi, [rel document]
    lea rdx, [rel renderer_registry]
    lea rcx, [rel behavior_store]
    call nebo_console_output_apply_styles
    cmp eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jne test_fail
    jmp test_pass

; 011 — pre-resolved focused input emits a deterministic caret command.
scenario_6:
    mov esi, NEBO_OUTPUT_VISUAL_FLAG_INITIALIZED | NEBO_OUTPUT_VISUAL_FLAG_INPUT_PRESENT | NEBO_OUTPUT_VISUAL_FLAG_FOCUSED
    call init_conformant_pipeline
    test eax, eax
    jnz test_fail
    cmp qword [rel draw_buffer+NEBO_DRAW_BUFFER_COUNT_OFFSET], 14
    jne test_fail
    lea rbx, [rel draw_commands+13*NEBO_DRAW_COMMAND_SIZE]
    cmp dword [rbx+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_DRAW_CARET
    jne test_fail
    mov eax, NEBO_COLOR_BGRA_CARET
    cmp [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    jne test_fail
    cmp qword [rbx+NEBO_DRAW_COMMAND_NODE_ID_OFFSET], 77
    jne test_fail
    jmp test_pass

; 012 — resolved input keeps visual box but removes caret/focus output.
scenario_7:
    mov esi, NEBO_OUTPUT_VISUAL_FLAG_INITIALIZED | NEBO_OUTPUT_VISUAL_FLAG_INPUT_PRESENT | NEBO_OUTPUT_VISUAL_FLAG_INPUT_RESOLVED
    call init_conformant_pipeline
    test eax, eax
    jnz test_fail
    cmp qword [rel draw_buffer+NEBO_DRAW_BUFFER_COUNT_OFFSET], 13
    jne test_fail
    lea rbx, [rel draw_commands+12*NEBO_DRAW_COMMAND_SIZE]
    cmp dword [rbx+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_STROKE_RECT
    jne test_fail
    mov eax, NEBO_COLOR_BGRA_INPUT_BORDER
    cmp [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    jne test_fail
    test qword [rel visual_state+NEBO_OUTPUT_VISUAL_FLAGS_OFFSET], NEBO_OUTPUT_VISUAL_FLAG_INPUT_RESOLVED
    jz test_fail
    jmp test_pass

; 013 — same fake font/surface state yields the same combined output hash.
scenario_8:
    mov esi, NEBO_OUTPUT_VISUAL_FLAG_INITIALIZED | NEBO_OUTPUT_VISUAL_FLAG_INPUT_PRESENT | NEBO_OUTPUT_VISUAL_FLAG_FOCUSED
    call init_conformant_pipeline
    test eax, eax
    jnz test_fail
    mov rax, [rel output_hash_a]
    mov [rel output_hash_b], rax
    mov esi, NEBO_OUTPUT_VISUAL_FLAG_INITIALIZED | NEBO_OUTPUT_VISUAL_FLAG_INPUT_PRESENT | NEBO_OUTPUT_VISUAL_FLAG_FOCUSED
    call init_conformant_pipeline
    test eax, eax
    jnz test_fail
    mov rax, [rel output_hash_a]
    cmp rax, [rel output_hash_b]
    jne test_fail
    test rax, rax
    jz test_fail
    jmp test_pass

; ESI visual flags. Builds document -> layout -> render/style -> draw -> surface.
init_conformant_pipeline:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12d, esi

    lea rdi, [rel document]
    mov rsi, 0x0000000100000000
    lea rdx, [rel nodes]
    mov ecx, TEST_NODE_CAPACITY
    lea r8, [rel text_store]
    mov r9d, TEST_TEXT_CAPACITY
    call nebo_console_document_init
    test eax, eax
    jnz .pipeline_done
    lea rdi, [rel document]
    lea rsi, [rel text_a]
    call nebo_console_document_append_text
    test eax, eax
    jnz .pipeline_done
    lea rdi, [rel document]
    mov esi, 42
    call nebo_console_document_append_int
    test eax, eax
    jnz .pipeline_done
    lea rdi, [rel document]
    mov esi, 1
    call nebo_console_document_append_bool
    test eax, eax
    jnz .pipeline_done

    lea rdi, [rel behavior_set_temp]
    mov esi, 1
    lea rdx, [rel red_descriptor]
    mov ecx, 1
    call nebo_console_behavior_set_build
    test eax, eax
    jnz .pipeline_done
    lea rdi, [rel behavior_store]
    lea rsi, [rel behavior_sets]
    mov edx, TEST_BEHAVIOR_CAPACITY
    call nebo_console_behavior_store_init
    test eax, eax
    jnz .pipeline_done
    lea rdi, [rel behavior_store]
    lea rsi, [rel behavior_set_temp]
    call nebo_console_behavior_store_register
    test eax, eax
    jnz .pipeline_done
    lea rdi, [rel document]
    mov esi, 3
    mov edx, 1
    call nebo_console_document_set_behavior_set
    test eax, eax
    jnz .pipeline_done

    lea rdi, [rel provider]
    call nebo_fake_glyph_provider_init
    test eax, eax
    jnz .pipeline_done
    lea rdi, [rel layout_tree]
    lea rsi, [rel layout_boxes]
    mov edx, TEST_BOX_CAPACITY
    mov ecx, TEST_SURFACE_WIDTH*NEBO_LAYOUT_ONE
    mov r8d, TEST_SURFACE_HEIGHT*NEBO_LAYOUT_ONE
    lea r9, [rel provider]
    call nebo_console_layout_init
    test eax, eax
    jnz .pipeline_done
    lea rdi, [rel layout_tree]
    lea rsi, [rel document]
    call nebo_console_layout_document
    test eax, eax
    jnz .pipeline_done

    lea rdi, [rel render_tree]
    lea rsi, [rel render_nodes]
    mov edx, TEST_RENDER_CAPACITY
    call nebo_console_render_tree_init
    test eax, eax
    jnz .pipeline_done
    lea rdi, [rel render_tree]
    lea rsi, [rel layout_tree]
    lea rdx, [rel document]
    call nebo_console_render_tree_build
    test eax, eax
    jnz .pipeline_done

    lea rdi, [rel renderer_registry]
    lea rsi, [rel renderer_entries]
    mov edx, TEST_RENDERER_CAPACITY
    call nebo_console_renderer_registry_init
    test eax, eax
    jnz .pipeline_done
    lea rdi, [rel render_tree]
    lea rsi, [rel document]
    lea rdx, [rel renderer_registry]
    lea rcx, [rel behavior_store]
    call nebo_console_output_apply_styles
    test eax, eax
    jnz .pipeline_done

    lea rdi, [rel draw_buffer]
    lea rsi, [rel draw_commands]
    mov edx, TEST_COMMAND_CAPACITY
    lea rcx, [rel document]
    call nebo_draw_command_buffer_init
    test eax, eax
    jnz .pipeline_done
    lea rdi, [rel draw_buffer]
    lea rsi, [rel layout_tree]
    lea rdx, [rel render_tree]
    call nebo_console_draw_commands_build
    test eax, eax
    jnz .pipeline_done
    lea rdi, [rel draw_buffer]
    lea rsi, [rel layout_tree]
    call nebo_console_output_append_chrome_controls
    test eax, eax
    jnz .pipeline_done

    lea rdi, [rel visual_state]
    mov esi, r12d
    mov edx, 77
    mov ecx, 77
    lea r8, [rel visual_geometry]
    call nebo_console_visual_state_init
    test eax, eax
    jnz .pipeline_done
    lea rdi, [rel draw_buffer]
    lea rsi, [rel visual_state]
    call nebo_console_output_append_visual_state
    test eax, eax
    jnz .pipeline_done

    lea rdi, [rel surface]
    lea rsi, [rel surface_pixels]
    mov edx, TEST_SURFACE_BYTES
    mov ecx, TEST_SURFACE_WIDTH
    mov r8d, TEST_SURFACE_HEIGHT
    call nebo_software_surface_init
    test eax, eax
    jnz .pipeline_done
    lea rdi, [rel surface]
    lea rsi, [rel draw_buffer]
    lea rdx, [rel provider]
    call nebo_software_surface_execute
    test eax, eax
    jnz .pipeline_done

    lea rdi, [rel draw_buffer]
    mov rsi, [rel surface+NEBO_SOFTWARE_SURFACE_STATE_HASH_OFFSET]
    mov rdx, [rel visual_state+NEBO_OUTPUT_VISUAL_STATE_HASH_OFFSET]
    lea rcx, [rel output_hash_a]
    call nebo_console_output_state_hash
.pipeline_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

test_pass:
    xor edi, edi
    jmp neboc_host_process_exit

test_fail:
    mov edi, 1
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
