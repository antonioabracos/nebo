; G089 source-to-effect probe. Each mode consumes the source integer through
; the canonical parser/runtime owners and returns the independently observable
; value. No fixture path or source identity participates in dispatch.
bits 64
default rel
%define NEBO_G089_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/console_options_source_probe.inc"
%include "compiler/parser/console_arguments.inc"
%include "compiler/parser/console_call.inc"
%include "runtime/console_options.inc"
%include "runtime/console_option_registry.inc"
%include "runtime/console_contract.inc"
%include "runtime/console_call.inc"
%include "runtime/render_intent.inc"
%include "runtime/color_target.inc"
%include "runtime/p01_integration.inc"
%include "compiler/diagnostics/p01.inc"
%include "compiler/formatter/console_options.inc"
%include "compiler/lsp/console_options.inc"

extern neboc_console_call_build
extern nebo_console_options_default
extern nebo_console_options_init
extern nebo_console_options_validate
extern nebo_console_option_model
extern nebo_console_options_normalize
extern nebo_console_options_budget_check
extern nebo_option_registry_validate_names
extern nebo_console_registry
extern nebo_console_call_finalize
extern nebo_render_intent_build
extern nebo_console_render_plan_is_safe
extern neboc_diag_from_option_status
extern neboc_format_option_schema_key
extern neboc_lsp_option_schema_info
extern nebo_p01_prepare_console_call

global nebo_g089_source_probe
global nebo_g089_negative_probe

section .rodata
g89_key_kind: db "kind"
g89_key_kind_len equ $-g89_key_kind
g89_key_title: db "title"
g89_key_title_len equ $-g89_key_title
g89_key_width: db "width"
g89_key_width_len equ $-g89_key_width

section .data align=16
g89_schemas:
    dq 1, 1, 1, 0, 0, g89_key_kind, g89_key_kind_len
    dq 2, 1, 2, 0, 0, g89_key_title, g89_key_title_len
    dq 3, 1, 1, 0, 0, g89_key_width, g89_key_width_len
g89_values:
    dq 3, 0, 0
    dq 1, 0, 0
g89_conflicts:
    dq 1, 11, 2
    dq 2, 13, 1

section .bss align=16
g89_parser_input: resb NEBOC_CONSOLE_CALL_INPUT_SIZE
g89_parser_node: resb NEBOC_CONSOLE_CALL_NODE_SIZE
g89_model: resb NEBO_CONSOLE_OPTIONS_SIZE
g89_model_copy: resb NEBO_CONSOLE_OPTIONS_SIZE
g89_validate_request: resb NEBO_CONSOLE_VALIDATE_REQUEST_SIZE
g89_normalized: resb NEBO_OPTION_VALUE_SIZE * 2
g89_normalize_receipt: resb NEBO_OPTIONS_RECEIPT_SIZE
g89_found: resq 1
g89_call_request: resb NEBO_CONSOLE_CALL_REQUEST_SIZE
g89_call_receipt: resb NEBO_CONSOLE_RECEIPT_SIZE
g89_intent: resb NEBO_RENDER_INTENT_SIZE
g89_plan: resb NEBO_RENDER_PLAN_SIZE
g89_budget: resb neboc_console_arguments_BUDGET_SIZE
g89_budget_copy: resb neboc_console_arguments_BUDGET_SIZE
g89_diagnostic: resb NEBOC_DIAG_SIZE
g89_formatted: resb g89_key_kind_len
g89_lsp_info: resb NEBOC_LSP_OPTION_INFO_SIZE
g89_p01_request: resb NEBO_P01_REQUEST_SIZE
g89_p01_scratch: resb NEBO_OPTION_VALUE_SIZE * 2
g89_p01_plan: resb NEBO_RENDER_PLAN_SIZE
g89_p01_receipt: resb NEBO_CONSOLE_RECEIPT_SIZE

section .text
; EDI=mode 1..9, ESI=source-derived value 0..255 -> EAX=observed value.
nebo_g089_source_probe:
    push rbx
    push r12
    sub rsp, 8
    mov r12d, edi
    mov ebx, esi
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
    cmp r12d, 9
    je .mode9
    jmp .failure

