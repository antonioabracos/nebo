; Nebo Assembly — RENDER-MODEL-P02 canonical typed RenderNode adapters
bits 64
default rel
%include "runtime/render_model.inc"
global nebo_render_scalar
global nebo_render_buffer
global nebo_render_collection
global nebo_render_tabular
global nebo_render_numeric_shape
global nebo_render_dynamic
global nebo_render_media_metadata
global nebo_adapter_registry_validate
global nebo_adapter_lookup
section .text
; rdi=ConsoleValue, rsi=caller-owned RenderNode. Output is failure-atomic.
nebo_render_scalar:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    mov rax, [rdi + NEBO_VALUE_FLAGS_OFFSET]
    test rax, NEBO_VALUE_SENSITIVE
    jnz .privacy
    mov rcx, [rdi + NEBO_VALUE_TYPE_OFFSET]
    cmp rcx, NEBO_TYPE_INT
    jb .unsupported
    cmp rcx, nebo_render_model_TYPE_CHAR
    ja .unsupported
    mov rdx, [rdi + NEBO_VALUE_PAYLOAD_OFFSET]
    cmp rcx, NEBO_TYPE_BOOL
    jne .char
    cmp rdx, 1
    ja .invalid
.char:
    cmp rcx, nebo_render_model_TYPE_CHAR
    jne .commit
    cmp rdx, 0x10ffff
    ja .invalid
    cmp rdx, 0xd800
    jb .commit
    cmp rdx, 0xdfff
    jbe .invalid
.commit:
    mov qword [rsi + NEBO_NODE_KIND_OFFSET], NEBO_NODE_SCALAR
    mov [rsi + NEBO_NODE_TYPE_OFFSET], rcx
    mov [rsi + NEBO_NODE_DATA_OFFSET], rdx
    mov qword [rsi + NEBO_NODE_COUNT_OFFSET], 1
    mov rax, [rdi + NEBO_VALUE_AUX_OFFSET]
    mov [rsi + NEBO_NODE_AUX_OFFSET], rax
    mov qword [rsi + NEBO_NODE_FLAGS_OFFSET], 0
    xor eax, eax
    ret
.privacy:
    mov eax, NEBO_RENDER_PRIVACY
    ret
.unsupported:
    mov eax, NEBO_RENDER_UNSUPPORTED
    ret
.invalid:
    mov eax, NEBO_RENDER_INVALID
    ret

; Text and Bytes borrow a bounded slice; arbitrary memory is never inspected.
; rdi=ConsoleValue(payload=pointer, aux=byte length), rsi=RenderNode.
nebo_render_buffer:
    test rdi, rdi
    jz .buffer_invalid
    test rsi, rsi
    jz .buffer_invalid
    mov rax, [rdi + NEBO_VALUE_FLAGS_OFFSET]
    test rax, NEBO_VALUE_SENSITIVE
    jnz .buffer_privacy
    mov rcx, [rdi + NEBO_VALUE_TYPE_OFFSET]
    cmp rcx, nebo_render_model_TYPE_TEXT
    jb .buffer_unsupported
    cmp rcx, nebo_render_model_TYPE_BYTES
    ja .buffer_unsupported
    mov rdx, [rdi + NEBO_VALUE_AUX_OFFSET]
    cmp rdx, NEBO_MAX_RENDER_PAYLOAD
    ja .buffer_limit
    mov r8, [rdi + NEBO_VALUE_PAYLOAD_OFFSET]
    test rdx, rdx
    jz .buffer_commit
    test r8, r8
    jz .buffer_invalid
.buffer_commit:
    mov qword [rsi + NEBO_NODE_KIND_OFFSET], NEBO_NODE_BUFFER
    mov [rsi + NEBO_NODE_TYPE_OFFSET], rcx
    mov [rsi + NEBO_NODE_DATA_OFFSET], r8
    mov [rsi + NEBO_NODE_COUNT_OFFSET], rdx
    mov qword [rsi + NEBO_NODE_AUX_OFFSET], 0
    mov qword [rsi + NEBO_NODE_FLAGS_OFFSET], 0
    xor eax, eax
    ret
.buffer_privacy:
    mov eax, NEBO_RENDER_PRIVACY
    ret
.buffer_limit:
    mov eax, NEBO_RENDER_LIMIT
    ret
.buffer_unsupported:
    mov eax, NEBO_RENDER_UNSUPPORTED
    ret
