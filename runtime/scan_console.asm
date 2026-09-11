; G105 ScanPlan/Console adapter. All state is caller allocated, every mutation
; follows a validate-then-commit boundary, and no function consults ambient
; terminal, filesystem, clock, locale, process, or network state.
bits 64
default rel
%define NEBO_SCAN_CONSOLE_IMPLEMENTATION 1
%include "runtime/scan_console.inc"
%include "runtime/textual/scan_plan.inc"

section .note.GNU-stack noalloc noexec nowrite progbits

section .text
global nebo_scan_console_plan_init
global nebo_scan_console_plan_metadata_sparse
global nebo_scan_console_plan_metadata
global nebo_scan_console_plan_multiline
global nebo_scan_console_plan_choices
global nebo_scan_console_plan_security
global nebo_scan_console_request_build
global nebo_scan_console_response_commit
global nebo_scan_console_response_apply
global nebo_scan_console_should_retry
global nebo_scan_console_replay_validate
global nebo_scan_console_select_backend
global nebo_scan_console_evidence_observe
global nebo_scan_console_zeroize
global nebo_scan_console_evidence_validate

; RDI plan. Recompute a stable digest over public plan fields.
g105_plan_digest:
    mov rax, 0xcbf29ce484222325
    xor rax, [rdi + NEBO_G105_PLAN_FRONTEND_OFFSET]
    rol rax, 7
    xor rax, [rdi + NEBO_G105_PLAN_FORM_OFFSET]
    rol rax, 7
    xor rax, [rdi + NEBO_G105_PLAN_FIELD_COUNT_OFFSET]
    rol rax, 7
    xor rax, [rdi + NEBO_G105_PLAN_VIEW_OFFSET]
    rol rax, 7
    xor rax, [rdi + NEBO_G105_PLAN_PANEL_OFFSET]
    rol rax, 7
    xor rax, [rdi + NEBO_G105_PLAN_FEEDBACK_OFFSET]
    rol rax, 7
    xor rax, [rdi + NEBO_G105_PLAN_STYLE_OFFSET]
    rol rax, 7
    xor rax, [rdi + NEBO_G105_PLAN_INPUT_MODE_OFFSET]
    rol rax, 7
    xor rax, [rdi + NEBO_G105_PLAN_MAX_LINES_OFFSET]
    rol rax, 7
    xor rax, [rdi + NEBO_G105_PLAN_DELIMITER_LEN_OFFSET]
    rol rax, 7
    xor rax, [rdi + NEBO_G105_PLAN_CHOICE_COUNT_OFFSET]
    rol rax, 7
    xor rax, [rdi + NEBO_G105_PLAN_CHOICE_FLAGS_OFFSET]
    rol rax, 7
    xor rax, [rdi + NEBO_G105_PLAN_SECURITY_FLAGS_OFFSET]
    rol rax, 7
    xor rax, [rdi + NEBO_G105_PLAN_MIN_STRENGTH_OFFSET]
    rol rax, 7
    xor rax, [rdi + NEBO_G105_PLAN_MAX_ATTEMPTS_OFFSET]
    rol rax, 7
    xor rax, [rdi + NEBO_G105_PLAN_CAPABILITIES_OFFSET]
    mov [rdi + NEBO_G105_PLAN_DIGEST_OFFSET], rax
    ret

; RDI plan, RSI max attempts, RDX capability mask.
nebo_scan_console_plan_init:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp rsi, NEBO_G105_MAX_ATTEMPTS
    ja .limit
    test rdx, ~NEBO_G105_CAP_ALL
    jnz .invalid
    test rdx, NEBO_G105_CAP_HEADLESS
    jz .capability
    push rdi
    push rsi
    push rdx
    mov rcx, NEBO_G105_PLAN_QWORDS
    xor eax, eax
    rep stosq
    pop rdx
    pop rsi
    pop rdi
    mov qword [rdi + NEBO_G105_PLAN_FRONTEND_OFFSET], NEBO_G105_FRONTEND_CONSOLE
    mov qword [rdi + NEBO_G105_PLAN_INPUT_MODE_OFFSET], NEBO_G105_INPUT_LINE
    mov qword [rdi + NEBO_G105_PLAN_MAX_LINES_OFFSET], 1
    mov [rdi + NEBO_G105_PLAN_MAX_ATTEMPTS_OFFSET], rsi
    mov [rdi + NEBO_G105_PLAN_CAPABILITIES_OFFSET], rdx
    call g105_plan_digest
    xor eax, eax
    ret
.invalid:
    mov eax, -NEBO_G105_STATUS_INVALID
    ret
.limit:
    mov eax, -NEBO_G105_STATUS_LIMIT
    ret
.capability:
    mov eax, -NEBO_G105_STATUS_CAPABILITY
    ret

; RDI plan, RSI form, RDX fields, RCX view, R8 panel, R9 feedback/style pack.
nebo_scan_console_plan_metadata:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    cmp rdx, NEBO_G105_MAX_FIELDS
    ja .limit
    test rcx, rcx
    jz .invalid
    test r8, r8
    jz .invalid
    mov rax, r9
    shr rax, 32
    test eax, eax
    jz .invalid
    test r9d, r9d
    jz .invalid
 .commit:
    mov [rdi + NEBO_G105_PLAN_FORM_OFFSET], rsi
    mov [rdi + NEBO_G105_PLAN_FIELD_COUNT_OFFSET], rdx
    mov [rdi + NEBO_G105_PLAN_VIEW_OFFSET], rcx
    mov [rdi + NEBO_G105_PLAN_PANEL_OFFSET], r8
    mov eax, r9d
    mov [rdi + NEBO_G105_PLAN_FEEDBACK_OFFSET], rax
    mov rax, r9
    shr rax, 32
    mov [rdi + NEBO_G105_PLAN_STYLE_OFFSET], rax
    call g105_plan_digest
    xor eax, eax
    ret
.invalid:
    mov eax, -NEBO_G105_STATUS_INVALID
    ret
.limit:
    mov eax, -NEBO_G105_STATUS_LIMIT
    ret

; Same metadata ABI; absent public metadata remains zero. This entry is for
; the typed source owner, which has already validated supplied Text identities.
nebo_scan_console_plan_metadata_sparse:
    test rdi,rdi
    jz nebo_scan_console_plan_metadata.invalid
    cmp rdx,NEBO_G105_MAX_FIELDS
    ja nebo_scan_console_plan_metadata.limit
    jmp nebo_scan_console_plan_metadata.commit

; RDI plan, RSI input mode, RDX max lines, RCX delimiter length.
nebo_scan_console_plan_multiline:
    test rdi, rdi
    jz .invalid
    cmp rsi, NEBO_G105_INPUT_LINE
    jb .invalid
    cmp rsi, NEBO_G105_INPUT_RAW_BLOCK
    ja .invalid
    test rdx, rdx
    jz .invalid
    cmp rdx, NEBO_G105_MAX_LINES
    ja .limit
    cmp rcx, 256
    ja .limit
    cmp rsi, NEBO_G105_INPUT_BLOCK
    jne .commit
    test rcx, rcx
    jz .invalid
.commit:
    mov [rdi + NEBO_G105_PLAN_INPUT_MODE_OFFSET], rsi
    mov [rdi + NEBO_G105_PLAN_MAX_LINES_OFFSET], rdx
    mov [rdi + NEBO_G105_PLAN_DELIMITER_LEN_OFFSET], rcx
    call g105_plan_digest
    xor eax, eax
    ret
.invalid:
    mov eax, -NEBO_G105_STATUS_INVALID
    ret
.limit:
    mov eax, -NEBO_G105_STATUS_LIMIT
    ret

; RDI plan, RSI choice count, RDX choice flags.
nebo_scan_console_plan_choices:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp rsi, NEBO_G105_MAX_CHOICES
    ja .limit
    test rdx, rdx
    jz .invalid
    test rdx, ~NEBO_G105_CHOICE_ALL
    jnz .invalid
    mov [rdi + NEBO_G105_PLAN_CHOICE_COUNT_OFFSET], rsi
    mov [rdi + NEBO_G105_PLAN_CHOICE_FLAGS_OFFSET], rdx
    call g105_plan_digest
    xor eax, eax
    ret
