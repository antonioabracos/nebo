bits 64
default rel

%include "runtime/internal_observability_services.inc"

section .text
global nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_log_levels_contract_validate
nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_log_levels_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_log_visual_progress_e_visual_timeline_log_levels_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_log_visual_progress_e_visual_timeline_log_levels_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_internos_visual_log_visual_progress_e_visual_timeline_log_levels_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_log_visual_progress_e_visual_timeline_log_levels_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_log_visual_progress_e_visual_timeline_log_levels_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_log_visual_progress_e_visual_timeline_log_levels_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_log_visual_progress_e_visual_timeline_log_levels_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_group_tag_branch_flush_contract_validate
nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_group_tag_branch_flush_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_log_visual_progress_e_visual_timeline_group_tag_branch_flush_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_log_visual_progress_e_visual_timeline_group_tag_branch_flush_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_internos_visual_log_visual_progress_e_visual_timeline_group_tag_branch_flush_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_log_visual_progress_e_visual_timeline_group_tag_branch_flush_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_log_visual_progress_e_visual_timeline_group_tag_branch_flush_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_log_visual_progress_e_visual_timeline_group_tag_branch_flush_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_log_visual_progress_e_visual_timeline_group_tag_branch_flush_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_progress_create_update_increment_contract_validate
nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_progress_create_update_increment_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_log_visual_progress_e_visual_timeline_progress_create_update_increment_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_log_visual_progress_e_visual_timeline_progress_create_update_increment_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_internos_visual_log_visual_progress_e_visual_timeline_progress_create_update_increment_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_log_visual_progress_e_visual_timeline_progress_create_update_increment_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_log_visual_progress_e_visual_timeline_progress_create_update_increment_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_log_visual_progress_e_visual_timeline_progress_create_update_increment_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_log_visual_progress_e_visual_timeline_progress_create_update_increment_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_message_finish_fail_cancel_contract_validate
nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_message_finish_fail_cancel_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_log_visual_progress_e_visual_timeline_message_finish_fail_cancel_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_log_visual_progress_e_visual_timeline_message_finish_fail_cancel_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_internos_visual_log_visual_progress_e_visual_timeline_message_finish_fail_cancel_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_log_visual_progress_e_visual_timeline_message_finish_fail_cancel_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_log_visual_progress_e_visual_timeline_message_finish_fail_cancel_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_log_visual_progress_e_visual_timeline_message_finish_fail_cancel_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_log_visual_progress_e_visual_timeline_message_finish_fail_cancel_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_progress_snapshot_contract_validate
nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_progress_snapshot_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_log_visual_progress_e_visual_timeline_progress_snapshot_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_log_visual_progress_e_visual_timeline_progress_snapshot_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_internos_visual_log_visual_progress_e_visual_timeline_progress_snapshot_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_log_visual_progress_e_visual_timeline_progress_snapshot_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_log_visual_progress_e_visual_timeline_progress_snapshot_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_log_visual_progress_e_visual_timeline_progress_snapshot_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_log_visual_progress_e_visual_timeline_progress_snapshot_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_timeline_fromevents_fromstream_contract_validate
nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_timeline_fromevents_fromstream_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_log_visual_progress_e_visual_timeline_timeline_fromevents_fromstream_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_log_visual_progress_e_visual_timeline_timeline_fromevents_fromstream_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_internos_visual_log_visual_progress_e_visual_timeline_timeline_fromevents_fromstream_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_log_visual_progress_e_visual_timeline_timeline_fromevents_fromstream_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_log_visual_progress_e_visual_timeline_timeline_fromevents_fromstream_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_log_visual_progress_e_visual_timeline_timeline_fromevents_fromstream_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_log_visual_progress_e_visual_timeline_timeline_fromevents_fromstream_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_fromparallel_fromtraining_contract_validate
nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_fromparallel_fromtraining_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_log_visual_progress_e_visual_timeline_fromparallel_fromtraining_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_log_visual_progress_e_visual_timeline_fromparallel_fromtraining_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_internos_visual_log_visual_progress_e_visual_timeline_fromparallel_fromtraining_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_log_visual_progress_e_visual_timeline_fromparallel_fromtraining_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_log_visual_progress_e_visual_timeline_fromparallel_fromtraining_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_log_visual_progress_e_visual_timeline_fromparallel_fromtraining_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_log_visual_progress_e_visual_timeline_fromparallel_fromtraining_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_limit_window_export_contract_validate
nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_limit_window_export_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_log_visual_progress_e_visual_timeline_limit_window_export_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_log_visual_progress_e_visual_timeline_limit_window_export_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_internos_visual_log_visual_progress_e_visual_timeline_limit_window_export_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_log_visual_progress_e_visual_timeline_limit_window_export_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_log_visual_progress_e_visual_timeline_limit_window_export_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_log_visual_progress_e_visual_timeline_limit_window_export_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_log_visual_progress_e_visual_timeline_limit_window_export_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_closeout_contract_validate
nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_closeout_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_log_visual_progress_e_visual_timeline_closeout_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_log_visual_progress_e_visual_timeline_closeout_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_internos_visual_log_visual_progress_e_visual_timeline_closeout_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_log_visual_progress_e_visual_timeline_closeout_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_log_visual_progress_e_visual_timeline_closeout_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_log_visual_progress_e_visual_timeline_closeout_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_log_visual_progress_e_visual_timeline_closeout_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret
