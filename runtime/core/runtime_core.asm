; Nebo Runtime Core v0 — no libc, MF049 lifecycle/cancellation/reclaim runtime
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/core/runtime_core.inc"
%include "runtime/textual/text-char-bytes/text_char_bytes_runtime.inc"
%include "runtime/scalars/option_result_runtime.inc"
%include "runtime/console/manager/console_manager.inc"
%include "runtime/console/queues/console_queue.inc"
%include "runtime/console/domain/console_domain.inc"
%include "runtime/console/platform/fake/fake_platform.inc"
%include "runtime/console/document/console_document.inc"
%include "runtime/console/behavior/console_behavior.inc"
%include "runtime/console/renderer-registry/renderer_registry.inc"
%include "runtime/console/renderers/basic/basic_renderer.inc"
%include "runtime/console/render/output_conformance.inc"
%include "runtime/console/input/registry/input_registry.inc"
%include "runtime/console/pending/pending_registry.inc"
%include "runtime/console/input/routing/scan_routing.inc"
%include "runtime/console/input/editing/text_editor.inc"
%include "runtime/console/focus/focus_manager.inc"
%include "runtime/console/dependency-bridge/dependency_bridge.inc"
%include "runtime/console/input/submission/input_submission.inc"
%include "runtime/console/lifecycle/console_lifecycle.inc"
%ifdef NEBO_RUNTIME_PRACTICAL_IO
%include "runtime/textual/scan_plan.inc"
%include "runtime/console/live/live_console.inc"
extern nebo_runtime_live_finalize
extern nebo_runtime_live_scan_roundtrip
%endif

global nebo_runtime_abi_version
global nebo_runtime_start
global nebo_runtime_exit
global nebo_runtime_trap
global nebo_runtime_trap_overflow
global nebo_runtime_trap_division_by_zero
global nebo_runtime_text_equal
global nebo_runtime_numeric_safety_is_negative_zero
global nebo_runtime_numeric_safety_is_infinite
global nebo_runtime_numeric_safety_is_nan
global nebo_runtime_numeric_safety_is_finite
global nebo_runtime_numeric_safety_int_to_float
global nebo_runtime_textual_text_byte_length
global nebo_runtime_textual_text_codepoint_count
global nebo_runtime_textual_char_codepoint
global nebo_runtime_textual_bytes_empty
global nebo_runtime_textual_bytes_byte_length
global nebo_runtime_textual_empty_bytes_descriptor
global neboc_runtime_store_zero_payload
global neboc_runtime_store_integer
global neboc_runtime_store_float
global neboc_runtime_load_tag
global neboc_runtime_load_integer
global neboc_runtime_load_float
global neboc_runtime_tag_test
global neboc_runtime_unwrap_integer
global neboc_runtime_unwrap_float
global neboc_runtime_validate_option
global neboc_runtime_validate_result
global neboc_runtime_roundtrip_integer_aggregate
global neboc_runtime_roundtrip_sse_aggregate
global nebo_runtime_console_ensure_initialized
global nebo_runtime_console_context
global nebo_runtime_console_publish_text
global nebo_runtime_console_publish_int
global nebo_runtime_console_publish_bool
global nebo_runtime_input_ensure_initialized
global nebo_runtime_contract_1
global nebo_runtime_contract_2
global nebo_runtime_contract_3
%ifdef NEBO_RUNTIME_PRACTICAL_IO
global nebo_runtime_scan_stdin_text
global nebo_runtime_scan_console_handle
%endif

section .rodata align=8
nebo_runtime_abi_version: dq NEBO_RUNTIME_ABI_VERSION_V0
align 8
nebo_runtime_textual_empty_bytes_data: db 0
align 8
nebo_runtime_textual_empty_bytes_descriptor:
 dq nebo_runtime_textual_empty_bytes_data
 dq 0
 dd NEBO_RUNTIME_BYTES_FLAGS_EMPTY
 dw NEBO_RUNTIME_BYTES_ELEMENT_WIDTH
 dw NEBO_RUNTIME_LIFETIME_STATIC

