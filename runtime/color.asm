; Nebo Assembly — TIPO-PUBLICO-COLOR-CONSTRUCTORS-PARSING-E-ABI immutable sRGB RGBA8 value operations
bits 64
default rel
%include "runtime/color.inc"
global nebo_color_copy
global nebo_color_rgb_lowering
global nebo_color_rgba_lowering
global nebo_color_hex_literal
global nebo_color_parse_hex
global nebo_color_channels
global nebo_color_red
global nebo_color_green
global nebo_color_blue
global nebo_color_alpha
global nebo_color_with_alpha
global nebo_color_is_opaque
global nebo_color_equal
global nebo_color_hash
global nebo_color_serialize_hex
global nebo_color_to_hex
global nebo_color_to_hex_with_alpha
section .text
; edi=logical 0xRRGGBBAA Color value, rsi=out dword.
nebo_color_copy:
    test rsi, rsi
    jz .invalid
    mov [rsi], edi
    xor eax, eax
    ret
.invalid:
    mov eax, NEBO_COLOR_INVALID
    ret

; rdi=r, rsi=g, rdx=b, rcx=out dword
nebo_color_rgb_lowering:
    cmp rdi, 255
    ja color_ctor_range
    cmp rsi, 255
    ja color_ctor_range
    cmp rdx, 255
    ja color_ctor_range
    test rcx, rcx
    jz color_ctor_invalid
    mov eax, edi
    shl eax, 24
    mov r8d, esi
    shl r8d, 16
    or eax, r8d
    mov r8d, edx
    shl r8d, 8
    or eax, r8d
    or eax, NEBO_COLOR_OPAQUE_ALPHA
    mov [rcx], eax
    xor eax, eax
    ret
; rdi=r, rsi=g, rdx=b, rcx=a, r8=out dword
nebo_color_rgba_lowering:
    cmp rdi, 255
    ja color_ctor_range
    cmp rsi, 255
    ja color_ctor_range
    cmp rdx, 255
    ja color_ctor_range
    cmp rcx, 255
    ja color_ctor_range
    test r8, r8
    jz color_ctor_invalid
    mov eax, edi
    shl eax, 24
    mov r9d, esi
    shl r9d, 16
    or eax, r9d
    mov r9d, edx
    shl r9d, 8
    or eax, r9d
    or eax, ecx
    mov [r8], eax
    xor eax, eax
    ret
color_ctor_range:
    mov eax, NEBO_COLOR_CHANNEL_RANGE
    ret
color_ctor_invalid:
    mov eax, NEBO_COLOR_INVALID
    ret

; rdi=TextLiteral bytes, rsi=len (7 or 9), rdx=out dword.
nebo_color_hex_literal:
    test rdi, rdi
    jz color_hex_invalid
    test rdx, rdx
    jz color_hex_invalid
    cmp rsi, 7
    je color_hex_length_ok
    cmp rsi, 9
    jne color_hex_invalid
color_hex_length_ok:
    cmp byte [rdi], '#'
    jne color_hex_invalid
    xor eax, eax
    mov ecx, 1
color_hex_loop:
    cmp rcx, rsi
    jae color_hex_commit
    movzx r8d, byte [rdi + rcx]
    cmp r8b, '0'
    jb color_hex_invalid
    cmp r8b, '9'
    jbe color_hex_digit
    or r8b, 0x20
    cmp r8b, 'a'
    jb color_hex_invalid
    cmp r8b, 'f'
    ja color_hex_invalid
    sub r8d, 'a' - 10
    jmp color_hex_accumulate
color_hex_digit:
    sub r8d, '0'
color_hex_accumulate:
    shl eax, 4
    or eax, r8d
    inc rcx
    jmp color_hex_loop
color_hex_commit:
    cmp rsi, 7
    jne color_hex_store
    shl eax, 8
    or eax, NEBO_COLOR_OPAQUE_ALPHA
color_hex_store:
    mov [rdx], eax
    xor eax, eax
    ret
color_hex_invalid:
    mov eax, NEBO_COLOR_HEX_INVALID
    ret

; rdi=dynamic Text bytes, rsi=len, rdx=out Result<Color,ColorParseError>.
; Parse failures are represented in the Result and are not silent defaults.
nebo_color_parse_hex:
    test rdx, rdx
    jz color_parse_invalid
    push rbx
    push r12
    push r13
    sub rsp, 16
    mov rbx, rdx
    mov r12, rdi
    mov r13, rsi
    lea rdx, [rsp]
    call nebo_color_hex_literal
    test eax, eax
    jnz color_parse_error
    mov eax, [rsp]
    mov [rbx + NEBO_COLOR_RESULT_VALUE_OFFSET], eax
    mov qword [rbx + NEBO_COLOR_RESULT_IS_OK_OFFSET], 1
    mov qword [rbx + NEBO_COLOR_RESULT_ERROR_OFFSET], 0
    mov qword [rbx + NEBO_COLOR_RESULT_ERROR_INDEX_OFFSET], 0
    xor eax, eax
    jmp color_parse_done
color_parse_error:
    xor ecx, ecx
    cmp r13, 7
    je color_parse_scan
    cmp r13, 9
    je color_parse_scan
    mov rcx, r13
    jmp color_parse_commit_error
color_parse_scan:
    test r12, r12
    jz color_parse_commit_error
    cmp byte [r12], '#'
    jne color_parse_commit_error
    mov ecx, 1
