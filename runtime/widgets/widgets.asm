bits 64
default rel
%define NEBO_WIDGETS_IMPLEMENTATION 1
%include "runtime/widgets/widgets.inc"

section .rodata align=8
ui_paint_background: dd 0x101820ff, NEBO_CANVAS_PAINT_MODE_FILL, 1, 0
ui_paint_button:     dd 0x285078ff, NEBO_CANVAS_PAINT_MODE_FILL, 1, 0
ui_paint_input:      dd 0x202830ff, NEBO_CANVAS_PAINT_MODE_FILL, 1, 0
ui_paint_text:       dd 0xffffffff, NEBO_CANVAS_PAINT_MODE_FILL, 1, 0
ui_paint_border:     dd 0x90a0b0ff, NEBO_CANVAS_PAINT_MODE_STROKE, 1, 0
ui_paint_focus:      dd 0xffd040ff, NEBO_CANVAS_PAINT_MODE_STROKE, 1, 0

section .text

global nebo_ui_tree_init
global nebo_ui_tree_validate
global nebo_ui_row
global nebo_ui_column
global nebo_ui_grid
global nebo_ui_label
global nebo_ui_button
global nebo_ui_text_input
global nebo_ui_layout
global nebo_ui_render
global nebo_ui_dispatch_window_event
global nebo_ui_event_poll
global nebo_ui_focus_next
global nebo_ui_focus_previous
global nebo_ui_set_disabled
global nebo_ui_set_text
global nebo_ui_accessibility_snapshot
global nebo_ui_close

; ---------------------------------------------------------------------------
; Internal helpers
; ---------------------------------------------------------------------------

; rdi=ptr, rcx=qwords.
ui_zero_qwords:
    xor eax,eax
    rep stosq
    ret

; rdi=ptr1,rsi=size1,rdx=ptr2,rcx=size2 -> eax=1 overlap/wrap, 0 disjoint.
ui_ranges_overlap:
    test rdi,rdi
    jz .overlap
    test rdx,rdx
    jz .overlap
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

; Strict canonical UTF-8 decoder. rdi=data,rsi=remaining -> r8=scalar,r9=bytes,eax=status.
ui_utf8_next:
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
    mov eax,NEBO_UI_ERROR_INVALID_UTF8
    xor r8d,r8d
    xor r9d,r9d
    ret

; rdi=data,rsi=len -> eax=status. Empty is valid; caller enforces non-empty names.
ui_validate_utf8:
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    test r13,r13
    jz .ok
    test r12,r12
    jz .invalid_argument
    xor ebx,ebx
.loop:
    cmp rbx,r13
    jae .ok
    lea rdi,[r12+rbx]
    mov rsi,r13
    sub rsi,rbx
    call ui_utf8_next
    test eax,eax
    jnz .return
    add rbx,r9
    jmp .loop
.ok:
    xor eax,eax
    jmp .return
.invalid_argument:
    mov eax,NEBO_UI_ERROR_INVALID_ARGUMENT
.return:
    pop r13
    pop r12
    pop rbx
    ret

; rdi=tree. Structural bounded validation; active and closed trees are accepted.
ui_validate_tree_common:
    test rdi,rdi
    jz .invalid
    mov rax,[rdi+NEBO_UI_TREE_MAGIC_OFFSET]
    mov rcx,NEBO_UI_TREE_MAGIC
    cmp rax,rcx
    jne .invalid
    mov eax,[rdi+NEBO_UI_TREE_STATE_OFFSET]
    cmp eax,NEBO_UI_TREE_STATE_ACTIVE
    je .state_ok
    cmp eax,NEBO_UI_TREE_STATE_CLOSED
    jne .bad_state
.state_ok:
    mov rax,[rdi+NEBO_UI_TREE_NODES_PTR_OFFSET]
    test rax,rax
    jz .invalid
    mov rcx,[rdi+NEBO_UI_TREE_EVENTS_PTR_OFFSET]
    test rcx,rcx
    jz .invalid
    mov rax,[rdi+NEBO_UI_TREE_NODE_CAPACITY_OFFSET]
    cmp rax,1
    jb .limit
    cmp rax,NEBO_UI_MAX_NODES
    ja .limit
    mov rcx,[rdi+NEBO_UI_TREE_NODE_COUNT_OFFSET]
    cmp rcx,1
    jb .invalid
    cmp rcx,rax
    ja .invalid
    mov rax,[rdi+NEBO_UI_TREE_EVENT_CAPACITY_OFFSET]
    cmp rax,NEBO_UI_MIN_EVENTS
    jb .limit
    cmp rax,NEBO_UI_MAX_EVENTS
    ja .limit
    mov rcx,[rdi+NEBO_UI_TREE_EVENT_COUNT_OFFSET]
    cmp rcx,rax
    ja .invalid
    mov rax,[rdi+NEBO_UI_TREE_EVENT_HEAD_OFFSET]
    cmp rax,[rdi+NEBO_UI_TREE_EVENT_CAPACITY_OFFSET]
    jae .invalid
    mov rax,[rdi+NEBO_UI_TREE_EVENT_TAIL_OFFSET]
    cmp rax,[rdi+NEBO_UI_TREE_EVENT_CAPACITY_OFFSET]
    jae .invalid
    mov rax,[rdi+NEBO_UI_TREE_NEXT_EVENT_SEQUENCE_OFFSET]
    test rax,rax
    jz .invalid
    mov rax,[rdi+NEBO_UI_TREE_WIDTH_OFFSET]
    cmp rax,1
    jb .limit
    cmp rax,NEBO_UI_MAX_AXIS
    ja .limit
    mov rax,[rdi+NEBO_UI_TREE_HEIGHT_OFFSET]
    cmp rax,1
    jb .limit
    cmp rax,NEBO_UI_MAX_AXIS
    ja .limit
    mov eax,[rdi+NEBO_UI_TREE_FLAGS_OFFSET]
    test eax,~NEBO_UI_TREE_KNOWN_FLAGS
    jnz .invalid
    mov rax,[rdi+NEBO_UI_TREE_RESERVED0_OFFSET]
    or rax,[rdi+NEBO_UI_TREE_RESERVED1_OFFSET]
    or rax,[rdi+NEBO_UI_TREE_RESERVED2_OFFSET]
    or rax,[rdi+NEBO_UI_TREE_RESERVED3_OFFSET]
    jnz .invalid
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_UI_ERROR_INVALID_ARGUMENT
    ret
.bad_state:
    mov eax,NEBO_UI_ERROR_BAD_STATE
    ret
.limit:
    mov eax,NEBO_UI_ERROR_LIMIT_EXCEEDED
    ret

; rdi=tree -> active status.
ui_require_active:
    sub rsp,8
    call ui_validate_tree_common
    add rsp,8
    test eax,eax
    jnz .return
    cmp dword [rdi+NEBO_UI_TREE_STATE_OFFSET],NEBO_UI_TREE_STATE_ACTIVE
    jne .closed
    xor eax,eax
.return:
    ret
.closed:
    mov eax,NEBO_UI_ERROR_CLOSED
    ret

; rdi=tree,rsi=index -> rax=node pointer, 0 on invalid index.
ui_node_ptr:
    cmp rsi,[rdi+NEBO_UI_TREE_NODE_COUNT_OFFSET]
    jae .invalid
    imul rax,rsi,NEBO_UI_NODE_SIZE
    add rax,[rdi+NEBO_UI_TREE_NODES_PTR_OFFSET]
    ret
.invalid:
    xor eax,eax
    ret

; eax=node kind -> eax=1 if container, else 0.
ui_kind_is_container:
    cmp eax,NEBO_UI_NODE_ROOT
    je .yes
    cmp eax,NEBO_UI_NODE_ROW
    je .yes
    cmp eax,NEBO_UI_NODE_COLUMN
    je .yes
    cmp eax,NEBO_UI_NODE_GRID
    je .yes
    xor eax,eax
    ret
.yes:
    mov eax,1
    ret

; rdi=tree,rsi=count -> eax=status for count queued events.
ui_can_enqueue:
    test rsi,rsi
    jz .ok
    mov rax,[rdi+NEBO_UI_TREE_EVENT_CAPACITY_OFFSET]
    sub rax,[rdi+NEBO_UI_TREE_EVENT_COUNT_OFFSET]
    cmp rax,rsi
    jb .full
    mov rax,[rdi+NEBO_UI_TREE_NEXT_EVENT_SEQUENCE_OFFSET]
    test rax,rax
    jz .full
    mov rcx,rsi
    dec rcx
    add rcx,rax
    jc .full
    test rcx,rcx
    jz .full
.ok:
    xor eax,eax
    ret
.full:
    mov eax,NEBO_UI_ERROR_EVENT_LIMIT
    ret

; rdi=tree,esi=kind,rdx=node,rcx=p0,r8=p1,r9=p2. Preflight is caller-owned.
ui_enqueue_event:
    mov r10,[rdi+NEBO_UI_TREE_EVENT_TAIL_OFFSET]
    imul r10,r10,NEBO_UI_EVENT_SIZE
    add r10,[rdi+NEBO_UI_TREE_EVENTS_PTR_OFFSET]
    mov r11,[rdi+NEBO_UI_TREE_NEXT_EVENT_SEQUENCE_OFFSET]
    mov [r10+NEBO_UI_EVENT_SEQUENCE_OFFSET],r11
    mov [r10+NEBO_UI_EVENT_KIND_OFFSET],esi
    mov dword [r10+NEBO_UI_EVENT_FLAGS_OFFSET],0
    mov [r10+NEBO_UI_EVENT_NODE_OFFSET],rdx
    mov [r10+NEBO_UI_EVENT_PAYLOAD0_OFFSET],rcx
    mov [r10+NEBO_UI_EVENT_PAYLOAD1_OFFSET],r8
    mov [r10+NEBO_UI_EVENT_PAYLOAD2_OFFSET],r9
    mov qword [r10+NEBO_UI_EVENT_RESERVED0_OFFSET],0
    mov qword [r10+NEBO_UI_EVENT_RESERVED1_OFFSET],0
    inc r11
    mov [rdi+NEBO_UI_TREE_NEXT_EVENT_SEQUENCE_OFFSET],r11
    mov rax,[rdi+NEBO_UI_TREE_EVENT_TAIL_OFFSET]
    inc rax
    cmp rax,[rdi+NEBO_UI_TREE_EVENT_CAPACITY_OFFSET]
    jb .tail_ready
    xor eax,eax