section .bss align=64
nebo_runtime_console_context: resb NEBO_CONSOLE_CONTEXT_SIZE
nebo_runtime_console_slots: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_CONSOLE_SLOT_SIZE
nebo_runtime_fake_clock: resb NEBO_FAKE_CLOCK_SIZE
nebo_runtime_fake_platform: resb NEBO_FAKE_PLATFORM_SIZE
nebo_runtime_console_scheduler: resb NEBO_CONSOLE_SCHEDULER_SIZE
nebo_runtime_console_domains: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_CONSOLE_DOMAIN_SIZE
nebo_runtime_console_command_buffers: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_CONSOLE_DEFAULT_QUEUE_CAPACITY*NEBO_CONSOLE_COMMAND_DESCRIPTOR_SIZE
nebo_runtime_console_event_buffers: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_CONSOLE_DEFAULT_QUEUE_CAPACITY*NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
nebo_runtime_console_documents: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_CONSOLE_DOCUMENT_SIZE
nebo_runtime_console_document_nodes: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_CONSOLE_DEFAULT_NODE_CAPACITY*NEBO_CONSOLE_NODE_HEADER_SIZE
nebo_runtime_console_document_text: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_CONSOLE_DEFAULT_TEXT_CAPACITY
nebo_runtime_headless_storage: resb NEBO_CONSOLE_HEADLESS_STORAGE_SIZE
nebo_runtime_input_runtime: resb NEBO_INPUT_RUNTIME_SIZE
nebo_runtime_input_storage: resb NEBO_INPUT_RUNTIME_STORAGE_SIZE
nebo_runtime_input_registries: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_INPUT_REGISTRY_SIZE
nebo_runtime_input_records: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_INPUT_DEFAULT_CAPACITY*NEBO_INPUT_RECORD_SIZE
nebo_runtime_pending_registries: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_PENDING_REGISTRY_SIZE
nebo_runtime_pending_records: resb NEBO_CONSOLE_MAX_ACTIVE*NEBO_INPUT_DEFAULT_CAPACITY*NEBO_PENDING_RECORD_SIZE
%ifdef NEBO_RUNTIME_PRACTICAL_IO
nebo_runtime_process_stack: resq 1
nebo_runtime_publication_count: resq 1
nebo_runtime_last_console_handle: resq 1
nebo_runtime_scan_result_count: resq 1
nebo_runtime_scan_descriptors: resb NEBO_RUNTIME_SCAN_RESULT_CAPACITY*NEBO_RUNTIME_TEXT_DESCRIPTOR_SIZE
nebo_runtime_scan_values: resb NEBO_RUNTIME_SCAN_RESULT_CAPACITY*SCAN_MAX_INPUT_BYTES
nebo_runtime_stdin_buffer: resb SCAN_MAX_INPUT_BYTES
%endif

section .text
; Runtime entry bridge. RDI = pointer to the lowered Nebo start() function.
; The process entry stack is 16-byte aligned before _start calls this function.
; At function entry RSP is therefore 8 mod 16; push RBP restores call alignment.
nebo_runtime_start:
 test rdi,rdi
 jz .invalid_entry
 push rbp
 mov rbp,rsp
 sub rsp,16
 mov [rsp],rdi
%ifdef NEBO_RUNTIME_PRACTICAL_IO
 mov [rel nebo_runtime_process_stack],rsi
%endif
 call nebo_runtime_console_ensure_initialized
 test eax,eax
 jnz .console_init_failed
 mov rdi,[rsp]
 call rdi
%ifdef NEBO_RUNTIME_PRACTICAL_IO
 mov [rsp+8],rax
 cmp qword [rel nebo_runtime_publication_count],0
 je .practical_done
 mov rdi,[rel nebo_runtime_process_stack]
 lea rsi,[rel nebo_runtime_console_context]
 mov rdx,[rel nebo_runtime_last_console_handle]
 call nebo_runtime_live_finalize
 test eax,eax
 jnz .console_init_failed
.practical_done:
 mov rax,[rsp+8]
%endif
 mov edi,eax
 add rsp,16
 pop rbp
 jmp nebo_runtime_exit
.console_init_failed:
 add rsp,16
 pop rbp
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 jmp nebo_runtime_trap
.invalid_entry:
 mov edi,NEBO_RUNTIME_TRAP_INVALID_ENTRY
 jmp nebo_runtime_trap

nebo_runtime_exit:
 mov eax,60
 syscall
 ud2

nebo_runtime_trap:
 mov eax,60
 add edi,128
 syscall
 ud2

nebo_runtime_trap_overflow:
 mov edi,NEBO_RUNTIME_TRAP_INT_OVERFLOW
 jmp nebo_runtime_trap

nebo_runtime_trap_division_by_zero:
 mov edi,NEBO_RUNTIME_TRAP_DIVISION_BY_ZERO
 jmp nebo_runtime_trap


; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-PF005 public numeric-safety foundation helpers.
; signed i64 in RDI -> IEEE binary64 in XMM0, with language rounding isolated
; from ambient MXCSR and the complete caller MXCSR restored.
align 16
nebo_runtime_numeric_safety_int_to_float:
 sub rsp,16
 stmxcsr [rsp]
 mov eax,[rsp]
 and eax,0xffff9fff
 mov [rsp+4],eax
 ldmxcsr [rsp+4]
 cvtsi2sd xmm0,rdi
 ldmxcsr [rsp]
 add rsp,16
 cld
 ret

align 16
nebo_runtime_numeric_safety_is_finite:
 movq rdx,xmm0
 mov rcx,rdx
 shr rcx,52
 and ecx,0x7ff
 cmp ecx,0x7ff
 setne al
 movzx eax,al
 cld
 ret

align 16
nebo_runtime_numeric_safety_is_nan:
 movq rdx,xmm0
 mov rcx,rdx
 shr rcx,52
 and ecx,0x7ff
 cmp ecx,0x7ff
 jne .false
 shl rdx,12
 setnz al
 movzx eax,al
 cld
 ret
