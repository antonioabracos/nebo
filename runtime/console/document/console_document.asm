; Nebo retained-mode ConsoleDocument — MF043
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/handles/console_handle.inc"
%include "runtime/console/queues/console_queue.inc"
%include "runtime/console/document/console_document.inc"
%include "runtime/console/input/routing/scan_routing.inc"
%include "runtime/console/renderers/basic/basic_renderer.inc"

global nebo_console_document_init
global nebo_console_document_validate
global nebo_console_document_node_from_id
global nebo_console_document_append_text
global nebo_console_document_append_newline
global nebo_console_document_append_int
global nebo_console_document_append_bool
global nebo_console_document_set_behavior_set
global nebo_console_document_append_scan
global nebo_console_document_apply_command
global nebo_console_document_audit_links
global nebo_console_document_copy_plain_text
global nebo_console_document_state_hash

%macro NEBO_DOCUMENT_HASH_QWORD 1
    mov rdx, %1
    mov ecx, 8
%%mix_loop:
    xor al, dl
    imul rax, rax, NEBO_CONSOLE_DOCUMENT_HASH_FNV1A32_PRIME
    shr rdx, 8
    dec ecx
    jnz %%mix_loop
%endmacro

section .text

; Internal failure publisher. RDI=document*, ESI=status, EDX=error.
nebo_console_document_set_failure_internal:
    test rdi, rdi
    jz .failure_return
    mov [rdi+NEBO_CONSOLE_DOCUMENT_LAST_STATUS_OFFSET], rsi
    mov [rdi+NEBO_CONSOLE_DOCUMENT_LAST_ERROR_OFFSET], rdx
.failure_return:
    mov eax, esi
    ret

; node_from_id(document*, NodeId, out_node**) -> status
nebo_console_document_node_from_id:
    test rdx, rdx
    jz .node_invalid
    mov qword [rdx], 0
    test rdi, rdi
    jz .node_invalid
    test rsi, rsi
    jz .node_invalid
    cmp rsi, [rdi+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET]
    ja .node_invalid
    mov rax, rsi
    dec rax
    imul rax, NEBO_CONSOLE_NODE_HEADER_SIZE
    add rax, [rdi+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET]
    test rax, rax
    jz .node_invalid
    cmp [rax+NEBO_CONSOLE_NODE_ID_OFFSET], rsi
    jne .node_state
    mov [rdx], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.node_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.node_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; document_init(document*, handle, node_store*, node_capacity,
;               text_store*, text_capacity) -> status
nebo_console_document_init:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov [rsp], r8
    mov [rsp+8], r9
    test r12, r12
    jz .init_invalid_no_document
    mov rdi, r12
    xor eax, eax
    mov ecx, NEBO_CONSOLE_DOCUMENT_QWORDS
    cld
    rep stosq
    test r13, r13
    jz .init_invalid
    test r14, r14
    jz .init_invalid
    test r15, r15
    jz .init_invalid
    cmp r15, NEBO_CONSOLE_MAX_NODES_PER_CONSOLE
    ja .init_node_limit
    cmp qword [rsp], 0
    je .init_invalid
    cmp qword [rsp+8], 0
    je .init_invalid
    cmp qword [rsp+8], NEBO_CONSOLE_MAX_TEXT_BYTES_PER_CONSOLE
    ja .init_text_limit

    mov rdi, r14
    xor eax, eax
    mov ecx, NEBO_CONSOLE_NODE_HEADER_QWORDS
    cld
    rep stosq
    mov qword [r14+NEBO_CONSOLE_NODE_ID_OFFSET], 1
    mov dword [r14+NEBO_CONSOLE_NODE_KIND_OFFSET], NEBO_CONSOLE_NODE_KIND_ROOT
    mov dword [r14+NEBO_CONSOLE_NODE_FLAGS_OFFSET], NEBO_CONSOLE_NODE_FLAG_LIVE | NEBO_CONSOLE_NODE_FLAG_ATOMIC_COMMIT
    mov dword [r14+NEBO_CONSOLE_NODE_SEMANTIC_ROLE_OFFSET], NEBO_CONSOLE_SEMANTIC_ROLE_ROOT
    mov qword [r14+NEBO_CONSOLE_NODE_ORDER_OFFSET], 0

    mov [r12+NEBO_CONSOLE_DOCUMENT_HANDLE_OFFSET], r13
    mov [r12+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET], r14
    mov [r12+NEBO_CONSOLE_DOCUMENT_NODE_CAPACITY_OFFSET], r15
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET], 1
    mov rax, [rsp]
    mov [r12+NEBO_CONSOLE_DOCUMENT_TEXT_STORE_PTR_OFFSET], rax
    mov rax, [rsp+8]
    mov [r12+NEBO_CONSOLE_DOCUMENT_TEXT_CAPACITY_OFFSET], rax
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_TEXT_LENGTH_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_ROOT_ID_OFFSET], 1
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_CURSOR_CONTAINER_ID_OFFSET], 1
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_CURSOR_CURRENT_LINE_ID_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_CURSOR_AFTER_NODE_ID_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_CURSOR_INLINE_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_CURSOR_MODE_OFFSET], NEBO_CONSOLE_CURSOR_MODE_INLINE
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_REVISION_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_DIRTY_REVISION_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_FLAGS_OFFSET], NEBO_CONSOLE_DOCUMENT_REQUIRED_FLAGS
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_LAST_ERROR_OFFSET], NEBO_CONSOLE_DOCUMENT_ERROR_NONE
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_TRANSACTION_SEQUENCE_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_COMMITTED_NODES_OFFSET], 1
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_COMMITTED_TEXT_BYTES_OFFSET], 0
    mov eax, NEBO_CONSOLE_DOCUMENT_HASH_FNV1A32_OFFSET_BASIS
    mov [r12+NEBO_CONSOLE_DOCUMENT_STATE_HASH_OFFSET], rax
    mov rdi, r12
    lea rsi, [r12+NEBO_CONSOLE_DOCUMENT_STATE_HASH_OFFSET]
    call nebo_console_document_state_hash
    jmp .init_done
