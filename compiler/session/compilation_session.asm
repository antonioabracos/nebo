; Nebo Assembly — CompilationSession v0
;
; Purpose:
;   Own one compilation's host binding, limits, statistics, root region, Arena,
;   StringPool, phase state and central cleanup.
;
; Inputs:
;   Per-function arguments follow NEBOC_INTERNAL_ABI_v0.
;
; Outputs:
;   StatusCode in EAX and explicit session/statistics fields.
;
; Status:
;   Uses the common StatusCode model; phase/run state are separate fields.
;
; Clobbers:
;   Caller-saved registers and flags.
;
; Preserved:
;   RBX, RBP, R12, R13, R14, R15 and RSP.
;
; Stack:
;   16-byte aligned before every internal CALL; no red-zone dependency.
;
; Ownership:
;   The session owns its MemoryRegion. Arena and StringPool borrow that region.
;
; Thread safety:
;   Single-writer v0.1; every mutation requires the exact non-zero owner token.
;
; Errors:
;   Invalid transitions, stale ownership and resource limits are controlled.
;
; Tests:
;   MF010 native session suite and HOST_SUPPORT_FOUNDATION_GREEN.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/support/limits/compilation_limits.inc"
%include "compiler/support/statistics/session_statistics.inc"
%include "compiler/support/memory/memory_region.inc"
%include "compiler/support/memory/arena.inc"
%include "compiler/support/string/string_pool.inc"
%include "compiler/support/id/typed_id.inc"
%include "compiler/session/compilation_session.inc"

extern neboc_compilation_limits_defaults
extern neboc_compilation_limits_validate
extern neboc_compilation_limit_get
extern neboc_compilation_limit_set_checked
extern neboc_session_statistics_zero
extern neboc_session_statistics_snapshot
extern neboc_memory_region_init
extern neboc_memory_region_validate
extern neboc_memory_region_destroy
extern neboc_arena_init
extern neboc_arena_validate
extern neboc_arena_destroy
extern neboc_string_pool_init
extern neboc_string_pool_validate

section .text

; session_init(session*, host*, owner_token)
NEBOC_ABI_FUNCTION neboc_compilation_session_init
    mov ecx, NEBOC_SESSION_DEFAULT_RESERVE_BYTES
    mov r8d, NEBOC_SESSION_DEFAULT_MAXIMUM_BYTES
    jmp neboc_compilation_session_init_with_memory

; session_init_with_memory(session*, host*, owner, reserve_bytes, maximum_bytes)
NEBOC_ABI_FUNCTION neboc_compilation_session_init_with_memory
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    test rcx, rcx
    jz .invalid
    test r8, r8
    jz .invalid
    cmp rcx, r8
    ja .limit
    cmp r8, NEBOC_MEMORY_REGION_HARD_MAXIMUM_BYTES
    ja .limit
    cmp qword [rdi + NEBOC_SESSION_INITIALIZED_OFFSET], 0
    jne .invalid

    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16

    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    mov r15, r8

    mov rax, [rbx + NEBOC_SESSION_GENERATION_OFFSET]
    inc rax
    jnz .generation_ready
    mov eax, 1
.generation_ready:
    mov [rsp + 8], rax

    mov rdi, rbx
    xor eax, eax
    mov ecx, NEBOC_COMPILATION_SESSION_QWORDS
    rep stosq

    mov [rbx + NEBOC_SESSION_HOST_OFFSET], r12
    mov [rbx + NEBOC_SESSION_OWNER_OFFSET], r13
    mov qword [rbx + NEBOC_SESSION_PHASE_OFFSET], NEBOC_PHASE_SESSION_CREATED
    mov qword [rbx + NEBOC_SESSION_LAST_STATUS_OFFSET], NEBOC_STATUS_OK
    mov qword [rbx + NEBOC_SESSION_RUN_STATE_OFFSET], NEBOC_SESSION_RUN_ACTIVE
    mov qword [rbx + NEBOC_SESSION_FLAGS_OFFSET], NEBOC_SESSION_FLAG_NONE
    mov rax, [rsp + 8]
    mov [rbx + NEBOC_SESSION_GENERATION_OFFSET], rax
    mov qword [rbx + NEBOC_SESSION_INITIALIZED_OFFSET], 1
    mov qword [rbx + NEBOC_SESSION_RESOURCES_ACTIVE_OFFSET], 0
    mov qword [rbx + NEBOC_SESSION_CLEANUP_STATUS_OFFSET], NEBOC_STATUS_OK

    lea rdi, [rbx + NEBOC_SESSION_LIMITS_OFFSET]
    call neboc_compilation_limits_defaults
    test eax, eax
    jne .init_fail_no_resource

    lea rdi, [rbx + NEBOC_SESSION_STATISTICS_OFFSET]
    call neboc_session_statistics_zero
    test eax, eax
    jne .init_fail_no_resource

    mov qword [rbx + NEBOC_SESSION_DIAGNOSTIC_COUNT_OFFSET], 0
    mov qword [rbx + NEBOC_SESSION_DIAGNOSTICS_FINALIZED_OFFSET], 0
    mov rax, [rbx + NEBOC_SESSION_LIMITS_OFFSET + NEBOC_LIMIT_DIAGNOSTICS_OFFSET]
    mov [rbx + NEBOC_SESSION_DIAGNOSTIC_LIMIT_OFFSET], rax

    lea rdi, [rbx + NEBOC_SESSION_MEMORY_REGION_OFFSET]
    mov rsi, r12
    mov rdx, r14
    mov rcx, r15
    mov r8, r13
    call neboc_memory_region_init
    test eax, eax
    jne .init_fail_no_resource

    lea rdi, [rbx + NEBOC_SESSION_ARENA_OFFSET]
    lea rsi, [rbx + NEBOC_SESSION_MEMORY_REGION_OFFSET]
    mov rdx, r14
    mov rcx, r13
    call neboc_arena_init
    test eax, eax
    jne .init_fail_region

    lea rdi, [rbx + NEBOC_SESSION_STRING_POOL_OFFSET]
    lea rsi, [rbx + NEBOC_SESSION_ARENA_OFFSET]
    mov edx, NEBOC_SESSION_DEFAULT_STRING_CAPACITY
    mov ecx, NEBOC_ID_KIND_STRING
    mov r8, r13
    call neboc_string_pool_init
    test eax, eax
    jne .init_fail_arena

    mov qword [rbx + NEBOC_SESSION_RESOURCES_ACTIVE_OFFSET], 1
    xor eax, eax
    jmp .init_finish

.init_fail_arena:
    mov [rsp], rax
    lea rdi, [rbx + NEBOC_SESSION_STRING_POOL_OFFSET]
    xor eax, eax
    mov ecx, NEBOC_STRING_POOL_SIZE / 8
    rep stosq
    lea rdi, [rbx + NEBOC_SESSION_ARENA_OFFSET]
    mov rsi, r13
    call neboc_arena_destroy
    jmp .init_release_region

.init_fail_region:
    mov [rsp], rax
.init_release_region:
    lea rdi, [rbx + NEBOC_SESSION_MEMORY_REGION_OFFSET]
    mov rsi, r13
    call neboc_memory_region_destroy
    jmp .init_record_failure

.init_fail_no_resource:
    mov [rsp], rax
.init_record_failure:
    mov rax, [rsp]
    mov [rbx + NEBOC_SESSION_LAST_STATUS_OFFSET], rax
    mov qword [rbx + NEBOC_SESSION_PHASE_OFFSET], NEBOC_PHASE_FAILED
    mov qword [rbx + NEBOC_SESSION_RUN_STATE_OFFSET], NEBOC_SESSION_RUN_FAILED
    mov qword [rbx + NEBOC_SESSION_RESOURCES_ACTIVE_OFFSET], 0
    mov qword [rbx + NEBOC_SESSION_DIAGNOSTICS_FINALIZED_OFFSET], 1
    inc qword [rbx + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_FAILURES_OFFSET]
    inc qword [rbx + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_CLEANUPS_OFFSET]
