; G113 bounded dashboard, ML, media and graph host-service adapters.
bits 64
default rel
%define NEBO_G113_DOMAIN_VISUAL_IMPLEMENTATION 1
%include "runtime/internal_domain_visual_services.inc"

section .text

%macro G113_ENTRY 3
global %1
%1:
    mov edx,%2
    mov ecx,%3
    jmp g113_service_build
%endmacro

G113_ENTRY nebo_g113_dashboard_create,NEBO_G113_DASHBOARD_CREATE,NEBO_G113_DOMAIN_DASHBOARD
G113_ENTRY nebo_g113_dashboard_from_spec,NEBO_G113_DASHBOARD_FROM_SPEC,NEBO_G113_DOMAIN_DASHBOARD
G113_ENTRY nebo_g113_dashboard_layout,NEBO_G113_DASHBOARD_LAYOUT,NEBO_G113_DOMAIN_DASHBOARD
G113_ENTRY nebo_g113_dashboard_add_panel,NEBO_G113_DASHBOARD_ADD_PANEL,NEBO_G113_DOMAIN_DASHBOARD
G113_ENTRY nebo_g113_dashboard_add_text,NEBO_G113_DASHBOARD_ADD_TEXT,NEBO_G113_DOMAIN_DASHBOARD
G113_ENTRY nebo_g113_dashboard_add_chart,NEBO_G113_DASHBOARD_ADD_CHART,NEBO_G113_DOMAIN_DASHBOARD
G113_ENTRY nebo_g113_dashboard_add_table,NEBO_G113_DASHBOARD_ADD_TABLE,NEBO_G113_DOMAIN_DASHBOARD
G113_ENTRY nebo_g113_dashboard_add_timeline,NEBO_G113_DASHBOARD_ADD_TIMELINE,NEBO_G113_DOMAIN_DASHBOARD
G113_ENTRY nebo_g113_dashboard_show,NEBO_G113_DASHBOARD_SHOW,NEBO_G113_DOMAIN_DASHBOARD
G113_ENTRY nebo_g113_dashboard_export_text,NEBO_G113_DASHBOARD_EXPORT_TEXT,NEBO_G113_DOMAIN_DASHBOARD
G113_ENTRY nebo_g113_dashboard_export_html,NEBO_G113_DASHBOARD_EXPORT_HTML,NEBO_G113_DOMAIN_DASHBOARD
G113_ENTRY nebo_g113_ml_training_dashboard,NEBO_G113_ML_TRAINING_DASHBOARD,NEBO_G113_DOMAIN_ML
G113_ENTRY nebo_g113_ml_training_result,NEBO_G113_ML_TRAINING_RESULT,NEBO_G113_DOMAIN_ML
G113_ENTRY nebo_g113_ml_loss_chart,NEBO_G113_ML_LOSS_CHART,NEBO_G113_DOMAIN_ML
G113_ENTRY nebo_g113_ml_metric_chart,NEBO_G113_ML_METRIC_CHART,NEBO_G113_DOMAIN_ML
G113_ENTRY nebo_g113_ml_confusion_matrix,NEBO_G113_ML_CONFUSION_MATRIX,NEBO_G113_DOMAIN_ML
G113_ENTRY nebo_g113_ml_predictions,NEBO_G113_ML_PREDICTIONS,NEBO_G113_DOMAIN_ML
G113_ENTRY nebo_g113_ml_checkpoint_timeline,NEBO_G113_ML_CHECKPOINT_TIMELINE,NEBO_G113_DOMAIN_ML
G113_ENTRY nebo_g113_ml_model_summary,NEBO_G113_ML_MODEL_SUMMARY,NEBO_G113_DOMAIN_ML
G113_ENTRY nebo_g113_media_image,NEBO_G113_MEDIA_IMAGE,NEBO_G113_DOMAIN_MEDIA
G113_ENTRY nebo_g113_media_audio,NEBO_G113_MEDIA_AUDIO,NEBO_G113_DOMAIN_MEDIA
G113_ENTRY nebo_g113_media_video,NEBO_G113_MEDIA_VIDEO,NEBO_G113_DOMAIN_MEDIA
G113_ENTRY nebo_g113_media_frame,NEBO_G113_MEDIA_FRAME,NEBO_G113_DOMAIN_MEDIA
G113_ENTRY nebo_g113_media_waveform,NEBO_G113_MEDIA_WAVEFORM,NEBO_G113_DOMAIN_MEDIA
G113_ENTRY nebo_g113_media_spectrogram,NEBO_G113_MEDIA_SPECTROGRAM,NEBO_G113_DOMAIN_MEDIA
G113_ENTRY nebo_g113_media_thumbnails,NEBO_G113_MEDIA_THUMBNAILS,NEBO_G113_DOMAIN_MEDIA
G113_ENTRY nebo_g113_media_metadata,NEBO_G113_MEDIA_METADATA,NEBO_G113_DOMAIN_MEDIA
G113_ENTRY nebo_g113_graph_graph,NEBO_G113_GRAPH_GRAPH,NEBO_G113_DOMAIN_GRAPH
G113_ENTRY nebo_g113_graph_tree,NEBO_G113_GRAPH_TREE,NEBO_G113_DOMAIN_GRAPH
G113_ENTRY nebo_g113_graph_dependency_graph,NEBO_G113_GRAPH_DEPENDENCY,NEBO_G113_DOMAIN_GRAPH
G113_ENTRY nebo_g113_graph_computational_graph,NEBO_G113_GRAPH_COMPUTATIONAL,NEBO_G113_DOMAIN_GRAPH
G113_ENTRY nebo_g113_graph_layout,NEBO_G113_GRAPH_LAYOUT,NEBO_G113_DOMAIN_GRAPH
G113_ENTRY nebo_g113_graph_limit_nodes,NEBO_G113_GRAPH_LIMIT_NODES,NEBO_G113_DOMAIN_GRAPH
G113_ENTRY nebo_g113_graph_limit_edges,NEBO_G113_GRAPH_LIMIT_EDGES,NEBO_G113_DOMAIN_GRAPH
%undef G113_ENTRY

; RDI=borrowed spec, RSI=caller-owned receipt, EDX=operation, ECX=domain.
; Validation completes before the staged receipt is published.
g113_service_build:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,112
    mov r12,rdi
    mov r13,rsi
    mov r14d,edx
    mov r15d,ecx
    test r12,r12
    jz .invalid
    test r13,r13
    jz .invalid
    test r12,7
    jnz .invalid
    test r13,7
    jnz .invalid
    cmp qword [r12+NEBO_G113_SPEC_VERSION_OFFSET],NEBO_G113_SPEC_VERSION
    jne .version
    mov rax,[r12+NEBO_G113_SPEC_TARGET_OFFSET]
    cmp rax,NEBO_G113_TARGET_HEADLESS
    jb .target
    cmp rax,NEBO_G113_TARGET_LIVE
    ja .target
    cmp qword [r12+NEBO_G113_SPEC_PRIMARY_OFFSET],1
    jb .bounds
    cmp qword [r12+NEBO_G113_SPEC_SECONDARY_OFFSET],1
    jb .bounds
    cmp qword [r12+NEBO_G113_SPEC_AUX_OFFSET],1
    jb .bounds
    cmp qword [r12+NEBO_G113_SPEC_GENERATION_OFFSET],1
    jb .invalid
    cmp qword [r12+NEBO_G113_SPEC_CORE_DIGEST_OFFSET],0
    je .core
    mov rax,[r12+NEBO_G113_SPEC_PRIVACY_OFFSET]
    cmp rax,NEBO_G113_PRIVACY_PUBLIC
    jb .policy
    cmp rax,NEBO_G113_PRIVACY_REDACTED
    ja .policy
    cmp qword [r12+NEBO_G113_SPEC_CAPABILITY_OFFSET],NEBO_G113_CAPABILITY_SEMANTIC_PREVIEW
    jne .capability
    mov rax,[r12+NEBO_G113_SPEC_OWNER_GENERATION_OFFSET]
    test rax,rax
    jz .lifetime
    cmp rax,[r12+NEBO_G113_SPEC_VIEW_GENERATION_OFFSET]
    jne .lifetime

    cmp r15d,NEBO_G113_DOMAIN_DASHBOARD
    je .dashboard
    cmp r15d,NEBO_G113_DOMAIN_ML
    je .ml
    cmp r15d,NEBO_G113_DOMAIN_MEDIA
    je .media
    cmp r15d,NEBO_G113_DOMAIN_GRAPH
    je .graph
    jmp .invalid
.dashboard:
    cmp qword [r12+NEBO_G113_SPEC_PRIMARY_OFFSET],NEBO_G113_MAX_DASHBOARD_PANELS
    ja .bounds
    cmp qword [r12+NEBO_G113_SPEC_SECONDARY_OFFSET],NEBO_G113_MAX_DASHBOARD_ITEMS
    ja .bounds
    mov rax,[r12+NEBO_G113_SPEC_LAYOUT_OFFSET]
    cmp rax,NEBO_G113_LAYOUT_GRID
    jb .layout
    cmp rax,NEBO_G113_LAYOUT_SPLIT
    ja .layout
    jmp .stage
.ml:
    cmp qword [r12+NEBO_G113_SPEC_PRIMARY_OFFSET],4096
    ja .bounds
    cmp qword [r12+NEBO_G113_SPEC_SECONDARY_OFFSET],NEBO_G113_MAX_ML_VALUES
    ja .bounds
    cmp qword [r12+NEBO_G113_SPEC_PRIVACY_OFFSET],NEBO_G113_PRIVACY_REDACTED
    jne .policy
    jmp .stage
.media:
    cmp qword [r12+NEBO_G113_SPEC_PRIMARY_OFFSET],4096
    ja .bounds
    cmp qword [r12+NEBO_G113_SPEC_SECONDARY_OFFSET],NEBO_G113_MAX_MEDIA_UNITS
    ja .bounds
    cmp qword [r12+NEBO_G113_SPEC_PRIVACY_OFFSET],NEBO_G113_PRIVACY_REDACTED
    jne .policy
    jmp .stage
.graph:
    cmp qword [r12+NEBO_G113_SPEC_PRIMARY_OFFSET],NEBO_G113_MAX_GRAPH_NODES
    ja .bounds
    cmp qword [r12+NEBO_G113_SPEC_SECONDARY_OFFSET],NEBO_G113_MAX_GRAPH_EDGES
    ja .bounds
    mov rax,[r12+NEBO_G113_SPEC_LAYOUT_OFFSET]
    cmp rax,NEBO_G113_LAYOUT_GRID
    jb .layout
    cmp rax,NEBO_G113_LAYOUT_LAYERED
    ja .layout
    cmp r14d,NEBO_G113_GRAPH_LIMIT_NODES
    jne .graph_edges
    mov rax,[r12+NEBO_G113_SPEC_AUX_OFFSET]
    cmp rax,[r12+NEBO_G113_SPEC_PRIMARY_OFFSET]
    ja .bounds
.graph_edges:
    cmp r14d,NEBO_G113_GRAPH_LIMIT_EDGES
    jne .stage
    mov rax,[r12+NEBO_G113_SPEC_AUX_OFFSET]
    cmp rax,[r12+NEBO_G113_SPEC_SECONDARY_OFFSET]
    ja .bounds

