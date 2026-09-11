; G099 source-to-effect probe over the bounded DashboardSpec semantic model.
bits 64
default rel
%define NEBO_G099_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/dashboard_source_probe.inc"
%include "runtime/console/dashboard.inc"

%define G099_PROBE_WIDGET_CAPACITY 256
%define G099_PROBE_EVENT_CAPACITY 512

global nebo_g099_source_probe
global nebo_g099_negative_probe

section .bss align=16
g99_request: resb NEBO_G099_REQUEST_SIZE
g99_headless: resb NEBO_G099_RESULT_SIZE
g99_live: resb NEBO_G099_RESULT_SIZE
g99_widgets: resb G099_PROBE_WIDGET_CAPACITY*NEBO_G099_WIDGET_SIZE
g99_events: resb G099_PROBE_EVENT_CAPACITY*NEBO_G099_EVENT_SIZE

section .text
g99_clear:
    lea rdi,[rel g99_request]
    mov ecx,NEBO_G099_REQUEST_SIZE/8
    xor eax,eax
    cld
    rep stosq
    lea rdi,[rel g99_headless]
    mov ecx,NEBO_G099_RESULT_SIZE/8
    rep stosq
    lea rdi,[rel g99_live]
    mov ecx,NEBO_G099_RESULT_SIZE/8
    rep stosq
    ret

; EDI=subgroup 1..9, ESI=source generation 1..255 -> EAX=generation.
nebo_g099_source_probe:
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
    call g99_clear
    mov qword [rel g99_request+NEBO_G099_REQUEST_PANELS_OFFSET],2
    mov qword [rel g99_request+NEBO_G099_REQUEST_WIDGETS_OFFSET],2
    mov dword [rel g99_request+NEBO_G099_REQUEST_LAYOUT_OFFSET],NEBO_G099_LAYOUT_GRID
    mov qword [rel g99_request+NEBO_G099_REQUEST_COLUMNS_OFFSET],2
    mov qword [rel g99_request+NEBO_G099_REQUEST_ROWS_OFFSET],1
    mov qword [rel g99_request+NEBO_G099_REQUEST_OPTIONS_OFFSET],NEBO_G099_OPTION_DASHBOARD | NEBO_G099_OPTION_SOURCE
    mov [rel g99_request+NEBO_G099_REQUEST_SEED_OFFSET],r13
    mov [rel g99_request+NEBO_G099_REQUEST_OWNER_GENERATION_OFFSET],r13
    mov [rel g99_request+NEBO_G099_REQUEST_VIEW_GENERATION_OFFSET],r13
    mov rax,r13
    add rax,200
    mov [rel g99_request+NEBO_G099_REQUEST_PROVENANCE_OFFSET],rax
    mov qword [rel g99_request+NEBO_G099_REQUEST_SPEC_VERSION_OFFSET],NEBO_G099_SPEC_VERSION
    lea rax,[rel g99_widgets]
    mov [rel g99_request+NEBO_G099_REQUEST_WIDGETS_PTR_OFFSET],rax

    cmp r12d,1
    je .configuration_ready
    cmp r12d,2
    je .panel_composition
    cmp r12d,3
    je .multi_view
    cmp r12d,4
    je .log_panel
    cmp r12d,5
    je .present
    cmp r12d,6
    je .export
    cmp r12d,7
    je .interactions
    cmp r12d,8
    je .snapshot
    jmp .closeout

.panel_composition:
    mov qword [rel g99_request+NEBO_G099_REQUEST_PANELS_OFFSET],4
    mov qword [rel g99_request+NEBO_G099_REQUEST_WIDGETS_OFFSET],4
    mov qword [rel g99_request+NEBO_G099_REQUEST_COLUMNS_OFFSET],2
    mov qword [rel g99_request+NEBO_G099_REQUEST_ROWS_OFFSET],2
    jmp .configuration_ready
.multi_view:
    mov qword [rel g99_request+NEBO_G099_REQUEST_PANELS_OFFSET],4
    mov qword [rel g99_request+NEBO_G099_REQUEST_WIDGETS_OFFSET],4
    mov dword [rel g99_request+NEBO_G099_REQUEST_LAYOUT_OFFSET],NEBO_G099_LAYOUT_SPLIT
    mov qword [rel g99_request+NEBO_G099_REQUEST_COLUMNS_OFFSET],2
    mov qword [rel g99_request+NEBO_G099_REQUEST_ROWS_OFFSET],2
    jmp .configuration_ready
.log_panel:
    mov qword [rel g99_request+NEBO_G099_REQUEST_PANELS_OFFSET],3
    mov qword [rel g99_request+NEBO_G099_REQUEST_WIDGETS_OFFSET],5
    mov dword [rel g99_request+NEBO_G099_REQUEST_LAYOUT_OFFSET],NEBO_G099_LAYOUT_STACK
    mov qword [rel g99_request+NEBO_G099_REQUEST_COLUMNS_OFFSET],1
    mov qword [rel g99_request+NEBO_G099_REQUEST_ROWS_OFFSET],3
    or qword [rel g99_request+NEBO_G099_REQUEST_OPTIONS_OFFSET],NEBO_G099_OPTION_LOG_PANEL
    jmp .configuration_ready
.present:
    or qword [rel g99_request+NEBO_G099_REQUEST_OPTIONS_OFFSET],NEBO_G099_OPTION_PRESENT
    jmp .configuration_ready
.export:
    or qword [rel g99_request+NEBO_G099_REQUEST_OPTIONS_OFFSET],NEBO_G099_OPTION_EXPORT
    mov eax,r13d
    xor edx,edx
    mov ecx,3
    div ecx
    inc edx
    mov [rel g99_request+NEBO_G099_REQUEST_EXPORT_FORMAT_OFFSET],rdx
    mov qword [rel g99_request+NEBO_G099_REQUEST_EXPORT_PERMISSION_OFFSET],1
    jmp .configuration_ready
.interactions:
    or qword [rel g99_request+NEBO_G099_REQUEST_OPTIONS_OFFSET],NEBO_G099_OPTION_INTERACTIONS
    mov qword [rel g99_request+NEBO_G099_REQUEST_WIDGETS_OFFSET],4
    mov qword [rel g99_request+NEBO_G099_REQUEST_EVENTS_OFFSET],3
    mov qword [rel g99_request+NEBO_G099_REQUEST_EVENT_BUDGET_OFFSET],2
    lea rax,[rel g99_events]
    mov [rel g99_request+NEBO_G099_REQUEST_EVENTS_PTR_OFFSET],rax
    jmp .configuration_ready
.snapshot:
    or qword [rel g99_request+NEBO_G099_REQUEST_OPTIONS_OFFSET],NEBO_G099_OPTION_SNAPSHOT
    mov [rel g99_request+NEBO_G099_REQUEST_SNAPSHOT_GENERATION_OFFSET],r13
    jmp .configuration_ready
.closeout:
    mov qword [rel g99_request+NEBO_G099_REQUEST_PANELS_OFFSET],6
    mov qword [rel g99_request+NEBO_G099_REQUEST_WIDGETS_OFFSET],6
    mov qword [rel g99_request+NEBO_G099_REQUEST_COLUMNS_OFFSET],3
    mov qword [rel g99_request+NEBO_G099_REQUEST_ROWS_OFFSET],2
    mov qword [rel g99_request+NEBO_G099_REQUEST_OPTIONS_OFFSET],NEBO_G099_OPTION_DASHBOARD | NEBO_G099_OPTION_LOG_PANEL | NEBO_G099_OPTION_PRESENT | NEBO_G099_OPTION_EXPORT | NEBO_G099_OPTION_INTERACTIONS | NEBO_G099_OPTION_SNAPSHOT | NEBO_G099_OPTION_SOURCE
    mov qword [rel g99_request+NEBO_G099_REQUEST_EXPORT_FORMAT_OFFSET],NEBO_G099_EXPORT_JSON
    mov qword [rel g99_request+NEBO_G099_REQUEST_EXPORT_PERMISSION_OFFSET],1
    mov [rel g99_request+NEBO_G099_REQUEST_SNAPSHOT_GENERATION_OFFSET],r13
    mov qword [rel g99_request+NEBO_G099_REQUEST_EVENTS_OFFSET],3
    mov qword [rel g99_request+NEBO_G099_REQUEST_EVENT_BUDGET_OFFSET],3
    lea rax,[rel g99_events]
    mov [rel g99_request+NEBO_G099_REQUEST_EVENTS_PTR_OFFSET],rax

