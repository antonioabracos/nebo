; Nebo deterministic BGRA8 software surface — MF044
bits 64
default rel

%include "runtime/console/handles/console_handle.inc"
%include "runtime/console/document/console_document.inc"
%include "runtime/console/render/draw_command.inc"
%include "runtime/console/render/software_surface.inc"

extern nebo_draw_command_buffer_validate
extern nebo_fake_glyph_provider_validate
extern nebo_fake_glyph_utf8_next

global nebo_software_surface_init
global nebo_software_surface_validate
global nebo_software_surface_resize
global nebo_software_surface_execute
global nebo_software_surface_state_hash

section .text

nebo_surface_set_failure_internal:
    test rdi, rdi
    jz .failure_return
    mov [rdi+NEBO_SOFTWARE_SURFACE_LAST_STATUS_OFFSET], rsi
    mov [rdi+NEBO_SOFTWARE_SURFACE_LAST_ERROR_OFFSET], rdx
.failure_return:
    mov eax, esi
    ret

; checked_required_bytes(width, height) -> RAX bytes, RDX nonzero on failure.
; Inputs RDI width, RSI height.
nebo_surface_required_bytes_internal:
    xor edx, edx
    test rdi, rdi
    jz .required_error
    test rsi, rsi
    jz .required_error
    cmp rdi, NEBO_SURFACE_MAX_AXIS_PIXELS
    ja .required_error
    cmp rsi, NEBO_SURFACE_MAX_AXIS_PIXELS
    ja .required_error
    mov rax, rdi
    shl rax, 2
    jo .required_error
    mul rsi
    test rdx, rdx
    jnz .required_error
    cmp rax, NEBO_SURFACE_MAX_BYTES
    ja .required_error
    xor edx, edx
    ret
.required_error:
    xor eax, eax
    mov edx, 1
    ret

; fill_rect(surface*, x_px, y_px, width_px, height_px, BGRA32) -> status
nebo_surface_fill_rect_internal:
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
    test r12, r12
    jz .fill_invalid
    test r15, r15
    jz .fill_success
    test rbx, rbx
    jz .fill_success
    cmp r13, [r12+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET]
    jae .fill_success
    cmp r14, [r12+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET]
    jae .fill_success
    mov rax, [r12+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET]
    sub rax, r13
    cmp r15, rax
    jbe .fill_width_ok
    mov r15, rax
.fill_width_ok:
    mov rax, [r12+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET]
    sub rax, r14
    cmp rbx, rax
    jbe .fill_height_ok
    mov rbx, rax
.fill_height_ok:
    xor r10d, r10d
.fill_row_loop:
    cmp r10, rbx
    jae .fill_success
    mov rax, r14
    add rax, r10
    mul qword [r12+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET]
    test rdx, rdx
    jnz .fill_overflow
    mov r11, r13
    shl r11, 2
    add rax, r11
    add rax, [r12+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET]
    xor r11d, r11d
.fill_col_loop:
    cmp r11, r15
    jae .fill_next_row
    mov edx, [rsp]
    mov [rax+r11*4], edx
    inc r11
    jmp .fill_col_loop
.fill_next_row:
    inc r10
    jmp .fill_row_loop
.fill_success:
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .fill_done
.fill_overflow:
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .fill_done
.fill_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.fill_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; init(surface*, pixel_buffer*, byte_capacity, width_px, height_px) -> status
nebo_software_surface_init:
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
    test r12, r12
    jz .init_invalid_no_surface
    mov rdi, r12
    xor eax, eax
    mov ecx, NEBO_SOFTWARE_SURFACE_QWORDS
    cld
    rep stosq
    test r13, r13
    jz .init_invalid
    mov rdi, r15
    mov rsi, rbx
    call nebo_surface_required_bytes_internal
    test rdx, rdx
    jnz .init_dimensions
    cmp r14, rax
    jb .init_bytes
    mov [r12+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET], r13
    mov [r12+NEBO_SOFTWARE_SURFACE_BYTE_CAPACITY_OFFSET], r14
    mov [r12+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET], r15
    mov [r12+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET], rbx
    mov rax, r15
    shl rax, 2
    mov [r12+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET], rax
    mov qword [r12+NEBO_SOFTWARE_SURFACE_PIXEL_FORMAT_OFFSET], NEBO_SURFACE_PIXEL_FORMAT_BGRA8_PREMULTIPLIED
    mov qword [r12+NEBO_SOFTWARE_SURFACE_GENERATION_OFFSET], 1
    mov qword [r12+NEBO_SOFTWARE_SURFACE_FLAGS_OFFSET], NEBO_SOFTWARE_SURFACE_REQUIRED_FLAGS
    mov qword [r12+NEBO_SOFTWARE_SURFACE_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r12+NEBO_SOFTWARE_SURFACE_LAST_ERROR_OFFSET], NEBO_SURFACE_ERROR_NONE
    mov eax, NEBO_SURFACE_HASH_FNV1A32_OFFSET_BASIS
    mov [r12+NEBO_SOFTWARE_SURFACE_STATE_HASH_OFFSET], rax
    mov qword [r12+NEBO_SOFTWARE_SURFACE_EXECUTED_COMMANDS_OFFSET], 0
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .init_done
.init_dimensions:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_SURFACE_ERROR_DIMENSION_LIMIT
    call nebo_surface_set_failure_internal
    jmp .init_done
.init_bytes:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_SURFACE_ERROR_BYTE_LIMIT
    call nebo_surface_set_failure_internal
    jmp .init_done
.init_invalid:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_SURFACE_ERROR_BAD_ARGUMENT
    call nebo_surface_set_failure_internal
    jmp .init_done
.init_invalid_no_surface:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.init_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_software_surface_validate:
    test rdi, rdi
    jz .validate_invalid
    cmp qword [rdi+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET], 0
    je .validate_state
    mov rax, [rdi+NEBO_SOFTWARE_SURFACE_FLAGS_OFFSET]
    and eax, NEBO_SOFTWARE_SURFACE_REQUIRED_FLAGS
    cmp eax, NEBO_SOFTWARE_SURFACE_REQUIRED_FLAGS
    jne .validate_state
    cmp qword [rdi+NEBO_SOFTWARE_SURFACE_PIXEL_FORMAT_OFFSET], NEBO_SURFACE_PIXEL_FORMAT_BGRA8_PREMULTIPLIED
    jne .validate_state
    mov rax, [rdi+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET]
    shl rax, 2
    cmp rax, [rdi+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET]
    jne .validate_state
    mov rdi, [rdi+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET]
    test rdi, rdi
    jz .validate_state
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.validate_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.validate_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; resize(surface*, width_px, height_px) -> status. Storage remains caller-owned.
nebo_software_surface_resize:
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov rdi, r12
    call nebo_software_surface_validate
    test eax, eax
    jnz .resize_done
    mov rdi, r13
    mov rsi, r14
    call nebo_surface_required_bytes_internal
    test rdx, rdx
    jnz .resize_dimension
    cmp rax, [r12+NEBO_SOFTWARE_SURFACE_BYTE_CAPACITY_OFFSET]
    ja .resize_bytes
    mov [r12+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET], r13
    mov [r12+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET], r14
    mov rax, r13
    shl rax, 2
    mov [r12+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET], rax
    inc qword [r12+NEBO_SOFTWARE_SURFACE_GENERATION_OFFSET]
    mov qword [r12+NEBO_SOFTWARE_SURFACE_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r12+NEBO_SOFTWARE_SURFACE_LAST_ERROR_OFFSET], NEBO_SURFACE_ERROR_NONE
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .resize_done
.resize_dimension:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_SURFACE_ERROR_DIMENSION_LIMIT
    call nebo_surface_set_failure_internal
    jmp .resize_done
.resize_bytes:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_SURFACE_ERROR_BYTE_LIMIT
    call nebo_surface_set_failure_internal
.resize_done:
    pop r14
    pop r13
    pop r12
    ret

; execute(surface*, draw_buffer*, glyph_provider*) -> status
nebo_software_surface_execute:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 64
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov rdi, r12
    call nebo_software_surface_validate
    test eax, eax
    jnz .execute_done
    mov rdi, r13
    call nebo_draw_command_buffer_validate
    test eax, eax
    jnz .execute_command
    mov rdi, r14
    call nebo_fake_glyph_provider_validate
    test eax, eax
    jnz .execute_state
    mov qword [r12+NEBO_SOFTWARE_SURFACE_EXECUTED_COMMANDS_OFFSET], 0
    xor r15d, r15d
.execute_loop:
    cmp r15, [r13+NEBO_DRAW_BUFFER_COUNT_OFFSET]
    jae .execute_success
    mov rax, r15
    imul rax, NEBO_DRAW_COMMAND_SIZE
    add rax, [r13+NEBO_DRAW_BUFFER_COMMANDS_PTR_OFFSET]
    mov rbx, rax
    mov eax, [rbx+NEBO_DRAW_COMMAND_KIND_OFFSET]
    cmp eax, NEBO_DRAW_COMMAND_CLEAR
    je .execute_clear
    cmp eax, NEBO_DRAW_COMMAND_FILL_RECT
    je .execute_fill
    cmp eax, NEBO_DRAW_COMMAND_STROKE_RECT
    je .execute_stroke
    cmp eax, NEBO_DRAW_COMMAND_DRAW_GLYPH_RUN
    je .execute_glyphs
    cmp eax, NEBO_DRAW_COMMAND_PUSH_CLIP
    je .execute_count
    cmp eax, NEBO_DRAW_COMMAND_POP_CLIP
    je .execute_count
    cmp eax, NEBO_DRAW_COMMAND_DRAW_CARET
    je .execute_fill
    jmp .execute_unsupported
