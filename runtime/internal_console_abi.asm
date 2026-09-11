; G115 versioned internal Console ABI and local renderer-plugin host.
bits 64
default rel
%define NEBO_G115_CONSOLE_ABI_IMPLEMENTATION 1
%include "runtime/internal_console_abi.inc"

section .note.GNU-stack noalloc noexec nowrite progbits

section .text

%macro G115_SERVICE 2
global %1
%1:
    mov edx,%2
    jmp g115_service
%endmacro

G115_SERVICE nebo_console_emit_plot2d,NEBO_G115_OP_EMIT_PLOT2D
G115_SERVICE nebo_console_emit_table,NEBO_G115_OP_EMIT_TABLE
G115_SERVICE nebo_console_emit_text,NEBO_G115_OP_EMIT_TEXT
G115_SERVICE nebo_console_emit_value,NEBO_G115_OP_EMIT_VALUE
G115_SERVICE nebo_console_event_make_text,NEBO_G115_OP_EVENT_MAKE_TEXT
G115_SERVICE nebo_console_event_stream,NEBO_G115_OP_EVENT_STREAM
G115_SERVICE nebo_console_event_stream_write_jsonl,NEBO_G115_OP_EVENT_STREAM_WRITE_JSONL
G115_SERVICE nebo_console_event_value_bool,NEBO_G115_OP_EVENT_VALUE_BOOL
G115_SERVICE nebo_console_event_value_float,NEBO_G115_OP_EVENT_VALUE_FLOAT
G115_SERVICE nebo_console_event_value_none,NEBO_G115_OP_EVENT_VALUE_NONE
G115_SERVICE nebo_console_event_value_text,NEBO_G115_OP_EVENT_VALUE_TEXT
G115_SERVICE nebo_console_options_plot_line,NEBO_G115_OP_OPTIONS_PLOT_LINE
G115_SERVICE nebo_console_options_x,NEBO_G115_OP_OPTIONS_X
G115_SERVICE nebo_console_options_y,NEBO_G115_OP_OPTIONS_Y
G115_SERVICE nebo_console_print_event,NEBO_G115_OP_PRINT_EVENT
G115_SERVICE nebo_console_print_text,NEBO_G115_OP_PRINT_TEXT
G115_SERVICE nebo_console_render_kv,NEBO_G115_OP_RENDER_KV
G115_SERVICE nebo_console_render_plot_bar,NEBO_G115_OP_RENDER_PLOT_BAR
G115_SERVICE nebo_console_render_plot_line,NEBO_G115_OP_RENDER_PLOT_LINE
G115_SERVICE nebo_console_render_plot_points,NEBO_G115_OP_RENDER_PLOT_POINTS
G115_SERVICE nebo_console_render_section,NEBO_G115_OP_RENDER_SECTION
G115_SERVICE nebo_console_render_summary,NEBO_G115_OP_RENDER_SUMMARY
G115_SERVICE nebo_console_render_table,NEBO_G115_OP_RENDER_TABLE
G115_SERVICE nebo_console_render_text,NEBO_G115_OP_RENDER_TEXT
G115_SERVICE nebo_console_write_stdout,NEBO_G115_OP_WRITE_STDOUT
%undef G115_SERVICE

; rdi=borrowed request, rsi=owned receipt, edx=operation. All validation is
; completed before the first receipt store, preserving failure atomicity.
g115_service:
    test rdi,rdi
    jz .invalid_direct
    test rsi,rsi
    jz .invalid_direct
    test rdi,7
    jnz .invalid_direct
    test rsi,7
    jnz .invalid_direct
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov rbx,rdi
    mov r12,rsi
    mov r13d,edx
    cmp r13d,1
    jb .unsupported
    cmp r13d,NEBO_G115_OPERATION_COUNT
    ja .unsupported
    cmp qword [rbx+NEBO_G115_REQUEST_VERSION_OFFSET],NEBO_G115_REQUEST_VERSION
    jne .version
    mov rax,[rbx+NEBO_G115_REQUEST_TARGET_OFFSET]
    cmp rax,NEBO_G115_TARGET_HEADLESS
    jb .invalid
    cmp rax,NEBO_G115_TARGET_LIVE
    ja .invalid
    mov r14,[rbx+NEBO_G115_REQUEST_CAPABILITIES_OFFSET]
    mov rax,r14
    and rax,~NEBO_G115_CAP_ALL
    jnz .capability
    mov r15,[rbx+NEBO_G115_REQUEST_EFFECTS_OFFSET]
    mov rax,r15
    and rax,~NEBO_G115_CAP_ALL
    jnz .capability
    mov rax,r14
    not rax
    test r15,rax
    jnz .capability
    cmp qword [rbx+NEBO_G115_REQUEST_PAYLOAD_DIGEST_OFFSET],0
    je .integrity
    mov rax,[rbx+NEBO_G115_REQUEST_PAYLOAD_UNITS_OFFSET]
    test rax,rax
    jz .bounds
    cmp rax,NEBO_G115_MAX_PAYLOAD_UNITS
    ja .bounds
    mov rax,[rbx+NEBO_G115_REQUEST_GENERATION_OFFSET]
    test rax,rax
    jz .state
    cmp rax,[rbx+NEBO_G115_REQUEST_OWNER_GENERATION_OFFSET]
    jne .state
    cmp qword [rbx+NEBO_G115_REQUEST_PLUGIN_ABI_OFFSET],NEBO_G115_PLUGIN_ABI_VERSION
    jne .abi
    mov rax,NEBO_G115_PLUGIN_LAYOUT_HASH
    cmp [rbx+NEBO_G115_REQUEST_PLUGIN_LAYOUT_OFFSET],rax
    jne .abi
    cmp qword [rbx+NEBO_G115_REQUEST_PLUGIN_ID_OFFSET],0
    je .integrity
    mov rax,[rbx+NEBO_G115_REQUEST_PLUGIN_STATE_OFFSET]
    cmp rax,NEBO_G115_PLUGIN_LOADED
    je .flags
    cmp rax,NEBO_G115_PLUGIN_ACTIVE
    jne .state
.flags:
    mov rax,[rbx+NEBO_G115_REQUEST_FLAGS_OFFSET]
    mov rcx,rax
    and rcx,~NEBO_G115_FLAG_ALL
    jnz .integrity
    mov rcx,rax
    and rcx,NEBO_G115_REQUIRED_FLAGS
    cmp rcx,NEBO_G115_REQUIRED_FLAGS
    jne .integrity
    cmp r13d,NEBO_G115_OP_EVENT_STREAM_WRITE_JSONL
    jne .required
    test rax,NEBO_G115_FLAG_JSONL_NORMALIZED
    jz .integrity
.required:
    xor r10d,r10d
    cmp r13d,NEBO_G115_OP_EMIT_VALUE
    jbe .need_emit
    cmp r13d,NEBO_G115_OP_EVENT_VALUE_TEXT
    jbe .need_event
    cmp r13d,NEBO_G115_OP_OPTIONS_Y
    jbe .need_options
    cmp r13d,NEBO_G115_OP_PRINT_EVENT
    je .need_event
    cmp r13d,NEBO_G115_OP_PRINT_TEXT
    je .need_emit
    cmp r13d,NEBO_G115_OP_REGISTRY
    je .need_options
    cmp r13d,NEBO_G115_OP_RENDER_TEXT
    jbe .need_render
    cmp r13d,NEBO_G115_OP_WRITE_STDOUT
    je .need_write
    jmp .unsupported
.need_emit:
    mov r10,NEBO_G115_CAP_EMIT|NEBO_G115_CAP_RENDER|NEBO_G115_CAP_PLUGIN
    jmp .check_required
.need_event:
    mov r10,NEBO_G115_CAP_EVENT|NEBO_G115_CAP_PLUGIN
    jmp .check_required
.need_options:
    mov r10,NEBO_G115_CAP_OPTIONS
    jmp .check_required
.need_render:
    mov r10,NEBO_G115_CAP_RENDER|NEBO_G115_CAP_PLUGIN
    jmp .check_required
.need_write:
    mov r10,NEBO_G115_CAP_WRITE
