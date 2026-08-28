; Nebo Assembly — MF044 layout/draw/software-surface scenarios
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/document/console_document.inc"
%include "runtime/console/layout/console_layout.inc"
%include "runtime/console/render/fake_glyph_provider.inc"
%include "runtime/console/render/render_tree.inc"
%include "runtime/console/render/draw_command.inc"
%include "runtime/console/render/software_surface.inc"

extern nebo_console_document_init
extern nebo_console_document_append_text
extern nebo_console_document_state_hash
extern nebo_fake_glyph_provider_init
extern nebo_console_layout_init
extern nebo_console_layout_document
extern nebo_console_flow_layout_items
extern nebo_console_render_tree_init
extern nebo_console_render_tree_build
extern nebo_draw_command_buffer_init
extern nebo_console_draw_commands_build
extern nebo_software_surface_init
extern nebo_software_surface_resize
extern nebo_software_surface_execute
extern neboc_host_process_exit

global _start

%define TEST_NODE_CAPACITY 32
%define TEST_TEXT_CAPACITY 512
%define TEST_BOX_CAPACITY 64
%define TEST_RENDER_CAPACITY 64
%define TEST_COMMAND_CAPACITY 128
%define TEST_SURFACE_WIDTH 160
%define TEST_SURFACE_HEIGHT 100
%define TEST_SURFACE_BYTES (TEST_SURFACE_WIDTH*TEST_SURFACE_HEIGHT*4)

section .rodata align=8
text_nebo_bytes: db 'Nebo'
text_wrap_bytes: db 'ABCDEFGHIJKL'
text_resize_bytes: db '0123456789'

text_nebo: dq text_nebo_bytes,4
           dd 0
           dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
text_wrap: dq text_wrap_bytes,12
           dd 0
           dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
text_resize: dq text_resize_bytes,10
             dd 0
             dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC

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
flow_items: resb 2*NEBO_LAYOUT_ITEM_SIZE
doc_hash_before: resq 1
layout_hash_before: resq 1

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
    cmp eax, 5
    ja test_fail
    cmp eax, 1
    je scenario_1
    cmp eax, 2
    je scenario_2
    cmp eax, 3
    je scenario_3
    cmp eax, 4
    je scenario_4
    jmp scenario_5