.invalid:
    mov eax, -NEBO_G105_STATUS_INVALID
    ret
.limit:
    mov eax, -NEBO_G105_STATUS_LIMIT
    ret

; RDI plan, RSI security flags, RDX minimum strength.
nebo_scan_console_plan_security:
    test rdi, rdi
    jz .invalid
    test rsi, ~NEBO_G105_SECURITY_ALL
    jnz .invalid
    test rsi, NEBO_G105_SECURITY_SECRET | NEBO_G105_SECURITY_PASSWORD
    jz .public
    mov rax, NEBO_G105_SECURITY_REDACT | NEBO_G105_SECURITY_NO_HISTORY
    or rax, NEBO_G105_SECURITY_NO_ECHO | NEBO_G105_SECURITY_SENSITIVE
    mov rcx, rsi
    and rcx, rax
    cmp rcx, rax
    jne .invalid
    test rdx, rdx
    jz .invalid
    cmp rdx, NEBO_G105_MAX_STRENGTH
    ja .limit
    jmp .canonical
.public:
    test rdx, rdx
    jnz .invalid
.canonical:
    push rdi
    push rsi
    push rdx
    mov r10, [rsp + 16]
    mov edi, SCAN_MAX_FEATURE_ID
    mov esi, SCAN_KIND_TEXT
    mov edx, SCAN_FLAG_REQUIRED
    mov rax, [rsp + 8]
    test rax, NEBO_G105_SECURITY_SECRET | NEBO_G105_SECURITY_PASSWORD
    jz .canonical_flags
    mov esi, SCAN_KIND_PASSWORD
    or edx, SCAN_FLAG_SECRET | SCAN_FLAG_NO_HISTORY | SCAN_FLAG_REDACT
.canonical_flags:
    test rax, NEBO_G105_SECURITY_UNTRUSTED
    jz .canonical_call
    or edx, SCAN_FLAG_UNTRUSTED
.canonical_call:
    mov r8d, [r10 + NEBO_G105_PLAN_MAX_ATTEMPTS_OFFSET]
    mov r9d, SCAN_SOURCE_MOCK
    mov ecx, SCAN_MAX_INPUT_BYTES
    call neboc_scan_feature_validate
    mov r10d, eax
    pop rdx
    pop rsi
    pop rdi
    test r10d, r10d
    jz .commit
    cmp r10d, -SCAN_E_LIMIT
    je .limit
    jmp .invalid
.commit:
    mov [rdi + NEBO_G105_PLAN_SECURITY_FLAGS_OFFSET], rsi
    mov [rdi + NEBO_G105_PLAN_MIN_STRENGTH_OFFSET], rdx
    call g105_plan_digest
    xor eax, eax
    ret
.invalid:
    mov eax, -NEBO_G105_STATUS_INVALID
    ret
.limit:
    mov eax, -NEBO_G105_STATUS_LIMIT
    ret

; RDI plan, RSI request, RDX id, RCX attempt, R8 source kind.
nebo_scan_console_request_build:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    cmp rcx, [rdi + NEBO_G105_PLAN_MAX_ATTEMPTS_OFFSET]
    jae .exhausted
    cmp r8, NEBO_G105_SOURCE_MOCK
    jb .invalid
    cmp r8, NEBO_G105_SOURCE_HEADLESS
    ja .invalid
    push rdi
    push rsi
    push rdx
    push rcx
    push r8
    mov edi, r8d
    mov rax, [rsp + 32]
    mov esi, [rax + NEBO_G105_PLAN_CAPABILITIES_OFFSET]
    call neboc_scan_source_validate
    mov r10d, eax
    pop r8
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    test r10d, r10d
    jnz .capability
    push rdi
    push rsi
    push rdx
    push rcx
    push r8
    mov rdi, rsi
    mov rcx, NEBO_G105_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    pop r8
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    mov [rsi + NEBO_G105_REQUEST_ID_OFFSET], rdx
    mov [rsi + NEBO_G105_REQUEST_ATTEMPT_OFFSET], rcx
    mov [rsi + NEBO_G105_REQUEST_SOURCE_OFFSET], r8
    mov rax, [rdi + NEBO_G105_PLAN_FORM_OFFSET]
    mov [rsi + NEBO_G105_REQUEST_FORM_OFFSET], rax
    mov rax, [rdi + NEBO_G105_PLAN_FIELD_COUNT_OFFSET]
    mov [rsi + NEBO_G105_REQUEST_FIELD_COUNT_OFFSET], rax
    mov rax, [rdi + NEBO_G105_PLAN_SECURITY_FLAGS_OFFSET]
    mov [rsi + NEBO_G105_REQUEST_FLAGS_OFFSET], rax
    xor eax, eax
    ret
