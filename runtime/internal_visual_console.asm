bits 64
default rel

%include "runtime/internal_visual_console.inc"

section .text
global nebo_servicos_internos_visual_console_e_visual_panel_facade_historica_visual_e_migration_contract_validate
nebo_servicos_internos_visual_console_e_visual_panel_facade_historica_visual_e_migration_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_console_e_visual_panel_facade_historica_visual_e_migration_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_console_e_visual_panel_facade_historica_visual_e_migration_.invalid_nebo_contract_validate
    cmp rdi, 64
    jg servicos_internos_visual_console_e_visual_panel_facade_historica_visual_e_migration_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_console_e_visual_panel_facade_historica_visual_e_migration_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_console_e_visual_panel_facade_historica_visual_e_migration_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_console_e_visual_panel_facade_historica_visual_e_migration_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_console_e_visual_panel_facade_historica_visual_e_migration_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_console_e_visual_panel_visual_console_open_close_status_contract_validate
nebo_servicos_internos_visual_console_e_visual_panel_visual_console_open_close_status_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_console_e_visual_panel_visual_console_open_close_status_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_console_e_visual_panel_visual_console_open_close_status_.invalid_nebo_contract_validate
    cmp rdi, 64
    jg servicos_internos_visual_console_e_visual_panel_visual_console_open_close_status_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_console_e_visual_panel_visual_console_open_close_status_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_console_e_visual_panel_visual_console_open_close_status_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_console_e_visual_panel_visual_console_open_close_status_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_console_e_visual_panel_visual_console_open_close_status_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_console_e_visual_panel_configure_headless_mode_theme_limits_contract_validate
nebo_servicos_internos_visual_console_e_visual_panel_configure_headless_mode_theme_limits_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_console_e_visual_panel_configure_headless_mode_theme_limits_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_console_e_visual_panel_configure_headless_mode_theme_limits_.invalid_nebo_contract_validate
    cmp rdi, 64
    jg servicos_internos_visual_console_e_visual_panel_configure_headless_mode_theme_limits_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_console_e_visual_panel_configure_headless_mode_theme_limits_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_console_e_visual_panel_configure_headless_mode_theme_limits_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_console_e_visual_panel_configure_headless_mode_theme_limits_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_console_e_visual_panel_configure_headless_mode_theme_limits_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_console_e_visual_panel_show_inspect_fallbacktext_contract_validate
nebo_servicos_internos_visual_console_e_visual_panel_show_inspect_fallbacktext_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_console_e_visual_panel_show_inspect_fallbacktext_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_console_e_visual_panel_show_inspect_fallbacktext_.invalid_nebo_contract_validate
    cmp rdi, 64
    jg servicos_internos_visual_console_e_visual_panel_show_inspect_fallbacktext_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_console_e_visual_panel_show_inspect_fallbacktext_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_console_e_visual_panel_show_inspect_fallbacktext_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_console_e_visual_panel_show_inspect_fallbacktext_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_console_e_visual_panel_show_inspect_fallbacktext_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_console_e_visual_panel_visual_panel_create_get_remove_contract_validate
nebo_servicos_internos_visual_console_e_visual_panel_visual_panel_create_get_remove_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_console_e_visual_panel_visual_panel_create_get_remove_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_console_e_visual_panel_visual_panel_create_get_remove_.invalid_nebo_contract_validate
    cmp rdi, 64
    jg servicos_internos_visual_console_e_visual_panel_visual_panel_create_get_remove_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_console_e_visual_panel_visual_panel_create_get_remove_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_console_e_visual_panel_visual_panel_create_get_remove_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_console_e_visual_panel_visual_panel_create_get_remove_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_console_e_visual_panel_visual_panel_create_get_remove_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_console_e_visual_panel_clear_title_type_contract_validate
nebo_servicos_internos_visual_console_e_visual_panel_clear_title_type_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_console_e_visual_panel_clear_title_type_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_console_e_visual_panel_clear_title_type_.invalid_nebo_contract_validate
    cmp rdi, 64
    jg servicos_internos_visual_console_e_visual_panel_clear_title_type_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_console_e_visual_panel_clear_title_type_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_console_e_visual_panel_clear_title_type_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_console_e_visual_panel_clear_title_type_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_console_e_visual_panel_clear_title_type_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_console_e_visual_panel_send_replace_append_contract_validate
nebo_servicos_internos_visual_console_e_visual_panel_send_replace_append_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_console_e_visual_panel_send_replace_append_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_console_e_visual_panel_send_replace_append_.invalid_nebo_contract_validate
    cmp rdi, 64
    jg servicos_internos_visual_console_e_visual_panel_send_replace_append_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_console_e_visual_panel_send_replace_append_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_console_e_visual_panel_send_replace_append_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_console_e_visual_panel_send_replace_append_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_console_e_visual_panel_send_replace_append_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_console_e_visual_panel_snapshot_lifecycle_contract_validate
nebo_servicos_internos_visual_console_e_visual_panel_snapshot_lifecycle_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_console_e_visual_panel_snapshot_lifecycle_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_console_e_visual_panel_snapshot_lifecycle_.invalid_nebo_contract_validate
    cmp rdi, 64
    jg servicos_internos_visual_console_e_visual_panel_snapshot_lifecycle_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_console_e_visual_panel_snapshot_lifecycle_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_console_e_visual_panel_snapshot_lifecycle_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_console_e_visual_panel_snapshot_lifecycle_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_console_e_visual_panel_snapshot_lifecycle_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_console_e_visual_panel_closeout_contract_validate
nebo_servicos_internos_visual_console_e_visual_panel_closeout_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_console_e_visual_panel_closeout_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_console_e_visual_panel_closeout_.invalid_nebo_contract_validate
    cmp rdi, 64
    jg servicos_internos_visual_console_e_visual_panel_closeout_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_console_e_visual_panel_closeout_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_console_e_visual_panel_closeout_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_console_e_visual_panel_closeout_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_console_e_visual_panel_closeout_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret
