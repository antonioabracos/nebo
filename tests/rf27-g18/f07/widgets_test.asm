bits 64
default rel
%include "runtime/widgets/widgets.inc"

%macro ASSERT_EAX 1
    inc r15d
    cmp eax,%1
    jne .fail
%endmacro
%macro ASSERT_Q 2
    inc r15d
    mov r11,%2
    cmp qword %1,r11
    jne .fail
%endmacro
%macro ASSERT_D 2
    inc r15d
    cmp dword %1,%2
    jne .fail
%endmacro
%macro ASSERT_B 2
    inc r15d
    cmp byte %1,%2
    jne .fail
%endmacro
%macro ASSERT_RQ 2
    inc r15d
    mov r11,%2
    cmp %1,r11
    jne .fail
%endmacro
%macro CHECK_Q 2
    mov r11,%2
    cmp qword %1,r11
    jne .fail
%endmacro

%macro CLEAR_WINDOW_EVENT 0
    lea rdi,[rel window_event]
    mov ecx,NEBO_WINDOW_EVENT_QWORDS
    xor eax,eax
    rep stosq
%endmacro

section .data align=8
name_label: db 'Label'
text_label: db 'Hello'
name_button: db 'Run'
text_button: db 'Run'
name_input: db 'Input'
name_grid: db 'Grid'
name_ok: db 'OK'
text_ok: db 'OK'
name_cancel: db 'Cancel'
text_cancel: db 'Cancel'
new_text: db 'OK'
invalid_utf8: db 0xc0,0x80
paint_dummy: dd 0xffffffff,NEBO_CANVAS_PAINT_MODE_FILL,1,0

section .bss align=16
tree: resb NEBO_UI_TREE_SIZE
nodes: resb NEBO_UI_NODE_SIZE*16
events: resb NEBO_UI_EVENT_SIZE*32
input_storage: resb 32
input_bad_storage: resb 8
window_event: resb NEBO_WINDOW_EVENT_SIZE
ui_event: resb NEBO_UI_EVENT_SIZE
access: resb NEBO_UI_ACCESS_SIZE
row_index: resq 1
label_index: resq 1
button_index: resq 1
input_index: resq 1
grid_index: resq 1
ok_index: resq 1
cancel_index: resq 1
canvas: resb NEBO_CANVAS_SIZE
pixels: resb 64*48*4
commands: resb NEBO_CANVAS_COMMAND_SIZE*128
saved_box: resq 4

