; Nebo Assembly — LAYOUT-COMPOSTO-GRID-ROW-COLUMN-CELL-TABS-E-SPLIT bounded deterministic layout tree
bits 64
default rel
%include "runtime/layout_model.inc"
global nebo_layout_container_build
global nebo_layout_cell_place
global nebo_layout_profile_validate
global nebo_layout_dashboard_compose
global nebo_layout_box_validate
global nebo_layout_responsive_resolve
global nebo_layout_composite_build
global nebo_layout_lifecycle_apply
global nebo_layout_hash
global nebo_layout_tree_validate
section .text
; Builds a grid/row/column node after validating its bounded child slice.
nebo_layout_container_build:
    test rdi, rdi
    jz .container_invalid
    test rsi, rsi
    jz .container_invalid
    mov rcx, [rdi + NEBO_LAYOUT_NODE_KIND_OFFSET]
    cmp rcx, NEBO_LAYOUT_GRID
    jb .container_invalid
    cmp rcx, NEBO_LAYOUT_COLUMN
    ja .container_invalid
    cmp qword [rdi + NEBO_LAYOUT_NODE_ID_OFFSET], 0
    je .container_invalid
    mov rdx, [rdi + NEBO_LAYOUT_NODE_CHILD_COUNT_OFFSET]
    cmp rdx, NEBO_LAYOUT_MAX_NODES
    ja .container_limit
    test rdx, rdx
    jz .container_size
    cmp qword [rdi + NEBO_LAYOUT_NODE_CHILDREN_OFFSET], 0
    je .container_invalid
.container_size:
    mov r8, [rdi + NEBO_LAYOUT_NODE_WIDTH_OFFSET]
    mov r9, [rdi + NEBO_LAYOUT_NODE_HEIGHT_OFFSET]
    test r8, r8
    jle .container_invalid
    test r9, r9
    jle .container_invalid
    mov rax, r8
    mul r9
    test rdx, rdx
    jnz .container_limit
    cmp rax, NEBO_LAYOUT_MAX_AREA
    ja .container_limit
    mov rax, [rdi + 0]
    mov [rsi + 0], rax
    mov rax, [rdi + 8]
    mov [rsi + 8], rax
    mov rax, [rdi + 16]
    mov [rsi + 16], rax
    mov rax, [rdi + 24]
    mov [rsi + 24], rax
    mov rax, [rdi + 32]
    mov [rsi + 32], rax
    mov rax, [rdi + 40]
    mov [rsi + 40], rax
    mov rax, [rdi + 48]
    mov [rsi + 48], rax
    mov qword [rsi + NEBO_LAYOUT_NODE_STATE_OFFSET], NEBO_LAYOUT_NODE_READY
    xor eax, eax
    ret
.container_limit:
    mov eax, NEBO_LAYOUT_LIMIT
    ret
.container_invalid:
    mov eax, NEBO_LAYOUT_INVALID
    ret