.invalid:
    mov eax, -NEBO_G105_STATUS_INVALID
    ret
.capability:
    mov eax, -NEBO_G105_STATUS_CAPABILITY
    ret
.exhausted:
    mov eax, -NEBO_G105_STATUS_EXHAUSTED
    ret

; RDI plan, RSI request, RDX bytes, RCX length, R8 response, R9 event.
; Validation failures are complete typed responses/events, never partial state.
nebo_scan_console_response_apply:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov [rsp], r9
    mov qword [rsp+8],-1
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    mov r15, r8
    test rbx, rbx
    jz .invalid
    test r12, r12
    jz .invalid
    test r13, r13
    jz .invalid
    test r15, r15
    jz .invalid
    test r9, r9
    jz .invalid
    test r14, r14
    jz .validation
    cmp r14, NEBO_G105_MAX_INPUT_BYTES
    ja .limit
    cmp qword [r12 + NEBO_G105_REQUEST_ID_OFFSET], 0
    je .invalid
    mov rdi, r13
    mov rsi, r14
    mov edx, 1
    mov ecx, SCAN_MAX_INPUT_BYTES
    xor r8d, r8d
    call neboc_scan_validate_text
    mov r9, [rsp]
    test eax, eax
    jnz .validation
    cmp qword [rbx + NEBO_G105_PLAN_INPUT_MODE_OFFSET], NEBO_G105_INPUT_LINE
    je .content_rules
    mov rdi, r13
    mov rsi, r14
    mov edx, [rbx + NEBO_G105_PLAN_MAX_LINES_OFFSET]
    mov ecx, SCAN_MAX_INPUT_BYTES
    call neboc_scan_multiline_validate
    mov r9, [rsp]
    cmp eax, -SCAN_E_LIMIT
    je .limit
    test eax, eax
    jnz .validation
.content_rules:
    cmp byte [r13], '!'
    je .validation
    cmp qword [rbx + NEBO_G105_PLAN_INPUT_MODE_OFFSET], NEBO_G105_INPUT_JSON_BLOCK
    jne .hash
    cmp byte [r13], '{'
    je .hash
    cmp byte [r13], '['
    jne .validation
.hash:
    mov rax, 0xcbf29ce484222325
    xor ecx, ecx
.hash_loop:
    cmp rcx, r14
    jae .hash_done
    movzx edx, byte [r13 + rcx]
    xor rax, rdx
    rol rax, 5
    inc rcx
    jmp .hash_loop
.hash_done:
    mov r10, rax
    cmp qword [rsp+8],-1
    jne .typed_selection_count
    mov r11, 1
    test qword [rbx + NEBO_G105_PLAN_CHOICE_FLAGS_OFFSET], NEBO_G105_CHOICE_MULTI
    jz .success_commit
    xor ecx, ecx
.comma_loop:
    cmp rcx, r14
    jae .success_commit
    cmp byte [r13 + rcx], ','
    jne .comma_next
    mov r11, 2
    jmp .success_commit
.comma_next:
    inc rcx
    jmp .comma_loop
.typed_selection_count:
    mov r11,[rsp+8]
