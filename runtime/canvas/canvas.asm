; Nebo CONTROLO-DE-FLUXO-ESTRUTURADO-F06 — bounded deterministic Canvas 2D core
bits 64
default rel

%define NEBO_CANVAS_CORE_IMPLEMENTATION 1
%include "runtime/canvas/canvas.inc"

global nebo_canvas_create
global nebo_canvas_validate
global nebo_canvas_clear
global nebo_canvas_line
global nebo_canvas_rectangle
global nebo_canvas_circle
global nebo_canvas_text
global nebo_canvas_present_headless
global nebo_canvas_close
global nebo_canvas_export_rgba
global nebo_canvas_state_hash
global nebo_canvas_coord_from_float_exact

section .rodata align=16
; Digits 0..9 followed by uppercase A..Z. Seven rows per glyph, five low bits.
canvas_font_table:
    db 0x0e,0x11,0x13,0x15,0x19,0x11,0x0e,0x04,0x0c,0x04,0x04,0x04,0x04,0x0e
    db 0x0e,0x11,0x01,0x02,0x04,0x08,0x1f,0x1e,0x01,0x01,0x0e,0x01,0x01,0x1e
    db 0x02,0x06,0x0a,0x12,0x1f,0x02,0x02,0x1f,0x10,0x10,0x1e,0x01,0x01,0x1e
    db 0x0e,0x10,0x10,0x1e,0x11,0x11,0x0e,0x1f,0x01,0x02,0x04,0x08,0x08,0x08
    db 0x0e,0x11,0x11,0x0e,0x11,0x11,0x0e,0x0e,0x11,0x11,0x0f,0x01,0x01,0x0e
    db 0x0e,0x11,0x11,0x1f,0x11,0x11,0x11,0x1e,0x11,0x11,0x1e,0x11,0x11,0x1e
    db 0x0e,0x11,0x10,0x10,0x10,0x11,0x0e,0x1e,0x11,0x11,0x11,0x11,0x11,0x1e
    db 0x1f,0x10,0x10,0x1e,0x10,0x10,0x1f,0x1f,0x10,0x10,0x1e,0x10,0x10,0x10
    db 0x0e,0x11,0x10,0x17,0x11,0x11,0x0e,0x11,0x11,0x11,0x1f,0x11,0x11,0x11
    db 0x0e,0x04,0x04,0x04,0x04,0x04,0x0e,0x01,0x01,0x01,0x01,0x11,0x11,0x0e
    db 0x11,0x12,0x14,0x18,0x14,0x12,0x11,0x10,0x10,0x10,0x10,0x10,0x10,0x1f
    db 0x11,0x1b,0x15,0x15,0x11,0x11,0x11,0x11,0x19,0x15,0x13,0x11,0x11,0x11
    db 0x0e,0x11,0x11,0x11,0x11,0x11,0x0e,0x1e,0x11,0x11,0x1e,0x10,0x10,0x10
    db 0x0e,0x11,0x11,0x11,0x15,0x12,0x0d,0x1e,0x11,0x11,0x1e,0x14,0x12,0x11
    db 0x0f,0x10,0x10,0x0e,0x01,0x01,0x1e,0x1f,0x04,0x04,0x04,0x04,0x04,0x04
    db 0x11,0x11,0x11,0x11,0x11,0x11,0x0e,0x11,0x11,0x11,0x11,0x11,0x0a,0x04
    db 0x11,0x11,0x11,0x15,0x15,0x15,0x0a,0x11,0x11,0x0a,0x04,0x0a,0x11,0x11
    db 0x11,0x11,0x0a,0x04,0x04,0x04,0x04,0x1f,0x01,0x02,0x04,0x08,0x10,0x1f
canvas_replacement_glyph: db 0x1f,0x11,0x15,0x11,0x15,0x11,0x1f

section .text

canvas_set_failure:
    mov eax,esi
    test rdi,rdi
    jz .return
    test rdi,7
    jnz .return
    mov rcx,NEBO_CANVAS_MAGIC
    cmp [rdi+NEBO_CANVAS_MAGIC_OFFSET],rcx
    jne .return
    mov [rdi+NEBO_CANVAS_LAST_STATUS_OFFSET],rsi
    mov [rdi+NEBO_CANVAS_LAST_ERROR_OFFSET],rdx
    mov [rdi+NEBO_SOFTWARE_SURFACE_LAST_STATUS_OFFSET],rsi
    mov [rdi+NEBO_SOFTWARE_SURFACE_LAST_ERROR_OFFSET],rdx
.return:
    ret

canvas_set_success:
    test rdi,rdi
    jz .return
    test rdi,7
    jnz .return
    mov rax,NEBO_CANVAS_MAGIC
    cmp [rdi+NEBO_CANVAS_MAGIC_OFFSET],rax
    jne .return
    mov qword [rdi+NEBO_CANVAS_LAST_STATUS_OFFSET],0
    mov qword [rdi+NEBO_CANVAS_LAST_ERROR_OFFSET],0
    mov qword [rdi+NEBO_SOFTWARE_SURFACE_LAST_STATUS_OFFSET],0
    mov qword [rdi+NEBO_SOFTWARE_SURFACE_LAST_ERROR_OFFSET],0
.return:
    xor eax,eax
    ret

; rdi=a, rsi=a_len, rdx=b, rcx=b_len -> eax=1 overlap/wrap, 0 disjoint.
canvas_ranges_overlap:
    test rdi,rdi
    jz .overlap
    test rdx,rdx
    jz .overlap
    test rsi,rsi
    jz .disjoint
    test rcx,rcx
    jz .disjoint
    mov r8,rdi
    add r8,rsi
    jc .overlap
    mov r9,rdx
    add r9,rcx
    jc .overlap
    cmp rdi,r9
    jae .disjoint
    cmp rdx,r8
    jae .disjoint
.overlap:
    mov eax,1
    ret
.disjoint:
    xor eax,eax
    ret

; rdi=width, rsi=height -> rax=bytes, edx=CanvasError.
canvas_required_bytes:
    cmp rdi,NEBO_CANVAS_MIN_AXIS
    jb .bad
    cmp rdi,NEBO_CANVAS_MAX_AXIS
    ja .bad
    cmp rsi,NEBO_CANVAS_MIN_AXIS
    jb .bad
    cmp rsi,NEBO_CANVAS_MAX_AXIS
    ja .bad
    mov rax,rdi
    mul rsi
    test rdx,rdx
    jnz .bad
    cmp rax,NEBO_CANVAS_MAX_PIXELS
    ja .bad
    shl rax,2
    jc .bad
    cmp rax,NEBO_CANVAS_MAX_PIXEL_BYTES
    ja .bad
    xor edx,edx
    ret
.bad:
    xor eax,eax
    mov edx,NEBO_CANVAS_ERROR_LIMIT_EXCEEDED
    ret

; rdi=signed coordinate -> eax=0 or coordinate error.
canvas_validate_coord:
    cmp rdi,NEBO_CANVAS_COORD_MIN
    jl .bad
    cmp rdi,NEBO_CANVAS_COORD_MAX
    jg .bad
    xor eax,eax
    ret
.bad:
    mov eax,NEBO_CANVAS_ERROR_COORDINATE_RANGE
    ret

; edi=channel, esi=alpha -> eax=premultiplied channel.
canvas_premul_channel:
    mov eax,edi
    test esi,esi
    jz .zero
    cmp esi,255
    je .done
    imul eax,esi
    add eax,127
    xor edx,edx
    mov ecx,255
    div ecx
.done:
    ret
.zero:
    xor eax,eax
    ret

