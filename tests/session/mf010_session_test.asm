; MF010 deterministic CompilationSession contract suite.

bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/support/limits/compilation_limits.inc"
%include "compiler/support/statistics/session_statistics.inc"
%include "compiler/support/memory/memory_region.inc"
%include "compiler/support/memory/arena.inc"
%include "compiler/support/string/string_pool.inc"
%include "compiler/session/compilation_session.inc"
%include "tests/fake-host/fake_host.inc"

%define TEST_OWNER 0x4e45424f53455353

%macro TEST_RETURN 1
    mov eax, %1
    add rsp, 8
    ret
%endmacro

extern nebo_fake_host_services
extern nebo_fake_host_context
extern nebo_fake_host_reset
extern neboc_compilation_session_init_with_memory
extern neboc_compilation_session_validate
extern neboc_compilation_session_advance
extern neboc_compilation_session_set_limit_checked
extern neboc_compilation_session_check_limit
extern neboc_compilation_session_record_diagnostic
extern neboc_compilation_session_cleanup
extern neboc_compilation_session_fail
extern neboc_compilation_session_destroy
extern neboc_host_process_exit

global _start

section .bss align=16
session_a: resb NEBOC_COMPILATION_SESSION_SIZE
session_b: resb NEBOC_COMPILATION_SESSION_SIZE
snapshot_limits_stats: resb NEBOC_COMPILATION_LIMITS_SIZE + NEBOC_SESSION_STATISTICS_SIZE

section .text

_start:
    call .test_phase_and_cleanup
    test eax, eax
    jnz .exit
    call .test_limits_and_failure
    test eax, eax
    jnz .exit
    call .test_init_failure
    test eax, eax
    jnz .exit
    call .test_determinism
.exit:
    mov edi, eax
    jmp neboc_host_process_exit

.test_phase_and_cleanup:
    sub rsp, 8
    call nebo_fake_host_reset
    lea rdi, [rel session_a]
    xor eax, eax
    mov ecx, NEBOC_COMPILATION_SESSION_QWORDS
    rep stosq

    lea rdi, [rel session_a]
    lea rsi, [rel nebo_fake_host_services]
    mov rdx, TEST_OWNER
    mov ecx, 4096
    mov r8d, 4096
    call neboc_compilation_session_init_with_memory
    test eax, eax
    jnz .fail_1

    lea rdi, [rel session_a]
    mov rsi, TEST_OWNER
    call neboc_compilation_session_validate
    test eax, eax
    jnz .fail_2

    cmp qword [rel session_a + NEBOC_SESSION_PHASE_OFFSET], NEBOC_PHASE_SESSION_CREATED
    jne .fail_3
    cmp qword [rel session_a + NEBOC_SESSION_RUN_STATE_OFFSET], NEBOC_SESSION_RUN_ACTIVE
    jne .fail_4
    cmp qword [rel session_a + NEBOC_SESSION_RESOURCES_ACTIVE_OFFSET], 1
    jne .fail_5
    cmp qword [rel session_a + NEBOC_SESSION_LIMITS_OFFSET + NEBOC_LIMIT_SOURCE_BYTES_OFFSET], NEBOC_LIMIT_DEFAULT_SOURCE_BYTES
    jne .fail_6
    cmp qword [rel session_a + NEBOC_SESSION_DIAGNOSTIC_LIMIT_OFFSET], NEBOC_LIMIT_DEFAULT_DIAGNOSTICS
    jne .fail_7

    ; Invalid CREATED -> LEXED transition must fail without changing phase.
    lea rdi, [rel session_a]
    mov esi, NEBOC_PHASE_SESSION_CREATED
    mov edx, NEBOC_PHASE_LEXED
    mov rcx, TEST_OWNER
    call neboc_compilation_session_advance
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne .fail_8
    cmp qword [rel session_a + NEBOC_SESSION_PHASE_OFFSET], NEBOC_PHASE_SESSION_CREATED
    jne .fail_9
    cmp qword [rel session_a + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_INVALID_TRANSITIONS_OFFSET], 1
    jne .fail_10

    xor r12d, r12d
    mov r13d, 1