.buffer_invalid:
    mov eax, NEBO_RENDER_INVALID
    ret

; Canonical collections are borrowed and bounded by node count.
nebo_render_collection:
    test rdi, rdi
    jz .collection_invalid
    test rsi, rsi
    jz .collection_invalid
    mov rax, [rdi + NEBO_VALUE_FLAGS_OFFSET]
    test rax, NEBO_VALUE_SENSITIVE
    jnz .collection_privacy
    mov rcx, [rdi + NEBO_VALUE_TYPE_OFFSET]
    cmp rcx, NEBO_TYPE_LIST
    jb .collection_unsupported
    cmp rcx, NEBO_TYPE_OBJECT
    ja .collection_unsupported
    mov rdx, [rdi + NEBO_VALUE_AUX_OFFSET]
    cmp rdx, NEBO_MAX_RENDER_NODES
    ja .collection_limit
    mov r8, [rdi + NEBO_VALUE_PAYLOAD_OFFSET]
    test rdx, rdx
    jz .collection_commit
    test r8, r8
    jz .collection_invalid
.collection_commit:
    mov qword [rsi + NEBO_NODE_KIND_OFFSET], NEBO_NODE_COLLECTION
    mov [rsi + NEBO_NODE_TYPE_OFFSET], rcx
    mov [rsi + NEBO_NODE_DATA_OFFSET], r8
    mov [rsi + NEBO_NODE_COUNT_OFFSET], rdx
    mov qword [rsi + NEBO_NODE_AUX_OFFSET], 0
    mov qword [rsi + NEBO_NODE_FLAGS_OFFSET], 0
    xor eax, eax
    ret
.collection_privacy:
    mov eax, NEBO_RENDER_PRIVACY
    ret
.collection_limit:
    mov eax, NEBO_RENDER_LIMIT
    ret
.collection_unsupported:
    mov eax, NEBO_RENDER_UNSUPPORTED
    ret
.collection_invalid:
    mov eax, NEBO_RENDER_INVALID
    ret

; rdi=bounded tabular request, rsi=RenderNode. Dataset sources stay lazy.
nebo_render_tabular:
    test rdi, rdi
    jz .tabular_invalid
    test rsi, rsi
    jz .tabular_invalid
    mov rax, [rdi + NEBO_TABULAR_FLAGS_OFFSET]
    test rax, NEBO_VALUE_SENSITIVE
    jnz .tabular_privacy
    mov rcx, [rdi + NEBO_TABULAR_TYPE_OFFSET]
    cmp rcx, NEBO_TYPE_ROW
    jb .tabular_unsupported
    cmp rcx, NEBO_TYPE_DATASET
    ja .tabular_unsupported
    mov rdx, [rdi + NEBO_TABULAR_ROWS_OFFSET]
    cmp rdx, NEBO_MAX_TABLE_ROWS
    ja .tabular_limit
    mov r8, [rdi + NEBO_TABULAR_COLUMNS_OFFSET]
    cmp r8, NEBO_MAX_TABLE_COLUMNS
    ja .tabular_limit
    mov rax, rdx
    imul rax, r8
    cmp rax, NEBO_MAX_RENDER_NODES
    ja .tabular_limit
    test r8, r8
    jz .tabular_empty
    cmp qword [rdi + NEBO_TABULAR_SCHEMA_OFFSET], 0
    je .tabular_schema
.tabular_empty:
    test rax, rax
    jz .tabular_commit
    cmp qword [rdi + NEBO_TABULAR_DATA_OFFSET], 0
    je .tabular_invalid
.tabular_commit:
    mov qword [rsi + NEBO_NODE_KIND_OFFSET], NEBO_NODE_TABULAR
    mov [rsi + NEBO_NODE_TYPE_OFFSET], rcx
    mov rax, [rdi + NEBO_TABULAR_DATA_OFFSET]
    mov [rsi + NEBO_NODE_DATA_OFFSET], rax
    mov [rsi + NEBO_NODE_COUNT_OFFSET], rdx
    mov [rsi + NEBO_NODE_AUX_OFFSET], r8
    mov rax, [rdi + NEBO_TABULAR_SCHEMA_OFFSET]
    mov [rsi + NEBO_NODE_FLAGS_OFFSET], rax
    xor eax, eax
    ret
.tabular_schema:
    mov eax, NEBO_RENDER_SCHEMA
    ret
.tabular_privacy:
    mov eax, NEBO_RENDER_PRIVACY
    ret
.tabular_limit:
    mov eax, NEBO_RENDER_LIMIT
    ret
.tabular_unsupported:
    mov eax, NEBO_RENDER_UNSUPPORTED
    ret
.tabular_invalid:
    mov eax, NEBO_RENDER_INVALID
    ret

; Validates canonical Vector/Matrix/Tensor shape without materializing data.
nebo_render_numeric_shape:
    test rdi, rdi
    jz .shape_invalid
    test rsi, rsi
    jz .shape_invalid
    mov rax, [rdi + NEBO_SHAPE_FLAGS_OFFSET]
    test rax, NEBO_VALUE_SENSITIVE
    jnz .shape_privacy
    mov rcx, [rdi + NEBO_SHAPE_TYPE_OFFSET]
    cmp rcx, NEBO_TYPE_VECTOR
    jb .shape_unsupported
    cmp rcx, NEBO_TYPE_TENSOR
    ja .shape_unsupported
    mov r8, [rdi + NEBO_SHAPE_RANK_OFFSET]
    test r8, r8
    jz .shape_schema
    cmp r8, NEBO_MAX_TENSOR_RANK
    ja .shape_limit
    cmp rcx, NEBO_TYPE_VECTOR
    jne .shape_matrix
    cmp r8, 1
    jne .shape_schema
.shape_matrix:
    cmp rcx, NEBO_TYPE_MATRIX
    jne .shape_pointers
    cmp r8, 2
    jne .shape_schema
.shape_pointers:
    mov r9, [rdi + NEBO_SHAPE_DIMS_OFFSET]
    test r9, r9
    jz .shape_invalid
    mov r10, [rdi + NEBO_SHAPE_ELEMENTS_OFFSET]
    test r10, r10
    jz .shape_schema
    cmp r10, NEBO_MAX_RENDER_NODES
    ja .shape_limit
    cmp qword [rdi + NEBO_SHAPE_DATA_OFFSET], 0
    je .shape_invalid
    mov rax, 1
    xor edx, edx
.shape_product:
    cmp rdx, r8
    jae .shape_compare
    mov r11, [r9 + rdx * 8]
    test r11, r11
    jz .shape_schema
    imul rax, r11
    cmp rax, NEBO_MAX_RENDER_NODES
    ja .shape_limit
    inc rdx
    jmp .shape_product
.shape_compare:
    cmp rax, r10
    jne .shape_schema
    mov qword [rsi + NEBO_NODE_KIND_OFFSET], NEBO_NODE_NUMERIC_SHAPE
    mov [rsi + NEBO_NODE_TYPE_OFFSET], rcx
    mov rax, [rdi + NEBO_SHAPE_DATA_OFFSET]
    mov [rsi + NEBO_NODE_DATA_OFFSET], rax
    mov [rsi + NEBO_NODE_COUNT_OFFSET], r10
    mov [rsi + NEBO_NODE_AUX_OFFSET], r8
    mov [rsi + NEBO_NODE_FLAGS_OFFSET], r9
    xor eax, eax
    ret
.shape_privacy:
    mov eax, NEBO_RENDER_PRIVACY
    ret
.shape_schema:
    mov eax, NEBO_RENDER_SCHEMA
    ret
.shape_limit:
    mov eax, NEBO_RENDER_LIMIT
    ret
.shape_unsupported:
    mov eax, NEBO_RENDER_UNSUPPORTED
    ret
.shape_invalid:
    mov eax, NEBO_RENDER_INVALID
    ret

; Graph/Tree/Event/Stream adapters require explicit node, depth and sample bounds.
nebo_render_dynamic:
    test rdi, rdi
    jz .dynamic_invalid
    test rsi, rsi
    jz .dynamic_invalid
    mov rax, [rdi + NEBO_DYNAMIC_FLAGS_OFFSET]
    test rax, NEBO_VALUE_SENSITIVE
    jnz .dynamic_privacy
    mov rcx, [rdi + NEBO_DYNAMIC_TYPE_OFFSET]
    cmp rcx, NEBO_TYPE_GRAPH
    jb .dynamic_unsupported
    cmp rcx, NEBO_TYPE_STREAM
    ja .dynamic_unsupported
    mov rdx, [rdi + NEBO_DYNAMIC_COUNT_OFFSET]
    cmp rdx, NEBO_MAX_RENDER_NODES
    ja .dynamic_limit
    mov r8, [rdi + NEBO_DYNAMIC_DEPTH_OFFSET]
    cmp r8, NEBO_MAX_RENDER_DEPTH
    ja .dynamic_limit
    test rdx, rdx
    jz .dynamic_kind
    cmp qword [rdi + NEBO_DYNAMIC_DATA_OFFSET], 0
    je .dynamic_invalid
.dynamic_kind:
    cmp rcx, NEBO_TYPE_EVENT
    jne .dynamic_stream
    cmp rdx, 1
    ja .dynamic_schema
.dynamic_stream:
    mov r9, [rdi + NEBO_DYNAMIC_SAMPLE_OFFSET]
    cmp rcx, NEBO_TYPE_STREAM
    jne .dynamic_commit
    test r9, r9
    jz .dynamic_schema
    cmp r9, NEBO_MAX_RENDER_NODES
    ja .dynamic_limit
    cmp rdx, r9
    jbe .dynamic_commit
    mov rdx, r9
.dynamic_commit:
    mov qword [rsi + NEBO_NODE_KIND_OFFSET], NEBO_NODE_DYNAMIC
    mov [rsi + NEBO_NODE_TYPE_OFFSET], rcx
    mov rax, [rdi + NEBO_DYNAMIC_DATA_OFFSET]
    mov [rsi + NEBO_NODE_DATA_OFFSET], rax
    mov [rsi + NEBO_NODE_COUNT_OFFSET], rdx
    mov [rsi + NEBO_NODE_AUX_OFFSET], r8
    mov [rsi + NEBO_NODE_FLAGS_OFFSET], r9
    xor eax, eax
    ret
.dynamic_privacy:
    mov eax, NEBO_RENDER_PRIVACY
    ret
.dynamic_schema:
    mov eax, NEBO_RENDER_SCHEMA
    ret
.dynamic_limit:
    mov eax, NEBO_RENDER_LIMIT
    ret
.dynamic_unsupported:
    mov eax, NEBO_RENDER_UNSUPPORTED
    ret
.dynamic_invalid:
    mov eax, NEBO_RENDER_INVALID
    ret

; Media/ML adaptation publishes bounded metadata only, never raw payload copies.
nebo_render_media_metadata:
    test rdi, rdi
    jz .media_invalid
    test rsi, rsi
    jz .media_invalid
    mov rax, [rdi + NEBO_MEDIA_FLAGS_OFFSET]
    test rax, NEBO_VALUE_SENSITIVE
    jnz .media_privacy
    mov rcx, [rdi + NEBO_MEDIA_TYPE_OFFSET]
    cmp rcx, NEBO_TYPE_IMAGE
    jb .media_unsupported
    cmp rcx, NEBO_TYPE_ML_ARTIFACT
    ja .media_unsupported
    cmp qword [rdi + NEBO_MEDIA_DATA_OFFSET], 0
    je .media_invalid
    mov rdx, [rdi + NEBO_MEDIA_METADATA_BYTES_OFFSET]
    cmp rdx, NEBO_MAX_RENDER_PAYLOAD
    ja .media_limit
    mov r8, [rdi + NEBO_MEDIA_EXTENT_A_OFFSET]
    mov r9, [rdi + NEBO_MEDIA_EXTENT_B_OFFSET]
    test r8, r8
    jz .media_schema
    cmp rcx, NEBO_TYPE_ML_MODEL
    jae .media_commit
    test r9, r9
    jz .media_schema
    mov rax, r8
    mul r9
    test rdx, rdx
    jnz .media_limit
    cmp rax, NEBO_MAX_RENDER_OUTPUT
    ja .media_limit
.media_commit:
    mov qword [rsi + NEBO_NODE_KIND_OFFSET], NEBO_NODE_MEDIA_METADATA
    mov [rsi + NEBO_NODE_TYPE_OFFSET], rcx
    mov rax, [rdi + NEBO_MEDIA_DATA_OFFSET]
    mov [rsi + NEBO_NODE_DATA_OFFSET], rax
    mov [rsi + NEBO_NODE_COUNT_OFFSET], r8
    mov [rsi + NEBO_NODE_AUX_OFFSET], r9
    mov rax, [rdi + NEBO_MEDIA_METADATA_BYTES_OFFSET]
    mov [rsi + NEBO_NODE_FLAGS_OFFSET], rax
    xor eax, eax
    ret