.configuration_ready:
    lea r8,[rel g99_widgets]
    xor ecx,ecx
    mov r10,[rel g99_request+NEBO_G099_REQUEST_WIDGETS_OFFSET]
.widget_fill:
    cmp rcx,r10
    jae .widgets_filled
    mov rax,rcx
    shl rax,5
    mov r11d,ecx
    and r11d,3
    inc r11d
    test qword [rel g99_request+NEBO_G099_REQUEST_OPTIONS_OFFSET],NEBO_G099_OPTION_LOG_PANEL
    jz .kind_ready
    cmp ecx,4
    jne .not_log_slot
    mov r11d,NEBO_G099_WIDGET_LOG
    jmp .kind_ready
.not_log_slot:
    cmp r12d,9
    jne .kind_ready
    cmp ecx,5
    jne .kind_ready
    mov r11d,NEBO_G099_WIDGET_SCIENTIFIC
.kind_ready:
    mov [r8+rax+NEBO_G099_WIDGET_KIND_OFFSET],r11d
    mov rbx,rax
    mov rax,rcx
    xor edx,edx
    div qword [rel g99_request+NEBO_G099_REQUEST_PANELS_OFFSET]
    mov [r8+rbx+NEBO_G099_WIDGET_PANEL_OFFSET],edx
    mov [r8+rbx+NEBO_G099_WIDGET_SOURCE_GENERATION_OFFSET],r13
    mov rax,r13
    add rax,rcx
    inc rax
    mov [r8+rbx+NEBO_G099_WIDGET_CONTENT_OFFSET],rax
    mov [r8+rbx+NEBO_G099_WIDGET_FLAGS_OFFSET],rcx
    inc rcx
    jmp .widget_fill
.widgets_filled:
    cmp qword [rel g99_request+NEBO_G099_REQUEST_EVENTS_OFFSET],0
    je .run
    lea r8,[rel g99_events]
    mov dword [r8+NEBO_G099_EVENT_SOURCE_OFFSET],0
    mov dword [r8+NEBO_G099_EVENT_TARGET_OFFSET],1
    mov qword [r8+NEBO_G099_EVENT_KIND_OFFSET],NEBO_G099_EVENT_SELECT
    mov [r8+NEBO_G099_EVENT_VALUE_OFFSET],r13
    mov dword [r8+NEBO_G099_EVENT_SIZE+NEBO_G099_EVENT_SOURCE_OFFSET],1
    mov dword [r8+NEBO_G099_EVENT_SIZE+NEBO_G099_EVENT_TARGET_OFFSET],2
    mov qword [r8+NEBO_G099_EVENT_SIZE+NEBO_G099_EVENT_KIND_OFFSET],NEBO_G099_EVENT_FILTER
    mov rax,r13
    inc rax
    mov [r8+NEBO_G099_EVENT_SIZE+NEBO_G099_EVENT_VALUE_OFFSET],rax
    mov dword [r8+NEBO_G099_EVENT_SIZE*2+NEBO_G099_EVENT_SOURCE_OFFSET],2
    mov dword [r8+NEBO_G099_EVENT_SIZE*2+NEBO_G099_EVENT_TARGET_OFFSET],0
    mov qword [r8+NEBO_G099_EVENT_SIZE*2+NEBO_G099_EVENT_KIND_OFFSET],NEBO_G099_EVENT_FOCUS
    inc rax
    mov [r8+NEBO_G099_EVENT_SIZE*2+NEBO_G099_EVENT_VALUE_OFFSET],rax