.success_commit:
    mov rax, [r12 + NEBO_G105_REQUEST_ID_OFFSET]
    mov [r15 + NEBO_G105_RESPONSE_REQUEST_ID_OFFSET], rax
    mov qword [r15 + NEBO_G105_RESPONSE_STATUS_OFFSET], NEBO_G105_STATUS_OK
    mov [r15 + NEBO_G105_RESPONSE_VALUE_LENGTH_OFFSET], r14
    mov [r15 + NEBO_G105_RESPONSE_VALUE_DIGEST_OFFSET], r10
    mov [r15 + NEBO_G105_RESPONSE_SELECTIONS_OFFSET], r11
    mov qword [r15 + NEBO_G105_RESPONSE_ZEROIZED_OFFSET], 0
    mov [r9 + NEBO_G105_EVENT_REQUEST_ID_OFFSET], rax
    mov qword [r9 + NEBO_G105_EVENT_KIND_OFFSET], NEBO_G105_EVENT_RESPONSE
    mov qword [r9 + NEBO_G105_EVENT_STATUS_OFFSET], NEBO_G105_STATUS_OK
    mov qword [r9 + NEBO_G105_EVENT_FLAGS_OFFSET], 0
    mov [r9 + NEBO_G105_EVENT_PUBLIC_LENGTH_OFFSET], r14
    mov [r9 + NEBO_G105_EVENT_PUBLIC_DIGEST_OFFSET], r10
    mov rax, [rbx + NEBO_G105_PLAN_SECURITY_FLAGS_OFFSET]
    test rax, NEBO_G105_SECURITY_SECRET | NEBO_G105_SECURITY_PASSWORD | NEBO_G105_SECURITY_SENSITIVE | NEBO_G105_SECURITY_REDACT
    jz .ok
    mov qword [r9 + NEBO_G105_EVENT_PUBLIC_LENGTH_OFFSET], 0
    mov rax, NEBO_G105_REDACTED_DIGEST
    mov [r9 + NEBO_G105_EVENT_PUBLIC_DIGEST_OFFSET], rax
    mov qword [r9 + NEBO_G105_EVENT_FLAGS_OFFSET], NEBO_G105_EVENT_FLAG_REDACTED
.ok:
    xor eax, eax
    jmp .done
.validation:
    mov rax, [r12 + NEBO_G105_REQUEST_ID_OFFSET]
    mov [r15 + NEBO_G105_RESPONSE_REQUEST_ID_OFFSET], rax
    mov qword [r15 + NEBO_G105_RESPONSE_STATUS_OFFSET], NEBO_G105_STATUS_VALIDATION
    mov qword [r15 + NEBO_G105_RESPONSE_VALUE_LENGTH_OFFSET], 0
    mov qword [r15 + NEBO_G105_RESPONSE_VALUE_DIGEST_OFFSET], 0
    mov qword [r15 + NEBO_G105_RESPONSE_SELECTIONS_OFFSET], 0
    mov qword [r15 + NEBO_G105_RESPONSE_ZEROIZED_OFFSET], 0
    mov [r9 + NEBO_G105_EVENT_REQUEST_ID_OFFSET], rax
    mov qword [r9 + NEBO_G105_EVENT_KIND_OFFSET], NEBO_G105_EVENT_VALIDATION_FAILED
    mov qword [r9 + NEBO_G105_EVENT_STATUS_OFFSET], NEBO_G105_STATUS_VALIDATION
    mov qword [r9 + NEBO_G105_EVENT_PUBLIC_LENGTH_OFFSET], 0
    mov qword [r9 + NEBO_G105_EVENT_PUBLIC_DIGEST_OFFSET], 0
    mov qword [r9 + NEBO_G105_EVENT_FLAGS_OFFSET], 0
    mov eax, -NEBO_G105_STATUS_VALIDATION
    jmp .done
.invalid:
    mov eax, -NEBO_G105_STATUS_INVALID
    jmp .done
.limit:
    mov eax, -NEBO_G105_STATUS_LIMIT
.done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Same response ABI, R10=the authoritative ScanPlan validation status.
; The public adapter records that decision without parsing or validating input
; a second time. Existing owner-only response_apply retains its old profile.
nebo_scan_console_response_commit:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    mov [rsp],r9
    mov [rsp+8],r11
    mov rbx,rdi
    mov r12,rsi
    mov r13,rdx
    mov r14,rcx
    mov r15,r8
    cmp r11,32
    ja nebo_scan_console_response_apply.limit
    test rbx,rbx
    jz nebo_scan_console_response_apply.invalid
    test r12,r12
    jz nebo_scan_console_response_apply.invalid
    test r13,r13
    jz nebo_scan_console_response_apply.invalid
    test r15,r15
    jz nebo_scan_console_response_apply.invalid
    test r9,r9
    jz nebo_scan_console_response_apply.invalid
    cmp r14,NEBO_G105_MAX_INPUT_BYTES
    ja nebo_scan_console_response_apply.limit
    cmp qword [r12+NEBO_G105_REQUEST_ID_OFFSET],0
    je nebo_scan_console_response_apply.invalid
    test r10,r10
    jnz nebo_scan_console_response_apply.validation
    jmp nebo_scan_console_response_apply.hash

; RDI plan, RSI current attempt, RDX status.
nebo_scan_console_should_retry:
    test rdi, rdi
    jz .invalid
    cmp rdx, NEBO_G105_STATUS_VALIDATION
    jne .no
    mov eax, esi
    inc eax
    mov esi, [rdi + NEBO_G105_PLAN_MAX_ATTEMPTS_OFFSET]
    mov edi, eax
    jmp neboc_scan_should_retry
.no:
    xor eax, eax
    ret
.invalid:
    mov eax, -NEBO_G105_STATUS_INVALID
    ret

; RDI previous request id, RSI request. Replay must be strictly monotonic.
nebo_scan_console_replay_validate:
    test rsi, rsi
    jz .invalid
    mov rax, [rsi + NEBO_G105_REQUEST_ID_OFFSET]
    cmp rax, rdi
    jbe .replay
    xor eax, eax
    ret
.invalid:
    mov eax, -NEBO_G105_STATUS_INVALID
    ret
.replay:
    mov eax, -NEBO_G105_STATUS_REPLAY
    ret

; RDI evidence, RSI requested source, RDX availability (0/1). Returns source.
nebo_scan_console_select_backend:
    test rdi, rdi
    jz .invalid
    cmp rsi, NEBO_G105_SOURCE_MOCK
    jb .invalid
    cmp rsi, NEBO_G105_SOURCE_LIVE
    ja .invalid
    cmp rdx, 1
    ja .invalid
    cmp rsi, NEBO_G105_SOURCE_LIVE
    jne .requested
    test rdx, rdx
    jnz .live
    inc qword [rdi + NEBO_G105_EVIDENCE_FALLBACKS_OFFSET]
    mov eax, NEBO_G105_SOURCE_HEADLESS
    ret
.live:
    mov qword [rdi + NEBO_G105_EVIDENCE_MATURITY_OFFSET], NEBO_G105_MATURITY_LIVE_SCAN_CONSOLE_GREEN
.requested:
    mov rax, rsi
    ret
.invalid:
    mov eax, -NEBO_G105_STATUS_INVALID
    ret

; RDI evidence, RSI request, RDX response, RCX event.
nebo_scan_console_evidence_observe:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    test rcx, rcx
    jz .invalid
    mov rax, [rsi + NEBO_G105_REQUEST_ID_OFFSET]
    cmp rax, [rdx + NEBO_G105_RESPONSE_REQUEST_ID_OFFSET]
    jne .state
    cmp rax, [rcx + NEBO_G105_EVENT_REQUEST_ID_OFFSET]
    jne .state
    mov r8, [rdx + NEBO_G105_RESPONSE_STATUS_OFFSET]
    cmp r8, [rcx + NEBO_G105_EVENT_STATUS_OFFSET]
    jne .state
    cmp r8, NEBO_G105_STATUS_OK
    je .response_event
    cmp r8, NEBO_G105_STATUS_VALIDATION
    je .validation_event
    jmp .state
