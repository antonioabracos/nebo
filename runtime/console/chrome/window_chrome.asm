; Nebo custom window chrome render and hit-test — MF052
bits 64
default rel

%include "runtime/console/chrome/window_chrome.inc"

global nebo_console_chrome_hit_test
global nebo_console_chrome_action_for_region
global nebo_console_chrome_render

section .text

; Internal fill rectangle.
; RDI=buffer, RSI=stride, RDX=x, RCX=y, R8=width, R9=height, R10D=color.
chrome_fill_rect_internal:
    test r8, r8
    jz .fill_done
    test r9, r9
    jz .fill_done
    mov rax, rcx
    imul rax, rsi
    lea rax, [rax+rdx*4]
    add rax, rdi
    xor r11d, r11d
.fill_row:
    push rax
    mov rcx, r8
.fill_pixel:
    mov [rax], r10d
    add rax, 4
    dec rcx
    jnz .fill_pixel
    pop rax
    add rax, rsi
    inc r11
    cmp r11, r9
    jb .fill_row
.fill_done:
    ret

; Internal single pixel write.
; RDI=buffer, RSI=stride, RDX=x, RCX=y, R10D=color.
chrome_put_pixel_internal:
    mov rax, rcx
    imul rax, rsi
    lea rax, [rax+rdx*4]
    mov [rdi+rax], r10d
    ret

; hit_test(width, height, x, y, out_region*) -> chrome status
; Buttons outrank resize border, then drag, then content.
nebo_console_chrome_hit_test:
    test r8, r8
    jz .hit_invalid
    mov dword [r8], NEBO_CHROME_REGION_NONE
    cmp rdi, NEBO_CHROME_MIN_WINDOW_WIDTH_PX
    jb .hit_limit
    cmp rsi, NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
    jb .hit_limit
    test rdx, rdx
    js .hit_invalid
    test rcx, rcx
    js .hit_invalid
    cmp rdx, rdi
    jae .hit_invalid
    cmp rcx, rsi
    jae .hit_invalid

    cmp rcx, NEBO_CHROME_HEIGHT_PX
    jae .hit_border
    mov rax, rdi
    sub rax, NEBO_CHROME_CONTROL_WIDTH_PX
    cmp rdx, rax
    jae .hit_close
    sub rax, NEBO_CHROME_CONTROL_WIDTH_PX
    cmp rdx, rax
    jae .hit_maximize
    sub rax, NEBO_CHROME_CONTROL_WIDTH_PX
    cmp rdx, rax
    jae .hit_minimize

.hit_border:
    cmp rdx, NEBO_CHROME_RESIZE_BORDER_PX
    jb .hit_resize
    cmp rcx, NEBO_CHROME_RESIZE_BORDER_PX
    jb .hit_resize
    mov rax, rdi
    sub rax, NEBO_CHROME_RESIZE_BORDER_PX
    cmp rdx, rax
    jae .hit_resize
    mov rax, rsi
    sub rax, NEBO_CHROME_RESIZE_BORDER_PX
    cmp rcx, rax
    jae .hit_resize
    cmp rcx, NEBO_CHROME_HEIGHT_PX
    jb .hit_drag
    mov dword [r8], NEBO_CHROME_REGION_CONTENT
    xor eax, eax
    ret
.hit_close:
    mov dword [r8], NEBO_CHROME_REGION_CLOSE
    xor eax, eax
    ret
.hit_maximize:
    mov dword [r8], NEBO_CHROME_REGION_MAXIMIZE_RESTORE
    xor eax, eax
    ret
.hit_minimize:
    mov dword [r8], NEBO_CHROME_REGION_MINIMIZE
    xor eax, eax
    ret
.hit_resize:
    mov dword [r8], NEBO_CHROME_REGION_RESIZE_BORDER
    xor eax, eax
    ret
.hit_drag:
    mov dword [r8], NEBO_CHROME_REGION_DRAG
    xor eax, eax
    ret
.hit_limit:
    mov eax, NEBO_CHROME_STATUS_LIMIT
    ret
.hit_invalid:
    mov eax, NEBO_CHROME_STATUS_INVALID_ARGUMENT
    ret

