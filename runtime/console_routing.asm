bits 64
default rel

%include "runtime/console_routing.inc"

section .text
global nebo_standard_targets_validate
nebo_standard_targets_validate:
    cmp rdi, 1
    jl .invalid_nebo_standard_targets_validate
    cmp rdi, 16
    jg .invalid_nebo_standard_targets_validate
    cmp rsi, 0
    jl .invalid_nebo_standard_targets_validate
    cmp rsi, 8
    jg .invalid_nebo_standard_targets_validate
    cmp rdx, 0
    jl .invalid_nebo_standard_targets_validate
    cmp rdx, 5
    jg .invalid_nebo_standard_targets_validate
    xor eax, eax
    ret
.invalid_nebo_standard_targets_validate:
    mov eax, -1
    ret


global nebo_file_modes_validate
nebo_file_modes_validate:
    cmp rdi, 1
    jl .invalid_nebo_file_modes_validate
    cmp rdi, 16
    jg .invalid_nebo_file_modes_validate
    cmp rsi, 0
    jl .invalid_nebo_file_modes_validate
    cmp rsi, 8
    jg .invalid_nebo_file_modes_validate
    cmp rdx, 0
    jl .invalid_nebo_file_modes_validate
    cmp rdx, 5
    jg .invalid_nebo_file_modes_validate
    xor eax, eax
    ret
.invalid_nebo_file_modes_validate:
    mov eax, -1
    ret


global nebo_sink_router_validate
nebo_sink_router_validate:
    cmp rdi, 1
    jl .invalid_nebo_sink_router_validate
    cmp rdi, 16
    jg .invalid_nebo_sink_router_validate
    cmp rsi, 0
    jl .invalid_nebo_sink_router_validate
    cmp rsi, 8
    jg .invalid_nebo_sink_router_validate
    cmp rdx, 0
    jl .invalid_nebo_sink_router_validate
    cmp rdx, 5
    jg .invalid_nebo_sink_router_validate
    xor eax, eax
    ret
.invalid_nebo_sink_router_validate:
    mov eax, -1
    ret


global nebo_mirror_targets_validate
nebo_mirror_targets_validate:
    cmp rdi, 1
    jl .invalid_nebo_mirror_targets_validate
    cmp rdi, 16
    jg .invalid_nebo_mirror_targets_validate
    cmp rsi, 0
    jl .invalid_nebo_mirror_targets_validate
    cmp rsi, 8
    jg .invalid_nebo_mirror_targets_validate
    cmp rdx, 0
    jl .invalid_nebo_mirror_targets_validate
    cmp rdx, 5
    jg .invalid_nebo_mirror_targets_validate
    xor eax, eax
    ret
.invalid_nebo_mirror_targets_validate:
    mov eax, -1
    ret


global nebo_fallback_target_validate
nebo_fallback_target_validate:
    cmp rdi, 1
    jl .invalid_nebo_fallback_target_validate
    cmp rdi, 16
    jg .invalid_nebo_fallback_target_validate
    cmp rsi, 0
    jl .invalid_nebo_fallback_target_validate
    cmp rsi, 8
    jg .invalid_nebo_fallback_target_validate
    cmp rdx, 0
    jl .invalid_nebo_fallback_target_validate
    cmp rdx, 5
    jg .invalid_nebo_fallback_target_validate
    xor eax, eax
    ret
.invalid_nebo_fallback_target_validate:
    mov eax, -1
    ret


global nebo_atomic_capabilities_validate
nebo_atomic_capabilities_validate:
    cmp rdi, 1
    jl .invalid_nebo_atomic_capabilities_validate
    cmp rdi, 16
    jg .invalid_nebo_atomic_capabilities_validate
    cmp rsi, 0
    jl .invalid_nebo_atomic_capabilities_validate
    cmp rsi, 8
    jg .invalid_nebo_atomic_capabilities_validate
    cmp rdx, 0
    jl .invalid_nebo_atomic_capabilities_validate
    cmp rdx, 5
    jg .invalid_nebo_atomic_capabilities_validate
    xor eax, eax
    ret
.invalid_nebo_atomic_capabilities_validate:
    mov eax, -1
    ret


global nebo_multi_target_parity_validate
nebo_multi_target_parity_validate:
    cmp rdi, 1
    jl .invalid_nebo_multi_target_parity_validate
    cmp rdi, 16
    jg .invalid_nebo_multi_target_parity_validate
    cmp rsi, 0
    jl .invalid_nebo_multi_target_parity_validate
    cmp rsi, 8
    jg .invalid_nebo_multi_target_parity_validate
    cmp rdx, 0
    jl .invalid_nebo_multi_target_parity_validate
    cmp rdx, 5
    jg .invalid_nebo_multi_target_parity_validate
    xor eax, eax
    ret
.invalid_nebo_multi_target_parity_validate:
    mov eax, -1
    ret


global nebo_cleanup_error_validate
nebo_cleanup_error_validate:
    cmp rdi, 1
    jl .invalid_nebo_cleanup_error_validate
    cmp rdi, 16
    jg .invalid_nebo_cleanup_error_validate
    cmp rsi, 0
    jl .invalid_nebo_cleanup_error_validate
    cmp rsi, 8
    jg .invalid_nebo_cleanup_error_validate
    cmp rdx, 0
    jl .invalid_nebo_cleanup_error_validate
    cmp rdx, 5
    jg .invalid_nebo_cleanup_error_validate
    xor eax, eax
    ret
.invalid_nebo_cleanup_error_validate:
    mov eax, -1
    ret


global nebo_sinks_routing_files_mirroring_e_fallback_closeout_contract_validate
nebo_sinks_routing_files_mirroring_e_fallback_closeout_contract_validate:
    cmp rdi, 1
    jl sinks_routing_files_mirroring_e_fallback_closeout_.invalid_nebo_contract_validate
    cmp rdi, 16
    jg sinks_routing_files_mirroring_e_fallback_closeout_.invalid_nebo_contract_validate
    cmp rsi, 0
    jl sinks_routing_files_mirroring_e_fallback_closeout_.invalid_nebo_contract_validate
    cmp rsi, 8
    jg sinks_routing_files_mirroring_e_fallback_closeout_.invalid_nebo_contract_validate
    cmp rdx, 0
    jl sinks_routing_files_mirroring_e_fallback_closeout_.invalid_nebo_contract_validate
    cmp rdx, 5
    jg sinks_routing_files_mirroring_e_fallback_closeout_.invalid_nebo_contract_validate
    xor eax, eax
    ret
sinks_routing_files_mirroring_e_fallback_closeout_.invalid_nebo_contract_validate:
    mov eax, -1
    ret
