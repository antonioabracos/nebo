; Source-to-effect bridge for G113 internal domain visual services.
bits 64
default rel
%define NEBO_G113_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/console_workflow_source_probe.inc"

section .note.GNU-stack noalloc noexec nowrite progbits

section .bss align=16
g113_clear_begin:
g113_spec: resb NEBO_G113_SPEC_SIZE
g113_receipts: resb NEBO_G113_OPERATION_COUNT*NEBO_G113_RECEIPT_SIZE
g113_live_receipt: resb NEBO_G113_RECEIPT_SIZE
g113_negative_receipt: resb NEBO_G113_RECEIPT_SIZE
g113_last_mode: resq 1
g113_last_seed: resq 1
g113_clear_end:

section .text
global nebo_g113_source_probe
global nebo_g113_surface_probe
global nebo_g113_negative_probe

g113_probe_clear:
    lea rdi,[rel g113_clear_begin]
    mov ecx,(g113_clear_end-g113_clear_begin)/8
    xor eax,eax
    cld
    rep stosq
    ret

; EDI=subgroup 1..10, ESI=source seed 3301..3310.
nebo_g113_source_probe:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov ebx,edi
    mov ebp,esi
    cmp ebx,1
    jb .invalid
    cmp ebx,NEBO_G113_SOURCE_MAX_MODE
    ja .invalid
    cmp ebp,NEBO_G113_SOURCE_MIN_SEED
    jb .invalid
    cmp ebp,NEBO_G113_SOURCE_MAX_SEED
    ja .invalid
    mov eax,ebp
    sub eax,3300
    cmp eax,ebx
    jne .invalid
    call g113_probe_clear
    mov [rel g113_last_mode],rbx
    mov [rel g113_last_seed],rbp

    mov qword [rel g113_spec+NEBO_G113_SPEC_VERSION_OFFSET],NEBO_G113_SPEC_VERSION
    mov qword [rel g113_spec+NEBO_G113_SPEC_TARGET_OFFSET],NEBO_G113_TARGET_HEADLESS
    mov qword [rel g113_spec+NEBO_G113_SPEC_PRIMARY_OFFSET],16
    mov qword [rel g113_spec+NEBO_G113_SPEC_SECONDARY_OFFSET],12
    mov qword [rel g113_spec+NEBO_G113_SPEC_AUX_OFFSET],5
    mov [rel g113_spec+NEBO_G113_SPEC_GENERATION_OFFSET],rbp
    mov rax,rbp
    imul rax,rax,131
    mov rdx,0x47313133434f5245
    xor rax,rdx
    mov [rel g113_spec+NEBO_G113_SPEC_CORE_DIGEST_OFFSET],rax
    mov qword [rel g113_spec+NEBO_G113_SPEC_PRIVACY_OFFSET],NEBO_G113_PRIVACY_REDACTED
    mov qword [rel g113_spec+NEBO_G113_SPEC_CAPABILITY_OFFSET],NEBO_G113_CAPABILITY_SEMANTIC_PREVIEW
    mov [rel g113_spec+NEBO_G113_SPEC_OWNER_GENERATION_OFFSET],rbp
    mov [rel g113_spec+NEBO_G113_SPEC_VIEW_GENERATION_OFFSET],rbp
    mov eax,ebx
    dec eax
    xor edx,edx
    mov ecx,3
    div ecx
    inc edx
    mov [rel g113_spec+NEBO_G113_SPEC_LAYOUT_OFFSET],rdx
    mov rax,rbx
    shl rax,32
    or rax,rbp
    mov [rel g113_spec+NEBO_G113_SPEC_FLAGS_OFFSET],rax

    lea r12,[rel g113_spec]
    lea r13,[rel g113_receipts]
%macro G113_CALL 2
    mov rdi,r12
    lea rsi,[r13+(%2-1)*NEBO_G113_RECEIPT_SIZE]
    call %1
    test eax,eax
    jnz .effect
    cmp qword [r13+(%2-1)*NEBO_G113_RECEIPT_SIZE+NEBO_G113_RECEIPT_OPERATION_OFFSET],%2
    jne .effect
    cmp qword [r13+(%2-1)*NEBO_G113_RECEIPT_SIZE+NEBO_G113_RECEIPT_MATURITY_OFFSET],NEBO_G113_MATURITY_INTERNAL_DOMAIN_VISUAL_SERVICES_GREEN
    jne .effect
%endmacro
    G113_CALL nebo_g113_dashboard_create,NEBO_G113_DASHBOARD_CREATE
    G113_CALL nebo_g113_dashboard_from_spec,NEBO_G113_DASHBOARD_FROM_SPEC
    G113_CALL nebo_g113_dashboard_layout,NEBO_G113_DASHBOARD_LAYOUT
    G113_CALL nebo_g113_dashboard_add_panel,NEBO_G113_DASHBOARD_ADD_PANEL
    G113_CALL nebo_g113_dashboard_add_text,NEBO_G113_DASHBOARD_ADD_TEXT
    G113_CALL nebo_g113_dashboard_add_chart,NEBO_G113_DASHBOARD_ADD_CHART
    G113_CALL nebo_g113_dashboard_add_table,NEBO_G113_DASHBOARD_ADD_TABLE
    G113_CALL nebo_g113_dashboard_add_timeline,NEBO_G113_DASHBOARD_ADD_TIMELINE
    G113_CALL nebo_g113_dashboard_show,NEBO_G113_DASHBOARD_SHOW
    G113_CALL nebo_g113_dashboard_export_text,NEBO_G113_DASHBOARD_EXPORT_TEXT
    G113_CALL nebo_g113_dashboard_export_html,NEBO_G113_DASHBOARD_EXPORT_HTML
    G113_CALL nebo_g113_ml_training_dashboard,NEBO_G113_ML_TRAINING_DASHBOARD
    G113_CALL nebo_g113_ml_training_result,NEBO_G113_ML_TRAINING_RESULT
    G113_CALL nebo_g113_ml_loss_chart,NEBO_G113_ML_LOSS_CHART
    G113_CALL nebo_g113_ml_metric_chart,NEBO_G113_ML_METRIC_CHART
    G113_CALL nebo_g113_ml_confusion_matrix,NEBO_G113_ML_CONFUSION_MATRIX
    G113_CALL nebo_g113_ml_predictions,NEBO_G113_ML_PREDICTIONS
    G113_CALL nebo_g113_ml_checkpoint_timeline,NEBO_G113_ML_CHECKPOINT_TIMELINE
    G113_CALL nebo_g113_ml_model_summary,NEBO_G113_ML_MODEL_SUMMARY
    G113_CALL nebo_g113_media_image,NEBO_G113_MEDIA_IMAGE
    G113_CALL nebo_g113_media_audio,NEBO_G113_MEDIA_AUDIO
    G113_CALL nebo_g113_media_video,NEBO_G113_MEDIA_VIDEO
    G113_CALL nebo_g113_media_frame,NEBO_G113_MEDIA_FRAME
    G113_CALL nebo_g113_media_waveform,NEBO_G113_MEDIA_WAVEFORM
    G113_CALL nebo_g113_media_spectrogram,NEBO_G113_MEDIA_SPECTROGRAM
    G113_CALL nebo_g113_media_thumbnails,NEBO_G113_MEDIA_THUMBNAILS
    G113_CALL nebo_g113_media_metadata,NEBO_G113_MEDIA_METADATA
    G113_CALL nebo_g113_graph_graph,NEBO_G113_GRAPH_GRAPH
    G113_CALL nebo_g113_graph_tree,NEBO_G113_GRAPH_TREE
    G113_CALL nebo_g113_graph_dependency_graph,NEBO_G113_GRAPH_DEPENDENCY
    G113_CALL nebo_g113_graph_computational_graph,NEBO_G113_GRAPH_COMPUTATIONAL
    G113_CALL nebo_g113_graph_layout,NEBO_G113_GRAPH_LAYOUT
    G113_CALL nebo_g113_graph_limit_nodes,NEBO_G113_GRAPH_LIMIT_NODES
    G113_CALL nebo_g113_graph_limit_edges,NEBO_G113_GRAPH_LIMIT_EDGES
%undef G113_CALL

    ; Live and headless targets must preserve the same logical service digest.
    mov qword [rel g113_spec+NEBO_G113_SPEC_TARGET_OFFSET],NEBO_G113_TARGET_LIVE
    mov rdi,r12
    lea rsi,[rel g113_live_receipt]
    call nebo_g113_dashboard_create
    test eax,eax
    jnz .effect
    mov rax,[rel g113_live_receipt+NEBO_G113_RECEIPT_SERVICE_DIGEST_OFFSET]
    cmp rax,[r13+NEBO_G113_RECEIPT_SERVICE_DIGEST_OFFSET]
    jne .effect

    mov eax,ebp
    jmp .done
.invalid:
    mov eax,NEBO_G113_ERROR_INVALID
    jmp .done
.effect:
    mov eax,-99
.done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; EDI=field 1..46. Fields 3..36 expose one independent digest per surface.
nebo_g113_surface_probe:
    cmp edi,1
    je .mode
    cmp edi,2
    je .seed
    cmp edi,3
    jb .zero
    cmp edi,36
    jbe .digest
    cmp edi,37
    je .first_operation
    cmp edi,38
    je .last_operation
    cmp edi,39
    je .maturity
    cmp edi,40
    je .privacy
    cmp edi,41
    je .capability
    cmp edi,42
    je .generation
    cmp edi,43
    je .target
    cmp edi,44
    je .primary
    cmp edi,45
    je .secondary
    cmp edi,46
    je .aux
.zero:
    xor eax,eax
    ret
.mode: mov rax,[rel g113_last_mode]
    ret
.seed: mov rax,[rel g113_last_seed]
    ret
.digest:
    sub edi,3
    imul edi,NEBO_G113_RECEIPT_SIZE
    lea rdx,[rel g113_receipts]
    mov rax,[rdx+rdi+NEBO_G113_RECEIPT_SERVICE_DIGEST_OFFSET]
    ret
.first_operation: mov rax,[rel g113_receipts+NEBO_G113_RECEIPT_OPERATION_OFFSET]
    ret
.last_operation: mov rax,[rel g113_receipts+(NEBO_G113_OPERATION_COUNT-1)*NEBO_G113_RECEIPT_SIZE+NEBO_G113_RECEIPT_OPERATION_OFFSET]
    ret
.maturity: mov rax,[rel g113_receipts+(NEBO_G113_OPERATION_COUNT-1)*NEBO_G113_RECEIPT_SIZE+NEBO_G113_RECEIPT_MATURITY_OFFSET]
    ret
.privacy: mov rax,[rel g113_receipts+NEBO_G113_RECEIPT_PRIVACY_OFFSET]
    ret
.capability: mov rax,[rel g113_receipts+NEBO_G113_RECEIPT_CAPABILITY_OFFSET]
    ret
.generation: mov rax,[rel g113_receipts+NEBO_G113_RECEIPT_GENERATION_OFFSET]
    ret
.target: mov rax,[rel g113_receipts+NEBO_G113_RECEIPT_TARGET_OFFSET]
    ret
.primary: mov rax,[rel g113_receipts+NEBO_G113_RECEIPT_PRIMARY_OFFSET]
    ret
.secondary: mov rax,[rel g113_receipts+NEBO_G113_RECEIPT_SECONDARY_OFFSET]
    ret
.aux: mov rax,[rel g113_receipts+NEBO_G113_RECEIPT_AUX_OFFSET]
    ret

; EDI=case 1..18. Failed service calls never modify the supplied receipt.
nebo_g113_negative_probe:
    push rbx
    push r12
    push r13
    sub rsp,8
    mov ebx,edi
    cmp ebx,1
    jb .bad
    cmp ebx,NEBO_G113_SOURCE_NEGATIVE_COUNT
    ja .bad
    mov edi,1
    mov esi,3301
    call nebo_g113_source_probe
    cmp eax,3301
    jne .bad
    cmp ebx,1
    je .bad_mode
    cmp ebx,2
    je .bad_seed
    mov rax,0x6e65676174697665
    mov [rel g113_negative_receipt+NEBO_G113_RECEIPT_SERVICE_DIGEST_OFFSET],rax
    cmp ebx,3
    je .null_spec
    cmp ebx,4
    je .null_receipt
    lea rdi,[rel g113_spec]
    lea rsi,[rel g113_negative_receipt]
    cmp ebx,5
    je .version
    cmp ebx,6
    je .target
    cmp ebx,7
    je .primary_zero
    cmp ebx,8
    je .dashboard_items
    cmp ebx,9
    je .core
    cmp ebx,10
    je .privacy
    cmp ebx,11
    je .capability
    cmp ebx,12
    je .lifetime
    cmp ebx,13
    je .dashboard_layout
    cmp ebx,14
    je .ml_bound
    cmp ebx,15
    je .media_policy
    cmp ebx,16
    je .graph_layout
    cmp ebx,17
    je .node_limit
    jmp .edge_limit
.bad_mode:
    xor edi,edi
    mov esi,3301
    call nebo_g113_source_probe
    cmp eax,NEBO_G113_ERROR_INVALID
    jne .bad
    jmp .ok