; action_for_region(region, window_flags, out_action*) -> chrome status
nebo_console_chrome_action_for_region:
    test rdx, rdx
    jz .action_invalid
    mov dword [rdx], NEBO_CHROME_ACTION_NONE
    cmp edi, NEBO_CHROME_REGION_DRAG
    je .action_drag
    cmp edi, NEBO_CHROME_REGION_MINIMIZE
    je .action_minimize
    cmp edi, NEBO_CHROME_REGION_MAXIMIZE_RESTORE
    je .action_maximize_restore
    cmp edi, NEBO_CHROME_REGION_CLOSE
    je .action_close
    cmp edi, NEBO_CHROME_REGION_RESIZE_BORDER
    je .action_resize
    cmp edi, NEBO_CHROME_REGION_CONTENT
    je .action_ok
    cmp edi, NEBO_CHROME_REGION_NONE
    je .action_ok
    jmp .action_invalid
.action_drag:
    mov dword [rdx], NEBO_CHROME_ACTION_BEGIN_DRAG
    jmp .action_ok
.action_minimize:
    mov dword [rdx], NEBO_CHROME_ACTION_MINIMIZE
    jmp .action_ok
.action_maximize_restore:
    test esi, NEBO_CHROME_WINDOW_FLAG_MAXIMIZED
    jnz .action_restore
    mov dword [rdx], NEBO_CHROME_ACTION_MAXIMIZE
    jmp .action_ok
.action_restore:
    mov dword [rdx], NEBO_CHROME_ACTION_RESTORE
    jmp .action_ok
.action_close:
    mov dword [rdx], NEBO_CHROME_ACTION_CLOSE
    jmp .action_ok
.action_resize:
    mov dword [rdx], NEBO_CHROME_ACTION_BEGIN_RESIZE
.action_ok:
    xor eax, eax
    ret
.action_invalid:
    mov eax, NEBO_CHROME_STATUS_INVALID_ARGUMENT
    ret

