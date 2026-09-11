; G098 target-neutral Graph/Tree/embedding/projection semantic owner.
bits 64
default rel
%define NEBO_G098_GRAPH_VIEW_IMPLEMENTATION 1
%include "runtime/console/graph_view.inc"

section .text
global nebo_g098_graph_view_model

; graph_view_model(request*, result*) -> stable status.
; Borrowed inputs are fully validated before a pointer-free receipt is published.
nebo_g098_graph_view_model:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,160
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    jz .invalid
    test r13,r13
    jz .invalid
    test r12,7
    jnz .invalid
    test r13,7
    jnz .invalid
    lea rdi,[rbp-200]
    mov ecx,NEBO_G098_RESULT_SIZE/8
    xor eax,eax
    cld
    rep stosq

    mov ebx,[r12+NEBO_G098_REQUEST_KIND_OFFSET]
    cmp ebx,NEBO_G098_KIND_GRAPH
    jb .kind
    cmp ebx,NEBO_G098_KIND_DEPENDENCY
    ja .kind
    mov eax,[r12+NEBO_G098_REQUEST_TARGET_OFFSET]
    cmp eax,NEBO_G098_TARGET_HEADLESS
    jb .target
    cmp eax,NEBO_G098_TARGET_LIVE
    ja .target
    mov r14,[r12+NEBO_G098_REQUEST_NODES_OFFSET]
    test r14,r14
    jz .bounds
    cmp r14,NEBO_G098_MAX_NODES
    ja .bounds
    mov rax,[r12+NEBO_G098_REQUEST_EDGES_OFFSET]
    cmp rax,NEBO_G098_MAX_EDGES
    ja .bounds
    mov rax,[r12+NEBO_G098_REQUEST_SEED_OFFSET]
    test rax,rax
    jz .layout
    mov rax,[r12+NEBO_G098_REQUEST_PROVENANCE_OFFSET]
    test rax,rax
    jz .provenance
    mov rax,[r12+NEBO_G098_REQUEST_OWNER_GENERATION_OFFSET]
    test rax,rax
    jz .lifetime
    cmp rax,[r12+NEBO_G098_REQUEST_VIEW_GENERATION_OFFSET]
    jne .lifetime
    mov rax,[r12+NEBO_G098_REQUEST_NODE_BUDGET_OFFSET]
    test rax,rax
    jz .budget
    cmp rax,NEBO_G098_MAX_NODE_BUDGET
    ja .budget
    mov rdx,r14
    cmp rax,rdx
    cmovb rdx,rax
    mov [rbp-200+NEBO_G098_RESULT_VISIBLE_NODES_OFFSET],rdx

    mov r11,[r12+NEBO_G098_REQUEST_OPTIONS_OFFSET]
    mov rax,r11
    and rax,~NEBO_G098_OPTION_KNOWN
    jnz .options
    cmp ebx,NEBO_G098_KIND_EMBEDDING
    je .embedding_contract

    test r11,NEBO_G098_OPTION_GRAPH
    jz .options
    mov rax,r11
    and rax,~(NEBO_G098_OPTION_GRAPH | NEBO_G098_OPTION_HIGHLIGHT | NEBO_G098_OPTION_HIGHLIGHT_PATH)
    jnz .options
    mov rax,r11
    and rax,NEBO_G098_OPTION_HIGHLIGHT_PATH
    jz .graph_highlight_pair_ready
    test r11,NEBO_G098_OPTION_HIGHLIGHT
    jz .options