.init_node_limit:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_NODE_LIMIT
    call nebo_console_document_set_failure_internal
    jmp .init_done
.init_text_limit:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_TEXT_LIMIT
    call nebo_console_document_set_failure_internal
    jmp .init_done
.init_invalid:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_BAD_ARGUMENT
    call nebo_console_document_set_failure_internal
    jmp .init_done
.init_invalid_no_document:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.init_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; document_validate(document*) -> status
nebo_console_document_validate:
    test rdi, rdi
    jz .validate_invalid
    cmp qword [rdi+NEBO_CONSOLE_DOCUMENT_HANDLE_OFFSET], 0
    je .validate_invalid
    cmp qword [rdi+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET], 0
    je .validate_invalid
    mov rax, [rdi+NEBO_CONSOLE_DOCUMENT_NODE_CAPACITY_OFFSET]
    test rax, rax
    jz .validate_invalid
    cmp rax, NEBO_CONSOLE_MAX_NODES_PER_CONSOLE
    ja .validate_state
    mov rcx, [rdi+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET]
    test rcx, rcx
    jz .validate_state
    cmp rcx, rax
    ja .validate_state
    cmp qword [rdi+NEBO_CONSOLE_DOCUMENT_TEXT_STORE_PTR_OFFSET], 0
    je .validate_invalid
    mov rax, [rdi+NEBO_CONSOLE_DOCUMENT_TEXT_CAPACITY_OFFSET]
    test rax, rax
    jz .validate_invalid
    cmp rax, NEBO_CONSOLE_MAX_TEXT_BYTES_PER_CONSOLE
    ja .validate_state
    cmp [rdi+NEBO_CONSOLE_DOCUMENT_TEXT_LENGTH_OFFSET], rax
    ja .validate_state
    cmp qword [rdi+NEBO_CONSOLE_DOCUMENT_ROOT_ID_OFFSET], 1
    jne .validate_state
    cmp qword [rdi+NEBO_CONSOLE_DOCUMENT_CURSOR_CONTAINER_ID_OFFSET], 1
    jne .validate_state
    mov rax, [rdi+NEBO_CONSOLE_DOCUMENT_FLAGS_OFFSET]
    and rax, NEBO_CONSOLE_DOCUMENT_REQUIRED_FLAGS
    cmp rax, NEBO_CONSOLE_DOCUMENT_REQUIRED_FLAGS
    jne .validate_state
    mov rax, [rdi+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET]
    cmp qword [rax+NEBO_CONSOLE_NODE_ID_OFFSET], 1
    jne .validate_state
    cmp dword [rax+NEBO_CONSOLE_NODE_KIND_OFFSET], NEBO_CONSOLE_NODE_KIND_ROOT
    jne .validate_state
    cmp qword [rax+NEBO_CONSOLE_NODE_PARENT_ID_OFFSET], 0
    jne .validate_state
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.validate_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.validate_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; Internal pre-commit revision/transaction overflow guard. RDI=document*.
nebo_console_document_can_commit_internal:
    mov rax, [rdi+NEBO_CONSOLE_DOCUMENT_REVISION_OFFSET]
    inc rax
    jz .can_commit_limit
    mov rax, [rdi+NEBO_CONSOLE_DOCUMENT_TRANSACTION_SEQUENCE_OFFSET]
    inc rax
    jz .can_commit_limit
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.can_commit_limit:
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    ret

; Internal node append. All capacities and input bytes are prevalidated.
; RDI=document*, RSI=data*, RDX=length, ECX=kind, R8D=semantic role.
; Returns the new NodeId in RAX and cannot fail under the preconditions.
nebo_console_document_commit_node_internal:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15d, ecx
    mov [rsp], r8
    mov rax, [r12+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET]
    inc rax
    mov [rsp+8], rax
    mov rbx, rax
    dec rbx
    imul rbx, NEBO_CONSOLE_NODE_HEADER_SIZE
    add rbx, [r12+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET]
    mov rdi, rbx
    xor eax, eax
    mov ecx, NEBO_CONSOLE_NODE_HEADER_QWORDS
    cld
    rep stosq
    mov rax, [rsp+8]
    mov [rbx+NEBO_CONSOLE_NODE_ID_OFFSET], rax
    mov [rbx+NEBO_CONSOLE_NODE_KIND_OFFSET], r15d
    mov eax, NEBO_CONSOLE_NODE_FLAG_LIVE | NEBO_CONSOLE_NODE_FLAG_DIRTY | NEBO_CONSOLE_NODE_FLAG_ATOMIC_COMMIT
    test r14, r14
    jz .commit_flags_ready
    or eax, NEBO_CONSOLE_NODE_FLAG_OWNED_TEXT
.commit_flags_ready:
    mov [rbx+NEBO_CONSOLE_NODE_FLAGS_OFFSET], eax
    mov qword [rbx+NEBO_CONSOLE_NODE_PARENT_ID_OFFSET], 1
    mov rax, [r12+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET]
    mov rdx, [rax+NEBO_CONSOLE_NODE_LAST_CHILD_ID_OFFSET]
    mov [rbx+NEBO_CONSOLE_NODE_PREVIOUS_SIBLING_ID_OFFSET], rdx
    mov rax, [r12+NEBO_CONSOLE_DOCUMENT_TEXT_LENGTH_OFFSET]
    mov [rbx+NEBO_CONSOLE_NODE_PAYLOAD_OFFSET_OFFSET], rax
    mov [rbx+NEBO_CONSOLE_NODE_PAYLOAD_LENGTH_OFFSET], r14
    mov rax, [rsp]
    mov [rbx+NEBO_CONSOLE_NODE_SEMANTIC_ROLE_OFFSET], eax
    mov rax, [rsp+8]
    dec rax
    mov [rbx+NEBO_CONSOLE_NODE_ORDER_OFFSET], rax

    test r14, r14
    jz .commit_link
    mov rdi, [r12+NEBO_CONSOLE_DOCUMENT_TEXT_STORE_PTR_OFFSET]
    add rdi, [r12+NEBO_CONSOLE_DOCUMENT_TEXT_LENGTH_OFFSET]
    mov rsi, r13
    mov rcx, r14
    cld
    rep movsb
.commit_link:
    mov rax, [r12+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET]
    mov rdx, [rbx+NEBO_CONSOLE_NODE_PREVIOUS_SIBLING_ID_OFFSET]
    test rdx, rdx
    jnz .commit_previous
    mov rdx, [rsp+8]
    mov [rax+NEBO_CONSOLE_NODE_FIRST_CHILD_ID_OFFSET], rdx
    jmp .commit_root_last
.commit_previous:
    dec rdx
    imul rdx, NEBO_CONSOLE_NODE_HEADER_SIZE
    add rdx, [r12+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET]
    mov rcx, [rsp+8]
    mov [rdx+NEBO_CONSOLE_NODE_NEXT_SIBLING_ID_OFFSET], rcx
.commit_root_last:
    mov rdx, [rsp+8]
    mov [rax+NEBO_CONSOLE_NODE_LAST_CHILD_ID_OFFSET], rdx
    mov [r12+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET], rdx
    add [r12+NEBO_CONSOLE_DOCUMENT_TEXT_LENGTH_OFFSET], r14
    mov [r12+NEBO_CONSOLE_DOCUMENT_CURSOR_AFTER_NODE_ID_OFFSET], rdx
    cmp r15d, NEBO_CONSOLE_NODE_KIND_LINE_BREAK
    jne .commit_inline
    mov [r12+NEBO_CONSOLE_DOCUMENT_CURSOR_CURRENT_LINE_ID_OFFSET], rdx
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_CURSOR_INLINE_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_CURSOR_MODE_OFFSET], NEBO_CONSOLE_CURSOR_MODE_NEW_LINE
    jmp .commit_done
.commit_inline:
    add [r12+NEBO_CONSOLE_DOCUMENT_CURSOR_INLINE_OFFSET], r14
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_CURSOR_MODE_OFFSET], NEBO_CONSOLE_CURSOR_MODE_INLINE
.commit_done:
    mov rax, [rsp+8]
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Internal transaction finalizer. RDI=document*, RSI=nodes, RDX=text bytes.
nebo_console_document_finish_transaction_internal:
    push r12
    mov r12, rdi
    inc qword [r12+NEBO_CONSOLE_DOCUMENT_TRANSACTION_SEQUENCE_OFFSET]
    inc qword [r12+NEBO_CONSOLE_DOCUMENT_REVISION_OFFSET]
    mov rax, [r12+NEBO_CONSOLE_DOCUMENT_REVISION_OFFSET]
    mov [r12+NEBO_CONSOLE_DOCUMENT_DIRTY_REVISION_OFFSET], rax
    or qword [r12+NEBO_CONSOLE_DOCUMENT_FLAGS_OFFSET], NEBO_CONSOLE_DOCUMENT_FLAG_DIRTY
    add [r12+NEBO_CONSOLE_DOCUMENT_COMMITTED_NODES_OFFSET], rsi
    add [r12+NEBO_CONSOLE_DOCUMENT_COMMITTED_TEXT_BYTES_OFFSET], rdx
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_LAST_ERROR_OFFSET], NEBO_CONSOLE_DOCUMENT_ERROR_NONE
    mov rdi, r12
    lea rsi, [r12+NEBO_CONSOLE_DOCUMENT_STATE_HASH_OFFSET]
    call nebo_console_document_state_hash
    pop r12
    ret

; Internal single-node transaction. RDI=document*, RSI=data*, RDX=len,
; ECX=kind, R8D=semantic. Data must be UTF-8 when len > 0.
nebo_console_document_append_single_internal:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15d, ecx
    mov [rsp], r8
    mov rdi, r12
    call nebo_console_document_validate
    test eax, eax
    jnz .single_state
    cmp r15d, NEBO_CONSOLE_NODE_KIND_TEXT
    jb .single_invalid
    cmp r15d, NEBO_CONSOLE_NODE_KIND_BOOL
    ja .single_invalid
    test r14, r14
    jz .single_data_ready
    test r13, r13
    jz .single_invalid
    mov rdi, r13
    mov rsi, r14
    call nebo_console_basic_validate_utf8
    test eax, eax
    jnz .single_utf8
.single_data_ready:
    mov rax, [r12+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET]
    inc rax
    jc .single_node_limit
    cmp rax, [r12+NEBO_CONSOLE_DOCUMENT_NODE_CAPACITY_OFFSET]
    ja .single_node_limit
    mov rax, [r12+NEBO_CONSOLE_DOCUMENT_TEXT_LENGTH_OFFSET]
    add rax, r14
    jc .single_text_limit
    cmp rax, [r12+NEBO_CONSOLE_DOCUMENT_TEXT_CAPACITY_OFFSET]
    ja .single_text_limit
    mov rdi, r12
    call nebo_console_document_can_commit_internal
    test eax, eax
    jnz .single_output_limit
    mov rdi, r12
    mov rsi, r13
    mov rdx, r14
    mov ecx, r15d
    mov r8, [rsp]
    call nebo_console_document_commit_node_internal
    mov rdi, r12
    mov esi, 1
    mov rdx, r14
    call nebo_console_document_finish_transaction_internal
    jmp .single_done
