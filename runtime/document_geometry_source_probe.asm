; G091 source-to-effect probes over the bounded ConsoleDocument geometry owner.
bits 64
default rel
%define NEBO_G091_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/document_geometry_source_probe.inc"
%include "runtime/console_geometry.inc"

extern nebo_geometry_position
extern nebo_geometry_size
extern nebo_geometry_surface
extern nebo_geometry_panel_layer
extern nebo_geometry_update
extern nebo_geometry_labels
extern nebo_geometry_address
extern nebo_geometry_multi_validate
extern nebo_geometry_target_map
extern nebo_geometry_document_validate

global nebo_g091_source_probe
global nebo_g091_negative_probe

section .rodata
; Every source-derived borrowed label length up to 255 has backing storage.
g91_label_byte: times 255 db 'L'
g91_ids: dq 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
         dq 17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32
         dq 33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48
         dq 49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64
g91_duplicate_ids: dq 7,7

section .bss align=16
g91_request: resb 128
g91_result: resb 128
g91_surface: resb NEBO_SURFACE_SIZE
g91_panel: resb NEBO_PANEL_SIZE
g91_label: resb NEBO_LABEL_SIZE
g91_update: resb NEBO_UPDATE_SIZE
g91_document: resb NEBO_DOCUMENT_SIZE
g91_receipt: resb NEBO_DOCUMENT_RECEIPT_SIZE

section .text
; EDI=mode 1..10, ESI=source-derived value -> EAX=owner-published observation.
nebo_g091_source_probe:
    push rbx
    push r12
    sub rsp, 8
    mov r12d, edi
    mov ebx, esi
    test ebx, ebx
    jz .failure
    cmp ebx, 255
    ja .failure
    lea rdi, [rel g91_request]
    mov ecx, 16
    xor eax, eax
    cld
    rep stosq
    lea rdi, [rel g91_result]
    mov ecx, 16
    xor eax, eax
    rep stosq
    cmp r12d, 1
    je .position
    cmp r12d, 2
    je .size
    cmp r12d, 3
    je .surface
    cmp r12d, 4
    je .panel
    cmp r12d, 5
    je .clear
    cmp r12d, 6
    je .labels
    cmp r12d, 7
    je .address
    cmp r12d, 8
    je .multi
    cmp r12d, 9
    je .target
    cmp r12d, 10
    je .document_closeout
    jmp .failure

.position:
    mov [rel g91_request + NEBO_POSITION_X_OFFSET], rbx
    mov qword [rel g91_request + NEBO_POSITION_Y_OFFSET], 3
    lea rdi, [rel g91_request]
    lea rsi, [rel g91_result]
    call nebo_geometry_position
    test eax, eax
    jnz .failure
    mov eax, [rel g91_result + NEBO_POSITION_RESULT_X_OFFSET]
    jmp .verify
.size:
    mov [rel g91_request + NEBO_SIZE_WIDTH_OFFSET], rbx
    mov qword [rel g91_request + NEBO_SIZE_HEIGHT_OFFSET], 1
    mov qword [rel g91_request + NEBO_SIZE_UNIT_OFFSET], NEBO_SIZE_UNIT_CELLS
    lea rdi, [rel g91_request]
    lea rsi, [rel g91_result]
    call nebo_geometry_size
    test eax, eax
    jnz .failure
    mov eax, [rel g91_result + NEBO_SIZE_WIDTH_OFFSET]
    jmp .verify
.surface:
    mov qword [rel g91_request + NEBO_SURFACE_KIND_OFFSET], NEBO_SURFACE_REGION
    mov [rel g91_request + NEBO_SURFACE_ID_OFFSET], rbx
    mov qword [rel g91_request + NEBO_SURFACE_X_OFFSET], 1
    mov qword [rel g91_request + NEBO_SURFACE_Y_OFFSET], 2
    mov qword [rel g91_request + NEBO_SURFACE_WIDTH_OFFSET], 80
    mov qword [rel g91_request + NEBO_SURFACE_HEIGHT_OFFSET], 24
    lea rdi, [rel g91_request]
    lea rsi, [rel g91_result]
    call nebo_geometry_surface
    test eax, eax
    jnz .failure
    mov eax, [rel g91_result + NEBO_SURFACE_ID_OFFSET]
    jmp .verify
.panel:
    mov qword [rel g91_request + NEBO_PANEL_PARENT_OFFSET], 1
    mov [rel g91_request + NEBO_PANEL_ID_OFFSET], rbx
    mov qword [rel g91_request + NEBO_PANEL_LAYER_OFFSET], 0
    mov qword [rel g91_request + NEBO_PANEL_Z_OFFSET], 4
    mov qword [rel g91_request + NEBO_PANEL_INSTANCE_COUNT_OFFSET], 1
    lea rdi, [rel g91_request]
    lea rsi, [rel g91_result]
    call nebo_geometry_panel_layer
    test eax, eax
    jnz .failure
    mov eax, [rel g91_result + NEBO_PANEL_ID_OFFSET]
    jmp .verify
.clear:
    mov qword [rel g91_request + NEBO_UPDATE_OPERATION_OFFSET], NEBO_UPDATE_CLEAR
    mov qword [rel g91_request + NEBO_UPDATE_SCOPE_OFFSET], NEBO_SCOPE_PANEL
    mov qword [rel g91_request + NEBO_UPDATE_SCOPE_ID_OFFSET], 1
    lea rax, [rbx - 1]
    mov [rel g91_request + NEBO_UPDATE_CURRENT_GENERATION_OFFSET], rax
    lea rdi, [rel g91_request]
    lea rsi, [rel g91_result]
    call nebo_geometry_update
    test eax, eax
    jnz .failure
    mov eax, [rel g91_result + NEBO_UPDATE_RESULT_GENERATION_OFFSET]
    jmp .verify
.labels:
    lea rax, [rel g91_label_byte]
    mov [rel g91_request + NEBO_LABEL_TEXT_OFFSET], rax
    mov [rel g91_request + NEBO_LABEL_TEXT_LENGTH_OFFSET], rbx
    mov qword [rel g91_request + NEBO_LABEL_ANCHOR_OFFSET], 5
    lea rdi, [rel g91_request]
    lea rsi, [rel g91_result]
    call nebo_geometry_labels
    test eax, eax
    jnz .failure
    mov eax, [rel g91_result + NEBO_LABEL_TEXT_LENGTH_OFFSET]
    jmp .verify
.address:
    mov qword [rel g91_request + NEBO_ADDRESS_SCOPE_OFFSET], NEBO_SCOPE_PANEL
    mov qword [rel g91_request + NEBO_ADDRESS_SCOPE_ID_OFFSET], 1
    mov eax, ebx
    xor edx, edx
    mov ecx, 8
    div ecx
    mov [rel g91_request + NEBO_ADDRESS_ROW_OFFSET], rax
    mov [rel g91_request + NEBO_ADDRESS_COLUMN_OFFSET], rdx
    mov qword [rel g91_request + NEBO_ADDRESS_ROWS_OFFSET], 32
    mov qword [rel g91_request + NEBO_ADDRESS_COLUMNS_OFFSET], 8
    mov qword [rel g91_request + NEBO_ADDRESS_FLAGS_OFFSET], NEBO_ADDRESS_SELECTED | NEBO_ADDRESS_FOCUSED
    lea rdi, [rel g91_request]
    lea rsi, [rel g91_result]
    call nebo_geometry_address
    test eax, eax
    jnz .failure
    mov eax, [rel g91_result + NEBO_ADDRESS_LINEAR_OFFSET]
    jmp .verify
.multi:
    cmp ebx, NEBO_GEOMETRY_MAX_INSTANCES
    ja .failure
    lea rax, [rel g91_ids]
    mov [rel g91_request + NEBO_MULTI_WINDOWS_OFFSET], rax
    mov [rel g91_request + NEBO_MULTI_WINDOW_COUNT_OFFSET], rbx
    mov qword [rel g91_request + NEBO_MULTI_TARGET_OFFSET], NEBO_TARGET_HEADLESS
    lea rdi, [rel g91_request]
    lea rsi, [rel g91_result]
    call nebo_geometry_multi_validate
    test eax, eax
    jnz .failure
    mov eax, [rel g91_result + NEBO_MULTI_TOTAL_OFFSET]
    jmp .verify