.false:
 xor eax,eax
 cld
 ret

align 16
nebo_runtime_numeric_safety_is_infinite:
 movq rdx,xmm0
 mov rcx,rdx
 shr rcx,52
 and ecx,0x7ff
 cmp ecx,0x7ff
 jne .false
 shl rdx,12
 setz al
 movzx eax,al
 cld
 ret
.false:
 xor eax,eax
 cld
 ret

align 16
nebo_runtime_numeric_safety_is_negative_zero:
 movq rdx,xmm0
 mov rax,0x8000000000000000
 cmp rdx,rax
 sete al
 movzx eax,al
 cld
 ret

; TEXT-CHAR-UNICODE-E-BYTES-PF005 public textual foundation helpers.
align 16
nebo_runtime_textual_text_byte_length:
 mov rax,[rdi+NEBO_RUNTIME_TEXT_DESCRIPTOR_LENGTH_OFFSET]
 cld
 ret
align 16
nebo_runtime_textual_text_codepoint_count:
 mov rcx,[rdi+NEBO_RUNTIME_TEXT_DESCRIPTOR_LENGTH_OFFSET]
 mov rsi,[rdi+NEBO_RUNTIME_TEXT_DESCRIPTOR_DATA_OFFSET]
 xor eax,eax
 test rcx,rcx
 jz ._count_done
._count_loop:
 mov dl,[rsi]
 and dl,0xc0
 cmp dl,0x80
 je ._continuation
 inc rax
._continuation:
 inc rsi
 dec rcx
 jnz ._count_loop
._count_done:
 cld
 ret
align 16
nebo_runtime_textual_char_codepoint:
 mov eax,edi
 cld
 ret
align 16
nebo_runtime_textual_bytes_empty:
 lea rax,[rel nebo_runtime_textual_empty_bytes_descriptor]
 cld
 ret
align 16
nebo_runtime_textual_bytes_byte_length:
 mov rax,[rdi+NEBO_RUNTIME_BYTES_DESCRIPTOR_LENGTH_OFFSET]
 cld
 ret

; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-PF005 public runtime integration reuses the PF004 caller-owned primitives.

; RDI=slot, RSI=tag. Canonicalizes all bytes and leaves payload zero.
NEBOC_ABI_FUNCTION neboc_runtime_store_zero_payload
 pxor xmm1,xmm1
 movdqu [rdi],xmm1
 mov byte [rdi+NEBO_RUNTIME_TAG_OFFSET],sil
 ret

; RDI=slot, RSI=tag, RDX=zero-extended or full-width integer payload.
NEBOC_ABI_FUNCTION neboc_runtime_store_integer
 pxor xmm1,xmm1
 movdqu [rdi],xmm1
 mov byte [rdi+NEBO_RUNTIME_TAG_OFFSET],sil
 mov [rdi+NEBO_RUNTIME_PAYLOAD_OFFSET],rdx
 ret

; RDI=slot, RSI=tag, XMM0=binary64 payload.
NEBOC_ABI_FUNCTION neboc_runtime_store_float
 pxor xmm1,xmm1
 movdqu [rdi],xmm1
 mov byte [rdi+NEBO_RUNTIME_TAG_OFFSET],sil
 movq [rdi+NEBO_RUNTIME_PAYLOAD_OFFSET],xmm0
 ret

; RDI=slot -> RAX=zero-extended tag.
NEBOC_ABI_FUNCTION neboc_runtime_load_tag
 movzx eax,byte [rdi+NEBO_RUNTIME_TAG_OFFSET]
 ret

; RDI=slot -> RAX=raw payload bits.
NEBOC_ABI_FUNCTION neboc_runtime_load_integer
 mov rax,[rdi+NEBO_RUNTIME_PAYLOAD_OFFSET]
 ret

; RDI=slot -> XMM0=binary64 payload.
NEBOC_ABI_FUNCTION neboc_runtime_load_float
 movq xmm0,[rdi+NEBO_RUNTIME_PAYLOAD_OFFSET]
 ret

; RDI=slot, RSI=expected tag -> RAX canonical Bool.
NEBOC_ABI_FUNCTION neboc_runtime_tag_test
 movzx eax,byte [rdi+NEBO_RUNTIME_TAG_OFFSET]
 cmp rax,rsi
 sete al
 movzx eax,al
 ret

; RDI=slot, RSI=success tag, RDX=fallback -> RAX payload or fallback.
NEBOC_ABI_FUNCTION neboc_runtime_unwrap_integer
 mov rax,rdx
 cmp byte [rdi+NEBO_RUNTIME_TAG_OFFSET],sil
 jne .done
 mov rax,[rdi+NEBO_RUNTIME_PAYLOAD_OFFSET]
.done:
 ret