.single_utf8:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_INVALID_UTF8
    call nebo_console_document_set_failure_internal
    jmp .single_done
.single_node_limit:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_NODE_LIMIT
    call nebo_console_document_set_failure_internal
    jmp .single_done
.single_text_limit:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_TEXT_LIMIT
    call nebo_console_document_set_failure_internal
    jmp .single_done
.single_output_limit:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_OUTPUT_LIMIT
    call nebo_console_document_set_failure_internal
    jmp .single_done
.single_state:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_BAD_STATE
    call nebo_console_document_set_failure_internal
    jmp .single_done
.single_invalid:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_BAD_ARGUMENT
    call nebo_console_document_set_failure_internal
.single_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; append_text(document*, TextDescriptor*) -> status. Newline byte 0x0A is a
; logical LineBreak; no separators or trailing newline are synthesized.
nebo_console_document_append_text:
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 56
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    call nebo_console_document_validate
    test eax, eax
    jnz .text_state
    test r13, r13
    jz .text_invalid
    cmp word [r13+NEBO_RUNTIME_TEXT_ENCODING_OFFSET], NEBO_RUNTIME_TEXT_ENCODING_UTF8
    jne .text_invalid_utf8
    mov r14, [r13+NEBO_RUNTIME_TEXT_DATA_OFFSET]
    mov r15, [r13+NEBO_RUNTIME_TEXT_LENGTH_OFFSET]
    test r15, r15
    jz .text_noop
    test r14, r14
    jz .text_invalid
    mov rdi, r14
    mov rsi, r15
    call nebo_console_basic_validate_utf8
    test eax, eax
    jnz .text_invalid_utf8

    xor ebx, ebx                    ; needed nodes
    xor ebp, ebp                    ; needed text bytes
    xor r8d, r8d                    ; in text segment
    xor rcx, rcx
.text_scan:
    cmp rcx, r15
    jae .text_scan_done
    cmp byte [r14+rcx], 10
    je .text_scan_break
    inc rbp
    mov r8d, 1
    inc rcx
    jmp .text_scan
.text_scan_break:
    test r8d, r8d
    jz .text_scan_break_node
    inc rbx
    xor r8d, r8d
.text_scan_break_node:
    inc rbx
    inc rcx
    jmp .text_scan
.text_scan_done:
    test r8d, r8d
    jz .text_counts_ready
    inc rbx
.text_counts_ready:
    mov rax, [r12+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET]
    add rax, rbx
    jc .text_node_limit
    cmp rax, [r12+NEBO_CONSOLE_DOCUMENT_NODE_CAPACITY_OFFSET]
    ja .text_node_limit
    mov rax, [r12+NEBO_CONSOLE_DOCUMENT_TEXT_LENGTH_OFFSET]
    add rax, rbp
    jc .text_text_limit
    cmp rax, [r12+NEBO_CONSOLE_DOCUMENT_TEXT_CAPACITY_OFFSET]
    ja .text_text_limit
    mov rdi, r12
    call nebo_console_document_can_commit_internal
    test eax, eax
    jnz .text_output_limit

    xor rcx, rcx                    ; scan index
    xor r8d, r8d                    ; segment length
    xor r9d, r9d                    ; segment start
.text_commit_loop:
    cmp rcx, r15
    jae .text_commit_tail
    cmp byte [r14+rcx], 10
    je .text_commit_break
    test r8, r8
    jnz .text_commit_char
    mov r9, rcx
.text_commit_char:
    inc r8
    inc rcx
    jmp .text_commit_loop
.text_commit_break:
    test r8, r8
    jz .text_commit_break_node
    mov [rsp], rcx
    mov [rsp+8], r9
    mov [rsp+16], r8
    mov rdi, r12
    lea rsi, [r14+r9]
    mov rdx, r8
    mov ecx, NEBO_CONSOLE_NODE_KIND_TEXT
    mov r8d, NEBO_CONSOLE_SEMANTIC_ROLE_TEXT
    call nebo_console_document_commit_node_internal
    mov rcx, [rsp]
    xor r8d, r8d
.text_commit_break_node:
    mov [rsp], rcx
    mov rdi, r12
    xor esi, esi
    xor edx, edx
    mov ecx, NEBO_CONSOLE_NODE_KIND_LINE_BREAK
    mov r8d, NEBO_CONSOLE_SEMANTIC_ROLE_LINE_BREAK
    call nebo_console_document_commit_node_internal
    mov rcx, [rsp]
    inc rcx
    xor r8d, r8d
    jmp .text_commit_loop
.text_commit_tail:
    test r8, r8
    jz .text_finish
    mov rdi, r12
    lea rsi, [r14+r9]
    mov rdx, r8
    mov ecx, NEBO_CONSOLE_NODE_KIND_TEXT
    mov r8d, NEBO_CONSOLE_SEMANTIC_ROLE_TEXT
    call nebo_console_document_commit_node_internal
.text_finish:
    mov rdi, r12
    mov rsi, rbx
    mov rdx, rbp
    call nebo_console_document_finish_transaction_internal
    jmp .text_done
.text_noop:
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r12+NEBO_CONSOLE_DOCUMENT_LAST_ERROR_OFFSET], NEBO_CONSOLE_DOCUMENT_ERROR_NONE
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .text_done
.text_invalid_utf8:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_INVALID_UTF8
    call nebo_console_document_set_failure_internal
    jmp .text_done
.text_node_limit:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_NODE_LIMIT
    call nebo_console_document_set_failure_internal
    jmp .text_done
.text_text_limit:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_TEXT_LIMIT
    call nebo_console_document_set_failure_internal
    jmp .text_done
.text_output_limit:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_OUTPUT_LIMIT
    call nebo_console_document_set_failure_internal
    jmp .text_done
.text_state:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_BAD_STATE
    call nebo_console_document_set_failure_internal
    jmp .text_done
.text_invalid:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_BAD_ARGUMENT
    call nebo_console_document_set_failure_internal
.text_done:
    add rsp, 56
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; append_newline(document*) -> status
nebo_console_document_append_newline:
    xor esi, esi
    xor edx, edx
    mov ecx, NEBO_CONSOLE_NODE_KIND_LINE_BREAK
    mov r8d, NEBO_CONSOLE_SEMANTIC_ROLE_LINE_BREAK
    jmp nebo_console_document_append_single_internal

; append_int(document*, int64) -> status
nebo_console_document_append_int:
    push r12
    push r13
    sub rsp, 56
    mov r12, rdi
    mov r13, rsi
    mov rdi, r13
    lea rsi, [rsp]
    mov edx, NEBO_CONSOLE_INT64_FORMAT_BUFFER_SIZE
    lea rcx, [rsp+32]
    call nebo_console_basic_format_int64
    test eax, eax
    jnz .int_append_done
    mov rdi, r12
    lea rsi, [rsp]
    mov rdx, [rsp+32]
    mov ecx, NEBO_CONSOLE_NODE_KIND_INT
    mov r8d, NEBO_CONSOLE_SEMANTIC_ROLE_VALUE
    call nebo_console_document_append_single_internal
.int_append_done:
    add rsp, 56
    pop r13
    pop r12
    ret

; append_bool(document*, canonical_bool) -> status
nebo_console_document_append_bool:
    push r12
    push r13
    sub rsp, 56
    mov r12, rdi
    mov r13, rsi
    mov rdi, r13
    lea rsi, [rsp]
    mov edx, NEBO_CONSOLE_INT64_FORMAT_BUFFER_SIZE
    lea rcx, [rsp+32]
    call nebo_console_basic_format_bool
    test eax, eax
    jnz .bool_append_format_fail
    mov rdi, r12
    lea rsi, [rsp]
    mov rdx, [rsp+32]
    mov ecx, NEBO_CONSOLE_NODE_KIND_BOOL
    mov r8d, NEBO_CONSOLE_SEMANTIC_ROLE_VALUE
    call nebo_console_document_append_single_internal
    jmp .bool_append_done
.bool_append_format_fail:
    test r12, r12
    jz .bool_append_done
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_INVALID_BOOL
    call nebo_console_document_set_failure_internal
.bool_append_done:
    add rsp, 56
    pop r13
    pop r12
    ret


; set_behavior_set(document*, NodeId, BehaviorSetId) -> status.
; Applies a validated behavior identity only to the selected receiver node.
nebo_console_document_set_behavior_set:
    push r12
    push r13
    push r14
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    test r14, r14
    jz .behavior_invalid
    mov rdi, r12
    call nebo_console_document_validate
    test eax, eax
    jnz .behavior_state
    cmp r13, 1
    jbe .behavior_invalid
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rsp]
    call nebo_console_document_node_from_id
    test eax, eax
    jnz .behavior_invalid
    mov rax, [rsp]
    mov ecx, [rax+NEBO_CONSOLE_NODE_KIND_OFFSET]
    cmp ecx, NEBO_CONSOLE_NODE_KIND_TEXT
    je .behavior_kind_ok
    cmp ecx, NEBO_CONSOLE_NODE_KIND_INT
    je .behavior_kind_ok
    cmp ecx, NEBO_CONSOLE_NODE_KIND_BOOL
    jne .behavior_invalid
.behavior_kind_ok:
    cmp qword [rax+NEBO_CONSOLE_NODE_BEHAVIOR_SET_ID_OFFSET], 0
    jne .behavior_conflict
    mov rdi, r12
    call nebo_console_document_can_commit_internal
    test eax, eax
    jnz .behavior_limit
    mov rax, [rsp]
    mov [rax+NEBO_CONSOLE_NODE_BEHAVIOR_SET_ID_OFFSET], r14
    or dword [rax+NEBO_CONSOLE_NODE_FLAGS_OFFSET], NEBO_CONSOLE_NODE_FLAG_DIRTY
    mov rdi, r12
    xor esi, esi
    xor edx, edx
    call nebo_console_document_finish_transaction_internal
    jmp .behavior_done
.behavior_conflict:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_BEHAVIOR_CONFLICT
    call nebo_console_document_set_failure_internal
    jmp .behavior_done
.behavior_limit:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_OUTPUT_LIMIT
    call nebo_console_document_set_failure_internal
    jmp .behavior_done
.behavior_state:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_BAD_STATE
    call nebo_console_document_set_failure_internal
    jmp .behavior_done
.behavior_invalid:
    test r12, r12
    jz .behavior_invalid_no_document
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_BAD_ARGUMENT
    call nebo_console_document_set_failure_internal
    jmp .behavior_done
.behavior_invalid_no_document:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.behavior_done:
    add rsp, 16
    pop r14
    pop r13
    pop r12
    ret

; document_append_scan(document*, route_kind, prompt_descriptor*, result*) -> status
; Atomically creates structural scan nodes and advances the insertion cursor.
nebo_console_document_append_scan:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 64
    mov r12, rdi
    mov r13d, esi
    mov r14, rdx
    mov r15, rcx
    test r15, r15
    jz .scan_invalid_no_result
    mov rdi, r15
    xor eax, eax
    mov ecx, NEBO_SCAN_DOCUMENT_RESULT_QWORDS
    cld
    rep stosq
    mov rdi, r12
    call nebo_console_document_validate
    test eax, eax
    jnz .scan_state
    mov qword [rsp], 0
    mov qword [rsp+8], 0
    mov qword [rsp+16], 0
    cmp r13d, NEBO_SCAN_ROUTE_TEXT_DEFAULT_ROW
    je .scan_text_row
    cmp r13d, NEBO_SCAN_ROUTE_CONSOLE_INLINE
    je .scan_console_inline
    cmp r13d, NEBO_SCAN_ROUTE_ANONYMOUS_INLINE
    je .scan_anonymous
    jmp .scan_invalid
.scan_text_row:
    test r14, r14
    jz .scan_invalid
    mov qword [rsp], 4
    cmp qword [r12+NEBO_CONSOLE_DOCUMENT_CURSOR_INLINE_OFFSET], 0
    je .scan_prompt_validate
    mov qword [rsp+16], 1
    inc qword [rsp]
    jmp .scan_prompt_validate
.scan_console_inline:
    test r14, r14
    jnz .scan_invalid
    mov qword [rsp], 2
    jmp .scan_capacity
.scan_anonymous:
    test r14, r14
    jz .scan_invalid
    mov qword [rsp], 3
.scan_prompt_validate:
    cmp word [r14+NEBO_RUNTIME_TEXT_ENCODING_OFFSET], NEBO_RUNTIME_TEXT_ENCODING_UTF8
    jne .scan_invalid
    mov rax, [r14+NEBO_RUNTIME_TEXT_LENGTH_OFFSET]
    mov [rsp+8], rax
    test rax, rax
    jz .scan_capacity
    cmp qword [r14+NEBO_RUNTIME_TEXT_DATA_OFFSET], 0
    je .scan_invalid
    mov rdi, [r14+NEBO_RUNTIME_TEXT_DATA_OFFSET]
    mov rsi, rax
    call nebo_console_basic_validate_utf8
    test eax, eax
    jnz .scan_utf8
.scan_capacity:
    mov rax, [r12+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET]
    add rax, [rsp]
    jc .scan_node_limit
    cmp rax, [r12+NEBO_CONSOLE_DOCUMENT_NODE_CAPACITY_OFFSET]
    ja .scan_node_limit
    mov rax, [r12+NEBO_CONSOLE_DOCUMENT_TEXT_LENGTH_OFFSET]
    add rax, [rsp+8]
    jc .scan_text_limit
    cmp rax, [r12+NEBO_CONSOLE_DOCUMENT_TEXT_CAPACITY_OFFSET]
    ja .scan_text_limit
    mov rdi, r12
    call nebo_console_document_can_commit_internal
    test eax, eax
    jnz .scan_output_limit
    cmp qword [rsp+16], 0
    je .scan_row_marker
    mov rdi, r12
    xor esi, esi
    xor edx, edx
    mov ecx, NEBO_CONSOLE_NODE_KIND_LINE_BREAK
    mov r8d, NEBO_CONSOLE_SEMANTIC_ROLE_LINE_BREAK
    call nebo_console_document_commit_node_internal
.scan_row_marker:
    cmp r13d, NEBO_SCAN_ROUTE_TEXT_DEFAULT_ROW
    jne .scan_prompt
    mov rdi, r12
    xor esi, esi
    xor edx, edx
    mov ecx, NEBO_CONSOLE_NODE_KIND_INPUT_ROW
    mov r8d, NEBO_CONSOLE_SEMANTIC_ROLE_INPUT_ROW
    call nebo_console_document_commit_node_internal
    mov [r15+NEBO_SCAN_DOCUMENT_ROW_NODE_ID_OFFSET], rax
.scan_prompt:
    cmp r13d, NEBO_SCAN_ROUTE_CONSOLE_INLINE
    je .scan_input
    mov rdi, r12
    mov rsi, [r14+NEBO_RUNTIME_TEXT_DATA_OFFSET]
    mov rdx, [r14+NEBO_RUNTIME_TEXT_LENGTH_OFFSET]
    mov ecx, NEBO_CONSOLE_NODE_KIND_PROMPT
    mov r8d, NEBO_CONSOLE_SEMANTIC_ROLE_PROMPT
    call nebo_console_document_commit_node_internal
    mov [r15+NEBO_SCAN_DOCUMENT_PROMPT_NODE_ID_OFFSET], rax
.scan_input:
    mov rdi, r12
    xor esi, esi
    xor edx, edx
    mov ecx, NEBO_CONSOLE_NODE_KIND_INPUT
    mov r8d, NEBO_CONSOLE_SEMANTIC_ROLE_INPUT
    call nebo_console_document_commit_node_internal
    mov [r15+NEBO_SCAN_DOCUMENT_INPUT_NODE_ID_OFFSET], rax
    mov rdi, r12
    xor esi, esi
    xor edx, edx
    mov ecx, NEBO_CONSOLE_NODE_KIND_LINE_BREAK
    mov r8d, NEBO_CONSOLE_SEMANTIC_ROLE_LINE_BREAK
    call nebo_console_document_commit_node_internal
    mov rax, [rsp]
    mov [r15+NEBO_SCAN_DOCUMENT_COMMITTED_NODE_COUNT_OFFSET], rax
    mov rdi, r12
    mov rsi, rax
    mov rdx, [rsp+8]
    call nebo_console_document_finish_transaction_internal
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .scan_done
.scan_utf8:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_INVALID_UTF8
    call nebo_console_document_set_failure_internal
    jmp .scan_done
.scan_node_limit:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_NODE_LIMIT
    call nebo_console_document_set_failure_internal
    jmp .scan_done
.scan_text_limit:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_TEXT_LIMIT
    call nebo_console_document_set_failure_internal
    jmp .scan_done
.scan_output_limit:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_OUTPUT_LIMIT
    call nebo_console_document_set_failure_internal
    jmp .scan_done
.scan_state:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_BAD_STATE
    call nebo_console_document_set_failure_internal
    jmp .scan_done
.scan_invalid:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_BAD_ARGUMENT
    call nebo_console_document_set_failure_internal
    jmp .scan_done
.scan_invalid_no_result:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.scan_done:
    add rsp, 64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; apply_command(document*, ConsoleCommandDescriptor*) -> status