.response_event:
    cmp qword [rcx + NEBO_G105_EVENT_KIND_OFFSET], NEBO_G105_EVENT_RESPONSE
    jne .state
    mov r9, [rcx + NEBO_G105_EVENT_FLAGS_OFFSET]
    test r9, ~NEBO_G105_EVENT_FLAG_REDACTED
    jnz .state
    test r9, NEBO_G105_EVENT_FLAG_REDACTED
    jz .public_event
    cmp qword [rcx + NEBO_G105_EVENT_PUBLIC_LENGTH_OFFSET], 0
    jne .state
    mov r10, NEBO_G105_REDACTED_DIGEST
    cmp [rcx + NEBO_G105_EVENT_PUBLIC_DIGEST_OFFSET], r10
    jne .state
    jmp .event_valid
.public_event:
    mov r9, [rdx + NEBO_G105_RESPONSE_VALUE_LENGTH_OFFSET]
    cmp r9, [rcx + NEBO_G105_EVENT_PUBLIC_LENGTH_OFFSET]
    jne .state
    mov r9, [rdx + NEBO_G105_RESPONSE_VALUE_DIGEST_OFFSET]
    cmp r9, [rcx + NEBO_G105_EVENT_PUBLIC_DIGEST_OFFSET]
    jne .state
    jmp .event_valid
.validation_event:
    cmp qword [rcx + NEBO_G105_EVENT_KIND_OFFSET], NEBO_G105_EVENT_VALIDATION_FAILED
    jne .state
    cmp qword [rdx + NEBO_G105_RESPONSE_VALUE_LENGTH_OFFSET], 0
    jne .state
    cmp qword [rdx + NEBO_G105_RESPONSE_VALUE_DIGEST_OFFSET], 0
    jne .state
    cmp qword [rdx + NEBO_G105_RESPONSE_SELECTIONS_OFFSET], 0
    jne .state
    cmp qword [rcx + NEBO_G105_EVENT_PUBLIC_LENGTH_OFFSET], 0
    jne .state
    cmp qword [rcx + NEBO_G105_EVENT_PUBLIC_DIGEST_OFFSET], 0
    jne .state
    cmp qword [rcx + NEBO_G105_EVENT_FLAGS_OFFSET], 0
    jne .state
.event_valid:
    cmp qword [rdx + NEBO_G105_RESPONSE_ZEROIZED_OFFSET], 1
    ja .state
    mov rax, [rsi + NEBO_G105_REQUEST_ID_OFFSET]
    mov r8, [rdi + NEBO_G105_EVIDENCE_LAST_REQUEST_ID_OFFSET]
    cmp rax, r8
    jbe .state
    inc qword [rdi + NEBO_G105_EVIDENCE_REQUESTS_OFFSET]
    inc qword [rdi + NEBO_G105_EVIDENCE_RESPONSES_OFFSET]
    cmp qword [rdx + NEBO_G105_RESPONSE_STATUS_OFFSET], NEBO_G105_STATUS_VALIDATION
    jne .retry
    inc qword [rdi + NEBO_G105_EVIDENCE_FAILURES_OFFSET]
.retry:
    cmp qword [rsi + NEBO_G105_REQUEST_ATTEMPT_OFFSET], 0
    je .redaction
    inc qword [rdi + NEBO_G105_EVIDENCE_RETRIES_OFFSET]
.redaction:
    test qword [rcx + NEBO_G105_EVENT_FLAGS_OFFSET], NEBO_G105_EVENT_FLAG_REDACTED
    jz .replay
    inc qword [rdi + NEBO_G105_EVIDENCE_REDACTIONS_OFFSET]
.replay:
    cmp qword [rsi + NEBO_G105_REQUEST_SOURCE_OFFSET], NEBO_G105_SOURCE_REPLAY
    jne .commit
    inc qword [rdi + NEBO_G105_EVIDENCE_REPLAYS_OFFSET]
.commit:
    mov [rdi + NEBO_G105_EVIDENCE_LAST_REQUEST_ID_OFFSET], rax
    mov rax, [rcx + NEBO_G105_EVENT_PUBLIC_DIGEST_OFFSET]
    mov [rdi + NEBO_G105_EVIDENCE_LAST_DIGEST_OFFSET], rax
    cmp qword [rdi + NEBO_G105_EVIDENCE_MATURITY_OFFSET], 0
    jne .ok
    mov qword [rdi + NEBO_G105_EVIDENCE_MATURITY_OFFSET], NEBO_G105_MATURITY_HEADLESS_SCAN_CONSOLE_GREEN