.target:
    mov [rel g91_request + NEBO_TARGET_MAP_X_OFFSET], rbx
    mov qword [rel g91_request + NEBO_TARGET_MAP_Y_OFFSET], 2
    mov qword [rel g91_request + NEBO_TARGET_MAP_WIDTH_OFFSET], 80
    mov qword [rel g91_request + NEBO_TARGET_MAP_HEIGHT_OFFSET], 24
    mov qword [rel g91_request + NEBO_TARGET_MAP_TARGET_OFFSET], NEBO_TARGET_HEADLESS
    mov qword [rel g91_request + NEBO_TARGET_MAP_SCALE_NUMERATOR_OFFSET], 1
    mov qword [rel g91_request + NEBO_TARGET_MAP_SCALE_DENOMINATOR_OFFSET], 1
    lea rdi, [rel g91_request]
    lea rsi, [rel g91_result]
    call nebo_geometry_target_map
    test eax, eax
    jnz .failure
    mov eax, [rel g91_result + NEBO_TARGET_MAP_RESULT_X_OFFSET]
    jmp .verify
.document_closeout:
    ; Refresh is explicit and contributes the observed generation.
    lea rdi, [rel g91_update]
    mov ecx, NEBO_UPDATE_SIZE / 8
    xor eax, eax
    rep stosq
    mov qword [rel g91_update + NEBO_UPDATE_OPERATION_OFFSET], NEBO_UPDATE_REFRESH
    mov qword [rel g91_update + NEBO_UPDATE_SCOPE_OFFSET], NEBO_SCOPE_DOCUMENT
    mov qword [rel g91_update + NEBO_UPDATE_SCOPE_ID_OFFSET], 1
    lea rax, [rbx - 1]
    mov [rel g91_update + NEBO_UPDATE_CURRENT_GENERATION_OFFSET], rax
    mov [rel g91_update + NEBO_UPDATE_SOURCE_GENERATION_OFFSET], rbx
    lea rdi, [rel g91_update]
    lea rsi, [rel g91_result]
    call nebo_geometry_update
    test eax, eax
    jnz .failure
    ; A ready headless surface, panel and label close one document atomically.
    call g91_prepare_document_records
    test eax, eax
    jnz .failure
    lea rax, [rel g91_surface]
    mov [rel g91_document + NEBO_DOCUMENT_SURFACES_OFFSET], rax
    mov qword [rel g91_document + NEBO_DOCUMENT_SURFACE_COUNT_OFFSET], 1
    lea rax, [rel g91_panel]
    mov [rel g91_document + NEBO_DOCUMENT_PANELS_OFFSET], rax
    mov qword [rel g91_document + NEBO_DOCUMENT_PANEL_COUNT_OFFSET], 1
    lea rax, [rel g91_label]
    mov [rel g91_document + NEBO_DOCUMENT_LABELS_OFFSET], rax
    mov qword [rel g91_document + NEBO_DOCUMENT_LABEL_COUNT_OFFSET], 1
    mov qword [rel g91_document + NEBO_DOCUMENT_TARGET_OFFSET], NEBO_TARGET_HEADLESS
    lea rdi, [rel g91_document]
    lea rsi, [rel g91_receipt]
    call nebo_geometry_document_validate
    test eax, eax
    jnz .failure
    cmp qword [rel g91_receipt + NEBO_DOCUMENT_RECEIPT_COUNT_OFFSET], 3
    jne .failure
    mov eax, [rel g91_result + NEBO_UPDATE_RESULT_GENERATION_OFFSET]
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

g91_prepare_document_records:
    lea rdi, [rel g91_surface]
    mov ecx, NEBO_SURFACE_SIZE / 8
    xor eax, eax
    rep stosq
    mov qword [rel g91_surface + NEBO_SURFACE_KIND_OFFSET], NEBO_SURFACE_HEADLESS_WINDOW
    mov qword [rel g91_surface + NEBO_SURFACE_ID_OFFSET], 11
    mov qword [rel g91_surface + NEBO_SURFACE_WIDTH_OFFSET], 80
    mov qword [rel g91_surface + NEBO_SURFACE_HEIGHT_OFFSET], 24
    lea rdi, [rel g91_surface]
    lea rsi, [rel g91_request]
    call nebo_geometry_surface
    test eax, eax
    jnz .prepare_done
    lea rsi, [rel g91_request]
    lea rdi, [rel g91_surface]
    mov ecx, NEBO_SURFACE_SIZE / 8
    rep movsq
    lea rdi, [rel g91_panel]
    mov ecx, NEBO_PANEL_SIZE / 8
    xor eax, eax
    rep stosq
    mov qword [rel g91_panel + NEBO_PANEL_PARENT_OFFSET], 11
    mov qword [rel g91_panel + NEBO_PANEL_ID_OFFSET], 12
    mov qword [rel g91_panel + NEBO_PANEL_INSTANCE_COUNT_OFFSET], 1
    lea rdi, [rel g91_panel]
    lea rsi, [rel g91_request]
    call nebo_geometry_panel_layer
    test eax, eax
    jnz .prepare_done
    lea rsi, [rel g91_request]
    lea rdi, [rel g91_panel]
    mov ecx, NEBO_PANEL_SIZE / 8
    rep movsq
    lea rdi, [rel g91_label]
    mov ecx, NEBO_LABEL_SIZE / 8
    xor eax, eax
    rep stosq
    lea rax, [rel g91_label_byte]
    mov [rel g91_label + NEBO_LABEL_TEXT_OFFSET], rax
    mov qword [rel g91_label + NEBO_LABEL_TEXT_LENGTH_OFFSET], 1
    mov qword [rel g91_label + NEBO_LABEL_ANCHOR_OFFSET], 5
    lea rdi, [rel g91_label]
    lea rsi, [rel g91_request]
    call nebo_geometry_labels
    test eax, eax
    jnz .prepare_done
    lea rsi, [rel g91_request]
    lea rdi, [rel g91_label]
    mov ecx, NEBO_LABEL_SIZE / 8
    rep movsq
    lea rdi, [rel g91_document]
    mov ecx, NEBO_DOCUMENT_SIZE / 8
    xor eax, eax
    rep stosq
    lea rdi, [rel g91_receipt]
    mov ecx, NEBO_DOCUMENT_RECEIPT_SIZE / 8
    xor eax, eax
    rep stosq
.prepare_done:
    ret

; EDI=case -> canonical status. Each destination remains untouched on failure.
nebo_g091_negative_probe:
    push rbx
    mov ebx, edi
    lea rdi, [rel g91_request]
    mov ecx, 16
    xor eax, eax
    rep stosq
    lea rdi, [rel g91_result]
    mov ecx, 16
    mov rax, 0xaaaaaaaaaaaaaaaa
    rep stosq
    cmp ebx, 1
    je .negative_live
    cmp ebx, 2
    je .negative_flags
    cmp ebx, 3
    je .negative_overflow
    cmp ebx, 4
    je .negative_duplicate
    cmp ebx, 5
    je .negative_stale
    jmp .negative_document_target
.negative_live:
    mov qword [rel g91_request + NEBO_SURFACE_KIND_OFFSET], NEBO_SURFACE_LIVE_WINDOW
    mov qword [rel g91_request + NEBO_SURFACE_ID_OFFSET], 1
    mov qword [rel g91_request + NEBO_SURFACE_WIDTH_OFFSET], 80
    mov qword [rel g91_request + NEBO_SURFACE_HEIGHT_OFFSET], 24
    mov qword [rel g91_request + NEBO_SURFACE_HANDLE_OFFSET], 1
    lea rdi, [rel g91_request]
    lea rsi, [rel g91_result]
    call nebo_geometry_surface
    jmp .negative_verify
.negative_flags:
    lea rax, [rel g91_label_byte]
    mov [rel g91_request + NEBO_LABEL_TEXT_OFFSET], rax
    mov qword [rel g91_request + NEBO_LABEL_TEXT_LENGTH_OFFSET], 1
    mov qword [rel g91_request + NEBO_LABEL_ANCHOR_OFFSET], 5
    mov qword [rel g91_request + NEBO_LABEL_FLAGS_OFFSET], 2
    lea rdi, [rel g91_request]
    lea rsi, [rel g91_result]
    call nebo_geometry_labels
    jmp .negative_verify
