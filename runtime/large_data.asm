bits 64
default rel

%include "runtime/large_data.inc"

section .text
global nebo_lod_validate
nebo_lod_validate:
    cmp rdi, 1
    jl .invalid_nebo_lod_validate
    cmp rdi, 16
    jg .invalid_nebo_lod_validate
    cmp rsi, 1
    jl .invalid_nebo_lod_validate
    cmp rsi, 100000
    jg .invalid_nebo_lod_validate
    cmp rdx, 1
    jl .invalid_nebo_lod_validate
    cmp rdx, 4
    jg .invalid_nebo_lod_validate
    xor eax, eax
    ret
.invalid_nebo_lod_validate:
    mov eax, -1
    ret


global nebo_decimation_validate
nebo_decimation_validate:
    cmp rdi, 1
    jl .invalid_nebo_decimation_validate
    cmp rdi, 100000
    jg .invalid_nebo_decimation_validate
    cmp rsi, 1
    jl .invalid_nebo_decimation_validate
    cmp rsi, 100000
    jg .invalid_nebo_decimation_validate
    cmp rdx, 1
    jl .invalid_nebo_decimation_validate
    cmp rdx, 3
    jg .invalid_nebo_decimation_validate
    cmp rsi, rdi
    jg .invalid_nebo_decimation_validate
    xor eax, eax
    ret
.invalid_nebo_decimation_validate:
    mov eax, -1
    ret


global nebo_sampling_validate
nebo_sampling_validate:
    cmp rdi, 1
    jl .invalid_nebo_sampling_validate
    cmp rdi, 100000
    jg .invalid_nebo_sampling_validate
    cmp rsi, 1
    jl .invalid_nebo_sampling_validate
    cmp rsi, 100000
    jg .invalid_nebo_sampling_validate
    cmp rdx, 1
    jl .invalid_nebo_sampling_validate
    cmp rdx, 2147483647
    jg .invalid_nebo_sampling_validate
    cmp rsi, rdi
    jg .invalid_nebo_sampling_validate
    xor eax, eax
    ret
.invalid_nebo_sampling_validate:
    mov eax, -1
    ret


global nebo_density_validate
nebo_density_validate:
    cmp rdi, 1
    jl .invalid_nebo_density_validate
    cmp rdi, 4096
    jg .invalid_nebo_density_validate
    cmp rsi, 1
    jl .invalid_nebo_density_validate
    cmp rsi, 16
    jg .invalid_nebo_density_validate
    cmp rdx, 1
    jl .invalid_nebo_density_validate
    cmp rdx, 256
    jg .invalid_nebo_density_validate
    xor eax, eax
    ret
.invalid_nebo_density_validate:
    mov eax, -1
    ret


global nebo_aggregation_validate
nebo_aggregation_validate:
    cmp rdi, 1
    jl .invalid_nebo_aggregation_validate
    cmp rdi, 100000
    jg .invalid_nebo_aggregation_validate
    cmp rsi, 1
    jl .invalid_nebo_aggregation_validate
    cmp rsi, 4096
    jg .invalid_nebo_aggregation_validate
    cmp rdx, 1
    jl .invalid_nebo_aggregation_validate
    cmp rdx, 4
    jg .invalid_nebo_aggregation_validate
    cmp rsi, rdi
    jg .invalid_nebo_aggregation_validate
    xor eax, eax
    ret
.invalid_nebo_aggregation_validate:
    mov eax, -1
    ret


global nebo_partition_validate
nebo_partition_validate:
    cmp rdi, 1
    jl .invalid_nebo_partition_validate
    cmp rdi, 65536
    jg .invalid_nebo_partition_validate
    cmp rsi, 1
    jl .invalid_nebo_partition_validate
    cmp rsi, 4096
    jg .invalid_nebo_partition_validate
    cmp rdx, 1
    jl .invalid_nebo_partition_validate
    cmp rdx, 100000
    jg .invalid_nebo_partition_validate
    xor eax, eax
    ret
.invalid_nebo_partition_validate:
    mov eax, -1
    ret


global nebo_cache_validate
nebo_cache_validate:
    cmp rdi, 1
    jl .invalid_nebo_cache_validate
    cmp rdi, 1024
    jg .invalid_nebo_cache_validate
    cmp rsi, 1
    jl .invalid_nebo_cache_validate
    cmp rsi, 1000000
    jg .invalid_nebo_cache_validate
    cmp rdx, 1
    jl .invalid_nebo_cache_validate
    cmp rdx, 2
    jg .invalid_nebo_cache_validate
    xor eax, eax
    ret
.invalid_nebo_cache_validate:
    mov eax, -1
    ret


global nebo_budget_validate
nebo_budget_validate:
    cmp rdi, 1
    jl .invalid_nebo_budget_validate
    cmp rdi, 67108864
    jg .invalid_nebo_budget_validate
    cmp rsi, 1
    jl .invalid_nebo_budget_validate
    cmp rsi, 100
    jg .invalid_nebo_budget_validate
    cmp rdx, 1
    jl .invalid_nebo_budget_validate
    cmp rdx, 4
    jg .invalid_nebo_budget_validate
    xor eax, eax
    ret
.invalid_nebo_budget_validate:
    mov eax, -1
    ret


global nebo_performance_report_validate
nebo_performance_report_validate:
    cmp rdi, 1
    jl .invalid_nebo_performance_report_validate
    cmp rdi, 100000
    jg .invalid_nebo_performance_report_validate
    cmp rsi, 1
    jl .invalid_nebo_performance_report_validate
    cmp rsi, 100
    jg .invalid_nebo_performance_report_validate
    cmp rdx, 0
    jl .invalid_nebo_performance_report_validate
    cmp rdx, 10
    jg .invalid_nebo_performance_report_validate
    xor eax, eax
    ret
.invalid_nebo_performance_report_validate:
    mov eax, -1
    ret


global nebo_large_data_contract_validate
nebo_large_data_contract_validate:
    cmp rdi, 1
    jl .invalid_nebo_large_data_contract_validate
    cmp rdi, 100000
    jg .invalid_nebo_large_data_contract_validate
    cmp rsi, 1
    jl .invalid_nebo_large_data_contract_validate
    cmp rsi, 67108864
    jg .invalid_nebo_large_data_contract_validate
    cmp rdx, 1
    jl .invalid_nebo_large_data_contract_validate
    cmp rdx, 1024
    jg .invalid_nebo_large_data_contract_validate
    xor eax, eax
    ret
.invalid_nebo_large_data_contract_validate:
    mov eax, -1
    ret