; Places one node in a zero-based grid cell/region with explicit spans.
nebo_layout_cell_place:
    test rdi, rdi
    jz .cell_invalid
    test rsi, rsi
    jz .cell_invalid
    mov rax, [rdi + NEBO_CELL_NODE_ID_OFFSET]
    mov rcx, [rdi + NEBO_CELL_PARENT_ID_OFFSET]
    test rax, rax
    jz .cell_invalid
    test rcx, rcx
    jz .cell_invalid
    cmp rax, rcx
    je .cell_conflict
    mov r8, [rdi + NEBO_CELL_GRID_ROWS_OFFSET]
    mov r9, [rdi + NEBO_CELL_GRID_COLUMNS_OFFSET]
    test r8, r8
    jz .cell_invalid
    test r9, r9
    jz .cell_invalid
    cmp r8, NEBO_CELL_MAX_ROWS
    ja .cell_limit
    cmp r9, NEBO_CELL_MAX_COLUMNS
    ja .cell_limit
    mov r10, [rdi + NEBO_CELL_ROW_OFFSET]
    mov r11, [rdi + NEBO_CELL_COLUMN_OFFSET]
    cmp r10, r8
    jae .cell_limit
    cmp r11, r9
    jae .cell_limit
    mov rdx, [rdi + NEBO_CELL_ROW_SPAN_OFFSET]
    test rdx, rdx
    jz .cell_invalid
    add rdx, r10
    jc .cell_limit
    cmp rdx, r8
    ja .cell_limit
    mov rcx, [rdi + NEBO_CELL_COLUMN_SPAN_OFFSET]
    test rcx, rcx
    jz .cell_invalid
    add rcx, r11
    jc .cell_limit
    cmp rcx, r9
    ja .cell_limit
    mov rax, r10
    imul rax, r9
    add rax, r11
    mov rdx, [rdi + 0]
    mov [rsi + 0], rdx
    mov rdx, [rdi + 8]
    mov [rsi + 8], rdx
    mov rdx, [rdi + 16]
    mov [rsi + 16], rdx
    mov rdx, [rdi + 24]
    mov [rsi + 24], rdx
    mov rdx, [rdi + 32]
    mov [rsi + 32], rdx
    mov rdx, [rdi + 40]
    mov [rsi + 40], rdx
    mov rdx, [rdi + 48]
    mov [rsi + 48], rdx
    mov rdx, [rdi + 56]
    mov [rsi + 56], rdx
    mov [rsi + NEBO_CELL_LINEAR_OFFSET], rax
    mov qword [rsi + NEBO_CELL_STATE_OFFSET], NEBO_CELL_READY
    xor eax, eax
    ret
.cell_conflict:
    mov eax, NEBO_LAYOUT_CONFLICT
    ret
.cell_limit:
    mov eax, NEBO_LAYOUT_LIMIT
    ret
.cell_invalid:
    mov eax, NEBO_LAYOUT_INVALID
    ret

; Layout/view profiles carry factual target and min/max viewport bounds.
nebo_layout_profile_validate:
    test rdi, rdi
    jz .profile_invalid
    test rsi, rsi
    jz .profile_invalid
    cmp qword [rdi + NEBO_PROFILE_ID_OFFSET], 0
    je .profile_invalid
    mov rcx, [rdi + NEBO_PROFILE_LAYOUT_KIND_OFFSET]
    cmp rcx, NEBO_LAYOUT_GRID
    jb .profile_invalid
    cmp rcx, NEBO_LAYOUT_COLUMN
    ja .profile_invalid
    mov rdx, [rdi + NEBO_PROFILE_VIEW_KIND_OFFSET]
    cmp rdx, NEBO_PROFILE_VIEW_COMPACT
    jb .profile_invalid
    cmp rdx, NEBO_PROFILE_VIEW_INSPECT
    ja .profile_invalid
    mov r8, [rdi + NEBO_PROFILE_MIN_WIDTH_OFFSET]
    mov r9, [rdi + NEBO_PROFILE_MIN_HEIGHT_OFFSET]
    mov r10, [rdi + NEBO_PROFILE_MAX_WIDTH_OFFSET]
    mov r11, [rdi + NEBO_PROFILE_MAX_HEIGHT_OFFSET]
    test r8, r8
    jle .profile_invalid
    test r9, r9
    jle .profile_invalid
    cmp r10, r8
    jb .profile_limit
    cmp r11, r9
    jb .profile_limit
    mov rax, r10
    mul r11
    test rdx, rdx
    jnz .profile_limit
    cmp rax, NEBO_LAYOUT_MAX_AREA
    ja .profile_limit
    mov rax, [rdi + NEBO_PROFILE_TARGET_OFFSET]
    cmp rax, NEBO_LAYOUT_TARGET_HEADLESS
    jb .profile_target
    cmp rax, NEBO_LAYOUT_TARGET_LIVE
    ja .profile_target
    cmp rax, NEBO_LAYOUT_TARGET_LIVE
    jne .profile_commit
    test qword [rdi + NEBO_PROFILE_FLAGS_OFFSET], NEBO_PROFILE_CAP_LIVE
    jz .profile_target
.profile_commit:
    mov rax, [rdi + 0]
    mov [rsi + 0], rax
    mov rax, [rdi + 8]
    mov [rsi + 8], rax
    mov rax, [rdi + 16]
    mov [rsi + 16], rax
    mov rax, [rdi + 24]
    mov [rsi + 24], rax
    mov rax, [rdi + 32]
    mov [rsi + 32], rax
    mov rax, [rdi + 40]
    mov [rsi + 40], rax
    mov rax, [rdi + 48]
    mov [rsi + 48], rax
    mov rax, [rdi + 56]
    mov [rsi + 56], rax
    mov rax, [rdi + 64]
    mov [rsi + 64], rax
    mov qword [rsi + NEBO_PROFILE_STATE_OFFSET], NEBO_PROFILE_READY
    xor eax, eax
    ret
.profile_target:
    mov eax, NEBO_LAYOUT_TARGET
    ret
.profile_limit:
    mov eax, NEBO_LAYOUT_LIMIT
    ret
.profile_invalid:
    mov eax, NEBO_LAYOUT_INVALID
    ret

; Composes a stable node table; the layout tree contains no business logic.
nebo_layout_dashboard_compose:
    test rdi, rdi
    jz .dashboard_invalid_pre
    test rsi, rsi
    jz .dashboard_invalid_pre
    push rbx
    push r12
    mov rbx, rsi
    mov rcx, [rdi + NEBO_DASHBOARD_COUNT_OFFSET]
    test rcx, rcx
    jz .dashboard_invalid
    cmp rcx, NEBO_LAYOUT_MAX_NODES
    ja .dashboard_limit
    mov rdx, [rdi + NEBO_DASHBOARD_NODES_OFFSET]
    test rdx, rdx
    jz .dashboard_invalid
    mov r8, [rdi + NEBO_DASHBOARD_ROOT_ID_OFFSET]
    test r8, r8
    jz .dashboard_invalid
    mov r9, [rdi + NEBO_DASHBOARD_PROFILE_OFFSET]
    test r9, r9
    jz .dashboard_invalid
    cmp qword [r9 + NEBO_PROFILE_STATE_OFFSET], NEBO_PROFILE_READY
    jne .dashboard_invalid
    cmp qword [r9 + NEBO_PROFILE_VIEW_KIND_OFFSET], NEBO_PROFILE_VIEW_DASHBOARD
    jne .dashboard_conflict
    mov rax, 0xcbf29ce484222325
    mov r11, 0x100000001b3
    xor r9d, r9d
    xor r12d, r12d
    xor r10d, r10d
.dashboard_loop:
    cmp r10, rcx
    jae .dashboard_checked
    mov rdi, r10
    shl rdi, 6
    add rdi, rdx
    cmp qword [rdi + NEBO_LAYOUT_NODE_STATE_OFFSET], NEBO_LAYOUT_NODE_READY
    jne .dashboard_invalid
    mov rsi, [rdi + NEBO_LAYOUT_NODE_ID_OFFSET]
    test rsi, rsi
    jz .dashboard_invalid
    cmp rsi, r9
    jbe .dashboard_conflict
    mov r9, rsi
    cmp rsi, r8
    jne .dashboard_hash
    mov r12d, 1
.dashboard_hash:
    xor rax, r9
    imul rax, r11
    xor rax, [rdi + NEBO_LAYOUT_NODE_KIND_OFFSET]
    imul rax, r11
    xor rax, [rdi + NEBO_LAYOUT_NODE_CHILD_COUNT_OFFSET]
    imul rax, r11
    inc r10
    jmp .dashboard_loop
.dashboard_checked:
    test r12, r12
    jz .dashboard_conflict
    mov [rbx + NEBO_DASHBOARD_RECEIPT_COUNT_OFFSET], rcx
    mov [rbx + NEBO_DASHBOARD_RECEIPT_ROOT_ID_OFFSET], r8
    mov [rbx + NEBO_DASHBOARD_RECEIPT_DIGEST_OFFSET], rax
    mov qword [rbx + NEBO_DASHBOARD_RECEIPT_STATE_OFFSET], NEBO_DASHBOARD_READY
    xor eax, eax
    jmp .dashboard_done