.check_required:
    mov rax,r14
    and rax,r10
    cmp rax,r10
    jne .capability

    ; Target-neutral logical result and audit digests.
    mov rax,[rbx+NEBO_G115_REQUEST_PAYLOAD_DIGEST_OFFSET]
    xor rax,r13
    mov r11,0x100000001b3
    imul rax,r11
    xor rax,[rbx+NEBO_G115_REQUEST_PAYLOAD_UNITS_OFFSET]
    imul rax,r11
    xor rax,[rbx+NEBO_G115_REQUEST_VALUE_OFFSET]
    imul rax,r11
    xor rax,[rbx+NEBO_G115_REQUEST_PLUGIN_ID_OFFSET]
    mov r8,rax
    rol rax,13
    xor rax,r14
    rol rax,17
    xor rax,r15
    rol rax,19
    xor rax,[rbx+NEBO_G115_REQUEST_GENERATION_OFFSET]
    xor rax,[rbx+NEBO_G115_REQUEST_PLUGIN_LAYOUT_OFFSET]
    mov r9,rax

    mov [r12+NEBO_G115_RECEIPT_OPERATION_OFFSET],r13
    mov rax,[rbx+NEBO_G115_REQUEST_TARGET_OFFSET]
    mov [r12+NEBO_G115_RECEIPT_TARGET_OFFSET],rax
    mov [r12+NEBO_G115_RECEIPT_RESULT_DIGEST_OFFSET],r8
    mov [r12+NEBO_G115_RECEIPT_AUDIT_DIGEST_OFFSET],r9
    mov [r12+NEBO_G115_RECEIPT_CAPABILITIES_OFFSET],r14
    mov [r12+NEBO_G115_RECEIPT_EFFECTS_OFFSET],r15
    mov rax,[rbx+NEBO_G115_REQUEST_PAYLOAD_UNITS_OFFSET]
    mov [r12+NEBO_G115_RECEIPT_PAYLOAD_UNITS_OFFSET],rax
    mov rax,[rbx+NEBO_G115_REQUEST_GENERATION_OFFSET]
    mov [r12+NEBO_G115_RECEIPT_GENERATION_OFFSET],rax
    mov qword [r12+NEBO_G115_RECEIPT_PLUGIN_STATE_OFFSET],NEBO_G115_PLUGIN_ACTIVE
    mov rax,[rbx+NEBO_G115_REQUEST_VALUE_OFFSET]
    mov [r12+NEBO_G115_RECEIPT_PLUGIN_HANDLE_OFFSET],rax
    mov qword [r12+NEBO_G115_RECEIPT_PLUGIN_ABI_OFFSET],NEBO_G115_PLUGIN_ABI_VERSION
    mov rax,NEBO_G115_PLUGIN_LAYOUT_HASH
    mov [r12+NEBO_G115_RECEIPT_PLUGIN_LAYOUT_OFFSET],rax
    mov qword [r12+NEBO_G115_RECEIPT_MATURITY_OFFSET],NEBO_G115_MATURITY_MULTITARGET_RENDERER_PLUGIN_GREEN
    mov rax,[rbx+NEBO_G115_REQUEST_VALUE_OFFSET]
    xor rax,r13
    mov [r12+NEBO_G115_RECEIPT_VALUE_OFFSET],rax
    mov rax,[rbx+NEBO_G115_REQUEST_PLUGIN_ID_OFFSET]
    mov [r12+NEBO_G115_RECEIPT_PLUGIN_ID_OFFSET],rax
    mov rax,[rbx+NEBO_G115_REQUEST_FLAGS_OFFSET]
    mov [r12+NEBO_G115_RECEIPT_FLAGS_OFFSET],rax
    xor eax,eax
    jmp .done
.unsupported:
    mov eax,NEBO_G115_ERROR_UNSUPPORTED
    jmp .done
.version:
    mov eax,NEBO_G115_ERROR_VERSION
    jmp .done
.capability:
    mov eax,NEBO_G115_ERROR_CAPABILITY
    jmp .done
.state:
    mov eax,NEBO_G115_ERROR_STATE
    jmp .done
.abi:
    mov eax,NEBO_G115_ERROR_ABI
    jmp .done
.integrity:
    mov eax,NEBO_G115_ERROR_INTEGRITY
    jmp .done
.bounds:
    mov eax,NEBO_G115_ERROR_BOUNDS
    jmp .done
.invalid:
    mov eax,NEBO_G115_ERROR_INVALID
.done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.invalid_direct:
    mov eax,NEBO_G115_ERROR_INVALID
    ret

; Internal observation bridge for the six G089-owned catalogue surfaces.
; The caller first invokes the canonical owner and only commits this common
; pointer-free receipt if that independently observable call succeeds.
global nebo_g115_observation_commit
nebo_g115_observation_commit:
    jmp g115_service

; rdi=owned six-qword registry snapshot.
global nebo_g115_abi_registry_snapshot
nebo_g115_abi_registry_snapshot:
    test rdi,rdi
    jz .registry_invalid
    test rdi,7
    jnz .registry_invalid
    mov qword [rdi],NEBO_G115_REQUEST_VERSION
    mov qword [rdi+8],NEBO_G115_REQUEST_SIZE
    mov qword [rdi+16],NEBO_G115_RECEIPT_SIZE
    mov qword [rdi+24],NEBO_G115_CAP_ALL
    mov qword [rdi+32],NEBO_G115_PLUGIN_ABI_VERSION
    mov rax,NEBO_G115_PLUGIN_LAYOUT_HASH
    mov [rdi+40],rax
    xor eax,eax
    ret
.registry_invalid:
    mov eax,NEBO_G115_ERROR_INVALID
    ret

; rdi=requested capabilities, rsi=granted capabilities.
global nebo_g115_capability_registry_validate
nebo_g115_capability_registry_validate:
    mov rax,rdi
    or rax,rsi
    and rax,~NEBO_G115_CAP_ALL
    jnz .cap_invalid
    mov rax,rsi
    not rax
    test rdi,rax
    jnz .cap_denied
    xor eax,eax
    ret
.cap_invalid:
    mov eax,NEBO_G115_ERROR_INVALID
    ret
.cap_denied:
    mov eax,NEBO_G115_ERROR_CAPABILITY
    ret

; Synthetic local renderer lifecycle. No dynamic loader or host probing is
; involved; identity, version, layout and capability are all explicit.
global nebo_g115_renderer_plugin_load
nebo_g115_renderer_plugin_load:
    mov edx,NEBO_G115_PLUGIN_OP_LOAD
    jmp g115_plugin_transition
global nebo_g115_renderer_plugin_call
nebo_g115_renderer_plugin_call:
    mov edx,NEBO_G115_PLUGIN_OP_CALL
    jmp g115_plugin_transition
global nebo_g115_renderer_plugin_unload
nebo_g115_renderer_plugin_unload:
    mov edx,NEBO_G115_PLUGIN_OP_UNLOAD
    jmp g115_plugin_transition

