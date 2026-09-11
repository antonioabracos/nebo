; G105 source-to-effect bridge. The compiler emits only a subgroup and source
; seed; this runtime drives the same caller-owned adapter APIs used by native
; consumers and never dispatches on source paths or fixture identities.
bits 64
default rel
%define NEBO_G105_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/console_scan_source_probe.inc"
%include "runtime/scan_console.inc"

section .note.GNU-stack noalloc noexec nowrite progbits

section .rodata
g105_public_input: db 'green,blue'
g105_public_input_len equ $-g105_public_input
g105_retry_bad: db '!invalid'
g105_retry_bad_len equ $-g105_retry_bad
g105_secret_template: db 'synthetic-secret'
g105_secret_len equ $-g105_secret_template

section .bss align=16
g105_plan: resb NEBO_G105_PLAN_SIZE
g105_request: resb NEBO_G105_REQUEST_SIZE
g105_response: resb NEBO_G105_RESPONSE_SIZE
g105_event: resb NEBO_G105_EVENT_SIZE
g105_evidence: resb NEBO_G105_EVIDENCE_SIZE
g105_secret_buffer: resb g105_secret_len

section .text
global nebo_g105_source_probe
global nebo_g105_surface_probe
global nebo_g105_negative_probe

g105_clear_observations:
    lea rdi, [rel g105_request]
    mov rcx, NEBO_G105_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    lea rdi, [rel g105_response]
    mov rcx, NEBO_G105_RESPONSE_SIZE/8
    rep stosq
    lea rdi, [rel g105_event]
    mov rcx, NEBO_G105_EVENT_SIZE/8
    rep stosq
    lea rdi, [rel g105_evidence]
    mov rcx, NEBO_G105_EVIDENCE_QWORDS
    rep stosq
    ret

g105_restore_secret:
    lea rdi, [rel g105_secret_buffer]
    lea rsi, [rel g105_secret_template]
    mov ecx, g105_secret_len
    rep movsb
    ret

; EDI subgroup 1..10, ESI source seed. Success returns the source seed.
nebo_g105_source_probe:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov ebx, edi
    mov r12d, esi
    cmp ebx, 1
    jb .invalid
    cmp ebx, G105_SOURCE_MAX_MODE
    ja .invalid
    cmp r12d, G105_SOURCE_MIN_SEED
    jb .invalid
    call g105_clear_observations

    lea rdi, [rel g105_plan]
    mov esi, 3
    mov edx, NEBO_G105_CAP_ALL
    call nebo_scan_console_plan_init
    test eax, eax
    jnz .effect

    ; Distinct metadata values make each source seed observable in the plan.
    lea rdi, [rel g105_plan]
    mov esi, r12d
    mov edx, ebx
    add edx, 2
    mov ecx, r12d
    add ecx, 17
    mov r8d, r12d
    add r8d, 29
    mov r9d, ebx
    add r9d, 41
    mov rax, rbx
    add rax, 59
    shl rax, 32
    or r9, rax
    call nebo_scan_console_plan_metadata
    test eax, eax
    jnz .effect

    lea rdi, [rel g105_plan]
    mov esi, NEBO_G105_INPUT_MARKDOWN
    mov edx, 12
    mov ecx, 3
    cmp ebx, 4
    jne .multiline_ready
    mov esi, NEBO_G105_INPUT_RAW_BLOCK
    mov edx, 32
    mov ecx, 5
.multiline_ready:
    call nebo_scan_console_plan_multiline
    test eax, eax
    jnz .effect

    lea rdi, [rel g105_plan]
    mov esi, 3
    mov edx, NEBO_G105_CHOICE_ONE
    cmp ebx, 5
    jne .choices_ready
    mov edx, NEBO_G105_CHOICE_ALL
.choices_ready:
    call nebo_scan_console_plan_choices
    test eax, eax
    jnz .effect

    lea rdi, [rel g105_plan]
    xor esi, esi
    xor edx, edx
    cmp ebx, 6
    je .secret_policy
    cmp ebx, 10
    jne .security_ready
.secret_policy:
    mov esi, NEBO_G105_SECURITY_ALL
    mov edx, 4
.security_ready:
    call nebo_scan_console_plan_security
    test eax, eax
    jnz .effect

    mov r13d, NEBO_G105_SOURCE_MOCK
    cmp ebx, 9
    jne .retry_case
    mov r13d, NEBO_G105_SOURCE_REPLAY
    lea rdi, [rel g105_evidence]
    mov esi, NEBO_G105_SOURCE_LIVE
    xor edx, edx
    call nebo_scan_console_select_backend
    cmp eax, NEBO_G105_SOURCE_HEADLESS
    jne .effect