.init_finish:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; session_validate(session*, owner)
NEBOC_ABI_FUNCTION neboc_compilation_session_validate
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp qword [rdi + NEBOC_SESSION_INITIALIZED_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_SESSION_OWNER_OFFSET], rsi
    jne .invalid
    cmp qword [rdi + NEBOC_SESSION_GENERATION_OFFSET], 0
    je .invalid
    mov rax, [rdi + NEBOC_SESSION_PHASE_OFFSET]
    cmp rax, NEBOC_PHASE_FAILED
    ja .invalid

    push rbx
    push r12
    push r13
    mov rbx, rdi
    mov r12, rsi

    lea rdi, [rbx + NEBOC_SESSION_LIMITS_OFFSET]
    call neboc_compilation_limits_validate
    test eax, eax
    jne .validate_finish

    mov rax, [rbx + NEBOC_SESSION_PHASE_OFFSET]
    cmp rax, NEBOC_PHASE_FAILED
    je .expect_failed
    cmp rax, NEBOC_PHASE_COMPLETE
    je .expect_complete
    cmp qword [rbx + NEBOC_SESSION_RUN_STATE_OFFSET], NEBOC_SESSION_RUN_ACTIVE
    jne .validate_invalid
    jmp .resource_check
.expect_failed:
    cmp qword [rbx + NEBOC_SESSION_RUN_STATE_OFFSET], NEBOC_SESSION_RUN_FAILED
    jne .validate_invalid
    jmp .resource_check
.expect_complete:
    mov rax, [rbx + NEBOC_SESSION_RUN_STATE_OFFSET]
    cmp rax, NEBOC_SESSION_RUN_COMPLETE
    je .resource_check
    cmp rax, NEBOC_SESSION_RUN_CLEANED
    jne .validate_invalid

.resource_check:
    cmp qword [rbx + NEBOC_SESSION_RESOURCES_ACTIVE_OFFSET], 1
    jne .resources_inactive

    lea rdi, [rbx + NEBOC_SESSION_MEMORY_REGION_OFFSET]
    mov rsi, r12
    call neboc_memory_region_validate
    test eax, eax
    jne .validate_finish

    lea rdi, [rbx + NEBOC_SESSION_ARENA_OFFSET]
    mov rsi, r12
    call neboc_arena_validate
    test eax, eax
    jne .validate_finish

    lea rdi, [rbx + NEBOC_SESSION_STRING_POOL_OFFSET]
    mov rsi, r12
    call neboc_string_pool_validate
    jmp .validate_finish

.resources_inactive:
    mov rax, [rbx + NEBOC_SESSION_RUN_STATE_OFFSET]
    cmp rax, NEBOC_SESSION_RUN_FAILED
    je .validate_ok
    cmp rax, NEBOC_SESSION_RUN_COMPLETE
    je .validate_ok
    cmp rax, NEBOC_SESSION_RUN_CLEANED
    je .validate_ok
    jmp .validate_invalid
.validate_ok:
    xor eax, eax
    jmp .validate_finish
.validate_invalid:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
.validate_finish:
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; session_advance(session*, expected_phase, next_phase, owner)
NEBOC_ABI_FUNCTION neboc_compilation_session_advance
    test rdi, rdi
    jz .invalid
    test rcx, rcx
    jz .invalid
    cmp qword [rdi + NEBOC_SESSION_INITIALIZED_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_SESSION_OWNER_OFFSET], rcx
    jne .invalid
    cmp qword [rdi + NEBOC_SESSION_RESOURCES_ACTIVE_OFFSET], 1
    jne .invalid_transition
    cmp qword [rdi + NEBOC_SESSION_RUN_STATE_OFFSET], NEBOC_SESSION_RUN_ACTIVE
    jne .invalid_transition
    cmp [rdi + NEBOC_SESSION_PHASE_OFFSET], rsi
    jne .invalid_transition
    cmp rsi, NEBOC_PHASE_LINKED
    ja .invalid_transition
    mov rax, rsi
    inc rax
    cmp rdx, rax
    jne .invalid_transition
    cmp rdx, NEBOC_PHASE_COMPLETE
    ja .invalid_transition

    mov [rdi + NEBOC_SESSION_PHASE_OFFSET], rdx
    mov qword [rdi + NEBOC_SESSION_LAST_STATUS_OFFSET], NEBOC_STATUS_OK
    inc qword [rdi + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_PHASE_TRANSITIONS_OFFSET]
    cmp rdx, NEBOC_PHASE_COMPLETE
    jne .advance_ok
    mov qword [rdi + NEBOC_SESSION_RUN_STATE_OFFSET], NEBOC_SESSION_RUN_COMPLETE
    mov qword [rdi + NEBOC_SESSION_DIAGNOSTICS_FINALIZED_OFFSET], 1
.advance_ok:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid_transition:
    inc qword [rdi + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_INVALID_TRANSITIONS_OFFSET]
    mov qword [rdi + NEBOC_SESSION_LAST_STATUS_OFFSET], NEBOC_STATUS_INVALID_ARGUMENT
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; session_set_limit_checked(session*, resource_kind, value, owner)
NEBOC_ABI_FUNCTION neboc_compilation_session_set_limit_checked
    test rdi, rdi
    jz .invalid
    test rcx, rcx
    jz .invalid
    cmp qword [rdi + NEBOC_SESSION_INITIALIZED_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_SESSION_OWNER_OFFSET], rcx
    jne .invalid

    push rbx
    push r12
    push r13
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    lea rdi, [rbx + NEBOC_SESSION_LIMITS_OFFSET]
    mov rsi, r12
    mov rdx, r13
    call neboc_compilation_limit_set_checked
    test eax, eax
    jne .set_finish
    cmp r12, NEBOC_RESOURCE_DIAGNOSTICS
    jne .set_ok
    mov [rbx + NEBOC_SESSION_DIAGNOSTIC_LIMIT_OFFSET], r13
.set_ok:
    mov qword [rbx + NEBOC_SESSION_LAST_STATUS_OFFSET], NEBOC_STATUS_OK
.set_finish:
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; session_check_limit(session*, resource_kind, observed_value, owner)
NEBOC_ABI_FUNCTION neboc_compilation_session_check_limit
    test rdi, rdi
    jz .invalid
    test rcx, rcx
    jz .invalid
    cmp qword [rdi + NEBOC_SESSION_INITIALIZED_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_SESSION_OWNER_OFFSET], rcx
    jne .invalid

    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    mov qword [rsp], 0

    inc qword [rbx + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_LIMIT_CHECKS_OFFSET]
    lea rdi, [rbx + NEBOC_SESSION_LIMITS_OFFSET]
    mov rsi, r12
    lea rdx, [rsp]
    call neboc_compilation_limit_get
    test eax, eax
    jne .check_finish
    cmp r13, [rsp]
    ja .check_limit

    cmp r12, NEBOC_RESOURCE_SOURCE_BYTES
    je .stat_source
    cmp r12, NEBOC_RESOURCE_TOKENS
    je .stat_tokens
    cmp r12, NEBOC_RESOURCE_AST_NODES
    je .stat_ast
    cmp r12, NEBOC_RESOURCE_SYMBOLS
    je .stat_symbols
    cmp r12, NEBOC_RESOURCE_FUNCTIONS
    je .stat_functions
    cmp r12, NEBOC_RESOURCE_DIAGNOSTICS
    je .stat_diagnostics
    cmp r12, NEBOC_RESOURCE_PARSER_NESTING
    je .stat_nesting
    cmp r12, NEBOC_RESOURCE_DEPENDENCY_NODES
    je .stat_dep_nodes
    cmp r12, NEBOC_RESOURCE_DEPENDENCY_EDGES
    je .stat_dep_edges
    cmp r12, NEBOC_RESOURCE_GENERATED_ASM_BYTES
    je .stat_generated
    cmp r12, NEBOC_RESOURCE_TOOL_OUTPUT_BYTES
    je .stat_tool
    jmp .check_invalid
.stat_source:
    mov [rbx + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_SOURCE_BYTES_OFFSET], r13
    jmp .check_ok
.stat_tokens:
    mov [rbx + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_TOKENS_OFFSET], r13
    jmp .check_ok
.stat_ast:
    mov [rbx + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_AST_NODES_OFFSET], r13
    jmp .check_ok
.stat_symbols:
    mov [rbx + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_SYMBOLS_OFFSET], r13
    jmp .check_ok
.stat_functions:
    mov [rbx + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_FUNCTIONS_OFFSET], r13
    jmp .check_ok
