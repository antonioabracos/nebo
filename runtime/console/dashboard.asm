; G099 deterministic DashboardSpec semantic owner.
bits 64
default rel
%define NEBO_G099_DASHBOARD_IMPLEMENTATION 1
%include "runtime/console/dashboard.inc"

section .text
global nebo_g099_dashboard_model

; dashboard_model(request*, result*) -> stable status.
; All borrowed cells/events are validated before the staged receipt is published.
nebo_g099_dashboard_model:
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
    mov ecx,NEBO_G099_RESULT_SIZE/8
    xor eax,eax
    cld
    rep stosq

    mov eax,[r12+NEBO_G099_REQUEST_TARGET_OFFSET]
    cmp eax,NEBO_G099_TARGET_HEADLESS
    jb .target
    cmp eax,NEBO_G099_TARGET_LIVE
    ja .target
    mov eax,[r12+NEBO_G099_REQUEST_LAYOUT_OFFSET]
    cmp eax,NEBO_G099_LAYOUT_GRID
    jb .layout
    cmp eax,NEBO_G099_LAYOUT_SPLIT
    ja .layout
    mov r14,[r12+NEBO_G099_REQUEST_PANELS_OFFSET]
    test r14,r14
    jz .bounds
    cmp r14,NEBO_G099_MAX_PANELS
    ja .bounds
    mov r10,[r12+NEBO_G099_REQUEST_WIDGETS_OFFSET]
    test r10,r10
    jz .bounds
    cmp r10,NEBO_G099_MAX_WIDGETS
    ja .bounds
    mov r8,[r12+NEBO_G099_REQUEST_WIDGETS_PTR_OFFSET]
    test r8,r8
    jz .widget
    test r8,7
    jnz .widget
    mov rax,[r12+NEBO_G099_REQUEST_COLUMNS_OFFSET]
    test rax,rax
    jz .layout
    cmp rax,16
    ja .layout
    mul qword [r12+NEBO_G099_REQUEST_ROWS_OFFSET]
    test rdx,rdx
    jnz .layout
    cmp qword [r12+NEBO_G099_REQUEST_ROWS_OFFSET],1
    jb .layout
    cmp qword [r12+NEBO_G099_REQUEST_ROWS_OFFSET],16
    ja .layout
    cmp r14,rax
    ja .layout
    cmp qword [r12+NEBO_G099_REQUEST_SPEC_VERSION_OFFSET],NEBO_G099_SPEC_VERSION
    jne .version
    cmp qword [r12+NEBO_G099_REQUEST_SEED_OFFSET],0
    je .source
    cmp qword [r12+NEBO_G099_REQUEST_PROVENANCE_OFFSET],0
    je .provenance
    mov rax,[r12+NEBO_G099_REQUEST_OWNER_GENERATION_OFFSET]
    test rax,rax
    jz .lifetime
    cmp rax,[r12+NEBO_G099_REQUEST_VIEW_GENERATION_OFFSET]
    jne .lifetime
    mov rbx,[r12+NEBO_G099_REQUEST_OPTIONS_OFFSET]
    mov rax,rbx
    and rax,~NEBO_G099_OPTION_KNOWN
    jnz .options
    mov rax,rbx
    and rax,NEBO_G099_OPTION_DASHBOARD | NEBO_G099_OPTION_SOURCE
    cmp rax,NEBO_G099_OPTION_DASHBOARD | NEBO_G099_OPTION_SOURCE
    jne .options

    ; Consume each cell source exactly once while deriving a logical content receipt.
    mov r15,0x44415348434f4e54
    xor r9d,r9d
    xor ecx,ecx
.widget_loop:
    cmp rcx,r10
    jae .widgets_ready
    mov rax,rcx
    shl rax,5
    mov edx,[r8+rax+NEBO_G099_WIDGET_KIND_OFFSET]
    cmp edx,NEBO_G099_WIDGET_TEXT
    jb .widget
    cmp edx,NEBO_G099_WIDGET_SCIENTIFIC
    ja .widget
    mov esi,[r8+rax+NEBO_G099_WIDGET_PANEL_OFFSET]
    cmp rsi,r14
    jae .panel
    mov rdi,[r8+rax+NEBO_G099_WIDGET_SOURCE_GENERATION_OFFSET]
    cmp rdi,[r12+NEBO_G099_REQUEST_VIEW_GENERATION_OFFSET]
    jne .source
    cmp qword [r8+rax+NEBO_G099_WIDGET_CONTENT_OFFSET],0
    je .source
    bts r9,rdx
    cmp edx,NEBO_G099_WIDGET_LOG
    jne .not_log
    inc qword [rbp-200+NEBO_G099_RESULT_LOG_WIDGETS_OFFSET]