.phase_loop:
    lea rdi, [rel session_a]
    mov rsi, r12
    mov rdx, r13
    mov rcx, TEST_OWNER
    call neboc_compilation_session_advance
    test eax, eax
    jnz .fail_11
    inc r12
    inc r13
    cmp r13, NEBOC_PHASE_COMPLETE + 1
    jb .phase_loop

    cmp qword [rel session_a + NEBOC_SESSION_PHASE_OFFSET], NEBOC_PHASE_COMPLETE
    jne .fail_12
    cmp qword [rel session_a + NEBOC_SESSION_RUN_STATE_OFFSET], NEBOC_SESSION_RUN_COMPLETE
    jne .fail_13
    cmp qword [rel session_a + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_PHASE_TRANSITIONS_OFFSET], 13
    jne .fail_14
    cmp qword [rel session_a + NEBOC_SESSION_DIAGNOSTICS_FINALIZED_OFFSET], 1
    jne .fail_15

    lea rdi, [rel session_a]
    mov rsi, TEST_OWNER
    call neboc_compilation_session_cleanup
    test eax, eax
    jnz .fail_16
    cmp qword [rel session_a + NEBOC_SESSION_RESOURCES_ACTIVE_OFFSET], 0
    jne .fail_17
    cmp qword [rel nebo_fake_host_context + NEBOC_FAKE_MEMORY_ACTIVE_OFFSET], 0
    jne .fail_18
    cmp qword [rel session_a + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_CLEANUPS_OFFSET], 1
    jne .fail_19

    ; Cleanup is idempotent and must not double-count.
    lea rdi, [rel session_a]
    mov rsi, TEST_OWNER
    call neboc_compilation_session_cleanup
    test eax, eax
    jnz .fail_20
    cmp qword [rel session_a + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_CLEANUPS_OFFSET], 1
    jne .fail_21

    lea rdi, [rel session_a]
    mov rsi, TEST_OWNER
    call neboc_compilation_session_validate
    test eax, eax
    jnz .fail_22

    lea rdi, [rel session_a]
    mov rsi, TEST_OWNER
    call neboc_compilation_session_destroy
    test eax, eax
    jnz .fail_23
    cmp qword [rel session_a + NEBOC_SESSION_INITIALIZED_OFFSET], 0
    jne .fail_24
    TEST_RETURN 0

.fail_1: TEST_RETURN 1
.fail_2: TEST_RETURN 2
.fail_3: TEST_RETURN 3
.fail_4: TEST_RETURN 4
.fail_5: TEST_RETURN 5
.fail_6: TEST_RETURN 6
.fail_7: TEST_RETURN 7
.fail_8: TEST_RETURN 8
.fail_9: TEST_RETURN 9
.fail_10: TEST_RETURN 10
.fail_11: TEST_RETURN 11
.fail_12: TEST_RETURN 12
.fail_13: TEST_RETURN 13
.fail_14: TEST_RETURN 14
.fail_15: TEST_RETURN 15
.fail_16: TEST_RETURN 16
.fail_17: TEST_RETURN 17
.fail_18: TEST_RETURN 18
.fail_19: TEST_RETURN 19
.fail_20: TEST_RETURN 20
.fail_21: TEST_RETURN 21
.fail_22: TEST_RETURN 22
.fail_23: TEST_RETURN 23
.fail_24: TEST_RETURN 24