.tail_ready:
    mov [rdi+NEBO_UI_TREE_EVENT_TAIL_OFFSET],rax
    inc qword [rdi+NEBO_UI_TREE_EVENT_COUNT_OFFSET]
    xor eax,eax
    ret

; rdi=tree,rsi=new index or -1 -> eax=status. Events are fully preflighted.
ui_focus_change:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,[r12+NEBO_UI_TREE_FOCUSED_NODE_OFFSET]
    cmp r13,r14
    je .ok
    cmp r13,NEBO_UI_NONE
    je .new_valid
    mov rdi,r12
    mov rsi,r13
    call ui_node_ptr
    test rax,rax
    jz .invalid_focus
    mov ecx,[rax+NEBO_UI_NODE_FLAGS_OFFSET]
    test ecx,NEBO_UI_NODE_FLAG_FOCUSABLE
    jz .invalid_focus
    test ecx,NEBO_UI_NODE_FLAG_DISABLED
    jnz .disabled
.new_valid:
    xor ebx,ebx
    cmp r14,NEBO_UI_NONE
    je .count_new
    inc ebx
.count_new:
    cmp r13,NEBO_UI_NONE
    je .preflight
    inc ebx
.preflight:
    mov rdi,r12
    mov esi,ebx
    call ui_can_enqueue
    test eax,eax
    jnz .return
    cmp r14,NEBO_UI_NONE
    je .set_new
    mov rdi,r12
    mov rsi,r14
    call ui_node_ptr
    test rax,rax
    jz .invalid_focus
    and dword [rax+NEBO_UI_NODE_FLAGS_OFFSET],~NEBO_UI_NODE_FLAG_FOCUSED
    mov rdi,r12
    mov esi,NEBO_UI_EVENT_BLUR
    mov rdx,r14
    xor ecx,ecx
    xor r8d,r8d
    xor r9d,r9d
    call ui_enqueue_event
.set_new:
    mov [r12+NEBO_UI_TREE_FOCUSED_NODE_OFFSET],r13
    cmp r13,NEBO_UI_NONE
    je .ok
    mov rdi,r12
    mov rsi,r13
    call ui_node_ptr
    test rax,rax
    jz .invalid_focus
    or dword [rax+NEBO_UI_NODE_FLAGS_OFFSET],NEBO_UI_NODE_FLAG_FOCUSED
    mov rdi,r12
    mov esi,NEBO_UI_EVENT_FOCUS
    mov rdx,r13
    xor ecx,ecx
    xor r8d,r8d
    xor r9d,r9d
    call ui_enqueue_event
.ok:
    xor eax,eax
    jmp .return
.invalid_focus:
    mov eax,NEBO_UI_ERROR_INVALID_FOCUS
    jmp .return
.disabled:
    mov eax,NEBO_UI_ERROR_DISABLED
.return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; rdi=tree,rsi=x,rdx=y -> rax=topmost focusable node or -1.
ui_find_at:
    mov r8,[rdi+NEBO_UI_TREE_NODE_COUNT_OFFSET]
    test r8,r8
    jz .none
    dec r8
.loop:
    cmp r8,0
    je .none
    imul rax,r8,NEBO_UI_NODE_SIZE
    add rax,[rdi+NEBO_UI_TREE_NODES_PTR_OFFSET]
    mov ecx,[rax+NEBO_UI_NODE_FLAGS_OFFSET]
    test ecx,NEBO_UI_NODE_FLAG_FOCUSABLE
    jz .previous
    test ecx,NEBO_UI_NODE_FLAG_DISABLED
    jnz .previous
    test ecx,NEBO_UI_NODE_FLAG_VISIBLE
    jz .previous
    mov r9,[rax+NEBO_UI_NODE_X_OFFSET]
    cmp rsi,r9
    jl .previous
    add r9,[rax+NEBO_UI_NODE_WIDTH_OFFSET]
    cmp rsi,r9
    jge .previous
    mov r9,[rax+NEBO_UI_NODE_Y_OFFSET]
    cmp rdx,r9
    jl .previous
    add r9,[rax+NEBO_UI_NODE_HEIGHT_OFFSET]
    cmp rdx,r9
    jge .previous
    mov rax,r8
    ret
.previous:
    dec r8
    jmp .loop
.none:
    mov rax,NEBO_UI_NONE
    ret

; ---------------------------------------------------------------------------
; Public tree and node construction
; ---------------------------------------------------------------------------

; treeInit(tree,nodes,nodeCapacity,events,eventCapacity,width,height,owner)
nebo_ui_tree_init:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rbp
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov rbx,r8
    mov rbp,r9
    mov r10,[rsp+64]
    mov r11,[rsp+72]
    test r12,r12
    jz .invalid
    test r13,r13
    jz .invalid
    test r15,r15
    jz .invalid
    cmp r14,1
    jb .limit
    cmp r14,NEBO_UI_MAX_NODES
    ja .limit
    cmp rbx,NEBO_UI_MIN_EVENTS
    jb .limit
    cmp rbx,NEBO_UI_MAX_EVENTS
    ja .limit
    cmp rbp,1
    jb .limit
    cmp rbp,NEBO_UI_MAX_AXIS
    ja .limit
    cmp r10,1
    jb .limit
    cmp r10,NEBO_UI_MAX_AXIS
    ja .limit
    mov rax,r14
    imul rax,NEBO_UI_NODE_SIZE
    jo .limit
    mov [rsp],rax
    mov rdi,r12
    mov rsi,NEBO_UI_TREE_SIZE
    mov rdx,r13
    mov rcx,rax
    call ui_ranges_overlap
    test eax,eax
    jnz .overlap
    mov rax,rbx
    imul rax,NEBO_UI_EVENT_SIZE
    jo .limit
    mov rdi,r12
    mov rsi,NEBO_UI_TREE_SIZE
    mov rdx,r15
    mov rcx,rax
    call ui_ranges_overlap
    test eax,eax
    jnz .overlap
    mov rax,rbx
    imul rax,NEBO_UI_EVENT_SIZE
    mov rdi,r13
    mov rsi,[rsp]
    mov rdx,r15
    mov rcx,rax
    call ui_ranges_overlap
    test eax,eax
    jnz .overlap

    mov rdi,r12
    mov ecx,NEBO_UI_TREE_QWORDS
    call ui_zero_qwords
    mov rdi,r13
    mov rax,r14
    imul rcx,rax,NEBO_UI_NODE_QWORDS
    call ui_zero_qwords
    mov rdi,r15
    mov rax,rbx
    imul rcx,rax,NEBO_UI_EVENT_QWORDS
    call ui_zero_qwords

    mov [r12+NEBO_UI_TREE_NODES_PTR_OFFSET],r13
    mov [r12+NEBO_UI_TREE_NODE_CAPACITY_OFFSET],r14
    mov qword [r12+NEBO_UI_TREE_NODE_COUNT_OFFSET],1
    mov [r12+NEBO_UI_TREE_EVENTS_PTR_OFFSET],r15
    mov [r12+NEBO_UI_TREE_EVENT_CAPACITY_OFFSET],rbx
    mov qword [r12+NEBO_UI_TREE_EVENT_HEAD_OFFSET],0
    mov qword [r12+NEBO_UI_TREE_EVENT_TAIL_OFFSET],0
    mov qword [r12+NEBO_UI_TREE_EVENT_COUNT_OFFSET],0
    mov qword [r12+NEBO_UI_TREE_NEXT_EVENT_SEQUENCE_OFFSET],1
    mov qword [r12+NEBO_UI_TREE_FOCUSED_NODE_OFFSET],NEBO_UI_NONE
    mov qword [r12+NEBO_UI_TREE_PRESSED_NODE_OFFSET],NEBO_UI_NONE
    mov [r12+NEBO_UI_TREE_WIDTH_OFFSET],rbp
    mov [r12+NEBO_UI_TREE_HEIGHT_OFFSET],r10
    mov dword [r12+NEBO_UI_TREE_STATE_OFFSET],NEBO_UI_TREE_STATE_ACTIVE
    mov dword [r12+NEBO_UI_TREE_FLAGS_OFFSET],0
    mov [r12+NEBO_UI_TREE_OWNER_CONTEXT_OFFSET],r11
    mov qword [r12+NEBO_UI_TREE_LAST_STATUS_OFFSET],0
    mov qword [r12+NEBO_UI_TREE_LAST_ERROR_OFFSET],0
    mov qword [r12+NEBO_UI_TREE_LAYOUT_GENERATION_OFFSET],0
    mov qword [r12+NEBO_UI_TREE_RENDER_GENERATION_OFFSET],0
    mov rax,NEBO_UI_TREE_MAGIC
    mov [r12+NEBO_UI_TREE_MAGIC_OFFSET],rax

    mov dword [r13+NEBO_UI_NODE_KIND_OFFSET],NEBO_UI_NODE_ROOT
    mov dword [r13+NEBO_UI_NODE_FLAGS_OFFSET],NEBO_UI_NODE_FLAG_VISIBLE
    mov qword [r13+NEBO_UI_NODE_ID_OFFSET],1
    mov qword [r13+NEBO_UI_NODE_PARENT_OFFSET],NEBO_UI_NONE
    mov qword [r13+NEBO_UI_NODE_FIRST_CHILD_OFFSET],NEBO_UI_NONE
    mov qword [r13+NEBO_UI_NODE_LAST_CHILD_OFFSET],NEBO_UI_NONE
    mov qword [r13+NEBO_UI_NODE_NEXT_SIBLING_OFFSET],NEBO_UI_NONE
    mov qword [r13+NEBO_UI_NODE_CHILD_COUNT_OFFSET],0
    mov qword [r13+NEBO_UI_NODE_GRID_COLUMNS_OFFSET],1
    mov qword [r13+NEBO_UI_NODE_GAP_OFFSET],0
    mov qword [r13+NEBO_UI_NODE_X_OFFSET],0
    mov qword [r13+NEBO_UI_NODE_Y_OFFSET],0
    mov [r13+NEBO_UI_NODE_WIDTH_OFFSET],rbp
    mov [r13+NEBO_UI_NODE_HEIGHT_OFFSET],r10
    mov dword [r13+NEBO_UI_NODE_ROLE_OFFSET],NEBO_UI_ROLE_GROUP
    xor eax,eax
    jmp .return