.mode1:
    mov [rel g89_values + NEBO_OPTION_VALUE_PAYLOAD_OFFSET], rbx
    lea rax, [rel g89_values]
    mov [rel g89_parser_input + NEBOC_CONSOLE_CALL_INPUT_RECEIVER_OFFSET], rax
    mov qword [rel g89_parser_input + NEBOC_CONSOLE_CALL_INPUT_RECEIVER_START_OFFSET], 10
    mov qword [rel g89_parser_input + NEBOC_CONSOLE_CALL_INPUT_RECEIVER_END_OFFSET], 21
    mov qword [rel g89_parser_input + NEBOC_CONSOLE_CALL_INPUT_METHOD_START_OFFSET], 22
    mov qword [rel g89_parser_input + NEBOC_CONSOLE_CALL_INPUT_METHOD_END_OFFSET], 35
    mov qword [rel g89_parser_input + NEBOC_CONSOLE_CALL_INPUT_ARGUMENTS_OFFSET], 0
    mov qword [rel g89_parser_input + NEBOC_CONSOLE_CALL_INPUT_CALL_END_OFFSET], 40
    lea rdi, [rel g89_parser_input]
    lea rsi, [rel g89_parser_node]
    call neboc_console_call_build
    test eax, eax
    jnz .failure
    cmp qword [rel g89_parser_node + NEBOC_CONSOLE_CALL_NODE_STATE_OFFSET], NEBOC_CONSOLE_CALL_NODE_READY
    jne .failure
    mov rax, [rel g89_parser_node + NEBOC_CONSOLE_CALL_NODE_RECEIVER_OFFSET]
    mov eax, [rax + NEBO_OPTION_VALUE_PAYLOAD_OFFSET]
    jmp .success_value

.mode2:
    lea rdi, [rel g89_model]
    call nebo_console_options_default
    test eax, eax
    jnz .failure
    cmp qword [rel g89_model + NEBO_CONSOLE_OPTIONS_COUNT_OFFSET], 0
    jne .failure
    mov [rel g89_values + NEBO_OPTION_VALUE_SIZE + NEBO_OPTION_VALUE_PAYLOAD_OFFSET], rbx
    lea rdi, [rel g89_model]
    lea rsi, [rel g89_values]
    mov edx, 2
    mov ecx, 2
    call nebo_console_options_init
    test eax, eax
    jnz .failure
    lea rdi, [rel g89_model]
    lea rsi, [rel g89_model_copy]
    call nebo_console_option_model
    test eax, eax
    jnz .failure
    cmp qword [rel g89_model_copy + NEBO_CONSOLE_OPTIONS_COUNT_OFFSET], 2
    jne .failure
    lea rax, [rel g89_model]
    mov [rel g89_validate_request + NEBO_CONSOLE_VALIDATE_MODEL_OFFSET], rax
    lea rax, [rel g89_schemas]
    mov [rel g89_validate_request + NEBO_CONSOLE_VALIDATE_REGISTRY_OFFSET], rax
    mov qword [rel g89_validate_request + NEBO_CONSOLE_VALIDATE_REGISTRY_COUNT_OFFSET], 3
    lea rax, [rel g89_normalized]
    mov [rel g89_validate_request + NEBO_CONSOLE_VALIDATE_SCRATCH_OFFSET], rax
    mov qword [rel g89_validate_request + NEBO_CONSOLE_VALIDATE_SCRATCH_CAPACITY_OFFSET], 2
    lea rax, [rel g89_normalize_receipt]
    mov [rel g89_validate_request + NEBO_CONSOLE_VALIDATE_RECEIPT_OFFSET], rax
    lea rdi, [rel g89_validate_request]
    call nebo_console_options_validate
    test eax, eax
    jnz .failure
    lea rdi, [rel g89_schemas]
    mov esi, 3
    lea rdx, [rel g89_key_kind]
    mov ecx, g89_key_kind_len
    lea r8, [rel g89_found]
    call nebo_console_registry
    test eax, eax
    jnz .failure
    mov rax, [rel g89_found]
    cmp qword [rax + NEBO_OPTION_SCHEMA_KIND_OFFSET], 1
    jne .failure
    mov eax, [rel g89_normalized + NEBO_OPTION_VALUE_PAYLOAD_OFFSET]
    jmp .success_value

