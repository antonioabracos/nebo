bits 64
default rel
%include "runtime/textual/render_console.inc"

section .rodata
payload: db '<','o','k','>'
secret: db 's','e','c','r','e','t'
expected_html: db '&','l','t',';','o','k','&','g','t',';',10,'[','r','e','d','a','c','t','e','d',']'
expected_html_len equ $ - expected_html
expected_plain: db '<','o','k','>',10,'[','r','e','d','a','c','t','e','d',']'
expected_plain_len equ $ - expected_plain

section .data
nodes:
    dq RENDER_NODE_TEXT, RENDER_FLAG_FALLBACK, payload, 4, 0, 0
    dq RENDER_NODE_BREAK, RENDER_FLAG_FALLBACK, 0, 0, 0, 0
    dq RENDER_NODE_TEXT, RENDER_FLAG_FALLBACK | RENDER_FLAG_PRIVATE | RENDER_FLAG_REDACT, secret, 6, 0, 0
buffer: times 64 db 0xaa
atomic_buffer: times 64 db 0xaa

section .text
extern neboc_render_feature_available
extern neboc_render_feature_validate
extern neboc_render_plan_validate
extern neboc_render_plan_measure
extern neboc_render_plan_write
global _start
_start:
    mov edi, 7306
    call neboc_render_feature_available
    cmp eax, 1
    jne .fail

    mov edi, 7306
    mov esi, RENDER_FLAG_FALLBACK | RENDER_FLAG_REDACT
    mov edx, 32
    mov ecx, 2
    mov r8d, RENDER_TARGET_HTML
    call neboc_render_feature_validate
    test eax, eax
    jnz .fail

    mov edi, 7306
    mov esi, 0
    mov edx, 16
    mov ecx, 2
    mov r8d, RENDER_TARGET_HTML
    call neboc_render_feature_validate
    test eax, eax
    jz .fail

    mov edi, 9999
    call neboc_render_feature_available
    test eax, eax
    jnz .fail

    mov rdi, nodes
    mov esi, 3
    mov edx, RENDER_TARGET_HTML
    call neboc_render_plan_validate
    test eax, eax
    jnz .fail

    mov rdi, nodes
    mov esi, 3
    mov edx, RENDER_TARGET_HTML
    call neboc_render_plan_measure
    cmp rax, expected_html_len
    jne .fail

    mov rdi, nodes
    mov esi, 3
    mov edx, RENDER_TARGET_HTML
    mov rcx, buffer
    mov r8d, 64
    call neboc_render_plan_write
    cmp rax, expected_html_len
    jne .fail
    mov rsi, buffer
    mov rdi, expected_html
    mov ecx, expected_html_len
    repe cmpsb
    jne .fail

    mov rdi, nodes
    mov esi, 3
    mov edx, RENDER_TARGET_HTML
    mov rcx, atomic_buffer
    mov r8d, expected_html_len - 1
    call neboc_render_plan_write
    cmp rax, -RENDER_E_CAPACITY
    jne .fail
    cmp byte [atomic_buffer], 0xaa
    jne .fail

    xor edi, edi
    mov eax, 60
    syscall
.fail:
    mov edi, 73
    add edi, 6
    mov eax, 60
    syscall
