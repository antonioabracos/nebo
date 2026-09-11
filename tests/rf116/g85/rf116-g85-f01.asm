bits 64
default rel

%include "compiler/semantic/name_style.inc"

extern neboc_name_style_classify
extern neboc_name_is_all_caps
global _start

%macro ASSERT_STYLE 3
    lea rdi, [rel %1]
    mov esi, %2
    call neboc_name_style_classify
    cmp eax, %3
    jne fail
%endmacro

%macro ASSERT_CAPS 3
    lea rdi, [rel %1]
    mov esi, %2
    call neboc_name_is_all_caps
    cmp eax, %3
    jne fail
%endmacro

section .text
_start:
    ASSERT_STYLE pi_name, pi_len, NEBOC_NAME_CAMEL_CASE
    ASSERT_STYLE max_retries_camel, max_retries_camel_len, NEBOC_NAME_CAMEL_CASE
    ASSERT_STYLE red_type, red_type_len, NEBOC_NAME_PASCAL_CASE
    ASSERT_STYLE http_type, http_type_len, NEBOC_NAME_PASCAL_CASE
    ASSERT_STYLE pi_caps, pi_caps_len, NEBOC_NAME_ALL_CAPS
    ASSERT_STYLE x_caps, x_caps_len, NEBOC_NAME_ALL_CAPS
    ASSERT_STYLE http2_port, http2_port_len, NEBOC_NAME_ALL_CAPS
    ASSERT_STYLE color_2, color_2_len, NEBOC_NAME_ALL_CAPS

    ASSERT_CAPS default_timeout, default_timeout_len, 1
    ASSERT_CAPS default_lower, default_lower_len, 0
    ASSERT_CAPS leading_underscore, leading_underscore_len, 0
    ASSERT_CAPS trailing_underscore, trailing_underscore_len, 0
    ASSERT_CAPS double_underscore, double_underscore_len, 0
    ASSERT_CAPS pascal_name, pascal_name_len, 0

    ASSERT_STYLE snake_name, snake_name_len, NEBOC_NAME_ORDINARY
    ASSERT_STYLE unicode_name, unicode_name_len, NEBOC_NAME_ORDINARY
    ASSERT_STYLE bad_punctuation, bad_punctuation_len, NEBOC_NAME_INVALID
    ASSERT_STYLE leading_digit, leading_digit_len, NEBOC_NAME_INVALID

    xor edi, edi
    xor esi, esi
    call neboc_name_style_classify
    test eax, eax
    jnz fail

    ; Pure classification must not mutate caller-owned adjacent state.
    mov rax, 0x1122334455667788
    cmp qword [rel sentinel], rax
    jne fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall

section .rodata
pi_name: db "pi"
pi_len equ $ - pi_name
max_retries_camel: db "maxRetries"
max_retries_camel_len equ $ - max_retries_camel
red_type: db "Red"
red_type_len equ $ - red_type
http_type: db "HTTPServer"
http_type_len equ $ - http_type
pi_caps: db "PI"
pi_caps_len equ $ - pi_caps
x_caps: db "X"
x_caps_len equ $ - x_caps
http2_port: db "HTTP2_PORT"
http2_port_len equ $ - http2_port
color_2: db "COLOR_2"
color_2_len equ $ - color_2
default_timeout: db "DEFAULT_TIMEOUT"
default_timeout_len equ $ - default_timeout
default_lower: db "DEFAULT_timeout"
default_lower_len equ $ - default_lower
leading_underscore: db "_HTTP_PORT"
leading_underscore_len equ $ - leading_underscore
trailing_underscore: db "HTTP_PORT_"
trailing_underscore_len equ $ - trailing_underscore
double_underscore: db "HTTP__PORT"
double_underscore_len equ $ - double_underscore
pascal_name: db "RedColor"
pascal_name_len equ $ - pascal_name
snake_name: db "red_color"
snake_name_len equ $ - snake_name
unicode_name: db 0xc3, 0x89, "clair"
unicode_name_len equ $ - unicode_name
bad_punctuation: db "BAD-NAME"
bad_punctuation_len equ $ - bad_punctuation
leading_digit: db "2FAST"
leading_digit_len equ $ - leading_digit

section .data
sentinel: dq 0x1122334455667788

section .note.GNU-stack noalloc noexec nowrite progbits