.mode3:
    mov [rel g89_values + NEBO_OPTION_VALUE_SIZE + NEBO_OPTION_VALUE_PAYLOAD_OFFSET], rbx
    lea rax, [rel g89_values]
    mov [rel g89_model + NEBO_OPTIONS_NORMALIZE_VALUES_OFFSET], rax
    mov qword [rel g89_model + NEBO_OPTIONS_NORMALIZE_COUNT_OFFSET], 2
    lea rax, [rel g89_normalized]
    mov [rel g89_model + NEBO_OPTIONS_NORMALIZE_DESTINATION_OFFSET], rax
    mov qword [rel g89_model + NEBO_OPTIONS_NORMALIZE_CAPACITY_OFFSET], 2
    lea rax, [rel g89_normalize_receipt]
    mov [rel g89_model + NEBO_OPTIONS_NORMALIZE_RECEIPT_OFFSET], rax
    lea rdi, [rel g89_model]
    call nebo_console_options_normalize
    test eax, eax
    jnz .failure
    cmp qword [rel g89_normalized + NEBO_OPTION_VALUE_KIND_OFFSET], 1
    jne .failure
    cmp [rel g89_normalized + NEBO_OPTION_VALUE_PAYLOAD_OFFSET], rbx
    jne .failure
    mov eax, [rel g89_normalized + NEBO_OPTION_VALUE_PAYLOAD_OFFSET]
    jmp .success_value

.mode4:
    mov [rel g89_schemas + NEBO_OPTION_SCHEMA_FLAGS_OFFSET], rbx
    lea rdi, [rel g89_schemas]
    mov esi, 3
    call nebo_option_registry_validate_names
    test eax, eax
    jnz .failure
    lea rdi, [rel g89_schemas]
    mov esi, 3
    lea rdx, [rel g89_key_kind]
    mov ecx, g89_key_kind_len
    lea r8, [rel g89_found]
    call nebo_console_registry
    test eax, eax
    jnz .failure
    lea rdi, [rel g89_key_kind]
    mov esi, g89_key_kind_len
    lea rdx, [rel g89_formatted]
    mov ecx, g89_key_kind_len
    call neboc_format_option_schema_key
    test eax, eax
    jnz .failure
    mov eax, [rel g89_key_kind]
    cmp eax, [rel g89_formatted]
    jne .failure
    mov rax, [rel g89_found]
    mov eax, [rax + NEBO_OPTION_SCHEMA_FLAGS_OFFSET]
    jmp .success_value

.mode5:
    mov [rel g89_call_request + NEBO_CONSOLE_CALL_METHOD_OFFSET], rbx
    mov qword [rel g89_call_request + NEBO_CONSOLE_CALL_EFFECTS_OFFSET], NEBO_CONSOLE_EFFECT_WRITE
    mov qword [rel g89_call_request + NEBO_CONSOLE_CALL_CAPABILITIES_OFFSET], NEBO_CONSOLE_EFFECT_WRITE
    mov qword [rel g89_call_request + NEBO_CONSOLE_CALL_RETURN_KIND_OFFSET], NEBO_CONSOLE_RETURN_RECEIPT
    lea rax, [rel g89_plan]
    mov [rel g89_call_request + NEBO_CONSOLE_CALL_RENDER_PLAN_OFFSET], rax
    mov qword [rel g89_call_request + NEBO_CONSOLE_CALL_HANDLE_OFFSET], 0
    lea rdi, [rel g89_call_request]
    lea rsi, [rel g89_call_receipt]
    call nebo_console_call_finalize
    test eax, eax
    jnz .failure
    cmp [rel g89_call_receipt + NEBO_CONSOLE_RECEIPT_METHOD_OFFSET], rbx
    jne .failure
    cmp qword [rel g89_call_receipt + NEBO_CONSOLE_RECEIPT_STATE_OFFSET], NEBO_CONSOLE_RECEIPT_READY
    jne .failure
    mov eax, [rel g89_call_receipt + NEBO_CONSOLE_RECEIPT_METHOD_OFFSET]
    jmp .success_value