.dashboard_conflict:
    mov eax, NEBO_LAYOUT_CONFLICT
    jmp .dashboard_done
.dashboard_limit:
    mov eax, NEBO_LAYOUT_LIMIT
    jmp .dashboard_done
.dashboard_invalid:
    mov eax, NEBO_LAYOUT_INVALID
.dashboard_done:
    pop r12
    pop rbx
    ret
.dashboard_invalid_pre:
    mov eax, NEBO_LAYOUT_INVALID
    ret

; Validates box-model spacing/alignment and publishes exact total extents.
nebo_layout_box_validate:
    test rdi, rdi
    jz .box_invalid
    test rsi, rsi
    jz .box_invalid
    mov r8, [rdi + NEBO_BOX_CONTENT_WIDTH_OFFSET]
    mov r9, [rdi + NEBO_BOX_CONTENT_HEIGHT_OFFSET]
    test r8, r8
    jle .box_invalid
    test r9, r9
    jle .box_invalid
    mov r10, 2
.box_spacing_loop:
    cmp r10, 10
    jae .box_alignment
    mov rax, [rdi + r10 * 8]
    test rax, rax
    js .box_invalid
    movsxd rdx, eax
    cmp rdx, rax
    jne .box_limit
    inc r10
    jmp .box_spacing_loop
.box_alignment:
    mov rax, [rdi + NEBO_BOX_ALIGN_HORIZONTAL_OFFSET]
    cmp rax, NEBO_BOX_ALIGN_START
    jb .box_invalid
    cmp rax, NEBO_BOX_ALIGN_END
    ja .box_invalid
    mov rax, [rdi + NEBO_BOX_ALIGN_VERTICAL_OFFSET]
    cmp rax, NEBO_BOX_ALIGN_START
    jb .box_invalid
    cmp rax, NEBO_BOX_ALIGN_END
    ja .box_invalid
    add r8, [rdi + NEBO_BOX_MARGIN_LEFT_OFFSET]
    jc .box_limit
    add r8, [rdi + NEBO_BOX_MARGIN_RIGHT_OFFSET]
    jc .box_limit
    add r8, [rdi + NEBO_BOX_PADDING_LEFT_OFFSET]
    jc .box_limit
    add r8, [rdi + NEBO_BOX_PADDING_RIGHT_OFFSET]
    jc .box_limit
    add r9, [rdi + NEBO_BOX_MARGIN_TOP_OFFSET]
    jc .box_limit
    add r9, [rdi + NEBO_BOX_MARGIN_BOTTOM_OFFSET]
    jc .box_limit
    add r9, [rdi + NEBO_BOX_PADDING_TOP_OFFSET]
    jc .box_limit
    add r9, [rdi + NEBO_BOX_PADDING_BOTTOM_OFFSET]
    jc .box_limit
    mov rax, r8
    mul r9
    test rdx, rdx
    jnz .box_limit
    cmp rax, NEBO_LAYOUT_MAX_AREA
    ja .box_limit
    mov rcx, 12
    rep movsq
    mov [rsi + NEBO_BOX_TOTAL_WIDTH_OFFSET - 96], r8
    mov [rsi + NEBO_BOX_TOTAL_HEIGHT_OFFSET - 96], r9
    mov qword [rsi + NEBO_BOX_STATE_OFFSET - 96], NEBO_BOX_READY
    xor eax, eax
    ret
.box_limit:
    mov eax, NEBO_LAYOUT_LIMIT
    ret
.box_invalid:
    mov eax, NEBO_LAYOUT_INVALID
    ret

