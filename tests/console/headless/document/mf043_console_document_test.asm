; Nebo Assembly — MF043 ConsoleDocument scenarios
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/handles/console_handle.inc"
%include "runtime/console/manager/console_manager.inc"
%include "runtime/console/queues/console_queue.inc"
%include "runtime/console/domain/console_domain.inc"
%include "runtime/console/platform/fake/fake_platform.inc"
%include "runtime/console/document/console_document.inc"

extern nebo_console_document_init
extern nebo_console_document_append_text
extern nebo_console_document_append_newline
extern nebo_console_document_append_int
extern nebo_console_document_append_bool
extern nebo_console_document_audit_links
extern nebo_console_document_copy_plain_text
extern nebo_console_document_state_hash
extern nebo_console_runtime_context_init
extern nebo_console_runtime_headless_bind
extern nebo_console_manager_default_get_or_create
extern nebo_console_domain_from_handle
extern nebo_console_domain_send
extern nebo_console_scheduler_run
extern neboc_host_process_exit

global _start

%define TEST_CAPACITY 2
%define TEST_QUEUE_CAPACITY 8
%define TEST_NODE_CAPACITY 16
%define TEST_TEXT_CAPACITY 256

section .rodata align=8
text_ola_bytes: db 'Ola'
text_nebo_bytes: db 'Nebo'
text_olanebo_bytes: db 'OlaNebo'
text_a_bytes: db 'A'
text_b_bytes: db 'B'
text_a_nl_b_bytes: db 'A',10,'B'
text_b_nl_c_bytes: db 'B',10,'C'
text_cursor_bytes: db 'A',10,'B','C'
invalid_utf8_bytes: db 0xC0,0xAF
expected_int_min: db '-9223372036854775808'
expected_true_false: db 'truefalse'

text_ola: dq text_ola_bytes,3
          dd 0
          dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
text_nebo: dq text_nebo_bytes,4
           dd 0
           dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
text_olanebo: dq text_olanebo_bytes,7
              dd 0
              dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
text_a: dq text_a_bytes,1
        dd 0
        dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
text_b: dq text_b_bytes,1
        dd 0
        dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
text_a_nl_b: dq text_a_nl_b_bytes,3
             dd 0
             dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
text_b_nl_c: dq text_b_nl_c_bytes,3
             dd 0
             dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
text_cursor: dq text_cursor_bytes,4
             dd 0
             dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
text_invalid_utf8: dq invalid_utf8_bytes,2
                   dd 0
                   dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC

section .bss align=64
doc_a: resb NEBO_CONSOLE_DOCUMENT_SIZE
nodes_a: resb TEST_NODE_CAPACITY*NEBO_CONSOLE_NODE_HEADER_SIZE
text_store_a: resb TEST_TEXT_CAPACITY
doc_b: resb NEBO_CONSOLE_DOCUMENT_SIZE
nodes_b: resb TEST_NODE_CAPACITY*NEBO_CONSOLE_NODE_HEADER_SIZE
text_store_b: resb TEST_TEXT_CAPACITY
output_a: resb 256
output_b: resb 256
output_len_a: resq 1
output_len_b: resq 1
hash_a: resq 1
hash_b: resq 1

context_rt: resb NEBO_CONSOLE_CONTEXT_SIZE
slots_rt: resb TEST_CAPACITY*NEBO_CONSOLE_SLOT_SIZE
clock_rt: resb NEBO_FAKE_CLOCK_SIZE
platform_rt: resb NEBO_FAKE_PLATFORM_SIZE
scheduler_rt: resb NEBO_CONSOLE_SCHEDULER_SIZE
domains_rt: resb TEST_CAPACITY*NEBO_CONSOLE_DOMAIN_SIZE
command_buffers_rt: resb TEST_CAPACITY*TEST_QUEUE_CAPACITY*NEBO_CONSOLE_COMMAND_DESCRIPTOR_SIZE
event_buffers_rt: resb TEST_CAPACITY*TEST_QUEUE_CAPACITY*NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
documents_rt: resb TEST_CAPACITY*NEBO_CONSOLE_DOCUMENT_SIZE
nodes_rt: resb TEST_CAPACITY*TEST_NODE_CAPACITY*NEBO_CONSOLE_NODE_HEADER_SIZE
text_rt: resb TEST_CAPACITY*TEST_TEXT_CAPACITY
storage_rt: resb NEBO_CONSOLE_HEADLESS_STORAGE_SIZE
handle_rt: resq 1
handle_rt_second: resq 1
domain_rt: resq 1
progress_rt: resq 1
command_rt: resb NEBO_CONSOLE_COMMAND_DESCRIPTOR_SIZE

section .text
_start:
    mov rax, [rsp]
    cmp rax, 2
    jne test_fail
    mov rbx, [rsp+16]
    cmp byte [rbx], '1'
    jne .not_ten
    cmp byte [rbx+1], '0'
    jne .not_ten
    cmp byte [rbx+2], 0
    je scenario_10
.not_ten:
    cmp byte [rbx+1], 0
    jne test_fail
    movzx eax, byte [rbx]
    sub eax, '0'
    cmp eax, 1
    jb test_fail
    cmp eax, 9
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
    cmp eax, 6
    je scenario_6
    cmp eax, 7
    je scenario_7
    cmp eax, 8
    je scenario_8
    jmp scenario_9

; 001 — default Console owns a retained document and ordered TextNode.
scenario_1:
    call init_runtime_default
    test eax, eax
    jnz test_fail
    lea rdi, [rel text_ola]
    call runtime_send_text
    test eax, eax
    jnz test_fail
    call runtime_run
    test eax, eax
    jnz test_fail
    mov rbx, [rel domain_rt]
    mov rbx, [rbx+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
    test rbx, rbx
    jz test_fail
    cmp qword [rbx+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET], 2
    jne test_fail
    mov rax, [rbx+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET]
    add rax, NEBO_CONSOLE_NODE_HEADER_SIZE
    cmp dword [rax+NEBO_CONSOLE_NODE_KIND_OFFSET], NEBO_CONSOLE_NODE_KIND_TEXT
    jne test_fail
    cmp qword [rax+NEBO_CONSOLE_NODE_PAYLOAD_LENGTH_OFFSET], 3
    jne test_fail
    jmp test_pass

; 002 — repeated default get plus two calls produces exact OlaNebo.
scenario_2:
    call init_runtime_default
    test eax, eax
    jnz test_fail
    lea rdi, [rel context_rt]
    lea rsi, [rel handle_rt_second]
    call nebo_console_manager_default_get_or_create
    test eax, eax
    jnz test_fail
    mov rax, [rel handle_rt]
    cmp rax, [rel handle_rt_second]
    jne test_fail
    lea rdi, [rel text_ola]
    call runtime_send_text
    test eax, eax
    jnz test_fail
    lea rdi, [rel text_nebo]
    call runtime_send_text
    test eax, eax
    jnz test_fail
    call runtime_run
    test eax, eax
    jnz test_fail
    mov rbx, [rel domain_rt]
    mov rdi, [rbx+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
    lea rsi, [rel output_a]
    mov edx, 256
    lea rcx, [rel output_len_a]
    call nebo_console_document_copy_plain_text
    test eax, eax
    jnz test_fail
    cmp qword [rel output_len_a], 7
    jne test_fail
    lea rsi, [rel output_a]
    lea rdi, [rel text_olanebo_bytes]
    mov ecx, 7
    call bytes_equal
    test eax, eax
    jz test_fail
    jmp test_pass

; 003 — newline is a logical LineBreak and flattens as one LF byte.
scenario_3:
    call init_doc_a
    test eax, eax
    jnz test_fail
    lea rdi, [rel doc_a]
    lea rsi, [rel text_a_nl_b]
    call nebo_console_document_append_text
    test eax, eax
    jnz test_fail
    cmp qword [rel doc_a+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET], 4
    jne test_fail
    lea rax, [rel nodes_a+2*NEBO_CONSOLE_NODE_HEADER_SIZE]
    cmp dword [rax+NEBO_CONSOLE_NODE_KIND_OFFSET], NEBO_CONSOLE_NODE_KIND_LINE_BREAK
    jne test_fail
    lea rdi, [rel doc_a]
    lea rsi, [rel output_a]
    mov edx, 256
    lea rcx, [rel output_len_a]
    call nebo_console_document_copy_plain_text
    test eax, eax
    jnz test_fail
    cmp qword [rel output_len_a], 3
    jne test_fail
    cmp byte [rel output_a+1], 10
    jne test_fail
    jmp test_pass

; 004 — separate calls synthesize neither spaces nor newline.
scenario_4:
    call init_doc_a
    test eax, eax
    jnz test_fail
    lea rdi, [rel doc_a]
    lea rsi, [rel text_a]
    call nebo_console_document_append_text
    test eax, eax
    jnz test_fail
    lea rdi, [rel doc_a]
    lea rsi, [rel text_b]
    call nebo_console_document_append_text
    test eax, eax
    jnz test_fail
    lea rdi, [rel doc_a]
    lea rsi, [rel output_a]
    mov edx, 256
    lea rcx, [rel output_len_a]
    call nebo_console_document_copy_plain_text
    test eax, eax
    jnz test_fail
    cmp qword [rel output_len_a], 2
    jne test_fail
    cmp byte [rel output_a], 'A'
    jne test_fail
    cmp byte [rel output_a+1], 'B'
    jne test_fail
    jmp test_pass

; 005 — Int64 logical node stores deterministic canonical decimal bytes.
scenario_5:
    call init_doc_a
    test eax, eax
    jnz test_fail
    lea rdi, [rel doc_a]
    mov rsi, 0x8000000000000000
    call nebo_console_document_append_int
    test eax, eax
    jnz test_fail
    lea rdi, [rel doc_a]
    lea rsi, [rel output_a]
    mov edx, 256
    lea rcx, [rel output_len_a]
    call nebo_console_document_copy_plain_text
    test eax, eax
    jnz test_fail
    cmp qword [rel output_len_a], 20
    jne test_fail
    lea rsi, [rel output_a]
    lea rdi, [rel expected_int_min]
    mov ecx, 20
    call bytes_equal
    test eax, eax
    jz test_fail
    lea rax, [rel nodes_a+NEBO_CONSOLE_NODE_HEADER_SIZE]
    cmp dword [rax+NEBO_CONSOLE_NODE_KIND_OFFSET], NEBO_CONSOLE_NODE_KIND_INT
    jne test_fail
    jmp test_pass

; 006 — Bool values render exactly true/false and reject noncanonical input.
scenario_6:
    call init_doc_a
    test eax, eax
    jnz test_fail
    lea rdi, [rel doc_a]
    mov esi, 1
    call nebo_console_document_append_bool
    test eax, eax
    jnz test_fail
    lea rdi, [rel doc_a]
    xor esi, esi
    call nebo_console_document_append_bool
    test eax, eax
    jnz test_fail
    mov r12, [rel doc_a+NEBO_CONSOLE_DOCUMENT_REVISION_OFFSET]
    mov r13, [rel doc_a+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET]
    lea rdi, [rel doc_a]
    mov esi, 2
    call nebo_console_document_append_bool
    cmp eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    jne test_fail
    cmp [rel doc_a+NEBO_CONSOLE_DOCUMENT_REVISION_OFFSET], r12
    jne test_fail
    cmp [rel doc_a+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET], r13
    jne test_fail
    lea rdi, [rel doc_a]
    lea rsi, [rel output_a]
    mov edx, 256
    lea rcx, [rel output_len_a]
    call nebo_console_document_copy_plain_text
    test eax, eax
    jnz test_fail
    cmp qword [rel output_len_a], 9
    jne test_fail
    lea rsi, [rel output_a]
    lea rdi, [rel expected_true_false]
    mov ecx, 9
    call bytes_equal
    test eax, eax
    jz test_fail
    jmp test_pass

; 007 — failed multi-node transaction leaves tree/text/cursor/revision unchanged.
scenario_7:
    lea rdi, [rel doc_a]
    mov rsi, 0x0000000100000000
    lea rdx, [rel nodes_a]
    mov ecx, 4
    lea r8, [rel text_store_a]
    mov r9d, 4
    call nebo_console_document_init
    test eax, eax
    jnz test_fail
    lea rdi, [rel doc_a]
    lea rsi, [rel text_a]
    call nebo_console_document_append_text
    test eax, eax
    jnz test_fail
    mov r12, [rel doc_a+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET]
    mov r13, [rel doc_a+NEBO_CONSOLE_DOCUMENT_TEXT_LENGTH_OFFSET]
    mov r14, [rel doc_a+NEBO_CONSOLE_DOCUMENT_REVISION_OFFSET]
    mov r15, [rel doc_a+NEBO_CONSOLE_DOCUMENT_CURSOR_AFTER_NODE_ID_OFFSET]
    lea rdi, [rel doc_a]
    lea rsi, [rel text_b_nl_c]
    call nebo_console_document_append_text
    cmp eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jne test_fail
    cmp [rel doc_a+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET], r12
    jne test_fail
    cmp [rel doc_a+NEBO_CONSOLE_DOCUMENT_TEXT_LENGTH_OFFSET], r13
    jne test_fail
    cmp [rel doc_a+NEBO_CONSOLE_DOCUMENT_REVISION_OFFSET], r14
    jne test_fail
    cmp [rel doc_a+NEBO_CONSOLE_DOCUMENT_CURSOR_AFTER_NODE_ID_OFFSET], r15
    jne test_fail
    lea rdi, [rel doc_a]
    call nebo_console_document_audit_links
    test eax, eax
    jnz test_fail
    jmp test_pass

; 008 — sibling links are acyclic and audit remains GREEN after mixed nodes.
scenario_8:
    call init_doc_a
    test eax, eax
    jnz test_fail
    lea rdi, [rel doc_a]
    lea rsi, [rel text_a_nl_b]
    call nebo_console_document_append_text
    test eax, eax
    jnz test_fail
    lea rdi, [rel doc_a]
    mov rsi, -42
    call nebo_console_document_append_int
    test eax, eax
    jnz test_fail
    lea rdi, [rel doc_a]
    mov esi, 1
    call nebo_console_document_append_bool
    test eax, eax
    jnz test_fail
    lea rdi, [rel doc_a]
    call nebo_console_document_audit_links
    test eax, eax
    jnz test_fail
    mov rax, [rel nodes_a+NEBO_CONSOLE_NODE_FIRST_CHILD_ID_OFFSET]
    cmp rax, 2
    jne test_fail
    mov rax, [rel nodes_a+NEBO_CONSOLE_NODE_LAST_CHILD_ID_OFFSET]
    cmp rax, 6
    jne test_fail
    jmp test_pass

; 009 — insertion cursor tracks current logical line and inline byte offset.
scenario_9:
    call init_doc_a
    test eax, eax
    jnz test_fail
    lea rdi, [rel doc_a]
    lea rsi, [rel text_cursor]
    call nebo_console_document_append_text
    test eax, eax
    jnz test_fail
    cmp qword [rel doc_a+NEBO_CONSOLE_DOCUMENT_CURSOR_CURRENT_LINE_ID_OFFSET], 3
    jne test_fail
    cmp qword [rel doc_a+NEBO_CONSOLE_DOCUMENT_CURSOR_AFTER_NODE_ID_OFFSET], 4
    jne test_fail
    cmp qword [rel doc_a+NEBO_CONSOLE_DOCUMENT_CURSOR_INLINE_OFFSET], 2
    jne test_fail
    cmp qword [rel doc_a+NEBO_CONSOLE_DOCUMENT_CURSOR_MODE_OFFSET], NEBO_CONSOLE_CURSOR_MODE_INLINE
    jne test_fail
    jmp test_pass

; 010 — coalesced and uncoalesced node shapes flatten to identical semantics.
scenario_10:
    call init_doc_a
    test eax, eax
    jnz test_fail
    call init_doc_b
    test eax, eax
    jnz test_fail
    lea rdi, [rel doc_a]
    lea rsi, [rel text_ola]
    call nebo_console_document_append_text
    test eax, eax
    jnz test_fail
    lea rdi, [rel doc_a]
    lea rsi, [rel text_nebo]
    call nebo_console_document_append_text
    test eax, eax
    jnz test_fail
    lea rdi, [rel doc_b]
    lea rsi, [rel text_olanebo]
    call nebo_console_document_append_text
    test eax, eax
    jnz test_fail
    lea rdi, [rel doc_a]
    lea rsi, [rel output_a]
    mov edx, 256
    lea rcx, [rel output_len_a]
    call nebo_console_document_copy_plain_text
    test eax, eax
    jnz test_fail
    lea rdi, [rel doc_b]
    lea rsi, [rel output_b]
    mov edx, 256
    lea rcx, [rel output_len_b]
    call nebo_console_document_copy_plain_text
    test eax, eax
    jnz test_fail
    mov rcx, [rel output_len_a]
    cmp rcx, [rel output_len_b]
    jne test_fail
    lea rsi, [rel output_a]
    lea rdi, [rel output_b]
    call bytes_equal
    test eax, eax
    jz test_fail
    cmp qword [rel doc_a+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET], 3
    jne test_fail
    cmp qword [rel doc_b+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET], 2
    jne test_fail
    jmp test_pass

init_doc_a:
    lea rdi, [rel doc_a]
    mov rsi, 0x0000000100000000
    lea rdx, [rel nodes_a]
    mov ecx, TEST_NODE_CAPACITY
    lea r8, [rel text_store_a]
    mov r9d, TEST_TEXT_CAPACITY
    jmp nebo_console_document_init

init_doc_b:
    lea rdi, [rel doc_b]
    mov rsi, 0x0000000100000001
    lea rdx, [rel nodes_b]
    mov ecx, TEST_NODE_CAPACITY
    lea r8, [rel text_store_b]
    mov r9d, TEST_TEXT_CAPACITY
    jmp nebo_console_document_init

init_runtime_default:
    push rbx
    sub rsp, 16
    lea rdi, [rel context_rt]
    lea rsi, [rel slots_rt]
    mov edx, TEST_CAPACITY
    mov ecx, NEBO_CONSOLE_RUNTIME_ABI_VERSION
    call nebo_console_runtime_context_init
    test eax, eax
    jnz .runtime_init_done
    lea rax, [rel clock_rt]
    mov [rel storage_rt+NEBO_CONSOLE_HEADLESS_STORAGE_CLOCK_PTR_OFFSET], rax
    lea rax, [rel platform_rt]
    mov [rel storage_rt+NEBO_CONSOLE_HEADLESS_STORAGE_PLATFORM_PTR_OFFSET], rax
    lea rax, [rel scheduler_rt]
    mov [rel storage_rt+NEBO_CONSOLE_HEADLESS_STORAGE_SCHEDULER_PTR_OFFSET], rax
    lea rax, [rel domains_rt]
    mov [rel storage_rt+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAINS_PTR_OFFSET], rax
    lea rax, [rel command_buffers_rt]
    mov [rel storage_rt+NEBO_CONSOLE_HEADLESS_STORAGE_COMMAND_BUFFERS_PTR_OFFSET], rax
    lea rax, [rel event_buffers_rt]
    mov [rel storage_rt+NEBO_CONSOLE_HEADLESS_STORAGE_EVENT_BUFFERS_PTR_OFFSET], rax
    mov qword [rel storage_rt+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAIN_CAPACITY_OFFSET], TEST_CAPACITY
    mov qword [rel storage_rt+NEBO_CONSOLE_HEADLESS_STORAGE_QUEUE_CAPACITY_OFFSET], TEST_QUEUE_CAPACITY
    lea rax, [rel documents_rt]
    mov [rel storage_rt+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENTS_PTR_OFFSET], rax
    lea rax, [rel nodes_rt]
    mov [rel storage_rt+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_NODES_PTR_OFFSET], rax
    lea rax, [rel text_rt]
    mov [rel storage_rt+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_TEXT_PTR_OFFSET], rax
    mov qword [rel storage_rt+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_NODE_CAPACITY_OFFSET], TEST_NODE_CAPACITY
    mov qword [rel storage_rt+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_TEXT_CAPACITY_OFFSET], TEST_TEXT_CAPACITY
    mov qword [rel storage_rt+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_FLAGS_OFFSET], NEBO_CONSOLE_CONTEXT_DOCUMENT_REQUIRED_FLAGS
    lea rdi, [rel context_rt]
    lea rsi, [rel storage_rt]
    call nebo_console_runtime_headless_bind
    test eax, eax
    jnz .runtime_init_done
    lea rdi, [rel context_rt]
    lea rsi, [rel handle_rt]
    call nebo_console_manager_default_get_or_create
    test eax, eax
    jnz .runtime_init_done
    lea rdi, [rel context_rt]
    mov rsi, [rel handle_rt]
    lea rdx, [rel domain_rt]
    call nebo_console_domain_from_handle
    test eax, eax
    jnz .runtime_init_done
    call runtime_run
.runtime_init_done:
    add rsp, 16
    pop rbx
    ret

runtime_send_text:
    push r12
    mov r12, rdi
    lea rdi, [rel command_rt]
    xor eax, eax
    mov ecx, NEBO_CONSOLE_COMMAND_DESCRIPTOR_QWORDS
    cld
    rep stosq
    mov dword [rel command_rt+NEBO_CONSOLE_COMMAND_KIND_OFFSET], NEBO_CONSOLE_COMMAND_APPEND_TEXT
    mov [rel command_rt+NEBO_CONSOLE_COMMAND_PAYLOAD0_OFFSET], r12
    lea rdi, [rel context_rt]
    mov rsi, [rel handle_rt]
    lea rdx, [rel command_rt]
    call nebo_console_domain_send
    pop r12
    ret

runtime_run:
    lea rdi, [rel context_rt]
    mov esi, 4
    lea rdx, [rel progress_rt]
    jmp nebo_console_scheduler_run

; RDI/RSi byte arrays, RCX length. EAX=1 equal, 0 otherwise.
bytes_equal:
    test rcx, rcx
    jz .bytes_equal_yes
    cld
    repe cmpsb
    jne .bytes_equal_no
.bytes_equal_yes:
    mov eax, 1
    ret
.bytes_equal_no:
    xor eax, eax
    ret

test_pass:
    xor edi, edi
    jmp neboc_host_process_exit

test_fail:
    mov edi, 1
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
