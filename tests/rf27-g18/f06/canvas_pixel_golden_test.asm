bits 64
default rel
%include "runtime/canvas/canvas.inc"

section .data align=8
paint_line:   dd 0xffcc00ff, NEBO_CANVAS_PAINT_MODE_STROKE, 1, 0
paint_rect_f: dd 0x2060ffff, NEBO_CANVAS_PAINT_MODE_FILL,   1, 0
paint_white:  dd 0xffffffff, NEBO_CANVAS_PAINT_MODE_STROKE, 1, 0
paint_circle_f: dd 0xe04080ff, NEBO_CANVAS_PAINT_MODE_FILL, 1, 0
paint_circle_s: dd 0x40ff80ff, NEBO_CANVAS_PAINT_MODE_STROKE, 1, 0
paint_text:   dd 0xffffffff, NEBO_CANVAS_PAINT_MODE_FILL, 1, 0
golden_text: db 'NEBO'

section .bss align=16
golden_canvas: resb NEBO_CANVAS_SIZE
golden_pixels: resb 32*24*4
golden_commands: resb NEBO_CANVAS_COMMAND_SIZE*16
golden_rgba: resb 32*24*4

section .text
global _start
_start:
    lea rdi,[rel golden_canvas]
    lea rsi,[rel golden_pixels]
    mov edx,32*24*4
    mov ecx,32
    mov r8d,24
    lea r9,[rel golden_commands]
    sub rsp,16
    mov qword [rsp],16
    call nebo_canvas_create
    add rsp,16
    test eax,eax
    jne .fail

    lea rdi,[rel golden_canvas]
    mov esi,0x102030ff
    call nebo_canvas_clear
    test eax,eax
    jne .fail

    lea rdi,[rel golden_canvas]
    mov rsi,-4
    xor edx,edx
    mov ecx,31
    mov r8d,23
    lea r9,[rel paint_line]
    call nebo_canvas_line
    test eax,eax
    jne .fail

    lea rdi,[rel golden_canvas]
    mov esi,2
    mov edx,3
    mov ecx,10
    mov r8d,6
    lea r9,[rel paint_rect_f]
    call nebo_canvas_rectangle
    test eax,eax
    jne .fail

    lea rdi,[rel golden_canvas]
    mov esi,18
    mov edx,2
    mov ecx,13
    mov r8d,9
    lea r9,[rel paint_white]
    call nebo_canvas_rectangle
    test eax,eax
    jne .fail

    lea rdi,[rel golden_canvas]
    mov esi,8
    mov edx,17
    mov ecx,5
    lea r8,[rel paint_circle_f]
    call nebo_canvas_circle
    test eax,eax
    jne .fail

    lea rdi,[rel golden_canvas]
    mov esi,23
    mov edx,17
    mov ecx,5
    lea r8,[rel paint_circle_s]
    call nebo_canvas_circle
    test eax,eax
    jne .fail

    lea rdi,[rel golden_canvas]
    lea rsi,[rel golden_text]
    mov edx,4
    mov ecx,4
    mov r8d,8
    lea r9,[rel paint_text]
    call nebo_canvas_text
    test eax,eax
    jne .fail

    cmp qword [rel golden_canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],7
    jne .fail
    lea rdi,[rel golden_canvas]
    lea rsi,[rel golden_rgba]
    mov edx,32*24*4
    call nebo_canvas_export_rgba
    test eax,eax
    jne .fail

    mov eax,1
    mov edi,1
    lea rsi,[rel golden_rgba]
    mov edx,32*24*4
    syscall
    cmp rax,32*24*4
    jne .fail
    xor edi,edi
    jmp .exit
.fail:
    mov edi,1
.exit:
    mov eax,60
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