; render(surface*, width, height, window_flags) -> chrome status
; The content region is preserved. Only border, chrome background and the three
; deterministic controls are written.
nebo_console_chrome_render:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov [rsp+8], rcx
    test r12, r12
    jz .render_invalid
    cmp r13, NEBO_CHROME_MIN_WINDOW_WIDTH_PX
    jb .render_limit
    cmp r14, NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
    jb .render_limit
    cmp qword [r12+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET], 0
    je .render_state
    mov rax, [r12+NEBO_SOFTWARE_SURFACE_FLAGS_OFFSET]
    and eax, NEBO_SOFTWARE_SURFACE_REQUIRED_FLAGS
    cmp eax, NEBO_SOFTWARE_SURFACE_REQUIRED_FLAGS
    jne .render_state
    cmp qword [r12+NEBO_SOFTWARE_SURFACE_PIXEL_FORMAT_OFFSET], NEBO_SURFACE_PIXEL_FORMAT_BGRA8_PREMULTIPLIED
    jne .render_state
    cmp [r12+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET], r13
    jne .render_state
    cmp [r12+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET], r14
    jne .render_state
    mov rbx, [r12+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET]
    mov rax, [r12+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET]
    mov [rsp], rax

    ; Top and bottom borders.
    mov rdi, rbx
    mov rsi, [rsp]
    xor edx, edx
    xor ecx, ecx
    mov r8, r13
    mov r9d, 1
    mov r10d, NEBO_CHROME_COLOR_BORDER
    call chrome_fill_rect_internal
    mov rdi, rbx
    mov rsi, [rsp]
    xor edx, edx
    mov rcx, r14
    dec rcx
    mov r8, r13
    mov r9d, 1
    mov r10d, NEBO_CHROME_COLOR_BORDER
    call chrome_fill_rect_internal

    ; Left and right borders.
    mov rdi, rbx
    mov rsi, [rsp]
    xor edx, edx
    mov ecx, 1
    mov r8d, 1
    mov r9, r14
    sub r9, 2
    mov r10d, NEBO_CHROME_COLOR_BORDER
    call chrome_fill_rect_internal
    mov rdi, rbx
    mov rsi, [rsp]
    mov rdx, r13
    dec rdx
    mov ecx, 1
    mov r8d, 1
    mov r9, r14
    sub r9, 2
    mov r10d, NEBO_CHROME_COLOR_BORDER
    call chrome_fill_rect_internal

    ; Chrome background inside the border.
    mov rdi, rbx
    mov rsi, [rsp]
    mov edx, 1
    mov ecx, 1
    mov r8, r13
    sub r8, 2
    mov r9d, NEBO_CHROME_HEIGHT_PX-1
    mov r10d, NEBO_CHROME_COLOR_BACKGROUND
    call chrome_fill_rect_internal

    ; Minimize glyph.
    mov rdx, r13
    sub rdx, NEBO_CHROME_CONTROLS_WIDTH_PX
    add rdx, 8
    mov rdi, rbx
    mov rsi, [rsp]
    mov ecx, 18
    mov r8d, 12
    mov r9d, 2
    mov r10d, NEBO_CHROME_COLOR_FOREGROUND
    call chrome_fill_rect_internal

    ; Maximize/restore glyph.
    mov rdx, r13
    sub rdx, (NEBO_CHROME_CONTROL_WIDTH_PX*2)
    add rdx, 8
    mov rdi, rbx
    mov rsi, [rsp]
    mov ecx, 8
    mov r8d, 12
    mov r9d, 2
    mov r10d, NEBO_CHROME_COLOR_FOREGROUND
    call chrome_fill_rect_internal
    mov rdi, rbx
    mov rsi, [rsp]
    mov rcx, 18
    mov r8d, 12
    mov r9d, 2
    mov r10d, NEBO_CHROME_COLOR_FOREGROUND
    call chrome_fill_rect_internal
    mov rdi, rbx
    mov rsi, [rsp]
    mov rcx, 8
    mov r8d, 2
    mov r9d, 12
    mov r10d, NEBO_CHROME_COLOR_FOREGROUND
    call chrome_fill_rect_internal
    add rdx, 10
    mov rdi, rbx
    mov rsi, [rsp]
    mov rcx, 8
    mov r8d, 2
    mov r9d, 12
    mov r10d, NEBO_CHROME_COLOR_FOREGROUND
    call chrome_fill_rect_internal
    test dword [rsp+8], NEBO_CHROME_WINDOW_FLAG_MAXIMIZED
    jz .render_close
    ; Restore state gets a second offset corner.
    mov rdx, r13
    sub rdx, (NEBO_CHROME_CONTROL_WIDTH_PX*2)
    add rdx, 6
    mov rdi, rbx
    mov rsi, [rsp]
    mov ecx, 6
    mov r8d, 10
    mov r9d, 2
    mov r10d, NEBO_CHROME_COLOR_FOREGROUND
    call chrome_fill_rect_internal
    mov rdi, rbx
    mov rsi, [rsp]
    mov rcx, 6
    mov r8d, 2
    mov r9d, 10
    mov r10d, NEBO_CHROME_COLOR_FOREGROUND
    call chrome_fill_rect_internal

.render_close:
    ; Close glyph: two 10-pixel diagonals.
    xor r15d, r15d
.close_loop:
    mov rdx, r13
    sub rdx, 19
    add rdx, r15
    mov rcx, r15
    add rcx, 9
    mov rdi, rbx
    mov rsi, [rsp]
    mov r10d, NEBO_CHROME_COLOR_FOREGROUND
    call chrome_put_pixel_internal
    mov rdx, r13
    sub rdx, 10
    sub rdx, r15
    mov rcx, r15
    add rcx, 9
    mov rdi, rbx
    mov rsi, [rsp]
    mov r10d, NEBO_CHROME_COLOR_FOREGROUND
    call chrome_put_pixel_internal
    inc r15
    cmp r15, 10
    jb .close_loop

    mov eax, NEBO_CHROME_STATUS_OK
    jmp .render_done
.render_state:
    mov eax, NEBO_CHROME_STATUS_BAD_STATE
    jmp .render_done
.render_limit:
    mov eax, NEBO_CHROME_STATUS_LIMIT
    jmp .render_done
.render_invalid:
    mov eax, NEBO_CHROME_STATUS_INVALID_ARGUMENT
.render_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
