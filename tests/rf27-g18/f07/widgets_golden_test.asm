bits 64
default rel
%include "runtime/widgets/widgets.inc"

%define GOLDEN_MAGIC 0x4e42554731384637
%define GOLDEN_SIZE 1344

%macro CHECK_EAX 0
    test eax,eax
    jnz .fail
%endmacro

%macro CLEAR_WINDOW_EVENT 0
    lea rdi,[rel window_event]
    mov ecx,NEBO_WINDOW_EVENT_QWORDS
    xor eax,eax
    rep stosq
%endmacro

section .data align=8
name_title: db 'Title'
text_title: db 'Nebo UI'
name_run: db 'Run'
text_run: db 'Run'
name_input: db 'Name'
name_status: db 'Status'
text_status: db 'Ready'
name_ok: db 'OK'
text_ok: db 'OK'
name_cancel: db 'Cancel'
text_cancel: db 'Cancel'
name_hint: db 'Hint'
text_hint: db 'Tab to move'

section .bss align=16
tree: resb NEBO_UI_TREE_SIZE
nodes: resb NEBO_UI_NODE_SIZE*16
events: resb NEBO_UI_EVENT_SIZE*32
input_storage: resb 32
window_event: resb NEBO_WINDOW_EVENT_SIZE
row_index: resq 1
title_index: resq 1
run_index: resq 1
input_index: resq 1
column_index: resq 1
status_index: resq 1
grid_index: resq 1
ok_index: resq 1
cancel_index: resq 1
hint_index: resq 1
golden_output: resb GOLDEN_SIZE