; edi=logical 0xRRGGBBAA -> eax=storage 0xAARRGGBB.
canvas_color_to_storage:
    push rbx
    push r12
    push r13
    push r14
    sub rsp,8
    mov r12d,edi
    mov r13d,r12d
    and r13d,0xff                    ; alpha
    mov edi,r12d
    shr edi,24                       ; red
    mov esi,r13d
    call canvas_premul_channel
    mov ebx,eax
    mov edi,r12d
    shr edi,16
    and edi,0xff                     ; green
    mov esi,r13d
    call canvas_premul_channel
    mov r14d,eax
    mov edi,r12d
    shr edi,8
    and edi,0xff                     ; blue
    mov esi,r13d
    call canvas_premul_channel
    mov edx,eax
    mov eax,r13d
    shl eax,24
    shl ebx,16
    or eax,ebx
    shl r14d,8
    or eax,r14d
    or eax,edx
    add rsp,8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; rdi=paint*, esi=required mode or zero -> eax=CanvasError.
canvas_validate_paint:
    test rdi,rdi
    jz .bad
    test rdi,3
    jnz .bad
    cmp dword [rdi+NEBO_CANVAS_PAINT_RESERVED_OFFSET],0
    jne .bad
    cmp dword [rdi+NEBO_CANVAS_PAINT_STROKE_WIDTH_OFFSET],1
    jne .bad
    mov eax,[rdi+NEBO_CANVAS_PAINT_MODE_OFFSET]
    cmp eax,NEBO_CANVAS_PAINT_MODE_STROKE
    je .mode
    cmp eax,NEBO_CANVAS_PAINT_MODE_FILL
    jne .bad
.mode:
    test esi,esi
    jz .ok
    cmp eax,esi
    jne .bad
.ok:
    xor eax,eax
    ret
.bad:
    mov eax,NEBO_CANVAS_ERROR_INVALID_PAINT
    ret

; rdi=canvas* -> eax=CanvasError.
canvas_validate_internal:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    test r12,r12
    jz .invalid
    test r12,7
    jnz .invalid
    mov rax,NEBO_CANVAS_MAGIC
    cmp [r12+NEBO_CANVAS_MAGIC_OFFSET],rax
    jne .invalid
    cmp qword [r12+NEBO_CANVAS_RESERVED_OFFSET],0
    jne .invalid
    mov eax,[r12+NEBO_CANVAS_STATE_OFFSET]
    cmp eax,NEBO_CANVAS_STATE_ACTIVE
    je .state_ok
    cmp eax,NEBO_CANVAS_STATE_CLOSED
    jne .invalid
.state_ok:
    mov eax,[r12+NEBO_CANVAS_FLAGS_OFFSET]
    test eax,~NEBO_CANVAS_KNOWN_FLAGS
    jnz .invalid
    test eax,NEBO_CANVAS_FLAG_INITIALIZED
    jz .invalid
    cmp qword [r12+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET],0
    je .invalid
    test qword [r12+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET],3
    jnz .invalid
    cmp qword [r12+NEBO_CANVAS_COMMANDS_PTR_OFFSET],0
    je .invalid
    test qword [r12+NEBO_CANVAS_COMMANDS_PTR_OFFSET],7
    jnz .invalid
    cmp qword [r12+NEBO_SOFTWARE_SURFACE_PIXEL_FORMAT_OFFSET],NEBO_SURFACE_PIXEL_FORMAT_BGRA8_PREMULTIPLIED
    jne .invalid
    cmp qword [r12+NEBO_SOFTWARE_SURFACE_FLAGS_OFFSET],NEBO_SOFTWARE_SURFACE_REQUIRED_FLAGS
    jne .invalid
    mov r13,[r12+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET]
    mov r14,[r12+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET]
    mov rdi,r13
    mov rsi,r14
    call canvas_required_bytes
    test edx,edx
    jnz .invalid
    mov r15,rax
    cmp [r12+NEBO_SOFTWARE_SURFACE_BYTE_CAPACITY_OFFSET],r15
    jb .invalid
    mov rax,r13
    shl rax,2
    cmp [r12+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET],rax
    jne .invalid
    mov rbx,[r12+NEBO_CANVAS_COMMAND_CAPACITY_OFFSET]
    test rbx,rbx
    jz .invalid
    cmp rbx,NEBO_CANVAS_MAX_COMMANDS
    ja .invalid
    cmp [r12+NEBO_CANVAS_COMMAND_COUNT_OFFSET],rbx
    ja .invalid
    mov r14,rbx
    shl r14,6
    mov rdi,r12
    mov esi,NEBO_CANVAS_SIZE
    mov rdx,[r12+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET]
    mov rcx,r15
    call canvas_ranges_overlap
    test eax,eax
    jnz .overlap
    mov rdi,r12
    mov esi,NEBO_CANVAS_SIZE
    mov rdx,[r12+NEBO_CANVAS_COMMANDS_PTR_OFFSET]
    mov rcx,r14
    call canvas_ranges_overlap
    test eax,eax
    jnz .overlap
    mov rdi,[r12+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET]
    mov rsi,r15
    mov rdx,[r12+NEBO_CANVAS_COMMANDS_PTR_OFFSET]
    mov rcx,r14
    call canvas_ranges_overlap
    test eax,eax
    jnz .overlap
    xor eax,eax
    jmp .return
.overlap:
    mov eax,NEBO_CANVAS_ERROR_STORAGE_OVERLAP
    jmp .return
.invalid:
    mov eax,NEBO_CANVAS_ERROR_INVALID_ARGUMENT
.return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; rdi=canvas* -> eax=CanvasError; CLOSED is not an active drawing state.
canvas_validate_active:
    push r12
    mov r12,rdi
    call canvas_validate_internal
    test eax,eax
    jnz .return
    cmp dword [r12+NEBO_CANVAS_STATE_OFFSET],NEBO_CANVAS_STATE_ACTIVE
    je .ok
    mov eax,NEBO_CANVAS_ERROR_CLOSED
    jmp .return
.ok:
    xor eax,eax
.return:
    pop r12
    ret

; rdi=canvas* -> rax=zeroed command record, ecx=CanvasError.
canvas_begin_command:
    push rbx
    push r12
    push r13
    mov r12,rdi
    call canvas_validate_internal
    test eax,eax
    jnz .error_eax
    cmp dword [r12+NEBO_CANVAS_STATE_OFFSET],NEBO_CANVAS_STATE_ACTIVE
    jne .closed
    mov r13,[r12+NEBO_CANVAS_COMMAND_COUNT_OFFSET]
    cmp r13,[r12+NEBO_CANVAS_COMMAND_CAPACITY_OFFSET]
    jae .limit
    cmp r13,NEBO_CANVAS_MAX_COMMANDS
    jae .limit
    mov rbx,r13
    shl rbx,6
    add rbx,[r12+NEBO_CANVAS_COMMANDS_PTR_OFFSET]
    mov rdi,rbx
    xor eax,eax
    mov ecx,NEBO_CANVAS_COMMAND_QWORDS
    cld
    rep stosq
    lea rax,[r13+1]
    mov [rbx+NEBO_CANVAS_COMMAND_SEQUENCE_OFFSET],rax
    mov rax,rbx
    xor ecx,ecx
    jmp .return
.error_eax:
    mov ecx,eax
    xor eax,eax
    jmp .return
.closed:
    mov ecx,NEBO_CANVAS_ERROR_CLOSED
    xor eax,eax
    jmp .return
.limit:
    mov ecx,NEBO_CANVAS_ERROR_COMMAND_LIMIT
    xor eax,eax
.return:
    pop r13
    pop r12
    pop rbx
    ret

; rdi=canvas* commits the already-filled command.
canvas_commit_command:
    inc qword [rdi+NEBO_CANVAS_COMMAND_COUNT_OFFSET]
    mov rax,[rdi+NEBO_CANVAS_COMMAND_COUNT_OFFSET]
    mov [rdi+NEBO_SOFTWARE_SURFACE_EXECUTED_COMMANDS_OFFSET],rax
    or dword [rdi+NEBO_CANVAS_FLAGS_OFFSET],NEBO_CANVAS_FLAG_DIRTY
    mov qword [rdi+NEBO_CANVAS_LAST_STATUS_OFFSET],NEBO_CANVAS_STATUS_OK
    mov qword [rdi+NEBO_CANVAS_LAST_ERROR_OFFSET],0
    mov qword [rdi+NEBO_SOFTWARE_SURFACE_LAST_STATUS_OFFSET],0
    mov qword [rdi+NEBO_SOFTWARE_SURFACE_LAST_ERROR_OFFSET],0
    xor eax,eax
    ret

; rdi=canvas, rsi=x, rdx=y, ecx=storage color. Out-of-surface is a no-op.
canvas_set_pixel:
    test rsi,rsi
    js .done
    test rdx,rdx
    js .done
    cmp rsi,[rdi+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET]
    jae .done
    cmp rdx,[rdi+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET]
    jae .done
    mov rax,rdx
    imul rax,[rdi+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET]
    lea rax,[rax+rsi*4]
    add rax,[rdi+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET]
    mov [rax],ecx
.done:
    ret

; rdi=canvas, rsi=x0, rdx=x1 inclusive, rcx=y, r8d=color.
canvas_hline:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov ebx,r8d
    test r15,r15
    js .done
    cmp r15,[r12+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET]
    jae .done
    cmp r13,r14
    jle .ordered
    xchg r13,r14
.ordered:
    cmp r14,0
    jl .done
    mov rax,[r12+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET]
    dec rax
    cmp r13,rax
    jg .done
    test r13,r13
    jns .left_ok
    xor r13d,r13d
.left_ok:
    cmp r14,rax
    jle .right_ok
    mov r14,rax
.right_ok:
.loop:
    cmp r13,r14
    jg .done
    mov rdi,r12
    mov rsi,r13
    mov rdx,r15
    mov ecx,ebx
    call canvas_set_pixel
    inc r13
    jmp .loop
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; rdi=canvas,rsi=x,rdx=y,rcx=width,r8=height,r9d=color.
canvas_fill_rect:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,32
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov rbx,r8
    mov [rsp],r9d
    test r15,r15
    jz .done
    test rbx,rbx
    jz .done
    mov rax,r13
    add rax,r15
    dec rax
    mov [rsp+8],rax
    mov qword [rsp+16],0
.row:
    mov rax,[rsp+16]
    cmp rax,rbx
    jae .done
    mov rcx,r14
    add rcx,rax
    mov rdi,r12
    mov rsi,r13
    mov rdx,[rsp+8]
    mov r8d,[rsp]
    call canvas_hline
    inc qword [rsp+16]
    jmp .row
.done:
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Bresenham: rdi=canvas,rsi=x0,rdx=y0,rcx=x1,r8=y1,r9d=color.
canvas_draw_line:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,48
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov rbx,r8
    mov [rsp],r9d
    mov rax,r15
    sub rax,r13
    jns .dx_ok
    neg rax
.dx_ok:
    mov [rsp+8],rax                 ; dx
    mov qword [rsp+24],-1           ; sx
    cmp r13,r15
    jge .sx_ok
    mov qword [rsp+24],1
.sx_ok:
    mov rax,rbx
    sub rax,r14
    jns .dy_abs
    neg rax
.dy_abs:
    neg rax
    mov [rsp+16],rax                ; dy negative
    mov qword [rsp+32],-1           ; sy
    cmp r14,rbx
    jge .sy_ok
    mov qword [rsp+32],1
.sy_ok:
    mov rax,[rsp+8]
    add rax,[rsp+16]
    mov [rsp+40],rax                ; err
.loop:
    mov rdi,r12
    mov rsi,r13
    mov rdx,r14
    mov ecx,[rsp]
    call canvas_set_pixel
    cmp r13,r15
    jne .step
    cmp r14,rbx
    je .done
.step:
    mov rax,[rsp+40]
    add rax,rax                     ; e2
    cmp rax,[rsp+16]
    jl .skip_x
    mov rcx,[rsp+16]
    add [rsp+40],rcx
    add r13,[rsp+24]
.skip_x:
    cmp rax,[rsp+8]
    jg .loop
    mov rcx,[rsp+8]
    add [rsp+40],rcx
    add r14,[rsp+32]
    jmp .loop
.done:
    add rsp,48
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; rdi=canvas,rsi=cx,rdx=cy,rcx=radius,r8d=color,r9d=paint mode.
canvas_draw_circle:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,32
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx                    ; x
    xor ebx,ebx                    ; y
    mov [rsp],r8d                  ; color
    mov [rsp+8],r9d                ; mode
    mov rax,1
    sub rax,r15
    mov [rsp+16],rax               ; error
.loop:
    cmp r15,rbx
    jl .done
    cmp dword [rsp+8],NEBO_CANVAS_PAINT_MODE_FILL
    je .fill
    ; Eight symmetric stroke pixels.
    mov rdi,r12
    mov rsi,r13
    add rsi,r15
    mov rdx,r14
    add rdx,rbx
    mov ecx,[rsp]
    call canvas_set_pixel
    mov rdi,r12
    mov rsi,r13
    add rsi,rbx
    mov rdx,r14
    add rdx,r15
    mov ecx,[rsp]
    call canvas_set_pixel
    mov rdi,r12
    mov rsi,r13
    sub rsi,rbx
    mov rdx,r14
    add rdx,r15
    mov ecx,[rsp]
    call canvas_set_pixel
    mov rdi,r12
    mov rsi,r13
    sub rsi,r15
    mov rdx,r14
    add rdx,rbx
    mov ecx,[rsp]
    call canvas_set_pixel
    mov rdi,r12
    mov rsi,r13
    sub rsi,r15
    mov rdx,r14
    sub rdx,rbx
    mov ecx,[rsp]
    call canvas_set_pixel
    mov rdi,r12
    mov rsi,r13
    sub rsi,rbx
    mov rdx,r14
    sub rdx,r15
    mov ecx,[rsp]
    call canvas_set_pixel
    mov rdi,r12
    mov rsi,r13
    add rsi,rbx
    mov rdx,r14
    sub rdx,r15
    mov ecx,[rsp]
    call canvas_set_pixel
    mov rdi,r12
    mov rsi,r13
    add rsi,r15
    mov rdx,r14
    sub rdx,rbx
    mov ecx,[rsp]
    call canvas_set_pixel
    jmp .advance
.fill:
    ; Four clipped horizontal spans; duplicate rows are harmless and exact.
    mov rdi,r12
    mov rsi,r13
    sub rsi,r15
    mov rdx,r13
    add rdx,r15
    mov rcx,r14
    add rcx,rbx
    mov r8d,[rsp]
    call canvas_hline
    mov rdi,r12
    mov rsi,r13
    sub rsi,r15
    mov rdx,r13
    add rdx,r15
    mov rcx,r14
    sub rcx,rbx
    mov r8d,[rsp]
    call canvas_hline
    mov rdi,r12
    mov rsi,r13
    sub rsi,rbx
    mov rdx,r13
    add rdx,rbx
    mov rcx,r14
    add rcx,r15
    mov r8d,[rsp]
    call canvas_hline
    mov rdi,r12
    mov rsi,r13
    sub rsi,rbx
    mov rdx,r13
    add rdx,rbx
    mov rcx,r14
    sub rcx,r15
    mov r8d,[rsp]
    call canvas_hline
.advance:
    inc rbx
    cmp qword [rsp+16],0
    jl .inside
    dec r15
    mov rax,rbx
    sub rax,r15
    shl rax,1
    inc rax
    add [rsp+16],rax
    jmp .loop
.inside:
    mov rax,rbx
    shl rax,1
    inc rax
    add [rsp+16],rax
    jmp .loop
.done:
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Strict canonical UTF-8 decoder. rdi=data,rsi=remaining -> r8=scalar,r9=bytes,eax=error.
canvas_utf8_next:
    test rdi,rdi
    jz .bad
    test rsi,rsi
    jz .bad
    movzx eax,byte [rdi]
    cmp eax,0x80
    jb .one
    cmp eax,0xc2
    jb .bad
    cmp eax,0xdf
    jbe .two
    cmp eax,0xef
    jbe .three
    cmp eax,0xf4
    jbe .four
    jmp .bad
.one:
    mov r8d,eax
    mov r9d,1
    xor eax,eax
    ret
.two:
    cmp rsi,2
    jb .bad
    movzx edx,byte [rdi+1]
    mov ecx,edx
    and ecx,0xc0
    cmp ecx,0x80
    jne .bad
    and eax,0x1f
    shl eax,6
    and edx,0x3f
    or eax,edx
    mov r8d,eax
    mov r9d,2
    xor eax,eax
    ret
.three:
    cmp rsi,3
    jb .bad
    movzx edx,byte [rdi+1]
    movzx ecx,byte [rdi+2]
    mov r10d,edx
    and r10d,0xc0
    cmp r10d,0x80
    jne .bad
    mov r10d,ecx
    and r10d,0xc0
    cmp r10d,0x80
    jne .bad
    cmp eax,0xe0
    jne .three_not_e0
    cmp edx,0xa0
    jb .bad
.three_not_e0:
    cmp eax,0xed
    jne .three_ready
    cmp edx,0xa0
    jae .bad
.three_ready:
    and eax,0x0f
    shl eax,12
    and edx,0x3f
    shl edx,6
    and ecx,0x3f
    or eax,edx
    or eax,ecx
    mov r8d,eax
    mov r9d,3
    xor eax,eax
    ret
.four:
    cmp rsi,4
    jb .bad
    movzx edx,byte [rdi+1]
    movzx ecx,byte [rdi+2]
    movzx r10d,byte [rdi+3]
    mov r11d,edx
    and r11d,0xc0
    cmp r11d,0x80
    jne .bad
    mov r11d,ecx
    and r11d,0xc0
    cmp r11d,0x80
    jne .bad
    mov r11d,r10d
    and r11d,0xc0
    cmp r11d,0x80
    jne .bad
    cmp eax,0xf0
    jne .four_not_f0
    cmp edx,0x90
    jb .bad
.four_not_f0:
    cmp eax,0xf4
    jne .four_ready
    cmp edx,0x90
    jae .bad
.four_ready:
    and eax,0x07
    shl eax,18
    and edx,0x3f
    shl edx,12
    and ecx,0x3f
    shl ecx,6
    and r10d,0x3f
    or eax,edx
    or eax,ecx
    or eax,r10d
    cmp eax,0x10ffff
    ja .bad
    mov r8d,eax
    mov r9d,4
    xor eax,eax
    ret
.bad:
    mov eax,NEBO_CANVAS_ERROR_INVALID_UTF8
    xor r8d,r8d
    xor r9d,r9d
    ret

; rdi=data,rsi=len,rdx=out_hash,rcx=out_scalars -> eax=error.
canvas_validate_text_hash:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    test r14,r14
    jz .invalid
    test r15,r15
    jz .invalid
    mov rax,NEBO_CANVAS_HASH_FNV1A64_OFFSET_BASIS
    mov [r14],rax
    mov qword [r15],0
    test r13,r13
    jz .ok
    test r12,r12
    jz .invalid
    xor ebx,ebx
.loop:
    cmp rbx,r13
    jae .ok
    lea rdi,[r12+rbx]
    mov rsi,r13
    sub rsi,rbx
    call canvas_utf8_next
    test eax,eax
    jnz .return
    lea r11,[r12+rbx]
    xor edx,edx
.hash_bytes:
    cmp rdx,r9
    jae .next
    mov rax,[r14]
    xor al,[r11+rdx]
    mov r10,NEBO_CANVAS_HASH_FNV1A64_PRIME
    imul rax,r10
    mov [r14],rax
    inc rdx
    jmp .hash_bytes
.next:
    add rbx,r9
    inc qword [r15]
    jmp .loop
.ok:
    xor eax,eax
    jmp .return
.invalid:
    mov eax,NEBO_CANVAS_ERROR_INVALID_ARGUMENT
.return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; edi=codepoint, esi=row 0..6 -> eax=five-bit row.
canvas_glyph_row:
    cmp esi,NEBO_CANVAS_FONT_HEIGHT
    jae .blank
    cmp edi,' '
    je .blank
    cmp edi,'a'
    jb .mapped
    cmp edi,'z'
    ja .mapped
    sub edi,32
.mapped:
    cmp edi,'0'
    jb .replacement
    cmp edi,'9'
    jbe .digit
    cmp edi,'A'
    jb .replacement
    cmp edi,'Z'
    ja .replacement
    sub edi,'A'
    add edi,10
    jmp .lookup
.digit:
    sub edi,'0'
.lookup:
    imul edi,7
    add edi,esi
    lea rax,[rel canvas_font_table]
    movzx eax,byte [rax+rdi]
    ret
.replacement:
    lea rax,[rel canvas_replacement_glyph]
    movzx eax,byte [rax+rsi]
    ret
.blank:
    xor eax,eax
    ret

; ---------------------------------------------------------------------------
; Public bounded native Canvas operations
; ---------------------------------------------------------------------------

; create(canvas*,pixels*,pixel_capacity,width,height,commands*,command_capacity)
; Seventh argument command_capacity is at [rsp+8] on entry.
nebo_canvas_create:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,40
    mov r12,rdi                    ; descriptor
    mov r13,rsi                    ; pixel buffer
    mov r14,rdx                    ; pixel capacity
    mov r15,rcx                    ; width
    mov rbx,r8                     ; height
    mov [rsp],r9                   ; command buffer
    mov rax,[rbp+16]
    mov [rsp+8],rax                ; command capacity
    test r12,r12
    jz .invalid
    test r12,7
    jnz .invalid
    test r13,r13
    jz .invalid
    test r13,3
    jnz .invalid
    cmp qword [rsp],0
    je .invalid
    test qword [rsp],7
    jnz .invalid
    cmp qword [rsp+8],0
    je .limit
    cmp qword [rsp+8],NEBO_CANVAS_MAX_COMMANDS
    ja .limit
    mov rdi,r15
    mov rsi,rbx
    call canvas_required_bytes
    test edx,edx
    jnz .limit
    cmp r14,rax
    jb .limit
    mov [rsp+16],rax               ; required pixel bytes
    mov rax,[rsp+8]
    shl rax,6
    mov [rsp+24],rax               ; command bytes
    ; Descriptor, active pixel bytes and active command bytes must be disjoint.
    mov rdi,r12
    mov esi,NEBO_CANVAS_SIZE
    mov rdx,r13
    mov rcx,[rsp+16]
    call canvas_ranges_overlap
    test eax,eax
    jnz .overlap
    mov rdi,r12
    mov esi,NEBO_CANVAS_SIZE
    mov rdx,[rsp]
    mov rcx,[rsp+24]
    call canvas_ranges_overlap
    test eax,eax
    jnz .overlap
    mov rdi,r13
    mov rsi,[rsp+16]
    mov rdx,[rsp]
    mov rcx,[rsp+24]
    call canvas_ranges_overlap
    test eax,eax
    jnz .overlap
    ; All checks complete. No output was mutated before this point.
    mov rdi,r12
    xor eax,eax
    mov ecx,NEBO_CANVAS_QWORDS
    cld
    rep stosq
    mov [r12+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET],r13
    mov [r12+NEBO_SOFTWARE_SURFACE_BYTE_CAPACITY_OFFSET],r14
    mov [r12+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET],r15
    mov [r12+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET],rbx
    mov rax,r15
    shl rax,2
    mov [r12+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET],rax
    mov qword [r12+NEBO_SOFTWARE_SURFACE_PIXEL_FORMAT_OFFSET],NEBO_SURFACE_PIXEL_FORMAT_BGRA8_PREMULTIPLIED
    mov qword [r12+NEBO_SOFTWARE_SURFACE_GENERATION_OFFSET],1
    mov qword [r12+NEBO_SOFTWARE_SURFACE_FLAGS_OFFSET],NEBO_SOFTWARE_SURFACE_REQUIRED_FLAGS
    mov rax,NEBO_CANVAS_HASH_FNV1A64_OFFSET_BASIS
    mov [r12+NEBO_SOFTWARE_SURFACE_STATE_HASH_OFFSET],rax
    mov r10,[rsp]
    mov r11,[rsp+8]
    mov [r12+NEBO_CANVAS_COMMANDS_PTR_OFFSET],r10
    mov [r12+NEBO_CANVAS_COMMAND_CAPACITY_OFFSET],r11
    mov dword [r12+NEBO_CANVAS_STATE_OFFSET],NEBO_CANVAS_STATE_ACTIVE
    mov dword [r12+NEBO_CANVAS_FLAGS_OFFSET],NEBO_CANVAS_FLAG_INITIALIZED
    mov rax,NEBO_CANVAS_MAGIC
    mov [r12+NEBO_CANVAS_MAGIC_OFFSET],rax
    ; Deterministic transparent-black pixels and zero command storage.
    mov rdi,r13
    xor eax,eax
    mov rcx,[rsp+16]
    shr rcx,2
    rep stosd
    mov rdi,r10
    xor eax,eax
    mov rcx,r11
    shl rcx,3
    rep stosq
    xor eax,eax
    jmp .return
.overlap:
    mov eax,NEBO_CANVAS_ERROR_STORAGE_OVERLAP
    jmp .return
.limit:
    mov eax,NEBO_CANVAS_ERROR_LIMIT_EXCEEDED
    jmp .return
.invalid:
    mov eax,NEBO_CANVAS_ERROR_INVALID_ARGUMENT
.return:
    add rsp,40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

nebo_canvas_validate:
    jmp canvas_validate_internal

; clear(canvas*, logical RGBA8 color)
nebo_canvas_clear:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13d,esi
    call canvas_begin_command
    test ecx,ecx
    jnz .error
    mov r14,rax
    mov edi,r13d
    call canvas_color_to_storage
    mov ebx,eax
    mov rdi,[r12+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET]
    mov rcx,[r12+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET]
    imul rcx,[r12+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET]
    mov eax,ebx
    cld
    rep stosd
    mov dword [r14+NEBO_CANVAS_COMMAND_KIND_OFFSET],NEBO_CANVAS_COMMAND_CLEAR
    mov dword [r14+NEBO_CANVAS_COMMAND_FLAGS_OFFSET],NEBO_CANVAS_COMMAND_FLAG_ACCEPTED | NEBO_CANVAS_COMMAND_FLAG_FILL
    mov [r14+NEBO_CANVAS_COMMAND_COLOR_OFFSET],r13d
    mov rdi,r12
    call canvas_commit_command
    jmp .return
.error:
    mov rdi,r12
    mov esi,ecx
    mov edx,ecx
    call canvas_set_failure
.return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; line(canvas*,x0,y0,x1,y1,paint*)
nebo_canvas_line:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,48
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov rbx,r8
    mov [rsp],r9
    mov rdi,r12
    call canvas_validate_active
    test eax,eax
    jnz .error_eax
    mov rdi,r13
    call canvas_validate_coord
    test eax,eax
    jnz .error_eax
    mov rdi,r14
    call canvas_validate_coord
    test eax,eax
    jnz .error_eax
    mov rdi,r15
    call canvas_validate_coord
    test eax,eax
    jnz .error_eax
    mov rdi,rbx
    call canvas_validate_coord
    test eax,eax
    jnz .error_eax
    cmp r13,r15
    jne .not_zero
    cmp r14,rbx
    je .success_noop
.not_zero:
    mov rdi,[rsp]
    mov esi,NEBO_CANVAS_PAINT_MODE_STROKE
    call canvas_validate_paint
    test eax,eax
    jnz .error_eax
    ; Snapshot borrowed Paint before command storage is reserved/zeroed.
    mov r10,[rsp]
    mov eax,[r10+NEBO_CANVAS_PAINT_COLOR_OFFSET]
    mov [rsp+16],eax
    mov rdi,r12
    call canvas_begin_command
    test ecx,ecx
    jnz .error_ecx
    mov [rsp+8],rax
    mov edi,[rsp+16]
    call canvas_color_to_storage
    mov [rsp+24],eax
    mov rdi,r12
    mov rsi,r13
    mov rdx,r14
    mov rcx,r15
    mov r8,rbx
    mov r9d,[rsp+24]
    call canvas_draw_line
    mov r10,[rsp+8]
    mov dword [r10+NEBO_CANVAS_COMMAND_KIND_OFFSET],NEBO_CANVAS_COMMAND_LINE
    mov dword [r10+NEBO_CANVAS_COMMAND_FLAGS_OFFSET],NEBO_CANVAS_COMMAND_FLAG_ACCEPTED | NEBO_CANVAS_COMMAND_FLAG_STROKE | NEBO_CANVAS_COMMAND_FLAG_CLIPPED
    mov [r10+NEBO_CANVAS_COMMAND_X0_OFFSET],r13
    mov [r10+NEBO_CANVAS_COMMAND_Y0_OFFSET],r14
    mov [r10+NEBO_CANVAS_COMMAND_X1_OFFSET],r15
    mov [r10+NEBO_CANVAS_COMMAND_Y1_OFFSET],rbx
    mov eax,[rsp+16]
    mov [r10+NEBO_CANVAS_COMMAND_COLOR_OFFSET],eax
    mov rdi,r12
    call canvas_commit_command
    jmp .return
.success_noop:
    mov rdi,r12
    call canvas_set_success
    jmp .return
.error_ecx:
    mov eax,ecx
.error_eax:
    mov rdi,r12
    mov esi,eax
    mov edx,eax
    call canvas_set_failure
.return:
    add rsp,48
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; rectangle(canvas*,x,y,width,height,paint*)
nebo_canvas_rectangle:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,64
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov rbx,r8
    mov [rsp],r9
    mov rdi,r12
    call canvas_validate_active
    test eax,eax
    jnz .error_eax
    mov rdi,r13
    call canvas_validate_coord
    test eax,eax
    jnz .error_eax
    mov rdi,r14
    call canvas_validate_coord
    test eax,eax
    jnz .error_eax
    cmp r15,8192
    ja .coord_error
    cmp rbx,8192
    ja .coord_error
    test r15,r15
    jz .success_noop
    test rbx,rbx
    jz .success_noop
    mov rdi,[rsp]
    xor esi,esi
    call canvas_validate_paint
    test eax,eax
    jnz .error_eax
    ; Snapshot borrowed Paint before command storage is reserved/zeroed.
    mov r10,[rsp]
    mov eax,[r10+NEBO_CANVAS_PAINT_MODE_OFFSET]
    mov [rsp+16],eax
    mov eax,[r10+NEBO_CANVAS_PAINT_COLOR_OFFSET]
    mov [rsp+20],eax
    mov rdi,r12
    call canvas_begin_command
    test ecx,ecx
    jnz .error_ecx
    mov [rsp+8],rax
    mov edi,[rsp+20]
    call canvas_color_to_storage
    mov [rsp+24],eax
    cmp dword [rsp+16],NEBO_CANVAS_PAINT_MODE_FILL
    jne .stroke
    mov rdi,r12
    mov rsi,r13
    mov rdx,r14
    mov rcx,r15
    mov r8,rbx
    mov r9d,[rsp+24]
    call canvas_fill_rect
    jmp .record
