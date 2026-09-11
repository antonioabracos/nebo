; G093 source-to-effect probes over the bounded composite-layout owner.
bits 64
default rel
%define NEBO_G093_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/composite_layout_source_probe.inc"
%include "runtime/layout_model.inc"

extern nebo_layout_container_build
extern nebo_layout_cell_place
extern nebo_layout_profile_validate
extern nebo_layout_dashboard_compose
extern nebo_layout_box_validate
extern nebo_layout_responsive_resolve
extern nebo_layout_composite_build
extern nebo_layout_lifecycle_apply
extern nebo_layout_hash
extern nebo_layout_tree_validate

global nebo_g093_source_probe
global nebo_g093_negative_probe

section .data align=16
g93_children: dq 2,3,4

section .bss align=16
g93_request: resb 128
g93_result: resb 128
g93_profile: resb NEBO_PROFILE_SIZE
g93_nodes: resb NEBO_LAYOUT_MAX_NODES * NEBO_LAYOUT_NODE_SIZE
g93_edges: resb (NEBO_LAYOUT_MAX_NODES - 1) * NEBO_LAYOUT_EDGE_SIZE

section .text
; EDI=mode 1..10, ESI=source value -> EAX=owner-published observation.
nebo_g093_source_probe:
    push rbx
    push r12
    sub rsp, 8
    mov r12d, edi
    mov ebx, esi
    test ebx, ebx
    jz .failure
    cmp ebx, 255
    ja .failure
    lea rdi, [rel g93_request]
    mov ecx, 16
    xor eax, eax
    cld
    rep stosq
    lea rdi, [rel g93_result]
    mov ecx, 16
    xor eax, eax
    rep stosq
    cmp r12d, 1
    je .container
    cmp r12d, 2
    je .cell
    cmp r12d, 3
    je .profile_mode
    cmp r12d, 4
    je .dashboard
    cmp r12d, 5
    je .box
    cmp r12d, 6
    je .responsive
    cmp r12d, 7
    je .composite
    cmp r12d, 8
    je .lifecycle
    cmp r12d, 9
    je .hash
    cmp r12d, 10
    je .tree
    jmp .failure

.container:
    mov qword [rel g93_request + NEBO_LAYOUT_NODE_KIND_OFFSET], NEBO_LAYOUT_GRID
    mov [rel g93_request + NEBO_LAYOUT_NODE_ID_OFFSET], rbx
    lea rax, [rel g93_children]
    mov [rel g93_request + NEBO_LAYOUT_NODE_CHILDREN_OFFSET], rax
    mov qword [rel g93_request + NEBO_LAYOUT_NODE_CHILD_COUNT_OFFSET], 2
    mov qword [rel g93_request + NEBO_LAYOUT_NODE_WIDTH_OFFSET], 80
    mov qword [rel g93_request + NEBO_LAYOUT_NODE_HEIGHT_OFFSET], 24
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_container_build
    test eax, eax
    jnz .failure
    cmp qword [rel g93_result + NEBO_LAYOUT_NODE_KIND_OFFSET], NEBO_LAYOUT_GRID
    jne .failure
    mov qword [rel g93_request + NEBO_LAYOUT_NODE_KIND_OFFSET], NEBO_LAYOUT_ROW
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_container_build
    test eax, eax
    jnz .failure
    cmp qword [rel g93_result + NEBO_LAYOUT_NODE_KIND_OFFSET], NEBO_LAYOUT_ROW
    jne .failure
    mov qword [rel g93_request + NEBO_LAYOUT_NODE_KIND_OFFSET], NEBO_LAYOUT_COLUMN
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_container_build
    test eax, eax
    jnz .failure
    cmp qword [rel g93_result + NEBO_LAYOUT_NODE_KIND_OFFSET], NEBO_LAYOUT_COLUMN
    jne .failure
    mov eax, [rel g93_result + NEBO_LAYOUT_NODE_ID_OFFSET]
    jmp .verify

