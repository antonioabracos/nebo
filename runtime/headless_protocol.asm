bits 64
default rel

%include "runtime/headless_protocol.inc"

section .text
global nebo_protocolo_headless_events_jsonl_e_round_trip_protocol_version_e_schema_schema_validate
nebo_protocolo_headless_events_jsonl_e_round_trip_protocol_version_e_schema_schema_validate:
    cmp rdi, 1
    jl .invalid_nebo_schema_validate
    cmp rdi, 1
    jg .invalid_nebo_schema_validate
    cmp rsi, 1
    jl .invalid_nebo_schema_validate
    cmp rsi, 65536
    jg .invalid_nebo_schema_validate
    cmp rdx, 1
    jl .invalid_nebo_schema_validate
    cmp rdx, 64
    jg .invalid_nebo_schema_validate
    xor eax, eax
    ret
.invalid_nebo_schema_validate:
    mov eax, -1
    ret


global nebo_text_event_validate
nebo_text_event_validate:
    cmp rdi, 1
    jl .invalid_nebo_text_event_validate
    cmp rdi, 1
    jg .invalid_nebo_text_event_validate
    cmp rsi, 1
    jl .invalid_nebo_text_event_validate
    cmp rsi, 65536
    jg .invalid_nebo_text_event_validate
    cmp rdx, 1
    jl .invalid_nebo_text_event_validate
    cmp rdx, 1
    jg .invalid_nebo_text_event_validate
    xor eax, eax
    ret
.invalid_nebo_text_event_validate:
    mov eax, -1
    ret


global nebo_table_event_validate
nebo_table_event_validate:
    cmp rdi, 2
    jl .invalid_nebo_table_event_validate
    cmp rdi, 2
    jg .invalid_nebo_table_event_validate
    cmp rsi, 1
    jl .invalid_nebo_table_event_validate
    cmp rsi, 4096
    jg .invalid_nebo_table_event_validate
    cmp rdx, 1
    jl .invalid_nebo_table_event_validate
    cmp rdx, 256
    jg .invalid_nebo_table_event_validate
    xor eax, eax
    ret
.invalid_nebo_table_event_validate:
    mov eax, -1
    ret


global nebo_visual_event_validate
nebo_visual_event_validate:
    cmp rdi, 3
    jl .invalid_nebo_visual_event_validate
    cmp rdi, 5
    jg .invalid_nebo_visual_event_validate
    cmp rsi, 1
    jl .invalid_nebo_visual_event_validate
    cmp rsi, 256
    jg .invalid_nebo_visual_event_validate
    cmp rdx, 1
    jl .invalid_nebo_visual_event_validate
    cmp rdx, 1
    jg .invalid_nebo_visual_event_validate
    xor eax, eax
    ret
.invalid_nebo_visual_event_validate:
    mov eax, -1
    ret


global nebo_scan_event_validate
nebo_scan_event_validate:
    cmp rdi, 6
    jl .invalid_nebo_scan_event_validate
    cmp rdi, 10
    jg .invalid_nebo_scan_event_validate
    cmp rsi, 1
    jl .invalid_nebo_scan_event_validate
    cmp rsi, 4096
    jg .invalid_nebo_scan_event_validate
    cmp rdx, 1
    jl .invalid_nebo_scan_event_validate
    cmp rdx, 1
    jg .invalid_nebo_scan_event_validate
    xor eax, eax
    ret
.invalid_nebo_scan_event_validate:
    mov eax, -1
    ret


global nebo_jsonl_batch_validate
nebo_jsonl_batch_validate:
    cmp rdi, 1
    jl .invalid_nebo_jsonl_batch_validate
    cmp rdi, 4096
    jg .invalid_nebo_jsonl_batch_validate
    cmp rsi, 1
    jl .invalid_nebo_jsonl_batch_validate
    cmp rsi, 65536
    jg .invalid_nebo_jsonl_batch_validate
    cmp rdx, 1
    jl .invalid_nebo_jsonl_batch_validate
    cmp rdx, 3
    jg .invalid_nebo_jsonl_batch_validate
    xor eax, eax
    ret
.invalid_nebo_jsonl_batch_validate:
    mov eax, -1
    ret


global nebo_roundtrip_validate
nebo_roundtrip_validate:
    cmp rdi, 1
    jl .invalid_nebo_roundtrip_validate
    cmp rdi, 1
    jg .invalid_nebo_roundtrip_validate
    cmp rsi, 1
    jl .invalid_nebo_roundtrip_validate
    cmp rsi, 1
    jg .invalid_nebo_roundtrip_validate
    cmp rdx, 1
    jl .invalid_nebo_roundtrip_validate
    cmp rdx, 64
    jg .invalid_nebo_roundtrip_validate
    cmp rdi, rsi
    jne .invalid_nebo_roundtrip_validate
    xor eax, eax
    ret
.invalid_nebo_roundtrip_validate:
    mov eax, -1
    ret

global nebo_event_pack
nebo_event_pack:
    cmp rdi, 1
    jl .invalid_nebo_event_pack
    cmp rdi, 255
    jg .invalid_nebo_event_pack
    cmp rsi, 0
    jl .invalid_nebo_event_pack
    cmp rsi, 65535
    jg .invalid_nebo_event_pack
    cmp rdx, 1
    jne .invalid_nebo_event_pack
    mov rax, rdx
    shl rax, 56
    mov rcx, rdi
    shl rcx, 48
    or rax, rcx
    or rax, rsi
    ret
.invalid_nebo_event_pack:
    mov rax, -1
    ret


global nebo_capability_report_validate
nebo_capability_report_validate:
    cmp rdi, 1
    jl .invalid_nebo_capability_report_validate
    cmp rdi, 32
    jg .invalid_nebo_capability_report_validate
    cmp rsi, 0
    jl .invalid_nebo_capability_report_validate
    cmp rsi, 1
    jg .invalid_nebo_capability_report_validate
    cmp rdx, 1
    jl .invalid_nebo_capability_report_validate
    cmp rdx, 1
    jg .invalid_nebo_capability_report_validate
    xor eax, eax
    ret
.invalid_nebo_capability_report_validate:
    mov eax, -1
    ret


global nebo_security_validate
nebo_security_validate:
    cmp rdi, 1
    jl .invalid_nebo_security_validate
    cmp rdi, 1
    jg .invalid_nebo_security_validate
    cmp rsi, 1
    jl .invalid_nebo_security_validate
    cmp rsi, 1
    jg .invalid_nebo_security_validate
    cmp rdx, 1
    jl .invalid_nebo_security_validate
    cmp rdx, 2
    jg .invalid_nebo_security_validate
    xor eax, eax
    ret
.invalid_nebo_security_validate:
    mov eax, -1
    ret


global nebo_protocol_contract_validate
nebo_protocol_contract_validate:
    cmp rdi, 1
    jl .invalid_nebo_protocol_contract_validate
    cmp rdi, 4096
    jg .invalid_nebo_protocol_contract_validate
    cmp rsi, 1
    jl .invalid_nebo_protocol_contract_validate
    cmp rsi, 65536
    jg .invalid_nebo_protocol_contract_validate
    cmp rdx, 1
    jl .invalid_nebo_protocol_contract_validate
    cmp rdx, 1
    jg .invalid_nebo_protocol_contract_validate
    xor eax, eax
    ret
.invalid_nebo_protocol_contract_validate:
    mov eax, -1
    ret