.execute_clear:
    mov rdi, r12
    xor esi, esi
    xor edx, edx
    mov rcx, [r12+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET]
    mov r8, [r12+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET]
    mov r9, [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET]
    call nebo_surface_fill_rect_internal
    test eax, eax
    jnz .execute_state
    jmp .execute_count
.execute_fill:
    mov rdi, r12
    mov rsi, [rbx+NEBO_DRAW_COMMAND_X_OFFSET]
    sar rsi, NEBO_LAYOUT_FRACTION_BITS
    mov rdx, [rbx+NEBO_DRAW_COMMAND_Y_OFFSET]
    sar rdx, NEBO_LAYOUT_FRACTION_BITS
    mov rcx, [rbx+NEBO_DRAW_COMMAND_WIDTH_OFFSET]
    sar rcx, NEBO_LAYOUT_FRACTION_BITS
    mov r8, [rbx+NEBO_DRAW_COMMAND_HEIGHT_OFFSET]
    sar r8, NEBO_LAYOUT_FRACTION_BITS
    mov r9, [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET]
    call nebo_surface_fill_rect_internal
    test eax, eax
    jnz .execute_state
    jmp .execute_count
.execute_stroke:
    ; Top.
    mov rdi, r12
    mov rsi, [rbx+NEBO_DRAW_COMMAND_X_OFFSET]
    sar rsi, NEBO_LAYOUT_FRACTION_BITS
    mov rdx, [rbx+NEBO_DRAW_COMMAND_Y_OFFSET]
    sar rdx, NEBO_LAYOUT_FRACTION_BITS
    mov rcx, [rbx+NEBO_DRAW_COMMAND_WIDTH_OFFSET]
    sar rcx, NEBO_LAYOUT_FRACTION_BITS
    mov r8d, 1
    mov r9, [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET]
    call nebo_surface_fill_rect_internal
    test eax, eax
    jnz .execute_state
    ; Bottom.
    mov rdi, r12
    mov rsi, [rbx+NEBO_DRAW_COMMAND_X_OFFSET]
    sar rsi, NEBO_LAYOUT_FRACTION_BITS
    mov rdx, [rbx+NEBO_DRAW_COMMAND_Y_OFFSET]
    add rdx, [rbx+NEBO_DRAW_COMMAND_HEIGHT_OFFSET]
    sar rdx, NEBO_LAYOUT_FRACTION_BITS
    dec rdx
    mov rcx, [rbx+NEBO_DRAW_COMMAND_WIDTH_OFFSET]
    sar rcx, NEBO_LAYOUT_FRACTION_BITS
    mov r8d, 1
    mov r9, [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET]
    call nebo_surface_fill_rect_internal
    test eax, eax
    jnz .execute_state
    ; Left.
    mov rdi, r12
    mov rsi, [rbx+NEBO_DRAW_COMMAND_X_OFFSET]
    sar rsi, NEBO_LAYOUT_FRACTION_BITS
    mov rdx, [rbx+NEBO_DRAW_COMMAND_Y_OFFSET]
    sar rdx, NEBO_LAYOUT_FRACTION_BITS
    mov ecx, 1
    mov r8, [rbx+NEBO_DRAW_COMMAND_HEIGHT_OFFSET]
    sar r8, NEBO_LAYOUT_FRACTION_BITS
    mov r9, [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET]
    call nebo_surface_fill_rect_internal
    test eax, eax
    jnz .execute_state
    ; Right.
    mov rdi, r12
    mov rsi, [rbx+NEBO_DRAW_COMMAND_X_OFFSET]
    add rsi, [rbx+NEBO_DRAW_COMMAND_WIDTH_OFFSET]
    sar rsi, NEBO_LAYOUT_FRACTION_BITS
    dec rsi
    mov rdx, [rbx+NEBO_DRAW_COMMAND_Y_OFFSET]
    sar rdx, NEBO_LAYOUT_FRACTION_BITS
    mov ecx, 1
    mov r8, [rbx+NEBO_DRAW_COMMAND_HEIGHT_OFFSET]
    sar r8, NEBO_LAYOUT_FRACTION_BITS
    mov r9, [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET]
    call nebo_surface_fill_rect_internal
    test eax, eax
    jnz .execute_state
    jmp .execute_count
