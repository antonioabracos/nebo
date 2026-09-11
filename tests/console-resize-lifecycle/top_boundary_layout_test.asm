; Exact layout-owner oracle for the TOP minimum-height boundary.
; No X11 connection, input event, pointer control, or product instrumentation.
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/document/console_document.inc"
%include "runtime/console/layout/console_layout.inc"
%include "runtime/console/render/fake_glyph_provider.inc"

extern nebo_console_document_init
extern nebo_console_document_append_text
extern nebo_fake_glyph_provider_init
extern nebo_console_layout_init
extern nebo_console_layout_document

global _start

%define SYS_EXIT 60
%define TEST_NODE_CAPACITY 16
%define TEST_TEXT_CAPACITY 128
%define TEST_BOX_CAPACITY 32

section .rodata align=8
probe_bytes: db "Move: "
probe_descriptor:
    dq probe_bytes, 6
    dd 0
    dw NEBO_RUNTIME_TEXT_ENCODING_UTF8, NEBO_RUNTIME_TEXT_LIFETIME_STATIC

section .bss align=64
document: resb NEBO_CONSOLE_DOCUMENT_SIZE
nodes: resb TEST_NODE_CAPACITY*NEBO_CONSOLE_NODE_HEADER_SIZE
text_store: resb TEST_TEXT_CAPACITY
provider: resb NEBO_FAKE_GLYPH_PROVIDER_SIZE
layout: resb NEBO_LAYOUT_TREE_SIZE
boxes: resb TEST_BOX_CAPACITY*NEBO_LAYOUT_BOX_SIZE

section .text
_start:
    lea rdi, [rel document]
    mov rsi, 0x0000000100000000
    lea rdx, [rel nodes]
    mov ecx, TEST_NODE_CAPACITY
    lea r8, [rel text_store]
    mov r9d, TEST_TEXT_CAPACITY
    call nebo_console_document_init
    test eax, eax
    jnz .fail_40
    lea rdi, [rel document]
    lea rsi, [rel probe_descriptor]
    call nebo_console_document_append_text
    test eax, eax
    jnz .fail_41
    lea rdi, [rel provider]
    call nebo_fake_glyph_provider_init
    test eax, eax
    jnz .fail_42

    ; 64px passes layout_init but leaves a 14px content box. A canonical
    ; 16px line therefore fails in layout_document with OVERFLOW.
    mov edi, 64
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, 14
    call check_height
    test eax, eax
    jnz .fail_43

    ; 65px leaves 15px and is still one pixel short.
    mov edi, 65
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, 15
    call check_height
    test eax, eax
    jnz .fail_44

    ; 66px leaves one complete 16px line and succeeds exactly.
    mov edi, 66
    mov esi, NEBO_CONSOLE_STATUS_OK
    mov edx, 16
    call check_height
    test eax, eax
    jnz .fail_45

    xor edi, edi
    jmp .exit
.fail_40:
    mov edi, 40
    jmp .exit
.fail_41:
    mov edi, 41
    jmp .exit
.fail_42:
    mov edi, 42
    jmp .exit
.fail_43:
    mov edi, 43
    jmp .exit
.fail_44:
    mov edi, 44
    jmp .exit
.fail_45:
    mov edi, 45
.exit:
    mov eax, SYS_EXIT
    syscall
    ud2

; EDI=height pixels, ESI=expected layout_document status,
; EDX=expected content height pixels.
check_height:
    push rbx
    push r12
    push r13
    mov r12d, edi
    mov r13d, esi
    mov ebx, edx
    lea rdi, [rel layout]
    lea rsi, [rel boxes]
    mov edx, TEST_BOX_CAPACITY
    mov ecx, 640*NEBO_LAYOUT_ONE
    mov r8d, r12d
    shl r8, NEBO_LAYOUT_FRACTION_BITS
    lea r9, [rel provider]
    call nebo_console_layout_init
    test eax, eax
    jnz .height_fail
    mov eax, ebx
    shl rax, NEBO_LAYOUT_FRACTION_BITS
    cmp [rel layout+NEBO_LAYOUT_TREE_CONTENT_HEIGHT_OFFSET], rax
    jne .height_fail
    lea rdi, [rel layout]
    lea rsi, [rel document]
    call nebo_console_layout_document
    cmp eax, r13d
    jne .height_fail
    test r13d, r13d
    jz .height_ok
    cmp qword [rel layout+NEBO_LAYOUT_TREE_LAST_ERROR_OFFSET], NEBO_LAYOUT_ERROR_OVERFLOW
    jne .height_fail
.height_ok:
    xor eax, eax
    jmp .height_done
.height_fail:
    mov eax, 1
.height_done:
    pop r13
    pop r12
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