.cell:
    mov [rel g93_request + NEBO_CELL_NODE_ID_OFFSET], rbx
    mov qword [rel g93_request + NEBO_CELL_PARENT_ID_OFFSET], 1
    mov qword [rel g93_request + NEBO_CELL_ROW_OFFSET], 1
    mov qword [rel g93_request + NEBO_CELL_COLUMN_OFFSET], 2
    mov qword [rel g93_request + NEBO_CELL_ROW_SPAN_OFFSET], 2
    mov qword [rel g93_request + NEBO_CELL_COLUMN_SPAN_OFFSET], 1
    mov qword [rel g93_request + NEBO_CELL_GRID_ROWS_OFFSET], 4
    mov qword [rel g93_request + NEBO_CELL_GRID_COLUMNS_OFFSET], 4
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_cell_place
    test eax, eax
    jnz .failure
    mov eax, [rel g93_result + NEBO_CELL_NODE_ID_OFFSET]
    jmp .verify

.profile_mode:
    mov [rel g93_request + NEBO_PROFILE_ID_OFFSET], rbx
    mov qword [rel g93_request + NEBO_PROFILE_LAYOUT_KIND_OFFSET], NEBO_LAYOUT_GRID
    mov qword [rel g93_request + NEBO_PROFILE_VIEW_KIND_OFFSET], NEBO_PROFILE_VIEW_DASHBOARD
    mov qword [rel g93_request + NEBO_PROFILE_MIN_WIDTH_OFFSET], 40
    mov qword [rel g93_request + NEBO_PROFILE_MIN_HEIGHT_OFFSET], 12
    mov qword [rel g93_request + NEBO_PROFILE_MAX_WIDTH_OFFSET], 160
    mov qword [rel g93_request + NEBO_PROFILE_MAX_HEIGHT_OFFSET], 48
    mov qword [rel g93_request + NEBO_PROFILE_TARGET_OFFSET], NEBO_LAYOUT_TARGET_HEADLESS
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_profile_validate
    test eax, eax
    jnz .failure
    mov eax, [rel g93_result + NEBO_PROFILE_ID_OFFSET]
    jmp .verify

.dashboard:
    lea rdi, [rel g93_nodes]
    mov ecx, 16
    xor eax, eax
    rep stosq
    mov qword [rel g93_nodes + NEBO_LAYOUT_NODE_KIND_OFFSET], NEBO_LAYOUT_GRID
    mov [rel g93_nodes + NEBO_LAYOUT_NODE_ID_OFFSET], rbx
    mov qword [rel g93_nodes + NEBO_LAYOUT_NODE_WIDTH_OFFSET], 80
    mov qword [rel g93_nodes + NEBO_LAYOUT_NODE_HEIGHT_OFFSET], 24
    mov qword [rel g93_nodes + NEBO_LAYOUT_NODE_STATE_OFFSET], NEBO_LAYOUT_NODE_READY
    mov qword [rel g93_nodes + NEBO_LAYOUT_NODE_SIZE + NEBO_LAYOUT_NODE_KIND_OFFSET], NEBO_LAYOUT_ROW
    mov rax, rbx
    inc rax
    mov [rel g93_nodes + NEBO_LAYOUT_NODE_SIZE + NEBO_LAYOUT_NODE_ID_OFFSET], rax
    mov qword [rel g93_nodes + NEBO_LAYOUT_NODE_SIZE + NEBO_LAYOUT_NODE_WIDTH_OFFSET], 80
    mov qword [rel g93_nodes + NEBO_LAYOUT_NODE_SIZE + NEBO_LAYOUT_NODE_HEIGHT_OFFSET], 12
    mov qword [rel g93_nodes + NEBO_LAYOUT_NODE_SIZE + NEBO_LAYOUT_NODE_STATE_OFFSET], NEBO_LAYOUT_NODE_READY
    lea rdi, [rel g93_profile]
    mov ecx, NEBO_PROFILE_SIZE / 8
    xor eax, eax
    rep stosq
    mov qword [rel g93_profile + NEBO_PROFILE_VIEW_KIND_OFFSET], NEBO_PROFILE_VIEW_DASHBOARD
    mov qword [rel g93_profile + NEBO_PROFILE_STATE_OFFSET], NEBO_PROFILE_READY
    lea rax, [rel g93_nodes]
    mov [rel g93_request + NEBO_DASHBOARD_NODES_OFFSET], rax
    mov qword [rel g93_request + NEBO_DASHBOARD_COUNT_OFFSET], 2
    mov [rel g93_request + NEBO_DASHBOARD_ROOT_ID_OFFSET], rbx
    lea rax, [rel g93_profile]
    mov [rel g93_request + NEBO_DASHBOARD_PROFILE_OFFSET], rax
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_dashboard_compose
    test eax, eax
    jnz .failure
    mov eax, [rel g93_result + NEBO_DASHBOARD_RECEIPT_ROOT_ID_OFFSET]
    jmp .verify

.box:
    mov [rel g93_request + NEBO_BOX_CONTENT_WIDTH_OFFSET], rbx
    mov qword [rel g93_request + NEBO_BOX_CONTENT_HEIGHT_OFFSET], 20
    mov qword [rel g93_request + NEBO_BOX_MARGIN_TOP_OFFSET], 1
    mov qword [rel g93_request + NEBO_BOX_MARGIN_RIGHT_OFFSET], 1
    mov qword [rel g93_request + NEBO_BOX_MARGIN_BOTTOM_OFFSET], 1
    mov qword [rel g93_request + NEBO_BOX_MARGIN_LEFT_OFFSET], 1
    mov qword [rel g93_request + NEBO_BOX_PADDING_TOP_OFFSET], 1
    mov qword [rel g93_request + NEBO_BOX_PADDING_RIGHT_OFFSET], 1
    mov qword [rel g93_request + NEBO_BOX_PADDING_BOTTOM_OFFSET], 1
    mov qword [rel g93_request + NEBO_BOX_PADDING_LEFT_OFFSET], 1
    mov qword [rel g93_request + NEBO_BOX_ALIGN_HORIZONTAL_OFFSET], NEBO_BOX_ALIGN_CENTER
    mov qword [rel g93_request + NEBO_BOX_ALIGN_VERTICAL_OFFSET], NEBO_BOX_ALIGN_START
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_box_validate
    test eax, eax
    jnz .failure
    cmp [rel g93_request + NEBO_BOX_CONTENT_WIDTH_OFFSET], rbx
    jne .failure
    mov eax, [rel g93_result + NEBO_BOX_CONTENT_WIDTH_OFFSET]
    jmp .verify

.responsive:
    mov qword [rel g93_request + NEBO_RESPONSIVE_AVAILABLE_WIDTH_OFFSET], 255
    mov qword [rel g93_request + NEBO_RESPONSIVE_AVAILABLE_HEIGHT_OFFSET], 255
    mov [rel g93_request + NEBO_RESPONSIVE_PREFERRED_WIDTH_OFFSET], rbx
    mov qword [rel g93_request + NEBO_RESPONSIVE_PREFERRED_HEIGHT_OFFSET], 4
    mov qword [rel g93_request + NEBO_RESPONSIVE_MIN_WIDTH_OFFSET], 1
    mov qword [rel g93_request + NEBO_RESPONSIVE_MIN_HEIGHT_OFFSET], 1
    mov qword [rel g93_request + NEBO_RESPONSIVE_WRAP_OFFSET], NEBO_WRAP_NONE
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_responsive_resolve
    test eax, eax
    jnz .failure
    mov eax, [rel g93_result + NEBO_RESPONSIVE_RESULT_WIDTH_OFFSET]
    jmp .verify

