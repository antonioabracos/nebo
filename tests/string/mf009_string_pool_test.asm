; MF009 native conformance suite for StringPool, hashing and typed IDs.

bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/support/memory/memory_region.inc"
%include "compiler/support/memory/arena.inc"
%include "compiler/support/hash/fnv1a.inc"
%include "compiler/support/id/typed_id.inc"
%include "compiler/support/string/string_pool.inc"
%include "tests/fake-host/fake_host.inc"

extern nebo_fake_host_services
extern nebo_fake_host_reset
extern neboc_memory_region_init
extern neboc_memory_region_destroy
extern neboc_arena_init
extern neboc_arena_destroy
extern neboc_hash_fnv1a32
extern neboc_typed_id_validate
extern neboc_string_pool_init
extern neboc_string_pool_validate
extern neboc_string_pool_intern
extern neboc_string_pool_get_view
extern neboc_host_process_exit

global _start

%define TEST_OWNER 0x4d463039
%define IDENTIFIER_TAG_VALUE 0x0200000000000000
%define STRING_TAG_VALUE 0x0100000000000000
%define EXPECTED_COLLISION_HASH 0x00000000ad182d96

section .text

_start:
    mov rax, [rsp]
    cmp rax, 2
    jb .usage
    mov rsi, [rsp + 16]
    mov al, [rsi]
    sub al, '0'
    cmp al, 7
    jne .usage
    call scenario_7
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

scenario_7:
    push rbx
    push r12
    push r13
    push r14
    push r15

    call setup_arena_4096
    test eax, eax
    jnz .fail_setup

    lea rdi, [rel pool_a]
    lea rsi, [rel test_arena]
    mov edx, 8
    mov ecx, NEBOC_ID_KIND_IDENTIFIER
    mov r8d, TEST_OWNER
    call neboc_string_pool_init
    test eax, eax
    jnz .fail_pool_a

    lea rdi, [rel pool_b]
    lea rsi, [rel test_arena]
    mov edx, 8
    mov ecx, NEBOC_ID_KIND_IDENTIFIER
    mov r8d, TEST_OWNER
    call neboc_string_pool_init
    test eax, eax
    jnz .fail_pool_b

    lea rdi, [rel pool_string]
    lea rsi, [rel test_arena]
    mov edx, 4
    mov ecx, NEBOC_ID_KIND_STRING
    mov r8d, TEST_OWNER
    call neboc_string_pool_init
    test eax, eax
    jnz .fail_pool_string

    mov rax, [rel pool_a + NEBOC_STRING_POOL_ENTRIES_OFFSET]
    cmp rax, [rel pool_b + NEBOC_STRING_POOL_ENTRIES_OFFSET]
    je .fail_distinct_storage

    lea r12, [rel identifier_inputs]
    xor r13d, r13d
.intern_loop:
    cmp r13, identifier_input_count
    jae .intern_done

    mov rsi, [r12]
    mov rdx, [r12 + 8]
    lea rdi, [rel pool_a]
    mov ecx, TEST_OWNER
    lea r8, [rel out_id_a]
    call neboc_string_pool_intern
    test eax, eax
    jnz .fail_intern_a

    mov rsi, [r12]
    mov rdx, [r12 + 8]
    lea rdi, [rel pool_b]
    mov ecx, TEST_OWNER
    lea r8, [rel out_id_b]
    call neboc_string_pool_intern
    test eax, eax
    jnz .fail_intern_b

    mov rax, [rel out_id_a]
    cmp rax, [rel out_id_b]
    jne .fail_deterministic_id
    lea rdx, [rel ids_a]
    mov [rdx + r13 * 8], rax
    lea rdx, [rel ids_b]
    mov [rdx + r13 * 8], rax

    mov r14, IDENTIFIER_TAG_VALUE
    lea r15, [r13 + 1]
    or r14, r15
    cmp rax, r14
    jne .fail_ordinal_policy

    add r12, 16
    inc r13
    jmp .intern_loop