.not_log:
    inc qword [rbp-200+NEBO_G099_RESULT_SOURCE_EVALUATIONS_OFFSET]
    mov rdx,[r8+rax]
    xor r15,rdx
    rol r15,11
    mov rdx,[r8+rax+8]
    xor r15,rdx
    rol r15,17
    mov rdx,[r8+rax+16]
    xor r15,rdx
    rol r15,23
    mov rdx,[r8+rax+24]
    xor r15,rdx
    rol r15,29
    inc rcx
    jmp .widget_loop
.widgets_ready:
    mov [rbp-200+NEBO_G099_RESULT_KIND_MASK_OFFSET],r9
    mov [rbp-200+NEBO_G099_RESULT_CONTENT_DIGEST_OFFSET],r15
    cmp qword [rbp-200+NEBO_G099_RESULT_LOG_WIDGETS_OFFSET],0
    je .no_log_widgets
    test rbx,NEBO_G099_OPTION_LOG_PANEL
    jz .log_panel
    jmp .log_contract_ready
.no_log_widgets:
    test rbx,NEBO_G099_OPTION_LOG_PANEL
    jnz .log_panel
.log_contract_ready:

    test rbx,NEBO_G099_OPTION_INTERACTIONS
    jz .no_interactions
    mov r10,[r12+NEBO_G099_REQUEST_EVENTS_OFFSET]
    test r10,r10
    jz .event
    cmp r10,NEBO_G099_MAX_EVENTS
    ja .event
    mov r8,[r12+NEBO_G099_REQUEST_EVENTS_PTR_OFFSET]
    test r8,r8
    jz .event
    test r8,7
    jnz .event
    mov rax,[r12+NEBO_G099_REQUEST_EVENT_BUDGET_OFFSET]
    test rax,rax
    jz .budget
    cmp rax,NEBO_G099_MAX_EVENT_BUDGET
    ja .budget
    mov rdx,r10
    cmp rax,rdx
    cmovb rdx,rax
    mov [rbp-200+NEBO_G099_RESULT_DELIVERED_EVENTS_OFFSET],rdx
    mov r15,0x4556454e54444739
    xor ecx,ecx
.event_loop:
    cmp rcx,r10
    jae .events_ready
    mov rax,rcx
    imul rax,NEBO_G099_EVENT_SIZE
    mov edx,[r8+rax+NEBO_G099_EVENT_SOURCE_OFFSET]
    cmp rdx,[r12+NEBO_G099_REQUEST_WIDGETS_OFFSET]
    jae .event
    mov esi,[r8+rax+NEBO_G099_EVENT_TARGET_OFFSET]
    cmp rsi,[r12+NEBO_G099_REQUEST_WIDGETS_OFFSET]
    jae .event
    cmp edx,esi
    je .event
    mov rdi,[r8+rax+NEBO_G099_EVENT_KIND_OFFSET]
    cmp rdi,NEBO_G099_EVENT_SELECT
    jb .event
    cmp rdi,NEBO_G099_EVENT_FOCUS
    ja .event
    mov rdx,[r8+rax]
    xor r15,rdx
    rol r15,13
    mov rdx,[r8+rax+8]
    xor r15,rdx
    rol r15,19
    mov rdx,[r8+rax+16]
    xor r15,rdx
    rol r15,31
    inc rcx
    jmp .event_loop
.events_ready:
    mov [rbp-200+NEBO_G099_RESULT_EVENT_DIGEST_OFFSET],r15
    jmp .export_contract
.no_interactions:
    cmp qword [r12+NEBO_G099_REQUEST_EVENTS_OFFSET],0
    jne .event
    cmp qword [r12+NEBO_G099_REQUEST_EVENTS_PTR_OFFSET],0
    jne .event
    cmp qword [r12+NEBO_G099_REQUEST_EVENT_BUDGET_OFFSET],0
    jne .budget