.graph_highlight_pair_ready:
    cmp qword [r12+NEBO_G098_REQUEST_INPUT_DIMENSIONS_OFFSET],0
    jne .projection
    cmp qword [r12+NEBO_G098_REQUEST_OUTPUT_DIMENSIONS_OFFSET],0
    jne .projection
    cmp qword [r12+NEBO_G098_REQUEST_PROJECTION_ALGORITHM_OFFSET],0
    jne .projection
    cmp qword [r12+NEBO_G098_REQUEST_PROJECTION_REPORT_OFFSET],0
    jne .report
    cmp qword [r12+NEBO_G098_REQUEST_EMBEDDING_PTR_OFFSET],0
    jne .projection
    mov rax,[r12+NEBO_G098_REQUEST_LAYOUT_OFFSET]
    cmp rax,NEBO_G098_LAYOUT_GRID
    jb .layout
    cmp rax,NEBO_G098_LAYOUT_LAYERED
    ja .layout
    mov rax,[r12+NEBO_G098_REQUEST_EDGES_OFFSET]
    test rax,rax
    jz .no_edge_storage
    mov r8,[r12+NEBO_G098_REQUEST_EDGES_PTR_OFFSET]
    test r8,r8
    jz .graph
    test r8,7
    jnz .graph
    jmp .edge_contract_ready
.no_edge_storage:
    cmp qword [r12+NEBO_G098_REQUEST_EDGES_PTR_OFFSET],0
    jne .graph
.edge_contract_ready:
    cmp ebx,NEBO_G098_KIND_TREE
    jne .edge_scan
    lea rdx,[r14-1]
    cmp [r12+NEBO_G098_REQUEST_EDGES_OFFSET],rdx
    jne .tree
    cmp qword [r12+NEBO_G098_REQUEST_LAYOUT_OFFSET],NEBO_G098_LAYOUT_LAYERED
    jne .layout
    jmp .edge_scan

.embedding_contract:
    mov rax,r11
    and rax,NEBO_G098_OPTION_EMBEDDING | NEBO_G098_OPTION_DIMENSIONS
    cmp rax,NEBO_G098_OPTION_EMBEDDING | NEBO_G098_OPTION_DIMENSIONS
    jne .options
    mov rax,r11
    and rax,~(NEBO_G098_OPTION_EMBEDDING | NEBO_G098_OPTION_PROJECTION | NEBO_G098_OPTION_PROJECT | NEBO_G098_OPTION_DIMENSIONS)
    jnz .options
    cmp qword [r12+NEBO_G098_REQUEST_EDGES_OFFSET],0
    jne .graph
    cmp qword [r12+NEBO_G098_REQUEST_EDGES_PTR_OFFSET],0
    jne .graph
    cmp qword [r12+NEBO_G098_REQUEST_LAYOUT_OFFSET],0
    jne .layout
    cmp qword [r12+NEBO_G098_REQUEST_PATH_COUNT_OFFSET],0
    jne .path
    cmp qword [r12+NEBO_G098_REQUEST_PATH_PTR_OFFSET],0
    jne .path
    cmp qword [r12+NEBO_G098_REQUEST_HIGHLIGHT_NODE_OFFSET],0
    jne .path
    mov rbx,[r12+NEBO_G098_REQUEST_INPUT_DIMENSIONS_OFFSET]
    test rbx,rbx
    jz .projection
    cmp rbx,NEBO_G098_MAX_DIMENSIONS
    ja .projection
    mov r8,[r12+NEBO_G098_REQUEST_EMBEDDING_PTR_OFFSET]
    test r8,r8
    jz .projection
    test r8,7
    jnz .projection
    mov rax,r14
    mul rbx
    test rdx,rdx
    jnz .bounds
    test rax,rax
    jz .bounds
    cmp rax,NEBO_G098_MAX_EMBEDDING_VALUES
    ja .bounds
    mov r10,rax
    mov rax,r11
    and rax,NEBO_G098_OPTION_PROJECTION | NEBO_G098_OPTION_PROJECT
    test rax,rax
    jz .embedding_without_projection
    cmp rax,NEBO_G098_OPTION_PROJECTION | NEBO_G098_OPTION_PROJECT
    jne .options
    mov rax,[r12+NEBO_G098_REQUEST_OUTPUT_DIMENSIONS_OFFSET]
    cmp rax,2
    jb .projection
    cmp rax,3
    ja .projection
    cmp rax,rbx
    ja .projection
    mov rax,[r12+NEBO_G098_REQUEST_PROJECTION_ALGORITHM_OFFSET]
    cmp rax,NEBO_G098_PROJECTION_LEADING_AXES
    jb .projection
    cmp rax,NEBO_G098_PROJECTION_SEEDED_SIGNED_AXES
    ja .projection
    cmp qword [r12+NEBO_G098_REQUEST_PROJECTION_REPORT_OFFSET],1
    jne .report
    jmp .embedding_scan
.embedding_without_projection:
    cmp qword [r12+NEBO_G098_REQUEST_OUTPUT_DIMENSIONS_OFFSET],0
    jne .projection
    cmp qword [r12+NEBO_G098_REQUEST_PROJECTION_ALGORITHM_OFFSET],0
    jne .projection
    cmp qword [r12+NEBO_G098_REQUEST_PROJECTION_REPORT_OFFSET],0
    jne .report
    jmp .embedding_scan

.edge_scan:
    mov r15,0x4752415048454447
    xor ecx,ecx
    mov r8,[r12+NEBO_G098_REQUEST_EDGES_PTR_OFFSET]
.edge_loop:
    cmp rcx,[r12+NEBO_G098_REQUEST_EDGES_OFFSET]
    jae .edge_scan_done
    mov rax,rcx
    shl rax,4
    mov rdx,[r8+rax]
    mov r9,[r8+rax+8]
    cmp rdx,r14
    jae .graph
    cmp r9,r14
    jae .graph
    cmp rdx,r9
    je .graph
    cmp ebx,NEBO_G098_KIND_TREE
    je .ordered_edge
    cmp ebx,NEBO_G098_KIND_DEPENDENCY
    jne .edge_mix
.ordered_edge:
    cmp rdx,r9
    jae .graph
.edge_mix:
    xor r15,rdx
    rol r15,11
    xor r15,r9
    rol r15,17
    inc rcx
    jmp .edge_loop
.edge_scan_done:
    mov [rbp-200+NEBO_G098_RESULT_DIGEST_OFFSET],r15
    cmp ebx,NEBO_G098_KIND_TREE
    jne .path_contract
    mov r9,1
.tree_node_loop:
    cmp r9,r14
    jae .path_contract
    xor r10d,r10d
    xor ecx,ecx
.tree_parent_loop:
    cmp rcx,[r12+NEBO_G098_REQUEST_EDGES_OFFSET]
    jae .tree_parent_ready
    mov rax,rcx
    shl rax,4
    cmp [r8+rax+8],r9
    jne .tree_parent_next
    inc r10
.tree_parent_next:
    inc rcx
    jmp .tree_parent_loop
.tree_parent_ready:
    cmp r10,1
    jne .tree
    inc r9
    jmp .tree_node_loop

.path_contract:
    mov r11,[r12+NEBO_G098_REQUEST_OPTIONS_OFFSET]
    test r11,NEBO_G098_OPTION_HIGHLIGHT
    jz .no_highlight
    mov rax,[r12+NEBO_G098_REQUEST_HIGHLIGHT_NODE_OFFSET]
    cmp rax,r14
    jae .path
    jmp .highlight_ready
.no_highlight:
    cmp qword [r12+NEBO_G098_REQUEST_HIGHLIGHT_NODE_OFFSET],0
    jne .path
.highlight_ready:
    test r11,NEBO_G098_OPTION_HIGHLIGHT_PATH
    jz .no_path
    mov r10,[r12+NEBO_G098_REQUEST_PATH_COUNT_OFFSET]
    cmp r10,2
    jb .path
    cmp r10,NEBO_G098_MAX_PATH
    ja .path
    cmp r10,r14
    ja .path
    mov r9,[r12+NEBO_G098_REQUEST_PATH_PTR_OFFSET]
    test r9,r9
    jz .path
    test r9,7
    jnz .path
    mov r15,0x5041544844494745
    xor ecx,ecx