.retry_case:
    cmp ebx, 8
    jne .single_request
    lea rdi, [rel g105_plan]
    lea rsi, [rel g105_request]
    mov edx, r12d
    xor ecx, ecx
    mov r8d, NEBO_G105_SOURCE_MOCK
    call nebo_scan_console_request_build
    test eax, eax
    jnz .effect
    lea rdi, [rel g105_plan]
    lea rsi, [rel g105_request]
    lea rdx, [rel g105_retry_bad]
    mov ecx, g105_retry_bad_len
    lea r8, [rel g105_response]
    lea r9, [rel g105_event]
    call nebo_scan_console_response_apply
    cmp eax, -NEBO_G105_STATUS_VALIDATION
    jne .effect
    lea rdi, [rel g105_evidence]
    lea rsi, [rel g105_request]
    lea rdx, [rel g105_response]
    lea rcx, [rel g105_event]
    call nebo_scan_console_evidence_observe
    test eax, eax
    jnz .effect
    lea rdi, [rel g105_plan]
    xor esi, esi
    mov edx, NEBO_G105_STATUS_VALIDATION
    call nebo_scan_console_should_retry
    cmp eax, 1
    jne .effect
    lea rdi, [rel g105_plan]
    lea rsi, [rel g105_request]
    mov edx, r12d
    inc edx
    mov ecx, 1
    mov r8d, NEBO_G105_SOURCE_MOCK
    call nebo_scan_console_request_build
    test eax, eax
    jnz .effect
    jmp .public_response

.single_request:
    lea rdi, [rel g105_plan]
    lea rsi, [rel g105_request]
    mov edx, r12d
    xor ecx, ecx
    mov r8d, r13d
    call nebo_scan_console_request_build
    test eax, eax
    jnz .effect
    cmp ebx, 9
    jne .select_input
    mov edi, r12d
    dec edi
    lea rsi, [rel g105_request]
    call nebo_scan_console_replay_validate
    test eax, eax
    jnz .effect

.select_input:
    cmp ebx, 6
    je .secret_response
    cmp ebx, 10
    je .secret_response
.public_response:
    lea rdi, [rel g105_plan]
    lea rsi, [rel g105_request]
    lea rdx, [rel g105_public_input]
    mov ecx, g105_public_input_len
    lea r8, [rel g105_response]
    lea r9, [rel g105_event]
    call nebo_scan_console_response_apply
    test eax, eax
    jnz .effect
    jmp .observe

.secret_response:
    call g105_restore_secret
    lea rdi, [rel g105_plan]
    lea rsi, [rel g105_request]
    lea rdx, [rel g105_secret_buffer]
    mov ecx, g105_secret_len
    lea r8, [rel g105_response]
    lea r9, [rel g105_event]
    call nebo_scan_console_response_apply
    test eax, eax
    jnz .effect

.observe:
    lea rdi, [rel g105_evidence]
    lea rsi, [rel g105_request]
    lea rdx, [rel g105_response]
    lea rcx, [rel g105_event]
    call nebo_scan_console_evidence_observe
    test eax, eax
    jnz .effect

    cmp ebx, 6
    je .zeroize
    cmp ebx, 10
    jne .validate_evidence
.zeroize:
    lea rdi, [rel g105_secret_buffer]
    mov esi, g105_secret_len
    lea rdx, [rel g105_response]
    lea rcx, [rel g105_evidence]
    call nebo_scan_console_zeroize
    test eax, eax
    jnz .effect

.validate_evidence:
    lea rdi, [rel g105_evidence]
    call nebo_scan_console_evidence_validate
    test eax, eax
    jnz .effect
    mov eax, r12d
    jmp .done
.invalid:
    mov eax, -NEBO_G105_STATUS_INVALID
    jmp .done