.stroke:
    mov rax,r13
    add rax,r15
    dec rax
    mov [rsp+32],rax
    mov rax,r14
    add rax,rbx
    dec rax
    mov [rsp+40],rax
    mov rdi,r12
    mov rsi,r13
    mov rdx,r14
    mov rcx,[rsp+32]
    mov r8,r14
    mov r9d,[rsp+24]
    call canvas_draw_line
    mov rdi,r12
    mov rsi,r13
    mov rdx,[rsp+40]
    mov rcx,[rsp+32]
    mov r8,[rsp+40]
    mov r9d,[rsp+24]
    call canvas_draw_line
    mov rdi,r12
    mov rsi,r13
    mov rdx,r14
    mov rcx,r13
    mov r8,[rsp+40]
    mov r9d,[rsp+24]
    call canvas_draw_line
    mov rdi,r12
    mov rsi,[rsp+32]
    mov rdx,r14
    mov rcx,[rsp+32]
    mov r8,[rsp+40]
    mov r9d,[rsp+24]
    call canvas_draw_line
.record:
    mov r10,[rsp+8]
    mov dword [r10+NEBO_CANVAS_COMMAND_KIND_OFFSET],NEBO_CANVAS_COMMAND_RECTANGLE
    mov eax,NEBO_CANVAS_COMMAND_FLAG_ACCEPTED | NEBO_CANVAS_COMMAND_FLAG_CLIPPED
    cmp dword [rsp+16],NEBO_CANVAS_PAINT_MODE_FILL
    jne .record_stroke
    or eax,NEBO_CANVAS_COMMAND_FLAG_FILL
    jmp .record_flags
.record_stroke:
    or eax,NEBO_CANVAS_COMMAND_FLAG_STROKE
.record_flags:
    mov [r10+NEBO_CANVAS_COMMAND_FLAGS_OFFSET],eax
    mov [r10+NEBO_CANVAS_COMMAND_X0_OFFSET],r13
    mov [r10+NEBO_CANVAS_COMMAND_Y0_OFFSET],r14
    mov [r10+NEBO_CANVAS_COMMAND_X1_OFFSET],r15
    mov [r10+NEBO_CANVAS_COMMAND_Y1_OFFSET],rbx
    mov eax,[rsp+20]
    mov [r10+NEBO_CANVAS_COMMAND_COLOR_OFFSET],eax
    mov eax,[rsp+16]
    mov [r10+NEBO_CANVAS_COMMAND_AUX_OFFSET],eax
    mov rdi,r12
    call canvas_commit_command
    jmp .return
.coord_error:
    mov eax,NEBO_CANVAS_ERROR_COORDINATE_RANGE
    jmp .error_eax
.success_noop:
    mov rdi,r12
    call canvas_set_success
    jmp .return
.error_ecx:
    mov eax,ecx
.error_eax:
    mov rdi,r12
    mov esi,eax
    mov edx,eax
    call canvas_set_failure
.return:
    add rsp,64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; circle(canvas*,cx,cy,radius,paint*)
nebo_canvas_circle:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,32
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov rbx,r8
    mov rdi,r12
    call canvas_validate_active
    test eax,eax
    jnz .error_eax
    mov rdi,r13
    call canvas_validate_coord
    test eax,eax
    jnz .error_eax
    mov rdi,r14
    call canvas_validate_coord
    test eax,eax
    jnz .error_eax
    cmp r15,NEBO_CANVAS_MAX_RADIUS
    ja .coord_error
    test r15,r15
    jz .success_noop
    mov rdi,rbx
    xor esi,esi
    call canvas_validate_paint
    test eax,eax
    jnz .error_eax
    ; Snapshot borrowed Paint before command storage is reserved/zeroed.
    mov eax,[rbx+NEBO_CANVAS_PAINT_MODE_OFFSET]
    mov [rsp+8],eax
    mov eax,[rbx+NEBO_CANVAS_PAINT_COLOR_OFFSET]
    mov [rsp+12],eax
    mov rdi,r12
    call canvas_begin_command
    test ecx,ecx
    jnz .error_ecx
    mov [rsp],rax
    mov edi,[rsp+12]
    call canvas_color_to_storage
    mov rdi,r12
    mov rsi,r13
    mov rdx,r14
    mov rcx,r15
    mov r8d,eax
    mov r9d,[rsp+8]
    call canvas_draw_circle
    mov r10,[rsp]
    mov dword [r10+NEBO_CANVAS_COMMAND_KIND_OFFSET],NEBO_CANVAS_COMMAND_CIRCLE
    mov eax,NEBO_CANVAS_COMMAND_FLAG_ACCEPTED | NEBO_CANVAS_COMMAND_FLAG_CLIPPED
    cmp dword [rsp+8],NEBO_CANVAS_PAINT_MODE_FILL
    jne .stroke
    or eax,NEBO_CANVAS_COMMAND_FLAG_FILL
    jmp .flags
.stroke:
    or eax,NEBO_CANVAS_COMMAND_FLAG_STROKE
.flags:
    mov [r10+NEBO_CANVAS_COMMAND_FLAGS_OFFSET],eax
    mov [r10+NEBO_CANVAS_COMMAND_X0_OFFSET],r13
    mov [r10+NEBO_CANVAS_COMMAND_Y0_OFFSET],r14
    mov [r10+NEBO_CANVAS_COMMAND_ARG0_OFFSET],r15
    mov eax,[rsp+12]
    mov [r10+NEBO_CANVAS_COMMAND_COLOR_OFFSET],eax
    mov eax,[rsp+8]
    mov [r10+NEBO_CANVAS_COMMAND_AUX_OFFSET],eax
    mov rdi,r12
    call canvas_commit_command
    jmp .return
.coord_error:
    mov eax,NEBO_CANVAS_ERROR_COORDINATE_RANGE
    jmp .error_eax
.success_noop:
    mov rdi,r12
    call canvas_set_success
    jmp .return
.error_ecx:
    mov eax,ecx
.error_eax:
    mov rdi,r12
    mov esi,eax
    mov edx,eax
    call canvas_set_failure
.return:
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; text(canvas*,utf8*,length,x,y,paint*) using deterministic built-in 5x7 glyphs.
nebo_canvas_text:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,88
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov rbx,r8
    mov [rsp],r9                    ; paint
    mov rdi,r12
    call canvas_validate_active
    test eax,eax
    jnz .error_eax
    cmp r14,NEBO_CANVAS_MAX_TEXT_BYTES
    ja .limit
    test r14,r14
    jz .success_noop
    mov rdi,r15
    call canvas_validate_coord
    test eax,eax
    jnz .error_eax
    mov rdi,rbx
    call canvas_validate_coord
    test eax,eax
    jnz .error_eax
    mov rdi,[rsp]
    mov esi,NEBO_CANVAS_PAINT_MODE_FILL
    call canvas_validate_paint
    test eax,eax
    jnz .error_eax
    ; Snapshot borrowed Paint before command storage is reserved/zeroed.
    mov r10,[rsp]
    mov eax,[r10+NEBO_CANVAS_PAINT_COLOR_OFFSET]
    mov [rsp+32],eax
    mov rdi,r13
    mov rsi,r14
    lea rdx,[rsp+8]                 ; text hash
    lea rcx,[rsp+16]                ; scalar count
    call canvas_validate_text_hash
    test eax,eax
    jnz .error_eax
    mov rdi,r12
    call canvas_begin_command
    test ecx,ecx
    jnz .error_ecx
    mov [rsp+24],rax                ; command
    mov edi,[rsp+32]                ; snapshotted logical color
    call canvas_color_to_storage
    mov [rsp+36],eax                ; storage color
    mov qword [rsp+40],0            ; byte offset
    mov [rsp+48],r15                ; current x
    mov [rsp+56],rbx                ; current y
.draw_scalar:
    mov rax,[rsp+40]
    cmp rax,r14
    jae .record
    lea rdi,[r13+rax]
    mov rsi,r14
    sub rsi,rax
    call canvas_utf8_next
    test eax,eax
    jnz .error_eax                  ; unreachable after prevalidation
    add [rsp+40],r9
    mov [rsp+64],r8                 ; codepoint
    cmp r8d,10
    jne .glyph
    mov [rsp+48],r15
    add qword [rsp+56],NEBO_CANVAS_FONT_LINE_HEIGHT
    jmp .draw_scalar