color_parse_scan_loop:
    cmp rcx, r13
    jae color_parse_commit_error
    mov al, [r12 + rcx]
    cmp al, '0'
    jb color_parse_commit_error
    cmp al, '9'
    jbe color_parse_scan_next
    or al, 0x20
    cmp al, 'a'
    jb color_parse_commit_error
    cmp al, 'f'
    ja color_parse_commit_error
color_parse_scan_next:
    inc rcx
    jmp color_parse_scan_loop
color_parse_commit_error:
    mov dword [rbx + NEBO_COLOR_RESULT_VALUE_OFFSET], 0
    mov qword [rbx + NEBO_COLOR_RESULT_IS_OK_OFFSET], 0
    mov qword [rbx + NEBO_COLOR_RESULT_ERROR_OFFSET], NEBO_COLOR_PARSE_ERROR_INVALID_HEX
    mov [rbx + NEBO_COLOR_RESULT_ERROR_INDEX_OFFSET], rcx
    xor eax, eax
color_parse_done:
    add rsp, 16
    pop r13
    pop r12
    pop rbx
    ret
color_parse_invalid:
    mov eax, NEBO_COLOR_INVALID
    ret

; edi=Color, rsi=out four bytes in r,g,b,a order.
nebo_color_channels:
    test rsi, rsi
    jz .channels_invalid
    mov eax, edi
    shr eax, 24
    mov [rsi], al
    mov eax, edi
    shr eax, 16
    mov [rsi + 1], al
    mov eax, edi
    shr eax, 8
    mov [rsi + 2], al
    mov eax, edi
    mov [rsi + 3], al
    xor eax, eax
    ret
.channels_invalid:
    mov eax, NEBO_COLOR_INVALID
    ret

; edi=Color -> eax=channel. Color remains an opaque public value even though
; its canonical ABI representation is a four-byte logical RGBA word.
nebo_color_red:
    mov eax, edi
    shr eax, 24
    ret

nebo_color_green:
    mov eax, edi
    shr eax, 16
    and eax, 0xff
    ret

nebo_color_blue:
    mov eax, edi
    shr eax, 8
    and eax, 0xff
    ret

nebo_color_alpha:
    mov eax, edi
    and eax, 0xff
    ret

; edi=Color, esi=new alpha, rdx=out Color. Checked and failure-atomic.
nebo_color_with_alpha:
    cmp rsi, 255
    ja .with_alpha_range
    test rdx, rdx
    jz .with_alpha_invalid
    mov eax, edi
    and eax, 0xffffff00
    or eax, esi
    mov [rdx], eax
    xor eax, eax
    ret
.with_alpha_range:
    mov eax, NEBO_COLOR_CHANNEL_RANGE
    ret
.with_alpha_invalid:
    mov eax, NEBO_COLOR_INVALID
    ret

; edi=Color -> eax=Bool.
nebo_color_is_opaque:
    and edi, 0xff
    cmp edi, NEBO_COLOR_OPAQUE_ALPHA
    sete al
    movzx eax, al
    ret

; edi=a, esi=b -> eax boolean.
nebo_color_equal:
    cmp edi, esi
    sete al
    movzx eax, al
    ret

; edi=Color -> rax stable FNV-1a hash over logical RGBA bytes.
nebo_color_hash:
    mov rax, 0xcbf29ce484222325
    mov r8, 0x100000001b3
    mov ecx, 24
.hash_next:
    mov edx, edi
    shr edx, cl
    and edx, 0xff
    xor rax, rdx
    imul rax, r8
    sub ecx, 8
    jns .hash_next
    ret

; edi=Color, rsi=out bytes, rdx=capacity, rcx=include alpha boolean.
; Returns byte count in rdx on success, canonical uppercase, no trailing NUL.
nebo_color_serialize_hex:
    test rsi, rsi
    jz .serialize_invalid
    mov r8d, 7
    test rcx, rcx
    jz .serialize_size_ready
    mov r8d, 9
.serialize_size_ready:
    cmp rdx, r8
    jb .serialize_capacity
    mov byte [rsi], '#'
    mov r9d, 24
    mov r10d, 1
    mov r11d, 3
    test rcx, rcx
    jz .serialize_loop
    mov r11d, 4
.serialize_loop:
    test r11d, r11d
    jz .serialize_done
    mov eax, edi
    mov ecx, r9d
    shr eax, cl
    and eax, 0xff
    mov edx, eax
    shr eax, 4
    call color_hex_digit_upper
    mov [rsi + r10], al
    inc r10
    mov eax, edx
    and eax, 0x0f
    call color_hex_digit_upper
    mov [rsi + r10], al
    inc r10
    sub r9d, 8
    dec r11d
    jmp .serialize_loop
.serialize_done:
    mov rdx, r8
    xor eax, eax
    ret
.serialize_capacity:
    mov eax, NEBO_COLOR_CAPACITY
    ret
.serialize_invalid:
    mov eax, NEBO_COLOR_INVALID
    ret

; Public Text serialization entry points. The caller owns the bounded Text
; storage; no allocation or hidden libc dependency is introduced.
nebo_color_to_hex:
    xor ecx, ecx
    sub rsp, 8
    call nebo_color_serialize_hex
    add rsp, 8
    ret

nebo_color_to_hex_with_alpha:
    mov ecx, 1
    sub rsp, 8
    call nebo_color_serialize_hex
    add rsp, 8
    ret

color_hex_digit_upper:
    cmp al, 9
    jbe .digit
    add al, 'A' - 10
    ret
.digit:
    add al, '0'
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