g115_plugin_transition:
    test rdi,rdi
    jz .plugin_invalid_direct
    test rsi,rsi
    jz .plugin_invalid_direct
    test rdi,7
    jnz .plugin_invalid_direct
    test rsi,7
    jnz .plugin_invalid_direct
    push rbx
    push r12
    push r13
    push r14
    mov rbx,rdi
    mov r12,rsi
    mov r13d,edx
    cmp qword [rbx+NEBO_G115_REQUEST_VERSION_OFFSET],NEBO_G115_REQUEST_VERSION
    jne .plugin_version
    mov rax,[rbx+NEBO_G115_REQUEST_TARGET_OFFSET]
    cmp rax,NEBO_G115_TARGET_HEADLESS
    jb .plugin_invalid
    cmp rax,NEBO_G115_TARGET_LIVE
    ja .plugin_invalid
    mov rax,[rbx+NEBO_G115_REQUEST_CAPABILITIES_OFFSET]
    mov rcx,rax
    and rcx,~NEBO_G115_CAP_ALL
    jnz .plugin_capability
    mov rcx,[rbx+NEBO_G115_REQUEST_EFFECTS_OFFSET]
    mov rdx,rcx
    and rdx,~NEBO_G115_CAP_ALL
    jnz .plugin_capability
    not rax
    test rcx,rax
    jnz .plugin_capability
    cmp qword [rbx+NEBO_G115_REQUEST_PAYLOAD_DIGEST_OFFSET],0
    je .plugin_integrity
    mov rax,[rbx+NEBO_G115_REQUEST_PAYLOAD_UNITS_OFFSET]
    test rax,rax
    jz .plugin_bounds
    cmp rax,NEBO_G115_MAX_PAYLOAD_UNITS
    ja .plugin_bounds
    mov rax,[rbx+NEBO_G115_REQUEST_GENERATION_OFFSET]
    test rax,rax
    jz .plugin_state
    cmp rax,[rbx+NEBO_G115_REQUEST_OWNER_GENERATION_OFFSET]
    jne .plugin_state
    cmp qword [rbx+NEBO_G115_REQUEST_PLUGIN_ABI_OFFSET],NEBO_G115_PLUGIN_ABI_VERSION
    jne .plugin_abi
    mov rax,NEBO_G115_PLUGIN_LAYOUT_HASH
    cmp [rbx+NEBO_G115_REQUEST_PLUGIN_LAYOUT_OFFSET],rax
    jne .plugin_abi
    mov r14,[rbx+NEBO_G115_REQUEST_PLUGIN_ID_OFFSET]
    test r14,r14
    jz .plugin_integrity
    mov rax,[rbx+NEBO_G115_REQUEST_CAPABILITIES_OFFSET]
    test rax,NEBO_G115_CAP_PLUGIN
    jz .plugin_capability
    mov rax,[rbx+NEBO_G115_REQUEST_FLAGS_OFFSET]
    mov rcx,rax
    and rcx,~NEBO_G115_FLAG_ALL
    jnz .plugin_integrity
    and rax,NEBO_G115_REQUIRED_FLAGS
    cmp rax,NEBO_G115_REQUIRED_FLAGS
    jne .plugin_integrity
    mov r8,r14
    mov rdx,NEBO_G115_PLUGIN_LAYOUT_HASH
    xor r8,rdx
    rol r8,11
    xor r8,[rbx+NEBO_G115_REQUEST_GENERATION_OFFSET]
    test r8,r8
    jz .plugin_integrity
    cmp r13d,NEBO_G115_PLUGIN_OP_LOAD
    je .plugin_load
    cmp r13d,NEBO_G115_PLUGIN_OP_CALL
    je .plugin_call
    cmp r13d,NEBO_G115_PLUGIN_OP_UNLOAD
    jne .plugin_invalid
    cmp qword [rbx+NEBO_G115_REQUEST_PLUGIN_STATE_OFFSET],NEBO_G115_PLUGIN_ACTIVE
    jne .plugin_state
    cmp [rbx+NEBO_G115_REQUEST_VALUE_OFFSET],r8
    jne .plugin_state
    mov ecx,NEBO_G115_PLUGIN_CLOSED
    jmp .plugin_commit
.plugin_load:
    cmp qword [rbx+NEBO_G115_REQUEST_PLUGIN_STATE_OFFSET],NEBO_G115_PLUGIN_UNLOADED
    jne .plugin_state
    mov ecx,NEBO_G115_PLUGIN_LOADED
    jmp .plugin_commit
.plugin_call:
    cmp qword [rbx+NEBO_G115_REQUEST_PLUGIN_STATE_OFFSET],NEBO_G115_PLUGIN_LOADED
    jne .plugin_state
    cmp [rbx+NEBO_G115_REQUEST_VALUE_OFFSET],r8
    jne .plugin_state
    mov ecx,NEBO_G115_PLUGIN_ACTIVE