.glyph:
    mov dword [rsp+72],0            ; row
.row:
    mov eax,[rsp+72]
    cmp eax,NEBO_CANVAS_FONT_HEIGHT
    jae .advance
    mov edi,[rsp+64]
    mov esi,eax
    call canvas_glyph_row
    mov [rsp+80],eax                ; row bits
    mov dword [rsp+76],0            ; column
.col:
    mov ecx,[rsp+76]
    cmp ecx,NEBO_CANVAS_FONT_WIDTH
    jae .next_row
    mov edx,4
    sub edx,ecx
    mov ecx,edx
    mov eax,1
    shl eax,cl
    test [rsp+80],eax
    jz .skip_pixel
    mov ecx,[rsp+76]
    mov rdi,r12
    mov rsi,[rsp+48]
    add rsi,rcx
    mov rdx,[rsp+56]
    mov eax,[rsp+72]
    add rdx,rax
    mov ecx,[rsp+36]
    call canvas_set_pixel
.skip_pixel:
    inc dword [rsp+76]
    jmp .col
.next_row:
    inc dword [rsp+72]
    jmp .row
.advance:
    add qword [rsp+48],NEBO_CANVAS_FONT_ADVANCE
    jmp .draw_scalar
.record:
    mov r10,[rsp+24]
    mov dword [r10+NEBO_CANVAS_COMMAND_KIND_OFFSET],NEBO_CANVAS_COMMAND_TEXT
    mov dword [r10+NEBO_CANVAS_COMMAND_FLAGS_OFFSET],NEBO_CANVAS_COMMAND_FLAG_ACCEPTED | NEBO_CANVAS_COMMAND_FLAG_FILL | NEBO_CANVAS_COMMAND_FLAG_CLIPPED
    mov [r10+NEBO_CANVAS_COMMAND_X0_OFFSET],r15
    mov [r10+NEBO_CANVAS_COMMAND_Y0_OFFSET],rbx
    mov rax,[rsp+8]
    mov [r10+NEBO_CANVAS_COMMAND_ARG0_OFFSET],rax
    mov eax,[rsp+32]
    mov [r10+NEBO_CANVAS_COMMAND_COLOR_OFFSET],eax
    mov eax,r14d
    mov [r10+NEBO_CANVAS_COMMAND_AUX_OFFSET],eax
    mov rdi,r12
    call canvas_commit_command
    jmp .return
.limit:
    mov eax,NEBO_CANVAS_ERROR_LIMIT_EXCEEDED
    jmp .error_eax
.success_noop:
    mov rdi,r12
    call canvas_set_success
    jmp .return
.error_ecx:
    mov eax,ecx
.error_eax:
    mov rdi,r12
    mov esi,eax
    mov edx,eax
    call canvas_set_failure
.return:
    add rsp,88
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; state_hash(canvas*,out_u64*)

; state_hash(canvas*,out_u64*) hashes descriptor, command trace and pixels in
; canonical RGBA channel order. Pointers and capacity slack are excluded.
nebo_canvas_state_hash:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    test r13,r13
    jz .invalid
    call canvas_validate_internal
    test eax,eax
    jnz .return
    mov r14,NEBO_CANVAS_HASH_FNV1A64_OFFSET_BASIS
    mov r9,NEBO_CANVAS_HASH_FNV1A64_PRIME
    ; Stable scalar fields.
    lea rbx,[rel .field_offsets]
    xor r15d,r15d
.field_loop:
    cmp r15d,8
    jae .commands
    movzx eax,byte [rbx+r15]
    mov r10,[r12+rax]
    mov ecx,8
.field_bytes:
    xor r14b,r10b
    imul r14,r9
    shr r10,8
    dec ecx
    jnz .field_bytes
    inc r15d
    jmp .field_loop
.commands:
    xor r15d,r15d
    mov r11,[r12+NEBO_CANVAS_COMMANDS_PTR_OFFSET]
.command_loop:
    cmp r15,[r12+NEBO_CANVAS_COMMAND_COUNT_OFFSET]
    jae .pixels
    mov rax,r15
    shl rax,6
    add rax,r11
    xor ecx,ecx
.command_bytes:
    cmp ecx,NEBO_CANVAS_COMMAND_SIZE
    jae .next_command
    xor r14b,[rax+rcx]
    imul r14,r9
    inc ecx
    jmp .command_bytes
.next_command:
    inc r15
    jmp .command_loop
.pixels:
    mov r11,[r12+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET]
    mov r15,[r12+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET]
    imul r15,[r12+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET]
    xor ebx,ebx
.pixel_loop:
    cmp rbx,r15
    jae .done_hash
    mov eax,[r11+rbx*4]             ; 0xAARRGGBB
    mov edx,eax
    shr edx,16                      ; R
    xor r14b,dl
    imul r14,r9
    mov edx,eax
    shr edx,8                       ; G
    xor r14b,dl
    imul r14,r9
    mov edx,eax                     ; B
    xor r14b,dl
    imul r14,r9
    shr eax,24                      ; A
    xor r14b,al
    imul r14,r9
    inc rbx
    jmp .pixel_loop
.done_hash:
    mov [r13],r14
    mov [r12+NEBO_SOFTWARE_SURFACE_STATE_HASH_OFFSET],r14
    xor eax,eax
    jmp .return
.invalid:
    mov eax,NEBO_CANVAS_ERROR_INVALID_ARGUMENT
.return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.field_offsets:
    db NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET
    db NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET
    db NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET
    db NEBO_SOFTWARE_SURFACE_PIXEL_FORMAT_OFFSET
    db NEBO_SOFTWARE_SURFACE_GENERATION_OFFSET
    db NEBO_CANVAS_COMMAND_COUNT_OFFSET
    db NEBO_CANVAS_STATE_OFFSET
    db NEBO_CANVAS_FRAME_SEQUENCE_OFFSET

; export_rgba(canvas*,out*,capacity) -> status. Output is canonical R,G,B,A.
nebo_canvas_export_rgba:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    call canvas_validate_internal
    test eax,eax
    jnz .return
    test r13,r13
    jz .invalid
    mov rdi,[r12+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET]
    mov rsi,[r12+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET]
    call canvas_required_bytes
    test edx,edx
    jnz .invalid
    cmp r14,rax
    jb .limit
    mov r15,rax
    shr r15,2
    mov r11,[r12+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET]
    xor ebx,ebx
.loop:
    cmp rbx,r15
    jae .ok
    mov eax,[r11+rbx*4]
    mov edx,eax
    shr edx,16
    mov [r13+rbx*4],dl              ; R
    mov edx,eax
    shr edx,8
    mov [r13+rbx*4+1],dl            ; G
    mov [r13+rbx*4+2],al            ; B
    shr eax,24
    mov [r13+rbx*4+3],al            ; A
    inc rbx
    jmp .loop
.ok:
    xor eax,eax
    jmp .return
.limit:
    mov eax,NEBO_CANVAS_ERROR_LIMIT_EXCEEDED
    jmp .return
.invalid:
    mov eax,NEBO_CANVAS_ERROR_INVALID_ARGUMENT
.return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; exact finite integral Float64 coordinate conversion.
; rdi=double*, rsi=out_i64* -> status.
nebo_canvas_coord_from_float_exact:
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    movsd xmm0,[rdi]
    ucomisd xmm0,xmm0
    jp .non_integer
    cvttsd2si rax,xmm0
    cmp rax,NEBO_CANVAS_COORD_MIN
    jl .range
    cmp rax,NEBO_CANVAS_COORD_MAX
    jg .range
    cvtsi2sd xmm1,rax
    ucomisd xmm0,xmm1
    jp .non_integer
    jne .non_integer
    mov [rsi],rax
    xor eax,eax
    ret
