bits 64
default rel

%include "runtime/internal_console_abi.inc"

section .text
global nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_internal_type_abi_registry_contract_validate
nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_internal_type_abi_registry_contract_validate:
    test rdx, rdx
    jz abi_interno_runtime_assembly_capabilities_e_renderer_plugins_internal_type_abi_registry_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl abi_interno_runtime_assembly_capabilities_e_renderer_plugins_internal_type_abi_registry_.invalid_nebo_contract_validate
    cmp rdi, 256
    jg abi_interno_runtime_assembly_capabilities_e_renderer_plugins_internal_type_abi_registry_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl abi_interno_runtime_assembly_capabilities_e_renderer_plugins_internal_type_abi_registry_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg abi_interno_runtime_assembly_capabilities_e_renderer_plugins_internal_type_abi_registry_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
abi_interno_runtime_assembly_capabilities_e_renderer_plugins_internal_type_abi_registry_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
abi_interno_runtime_assembly_capabilities_e_renderer_plugins_internal_type_abi_registry_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_options_functions_contract_validate
nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_options_functions_contract_validate:
    test rdx, rdx
    jz abi_interno_runtime_assembly_capabilities_e_renderer_plugins_options_functions_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl abi_interno_runtime_assembly_capabilities_e_renderer_plugins_options_functions_.invalid_nebo_contract_validate
    cmp rdi, 256
    jg abi_interno_runtime_assembly_capabilities_e_renderer_plugins_options_functions_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl abi_interno_runtime_assembly_capabilities_e_renderer_plugins_options_functions_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg abi_interno_runtime_assembly_capabilities_e_renderer_plugins_options_functions_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
abi_interno_runtime_assembly_capabilities_e_renderer_plugins_options_functions_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
abi_interno_runtime_assembly_capabilities_e_renderer_plugins_options_functions_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_render_functions_contract_validate
nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_render_functions_contract_validate:
    test rdx, rdx
    jz abi_interno_runtime_assembly_capabilities_e_renderer_plugins_render_functions_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl abi_interno_runtime_assembly_capabilities_e_renderer_plugins_render_functions_.invalid_nebo_contract_validate
    cmp rdi, 256
    jg abi_interno_runtime_assembly_capabilities_e_renderer_plugins_render_functions_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl abi_interno_runtime_assembly_capabilities_e_renderer_plugins_render_functions_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg abi_interno_runtime_assembly_capabilities_e_renderer_plugins_render_functions_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
abi_interno_runtime_assembly_capabilities_e_renderer_plugins_render_functions_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
abi_interno_runtime_assembly_capabilities_e_renderer_plugins_render_functions_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_emit_functions_contract_validate
nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_emit_functions_contract_validate:
    test rdx, rdx
    jz abi_interno_runtime_assembly_capabilities_e_renderer_plugins_emit_functions_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl abi_interno_runtime_assembly_capabilities_e_renderer_plugins_emit_functions_.invalid_nebo_contract_validate
    cmp rdi, 256
    jg abi_interno_runtime_assembly_capabilities_e_renderer_plugins_emit_functions_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl abi_interno_runtime_assembly_capabilities_e_renderer_plugins_emit_functions_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg abi_interno_runtime_assembly_capabilities_e_renderer_plugins_emit_functions_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
abi_interno_runtime_assembly_capabilities_e_renderer_plugins_emit_functions_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
abi_interno_runtime_assembly_capabilities_e_renderer_plugins_emit_functions_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_event_stream_functions_contract_validate
nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_event_stream_functions_contract_validate:
    test rdx, rdx
    jz abi_interno_runtime_assembly_capabilities_e_renderer_plugins_event_stream_functions_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl abi_interno_runtime_assembly_capabilities_e_renderer_plugins_event_stream_functions_.invalid_nebo_contract_validate
    cmp rdi, 256
    jg abi_interno_runtime_assembly_capabilities_e_renderer_plugins_event_stream_functions_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl abi_interno_runtime_assembly_capabilities_e_renderer_plugins_event_stream_functions_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg abi_interno_runtime_assembly_capabilities_e_renderer_plugins_event_stream_functions_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