.invalid:
    mov eax,NEBO_UI_ERROR_INVALID_ARGUMENT
    jmp .return
.limit:
    mov eax,NEBO_UI_ERROR_LIMIT_EXCEEDED
    jmp .return
.overlap:
    mov eax,NEBO_UI_ERROR_STORAGE_OVERLAP
.return:
    add rsp,8
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_ui_tree_validate:
    jmp ui_validate_tree_common

; Internal container addition. rdi=tree,rsi=parent,edx=kind,rcx=gap,r8=columns,r9=out.
ui_add_container_common:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    mov r12,rdi
    mov r13,rsi
    mov r14d,edx
    mov r15,rcx
    mov rbx,r8
    test r9,r9
    jz .invalid
    mov [rsp],r9
    mov rdi,r12
    call ui_require_active
    test eax,eax
    jnz .return
    cmp r14d,NEBO_UI_NODE_ROW
    je .kind_ok
    cmp r14d,NEBO_UI_NODE_COLUMN
    je .kind_ok
    cmp r14d,NEBO_UI_NODE_GRID
    jne .invalid_kind
.kind_ok:
    cmp r15,NEBO_UI_MAX_GAP
    ja .limit
    cmp r14d,NEBO_UI_NODE_GRID
    jne .nongrid
    cmp rbx,1
    jb .limit
    cmp rbx,NEBO_UI_MAX_GRID_COLUMNS
    ja .limit
    jmp .grid_ready
.nongrid:
    mov rbx,1
.grid_ready:
    mov rax,[r12+NEBO_UI_TREE_NODE_COUNT_OFFSET]
    cmp rax,[r12+NEBO_UI_TREE_NODE_CAPACITY_OFFSET]
    jae .node_limit
    mov rdi,r12
    mov rsi,r13
    call ui_node_ptr
    test rax,rax
    jz .parent
    mov edx,[rax+NEBO_UI_NODE_KIND_OFFSET]
    mov eax,edx
    call ui_kind_is_container
    test eax,eax
    jz .parent
    mov r10,[r12+NEBO_UI_TREE_NODE_COUNT_OFFSET]
    imul r11,r10,NEBO_UI_NODE_SIZE
    add r11,[r12+NEBO_UI_TREE_NODES_PTR_OFFSET]
    mov rdi,r11
    mov ecx,NEBO_UI_NODE_QWORDS
    call ui_zero_qwords
    mov [r11+NEBO_UI_NODE_KIND_OFFSET],r14d
    mov dword [r11+NEBO_UI_NODE_FLAGS_OFFSET],NEBO_UI_NODE_FLAG_VISIBLE
    lea rax,[r10+1]
    mov [r11+NEBO_UI_NODE_ID_OFFSET],rax
    mov [r11+NEBO_UI_NODE_PARENT_OFFSET],r13
    mov qword [r11+NEBO_UI_NODE_FIRST_CHILD_OFFSET],NEBO_UI_NONE
    mov qword [r11+NEBO_UI_NODE_LAST_CHILD_OFFSET],NEBO_UI_NONE
    mov qword [r11+NEBO_UI_NODE_NEXT_SIBLING_OFFSET],NEBO_UI_NONE
    mov [r11+NEBO_UI_NODE_GRID_COLUMNS_OFFSET],rbx
    mov [r11+NEBO_UI_NODE_GAP_OFFSET],r15
    mov dword [r11+NEBO_UI_NODE_ROLE_OFFSET],NEBO_UI_ROLE_GROUP
    mov rdi,r12
    mov rsi,r13
    call ui_node_ptr
    mov rdx,[rax+NEBO_UI_NODE_LAST_CHILD_OFFSET]
    cmp rdx,NEBO_UI_NONE
    je .first_child
    mov rdi,r12
    mov rsi,rdx
    call ui_node_ptr
    mov [rax+NEBO_UI_NODE_NEXT_SIBLING_OFFSET],r10
    jmp .link_last
.first_child:
    mov [rax+NEBO_UI_NODE_FIRST_CHILD_OFFSET],r10
.link_last:
    ; Re-resolve parent because ui_node_ptr returns the previous child above.
    mov rdi,r12
    mov rsi,r13
    call ui_node_ptr
    mov [rax+NEBO_UI_NODE_LAST_CHILD_OFFSET],r10
    inc qword [rax+NEBO_UI_NODE_CHILD_COUNT_OFFSET]
    inc qword [r12+NEBO_UI_TREE_NODE_COUNT_OFFSET]
    and dword [r12+NEBO_UI_TREE_FLAGS_OFFSET],~NEBO_UI_TREE_FLAG_LAYOUT_VALID
    mov qword [r12+NEBO_UI_TREE_LAYOUT_GENERATION_OFFSET],0
    mov r9,[rsp]
    mov [r9],r10
    xor eax,eax
    jmp .return
.invalid:
    mov eax,NEBO_UI_ERROR_INVALID_ARGUMENT
    jmp .return
.invalid_kind:
    mov eax,NEBO_UI_ERROR_INVALID_KIND
    jmp .return
.limit:
    mov eax,NEBO_UI_ERROR_LIMIT_EXCEEDED
    jmp .return
.node_limit:
    mov eax,NEBO_UI_ERROR_NODE_LIMIT
    jmp .return
.parent:
    mov eax,NEBO_UI_ERROR_INVALID_PARENT
.return:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_ui_row:
    ; rdi=tree,rsi=parent,rdx=gap,rcx=out
    mov r9,rcx
    mov rcx,rdx
    xor r8d,r8d
    mov edx,NEBO_UI_NODE_ROW
    jmp ui_add_container_common

nebo_ui_column:
    ; rdi=tree,rsi=parent,rdx=gap,rcx=out
    mov r9,rcx
    mov rcx,rdx
    xor r8d,r8d
    mov edx,NEBO_UI_NODE_COLUMN
    jmp ui_add_container_common

nebo_ui_grid:
    ; rdi=tree,rsi=parent,rdx=gap,rcx=columns,r8=out
    mov r9,r8
    mov r8,rcx
    mov rcx,rdx
    mov edx,NEBO_UI_NODE_GRID
    jmp ui_add_container_common

; Common leaf addition.
; rdi=tree,rsi=parent,rdx=name,rcx=nameLen,r8=text,r9=textLen,
; stack: capacity,kind,out.
ui_add_leaf_common:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rbp
    sub rsp,24
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov rbx,r8
    mov rbp,r9
    mov r10,[rsp+80]
    mov r11,[rsp+88]
    mov rax,[rsp+96]
    mov [rsp],rax
    mov rdi,r12
    call ui_require_active
    test eax,eax
    jnz .return
    cmp qword [rsp],0
    jz .invalid
    cmp r11,NEBO_UI_NODE_LABEL
    je .kind_ok
    cmp r11,NEBO_UI_NODE_BUTTON
    je .kind_ok
    cmp r11,NEBO_UI_NODE_TEXT_INPUT
    jne .invalid_kind
.kind_ok:
    cmp r15,1
    jb .missing_name
    cmp r15,NEBO_UI_MAX_ACCESSIBLE_NAME_BYTES
    ja .limit
    mov rdi,r14
    mov rsi,r15
    call ui_validate_utf8
    test eax,eax
    jnz .return
    cmp r10,NEBO_UI_MAX_TEXT_BYTES
    ja .text_capacity
    cmp rbp,r10
    ja .text_capacity
    test rbp,rbp
    jz .text_valid
    test rbx,rbx
    jz .invalid
    mov rdi,rbx
    mov rsi,rbp
    call ui_validate_utf8
    test eax,eax
    jnz .return
.text_valid:
    cmp r11,NEBO_UI_NODE_TEXT_INPUT
    jne .capacity_ready
    test rbx,rbx
    jz .invalid
    cmp r10,1
    jb .text_capacity
.capacity_ready:
    mov rax,[r12+NEBO_UI_TREE_NODE_COUNT_OFFSET]
    cmp rax,[r12+NEBO_UI_TREE_NODE_CAPACITY_OFFSET]
    jae .node_limit
    mov rdi,r12
    mov rsi,r13
    call ui_node_ptr
    test rax,rax
    jz .parent
    mov edx,[rax+NEBO_UI_NODE_KIND_OFFSET]
    mov eax,edx
    call ui_kind_is_container
    test eax,eax
    jz .parent

    mov r9,[r12+NEBO_UI_TREE_NODE_COUNT_OFFSET]
    imul rax,r9,NEBO_UI_NODE_SIZE
    add rax,[r12+NEBO_UI_TREE_NODES_PTR_OFFSET]
    mov [rsp+8],rax
    mov rdi,rax
    mov ecx,NEBO_UI_NODE_QWORDS
    call ui_zero_qwords
    mov rax,[rsp+8]
    mov [rax+NEBO_UI_NODE_KIND_OFFSET],r11d
    mov edx,NEBO_UI_NODE_FLAG_VISIBLE
    cmp r11d,NEBO_UI_NODE_BUTTON
    jne .not_button
    or edx,NEBO_UI_NODE_FLAG_FOCUSABLE
.not_button:
    cmp r11d,NEBO_UI_NODE_TEXT_INPUT
    jne .flags_ready
    or edx,NEBO_UI_NODE_FLAG_FOCUSABLE | NEBO_UI_NODE_FLAG_EDITABLE
.flags_ready:
    mov [rax+NEBO_UI_NODE_FLAGS_OFFSET],edx
    lea rdx,[r9+1]
    mov [rax+NEBO_UI_NODE_ID_OFFSET],rdx
    mov [rax+NEBO_UI_NODE_PARENT_OFFSET],r13
    mov qword [rax+NEBO_UI_NODE_FIRST_CHILD_OFFSET],NEBO_UI_NONE
    mov qword [rax+NEBO_UI_NODE_LAST_CHILD_OFFSET],NEBO_UI_NONE
    mov qword [rax+NEBO_UI_NODE_NEXT_SIBLING_OFFSET],NEBO_UI_NONE
    mov qword [rax+NEBO_UI_NODE_GRID_COLUMNS_OFFSET],1
    mov qword [rax+NEBO_UI_NODE_GAP_OFFSET],0
    mov [rax+NEBO_UI_NODE_NAME_PTR_OFFSET],r14
    mov [rax+NEBO_UI_NODE_NAME_LENGTH_OFFSET],r15
    mov [rax+NEBO_UI_NODE_TEXT_PTR_OFFSET],rbx
    mov [rax+NEBO_UI_NODE_TEXT_LENGTH_OFFSET],rbp
    mov [rax+NEBO_UI_NODE_TEXT_CAPACITY_OFFSET],r10
    mov [rax+NEBO_UI_NODE_CARET_OFFSET],rbp
    mov qword [rax+NEBO_UI_NODE_REVISION_OFFSET],1
    mov dword [rax+NEBO_UI_NODE_BACKGROUND_RGBA_OFFSET],0x202830ff
    mov dword [rax+NEBO_UI_NODE_FOREGROUND_RGBA_OFFSET],0xffffffff
    mov dword [rax+NEBO_UI_NODE_BORDER_RGBA_OFFSET],0x90a0b0ff
    mov edx,NEBO_UI_ROLE_LABEL
    cmp r11d,NEBO_UI_NODE_BUTTON
    jne .role_input
    mov edx,NEBO_UI_ROLE_BUTTON
