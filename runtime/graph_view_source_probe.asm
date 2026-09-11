; G098 source-to-effect probe over the bounded graph-view semantic model.
bits 64
default rel
%define NEBO_G098_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/graph_view_source_probe.inc"
%include "runtime/console/graph_view.inc"

%define G098_PROBE_EDGE_CAPACITY 256
%define G098_PROBE_PATH_CAPACITY 16
%define G098_PROBE_EMBEDDING_CAPACITY 256

global nebo_g098_source_probe
global nebo_g098_negative_probe

section .bss align=16
g98_request: resb NEBO_G098_REQUEST_SIZE
g98_headless: resb NEBO_G098_RESULT_SIZE
g98_live: resb NEBO_G098_RESULT_SIZE
g98_edges: resq G098_PROBE_EDGE_CAPACITY*2
g98_path: resq G098_PROBE_PATH_CAPACITY
g98_embedding: resq G098_PROBE_EMBEDDING_CAPACITY

section .text
g98_clear:
    lea rdi,[rel g98_request]
    mov ecx,NEBO_G098_REQUEST_SIZE/8
    xor eax,eax
    cld
    rep stosq
    lea rdi,[rel g98_headless]
    mov ecx,NEBO_G098_RESULT_SIZE/8
    rep stosq
    lea rdi,[rel g98_live]
    mov ecx,NEBO_G098_RESULT_SIZE/8
    rep stosq
    ret

; EDI=subgroup 1..9, ESI=source generation 1..255 -> EAX=generation.
nebo_g098_source_probe:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12d,edi
    mov r13d,esi
    cmp r12d,1
    jb .failure
    cmp r12d,9
    ja .failure
    test r13d,r13d
    jz .failure
    cmp r13d,255
    ja .failure
    call g98_clear
    mov [rel g98_request+NEBO_G098_REQUEST_SEED_OFFSET],r13
    mov rax,r13
    add rax,100
    mov [rel g98_request+NEBO_G098_REQUEST_PROVENANCE_OFFSET],rax
    mov [rel g98_request+NEBO_G098_REQUEST_OWNER_GENERATION_OFFSET],r13
    mov [rel g98_request+NEBO_G098_REQUEST_VIEW_GENERATION_OFFSET],r13
    cmp r12d,1
    je .graph_renderer
    cmp r12d,2
    je .tree_renderer
    cmp r12d,3
    je .layout_view
    cmp r12d,4
    je .highlight_view
    cmp r12d,5
    je .embedding_view
    cmp r12d,6
    je .projection_view
    cmp r12d,7
    je .dependency_view
    cmp r12d,8
    je .bounded_view
    jmp .closeout_view

.graph_renderer:
    mov dword [rel g98_request+NEBO_G098_REQUEST_KIND_OFFSET],NEBO_G098_KIND_GRAPH
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODES_OFFSET],5
    mov qword [rel g98_request+NEBO_G098_REQUEST_EDGES_OFFSET],5
    mov qword [rel g98_request+NEBO_G098_REQUEST_LAYOUT_OFFSET],NEBO_G098_LAYOUT_GRID
    mov qword [rel g98_request+NEBO_G098_REQUEST_OPTIONS_OFFSET],NEBO_G098_OPTION_GRAPH
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODE_BUDGET_OFFSET],5
    jmp .graph_cycle
.tree_renderer:
    mov dword [rel g98_request+NEBO_G098_REQUEST_KIND_OFFSET],NEBO_G098_KIND_TREE
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODES_OFFSET],6
    mov qword [rel g98_request+NEBO_G098_REQUEST_EDGES_OFFSET],5
    mov qword [rel g98_request+NEBO_G098_REQUEST_LAYOUT_OFFSET],NEBO_G098_LAYOUT_LAYERED
    mov qword [rel g98_request+NEBO_G098_REQUEST_OPTIONS_OFFSET],NEBO_G098_OPTION_GRAPH
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODE_BUDGET_OFFSET],6
    jmp .graph_chain
