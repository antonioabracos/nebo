bits 64
default rel
%include "runtime/widgets/widgets.inc"

section .data align=8
name_header: db 'Header'
text_header: db 'Nebo widgets'
name_action: db 'Action'
text_action: db 'Continue'
name_input: db 'Message'

section .bss align=16
tree: resb NEBO_UI_TREE_SIZE
nodes: resb NEBO_UI_NODE_SIZE*8
events: resb NEBO_UI_EVENT_SIZE*16
input_storage: resb 64
row_index: resq 1
label_index: resq 1
button_index: resq 1
input_index: resq 1
canvas: resb NEBO_CANVAS_SIZE
pixels: resb 96*48*4
commands: resb NEBO_CANVAS_COMMAND_SIZE*64

section .text
global _start
_start:
    lea rdi,[rel tree]
    lea rsi,[rel nodes]
    mov edx,8
    lea rcx,[rel events]
    mov r8d,16
    mov r9d,96
    sub rsp,16
    mov qword [rsp],48
    mov qword [rsp+8],0x1807
    call nebo_ui_tree_init
    add rsp,16
    test eax,eax
    jnz .fail

    lea rdi,[rel tree]
    xor esi,esi
    mov edx,2
    lea rcx,[rel row_index]
    call nebo_ui_row
    test eax,eax
    jnz .fail

    lea rdi,[rel tree]
    mov rsi,[rel row_index]
    lea rdx,[rel name_header]
    mov ecx,6
    lea r8,[rel text_header]
    mov r9d,12
    sub rsp,16
    lea rax,[rel label_index]
    mov [rsp],rax
    call nebo_ui_label
    add rsp,16
    test eax,eax
    jnz .fail

    lea rdi,[rel tree]
    mov rsi,[rel row_index]
    lea rdx,[rel name_action]
    mov ecx,6
    lea r8,[rel text_action]
    mov r9d,8
    sub rsp,16
    lea rax,[rel button_index]
    mov [rsp],rax
    call nebo_ui_button
    add rsp,16
    test eax,eax
    jnz .fail

    lea rdi,[rel tree]
    mov rsi,[rel row_index]
    lea rdx,[rel name_input]
    mov ecx,7
    lea r8,[rel input_storage]
    mov r9d,64
    sub rsp,16
    mov qword [rsp],0
    lea rax,[rel input_index]
    mov [rsp+8],rax
    call nebo_ui_text_input
    add rsp,16
    test eax,eax
    jnz .fail

    lea rdi,[rel tree]
    call nebo_ui_layout
    test eax,eax
    jnz .fail

    lea rdi,[rel canvas]
    lea rsi,[rel pixels]
    mov edx,96*48*4
    mov ecx,96
    mov r8d,48
    lea r9,[rel commands]
    sub rsp,16
    mov qword [rsp],64
    call nebo_canvas_create
    add rsp,16
    test eax,eax
    jnz .fail

    lea rdi,[rel tree]
    lea rsi,[rel canvas]
    call nebo_ui_render
    test eax,eax
    jnz .fail

    lea rdi,[rel tree]
    call nebo_ui_focus_next
    test eax,eax
    jnz .fail

    mov eax,60
    xor edi,edi
    syscall
.fail:
    mov eax,60
    mov edi,1
    syscall
