; NPT-CONSOLE-SCAN-CLOSE-001 exact routed cancellation state oracle.
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/manager/console_manager.inc"
%include "runtime/console/domain/console_domain.inc"
%include "runtime/console/document/console_document.inc"
%include "runtime/console/platform/fake/fake_platform.inc"
%include "runtime/console/input/routing/scan_routing.inc"

extern nebo_console_runtime_context_init
extern nebo_console_runtime_headless_bind
extern nebo_console_manager_named_create
extern nebo_console_manager_handle_validate
extern nebo_input_runtime_init
extern nebo_input_runtime_registry_for_console
extern nebo_console_scan_route
extern nebo_console_scan_cancel
extern nebo_input_registry_get
extern nebo_pending_registry_get

global _start

%define TEST_CONSOLE_CAPACITY 2
%define TEST_QUEUE_CAPACITY 8
%define TEST_NODE_CAPACITY 256
%define TEST_TEXT_CAPACITY 4096
%define TEST_INPUT_CAPACITY 64
%define TEST_CYCLES 32

section .rodata align=8
console_name_bytes: db "scan-close"
console_name:
    dq console_name_bytes, 10
    dd 0
    dw NEBO_RUNTIME_TEXT_ENCODING_UTF8, NEBO_RUNTIME_TEXT_LIFETIME_STATIC

section .bss align=64
context: resb NEBO_CONSOLE_CONTEXT_SIZE
slots: resb TEST_CONSOLE_CAPACITY*NEBO_CONSOLE_SLOT_SIZE
clock: resb NEBO_FAKE_CLOCK_SIZE
fake_platform: resb NEBO_FAKE_PLATFORM_SIZE
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
route: resb NEBO_SCAN_ROUTE_DESCRIPTOR_SIZE
console_handle: resq 1
slot_ptr: resq 1
input_registry_ptr: resq 1
pending_registry_ptr: resq 1
input_record_ptr: resq 1
pending_record_ptr: resq 1
saved_input_record_ptr: resq 1
saved_pending_record_ptr: resq 1
saved_input_handle: resq 1
saved_pending_handle: resq 1

section .text
_start:
    call setup_runtime
    test eax, eax
    jnz fail_10
    lea rdi, [rel context]
    lea rsi, [rel console_name]
    lea rdx, [rel console_handle]
    call nebo_console_manager_named_create
    test eax, eax
    jnz fail_11
    xor r12d, r12d