.mode6:
    call g89_build_plan
    test eax, eax
    jnz .failure
    lea rdi, [rel g89_plan]
    call nebo_console_render_plan_is_safe
    test eax, eax
    jnz .failure
    mov rax, [rel g89_plan + NEBO_RENDER_PLAN_OPTIONS_OFFSET]
    mov eax, [rax + NEBO_OPTION_VALUE_PAYLOAD_OFFSET]
    jmp .success_value

.mode7:
    mov qword [rel g89_budget + NEBOC_BUDGET_OPTIONS_OFFSET], NEBOC_MAX_CONSOLE_OPTIONS
    mov qword [rel g89_budget + NEBOC_BUDGET_ARGUMENTS_OFFSET], NEBOC_MAX_OPTION_ARGUMENTS
    mov qword [rel g89_budget + NEBOC_BUDGET_DEPTH_OFFSET], NEBOC_MAX_NESTED_CALL_DEPTH
    mov qword [rel g89_budget + NEBOC_BUDGET_NODES_OFFSET], NEBOC_MAX_OPTION_AST_NODES
    mov [rel g89_budget + NEBOC_BUDGET_STEPS_OFFSET], rbx
    lea rdi, [rel g89_budget]
    lea rsi, [rel g89_budget_copy]
    call nebo_console_options_budget_check
    test eax, eax
    jnz .failure
    cmp [rel g89_budget_copy + NEBOC_BUDGET_STEPS_OFFSET], rbx
    jne .failure
    mov eax, [rel g89_budget_copy + NEBOC_BUDGET_STEPS_OFFSET]
    jmp .success_value

.mode8:
    mov edi, NEBO_OPTIONS_CONFLICT
    mov esi, ebx
    lea edx, [ebx + 5]
    lea rcx, [rel g89_diagnostic]
    call neboc_diag_from_option_status
    test eax, eax
    jnz .failure
    cmp qword [rel g89_diagnostic + NEBOC_DIAG_CODE_OFFSET], NEBOC_DIAG_OPTION_CONFLICT
    jne .failure
    lea rdi, [rel g89_schemas]
    mov esi, 2
    lea rdx, [rel g89_key_kind]
    mov ecx, g89_key_kind_len
    lea r8, [rel g89_lsp_info]
    call neboc_lsp_option_schema_info
    test eax, eax
    jnz .failure
    cmp qword [rel g89_lsp_info + NEBOC_LSP_OPTION_KIND_OFFSET], 1
    jne .failure
    mov eax, [rel g89_diagnostic + NEBOC_DIAG_START_OFFSET]
    jmp .success_value

.mode9:
    mov [rel g89_values + NEBO_OPTION_VALUE_SIZE + NEBO_OPTION_VALUE_PAYLOAD_OFFSET], rbx
    lea rax, [rel g89_values]
    mov [rel g89_p01_request + NEBO_P01_REQUEST_VALUES_OFFSET], rax
    mov qword [rel g89_p01_request + NEBO_P01_REQUEST_COUNT_OFFSET], 2
    lea rax, [rel g89_p01_scratch]
    mov [rel g89_p01_request + NEBO_P01_REQUEST_SCRATCH_OFFSET], rax
    mov qword [rel g89_p01_request + NEBO_P01_REQUEST_SCRATCH_CAPACITY_OFFSET], 2
    mov qword [rel g89_p01_request + NEBO_P01_REQUEST_TARGET_OFFSET], NEBO_COLOR_TARGET_HEADLESS
    mov qword [rel g89_p01_request + NEBO_P01_REQUEST_CAPABILITIES_OFFSET], NEBO_CONSOLE_EFFECT_WRITE
    mov qword [rel g89_p01_request + NEBO_P01_REQUEST_EFFECTS_OFFSET], NEBO_CONSOLE_EFFECT_WRITE
    mov [rel g89_p01_request + NEBO_P01_REQUEST_METHOD_OFFSET], rbx
    mov qword [rel g89_p01_request + NEBO_P01_REQUEST_RETURN_KIND_OFFSET], NEBO_CONSOLE_RETURN_RECEIPT
    mov qword [rel g89_p01_request + NEBO_P01_REQUEST_HANDLE_OFFSET], 0
    lea rax, [rel g89_p01_plan]
    mov [rel g89_p01_request + NEBO_P01_REQUEST_PLAN_OFFSET], rax
    lea rax, [rel g89_p01_receipt]
    mov [rel g89_p01_request + NEBO_P01_REQUEST_RECEIPT_OFFSET], rax
    lea rdi, [rel g89_p01_request]
    call nebo_p01_prepare_console_call
    test eax, eax
    jnz .failure
    cmp [rel g89_p01_receipt + NEBO_CONSOLE_RECEIPT_METHOD_OFFSET], rbx
    jne .failure
    lea rdi, [rel g89_p01_plan]
    call nebo_console_render_plan_is_safe
    test eax, eax
    jnz .failure
    mov eax, [rel g89_p01_receipt + NEBO_CONSOLE_RECEIPT_METHOD_OFFSET]
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