.effect:
    mov eax, -NEBO_G105_STATUS_BAD_STATE
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; EDI mode, ESI seed, RDX selector -> stable source-derived observation.
nebo_g105_surface_probe:
    push rbx
    push r12
    sub rsp, 8
    mov ebx, esi
    mov r12, rdx
    call nebo_g105_source_probe
    cmp eax, ebx
    jne .done
    cmp r12, 1
    je .frontend
    cmp r12, 2
    je .form
    cmp r12, 3
    je .fields
    cmp r12, 4
    je .input_mode
    cmp r12, 5
    je .choices
    cmp r12, 6
    je .security
    cmp r12, 7
    je .requests
    cmp r12, 8
    je .failures
    cmp r12, 9
    je .retries
    cmp r12, 10
    je .redactions
    cmp r12, 11
    je .zeroizations
    cmp r12, 12
    je .fallbacks
    cmp r12, 13
    je .replays
    cmp r12, 14
    je .public_length
    cmp r12, 15
    je .public_digest
    cmp r12, 16
    je .value_digest
    cmp r12, 17
    je .maturity
    cmp r12, 18
    je .plan_digest
    cmp r12, 19
    je .selections
    cmp r12, 20
    je .last_request
    mov eax, -NEBO_G105_STATUS_INVALID
    jmp .done
.frontend: mov rax, [rel g105_plan + NEBO_G105_PLAN_FRONTEND_OFFSET]
    jmp .done
.form: mov rax, [rel g105_plan + NEBO_G105_PLAN_FORM_OFFSET]
    jmp .done
.fields: mov rax, [rel g105_plan + NEBO_G105_PLAN_FIELD_COUNT_OFFSET]
    jmp .done
.input_mode: mov rax, [rel g105_plan + NEBO_G105_PLAN_INPUT_MODE_OFFSET]
    jmp .done
.choices: mov rax, [rel g105_plan + NEBO_G105_PLAN_CHOICE_FLAGS_OFFSET]
    jmp .done
.security: mov rax, [rel g105_plan + NEBO_G105_PLAN_SECURITY_FLAGS_OFFSET]
    jmp .done
.requests: mov rax, [rel g105_evidence + NEBO_G105_EVIDENCE_REQUESTS_OFFSET]
    jmp .done
.failures: mov rax, [rel g105_evidence + NEBO_G105_EVIDENCE_FAILURES_OFFSET]
    jmp .done
.retries: mov rax, [rel g105_evidence + NEBO_G105_EVIDENCE_RETRIES_OFFSET]
    jmp .done
.redactions: mov rax, [rel g105_evidence + NEBO_G105_EVIDENCE_REDACTIONS_OFFSET]
    jmp .done
.zeroizations: mov rax, [rel g105_evidence + NEBO_G105_EVIDENCE_ZEROIZATIONS_OFFSET]
    jmp .done
.fallbacks: mov rax, [rel g105_evidence + NEBO_G105_EVIDENCE_FALLBACKS_OFFSET]
    jmp .done
.replays: mov rax, [rel g105_evidence + NEBO_G105_EVIDENCE_REPLAYS_OFFSET]
    jmp .done
.public_length: mov rax, [rel g105_event + NEBO_G105_EVENT_PUBLIC_LENGTH_OFFSET]
    jmp .done
.public_digest: mov rax, [rel g105_event + NEBO_G105_EVENT_PUBLIC_DIGEST_OFFSET]
    jmp .done
.value_digest: mov rax, [rel g105_response + NEBO_G105_RESPONSE_VALUE_DIGEST_OFFSET]
    jmp .done
.maturity: mov rax, [rel g105_evidence + NEBO_G105_EVIDENCE_MATURITY_OFFSET]
    jmp .done
.plan_digest: mov rax, [rel g105_plan + NEBO_G105_PLAN_DIGEST_OFFSET]
    jmp .done
.selections: mov rax, [rel g105_response + NEBO_G105_RESPONSE_SELECTIONS_OFFSET]
    jmp .done
.last_request: mov rax, [rel g105_evidence + NEBO_G105_EVIDENCE_LAST_REQUEST_ID_OFFSET]
.done:
    add rsp, 8
    pop r12
    pop rbx
    ret

; EDI case 1..7. Zero means the requested negative behavior was observed.
nebo_g105_negative_probe:
    push rbx
    push r12
    sub rsp, 8
    mov ebx, edi
    mov edi, 1
    mov esi, 2501
    call nebo_g105_source_probe
    cmp eax, 2501
    jne .failed
    cmp ebx, 1
    je .security_atomic
    cmp ebx, 2
    je .response_atomic
    cmp ebx, 3
    je .attempt_atomic
    cmp ebx, 4
    je .replay_order
    cmp ebx, 5
    je .secret_event
    cmp ebx, 6
    je .fallback_replay
    cmp ebx, 7
    je .evidence_atomic
    jmp .invalid_case