.path_node_loop:
    cmp rcx,r10
    jae .path_ready
    mov rdx,[r9+rcx*8]
    cmp rdx,r14
    jae .path
    xor r15,rdx
    rol r15,13
    test rcx,rcx
    jz .path_node_next
    mov rdx,[r9+rcx*8-8]
    mov rax,[r9+rcx*8]
    xor edi,edi
    xor esi,esi
.path_edge_loop:
    cmp rsi,[r12+NEBO_G098_REQUEST_EDGES_OFFSET]
    jae .path_edge_ready
    mov r11,rsi
    shl r11,4
    cmp [r8+r11],rdx
    jne .path_edge_next
    cmp [r8+r11+8],rax
    jne .path_edge_next
    mov edi,1
    jmp .path_edge_ready
.path_edge_next:
    inc rsi
    jmp .path_edge_loop
.path_edge_ready:
    test edi,edi
    jz .path
.path_node_next:
    inc rcx
    jmp .path_node_loop
.path_ready:
    mov [rbp-200+NEBO_G098_RESULT_PATH_DIGEST_OFFSET],r15
    jmp .layout_digest
.no_path:
    cmp qword [r12+NEBO_G098_REQUEST_PATH_COUNT_OFFSET],0
    jne .path
    cmp qword [r12+NEBO_G098_REQUEST_PATH_PTR_OFFSET],0
    jne .path

.layout_digest:
    mov r15,0x4c41594f55544738
    xor r15,[r12+NEBO_G098_REQUEST_SEED_OFFSET]
    rol r15,7
    xor r15,[r12+NEBO_G098_REQUEST_PROVENANCE_OFFSET]
    rol r15,11
    xor ecx,ecx
.layout_loop:
    cmp rcx,[rbp-200+NEBO_G098_RESULT_VISIBLE_NODES_OFFSET]
    jae .layout_done
    mov rax,rcx
    imul rax,[r12+NEBO_G098_REQUEST_SEED_OFFSET]
    mov rdx,[r12+NEBO_G098_REQUEST_LAYOUT_OFFSET]
    imul rdx,17
    add rax,rdx
    xor r15,rax
    rol r15,19
    mov rax,rcx
    imul rax,rcx
    add rax,[r12+NEBO_G098_REQUEST_SEED_OFFSET]
    xor r15,rax
    rol r15,23
    inc rcx
    jmp .layout_loop
.layout_done:
    mov [rbp-200+NEBO_G098_RESULT_LAYOUT_DIGEST_OFFSET],r15
    jmp .publish

.embedding_scan:
    mov r15,0x454d42454444494e
    xor ecx,ecx
.embedding_value_loop:
    cmp rcx,r10
    jae .embedding_values_ready
    mov rdx,[r8+rcx*8]
    mov rax,rdx
    shr rax,52
    and eax,0x7ff
    cmp eax,0x7ff
    je .nonfinite
    xor r15,rdx
    rol r15,13
    inc rcx
    jmp .embedding_value_loop
.embedding_values_ready:
    mov [rbp-200+NEBO_G098_RESULT_PROJECTION_DIGEST_OFFSET],r15
    mov rax,[r12+NEBO_G098_REQUEST_OPTIONS_OFFSET]
    test rax,NEBO_G098_OPTION_PROJECTION
    jz .publish
    mov r15,0x50524f4a45435438
    xor r9d,r9d
.projection_node_loop:
    cmp r9,r14
    jae .projection_done
    xor r10d,r10d
.projection_dimension_loop:
    cmp r10,[r12+NEBO_G098_REQUEST_OUTPUT_DIMENSIONS_OFFSET]
    jae .projection_node_next
    cmp qword [r12+NEBO_G098_REQUEST_PROJECTION_ALGORITHM_OFFSET],NEBO_G098_PROJECTION_LEADING_AXES
    jne .projection_seeded
    mov rax,r10
    jmp .projection_index_ready
.projection_seeded:
    mov rax,[r12+NEBO_G098_REQUEST_SEED_OFFSET]
    add rax,r9
    add rax,r10
    xor edx,edx
    div rbx
    mov rax,rdx