.role_input:
    cmp r11d,NEBO_UI_NODE_TEXT_INPUT
    jne .role_ready
    mov edx,NEBO_UI_ROLE_TEXTBOX
.role_ready:
    mov [rax+NEBO_UI_NODE_ROLE_OFFSET],edx

    mov rdi,r12
    mov rsi,r13
    call ui_node_ptr
    mov rdx,[rax+NEBO_UI_NODE_LAST_CHILD_OFFSET]
    cmp rdx,NEBO_UI_NONE
    je .first_child
    mov rdi,r12
    mov rsi,rdx
    call ui_node_ptr
    mov [rax+NEBO_UI_NODE_NEXT_SIBLING_OFFSET],r9
    jmp .last_child
.first_child:
    mov [rax+NEBO_UI_NODE_FIRST_CHILD_OFFSET],r9
.last_child:
    mov rdi,r12
    mov rsi,r13
    call ui_node_ptr
    mov [rax+NEBO_UI_NODE_LAST_CHILD_OFFSET],r9
    inc qword [rax+NEBO_UI_NODE_CHILD_COUNT_OFFSET]
    inc qword [r12+NEBO_UI_TREE_NODE_COUNT_OFFSET]
    and dword [r12+NEBO_UI_TREE_FLAGS_OFFSET],~NEBO_UI_TREE_FLAG_LAYOUT_VALID
    mov qword [r12+NEBO_UI_TREE_LAYOUT_GENERATION_OFFSET],0
    mov rax,[rsp]
    mov [rax],r9
    xor eax,eax
    jmp .return
.invalid:
    mov eax,NEBO_UI_ERROR_INVALID_ARGUMENT
    jmp .return
.invalid_kind:
    mov eax,NEBO_UI_ERROR_INVALID_KIND
    jmp .return
.missing_name:
    mov eax,NEBO_UI_ERROR_MISSING_ACCESSIBLE_NAME
    jmp .return
.limit:
    mov eax,NEBO_UI_ERROR_LIMIT_EXCEEDED
    jmp .return
.text_capacity:
    mov eax,NEBO_UI_ERROR_TEXT_CAPACITY
    jmp .return
.node_limit:
    mov eax,NEBO_UI_ERROR_NODE_LIMIT
    jmp .return
.parent:
    mov eax,NEBO_UI_ERROR_INVALID_PARENT
.return:
    add rsp,24
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; label(tree,parent,name,nameLen,text,textLen,out)
nebo_ui_label:
    mov r10,[rsp+8]
    sub rsp,40
    mov [rsp],r9
    mov qword [rsp+8],NEBO_UI_NODE_LABEL
    mov [rsp+16],r10
    call ui_add_leaf_common
    add rsp,40
    ret

; button(tree,parent,name,nameLen,text,textLen,out)
nebo_ui_button:
    mov r10,[rsp+8]
    sub rsp,40
    mov [rsp],r9
    mov qword [rsp+8],NEBO_UI_NODE_BUTTON
    mov [rsp+16],r10
    call ui_add_leaf_common
    add rsp,40
    ret

; textInput(tree,parent,name,nameLen,storage,capacity,initialLen,out)
nebo_ui_text_input:
    mov r10,[rsp+8]
    mov r11,[rsp+16]
    mov rax,r9
    mov r9,r10
    sub rsp,40
    mov [rsp],rax
    mov qword [rsp+8],NEBO_UI_NODE_TEXT_INPUT
    mov [rsp+16],r11
    call ui_add_leaf_common
    add rsp,40
    ret

; ---------------------------------------------------------------------------
; Exact bounded layout
; ---------------------------------------------------------------------------

; layout(tree). Candidate boxes are held in 1024 x 16-byte bounded stack
; scratch. No public node box is written until the whole graph passes.
nebo_ui_layout:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rbp
    sub rsp,8
    mov r12,rdi
    call ui_require_active
    add rsp,8
    test eax,eax
    jnz .return_no_frame
    cmp qword [r12+NEBO_UI_TREE_LAYOUT_GENERATION_OFFSET],-1
    je .revision_no_frame
    sub rsp,16520
    lea rbp,[rsp+128]

    ; Root candidate.
    mov dword [rbp],0
    mov dword [rbp+4],0
    mov eax,[r12+NEBO_UI_TREE_WIDTH_OFFSET]
    mov [rbp+8],eax
    mov eax,[r12+NEBO_UI_TREE_HEIGHT_OFFSET]
    mov [rbp+12],eax
    mov qword [rsp],0

.container_loop:
    mov rax,[rsp]
    cmp rax,[r12+NEBO_UI_TREE_NODE_COUNT_OFFSET]
    jae .commit_candidates
    imul r13,rax,NEBO_UI_NODE_SIZE
    add r13,[r12+NEBO_UI_TREE_NODES_PTR_OFFSET]
    mov eax,[r13+NEBO_UI_NODE_KIND_OFFSET]
    cmp eax,NEBO_UI_NODE_ROOT
    je .container_column
    cmp eax,NEBO_UI_NODE_ROW
    je .container_row
    cmp eax,NEBO_UI_NODE_COLUMN
    je .container_column
    cmp eax,NEBO_UI_NODE_GRID
    je .container_grid
    cmp qword [r13+NEBO_UI_NODE_CHILD_COUNT_OFFSET],0
    jne .cycle
    jmp .next_container

.load_common:
    ; This helper is entered with CALL, so its return address occupies [rsp].
    ; Every outer-frame local is therefore addressed at its caller offset + 8.
    mov rax,[r13+NEBO_UI_NODE_CHILD_COUNT_OFFSET]
    mov [rsp+16],rax
    test rax,rax
    jz .load_next_container
    cmp rax,[r12+NEBO_UI_TREE_NODE_COUNT_OFFSET]
    ja .load_cycle
    mov rax,[r13+NEBO_UI_NODE_GAP_OFFSET]
    cmp rax,NEBO_UI_MAX_GAP
    ja .load_overflow
    mov [rsp+24],rax
    mov rax,[rsp+8]
    shl rax,4
    lea r14,[rbp+rax]
    movsxd rax,dword [r14]
    mov [rsp+104],rax
    movsxd rax,dword [r14+4]
    mov [rsp+112],rax
    mov eax,[r14+8]
    mov [rsp+120],rax
    mov eax,[r14+12]
    mov [rsp+128],rax
    ret
.load_next_container:
    add rsp,8
    jmp .next_container
.load_cycle:
    add rsp,8
    jmp .cycle
.load_overflow:
    add rsp,8
    jmp .overflow

.container_row:
    call .load_common
    mov rax,[rsp+8]
    test rax,rax
    jz .next_container
    mov rcx,rax
    dec rcx
    imul rcx,[rsp+16]
    cmp rcx,[rsp+112]
    ja .overflow
    mov rax,[rsp+112]
    sub rax,rcx
    xor edx,edx
    div qword [rsp+8]
    mov [rsp+40],rax
    mov [rsp+48],rdx
    mov rax,[r13+NEBO_UI_NODE_FIRST_CHILD_OFFSET]
    mov [rsp+24],rax
    mov qword [rsp+32],0
    mov rax,[rsp+96]
    mov [rsp+88],rax
.row_child_loop:
    mov rax,[rsp+32]
    cmp rax,[rsp+8]
    jae .children_done
    mov rsi,[rsp+24]
    cmp rsi,NEBO_UI_NONE
    je .cycle
    cmp rsi,[r12+NEBO_UI_TREE_NODE_COUNT_OFFSET]
    jae .cycle
    imul r15,rsi,NEBO_UI_NODE_SIZE
    add r15,[r12+NEBO_UI_TREE_NODES_PTR_OFFSET]
    mov rax,[r15+NEBO_UI_NODE_PARENT_OFFSET]
    cmp rax,[rsp]
    jne .cycle
    mov rax,rsi
    shl rax,4
    lea r14,[rbp+rax]
    mov rax,[rsp+88]
    mov [r14],eax
    mov rax,[rsp+104]
    mov [r14+4],eax
    mov rax,[rsp+40]
    mov rcx,[rsp+32]
    cmp rcx,[rsp+48]
    jae .row_width_ready
    inc rax
.row_width_ready:
    mov [r14+8],eax
    mov rcx,[rsp+120]
    mov [r14+12],ecx
    add [rsp+88],rax
    mov rcx,[rsp+16]
    add [rsp+88],rcx
    mov rax,[r15+NEBO_UI_NODE_NEXT_SIBLING_OFFSET]
    mov [rsp+24],rax
    inc qword [rsp+32]
    jmp .row_child_loop

.container_column:
    call .load_common
    mov rax,[rsp+8]
    test rax,rax
    jz .next_container
    mov rcx,rax
    dec rcx
    imul rcx,[rsp+16]
    cmp rcx,[rsp+120]
    ja .overflow
    mov rax,[rsp+120]
    sub rax,rcx
    xor edx,edx
    div qword [rsp+8]
    mov [rsp+56],rax
    mov [rsp+64],rdx
    mov rax,[r13+NEBO_UI_NODE_FIRST_CHILD_OFFSET]
    mov [rsp+24],rax
    mov qword [rsp+32],0
    mov rax,[rsp+104]
    mov [rsp+88],rax