.composite:
    mov qword [rel g93_request + NEBO_COMPOSITE_KIND_OFFSET], NEBO_LAYOUT_TABS
    mov [rel g93_request + NEBO_COMPOSITE_ID_OFFSET], rbx
    lea rax, [rel g93_children]
    mov [rel g93_request + NEBO_COMPOSITE_CHILDREN_OFFSET], rax
    mov qword [rel g93_request + NEBO_COMPOSITE_CHILD_COUNT_OFFSET], 3
    mov qword [rel g93_request + NEBO_COMPOSITE_ACTIVE_OFFSET], 1
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_composite_build
    test eax, eax
    jnz .failure
    cmp qword [rel g93_result + NEBO_COMPOSITE_KIND_OFFSET], NEBO_LAYOUT_TABS
    jne .failure
    mov qword [rel g93_request + NEBO_COMPOSITE_KIND_OFFSET], NEBO_LAYOUT_SPLIT
    mov qword [rel g93_request + NEBO_COMPOSITE_CHILD_COUNT_OFFSET], 2
    mov qword [rel g93_request + NEBO_COMPOSITE_SPLIT_BASIS_OFFSET], 50
    mov qword [rel g93_request + NEBO_COMPOSITE_AXIS_OFFSET], NEBO_COMPOSITE_AXIS_HORIZONTAL
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_composite_build
    test eax, eax
    jnz .failure
    cmp qword [rel g93_result + NEBO_COMPOSITE_KIND_OFFSET], NEBO_LAYOUT_SPLIT
    jne .failure
    mov qword [rel g93_request + NEBO_COMPOSITE_KIND_OFFSET], NEBO_LAYOUT_STACK
    mov qword [rel g93_request + NEBO_COMPOSITE_CHILD_COUNT_OFFSET], 3
    mov qword [rel g93_request + NEBO_COMPOSITE_ACTIVE_OFFSET], 2
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_composite_build
    test eax, eax
    jnz .failure
    cmp qword [rel g93_result + NEBO_COMPOSITE_KIND_OFFSET], NEBO_LAYOUT_STACK
    jne .failure
    mov eax, [rel g93_result + NEBO_COMPOSITE_ID_OFFSET]
    jmp .verify

.lifecycle:
    mov qword [rel g93_request + NEBO_LIFECYCLE_OPERATION_OFFSET], NEBO_LIFECYCLE_REFRESH
    mov qword [rel g93_request + NEBO_LIFECYCLE_PLAN_STATE_OFFSET], NEBO_LIFECYCLE_PLAN_READY
    mov rax, rbx
    dec rax
    mov [rel g93_request + NEBO_LIFECYCLE_CURRENT_GENERATION_OFFSET], rax
    mov [rel g93_request + NEBO_LIFECYCLE_SOURCE_GENERATION_OFFSET], rbx
    mov qword [rel g93_request + NEBO_LIFECYCLE_EFFECTS_OFFSET], NEBO_LIFECYCLE_EFFECT_PRESENT
    mov qword [rel g93_request + NEBO_LIFECYCLE_CAPABILITIES_OFFSET], NEBO_LIFECYCLE_CAP_REFRESH
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_lifecycle_apply
    test eax, eax
    jnz .failure
    mov eax, [rel g93_result + NEBO_LIFECYCLE_RECEIPT_GENERATION_OFFSET]
    jmp .verify

.hash:
    xor r8d, r8d
.hash_fill:
    cmp r8, rbx
    jae .hash_ready
    mov rax, r8
    shl rax, 6
    lea rdi, [rel g93_nodes]
    add rdi, rax
    mov qword [rdi + NEBO_LAYOUT_NODE_KIND_OFFSET], NEBO_LAYOUT_GRID
    mov rax, r8
    inc rax
    mov [rdi + NEBO_LAYOUT_NODE_ID_OFFSET], rax
    mov qword [rdi + NEBO_LAYOUT_NODE_CHILDREN_OFFSET], 0
    mov qword [rdi + NEBO_LAYOUT_NODE_CHILD_COUNT_OFFSET], 0
    mov qword [rdi + NEBO_LAYOUT_NODE_WIDTH_OFFSET], 80
    mov qword [rdi + NEBO_LAYOUT_NODE_HEIGHT_OFFSET], 24
    mov qword [rdi + NEBO_LAYOUT_NODE_FLAGS_OFFSET], 0
    mov qword [rdi + NEBO_LAYOUT_NODE_STATE_OFFSET], NEBO_LAYOUT_NODE_READY
    inc r8
    jmp .hash_fill