.range:
    mov eax,NEBO_CANVAS_ERROR_COORDINATE_RANGE
    ret
.non_integer:
    mov eax,NEBO_CANVAS_ERROR_NON_INTEGER_FLOAT
    ret
.invalid:
    mov eax,NEBO_CANVAS_ERROR_INVALID_ARGUMENT
    ret

; present_headless(canvas*,runtime*,handle,owner,result*)
nebo_canvas_present_headless:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,40
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov rbx,r8
    test rbx,rbx
    jz .invalid
    test rbx,7
    jnz .invalid
    mov rdi,r12
    call canvas_validate_internal
    test eax,eax
    jnz .error_eax
    cmp dword [r12+NEBO_CANVAS_STATE_OFFSET],NEBO_CANVAS_STATE_ACTIVE
    jne .closed
    test r13,r13
    jz .invalid
    test r13,7
    jnz .invalid
    mov rax,NEBO_HEADLESS_RUNTIME_MAGIC
    cmp [r13+NEBO_HEADLESS_RUNTIME_MAGIC_OFFSET],rax
    jne .invalid
    mov rax,[r13+NEBO_HEADLESS_RUNTIME_RECORDS_PTR_OFFSET]
    test rax,rax
    jz .invalid
    test rax,7
    jnz .invalid
    mov rcx,[r13+NEBO_HEADLESS_RUNTIME_CAPACITY_OFFSET]
    test rcx,rcx
    jz .invalid
    cmp rcx,NEBO_WINDOW_MAX_WINDOWS
    ja .invalid
    test r14,r14
    jz .stale
    mov ecx,r14d
    test ecx,ecx
    jz .stale
    cmp rcx,[r13+NEBO_HEADLESS_RUNTIME_CAPACITY_OFFSET]
    ja .stale
    mov r9,r14
    shr r9,NEBO_WINDOW_HANDLE_GENERATION_SHIFT
    test r9d,r9d
    jz .stale
    dec ecx
    mov rdx,[r13+NEBO_HEADLESS_RUNTIME_RECORDS_PTR_OFFSET]
    mov rax,rcx
    imul rax,NEBO_WINDOW_SIZE
    add rax,rdx
    mov [rsp],rax                    ; record
    cmp [rax+NEBO_WINDOW_HANDLE_OFFSET],r14
    jne .stale
    cmp [rax+nebo_canvas_WINDOW_GENERATION_OFFSET],r9
    jne .stale
    cmp [rax+NEBO_WINDOW_OWNER_CONTEXT_OFFSET],r15
    jne .owner
    cmp dword [rax+NEBO_WINDOW_STATE_OFFSET],NEBO_WINDOW_STATE_VISIBLE
    jne .bad_state
    mov rdx,[r12+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET]
    cmp [rax+NEBO_WINDOW_WIDTH_OFFSET],rdx
    jne .dimension
    mov rdx,[r12+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET]
    cmp [rax+NEBO_WINDOW_HEIGHT_OFFSET],rdx
    jne .dimension
    mov rdx,[r12+NEBO_CANVAS_OWNER_CONTEXT_OFFSET]
    test rdx,rdx
    jz .canvas_owner_ready
    cmp rdx,r15
    jne .owner
.canvas_owner_ready:
    cmp qword [r12+NEBO_CANVAS_FRAME_SEQUENCE_OFFSET],-1
    je .frame_exhausted
    cmp qword [r12+NEBO_CANVAS_PRESENT_COUNT_OFFSET],-1
    je .frame_exhausted
    lea rsi,[rsp+8]
    mov rdi,r12
    call nebo_canvas_state_hash
    test eax,eax
    jnz .error_eax
    mov rax,[r12+NEBO_CANVAS_FRAME_SEQUENCE_OFFSET]
    inc rax
    mov [rbx+NEBO_CANVAS_PRESENT_FRAME_SEQUENCE_OFFSET],rax
    mov rdx,[rsp+8]
    mov [rbx+NEBO_CANVAS_PRESENT_FRAME_HASH_OFFSET],rdx
    mov rcx,[r12+NEBO_CANVAS_COMMAND_COUNT_OFFSET]
    mov [rbx+NEBO_CANVAS_PRESENT_COMMAND_COUNT_OFFSET],rcx
    mov [r12+NEBO_CANVAS_LAST_FRAME_COMMAND_COUNT_OFFSET],rcx
    mov [r12+NEBO_CANVAS_FRAME_SEQUENCE_OFFSET],rax
    inc qword [r12+NEBO_CANVAS_PRESENT_COUNT_OFFSET]
    mov [r12+NEBO_CANVAS_LAST_FRAME_HASH_OFFSET],rdx
    cmp qword [r12+NEBO_CANVAS_OWNER_CONTEXT_OFFSET],0
    jne .owner_bound
    mov [r12+NEBO_CANVAS_OWNER_CONTEXT_OFFSET],r15
.owner_bound:
    mov qword [r12+NEBO_CANVAS_COMMAND_COUNT_OFFSET],0
    and dword [r12+NEBO_CANVAS_FLAGS_OFFSET],~NEBO_CANVAS_FLAG_DIRTY
    or dword [r12+NEBO_CANVAS_FLAGS_OFFSET],NEBO_CANVAS_FLAG_PRESENTED
    mov rax,[rsp]
    and dword [rax+NEBO_WINDOW_FLAGS_OFFSET],~NEBO_HEADLESS_FLAG_REDRAW_PENDING
    mov rdi,r12
    call canvas_set_success
    jmp .return
.frame_exhausted:
    mov eax,NEBO_CANVAS_ERROR_FRAME_EXHAUSTED
    jmp .error_eax
.dimension:
    mov eax,NEBO_CANVAS_ERROR_DIMENSION_MISMATCH
    jmp .error_eax
.owner:
    mov eax,NEBO_CANVAS_ERROR_OWNER_MISMATCH
    jmp .error_eax
.stale:
    mov eax,NEBO_CANVAS_ERROR_STALE_WINDOW
    jmp .error_eax
.bad_state:
    mov eax,NEBO_CANVAS_ERROR_BAD_STATE
    jmp .error_eax
.closed:
    mov eax,NEBO_CANVAS_ERROR_CLOSED
    jmp .error_eax
.invalid:
    mov eax,NEBO_CANVAS_ERROR_INVALID_ARGUMENT
.error_eax:
    mov rdi,r12
    mov esi,eax
    mov edx,eax
    call canvas_set_failure
.return:
    add rsp,40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

nebo_canvas_close:
    push rbx
    push r12
    push r13
    mov r12,rdi
    call canvas_validate_internal
    test eax,eax
    jnz .return
    cmp dword [r12+NEBO_CANVAS_STATE_OFFSET],NEBO_CANVAS_STATE_CLOSED
    je .closed
    cmp qword [r12+NEBO_SOFTWARE_SURFACE_GENERATION_OFFSET],-1
    je .exhausted
    mov dword [r12+NEBO_CANVAS_STATE_OFFSET],NEBO_CANVAS_STATE_CLOSED
    mov qword [r12+NEBO_CANVAS_COMMAND_COUNT_OFFSET],0
    and dword [r12+NEBO_CANVAS_FLAGS_OFFSET],~NEBO_CANVAS_FLAG_DIRTY
    inc qword [r12+NEBO_SOFTWARE_SURFACE_GENERATION_OFFSET]
    mov rdi,r12
    call canvas_set_success
    jmp .return
.exhausted:
    mov rdi,r12
    mov esi,NEBO_CANVAS_ERROR_FRAME_EXHAUSTED
    mov edx,NEBO_CANVAS_ERROR_FRAME_EXHAUSTED
    call canvas_set_failure
    jmp .return
.closed:
    mov rdi,r12
    mov esi,NEBO_CANVAS_ERROR_CLOSED
    mov edx,NEBO_CANVAS_ERROR_CLOSED
    call canvas_set_failure
.return:
    pop r13
    pop r12
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