; Resolves preferred/min sizing against an explicit viewport and wrap rule.
nebo_layout_responsive_resolve:
    test rdi, rdi
    jz .responsive_invalid
    test rsi, rsi
    jz .responsive_invalid
    mov r8, [rdi + NEBO_RESPONSIVE_AVAILABLE_WIDTH_OFFSET]
    mov r9, [rdi + NEBO_RESPONSIVE_AVAILABLE_HEIGHT_OFFSET]
    mov r10, [rdi + NEBO_RESPONSIVE_PREFERRED_WIDTH_OFFSET]
    mov r11, [rdi + NEBO_RESPONSIVE_PREFERRED_HEIGHT_OFFSET]
    test r8, r8
    jle .responsive_invalid
    test r9, r9
    jle .responsive_invalid
    test r10, r10
    jle .responsive_invalid
    test r11, r11
    jle .responsive_invalid
    mov rcx, [rdi + NEBO_RESPONSIVE_MIN_WIDTH_OFFSET]
    mov rdx, [rdi + NEBO_RESPONSIVE_MIN_HEIGHT_OFFSET]
    test rcx, rcx
    jle .responsive_invalid
    test rdx, rdx
    jle .responsive_invalid
    cmp rcx, r8
    ja .responsive_limit
    cmp rdx, r9
    ja .responsive_limit
    mov rax, [rdi + NEBO_RESPONSIVE_WRAP_OFFSET]
    cmp rax, NEBO_WRAP_CHARACTER
    ja .responsive_invalid
    cmp r10, r8
    jbe .responsive_single
    cmp rax, NEBO_WRAP_NONE
    je .responsive_limit
    mov rax, r10
    xor edx, edx
    div r8
    test rdx, rdx
    jz .responsive_lines_ready
    inc rax
.responsive_lines_ready:
    mov rcx, rax
    mov rax, r11
    mul rcx
    test rdx, rdx
    jnz .responsive_limit
    cmp rax, r9
    ja .responsive_limit
    mov r10, r8
    mov r11, rax
    jmp .responsive_commit
.responsive_single:
    mov rcx, 1
    cmp r10, [rdi + NEBO_RESPONSIVE_MIN_WIDTH_OFFSET]
    jae .responsive_height
    mov r10, [rdi + NEBO_RESPONSIVE_MIN_WIDTH_OFFSET]
.responsive_height:
    cmp r11, [rdi + NEBO_RESPONSIVE_MIN_HEIGHT_OFFSET]
    jae .responsive_commit
    mov r11, [rdi + NEBO_RESPONSIVE_MIN_HEIGHT_OFFSET]
.responsive_commit:
    mov [rsi + NEBO_RESPONSIVE_RESULT_WIDTH_OFFSET], r10
    mov [rsi + NEBO_RESPONSIVE_RESULT_HEIGHT_OFFSET], r11
    mov [rsi + NEBO_RESPONSIVE_LINES_OFFSET], rcx
    mov qword [rsi + NEBO_RESPONSIVE_STATE_OFFSET], NEBO_RESPONSIVE_READY
    xor eax, eax
    ret
.responsive_limit:
    mov eax, NEBO_LAYOUT_LIMIT
    ret
.responsive_invalid:
    mov eax, NEBO_LAYOUT_INVALID
    ret

; Composes tabs, split and stack nodes from one bounded child slice.
nebo_layout_composite_build:
    test rdi, rdi
    jz .composite_invalid
    test rsi, rsi
    jz .composite_invalid
    mov rax, [rdi + NEBO_COMPOSITE_KIND_OFFSET]
    cmp rax, NEBO_LAYOUT_TABS
    jb .composite_invalid
    cmp rax, NEBO_LAYOUT_STACK
    ja .composite_invalid
    cmp qword [rdi + NEBO_COMPOSITE_ID_OFFSET], 0
    je .composite_invalid
    cmp qword [rdi + NEBO_COMPOSITE_CHILDREN_OFFSET], 0
    je .composite_invalid
    mov rcx, [rdi + NEBO_COMPOSITE_CHILD_COUNT_OFFSET]
    test rcx, rcx
    jz .composite_invalid
    cmp rcx, NEBO_LAYOUT_MAX_NODES
    ja .composite_limit
    cmp rax, NEBO_LAYOUT_SPLIT
    je .composite_split
    cmp qword [rdi + NEBO_COMPOSITE_ACTIVE_OFFSET], rcx
    jae .composite_conflict
    jmp .composite_commit