; RDI=slot, RSI=success tag, XMM0=fallback -> XMM0 payload or unchanged fallback.
NEBOC_ABI_FUNCTION neboc_runtime_unwrap_float
 cmp byte [rdi+NEBO_RUNTIME_TAG_OFFSET],sil
 jne .done
 movq xmm0,[rdi+NEBO_RUNTIME_PAYLOAD_OFFSET]
.done:
 ret

; Option canonicality: tag 0/1, padding zero, and None payload zero.
NEBOC_ABI_FUNCTION neboc_runtime_validate_option
 movzx eax,byte [rdi]
 cmp eax,1
 ja .bad
 mov rcx,[rdi]
 and rcx,-256
 jnz .bad
 test eax,eax
 jnz .good
 cmp qword [rdi+8],0
 jne .bad
.good:
 mov eax,1
 ret
.bad:
 xor eax,eax
 ret

; Result canonicality: tag 0/1 and padding zero; both variants carry a payload.
NEBOC_ABI_FUNCTION neboc_runtime_validate_result
 movzx eax,byte [rdi]
 cmp eax,1
 ja .bad
 mov rcx,[rdi]
 and rcx,-256
 jnz .bad
 mov eax,1
 ret
.bad:
 xor eax,eax
 ret

; Register-level SysV aggregate prototype for INTEGER/INTEGER values.
; RDI=tag, RSI=payload -> RAX=tag, RDX=payload.
NEBOC_ABI_FUNCTION neboc_runtime_roundtrip_integer_aggregate
 mov rax,rdi
 mov rdx,rsi
 ret

; Register-level SysV aggregate prototype for INTEGER/SSE values.
; RDI=tag, XMM0=payload -> RAX=tag, XMM0=payload.
NEBOC_ABI_FUNCTION neboc_runtime_roundtrip_sse_aggregate
 mov rax,rdi
 ret

; RDI/RSI = TextDescriptor*. EAX = 0/1.
nebo_runtime_text_equal:
 test rdi,rdi
 jz .not_equal
 test rsi,rsi
 jz .not_equal
 mov rax,[rdi+NEBO_RUNTIME_TEXT_LENGTH_OFFSET]
 cmp rax,[rsi+NEBO_RUNTIME_TEXT_LENGTH_OFFSET]
 jne .not_equal
 cmp word [rdi+NEBO_RUNTIME_TEXT_ENCODING_OFFSET],NEBO_RUNTIME_TEXT_ENCODING_UTF8
 jne .not_equal
 cmp word [rsi+NEBO_RUNTIME_TEXT_ENCODING_OFFSET],NEBO_RUNTIME_TEXT_ENCODING_UTF8
 jne .not_equal
 test rax,rax
 jz .equal
 mov rcx,rax
 mov rdi,[rdi+NEBO_RUNTIME_TEXT_DATA_OFFSET]
 mov rsi,[rsi+NEBO_RUNTIME_TEXT_DATA_OFFSET]
 test rdi,rdi
 jz .not_equal
 test rsi,rsi
 jz .not_equal
 cld
 repe cmpsb
 jne .not_equal
.equal:
 mov eax,1
 ret
.not_equal:
 xor eax,eax
 ret

; Initialize and bind the one process-wide deterministic headless runtime.
nebo_runtime_console_ensure_initialized:
 cmp qword [rel nebo_runtime_console_context+NEBO_CONSOLE_CONTEXT_STATE_OFFSET],NEBO_CONSOLE_CONTEXT_STATE_READY
 je .console_ready
 cmp qword [rel nebo_runtime_console_context+NEBO_CONSOLE_CONTEXT_STATE_OFFSET],NEBO_CONSOLE_CONTEXT_STATE_EMPTY
 jne .console_bad_state
 sub rsp,8
 lea rdi,[rel nebo_runtime_console_context]
 lea rsi,[rel nebo_runtime_console_slots]
 mov edx,NEBO_CONSOLE_MAX_ACTIVE
 mov ecx,NEBO_CONSOLE_RUNTIME_ABI_VERSION
 call nebo_console_runtime_context_init
 test eax,eax
 jnz .console_init_done
 lea rax,[rel nebo_runtime_fake_clock]
 mov [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_CLOCK_PTR_OFFSET],rax
 lea rax,[rel nebo_runtime_fake_platform]
 mov [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_PLATFORM_PTR_OFFSET],rax
 lea rax,[rel nebo_runtime_console_scheduler]
 mov [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_SCHEDULER_PTR_OFFSET],rax
 lea rax,[rel nebo_runtime_console_domains]
 mov [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAINS_PTR_OFFSET],rax
 lea rax,[rel nebo_runtime_console_command_buffers]
 mov [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_COMMAND_BUFFERS_PTR_OFFSET],rax
 lea rax,[rel nebo_runtime_console_event_buffers]
 mov [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_EVENT_BUFFERS_PTR_OFFSET],rax
 mov qword [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAIN_CAPACITY_OFFSET],NEBO_CONSOLE_MAX_ACTIVE
 mov qword [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_QUEUE_CAPACITY_OFFSET],NEBO_CONSOLE_DEFAULT_QUEUE_CAPACITY
 lea rax,[rel nebo_runtime_console_documents]
 mov [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENTS_PTR_OFFSET],rax
 lea rax,[rel nebo_runtime_console_document_nodes]
 mov [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_NODES_PTR_OFFSET],rax
 lea rax,[rel nebo_runtime_console_document_text]
 mov [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_TEXT_PTR_OFFSET],rax
 mov qword [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_NODE_CAPACITY_OFFSET],NEBO_CONSOLE_DEFAULT_NODE_CAPACITY
 mov qword [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_TEXT_CAPACITY_OFFSET],NEBO_CONSOLE_DEFAULT_TEXT_CAPACITY
 mov qword [rel nebo_runtime_headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_FLAGS_OFFSET],NEBO_CONSOLE_CONTEXT_DOCUMENT_REQUIRED_FLAGS
 lea rdi,[rel nebo_runtime_console_context]
 lea rsi,[rel nebo_runtime_headless_storage]
 call nebo_console_runtime_headless_bind