nebo_console_document_apply_command:
    test rdi, rdi
    jz .command_invalid
    test rsi, rsi
    jz .command_invalid
    mov eax, [rsi+NEBO_CONSOLE_COMMAND_KIND_OFFSET]
    cmp eax, NEBO_CONSOLE_COMMAND_CREATE_INITIAL_CONTENT
    je .command_text
    cmp eax, NEBO_CONSOLE_COMMAND_APPEND_TEXT
    je .command_text
    cmp eax, NEBO_CONSOLE_COMMAND_APPEND_INT
    je .command_int
    cmp eax, NEBO_CONSOLE_COMMAND_APPEND_BOOL
    je .command_bool
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret
.command_text:
    mov rsi, [rsi+NEBO_CONSOLE_COMMAND_PAYLOAD0_OFFSET]
    jmp nebo_console_document_append_text
.command_int:
    mov rsi, [rsi+NEBO_CONSOLE_COMMAND_PAYLOAD0_OFFSET]
    jmp nebo_console_document_append_int
.command_bool:
    mov rsi, [rsi+NEBO_CONSOLE_COMMAND_PAYLOAD0_OFFSET]
    jmp nebo_console_document_append_bool
.command_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; audit_links(document*) -> status
nebo_console_document_audit_links:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov rdi, r12
    call nebo_console_document_validate
    test eax, eax
    jnz .audit_done
    mov r13, [r12+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET]
    mov r14, [r13+NEBO_CONSOLE_NODE_FIRST_CHILD_ID_OFFSET]
    mov r15, [r13+NEBO_CONSOLE_NODE_LAST_CHILD_ID_OFFSET]
    mov rax, [r12+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET]
    dec rax
    test rax, rax
    jnz .audit_nonempty
    test r14, r14
    jnz .audit_corrupt
    test r15, r15
    jnz .audit_corrupt
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .audit_done
.audit_nonempty:
    test r14, r14
    jz .audit_corrupt
    test r15, r15
    jz .audit_corrupt
    xor ebx, ebx                    ; visited
    xor r13d, r13d                  ; expected previous
.audit_loop:
    test r14, r14
    jz .audit_end
    cmp r14, 1
    jbe .audit_corrupt
    cmp r14, [r12+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET]
    ja .audit_corrupt
    mov rax, r14
    dec rax
    imul rax, NEBO_CONSOLE_NODE_HEADER_SIZE
    add rax, [r12+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET]
    cmp [rax+NEBO_CONSOLE_NODE_ID_OFFSET], r14
    jne .audit_corrupt
    cmp qword [rax+NEBO_CONSOLE_NODE_PARENT_ID_OFFSET], 1
    jne .audit_corrupt
    cmp [rax+NEBO_CONSOLE_NODE_PREVIOUS_SIBLING_ID_OFFSET], r13
    jne .audit_corrupt
    mov edx, [rax+NEBO_CONSOLE_NODE_KIND_OFFSET]
    cmp edx, NEBO_CONSOLE_NODE_KIND_TEXT
    jb .audit_corrupt
    cmp edx, NEBO_CONSOLE_NODE_KIND_MAX
    ja .audit_corrupt
    test dword [rax+NEBO_CONSOLE_NODE_FLAGS_OFFSET], NEBO_CONSOLE_NODE_FLAG_LIVE
    jz .audit_corrupt
    cmp qword [rax+NEBO_CONSOLE_NODE_FIRST_CHILD_ID_OFFSET], 0
    jne .audit_corrupt
    cmp qword [rax+NEBO_CONSOLE_NODE_LAST_CHILD_ID_OFFSET], 0
    jne .audit_corrupt
    mov rdx, [rax+NEBO_CONSOLE_NODE_PAYLOAD_OFFSET_OFFSET]
    add rdx, [rax+NEBO_CONSOLE_NODE_PAYLOAD_LENGTH_OFFSET]
    jc .audit_corrupt
    cmp rdx, [r12+NEBO_CONSOLE_DOCUMENT_TEXT_LENGTH_OFFSET]
    ja .audit_corrupt
    inc rbx
    mov rdx, [r12+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET]
    dec rdx
    cmp rbx, rdx
    ja .audit_corrupt
    mov r13, r14
    mov r14, [rax+NEBO_CONSOLE_NODE_NEXT_SIBLING_ID_OFFSET]
    jmp .audit_loop
.audit_end:
    mov rax, [r12+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET]
    dec rax
    cmp rbx, rax
    jne .audit_corrupt
    cmp r13, r15
    jne .audit_corrupt
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .audit_done
.audit_corrupt:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_CONSOLE_DOCUMENT_ERROR_LINK_CORRUPTION
    call nebo_console_document_set_failure_internal
.audit_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; copy_plain_text(document*, output*, capacity, out_length*) -> status
nebo_console_document_copy_plain_text:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    test r15, r15
    jz .copy_invalid
    mov qword [r15], 0
    mov rdi, r12
    call nebo_console_document_audit_links
    test eax, eax
    jnz .copy_done
    mov rax, [r12+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET]
    mov rbx, [rax+NEBO_CONSOLE_NODE_FIRST_CHILD_ID_OFFSET]
    xor r8d, r8d
.copy_measure:
    test rbx, rbx
    jz .copy_capacity
    mov rax, rbx
    dec rax
    imul rax, NEBO_CONSOLE_NODE_HEADER_SIZE
    add rax, [r12+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET]
    cmp dword [rax+NEBO_CONSOLE_NODE_KIND_OFFSET], NEBO_CONSOLE_NODE_KIND_LINE_BREAK
    jne .copy_measure_payload
    inc r8
    jc .copy_limit
    jmp .copy_measure_next
.copy_measure_payload:
    add r8, [rax+NEBO_CONSOLE_NODE_PAYLOAD_LENGTH_OFFSET]
    jc .copy_limit
