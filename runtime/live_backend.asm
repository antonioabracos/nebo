bits 64
default rel

%include "runtime/live_backend.inc"

section .text
global nebo_backend_registry_validate
nebo_backend_registry_validate:
    cmp rdi, 1
    jl .invalid_nebo_backend_registry_validate
    cmp rdi, 6
    jg .invalid_nebo_backend_registry_validate
    cmp rsi, 0
    jl .invalid_nebo_backend_registry_validate
    cmp rsi, 1
    jg .invalid_nebo_backend_registry_validate
    cmp rdx, 1
    jl .invalid_nebo_backend_registry_validate
    cmp rdx, 1
    jg .invalid_nebo_backend_registry_validate
    xor eax, eax
    ret
.invalid_nebo_backend_registry_validate:
    mov eax, -1
    ret


global nebo_headless_backend_validate
nebo_headless_backend_validate:
    cmp rdi, 1
    jl .invalid_nebo_headless_backend_validate
    cmp rdi, 3
    jg .invalid_nebo_headless_backend_validate
    cmp rsi, 0
    jl .invalid_nebo_headless_backend_validate
    cmp rsi, 3
    jg .invalid_nebo_headless_backend_validate
    cmp rdx, 1
    jl .invalid_nebo_headless_backend_validate
    cmp rdx, 1
    jg .invalid_nebo_headless_backend_validate
    xor eax, eax
    ret
.invalid_nebo_headless_backend_validate:
    mov eax, -1
    ret


global nebo_window_lifecycle_validate
nebo_window_lifecycle_validate:
    cmp rdi, 0
    jl .invalid_nebo_window_lifecycle_validate
    cmp rdi, 3
    jg .invalid_nebo_window_lifecycle_validate
    cmp rsi, 1
    jl .invalid_nebo_window_lifecycle_validate
    cmp rsi, 4
    jg .invalid_nebo_window_lifecycle_validate
    cmp rdx, 0
    jl .invalid_nebo_window_lifecycle_validate
    cmp rdx, 1
    jg .invalid_nebo_window_lifecycle_validate
    xor eax, eax
    ret
.invalid_nebo_window_lifecycle_validate:
    mov eax, -1
    ret


global nebo_frame_validate
nebo_frame_validate:
    cmp rdi, 1
    jl .invalid_nebo_frame_validate
    cmp rdi, 2
    jg .invalid_nebo_frame_validate
    cmp rsi, 1
    jl .invalid_nebo_frame_validate
    cmp rsi, 2147483647
    jg .invalid_nebo_frame_validate
    cmp rdx, 1
    jl .invalid_nebo_frame_validate
    cmp rdx, 1
    jg .invalid_nebo_frame_validate
    xor eax, eax
    ret
.invalid_nebo_frame_validate:
    mov eax, -1
    ret


global nebo_event_loop_validate
nebo_event_loop_validate:
    cmp rdi, 1
    jl .invalid_nebo_event_loop_validate
    cmp rdi, 1024
    jg .invalid_nebo_event_loop_validate
    cmp rsi, 0
    jl .invalid_nebo_event_loop_validate
    cmp rsi, 1
    jg .invalid_nebo_event_loop_validate
    cmp rdx, 0
    jl .invalid_nebo_event_loop_validate
    cmp rdx, 1
    jg .invalid_nebo_event_loop_validate
    cmp rsi, rdx
    jg .invalid_nebo_event_loop_validate
    xor eax, eax
    ret
.invalid_nebo_event_loop_validate:
    mov eax, -1
    ret


global nebo_window_target_validate
nebo_window_target_validate:
    cmp rdi, 1
    jl .invalid_nebo_window_target_validate
    cmp rdi, 3
    jg .invalid_nebo_window_target_validate
    cmp rsi, 0
    jl .invalid_nebo_window_target_validate
    cmp rsi, 1
    jg .invalid_nebo_window_target_validate
    cmp rdx, 0
    jl .invalid_nebo_window_target_validate
    cmp rdx, 16
    jg .invalid_nebo_window_target_validate
    xor eax, eax
    ret
.invalid_nebo_window_target_validate:
    mov eax, -1
    ret


global nebo_adapter_validate
nebo_adapter_validate:
    cmp rdi, 1
    jl .invalid_nebo_adapter_validate
    cmp rdi, 3
    jg .invalid_nebo_adapter_validate
    cmp rsi, 0
    jl .invalid_nebo_adapter_validate
    cmp rsi, 1
    jg .invalid_nebo_adapter_validate
    cmp rdx, 1
    jl .invalid_nebo_adapter_validate
    cmp rdx, 1
    jg .invalid_nebo_adapter_validate
    xor eax, eax
    ret
.invalid_nebo_adapter_validate:
    mov eax, -1
    ret


global nebo_font_shape_validate
nebo_font_shape_validate:
    cmp rdi, 1
    jl .invalid_nebo_font_shape_validate
    cmp rdi, 4096
    jg .invalid_nebo_font_shape_validate
    cmp rsi, 1
    jl .invalid_nebo_font_shape_validate
    cmp rsi, 3
    jg .invalid_nebo_font_shape_validate
    cmp rdx, 1
    jl .invalid_nebo_font_shape_validate
    cmp rdx, 65536
    jg .invalid_nebo_font_shape_validate
    xor eax, eax
    ret
.invalid_nebo_font_shape_validate:
    mov eax, -1
    ret


global nebo_live_evidence_validate
nebo_live_evidence_validate:
    cmp rdi, 0
    jl .invalid_nebo_live_evidence_validate
    cmp rdi, 1
    jg .invalid_nebo_live_evidence_validate
    cmp rsi, 0
    jl .invalid_nebo_live_evidence_validate
    cmp rsi, 1
    jg .invalid_nebo_live_evidence_validate
    cmp rdx, 0
    jl .invalid_nebo_live_evidence_validate
    cmp rdx, 1
    jg .invalid_nebo_live_evidence_validate
    cmp rdx, rsi
    jg .invalid_nebo_live_evidence_validate
    cmp rsi, rdi
    jg .invalid_nebo_live_evidence_validate
    xor eax, eax
    ret
.invalid_nebo_live_evidence_validate:
    mov eax, -1
    ret


global nebo_live_contract_validate
nebo_live_contract_validate:
    cmp rdi, 1
    jl .invalid_nebo_live_contract_validate
    cmp rdi, 64
    jg .invalid_nebo_live_contract_validate
    cmp rsi, 1
    jl .invalid_nebo_live_contract_validate
    cmp rsi, 64
    jg .invalid_nebo_live_contract_validate
    cmp rdx, 1
    jl .invalid_nebo_live_contract_validate
    cmp rdx, 1
    jg .invalid_nebo_live_contract_validate
    xor eax, eax
    ret
.invalid_nebo_live_contract_validate:
    mov eax, -1
    ret