.security_atomic:
    mov r12, [rel g105_plan + NEBO_G105_PLAN_DIGEST_OFFSET]
    lea rdi, [rel g105_plan]
    mov esi, NEBO_G105_SECURITY_SECRET
    mov edx, 4
    call nebo_scan_console_plan_security
    cmp eax, -NEBO_G105_STATUS_INVALID
    jne .failed
    cmp r12, [rel g105_plan + NEBO_G105_PLAN_DIGEST_OFFSET]
    jne .failed
    jmp .ok
.response_atomic:
    mov qword [rel g105_response], 0x55555555
    mov qword [rel g105_event], 0x55555555
    lea rdi, [rel g105_plan]
    lea rsi, [rel g105_request]
    lea rdx, [rel g105_public_input]
    mov ecx, NEBO_G105_MAX_INPUT_BYTES + 1
    lea r8, [rel g105_response]
    lea r9, [rel g105_event]
    call nebo_scan_console_response_apply
    cmp eax, -NEBO_G105_STATUS_LIMIT
    jne .failed
    cmp qword [rel g105_response], 0x55555555
    jne .failed
    cmp qword [rel g105_event], 0x55555555
    jne .failed
    jmp .ok
.attempt_atomic:
    mov qword [rel g105_request], 0x55555555
    lea rdi, [rel g105_plan]
    lea rsi, [rel g105_request]
    mov edx, 99
    mov ecx, 3
    mov r8d, NEBO_G105_SOURCE_MOCK
    call nebo_scan_console_request_build
    cmp eax, -NEBO_G105_STATUS_EXHAUSTED
    jne .failed
    cmp qword [rel g105_request], 0x55555555
    jne .failed
    jmp .ok
.replay_order:
    mov rdi, [rel g105_request + NEBO_G105_REQUEST_ID_OFFSET]
    lea rsi, [rel g105_request]
    call nebo_scan_console_replay_validate
    cmp eax, -NEBO_G105_STATUS_REPLAY
    jne .failed
    jmp .ok
.secret_event:
    mov edi, 6
    mov esi, 2506
    call nebo_g105_source_probe
    cmp eax, 2506
    jne .failed
    cmp qword [rel g105_event + NEBO_G105_EVENT_PUBLIC_LENGTH_OFFSET], 0
    jne .failed
    mov rax, NEBO_G105_REDACTED_DIGEST
    cmp [rel g105_event + NEBO_G105_EVENT_PUBLIC_DIGEST_OFFSET], rax
    jne .failed
    cmp qword [rel g105_request + NEBO_G105_REQUEST_FLAGS_OFFSET], NEBO_G105_SECURITY_ALL
    jne .failed
    jmp .ok
.fallback_replay:
    mov edi, 9
    mov esi, 2509
    call nebo_g105_source_probe
    cmp eax, 2509
    jne .failed
    cmp qword [rel g105_evidence + NEBO_G105_EVIDENCE_FALLBACKS_OFFSET], 1
    jne .failed
    cmp qword [rel g105_evidence + NEBO_G105_EVIDENCE_REPLAYS_OFFSET], 1
    jne .failed
    jmp .ok
.evidence_atomic:
    mov r12, [rel g105_evidence + NEBO_G105_EVIDENCE_REQUESTS_OFFSET]
    inc qword [rel g105_request + NEBO_G105_REQUEST_ID_OFFSET]
    inc qword [rel g105_response + NEBO_G105_RESPONSE_REQUEST_ID_OFFSET]
    inc qword [rel g105_event + NEBO_G105_EVENT_REQUEST_ID_OFFSET]
    mov qword [rel g105_event + NEBO_G105_EVENT_STATUS_OFFSET], NEBO_G105_STATUS_VALIDATION
    lea rdi, [rel g105_evidence]
    lea rsi, [rel g105_request]
    lea rdx, [rel g105_response]
    lea rcx, [rel g105_event]
    call nebo_scan_console_evidence_observe
    cmp eax, -NEBO_G105_STATUS_BAD_STATE
    jne .failed
    cmp r12, [rel g105_evidence + NEBO_G105_EVIDENCE_REQUESTS_OFFSET]
    jne .failed
.ok:
    xor eax, eax
    jmp .done
.invalid_case:
    mov eax, -NEBO_G105_STATUS_INVALID
    jmp .done
.failed:
    mov eax, -NEBO_G105_STATUS_BAD_STATE
.done:
    add rsp, 8
    pop r12
    pop rbx
    ret