.intern_done:
    cmp qword [rel pool_a + NEBOC_STRING_POOL_COUNT_OFFSET], identifier_input_count
    jne .fail_count_a
    cmp qword [rel pool_b + NEBOC_STRING_POOL_COUNT_OFFSET], identifier_input_count
    jne .fail_count_b
    cmp qword [rel pool_a + NEBOC_STRING_POOL_COLLISION_COUNT_OFFSET], 1
    jne .fail_collision_count_a
    cmp qword [rel pool_b + NEBOC_STRING_POOL_COLLISION_COUNT_OFFSET], 1
    jne .fail_collision_count_b

    mov rax, [rel ids_a + 8]
    cmp rax, [rel ids_a + 16]
    je .fail_collision_ids

    lea rdi, [rel collision_a]
    mov esi, collision_a_length
    lea rdx, [rel hash_a]
    call neboc_hash_fnv1a32
    test eax, eax
    jnz .fail_hash_a
    lea rdi, [rel collision_b]
    mov esi, collision_b_length
    lea rdx, [rel hash_b]
    call neboc_hash_fnv1a32
    test eax, eax
    jnz .fail_hash_b
    mov rax, [rel hash_a]
    cmp eax, EXPECTED_COLLISION_HASH
    jne .fail_hash_expected
    cmp rax, [rel hash_b]
    jne .fail_hash_collision

    lea rdi, [rel pool_a]
    mov rsi, [rel ids_a + 8]
    mov edx, TEST_OWNER
    lea rcx, [rel view_a]
    call neboc_string_pool_get_view
    test eax, eax
    jnz .fail_view_a
    lea rdi, [rel pool_a]
    mov rsi, [rel ids_a + 16]
    mov edx, TEST_OWNER
    lea rcx, [rel view_b]
    call neboc_string_pool_get_view
    test eax, eax
    jnz .fail_view_b
    cmp dword [rel view_a + NEBOC_STRING_VIEW_HASH_OFFSET], EXPECTED_COLLISION_HASH
    jne .fail_view_hash_a
    cmp dword [rel view_b + NEBOC_STRING_VIEW_HASH_OFFSET], EXPECTED_COLLISION_HASH
    jne .fail_view_hash_b
    mov rax, [rel view_a + NEBOC_STRING_VIEW_BYTES_OFFSET]
    cmp rax, [rel view_b + NEBOC_STRING_VIEW_BYTES_OFFSET]
    je .fail_collision_storage
    cmp byte [rax], 'c'
    jne .fail_collision_content_a
    mov rax, [rel view_b + NEBOC_STRING_VIEW_BYTES_OFFSET]
    cmp byte [rax], 'y'
    jne .fail_collision_content_b

    lea rdi, [rel pool_a]
    lea rsi, [rel alpha]
    mov edx, alpha_length
    mov ecx, TEST_OWNER
    lea r8, [rel duplicate_id]
    call neboc_string_pool_intern
    test eax, eax
    jnz .fail_duplicate
    mov rax, [rel duplicate_id]
    cmp rax, [rel ids_a]
    jne .fail_duplicate_id
    cmp qword [rel pool_a + NEBOC_STRING_POOL_COUNT_OFFSET], identifier_input_count
    jne .fail_duplicate_count

    lea rdi, [rel pool_string]
    lea rsi, [rel alpha]
    mov edx, alpha_length
    mov ecx, TEST_OWNER
    lea r8, [rel string_id]
    call neboc_string_pool_intern
    test eax, eax
    jnz .fail_string_intern
    mov rdx, STRING_TAG_VALUE | 1
    cmp [rel string_id], rdx
    jne .fail_string_kind
    mov rax, [rel string_id]
    cmp rax, [rel ids_a]
    je .fail_typed_distinction

    mov rdi, [rel ids_a + 24]
    mov esi, NEBOC_ID_KIND_IDENTIFIER
    lea rdx, [rel ordinal_out]
    call neboc_typed_id_validate
    test eax, eax
    jnz .fail_typed_validate
    cmp qword [rel ordinal_out], 4
    jne .fail_typed_ordinal

    lea rdi, [rel pool_a]
    lea rsi, [rel unicode_identifier]
    mov edx, unicode_identifier_length
    mov ecx, TEST_OWNER
    lea r8, [rel invalid_id]
    call neboc_string_pool_intern
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne .fail_unicode_status
    cmp qword [rel invalid_id], NEBOC_IDENTIFIER_ID_INVALID
    jne .fail_unicode_id
    cmp qword [rel pool_a + NEBOC_STRING_POOL_COUNT_OFFSET], identifier_input_count
    jne .fail_unicode_count

    lea rdi, [rel pool_a]
    mov rsi, [rel view_a + NEBOC_STRING_VIEW_BYTES_OFFSET]
    mov edx, TEST_OWNER
    lea rcx, [rel invalid_view]
    call neboc_string_pool_get_view
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne .fail_pointer_id_status
    cmp qword [rel invalid_view + NEBOC_STRING_VIEW_ID_OFFSET], NEBOC_ID_INVALID
    jne .fail_pointer_id_view

    lea rdi, [rel pool_a]
    mov esi, TEST_OWNER
    call neboc_string_pool_validate
    test eax, eax
    jnz .fail_validate_a
    lea rdi, [rel pool_b]
    mov esi, TEST_OWNER
    call neboc_string_pool_validate
    test eax, eax
    jnz .fail_validate_b
    lea rdi, [rel pool_string]
    mov esi, TEST_OWNER
    call neboc_string_pool_validate
    test eax, eax
    jnz .fail_validate_string

    call cleanup_arena
    test eax, eax
    jnz .fail_cleanup
    xor eax, eax
    jmp .done

.fail_setup: mov eax, 1
    jmp .done
.fail_pool_a: mov eax, 2
    jmp .done
.fail_pool_b: mov eax, 3
    jmp .done
.fail_pool_string: mov eax, 4
    jmp .done
.fail_distinct_storage: mov eax, 5
    jmp .done
.fail_intern_a: mov eax, 6
    jmp .done
.fail_intern_b: mov eax, 7
    jmp .done
.fail_deterministic_id: mov eax, 8
    jmp .done
.fail_ordinal_policy: mov eax, 9
    jmp .done
.fail_count_a: mov eax, 10
    jmp .done
.fail_count_b: mov eax, 11
    jmp .done
.fail_collision_count_a: mov eax, 12
    jmp .done
.fail_collision_count_b: mov eax, 13
    jmp .done
.fail_collision_ids: mov eax, 14
    jmp .done
.fail_hash_a: mov eax, 15
    jmp .done
.fail_hash_b: mov eax, 16
    jmp .done
.fail_hash_expected: mov eax, 17
    jmp .done
.fail_hash_collision: mov eax, 18
    jmp .done
.fail_view_a: mov eax, 19
    jmp .done
.fail_view_b: mov eax, 20
    jmp .done
.fail_view_hash_a: mov eax, 21
    jmp .done
.fail_view_hash_b: mov eax, 22
    jmp .done
.fail_collision_storage: mov eax, 23
    jmp .done
.fail_collision_content_a: mov eax, 24
    jmp .done
.fail_collision_content_b: mov eax, 25
    jmp .done
.fail_duplicate: mov eax, 26
    jmp .done
.fail_duplicate_id: mov eax, 27
    jmp .done
.fail_duplicate_count: mov eax, 28
    jmp .done
.fail_string_intern: mov eax, 29
    jmp .done
.fail_string_kind: mov eax, 30
    jmp .done
.fail_typed_distinction: mov eax, 31
    jmp .done
.fail_typed_validate: mov eax, 32
    jmp .done
.fail_typed_ordinal: mov eax, 33
    jmp .done
.fail_unicode_status: mov eax, 34
    jmp .done
.fail_unicode_id: mov eax, 35
    jmp .done
.fail_unicode_count: mov eax, 36
    jmp .done
.fail_pointer_id_status: mov eax, 37
    jmp .done
.fail_pointer_id_view: mov eax, 38
    jmp .done
.fail_validate_a: mov eax, 39
    jmp .done
.fail_validate_b: mov eax, 40
    jmp .done
.fail_validate_string: mov eax, 41
    jmp .done
.fail_cleanup: mov eax, 42
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

section .rodata
alpha: db 'alpha'
alpha_length equ $ - alpha
collision_a: db 'ctgfhnxe'
collision_a_length equ $ - collision_a
collision_b: db 'ybzaqr9e'
collision_b_length equ $ - collision_b
omega: db 'omega'
omega_length equ $ - omega
unicode_identifier: db 0xc3, 0xa9
unicode_identifier_length equ $ - unicode_identifier

identifier_inputs:
    dq alpha, alpha_length
    dq collision_a, collision_a_length
    dq collision_b, collision_b_length
    dq omega, omega_length
identifier_input_count equ ($ - identifier_inputs) / 16

section .bss align=16
test_region: resb NEBOC_MEMORY_REGION_SIZE
test_arena: resb NEBOC_ARENA_SIZE
pool_a: resb NEBOC_STRING_POOL_SIZE
pool_b: resb NEBOC_STRING_POOL_SIZE
pool_string: resb NEBOC_STRING_POOL_SIZE
ids_a: resq identifier_input_count
ids_b: resq identifier_input_count
out_id_a: resq 1
out_id_b: resq 1
duplicate_id: resq 1
string_id: resq 1
invalid_id: resq 1
ordinal_out: resq 1
hash_a: resq 1
hash_b: resq 1
view_a: resb NEBOC_STRING_VIEW_SIZE
view_b: resb NEBOC_STRING_VIEW_SIZE
invalid_view: resb NEBOC_STRING_VIEW_SIZE
test_state_end:

section .note.GNU-stack noalloc noexec nowrite progbits