.composite_split:
    cmp rcx, 2
    jne .composite_conflict
    mov rdx, [rdi + NEBO_COMPOSITE_SPLIT_BASIS_OFFSET]
    test rdx, rdx
    jz .composite_invalid
    cmp rdx, 99
    ja .composite_invalid
    mov rdx, [rdi + NEBO_COMPOSITE_AXIS_OFFSET]
    cmp rdx, NEBO_COMPOSITE_AXIS_HORIZONTAL
    jb .composite_invalid
    cmp rdx, NEBO_COMPOSITE_AXIS_VERTICAL
    ja .composite_invalid
.composite_commit:
    mov rax, [rdi + 0]
    mov [rsi + 0], rax
    mov rax, [rdi + 8]
    mov [rsi + 8], rax
    mov rax, [rdi + 16]
    mov [rsi + 16], rax
    mov rax, [rdi + 24]
    mov [rsi + 24], rax
    mov rax, [rdi + 32]
    mov [rsi + 32], rax
    mov rax, [rdi + 40]
    mov [rsi + 40], rax
    mov rax, [rdi + 48]
    mov [rsi + 48], rax
    mov qword [rsi + NEBO_COMPOSITE_STATE_OFFSET], NEBO_COMPOSITE_READY
    xor eax, eax
    ret
.composite_conflict:
    mov eax, NEBO_LAYOUT_CONFLICT
    ret
.composite_limit:
    mov eax, NEBO_LAYOUT_LIMIT
    ret
.composite_invalid:
    mov eax, NEBO_LAYOUT_INVALID
    ret

; Applies one present/refresh transition without re-evaluating source state.
nebo_layout_lifecycle_apply:
    test rdi, rdi
    jz .lifecycle_invalid
    test rsi, rsi
    jz .lifecycle_invalid
    cmp qword [rdi + NEBO_LIFECYCLE_PLAN_STATE_OFFSET], NEBO_LIFECYCLE_PLAN_READY
    jne .lifecycle_invalid
    cmp qword [rdi + NEBO_LIFECYCLE_EFFECTS_OFFSET], NEBO_LIFECYCLE_EFFECT_PRESENT
    jne .lifecycle_invalid
    mov rax, [rdi + NEBO_LIFECYCLE_OPERATION_OFFSET]
    cmp rax, NEBO_LIFECYCLE_PRESENT
    je .lifecycle_present
    cmp rax, NEBO_LIFECYCLE_REFRESH
    jne .lifecycle_invalid
    test qword [rdi + NEBO_LIFECYCLE_CAPABILITIES_OFFSET], NEBO_LIFECYCLE_CAP_REFRESH
    jz .lifecycle_target
    mov rcx, [rdi + NEBO_LIFECYCLE_CURRENT_GENERATION_OFFSET]
    test rcx, rcx
    jz .lifecycle_state
    inc rcx
    jz .lifecycle_limit
    cmp rcx, [rdi + NEBO_LIFECYCLE_SOURCE_GENERATION_OFFSET]
    jne .lifecycle_state
    jmp .lifecycle_commit
.lifecycle_present:
    cmp qword [rdi + NEBO_LIFECYCLE_CURRENT_GENERATION_OFFSET], 0
    jne .lifecycle_state
    cmp qword [rdi + NEBO_LIFECYCLE_SOURCE_GENERATION_OFFSET], 0
    jne .lifecycle_state
    mov rcx, 1
.lifecycle_commit:
    mov [rsi + NEBO_LIFECYCLE_RECEIPT_OPERATION_OFFSET], rax
    mov [rsi + NEBO_LIFECYCLE_RECEIPT_GENERATION_OFFSET], rcx
    mov qword [rsi + NEBO_LIFECYCLE_RECEIPT_EVALUATIONS_OFFSET], 1
    mov qword [rsi + NEBO_LIFECYCLE_RECEIPT_STATE_OFFSET], NEBO_LIFECYCLE_READY
    xor eax, eax
    ret
.lifecycle_target:
    mov eax, NEBO_LAYOUT_TARGET
    ret
.lifecycle_state:
    mov eax, NEBO_LAYOUT_LIFECYCLE
    ret
.lifecycle_limit:
    mov eax, NEBO_LAYOUT_LIMIT
    ret
.lifecycle_invalid:
    mov eax, NEBO_LAYOUT_INVALID
    ret

; Hashes semantic layout fields only; pointer identity is deliberately excluded.
nebo_layout_hash:
    test rdi, rdi
    jz .hash_invalid
    test rsi, rsi
    jz .hash_invalid
    mov rcx, [rdi + NEBO_LAYOUT_HASH_COUNT_OFFSET]
    test rcx, rcx
    jz .hash_invalid
    cmp rcx, NEBO_LAYOUT_MAX_NODES
    ja .hash_limit
    mov rdx, [rdi + NEBO_LAYOUT_HASH_NODES_OFFSET]
    test rdx, rdx
    jz .hash_invalid
    mov rax, 0xcbf29ce484222325
    mov r11, 0x100000001b3
    xor r8d, r8d
    xor r9d, r9d
.hash_loop:
    cmp r8, rcx
    jae .hash_commit
    mov r10, r8
    shl r10, 6
    add r10, rdx
    cmp qword [r10 + NEBO_LAYOUT_NODE_STATE_OFFSET], NEBO_LAYOUT_NODE_READY
    jne .hash_invalid
    mov rdi, [r10 + NEBO_LAYOUT_NODE_ID_OFFSET]
    test rdi, rdi
    jz .hash_invalid
    cmp rdi, r9
    jbe .hash_conflict
    mov r9, rdi
    xor rax, [r10 + NEBO_LAYOUT_NODE_KIND_OFFSET]
    imul rax, r11
    xor rax, rdi
    imul rax, r11
    xor rax, [r10 + NEBO_LAYOUT_NODE_CHILD_COUNT_OFFSET]
    imul rax, r11
    xor rax, [r10 + NEBO_LAYOUT_NODE_WIDTH_OFFSET]
    imul rax, r11
    xor rax, [r10 + NEBO_LAYOUT_NODE_HEIGHT_OFFSET]
    imul rax, r11
    xor rax, [r10 + NEBO_LAYOUT_NODE_FLAGS_OFFSET]
    imul rax, r11
    inc r8
    jmp .hash_loop
.hash_commit:
    mov [rsi + NEBO_LAYOUT_HASH_RECEIPT_COUNT_OFFSET], rcx
    mov [rsi + NEBO_LAYOUT_HASH_RECEIPT_DIGEST_OFFSET], rax
    mov qword [rsi + NEBO_LAYOUT_HASH_RECEIPT_STATE_OFFSET], NEBO_LAYOUT_HASH_READY
    xor eax, eax
    ret
.hash_conflict:
    mov eax, NEBO_LAYOUT_CONFLICT
    ret
.hash_limit:
    mov eax, NEBO_LAYOUT_LIMIT
    ret
.hash_invalid:
    mov eax, NEBO_LAYOUT_INVALID
    ret

; Closes a bounded rooted tree: every non-root node has one prior parent.
nebo_layout_tree_validate:
    test rdi, rdi
    jz .tree_invalid_pre
    test rsi, rsi
    jz .tree_invalid_pre
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov rbx, rsi
    mov r12, [rdi + NEBO_LAYOUT_TREE_NODES_OFFSET]
    mov r13, [rdi + NEBO_LAYOUT_TREE_NODE_COUNT_OFFSET]
    test r12, r12
    jz .tree_invalid
    test r13, r13
    jz .tree_invalid
    cmp r13, NEBO_LAYOUT_MAX_NODES
    ja .tree_limit
    mov r14, [rdi + NEBO_LAYOUT_TREE_EDGES_OFFSET]
    mov rcx, [rdi + NEBO_LAYOUT_TREE_EDGE_COUNT_OFFSET]
    mov rax, r13
    dec rax
    cmp rcx, rax
    jne .tree_conflict
    test rcx, rcx
    jz .tree_root
    test r14, r14
    jz .tree_invalid