; Construct one sorted bounded plan whose first payload is source-derived.
g89_build_plan:
    mov qword [rel g89_values + NEBO_OPTION_VALUE_KIND_OFFSET], 1
    mov [rel g89_values + NEBO_OPTION_VALUE_PAYLOAD_OFFSET], rbx
    mov qword [rel g89_values + NEBO_OPTION_VALUE_CONFLICT_MASK_OFFSET], 0
    mov qword [rel g89_values + NEBO_OPTION_VALUE_SIZE + NEBO_OPTION_VALUE_KIND_OFFSET], 3
    mov qword [rel g89_values + NEBO_OPTION_VALUE_SIZE + NEBO_OPTION_VALUE_CONFLICT_MASK_OFFSET], 0
    lea rax, [rel g89_values]
    mov [rel g89_intent + NEBO_RENDER_INTENT_OPTIONS_OFFSET], rax
    mov qword [rel g89_intent + NEBO_RENDER_INTENT_COUNT_OFFSET], 2
    mov qword [rel g89_intent + NEBO_RENDER_INTENT_TARGET_OFFSET], NEBO_COLOR_TARGET_HEADLESS
    mov qword [rel g89_intent + NEBO_RENDER_INTENT_CAPABILITIES_OFFSET], NEBO_CONSOLE_EFFECT_WRITE
    mov qword [rel g89_intent + NEBO_RENDER_INTENT_EFFECTS_OFFSET], NEBO_CONSOLE_EFFECT_WRITE
    lea rdi, [rel g89_intent]
    lea rsi, [rel g89_plan]
    jmp nebo_render_intent_build

; EDI=case. Returns the canonical failure status for adversarial probes.
nebo_g089_negative_probe:
    cmp edi, 1
    je .duplicate
    cmp edi, 2
    je .unsafe
    mov eax, NEBO_OPTIONS_INVALID
    ret
.duplicate:
    sub rsp, 8
    lea rdi, [rel g89_model]
    lea rsi, [rel g89_conflicts]
    mov edx, 2
    mov ecx, 2
    call nebo_console_options_init
    test eax, eax
    jnz .duplicate_done
    lea rax, [rel g89_model]
    mov [rel g89_validate_request + NEBO_CONSOLE_VALIDATE_MODEL_OFFSET], rax
    lea rax, [rel g89_schemas]
    mov [rel g89_validate_request + NEBO_CONSOLE_VALIDATE_REGISTRY_OFFSET], rax
    mov qword [rel g89_validate_request + NEBO_CONSOLE_VALIDATE_REGISTRY_COUNT_OFFSET], 3
    lea rax, [rel g89_normalized]
    mov [rel g89_validate_request + NEBO_CONSOLE_VALIDATE_SCRATCH_OFFSET], rax
    mov qword [rel g89_validate_request + NEBO_CONSOLE_VALIDATE_SCRATCH_CAPACITY_OFFSET], 2
    lea rax, [rel g89_normalize_receipt]
    mov [rel g89_validate_request + NEBO_CONSOLE_VALIDATE_RECEIPT_OFFSET], rax
    lea rdi, [rel g89_validate_request]
    call nebo_console_options_validate
.duplicate_done:
    add rsp, 8
    ret
.unsafe:
    mov qword [rel g89_plan + NEBO_RENDER_PLAN_STATE_OFFSET], 0
    lea rdi, [rel g89_plan]
    jmp nebo_console_render_plan_is_safe

section .note.GNU-stack noalloc noexec nowrite progbits
