; MF007 native conformance suite for MemoryRegion, Arena and MemorySpan.

bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/support/memory/memory_region.inc"
%include "compiler/support/memory/arena.inc"
%include "tests/fake-host/fake_host.inc"

extern nebo_fake_host_services
extern nebo_fake_host_context
extern nebo_fake_host_reset
extern neboc_memory_region_init
extern neboc_memory_region_destroy
extern neboc_arena_init
extern neboc_arena_allocate
extern neboc_arena_allocate_zeroed
extern neboc_arena_align
extern neboc_arena_mark
extern neboc_arena_rewind
extern neboc_arena_reset
extern neboc_arena_destroy
extern neboc_memory_span_at
extern neboc_host_process_exit

global _start

%define TEST_OWNER 0x4d463037

section .text

_start:
    mov rax, [rsp]
    cmp rax, 2
    jb .usage
    mov rsi, [rsp + 16]
    mov al, [rsi]
    sub al, '0'
    cmp al, 1
    je .scenario_1
    cmp al, 2
    je .scenario_2
    cmp al, 3
    je .scenario_3
    cmp al, 6
    je .scenario_6
    cmp al, 8
    je .scenario_8
    jmp .usage
.scenario_1:
    call scenario_1
    jmp .finish
.scenario_2:
    call scenario_2
    jmp .finish
.scenario_3:
    call scenario_3
    jmp .finish
.scenario_6:
    call scenario_6
    jmp .finish
.scenario_8:
    call scenario_8
.finish:
    mov edi, eax
    jmp neboc_host_process_exit
.usage:
    mov edi, 99
    jmp neboc_host_process_exit

clear_test_state:
    lea rdi, [rel test_region]
    xor eax, eax
    mov ecx, (NEBOC_MEMORY_REGION_SIZE + NEBOC_ARENA_SIZE + NEBOC_ARENA_MARK_SIZE + NEBOC_MEMORY_SPAN_SIZE + 32) / 8
    cld
    rep stosq
    ret

setup_arena_256:
    sub rsp, 8
    call nebo_fake_host_reset
    call clear_test_state
    lea rdi, [rel test_region]
    lea rsi, [rel nebo_fake_host_services]
    mov edx, 256
    mov ecx, 256
    mov r8d, TEST_OWNER
    call neboc_memory_region_init
    test eax, eax
    jne .setup_done
    lea rdi, [rel test_arena]
    lea rsi, [rel test_region]
    mov edx, 256
    mov ecx, TEST_OWNER
    call neboc_arena_init
.setup_done:
    add rsp, 8
    ret

cleanup_arena:
    sub rsp, 8
    lea rdi, [rel test_arena]
    mov esi, TEST_OWNER
    call neboc_arena_destroy
    test eax, eax
    jne .cleanup_done
    lea rdi, [rel test_region]
    mov esi, TEST_OWNER
    call neboc_memory_region_destroy
.cleanup_done:
    add rsp, 8
    ret

scenario_1:
    sub rsp, 8
    call setup_arena_256
    test eax, eax
    jnz .fail_setup

    lea rdi, [rel test_arena]
    mov esi, 17
    mov edx, 64
    mov ecx, TEST_OWNER
    lea r8, [rel test_out]
    call neboc_arena_allocate
    test eax, eax
    jnz .fail_allocate
    mov rax, [rel test_out]
    test rax, 63
    jnz .fail_alignment
    cmp rax, [rel test_region + NEBOC_MEMORY_REGION_BASE_OFFSET]
    jb .fail_range
    mov rdx, rax
    add rdx, 17
    cmp rdx, [rel test_arena + NEBOC_ARENA_CURRENT_OFFSET]
    jne .fail_current
    cmp qword [rel test_arena + NEBOC_ARENA_ALLOCATION_COUNT_OFFSET], 1
    jne .fail_accounting

    lea rdi, [rel test_arena]
    mov esi, 32
    mov edx, TEST_OWNER
    lea rcx, [rel test_out_2]
    call neboc_arena_align
    test eax, eax
    jnz .fail_align_operation
    mov rax, [rel test_out_2]
    test rax, 31
    jnz .fail_align_pointer
    cmp [rel test_arena + NEBOC_ARENA_CURRENT_OFFSET], rax
    jne .fail_align_current

    lea rdi, [rel test_arena]
    mov esi, 16
    mov edx, 16
    mov ecx, TEST_OWNER
    lea r8, [rel test_out_2]
    call neboc_arena_allocate_zeroed
    test eax, eax
    jnz .fail_zeroed
    mov rdi, [rel test_out_2]
    mov ecx, 16