.projection_index_ready:
    mov rdx,r9
    imul rdx,rbx
    add rdx,rax
    mov rdx,[r8+rdx*8]
    cmp qword [r12+NEBO_G098_REQUEST_PROJECTION_ALGORITHM_OFFSET],NEBO_G098_PROJECTION_SEEDED_SIGNED_AXES
    jne .projection_mix
    mov rax,[r12+NEBO_G098_REQUEST_SEED_OFFSET]
    add rax,r9
    add rax,r10
    test al,1
    jz .projection_mix
    mov rax,0x8000000000000000
    xor rdx,rax
.projection_mix:
    xor r15,rdx
    rol r15,17
    inc r10
    jmp .projection_dimension_loop
.projection_node_next:
    inc r9
    jmp .projection_node_loop
.projection_done:
    xor r15,[rbp-200+NEBO_G098_RESULT_PROJECTION_DIGEST_OFFSET]
    rol r15,29
    mov [rbp-200+NEBO_G098_RESULT_PROJECTION_DIGEST_OFFSET],r15

.publish:
    mov ebx,[r12+NEBO_G098_REQUEST_KIND_OFFSET]
    mov dword [rbp-200+NEBO_G098_RESULT_KIND_OFFSET],ebx
    mov eax,[r12+NEBO_G098_REQUEST_TARGET_OFFSET]
    mov dword [rbp-200+NEBO_G098_RESULT_TARGET_OFFSET],eax
    mov rax,[r12+NEBO_G098_REQUEST_NODES_OFFSET]
    mov [rbp-200+NEBO_G098_RESULT_NODES_OFFSET],rax
    mov rax,[r12+NEBO_G098_REQUEST_EDGES_OFFSET]
    mov [rbp-200+NEBO_G098_RESULT_EDGES_OFFSET],rax
    mov rax,[r12+NEBO_G098_REQUEST_LAYOUT_OFFSET]
    mov [rbp-200+NEBO_G098_RESULT_LAYOUT_OFFSET],rax
    mov rax,[r12+NEBO_G098_REQUEST_SEED_OFFSET]
    mov [rbp-200+NEBO_G098_RESULT_SEED_OFFSET],rax
    mov rax,[r12+NEBO_G098_REQUEST_OPTIONS_OFFSET]
    mov [rbp-200+NEBO_G098_RESULT_OPTIONS_OFFSET],rax
    mov rax,[r12+NEBO_G098_REQUEST_PATH_COUNT_OFFSET]
    mov [rbp-200+NEBO_G098_RESULT_PATH_COUNT_OFFSET],rax
    mov rax,[r12+NEBO_G098_REQUEST_INPUT_DIMENSIONS_OFFSET]
    mov [rbp-200+NEBO_G098_RESULT_INPUT_DIMENSIONS_OFFSET],rax
    mov rax,[r12+NEBO_G098_REQUEST_OUTPUT_DIMENSIONS_OFFSET]
    mov [rbp-200+NEBO_G098_RESULT_OUTPUT_DIMENSIONS_OFFSET],rax
    mov rax,[r12+NEBO_G098_REQUEST_PROJECTION_ALGORITHM_OFFSET]
    mov [rbp-200+NEBO_G098_RESULT_PROJECTION_ALGORITHM_OFFSET],rax
    mov rax,[r12+NEBO_G098_REQUEST_PROJECTION_REPORT_OFFSET]
    mov [rbp-200+NEBO_G098_RESULT_PROJECTION_REPORT_OFFSET],rax
    mov rax,[r12+NEBO_G098_REQUEST_PROVENANCE_OFFSET]
    mov [rbp-200+NEBO_G098_RESULT_PROVENANCE_OFFSET],rax
    mov rax,[r12+NEBO_G098_REQUEST_OWNER_GENERATION_OFFSET]
    mov [rbp-200+NEBO_G098_RESULT_OWNER_GENERATION_OFFSET],rax
    mov rax,[r12+NEBO_G098_REQUEST_VIEW_GENERATION_OFFSET]
    mov [rbp-200+NEBO_G098_RESULT_VIEW_GENERATION_OFFSET],rax

    mov r15,0xcbf29ce484222325
    mov eax,ebx
    xor r15,rax
    rol r15,7
    xor r15,[r12+NEBO_G098_REQUEST_NODES_OFFSET]
    rol r15,11
    xor r15,[r12+NEBO_G098_REQUEST_EDGES_OFFSET]
    rol r15,13
    xor r15,[r12+NEBO_G098_REQUEST_LAYOUT_OFFSET]
    rol r15,17
    xor r15,[r12+NEBO_G098_REQUEST_SEED_OFFSET]
    rol r15,19
    xor r15,[r12+NEBO_G098_REQUEST_OPTIONS_OFFSET]
    rol r15,23
    xor r15,[rbp-200+NEBO_G098_RESULT_VISIBLE_NODES_OFFSET]
    rol r15,29
    xor r15,[r12+NEBO_G098_REQUEST_PATH_COUNT_OFFSET]
    rol r15,31
    xor r15,[r12+NEBO_G098_REQUEST_INPUT_DIMENSIONS_OFFSET]
    rol r15,5
    xor r15,[r12+NEBO_G098_REQUEST_OUTPUT_DIMENSIONS_OFFSET]
    rol r15,9
    xor r15,[r12+NEBO_G098_REQUEST_PROJECTION_ALGORITHM_OFFSET]
    rol r15,15
    xor r15,[r12+NEBO_G098_REQUEST_PROJECTION_REPORT_OFFSET]
    rol r15,21
    xor r15,[rbp-200+NEBO_G098_RESULT_DIGEST_OFFSET]
    rol r15,27
    xor r15,[rbp-200+NEBO_G098_RESULT_LAYOUT_DIGEST_OFFSET]
    rol r15,33
    xor r15,[rbp-200+NEBO_G098_RESULT_PATH_DIGEST_OFFSET]
    rol r15,37
    xor r15,[rbp-200+NEBO_G098_RESULT_PROJECTION_DIGEST_OFFSET]
    rol r15,41
    xor r15,[r12+NEBO_G098_REQUEST_PROVENANCE_OFFSET]
    rol r15,43
    xor r15,[r12+NEBO_G098_REQUEST_OWNER_GENERATION_OFFSET]
    mov [rbp-200+NEBO_G098_RESULT_DIGEST_OFFSET],r15
    lea rsi,[rbp-200]
    mov rdi,r13
    mov ecx,NEBO_G098_RESULT_SIZE/8
    cld
    rep movsq
    xor eax,eax
    jmp .done