.column_child_loop:
    mov rax,[rsp+32]
    cmp rax,[rsp+8]
    jae .children_done
    mov rsi,[rsp+24]
    cmp rsi,NEBO_UI_NONE
    je .cycle
    cmp rsi,[r12+NEBO_UI_TREE_NODE_COUNT_OFFSET]
    jae .cycle
    imul r15,rsi,NEBO_UI_NODE_SIZE
    add r15,[r12+NEBO_UI_TREE_NODES_PTR_OFFSET]
    mov rax,[r15+NEBO_UI_NODE_PARENT_OFFSET]
    cmp rax,[rsp]
    jne .cycle
    mov rax,rsi
    shl rax,4
    lea r14,[rbp+rax]
    mov rax,[rsp+96]
    mov [r14],eax
    mov rax,[rsp+88]
    mov [r14+4],eax
    mov rax,[rsp+112]
    mov [r14+8],eax
    mov rax,[rsp+56]
    mov rcx,[rsp+32]
    cmp rcx,[rsp+64]
    jae .column_height_ready
    inc rax
.column_height_ready:
    mov [r14+12],eax
    add [rsp+88],rax
    mov rcx,[rsp+16]
    add [rsp+88],rcx
    mov rax,[r15+NEBO_UI_NODE_NEXT_SIBLING_OFFSET]
    mov [rsp+24],rax
    inc qword [rsp+32]
    jmp .column_child_loop

.container_grid:
    call .load_common
    mov rax,[rsp+8]
    test rax,rax
    jz .next_container
    mov rcx,[r13+NEBO_UI_NODE_GRID_COLUMNS_OFFSET]
    cmp rcx,1
    jb .overflow
    cmp rcx,NEBO_UI_MAX_GRID_COLUMNS
    ja .overflow
    mov [rsp+72],rcx
    mov rax,[rsp+8]
    add rax,rcx
    dec rax
    xor edx,edx
    div rcx
    mov [rsp+80],rax

    mov rax,[rsp+72]
    dec rax
    imul rax,[rsp+16]
    cmp rax,[rsp+112]
    ja .overflow
    mov rcx,[rsp+112]
    sub rcx,rax
    mov rax,rcx
    xor edx,edx
    div qword [rsp+72]
    mov [rsp+40],rax
    mov [rsp+48],rdx

    mov rax,[rsp+80]
    dec rax
    imul rax,[rsp+16]
    cmp rax,[rsp+120]
    ja .overflow
    mov rcx,[rsp+120]
    sub rcx,rax
    mov rax,rcx
    xor edx,edx
    div qword [rsp+80]
    mov [rsp+56],rax
    mov [rsp+64],rdx

    mov rax,[r13+NEBO_UI_NODE_FIRST_CHILD_OFFSET]
    mov [rsp+24],rax
    mov qword [rsp+32],0
.grid_child_loop:
    mov rax,[rsp+32]
    cmp rax,[rsp+8]
    jae .children_done
    mov rsi,[rsp+24]
    cmp rsi,NEBO_UI_NONE
    je .cycle
    cmp rsi,[r12+NEBO_UI_TREE_NODE_COUNT_OFFSET]
    jae .cycle
    imul r15,rsi,NEBO_UI_NODE_SIZE
    add r15,[r12+NEBO_UI_TREE_NODES_PTR_OFFSET]
    mov rax,[r15+NEBO_UI_NODE_PARENT_OFFSET]
    cmp rax,[rsp]
    jne .cycle

    mov rax,[rsp+32]
    xor edx,edx
    div qword [rsp+72]
    ; rax=row, rdx=column
    mov r8,rax
    mov r9,rdx
    mov rax,rsi
    shl rax,4
    lea r14,[rbp+rax]

    mov rax,r9
    imul rax,[rsp+40]
    mov rcx,r9
    cmp rcx,[rsp+48]
    jbe .grid_x_remainder_ready
    mov rcx,[rsp+48]
.grid_x_remainder_ready:
    add rax,rcx
    mov rcx,r9
    imul rcx,[rsp+16]
    add rax,rcx
    add rax,[rsp+96]
    mov [r14],eax

    mov rax,r8
    imul rax,[rsp+56]
    mov rcx,r8
    cmp rcx,[rsp+64]
    jbe .grid_y_remainder_ready
    mov rcx,[rsp+64]
.grid_y_remainder_ready:
    add rax,rcx
    mov rcx,r8
    imul rcx,[rsp+16]
    add rax,rcx
    add rax,[rsp+104]
    mov [r14+4],eax

    mov rax,[rsp+40]
    cmp r9,[rsp+48]
    jae .grid_width_ready
    inc rax
.grid_width_ready:
    mov [r14+8],eax
    mov rax,[rsp+56]
    cmp r8,[rsp+64]
    jae .grid_height_ready
    inc rax
.grid_height_ready:
    mov [r14+12],eax

    mov rax,[r15+NEBO_UI_NODE_NEXT_SIBLING_OFFSET]
    mov [rsp+24],rax
    inc qword [rsp+32]
    jmp .grid_child_loop

.children_done:
    cmp qword [rsp+24],NEBO_UI_NONE
    jne .cycle
.next_container:
    inc qword [rsp]
    jmp .container_loop

.commit_candidates:
    xor ebx,ebx
.commit_loop:
    cmp rbx,[r12+NEBO_UI_TREE_NODE_COUNT_OFFSET]
    jae .commit_done
    imul r13,rbx,NEBO_UI_NODE_SIZE
    add r13,[r12+NEBO_UI_TREE_NODES_PTR_OFFSET]
    mov rax,rbx
    shl rax,4
    lea r14,[rbp+rax]
    movsxd rax,dword [r14]
    mov [r13+NEBO_UI_NODE_X_OFFSET],rax
    movsxd rax,dword [r14+4]
    mov [r13+NEBO_UI_NODE_Y_OFFSET],rax
    mov eax,[r14+8]
    mov [r13+NEBO_UI_NODE_WIDTH_OFFSET],rax
    mov eax,[r14+12]
    mov [r13+NEBO_UI_NODE_HEIGHT_OFFSET],rax
    inc rbx
    jmp .commit_loop
.commit_done:
    inc qword [r12+NEBO_UI_TREE_LAYOUT_GENERATION_OFFSET]
    or dword [r12+NEBO_UI_TREE_FLAGS_OFFSET],NEBO_UI_TREE_FLAG_LAYOUT_VALID
    and dword [r12+NEBO_UI_TREE_FLAGS_OFFSET],~NEBO_UI_TREE_FLAG_RENDERED
    xor eax,eax
    jmp .layout_return
.overflow:
    mov eax,NEBO_UI_ERROR_LAYOUT_OVERFLOW
    jmp .layout_return
.cycle:
    mov eax,NEBO_UI_ERROR_CYCLE
.layout_return:
    add rsp,16520
.return_no_frame:
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.revision_no_frame:
    mov eax,NEBO_UI_ERROR_REVISION_EXHAUSTED
    jmp .return_no_frame

; ---------------------------------------------------------------------------
; Canvas composition and event stream
; ---------------------------------------------------------------------------

; render(tree,canvas). Uses only F06 bounded Canvas primitives.
nebo_ui_render:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rbp
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    mov rdi,r12
    call ui_require_active
    test eax,eax
    jnz .return
    test dword [r12+NEBO_UI_TREE_FLAGS_OFFSET],NEBO_UI_TREE_FLAG_LAYOUT_VALID
    jz .bad_state
    cmp qword [r12+NEBO_UI_TREE_RENDER_GENERATION_OFFSET],-1
    je .revision
    mov rdi,r13
    call nebo_canvas_validate
    test eax,eax
    jnz .return
    mov rdi,r13
    mov esi,0x101820ff
    call nebo_canvas_clear
    test eax,eax
    jnz .return
    mov r14,1
.render_loop:
    cmp r14,[r12+NEBO_UI_TREE_NODE_COUNT_OFFSET]
    jae .render_done
    imul r15,r14,NEBO_UI_NODE_SIZE
    add r15,[r12+NEBO_UI_TREE_NODES_PTR_OFFSET]
    mov ebx,[r15+NEBO_UI_NODE_KIND_OFFSET]
    cmp ebx,NEBO_UI_NODE_LABEL
    je .draw_text
    cmp ebx,NEBO_UI_NODE_BUTTON
    je .draw_button
    cmp ebx,NEBO_UI_NODE_TEXT_INPUT
    je .draw_input
    jmp .next_node
.draw_button:
    mov rdi,r13
    mov rsi,[r15+NEBO_UI_NODE_X_OFFSET]
    mov rdx,[r15+NEBO_UI_NODE_Y_OFFSET]
    mov rcx,[r15+NEBO_UI_NODE_WIDTH_OFFSET]
    mov r8,[r15+NEBO_UI_NODE_HEIGHT_OFFSET]
    lea r9,[rel ui_paint_button]
    call nebo_canvas_rectangle
    test eax,eax
    jnz .return
    jmp .draw_border
.draw_input:
    mov rdi,r13
    mov rsi,[r15+NEBO_UI_NODE_X_OFFSET]
    mov rdx,[r15+NEBO_UI_NODE_Y_OFFSET]
    mov rcx,[r15+NEBO_UI_NODE_WIDTH_OFFSET]
    mov r8,[r15+NEBO_UI_NODE_HEIGHT_OFFSET]
    lea r9,[rel ui_paint_input]
    call nebo_canvas_rectangle
    test eax,eax
    jnz .return
.draw_border:
    mov rdi,r13
    mov rsi,[r15+NEBO_UI_NODE_X_OFFSET]
    mov rdx,[r15+NEBO_UI_NODE_Y_OFFSET]
    mov rcx,[r15+NEBO_UI_NODE_WIDTH_OFFSET]
    mov r8,[r15+NEBO_UI_NODE_HEIGHT_OFFSET]
    lea r9,[rel ui_paint_border]
    test dword [r15+NEBO_UI_NODE_FLAGS_OFFSET],NEBO_UI_NODE_FLAG_FOCUSED
    jz .border_ready
    lea r9,[rel ui_paint_focus]
.border_ready:
    call nebo_canvas_rectangle
    test eax,eax
    jnz .return
.draw_text:
    mov rax,[r15+NEBO_UI_NODE_TEXT_LENGTH_OFFSET]
    test rax,rax
    jz .next_node
    mov rdi,r13
    mov rsi,[r15+NEBO_UI_NODE_TEXT_PTR_OFFSET]
    mov edx,eax
    mov rcx,[r15+NEBO_UI_NODE_X_OFFSET]
    add rcx,2
    mov r8,[r15+NEBO_UI_NODE_Y_OFFSET]
    add r8,2
    lea r9,[rel ui_paint_text]
    call nebo_canvas_text
    test eax,eax
    jnz .return
.next_node:
    inc r14
    jmp .render_loop
.render_done:
    inc qword [r12+NEBO_UI_TREE_RENDER_GENERATION_OFFSET]
    or dword [r12+NEBO_UI_TREE_FLAGS_OFFSET],NEBO_UI_TREE_FLAG_RENDERED
    xor eax,eax
    jmp .return
.bad_state:
    mov eax,NEBO_UI_ERROR_BAD_STATE
    jmp .return
.revision:
    mov eax,NEBO_UI_ERROR_REVISION_EXHAUSTED
.return:
    add rsp,8
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; eventPoll(tree,outEvent) -> eax=status, edx=present.
nebo_ui_event_poll:
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    mov rdi,r12
    call ui_require_active
    test eax,eax
    jnz .error
    test r13,r13
    jz .invalid
    cmp qword [r12+NEBO_UI_TREE_EVENT_COUNT_OFFSET],0
    je .empty
    mov rbx,[r12+NEBO_UI_TREE_EVENT_HEAD_OFFSET]
    imul rbx,rbx,NEBO_UI_EVENT_SIZE
    add rbx,[r12+NEBO_UI_TREE_EVENTS_PTR_OFFSET]
    mov rsi,rbx
    mov rdi,r13
    mov ecx,NEBO_UI_EVENT_QWORDS
    rep movsq
    mov rax,[r12+NEBO_UI_TREE_EVENT_HEAD_OFFSET]
    inc rax
    cmp rax,[r12+NEBO_UI_TREE_EVENT_CAPACITY_OFFSET]
    jb .head_ready
    xor eax,eax
.head_ready:
    mov [r12+NEBO_UI_TREE_EVENT_HEAD_OFFSET],rax
    dec qword [r12+NEBO_UI_TREE_EVENT_COUNT_OFFSET]
    mov edx,1
    xor eax,eax
    jmp .return
.empty:
    xor edx,edx
    xor eax,eax
    jmp .return
.invalid:
    mov eax,NEBO_UI_ERROR_INVALID_ARGUMENT
.error:
    xor edx,edx
.return:
    pop r13
    pop r12
    pop rbx
    ret

; focusNext(tree).
nebo_ui_focus_next:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov rdi,r12
    call ui_require_active
    test eax,eax
    jnz .return
    mov r13,[r12+NEBO_UI_TREE_FOCUSED_NODE_OFFSET]
    mov r14,[r12+NEBO_UI_TREE_NODE_COUNT_OFFSET]
    cmp r14,1
    jbe .ok
    mov r15,1
    cmp r13,NEBO_UI_NONE
    je .scan
    lea r15,[r13+1]
    cmp r15,r14
    jb .scan
    mov r15,1
.scan:
    xor ebx,ebx
.scan_loop:
    cmp rbx,r14
    jae .ok
    cmp r15,r14
    jb .index_ready
    mov r15,1
.index_ready:
    imul rax,r15,NEBO_UI_NODE_SIZE
    add rax,[r12+NEBO_UI_TREE_NODES_PTR_OFFSET]
    mov ecx,[rax+NEBO_UI_NODE_FLAGS_OFFSET]
    test ecx,NEBO_UI_NODE_FLAG_FOCUSABLE
    jz .advance
    test ecx,NEBO_UI_NODE_FLAG_DISABLED
    jnz .advance
    mov rdi,r12
    mov rsi,r15
    call ui_focus_change
    jmp .return
.advance:
    inc r15
    inc rbx
    jmp .scan_loop
.ok:
    xor eax,eax
.return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; focusPrevious(tree).
nebo_ui_focus_previous:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov rdi,r12
    call ui_require_active
    test eax,eax
    jnz .return
    mov r14,[r12+NEBO_UI_TREE_NODE_COUNT_OFFSET]
    cmp r14,1
    jbe .ok
    mov r13,[r12+NEBO_UI_TREE_FOCUSED_NODE_OFFSET]
    cmp r13,NEBO_UI_NONE
    jne .have_focus
    lea r15,[r14-1]
    jmp .scan
.have_focus:
    cmp r13,1
    ja .decrement
    lea r15,[r14-1]
    jmp .scan
.decrement:
    lea r15,[r13-1]
.scan:
    xor ebx,ebx
.scan_loop:
    cmp rbx,r14
    jae .ok
    cmp r15,1
    jae .index_ready
    lea r15,[r14-1]
.index_ready:
    imul rax,r15,NEBO_UI_NODE_SIZE
    add rax,[r12+NEBO_UI_TREE_NODES_PTR_OFFSET]
    mov ecx,[rax+NEBO_UI_NODE_FLAGS_OFFSET]
    test ecx,NEBO_UI_NODE_FLAG_FOCUSABLE
    jz .advance
    test ecx,NEBO_UI_NODE_FLAG_DISABLED
    jnz .advance
    mov rdi,r12
    mov rsi,r15
    call ui_focus_change
    jmp .return
.advance:
    dec r15
    inc rbx
    jmp .scan_loop
.ok:
    xor eax,eax
.return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; dispatchWindowEvent(tree,WindowEvent). The event itself remains pointer-free.
nebo_ui_dispatch_window_event:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rbp
    sub rsp,40
    mov r12,rdi
    mov r13,rsi
    mov rdi,r12
    call ui_require_active
    test eax,eax
    jnz .return
    test r13,r13
    jz .invalid
    cmp qword [r13+NEBO_WINDOW_EVENT_RESERVED_OFFSET],0
    jne .invalid_event
    mov ebx,[r13+NEBO_WINDOW_EVENT_KIND_OFFSET]
    cmp ebx,NEBO_WINDOW_EVENT_CREATED
    jb .invalid_event
    cmp ebx,NEBO_WINDOW_EVENT_KIND_COUNT
    jae .invalid_event
    cmp ebx,NEBO_WINDOW_EVENT_RESIZED
    je .resize
    cmp ebx,NEBO_WINDOW_EVENT_FOCUS_LOST
    je .focus_lost
    cmp ebx,NEBO_WINDOW_EVENT_POINTER_DOWN
    je .pointer_down
    cmp ebx,NEBO_WINDOW_EVENT_POINTER_UP
    je .pointer_up
    cmp ebx,NEBO_WINDOW_EVENT_KEY_DOWN
    je .key_down
    cmp ebx,NEBO_WINDOW_EVENT_TEXT_INPUT
    je .text_input
    xor eax,eax
    jmp .return

.resize:
    mov rax,[r13+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET]
    mov rcx,[r13+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET]
    cmp rax,1
    jb .invalid_event
    cmp rax,NEBO_UI_MAX_AXIS
    ja .invalid_event
    cmp rcx,1
    jb .invalid_event
    cmp rcx,NEBO_UI_MAX_AXIS
    ja .invalid_event
    mov [r12+NEBO_UI_TREE_WIDTH_OFFSET],rax
    mov [r12+NEBO_UI_TREE_HEIGHT_OFFSET],rcx
    mov rdx,[r12+NEBO_UI_TREE_NODES_PTR_OFFSET]
    mov [rdx+NEBO_UI_NODE_WIDTH_OFFSET],rax
    mov [rdx+NEBO_UI_NODE_HEIGHT_OFFSET],rcx
    mov qword [r12+NEBO_UI_TREE_LAYOUT_GENERATION_OFFSET],0
    and dword [r12+NEBO_UI_TREE_FLAGS_OFFSET],~(NEBO_UI_TREE_FLAG_LAYOUT_VALID | NEBO_UI_TREE_FLAG_RENDERED)
    xor eax,eax
    jmp .return

.focus_lost:
    mov rdi,r12
    mov rsi,NEBO_UI_NONE
    call ui_focus_change
    jmp .return

.pointer_down:
    mov rsi,[r13+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET]
    mov rdx,[r13+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET]
    mov [rsp+8],rsi
    mov [rsp+16],rdx
    mov rdi,r12
    call ui_find_at
    cmp rax,NEBO_UI_NONE
    je .ok
    mov r14,rax
    mov rdi,r12
    mov rsi,r14
    call ui_focus_change
    test eax,eax
    jnz .return
    mov rdi,r12
    mov rsi,r14
    call ui_node_ptr
    cmp dword [rax+NEBO_UI_NODE_KIND_OFFSET],NEBO_UI_NODE_BUTTON
    jne .ok
    or dword [rax+NEBO_UI_NODE_FLAGS_OFFSET],NEBO_UI_NODE_FLAG_PRESSED
    mov [r12+NEBO_UI_TREE_PRESSED_NODE_OFFSET],r14
    xor eax,eax
    jmp .return

.pointer_up:
    mov rsi,[r13+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET]
    mov rdx,[r13+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET]
    mov [rsp+8],rsi
    mov [rsp+16],rdx
    mov rdi,r12
    call ui_find_at
    mov r14,rax
    mov r15,[r12+NEBO_UI_TREE_PRESSED_NODE_OFFSET]
    cmp r15,NEBO_UI_NONE
    je .ok
    mov rdi,r12
    mov rsi,r15
    call ui_node_ptr
    test rax,rax
    jz .clear_pressed_only
    mov rbp,rax
    cmp r14,r15
    jne .clear_pressed_only
    cmp dword [rbp+NEBO_UI_NODE_KIND_OFFSET],NEBO_UI_NODE_BUTTON
    jne .clear_pressed_only
    test dword [rbp+NEBO_UI_NODE_FLAGS_OFFSET],NEBO_UI_NODE_FLAG_DISABLED
    jnz .clear_pressed_only
    mov rdi,r12
    mov esi,1
    call ui_can_enqueue
    test eax,eax
    jnz .return
    and dword [rbp+NEBO_UI_NODE_FLAGS_OFFSET],~NEBO_UI_NODE_FLAG_PRESSED
    mov qword [r12+NEBO_UI_TREE_PRESSED_NODE_OFFSET],NEBO_UI_NONE
    mov rdi,r12
    mov esi,NEBO_UI_EVENT_CLICK
    mov rdx,r15
    mov rcx,[rsp+8]
    mov r8,[rsp+16]
    xor r9d,r9d
    call ui_enqueue_event
    jmp .return
.clear_pressed_only:
    test rax,rax
    jz .clear_tree_pressed
    and dword [rax+NEBO_UI_NODE_FLAGS_OFFSET],~NEBO_UI_NODE_FLAG_PRESSED
.clear_tree_pressed:
    mov qword [r12+NEBO_UI_TREE_PRESSED_NODE_OFFSET],NEBO_UI_NONE
    xor eax,eax
    jmp .return

.key_down:
    mov rax,[r13+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET]
    cmp rax,NEBO_UI_KEY_TAB
    je .key_tab
    cmp rax,NEBO_UI_KEY_ENTER
    je .key_enter
    cmp rax,NEBO_UI_KEY_BACKSPACE
    je .key_backspace
    cmp rax,NEBO_UI_KEY_LEFT
    je .key_left
    cmp rax,NEBO_UI_KEY_RIGHT
    je .key_right
    xor eax,eax
    jmp .return
.key_tab:
    mov rax,[r13+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET]
    test rax,NEBO_UI_KEY_MOD_SHIFT
    jnz .key_shift_tab
    mov rdi,r12
    call nebo_ui_focus_next
    jmp .return
.key_shift_tab:
    mov rdi,r12
    call nebo_ui_focus_previous
    jmp .return
.key_enter:
    mov r14,[r12+NEBO_UI_TREE_FOCUSED_NODE_OFFSET]
    cmp r14,NEBO_UI_NONE
    je .ok
    mov rdi,r12
    mov rsi,r14
    call ui_node_ptr
    test rax,rax
    jz .invalid_focus
    mov ebx,[rax+NEBO_UI_NODE_KIND_OFFSET]
    cmp ebx,NEBO_UI_NODE_BUTTON
    je .enter_click
    cmp ebx,NEBO_UI_NODE_TEXT_INPUT
    je .enter_submit
    jmp .ok
.enter_click:
    mov ebx,NEBO_UI_EVENT_CLICK
    jmp .enter_enqueue
.enter_submit:
    mov ebx,NEBO_UI_EVENT_SUBMIT
.enter_enqueue:
    mov rdi,r12
    mov esi,1
    call ui_can_enqueue
    test eax,eax
    jnz .return
    mov rdi,r12
    mov esi,ebx
    mov rdx,r14
    mov rcx,[r13+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET]
    xor r8d,r8d
    xor r9d,r9d
    call ui_enqueue_event
    jmp .return

.key_left:
    mov r14,[r12+NEBO_UI_TREE_FOCUSED_NODE_OFFSET]
    cmp r14,NEBO_UI_NONE
    je .ok
    mov rdi,r12
    mov rsi,r14
    call ui_node_ptr
    test rax,rax
    jz .invalid_focus
    cmp dword [rax+NEBO_UI_NODE_KIND_OFFSET],NEBO_UI_NODE_TEXT_INPUT
    jne .ok
    mov rcx,[rax+NEBO_UI_NODE_CARET_OFFSET]
    test rcx,rcx
    jz .ok
    mov rdx,[rax+NEBO_UI_NODE_TEXT_PTR_OFFSET]
    dec rcx
.left_scan:
    movzx ebx,byte [rdx+rcx]
    and ebx,0xc0
    cmp ebx,0x80
    jne .left_ready
    test rcx,rcx
    jz .left_ready
    dec rcx
    jmp .left_scan
.left_ready:
    mov [rax+NEBO_UI_NODE_CARET_OFFSET],rcx
    xor eax,eax
    jmp .return

.key_right:
    mov r14,[r12+NEBO_UI_TREE_FOCUSED_NODE_OFFSET]
    cmp r14,NEBO_UI_NONE
    je .ok
    mov rdi,r12
    mov rsi,r14
    call ui_node_ptr
    test rax,rax
    jz .invalid_focus
    cmp dword [rax+NEBO_UI_NODE_KIND_OFFSET],NEBO_UI_NODE_TEXT_INPUT
    jne .ok
    mov rbp,rax
    mov rcx,[rbp+NEBO_UI_NODE_CARET_OFFSET]
    cmp rcx,[rbp+NEBO_UI_NODE_TEXT_LENGTH_OFFSET]
    jae .ok
    mov rdi,[rbp+NEBO_UI_NODE_TEXT_PTR_OFFSET]
    add rdi,rcx
    mov rsi,[rbp+NEBO_UI_NODE_TEXT_LENGTH_OFFSET]
    sub rsi,rcx
    call ui_utf8_next
    test eax,eax
    jnz .return
    add [rbp+NEBO_UI_NODE_CARET_OFFSET],r9
    xor eax,eax
    jmp .return

.key_backspace:
    mov r14,[r12+NEBO_UI_TREE_FOCUSED_NODE_OFFSET]
    cmp r14,NEBO_UI_NONE
    je .ok
    mov rdi,r12
    mov rsi,r14
    call ui_node_ptr
    test rax,rax
    jz .invalid_focus
    cmp dword [rax+NEBO_UI_NODE_KIND_OFFSET],NEBO_UI_NODE_TEXT_INPUT
    jne .ok
    mov rbp,rax
    mov r15,[rbp+NEBO_UI_NODE_CARET_OFFSET]
    test r15,r15
    jz .ok
    cmp qword [rbp+NEBO_UI_NODE_REVISION_OFFSET],-1
    je .revision
    mov rbx,r15
    dec rbx
    mov rdx,[rbp+NEBO_UI_NODE_TEXT_PTR_OFFSET]
.backspace_scan:
    movzx eax,byte [rdx+rbx]
    and eax,0xc0
    cmp eax,0x80
    jne .backspace_ready
    test rbx,rbx
    jz .backspace_ready
    dec rbx
    jmp .backspace_scan
.backspace_ready:
    mov rdi,r12
    mov esi,1
    call ui_can_enqueue
    test eax,eax
    jnz .return
    mov rdi,[rbp+NEBO_UI_NODE_TEXT_PTR_OFFSET]
    add rdi,rbx
    mov rsi,[rbp+NEBO_UI_NODE_TEXT_PTR_OFFSET]
    add rsi,r15
    mov rcx,[rbp+NEBO_UI_NODE_TEXT_LENGTH_OFFSET]
    sub rcx,r15
    cld
    rep movsb
    mov rax,r15
    sub rax,rbx
    sub [rbp+NEBO_UI_NODE_TEXT_LENGTH_OFFSET],rax
    mov [rbp+NEBO_UI_NODE_CARET_OFFSET],rbx
    inc qword [rbp+NEBO_UI_NODE_REVISION_OFFSET]
    mov rdi,r12
    mov esi,NEBO_UI_EVENT_CHANGE
    mov rdx,r14
    mov rcx,[rbp+NEBO_UI_NODE_TEXT_LENGTH_OFFSET]
    mov r8,rbx
    xor r9d,r9d
    call ui_enqueue_event
    jmp .return

.text_input:
    mov r14,[r12+NEBO_UI_TREE_FOCUSED_NODE_OFFSET]
    cmp r14,NEBO_UI_NONE
    je .ok
    mov rdi,r12
    mov rsi,r14
    call ui_node_ptr
    test rax,rax
    jz .invalid_focus
    cmp dword [rax+NEBO_UI_NODE_KIND_OFFSET],NEBO_UI_NODE_TEXT_INPUT
    jne .ok
    mov rbp,rax
    mov r15,[r13+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET]
    cmp r15,1
    jb .invalid_event
    cmp r15,4
    ja .invalid_event
    mov rax,[r13+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET]
    mov [rsp],rax
    lea rdi,[rsp]
    mov rsi,r15
    call ui_utf8_next
    test eax,eax
    jnz .invalid_event
    cmp r9,r15
    jne .invalid_event
    cmp r8,[r13+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET]
    jne .invalid_event
    mov rax,[rbp+NEBO_UI_NODE_TEXT_LENGTH_OFFSET]
    add rax,r15
    jc .text_capacity
    cmp rax,[rbp+NEBO_UI_NODE_TEXT_CAPACITY_OFFSET]
    ja .text_capacity
    cmp qword [rbp+NEBO_UI_NODE_REVISION_OFFSET],-1
    je .revision
    mov rdi,r12
    mov esi,1
    call ui_can_enqueue
    test eax,eax
    jnz .return
    mov rbx,[rbp+NEBO_UI_NODE_CARET_OFFSET]
    mov rcx,[rbp+NEBO_UI_NODE_TEXT_LENGTH_OFFSET]
    sub rcx,rbx
    test rcx,rcx
    jz .insert_bytes
    mov rdi,[rbp+NEBO_UI_NODE_TEXT_PTR_OFFSET]
    add rdi,[rbp+NEBO_UI_NODE_TEXT_LENGTH_OFFSET]
    add rdi,r15
    dec rdi
    mov rsi,[rbp+NEBO_UI_NODE_TEXT_PTR_OFFSET]
    add rsi,[rbp+NEBO_UI_NODE_TEXT_LENGTH_OFFSET]
    dec rsi
    std
    rep movsb
    cld
.insert_bytes:
    mov rdi,[rbp+NEBO_UI_NODE_TEXT_PTR_OFFSET]
    add rdi,rbx
    lea rsi,[rsp]
    mov rcx,r15
    cld
    rep movsb
    add [rbp+NEBO_UI_NODE_TEXT_LENGTH_OFFSET],r15
    add [rbp+NEBO_UI_NODE_CARET_OFFSET],r15
    inc qword [rbp+NEBO_UI_NODE_REVISION_OFFSET]
    mov rdi,r12
    mov esi,NEBO_UI_EVENT_CHANGE
    mov rdx,r14
    mov rcx,[rbp+NEBO_UI_NODE_TEXT_LENGTH_OFFSET]
    mov r8,[rbp+NEBO_UI_NODE_CARET_OFFSET]
    mov r9,[r13+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET]
    call ui_enqueue_event
    jmp .return

.ok:
    xor eax,eax
    jmp .return
.invalid:
    mov eax,NEBO_UI_ERROR_INVALID_ARGUMENT
    jmp .return
.invalid_event:
    mov eax,NEBO_UI_ERROR_INVALID_EVENT
    jmp .return
.invalid_focus:
    mov eax,NEBO_UI_ERROR_INVALID_FOCUS
    jmp .return
.text_capacity:
    mov eax,NEBO_UI_ERROR_TEXT_CAPACITY
    jmp .return
.revision:
    mov eax,NEBO_UI_ERROR_REVISION_EXHAUSTED
