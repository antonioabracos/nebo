bits 64
default rel

%include "runtime/stream_monitor.inc"

section .text
global nebo_log_event_validate
nebo_log_event_validate:
    cmp rdi, 1
    jl .invalid_nebo_log_event_validate
    cmp rdi, 32
    jg .invalid_nebo_log_event_validate
    cmp rsi, 0
    jl .invalid_nebo_log_event_validate
    cmp rsi, 4
    jg .invalid_nebo_log_event_validate
    cmp rdx, 0
    jl .invalid_nebo_log_event_validate
    cmp rdx, 1
    jg .invalid_nebo_log_event_validate
    xor eax, eax
    ret
.invalid_nebo_log_event_validate:
    mov eax, -1
    ret


global nebo_progress_validate
nebo_progress_validate:
    cmp rdi, 0
    jl .invalid_nebo_progress_validate
    cmp rdi, 1000000
    jg .invalid_nebo_progress_validate
    cmp rsi, 1
    jl .invalid_nebo_progress_validate
    cmp rsi, 1000000
    jg .invalid_nebo_progress_validate
    cmp rdx, 0
    jl .invalid_nebo_progress_validate
    cmp rdx, 3
    jg .invalid_nebo_progress_validate
    cmp rdi, rsi
    jg .invalid_nebo_progress_validate
    xor eax, eax
    ret
.invalid_nebo_progress_validate:
    mov eax, -1
    ret


global nebo_stream_validate
nebo_stream_validate:
    cmp rdi, 1
    jl .invalid_nebo_stream_validate
    cmp rdi, 4096
    jg .invalid_nebo_stream_validate
    cmp rsi, 1
    jl .invalid_nebo_stream_validate
    cmp rsi, 256
    jg .invalid_nebo_stream_validate
    cmp rdx, 1
    jl .invalid_nebo_stream_validate
    cmp rdx, 3
    jg .invalid_nebo_stream_validate
    cmp rsi, rdi
    jg .invalid_nebo_stream_validate
    xor eax, eax
    ret
.invalid_nebo_stream_validate:
    mov eax, -1
    ret


global nebo_parallel_validate
nebo_parallel_validate:
    cmp rdi, 1
    jl .invalid_nebo_parallel_validate
    cmp rdi, 64
    jg .invalid_nebo_parallel_validate
    cmp rsi, 1
    jl .invalid_nebo_parallel_validate
    cmp rsi, 64
    jg .invalid_nebo_parallel_validate
    cmp rdx, 1
    jl .invalid_nebo_parallel_validate
    cmp rdx, 3
    jg .invalid_nebo_parallel_validate
    cmp rsi, rdi
    jg .invalid_nebo_parallel_validate
    xor eax, eax
    ret
.invalid_nebo_parallel_validate:
    mov eax, -1
    ret


global nebo_timeline_validate
nebo_timeline_validate:
    cmp rdi, 1
    jl .invalid_nebo_timeline_validate
    cmp rdi, 100000
    jg .invalid_nebo_timeline_validate
    cmp rsi, 1
    jl .invalid_nebo_timeline_validate
    cmp rsi, 1
    jg .invalid_nebo_timeline_validate
    cmp rdx, 1
    jl .invalid_nebo_timeline_validate
    cmp rdx, 3
    jg .invalid_nebo_timeline_validate
    xor eax, eax
    ret
.invalid_nebo_timeline_validate:
    mov eax, -1
    ret


global nebo_backpressure_validate
nebo_backpressure_validate:
    cmp rdi, 0
    jl .invalid_nebo_backpressure_validate
    cmp rdi, 256
    jg .invalid_nebo_backpressure_validate
    cmp rsi, 1
    jl .invalid_nebo_backpressure_validate
    cmp rsi, 256
    jg .invalid_nebo_backpressure_validate
    cmp rdx, 0
    jl .invalid_nebo_backpressure_validate
    cmp rdx, 1
    jg .invalid_nebo_backpressure_validate
    cmp rdi, rsi
    jg .invalid_nebo_backpressure_validate
    xor eax, eax
    ret
.invalid_nebo_backpressure_validate:
    mov eax, -1
    ret


global nebo_window_validate
nebo_window_validate:
    cmp rdi, 1
    jl .invalid_nebo_window_validate
    cmp rdi, 100000
    jg .invalid_nebo_window_validate
    cmp rsi, 1
    jl .invalid_nebo_window_validate
    cmp rsi, 86400000
    jg .invalid_nebo_window_validate
    cmp rdx, 1
    jl .invalid_nebo_window_validate
    cmp rdx, 3
    jg .invalid_nebo_window_validate
    xor eax, eax
    ret
.invalid_nebo_window_validate:
    mov eax, -1
    ret


global nebo_metric_validate
nebo_metric_validate:
    cmp rdi, 1
    jl .invalid_nebo_metric_validate
    cmp rdi, 64
    jg .invalid_nebo_metric_validate
    cmp rsi, 0
    jl .invalid_nebo_metric_validate
    cmp rsi, 4
    jg .invalid_nebo_metric_validate
    cmp rdx, 1
    jl .invalid_nebo_metric_validate
    cmp rdx, 8
    jg .invalid_nebo_metric_validate
    xor eax, eax
    ret
.invalid_nebo_metric_validate:
    mov eax, -1
    ret


global nebo_cancellation_validate
nebo_cancellation_validate:
    cmp rdi, 1
    jl .invalid_nebo_cancellation_validate
    cmp rdi, 3
    jg .invalid_nebo_cancellation_validate
    cmp rsi, 0
    jl .invalid_nebo_cancellation_validate
    cmp rsi, 1
    jg .invalid_nebo_cancellation_validate
    cmp rdx, 0
    jl .invalid_nebo_cancellation_validate
    cmp rdx, 255
    jg .invalid_nebo_cancellation_validate
    xor eax, eax
    ret
.invalid_nebo_cancellation_validate:
    mov eax, -1
    ret


global nebo_stream_contract_validate
nebo_stream_contract_validate:
    cmp rdi, 1
    jl .invalid_nebo_stream_contract_validate
    cmp rdi, 4096
    jg .invalid_nebo_stream_contract_validate
    cmp rsi, 0
    jl .invalid_nebo_stream_contract_validate
    cmp rsi, 256
    jg .invalid_nebo_stream_contract_validate
    cmp rdx, 1
    jl .invalid_nebo_stream_contract_validate
    cmp rdx, 64
    jg .invalid_nebo_stream_contract_validate
    cmp rsi, rdi
    jg .invalid_nebo_stream_contract_validate
    xor eax, eax
    ret
.invalid_nebo_stream_contract_validate:
    mov eax, -1
    ret