.layout_view:
    mov dword [rel g98_request+NEBO_G098_REQUEST_KIND_OFFSET],NEBO_G098_KIND_GRAPH
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODES_OFFSET],7
    mov qword [rel g98_request+NEBO_G098_REQUEST_EDGES_OFFSET],7
    mov eax,r13d
    xor edx,edx
    mov ecx,4
    div ecx
    inc edx
    mov [rel g98_request+NEBO_G098_REQUEST_LAYOUT_OFFSET],rdx
    mov qword [rel g98_request+NEBO_G098_REQUEST_OPTIONS_OFFSET],NEBO_G098_OPTION_GRAPH
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODE_BUDGET_OFFSET],7
    jmp .graph_cycle
.highlight_view:
    mov dword [rel g98_request+NEBO_G098_REQUEST_KIND_OFFSET],NEBO_G098_KIND_GRAPH
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODES_OFFSET],6
    mov qword [rel g98_request+NEBO_G098_REQUEST_EDGES_OFFSET],5
    mov qword [rel g98_request+NEBO_G098_REQUEST_LAYOUT_OFFSET],NEBO_G098_LAYOUT_RADIAL
    mov qword [rel g98_request+NEBO_G098_REQUEST_OPTIONS_OFFSET],NEBO_G098_OPTION_GRAPH | NEBO_G098_OPTION_HIGHLIGHT | NEBO_G098_OPTION_HIGHLIGHT_PATH
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODE_BUDGET_OFFSET],6
    mov qword [rel g98_request+NEBO_G098_REQUEST_HIGHLIGHT_NODE_OFFSET],2
    jmp .graph_with_path
.embedding_view:
    mov dword [rel g98_request+NEBO_G098_REQUEST_KIND_OFFSET],NEBO_G098_KIND_EMBEDDING
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODES_OFFSET],4
    mov qword [rel g98_request+NEBO_G098_REQUEST_INPUT_DIMENSIONS_OFFSET],4
    mov qword [rel g98_request+NEBO_G098_REQUEST_OPTIONS_OFFSET],NEBO_G098_OPTION_EMBEDDING | NEBO_G098_OPTION_DIMENSIONS
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODE_BUDGET_OFFSET],4
    jmp .embedding_fill
.projection_view:
    mov dword [rel g98_request+NEBO_G098_REQUEST_KIND_OFFSET],NEBO_G098_KIND_EMBEDDING
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODES_OFFSET],5
    mov qword [rel g98_request+NEBO_G098_REQUEST_INPUT_DIMENSIONS_OFFSET],5
    mov eax,r13d
    xor edx,edx
    mov ecx,2
    div ecx
    add edx,2
    mov [rel g98_request+NEBO_G098_REQUEST_OUTPUT_DIMENSIONS_OFFSET],rdx
    mov eax,r13d
    xor edx,edx
    mov ecx,2
    div ecx
    inc edx
    mov [rel g98_request+NEBO_G098_REQUEST_PROJECTION_ALGORITHM_OFFSET],rdx
    mov qword [rel g98_request+NEBO_G098_REQUEST_PROJECTION_REPORT_OFFSET],1
    mov qword [rel g98_request+NEBO_G098_REQUEST_OPTIONS_OFFSET],NEBO_G098_OPTION_EMBEDDING | NEBO_G098_OPTION_PROJECTION | NEBO_G098_OPTION_PROJECT | NEBO_G098_OPTION_DIMENSIONS
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODE_BUDGET_OFFSET],5
    jmp .embedding_fill
.dependency_view:
    mov dword [rel g98_request+NEBO_G098_REQUEST_KIND_OFFSET],NEBO_G098_KIND_DEPENDENCY
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODES_OFFSET],6
    mov qword [rel g98_request+NEBO_G098_REQUEST_EDGES_OFFSET],5
    mov qword [rel g98_request+NEBO_G098_REQUEST_LAYOUT_OFFSET],NEBO_G098_LAYOUT_LAYERED
    mov qword [rel g98_request+NEBO_G098_REQUEST_OPTIONS_OFFSET],NEBO_G098_OPTION_GRAPH
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODE_BUDGET_OFFSET],6
    jmp .graph_chain
.bounded_view:
    mov dword [rel g98_request+NEBO_G098_REQUEST_KIND_OFFSET],NEBO_G098_KIND_GRAPH
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODES_OFFSET],128
    mov qword [rel g98_request+NEBO_G098_REQUEST_EDGES_OFFSET],127
    mov qword [rel g98_request+NEBO_G098_REQUEST_LAYOUT_OFFSET],NEBO_G098_LAYOUT_FORCE
    mov qword [rel g98_request+NEBO_G098_REQUEST_OPTIONS_OFFSET],NEBO_G098_OPTION_GRAPH
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODE_BUDGET_OFFSET],16
    jmp .graph_chain
.closeout_view:
    mov dword [rel g98_request+NEBO_G098_REQUEST_KIND_OFFSET],NEBO_G098_KIND_DEPENDENCY
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODES_OFFSET],8
    mov qword [rel g98_request+NEBO_G098_REQUEST_EDGES_OFFSET],7
    mov qword [rel g98_request+NEBO_G098_REQUEST_LAYOUT_OFFSET],NEBO_G098_LAYOUT_LAYERED
    mov qword [rel g98_request+NEBO_G098_REQUEST_OPTIONS_OFFSET],NEBO_G098_OPTION_GRAPH | NEBO_G098_OPTION_HIGHLIGHT | NEBO_G098_OPTION_HIGHLIGHT_PATH
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODE_BUDGET_OFFSET],5
    mov qword [rel g98_request+NEBO_G098_REQUEST_HIGHLIGHT_NODE_OFFSET],3

.graph_with_path:
    lea rax,[rel g98_path]
    mov [rel g98_request+NEBO_G098_REQUEST_PATH_PTR_OFFSET],rax
    mov qword [rel g98_request+NEBO_G098_REQUEST_PATH_COUNT_OFFSET],4
    mov qword [rel g98_path],1
    mov qword [rel g98_path+8],2
    mov qword [rel g98_path+16],3
    mov qword [rel g98_path+24],4
.graph_chain:
    lea rdi,[rel g98_edges]
    xor ecx,ecx
    mov r10,[rel g98_request+NEBO_G098_REQUEST_EDGES_OFFSET]
.chain_loop:
    cmp rcx,r10
    jae .graph_ready
    mov [rdi+rcx*8],rcx
    mov rax,rcx
    inc rax
    mov [rdi+rcx*8+8],rax
    add rdi,8
    inc rcx
    jmp .chain_loop
.graph_cycle:
    lea rdi,[rel g98_edges]
    xor ecx,ecx
    mov r10,[rel g98_request+NEBO_G098_REQUEST_EDGES_OFFSET]
    mov r11,[rel g98_request+NEBO_G098_REQUEST_NODES_OFFSET]
.cycle_loop:
    cmp rcx,r10
    jae .graph_ready
    mov [rdi+rcx*8],rcx
    mov rax,rcx
    inc rax
    xor edx,edx
    div r11
    mov [rdi+rcx*8+8],rdx
    add rdi,8
    inc rcx
    jmp .cycle_loop
.graph_ready:
    lea rax,[rel g98_edges]
    mov [rel g98_request+NEBO_G098_REQUEST_EDGES_PTR_OFFSET],rax
    jmp .run

.embedding_fill:
    mov rax,[rel g98_request+NEBO_G098_REQUEST_NODES_OFFSET]
    imul rax,[rel g98_request+NEBO_G098_REQUEST_INPUT_DIMENSIONS_OFFSET]
    mov r10,rax
    lea r8,[rel g98_embedding]
    xor ecx,ecx
.embedding_fill_loop:
    cmp rcx,r10
    jae .embedding_ready
    mov eax,r13d
    add rax,rcx
    inc rax
    cvtsi2sd xmm0,rax
    movsd [r8+rcx*8],xmm0
    inc rcx
    jmp .embedding_fill_loop
.embedding_ready:
    lea rax,[rel g98_embedding]
    mov [rel g98_request+NEBO_G098_REQUEST_EMBEDDING_PTR_OFFSET],rax

.run:
    mov dword [rel g98_request+NEBO_G098_REQUEST_TARGET_OFFSET],NEBO_G098_TARGET_HEADLESS
    lea rdi,[rel g98_request]
    lea rsi,[rel g98_headless]
    call nebo_g098_graph_view_model
    test eax,eax
    jnz .failure
    mov dword [rel g98_request+NEBO_G098_REQUEST_TARGET_OFFSET],NEBO_G098_TARGET_LIVE
    lea rdi,[rel g98_request]
    lea rsi,[rel g98_live]
    call nebo_g098_graph_view_model
    test eax,eax
    jnz .failure
%macro G098_COMPARE_QWORD 1
    mov rax,[rel g98_headless+%1]
    cmp rax,[rel g98_live+%1]
    jne .failure
%endmacro
    G098_COMPARE_QWORD NEBO_G098_RESULT_NODES_OFFSET
    G098_COMPARE_QWORD NEBO_G098_RESULT_EDGES_OFFSET
    G098_COMPARE_QWORD NEBO_G098_RESULT_LAYOUT_OFFSET
    G098_COMPARE_QWORD NEBO_G098_RESULT_SEED_OFFSET
    G098_COMPARE_QWORD NEBO_G098_RESULT_OPTIONS_OFFSET
    G098_COMPARE_QWORD NEBO_G098_RESULT_VISIBLE_NODES_OFFSET
    G098_COMPARE_QWORD NEBO_G098_RESULT_PATH_COUNT_OFFSET
    G098_COMPARE_QWORD NEBO_G098_RESULT_INPUT_DIMENSIONS_OFFSET
    G098_COMPARE_QWORD NEBO_G098_RESULT_OUTPUT_DIMENSIONS_OFFSET
    G098_COMPARE_QWORD NEBO_G098_RESULT_PROJECTION_ALGORITHM_OFFSET
    G098_COMPARE_QWORD NEBO_G098_RESULT_PROJECTION_REPORT_OFFSET
    G098_COMPARE_QWORD NEBO_G098_RESULT_DIGEST_OFFSET
    G098_COMPARE_QWORD NEBO_G098_RESULT_LAYOUT_DIGEST_OFFSET
    G098_COMPARE_QWORD NEBO_G098_RESULT_PATH_DIGEST_OFFSET
    G098_COMPARE_QWORD NEBO_G098_RESULT_PROJECTION_DIGEST_OFFSET
    G098_COMPARE_QWORD NEBO_G098_RESULT_PROVENANCE_OFFSET
    G098_COMPARE_QWORD NEBO_G098_RESULT_OWNER_GENERATION_OFFSET
    G098_COMPARE_QWORD NEBO_G098_RESULT_VIEW_GENERATION_OFFSET
%undef G098_COMPARE_QWORD
    mov eax,[rel g98_headless+NEBO_G098_RESULT_KIND_OFFSET]
    cmp eax,[rel g98_live+NEBO_G098_RESULT_KIND_OFFSET]
    jne .failure
    mov rax,[rel g98_headless+NEBO_G098_RESULT_DIGEST_OFFSET]
    test rax,rax
    jz .failure
    mov eax,r13d
    jmp .done
.failure:
    mov eax,-1
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; EDI=case 1..16 -> EAX=stable model error and sentinel-preserving failure.
nebo_g098_negative_probe:
    push rbx
    push r12
    mov r12d,edi
    call g98_clear
    call g98_negative_graph
    mov rax,0x6b6b6b6b6b6b6b6b
    lea rdi,[rel g98_headless]
    mov ecx,NEBO_G098_RESULT_SIZE/8
    cld
    rep stosq
    cmp r12d,1
    je .bad_kind
    cmp r12d,2
    je .bad_target
    cmp r12d,3
    je .bad_nodes
    cmp r12d,4
    je .bad_edge_count
    cmp r12d,5
    je .bad_endpoint
    cmp r12d,6
    je .self_edge
    cmp r12d,7
    je .bad_tree
    cmp r12d,8
    je .bad_layout
    cmp r12d,9
    je .bad_path
    cmp r12d,10
    je .nonfinite_embedding
    cmp r12d,11
    je .bad_projection
    cmp r12d,12
    je .bad_report
    cmp r12d,13
    je .stale_view
    cmp r12d,14
    je .unknown_option
    cmp r12d,15
    je .missing_provenance
    cmp r12d,16
    je .bad_budget
    mov eax,-1
    jmp .negative_done
