; MF008 native conformance suite for Slice, Buffer and TypedArray.

bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/support/memory/memory_region.inc"
%include "compiler/support/memory/arena.inc"
%include "compiler/support/slice/slice.inc"
%include "compiler/support/buffer/buffer.inc"
%include "compiler/support/array/typed_array.inc"
%include "tests/fake-host/fake_host.inc"

extern nebo_fake_host_services
extern nebo_fake_host_reset
extern neboc_memory_region_init
extern neboc_memory_region_destroy
extern neboc_arena_init
extern neboc_arena_destroy
extern neboc_buffer_init
extern neboc_buffer_reserve
extern neboc_buffer_append
extern neboc_buffer_finalize
extern neboc_slice_validate
extern neboc_slice_at
extern neboc_slice_init
extern neboc_typed_array_init
extern neboc_typed_array_push
extern neboc_typed_array_at
extern neboc_typed_array_finalize
extern neboc_host_process_exit

global _start

%define TEST_OWNER 0x4d463038
%define TOKEN_TYPE_ID 0x544f4b4e

section .text

_start:
    mov rax, [rsp]
    cmp rax, 2
    jb .usage
    mov rsi, [rsp + 16]
    mov al, [rsi]
    sub al, '0'
    cmp al, 4
    je .scenario_4
    cmp al, 5
    je .scenario_5
    jmp .usage
.scenario_4:
    call scenario_4
    jmp .finish
.scenario_5:
    call scenario_5
.finish:
    mov edi, eax
    jmp neboc_host_process_exit
.usage:
    mov edi, 99
    jmp neboc_host_process_exit

clear_test_state:
    lea rdi, [rel test_region]
    xor eax, eax
    mov ecx, (test_state_end - test_region) / 8
    cld
    rep stosq
    ret

setup_arena_4096:
    sub rsp, 8
    call nebo_fake_host_reset
    call clear_test_state
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

cleanup_arena:
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

scenario_4:
    push r12
    push r13
    push r14

    call setup_arena_4096
    test eax, eax
    jnz .fail_setup

    lea rdi, [rel test_buffer]
    lea rsi, [rel test_arena]
    mov edx, 1
    mov ecx, 1
    mov r8d, TEST_OWNER
    call neboc_buffer_init
    test eax, eax
    jnz .fail_buffer_init

    lea rdi, [rel test_buffer]
    lea rsi, [rel bytes_a]
    mov edx, bytes_a_length
    mov ecx, TEST_OWNER
    call neboc_buffer_append
    test eax, eax
    jnz .fail_append_a
    cmp qword [rel test_buffer + NEBOC_BUFFER_CAPACITY_OFFSET], 8
    jne .fail_capacity_8
    cmp qword [rel test_buffer + NEBOC_BUFFER_GROWTH_COUNT_OFFSET], 1
    jne .fail_growth_1

    lea rdi, [rel test_buffer]
    lea rsi, [rel bytes_b]
    mov edx, bytes_b_length
    mov ecx, TEST_OWNER
    call neboc_buffer_append
    test eax, eax
    jnz .fail_append_b
    cmp qword [rel test_buffer + NEBOC_BUFFER_CAPACITY_OFFSET], 16
    jne .fail_capacity_16
    cmp qword [rel test_buffer + NEBOC_BUFFER_GROWTH_COUNT_OFFSET], 2
    jne .fail_growth_2

    lea rdi, [rel test_buffer]
    lea rsi, [rel bytes_c]
    mov edx, bytes_c_length
    mov ecx, TEST_OWNER
    call neboc_buffer_append
    test eax, eax
    jnz .fail_append_c
    cmp qword [rel test_buffer + NEBOC_BUFFER_LENGTH_OFFSET], expected_bytes_length
    jne .fail_length
    cmp qword [rel test_buffer + NEBOC_BUFFER_CAPACITY_OFFSET], 32
    jne .fail_capacity_32
    cmp qword [rel test_buffer + NEBOC_BUFFER_GROWTH_COUNT_OFFSET], 3
    jne .fail_growth_3

    mov rsi, [rel test_buffer + NEBOC_BUFFER_DATA_OFFSET]
    lea rdi, [rel expected_bytes]
    mov ecx, expected_bytes_length
    cld
    repe cmpsb
    jne .fail_content

    lea rdi, [rel test_buffer]
    lea rsi, [rel test_slice]
    mov edx, TEST_OWNER
    call neboc_buffer_finalize
    test eax, eax
    jnz .fail_finalize

    lea rdi, [rel test_slice]
    mov esi, TEST_OWNER
    call neboc_slice_validate
    test eax, eax
    jnz .fail_slice_validate

    lea rdi, [rel test_slice]
    mov esi, expected_bytes_length - 1
    mov edx, TEST_OWNER
    lea rcx, [rel test_out]
    call neboc_slice_at
    test eax, eax
    jnz .fail_slice_at
    mov rax, [rel test_out]
    cmp byte [rax], 'q'
    jne .fail_slice_value

    lea rdi, [rel test_slice]
    mov esi, expected_bytes_length
    mov edx, TEST_OWNER
    lea rcx, [rel test_out]
    call neboc_slice_at
    cmp eax, NEBOC_STATUS_LIMIT_EXCEEDED
    jne .fail_slice_bound
    cmp qword [rel test_out], 0
    jne .fail_slice_out

    lea rdi, [rel test_buffer]
    lea rsi, [rel bytes_a]
    mov edx, 1
    mov ecx, TEST_OWNER
    call neboc_buffer_append
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne .fail_append_finalized
    cmp qword [rel test_buffer + NEBOC_BUFFER_LENGTH_OFFSET], expected_bytes_length
    jne .fail_finalized_mutation

    lea rdi, [rel test_array]
    lea rsi, [rel test_arena]
    mov edx, TOKEN_TYPE_ID
    mov ecx, 8
    mov r8d, 8
    mov r9d, TEST_OWNER
    call neboc_typed_array_init
    test eax, eax
    jnz .fail_array_init

    lea r12, [rel typed_values]
    mov r13d, typed_values_count
.push_loop:
    lea rdi, [rel test_array]
    mov esi, TOKEN_TYPE_ID
    mov rdx, r12
    mov ecx, TEST_OWNER
    call neboc_typed_array_push
    test eax, eax
    jnz .fail_array_push
    add r12, 8
    dec r13
    jnz .push_loop

    cmp qword [rel test_array + NEBOC_BUFFER_LENGTH_OFFSET], typed_values_count
    jne .fail_array_length
    cmp qword [rel test_array + NEBOC_BUFFER_CAPACITY_OFFSET], 16
    jne .fail_array_capacity
    cmp qword [rel test_array + NEBOC_BUFFER_GROWTH_COUNT_OFFSET], 2
    jne .fail_array_growth

    lea rdi, [rel test_array]
    mov esi, TOKEN_TYPE_ID
    mov edx, typed_values_count - 1
    mov ecx, TEST_OWNER
    lea r8, [rel test_out]
    call neboc_typed_array_at
    test eax, eax
    jnz .fail_array_at
    mov rax, [rel test_out]
    cmp qword [rax], 99
    jne .fail_array_value

    lea rdi, [rel test_array]
    mov esi, TOKEN_TYPE_ID
    lea rdx, [rel test_array_slice]
    mov ecx, TEST_OWNER
    call neboc_typed_array_finalize
    test eax, eax
    jnz .fail_array_finalize
    cmp qword [rel test_array_slice + NEBOC_SLICE_LENGTH_OFFSET], typed_values_count
    jne .fail_array_slice_length
    cmp qword [rel test_array_slice + NEBOC_SLICE_ELEMENT_SIZE_OFFSET], 8
    jne .fail_array_slice_size

    call cleanup_arena
    test eax, eax
    jnz .fail_cleanup
    xor eax, eax
    jmp .done

.fail_setup: mov eax, 41
    jmp .done
.fail_buffer_init: mov eax, 42
    jmp .done
.fail_append_a: mov eax, 43
    jmp .done
.fail_capacity_8: mov eax, 44
    jmp .done
.fail_growth_1: mov eax, 45
    jmp .done
.fail_append_b: mov eax, 46
    jmp .done
.fail_capacity_16: mov eax, 47
    jmp .done
.fail_growth_2: mov eax, 48
    jmp .done
.fail_append_c: mov eax, 49
    jmp .done
.fail_length: mov eax, 50
    jmp .done
.fail_capacity_32: mov eax, 51
    jmp .done
.fail_growth_3: mov eax, 52
    jmp .done
.fail_content: mov eax, 53
    jmp .done
.fail_finalize: mov eax, 54
    jmp .done
.fail_slice_validate: mov eax, 55
    jmp .done
.fail_slice_at: mov eax, 56
    jmp .done
.fail_slice_value: mov eax, 57
    jmp .done
.fail_slice_bound: mov eax, 58
    jmp .done
.fail_slice_out: mov eax, 59
    jmp .done
.fail_append_finalized: mov eax, 60
    jmp .done
.fail_finalized_mutation: mov eax, 61
    jmp .done
.fail_array_init: mov eax, 62
    jmp .done
.fail_array_push: mov eax, 63
    jmp .done
.fail_array_length: mov eax, 64
    jmp .done
.fail_array_capacity: mov eax, 65
    jmp .done
.fail_array_growth: mov eax, 66
    jmp .done
.fail_array_at: mov eax, 67
    jmp .done
.fail_array_value: mov eax, 68
    jmp .done
.fail_array_finalize: mov eax, 69
    jmp .done
.fail_array_slice_length: mov eax, 70
    jmp .done
.fail_array_slice_size: mov eax, 71
    jmp .done
.fail_cleanup: mov eax, 72
.done:
    pop r14
    pop r13
    pop r12
    ret

scenario_5:
    push r12
    push r13
    push r14

    call setup_arena_4096
    test eax, eax
    jnz .fail_setup

    lea rdi, [rel test_buffer]
    lea rsi, [rel test_arena]
    mov edx, 16
    mov ecx, 16
    mov r8d, TEST_OWNER
    call neboc_buffer_init
    test eax, eax
    jnz .fail_buffer_init

    mov rax, [rel test_arena + NEBOC_ARENA_CURRENT_OFFSET]
    mov [rel saved_current], rax

    lea rdi, [rel test_buffer]
    mov esi, (NEBOC_BUFFER_HARD_MAX_BYTES / 16) + 1
    mov edx, TEST_OWNER
    call neboc_buffer_reserve
    cmp eax, NEBOC_STATUS_LIMIT_EXCEEDED
    jne .fail_hard_limit
    cmp qword [rel test_buffer + NEBOC_BUFFER_CAPACITY_OFFSET], 0
    jne .fail_hard_state
    mov rax, [rel saved_current]
    cmp [rel test_arena + NEBOC_ARENA_CURRENT_OFFSET], rax
    jne .fail_hard_arena

    lea rdi, [rel test_buffer]
    lea rsi, [rel overflow_element]
    mov rdx, -1
    mov ecx, TEST_OWNER
    call neboc_buffer_append
    cmp eax, NEBOC_STATUS_LIMIT_EXCEEDED
    jne .fail_count_overflow
    cmp qword [rel test_buffer + NEBOC_BUFFER_LENGTH_OFFSET], 0
    jne .fail_count_state

    lea rdi, [rel test_buffer]
    mov esi, 512
    mov edx, TEST_OWNER
    call neboc_buffer_reserve
    cmp eax, NEBOC_STATUS_LIMIT_EXCEEDED
    jne .fail_arena_limit
    cmp qword [rel test_buffer + NEBOC_BUFFER_CAPACITY_OFFSET], 0
    jne .fail_arena_state

    lea rdi, [rel test_slice]
    mov rsi, [rel test_arena + NEBOC_ARENA_BEGIN_OFFSET]
    mov rdx, -1
    mov ecx, 16
    lea r8, [rel test_arena]
    mov r9d, TEST_OWNER
    call neboc_slice_init
    cmp eax, NEBOC_STATUS_LIMIT_EXCEEDED
    jne .fail_slice_overflow

    lea rdi, [rel test_array]
    lea rsi, [rel test_arena]
    mov edx, TOKEN_TYPE_ID
    xor ecx, ecx
    mov r8d, 8
    mov r9d, TEST_OWNER
    call neboc_typed_array_init
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne .fail_zero_element

    lea rdi, [rel test_array]
    lea rsi, [rel test_arena]
    mov edx, TOKEN_TYPE_ID
    mov ecx, 8
    mov r8d, 8
    mov r9d, TEST_OWNER
    call neboc_typed_array_init
    test eax, eax
    jnz .fail_array_init

    lea rdi, [rel test_array]
    mov esi, TOKEN_TYPE_ID + 1
    lea rdx, [rel overflow_element]
    mov ecx, TEST_OWNER
    call neboc_typed_array_push
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne .fail_type_mismatch
    cmp qword [rel test_array + NEBOC_BUFFER_LENGTH_OFFSET], 0
    jne .fail_type_state

    lea rdi, [rel test_buffer]
    lea rsi, [rel test_slice]
    mov edx, TEST_OWNER
    call neboc_buffer_finalize
    test eax, eax
    jnz .fail_empty_finalize

    lea rdi, [rel test_slice]
    xor esi, esi
    mov edx, TEST_OWNER
    lea rcx, [rel test_out]
    call neboc_slice_at
    cmp eax, NEBOC_STATUS_LIMIT_EXCEEDED
    jne .fail_empty_bounds
    cmp qword [rel test_out], 0
    jne .fail_empty_out

    lea rdi, [rel test_buffer]
    mov esi, 1
    mov edx, TEST_OWNER
    call neboc_buffer_reserve
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne .fail_finalized_reserve

    call cleanup_arena
    test eax, eax
    jnz .fail_cleanup
    xor eax, eax
    jmp .done

.fail_setup: mov eax, 81
    jmp .done
.fail_buffer_init: mov eax, 82
    jmp .done
.fail_hard_limit: mov eax, 83
    jmp .done
.fail_hard_state: mov eax, 84
    jmp .done
.fail_hard_arena: mov eax, 85
    jmp .done
.fail_count_overflow: mov eax, 86
    jmp .done
.fail_count_state: mov eax, 87
    jmp .done
.fail_arena_limit: mov eax, 88
    jmp .done
.fail_arena_state: mov eax, 89
    jmp .done
.fail_slice_overflow: mov eax, 90
    jmp .done
.fail_zero_element: mov eax, 91
    jmp .done
.fail_array_init: mov eax, 92
    jmp .done
.fail_type_mismatch: mov eax, 93
    jmp .done
.fail_type_state: mov eax, 94
    jmp .done
.fail_empty_finalize: mov eax, 95
    jmp .done
.fail_empty_bounds: mov eax, 96
    jmp .done
.fail_empty_out: mov eax, 97
    jmp .done
.fail_finalized_reserve: mov eax, 98
    jmp .done
.fail_cleanup: mov eax, 99
.done:
    pop r14
    pop r13
    pop r12
    ret

section .rodata
bytes_a: db 'abc'
bytes_a_length equ $ - bytes_a
bytes_b: db 'defghijklm'
bytes_b_length equ $ - bytes_b
bytes_c: db 'nopq'
bytes_c_length equ $ - bytes_c
expected_bytes: db 'abcdefghijklmnopq'
expected_bytes_length equ $ - expected_bytes
typed_values: dq 11, 22, 33, 44, 55, 66, 77, 88, 99
typed_values_count equ ($ - typed_values) / 8
overflow_element: dq 0x1122334455667788, 0x99aabbccddeeff00

section .bss align=16
test_region: resb NEBOC_MEMORY_REGION_SIZE
test_arena: resb NEBOC_ARENA_SIZE
test_buffer: resb NEBOC_BUFFER_SIZE
test_slice: resb NEBOC_SLICE_SIZE
test_array: resb NEBOC_TYPED_ARRAY_SIZE
test_array_slice: resb NEBOC_SLICE_SIZE
test_out: resq 1
saved_current: resq 1
test_state_end:

section .note.GNU-stack noalloc noexec nowrite progbits
