; MF011 Linux HostServices source read smoke. Physical extension is deliberately
; not .no; security and validation depend on bytes, not filename extension.

bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/support/memory/memory_region.inc"
%include "compiler/support/memory/arena.inc"
%include "compiler/source/file/source_file.inc"

extern neboc_linux_host_services
extern neboc_memory_region_init
extern neboc_memory_region_destroy
extern neboc_arena_init
extern neboc_arena_destroy
extern neboc_source_file_load
extern neboc_source_file_validate
extern neboc_host_process_exit

global _start

%define OWNER 0x4c4e58303131
%define LINUX_HASH 0xeda303ed

section .text
_start:
    lea rdi, [rel region]
    lea rsi, [rel neboc_linux_host_services]
    mov edx, 4096
    mov ecx, 4096
    mov r8, OWNER
    call neboc_memory_region_init
    test eax, eax
    jnz .fail
    lea rdi, [rel arena]
    lea rsi, [rel region]
    mov edx, 4096
    mov rcx, OWNER
    call neboc_arena_init
    test eax, eax
    jnz .fail_region

    lea rax, [rel neboc_linux_host_services]
    mov [rel request + NEBOC_SOURCE_REQUEST_HOST_OFFSET], rax
    lea rax, [rel arena]
    mov [rel request + NEBOC_SOURCE_REQUEST_ARENA_OFFSET], rax
    mov rax, OWNER
    mov [rel request + NEBOC_SOURCE_REQUEST_OWNER_OFFSET], rax
    lea rax, [rel physical_path]
    mov [rel request + NEBOC_SOURCE_REQUEST_PHYSICAL_PATH_OFFSET], rax
    mov qword [rel request + NEBOC_SOURCE_REQUEST_PHYSICAL_LENGTH_OFFSET], physical_path_length
    lea rax, [rel logical_path]
    mov [rel request + NEBOC_SOURCE_REQUEST_LOGICAL_PATH_OFFSET], rax
    mov qword [rel request + NEBOC_SOURCE_REQUEST_LOGICAL_LENGTH_OFFSET], logical_path_length
    mov qword [rel request + NEBOC_SOURCE_REQUEST_LIMIT_OFFSET], 256

    lea rdi, [rel source]
    lea rsi, [rel request]
    call neboc_source_file_load
    test eax, eax
    jnz .fail_arena
    lea rdi, [rel source]
    mov rsi, OWNER
    call neboc_source_file_validate
    test eax, eax
    jnz .fail_arena
    cmp qword [rel source + NEBOC_SOURCE_FILE_CONTENT_LENGTH_OFFSET], 35
    jne .fail_arena
    mov eax, LINUX_HASH
    cmp qword [rel source + NEBOC_SOURCE_FILE_CONTENT_HASH_OFFSET], rax
    jne .fail_arena
    cmp qword [rel source + NEBOC_SOURCE_FILE_LOGICAL_LENGTH_OFFSET], logical_path_length
    jne .fail_arena

    lea rdi, [rel arena]
    mov rsi, OWNER
    call neboc_arena_destroy
    test eax, eax
    jnz .fail
    lea rdi, [rel region]
    mov rsi, OWNER
    call neboc_memory_region_destroy
    mov edi, eax
    jmp neboc_host_process_exit
.fail_arena:
    lea rdi, [rel arena]
    mov rsi, OWNER
    call neboc_arena_destroy
.fail_region:
    lea rdi, [rel region]
    mov rsi, OWNER
    call neboc_memory_region_destroy
.fail:
    mov edi, 1
    jmp neboc_host_process_exit

section .rodata
physical_path: db "tests/source/fixtures/linux-valid.data", 0
physical_path_length equ $ - physical_path - 1
logical_path: db "examples/linux-source.no"
logical_path_length equ $ - logical_path

section .bss align=16
region: resb NEBOC_MEMORY_REGION_SIZE
arena: resb NEBOC_ARENA_SIZE
source: resb NEBOC_SOURCE_FILE_SIZE
request: resb NEBOC_SOURCE_REQUEST_SIZE

section .note.GNU-stack noalloc noexec nowrite progbits