.bad_kind:
    mov dword [rel g98_request+NEBO_G098_REQUEST_KIND_OFFSET],0
    jmp .negative_run
.bad_target:
    mov dword [rel g98_request+NEBO_G098_REQUEST_TARGET_OFFSET],0
    jmp .negative_run
.bad_nodes:
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODES_OFFSET],0
    jmp .negative_run
.bad_edge_count:
    mov qword [rel g98_request+NEBO_G098_REQUEST_EDGES_OFFSET],NEBO_G098_MAX_EDGES+1
    jmp .negative_run
.bad_endpoint:
    mov qword [rel g98_edges+8],4
    jmp .negative_run
.self_edge:
    mov qword [rel g98_edges+8],0
    jmp .negative_run
.bad_tree:
    mov dword [rel g98_request+NEBO_G098_REQUEST_KIND_OFFSET],NEBO_G098_KIND_TREE
    mov qword [rel g98_request+NEBO_G098_REQUEST_LAYOUT_OFFSET],NEBO_G098_LAYOUT_LAYERED
    mov qword [rel g98_edges],0
    mov qword [rel g98_edges+8],1
    mov qword [rel g98_edges+16],0
    mov qword [rel g98_edges+24],1
    mov qword [rel g98_edges+32],1
    mov qword [rel g98_edges+40],2
    jmp .negative_run
.bad_layout:
    mov qword [rel g98_request+NEBO_G098_REQUEST_LAYOUT_OFFSET],0
    jmp .negative_run
.bad_path:
    or qword [rel g98_request+NEBO_G098_REQUEST_OPTIONS_OFFSET],NEBO_G098_OPTION_HIGHLIGHT | NEBO_G098_OPTION_HIGHLIGHT_PATH
    lea rax,[rel g98_path]
    mov [rel g98_request+NEBO_G098_REQUEST_PATH_PTR_OFFSET],rax
    mov qword [rel g98_request+NEBO_G098_REQUEST_PATH_COUNT_OFFSET],2
    mov qword [rel g98_path],0
    mov qword [rel g98_path+8],2
    mov qword [rel g98_request+NEBO_G098_REQUEST_HIGHLIGHT_NODE_OFFSET],1
    jmp .negative_run
.nonfinite_embedding:
    call g98_negative_embedding
    mov rax,0x7ff8000000000001
    mov [rel g98_embedding],rax
    jmp .negative_run
.bad_projection:
    call g98_negative_projection
    mov qword [rel g98_request+NEBO_G098_REQUEST_OUTPUT_DIMENSIONS_OFFSET],4
    jmp .negative_run
.bad_report:
    call g98_negative_projection
    mov qword [rel g98_request+NEBO_G098_REQUEST_PROJECTION_REPORT_OFFSET],2
    jmp .negative_run
.stale_view:
    mov qword [rel g98_request+NEBO_G098_REQUEST_VIEW_GENERATION_OFFSET],8
    jmp .negative_run
.unknown_option:
    or qword [rel g98_request+NEBO_G098_REQUEST_OPTIONS_OFFSET],128
    jmp .negative_run
.missing_provenance:
    mov qword [rel g98_request+NEBO_G098_REQUEST_PROVENANCE_OFFSET],0
    jmp .negative_run