section .text
global _start
_start:
    xor r15d,r15d

    ; Overlap rejection is atomic.
    mov rax,0x1122334455667788
    mov [rel tree],rax
    lea rdi,[rel tree]
    lea rsi,[rel tree]
    mov edx,16
    lea rcx,[rel events]
    mov r8d,32
    mov r9d,64
    sub rsp,16
    mov qword [rsp],48
    mov qword [rsp+8],0x707
    call nebo_ui_tree_init
    add rsp,16
    ASSERT_EAX NEBO_UI_ERROR_STORAGE_OVERLAP
    ASSERT_Q [rel tree],0x1122334455667788

    ; Valid caller-owned tree.
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
    ASSERT_EAX 0
    CHECK_Q [rel tree+NEBO_UI_TREE_NODE_CAPACITY_OFFSET],16
    ASSERT_Q [rel tree+NEBO_UI_TREE_NODE_COUNT_OFFSET],1
    CHECK_Q [rel tree+NEBO_UI_TREE_EVENT_CAPACITY_OFFSET],32
    CHECK_Q [rel tree+NEBO_UI_TREE_WIDTH_OFFSET],64
    CHECK_Q [rel tree+NEBO_UI_TREE_HEIGHT_OFFSET],48
    ASSERT_D [rel tree+NEBO_UI_TREE_STATE_OFFSET],NEBO_UI_TREE_STATE_ACTIVE
    ASSERT_Q [rel tree+NEBO_UI_TREE_FOCUSED_NODE_OFFSET],NEBO_UI_NONE
    ASSERT_D [rel nodes+NEBO_UI_NODE_KIND_OFFSET],NEBO_UI_NODE_ROOT
    CHECK_Q [rel nodes+NEBO_UI_NODE_PARENT_OFFSET],NEBO_UI_NONE

    lea rdi,[rel tree]
    call nebo_ui_tree_validate
    ASSERT_EAX 0

    ; Invalid parent and missing accessible name are rejected.
    lea rdi,[rel tree]
    mov esi,99
    mov edx,1
    lea rcx,[rel row_index]
    call nebo_ui_row
    ASSERT_EAX NEBO_UI_ERROR_INVALID_PARENT
    CHECK_Q [rel tree+NEBO_UI_TREE_NODE_COUNT_OFFSET],1

    lea rdi,[rel tree]
    xor esi,esi
    mov edx,1
    lea rcx,[rel row_index]
    call nebo_ui_row
    ASSERT_EAX 0
    ASSERT_Q [rel row_index],1
    ASSERT_Q [rel tree+NEBO_UI_TREE_NODE_COUNT_OFFSET],2

    lea rdi,[rel tree]
    mov rsi,[rel row_index]
    lea rdx,[rel name_label]
    xor ecx,ecx
    lea r8,[rel text_label]
    mov r9d,5
    sub rsp,16
    lea rax,[rel label_index]
    mov [rsp],rax
    call nebo_ui_label
    add rsp,16
    ASSERT_EAX NEBO_UI_ERROR_MISSING_ACCESSIBLE_NAME
    ASSERT_Q [rel tree+NEBO_UI_TREE_NODE_COUNT_OFFSET],2

    ; Label, Button and TextInput.
    lea rdi,[rel tree]
    mov rsi,[rel row_index]
    lea rdx,[rel name_label]
    mov ecx,5
    lea r8,[rel text_label]
    mov r9d,5
    sub rsp,16
    lea rax,[rel label_index]
    mov [rsp],rax
    call nebo_ui_label
    add rsp,16
    ASSERT_EAX 0
    CHECK_Q [rel label_index],2

    lea rdi,[rel tree]
    mov rsi,[rel row_index]
    lea rdx,[rel name_button]
    mov ecx,3
    lea r8,[rel text_button]
    mov r9d,3
    sub rsp,16
    lea rax,[rel button_index]
    mov [rsp],rax
    call nebo_ui_button
    add rsp,16
    ASSERT_EAX 0
    CHECK_Q [rel button_index],3
    ASSERT_D [rel nodes+NEBO_UI_NODE_SIZE*3+NEBO_UI_NODE_ROLE_OFFSET],NEBO_UI_ROLE_BUTTON

    mov word [rel input_bad_storage],0x80c0
    lea rdi,[rel tree]
    mov rsi,[rel row_index]
    lea rdx,[rel name_input]
    mov ecx,5
    lea r8,[rel input_bad_storage]
    mov r9d,8
    sub rsp,16
    mov qword [rsp],2
    lea rax,[rel input_index]
    mov [rsp+8],rax
    call nebo_ui_text_input
    add rsp,16
    ASSERT_EAX NEBO_UI_ERROR_INVALID_UTF8
    ASSERT_Q [rel tree+NEBO_UI_TREE_NODE_COUNT_OFFSET],4

    lea rdi,[rel tree]
    mov rsi,[rel row_index]
    lea rdx,[rel name_input]
    mov ecx,5
    lea r8,[rel input_storage]
    mov r9d,32
    sub rsp,16
    mov qword [rsp],0
    lea rax,[rel input_index]
    mov [rsp+8],rax
    call nebo_ui_text_input
    add rsp,16
    ASSERT_EAX 0
    ASSERT_Q [rel input_index],4
    ASSERT_D [rel nodes+NEBO_UI_NODE_SIZE*4+NEBO_UI_NODE_ROLE_OFFSET],NEBO_UI_ROLE_TEXTBOX
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*4+NEBO_UI_NODE_TEXT_CAPACITY_OFFSET],32

    ; Grid under root and two buttons.
    lea rdi,[rel tree]
    xor esi,esi
    mov edx,1
    mov ecx,2
    lea r8,[rel grid_index]
    call nebo_ui_grid
    ASSERT_EAX 0
    CHECK_Q [rel grid_index],5

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
    ASSERT_EAX 0
    ASSERT_Q [rel ok_index],6

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
    ASSERT_EAX 0
    ASSERT_Q [rel cancel_index],7
    ASSERT_Q [rel tree+NEBO_UI_TREE_NODE_COUNT_OFFSET],8
    ASSERT_Q [rel nodes+NEBO_UI_NODE_FIRST_CHILD_OFFSET],1
    ASSERT_Q [rel nodes+NEBO_UI_NODE_LAST_CHILD_OFFSET],5

    ; Exact integer layout.
    lea rdi,[rel tree]
    call nebo_ui_layout
    ASSERT_EAX 0
    ASSERT_Q [rel tree+NEBO_UI_TREE_LAYOUT_GENERATION_OFFSET],1
    ASSERT_D [rel tree+NEBO_UI_TREE_FLAGS_OFFSET],NEBO_UI_TREE_FLAG_LAYOUT_VALID
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*1+NEBO_UI_NODE_X_OFFSET],0
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*1+NEBO_UI_NODE_Y_OFFSET],0
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*1+NEBO_UI_NODE_WIDTH_OFFSET],64
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*1+NEBO_UI_NODE_HEIGHT_OFFSET],24
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*2+NEBO_UI_NODE_WIDTH_OFFSET],21
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*3+NEBO_UI_NODE_X_OFFSET],22
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*3+NEBO_UI_NODE_WIDTH_OFFSET],21
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*4+NEBO_UI_NODE_X_OFFSET],44
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*4+NEBO_UI_NODE_WIDTH_OFFSET],20
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*5+NEBO_UI_NODE_Y_OFFSET],24
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*5+NEBO_UI_NODE_HEIGHT_OFFSET],24
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*6+NEBO_UI_NODE_WIDTH_OFFSET],32
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*7+NEBO_UI_NODE_X_OFFSET],33
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*7+NEBO_UI_NODE_WIDTH_OFFSET],31

    ; Layout overflow and cycle fail before public box mutation.
    mov rax,[rel nodes+NEBO_UI_NODE_SIZE*2+NEBO_UI_NODE_X_OFFSET]
    mov [rel saved_box],rax
    mov rax,[rel nodes+NEBO_UI_NODE_SIZE*2+NEBO_UI_NODE_Y_OFFSET]
    mov [rel saved_box+8],rax
    mov rax,[rel nodes+NEBO_UI_NODE_SIZE*2+NEBO_UI_NODE_WIDTH_OFFSET]
    mov [rel saved_box+16],rax
    mov rax,[rel nodes+NEBO_UI_NODE_SIZE*2+NEBO_UI_NODE_HEIGHT_OFFSET]
    mov [rel saved_box+24],rax
    mov qword [rel nodes+NEBO_UI_NODE_SIZE*1+NEBO_UI_NODE_GAP_OFFSET],256
    lea rdi,[rel tree]
    call nebo_ui_layout
    ASSERT_EAX NEBO_UI_ERROR_LAYOUT_OVERFLOW
    mov rax,[rel saved_box]
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*2+NEBO_UI_NODE_X_OFFSET],rax
    mov qword [rel nodes+NEBO_UI_NODE_SIZE*1+NEBO_UI_NODE_GAP_OFFSET],1

    mov rax,[rel nodes+NEBO_UI_NODE_SIZE*1+NEBO_UI_NODE_FIRST_CHILD_OFFSET]
    mov [rel saved_box],rax
    mov rcx,[rel nodes+NEBO_UI_NODE_SIZE*1+NEBO_UI_NODE_CHILD_COUNT_OFFSET]
    mov [rel saved_box+8],rcx
    mov qword [rel nodes+NEBO_UI_NODE_SIZE*1+NEBO_UI_NODE_FIRST_CHILD_OFFSET],1
    mov qword [rel nodes+NEBO_UI_NODE_SIZE*1+NEBO_UI_NODE_CHILD_COUNT_OFFSET],1
    lea rdi,[rel tree]
    call nebo_ui_layout
    ASSERT_EAX NEBO_UI_ERROR_CYCLE
    mov rax,[rel saved_box]
    mov [rel nodes+NEBO_UI_NODE_SIZE*1+NEBO_UI_NODE_FIRST_CHILD_OFFSET],rax
    mov rax,[rel saved_box+8]
    mov [rel nodes+NEBO_UI_NODE_SIZE*1+NEBO_UI_NODE_CHILD_COUNT_OFFSET],rax
    lea rdi,[rel tree]
    call nebo_ui_layout
    ASSERT_EAX 0

    ; Canvas composition.
    lea rdi,[rel canvas]
    lea rsi,[rel pixels]
    mov edx,64*48*4
    mov ecx,64
    mov r8d,48
    lea r9,[rel commands]
    sub rsp,16
    mov qword [rsp],128
    call nebo_canvas_create
    add rsp,16
    ASSERT_EAX 0
    lea rdi,[rel tree]
    lea rsi,[rel canvas]
    call nebo_ui_render
    ASSERT_EAX 0
    ASSERT_Q [rel tree+NEBO_UI_TREE_RENDER_GENERATION_OFFSET],1
    ASSERT_D [rel tree+NEBO_UI_TREE_FLAGS_OFFSET],NEBO_UI_TREE_FLAG_LAYOUT_VALID | NEBO_UI_TREE_FLAG_RENDERED
    ASSERT_Q [rel tree+NEBO_UI_TREE_OWNER_CONTEXT_OFFSET],0x707
    inc r15d
    cmp qword [rel canvas+NEBO_CANVAS_COMMAND_COUNT_OFFSET],0
    jbe .fail

    ; Stable focus order and typed events.
    lea rdi,[rel tree]
    call nebo_ui_focus_next
    ASSERT_EAX 0
    ASSERT_Q [rel tree+NEBO_UI_TREE_FOCUSED_NODE_OFFSET],3
    ASSERT_Q [rel tree+NEBO_UI_TREE_EVENT_COUNT_OFFSET],1
    lea rdi,[rel tree]
    lea rsi,[rel ui_event]
    call nebo_ui_event_poll
    ASSERT_EAX 0
    inc r15d
    cmp edx,1
    jne .fail
    ASSERT_D [rel ui_event+NEBO_UI_EVENT_KIND_OFFSET],NEBO_UI_EVENT_FOCUS
    ASSERT_Q [rel ui_event+NEBO_UI_EVENT_NODE_OFFSET],3

    lea rdi,[rel tree]
    call nebo_ui_focus_next
    ASSERT_EAX 0
    ASSERT_Q [rel tree+NEBO_UI_TREE_FOCUSED_NODE_OFFSET],4
    ASSERT_Q [rel tree+NEBO_UI_TREE_EVENT_COUNT_OFFSET],2
    lea rdi,[rel tree]
    lea rsi,[rel ui_event]
    call nebo_ui_event_poll
    ASSERT_EAX 0
    ASSERT_D [rel ui_event+NEBO_UI_EVENT_KIND_OFFSET],NEBO_UI_EVENT_BLUR
    lea rdi,[rel tree]
    lea rsi,[rel ui_event]
    call nebo_ui_event_poll
    ASSERT_EAX 0
    ASSERT_D [rel ui_event+NEBO_UI_EVENT_KIND_OFFSET],NEBO_UI_EVENT_FOCUS

    ; Canonical one-scalar UTF-8 insertion, caret and backspace.
    CLEAR_WINDOW_EVENT
    mov dword [rel window_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_TEXT_INPUT
    mov qword [rel window_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],0xe9
    mov qword [rel window_event+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],2
    mov qword [rel window_event+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],0xa9c3
    lea rdi,[rel tree]
    lea rsi,[rel window_event]
    call nebo_ui_dispatch_window_event
    ASSERT_EAX 0
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*4+NEBO_UI_NODE_TEXT_LENGTH_OFFSET],2
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*4+NEBO_UI_NODE_CARET_OFFSET],2
    ASSERT_B [rel input_storage],0xc3
    ASSERT_B [rel input_storage+1],0xa9
    ASSERT_Q [rel tree+NEBO_UI_TREE_EVENT_COUNT_OFFSET],1

    CLEAR_WINDOW_EVENT
    mov dword [rel window_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_KEY_DOWN
    mov qword [rel window_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],NEBO_UI_KEY_LEFT
    lea rdi,[rel tree]
    lea rsi,[rel window_event]
    call nebo_ui_dispatch_window_event
    ASSERT_EAX 0
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*4+NEBO_UI_NODE_CARET_OFFSET],0

    mov qword [rel window_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],NEBO_UI_KEY_RIGHT
    lea rdi,[rel tree]
    lea rsi,[rel window_event]
    call nebo_ui_dispatch_window_event
    ASSERT_EAX 0
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*4+NEBO_UI_NODE_CARET_OFFSET],2

    mov qword [rel window_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],NEBO_UI_KEY_BACKSPACE
    lea rdi,[rel tree]
    lea rsi,[rel window_event]
    call nebo_ui_dispatch_window_event
    ASSERT_EAX 0
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*4+NEBO_UI_NODE_TEXT_LENGTH_OFFSET],0
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*4+NEBO_UI_NODE_CARET_OFFSET],0

    ; Invalid text payload and bounded setText.
    CLEAR_WINDOW_EVENT
    mov dword [rel window_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_TEXT_INPUT
    mov qword [rel window_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],0
    mov qword [rel window_event+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],2
    mov qword [rel window_event+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET],0x80c0
    lea rdi,[rel tree]
    lea rsi,[rel window_event]
    call nebo_ui_dispatch_window_event
    ASSERT_EAX NEBO_UI_ERROR_INVALID_EVENT
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*4+NEBO_UI_NODE_TEXT_LENGTH_OFFSET],0

    lea rdi,[rel tree]
    mov rsi,[rel input_index]
    lea rdx,[rel new_text]
    mov ecx,2
    call nebo_ui_set_text
    ASSERT_EAX 0
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*4+NEBO_UI_NODE_TEXT_LENGTH_OFFSET],2
    ASSERT_Q [rel nodes+NEBO_UI_NODE_SIZE*4+NEBO_UI_NODE_CARET_OFFSET],2
    ASSERT_B [rel input_storage],'O'
    ASSERT_B [rel input_storage+1],'K'

    ; Accessibility metadata is bounded, semantic and pointer-bearing only.
    lea rdi,[rel tree]
    mov rsi,[rel input_index]
    lea rdx,[rel access]
    call nebo_ui_accessibility_snapshot
    ASSERT_EAX 0
    ASSERT_Q [rel access+NEBO_UI_ACCESS_NODE_OFFSET],4
    ASSERT_D [rel access+NEBO_UI_ACCESS_ROLE_OFFSET],NEBO_UI_ROLE_TEXTBOX
    ASSERT_D [rel access+NEBO_UI_ACCESS_STATE_OFFSET],NEBO_UI_ACCESS_STATE_FOCUSED | NEBO_UI_ACCESS_STATE_EDITABLE
    ASSERT_Q [rel access+NEBO_UI_ACCESS_NAME_LENGTH_OFFSET],5
    ASSERT_Q [rel access+NEBO_UI_ACCESS_VALUE_LENGTH_OFFSET],2
    ASSERT_Q [rel access+NEBO_UI_ACCESS_CARET_OFFSET],2

    ; Disabled nodes leave focus order and pointer routing bounded.
    lea rdi,[rel tree]
    mov rsi,[rel input_index]
    mov edx,1
    call nebo_ui_set_disabled
    ASSERT_EAX 0
    ASSERT_Q [rel tree+NEBO_UI_TREE_FOCUSED_NODE_OFFSET],NEBO_UI_NONE
    ASSERT_D [rel nodes+NEBO_UI_NODE_SIZE*4+NEBO_UI_NODE_FLAGS_OFFSET],NEBO_UI_NODE_FLAG_FOCUSABLE | NEBO_UI_NODE_FLAG_DISABLED | NEBO_UI_NODE_FLAG_EDITABLE | NEBO_UI_NODE_FLAG_VISIBLE

    lea rdi,[rel tree]
    call nebo_ui_focus_next
    ASSERT_EAX 0
    ASSERT_Q [rel tree+NEBO_UI_TREE_FOCUSED_NODE_OFFSET],3

    ; Queue preflight prevents partial focus mutation.
    mov rax,[rel tree+NEBO_UI_TREE_EVENT_COUNT_OFFSET]
    mov [rel saved_box],rax
    mov rax,[rel tree+NEBO_UI_TREE_EVENT_CAPACITY_OFFSET]
    mov [rel tree+NEBO_UI_TREE_EVENT_COUNT_OFFSET],rax
    lea rdi,[rel tree]
    call nebo_ui_focus_next
    ASSERT_EAX NEBO_UI_ERROR_EVENT_LIMIT
    ASSERT_Q [rel tree+NEBO_UI_TREE_FOCUSED_NODE_OFFSET],3
    mov rax,[rel saved_box]
    mov [rel tree+NEBO_UI_TREE_EVENT_COUNT_OFFSET],rax

    ; Resize invalidates layout, then exact relayout succeeds.
    CLEAR_WINDOW_EVENT
    mov dword [rel window_event+NEBO_WINDOW_EVENT_KIND_OFFSET],NEBO_WINDOW_EVENT_RESIZED
    mov qword [rel window_event+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET],80
    mov qword [rel window_event+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET],60
    lea rdi,[rel tree]
    lea rsi,[rel window_event]
    call nebo_ui_dispatch_window_event
    ASSERT_EAX 0
    ASSERT_Q [rel tree+NEBO_UI_TREE_WIDTH_OFFSET],80
    ASSERT_Q [rel tree+NEBO_UI_TREE_HEIGHT_OFFSET],60
    ASSERT_Q [rel tree+NEBO_UI_TREE_LAYOUT_GENERATION_OFFSET],0
    lea rdi,[rel tree]
    call nebo_ui_layout
    ASSERT_EAX 0
    ASSERT_Q [rel tree+NEBO_UI_TREE_LAYOUT_GENERATION_OFFSET],1

    ; Terminal close is exactly once.
    lea rdi,[rel tree]
    call nebo_ui_close
    ASSERT_EAX 0
    ASSERT_D [rel tree+NEBO_UI_TREE_STATE_OFFSET],NEBO_UI_TREE_STATE_CLOSED
    lea rdi,[rel tree]
    call nebo_ui_close
    ASSERT_EAX NEBO_UI_ERROR_CLOSED
    lea rdi,[rel tree]
    call nebo_ui_tree_validate
    ASSERT_EAX 0
    lea rdi,[rel tree]
    lea rsi,[rel canvas]
    call nebo_ui_render
    ASSERT_EAX NEBO_UI_ERROR_CLOSED

    cmp r15d,117
    jne .fail
    mov eax,60
    xor edi,edi
    syscall
.fail:
    mov eax,60
    mov edi,1
    syscall
