; G090 closed TypeId/schema adapter registry and failure-atomic dispatch.
bits 64
default rel
%include "runtime/render_model.inc"
%include "runtime/console_renderable.inc"

extern nebo_render_scalar
extern nebo_render_buffer
extern nebo_render_collection
extern nebo_render_tabular
extern nebo_render_numeric_shape
extern nebo_render_dynamic
extern nebo_render_media_metadata
extern nebo_adapter_registry_validate
extern nebo_adapter_lookup

global nebo_console_renderable_registry
global nebo_console_renderable_adapt
global nebo_console_render_result_value

section .data.rel.ro align=16
%macro G90_ADAPTER 3
    dq %1, %2, %3, NEBO_ADAPTER_SAFE
%endmacro
g90_builtin_adapters:
    G90_ADAPTER NEBO_TYPE_INT, nebo_render_scalar, 0x9001
    G90_ADAPTER NEBO_TYPE_FLOAT, nebo_render_scalar, 0x9002
    G90_ADAPTER NEBO_TYPE_BOOL, nebo_render_scalar, 0x9003
    G90_ADAPTER nebo_render_model_TYPE_CHAR, nebo_render_scalar, 0x9004
    G90_ADAPTER nebo_render_model_TYPE_TEXT, nebo_render_buffer, 0x9005
    G90_ADAPTER nebo_render_model_TYPE_BYTES, nebo_render_buffer, 0x9006
    G90_ADAPTER NEBO_TYPE_LIST, nebo_render_collection, 0x9007
    G90_ADAPTER NEBO_TYPE_TUPLE, nebo_render_collection, 0x9008
    G90_ADAPTER NEBO_TYPE_ARRAY, nebo_render_collection, 0x9009
    G90_ADAPTER NEBO_TYPE_DICT, nebo_render_collection, 0x900a
    G90_ADAPTER NEBO_TYPE_SET, nebo_render_collection, 0x900b
    G90_ADAPTER NEBO_TYPE_OBJECT, nebo_render_collection, 0x900c
    G90_ADAPTER NEBO_TYPE_ROW, nebo_render_tabular, 0x900d
    G90_ADAPTER NEBO_TYPE_COLUMN, nebo_render_tabular, 0x900e
    G90_ADAPTER NEBO_TYPE_TABLE, nebo_render_tabular, 0x900f
    G90_ADAPTER NEBO_TYPE_DATASET, nebo_render_tabular, 0x9010
    G90_ADAPTER NEBO_TYPE_VECTOR, nebo_render_numeric_shape, 0x9011
    G90_ADAPTER NEBO_TYPE_MATRIX, nebo_render_numeric_shape, 0x9012
    G90_ADAPTER NEBO_TYPE_TENSOR, nebo_render_numeric_shape, 0x9013
    G90_ADAPTER NEBO_TYPE_GRAPH, nebo_render_dynamic, 0x9014
    G90_ADAPTER NEBO_TYPE_TREE, nebo_render_dynamic, 0x9015
    G90_ADAPTER NEBO_TYPE_EVENT, nebo_render_dynamic, 0x9016
    G90_ADAPTER NEBO_TYPE_STREAM, nebo_render_dynamic, 0x9017
    G90_ADAPTER NEBO_TYPE_IMAGE, nebo_render_media_metadata, 0x9018
    G90_ADAPTER NEBO_TYPE_AUDIO, nebo_render_media_metadata, 0x9019
    G90_ADAPTER NEBO_TYPE_VIDEO, nebo_render_media_metadata, 0x901a
    G90_ADAPTER NEBO_TYPE_ML_MODEL, nebo_render_media_metadata, 0x901b
    G90_ADAPTER NEBO_TYPE_ML_ARTIFACT, nebo_render_media_metadata, 0x901c
g90_builtin_adapters_end:
%undef G90_ADAPTER

section .text
; rdi=out registry, rsi=out receipt. Both outputs are published only after the
; immutable built-in registry has passed the canonical validator.
nebo_console_renderable_registry:
    test rdi, rdi
    jz .registry_invalid_direct
    test rsi, rsi
    jz .registry_invalid_direct
    push rbx
    push r12
    push r13
    sub rsp, 48
    mov r12, rdi
    mov r13, rsi
    lea rax, [rel g90_builtin_adapters]
    mov [rsp + NEBO_REGISTRY_ENTRIES_OFFSET], rax
    mov qword [rsp + NEBO_REGISTRY_COUNT_OFFSET], NEBO_CONSOLE_RENDERABLE_BUILTIN_COUNT
    lea rdi, [rsp]
    lea rsi, [rsp + NEBO_REGISTRY_SIZE]
    call nebo_adapter_registry_validate
    test eax, eax
    jnz .registry_done
    mov rax, [rsp + NEBO_REGISTRY_ENTRIES_OFFSET]
    mov [r12 + NEBO_REGISTRY_ENTRIES_OFFSET], rax
    mov rax, [rsp + NEBO_REGISTRY_COUNT_OFFSET]
    mov [r12 + NEBO_REGISTRY_COUNT_OFFSET], rax
    mov rax, [rsp + NEBO_REGISTRY_SIZE + NEBO_REGISTRY_RECEIPT_COUNT_OFFSET]
    mov [r13 + NEBO_REGISTRY_RECEIPT_COUNT_OFFSET], rax
    mov rax, [rsp + NEBO_REGISTRY_SIZE + NEBO_REGISTRY_RECEIPT_DIGEST_OFFSET]
    mov [r13 + NEBO_REGISTRY_RECEIPT_DIGEST_OFFSET], rax
    mov rax, [rsp + NEBO_REGISTRY_SIZE + NEBO_REGISTRY_RECEIPT_STATE_OFFSET]
    mov [r13 + NEBO_REGISTRY_RECEIPT_STATE_OFFSET], rax
    xor eax, eax
.registry_done:
    add rsp, 48
    pop r13
    pop r12
    pop rbx
    ret
.registry_invalid_direct:
    mov eax, NEBO_RENDER_INVALID
    ret

; rdi=ConsoleRenderable request, rsi=caller-owned ConsoleRenderResult.
; Validation and adapter execution use local storage, so any failure leaves the
; destination result byte-identical.
nebo_console_renderable_adapt:
    test rdi, rdi
    jz .adapt_invalid_direct
    test rsi, rsi
    jz .adapt_invalid_direct
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 96
    mov r12, rdi
    mov r13, rsi
    mov r14, [r12 + NEBO_CONSOLE_RENDER_REQUEST_VALUE_OFFSET]
    mov r15, [r12 + NEBO_CONSOLE_RENDER_REQUEST_TYPE_OFFSET]
    test r14, r14
    jz .adapt_invalid
    cmp r15, NEBO_TYPE_INT
    jb .adapt_unsupported
    cmp r15, NEBO_TYPE_ML_ARTIFACT
    ja .adapt_unsupported
    mov rax, [r14 + NEBO_VALUE_TYPE_OFFSET]
    cmp r15, NEBO_TYPE_OBJECT
    jbe .adapt_type_ready
    mov rax, [r14 + 8]