.cycle:
    cmp r12d, TEST_CYCLES
    jae .cycles_done
    lea rdi, [rel route]
    xor eax, eax
    mov ecx, NEBO_SCAN_ROUTE_DESCRIPTOR_QWORDS
    cld
    rep stosq
    mov dword [rel route+NEBO_SCAN_ROUTE_KIND_OFFSET], NEBO_SCAN_ROUTE_CONSOLE_INLINE
    mov dword [rel route+NEBO_SCAN_ROUTE_FLAGS_OFFSET], NEBO_SCAN_ROUTE_REQUIRED_FLAGS
    mov rax, [rel console_handle]
    mov [rel route+NEBO_SCAN_ROUTE_TARGET_CONSOLE_HANDLE_OFFSET], rax
    lea eax, [r12d+1001]
    mov [rel route+NEBO_SCAN_ROUTE_BINDING_ID_OFFSET], rax
    lea eax, [r12d+2001]
    mov [rel route+NEBO_SCAN_ROUTE_COMPILER_PENDING_ID_OFFSET], rax
    lea eax, [r12d+1]
    mov [rel route+NEBO_SCAN_ROUTE_SOURCE_ORDER_OFFSET], rax
    lea rdi, [rel input_runtime]
    lea rsi, [rel route]
    call nebo_console_scan_route
    test eax, eax
    jnz fail_20

    mov rax, [rel route+NEBO_SCAN_ROUTE_OUT_INPUT_HANDLE_OFFSET]
    mov [rel saved_input_handle], rax
    test rax, rax
    jz fail_21
    mov rax, [rel route+NEBO_SCAN_ROUTE_OUT_PENDING_HANDLE_OFFSET]
    mov [rel saved_pending_handle], rax
    test rax, rax
    jz fail_22
    lea rdi, [rel input_runtime]
    mov rsi, [rel console_handle]
    lea rdx, [rel input_registry_ptr]
    lea rcx, [rel pending_registry_ptr]
    call nebo_input_runtime_registry_for_console
    test eax, eax
    jnz fail_23
    lea rdi, [rel context]
    mov rsi, [rel console_handle]
    lea rdx, [rel slot_ptr]
    call nebo_console_manager_handle_validate
    test eax, eax
    jnz fail_24
    mov rdi, [rel input_registry_ptr]
    mov rsi, [rel saved_input_handle]
    lea rdx, [rel input_record_ptr]
    call nebo_input_registry_get
    test eax, eax
    jnz fail_25
    mov rdi, [rel pending_registry_ptr]
    mov rsi, [rel saved_pending_handle]
    lea rdx, [rel pending_record_ptr]
    call nebo_pending_registry_get
    test eax, eax
    jnz fail_26
    mov rax, [rel input_record_ptr]
    mov [rel saved_input_record_ptr], rax
    mov rax, [rel pending_record_ptr]
    mov [rel saved_pending_record_ptr], rax
    cmp qword [rel input_registry_ptr+0], 0
    je fail_27
    mov rax, [rel input_registry_ptr]
    cmp qword [rax+NEBO_INPUT_REGISTRY_ACTIVE_COUNT_OFFSET], 1
    jne fail_28
    mov rax, [rel pending_registry_ptr]
    cmp qword [rax+NEBO_PENDING_REGISTRY_ACTIVE_COUNT_OFFSET], 1
    jne fail_29
    mov rax, [rel slot_ptr]
    cmp qword [rax+NEBO_CONSOLE_SLOT_PENDING_COUNT_OFFSET], 1
    jne fail_30

    ; One cycle models partial editor/validation state. Cancellation must clear
    ; transient validation metadata without manufacturing a value.
    cmp r12d, 3
    jne .mismatch_or_cancel
    mov rax, [rel input_record_ptr]
    or dword [rax+NEBO_INPUT_RECORD_FLAGS_OFFSET], NEBO_INPUT_FLAG_VALIDATION_ERROR
    mov qword [rax+NEBO_INPUT_RECORD_VALIDATION_ERROR_OFFSET], 77
.mismatch_or_cancel:
    ; Prove a mismatched route is rejected without changing the pair.
    cmp r12d, 0
    jne .cancel
    inc qword [rel route+NEBO_SCAN_ROUTE_BINDING_ID_OFFSET]
    lea rdi, [rel input_runtime]
    lea rsi, [rel route]
    call nebo_console_scan_cancel
    test eax, eax
    jz fail_31
    dec qword [rel route+NEBO_SCAN_ROUTE_BINDING_ID_OFFSET]
    mov rax, [rel input_record_ptr]
    cmp dword [rax+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_PENDING
    jne fail_32
.cancel:
    lea rdi, [rel input_runtime]
    lea rsi, [rel route]
    call nebo_console_scan_cancel
    test eax, eax
    jnz fail_33
    cmp qword [rel route+NEBO_SCAN_ROUTE_OUT_INPUT_HANDLE_OFFSET], 0
    jne fail_34
    cmp qword [rel route+NEBO_SCAN_ROUTE_OUT_PENDING_HANDLE_OFFSET], 0
    jne fail_35
    mov rax, [rel saved_input_record_ptr]
    cmp dword [rax+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_CANCELLED
    jne fail_36
    test dword [rax+NEBO_INPUT_RECORD_FLAGS_OFFSET], (NEBO_INPUT_FLAG_ACTIVE | NEBO_INPUT_FLAG_VALIDATION_ERROR)
    jnz fail_37
    cmp qword [rax+NEBO_INPUT_RECORD_VALIDATION_ERROR_OFFSET], 0
    jne fail_38
    mov rax, [rel saved_pending_record_ptr]
    cmp dword [rax+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_CANCELLED
    jne fail_39
    test qword [rax+NEBO_PENDING_RECORD_FLAGS_OFFSET], NEBO_PENDING_FLAG_ACTIVE
    jnz fail_40
    cmp qword [rax+NEBO_PENDING_RECORD_RESULT_LENGTH_OFFSET], 0
    jne fail_41
    cmp qword [rax+NEBO_PENDING_RECORD_RESOLUTION_SEQUENCE_OFFSET], 0
    je fail_42
    mov rax, [rel input_registry_ptr]
    cmp qword [rax+NEBO_INPUT_REGISTRY_ACTIVE_COUNT_OFFSET], 0
    jne fail_43
    mov rax, [rel pending_registry_ptr]
    cmp qword [rax+NEBO_PENDING_REGISTRY_ACTIVE_COUNT_OFFSET], 0
    jne fail_44
    mov rax, [rel slot_ptr]
    cmp qword [rax+NEBO_CONSOLE_SLOT_PENDING_COUNT_OFFSET], 0
    jne fail_45

    ; Old generational handles no longer resolve after cancellation.
    mov rdi, [rel input_registry_ptr]
    mov rsi, [rel saved_input_handle]
    lea rdx, [rel input_record_ptr]
    call nebo_input_registry_get
    test eax, eax
    jz fail_46
    mov rdi, [rel pending_registry_ptr]
    mov rsi, [rel saved_pending_handle]
    lea rdx, [rel pending_record_ptr]
    call nebo_pending_registry_get
    test eax, eax
    jz fail_47

    ; A duplicate cancellation cannot decrement accounting again.
    lea rdi, [rel input_runtime]
    lea rsi, [rel route]
    call nebo_console_scan_cancel
    test eax, eax
    jz fail_48
    mov rax, [rel input_registry_ptr]
    cmp qword [rax+NEBO_INPUT_REGISTRY_ACTIVE_COUNT_OFFSET], 0
    jne fail_49
    inc r12d
    jmp .cycle
.cycles_done:
    mov rax, [rel input_registry_ptr]
    cmp qword [rax+NEBO_INPUT_REGISTRY_CREATED_COUNT_OFFSET], TEST_CYCLES
    jne fail_50
    mov rax, [rel pending_registry_ptr]
    cmp qword [rax+NEBO_PENDING_REGISTRY_CREATED_COUNT_OFFSET], TEST_CYCLES
    jne fail_51
    xor edi, edi
    jmp exit_process

setup_runtime:
    push rbx
    sub rsp, 16
    lea rdi, [rel context]
    lea rsi, [rel slots]
    mov edx, TEST_CONSOLE_CAPACITY
    mov ecx, NEBO_CONSOLE_RUNTIME_ABI_VERSION
    call nebo_console_runtime_context_init
    test eax, eax
    jnz .done
    lea rax, [rel clock]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_CLOCK_PTR_OFFSET], rax
    lea rax, [rel fake_platform]
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
    jnz .done
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
.done:
    add rsp, 16
    pop rbx
    ret

fail_10: mov edi,10
    jmp exit_process
fail_11: mov edi,11
    jmp exit_process
fail_20: mov edi,20
    jmp exit_process
fail_21: mov edi,21
    jmp exit_process
fail_22: mov edi,22
    jmp exit_process
fail_23: mov edi,23
    jmp exit_process
fail_24: mov edi,24
    jmp exit_process
fail_25: mov edi,25
    jmp exit_process
fail_26: mov edi,26
    jmp exit_process
fail_27: mov edi,27
    jmp exit_process
fail_28: mov edi,28
    jmp exit_process
fail_29: mov edi,29
    jmp exit_process
fail_30: mov edi,30
    jmp exit_process
fail_31: mov edi,31
    jmp exit_process
fail_32: mov edi,32
    jmp exit_process
fail_33: mov edi,33
    jmp exit_process
fail_34: mov edi,34
    jmp exit_process
fail_35: mov edi,35
    jmp exit_process
fail_36: mov edi,36
    jmp exit_process
fail_37: mov edi,37
    jmp exit_process
fail_38: mov edi,38
    jmp exit_process
fail_39: mov edi,39
    jmp exit_process
fail_40: mov edi,40
    jmp exit_process
fail_41: mov edi,41
    jmp exit_process
fail_42: mov edi,42
    jmp exit_process
fail_43: mov edi,43
    jmp exit_process
fail_44: mov edi,44
    jmp exit_process
fail_45: mov edi,45
    jmp exit_process
fail_46: mov edi,46
    jmp exit_process
fail_47: mov edi,47
    jmp exit_process
fail_48: mov edi,48
    jmp exit_process
fail_49: mov edi,49
    jmp exit_process
fail_50: mov edi,50
    jmp exit_process
fail_51: mov edi,51
exit_process:
    mov eax, 60
    syscall
    ud2

section .note.GNU-stack noalloc noexec nowrite progbits