.export_contract:
    test rbx,NEBO_G099_OPTION_EXPORT
    jz .no_export
    mov rax,[r12+NEBO_G099_REQUEST_EXPORT_FORMAT_OFFSET]
    cmp rax,NEBO_G099_EXPORT_TEXT
    jb .export
    cmp rax,NEBO_G099_EXPORT_JSON
    ja .export
    cmp qword [r12+NEBO_G099_REQUEST_EXPORT_PERMISSION_OFFSET],1
    jne .export
    mov r15,0x4558504f52544739
    xor r15,rax
    rol r15,17
    xor r15,[rbp-200+NEBO_G099_RESULT_CONTENT_DIGEST_OFFSET]
    rol r15,29
    mov [rbp-200+NEBO_G099_RESULT_EXPORT_DIGEST_OFFSET],r15
    jmp .snapshot_contract
.no_export:
    cmp qword [r12+NEBO_G099_REQUEST_EXPORT_FORMAT_OFFSET],0
    jne .export
    cmp qword [r12+NEBO_G099_REQUEST_EXPORT_PERMISSION_OFFSET],0
    jne .export

.snapshot_contract:
    test rbx,NEBO_G099_OPTION_SNAPSHOT
    jz .no_snapshot
    mov rax,[r12+NEBO_G099_REQUEST_SNAPSHOT_GENERATION_OFFSET]
    cmp rax,[r12+NEBO_G099_REQUEST_VIEW_GENERATION_OFFSET]
    jne .lifetime
    mov r15,0x534e415053484739
    xor r15,rax
    rol r15,23
    xor r15,[rbp-200+NEBO_G099_RESULT_CONTENT_DIGEST_OFFSET]
    rol r15,37
    mov [rbp-200+NEBO_G099_RESULT_SNAPSHOT_DIGEST_OFFSET],r15
    jmp .publish
.no_snapshot:
    cmp qword [r12+NEBO_G099_REQUEST_SNAPSHOT_GENERATION_OFFSET],0
    jne .lifetime