section .text
global _start
_start:
%if NEBO_UI_TREE_SIZE != 192
%error ui_tree_size
%endif
%if NEBO_UI_NODE_SIZE != 192
%error ui_node_size
%endif
%if NEBO_UI_EVENT_SIZE != 64
%error ui_event_size
%endif
%if NEBO_UI_ACCESS_SIZE != 96
%error accessibility_size
%endif

    lea rdi,[rel tree]
    lea rsi,[rel nodes]
    mov edx,16
    lea rcx,[rel events]
    mov r8d,32
    mov r9d,64
    sub rsp,16
    mov qword [rsp],48
    mov qword [rsp+8],0x707
    call nebo_ui_tree_init
    add rsp,16
    CHECK_EAX

    lea rdi,[rel tree]
    xor esi,esi
    mov edx,1
    lea rcx,[rel row_index]
    call nebo_ui_row
    CHECK_EAX

    lea rdi,[rel tree]
    mov rsi,[rel row_index]
    lea rdx,[rel name_title]
    mov ecx,5
    lea r8,[rel text_title]
    mov r9d,7
    sub rsp,16
    lea rax,[rel title_index]
    mov [rsp],rax
    call nebo_ui_label
    add rsp,16
    CHECK_EAX

    lea rdi,[rel tree]
    mov rsi,[rel row_index]
    lea rdx,[rel name_run]
    mov ecx,3
    lea r8,[rel text_run]
    mov r9d,3
    sub rsp,16
    lea rax,[rel run_index]
    mov [rsp],rax
    call nebo_ui_button
    add rsp,16
    CHECK_EAX

    lea rdi,[rel tree]
    mov rsi,[rel row_index]
    lea rdx,[rel name_input]
    mov ecx,4
    lea r8,[rel input_storage]
    mov r9d,32
    sub rsp,16
    mov qword [rsp],0
    lea rax,[rel input_index]
    mov [rsp+8],rax
    call nebo_ui_text_input
    add rsp,16
    CHECK_EAX

    lea rdi,[rel tree]
    xor esi,esi
    mov edx,1
    lea rcx,[rel column_index]
    call nebo_ui_column
    CHECK_EAX

    lea rdi,[rel tree]
    mov rsi,[rel column_index]
    lea rdx,[rel name_status]
    mov ecx,6
    lea r8,[rel text_status]
    mov r9d,5
    sub rsp,16
    lea rax,[rel status_index]
    mov [rsp],rax
    call nebo_ui_label
    add rsp,16
    CHECK_EAX

    lea rdi,[rel tree]
    mov rsi,[rel column_index]
    mov edx,1
    mov ecx,2
    lea r8,[rel grid_index]
    call nebo_ui_grid
    CHECK_EAX

    lea rdi,[rel tree]
    mov rsi,[rel grid_index]
    lea rdx,[rel name_ok]
    mov ecx,2
    lea r8,[rel text_ok]
    mov r9d,2
    sub rsp,16
    lea rax,[rel ok_index]
    mov [rsp],rax
    call nebo_ui_button
    add rsp,16
    CHECK_EAX

    lea rdi,[rel tree]
    mov rsi,[rel grid_index]
    lea rdx,[rel name_cancel]
    mov ecx,6
    lea r8,[rel text_cancel]
    mov r9d,6
    sub rsp,16
    lea rax,[rel cancel_index]
    mov [rsp],rax
    call nebo_ui_button
    add rsp,16
    CHECK_EAX

    lea rdi,[rel tree]
    mov rsi,[rel grid_index]
    lea rdx,[rel name_hint]
    mov ecx,4
    lea r8,[rel text_hint]
    mov r9d,11
    sub rsp,16
    lea rax,[rel hint_index]
    mov [rsp],rax
    call nebo_ui_label
    add rsp,16
    CHECK_EAX

    lea rdi,[rel tree]
    call nebo_ui_layout
    CHECK_EAX

    ; 1 focus Run, 2 click Run.
    lea rdi,[rel tree]
    call nebo_ui_focus_next
    CHECK_EAX
    CLEAR_WINDOW_EVENT
    mov dword [rel window_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_KEY_DOWN
    mov qword [rel window_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],NEBO_UI_KEY_ENTER
    lea rdi,[rel tree]
    lea rsi,[rel window_event]
    call nebo_ui_dispatch_window_event
    CHECK_EAX

    ; 3 blur Run, 4 focus TextInput, 5 change, 6 submit.
    lea rdi,[rel tree]
    call nebo_ui_focus_next
    CHECK_EAX
    CLEAR_WINDOW_EVENT
    mov dword [rel window_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_TEXT_INPUT
    mov qword [rel window_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],'A'
    mov qword [rel window_event+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],1
    mov qword [rel window_event+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],'A'
    lea rdi,[rel tree]
    lea rsi,[rel window_event]
    call nebo_ui_dispatch_window_event
    CHECK_EAX
    CLEAR_WINDOW_EVENT
    mov dword [rel window_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_KEY_DOWN
    mov qword [rel window_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],NEBO_UI_KEY_ENTER
    lea rdi,[rel tree]
    lea rsi,[rel window_event]
    call nebo_ui_dispatch_window_event
    CHECK_EAX

    ; 7 blur TextInput, 8 focus OK, 9 click OK.
    lea rdi,[rel tree]
    call nebo_ui_focus_next
    CHECK_EAX
    CLEAR_WINDOW_EVENT
    mov dword [rel window_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_KEY_DOWN
    mov qword [rel window_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],NEBO_UI_KEY_ENTER
    lea rdi,[rel tree]
    lea rsi,[rel window_event]
    call nebo_ui_dispatch_window_event
    CHECK_EAX

    cmp qword [rel tree+NEBO_UI_TREE_NODE_COUNT_OFFSET],11
    jne .fail
    cmp qword [rel tree+NEBO_UI_TREE_EVENT_COUNT_OFFSET],9
    jne .fail
    cmp qword [rel tree+NEBO_UI_TREE_FOCUSED_NODE_OFFSET],8
    jne .fail

    lea rdi,[rel golden_output]
    mov ecx,GOLDEN_SIZE/8
    xor eax,eax
    rep stosq
    mov rax,GOLDEN_MAGIC
    mov [rel golden_output],rax
    mov qword [rel golden_output+8],1
    mov qword [rel golden_output+16],11
    mov qword [rel golden_output+24],9
    mov qword [rel golden_output+32],64
    mov qword [rel golden_output+40],48
    mov rax,[rel tree+NEBO_UI_TREE_LAYOUT_GENERATION_OFFSET]
    mov [rel golden_output+48],rax
    mov rax,[rel tree+NEBO_UI_TREE_FOCUSED_NODE_OFFSET]
    mov [rel golden_output+56],rax

    xor r12d,r12d
.copy_nodes:
    cmp r12d,11
    jae .copy_events
    imul r13,r12,NEBO_UI_NODE_SIZE
    lea r14,[rel nodes]
    add r13,r14
    mov rax,r12
    shl rax,6
    lea r14,[rel golden_output+64]
    add r14,rax
    mov [r14],r12
    mov eax,[r13+NEBO_UI_NODE_KIND_OFFSET]
    mov [r14+8],rax
    mov eax,[r13+NEBO_UI_NODE_FLAGS_OFFSET]
    mov [r14+16],rax
    mov rax,[r13+NEBO_UI_NODE_PARENT_OFFSET]
    mov [r14+24],rax
    mov rax,[r13+NEBO_UI_NODE_X_OFFSET]
    mov [r14+32],rax
    mov rax,[r13+NEBO_UI_NODE_Y_OFFSET]
    mov [r14+40],rax
    mov rax,[r13+NEBO_UI_NODE_WIDTH_OFFSET]
    mov [r14+48],rax
    mov rax,[r13+NEBO_UI_NODE_HEIGHT_OFFSET]
    mov [r14+56],rax
    inc r12
    jmp .copy_nodes

.copy_events:
    lea rsi,[rel events]
    lea rdi,[rel golden_output+768]
    mov ecx,(9*NEBO_UI_EVENT_SIZE)/8
    rep movsq

    mov eax,1
    mov edi,1
    lea rsi,[rel golden_output]
    mov edx,GOLDEN_SIZE
    syscall
    cmp rax,GOLDEN_SIZE
    jne .fail
    mov eax,60
    xor edi,edi
    syscall
.fail:
    mov eax,60
    mov edi,1
    syscall