.test_limits_and_failure:
    sub rsp, 8
    call nebo_fake_host_reset
    lea rdi, [rel session_a]
    xor eax, eax
    mov ecx, NEBOC_COMPILATION_SESSION_QWORDS
    rep stosq
    lea rdi, [rel session_a]
    lea rsi, [rel nebo_fake_host_services]
    mov rdx, TEST_OWNER
    mov ecx, 4096
    mov r8d, 4096
    call neboc_compilation_session_init_with_memory
    test eax, eax
    jnz .fail_31

    lea rdi, [rel session_a]
    mov esi, NEBOC_RESOURCE_SOURCE_BYTES
    mov edx, 8
    mov rcx, TEST_OWNER
    call neboc_compilation_session_set_limit_checked
    test eax, eax
    jnz .fail_32

    lea rdi, [rel session_a]
    mov esi, NEBOC_RESOURCE_SOURCE_BYTES
    mov edx, 8
    mov rcx, TEST_OWNER
    call neboc_compilation_session_check_limit
    test eax, eax
    jnz .fail_33

    lea rdi, [rel session_a]
    mov esi, NEBOC_RESOURCE_SOURCE_BYTES
    mov edx, 9
    mov rcx, TEST_OWNER
    call neboc_compilation_session_check_limit
    cmp eax, NEBOC_STATUS_LIMIT_EXCEEDED
    jne .fail_34

    lea rdi, [rel session_a]
    mov esi, NEBOC_RESOURCE_DIAGNOSTICS
    mov edx, 1
    mov rcx, TEST_OWNER
    call neboc_compilation_session_set_limit_checked
    test eax, eax
    jnz .fail_35

    lea rdi, [rel session_a]
    mov rsi, TEST_OWNER
    call neboc_compilation_session_record_diagnostic
    test eax, eax
    jnz .fail_36
    lea rdi, [rel session_a]
    mov rsi, TEST_OWNER
    call neboc_compilation_session_record_diagnostic
    cmp eax, NEBOC_STATUS_LIMIT_EXCEEDED
    jne .fail_37

    cmp qword [rel session_a + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_LIMIT_CHECKS_OFFSET], 4
    jne .fail_38
    cmp qword [rel session_a + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_LIMIT_FAILURES_OFFSET], 2
    jne .fail_39
    cmp qword [rel session_a + NEBOC_SESSION_DIAGNOSTIC_COUNT_OFFSET], 1
    jne .fail_40

    lea rdi, [rel session_a]
    mov esi, NEBOC_STATUS_LIMIT_EXCEEDED
    mov rdx, TEST_OWNER
    call neboc_compilation_session_fail
    cmp eax, NEBOC_STATUS_LIMIT_EXCEEDED
    jne .fail_41
    cmp qword [rel session_a + NEBOC_SESSION_PHASE_OFFSET], NEBOC_PHASE_FAILED
    jne .fail_42
    cmp qword [rel session_a + NEBOC_SESSION_RUN_STATE_OFFSET], NEBOC_SESSION_RUN_FAILED
    jne .fail_43
    cmp qword [rel session_a + NEBOC_SESSION_RESOURCES_ACTIVE_OFFSET], 0
    jne .fail_44
    cmp qword [rel session_a + NEBOC_SESSION_DIAGNOSTICS_FINALIZED_OFFSET], 1
    jne .fail_45
    cmp qword [rel nebo_fake_host_context + NEBOC_FAKE_MEMORY_ACTIVE_OFFSET], 0
    jne .fail_46
    cmp qword [rel session_a + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_FAILURES_OFFSET], 1
    jne .fail_47
    cmp qword [rel session_a + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_CLEANUPS_OFFSET], 1
    jne .fail_48

    lea rdi, [rel session_a]
    mov rsi, TEST_OWNER
    call neboc_compilation_session_validate
    test eax, eax
    jnz .fail_49
    lea rdi, [rel session_a]
    mov rsi, TEST_OWNER
    call neboc_compilation_session_destroy
    test eax, eax
    jnz .fail_50
    TEST_RETURN 0
.fail_31: TEST_RETURN 31
.fail_32: TEST_RETURN 32
.fail_33: TEST_RETURN 33
.fail_34: TEST_RETURN 34
.fail_35: TEST_RETURN 35
.fail_36: TEST_RETURN 36
.fail_37: TEST_RETURN 37
.fail_38: TEST_RETURN 38
.fail_39: TEST_RETURN 39
.fail_40: TEST_RETURN 40
.fail_41: TEST_RETURN 41
.fail_42: TEST_RETURN 42
.fail_43: TEST_RETURN 43
.fail_44: TEST_RETURN 44
.fail_45: TEST_RETURN 45
.fail_46: TEST_RETURN 46
.fail_47: TEST_RETURN 47
.fail_48: TEST_RETURN 48
.fail_49: TEST_RETURN 49
.fail_50: TEST_RETURN 50