.console_init_done:
 add rsp,8
 ret
.console_ready:
 cmp qword [rel nebo_runtime_console_context+NEBO_CONSOLE_CONTEXT_HEADLESS_FLAGS_OFFSET],NEBO_CONSOLE_CONTEXT_HEADLESS_REQUIRED_FLAGS
 jne .console_bad_state
 mov eax,NEBO_CONSOLE_STATUS_OK
 ret
.console_bad_state:
 mov eax,NEBO_CONSOLE_STATUS_BAD_STATE
 ret

; Initialize the process-wide MF046 InputRegistry/PendingRegistry runtime.
nebo_runtime_input_ensure_initialized:
    cmp qword [rel nebo_runtime_input_runtime+NEBO_INPUT_RUNTIME_FLAGS_OFFSET], NEBO_INPUT_RUNTIME_REQUIRED_FLAGS
    je .input_ready
    sub rsp, 8
    call nebo_runtime_console_ensure_initialized
    test eax, eax
    jnz .input_done
    lea rax, [rel nebo_runtime_input_registries]
    mov [rel nebo_runtime_input_storage+NEBO_INPUT_RUNTIME_STORAGE_INPUT_REGISTRIES_PTR_OFFSET], rax
    lea rax, [rel nebo_runtime_input_records]
    mov [rel nebo_runtime_input_storage+NEBO_INPUT_RUNTIME_STORAGE_INPUT_RECORDS_PTR_OFFSET], rax
    lea rax, [rel nebo_runtime_pending_registries]
    mov [rel nebo_runtime_input_storage+NEBO_INPUT_RUNTIME_STORAGE_PENDING_REGISTRIES_PTR_OFFSET], rax
    lea rax, [rel nebo_runtime_pending_records]
    mov [rel nebo_runtime_input_storage+NEBO_INPUT_RUNTIME_STORAGE_PENDING_RECORDS_PTR_OFFSET], rax
    mov qword [rel nebo_runtime_input_storage+NEBO_INPUT_RUNTIME_STORAGE_CONSOLE_CAPACITY_OFFSET], NEBO_CONSOLE_MAX_ACTIVE
    mov qword [rel nebo_runtime_input_storage+NEBO_INPUT_RUNTIME_STORAGE_INPUT_CAPACITY_OFFSET], NEBO_INPUT_DEFAULT_CAPACITY
    lea rdi, [rel nebo_runtime_input_runtime]
    lea rsi, [rel nebo_runtime_console_context]
    lea rdx, [rel nebo_runtime_input_storage]
    call nebo_input_runtime_init
.input_done:
    add rsp, 8
    ret
.input_ready:
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret

; Stable runtime contract 1: default Console logical get-or-create.
; Returns the immutable 64-bit ConsoleHandle in RAX.
nebo_runtime_contract_1:
 sub rsp,24
 call nebo_runtime_console_ensure_initialized
 test eax,eax
 jnz .contract_1_failed
 lea rdi,[rel nebo_runtime_console_context]
 lea rsi,[rsp]
 call nebo_console_manager_default_get_or_create
 test eax,eax
 jnz .contract_1_failed
 mov rax,[rsp]
 add rsp,24
 ret
.contract_1_failed:
 add rsp,24
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 jmp nebo_runtime_trap

; Public source `.console()` publication bridge.  The three typed entries keep
; the source receiver representation explicit, enqueue one retained-document
; command, run the cooperative domain, and return the stable default handle.
; RDI = TextDescriptor* / signed Int / canonical Bool. RAX = ConsoleHandle.
nebo_runtime_console_publish_text:
 mov esi,NEBO_CONSOLE_COMMAND_APPEND_TEXT
 jmp nebo_runtime_console_publish_value

nebo_runtime_console_publish_int:
 mov esi,NEBO_CONSOLE_COMMAND_APPEND_INT
 jmp nebo_runtime_console_publish_value

nebo_runtime_console_publish_bool:
 mov esi,NEBO_CONSOLE_COMMAND_APPEND_BOOL

nebo_runtime_console_publish_value:
 push rbp
 mov rbp,rsp
 sub rsp,96
 mov [rsp+72],rdi
 mov [rsp+80],rsi
 call nebo_runtime_contract_1
 mov [rsp+64],rax
 mov rdi,rsp
 xor eax,eax
 mov ecx,NEBO_CONSOLE_COMMAND_DESCRIPTOR_QWORDS
 cld
 rep stosq
 mov eax,[rsp+80]
 mov [rsp+NEBO_CONSOLE_COMMAND_KIND_OFFSET],eax
 mov rax,[rsp+72]
 mov [rsp+NEBO_CONSOLE_COMMAND_PAYLOAD0_OFFSET],rax
 lea rdi,[rel nebo_runtime_console_context]
 mov rsi,[rsp+64]
 mov rdx,rsp
 call nebo_console_domain_send
 test eax,eax
 jnz .console_publish_failed
 lea rdi,[rel nebo_runtime_console_context]
 mov esi,8
 lea rdx,[rsp+88]
 call nebo_console_scheduler_run
 test eax,eax
 jnz .console_publish_failed
 mov rax,[rsp+64]
%ifdef NEBO_RUNTIME_PRACTICAL_IO
 inc qword [rel nebo_runtime_publication_count]
 mov [rel nebo_runtime_last_console_handle],rax
%endif
 leave
 ret
.console_publish_failed:
 leave
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 jmp nebo_runtime_trap

; Stable runtime contract 2: named Console logical creation from TextDescriptor.
; RDI = immutable UTF-8 TextDescriptor*, RAX = ConsoleHandle.
nebo_runtime_contract_2:
 sub rsp,24
 mov [rsp+8],rdi
 call nebo_runtime_console_ensure_initialized
 test eax,eax
 jnz .contract_2_failed
 lea rdi,[rel nebo_runtime_console_context]
 mov rsi,[rsp+8]
 lea rdx,[rsp]
 call nebo_console_manager_named_create
 test eax,eax
 jnz .contract_2_failed
 mov rax,[rsp]
 add rsp,24
 ret
.contract_2_failed:
 add rsp,24
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 jmp nebo_runtime_trap

; Stable runtime contract 3: anonymous Text.console().scan().
; RDI=TextDescriptor*, RSI=BindingId, RDX=compiler PendingId, RCX=source order.
; Returns PendingHandle in RAX; Console/Input handles remain internal.
nebo_runtime_contract_3:
    push rbp
    mov rbp, rsp
    sub rsp, NEBO_SCAN_ROUTE_DESCRIPTOR_SIZE
    mov r8, rdi
    mov r9, rsi
    mov r10, rdx
    mov r11, rcx
    mov rdi, rsp
    xor eax, eax
    mov ecx, NEBO_SCAN_ROUTE_DESCRIPTOR_QWORDS
    cld
    rep stosq
    mov dword [rsp+NEBO_SCAN_ROUTE_KIND_OFFSET], NEBO_SCAN_ROUTE_ANONYMOUS_INLINE
    mov dword [rsp+NEBO_SCAN_ROUTE_FLAGS_OFFSET], NEBO_SCAN_ROUTE_REQUIRED_FLAGS
    mov [rsp+NEBO_SCAN_ROUTE_PROMPT_DESCRIPTOR_PTR_OFFSET], r8
    mov [rsp+NEBO_SCAN_ROUTE_BINDING_ID_OFFSET], r9
    mov [rsp+NEBO_SCAN_ROUTE_COMPILER_PENDING_ID_OFFSET], r10
    mov [rsp+NEBO_SCAN_ROUTE_SOURCE_ORDER_OFFSET], r11
    call nebo_runtime_input_ensure_initialized
    test eax, eax
    jnz .contract_3_failed
    lea rdi, [rel nebo_runtime_input_runtime]
    mov rsi, rsp
    call nebo_console_scan_route
    test eax, eax
    jnz .contract_3_failed
    mov rax, [rsp+NEBO_SCAN_ROUTE_OUT_PENDING_HANDLE_OFFSET]
    leave
    ret
.contract_3_failed:
    leave
    mov edi, NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
    jmp nebo_runtime_trap

%ifdef NEBO_RUNTIME_PRACTICAL_IO
; Basic canonical Text Scan over stdin.  Prompt bytes are written to stdout,
; acquisition is bounded to ScanPlan's 4096-byte ceiling, and a stable runtime
; Text descriptor is returned only after canonical normalization/validation.
; RDI=prompt TextDescriptor*, RSI/ RDX/ RCX=nonzero compiler route identities.
nebo_runtime_scan_stdin_text:
 push rbp
 mov rbp,rsp
 sub rsp,32
 mov [rsp],rdi
 mov [rsp+8],rsi
 mov [rsp+16],rdx
 mov [rsp+24],rcx
 test rsi,rsi
 jz .stdin_failed
 test rdx,rdx
 jz .stdin_failed
 test rcx,rcx
 jz .stdin_failed
 test rdi,rdi
 jz .stdin_failed
 cmp word [rdi+NEBO_RUNTIME_TEXT_ENCODING_OFFSET],NEBO_RUNTIME_TEXT_ENCODING_UTF8
 jne .stdin_failed
 mov rdx,[rdi+NEBO_RUNTIME_TEXT_LENGTH_OFFSET]
 test rdx,rdx
 jz .stdin_read
 cmp rdx,SCAN_MAX_INPUT_BYTES
 ja .stdin_failed
 mov rsi,[rdi+NEBO_RUNTIME_TEXT_DATA_OFFSET]
 test rsi,rsi
 jz .stdin_failed
.stdin_write:
 mov eax,1
 mov edi,1
 syscall
 test rax,rax
 js .stdin_write_retry
 add rsi,rax
 sub rdx,rax
 jnz .stdin_write
.stdin_read:
 xor eax,eax
 xor edi,edi
 lea rsi,[rel nebo_runtime_stdin_buffer]
 mov edx,SCAN_MAX_INPUT_BYTES
 syscall
 test rax,rax
 js .stdin_read_retry
 test rax,rax
 jz .stdin_failed
 lea rdi,[rel nebo_runtime_stdin_buffer]
 mov rsi,rax
 mov edx,SCAN_SOURCE_STDIN
 call nebo_runtime_scan_store_text
 leave
 ret
.stdin_write_retry:
 cmp rax,-4
 je .stdin_write
 jmp .stdin_failed
.stdin_read_retry:
 cmp rax,-4
 je .stdin_read
.stdin_failed:
 leave
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 jmp nebo_runtime_trap

; Console frontend acquisition.  The canonical route owns document/input/
; pending state; the live frontend only drives normalized events and returns
; the immutable submission result for ScanPlan validation and binding.
; RDI=ConsoleHandle, RSI=BindingId, RDX=PendingId, RCX=source order.
nebo_runtime_scan_console_handle:
 push rbp
 mov rbp,rsp
 sub rsp,208
 mov [rsp+176],rdi
 mov [rsp+184],rsi
 mov [rsp+192],rdx
 mov [rsp+200],rcx
 test rdi,rdi
 jz .console_scan_failed
 test rsi,rsi
 jz .console_scan_failed
 test rdx,rdx
 jz .console_scan_failed
 test rcx,rcx
 jz .console_scan_failed
 mov rdi,rsp
 xor eax,eax
 mov ecx,NEBO_SCAN_ROUTE_DESCRIPTOR_QWORDS
 cld
 rep stosq
 mov dword [rsp+NEBO_SCAN_ROUTE_KIND_OFFSET],NEBO_SCAN_ROUTE_CONSOLE_INLINE
 mov dword [rsp+NEBO_SCAN_ROUTE_FLAGS_OFFSET],NEBO_SCAN_ROUTE_REQUIRED_FLAGS
 mov rax,[rsp+176]
 mov [rsp+NEBO_SCAN_ROUTE_TARGET_CONSOLE_HANDLE_OFFSET],rax
 mov rax,[rsp+184]
 mov [rsp+NEBO_SCAN_ROUTE_BINDING_ID_OFFSET],rax
 mov rax,[rsp+192]
 mov [rsp+NEBO_SCAN_ROUTE_COMPILER_PENDING_ID_OFFSET],rax
 mov rax,[rsp+200]
 mov [rsp+NEBO_SCAN_ROUTE_SOURCE_ORDER_OFFSET],rax
 call nebo_runtime_input_ensure_initialized
 test eax,eax
 jnz .console_scan_failed
 lea rdi,[rel nebo_runtime_input_runtime]
 mov rsi,rsp
 call nebo_console_scan_route
 test eax,eax
 jnz .console_scan_failed
 lea rdi,[rsp+112]
 xor eax,eax
 mov ecx,NEBO_SUBMISSION_RESULT_QWORDS
 cld
 rep stosq
 mov rdi,[rel nebo_runtime_process_stack]
 lea rsi,[rel nebo_runtime_console_context]
 lea rdx,[rel nebo_runtime_input_runtime]
 mov rcx,rsp
 lea r8,[rsp+112]
 call nebo_runtime_live_scan_roundtrip
 cmp eax,NEBO_LIVE_STATUS_CANCELLED
 je .console_scan_cancelled
 test eax,eax
 jnz .console_scan_failed
 mov rax,[rsp+112+NEBO_SUBMISSION_RESULT_BINDING_ID_OFFSET]
 cmp rax,[rsp+184]
 jne .console_scan_failed
 mov rax,[rsp+112+NEBO_SUBMISSION_RESULT_COMPILER_PENDING_ID_OFFSET]
 cmp rax,[rsp+192]
 jne .console_scan_failed
 mov rdi,[rsp+112+NEBO_SUBMISSION_RESULT_VALUE_PTR_OFFSET]
 mov rsi,[rsp+112+NEBO_SUBMISSION_RESULT_VALUE_LENGTH_OFFSET]
 mov edx,SCAN_SOURCE_DEVICE
 call nebo_runtime_scan_store_text
 leave
 ret
.console_scan_cancelled:
 leave
 xor edi,edi
 jmp nebo_runtime_exit
.console_scan_failed:
 leave
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 jmp nebo_runtime_trap

; data*, length, Scan source -> stable TextDescriptor*.  Slot publication is
; failure-atomic: the process-wide count advances only after every ScanPlan
; gate succeeds.
nebo_runtime_scan_store_text:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14d,edx
 cmp r13,SCAN_MAX_INPUT_BYTES
 ja .store_failed
 mov edi,SCAN_MIN_FEATURE_ID
 mov esi,SCAN_KIND_TEXT
 mov edx,SCAN_FLAG_OPTIONAL | SCAN_FLAG_ALLOW_EMPTY | SCAN_FLAG_CHOMP
 mov ecx,r13d
 mov r8d,1
 mov r9d,r14d
 call neboc_scan_feature_validate
 test eax,eax
 jnz .store_failed
 mov edi,r14d
 mov esi,SCAN_CAP_STDIN | SCAN_CAP_DEVICE
 call neboc_scan_source_validate
 test eax,eax
 jnz .store_failed
 mov rbx,[rel nebo_runtime_scan_result_count]
 cmp rbx,NEBO_RUNTIME_SCAN_RESULT_CAPACITY
 jae .store_failed
 mov rax,rbx
 imul rax,SCAN_MAX_INPUT_BYTES
 lea rdx,[rel nebo_runtime_scan_values]
 add rdx,rax
 mov rdi,r12
 mov rsi,r13
 mov ecx,SCAN_MAX_INPUT_BYTES
 mov r8d,SCAN_FLAG_OPTIONAL | SCAN_FLAG_ALLOW_EMPTY | SCAN_FLAG_CHOMP
 call neboc_scan_normalize_ascii
 test rax,rax
 js .store_failed
 mov r13,rax
 mov rax,rbx
 imul rax,SCAN_MAX_INPUT_BYTES
 lea r12,[rel nebo_runtime_scan_values]
 add r12,rax
 mov rdi,r12
 mov rsi,r13
 xor edx,edx
 mov ecx,SCAN_MAX_INPUT_BYTES
 mov r8d,SCAN_TEXT_NO_CONTROL
 call neboc_scan_validate_text
 test eax,eax
 jnz .store_failed
 mov rax,rbx
 imul rax,NEBO_RUNTIME_TEXT_DESCRIPTOR_SIZE
 lea rdx,[rel nebo_runtime_scan_descriptors]
 add rdx,rax
 mov [rdx+NEBO_RUNTIME_TEXT_DATA_OFFSET],r12
 mov [rdx+NEBO_RUNTIME_TEXT_LENGTH_OFFSET],r13
 mov dword [rdx+NEBO_RUNTIME_TEXT_FLAGS_OFFSET],0
 mov word [rdx+NEBO_RUNTIME_TEXT_ENCODING_OFFSET],NEBO_RUNTIME_TEXT_ENCODING_UTF8
 mov word [rdx+NEBO_RUNTIME_TEXT_LIFETIME_OFFSET],NEBO_RUNTIME_TEXT_LIFETIME_STATIC
 inc qword [rel nebo_runtime_scan_result_count]
 mov rax,rdx
 jmp .store_done
.store_failed:
 xor eax,eax
.store_done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 test rax,rax
 jz .store_trap
 ret
.store_trap:
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 jmp nebo_runtime_trap
%endif

%include "runtime/console/handles/console_handle.asm"
%include "runtime/console/input/registry/input_registry.asm"
%include "runtime/console/pending/pending_registry.asm"
%include "runtime/console/input/routing/scan_routing.asm"
%include "runtime/console/input/editing/text_editor.asm"
%include "runtime/console/focus/focus_manager.asm"
%include "runtime/console/dependency-bridge/dependency_bridge.asm"
%include "runtime/console/input/submission/input_submission.asm"
%include "runtime/console/lifecycle/console_lifecycle.asm"
%include "runtime/console/queues/console_queue.asm"
%include "runtime/console/renderers/basic/basic_renderer.asm"
%include "runtime/console/document/console_document.asm"
%include "runtime/console/behavior/console_behavior.asm"
%include "runtime/console/renderer-registry/renderer_registry.asm"
%include "runtime/console/render/fake_glyph_provider.asm"
%include "runtime/console/layout/console_layout.asm"
%include "runtime/console/render/render_tree.asm"
%include "runtime/console/render/draw_command.asm"
%include "runtime/console/render/software_surface.asm"
%include "runtime/console/render/output_conformance.asm"
%include "runtime/console/platform/fake/fake_platform.asm"
%include "runtime/console/domain/console_domain.asm"
%include "runtime/console/manager/console_manager.asm"

section .note.GNU-stack noalloc noexec nowrite progbits