.negative_overflow:
    mov rax, 0x7fffffffffffffff
    mov [rel g91_request + NEBO_TARGET_MAP_X_OFFSET], rax
    mov qword [rel g91_request + NEBO_TARGET_MAP_WIDTH_OFFSET], 80
    mov qword [rel g91_request + NEBO_TARGET_MAP_HEIGHT_OFFSET], 24
    mov qword [rel g91_request + NEBO_TARGET_MAP_TARGET_OFFSET], NEBO_TARGET_LIVE
    mov qword [rel g91_request + NEBO_TARGET_MAP_SCALE_NUMERATOR_OFFSET], 2
    mov qword [rel g91_request + NEBO_TARGET_MAP_SCALE_DENOMINATOR_OFFSET], 1
    mov qword [rel g91_request + NEBO_TARGET_MAP_CAPABILITIES_OFFSET], NEBO_SURFACE_CAP_LIVE
    lea rdi, [rel g91_request]
    lea rsi, [rel g91_result]
    call nebo_geometry_target_map
    jmp .negative_verify
.negative_duplicate:
    lea rax, [rel g91_duplicate_ids]
    mov [rel g91_request + NEBO_MULTI_WINDOWS_OFFSET], rax
    mov qword [rel g91_request + NEBO_MULTI_WINDOW_COUNT_OFFSET], 2
    mov qword [rel g91_request + NEBO_MULTI_TARGET_OFFSET], NEBO_TARGET_HEADLESS
    lea rdi, [rel g91_request]
    lea rsi, [rel g91_result]
    call nebo_geometry_multi_validate
    jmp .negative_verify
.negative_stale:
    mov qword [rel g91_request + NEBO_UPDATE_OPERATION_OFFSET], NEBO_UPDATE_REFRESH
    mov qword [rel g91_request + NEBO_UPDATE_SCOPE_OFFSET], NEBO_SCOPE_DOCUMENT
    mov qword [rel g91_request + NEBO_UPDATE_SCOPE_ID_OFFSET], 1
    mov qword [rel g91_request + NEBO_UPDATE_CURRENT_GENERATION_OFFSET], 4
    mov qword [rel g91_request + NEBO_UPDATE_SOURCE_GENERATION_OFFSET], 4
    lea rdi, [rel g91_request]
    lea rsi, [rel g91_result]
    call nebo_geometry_update
    jmp .negative_verify
.negative_document_target:
    lea rdi, [rel g91_surface]
    mov ecx, NEBO_SURFACE_SIZE / 8
    xor eax, eax
    rep stosq
    mov qword [rel g91_surface + NEBO_SURFACE_KIND_OFFSET], NEBO_SURFACE_LIVE_WINDOW
    mov qword [rel g91_surface + NEBO_SURFACE_ID_OFFSET], 1
    mov qword [rel g91_surface + NEBO_SURFACE_HANDLE_OFFSET], 1
    mov qword [rel g91_surface + NEBO_SURFACE_CAPABILITIES_OFFSET], NEBO_SURFACE_CAP_LIVE
    mov qword [rel g91_surface + NEBO_SURFACE_STATE_OFFSET], NEBO_SURFACE_READY
    lea rax, [rel g91_surface]
    mov [rel g91_request + NEBO_DOCUMENT_SURFACES_OFFSET], rax
    mov qword [rel g91_request + NEBO_DOCUMENT_SURFACE_COUNT_OFFSET], 1
    mov qword [rel g91_request + NEBO_DOCUMENT_TARGET_OFFSET], NEBO_TARGET_HEADLESS
    lea rdi, [rel g91_request]
    lea rsi, [rel g91_result]
    call nebo_geometry_document_validate
.negative_verify:
    mov r8d, eax
    lea rdi, [rel g91_result]
    mov ecx, 16
    mov rax, 0xaaaaaaaaaaaaaaaa
.negative_atomic:
    cmp [rdi], rax
    jne .negative_corrupt
    add rdi, 8
    loop .negative_atomic
    mov eax, r8d
    pop rbx
    ret
.negative_corrupt:
    mov eax, 99
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