.stat_diagnostics:
    mov [rbx + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_DIAGNOSTICS_OFFSET], r13
    jmp .check_ok
.stat_nesting:
    cmp r13, [rbx + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_PARSER_NESTING_PEAK_OFFSET]
    jbe .check_ok
    mov [rbx + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_PARSER_NESTING_PEAK_OFFSET], r13
    jmp .check_ok
.stat_dep_nodes:
    mov [rbx + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_DEPENDENCY_NODES_OFFSET], r13
    jmp .check_ok
.stat_dep_edges:
    mov [rbx + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_DEPENDENCY_EDGES_OFFSET], r13
    jmp .check_ok
.stat_generated:
    mov [rbx + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_GENERATED_ASM_BYTES_OFFSET], r13
    jmp .check_ok
.stat_tool:
    mov [rbx + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_TOOL_OUTPUT_BYTES_OFFSET], r13
.check_ok:
    mov qword [rbx + NEBOC_SESSION_LAST_STATUS_OFFSET], NEBOC_STATUS_OK
    xor eax, eax
    jmp .check_finish
.check_limit:
    inc qword [rbx + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_LIMIT_FAILURES_OFFSET]
    mov qword [rbx + NEBOC_SESSION_LAST_STATUS_OFFSET], NEBOC_STATUS_LIMIT_EXCEEDED
    mov eax, NEBOC_STATUS_LIMIT_EXCEEDED
    jmp .check_finish
.check_invalid:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
.check_finish:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; session_record_diagnostic(session*, owner)
NEBOC_ABI_FUNCTION neboc_compilation_session_record_diagnostic
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    push rbx
    push r12
    push r13
    mov rbx, rdi
    mov r12, rsi
    mov r13, [rbx + NEBOC_SESSION_DIAGNOSTIC_COUNT_OFFSET]
    inc r13
    mov rdi, rbx
    mov esi, NEBOC_RESOURCE_DIAGNOSTICS
    mov rdx, r13
    mov rcx, r12
    call neboc_compilation_session_check_limit
    test eax, eax
    jne .diagnostic_finish
    mov [rbx + NEBOC_SESSION_DIAGNOSTIC_COUNT_OFFSET], r13
.diagnostic_finish:
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; session_cleanup(session*, owner) — idempotent central resource cleanup.
NEBOC_ABI_FUNCTION neboc_compilation_session_cleanup
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp qword [rdi + NEBOC_SESSION_INITIALIZED_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_SESSION_OWNER_OFFSET], rsi
    jne .invalid
    cmp qword [rdi + NEBOC_SESSION_RESOURCES_ACTIVE_OFFSET], 0
    je .already_clean

    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov rbx, rdi
    mov r12, rsi
    mov qword [rsp], NEBOC_STATUS_OK

    mov rax, [rbx + NEBOC_SESSION_ARENA_OFFSET + NEBOC_ARENA_HIGH_WATER_OFFSET]
    cmp rax, [rbx + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_ARENA_HIGH_WATER_OFFSET]
    jbe .high_water_done
    mov [rbx + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_ARENA_HIGH_WATER_OFFSET], rax
.high_water_done:

    lea rdi, [rbx + NEBOC_SESSION_STRING_POOL_OFFSET]
    xor eax, eax
    mov ecx, NEBOC_STRING_POOL_SIZE / 8
    rep stosq

    cmp qword [rbx + NEBOC_SESSION_ARENA_OFFSET + NEBOC_ARENA_ACTIVE_OFFSET], 1
    jne .cleanup_region
    lea rdi, [rbx + NEBOC_SESSION_ARENA_OFFSET]
    mov rsi, r12
    call neboc_arena_destroy
    test eax, eax
    jz .cleanup_region
    mov [rsp], rax
.cleanup_region:
    cmp qword [rbx + NEBOC_SESSION_MEMORY_REGION_OFFSET + NEBOC_MEMORY_REGION_ACTIVE_OFFSET], 1
    jne .cleanup_finalize
    lea rdi, [rbx + NEBOC_SESSION_MEMORY_REGION_OFFSET]
    mov rsi, r12
    call neboc_memory_region_destroy
    test eax, eax
    jz .cleanup_finalize
    cmp qword [rsp], NEBOC_STATUS_OK
    jne .cleanup_finalize
    mov [rsp], rax
.cleanup_finalize:
    cmp qword [rsp], NEBOC_STATUS_OK
    jne .cleanup_error
    mov qword [rbx + NEBOC_SESSION_RESOURCES_ACTIVE_OFFSET], 0
    mov qword [rbx + NEBOC_SESSION_CLEANUP_STATUS_OFFSET], NEBOC_STATUS_OK
    inc qword [rbx + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_CLEANUPS_OFFSET]
    xor eax, eax
    jmp .cleanup_finish
.cleanup_error:
    mov rax, [rsp]
    mov [rbx + NEBOC_SESSION_CLEANUP_STATUS_OFFSET], rax
    mov [rbx + NEBOC_SESSION_LAST_STATUS_OFFSET], rax
.cleanup_finish:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret
.already_clean:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; session_fail(session*, blocking_status, owner)
NEBOC_ABI_FUNCTION neboc_compilation_session_fail
    test rdi, rdi
    jz .invalid
    test rdx, rdx
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp rsi, NEBOC_STATUS_COUNT
    jae .invalid
    cmp qword [rdi + NEBOC_SESSION_INITIALIZED_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_SESSION_OWNER_OFFSET], rdx
    jne .invalid
    cmp qword [rdi + NEBOC_SESSION_RUN_STATE_OFFSET], NEBOC_SESSION_RUN_ACTIVE
    jne .invalid

    push rbx
    push r12
    push r13
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov [rbx + NEBOC_SESSION_LAST_STATUS_OFFSET], r12
    mov qword [rbx + NEBOC_SESSION_PHASE_OFFSET], NEBOC_PHASE_FAILED
    mov qword [rbx + NEBOC_SESSION_RUN_STATE_OFFSET], NEBOC_SESSION_RUN_FAILED
    mov qword [rbx + NEBOC_SESSION_DIAGNOSTICS_FINALIZED_OFFSET], 1
    inc qword [rbx + NEBOC_SESSION_STATISTICS_OFFSET + NEBOC_STATS_FAILURES_OFFSET]
    mov rdi, rbx
    mov rsi, r13
    call neboc_compilation_session_cleanup
    test eax, eax
    jne .fail_finish
    mov eax, r12d
.fail_finish:
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; session_destroy(session*, owner)
NEBOC_ABI_FUNCTION neboc_compilation_session_destroy
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp qword [rdi + NEBOC_SESSION_INITIALIZED_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_SESSION_OWNER_OFFSET], rsi
    jne .invalid

    push rbx
    push r12
    push r13
    mov rbx, rdi
    mov r12, rsi
    mov rdi, rbx
    mov rsi, r12
    call neboc_compilation_session_cleanup
    test eax, eax
    jne .destroy_finish
    mov rax, [rbx + NEBOC_SESSION_GENERATION_OFFSET]
    inc rax
    jnz .destroy_generation_ready
    mov eax, 1
.destroy_generation_ready:
    mov [rbx + NEBOC_SESSION_GENERATION_OFFSET], rax
    mov qword [rbx + NEBOC_SESSION_HOST_OFFSET], 0
    mov qword [rbx + NEBOC_SESSION_OWNER_OFFSET], 0
    mov qword [rbx + NEBOC_SESSION_INITIALIZED_OFFSET], 0
    mov qword [rbx + NEBOC_SESSION_RESOURCES_ACTIVE_OFFSET], 0
    mov qword [rbx + NEBOC_SESSION_RUN_STATE_OFFSET], NEBOC_SESSION_RUN_CLEANED
    xor eax, eax
.destroy_finish:
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; session_statistics_snapshot(session*, owner, out_statistics*)
NEBOC_ABI_FUNCTION neboc_compilation_session_statistics_snapshot
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    cmp qword [rdi + NEBOC_SESSION_INITIALIZED_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_SESSION_OWNER_OFFSET], rsi
    jne .invalid
    lea rdi, [rdi + NEBOC_SESSION_STATISTICS_OFFSET]
    mov rsi, rdx
    jmp neboc_session_statistics_snapshot
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
