bits 64
default rel
global _start
extern nebo_text_event_validate
extern nebo_protocolo_headless_events_jsonl_e_round_trip_protocol_version_e_schema_schema_validate

section .text
_start:
    mov rdi, 1
    mov rsi, 256
    mov rdx, 1
    call nebo_text_event_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 256
    mov rdx, 1
    call nebo_text_event_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1
    mov rsi, 256
    mov rdx, 2
    call nebo_text_event_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1
    mov rsi, 256
    mov rdx, 1
    call nebo_text_event_validate
    test eax, eax
    jne .fail
    mov rdi, 1
    mov rsi, 4096
    mov rdx, 8
    call nebo_protocolo_headless_events_jsonl_e_round_trip_protocol_version_e_schema_schema_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
