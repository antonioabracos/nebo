bits 64
default rel

%include "runtime/console_testability.inc"

section .text
global nebo_capture_validate
nebo_capture_validate:
    cmp rdi, 1
    jl .invalid_nebo_capture_validate
    cmp rdi, 4096
    jg .invalid_nebo_capture_validate
    cmp rsi, 0
    jl .invalid_nebo_capture_validate
    cmp rsi, 65536
    jg .invalid_nebo_capture_validate
    cmp rdx, 0
    jl .invalid_nebo_capture_validate
    cmp rdx, 3
    jg .invalid_nebo_capture_validate
    xor eax, eax
    ret
.invalid_nebo_capture_validate:
    mov eax, -1
    ret


global nebo_mock_silent_validate
nebo_mock_silent_validate:
    cmp rdi, 1
    jl .invalid_nebo_mock_silent_validate
    cmp rdi, 4096
    jg .invalid_nebo_mock_silent_validate
    cmp rsi, 0
    jl .invalid_nebo_mock_silent_validate
    cmp rsi, 65536
    jg .invalid_nebo_mock_silent_validate
    cmp rdx, 0
    jl .invalid_nebo_mock_silent_validate
    cmp rdx, 3
    jg .invalid_nebo_mock_silent_validate
    xor eax, eax
    ret
.invalid_nebo_mock_silent_validate:
    mov eax, -1
    ret


global nebo_snapshot_golden_validate
nebo_snapshot_golden_validate:
    cmp rdi, 1
    jl .invalid_nebo_snapshot_golden_validate
    cmp rdi, 4096
    jg .invalid_nebo_snapshot_golden_validate
    cmp rsi, 0
    jl .invalid_nebo_snapshot_golden_validate
    cmp rsi, 65536
    jg .invalid_nebo_snapshot_golden_validate
    cmp rdx, 0
    jl .invalid_nebo_snapshot_golden_validate
    cmp rdx, 3
    jg .invalid_nebo_snapshot_golden_validate
    xor eax, eax
    ret
.invalid_nebo_snapshot_golden_validate:
    mov eax, -1
    ret


global nebo_record_replay_validate
nebo_record_replay_validate:
    cmp rdi, 1
    jl .invalid_nebo_record_replay_validate
    cmp rdi, 4096
    jg .invalid_nebo_record_replay_validate
    cmp rsi, 0
    jl .invalid_nebo_record_replay_validate
    cmp rsi, 65536
    jg .invalid_nebo_record_replay_validate
    cmp rdx, 0
    jl .invalid_nebo_record_replay_validate
    cmp rdx, 3
    jg .invalid_nebo_record_replay_validate
    xor eax, eax
    ret
.invalid_nebo_record_replay_validate:
    mov eax, -1
    ret


global nebo_normalize_output_validate
nebo_normalize_output_validate:
    cmp rdi, 1
    jl .invalid_nebo_normalize_output_validate
    cmp rdi, 4096
    jg .invalid_nebo_normalize_output_validate
    cmp rsi, 0
    jl .invalid_nebo_normalize_output_validate
    cmp rsi, 65536
    jg .invalid_nebo_normalize_output_validate
    cmp rdx, 0
    jl .invalid_nebo_normalize_output_validate
    cmp rdx, 3
    jg .invalid_nebo_normalize_output_validate
    xor eax, eax
    ret
.invalid_nebo_normalize_output_validate:
    mov eax, -1
    ret


global nebo_assertions_validate
nebo_assertions_validate:
    cmp rdi, 1
    jl .invalid_nebo_assertions_validate
    cmp rdi, 4096
    jg .invalid_nebo_assertions_validate
    cmp rsi, 0
    jl .invalid_nebo_assertions_validate
    cmp rsi, 65536
    jg .invalid_nebo_assertions_validate
    cmp rdx, 0
    jl .invalid_nebo_assertions_validate
    cmp rdx, 3
    jg .invalid_nebo_assertions_validate
    xor eax, eax
    ret
.invalid_nebo_assertions_validate:
    mov eax, -1
    ret


global nebo_headless_live_matrix_validate
nebo_headless_live_matrix_validate:
    cmp rdi, 1
    jl .invalid_nebo_headless_live_matrix_validate
    cmp rdi, 4096
    jg .invalid_nebo_headless_live_matrix_validate
    cmp rsi, 0
    jl .invalid_nebo_headless_live_matrix_validate
    cmp rsi, 65536
    jg .invalid_nebo_headless_live_matrix_validate
    cmp rdx, 0
    jl .invalid_nebo_headless_live_matrix_validate
    cmp rdx, 3
    jg .invalid_nebo_headless_live_matrix_validate
    xor eax, eax
    ret
.invalid_nebo_headless_live_matrix_validate:
    mov eax, -1
    ret


global nebo_deterministic_time_seed_validate
nebo_deterministic_time_seed_validate:
    cmp rdi, 1
    jl .invalid_nebo_deterministic_time_seed_validate
    cmp rdi, 4096
    jg .invalid_nebo_deterministic_time_seed_validate
    cmp rsi, 0
    jl .invalid_nebo_deterministic_time_seed_validate
    cmp rsi, 65536
    jg .invalid_nebo_deterministic_time_seed_validate
    cmp rdx, 0
    jl .invalid_nebo_deterministic_time_seed_validate
    cmp rdx, 3
    jg .invalid_nebo_deterministic_time_seed_validate
    xor eax, eax
    ret
.invalid_nebo_deterministic_time_seed_validate:
    mov eax, -1
    ret


global nebo_capture_mock_snapshot_golden_record_e_replay_closeout_contract_validate
nebo_capture_mock_snapshot_golden_record_e_replay_closeout_contract_validate:
    cmp rdi, 1
    jl capture_mock_snapshot_golden_record_e_replay_closeout_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg capture_mock_snapshot_golden_record_e_replay_closeout_.invalid_nebo_contract_validate
    cmp rsi, 0
    jl capture_mock_snapshot_golden_record_e_replay_closeout_.invalid_nebo_contract_validate
    cmp rsi, 65536
    jg capture_mock_snapshot_golden_record_e_replay_closeout_.invalid_nebo_contract_validate
    cmp rdx, 0
    jl capture_mock_snapshot_golden_record_e_replay_closeout_.invalid_nebo_contract_validate
    cmp rdx, 3
    jg capture_mock_snapshot_golden_record_e_replay_closeout_.invalid_nebo_contract_validate
    xor eax, eax
    ret
capture_mock_snapshot_golden_record_e_replay_closeout_.invalid_nebo_contract_validate:
    mov eax, -1
    ret