.hash_ready:
    lea rax, [rel g93_nodes]
    mov [rel g93_request + NEBO_LAYOUT_HASH_NODES_OFFSET], rax
    mov [rel g93_request + NEBO_LAYOUT_HASH_COUNT_OFFSET], rbx
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_hash
    test eax, eax
    jnz .failure
    mov eax, [rel g93_result + NEBO_LAYOUT_HASH_RECEIPT_COUNT_OFFSET]
    jmp .verify

.tree:
    xor r8d, r8d
.tree_node_fill:
    cmp r8, rbx
    jae .tree_edge_setup
    mov rax, r8
    shl rax, 6
    lea rdi, [rel g93_nodes]
    add rdi, rax
    mov qword [rdi + NEBO_LAYOUT_NODE_KIND_OFFSET], NEBO_LAYOUT_ROW
    mov rax, r8
    inc rax
    mov [rdi + NEBO_LAYOUT_NODE_ID_OFFSET], rax
    mov qword [rdi + NEBO_LAYOUT_NODE_CHILDREN_OFFSET], 0
    mov qword [rdi + NEBO_LAYOUT_NODE_CHILD_COUNT_OFFSET], 0
    mov qword [rdi + NEBO_LAYOUT_NODE_WIDTH_OFFSET], 80
    mov qword [rdi + NEBO_LAYOUT_NODE_HEIGHT_OFFSET], 24
    mov qword [rdi + NEBO_LAYOUT_NODE_FLAGS_OFFSET], 0
    mov qword [rdi + NEBO_LAYOUT_NODE_STATE_OFFSET], NEBO_LAYOUT_NODE_READY
    inc r8
    jmp .tree_node_fill
.tree_edge_setup:
    xor r8d, r8d
    mov r9, rbx
    dec r9
.tree_edge_fill:
    cmp r8, r9
    jae .tree_ready
    mov rax, r8
    shl rax, 4
    lea rdi, [rel g93_edges]
    add rdi, rax
    mov qword [rdi + NEBO_LAYOUT_EDGE_PARENT_OFFSET], 1
    mov rax, r8
    add rax, 2
    mov [rdi + NEBO_LAYOUT_EDGE_CHILD_OFFSET], rax
    inc r8
    jmp .tree_edge_fill
.tree_ready:
    lea rax, [rel g93_nodes]
    mov [rel g93_request + NEBO_LAYOUT_TREE_NODES_OFFSET], rax
    mov [rel g93_request + NEBO_LAYOUT_TREE_NODE_COUNT_OFFSET], rbx
    lea rax, [rel g93_edges]
    mov [rel g93_request + NEBO_LAYOUT_TREE_EDGES_OFFSET], rax
    mov rax, rbx
    dec rax
    mov [rel g93_request + NEBO_LAYOUT_TREE_EDGE_COUNT_OFFSET], rax
    mov qword [rel g93_request + NEBO_LAYOUT_TREE_ROOT_ID_OFFSET], 1
    mov qword [rel g93_request + NEBO_LAYOUT_TREE_DEPTH_OFFSET], 2
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_tree_validate
    test eax, eax
    jnz .failure
    mov eax, [rel g93_result + NEBO_LAYOUT_TREE_RECEIPT_NODE_COUNT_OFFSET]
.verify:
    cmp eax, ebx
    jne .failure
    jmp .done
.failure:
    mov eax, 255
.done:
    add rsp, 8
    pop r12
    pop rbx
    ret

; EDI=case 1..10 -> canonical error, with the destination unchanged.
nebo_g093_negative_probe:
    push rbx
    push r12
    sub rsp, 8
    mov r12d, edi
    lea rdi, [rel g93_request]
    mov ecx, 16
    xor eax, eax
    cld
    rep stosq
    lea rdi, [rel g93_result]
    mov ecx, 16
    mov rax, 0xaaaaaaaaaaaaaaaa
    rep stosq
    cmp r12d, 1
    je .negative_container
    cmp r12d, 2
    je .negative_cell
    cmp r12d, 3
    je .negative_profile
    cmp r12d, 4
    je .negative_dashboard
    cmp r12d, 5
    je .negative_box
    cmp r12d, 6
    je .negative_responsive
    cmp r12d, 7
    je .negative_composite
    cmp r12d, 8
    je .negative_lifecycle
    cmp r12d, 9
    je .negative_hash
    cmp r12d, 10
    je .negative_tree
    jmp .negative_bad

.negative_container:
    mov qword [rel g93_request + NEBO_LAYOUT_NODE_KIND_OFFSET], NEBO_LAYOUT_GRID
    mov qword [rel g93_request + NEBO_LAYOUT_NODE_ID_OFFSET], 1
    mov qword [rel g93_request + NEBO_LAYOUT_NODE_WIDTH_OFFSET], NEBO_LAYOUT_MAX_AREA + 1
    mov qword [rel g93_request + NEBO_LAYOUT_NODE_HEIGHT_OFFSET], 1
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_container_build
    jmp .negative_verify
.negative_cell:
    mov qword [rel g93_request + NEBO_CELL_NODE_ID_OFFSET], 1
    mov qword [rel g93_request + NEBO_CELL_PARENT_ID_OFFSET], 1
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_cell_place
    jmp .negative_verify
.negative_profile:
    mov qword [rel g93_request + NEBO_PROFILE_ID_OFFSET], 1
    mov qword [rel g93_request + NEBO_PROFILE_LAYOUT_KIND_OFFSET], NEBO_LAYOUT_GRID
    mov qword [rel g93_request + NEBO_PROFILE_VIEW_KIND_OFFSET], NEBO_PROFILE_VIEW_DASHBOARD
    mov qword [rel g93_request + NEBO_PROFILE_MIN_WIDTH_OFFSET], 40
    mov qword [rel g93_request + NEBO_PROFILE_MIN_HEIGHT_OFFSET], 12
    mov qword [rel g93_request + NEBO_PROFILE_MAX_WIDTH_OFFSET], 160
    mov qword [rel g93_request + NEBO_PROFILE_MAX_HEIGHT_OFFSET], 48
    mov qword [rel g93_request + NEBO_PROFILE_TARGET_OFFSET], NEBO_LAYOUT_TARGET_LIVE
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_profile_validate
    jmp .negative_verify
.negative_dashboard:
    lea rdi, [rel g93_nodes]
    mov ecx, 16
    xor eax, eax
    rep stosq
    mov qword [rel g93_nodes + NEBO_LAYOUT_NODE_KIND_OFFSET], NEBO_LAYOUT_GRID
    mov qword [rel g93_nodes + NEBO_LAYOUT_NODE_ID_OFFSET], 1
    mov qword [rel g93_nodes + NEBO_LAYOUT_NODE_STATE_OFFSET], NEBO_LAYOUT_NODE_READY
    mov qword [rel g93_nodes + NEBO_LAYOUT_NODE_SIZE + NEBO_LAYOUT_NODE_KIND_OFFSET], NEBO_LAYOUT_ROW
    mov qword [rel g93_nodes + NEBO_LAYOUT_NODE_SIZE + NEBO_LAYOUT_NODE_ID_OFFSET], 1
    mov qword [rel g93_nodes + NEBO_LAYOUT_NODE_SIZE + NEBO_LAYOUT_NODE_STATE_OFFSET], NEBO_LAYOUT_NODE_READY
    lea rdi, [rel g93_profile]
    mov ecx, NEBO_PROFILE_SIZE / 8
    xor eax, eax
    rep stosq
    mov qword [rel g93_profile + NEBO_PROFILE_VIEW_KIND_OFFSET], NEBO_PROFILE_VIEW_DASHBOARD
    mov qword [rel g93_profile + NEBO_PROFILE_STATE_OFFSET], NEBO_PROFILE_READY
    lea rax, [rel g93_nodes]
    mov [rel g93_request + NEBO_DASHBOARD_NODES_OFFSET], rax
    mov qword [rel g93_request + NEBO_DASHBOARD_COUNT_OFFSET], 2
    mov qword [rel g93_request + NEBO_DASHBOARD_ROOT_ID_OFFSET], 1
    lea rax, [rel g93_profile]
    mov [rel g93_request + NEBO_DASHBOARD_PROFILE_OFFSET], rax
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_dashboard_compose
    jmp .negative_verify
.negative_box:
    mov qword [rel g93_request + NEBO_BOX_CONTENT_WIDTH_OFFSET], 80
    mov qword [rel g93_request + NEBO_BOX_CONTENT_HEIGHT_OFFSET], 20
    mov qword [rel g93_request + NEBO_BOX_MARGIN_TOP_OFFSET], -1
    mov qword [rel g93_request + NEBO_BOX_ALIGN_HORIZONTAL_OFFSET], NEBO_BOX_ALIGN_CENTER
    mov qword [rel g93_request + NEBO_BOX_ALIGN_VERTICAL_OFFSET], NEBO_BOX_ALIGN_START
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_box_validate
    jmp .negative_verify
.negative_responsive:
    mov qword [rel g93_request + NEBO_RESPONSIVE_AVAILABLE_WIDTH_OFFSET], 40
    mov qword [rel g93_request + NEBO_RESPONSIVE_AVAILABLE_HEIGHT_OFFSET], 20
    mov qword [rel g93_request + NEBO_RESPONSIVE_PREFERRED_WIDTH_OFFSET], 80
    mov qword [rel g93_request + NEBO_RESPONSIVE_PREFERRED_HEIGHT_OFFSET], 4
    mov qword [rel g93_request + NEBO_RESPONSIVE_MIN_WIDTH_OFFSET], 10
    mov qword [rel g93_request + NEBO_RESPONSIVE_MIN_HEIGHT_OFFSET], 4
    mov qword [rel g93_request + NEBO_RESPONSIVE_WRAP_OFFSET], NEBO_WRAP_NONE
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_responsive_resolve
    jmp .negative_verify
.negative_composite:
    mov qword [rel g93_request + NEBO_COMPOSITE_KIND_OFFSET], NEBO_LAYOUT_SPLIT
    mov qword [rel g93_request + NEBO_COMPOSITE_ID_OFFSET], 8
    lea rax, [rel g93_children]
    mov [rel g93_request + NEBO_COMPOSITE_CHILDREN_OFFSET], rax
    mov qword [rel g93_request + NEBO_COMPOSITE_CHILD_COUNT_OFFSET], 3
    mov qword [rel g93_request + NEBO_COMPOSITE_SPLIT_BASIS_OFFSET], 50
    mov qword [rel g93_request + NEBO_COMPOSITE_AXIS_OFFSET], NEBO_COMPOSITE_AXIS_HORIZONTAL
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_composite_build
    jmp .negative_verify
.negative_lifecycle:
    mov qword [rel g93_request + NEBO_LIFECYCLE_OPERATION_OFFSET], NEBO_LIFECYCLE_REFRESH
    mov qword [rel g93_request + NEBO_LIFECYCLE_PLAN_STATE_OFFSET], NEBO_LIFECYCLE_PLAN_READY
    mov qword [rel g93_request + NEBO_LIFECYCLE_CURRENT_GENERATION_OFFSET], 4
    mov qword [rel g93_request + NEBO_LIFECYCLE_SOURCE_GENERATION_OFFSET], 4
    mov qword [rel g93_request + NEBO_LIFECYCLE_EFFECTS_OFFSET], NEBO_LIFECYCLE_EFFECT_PRESENT
    mov qword [rel g93_request + NEBO_LIFECYCLE_CAPABILITIES_OFFSET], NEBO_LIFECYCLE_CAP_REFRESH
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_lifecycle_apply
    jmp .negative_verify
.negative_hash:
    lea rdi, [rel g93_nodes]
    mov ecx, 16
    xor eax, eax
    rep stosq
    mov qword [rel g93_nodes + NEBO_LAYOUT_NODE_KIND_OFFSET], NEBO_LAYOUT_GRID
    mov qword [rel g93_nodes + NEBO_LAYOUT_NODE_ID_OFFSET], 2
    mov qword [rel g93_nodes + NEBO_LAYOUT_NODE_STATE_OFFSET], NEBO_LAYOUT_NODE_READY
    mov qword [rel g93_nodes + NEBO_LAYOUT_NODE_SIZE + NEBO_LAYOUT_NODE_KIND_OFFSET], NEBO_LAYOUT_ROW
    mov qword [rel g93_nodes + NEBO_LAYOUT_NODE_SIZE + NEBO_LAYOUT_NODE_ID_OFFSET], 1
    mov qword [rel g93_nodes + NEBO_LAYOUT_NODE_SIZE + NEBO_LAYOUT_NODE_STATE_OFFSET], NEBO_LAYOUT_NODE_READY
    lea rax, [rel g93_nodes]
    mov [rel g93_request + NEBO_LAYOUT_HASH_NODES_OFFSET], rax
    mov qword [rel g93_request + NEBO_LAYOUT_HASH_COUNT_OFFSET], 2
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_hash
    jmp .negative_verify
.negative_tree:
    lea rdi, [rel g93_nodes]
    mov ecx, 24
    xor eax, eax
    rep stosq
    xor r8d, r8d
.negative_tree_nodes:
    cmp r8, 3
    jae .negative_tree_edges
    mov rax, r8
    shl rax, 6
    lea rdi, [rel g93_nodes]
    add rdi, rax
    mov qword [rdi + NEBO_LAYOUT_NODE_KIND_OFFSET], NEBO_LAYOUT_ROW
    mov rax, r8
    inc rax
    mov [rdi + NEBO_LAYOUT_NODE_ID_OFFSET], rax
    mov qword [rdi + NEBO_LAYOUT_NODE_STATE_OFFSET], NEBO_LAYOUT_NODE_READY
    inc r8
    jmp .negative_tree_nodes
.negative_tree_edges:
    mov qword [rel g93_edges + 0], 2
    mov qword [rel g93_edges + 8], 1
    mov qword [rel g93_edges + 16], 1
    mov qword [rel g93_edges + 24], 3
    lea rax, [rel g93_nodes]
    mov [rel g93_request + NEBO_LAYOUT_TREE_NODES_OFFSET], rax
    mov qword [rel g93_request + NEBO_LAYOUT_TREE_NODE_COUNT_OFFSET], 3
    lea rax, [rel g93_edges]
    mov [rel g93_request + NEBO_LAYOUT_TREE_EDGES_OFFSET], rax
    mov qword [rel g93_request + NEBO_LAYOUT_TREE_EDGE_COUNT_OFFSET], 2
    mov qword [rel g93_request + NEBO_LAYOUT_TREE_ROOT_ID_OFFSET], 1
    mov qword [rel g93_request + NEBO_LAYOUT_TREE_DEPTH_OFFSET], 2
    lea rdi, [rel g93_request]
    lea rsi, [rel g93_result]
    call nebo_layout_tree_validate

.negative_verify:
    mov ebx, eax
    lea rdi, [rel g93_result]
    mov ecx, 16
    mov rax, 0xaaaaaaaaaaaaaaaa
.negative_scan:
    cmp [rdi], rax
    jne .negative_bad
    add rdi, 8
    dec ecx
    jnz .negative_scan
    mov eax, ebx
    jmp .negative_done
.negative_bad:
    mov eax, 255
.negative_done:
    add rsp, 8
    pop r12
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
