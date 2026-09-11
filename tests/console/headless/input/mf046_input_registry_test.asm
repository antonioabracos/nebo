; Nebo Assembly — MF046 InputRegistry and runtime scan routing scenarios
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/handles/console_handle.inc"
%include "runtime/console/manager/console_manager.inc"
%include "runtime/console/queues/console_queue.inc"
%include "runtime/console/domain/console_domain.inc"
%include "runtime/console/platform/fake/fake_platform.inc"
%include "runtime/console/document/console_document.inc"
%include "runtime/console/input/registry/input_registry.inc"
%include "runtime/console/pending/pending_registry.inc"
%include "runtime/console/input/routing/scan_routing.inc"
%include "runtime/console/layout/console_layout.inc"
%include "runtime/console/render/fake_glyph_provider.inc"

extern nebo_console_runtime_context_init
extern nebo_console_runtime_headless_bind
extern nebo_console_manager_default_get_or_create
extern nebo_console_manager_handle_validate
extern nebo_console_domain_from_handle
extern nebo_console_document_append_text
extern nebo_console_document_node_from_id
extern nebo_console_document_audit_links
extern nebo_input_runtime_init
extern nebo_input_runtime_registry_for_console
extern nebo_console_scan_route
extern nebo_input_registry_get
extern nebo_pending_registry_get
extern nebo_fake_glyph_provider_init
extern nebo_console_layout_init
extern nebo_console_layout_document
extern neboc_host_process_exit

global _start

%define TEST_CONSOLE_CAPACITY 4
%define TEST_QUEUE_CAPACITY 8
%define TEST_NODE_CAPACITY 64
%define TEST_TEXT_CAPACITY 1024
%define TEST_INPUT_CAPACITY 8
%define TEST_LAYOUT_CAPACITY 64

section .rodata align=8
prompt_name_bytes: db 'Nome: '
prompt_name: dq prompt_name_bytes,6
             dd 0
             dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
prompt_student_bytes: db 'Aluno: '
prompt_student: dq prompt_student_bytes,7
                dd 0
                dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
prefix_bytes: db 'prefix'
prefix_text: dq prefix_bytes,6
             dd 0
             dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC

section .bss align=64
context: resb NEBO_CONSOLE_CONTEXT_SIZE
slots: resb TEST_CONSOLE_CAPACITY*NEBO_CONSOLE_SLOT_SIZE
clock: resb NEBO_FAKE_CLOCK_SIZE
platform: resb NEBO_FAKE_PLATFORM_SIZE
scheduler: resb NEBO_CONSOLE_SCHEDULER_SIZE
domains: resb TEST_CONSOLE_CAPACITY*NEBO_CONSOLE_DOMAIN_SIZE
command_buffers: resb TEST_CONSOLE_CAPACITY*TEST_QUEUE_CAPACITY*NEBO_CONSOLE_COMMAND_DESCRIPTOR_SIZE
event_buffers: resb TEST_CONSOLE_CAPACITY*TEST_QUEUE_CAPACITY*NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
documents: resb TEST_CONSOLE_CAPACITY*NEBO_CONSOLE_DOCUMENT_SIZE
nodes: resb TEST_CONSOLE_CAPACITY*TEST_NODE_CAPACITY*NEBO_CONSOLE_NODE_HEADER_SIZE
text_store: resb TEST_CONSOLE_CAPACITY*TEST_TEXT_CAPACITY
headless_storage: resb NEBO_CONSOLE_HEADLESS_STORAGE_SIZE
input_runtime: resb NEBO_INPUT_RUNTIME_SIZE
input_storage: resb NEBO_INPUT_RUNTIME_STORAGE_SIZE
input_registries: resb TEST_CONSOLE_CAPACITY*NEBO_INPUT_REGISTRY_SIZE
input_records: resb TEST_CONSOLE_CAPACITY*TEST_INPUT_CAPACITY*NEBO_INPUT_RECORD_SIZE
pending_registries: resb TEST_CONSOLE_CAPACITY*NEBO_PENDING_REGISTRY_SIZE
pending_records: resb TEST_CONSOLE_CAPACITY*TEST_INPUT_CAPACITY*NEBO_PENDING_RECORD_SIZE
route_a: resb NEBO_SCAN_ROUTE_DESCRIPTOR_SIZE
route_b: resb NEBO_SCAN_ROUTE_DESCRIPTOR_SIZE
handle_a: resq 1
handle_b: resq 1
domain_ptr: resq 1
slot_ptr: resq 1
node_ptr: resq 1
input_registry_ptr: resq 1
pending_registry_ptr: resq 1
record_a: resq 1
record_b: resq 1
provider: resb NEBO_FAKE_GLYPH_PROVIDER_SIZE
layout: resb NEBO_LAYOUT_TREE_SIZE
layout_boxes: resb TEST_LAYOUT_CAPACITY*NEBO_LAYOUT_BOX_SIZE

section .text
_start:
    mov rax, [rsp]
    cmp rax, 2
    jne test_fail
    mov rbx, [rsp+16]
    cmp byte [rbx+1], 0
    jne test_fail
    movzx eax, byte [rbx]
    sub eax, '0'
    cmp eax, 1
    jb test_fail
    cmp eax, 6
    ja test_fail
    cmp eax, 1
    je scenario_1
    cmp eax, 2
    je scenario_2
    cmp eax, 3
    je scenario_3
    cmp eax, 4
    je scenario_4
    cmp eax, 5
    je scenario_5
    jmp scenario_6

; Text.scan without default creates default + InputRow/Prompt/Input.
scenario_1:
    call setup_runtime
    test eax, eax
    jnz test_fail
    lea rdi, [rel route_a]
    mov esi, NEBO_SCAN_ROUTE_TEXT_DEFAULT_ROW
    lea rdx, [rel prompt_name]
    mov ecx, 101
    mov r8d, 1001
    mov r9d, 1
    call build_route
    lea rdi, [rel input_runtime]
    lea rsi, [rel route_a]
    call nebo_console_scan_route
    test eax, eax
    jnz test_fail
    cmp qword [rel context+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET], 1
    jne test_fail
    mov rax, [rel route_a+NEBO_SCAN_ROUTE_OUT_CONSOLE_HANDLE_OFFSET]
    test rax, rax
    jz test_fail
    cmp rax, [rel context+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_DEFAULT_HANDLE_OFFSET]
    jne test_fail
    cmp qword [rel route_a+NEBO_SCAN_ROUTE_OUT_ROW_NODE_ID_OFFSET], 0
    je test_fail
    cmp qword [rel route_a+NEBO_SCAN_ROUTE_OUT_PROMPT_NODE_ID_OFFSET], 0
    je test_fail
    cmp qword [rel route_a+NEBO_SCAN_ROUTE_OUT_INPUT_NODE_ID_OFFSET], 0
    je test_fail
    mov [rel handle_a], rax
    call get_domain_document
    test eax, eax
    jnz test_fail
    mov rdi, [rel domain_ptr]
    mov rdi, [rdi+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
    mov rsi, [rel route_a+NEBO_SCAN_ROUTE_OUT_ROW_NODE_ID_OFFSET]
    lea rdx, [rel node_ptr]
    call nebo_console_document_node_from_id
    test eax, eax
    jnz test_fail
    mov rax, [rel node_ptr]
    cmp dword [rax+NEBO_CONSOLE_NODE_KIND_OFFSET], NEBO_CONSOLE_NODE_KIND_INPUT_ROW
    jne test_fail
    mov rsi, [rel route_a+NEBO_SCAN_ROUTE_OUT_PROMPT_NODE_ID_OFFSET]
    mov rdi, [rel domain_ptr]
    mov rdi, [rdi+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
    lea rdx, [rel node_ptr]
    call nebo_console_document_node_from_id
    test eax, eax
    jnz test_fail
    mov rax, [rel node_ptr]
    cmp dword [rax+NEBO_CONSOLE_NODE_KIND_OFFSET], NEBO_CONSOLE_NODE_KIND_PROMPT
    jne test_fail
    mov rsi, [rel route_a+NEBO_SCAN_ROUTE_OUT_INPUT_NODE_ID_OFFSET]
    mov rdi, [rel domain_ptr]
    mov rdi, [rdi+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
    lea rdx, [rel node_ptr]
    call nebo_console_document_node_from_id
    test eax, eax
    jnz test_fail
    mov rax, [rel node_ptr]
    cmp dword [rax+NEBO_CONSOLE_NODE_KIND_OFFSET], NEBO_CONSOLE_NODE_KIND_INPUT
    jne test_fail
    mov rdi, [rel domain_ptr]
    mov rdi, [rdi+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
    call nebo_console_document_audit_links
    test eax, eax
    jnz test_fail
    jmp test_pass

; Text.scan after output inserts a leading logical line break.
scenario_2:
    call setup_runtime
    test eax, eax
    jnz test_fail
    lea rdi, [rel context]
    lea rsi, [rel handle_a]
    call nebo_console_manager_default_get_or_create
    test eax, eax
    jnz test_fail
    call get_domain_document
    test eax, eax
    jnz test_fail
    mov rdi, [rel domain_ptr]
    mov rdi, [rdi+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
    lea rsi, [rel prefix_text]
    call nebo_console_document_append_text
    test eax, eax
    jnz test_fail
    lea rdi, [rel route_a]
    mov esi, NEBO_SCAN_ROUTE_TEXT_DEFAULT_ROW
    lea rdx, [rel prompt_name]
    mov ecx, 102
    mov r8d, 1002
    mov r9d, 2
    call build_route
    lea rdi, [rel input_runtime]
    lea rsi, [rel route_a]
    call nebo_console_scan_route
    test eax, eax
    jnz test_fail
    cmp qword [rel route_a+NEBO_SCAN_ROUTE_OUT_ROW_NODE_ID_OFFSET], 4
    jne test_fail
    mov rdi, [rel domain_ptr]
    mov rdi, [rdi+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
    mov esi, 3
    lea rdx, [rel node_ptr]
    call nebo_console_document_node_from_id
    test eax, eax
    jnz test_fail
    mov rax, [rel node_ptr]
    cmp dword [rax+NEBO_CONSOLE_NODE_KIND_OFFSET], NEBO_CONSOLE_NODE_KIND_LINE_BREAK
    jne test_fail
    jmp test_pass

; Console.scan reuses target Console and lays out input inline.
scenario_3:
    call setup_runtime
    test eax, eax
    jnz test_fail
    lea rdi, [rel context]
    lea rsi, [rel handle_a]
    call nebo_console_manager_default_get_or_create
    test eax, eax
    jnz test_fail
    call get_domain_document
    test eax, eax
    jnz test_fail
    mov rdi, [rel domain_ptr]
    mov rdi, [rdi+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
    lea rsi, [rel prompt_student]
    call nebo_console_document_append_text
    test eax, eax
    jnz test_fail
    lea rdi, [rel route_a]
    mov esi, NEBO_SCAN_ROUTE_CONSOLE_INLINE
    xor edx, edx
    mov ecx, 103
    mov r8d, 1003
    mov r9d, 3
    call build_route
    mov rax, [rel handle_a]
    mov [rel route_a+NEBO_SCAN_ROUTE_TARGET_CONSOLE_HANDLE_OFFSET], rax
    lea rdi, [rel input_runtime]
    lea rsi, [rel route_a]
    call nebo_console_scan_route
    test eax, eax
    jnz test_fail
    mov rax, [rel route_a+NEBO_SCAN_ROUTE_OUT_CONSOLE_HANDLE_OFFSET]
    cmp rax, [rel handle_a]
    jne test_fail
    cmp qword [rel context+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET], 1
    jne test_fail
    lea rdi, [rel provider]
    call nebo_fake_glyph_provider_init
    test eax, eax
    jnz test_fail
    lea rdi, [rel layout]
    lea rsi, [rel layout_boxes]
    mov edx, TEST_LAYOUT_CAPACITY
    mov ecx, NEBO_LAYOUT_DEFAULT_WIDTH
    mov r8, NEBO_LAYOUT_DEFAULT_HEIGHT
    lea r9, [rel provider]
    call nebo_console_layout_init
    test eax, eax
    jnz test_fail
    lea rdi, [rel layout]
    mov rsi, [rel domain_ptr]
    mov rsi, [rsi+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
    call nebo_console_layout_document
    test eax, eax
    jnz test_fail
    cmp qword [rel layout+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET], 4
    jne test_fail
    lea rax, [rel layout_boxes+2*NEBO_LAYOUT_BOX_SIZE]
    cmp dword [rax+NEBO_LAYOUT_BOX_KIND_OFFSET], NEBO_LAYOUT_BOX_KIND_TEXT
    jne test_fail
    lea rbx, [rel layout_boxes+3*NEBO_LAYOUT_BOX_SIZE]
    cmp dword [rbx+NEBO_LAYOUT_BOX_KIND_OFFSET], NEBO_LAYOUT_BOX_KIND_INPUT_INLINE
    jne test_fail
    mov rcx, [rax+NEBO_LAYOUT_BOX_Y_OFFSET]
    cmp rcx, [rbx+NEBO_LAYOUT_BOX_Y_OFFSET]
    jne test_fail
    jmp test_pass

; Text.console().scan creates an independent anonymous Console and inline input.
scenario_4:
    call setup_runtime
    test eax, eax
    jnz test_fail
    lea rdi, [rel route_a]
    mov esi, NEBO_SCAN_ROUTE_ANONYMOUS_INLINE
    lea rdx, [rel prompt_student]
    mov ecx, 104
    mov r8d, 1004
    mov r9d, 4
    call build_route
    lea rdi, [rel input_runtime]
    lea rsi, [rel route_a]
    call nebo_console_scan_route
    test eax, eax
    jnz test_fail
    mov rax, [rel route_a+NEBO_SCAN_ROUTE_OUT_CONSOLE_HANDLE_OFFSET]
    mov [rel handle_a], rax
    lea rdi, [rel context]
    mov rsi, rax
    lea rdx, [rel slot_ptr]
    call nebo_console_manager_handle_validate
    test eax, eax
    jnz test_fail
    mov rax, [rel slot_ptr]
    cmp dword [rax+NEBO_CONSOLE_SLOT_KIND_OFFSET], NEBO_CONSOLE_KIND_ANONYMOUS
    jne test_fail
    cmp qword [rel route_a+NEBO_SCAN_ROUTE_OUT_ROW_NODE_ID_OFFSET], 0
    jne test_fail
    cmp qword [rel route_a+NEBO_SCAN_ROUTE_OUT_PROMPT_NODE_ID_OFFSET], 2
    jne test_fail
    cmp qword [rel route_a+NEBO_SCAN_ROUTE_OUT_INPUT_NODE_ID_OFFSET], 3
    jne test_fail
    jmp test_pass

; Cursor advances to the line following the created input.
scenario_5:
    call setup_runtime
    test eax, eax
    jnz test_fail
    lea rdi, [rel route_a]
    mov esi, NEBO_SCAN_ROUTE_TEXT_DEFAULT_ROW
    lea rdx, [rel prompt_name]
    mov ecx, 105
    mov r8d, 1005
    mov r9d, 5
    call build_route
    lea rdi, [rel input_runtime]
    lea rsi, [rel route_a]
    call nebo_console_scan_route
    test eax, eax
    jnz test_fail
    mov rax, [rel route_a+NEBO_SCAN_ROUTE_OUT_CONSOLE_HANDLE_OFFSET]
    mov [rel handle_a], rax
    call get_domain_document
    test eax, eax
    jnz test_fail
    mov rbx, [rel domain_ptr]
    mov rbx, [rbx+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
    cmp qword [rbx+NEBO_CONSOLE_DOCUMENT_CURSOR_MODE_OFFSET], NEBO_CONSOLE_CURSOR_MODE_NEW_LINE
    jne test_fail
    cmp qword [rbx+NEBO_CONSOLE_DOCUMENT_CURSOR_INLINE_OFFSET], 0
    jne test_fail
    mov rsi, [rbx+NEBO_CONSOLE_DOCUMENT_CURSOR_AFTER_NODE_ID_OFFSET]
    mov rdi, rbx
    lea rdx, [rel node_ptr]
    call nebo_console_document_node_from_id
    test eax, eax
    jnz test_fail
    mov rax, [rel node_ptr]
    cmp dword [rax+NEBO_CONSOLE_NODE_KIND_OFFSET], NEBO_CONSOLE_NODE_KIND_LINE_BREAK
    jne test_fail
    jmp test_pass

; Multiple inputs remain PENDING with stable Binding/Pending metadata.
scenario_6:
    call setup_runtime
    test eax, eax
    jnz test_fail
    lea rdi, [rel context]
    lea rsi, [rel handle_a]
    call nebo_console_manager_default_get_or_create
    test eax, eax
    jnz test_fail
    lea rdi, [rel route_a]
    mov esi, NEBO_SCAN_ROUTE_CONSOLE_INLINE
    xor edx, edx
    mov ecx, 201
    mov r8d, 2001
    mov r9d, 10
    call build_route
    mov rax, [rel handle_a]
    mov [rel route_a+NEBO_SCAN_ROUTE_TARGET_CONSOLE_HANDLE_OFFSET], rax
    lea rdi, [rel input_runtime]
    lea rsi, [rel route_a]
    call nebo_console_scan_route
    test eax, eax
    jnz test_fail
    lea rdi, [rel route_b]
    mov esi, NEBO_SCAN_ROUTE_CONSOLE_INLINE
    xor edx, edx
    mov ecx, 202
    mov r8d, 2002
    mov r9d, 11
    call build_route
    mov rax, [rel handle_a]
    mov [rel route_b+NEBO_SCAN_ROUTE_TARGET_CONSOLE_HANDLE_OFFSET], rax
    lea rdi, [rel input_runtime]
    lea rsi, [rel route_b]
    call nebo_console_scan_route
    test eax, eax
    jnz test_fail
    mov rdi, [rel input_registry_ptr]
    test rdi, rdi
    jnz .registries_ready
    lea rdi, [rel input_runtime]
    mov rsi, [rel handle_a]
    lea rdx, [rel input_registry_ptr]
    lea rcx, [rel pending_registry_ptr]
    call nebo_input_runtime_registry_for_console
    test eax, eax
    jnz test_fail
.registries_ready:
    mov rax, [rel input_registry_ptr]
    cmp qword [rax+NEBO_INPUT_REGISTRY_ACTIVE_COUNT_OFFSET], 2
    jne test_fail
    mov rbx, [rel pending_registry_ptr]
    cmp qword [rbx+NEBO_PENDING_REGISTRY_ACTIVE_COUNT_OFFSET], 2
    jne test_fail
    mov rsi, [rel route_a+NEBO_SCAN_ROUTE_OUT_INPUT_HANDLE_OFFSET]
    cmp rsi, [rel route_b+NEBO_SCAN_ROUTE_OUT_INPUT_HANDLE_OFFSET]
    je test_fail
    mov rdi, rax
    lea rdx, [rel record_a]
    call nebo_input_registry_get
    test eax, eax
    jnz test_fail
    mov rax, [rel record_a]
    cmp qword [rax+NEBO_INPUT_RECORD_BINDING_ID_OFFSET], 201
    jne test_fail
    cmp qword [rax+NEBO_INPUT_RECORD_COMPILER_PENDING_ID_OFFSET], 2001
    jne test_fail
    cmp dword [rax+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_PENDING
    jne test_fail
    mov rdi, [rel pending_registry_ptr]
    mov rsi, [rel route_b+NEBO_SCAN_ROUTE_OUT_PENDING_HANDLE_OFFSET]
    lea rdx, [rel record_b]
    call nebo_pending_registry_get
    test eax, eax
    jnz test_fail
    mov rax, [rel record_b]
    cmp qword [rax+NEBO_PENDING_RECORD_BINDING_ID_OFFSET], 202
    jne test_fail
    cmp qword [rax+NEBO_PENDING_RECORD_COMPILER_PENDING_ID_OFFSET], 2002
    jne test_fail
    cmp dword [rax+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_PENDING
    jne test_fail
    lea rdi, [rel context]
    mov rsi, [rel handle_a]
    lea rdx, [rel slot_ptr]
    call nebo_console_manager_handle_validate
    test eax, eax
    jnz test_fail
    mov rax, [rel slot_ptr]
    cmp qword [rax+NEBO_CONSOLE_SLOT_PENDING_COUNT_OFFSET], 2
    jne test_fail
    jmp test_pass

; build_route(desc*, kind, prompt*, binding, pending, source)
build_route:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov rbx, rdi
    mov r12d, esi
    mov r13, rdx
    mov r14, rcx
    mov r15, r8
    mov [rsp], r9
    mov rdi, rbx
    xor eax, eax
    mov ecx, NEBO_SCAN_ROUTE_DESCRIPTOR_QWORDS
    cld
    rep stosq
    mov [rbx+NEBO_SCAN_ROUTE_KIND_OFFSET], r12d
    mov dword [rbx+NEBO_SCAN_ROUTE_FLAGS_OFFSET], NEBO_SCAN_ROUTE_REQUIRED_FLAGS
    mov [rbx+NEBO_SCAN_ROUTE_PROMPT_DESCRIPTOR_PTR_OFFSET], r13
    mov [rbx+NEBO_SCAN_ROUTE_BINDING_ID_OFFSET], r14
    mov [rbx+NEBO_SCAN_ROUTE_COMPILER_PENDING_ID_OFFSET], r15
    mov rax, [rsp]
    mov [rbx+NEBO_SCAN_ROUTE_SOURCE_ORDER_OFFSET], rax
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

setup_runtime:
    push rbx
    sub rsp, 16
    lea rdi, [rel context]
    lea rsi, [rel slots]
    mov edx, TEST_CONSOLE_CAPACITY
    mov ecx, NEBO_CONSOLE_RUNTIME_ABI_VERSION
    call nebo_console_runtime_context_init
    test eax, eax
    jnz .setup_done
    lea rax, [rel clock]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_CLOCK_PTR_OFFSET], rax
    lea rax, [rel platform]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_PLATFORM_PTR_OFFSET], rax
    lea rax, [rel scheduler]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_SCHEDULER_PTR_OFFSET], rax
    lea rax, [rel domains]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAINS_PTR_OFFSET], rax
    lea rax, [rel command_buffers]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_COMMAND_BUFFERS_PTR_OFFSET], rax
    lea rax, [rel event_buffers]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_EVENT_BUFFERS_PTR_OFFSET], rax
    mov qword [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAIN_CAPACITY_OFFSET], TEST_CONSOLE_CAPACITY
    mov qword [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_QUEUE_CAPACITY_OFFSET], TEST_QUEUE_CAPACITY
    lea rax, [rel documents]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENTS_PTR_OFFSET], rax
    lea rax, [rel nodes]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_NODES_PTR_OFFSET], rax
    lea rax, [rel text_store]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_TEXT_PTR_OFFSET], rax
    mov qword [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_NODE_CAPACITY_OFFSET], TEST_NODE_CAPACITY
    mov qword [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_TEXT_CAPACITY_OFFSET], TEST_TEXT_CAPACITY
    mov qword [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_FLAGS_OFFSET], NEBO_CONSOLE_CONTEXT_DOCUMENT_REQUIRED_FLAGS
    lea rdi, [rel context]
    lea rsi, [rel headless_storage]
    call nebo_console_runtime_headless_bind
    test eax, eax
    jnz .setup_done
    lea rax, [rel input_registries]
    mov [rel input_storage+NEBO_INPUT_RUNTIME_STORAGE_INPUT_REGISTRIES_PTR_OFFSET], rax
    lea rax, [rel input_records]
    mov [rel input_storage+NEBO_INPUT_RUNTIME_STORAGE_INPUT_RECORDS_PTR_OFFSET], rax
    lea rax, [rel pending_registries]
    mov [rel input_storage+NEBO_INPUT_RUNTIME_STORAGE_PENDING_REGISTRIES_PTR_OFFSET], rax
    lea rax, [rel pending_records]
    mov [rel input_storage+NEBO_INPUT_RUNTIME_STORAGE_PENDING_RECORDS_PTR_OFFSET], rax
    mov qword [rel input_storage+NEBO_INPUT_RUNTIME_STORAGE_CONSOLE_CAPACITY_OFFSET], TEST_CONSOLE_CAPACITY
    mov qword [rel input_storage+NEBO_INPUT_RUNTIME_STORAGE_INPUT_CAPACITY_OFFSET], TEST_INPUT_CAPACITY
    lea rdi, [rel input_runtime]
    lea rsi, [rel context]
    lea rdx, [rel input_storage]
    call nebo_input_runtime_init
.setup_done:
    add rsp, 16
    pop rbx
    ret

; handle_a must contain the target. Stores domain_ptr and registry pointers.
get_domain_document:
    sub rsp, 8
    lea rdi, [rel context]
    mov rsi, [rel handle_a]
    lea rdx, [rel domain_ptr]
    call nebo_console_domain_from_handle
    test eax, eax
    jnz .get_done
    lea rdi, [rel input_runtime]
    mov rsi, [rel handle_a]
    lea rdx, [rel input_registry_ptr]
    lea rcx, [rel pending_registry_ptr]
    call nebo_input_runtime_registry_for_console
.get_done:
    add rsp, 8
    ret

test_pass:
    xor edi, edi
    jmp neboc_host_process_exit

test_fail:
    mov edi, 1
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
