; MF011 native primary suite for SourceFile and UTF-8.

bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/support/memory/memory_region.inc"
%include "compiler/support/memory/arena.inc"
%include "compiler/source/file/source_file.inc"
%include "tests/fake-host/fake_host.inc"

extern nebo_fake_host_services
extern nebo_fake_host_context
extern nebo_fake_host_reset
extern neboc_memory_region_init
extern neboc_memory_region_destroy
extern neboc_arena_init
extern neboc_arena_destroy
extern neboc_source_file_load
extern neboc_source_file_validate
extern neboc_host_process_exit

global _start

%define TEST_OWNER 0x4d46303131
%define VALID_HASH 0x6c7bf8e9

section .text
_start:
    mov rax, [rsp]
    cmp rax, 2
    jb .usage
    mov rsi, [rsp + 16]
    mov al, [rsi]
    sub al, '0'
    cmp al, 1
    je .s1
    cmp al, 2
    je .s2
    cmp al, 3
    je .s3
    cmp al, 7
    je .s7
    jmp .usage
.s1:
    call scenario_valid
    jmp .exit
.s2:
    call scenario_bom
    jmp .exit
.s3:
    call scenario_invalid_utf8
    jmp .exit
.s7:
    call scenario_oversize
.exit:
    mov edi, eax
    jmp neboc_host_process_exit
.usage:
    mov edi, 99
    jmp neboc_host_process_exit

clear_state:
    lea rdi, [rel test_region]
    xor eax, eax
    mov ecx, (test_state_end - test_region) / 8
    cld
    rep stosq
    ret

setup:
    sub rsp, 8
    call nebo_fake_host_reset
    call clear_state
    lea rdi, [rel test_region]
    lea rsi, [rel nebo_fake_host_services]
    mov edx, 4096
    mov ecx, 4096
    mov r8, TEST_OWNER
    call neboc_memory_region_init
    test eax, eax
    jne .done
    lea rdi, [rel test_arena]
    lea rsi, [rel test_region]
    mov edx, 4096
    mov rcx, TEST_OWNER
    call neboc_arena_init
.done:
    add rsp, 8
    ret

cleanup:
    sub rsp, 8
    lea rdi, [rel test_arena]
    mov rsi, TEST_OWNER
    call neboc_arena_destroy
    test eax, eax
    jne .done
    lea rdi, [rel test_region]
    mov rsi, TEST_OWNER
    call neboc_memory_region_destroy
.done:
    add rsp, 8
    ret

configure_request:
    ; RDI data, RSI length, RDX logical pointer, RCX logical length, R8 limit
    mov [rel nebo_fake_host_context + NEBOC_FAKE_FILE_DATA_POINTER_OFFSET], rdi
    mov [rel nebo_fake_host_context + NEBOC_FAKE_FILE_DATA_LENGTH_OFFSET], rsi
    mov qword [rel nebo_fake_host_context + NEBOC_FAKE_PARTIAL_CHUNK_OFFSET], 2
    lea rax, [rel nebo_fake_host_services]
    mov [rel request + NEBOC_SOURCE_REQUEST_HOST_OFFSET], rax
    lea rax, [rel test_arena]
    mov [rel request + NEBOC_SOURCE_REQUEST_ARENA_OFFSET], rax
    mov rax, TEST_OWNER
    mov [rel request + NEBOC_SOURCE_REQUEST_OWNER_OFFSET], rax
    lea rax, [rel physical_path]
    mov [rel request + NEBOC_SOURCE_REQUEST_PHYSICAL_PATH_OFFSET], rax
    mov qword [rel request + NEBOC_SOURCE_REQUEST_PHYSICAL_LENGTH_OFFSET], physical_path_length
    mov [rel request + NEBOC_SOURCE_REQUEST_LOGICAL_PATH_OFFSET], rdx
    mov [rel request + NEBOC_SOURCE_REQUEST_LOGICAL_LENGTH_OFFSET], rcx
    mov [rel request + NEBOC_SOURCE_REQUEST_LIMIT_OFFSET], r8
    ret

scenario_valid:
    push rbx
    call setup
    test eax, eax
    jnz .fail
    lea rdi, [rel valid_source]
    mov esi, valid_source_length
    lea rdx, [rel logical_valid]
    mov ecx, logical_valid_length
    mov r8d, 64
    call configure_request
    lea rdi, [rel source_file]
    lea rsi, [rel request]
    call neboc_source_file_load
    test eax, eax
    jnz .fail_cleanup
    lea rdi, [rel source_file]
    mov rsi, TEST_OWNER
    call neboc_source_file_validate
    test eax, eax
    jnz .fail_cleanup
    cmp qword [rel source_file + NEBOC_SOURCE_FILE_CONTENT_LENGTH_OFFSET], valid_source_length
    jne .fail_cleanup
    cmp qword [rel source_file + NEBOC_SOURCE_FILE_CONTENT_HASH_OFFSET], VALID_HASH
    jne .fail_cleanup
    mov rsi, [rel source_file + NEBOC_SOURCE_FILE_CONTENT_OFFSET]
    lea rdi, [rel valid_source]
    mov ecx, valid_source_length
    cld
    repe cmpsb
    jne .fail_cleanup
    cmp qword [rel source_file + NEBOC_SOURCE_FILE_LOGICAL_LENGTH_OFFSET], logical_valid_length
    jne .fail_cleanup
    mov rsi, [rel source_file + NEBOC_SOURCE_FILE_LOGICAL_PATH_OFFSET]
    lea rdi, [rel logical_valid]
    mov ecx, logical_valid_length
    repe cmpsb
    jne .fail_cleanup
    cmp qword [rel source_file + NEBOC_SOURCE_FILE_DIAGNOSTIC_OFFSET], NEBOC_SOURCE_DIAGNOSTIC_NONE
    jne .fail_cleanup
    cmp qword [rel nebo_fake_host_context + NEBOC_FAKE_FILE_OPEN_OFFSET], 0
    jne .fail_cleanup
    cmp qword [rel nebo_fake_host_context + NEBOC_FAKE_READ_CALLS_OFFSET], 1
    jbe .fail_cleanup
    call cleanup
    test eax, eax
    jnz .fail
    xor eax, eax
    jmp .done
.fail_cleanup:
    call cleanup
.fail:
    mov eax, 1
.done:
    pop rbx
    ret

scenario_bom:
    push rbx
    call setup
    test eax, eax
    jnz .fail
    lea rdi, [rel bom_source]
    mov esi, bom_source_length
    lea rdx, [rel logical_bom]
    mov ecx, logical_bom_length
    mov r8d, 64
    call configure_request
    lea rdi, [rel source_file]
    lea rsi, [rel request]
    call neboc_source_file_load
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne .fail_cleanup
    cmp qword [rel source_file + NEBOC_SOURCE_FILE_DIAGNOSTIC_OFFSET], NEBOC_SOURCE_DIAGNOSTIC_BOM_FORBIDDEN
    jne .fail_cleanup
    cmp qword [rel source_file + NEBOC_SOURCE_FILE_DIAGNOSTIC_OFFSET_OFFSET], 0
    jne .fail_cleanup
    cmp qword [rel source_file + NEBOC_SOURCE_FILE_ACTIVE_OFFSET], 0
    jne .fail_cleanup
    cmp qword [rel nebo_fake_host_context + NEBOC_FAKE_FILE_OPEN_OFFSET], 0
    jne .fail_cleanup
    call cleanup
    xor eax, eax
    jmp .done
.fail_cleanup:
    call cleanup
.fail:
    mov eax, 1
.done:
    pop rbx
    ret

scenario_invalid_utf8:
    push rbx
    call setup
    test eax, eax
    jnz .fail
    lea rdi, [rel invalid_source]
    mov esi, invalid_source_length
    lea rdx, [rel logical_invalid]
    mov ecx, logical_invalid_length
    mov r8d, 64
    call configure_request
    lea rdi, [rel source_file]
    lea rsi, [rel request]
    call neboc_source_file_load
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne .fail_cleanup
    cmp qword [rel source_file + NEBOC_SOURCE_FILE_DIAGNOSTIC_OFFSET], NEBOC_SOURCE_DIAGNOSTIC_INVALID_UTF8
    jne .fail_cleanup
    cmp qword [rel source_file + NEBOC_SOURCE_FILE_DIAGNOSTIC_OFFSET_OFFSET], 2
    jne .fail_cleanup
    cmp qword [rel source_file + NEBOC_SOURCE_FILE_ACTIVE_OFFSET], 0
    jne .fail_cleanup
    call cleanup
    xor eax, eax
    jmp .done
.fail_cleanup:
    call cleanup
.fail:
    mov eax, 1
.done:
    pop rbx
    ret

scenario_oversize:
    push rbx
    call setup
    test eax, eax
    jnz .fail
    lea rdi, [rel oversize_source]
    mov esi, oversize_source_length
    lea rdx, [rel logical_large]
    mov ecx, logical_large_length
    mov r8d, 64
    call configure_request
    lea rdi, [rel source_file]
    lea rsi, [rel request]
    call neboc_source_file_load
    cmp eax, NEBOC_STATUS_LIMIT_EXCEEDED
    jne .fail_cleanup
    cmp qword [rel source_file + NEBOC_SOURCE_FILE_DIAGNOSTIC_OFFSET], NEBOC_SOURCE_DIAGNOSTIC_LIMIT_EXCEEDED
    jne .fail_cleanup
    cmp qword [rel source_file + NEBOC_SOURCE_FILE_DIAGNOSTIC_OFFSET_OFFSET], 64
    jne .fail_cleanup
    cmp qword [rel source_file + NEBOC_SOURCE_FILE_ACTIVE_OFFSET], 0
    jne .fail_cleanup
    cmp qword [rel nebo_fake_host_context + NEBOC_FAKE_FILE_OPEN_OFFSET], 0
    jne .fail_cleanup
    call cleanup
    xor eax, eax
    jmp .done
.fail_cleanup:
    call cleanup
.fail:
    mov eax, 1
.done:
    pop rbx
    ret

section .rodata
physical_path: db "ignored.no", 0
physical_path_length equ $ - physical_path - 1
logical_valid: db "src/main.no"
logical_valid_length equ $ - logical_valid
logical_bom: db "src/bom.no"
logical_bom_length equ $ - logical_bom
logical_invalid: db "src/invalid.no"
logical_invalid_length equ $ - logical_invalid
logical_large: db "src/large.no"
logical_large_length equ $ - logical_large
valid_source: db 115, 116, 97, 114, 116, 40, 41, 32, 123, 10, 32, 32, 34, 79, 108, 195, 161, 34, 46, 99, 111, 110, 115, 111, 108, 101, 59, 10, 125, 10
valid_source_length equ $ - valid_source
bom_source: db 239, 187, 191, 115, 116, 97, 114, 116, 40, 41, 32, 123, 125, 10
bom_source_length equ $ - bom_source
invalid_source: db 102, 110, 192, 175, 40, 41, 10
invalid_source_length equ $ - invalid_source
oversize_source: times 65 db 'A'
oversize_source_length equ $ - oversize_source

section .bss align=16
test_region: resb NEBOC_MEMORY_REGION_SIZE
test_arena: resb NEBOC_ARENA_SIZE
source_file: resb NEBOC_SOURCE_FILE_SIZE
request: resb NEBOC_SOURCE_REQUEST_SIZE
test_state_end:

section .note.GNU-stack noalloc noexec nowrite progbits