.bad_budget:
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODE_BUDGET_OFFSET],0
.negative_run:
    lea rdi,[rel g98_request]
    lea rsi,[rel g98_headless]
    call nebo_g098_graph_view_model
    mov ebx,eax
    mov rax,0x6b6b6b6b6b6b6b6b
    lea rdi,[rel g98_headless]
    mov ecx,NEBO_G098_RESULT_SIZE/8
    cld
    repe scasq
    jne .atomicity_failed
    mov eax,ebx
    jmp .negative_done
.atomicity_failed:
    mov eax,-1
.negative_done:
    pop r12
    pop rbx
    ret

g98_negative_graph:
    mov dword [rel g98_request+NEBO_G098_REQUEST_KIND_OFFSET],NEBO_G098_KIND_GRAPH
    mov dword [rel g98_request+NEBO_G098_REQUEST_TARGET_OFFSET],NEBO_G098_TARGET_HEADLESS
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODES_OFFSET],4
    mov qword [rel g98_request+NEBO_G098_REQUEST_EDGES_OFFSET],3
    mov qword [rel g98_request+NEBO_G098_REQUEST_LAYOUT_OFFSET],NEBO_G098_LAYOUT_GRID
    mov qword [rel g98_request+NEBO_G098_REQUEST_SEED_OFFSET],7
    mov qword [rel g98_request+NEBO_G098_REQUEST_OPTIONS_OFFSET],NEBO_G098_OPTION_GRAPH
    lea rax,[rel g98_edges]
    mov [rel g98_request+NEBO_G098_REQUEST_EDGES_PTR_OFFSET],rax
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODE_BUDGET_OFFSET],4
    mov qword [rel g98_request+NEBO_G098_REQUEST_PROVENANCE_OFFSET],101
    mov qword [rel g98_request+NEBO_G098_REQUEST_OWNER_GENERATION_OFFSET],7
    mov qword [rel g98_request+NEBO_G098_REQUEST_VIEW_GENERATION_OFFSET],7
    mov qword [rel g98_edges],0
    mov qword [rel g98_edges+8],1
    mov qword [rel g98_edges+16],1
    mov qword [rel g98_edges+24],2
    mov qword [rel g98_edges+32],2
    mov qword [rel g98_edges+40],3
    ret

g98_negative_embedding:
    mov dword [rel g98_request+NEBO_G098_REQUEST_KIND_OFFSET],NEBO_G098_KIND_EMBEDDING
    mov qword [rel g98_request+NEBO_G098_REQUEST_EDGES_OFFSET],0
    mov qword [rel g98_request+NEBO_G098_REQUEST_EDGES_PTR_OFFSET],0
    mov qword [rel g98_request+NEBO_G098_REQUEST_LAYOUT_OFFSET],0
    mov qword [rel g98_request+NEBO_G098_REQUEST_NODES_OFFSET],2
    mov qword [rel g98_request+NEBO_G098_REQUEST_INPUT_DIMENSIONS_OFFSET],3
    mov qword [rel g98_request+NEBO_G098_REQUEST_OPTIONS_OFFSET],NEBO_G098_OPTION_EMBEDDING | NEBO_G098_OPTION_DIMENSIONS
    lea rax,[rel g98_embedding]
    mov [rel g98_request+NEBO_G098_REQUEST_EMBEDDING_PTR_OFFSET],rax
    lea rdi,[rel g98_embedding]
    mov ecx,6
    mov rax,0x3ff0000000000000
    cld
    rep stosq
    ret

g98_negative_projection:
    call g98_negative_embedding
    mov qword [rel g98_request+NEBO_G098_REQUEST_OUTPUT_DIMENSIONS_OFFSET],2
    mov qword [rel g98_request+NEBO_G098_REQUEST_PROJECTION_ALGORITHM_OFFSET],NEBO_G098_PROJECTION_LEADING_AXES
    mov qword [rel g98_request+NEBO_G098_REQUEST_PROJECTION_REPORT_OFFSET],1
    mov qword [rel g98_request+NEBO_G098_REQUEST_OPTIONS_OFFSET],NEBO_G098_OPTION_EMBEDDING | NEBO_G098_OPTION_PROJECTION | NEBO_G098_OPTION_PROJECT | NEBO_G098_OPTION_DIMENSIONS
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