.run:
    mov dword [rel g99_request+NEBO_G099_REQUEST_TARGET_OFFSET],NEBO_G099_TARGET_HEADLESS
    lea rdi,[rel g99_request]
    lea rsi,[rel g99_headless]
    call nebo_g099_dashboard_model
    test eax,eax
    jnz .failure
    mov dword [rel g99_request+NEBO_G099_REQUEST_TARGET_OFFSET],NEBO_G099_TARGET_LIVE
    lea rdi,[rel g99_request]
    lea rsi,[rel g99_live]
    call nebo_g099_dashboard_model
    test eax,eax
    jnz .failure
%macro G099_COMPARE_QWORD 1
    mov rax,[rel g99_headless+%1]
    cmp rax,[rel g99_live+%1]
    jne .failure
%endmacro
    G099_COMPARE_QWORD NEBO_G099_RESULT_PANELS_OFFSET
    G099_COMPARE_QWORD NEBO_G099_RESULT_WIDGETS_OFFSET
    G099_COMPARE_QWORD NEBO_G099_RESULT_EVENTS_OFFSET
    G099_COMPARE_QWORD NEBO_G099_RESULT_DELIVERED_EVENTS_OFFSET
    G099_COMPARE_QWORD NEBO_G099_RESULT_OPTIONS_OFFSET
    G099_COMPARE_QWORD NEBO_G099_RESULT_SEED_OFFSET
    G099_COMPARE_QWORD NEBO_G099_RESULT_KIND_MASK_OFFSET
    G099_COMPARE_QWORD NEBO_G099_RESULT_LOG_WIDGETS_OFFSET
    G099_COMPARE_QWORD NEBO_G099_RESULT_SOURCE_EVALUATIONS_OFFSET
    G099_COMPARE_QWORD NEBO_G099_RESULT_CONTENT_DIGEST_OFFSET
    G099_COMPARE_QWORD NEBO_G099_RESULT_EVENT_DIGEST_OFFSET
    G099_COMPARE_QWORD NEBO_G099_RESULT_LAYOUT_DIGEST_OFFSET
    G099_COMPARE_QWORD NEBO_G099_RESULT_EXPORT_DIGEST_OFFSET
    G099_COMPARE_QWORD NEBO_G099_RESULT_SNAPSHOT_DIGEST_OFFSET
    G099_COMPARE_QWORD NEBO_G099_RESULT_EXPORT_FORMAT_OFFSET
    G099_COMPARE_QWORD NEBO_G099_RESULT_SNAPSHOT_GENERATION_OFFSET
    G099_COMPARE_QWORD NEBO_G099_RESULT_OWNER_GENERATION_OFFSET
    G099_COMPARE_QWORD NEBO_G099_RESULT_VIEW_GENERATION_OFFSET
    G099_COMPARE_QWORD NEBO_G099_RESULT_SPEC_VERSION_OFFSET
%undef G099_COMPARE_QWORD
    mov rax,[rel g99_headless+NEBO_G099_RESULT_SOURCE_EVALUATIONS_OFFSET]
    cmp rax,[rel g99_headless+NEBO_G099_RESULT_WIDGETS_OFFSET]
    jne .failure
    cmp qword [rel g99_headless+NEBO_G099_RESULT_CONTENT_DIGEST_OFFSET],0
    je .failure
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