.bad_seed:
    mov edi,1
    mov esi,3302
    call nebo_g113_source_probe
    cmp eax,NEBO_G113_ERROR_INVALID
    jne .bad
    jmp .ok
.null_spec:
    xor edi,edi
    lea rsi,[rel g113_negative_receipt]
    mov r12d,NEBO_G113_ERROR_INVALID
    jmp .run_dashboard
.null_receipt:
    lea rdi,[rel g113_spec]
    xor esi,esi
    call nebo_g113_dashboard_create
    cmp eax,NEBO_G113_ERROR_INVALID
    jne .bad
    jmp .ok
.version:
    mov qword [rel g113_spec+NEBO_G113_SPEC_VERSION_OFFSET],2
    mov r12d,NEBO_G113_ERROR_VERSION
    jmp .run_dashboard
.target:
    mov qword [rel g113_spec+NEBO_G113_SPEC_TARGET_OFFSET],3
    mov r12d,NEBO_G113_ERROR_TARGET
    jmp .run_dashboard
.primary_zero:
    mov qword [rel g113_spec+NEBO_G113_SPEC_PRIMARY_OFFSET],0
    mov r12d,NEBO_G113_ERROR_BOUNDS
    jmp .run_dashboard
.dashboard_items:
    mov qword [rel g113_spec+NEBO_G113_SPEC_SECONDARY_OFFSET],257
    mov r12d,NEBO_G113_ERROR_BOUNDS
    jmp .run_dashboard
.core:
    mov qword [rel g113_spec+NEBO_G113_SPEC_CORE_DIGEST_OFFSET],0
    mov r12d,NEBO_G113_ERROR_CORE
    jmp .run_dashboard
.privacy:
    mov qword [rel g113_spec+NEBO_G113_SPEC_PRIVACY_OFFSET],3
    mov r12d,NEBO_G113_ERROR_POLICY
    jmp .run_dashboard
.capability:
    mov qword [rel g113_spec+NEBO_G113_SPEC_CAPABILITY_OFFSET],2
    mov r12d,NEBO_G113_ERROR_CAPABILITY
    jmp .run_dashboard
.lifetime:
    inc qword [rel g113_spec+NEBO_G113_SPEC_VIEW_GENERATION_OFFSET]
    mov r12d,NEBO_G113_ERROR_LIFETIME
    jmp .run_dashboard
.dashboard_layout:
    mov qword [rel g113_spec+NEBO_G113_SPEC_LAYOUT_OFFSET],4
    mov r12d,NEBO_G113_ERROR_LAYOUT
    jmp .run_dashboard
.ml_bound:
    mov qword [rel g113_spec+NEBO_G113_SPEC_PRIMARY_OFFSET],4097
    mov r12d,NEBO_G113_ERROR_BOUNDS
    jmp .run_ml
.media_policy:
    mov qword [rel g113_spec+NEBO_G113_SPEC_PRIVACY_OFFSET],NEBO_G113_PRIVACY_PUBLIC
    mov r12d,NEBO_G113_ERROR_POLICY
    jmp .run_media
.graph_layout:
    mov qword [rel g113_spec+NEBO_G113_SPEC_LAYOUT_OFFSET],5
    mov r12d,NEBO_G113_ERROR_LAYOUT
    jmp .run_graph
.node_limit:
    mov qword [rel g113_spec+NEBO_G113_SPEC_AUX_OFFSET],17
    mov r12d,NEBO_G113_ERROR_BOUNDS
    jmp .run_nodes
.edge_limit:
    mov qword [rel g113_spec+NEBO_G113_SPEC_AUX_OFFSET],13
    mov r12d,NEBO_G113_ERROR_BOUNDS
    jmp .run_edges
.run_dashboard:
    call nebo_g113_dashboard_create
    jmp .verify
.run_ml:
    call nebo_g113_ml_training_dashboard
    jmp .verify
.run_media:
    call nebo_g113_media_image
    jmp .verify
.run_graph:
    call nebo_g113_graph_graph
    jmp .verify
.run_nodes:
    call nebo_g113_graph_limit_nodes
    jmp .verify
.run_edges:
    call nebo_g113_graph_limit_edges
.verify:
    cmp eax,r12d
    jne .bad
    mov r13,0x6e65676174697665
    cmp [rel g113_negative_receipt+NEBO_G113_RECEIPT_SERVICE_DIGEST_OFFSET],r13
    jne .bad
.ok:
    xor eax,eax
    jmp .done
.bad:
    mov eax,1
.done:
    add rsp,8
    pop r13
    pop r12
    pop rbx
    ret