.media_privacy:
    mov eax, NEBO_RENDER_PRIVACY
    ret
.media_schema:
    mov eax, NEBO_RENDER_SCHEMA
    ret
.media_limit:
    mov eax, NEBO_RENDER_LIMIT
    ret
.media_unsupported:
    mov eax, NEBO_RENDER_UNSUPPORTED
    ret
.media_invalid:
    mov eax, NEBO_RENDER_INVALID
    ret

; Registry is closed over stable TypeId/schema rows and rejects secret adapters.
nebo_adapter_registry_validate:
    test rdi, rdi
    jz .registry_invalid
    test rsi, rsi
    jz .registry_invalid
    mov rcx, [rdi + NEBO_REGISTRY_COUNT_OFFSET]
    test rcx, rcx
    jz .registry_schema
    cmp rcx, NEBO_MAX_ADAPTERS
    ja .registry_limit
    mov rdx, [rdi + NEBO_REGISTRY_ENTRIES_OFFSET]
    test rdx, rdx
    jz .registry_invalid
    mov rax, 0xcbf29ce484222325
    mov r11, 0x100000001b3
    xor r8d, r8d
    xor r9d, r9d
.registry_loop:
    cmp r8, rcx
    jae .registry_commit
    mov r10, r8
    shl r10, 5
    add r10, rdx
    mov rdi, [r10 + NEBO_ADAPTER_TYPE_OFFSET]
    test rdi, rdi
    jz .registry_schema
    cmp rdi, NEBO_TYPE_ML_ARTIFACT
    ja .registry_unsupported
    cmp rdi, r9
    jbe .registry_schema
    mov r9, rdi
    cmp qword [r10 + NEBO_ADAPTER_FUNCTION_OFFSET], 0
    je .registry_schema
    mov rdi, [r10 + NEBO_ADAPTER_SCHEMA_OFFSET]
    test rdi, rdi
    jz .registry_schema
    mov rdi, [r10 + NEBO_ADAPTER_FLAGS_OFFSET]
    test rdi, NEBO_ADAPTER_SENSITIVE
    jnz .registry_privacy
    cmp rdi, NEBO_ADAPTER_SAFE
    jne .registry_schema
    xor rax, r9
    imul rax, r11
    xor rax, [r10 + NEBO_ADAPTER_SCHEMA_OFFSET]
    imul rax, r11
    inc r8
    jmp .registry_loop
.registry_commit:
    mov [rsi + NEBO_REGISTRY_RECEIPT_COUNT_OFFSET], rcx
    mov [rsi + NEBO_REGISTRY_RECEIPT_DIGEST_OFFSET], rax
    mov qword [rsi + NEBO_REGISTRY_RECEIPT_STATE_OFFSET], NEBO_REGISTRY_READY
    xor eax, eax
    ret
.registry_privacy:
    mov eax, NEBO_RENDER_PRIVACY
    ret
.registry_schema:
    mov eax, NEBO_RENDER_SCHEMA
    ret
.registry_limit:
    mov eax, NEBO_RENDER_LIMIT
    ret
.registry_unsupported:
    mov eax, NEBO_RENDER_UNSUPPORTED
    ret
.registry_invalid:
    mov eax, NEBO_RENDER_INVALID
    ret

; rdi=entries, rsi=count, rdx=TypeId, rcx=out entry pointer.
nebo_adapter_lookup:
    test rdi, rdi
    jz .lookup_invalid
    test rcx, rcx
    jz .lookup_invalid
    test rsi, rsi
    jz .lookup_unsupported
    cmp rsi, NEBO_MAX_ADAPTERS
    ja .lookup_limit
    xor r8d, r8d
.lookup_loop:
    cmp r8, rsi
    jae .lookup_unsupported
    mov rax, r8
    shl rax, 5
    add rax, rdi
    cmp [rax + NEBO_ADAPTER_TYPE_OFFSET], rdx
    je .lookup_commit
    inc r8
    jmp .lookup_loop
.lookup_commit:
    mov [rcx], rax
    xor eax, eax
    ret
.lookup_limit:
    mov eax, NEBO_RENDER_LIMIT
    ret
.lookup_unsupported:
    mov eax, NEBO_RENDER_UNSUPPORTED
    ret
.lookup_invalid:
    mov eax, NEBO_RENDER_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