; EDI=case 1..15 -> EAX=stable model error and sentinel-preserving failure.
nebo_g099_negative_probe:
    push rbx
    push r12
    mov r12d,edi
    call g99_negative_base
    mov rax,0x6b6b6b6b6b6b6b6b
    lea rdi,[rel g99_headless]
    mov ecx,NEBO_G099_RESULT_SIZE/8
    cld
    rep stosq
    cmp r12d,1
    je .bad_target
    cmp r12d,2
    je .bad_panels
    cmp r12d,3
    je .bad_widget_count
    cmp r12d,4
    je .bad_widget_kind
    cmp r12d,5
    je .bad_panel
    cmp r12d,6
    je .unknown_option
    cmp r12d,7
    je .bad_log_panel
    cmp r12d,8
    je .bad_layout
    cmp r12d,9
    je .bad_event
    cmp r12d,10
    je .bad_budget
    cmp r12d,11
    je .bad_export
    cmp r12d,12
    je .stale_view
    cmp r12d,13
    je .missing_provenance
    cmp r12d,14
    je .bad_version
    cmp r12d,15
    je .stale_source
    mov eax,-1
    jmp .negative_done
.bad_target:
    mov dword [rel g99_request+NEBO_G099_REQUEST_TARGET_OFFSET],0
    jmp .negative_run
.bad_panels:
    mov qword [rel g99_request+NEBO_G099_REQUEST_PANELS_OFFSET],0
    jmp .negative_run
.bad_widget_count:
    mov qword [rel g99_request+NEBO_G099_REQUEST_WIDGETS_OFFSET],NEBO_G099_MAX_WIDGETS+1
    jmp .negative_run
.bad_widget_kind:
    mov dword [rel g99_widgets+NEBO_G099_WIDGET_KIND_OFFSET],0
    jmp .negative_run
.bad_panel:
    mov dword [rel g99_widgets+NEBO_G099_WIDGET_PANEL_OFFSET],2
    jmp .negative_run
.unknown_option:
    or qword [rel g99_request+NEBO_G099_REQUEST_OPTIONS_OFFSET],128
    jmp .negative_run
.bad_log_panel:
    or qword [rel g99_request+NEBO_G099_REQUEST_OPTIONS_OFFSET],NEBO_G099_OPTION_LOG_PANEL
    jmp .negative_run
.bad_layout:
    mov qword [rel g99_request+NEBO_G099_REQUEST_COLUMNS_OFFSET],1
    mov qword [rel g99_request+NEBO_G099_REQUEST_ROWS_OFFSET],1
    jmp .negative_run
.bad_event:
    or qword [rel g99_request+NEBO_G099_REQUEST_OPTIONS_OFFSET],NEBO_G099_OPTION_INTERACTIONS
    mov qword [rel g99_request+NEBO_G099_REQUEST_EVENTS_OFFSET],1
    lea rax,[rel g99_events]
    mov [rel g99_request+NEBO_G099_REQUEST_EVENTS_PTR_OFFSET],rax
    mov qword [rel g99_request+NEBO_G099_REQUEST_EVENT_BUDGET_OFFSET],1
    mov dword [rel g99_events+NEBO_G099_EVENT_SOURCE_OFFSET],0
    mov dword [rel g99_events+NEBO_G099_EVENT_TARGET_OFFSET],0
    mov qword [rel g99_events+NEBO_G099_EVENT_KIND_OFFSET],NEBO_G099_EVENT_SELECT
    jmp .negative_run
.bad_budget:
    or qword [rel g99_request+NEBO_G099_REQUEST_OPTIONS_OFFSET],NEBO_G099_OPTION_INTERACTIONS
    mov qword [rel g99_request+NEBO_G099_REQUEST_EVENTS_OFFSET],1
    lea rax,[rel g99_events]
    mov [rel g99_request+NEBO_G099_REQUEST_EVENTS_PTR_OFFSET],rax
    mov qword [rel g99_request+NEBO_G099_REQUEST_EVENT_BUDGET_OFFSET],0
    jmp .negative_run
.bad_export:
    or qword [rel g99_request+NEBO_G099_REQUEST_OPTIONS_OFFSET],NEBO_G099_OPTION_EXPORT
    mov qword [rel g99_request+NEBO_G099_REQUEST_EXPORT_FORMAT_OFFSET],NEBO_G099_EXPORT_JSON
    mov qword [rel g99_request+NEBO_G099_REQUEST_EXPORT_PERMISSION_OFFSET],0
    jmp .negative_run