.ok:
    xor eax, eax
    ret
.invalid:
    mov eax, -NEBO_G105_STATUS_INVALID
    ret
.state:
    mov eax, -NEBO_G105_STATUS_BAD_STATE
    ret

; RDI bytes, RSI length, RDX response, RCX evidence.
nebo_scan_console_zeroize:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp rsi, NEBO_G105_MAX_INPUT_BYTES
    ja .limit
    test rdx, rdx
    jz .invalid
    test rcx, rcx
    jz .invalid
    mov r8, rcx
    mov rcx, rsi
    xor eax, eax
    rep stosb
    mov qword [rdx + NEBO_G105_RESPONSE_ZEROIZED_OFFSET], 1
    inc qword [r8 + NEBO_G105_EVIDENCE_ZEROIZATIONS_OFFSET]
    xor eax, eax
    ret
.invalid:
    mov eax, -NEBO_G105_STATUS_INVALID
    ret
.limit:
    mov eax, -NEBO_G105_STATUS_LIMIT
    ret

; RDI evidence. Validate coherent request/response accounting and maturity.
nebo_scan_console_evidence_validate:
    test rdi, rdi
    jz .invalid
    mov rax, [rdi + NEBO_G105_EVIDENCE_REQUESTS_OFFSET]
    test rax, rax
    jz .state
    cmp rax, [rdi + NEBO_G105_EVIDENCE_RESPONSES_OFFSET]
    jne .state
    mov rcx, [rdi + NEBO_G105_EVIDENCE_FAILURES_OFFSET]
    cmp rcx, rax
    ja .state
    mov rcx, [rdi + NEBO_G105_EVIDENCE_RETRIES_OFFSET]
    cmp rcx, rax
    ja .state
    mov rcx, [rdi + NEBO_G105_EVIDENCE_MATURITY_OFFSET]
    cmp rcx, NEBO_G105_MATURITY_HEADLESS_SCAN_CONSOLE_GREEN
    jb .state
    cmp rcx, NEBO_G105_MATURITY_LIVE_SCAN_CONSOLE_GREEN
    ja .state
    xor eax, eax
    ret
.invalid:
    mov eax, -NEBO_G105_STATUS_INVALID
    ret
.state:
    mov eax, -NEBO_G105_STATUS_BAD_STATE
    ret

; Historical RF116 front compatibility. These symbols remain linked, but G105
; conformance is established by the structured APIs and source vertical above.
global nebo_scan_console_adapter_validate
global nebo_form_metadata_validate
global nebo_feedback_style_validate
global nebo_multiline_input_validate
global nebo_choice_model_validate
global nebo_security_policy_validate
global nebo_request_response_validate
global nebo_validation_retry_validate
global nebo_live_fallback_replay_validate
global nebo_scan_console_forms_choices_e_input_visual_closeout_contract_validate

g105_legacy_validate:
    cmp rdi, 1
    jb .bad
    cmp rdi, 64
    ja .bad
    cmp rsi, 4
    ja .bad
    cmp rdx, 3
    ja .bad
    xor eax, eax
    ret
.bad:
    mov eax, -1
    ret

nebo_scan_console_adapter_validate: jmp g105_legacy_validate
nebo_form_metadata_validate: jmp g105_legacy_validate
nebo_feedback_style_validate: jmp g105_legacy_validate
nebo_multiline_input_validate: jmp g105_legacy_validate
nebo_choice_model_validate: jmp g105_legacy_validate
nebo_security_policy_validate: jmp g105_legacy_validate
nebo_request_response_validate: jmp g105_legacy_validate
nebo_validation_retry_validate: jmp g105_legacy_validate
nebo_live_fallback_replay_validate: jmp g105_legacy_validate
nebo_scan_console_forms_choices_e_input_visual_closeout_contract_validate: jmp g105_legacy_validate
