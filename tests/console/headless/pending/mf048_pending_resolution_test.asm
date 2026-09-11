; Nebo Assembly — MF048 ENTER/Pending/dependency bridge scenarios
bits 64
default rel
%include "runtime/console/input/registry/input_registry.inc"
%include "runtime/console/pending/pending_registry.inc"
%include "runtime/console/input/editing/text_editor.inc"
%include "runtime/console/focus/focus_manager.inc"
%include "runtime/console/layout/console_layout.inc"
%include "runtime/console/dependency-bridge/dependency_bridge.inc"
%include "runtime/console/input/submission/input_submission.inc"

extern nebo_input_registry_init
extern nebo_pending_registry_init
extern nebo_text_edit_init
extern nebo_dependency_bridge_init
extern nebo_dependency_bridge_register
extern nebo_input_submission_init
extern nebo_input_submission_enter
extern nebo_input_submission_key
extern nebo_text_edit_insert_utf8
extern neboc_host_process_exit

global _start

%define CAP 2
%define STRIDE 32
%define CONT_CAP 4

section .rodata
second_text: db 'segundo'
one_text: db 'x'

section .bss align=64
input_registry: resb NEBO_INPUT_REGISTRY_SIZE
input_records: resb CAP*NEBO_INPUT_RECORD_SIZE
pending_registry: resb NEBO_PENDING_REGISTRY_SIZE
pending_records: resb CAP*NEBO_PENDING_RECORD_SIZE
layout_dummy: resb NEBO_LAYOUT_TREE_SIZE
focus: resb NEBO_FOCUS_MANAGER_SIZE
editors: resb CAP*NEBO_TEXT_EDIT_RECORD_SIZE
edit_buffers: resb CAP*STRIDE
bridge: resb NEBO_DEPENDENCY_BRIDGE_SIZE
continuations: resb CONT_CAP*NEBO_DEPENDENCY_CONTINUATION_SIZE
submission: resb NEBO_SUBMISSION_CONTEXT_SIZE
submission_storage: resb NEBO_SUBMISSION_STORAGE_SIZE
values: resb CAP*STRIDE
result: resb NEBO_SUBMISSION_RESULT_SIZE

section .text
_start:
    cmp qword [rsp], 2
    jne fail
    mov rbx, [rsp+16]
    movzx eax, byte [rbx]
    sub eax, '0'
    cmp eax, 1
    jb fail
    cmp eax, 5
    ja fail
    call setup
    test eax, eax
    jnz fail
    cmp byte [rbx], '1'
    je scenario1
    cmp byte [rbx], '2'
    je scenario2
    cmp byte [rbx], '3'
    je scenario3
    cmp byte [rbx], '4'
    je scenario4
    jmp scenario5

scenario1:
    ; Focus second input and resolve it before the first.
    lea rdi, [rel bridge]
    mov esi, 21
    mov edx, 1002
    mov ecx, 202
    mov r8d, 3
    mov r9d, 921
    call nebo_dependency_bridge_register
    test eax, eax
    jnz fail
    mov rax, 0x0000000100000001
    mov [rel focus+NEBO_FOCUS_MANAGER_FOCUSED_HANDLE_OFFSET], rax
    lea rdi, [rel editors+NEBO_TEXT_EDIT_RECORD_SIZE]
    lea rsi, [rel second_text]
    mov edx, 7
    call nebo_text_edit_insert_utf8
    test eax, eax
    jnz fail
    lea rdi, [rel submission]
    mov esi, NEBO_FOCUS_KEY_ENTER
    lea rdx, [rel result]
    call nebo_input_submission_key
    test eax, eax
    jnz fail
    cmp qword [rel result+NEBO_SUBMISSION_RESULT_BINDING_ID_OFFSET], 202
    jne fail
    cmp dword [rel input_records+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_PENDING
    jne fail
    cmp dword [rel input_records+NEBO_INPUT_RECORD_SIZE+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_RESOLVED
    jne fail
    cmp qword [rel result+NEBO_SUBMISSION_RESULT_ACTIVATION_COUNT_OFFSET], 1
    jne fail
    jmp pass

scenario2:
    ; Empty Text is valid and immutable.
    lea rdi, [rel submission]
    mov esi, NEBO_FOCUS_KEY_ENTER
    lea rdx, [rel result]
    call nebo_input_submission_key
    test eax, eax
    jnz fail
    cmp qword [rel result+NEBO_SUBMISSION_RESULT_VALUE_LENGTH_OFFSET], 0
    jne fail
    cmp dword [rel pending_records+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_RESOLVED
    jne fail
    jmp pass

scenario3:
    ; Result storage limit rejects submission and keeps Pending active.
    mov qword [rel submission+NEBO_SUBMISSION_CONTEXT_VALUE_STRIDE_OFFSET], 4
    lea rdi, [rel editors]
    lea rsi, [rel second_text]
    mov edx, 7
    call nebo_text_edit_insert_utf8
    test eax, eax
    jnz fail
    lea rdi, [rel submission]
    mov esi, NEBO_FOCUS_KEY_ENTER
    lea rdx, [rel result]
    call nebo_input_submission_key
    cmp eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jne fail
    cmp dword [rel input_records+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_PENDING
    jne fail
    cmp dword [rel pending_records+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_PENDING
    jne fail
    test dword [rel input_records+NEBO_INPUT_RECORD_FLAGS_OFFSET], NEBO_INPUT_FLAG_VALIDATION_ERROR
    jz fail
    jmp pass

scenario4:
    ; Resolved input cannot be submitted or edited again.
    lea rdi, [rel submission]
    mov esi, NEBO_FOCUS_KEY_ENTER
    lea rdx, [rel result]
    call nebo_input_submission_key
    test eax, eax
    jnz fail
    lea rdi, [rel editors]
    lea rsi, [rel one_text]
    mov edx, 1
    call nebo_text_edit_insert_utf8
    cmp eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jne fail
    mov rax, 0x0000000100000000
    mov [rel focus+NEBO_FOCUS_MANAGER_FOCUSED_HANDLE_OFFSET], rax
    lea rdi, [rel submission]
    mov esi, NEBO_FOCUS_KEY_ENTER
    lea rdx, [rel result]
    call nebo_input_submission_key
    cmp eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jne fail
    jmp pass

scenario5:
    ; Two dependents activate in source order; unrelated Pending remains waiting.
    lea rdi, [rel bridge]
    mov esi, 11
    mov edx, 1001
    mov ecx, 201
    mov r8d, 20
    mov r9d, 901
    call nebo_dependency_bridge_register
    test eax, eax
    jnz fail
    lea rdi, [rel bridge]
    mov esi, 12
    mov edx, 1001
    mov ecx, 201
    mov r8d, 10
    mov r9d, 902
    call nebo_dependency_bridge_register
    test eax, eax
    jnz fail
    lea rdi, [rel bridge]
    mov esi, 13
    mov edx, 1002
    mov ecx, 202
    mov r8d, 5
    mov r9d, 903
    call nebo_dependency_bridge_register
    test eax, eax
    jnz fail
    lea rdi, [rel submission]
    mov esi, NEBO_FOCUS_KEY_ENTER
    lea rdx, [rel result]
    call nebo_input_submission_key
    test eax, eax
    jnz fail
    cmp qword [rel result+NEBO_SUBMISSION_RESULT_ACTIVATION_COUNT_OFFSET], 2
    jne fail
    cmp qword [rel continuations+NEBO_DEPENDENCY_ACTIVATION_SEQUENCE_OFFSET], 2
    jne fail
    cmp qword [rel continuations+NEBO_DEPENDENCY_CONTINUATION_SIZE+NEBO_DEPENDENCY_ACTIVATION_SEQUENCE_OFFSET], 1
    jne fail
    cmp dword [rel continuations+2*NEBO_DEPENDENCY_CONTINUATION_SIZE+NEBO_DEPENDENCY_STATE_OFFSET], NEBO_DEPENDENCY_STATE_WAITING
    jne fail
    jmp pass

setup:
    push rbx
    push r12
    sub rsp, 8
    lea rdi, [rel input_registry]
    lea rsi, [rel input_records]
    mov edx, CAP
    mov rcx, 0x0000000100000000
    call nebo_input_registry_init
    test eax, eax
    jnz .done
    lea rdi, [rel pending_registry]
    lea rsi, [rel pending_records]
    mov edx, CAP
    mov rcx, 0x0000000100000000
    call nebo_pending_registry_init
    test eax, eax
    jnz .done
    ; Two matching input/pending records.
    xor ebx, ebx
.fill:
    cmp ebx, CAP
    jae .edit
    mov eax, ebx
    shl rax, 7
    lea r12, [rel input_records]
    add r12, rax
    mov dword [r12+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_PENDING
    mov eax, ebx
    mov edx, 1
    shl rdx, 32
    or rax, rdx
    mov [r12+NEBO_INPUT_RECORD_HANDLE_OFFSET], rax
    mov qword [r12+NEBO_INPUT_RECORD_NODE_ID_OFFSET], 100
    add [r12+NEBO_INPUT_RECORD_NODE_ID_OFFSET], rbx
    mov [r12+NEBO_INPUT_RECORD_PENDING_HANDLE_OFFSET], rax
    mov rdx, 1001
    add rdx, rbx
    mov [r12+NEBO_INPUT_RECORD_COMPILER_PENDING_ID_OFFSET], rdx
    mov rdx, 201
    add rdx, rbx
    mov [r12+NEBO_INPUT_RECORD_BINDING_ID_OFFSET], rdx
    mov rax, 0x0000000100000000
    mov [r12+NEBO_INPUT_RECORD_CONSOLE_HANDLE_OFFSET], rax
    mov dword [r12+NEBO_INPUT_RECORD_FLAGS_OFFSET], NEBO_INPUT_REQUIRED_FLAGS
    mov rdx, rbx
    inc rdx
    mov [r12+NEBO_INPUT_RECORD_SOURCE_ORDER_OFFSET], rdx
    mov rax, rbx
    imul rax, NEBO_PENDING_RECORD_SIZE
    lea r12, [rel pending_records]
    add r12, rax
    mov dword [r12+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_PENDING
    mov eax, ebx
    mov edx, 1
    shl rdx, 32
    or rax, rdx
    mov [r12+NEBO_PENDING_RECORD_HANDLE_OFFSET], rax
    mov [r12+NEBO_PENDING_RECORD_INPUT_HANDLE_OFFSET], rax
    mov rdx, 1001
    add rdx, rbx
    mov [r12+NEBO_PENDING_RECORD_COMPILER_PENDING_ID_OFFSET], rdx
    mov rdx, 201
    add rdx, rbx
    mov [r12+NEBO_PENDING_RECORD_BINDING_ID_OFFSET], rdx
    mov rax, 0x0000000100000000
    mov [r12+NEBO_PENDING_RECORD_CONSOLE_HANDLE_OFFSET], rax
    mov qword [r12+NEBO_PENDING_RECORD_TYPE_TAG_OFFSET], NEBO_PENDING_TYPE_TEXT
    mov qword [r12+NEBO_PENDING_RECORD_FLAGS_OFFSET], NEBO_PENDING_REQUIRED_FLAGS
    inc ebx
    jmp .fill
.edit:
    mov qword [rel input_registry+NEBO_INPUT_REGISTRY_ACTIVE_COUNT_OFFSET], CAP
    mov qword [rel input_registry+NEBO_INPUT_REGISTRY_CREATED_COUNT_OFFSET], CAP
    mov qword [rel pending_registry+NEBO_PENDING_REGISTRY_ACTIVE_COUNT_OFFSET], CAP
    mov qword [rel pending_registry+NEBO_PENDING_REGISTRY_CREATED_COUNT_OFFSET], CAP
    lea rdi, [rel editors]
    mov rsi, 0x0000000100000000
    mov edx, 100
    lea rcx, [rel edit_buffers]
    mov r8d, STRIDE
    call nebo_text_edit_init
    test eax, eax
    jnz .done
    lea rdi, [rel editors+NEBO_TEXT_EDIT_RECORD_SIZE]
    mov rsi, 0x0000000100000001
    mov edx, 101
    lea rcx, [rel edit_buffers+STRIDE]
    mov r8d, STRIDE
    call nebo_text_edit_init
    test eax, eax
    jnz .done
    ; Minimal valid FocusManager, no layout traversal needed by submission.
    lea rax, [rel input_registry]
    mov [rel focus+NEBO_FOCUS_MANAGER_INPUT_REGISTRY_PTR_OFFSET], rax
    lea rax, [rel layout_dummy]
    mov [rel focus+NEBO_FOCUS_MANAGER_LAYOUT_PTR_OFFSET], rax
    lea rax, [rel editors]
    mov [rel focus+NEBO_FOCUS_MANAGER_EDITORS_PTR_OFFSET], rax
    mov qword [rel focus+NEBO_FOCUS_MANAGER_EDITOR_CAPACITY_OFFSET], CAP
    lea rax, [rel edit_buffers]
    mov [rel focus+NEBO_FOCUS_MANAGER_TEXT_PTR_OFFSET], rax
    mov qword [rel focus+NEBO_FOCUS_MANAGER_TEXT_STRIDE_OFFSET], STRIDE
    mov rax, 0x0000000100000000
    mov [rel focus+NEBO_FOCUS_MANAGER_FOCUSED_HANDLE_OFFSET], rax
    mov qword [rel focus+NEBO_FOCUS_MANAGER_WINDOW_ACTIVE_OFFSET], 1
    mov qword [rel focus+NEBO_FOCUS_MANAGER_FLAGS_OFFSET], NEBO_FOCUS_MANAGER_REQUIRED_FLAGS
    lea rdi, [rel bridge]
    lea rsi, [rel continuations]
    mov edx, CONT_CAP
    mov rcx, 0x0000000100000000
    call nebo_dependency_bridge_init
    test eax, eax
    jnz .done
    lea rax, [rel values]
    mov [rel submission_storage+NEBO_SUBMISSION_STORAGE_VALUES_PTR_OFFSET], rax
    mov qword [rel submission_storage+NEBO_SUBMISSION_STORAGE_VALUE_STRIDE_OFFSET], STRIDE
    mov qword [rel submission_storage+NEBO_SUBMISSION_STORAGE_VALUE_CAPACITY_OFFSET], CAP
    lea rdi, [rel submission]
    lea rsi, [rel input_registry]
    lea rdx, [rel pending_registry]
    lea rcx, [rel focus]
    lea r8, [rel bridge]
    lea r9, [rel submission_storage]
    call nebo_input_submission_init
.done:
    add rsp, 8
    pop r12
    pop rbx
    ret

pass:
    xor edi, edi
    jmp neboc_host_process_exit
fail:
    mov edi, 1
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