.stale_view:
    mov qword [rel g99_request+NEBO_G099_REQUEST_VIEW_GENERATION_OFFSET],8
    jmp .negative_run
.missing_provenance:
    mov qword [rel g99_request+NEBO_G099_REQUEST_PROVENANCE_OFFSET],0
    jmp .negative_run
.bad_version:
    mov qword [rel g99_request+NEBO_G099_REQUEST_SPEC_VERSION_OFFSET],2
    jmp .negative_run
.stale_source:
    mov qword [rel g99_widgets+NEBO_G099_WIDGET_SOURCE_GENERATION_OFFSET],8
.negative_run:
    lea rdi,[rel g99_request]
    lea rsi,[rel g99_headless]
    call nebo_g099_dashboard_model
    mov ebx,eax
    mov rax,0x6b6b6b6b6b6b6b6b
    lea rdi,[rel g99_headless]
    mov ecx,NEBO_G099_RESULT_SIZE/8
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

g99_negative_base:
    call g99_clear
    mov dword [rel g99_request+NEBO_G099_REQUEST_TARGET_OFFSET],NEBO_G099_TARGET_HEADLESS
    mov dword [rel g99_request+NEBO_G099_REQUEST_LAYOUT_OFFSET],NEBO_G099_LAYOUT_GRID
    mov qword [rel g99_request+NEBO_G099_REQUEST_PANELS_OFFSET],2
    mov qword [rel g99_request+NEBO_G099_REQUEST_WIDGETS_OFFSET],2
    lea rax,[rel g99_widgets]
    mov [rel g99_request+NEBO_G099_REQUEST_WIDGETS_PTR_OFFSET],rax
    mov qword [rel g99_request+NEBO_G099_REQUEST_OPTIONS_OFFSET],NEBO_G099_OPTION_DASHBOARD | NEBO_G099_OPTION_SOURCE
    mov qword [rel g99_request+NEBO_G099_REQUEST_SEED_OFFSET],7
    mov qword [rel g99_request+NEBO_G099_REQUEST_OWNER_GENERATION_OFFSET],7
    mov qword [rel g99_request+NEBO_G099_REQUEST_VIEW_GENERATION_OFFSET],7
    mov qword [rel g99_request+NEBO_G099_REQUEST_PROVENANCE_OFFSET],207
    mov qword [rel g99_request+NEBO_G099_REQUEST_COLUMNS_OFFSET],2
    mov qword [rel g99_request+NEBO_G099_REQUEST_ROWS_OFFSET],1
    mov qword [rel g99_request+NEBO_G099_REQUEST_SPEC_VERSION_OFFSET],NEBO_G099_SPEC_VERSION
    mov dword [rel g99_widgets+NEBO_G099_WIDGET_KIND_OFFSET],NEBO_G099_WIDGET_TEXT
    mov dword [rel g99_widgets+NEBO_G099_WIDGET_PANEL_OFFSET],0
    mov qword [rel g99_widgets+NEBO_G099_WIDGET_SOURCE_GENERATION_OFFSET],7
    mov qword [rel g99_widgets+NEBO_G099_WIDGET_CONTENT_OFFSET],8
    mov dword [rel g99_widgets+NEBO_G099_WIDGET_SIZE+NEBO_G099_WIDGET_KIND_OFFSET],NEBO_G099_WIDGET_CHART
    mov dword [rel g99_widgets+NEBO_G099_WIDGET_SIZE+NEBO_G099_WIDGET_PANEL_OFFSET],1
    mov qword [rel g99_widgets+NEBO_G099_WIDGET_SIZE+NEBO_G099_WIDGET_SOURCE_GENERATION_OFFSET],7
    mov qword [rel g99_widgets+NEBO_G099_WIDGET_SIZE+NEBO_G099_WIDGET_CONTENT_OFFSET],9
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
