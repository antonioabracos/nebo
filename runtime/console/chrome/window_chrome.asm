; Nebo custom window chrome render and hit-test — MF052
bits 64
default rel

%include "runtime/console/chrome/window_chrome.inc"

global nebo_console_chrome_hit_test
global nebo_console_chrome_motion_hit_test
global nebo_console_chrome_resize_direction
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

; motion_hit_test(width, height, x, y, out_region*) -> chrome status
; Core X11 motion coordinates are signed and may be outside the event window
; while a button grab or WM moveresize transition is completing.  That is a
; valid no-hit state for motion only; press/release keep the strict contract.
nebo_console_chrome_motion_hit_test:
    test r8, r8
    jz .motion_invalid
    mov dword [r8], NEBO_CHROME_REGION_NONE
    cmp rdi, NEBO_CHROME_MIN_WINDOW_WIDTH_PX
    jb .motion_limit
    cmp rsi, NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
    jb .motion_limit
    test rdx, rdx
    js .motion_outside
    test rcx, rcx
    js .motion_outside
    cmp rdx, rdi
    jae .motion_outside
    cmp rcx, rsi
    jae .motion_outside
    jmp nebo_console_chrome_hit_test
.motion_outside:
    xor eax, eax
    ret
.motion_limit:
    mov eax, NEBO_CHROME_STATUS_LIMIT
    ret
.motion_invalid:
    mov eax, NEBO_CHROME_STATUS_INVALID_ARGUMENT
    ret

; resize_direction(width, height, x, y, out_direction*) -> chrome status
; The top-right resize grip lives on the first border-width rows immediately
; below the title controls. It therefore never overlaps Close/Maximize/Minimize.
nebo_console_chrome_resize_direction:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov rbx, r8
    test rbx, rbx
    jz .direction_invalid
    mov dword [rbx], 0
    mov rdi, r12
    mov rsi, r13
    mov rdx, r14
    mov rcx, r15
    mov r8, rbx
    call nebo_console_chrome_hit_test
    test eax, eax
    jnz .direction_done
    cmp dword [rbx], NEBO_CHROME_REGION_RESIZE_BORDER
    jne .direction_invalid
    cmp r14, NEBO_CHROME_RESIZE_BORDER_PX
    jb .direction_left
    mov rax, r12
    sub rax, NEBO_CHROME_RESIZE_BORDER_PX
    cmp r14, rax
    jae .direction_right
    cmp r15, NEBO_CHROME_RESIZE_BORDER_PX
    jb .direction_top
    mov rax, r13
    sub rax, NEBO_CHROME_RESIZE_BORDER_PX
    cmp r15, rax
    jae .direction_bottom
    jmp .direction_invalid
.direction_left:
    cmp r15, NEBO_CHROME_RESIZE_BORDER_PX
    jb .direction_top_left
    mov rax, r13
    sub rax, NEBO_CHROME_RESIZE_BORDER_PX
    cmp r15, rax
    jae .direction_bottom_left
    mov dword [rbx], NEBO_CHROME_RESIZE_DIRECTION_LEFT
    jmp .direction_ok
.direction_right:
    cmp r15, NEBO_CHROME_HEIGHT_PX + NEBO_CHROME_RESIZE_BORDER_PX
    jb .direction_top_right
    mov rax, r13
    sub rax, NEBO_CHROME_RESIZE_BORDER_PX
    cmp r15, rax
    jae .direction_bottom_right
    mov dword [rbx], NEBO_CHROME_RESIZE_DIRECTION_RIGHT
    jmp .direction_ok
.direction_top_left:
    mov dword [rbx], NEBO_CHROME_RESIZE_DIRECTION_TOPLEFT
    jmp .direction_ok
.direction_top:
    mov dword [rbx], NEBO_CHROME_RESIZE_DIRECTION_TOP
    jmp .direction_ok
.direction_top_right:
    mov dword [rbx], NEBO_CHROME_RESIZE_DIRECTION_TOPRIGHT
    jmp .direction_ok
.direction_bottom_right:
    mov dword [rbx], NEBO_CHROME_RESIZE_DIRECTION_BOTTOMRIGHT
    jmp .direction_ok
.direction_bottom:
    mov dword [rbx], NEBO_CHROME_RESIZE_DIRECTION_BOTTOM
    jmp .direction_ok
.direction_bottom_left:
    mov dword [rbx], NEBO_CHROME_RESIZE_DIRECTION_BOTTOMLEFT
.direction_ok:
    xor eax, eax
    jmp .direction_done
.direction_invalid:
    mov eax, NEBO_CHROME_STATUS_INVALID_ARGUMENT
.direction_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
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
    mov r10d, NEBO_CHROME_COLOR_BACKGROUND_INACTIVE
    test dword [rsp+8], NEBO_CHROME_WINDOW_FLAG_ACTIVE
    jz .chrome_background_ready
    mov r10d, NEBO_CHROME_COLOR_BACKGROUND
.chrome_background_ready:
    call chrome_fill_rect_internal

    ; Hover state is event-driven. The frontend repaints only when the hit
    ; region changes, so these affordances never require polling.
    test dword [rsp+8], NEBO_CHROME_WINDOW_FLAG_HOVER_MINIMIZE
    jz .hover_maximize
    mov rdi, rbx
    mov rsi, [rsp]
    mov rdx, r13
    sub rdx, NEBO_CHROME_CONTROLS_WIDTH_PX
    mov ecx, 1
    mov r8d, NEBO_CHROME_CONTROL_WIDTH_PX
    mov r9d, NEBO_CHROME_HEIGHT_PX-1
    mov r10d, NEBO_CHROME_COLOR_CONTROL_HOVER
    call chrome_fill_rect_internal
.hover_maximize:
    test dword [rsp+8], NEBO_CHROME_WINDOW_FLAG_HOVER_MAXIMIZE
    jz .hover_close
    mov rdi, rbx
    mov rsi, [rsp]
    mov rdx, r13
    sub rdx, NEBO_CHROME_CONTROL_WIDTH_PX*2
    mov ecx, 1
    mov r8d, NEBO_CHROME_CONTROL_WIDTH_PX
    mov r9d, NEBO_CHROME_HEIGHT_PX-1
    mov r10d, NEBO_CHROME_COLOR_CONTROL_HOVER
    call chrome_fill_rect_internal
.hover_close:
    test dword [rsp+8], NEBO_CHROME_WINDOW_FLAG_HOVER_CLOSE
    jz .render_minimize
    mov rdi, rbx
    mov rsi, [rsp]
    mov rdx, r13
    sub rdx, NEBO_CHROME_CONTROL_WIDTH_PX
    mov ecx, 1
    mov r8d, NEBO_CHROME_CONTROL_WIDTH_PX-1
    mov r9d, NEBO_CHROME_HEIGHT_PX-1
    mov r10d, NEBO_CHROME_COLOR_CLOSE_HOVER
    call chrome_fill_rect_internal

    ; Minimize glyph.
.render_minimize:
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