.adapt_type_ready:
    cmp rax, r15
    jne .adapt_invalid
    lea rdi, [rsp]
    lea rsi, [rsp + 16]
    call nebo_console_renderable_registry
    test eax, eax
    jnz .adapt_done
    mov rdi, [rsp + NEBO_REGISTRY_ENTRIES_OFFSET]
    mov rsi, [rsp + NEBO_REGISTRY_COUNT_OFFSET]
    mov rdx, r15
    lea rcx, [rsp + 40]
    call nebo_adapter_lookup
    test eax, eax
    jnz .adapt_done
    mov rbx, [rsp + 40]
    cmp qword [rbx + NEBO_ADAPTER_TYPE_OFFSET], r15
    jne .adapt_invalid
    cmp qword [rbx + NEBO_ADAPTER_FLAGS_OFFSET], NEBO_ADAPTER_SAFE
    jne .adapt_privacy
    mov rax, [rbx + NEBO_ADAPTER_FUNCTION_OFFSET]
    test rax, rax
    jz .adapt_invalid
    mov rdi, r14
    lea rsi, [rsp + 48]
    call rax
    test eax, eax
    jnz .adapt_done
    cmp [rsp + 48 + NEBO_NODE_TYPE_OFFSET], r15
    jne .adapt_invalid
    mov rax, [rsp + 48 + NEBO_NODE_KIND_OFFSET]
    cmp rax, NEBO_CONSOLE_RENDERABLE_SCALAR
    jb .adapt_invalid
    cmp rax, NEBO_CONSOLE_RENDERABLE_MEDIA_METADATA
    ja .adapt_invalid
    mov rcx, [rsp + 48 + 0]
    mov [r13 + NEBO_CONSOLE_RENDER_RESULT_NODE_OFFSET + 0], rcx
    mov rcx, [rsp + 48 + 8]
    mov [r13 + NEBO_CONSOLE_RENDER_RESULT_NODE_OFFSET + 8], rcx
    mov rcx, [rsp + 48 + 16]
    mov [r13 + NEBO_CONSOLE_RENDER_RESULT_NODE_OFFSET + 16], rcx
    mov rcx, [rsp + 48 + 24]
    mov [r13 + NEBO_CONSOLE_RENDER_RESULT_NODE_OFFSET + 24], rcx
    mov rcx, [rsp + 48 + 32]
    mov [r13 + NEBO_CONSOLE_RENDER_RESULT_NODE_OFFSET + 32], rcx
    mov rcx, [rsp + 48 + 40]
    mov [r13 + NEBO_CONSOLE_RENDER_RESULT_NODE_OFFSET + 40], rcx
    mov [r13 + NEBO_CONSOLE_RENDER_RESULT_TYPE_OFFSET], r15
    mov [r13 + NEBO_CONSOLE_RENDER_RESULT_KIND_OFFSET], rax
    mov rcx, [rbx + NEBO_ADAPTER_SCHEMA_OFFSET]
    mov [r13 + NEBO_CONSOLE_RENDER_RESULT_SCHEMA_OFFSET], rcx
    mov qword [r13 + NEBO_CONSOLE_RENDER_RESULT_STATUS_OFFSET], NEBO_RENDER_OK
    mov qword [r13 + NEBO_CONSOLE_RENDER_RESULT_STATE_OFFSET], NEBO_CONSOLE_RENDER_RESULT_READY
    xor eax, eax
    jmp .adapt_done
.adapt_privacy:
    mov eax, NEBO_RENDER_PRIVACY
    jmp .adapt_done
.adapt_unsupported:
    mov eax, NEBO_RENDER_UNSUPPORTED
    jmp .adapt_done
.adapt_invalid:
    mov eax, NEBO_RENDER_INVALID
.adapt_done:
    add rsp, 96
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.adapt_invalid_direct:
    mov eax, NEBO_RENDER_INVALID
    ret

; Contextual `.value(...)` selector over a successful scalar render result.
; rdi=result, rsi=out value.
nebo_console_render_result_value:
    test rdi, rdi
    jz .value_invalid
    test rsi, rsi
    jz .value_invalid
    cmp qword [rdi + NEBO_CONSOLE_RENDER_RESULT_STATE_OFFSET], NEBO_CONSOLE_RENDER_RESULT_READY
    jne .value_invalid
    cmp qword [rdi + NEBO_CONSOLE_RENDER_RESULT_STATUS_OFFSET], NEBO_RENDER_OK
    jne .value_invalid
    cmp qword [rdi + NEBO_CONSOLE_RENDER_RESULT_KIND_OFFSET], NEBO_CONSOLE_RENDERABLE_SCALAR
    jne .value_unsupported
    mov rax, [rdi + NEBO_CONSOLE_RENDER_RESULT_NODE_OFFSET + NEBO_NODE_DATA_OFFSET]
    mov [rsi], rax
    xor eax, eax
    ret
.value_unsupported:
    mov eax, NEBO_RENDER_UNSUPPORTED
    ret
.value_invalid:
    mov eax, NEBO_RENDER_INVALID
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