.invalid:
    mov eax,NEBO_G098_ERROR_INVALID
    jmp .done
.bounds:
    mov eax,NEBO_G098_ERROR_BOUNDS
    jmp .done
.kind:
    mov eax,NEBO_G098_ERROR_KIND
    jmp .done
.graph:
    mov eax,NEBO_G098_ERROR_GRAPH
    jmp .done
.tree:
    mov eax,NEBO_G098_ERROR_TREE
    jmp .done
.layout:
    mov eax,NEBO_G098_ERROR_LAYOUT
    jmp .done
.path:
    mov eax,NEBO_G098_ERROR_PATH
    jmp .done
.nonfinite:
    mov eax,NEBO_G098_ERROR_NONFINITE
    jmp .done
.projection:
    mov eax,NEBO_G098_ERROR_PROJECTION
    jmp .done
.lifetime:
    mov eax,NEBO_G098_ERROR_LIFETIME
    jmp .done
.options:
    mov eax,NEBO_G098_ERROR_OPTIONS
    jmp .done
.target:
    mov eax,NEBO_G098_ERROR_TARGET
    jmp .done
.provenance:
    mov eax,NEBO_G098_ERROR_PROVENANCE
    jmp .done
.budget:
    mov eax,NEBO_G098_ERROR_BUDGET
    jmp .done
.report:
    mov eax,NEBO_G098_ERROR_REPORT
.done:
    add rsp,160
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