.copy_measure_next:
    mov rbx, [rax+NEBO_CONSOLE_NODE_NEXT_SIBLING_ID_OFFSET]
    jmp .copy_measure
.copy_capacity:
    cmp r8, r14
    ja .copy_limit
    test r8, r8
    jz .copy_empty
    test r13, r13
    jz .copy_invalid
    mov [rsp], r8
    mov rax, [r12+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET]
    mov rbx, [rax+NEBO_CONSOLE_NODE_FIRST_CHILD_ID_OFFSET]
    xor r9d, r9d
.copy_loop:
    test rbx, rbx
    jz .copy_success
    mov rax, rbx
    dec rax
    imul rax, NEBO_CONSOLE_NODE_HEADER_SIZE
    add rax, [r12+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET]
    cmp dword [rax+NEBO_CONSOLE_NODE_KIND_OFFSET], NEBO_CONSOLE_NODE_KIND_LINE_BREAK
    jne .copy_payload
    mov byte [r13+r9], 10
    inc r9
    jmp .copy_next
.copy_payload:
    mov rcx, [rax+NEBO_CONSOLE_NODE_PAYLOAD_LENGTH_OFFSET]
    test rcx, rcx
    jz .copy_next
    mov rsi, [r12+NEBO_CONSOLE_DOCUMENT_TEXT_STORE_PTR_OFFSET]
    add rsi, [rax+NEBO_CONSOLE_NODE_PAYLOAD_OFFSET_OFFSET]
    lea rdi, [r13+r9]
    add r9, rcx
    cld
    rep movsb
.copy_next:
    mov rbx, [rax+NEBO_CONSOLE_NODE_NEXT_SIBLING_ID_OFFSET]
    jmp .copy_loop
.copy_empty:
    xor r9d, r9d
.copy_success:
    mov [r15], r9
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .copy_done
.copy_limit:
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .copy_done
.copy_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.copy_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; state_hash(document*, out_hash*) -> status. Native storage pointers are not
; hash inputs; only logical IDs, links, kinds, payload bytes and cursor state.
nebo_console_document_state_hash:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r15, rsi
    test r15, r15
    jz .hash_invalid
    mov qword [r15], 0
    mov rdi, r12
    call nebo_console_document_audit_links
    test eax, eax
    jnz .hash_done
    mov eax, NEBO_CONSOLE_DOCUMENT_HASH_FNV1A32_OFFSET_BASIS
    NEBO_DOCUMENT_HASH_QWORD [r12+NEBO_CONSOLE_DOCUMENT_HANDLE_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r12+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r12+NEBO_CONSOLE_DOCUMENT_TEXT_LENGTH_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r12+NEBO_CONSOLE_DOCUMENT_ROOT_ID_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r12+NEBO_CONSOLE_DOCUMENT_CURSOR_CONTAINER_ID_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r12+NEBO_CONSOLE_DOCUMENT_CURSOR_CURRENT_LINE_ID_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r12+NEBO_CONSOLE_DOCUMENT_CURSOR_AFTER_NODE_ID_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r12+NEBO_CONSOLE_DOCUMENT_CURSOR_INLINE_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r12+NEBO_CONSOLE_DOCUMENT_CURSOR_MODE_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r12+NEBO_CONSOLE_DOCUMENT_REVISION_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r12+NEBO_CONSOLE_DOCUMENT_DIRTY_REVISION_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r12+NEBO_CONSOLE_DOCUMENT_FLAGS_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r12+NEBO_CONSOLE_DOCUMENT_TRANSACTION_SEQUENCE_OFFSET]
    mov r13, [r12+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET]
    xor ebx, ebx
.hash_node_loop:
    cmp rbx, [r12+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET]
    jae .hash_finish
    mov r14, rbx
    imul r14, NEBO_CONSOLE_NODE_HEADER_SIZE
    add r14, r13
    NEBO_DOCUMENT_HASH_QWORD [r14+NEBO_CONSOLE_NODE_ID_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r14+NEBO_CONSOLE_NODE_KIND_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r14+NEBO_CONSOLE_NODE_PARENT_ID_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r14+NEBO_CONSOLE_NODE_PREVIOUS_SIBLING_ID_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r14+NEBO_CONSOLE_NODE_NEXT_SIBLING_ID_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r14+NEBO_CONSOLE_NODE_FIRST_CHILD_ID_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r14+NEBO_CONSOLE_NODE_LAST_CHILD_ID_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r14+NEBO_CONSOLE_NODE_PAYLOAD_LENGTH_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r14+NEBO_CONSOLE_NODE_BEHAVIOR_SET_ID_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r14+NEBO_CONSOLE_NODE_SEMANTIC_ROLE_OFFSET]
    NEBO_DOCUMENT_HASH_QWORD [r14+NEBO_CONSOLE_NODE_ORDER_OFFSET]
    mov rcx, [r14+NEBO_CONSOLE_NODE_PAYLOAD_LENGTH_OFFSET]
    test rcx, rcx
    jz .hash_next_node
    mov rsi, [r12+NEBO_CONSOLE_DOCUMENT_TEXT_STORE_PTR_OFFSET]
    add rsi, [r14+NEBO_CONSOLE_NODE_PAYLOAD_OFFSET_OFFSET]
.hash_payload_loop:
    xor al, [rsi]
    imul rax, rax, NEBO_CONSOLE_DOCUMENT_HASH_FNV1A32_PRIME
    inc rsi
    dec rcx
    jnz .hash_payload_loop
.hash_next_node:
    inc rbx
    jmp .hash_node_loop
.hash_finish:
    mov [r12+NEBO_CONSOLE_DOCUMENT_STATE_HASH_OFFSET], rax
    mov [r15], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .hash_done
.hash_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.hash_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