abi_interno_runtime_assembly_capabilities_e_renderer_plugins_event_stream_functions_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
abi_interno_runtime_assembly_capabilities_e_renderer_plugins_event_stream_functions_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_window_facade_functions_contract_validate
nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_window_facade_functions_contract_validate:
    test rdx, rdx
    jz abi_interno_runtime_assembly_capabilities_e_renderer_plugins_window_facade_functions_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl abi_interno_runtime_assembly_capabilities_e_renderer_plugins_window_facade_functions_.invalid_nebo_contract_validate
    cmp rdi, 256
    jg abi_interno_runtime_assembly_capabilities_e_renderer_plugins_window_facade_functions_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl abi_interno_runtime_assembly_capabilities_e_renderer_plugins_window_facade_functions_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg abi_interno_runtime_assembly_capabilities_e_renderer_plugins_window_facade_functions_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
abi_interno_runtime_assembly_capabilities_e_renderer_plugins_window_facade_functions_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
abi_interno_runtime_assembly_capabilities_e_renderer_plugins_window_facade_functions_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_effects_capability_registry_contract_validate
nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_effects_capability_registry_contract_validate:
    test rdx, rdx
    jz abi_interno_runtime_assembly_capabilities_e_renderer_plugins_effects_capability_registry_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl abi_interno_runtime_assembly_capabilities_e_renderer_plugins_effects_capability_registry_.invalid_nebo_contract_validate
    cmp rdi, 256
    jg abi_interno_runtime_assembly_capabilities_e_renderer_plugins_effects_capability_registry_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl abi_interno_runtime_assembly_capabilities_e_renderer_plugins_effects_capability_registry_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg abi_interno_runtime_assembly_capabilities_e_renderer_plugins_effects_capability_registry_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
abi_interno_runtime_assembly_capabilities_e_renderer_plugins_effects_capability_registry_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
abi_interno_runtime_assembly_capabilities_e_renderer_plugins_effects_capability_registry_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_renderer_plugin_abi_contract_validate
nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_renderer_plugin_abi_contract_validate:
    test rdx, rdx
    jz abi_interno_runtime_assembly_capabilities_e_renderer_plugins_renderer_plugin_abi_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl abi_interno_runtime_assembly_capabilities_e_renderer_plugins_renderer_plugin_abi_.invalid_nebo_contract_validate
    cmp rdi, 1
    jg abi_interno_runtime_assembly_capabilities_e_renderer_plugins_renderer_plugin_abi_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl abi_interno_runtime_assembly_capabilities_e_renderer_plugins_renderer_plugin_abi_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg abi_interno_runtime_assembly_capabilities_e_renderer_plugins_renderer_plugin_abi_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
abi_interno_runtime_assembly_capabilities_e_renderer_plugins_renderer_plugin_abi_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
abi_interno_runtime_assembly_capabilities_e_renderer_plugins_renderer_plugin_abi_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_portability_no_c_no_libc_contract_validate
nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_portability_no_c_no_libc_contract_validate:
    test rdx, rdx
    jz abi_interno_runtime_assembly_capabilities_e_renderer_plugins_portability_no_c_no_libc_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl abi_interno_runtime_assembly_capabilities_e_renderer_plugins_portability_no_c_no_libc_.invalid_nebo_contract_validate
    cmp rdi, 256
    jg abi_interno_runtime_assembly_capabilities_e_renderer_plugins_portability_no_c_no_libc_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl abi_interno_runtime_assembly_capabilities_e_renderer_plugins_portability_no_c_no_libc_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg abi_interno_runtime_assembly_capabilities_e_renderer_plugins_portability_no_c_no_libc_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
abi_interno_runtime_assembly_capabilities_e_renderer_plugins_portability_no_c_no_libc_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
abi_interno_runtime_assembly_capabilities_e_renderer_plugins_portability_no_c_no_libc_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_closeout_contract_validate
nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_closeout_contract_validate:
    test rdx, rdx
    jz abi_interno_runtime_assembly_capabilities_e_renderer_plugins_closeout_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl abi_interno_runtime_assembly_capabilities_e_renderer_plugins_closeout_.invalid_nebo_contract_validate
    cmp rdi, 1
    jg abi_interno_runtime_assembly_capabilities_e_renderer_plugins_closeout_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl abi_interno_runtime_assembly_capabilities_e_renderer_plugins_closeout_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg abi_interno_runtime_assembly_capabilities_e_renderer_plugins_closeout_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
abi_interno_runtime_assembly_capabilities_e_renderer_plugins_closeout_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
abi_interno_runtime_assembly_capabilities_e_renderer_plugins_closeout_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret
