bits 64
default rel

%include "runtime/animation_export.inc"

section .text
global nebo_animation_plan_validate
nebo_animation_plan_validate:
    cmp rdi, 1
    jl .invalid_nebo_animation_plan_validate
    cmp rdi, 1
    jg .invalid_nebo_animation_plan_validate
    cmp rsi, 1
    jl .invalid_nebo_animation_plan_validate
    cmp rsi, 64
    jg .invalid_nebo_animation_plan_validate
    cmp rdx, 1
    jl .invalid_nebo_animation_plan_validate
    cmp rdx, 3
    jg .invalid_nebo_animation_plan_validate
    xor eax, eax
    ret
.invalid_nebo_animation_plan_validate:
    mov eax, -1
    ret


global nebo_timebase_validate
nebo_timebase_validate:
    cmp rdi, 1
    jl .invalid_nebo_timebase_validate
    cmp rdi, 10000
    jg .invalid_nebo_timebase_validate
    cmp rsi, 1
    jl .invalid_nebo_timebase_validate
    cmp rsi, 1000000
    jg .invalid_nebo_timebase_validate
    cmp rdx, 1
    jl .invalid_nebo_timebase_validate
    cmp rdx, 1
    jg .invalid_nebo_timebase_validate
    xor eax, eax
    ret
.invalid_nebo_timebase_validate:
    mov eax, -1
    ret


global nebo_playback_validate
nebo_playback_validate:
    cmp rdi, 1
    jl .invalid_nebo_playback_validate
    cmp rdi, 240
    jg .invalid_nebo_playback_validate
    cmp rsi, 0
    jl .invalid_nebo_playback_validate
    cmp rsi, 1
    jg .invalid_nebo_playback_validate
    cmp rdx, 1
    jl .invalid_nebo_playback_validate
    cmp rdx, 86400000
    jg .invalid_nebo_playback_validate
    xor eax, eax
    ret
.invalid_nebo_playback_validate:
    mov eax, -1
    ret


global nebo_replay_validate
nebo_replay_validate:
    cmp rdi, 1
    jl .invalid_nebo_replay_validate
    cmp rdi, 10000
    jg .invalid_nebo_replay_validate
    cmp rsi, 1
    jl .invalid_nebo_replay_validate
    cmp rsi, 2147483647
    jg .invalid_nebo_replay_validate
    cmp rdx, 1
    jl .invalid_nebo_replay_validate
    cmp rdx, 1
    jg .invalid_nebo_replay_validate
    xor eax, eax
    ret
.invalid_nebo_replay_validate:
    mov eax, -1
    ret


global nebo_capture_capability_validate
nebo_capture_capability_validate:
    cmp rdi, 1
    jl .invalid_nebo_capture_capability_validate
    cmp rdi, 1
    jg .invalid_nebo_capture_capability_validate
    cmp rsi, 0
    jl .invalid_nebo_capture_capability_validate
    cmp rsi, 9999
    jg .invalid_nebo_capture_capability_validate
    cmp rdx, 1
    jl .invalid_nebo_capture_capability_validate
    cmp rdx, 1
    jg .invalid_nebo_capture_capability_validate
    xor eax, eax
    ret
.invalid_nebo_capture_capability_validate:
    mov eax, -1
    ret


global nebo_png_boundary_validate
nebo_png_boundary_validate:
    cmp rdi, 1
    jl .invalid_nebo_png_boundary_validate
    cmp rdi, 1
    jg .invalid_nebo_png_boundary_validate
    cmp rsi, 1
    jl .invalid_nebo_png_boundary_validate
    cmp rsi, 16384
    jg .invalid_nebo_png_boundary_validate
    cmp rdx, 1
    jl .invalid_nebo_png_boundary_validate
    cmp rdx, 16384
    jg .invalid_nebo_png_boundary_validate
    xor eax, eax
    ret
.invalid_nebo_png_boundary_validate:
    mov eax, -1
    ret


global nebo_video_boundary_validate
nebo_video_boundary_validate:
    cmp rdi, 1
    jl .invalid_nebo_video_boundary_validate
    cmp rdi, 1
    jg .invalid_nebo_video_boundary_validate
    cmp rsi, 1
    jl .invalid_nebo_video_boundary_validate
    cmp rsi, 10000
    jg .invalid_nebo_video_boundary_validate
    cmp rdx, 1
    jl .invalid_nebo_video_boundary_validate
    cmp rdx, 3
    jg .invalid_nebo_video_boundary_validate
    xor eax, eax
    ret
.invalid_nebo_video_boundary_validate:
    mov eax, -1
    ret


global nebo_export_target_validate
nebo_export_target_validate:
    cmp rdi, 1
    jl .invalid_nebo_export_target_validate
    cmp rdi, 4096
    jg .invalid_nebo_export_target_validate
    cmp rsi, 1
    jl .invalid_nebo_export_target_validate
    cmp rsi, 3
    jg .invalid_nebo_export_target_validate
    cmp rdx, 0
    jl .invalid_nebo_export_target_validate
    cmp rdx, 1
    jg .invalid_nebo_export_target_validate
    xor eax, eax
    ret
.invalid_nebo_export_target_validate:
    mov eax, -1
    ret


global nebo_export_atomicity_validate
nebo_export_atomicity_validate:
    cmp rdi, 1
    jl .invalid_nebo_export_atomicity_validate
    cmp rdi, 1
    jg .invalid_nebo_export_atomicity_validate
    cmp rsi, 1
    jl .invalid_nebo_export_atomicity_validate
    cmp rsi, 1
    jg .invalid_nebo_export_atomicity_validate
    cmp rdx, 1
    jl .invalid_nebo_export_atomicity_validate
    cmp rdx, 1
    jg .invalid_nebo_export_atomicity_validate
    xor eax, eax
    ret
.invalid_nebo_export_atomicity_validate:
    mov eax, -1
    ret


global nebo_animation_contract_validate
nebo_animation_contract_validate:
    cmp rdi, 1
    jl .invalid_nebo_animation_contract_validate
    cmp rdi, 10000
    jg .invalid_nebo_animation_contract_validate
    cmp rsi, 1
    jl .invalid_nebo_animation_contract_validate
    cmp rsi, 65536
    jg .invalid_nebo_animation_contract_validate
    cmp rdx, 1
    jl .invalid_nebo_animation_contract_validate
    cmp rdx, 1
    jg .invalid_nebo_animation_contract_validate
    xor eax, eax
    ret
.invalid_nebo_animation_contract_validate:
    mov eax, -1
    ret