.stage:
    lea rdi,[rsp]
    mov ecx,NEBO_G113_RECEIPT_SIZE/8
    xor eax,eax
    cld
    rep stosq
    mov [rsp+NEBO_G113_RECEIPT_OPERATION_OFFSET],r14
    mov [rsp+NEBO_G113_RECEIPT_DOMAIN_OFFSET],r15
    mov rax,[r12+NEBO_G113_SPEC_TARGET_OFFSET]
    mov [rsp+NEBO_G113_RECEIPT_TARGET_OFFSET],rax
    mov rax,[r12+NEBO_G113_SPEC_PRIMARY_OFFSET]
    mov [rsp+NEBO_G113_RECEIPT_PRIMARY_OFFSET],rax
    mov rax,[r12+NEBO_G113_SPEC_SECONDARY_OFFSET]
    mov [rsp+NEBO_G113_RECEIPT_SECONDARY_OFFSET],rax
    mov rax,[r12+NEBO_G113_SPEC_AUX_OFFSET]
    mov [rsp+NEBO_G113_RECEIPT_AUX_OFFSET],rax
    mov rax,[r12+NEBO_G113_SPEC_CORE_DIGEST_OFFSET]
    mov [rsp+NEBO_G113_RECEIPT_CORE_DIGEST_OFFSET],rax
    mov rax,[r12+NEBO_G113_SPEC_GENERATION_OFFSET]
    mov [rsp+NEBO_G113_RECEIPT_GENERATION_OFFSET],rax
    mov rax,[r12+NEBO_G113_SPEC_PRIVACY_OFFSET]
    mov [rsp+NEBO_G113_RECEIPT_PRIVACY_OFFSET],rax
    mov rax,[r12+NEBO_G113_SPEC_CAPABILITY_OFFSET]
    mov [rsp+NEBO_G113_RECEIPT_CAPABILITY_OFFSET],rax
    mov rax,[r12+NEBO_G113_SPEC_LAYOUT_OFFSET]
    mov [rsp+NEBO_G113_RECEIPT_LAYOUT_OFFSET],rax
    mov qword [rsp+NEBO_G113_RECEIPT_MATURITY_OFFSET],NEBO_G113_MATURITY_INTERNAL_DOMAIN_VISUAL_SERVICES_GREEN

    ; Target is excluded: headless and live backends share the semantic receipt.
    mov rbx,0x67313133646f6d31
    xor rbx,r14
    rol rbx,7
    xor rbx,r15
    rol rbx,11
    xor rbx,[r12+NEBO_G113_SPEC_PRIMARY_OFFSET]
    rol rbx,13
    xor rbx,[r12+NEBO_G113_SPEC_SECONDARY_OFFSET]
    rol rbx,17
    xor rbx,[r12+NEBO_G113_SPEC_AUX_OFFSET]
    rol rbx,19
    xor rbx,[r12+NEBO_G113_SPEC_CORE_DIGEST_OFFSET]
    rol rbx,23
    xor rbx,[r12+NEBO_G113_SPEC_GENERATION_OFFSET]
    rol rbx,29
    xor rbx,[r12+NEBO_G113_SPEC_PRIVACY_OFFSET]
    rol rbx,31
    xor rbx,[r12+NEBO_G113_SPEC_CAPABILITY_OFFSET]
    rol rbx,37
    xor rbx,[r12+NEBO_G113_SPEC_LAYOUT_OFFSET]
    rol rbx,41
    xor rbx,[r12+NEBO_G113_SPEC_FLAGS_OFFSET]
    mov [rsp+NEBO_G113_RECEIPT_SERVICE_DIGEST_OFFSET],rbx

    mov rdi,r13
    lea rsi,[rsp]
    mov ecx,NEBO_G113_RECEIPT_SIZE/8
    cld
    rep movsq
    xor eax,eax
    jmp .done
.invalid: mov eax,NEBO_G113_ERROR_INVALID
    jmp .done
.bounds: mov eax,NEBO_G113_ERROR_BOUNDS
    jmp .done
.version: mov eax,NEBO_G113_ERROR_VERSION
    jmp .done
.target: mov eax,NEBO_G113_ERROR_TARGET
    jmp .done
.policy: mov eax,NEBO_G113_ERROR_POLICY
    jmp .done
.lifetime: mov eax,NEBO_G113_ERROR_LIFETIME
    jmp .done
.core: mov eax,NEBO_G113_ERROR_CORE
    jmp .done
.layout: mov eax,NEBO_G113_ERROR_LAYOUT
    jmp .done
.capability: mov eax,NEBO_G113_ERROR_CAPABILITY
.done:
    add rsp,112
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Compatibility hook used by the P06 closeout aggregator. It remains a
; bounded scalar gate and is not a G113 surface implementation.
global nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_closeout_contract_validate
nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_closeout_contract_validate:
    test rdx,rdx
    jz .compat_invalid
    cmp rdi,1
    jb .compat_invalid
    cmp rdi,100000
    ja .compat_bounds
    cmp rsi,64
    ja .compat_bounds
    lea rax,[rdi+rsi]
    mov [rdx],rax
    xor eax,eax
    ret
.compat_invalid:
    mov eax,NEBO_G113_ERROR_INVALID
    ret
.compat_bounds:
    mov eax,NEBO_G113_ERROR_BOUNDS
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