.check_zero:
    cmp byte [rdi], 0
    jne .fail_zero_content
    inc rdi
    loop .check_zero

    call cleanup_arena
    test eax, eax
    jnz .fail_cleanup
    xor eax, eax
    jmp .done
.fail_setup: mov eax, 11
    jmp .done
.fail_allocate: mov eax, 12
    jmp .done
.fail_alignment: mov eax, 13
    jmp .done
.fail_range: mov eax, 14
    jmp .done
.fail_current: mov eax, 15
    jmp .done
.fail_accounting: mov eax, 16
    jmp .done
.fail_align_operation: mov eax, 17
    jmp .done
.fail_align_pointer: mov eax, 18
    jmp .done
.fail_align_current: mov eax, 19
    jmp .done
.fail_zeroed: mov eax, 20
    jmp .done
.fail_zero_content: mov eax, 21
    jmp .done
.fail_cleanup: mov eax, 22
.done:
    add rsp, 8
    ret

scenario_2:
    sub rsp, 8
    call nebo_fake_host_reset
    call clear_test_state
    mov qword [rel nebo_fake_host_context + NEBOC_FAKE_FAIL_MASK_OFFSET], NEBOC_FAKE_FAIL_MEMORY_RESERVE
    lea rdi, [rel test_region]
    lea rsi, [rel nebo_fake_host_services]
    mov edx, 256
    mov ecx, 256
    mov r8d, TEST_OWNER
    call neboc_memory_region_init
    cmp eax, NEBOC_STATUS_OUT_OF_MEMORY
    jne .fail_oom
    cmp qword [rel test_region + NEBOC_MEMORY_REGION_ACTIVE_OFFSET], 0
    jne .fail_oom_state

    call setup_arena_256
    test eax, eax
    jnz .fail_setup
    lea rdi, [rel test_arena]
    mov esi, 240
    mov edx, 1
    mov ecx, TEST_OWNER
    lea r8, [rel test_out]
    call neboc_arena_allocate
    test eax, eax
    jnz .fail_first
    mov rax, [rel test_arena + NEBOC_ARENA_CURRENT_OFFSET]
    mov [rel saved_current], rax

    lea rdi, [rel test_arena]
    mov esi, 32
    mov edx, 16
    mov ecx, TEST_OWNER
    lea r8, [rel test_out_2]
    call neboc_arena_allocate
    cmp eax, NEBOC_STATUS_LIMIT_EXCEEDED
    jne .fail_limit
    cmp qword [rel test_out_2], 0
    jne .fail_out_pointer
    mov rax, [rel saved_current]
    cmp [rel test_arena + NEBOC_ARENA_CURRENT_OFFSET], rax
    jne .fail_corruption

    lea rdi, [rel test_arena]
    mov rsi, -1
    mov edx, 16
    mov ecx, TEST_OWNER
    lea r8, [rel test_out_2]
    call neboc_arena_allocate
    cmp eax, NEBOC_STATUS_LIMIT_EXCEEDED
    jne .fail_overflow

    call cleanup_arena
    test eax, eax
    jnz .fail_cleanup
    xor eax, eax
    jmp .done
.fail_oom: mov eax, 21
    jmp .done
.fail_oom_state: mov eax, 22
    jmp .done
.fail_setup: mov eax, 23
    jmp .done
.fail_first: mov eax, 24
    jmp .done
.fail_limit: mov eax, 25
    jmp .done
.fail_out_pointer: mov eax, 26
    jmp .done
.fail_corruption: mov eax, 27
    jmp .done
.fail_overflow: mov eax, 28
    jmp .done
.fail_cleanup: mov eax, 29
.done:
    add rsp, 8
    ret