.publish:
    mov eax,[r12+NEBO_G099_REQUEST_TARGET_OFFSET]
    mov [rbp-200+NEBO_G099_RESULT_TARGET_OFFSET],eax
    mov eax,[r12+NEBO_G099_REQUEST_LAYOUT_OFFSET]
    mov [rbp-200+NEBO_G099_RESULT_LAYOUT_OFFSET],eax
    mov rax,[r12+NEBO_G099_REQUEST_PANELS_OFFSET]
    mov [rbp-200+NEBO_G099_RESULT_PANELS_OFFSET],rax
    mov rax,[r12+NEBO_G099_REQUEST_WIDGETS_OFFSET]
    mov [rbp-200+NEBO_G099_RESULT_WIDGETS_OFFSET],rax
    mov rax,[r12+NEBO_G099_REQUEST_EVENTS_OFFSET]
    mov [rbp-200+NEBO_G099_RESULT_EVENTS_OFFSET],rax
    mov rax,[r12+NEBO_G099_REQUEST_OPTIONS_OFFSET]
    mov [rbp-200+NEBO_G099_RESULT_OPTIONS_OFFSET],rax
    mov rax,[r12+NEBO_G099_REQUEST_SEED_OFFSET]
    mov [rbp-200+NEBO_G099_RESULT_SEED_OFFSET],rax
    mov rax,[r12+NEBO_G099_REQUEST_EXPORT_FORMAT_OFFSET]
    mov [rbp-200+NEBO_G099_RESULT_EXPORT_FORMAT_OFFSET],rax
    mov rax,[r12+NEBO_G099_REQUEST_SNAPSHOT_GENERATION_OFFSET]
    mov [rbp-200+NEBO_G099_RESULT_SNAPSHOT_GENERATION_OFFSET],rax
    mov rax,[r12+NEBO_G099_REQUEST_OWNER_GENERATION_OFFSET]
    mov [rbp-200+NEBO_G099_RESULT_OWNER_GENERATION_OFFSET],rax
    mov rax,[r12+NEBO_G099_REQUEST_VIEW_GENERATION_OFFSET]
    mov [rbp-200+NEBO_G099_RESULT_VIEW_GENERATION_OFFSET],rax
    mov rax,[r12+NEBO_G099_REQUEST_SPEC_VERSION_OFFSET]
    mov [rbp-200+NEBO_G099_RESULT_SPEC_VERSION_OFFSET],rax

    mov r15,0x4c41594f55544739
    xor r15,[r12+NEBO_G099_REQUEST_COLUMNS_OFFSET]
    rol r15,11
    xor r15,[r12+NEBO_G099_REQUEST_ROWS_OFFSET]
    rol r15,17
    xor r15,[r12+NEBO_G099_REQUEST_PANELS_OFFSET]
    rol r15,23
    xor r15,[r12+NEBO_G099_REQUEST_SEED_OFFSET]
    mov [rbp-200+NEBO_G099_RESULT_LAYOUT_DIGEST_OFFSET],r15

    mov r15,0xcbf29ce484222325
    xor r15,[r12+NEBO_G099_REQUEST_PANELS_OFFSET]
    rol r15,7
    xor r15,[r12+NEBO_G099_REQUEST_WIDGETS_OFFSET]
    rol r15,11
    xor r15,[r12+NEBO_G099_REQUEST_EVENTS_OFFSET]
    rol r15,13
    xor r15,[r12+NEBO_G099_REQUEST_OPTIONS_OFFSET]
    rol r15,17
    xor r15,[r12+NEBO_G099_REQUEST_SEED_OFFSET]
    rol r15,19
    xor r15,[rbp-200+NEBO_G099_RESULT_KIND_MASK_OFFSET]
    rol r15,23
    xor r15,[rbp-200+NEBO_G099_RESULT_CONTENT_DIGEST_OFFSET]
    rol r15,29
    xor r15,[rbp-200+NEBO_G099_RESULT_EVENT_DIGEST_OFFSET]
    rol r15,31
    xor r15,[rbp-200+NEBO_G099_RESULT_LAYOUT_DIGEST_OFFSET]
    rol r15,37
    xor r15,[rbp-200+NEBO_G099_RESULT_EXPORT_DIGEST_OFFSET]
    rol r15,41
    xor r15,[rbp-200+NEBO_G099_RESULT_SNAPSHOT_DIGEST_OFFSET]
    rol r15,43
    xor r15,[r12+NEBO_G099_REQUEST_PROVENANCE_OFFSET]
    rol r15,47
    xor r15,[r12+NEBO_G099_REQUEST_OWNER_GENERATION_OFFSET]
    xor [rbp-200+NEBO_G099_RESULT_CONTENT_DIGEST_OFFSET],r15

    lea rsi,[rbp-200]
    mov rdi,r13
    mov ecx,NEBO_G099_RESULT_SIZE/8
    cld
    rep movsq
    xor eax,eax
    jmp .done

.invalid:
    mov eax,NEBO_G099_ERROR_INVALID
    jmp .done
.target:
    mov eax,NEBO_G099_ERROR_TARGET
    jmp .done
.bounds:
    mov eax,NEBO_G099_ERROR_BOUNDS
    jmp .done
.widget:
    mov eax,NEBO_G099_ERROR_WIDGET
    jmp .done
.panel:
    mov eax,NEBO_G099_ERROR_PANEL
    jmp .done
.options:
    mov eax,NEBO_G099_ERROR_OPTIONS
    jmp .done
.log_panel:
    mov eax,NEBO_G099_ERROR_LOG_PANEL
    jmp .done
.layout:
    mov eax,NEBO_G099_ERROR_LAYOUT
    jmp .done
.event:
    mov eax,NEBO_G099_ERROR_EVENT
    jmp .done
.budget:
    mov eax,NEBO_G099_ERROR_BUDGET
    jmp .done
.export:
    mov eax,NEBO_G099_ERROR_EXPORT
    jmp .done
.lifetime:
    mov eax,NEBO_G099_ERROR_LIFETIME
    jmp .done
.provenance:
    mov eax,NEBO_G099_ERROR_PROVENANCE
    jmp .done
.version:
    mov eax,NEBO_G099_ERROR_VERSION
    jmp .done
.source:
    mov eax,NEBO_G099_ERROR_SOURCE
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
