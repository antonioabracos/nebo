; MF012 native conformance suite for LineMap, SourceSpan and snippets.

bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/support/memory/memory_region.inc"
%include "compiler/support/memory/arena.inc"
%include "compiler/source/line-map/line_map.inc"
%include "compiler/source/span/source_span.inc"
%include "compiler/source/snippet/snippet.inc"
%include "tests/fake-host/fake_host.inc"

extern nebo_fake_host_services
extern nebo_fake_host_reset
extern neboc_memory_region_init
extern neboc_memory_region_destroy
extern neboc_arena_init
extern neboc_arena_destroy
extern neboc_line_map_build
extern neboc_line_map_validate
extern neboc_line_map_lookup
extern neboc_source_span_init
extern neboc_source_span_validate
extern neboc_source_span_union
extern neboc_snippet_extract
extern neboc_host_process_exit

global _start

%define TEST_OWNER 0x4d463132
%define SOURCE_ID 0x0100000000000012

section .text

_start:
    mov rax, [rsp]
    cmp rax, 2
    jb .usage
    mov rsi, [rsp + 16]
    mov al, [rsi]
    sub al, '0'
    cmp al, 4
    je .s4
    cmp al, 5
    je .s5
    cmp al, 6
    je .s6
    cmp al, 8
    je .s8
    jmp .usage
.s4:
    call scenario_4
    jmp .finish
.s5:
    call scenario_5
    jmp .finish
.s6:
    call scenario_6
    jmp .finish
.s8:
    call scenario_8
.finish:
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
    mov r8d, TEST_OWNER
    call neboc_memory_region_init
    test eax, eax
    jne .done
    lea rdi, [rel test_arena]
    lea rsi, [rel test_region]
    mov edx, 4096
    mov ecx, TEST_OWNER
    call neboc_arena_init
.done:
    add rsp, 8
    ret

cleanup:
    sub rsp, 8
    lea rdi, [rel test_arena]
    mov esi, TEST_OWNER
    call neboc_arena_destroy
    test eax, eax
    jne .done
    lea rdi, [rel test_region]
    mov esi, TEST_OWNER
    call neboc_memory_region_destroy
.done:
    add rsp, 8
    ret

build_map_a:
    ; RSI=source, RDX=length
    lea rdi, [rel map_a]
    lea rcx, [rel test_arena]
    mov r8d, TEST_OWNER
    mov r9, SOURCE_ID
    jmp neboc_line_map_build

build_map_b:
    ; RSI=source, RDX=length
    lea rdi, [rel map_b]
    lea rcx, [rel test_arena]
    mov r8d, TEST_OWNER
    mov r9, SOURCE_ID
    jmp neboc_line_map_build

scenario_4:
    sub rsp, 8
    call setup
    test eax, eax
    jnz .fail
    lea rsi, [rel source_lf]
    mov edx, source_lf_length
    call build_map_a
    test eax, eax
    jnz .fail_cleanup
    cmp qword [rel map_a + NEBOC_LINE_MAP_LINE_COUNT_OFFSET], 3
    jne .fail_cleanup
    mov rax, [rel map_a + NEBOC_LINE_MAP_STARTS_OFFSET]
    cmp qword [rax], 0
    jne .fail_cleanup
    cmp qword [rax + 8], 6
    jne .fail_cleanup
    cmp qword [rax + 16], 12
    jne .fail_cleanup
    lea rdi, [rel map_a]
    mov esi, TEST_OWNER
    call neboc_line_map_validate
    test eax, eax
    jnz .fail_cleanup
    lea rdi, [rel span_a]
    mov rsi, SOURCE_ID
    mov edx, 6
    mov ecx, 11
    mov r8d, source_lf_length
    call neboc_source_span_init
    test eax, eax
    jnz .fail_cleanup
    lea rdi, [rel map_a]
    lea rsi, [rel span_a]
    lea rdx, [rel logical_path]
    mov ecx, logical_path_length
    mov r8d, NEBOC_SNIPPET_DEFAULT_MAX_BYTES
    lea r9, [rel snippet_a]
    call neboc_snippet_extract
    test eax, eax
    jnz .fail_cleanup
    cmp qword [rel snippet_a + NEBOC_SNIPPET_LINE_OFFSET], 2
    jne .fail_cleanup
    cmp qword [rel snippet_a + NEBOC_SNIPPET_BYTE_LENGTH_OFFSET], 5
    jne .fail_cleanup
    mov rsi, [rel snippet_a + NEBOC_SNIPPET_BYTES_OFFSET]
    lea rdi, [rel line_beta]
    mov ecx, line_beta_length
    repe cmpsb
    jne .fail_cleanup
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
    add rsp, 8
    ret

scenario_5:
    sub rsp, 8
    call setup
    test eax, eax
    jnz .fail
    lea rsi, [rel source_crlf]
    mov edx, source_crlf_length
    call build_map_a
    test eax, eax
    jnz .fail_cleanup
    cmp qword [rel map_a + NEBOC_LINE_MAP_LINE_COUNT_OFFSET], 3
    jne .fail_cleanup
    mov rax, [rel map_a + NEBOC_LINE_MAP_STARTS_OFFSET]
    cmp qword [rax], 0
    jne .fail_cleanup
    cmp qword [rax + 8], 7
    jne .fail_cleanup
    cmp qword [rax + 16], 14
    jne .fail_cleanup
    lea rdi, [rel span_a]
    mov rsi, SOURCE_ID
    mov edx, 7
    mov ecx, 12
    mov r8d, source_crlf_length
    call neboc_source_span_init
    test eax, eax
    jnz .fail_cleanup
    lea rdi, [rel map_a]
    lea rsi, [rel span_a]
    lea rdx, [rel logical_path]
    mov ecx, logical_path_length
    mov r8d, NEBOC_SNIPPET_DEFAULT_MAX_BYTES
    lea r9, [rel snippet_a]
    call neboc_snippet_extract
    test eax, eax
    jnz .fail_cleanup
    cmp qword [rel snippet_a + NEBOC_SNIPPET_LINE_OFFSET], 2
    jne .fail_cleanup
    cmp qword [rel snippet_a + NEBOC_SNIPPET_BYTE_LENGTH_OFFSET], 5
    jne .fail_cleanup
    mov rsi, [rel snippet_a + NEBOC_SNIPPET_BYTES_OFFSET]
    lea rdi, [rel line_beta]
    mov ecx, line_beta_length
    repe cmpsb
    jne .fail_cleanup
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
    add rsp, 8
    ret

scenario_6:
    sub rsp, 8
    call setup
    test eax, eax
    jnz .fail
    lea rsi, [rel source_unicode]
    mov edx, source_unicode_length
    call build_map_a
    test eax, eax
    jnz .fail_cleanup

    lea rdi, [rel map_a]
    mov esi, 1
    mov edx, TEST_OWNER
    lea rcx, [rel location_a]
    call neboc_line_map_lookup
    test eax, eax
    jnz .fail_cleanup
    cmp qword [rel location_a + NEBOC_SOURCE_LOCATION_LINE_OFFSET], 1
    jne .fail_cleanup
    cmp qword [rel location_a + NEBOC_SOURCE_LOCATION_COLUMN_OFFSET], 2
    jne .fail_cleanup

    lea rdi, [rel map_a]
    mov esi, 3
    mov edx, TEST_OWNER
    lea rcx, [rel location_a]
    call neboc_line_map_lookup
    test eax, eax
    jnz .fail_cleanup
    cmp qword [rel location_a + NEBOC_SOURCE_LOCATION_COLUMN_OFFSET], 3
    jne .fail_cleanup

    lea rdi, [rel map_a]
    mov esi, 7
    mov edx, TEST_OWNER
    lea rcx, [rel location_a]
    call neboc_line_map_lookup
    test eax, eax
    jnz .fail_cleanup
    cmp qword [rel location_a + NEBOC_SOURCE_LOCATION_LINE_OFFSET], 2
    jne .fail_cleanup
    cmp qword [rel location_a + NEBOC_SOURCE_LOCATION_COLUMN_OFFSET], 1
    jne .fail_cleanup

    lea rdi, [rel map_a]
    mov esi, 2
    mov edx, TEST_OWNER
    lea rcx, [rel location_a]
    call neboc_line_map_lookup
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne .fail_cleanup

    lea rdi, [rel span_a]
    mov rsi, SOURCE_ID
    mov edx, 1
    mov ecx, 3
    mov r8d, source_unicode_length
    call neboc_source_span_init
    test eax, eax
    jnz .fail_cleanup
    lea rdi, [rel span_b]
    mov rsi, SOURCE_ID
    mov edx, 3
    mov ecx, 6
    mov r8d, source_unicode_length
    call neboc_source_span_init
    test eax, eax
    jnz .fail_cleanup
    lea rdi, [rel span_union]
    lea rsi, [rel span_a]
    lea rdx, [rel span_b]
    call neboc_source_span_union
    test eax, eax
    jnz .fail_cleanup
    cmp qword [rel span_union + NEBOC_SOURCE_SPAN_START_OFFSET], 1
    jne .fail_cleanup
    cmp qword [rel span_union + NEBOC_SOURCE_SPAN_END_OFFSET], 6
    jne .fail_cleanup
    lea rdi, [rel span_empty]
    mov rsi, SOURCE_ID
    mov edx, 7
    mov ecx, 7
    mov r8d, source_unicode_length
    call neboc_source_span_init
    test eax, eax
    jnz .fail_cleanup
    lea rdi, [rel span_empty]
    mov rsi, SOURCE_ID
    mov edx, source_unicode_length
    call neboc_source_span_validate
    test eax, eax
    jnz .fail_cleanup

    lea rdi, [rel map_a]
    lea rsi, [rel span_union]
    lea rdx, [rel logical_path]
    mov ecx, logical_path_length
    mov r8d, NEBOC_SNIPPET_DEFAULT_MAX_BYTES
    lea r9, [rel snippet_a]
    call neboc_snippet_extract
    test eax, eax
    jnz .fail_cleanup
    cmp qword [rel snippet_a + NEBOC_SNIPPET_COLUMN_START_OFFSET], 2
    jne .fail_cleanup
    cmp qword [rel snippet_a + NEBOC_SNIPPET_COLUMN_END_OFFSET], 4
    jne .fail_cleanup
    cmp qword [rel snippet_a + NEBOC_SNIPPET_BYTE_LENGTH_OFFSET], 6
    jne .fail_cleanup

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
    add rsp, 8
    ret

scenario_8:
    sub rsp, 8
    call setup
    test eax, eax
    jnz .fail
    lea rsi, [rel source_lf]
    mov edx, source_lf_length
    call build_map_a
    test eax, eax
    jnz .fail_cleanup
    lea rsi, [rel source_lf]
    mov edx, source_lf_length
    call build_map_b
    test eax, eax
    jnz .fail_cleanup
    mov rax, [rel map_a + NEBOC_LINE_MAP_STARTS_OFFSET]
    cmp rax, [rel map_b + NEBOC_LINE_MAP_STARTS_OFFSET]
    je .fail_cleanup
    mov rcx, [rel map_a + NEBOC_LINE_MAP_LINE_COUNT_OFFSET]
    cmp rcx, [rel map_b + NEBOC_LINE_MAP_LINE_COUNT_OFFSET]
    jne .fail_cleanup
    mov rsi, [rel map_a + NEBOC_LINE_MAP_STARTS_OFFSET]
    mov rdi, [rel map_b + NEBOC_LINE_MAP_STARTS_OFFSET]
    repe cmpsq
    jne .fail_cleanup

    lea rdi, [rel map_a]
    mov esi, 7
    mov edx, TEST_OWNER
    lea rcx, [rel location_a]
    call neboc_line_map_lookup
    test eax, eax
    jnz .fail_cleanup
    lea rdi, [rel map_b]
    mov esi, 7
    mov edx, TEST_OWNER
    lea rcx, [rel location_b]
    call neboc_line_map_lookup
    test eax, eax
    jnz .fail_cleanup
    lea rsi, [rel location_a]
    lea rdi, [rel location_b]
    mov ecx, NEBOC_SOURCE_LOCATION_QWORDS
    repe cmpsq
    jne .fail_cleanup

    lea rdi, [rel span_a]
    mov rsi, SOURCE_ID
    mov edx, 7
    mov ecx, 9
    mov r8d, source_lf_length
    call neboc_source_span_init
    test eax, eax
    jnz .fail_cleanup
    lea rdi, [rel map_a]
    lea rsi, [rel span_a]
    lea rdx, [rel logical_path]
    mov ecx, logical_path_length
    mov r8d, NEBOC_SNIPPET_DEFAULT_MAX_BYTES
    lea r9, [rel snippet_a]
    call neboc_snippet_extract
    test eax, eax
    jnz .fail_cleanup
    lea rdi, [rel map_b]
    lea rsi, [rel span_a]
    lea rdx, [rel logical_path]
    mov ecx, logical_path_length
    mov r8d, NEBOC_SNIPPET_DEFAULT_MAX_BYTES
    lea r9, [rel snippet_b]
    call neboc_snippet_extract
    test eax, eax
    jnz .fail_cleanup

    ; Compare deterministic semantic fields, excluding borrowed pointers.
    mov rax, [rel snippet_a + NEBOC_SNIPPET_SOURCE_ID_OFFSET]
    cmp rax, [rel snippet_b + NEBOC_SNIPPET_SOURCE_ID_OFFSET]
    jne .fail_cleanup
    mov rax, [rel snippet_a + NEBOC_SNIPPET_LOGICAL_PATH_LENGTH_OFFSET]
    cmp rax, [rel snippet_b + NEBOC_SNIPPET_LOGICAL_PATH_LENGTH_OFFSET]
    jne .fail_cleanup
    mov rax, [rel snippet_a + NEBOC_SNIPPET_BYTE_LENGTH_OFFSET]
    cmp rax, [rel snippet_b + NEBOC_SNIPPET_BYTE_LENGTH_OFFSET]
    jne .fail_cleanup
    mov rax, [rel snippet_a + NEBOC_SNIPPET_LINE_OFFSET]
    cmp rax, [rel snippet_b + NEBOC_SNIPPET_LINE_OFFSET]
    jne .fail_cleanup
    mov rax, [rel snippet_a + NEBOC_SNIPPET_COLUMN_START_OFFSET]
    cmp rax, [rel snippet_b + NEBOC_SNIPPET_COLUMN_START_OFFSET]
    jne .fail_cleanup
    mov rax, [rel snippet_a + NEBOC_SNIPPET_COLUMN_END_OFFSET]
    cmp rax, [rel snippet_b + NEBOC_SNIPPET_COLUMN_END_OFFSET]
    jne .fail_cleanup
    mov rax, [rel snippet_a + NEBOC_SNIPPET_FLAGS_OFFSET]
    cmp rax, [rel snippet_b + NEBOC_SNIPPET_FLAGS_OFFSET]
    jne .fail_cleanup

    cmp byte [rel logical_path], '/'
    je .fail_cleanup
    lea rsi, [rel logical_path]
    mov ecx, logical_path_length
.path_check:
    mov al, [rsi]
    cmp al, ':'
    je .fail_cleanup
    cmp al, 92
    je .fail_cleanup
    inc rsi
    loop .path_check

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
    add rsp, 8
    ret

section .rodata
source_lf: db 'alpha', 10, 'b', 0xc3, 0xa9, 'ta', 10, 'end'
source_lf_length equ $ - source_lf
source_crlf: db 'alpha', 13, 10, 'b', 0xc3, 0xa9, 'ta', 13, 10, 'end'
source_crlf_length equ $ - source_crlf
source_unicode: db 'A', 0xc3, 0xa9, 0xe4, 0xb8, 0xad, 10, 'Z'
source_unicode_length equ $ - source_unicode
line_beta: db 'b', 0xc3, 0xa9, 'ta'
line_beta_length equ $ - line_beta
logical_path: db 'src/main.no'
logical_path_length equ $ - logical_path

section .bss align=16
test_region: resb NEBOC_MEMORY_REGION_SIZE
test_arena: resb NEBOC_ARENA_SIZE
map_a: resb NEBOC_LINE_MAP_SIZE
map_b: resb NEBOC_LINE_MAP_SIZE
location_a: resb NEBOC_SOURCE_LOCATION_SIZE
location_b: resb NEBOC_SOURCE_LOCATION_SIZE
span_a: resb NEBOC_SOURCE_SPAN_SIZE
span_b: resb NEBOC_SOURCE_SPAN_SIZE
span_union: resb NEBOC_SOURCE_SPAN_SIZE
span_empty: resb NEBOC_SOURCE_SPAN_SIZE
snippet_a: resb NEBOC_SNIPPET_SIZE
snippet_b: resb NEBOC_SNIPPET_SIZE
test_state_end:

section .note.GNU-stack noalloc noexec nowrite progbits