.test_init_failure:
    sub rsp, 8
    call nebo_fake_host_reset
    mov qword [rel nebo_fake_host_context + NEBOC_FAKE_FAIL_MASK_OFFSET], NEBOC_FAKE_FAIL_MEMORY_RESERVE
    lea rdi, [rel session_a]
    xor eax, eax
    mov ecx, NEBOC_COMPILATION_SESSION_QWORDS
    rep stosq
    lea rdi, [rel session_a]
    lea rsi, [rel nebo_fake_host_services]
    mov rdx, TEST_OWNER
    mov ecx, 4096
    mov r8d, 4096
    call neboc_compilation_session_init_with_memory
    cmp eax, NEBOC_STATUS_OUT_OF_MEMORY
    jne .fail_61
    cmp qword [rel session_a + NEBOC_SESSION_PHASE_OFFSET], NEBOC_PHASE_FAILED
    jne .fail_62
    cmp qword [rel session_a + NEBOC_SESSION_RESOURCES_ACTIVE_OFFSET], 0
    jne .fail_63
    cmp qword [rel nebo_fake_host_context + NEBOC_FAKE_MEMORY_ACTIVE_OFFSET], 0
    jne .fail_64
    cmp qword [rel session_a + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_FAILURES_OFFSET], 1
    jne .fail_65
    lea rdi, [rel session_a]
    mov rsi, TEST_OWNER
    call neboc_compilation_session_destroy
    test eax, eax
    jnz .fail_66
    TEST_RETURN 0
.fail_61: TEST_RETURN 61
.fail_62: TEST_RETURN 62
.fail_63: TEST_RETURN 63
.fail_64: TEST_RETURN 64
.fail_65: TEST_RETURN 65
.fail_66: TEST_RETURN 66

.test_determinism:
    sub rsp, 8
    call nebo_fake_host_reset
    lea rdi, [rel session_a]
    xor eax, eax
    mov ecx, NEBOC_COMPILATION_SESSION_QWORDS
    rep stosq
    lea rdi, [rel session_a]
    lea rsi, [rel nebo_fake_host_services]
    mov rdx, TEST_OWNER
    mov ecx, 4096
    mov r8d, 4096
    call neboc_compilation_session_init_with_memory
    test eax, eax
    jnz .fail_71
    lea rsi, [rel session_a + NEBOC_SESSION_LIMITS_OFFSET]
    lea rdi, [rel snapshot_limits_stats]
    mov ecx, (NEBOC_COMPILATION_LIMITS_SIZE + NEBOC_SESSION_STATISTICS_SIZE) / 8
    rep movsq
    lea rdi, [rel session_a]
    mov rsi, TEST_OWNER
    call neboc_compilation_session_destroy
    test eax, eax
    jnz .fail_72

    call nebo_fake_host_reset
    lea rdi, [rel session_b]
    xor eax, eax
    mov ecx, NEBOC_COMPILATION_SESSION_QWORDS
    rep stosq
    lea rdi, [rel session_b]
    lea rsi, [rel nebo_fake_host_services]
    mov rdx, TEST_OWNER
    mov ecx, 4096
    mov r8d, 4096
    call neboc_compilation_session_init_with_memory
    test eax, eax
    jnz .fail_73
    lea rsi, [rel snapshot_limits_stats]
    lea rdi, [rel session_b + NEBOC_SESSION_LIMITS_OFFSET]
    mov ecx, (NEBOC_COMPILATION_LIMITS_SIZE + NEBOC_SESSION_STATISTICS_SIZE) / 8
    repe cmpsq
    jne .fail_74
    cmp qword [rel session_b + NEBOC_SESSION_PHASE_OFFSET], NEBOC_PHASE_SESSION_CREATED
    jne .fail_75
    cmp qword [rel session_b + NEBOC_SESSION_RUN_STATE_OFFSET], NEBOC_SESSION_RUN_ACTIVE
    jne .fail_76
    lea rdi, [rel session_b]
    mov rsi, TEST_OWNER
    call neboc_compilation_session_destroy
    test eax, eax
    jnz .fail_77
    TEST_RETURN 0
.fail_71: TEST_RETURN 71
.fail_72: TEST_RETURN 72
.fail_73: TEST_RETURN 73
.fail_74: TEST_RETURN 74
.fail_75: TEST_RETURN 75
.fail_76: TEST_RETURN 76
.fail_77: TEST_RETURN 77

section .note.GNU-stack noalloc noexec nowrite progbits
