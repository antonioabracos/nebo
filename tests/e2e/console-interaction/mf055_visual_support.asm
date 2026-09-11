; Nebo Assembly — MF055 test-only readable visual support
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/document/console_document.inc"
%include "runtime/console/layout/console_layout.inc"
%include "runtime/console/input/registry/input_registry.inc"
%include "runtime/console/input/editing/text_editor.inc"
%include "runtime/console/focus/focus_manager.inc"
%include "runtime/console/render/draw_command.inc"
%include "runtime/console/render/software_surface.inc"
%include "runtime/console/render/output_conformance.inc"

extern nebo_console_visual_state_init
extern nebo_console_output_append_visual_state

; RDI=draw_buffer*, RSI=layout*, RDX=input_registry*, RCX=focus_manager*.
global mf055_append_input_visuals
; RDI=surface*, RSI=draw_buffer*.
global mf055_overlay_document_glyphs
; RDI=surface*, RSI=layout*, RDX=input_registry*, RCX=focus_manager*.
global mf055_overlay_editor_glyphs
; RDI=surface*, RSI=path*.
global mf055_write_ppm
; RDI=surface*, RSI=x, RDX=y, RCX=w, R8=h, R9D=color.
global mf055_fill_rect

%define TEST_WIDTH 640
%define TEST_HEIGHT 400
%define TEST_RGB_BYTES (TEST_WIDTH*TEST_HEIGHT*3)
%define SYS_WRITE 1
%define SYS_CLOSE 3
%define SYS_OPENAT 257
%define AT_FDCWD -100
%define O_WRONLY_CREAT_TRUNC 577
%define MODE_0644 420

section .rodata align=8
ppm_header: db 80,54,10,54,52,48,32,52,48,48,10,50,53,53,10
%define PPM_HEADER_LEN 15

; Small custom 5x7 fixture font. Unsupported bytes use '?'.
font_chars: db 32,58,63,65,66,67,77,78,80,84,97,98,99,100,101,103,105,109,110,111,114,115,117,118
%define FONT_CHAR_COUNT 24
font_rows:
    db 0,0,0,0,0,0,0                       ; space
    db 0,4,0,0,4,0,0                       ; :
    db 14,17,1,2,4,0,4                     ; ?
    db 14,17,17,31,17,17,17                ; A
    db 30,17,17,30,17,17,30                ; B
    db 14,17,16,16,16,17,14                ; C
    db 17,27,21,21,17,17,17                ; M
    db 17,25,21,19,17,17,17                ; N
    db 30,17,17,30,16,16,16                ; P
    db 31,4,4,4,4,4,4                      ; T
    db 0,0,14,1,15,17,15                   ; a
    db 16,16,30,17,17,17,30                ; b
    db 0,0,14,17,16,17,14                  ; c
    db 1,1,15,17,17,17,15                  ; d
    db 0,0,14,17,31,16,14                  ; e
    db 0,0,15,17,15,1,14                   ; g
    db 4,0,12,4,4,4,14                     ; i
    db 0,0,26,21,21,21,21                  ; m
    db 0,0,30,17,17,17,17                  ; n
    db 0,0,14,17,17,17,14                  ; o
    db 0,0,22,25,16,16,16                  ; r
    db 0,0,15,16,14,1,30                   ; s
    db 0,0,17,17,17,19,13                  ; u
    db 0,0,17,17,17,10,4                   ; v

section .bss align=64
visual_state: resb NEBO_OUTPUT_VISUAL_STATE_SIZE
geometry: resq 8
rgb_buffer: resb TEST_RGB_BYTES

section .text

; Find layout box for a document node.
; RDI=layout*, RSI=node_id, RDX=out_box**.
find_box_for_node:
    test rdi, rdi
    jz .invalid
    test rdx, rdx
    jz .invalid
    mov qword [rdx], 0
    xor ecx, ecx
.loop:
    cmp rcx, [rdi+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET]
    jae .not_found
    mov rax, rcx
    imul rax, NEBO_LAYOUT_BOX_SIZE
    add rax, [rdi+NEBO_LAYOUT_TREE_BOXES_PTR_OFFSET]
    cmp [rax+NEBO_LAYOUT_BOX_NODE_ID_OFFSET], rsi
    je .found
    inc rcx
    jmp .loop
.found:
    mov [rdx], rax
    xor eax, eax
    ret
.not_found:
    mov eax, NEBO_CONSOLE_STATUS_NO_PROGRESS
    ret
.invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

mf055_append_input_visuals:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    mov r12, rdi                         ; draw
    mov r13, rsi                         ; layout
    mov r14, rdx                         ; registry
    mov r15, rcx                         ; focus
    xor ebx, ebx
.loop:
    cmp rbx, [r14+NEBO_INPUT_REGISTRY_CAPACITY_OFFSET]
    jae .ok
    mov rax, rbx
    shl rax, 7
    add rax, [r14+NEBO_INPUT_REGISTRY_RECORDS_PTR_OFFSET]
    mov [rsp], rax                       ; record
    mov edx, [rax+NEBO_INPUT_RECORD_STATE_OFFSET]
    cmp edx, NEBO_INPUT_STATE_PENDING
    je .active
    cmp edx, NEBO_INPUT_STATE_RESOLVED
    jne .next
.active:
    mov rsi, [rax+NEBO_INPUT_RECORD_NODE_ID_OFFSET]
    mov rdi, r13
    lea rdx, [rsp+8]
    call find_box_for_node
    test eax, eax
    jnz .fail
    mov rax, rbx
    imul rax, NEBO_TEXT_EDIT_RECORD_SIZE
    add rax, [r15+NEBO_FOCUS_MANAGER_EDITORS_PTR_OFFSET]
    mov [rsp+16], rax                    ; editor
    mov rbp, [rsp+8]                     ; box
    mov rax, [rbp+NEBO_LAYOUT_BOX_X_OFFSET]
    add rax, 4*NEBO_LAYOUT_ONE
    mov rdx, [rsp+16]
    mov rdx, [rdx+NEBO_TEXT_EDIT_CARET_OFFSET]
    imul rdx, 8*NEBO_LAYOUT_ONE
    add rax, rdx
    mov [rel geometry], rax
    mov rax, [rbp+NEBO_LAYOUT_BOX_Y_OFFSET]
    add rax, 4*NEBO_LAYOUT_ONE
    mov [rel geometry+8], rax
    mov qword [rel geometry+16], NEBO_LAYOUT_ONE
    mov qword [rel geometry+24], 16*NEBO_LAYOUT_ONE
    mov rax, [rbp+NEBO_LAYOUT_BOX_X_OFFSET]
    mov [rel geometry+32], rax
    mov rax, [rbp+NEBO_LAYOUT_BOX_Y_OFFSET]
    mov [rel geometry+40], rax
    mov rax, [rbp+NEBO_LAYOUT_BOX_WIDTH_OFFSET]
    mov [rel geometry+48], rax
    mov rax, [rbp+NEBO_LAYOUT_BOX_HEIGHT_OFFSET]
    mov [rel geometry+56], rax
    mov esi, NEBO_OUTPUT_VISUAL_FLAG_INITIALIZED | NEBO_OUTPUT_VISUAL_FLAG_INPUT_PRESENT
    mov rax, [rsp]
    mov rdx, [rax+NEBO_INPUT_RECORD_HANDLE_OFFSET]
    cmp rdx, [r15+NEBO_FOCUS_MANAGER_FOCUSED_HANDLE_OFFSET]
    jne .not_focused
    or esi, NEBO_OUTPUT_VISUAL_FLAG_FOCUSED
.not_focused:
    cmp dword [rax+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_RESOLVED
    jne .flags_ready
    or esi, NEBO_OUTPUT_VISUAL_FLAG_INPUT_RESOLVED
.flags_ready:
    mov rdx, [rax+NEBO_INPUT_RECORD_NODE_ID_OFFSET]
    mov rcx, rdx
    lea rdi, [rel visual_state]
    lea r8, [rel geometry]
    call nebo_console_visual_state_init
    test eax, eax
    jnz .fail
    mov rdi, r12
    lea rsi, [rel visual_state]
    call nebo_console_output_append_visual_state
    test eax, eax
    jnz .fail
.next:
    inc rbx
    jmp .loop
.ok:
    xor eax, eax
    jmp .done
.fail:
    mov eax, -1
.done:
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; RDI=surface*, RSI=x, RDX=y, ECX=color.
put_pixel:
    test rdi, rdi
    jz .fail
    cmp rsi, [rdi+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET]
    jae .ok
    cmp rdx, [rdi+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET]
    jae .ok
    mov rax, rdx
    imul rax, [rdi+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET]
    lea rax, [rax+rsi*4]
    add rax, [rdi+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET]
    mov [rax], ecx
.ok:
    xor eax, eax
    ret
.fail:
    mov eax, -1
    ret

mf055_fill_rect:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov rbx, r8
    mov [rsp], r9d
    xor r10d, r10d
.row:
    cmp r10, rbx
    jae .ok
    xor r11d, r11d
.col:
    cmp r11, r15
    jae .next_row
    mov rdi, r12
    lea rsi, [r13+r11]
    lea rdx, [r14+r10]
    mov ecx, [rsp]
    call put_pixel
    test eax, eax
    jnz .fail
    inc r11
    jmp .col
.next_row:
    inc r10
    jmp .row
.ok:
    xor eax, eax
    jmp .done
.fail:
    mov eax, -1
.done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; EDI=byte, RSI=x, RDX=y, ECX=color, R8=surface*.
draw_glyph:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12d, edi
    mov r13, rsi
    mov r14, rdx
    mov r15d, ecx
    mov [rsp], r8
    xor ebx, ebx
.find:
    cmp ebx, FONT_CHAR_COUNT
    jae .fallback
    lea rax, [rel font_chars]
    movzx eax, byte [rax+rbx]
    cmp eax, r12d
    je .found
    inc ebx
    jmp .find
.fallback:
    mov ebx, 2
.found:
    imul rbx, 7
    xor r10d, r10d
.row:
    cmp r10d, 7
    jae .ok
    lea rax, [rel font_rows]
    add rax, rbx
    movzx r11d, byte [rax+r10]
    xor r9d, r9d
.col:
    cmp r9d, 5
    jae .next_row
    mov eax, 4
    sub eax, r9d
    mov edx, 1
    mov ecx, eax
    shl edx, cl
    test r11d, edx
    jz .next_col
    mov rdi, [rsp]
    lea rsi, [r13+r9]
    lea rdx, [r14+r10]
    mov ecx, r15d
    call put_pixel
    test eax, eax
    jnz .fail
.next_col:
    inc r9d
    jmp .col
.next_row:
    inc r10d
    jmp .row
.ok:
    xor eax, eax
    jmp .done
.fail:
    mov eax, -1
.done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

mf055_overlay_document_glyphs:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 56
    mov r12, rdi                         ; surface
    mov r13, rsi                         ; draw
    xor r14d, r14d
.loop:
    cmp r14, [r13+NEBO_DRAW_BUFFER_COUNT_OFFSET]
    jae .ok
    mov rax, r14
    imul rax, NEBO_DRAW_COMMAND_SIZE
    add rax, [r13+NEBO_DRAW_BUFFER_COMMANDS_PTR_OFFSET]
    mov rbx, rax
    cmp dword [rbx+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_DRAW_GLYPH_RUN
    jne .next
    mov rax, [rbx+NEBO_DRAW_COMMAND_SOURCE_LENGTH_OFFSET]
    test rax, rax
    jz .next
    mov [rsp], rax
    mov rax, [r13+NEBO_DRAW_BUFFER_DOCUMENT_PTR_OFFSET]
    test rax, rax
    jz .fail
    mov r15, [rax+NEBO_CONSOLE_DOCUMENT_TEXT_STORE_PTR_OFFSET]
    add r15, [rbx+NEBO_DRAW_COMMAND_SOURCE_OFFSET_OFFSET]
    mov rax, [rbx+NEBO_DRAW_COMMAND_X_OFFSET]
    sar rax, NEBO_LAYOUT_FRACTION_BITS
    mov [rsp+8], rax
    mov rax, [rbx+NEBO_DRAW_COMMAND_Y_OFFSET]
    sar rax, NEBO_LAYOUT_FRACTION_BITS
    mov [rsp+16], rax
    mov rax, [rbx+NEBO_DRAW_COMMAND_WIDTH_OFFSET]
    sar rax, NEBO_LAYOUT_FRACTION_BITS
    mov [rsp+24], rax
    mov rax, [rbx+NEBO_DRAW_COMMAND_HEIGHT_OFFSET]
    sar rax, NEBO_LAYOUT_FRACTION_BITS
    mov [rsp+32], rax
    mov rdi, r12
    mov rsi, [rsp+8]
    mov rdx, [rsp+16]
    mov rcx, [rsp+24]
    mov r8, [rsp+32]
    mov r9d, NEBO_COLOR_BGRA_BLACK
    call mf055_fill_rect
    test eax, eax
    jnz .fail
    xor r10d, r10d
.glyph_loop:
    cmp r10, [rsp]
    jae .next
    movzx edi, byte [r15+r10]
    mov rsi, [rsp+8]
    mov rax, r10
    imul rax, 8
    add rsi, rax
    mov rdx, [rsp+16]
    add rdx, 4
    mov ecx, [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET]
    mov [rsp+40], r10
    mov r8, r12
    call draw_glyph
    mov r10, [rsp+40]
    test eax, eax
    jnz .fail
    inc r10
    jmp .glyph_loop
.next:
    inc r14
    jmp .loop
.ok:
    xor eax, eax
    jmp .done
.fail:
    mov eax, -1
.done:
    add rsp, 56
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

mf055_overlay_editor_glyphs:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    mov r12, rdi                         ; surface
    mov r13, rsi                         ; layout
    mov r14, rdx                         ; registry
    mov r15, rcx                         ; focus
    xor ebx, ebx
.loop:
    cmp rbx, [r14+NEBO_INPUT_REGISTRY_CAPACITY_OFFSET]
    jae .ok
    mov rax, rbx
    shl rax, 7
    add rax, [r14+NEBO_INPUT_REGISTRY_RECORDS_PTR_OFFSET]
    mov [rsp], rax
    mov edx, [rax+NEBO_INPUT_RECORD_STATE_OFFSET]
    cmp edx, NEBO_INPUT_STATE_PENDING
    je .active
    cmp edx, NEBO_INPUT_STATE_RESOLVED
    jne .next
.active:
    mov rsi, [rax+NEBO_INPUT_RECORD_NODE_ID_OFFSET]
    mov rdi, r13
    lea rdx, [rsp+8]
    call find_box_for_node
    test eax, eax
    jnz .fail
    mov rax, rbx
    imul rax, NEBO_TEXT_EDIT_RECORD_SIZE
    add rax, [r15+NEBO_FOCUS_MANAGER_EDITORS_PTR_OFFSET]
    mov rbp, rax
    mov rax, [rbp+NEBO_TEXT_EDIT_LENGTH_OFFSET]
    mov [rsp+16], rax
    test rax, rax
    jz .next
    mov rax, [rsp+8]
    mov rdx, [rax+NEBO_LAYOUT_BOX_X_OFFSET]
    sar rdx, NEBO_LAYOUT_FRACTION_BITS
    add rdx, 4
    mov [rsp+24], rdx
    mov rdx, [rax+NEBO_LAYOUT_BOX_Y_OFFSET]
    sar rdx, NEBO_LAYOUT_FRACTION_BITS
    add rdx, 4
    mov [rsp+32], rdx
    xor r10d, r10d
.glyph_loop:
    cmp r10, [rsp+16]
    jae .next
    mov rax, [rbp+NEBO_TEXT_EDIT_BUFFER_PTR_OFFSET]
    movzx edi, byte [rax+r10]
    mov rsi, [rsp+24]
    mov rax, r10
    imul rax, 8
    add rsi, rax
    mov rdx, [rsp+32]
    mov ecx, NEBO_COLOR_BGRA_WHITE
    mov [rsp], r10
    mov r8, r12
    call draw_glyph
    mov r10, [rsp]
    test eax, eax
    jnz .fail
    inc r10
    jmp .glyph_loop
.next:
    inc rbx
    jmp .loop
.ok:
    xor eax, eax
    jmp .done
.fail:
    mov eax, -1
.done:
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

write_all:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    mov rbx, rdx
.loop:
    test rbx, rbx
    jz .ok
    mov eax, SYS_WRITE
    mov rdi, r12
    mov rsi, r13
    mov rdx, rbx
    syscall
    test rax, rax
    jle .fail
    add r13, rax
    sub rbx, rax
    jmp .loop
.ok:
    xor eax, eax
    jmp .done
.fail:
    mov eax, -1
.done:
    pop r13
    pop r12
    pop rbx
    ret

mf055_write_ppm:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .fail
    test r13, r13
    jz .fail
    mov r14, [r12+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET]
    lea r15, [rel rgb_buffer]
    xor rcx, rcx
.convert:
    cmp rcx, TEST_WIDTH*TEST_HEIGHT
    jae .open
    mov eax, [r14+rcx*4]
    lea r8, [rcx+rcx*2]
    mov edx, eax
    shr edx, 16
    mov [r15+r8], dl
    mov edx, eax
    shr edx, 8
    mov [r15+r8+1], dl
    mov [r15+r8+2], al
    inc rcx
    jmp .convert
.open:
    mov eax, SYS_OPENAT
    mov rdi, AT_FDCWD
    mov rsi, r13
    mov edx, O_WRONLY_CREAT_TRUNC
    mov r10d, MODE_0644
    syscall
    test rax, rax
    js .fail
    mov rbx, rax
    mov rdi, rbx
    lea rsi, [rel ppm_header]
    mov edx, PPM_HEADER_LEN
    call write_all
    test eax, eax
    jnz .close_fail
    mov rdi, rbx
    lea rsi, [rel rgb_buffer]
    mov edx, TEST_RGB_BYTES
    call write_all
    test eax, eax
    jnz .close_fail
    mov eax, SYS_CLOSE
    mov rdi, rbx
    syscall
    test rax, rax
    js .fail
    xor eax, eax
    jmp .done
.close_fail:
    mov eax, SYS_CLOSE
    mov rdi, rbx
    syscall
.fail:
    mov eax, -1
.done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
