; G090 source-to-effect probe over the closed TypeId/schema adapter registry.
bits 64
default rel
%define NEBO_G090_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/console_values_source_probe.inc"
%include "runtime/render_model.inc"
%include "runtime/console_renderable.inc"

extern nebo_console_renderable_registry
extern nebo_console_renderable_adapt
extern nebo_console_render_result_value

global nebo_g090_source_probe
global nebo_g090_negative_probe

section .data align=16
g90_dims: dq 1, 1
g90_schema: dq 1

section .bss align=16
g90_storage: resq NEBO_MAX_RENDER_NODES
g90_value: resb nebo_render_model_VALUE_SIZE
g90_tabular: resb NEBO_TABULAR_SIZE
g90_shape: resb NEBO_SHAPE_SIZE
g90_dynamic: resb NEBO_DYNAMIC_SIZE
g90_media: resb NEBO_MEDIA_SIZE
g90_request: resb NEBO_CONSOLE_RENDER_REQUEST_SIZE
g90_result: resb NEBO_CONSOLE_RENDER_RESULT_SIZE
g90_selected_value: resq 1

section .text
; EDI=mode 1..8, ESI=source-derived value 1..255 -> EAX=observed value.
nebo_g090_source_probe:
    push rbx
    push r12
    sub rsp, 8
    mov r12d, edi
    mov ebx, esi
    test ebx, ebx
    jz .failure
    cmp ebx, 255
    ja .failure
    cmp r12d, 1
    je .mode1
    cmp r12d, 2
    je .mode2
    cmp r12d, 3
    je .mode3
    cmp r12d, 4
    je .mode4
    cmp r12d, 5
    je .mode5
    cmp r12d, 6
    je .mode6
    cmp r12d, 7
    je .mode7
    cmp r12d, 8
    je .mode8
    jmp .failure

.mode1:
    mov qword [rel g90_value + NEBO_VALUE_TYPE_OFFSET], NEBO_TYPE_INT
    mov [rel g90_value + NEBO_VALUE_PAYLOAD_OFFSET], rbx
    mov qword [rel g90_value + NEBO_VALUE_AUX_OFFSET], 0
    mov qword [rel g90_value + NEBO_VALUE_FLAGS_OFFSET], 0
    lea rdi, [rel g90_value]
    mov esi, NEBO_TYPE_INT
    call g90_dispatch
    test rax, rax
    jz .failure
    cmp qword [rax + NEBO_CONSOLE_RENDER_RESULT_KIND_OFFSET], NEBO_CONSOLE_RENDERABLE_SCALAR
    jne .failure
    mov eax, [rax + NEBO_CONSOLE_RENDER_RESULT_NODE_OFFSET + NEBO_NODE_DATA_OFFSET]
    jmp .success_value

.mode2:
    mov [rel g90_storage], rbx
    mov qword [rel g90_value + NEBO_VALUE_TYPE_OFFSET], nebo_render_model_TYPE_TEXT
    lea rax, [rel g90_storage]
    mov [rel g90_value + NEBO_VALUE_PAYLOAD_OFFSET], rax
    mov [rel g90_value + NEBO_VALUE_AUX_OFFSET], rbx
    mov qword [rel g90_value + NEBO_VALUE_FLAGS_OFFSET], 0
    lea rdi, [rel g90_value]
    mov esi, nebo_render_model_TYPE_TEXT
    call g90_dispatch
    test rax, rax
    jz .failure
    cmp qword [rax + NEBO_CONSOLE_RENDER_RESULT_KIND_OFFSET], NEBO_CONSOLE_RENDERABLE_BUFFER
    jne .failure
    mov eax, [rax + NEBO_CONSOLE_RENDER_RESULT_NODE_OFFSET + NEBO_NODE_COUNT_OFFSET]
    jmp .success_value

.mode3:
    mov [rel g90_storage], rbx
    mov qword [rel g90_value + NEBO_VALUE_TYPE_OFFSET], NEBO_TYPE_LIST
    lea rax, [rel g90_storage]
    mov [rel g90_value + NEBO_VALUE_PAYLOAD_OFFSET], rax
    mov [rel g90_value + NEBO_VALUE_AUX_OFFSET], rbx
    mov qword [rel g90_value + NEBO_VALUE_FLAGS_OFFSET], 0
    lea rdi, [rel g90_value]
    mov esi, NEBO_TYPE_LIST
    call g90_dispatch
    test rax, rax
    jz .failure
    cmp qword [rax + NEBO_CONSOLE_RENDER_RESULT_KIND_OFFSET], NEBO_CONSOLE_RENDERABLE_COLLECTION
    jne .failure
    mov eax, [rax + NEBO_CONSOLE_RENDER_RESULT_NODE_OFFSET + NEBO_NODE_COUNT_OFFSET]
    jmp .success_value

.mode4:
    lea rax, [rel g90_storage]
    mov [rel g90_tabular + NEBO_TABULAR_DATA_OFFSET], rax
    mov qword [rel g90_tabular + NEBO_TABULAR_TYPE_OFFSET], NEBO_TYPE_TABLE
    mov [rel g90_tabular + NEBO_TABULAR_ROWS_OFFSET], rbx
    mov qword [rel g90_tabular + NEBO_TABULAR_COLUMNS_OFFSET], 1
    lea rax, [rel g90_schema]
    mov [rel g90_tabular + NEBO_TABULAR_SCHEMA_OFFSET], rax
    mov qword [rel g90_tabular + NEBO_TABULAR_FLAGS_OFFSET], 0
    lea rdi, [rel g90_tabular]
    mov esi, NEBO_TYPE_TABLE
    call g90_dispatch
    test rax, rax
    jz .failure
    cmp qword [rax + NEBO_CONSOLE_RENDER_RESULT_KIND_OFFSET], NEBO_CONSOLE_RENDERABLE_TABULAR
    jne .failure
    mov eax, [rax + NEBO_CONSOLE_RENDER_RESULT_NODE_OFFSET + NEBO_NODE_COUNT_OFFSET]
    jmp .success_value

.mode5:
    mov [rel g90_storage], rbx
    mov [rel g90_dims], rbx
    mov qword [rel g90_dims + 8], 1
    lea rax, [rel g90_storage]
    mov [rel g90_shape + NEBO_SHAPE_DATA_OFFSET], rax
    mov qword [rel g90_shape + NEBO_SHAPE_TYPE_OFFSET], NEBO_TYPE_MATRIX
    lea rax, [rel g90_dims]
    mov [rel g90_shape + NEBO_SHAPE_DIMS_OFFSET], rax
    mov qword [rel g90_shape + NEBO_SHAPE_RANK_OFFSET], 2
    mov [rel g90_shape + NEBO_SHAPE_ELEMENTS_OFFSET], rbx
    mov qword [rel g90_shape + NEBO_SHAPE_FLAGS_OFFSET], 0
    lea rdi, [rel g90_shape]
    mov esi, NEBO_TYPE_MATRIX
    call g90_dispatch
    test rax, rax
    jz .failure
    cmp qword [rax + NEBO_CONSOLE_RENDER_RESULT_KIND_OFFSET], NEBO_CONSOLE_RENDERABLE_NUMERIC_SHAPE
    jne .failure
    mov eax, [rax + NEBO_CONSOLE_RENDER_RESULT_NODE_OFFSET + NEBO_NODE_COUNT_OFFSET]
    jmp .success_value

.mode6:
    lea rax, [rel g90_storage]
    mov [rel g90_dynamic + NEBO_DYNAMIC_DATA_OFFSET], rax
    mov qword [rel g90_dynamic + NEBO_DYNAMIC_TYPE_OFFSET], NEBO_TYPE_STREAM
    mov [rel g90_dynamic + NEBO_DYNAMIC_COUNT_OFFSET], rbx
    mov qword [rel g90_dynamic + NEBO_DYNAMIC_DEPTH_OFFSET], 1
    mov [rel g90_dynamic + NEBO_DYNAMIC_SAMPLE_OFFSET], rbx
    mov qword [rel g90_dynamic + NEBO_DYNAMIC_FLAGS_OFFSET], 0
    lea rdi, [rel g90_dynamic]
    mov esi, NEBO_TYPE_STREAM
    call g90_dispatch
    test rax, rax
    jz .failure
    cmp qword [rax + NEBO_CONSOLE_RENDER_RESULT_KIND_OFFSET], NEBO_CONSOLE_RENDERABLE_DYNAMIC
    jne .failure
    mov eax, [rax + NEBO_CONSOLE_RENDER_RESULT_NODE_OFFSET + NEBO_NODE_COUNT_OFFSET]
    jmp .success_value

.mode7:
    lea rax, [rel g90_storage]
    mov [rel g90_media + NEBO_MEDIA_DATA_OFFSET], rax
    mov qword [rel g90_media + NEBO_MEDIA_TYPE_OFFSET], NEBO_TYPE_IMAGE
    mov [rel g90_media + NEBO_MEDIA_EXTENT_A_OFFSET], rbx
    mov qword [rel g90_media + NEBO_MEDIA_EXTENT_B_OFFSET], 1
    mov qword [rel g90_media + NEBO_MEDIA_METADATA_BYTES_OFFSET], 8
    mov qword [rel g90_media + NEBO_MEDIA_FLAGS_OFFSET], 0
    lea rdi, [rel g90_media]
    mov esi, NEBO_TYPE_IMAGE
    call g90_dispatch
    test rax, rax
    jz .failure
    cmp qword [rax + NEBO_CONSOLE_RENDER_RESULT_KIND_OFFSET], NEBO_CONSOLE_RENDERABLE_MEDIA_METADATA
    jne .failure
    mov eax, [rax + NEBO_CONSOLE_RENDER_RESULT_NODE_OFFSET + NEBO_NODE_COUNT_OFFSET]
    jmp .success_value

.mode8:
    mov qword [rel g90_value + NEBO_VALUE_TYPE_OFFSET], NEBO_TYPE_INT
    mov [rel g90_value + NEBO_VALUE_PAYLOAD_OFFSET], rbx
    mov qword [rel g90_value + NEBO_VALUE_AUX_OFFSET], 0
    mov qword [rel g90_value + NEBO_VALUE_FLAGS_OFFSET], 0
    lea rdi, [rel g90_value]
    mov esi, NEBO_TYPE_INT
    call g90_dispatch
    test rax, rax
    jz .failure
    mov rdi, rax
    lea rsi, [rel g90_selected_value]
    call nebo_console_render_result_value
    test eax, eax
    jnz .failure
    mov eax, [rel g90_selected_value]
    jmp .success_value

.success_value:
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

; RDI=value representation, RSI=canonical adapter TypeId -> RAX=result or 0.
g90_dispatch:
    push rbx
    push r12
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    mov [rel g90_request + NEBO_CONSOLE_RENDER_REQUEST_VALUE_OFFSET], rbx
    mov [rel g90_request + NEBO_CONSOLE_RENDER_REQUEST_TYPE_OFFSET], r12
    lea rdi, [rel g90_request]
    lea rsi, [rel g90_result]
    call nebo_console_renderable_adapt
    test eax, eax
    jnz .dispatch_failure
    cmp qword [rel g90_result + NEBO_CONSOLE_RENDER_RESULT_STATE_OFFSET], NEBO_CONSOLE_RENDER_RESULT_READY
    jne .dispatch_failure
    cmp [rel g90_result + NEBO_CONSOLE_RENDER_RESULT_TYPE_OFFSET], r12
    jne .dispatch_failure
    lea rax, [rel g90_result]
    jmp .dispatch_done
.dispatch_failure:
    xor eax, eax
.dispatch_done:
    add rsp, 8
    pop r12
    pop rbx
    ret

; EDI=case -> canonical error status for known-bad adapter requests.
nebo_g090_negative_probe:
    push rbx
    mov ebx, edi
    mov qword [rel g90_value + NEBO_VALUE_TYPE_OFFSET], NEBO_TYPE_INT
    mov qword [rel g90_value + NEBO_VALUE_PAYLOAD_OFFSET], 7
    mov qword [rel g90_value + NEBO_VALUE_AUX_OFFSET], 0
    mov qword [rel g90_value + NEBO_VALUE_FLAGS_OFFSET], 0
    mov qword [rel g90_request + NEBO_CONSOLE_RENDER_REQUEST_TYPE_OFFSET], NEBO_TYPE_INT
    cmp ebx, 1
    jne .negative_sensitive
    mov qword [rel g90_request + NEBO_CONSOLE_RENDER_REQUEST_TYPE_OFFSET], NEBO_TYPE_ML_ARTIFACT + 1
    jmp .negative_call
.negative_sensitive:
    cmp ebx, 2
    jne .negative_invalid
    mov qword [rel g90_value + NEBO_VALUE_FLAGS_OFFSET], NEBO_VALUE_SENSITIVE
    jmp .negative_call
.negative_invalid:
    mov qword [rel g90_value + NEBO_VALUE_TYPE_OFFSET], NEBO_TYPE_BOOL
    mov qword [rel g90_value + NEBO_VALUE_PAYLOAD_OFFSET], 2
    mov qword [rel g90_request + NEBO_CONSOLE_RENDER_REQUEST_TYPE_OFFSET], NEBO_TYPE_BOOL
.negative_call:
    lea rdi, [rel g90_result]
    mov rax, 0xaaaaaaaaaaaaaaaa
    mov ecx, NEBO_CONSOLE_RENDER_RESULT_SIZE / 8
    cld
    rep stosq
    lea rax, [rel g90_value]
    mov [rel g90_request + NEBO_CONSOLE_RENDER_REQUEST_VALUE_OFFSET], rax
    lea rdi, [rel g90_request]
    lea rsi, [rel g90_result]
    call nebo_console_renderable_adapt
    mov r8d, eax
    lea rdi, [rel g90_result]
    mov rax, 0xaaaaaaaaaaaaaaaa
    mov ecx, NEBO_CONSOLE_RENDER_RESULT_SIZE / 8
.negative_atomic:
    cmp [rdi], rax
    jne .negative_corrupt
    add rdi, 8
    loop .negative_atomic
    mov eax, r8d
    jmp .negative_done
.negative_corrupt:
    mov eax, 99
.negative_done:
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