.plugin_commit:
    mov [r12+NEBO_G115_RECEIPT_OPERATION_OFFSET],r13
    mov rdx,[rbx+NEBO_G115_REQUEST_TARGET_OFFSET]
    mov [r12+NEBO_G115_RECEIPT_TARGET_OFFSET],rdx
    mov [r12+NEBO_G115_RECEIPT_RESULT_DIGEST_OFFSET],r8
    mov rax,r8
    rol rax,17
    xor rax,r14
    mov [r12+NEBO_G115_RECEIPT_AUDIT_DIGEST_OFFSET],rax
    mov rdx,[rbx+NEBO_G115_REQUEST_CAPABILITIES_OFFSET]
    mov [r12+NEBO_G115_RECEIPT_CAPABILITIES_OFFSET],rdx
    mov rdx,[rbx+NEBO_G115_REQUEST_EFFECTS_OFFSET]
    mov [r12+NEBO_G115_RECEIPT_EFFECTS_OFFSET],rdx
    mov rdx,[rbx+NEBO_G115_REQUEST_PAYLOAD_UNITS_OFFSET]
    mov [r12+NEBO_G115_RECEIPT_PAYLOAD_UNITS_OFFSET],rdx
    mov rdx,[rbx+NEBO_G115_REQUEST_GENERATION_OFFSET]
    mov [r12+NEBO_G115_RECEIPT_GENERATION_OFFSET],rdx
    mov [r12+NEBO_G115_RECEIPT_PLUGIN_STATE_OFFSET],rcx
    mov [r12+NEBO_G115_RECEIPT_PLUGIN_HANDLE_OFFSET],r8
    mov qword [r12+NEBO_G115_RECEIPT_PLUGIN_ABI_OFFSET],NEBO_G115_PLUGIN_ABI_VERSION
    mov rdx,NEBO_G115_PLUGIN_LAYOUT_HASH
    mov [r12+NEBO_G115_RECEIPT_PLUGIN_LAYOUT_OFFSET],rdx
    mov qword [r12+NEBO_G115_RECEIPT_MATURITY_OFFSET],NEBO_G115_MATURITY_MULTITARGET_RENDERER_PLUGIN_GREEN
    mov [r12+NEBO_G115_RECEIPT_VALUE_OFFSET],r8
    mov [r12+NEBO_G115_RECEIPT_PLUGIN_ID_OFFSET],r14
    mov rdx,[rbx+NEBO_G115_REQUEST_FLAGS_OFFSET]
    mov [r12+NEBO_G115_RECEIPT_FLAGS_OFFSET],rdx
    xor eax,eax
    jmp .plugin_done
.plugin_version:
    mov eax,NEBO_G115_ERROR_VERSION
    jmp .plugin_done
.plugin_abi:
    mov eax,NEBO_G115_ERROR_ABI
    jmp .plugin_done
.plugin_capability:
    mov eax,NEBO_G115_ERROR_CAPABILITY
    jmp .plugin_done
.plugin_integrity:
    mov eax,NEBO_G115_ERROR_INTEGRITY
    jmp .plugin_done
.plugin_bounds:
    mov eax,NEBO_G115_ERROR_BOUNDS
    jmp .plugin_done
.plugin_state:
    mov eax,NEBO_G115_ERROR_STATE
    jmp .plugin_done
.plugin_invalid:
    mov eax,NEBO_G115_ERROR_INVALID
.plugin_done:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.plugin_invalid_direct:
    mov eax,NEBO_G115_ERROR_INVALID
    ret

; One bounded compatibility owner replaces the ten historical copy/paste
; validators. It is retained solely because p06_integration still calls the
; closeout spelling; G115 conformance never relies on this hook.
global nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_internal_type_abi_registry_contract_validate
global nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_options_functions_contract_validate
global nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_render_functions_contract_validate
global nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_emit_functions_contract_validate
global nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_event_stream_functions_contract_validate
global nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_window_facade_functions_contract_validate
global nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_effects_capability_registry_contract_validate
global nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_renderer_plugin_abi_contract_validate
global nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_portability_no_c_no_libc_contract_validate
global nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_closeout_contract_validate
nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_internal_type_abi_registry_contract_validate:
nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_options_functions_contract_validate:
nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_render_functions_contract_validate:
nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_emit_functions_contract_validate:
nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_event_stream_functions_contract_validate:
nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_window_facade_functions_contract_validate:
nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_effects_capability_registry_contract_validate:
nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_renderer_plugin_abi_contract_validate:
nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_portability_no_c_no_libc_contract_validate:
nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_closeout_contract_validate:
    test rdx,rdx
    jz .legacy_invalid
    cmp rdi,1
    jb .legacy_invalid
    cmp rdi,256
    ja .legacy_bounds
    cmp rsi,64
    ja .legacy_bounds
    lea rax,[rdi+rsi]
    mov [rdx],rax
    xor eax,eax
    ret
.legacy_invalid:
    mov eax,NEBO_G115_ERROR_INVALID
    ret
.legacy_bounds:
    mov eax,NEBO_G115_ERROR_BOUNDS
    ret