.execute_glyphs:
    mov rax, [r13+NEBO_DRAW_BUFFER_DOCUMENT_PTR_OFFSET]
    test rax, rax
    jz .execute_command
    mov r10, [rax+NEBO_CONSOLE_DOCUMENT_TEXT_STORE_PTR_OFFSET]
    add r10, [rbx+NEBO_DRAW_COMMAND_SOURCE_OFFSET_OFFSET]
    mov [rsp+16], r10                 ; current text pointer
    mov rax, [rbx+NEBO_DRAW_COMMAND_SOURCE_LENGTH_OFFSET]
    mov [rsp+24], rax                 ; remaining bytes
    mov rax, [rbx+NEBO_DRAW_COMMAND_GLYPH_COUNT_OFFSET]
    mov [rsp+32], rax                 ; remaining glyphs
    mov rax, [rbx+NEBO_DRAW_COMMAND_X_OFFSET]
    sar rax, NEBO_LAYOUT_FRACTION_BITS
    mov [rsp+40], rax                 ; x px
    mov rax, [rbx+NEBO_DRAW_COMMAND_Y_OFFSET]
    sar rax, NEBO_LAYOUT_FRACTION_BITS
    add rax, 3
    mov [rsp+48], rax                 ; y px
.glyph_loop:
    cmp qword [rsp+32], 0
    je .execute_count
    cmp qword [rsp+24], 0
    je .execute_command
    mov rdi, [rsp+16]
    mov rsi, [rsp+24]
    lea rdx, [rsp]
    lea rcx, [rsp+8]
    call nebo_fake_glyph_utf8_next
    test eax, eax
    jnz .execute_command
    mov rdi, r12
    mov rsi, [rsp+40]
    mov rdx, [rsp+48]
    mov ecx, 5
    mov r8d, 9
    mov r9, [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET]
    call nebo_surface_fill_rect_internal
    test eax, eax
    jnz .execute_state
    ; Content-dependent black notch inside the synthetic glyph.
    mov rax, [rsp]
    and eax, 3
    inc eax
    mov rdi, r12
    mov rsi, [rsp+40]
    add rsi, rax
    mov rdx, [rsp+48]
    add rdx, 2
    mov ecx, 1
    mov r8d, 5
    mov r9d, NEBO_COLOR_BGRA_BLACK
    call nebo_surface_fill_rect_internal
    test eax, eax
    jnz .execute_state
    mov rax, [rsp+8]
    add [rsp+16], rax
    sub [rsp+24], rax
    add qword [rsp+40], 8
    dec qword [rsp+32]
    jmp .glyph_loop
.execute_count:
    inc qword [r12+NEBO_SOFTWARE_SURFACE_EXECUTED_COMMANDS_OFFSET]
    inc r15
    jmp .execute_loop
.execute_success:
    mov qword [r12+NEBO_SOFTWARE_SURFACE_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r12+NEBO_SOFTWARE_SURFACE_LAST_ERROR_OFFSET], NEBO_SURFACE_ERROR_NONE
    lea rsi, [r12+NEBO_SOFTWARE_SURFACE_STATE_HASH_OFFSET]
    mov rdi, r12
    call nebo_software_surface_state_hash
    jmp .execute_done
.execute_unsupported:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_SURFACE_ERROR_UNSUPPORTED_COMMAND
    call nebo_surface_set_failure_internal
    jmp .execute_done
.execute_command:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_SURFACE_ERROR_COMMAND_CORRUPT
    call nebo_surface_set_failure_internal
    jmp .execute_done
.execute_state:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_SURFACE_ERROR_BAD_STATE
    call nebo_surface_set_failure_internal
.execute_done:
    add rsp, 64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; surface_state_hash(surface*, out*) -> status
nebo_software_surface_state_hash:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .hash_invalid
    test r13, r13
    jz .hash_invalid
    mov eax, NEBO_SURFACE_HASH_FNV1A32_OFFSET_BASIS
    mov edx, NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET
.hash_header:
    cmp edx, NEBO_SOFTWARE_SURFACE_STATE_HASH_OFFSET
    jae .hash_pixels
    mov rbx, [r12+rdx]
    mov ecx, 8
.hash_header_bytes:
    xor al, bl
    imul rax, rax, NEBO_SURFACE_HASH_FNV1A32_PRIME
    shr rbx, 8
    dec ecx
    jnz .hash_header_bytes
    add edx, 8
    jmp .hash_header
.hash_pixels:
    mov r8, [r12+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET]
    imul r8, [r12+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET]
    mov r9, [r12+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET]
    xor r10d, r10d
.hash_pixel_loop:
    cmp r10, r8
    jae .hash_done
    xor al, [r9+r10]
    imul rax, rax, NEBO_SURFACE_HASH_FNV1A32_PRIME
    inc r10
    jmp .hash_pixel_loop
.hash_done:
    mov [r13], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .hash_return
.hash_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.hash_return:
    pop r13
    pop r12
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