scenario_3:
    sub rsp, 8
    call setup_arena_256
    test eax, eax
    jnz .fail_setup

    lea rdi, [rel test_arena]
    mov esi, 32
    mov edx, 8
    mov ecx, TEST_OWNER
    lea r8, [rel test_out]
    call neboc_arena_allocate
    test eax, eax
    jnz .fail_first

    lea rdi, [rel test_arena]
    mov esi, TEST_OWNER
    lea rdx, [rel test_mark]
    call neboc_arena_mark
    test eax, eax
    jnz .fail_mark

    lea rdi, [rel test_arena]
    mov esi, 24
    mov edx, 8
    mov ecx, TEST_OWNER
    lea r8, [rel test_out_2]
    call neboc_arena_allocate
    test eax, eax
    jnz .fail_second
    mov rax, [rel test_out_2]
    mov [rel saved_pointer], rax

    lea rdi, [rel test_arena]
    mov esi, TEST_OWNER
    lea rdx, [rel test_mark]
    call neboc_arena_rewind
    test eax, eax
    jnz .fail_rewind
    mov rax, [rel test_mark + NEBOC_ARENA_MARK_OFFSET_OFFSET]
    cmp [rel test_arena + NEBOC_ARENA_ALLOCATED_BYTES_OFFSET], rax
    jne .fail_state

    lea rdi, [rel test_arena]
    mov esi, 24
    mov edx, 8
    mov ecx, TEST_OWNER
    lea r8, [rel test_out]
    call neboc_arena_allocate
    test eax, eax
    jnz .fail_reallocate
    mov rax, [rel saved_pointer]
    cmp [rel test_out], rax
    jne .fail_pointer
    cmp qword [rel test_arena + NEBOC_ARENA_REWIND_COUNT_OFFSET], 1
    jne .fail_accounting

    call cleanup_arena
    test eax, eax
    jnz .fail_cleanup
    xor eax, eax
    jmp .done
.fail_setup: mov eax, 31
    jmp .done
.fail_first: mov eax, 32
    jmp .done
.fail_mark: mov eax, 33
    jmp .done
.fail_second: mov eax, 34
    jmp .done
.fail_rewind: mov eax, 35
    jmp .done
.fail_state: mov eax, 36
    jmp .done
.fail_reallocate: mov eax, 37
    jmp .done
.fail_pointer: mov eax, 38
    jmp .done
.fail_accounting: mov eax, 39
    jmp .done
.fail_cleanup: mov eax, 40
.done:
    add rsp, 8
    ret

scenario_6:
    sub rsp, 8
    call setup_arena_256
    test eax, eax
    jnz .fail_setup

    lea rdi, [rel test_arena]
    mov esi, 16
    mov edx, 8
    mov ecx, TEST_OWNER
    lea r8, [rel test_out]
    call neboc_arena_allocate
    test eax, eax
    jnz .fail_allocate

    mov rax, [rel test_out]
    mov [rel test_span + NEBOC_MEMORY_SPAN_POINTER_OFFSET], rax
    mov qword [rel test_span + NEBOC_MEMORY_SPAN_LENGTH_OFFSET], 16
    mov rax, [rel test_arena + NEBOC_ARENA_GENERATION_OFFSET]
    mov [rel test_span + NEBOC_MEMORY_SPAN_GENERATION_OFFSET], rax
    lea rax, [rel test_arena]
    mov [rel test_span + NEBOC_MEMORY_SPAN_ARENA_OFFSET], rax

    lea rdi, [rel test_span]
    mov esi, 15
    mov edx, 1
    lea rcx, [rel test_out_2]
    call neboc_memory_span_at
    test eax, eax
    jnz .fail_valid
    mov rax, [rel test_out]
    inc rax
    add rax, 14
    cmp [rel test_out_2], rax
    jne .fail_valid_pointer

    lea rdi, [rel test_span]
    mov esi, 16
    mov edx, 1
    lea rcx, [rel test_out_2]
    call neboc_memory_span_at
    cmp eax, NEBOC_STATUS_LIMIT_EXCEEDED
    jne .fail_edge
    cmp qword [rel test_out_2], 0
    jne .fail_edge_pointer

    lea rdi, [rel test_span]
    mov esi, 8
    mov edx, 9
    lea rcx, [rel test_out_2]
    call neboc_memory_span_at
    cmp eax, NEBOC_STATUS_LIMIT_EXCEEDED
    jne .fail_width

    lea rdi, [rel test_span]
    mov esi, 16
    xor edx, edx
    lea rcx, [rel test_out_2]
    call neboc_memory_span_at
    test eax, eax
    jnz .fail_zero_width

    call cleanup_arena
    test eax, eax
    jnz .fail_cleanup
    xor eax, eax
    jmp .done
.fail_setup: mov eax, 61
    jmp .done
.fail_allocate: mov eax, 62
    jmp .done
.fail_valid: mov eax, 63
    jmp .done
.fail_valid_pointer: mov eax, 64
    jmp .done
.fail_edge: mov eax, 65
    jmp .done
.fail_edge_pointer: mov eax, 66
    jmp .done
.fail_width: mov eax, 67
    jmp .done
.fail_zero_width: mov eax, 68
    jmp .done
.fail_cleanup: mov eax, 69
.done:
    add rsp, 8
    ret

scenario_8:
    sub rsp, 8
    call setup_arena_256
    test eax, eax
    jnz .fail_setup

    lea rdi, [rel test_arena]
    mov esi, 16
    mov edx, 8
    mov ecx, TEST_OWNER
    lea r8, [rel test_out]
    call neboc_arena_allocate
    test eax, eax
    jnz .fail_allocate

    lea rdi, [rel test_arena]
    mov esi, TEST_OWNER
    lea rdx, [rel test_mark]
    call neboc_arena_mark
    test eax, eax
    jnz .fail_mark

    mov rax, [rel test_out]
    mov [rel test_span + NEBOC_MEMORY_SPAN_POINTER_OFFSET], rax
    mov qword [rel test_span + NEBOC_MEMORY_SPAN_LENGTH_OFFSET], 16
    mov rax, [rel test_arena + NEBOC_ARENA_GENERATION_OFFSET]
    mov [rel test_span + NEBOC_MEMORY_SPAN_GENERATION_OFFSET], rax
    lea rax, [rel test_arena]
    mov [rel test_span + NEBOC_MEMORY_SPAN_ARENA_OFFSET], rax

    lea rdi, [rel test_arena]
    mov esi, TEST_OWNER
    call neboc_arena_reset
    test eax, eax
    jnz .fail_reset

    lea rdi, [rel test_arena]
    mov esi, TEST_OWNER
    lea rdx, [rel test_mark]
    call neboc_arena_rewind
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne .fail_stale_mark

    lea rdi, [rel test_span]
    xor esi, esi
    mov edx, 1
    lea rcx, [rel test_out_2]
    call neboc_memory_span_at
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne .fail_stale_span

    lea rdi, [rel test_arena]
    mov esi, 8
    mov edx, 8
    mov ecx, TEST_OWNER + 1
    lea r8, [rel test_out_2]
    call neboc_arena_allocate
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne .fail_owner

    call cleanup_arena
    test eax, eax
    jnz .fail_cleanup
    xor eax, eax
    jmp .done
.fail_setup: mov eax, 81
    jmp .done
.fail_allocate: mov eax, 82
    jmp .done
.fail_mark: mov eax, 83
    jmp .done
.fail_reset: mov eax, 84
    jmp .done
.fail_stale_mark: mov eax, 85
    jmp .done
.fail_stale_span: mov eax, 86
    jmp .done
.fail_owner: mov eax, 87
    jmp .done
.fail_cleanup: mov eax, 88
.done:
    add rsp, 8
    ret

section .bss align=16
test_region: resb NEBOC_MEMORY_REGION_SIZE
test_arena: resb NEBOC_ARENA_SIZE
test_mark: resb NEBOC_ARENA_MARK_SIZE
test_span: resb NEBOC_MEMORY_SPAN_SIZE
test_out: resq 1
test_out_2: resq 1
saved_current: resq 1
saved_pointer: resq 1

section .note.GNU-stack noalloc noexec nowrite progbits