.tree_root:
    mov r15, [rdi + NEBO_LAYOUT_TREE_ROOT_ID_OFFSET]
    test r15, r15
    jz .tree_invalid
    mov rax, [rdi + NEBO_LAYOUT_TREE_DEPTH_OFFSET]
    test rax, rax
    jz .tree_invalid
    cmp rax, NEBO_LAYOUT_MAX_DEPTH
    ja .tree_limit
    cmp [r12 + NEBO_LAYOUT_NODE_ID_OFFSET], r15
    jne .tree_conflict
    xor r8d, r8d
    xor r9d, r9d
.tree_node_loop:
    cmp r8, r13
    jae .tree_edge_setup
    mov r10, r8
    shl r10, 6
    add r10, r12
    cmp qword [r10 + NEBO_LAYOUT_NODE_STATE_OFFSET], NEBO_LAYOUT_NODE_READY
    jne .tree_invalid
    mov r11, [r10 + NEBO_LAYOUT_NODE_ID_OFFSET]
    test r11, r11
    jz .tree_invalid
    cmp r11, r9
    jbe .tree_conflict
    mov r9, r11
    inc r8
    jmp .tree_node_loop
.tree_edge_setup:
    xor r8d, r8d
    mov rax, 0xcbf29ce484222325
.tree_edge_loop:
    mov rcx, r13
    dec rcx
    cmp r8, rcx
    jae .tree_commit
    mov r10, r8
    shl r10, 4
    add r10, r14
    mov r9, [r10 + NEBO_LAYOUT_EDGE_PARENT_OFFSET]
    mov r11, [r10 + NEBO_LAYOUT_EDGE_CHILD_OFFSET]
    test r9, r9
    jz .tree_invalid
    cmp r9, r11
    jae .tree_cycle
    mov rcx, r8
    inc rcx
    shl rcx, 6
    add rcx, r12
    cmp r11, [rcx + NEBO_LAYOUT_NODE_ID_OFFSET]
    jne .tree_conflict
    xor edx, edx
.tree_parent_search:
    cmp rdx, r8
    ja .tree_conflict
    mov rcx, rdx
    shl rcx, 6
    add rcx, r12
    cmp r9, [rcx + NEBO_LAYOUT_NODE_ID_OFFSET]
    je .tree_edge_hash
    inc rdx
    jmp .tree_parent_search
.tree_edge_hash:
    xor rax, r9
    rol rax, 13
    xor rax, r11
    rol rax, 17
    inc r8
    jmp .tree_edge_loop
.tree_commit:
    mov [rbx + NEBO_LAYOUT_TREE_RECEIPT_NODE_COUNT_OFFSET], r13
    mov rcx, r13
    dec rcx
    mov [rbx + NEBO_LAYOUT_TREE_RECEIPT_EDGE_COUNT_OFFSET], rcx
    mov [rbx + NEBO_LAYOUT_TREE_RECEIPT_DIGEST_OFFSET], rax
    mov qword [rbx + NEBO_LAYOUT_TREE_RECEIPT_STATE_OFFSET], NEBO_LAYOUT_TREE_READY
    xor eax, eax
    jmp .tree_done
.tree_cycle:
    mov eax, NEBO_LAYOUT_CYCLE
    jmp .tree_done
.tree_conflict:
    mov eax, NEBO_LAYOUT_CONFLICT
    jmp .tree_done
.tree_limit:
    mov eax, NEBO_LAYOUT_LIMIT
    jmp .tree_done
.tree_invalid:
    mov eax, NEBO_LAYOUT_INVALID
.tree_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.tree_invalid_pre:
    mov eax, NEBO_LAYOUT_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