.return:
    cld
    add rsp,40
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; setDisabled(tree,node,bool).
nebo_ui_set_disabled:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14d,edx
    mov rdi,r12
    call ui_require_active
    test eax,eax
    jnz .return
    cmp r14d,1
    ja .invalid
    mov rdi,r12
    mov rsi,r13
    call ui_node_ptr
    test rax,rax
    jz .invalid
    mov r15,rax
    mov ebx,[r15+NEBO_UI_NODE_KIND_OFFSET]
    cmp ebx,NEBO_UI_NODE_BUTTON
    je .kind_ok
    cmp ebx,NEBO_UI_NODE_TEXT_INPUT
    jne .invalid_kind
.kind_ok:
    test r14d,r14d
    jz .enable
    test dword [r15+NEBO_UI_NODE_FLAGS_OFFSET],NEBO_UI_NODE_FLAG_DISABLED
    jnz .ok
    cmp r13,[r12+NEBO_UI_TREE_FOCUSED_NODE_OFFSET]
    jne .disable_commit
    mov rdi,r12
    mov rsi,NEBO_UI_NONE
    call ui_focus_change
    test eax,eax
    jnz .return
.disable_commit:
    or dword [r15+NEBO_UI_NODE_FLAGS_OFFSET],NEBO_UI_NODE_FLAG_DISABLED
    and dword [r15+NEBO_UI_NODE_FLAGS_OFFSET],~NEBO_UI_NODE_FLAG_PRESSED
    cmp r13,[r12+NEBO_UI_TREE_PRESSED_NODE_OFFSET]
    jne .ok
    mov qword [r12+NEBO_UI_TREE_PRESSED_NODE_OFFSET],NEBO_UI_NONE
    jmp .ok
.enable:
    and dword [r15+NEBO_UI_NODE_FLAGS_OFFSET],~NEBO_UI_NODE_FLAG_DISABLED
.ok:
    xor eax,eax
    jmp .return
.invalid:
    mov eax,NEBO_UI_ERROR_INVALID_ARGUMENT
    jmp .return
.invalid_kind:
    mov eax,NEBO_UI_ERROR_INVALID_KIND
.return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; setText(tree,node,text,textLen). TextInput copies into its caller-owned storage;
; Label/Button retain a validated borrowed slice.
nebo_ui_set_text:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rbp
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov rdi,r12
    call ui_require_active
    test eax,eax
    jnz .return
    cmp r15,NEBO_UI_MAX_TEXT_BYTES
    ja .capacity
    test r15,r15
    jz .utf8_ready
    test r14,r14
    jz .invalid
    mov rdi,r14
    mov rsi,r15
    call ui_validate_utf8
    test eax,eax
    jnz .return
.utf8_ready:
    mov rdi,r12
    mov rsi,r13
    call ui_node_ptr
    test rax,rax
    jz .invalid
    mov rbp,rax
    mov ebx,[rbp+NEBO_UI_NODE_KIND_OFFSET]
    cmp ebx,NEBO_UI_NODE_LABEL
    je .borrowed
    cmp ebx,NEBO_UI_NODE_BUTTON
    je .borrowed
    cmp ebx,NEBO_UI_NODE_TEXT_INPUT
    jne .invalid_kind
    cmp r15,[rbp+NEBO_UI_NODE_TEXT_CAPACITY_OFFSET]
    ja .capacity
    cmp qword [rbp+NEBO_UI_NODE_REVISION_OFFSET],-1
    je .revision
    mov rdi,r12
    mov esi,1
    call ui_can_enqueue
    test eax,eax
    jnz .return
    test r15,r15
    jz .copy_done
    mov rdi,[rbp+NEBO_UI_NODE_TEXT_PTR_OFFSET]
    cmp rdi,r14
    je .copy_done
    ; Reject overlapping distinct ranges to keep the copy deterministic.
    mov rsi,[rbp+NEBO_UI_NODE_TEXT_CAPACITY_OFFSET]
    mov rdx,r14
    mov rcx,r15
    call ui_ranges_overlap
    test eax,eax
    jnz .overlap
    mov rdi,[rbp+NEBO_UI_NODE_TEXT_PTR_OFFSET]
    mov rsi,r14
    mov rcx,r15
    cld
    rep movsb
.copy_done:
    mov [rbp+NEBO_UI_NODE_TEXT_LENGTH_OFFSET],r15
    mov [rbp+NEBO_UI_NODE_CARET_OFFSET],r15
    inc qword [rbp+NEBO_UI_NODE_REVISION_OFFSET]
    mov rdi,r12
    mov esi,NEBO_UI_EVENT_CHANGE
    mov rdx,r13
    mov rcx,r15
    mov r8,r15
    xor r9d,r9d
    call ui_enqueue_event
    xor eax,eax
    jmp .return
.borrowed:
    cmp qword [rbp+NEBO_UI_NODE_REVISION_OFFSET],-1
    je .revision
    mov [rbp+NEBO_UI_NODE_TEXT_PTR_OFFSET],r14
    mov [rbp+NEBO_UI_NODE_TEXT_LENGTH_OFFSET],r15
    mov [rbp+NEBO_UI_NODE_TEXT_CAPACITY_OFFSET],r15
    mov [rbp+NEBO_UI_NODE_CARET_OFFSET],r15
    inc qword [rbp+NEBO_UI_NODE_REVISION_OFFSET]
    xor eax,eax
    jmp .return
.invalid:
    mov eax,NEBO_UI_ERROR_INVALID_ARGUMENT
    jmp .return
.invalid_kind:
    mov eax,NEBO_UI_ERROR_INVALID_KIND
    jmp .return
.capacity:
    mov eax,NEBO_UI_ERROR_TEXT_CAPACITY
    jmp .return
.overlap:
    mov eax,NEBO_UI_ERROR_STORAGE_OVERLAP
    jmp .return
.revision:
    mov eax,NEBO_UI_ERROR_REVISION_EXHAUSTED
.return:
    add rsp,8
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; accessibilitySnapshot(tree,node,out96).
nebo_ui_accessibility_snapshot:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov rdi,r12
    call ui_require_active
    test eax,eax
    jnz .return
    test r14,r14
    jz .invalid
    mov rdi,r12
    mov rsi,r13
    call ui_node_ptr
    test rax,rax
    jz .invalid
    mov r15,rax
    mov rdi,r14
    mov ecx,NEBO_UI_ACCESS_QWORDS
    call ui_zero_qwords
    mov [r14+NEBO_UI_ACCESS_NODE_OFFSET],r13
    mov eax,[r15+NEBO_UI_NODE_ROLE_OFFSET]
    mov [r14+NEBO_UI_ACCESS_ROLE_OFFSET],eax
    xor ebx,ebx
    mov eax,[r15+NEBO_UI_NODE_FLAGS_OFFSET]
    test eax,NEBO_UI_NODE_FLAG_DISABLED
    jz .not_disabled
    or ebx,NEBO_UI_ACCESS_STATE_DISABLED
.not_disabled:
    test eax,NEBO_UI_NODE_FLAG_FOCUSED
    jz .not_focused
    or ebx,NEBO_UI_ACCESS_STATE_FOCUSED
.not_focused:
    test eax,NEBO_UI_NODE_FLAG_PRESSED
    jz .not_pressed
    or ebx,NEBO_UI_ACCESS_STATE_PRESSED
.not_pressed:
    test eax,NEBO_UI_NODE_FLAG_EDITABLE
    jz .state_ready
    or ebx,NEBO_UI_ACCESS_STATE_EDITABLE
.state_ready:
    mov [r14+NEBO_UI_ACCESS_STATE_OFFSET],ebx
    mov rax,[r15+NEBO_UI_NODE_X_OFFSET]
    mov [r14+NEBO_UI_ACCESS_X_OFFSET],rax
    mov rax,[r15+NEBO_UI_NODE_Y_OFFSET]
    mov [r14+NEBO_UI_ACCESS_Y_OFFSET],rax
    mov rax,[r15+NEBO_UI_NODE_WIDTH_OFFSET]
    mov [r14+NEBO_UI_ACCESS_WIDTH_OFFSET],rax
    mov rax,[r15+NEBO_UI_NODE_HEIGHT_OFFSET]
    mov [r14+NEBO_UI_ACCESS_HEIGHT_OFFSET],rax
    mov rax,[r15+NEBO_UI_NODE_NAME_PTR_OFFSET]
    mov [r14+NEBO_UI_ACCESS_NAME_PTR_OFFSET],rax
    mov rax,[r15+NEBO_UI_NODE_NAME_LENGTH_OFFSET]
    mov [r14+NEBO_UI_ACCESS_NAME_LENGTH_OFFSET],rax
    mov rax,[r15+NEBO_UI_NODE_TEXT_PTR_OFFSET]
    mov [r14+NEBO_UI_ACCESS_VALUE_PTR_OFFSET],rax
    mov rax,[r15+NEBO_UI_NODE_TEXT_LENGTH_OFFSET]
    mov [r14+NEBO_UI_ACCESS_VALUE_LENGTH_OFFSET],rax
    mov rax,[r15+NEBO_UI_NODE_CARET_OFFSET]
    mov [r14+NEBO_UI_ACCESS_CARET_OFFSET],rax
    mov rax,[r12+NEBO_UI_TREE_LAYOUT_GENERATION_OFFSET]
    mov [r14+NEBO_UI_ACCESS_GENERATION_OFFSET],rax
    xor eax,eax
    jmp .return
.invalid:
    mov eax,NEBO_UI_ERROR_INVALID_ARGUMENT
.return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; close(tree). Terminal and exactly once.
nebo_ui_close:
    test rdi,rdi
    jz .invalid
    mov rax,[rdi+NEBO_UI_TREE_MAGIC_OFFSET]
    mov rcx,NEBO_UI_TREE_MAGIC
    cmp rax,rcx
    jne .invalid
    cmp dword [rdi+NEBO_UI_TREE_STATE_OFFSET],NEBO_UI_TREE_STATE_ACTIVE
    jne .closed
    mov dword [rdi+NEBO_UI_TREE_STATE_OFFSET],NEBO_UI_TREE_STATE_CLOSED
    mov qword [rdi+NEBO_UI_TREE_FOCUSED_NODE_OFFSET],NEBO_UI_NONE
    mov qword [rdi+NEBO_UI_TREE_PRESSED_NODE_OFFSET],NEBO_UI_NONE
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_UI_ERROR_INVALID_ARGUMENT
    ret
.closed:
    mov eax,NEBO_UI_ERROR_CLOSED
    ret