; 001 — chrome/content boxes, deterministic draw commands and BGRA surface.
scenario_1:
    lea rdi, [rel text_nebo]
    call init_document_with_text
    test eax, eax
    jnz test_fail
    mov ecx, TEST_SURFACE_WIDTH*NEBO_LAYOUT_ONE
    mov r8d, TEST_SURFACE_HEIGHT*NEBO_LAYOUT_ONE
    call init_layout_pipeline
    test eax, eax
    jnz test_fail
    cmp qword [rel layout_tree+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET], 3
    jne test_fail
    lea rbx, [rel layout_boxes]
    cmp dword [rbx+NEBO_LAYOUT_BOX_KIND_OFFSET], NEBO_LAYOUT_BOX_KIND_CHROME
    jne test_fail
    cmp qword [rbx+NEBO_LAYOUT_BOX_X_OFFSET], NEBO_LAYOUT_BORDER
    jne test_fail
    cmp qword [rbx+NEBO_LAYOUT_BOX_Y_OFFSET], NEBO_LAYOUT_BORDER
    jne test_fail
    add rbx, NEBO_LAYOUT_BOX_SIZE
    cmp dword [rbx+NEBO_LAYOUT_BOX_KIND_OFFSET], NEBO_LAYOUT_BOX_KIND_CONTENT
    jne test_fail
    cmp qword [rel draw_buffer+NEBO_DRAW_BUFFER_COUNT_OFFSET], 6
    jne test_fail
    lea rbx, [rel draw_commands]
    cmp dword [rbx+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_CLEAR
    jne test_fail
    mov eax, NEBO_COLOR_BGRA_BLACK
    cmp [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    jne test_fail
    add rbx, NEBO_DRAW_COMMAND_SIZE
    cmp dword [rbx+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_FILL_RECT
    jne test_fail
    mov eax, NEBO_COLOR_BGRA_CHROME_BACKGROUND
    cmp [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    jne test_fail
    add rbx, NEBO_DRAW_COMMAND_SIZE
    cmp dword [rbx+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_STROKE_RECT
    jne test_fail
    mov eax, NEBO_COLOR_BGRA_GREY
    cmp [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    jne test_fail
    cmp dword [rel surface_pixels], NEBO_COLOR_BGRA_GREY
    jne test_fail
    mov eax, [rel surface_pixels + (2*TEST_SURFACE_WIDTH+2)*4]
    cmp eax, NEBO_COLOR_BGRA_CHROME_BACKGROUND
    jne test_fail
    cmp qword [rel surface+NEBO_SOFTWARE_SURFACE_STATE_HASH_OFFSET], 0
    je test_fail
    jmp test_pass

; 002 — 12 glyphs wrap into 5/5/2 logical runs.
scenario_2:
    lea rdi, [rel text_wrap]
    call init_document_with_text
    test eax, eax
    jnz test_fail
    mov ecx, 66*NEBO_LAYOUT_ONE
    mov r8d, TEST_SURFACE_HEIGHT*NEBO_LAYOUT_ONE
    call init_layout_only
    test eax, eax
    jnz test_fail
    cmp qword [rel layout_tree+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET], 5
    jne test_fail
    lea rbx, [rel layout_boxes+2*NEBO_LAYOUT_BOX_SIZE]
    cmp qword [rbx+NEBO_LAYOUT_BOX_SOURCE_LENGTH_OFFSET], 5
    jne test_fail
    cmp qword [rbx+NEBO_LAYOUT_BOX_LINE_INDEX_OFFSET], 0
    jne test_fail
    test dword [rbx+NEBO_LAYOUT_BOX_FLAGS_OFFSET], NEBO_LAYOUT_BOX_FLAG_WRAPPED
    jz test_fail
    add rbx, NEBO_LAYOUT_BOX_SIZE
    cmp qword [rbx+NEBO_LAYOUT_BOX_SOURCE_LENGTH_OFFSET], 5
    jne test_fail
    cmp qword [rbx+NEBO_LAYOUT_BOX_LINE_INDEX_OFFSET], 1
    jne test_fail
    add rbx, NEBO_LAYOUT_BOX_SIZE
    cmp qword [rbx+NEBO_LAYOUT_BOX_SOURCE_LENGTH_OFFSET], 2
    jne test_fail
    cmp qword [rbx+NEBO_LAYOUT_BOX_LINE_INDEX_OFFSET], 2
    jne test_fail
    jmp test_pass

; 003 — prompt and inline input layout item share one line.
scenario_3:
    call init_provider_and_wide_layout
    test eax, eax
    jnz test_fail
    call init_flow_items
    lea rdi, [rel layout_tree]
    lea rsi, [rel flow_items]
    mov edx, 2
    call nebo_console_flow_layout_items
    test eax, eax
    jnz test_fail
    lea rbx, [rel layout_boxes+2*NEBO_LAYOUT_BOX_SIZE]
    mov rax, [rbx+NEBO_LAYOUT_BOX_Y_OFFSET]
    mov rcx, [rbx+NEBO_LAYOUT_BOX_X_OFFSET]
    add rcx, [rbx+NEBO_LAYOUT_BOX_WIDTH_OFFSET]
    add rbx, NEBO_LAYOUT_BOX_SIZE
    cmp [rbx+NEBO_LAYOUT_BOX_Y_OFFSET], rax
    jne test_fail
    cmp [rbx+NEBO_LAYOUT_BOX_X_OFFSET], rcx
    jne test_fail
    cmp dword [rbx+NEBO_LAYOUT_BOX_KIND_OFFSET], NEBO_LAYOUT_BOX_KIND_INPUT_INLINE
    jne test_fail
    jmp test_pass

; 004 — InputRow structural item starts on its own line.
scenario_4:
    call init_provider_and_wide_layout
    test eax, eax
    jnz test_fail
    call init_flow_items
    mov dword [rel flow_items+NEBO_LAYOUT_ITEM_SIZE+NEBO_LAYOUT_ITEM_KIND_OFFSET], NEBO_LAYOUT_ITEM_KIND_INPUT_ROW
    mov dword [rel flow_items+NEBO_LAYOUT_ITEM_SIZE+NEBO_LAYOUT_ITEM_FLAGS_OFFSET], NEBO_LAYOUT_ITEM_FLAG_ROW
    lea rdi, [rel layout_tree]
    lea rsi, [rel flow_items]
    mov edx, 2
    call nebo_console_flow_layout_items
    test eax, eax
    jnz test_fail
    lea rbx, [rel layout_boxes+2*NEBO_LAYOUT_BOX_SIZE]
    mov rax, [rbx+NEBO_LAYOUT_BOX_Y_OFFSET]
    add rax, NEBO_LAYOUT_LINE_HEIGHT
    add rbx, NEBO_LAYOUT_BOX_SIZE
    cmp [rbx+NEBO_LAYOUT_BOX_Y_OFFSET], rax
    jne test_fail
    mov rax, [rel layout_tree+NEBO_LAYOUT_TREE_CONTENT_X_OFFSET]
    cmp [rbx+NEBO_LAYOUT_BOX_X_OFFSET], rax
    jne test_fail
    cmp dword [rbx+NEBO_LAYOUT_BOX_KIND_OFFSET], NEBO_LAYOUT_BOX_KIND_INPUT_ROW
    jne test_fail
    jmp test_pass

; 005 — resize/reflow changes derived layout, preserves retained document state.
scenario_5:
    lea rdi, [rel text_resize]
    call init_document_with_text
    test eax, eax
    jnz test_fail
    lea rdi, [rel document]
    lea rsi, [rel doc_hash_before]
    call nebo_console_document_state_hash
    test eax, eax
    jnz test_fail
    mov ecx, TEST_SURFACE_WIDTH*NEBO_LAYOUT_ONE
    mov r8d, TEST_SURFACE_HEIGHT*NEBO_LAYOUT_ONE
    call init_layout_only
    test eax, eax
    jnz test_fail
    cmp qword [rel layout_tree+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET], 3
    jne test_fail
    mov rax, [rel layout_tree+NEBO_LAYOUT_TREE_STATE_HASH_OFFSET]
    mov [rel layout_hash_before], rax
    lea rdi, [rel surface]
    lea rsi, [rel surface_pixels]
    mov edx, TEST_SURFACE_BYTES
    mov ecx, TEST_SURFACE_WIDTH
    mov r8d, TEST_SURFACE_HEIGHT
    call nebo_software_surface_init
    test eax, eax
    jnz test_fail
    ; Reinitialize only derived layout with a narrower viewport.
    lea rdi, [rel layout_tree]
    lea rsi, [rel layout_boxes]
    mov edx, TEST_BOX_CAPACITY
    mov ecx, 66*NEBO_LAYOUT_ONE
    mov r8d, TEST_SURFACE_HEIGHT*NEBO_LAYOUT_ONE
    lea r9, [rel provider]
    call nebo_console_layout_init
    test eax, eax
    jnz test_fail
    lea rdi, [rel layout_tree]
    lea rsi, [rel document]
    call nebo_console_layout_document
    test eax, eax
    jnz test_fail
    cmp qword [rel layout_tree+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET], 4
    jne test_fail
    mov rax, [rel layout_tree+NEBO_LAYOUT_TREE_STATE_HASH_OFFSET]
    cmp rax, [rel layout_hash_before]
    je test_fail
    lea rdi, [rel document]
    lea rsi, [rel layout_hash_before]
    call nebo_console_document_state_hash
    test eax, eax
    jnz test_fail
    mov rax, [rel layout_hash_before]
    cmp rax, [rel doc_hash_before]
    jne test_fail
    lea rdi, [rel surface]
    mov esi, 66
    mov edx, TEST_SURFACE_HEIGHT
    call nebo_software_surface_resize
    test eax, eax
    jnz test_fail
    cmp qword [rel surface+NEBO_SOFTWARE_SURFACE_GENERATION_OFFSET], 2
    jne test_fail
    jmp test_pass

; RDI = TextDescriptor*. Initializes retained document containing one Text node.
init_document_with_text:
    push r12
    mov r12, rdi
    lea rdi, [rel document]
    mov rsi, 0x0000000100000000
    lea rdx, [rel nodes]
    mov ecx, TEST_NODE_CAPACITY
    lea r8, [rel text_store]
    mov r9d, TEST_TEXT_CAPACITY
    call nebo_console_document_init
    test eax, eax
    jnz .init_document_done
    lea rdi, [rel document]
    mov rsi, r12
    call nebo_console_document_append_text
.init_document_done:
    pop r12
    ret

init_provider_and_wide_layout:
    lea rdi, [rel provider]
    call nebo_fake_glyph_provider_init
    test eax, eax
    jnz .provider_layout_done
    lea rdi, [rel layout_tree]
    lea rsi, [rel layout_boxes]
    mov edx, TEST_BOX_CAPACITY
    mov ecx, TEST_SURFACE_WIDTH*NEBO_LAYOUT_ONE
    mov r8d, TEST_SURFACE_HEIGHT*NEBO_LAYOUT_ONE
    lea r9, [rel provider]
    call nebo_console_layout_init
.provider_layout_done:
    ret

; ECX width logical, R8 height logical.
init_layout_only:
    push r12
    push r13
    mov r12, rcx
    mov r13, r8
    lea rdi, [rel provider]
    call nebo_fake_glyph_provider_init
    test eax, eax
    jnz .layout_only_done
    lea rdi, [rel layout_tree]
    lea rsi, [rel layout_boxes]
    mov edx, TEST_BOX_CAPACITY
    mov rcx, r12
    mov r8, r13
    lea r9, [rel provider]
    call nebo_console_layout_init
    test eax, eax
    jnz .layout_only_done
    lea rdi, [rel layout_tree]
    lea rsi, [rel document]
    call nebo_console_layout_document
.layout_only_done:
    pop r13
    pop r12
    ret

; ECX width logical, R8 height logical. Builds full layout→render→draw→surface.
init_layout_pipeline:
    push r12
    push r13
    mov r12, rcx
    mov r13, r8
    mov rcx, r12
    mov r8, r13
    call init_layout_only
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
.pipeline_done:
    pop r13
    pop r12
    ret

init_flow_items:
    lea rdi, [rel flow_items]
    xor eax, eax
    mov ecx, 2*NEBO_LAYOUT_ITEM_QWORDS
    cld
    rep stosq
    mov dword [rel flow_items+NEBO_LAYOUT_ITEM_KIND_OFFSET], NEBO_LAYOUT_ITEM_KIND_PROMPT
    mov dword [rel flow_items+NEBO_LAYOUT_ITEM_FLAGS_OFFSET], NEBO_LAYOUT_ITEM_FLAG_INLINE
    mov qword [rel flow_items+NEBO_LAYOUT_ITEM_NODE_ID_OFFSET], 10
    mov qword [rel flow_items+NEBO_LAYOUT_ITEM_WIDTH_OFFSET], 24*NEBO_LAYOUT_ONE
    mov qword [rel flow_items+NEBO_LAYOUT_ITEM_HEIGHT_OFFSET], NEBO_LAYOUT_LINE_HEIGHT
    mov dword [rel flow_items+NEBO_LAYOUT_ITEM_SIZE+NEBO_LAYOUT_ITEM_KIND_OFFSET], NEBO_LAYOUT_ITEM_KIND_INPUT_INLINE
    mov dword [rel flow_items+NEBO_LAYOUT_ITEM_SIZE+NEBO_LAYOUT_ITEM_FLAGS_OFFSET], NEBO_LAYOUT_ITEM_FLAG_INLINE
    mov qword [rel flow_items+NEBO_LAYOUT_ITEM_SIZE+NEBO_LAYOUT_ITEM_NODE_ID_OFFSET], 11
    mov qword [rel flow_items+NEBO_LAYOUT_ITEM_SIZE+NEBO_LAYOUT_ITEM_WIDTH_OFFSET], 40*NEBO_LAYOUT_ONE
    mov qword [rel flow_items+NEBO_LAYOUT_ITEM_SIZE+NEBO_LAYOUT_ITEM_HEIGHT_OFFSET], NEBO_LAYOUT_LINE_HEIGHT
    ret

test_pass:
    xor edi, edi
    jmp neboc_host_process_exit

test_fail:
    mov edi, 1
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
