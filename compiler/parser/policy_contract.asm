; Nebo Assembly — EFFECTS-CAPABILITIES-E-POLITICAS-PF002 bounded Policy syntax/API contract
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/policy_contract.inc"
%include "compiler/semantic/effect/effect_policy.inc"

section .rodata
kw_start: db 'start'
kw_start_len equ $-kw_start
kw_policy: db 'Policy'
kw_policy_len equ $-kw_policy
kw_effects: db 'effects'
kw_effects_len equ $-kw_effects
kw_capabilities: db 'capabilities'
kw_capabilities_len equ $-kw_capabilities
kw_allow: db 'allow'
kw_allow_len equ $-kw_allow
kw_deny: db 'deny'
kw_deny_len equ $-kw_deny
kw_budget: db 'budget'
kw_budget_len equ $-kw_budget
kw_trust: db 'trust'
kw_trust_len equ $-kw_trust
kw_audit: db 'audit'
kw_audit_len equ $-kw_audit
kw_permit: db 'permit'
kw_permit_len equ $-kw_permit

atom_console_write: db 'console_write'
atom_console_write_len equ $-atom_console_write
atom_console_read: db 'console_read'
atom_console_read_len equ $-atom_console_read
atom_fs_read: db 'fs_read'
atom_fs_read_len equ $-atom_fs_read
atom_fs_write: db 'fs_write'
atom_fs_write_len equ $-atom_fs_write
atom_net_http: db 'net_http'
atom_net_http_len equ $-atom_net_http
atom_time_read: db 'time_read'
atom_time_read_len equ $-atom_time_read
atom_random_read: db 'random_read'
atom_random_read_len equ $-atom_random_read
atom_process_spawn: db 'process_spawn'
atom_process_spawn_len equ $-atom_process_spawn
atom_gpu_compute: db 'gpu_compute'
atom_gpu_compute_len equ $-atom_gpu_compute
atom_distributed_send: db 'distributed_send'
atom_distributed_send_len equ $-atom_distributed_send
atom_unsafe: db 'unsafe'
atom_unsafe_len equ $-atom_unsafe

atom_public: db 'public'
atom_public_len equ $-atom_public
atom_internal: db 'internal'
atom_internal_len equ $-atom_internal
atom_restricted: db 'restricted'
atom_restricted_len equ $-atom_restricted
atom_secret: db 'secret'
atom_secret_len equ $-atom_secret

section .text

; rdi = aligned pointer to neboc_effects_capabilities_e_politicas_PARSE_REQUEST_SIZE
; eax = NEBOC_STATUS_*; on source failure q3/q4/q5 identify the first cause.
NEBOC_ABI_FUNCTION neboc_policy_parse
    test rdi, rdi
    jz .invalid_argument
    test rdi, neboc_effects_capabilities_e_politicas_PARSE_ALIGNMENT - 1
    jnz .invalid_argument
    cmp qword [rdi + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_OFFSET], 0
    je .invalid_argument
    cmp qword [rdi + neboc_effects_capabilities_e_politicas_PARSE_OUTPUT_OFFSET], 0
    je .invalid_argument
    mov rax, [rdi + neboc_effects_capabilities_e_politicas_PARSE_OUTPUT_OFFSET]
    test rax, NEBOC_POLICY_ALIGNMENT - 1
    jnz .invalid_argument
    cmp qword [rdi + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_LENGTH_OFFSET], 0
    je .invalid_argument
    cmp qword [rdi + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_LENGTH_OFFSET], neboc_effects_capabilities_e_politicas_PARSE_MAX_SOURCE_BYTES
    ja .limit_exceeded

    ; The request, source and output spans are an explicitly disjoint ABI.
    ; Reject overlap before clearing output so failure is transactional.
    mov r8, rdi
    add r8, neboc_effects_capabilities_e_politicas_PARSE_REQUEST_SIZE
    jc .invalid_argument
    mov r9, [rdi + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_OFFSET]
    mov r10, r9
    add r10, [rdi + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_LENGTH_OFFSET]
    jc .invalid_argument
    mov r11, [rdi + neboc_effects_capabilities_e_politicas_PARSE_OUTPUT_OFFSET]
    mov rax, r11
    add rax, NEBOC_POLICY_REQUEST_SIZE
    jc .invalid_argument
    cmp r10, rdi
    jbe .source_request_disjoint
    cmp r9, r8
    jb .invalid_argument
.source_request_disjoint:
    cmp rax, rdi
    jbe .output_request_disjoint
    cmp r11, r8
    jb .invalid_argument
.output_request_disjoint:
    cmp r10, r11
    jbe .source_output_disjoint
    cmp r9, rax
    jb .invalid_argument
.source_output_disjoint:

    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, [r12 + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_OFFSET]
    mov r14, r13
    add r14, [r12 + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_LENGTH_OFFSET]
    mov r15, r13
    mov rbx, [r12 + neboc_effects_capabilities_e_politicas_PARSE_OUTPUT_OFFSET]

    mov qword [r12 + neboc_effects_capabilities_e_politicas_PARSE_ERROR_OFFSET_OFFSET], 0
    mov qword [r12 + neboc_effects_capabilities_e_politicas_PARSE_DIAGNOSTIC_OFFSET], 0
    mov qword [r12 + neboc_effects_capabilities_e_politicas_PARSE_CONSUMED_OFFSET], 0
    mov qword [r12 + neboc_effects_capabilities_e_politicas_PARSE_CANONICAL_HASH_OFFSET], 0
    mov qword [r12 + NEBOC_PARSE_CLAUSE_MASK_OFFSET], 0
    mov rdi, rbx
    mov ecx, NEBOC_POLICY_REQUEST_QWORDS
    xor eax, eax
    rep stosq

    lea rsi, [rel kw_start]
    mov ecx, kw_start_len
    call match_literal
    jc .parse_failure
    mov edi, '('
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure
    mov edi, ')'
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure
    mov edi, '{'
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure
    lea rsi, [rel kw_policy]
    mov ecx, kw_policy_len
    call match_literal
    jc .parse_failure
    mov edi, '('
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure

    ; effects(...)
    lea rsi, [rel kw_effects]
    mov ecx, kw_effects_len
    call match_literal
    jc .parse_failure
    mov edi, '('
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure
    call parse_effect_set
    jc .set_failure
    mov [rbx + NEBOC_POLICY_DIRECT_EFFECTS_OFFSET], rax
    mov [rbx + NEBOC_POLICY_DECLARED_EFFECTS_OFFSET], rax
    or qword [r12 + NEBOC_PARSE_CLAUSE_MASK_OFFSET], NEBOC_PARSE_CLAUSE_EFFECTS
    mov edi, ','
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure

    ; capabilities(...)
    lea rsi, [rel kw_capabilities]
    mov ecx, kw_capabilities_len
    call match_literal
    jc .parse_failure
    mov edi, '('
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure
    call parse_effect_set
    jc .set_failure
    mov [rbx + NEBOC_POLICY_CAPABILITIES_OFFSET], rax
    or qword [r12 + NEBOC_PARSE_CLAUSE_MASK_OFFSET], NEBOC_PARSE_CLAUSE_CAPABILITIES
    mov edi, ','
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure

    ; allow(...)
    lea rsi, [rel kw_allow]
    mov ecx, kw_allow_len
    call match_literal
    jc .parse_failure
    mov edi, '('
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure
    call parse_effect_set
    jc .set_failure
    mov [rbx + NEBOC_POLICY_ALLOW_OFFSET], rax
    or qword [r12 + NEBOC_PARSE_CLAUSE_MASK_OFFSET], NEBOC_PARSE_CLAUSE_ALLOW
    mov edi, ','
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure

    ; deny(...)
    lea rsi, [rel kw_deny]
    mov ecx, kw_deny_len
    call match_literal
    jc .parse_failure
    mov edi, '('
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure
    call parse_effect_set
    jc .set_failure
    mov [rbx + NEBOC_POLICY_DENY_OFFSET], rax
    or qword [r12 + NEBOC_PARSE_CLAUSE_MASK_OFFSET], NEBOC_PARSE_CLAUSE_DENY
    mov edi, ','
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure

    ; budget(unsigned-16)
    lea rsi, [rel kw_budget]
    mov ecx, kw_budget_len
    call match_literal
    jc .parse_failure
    mov edi, '('
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure
    call parse_u64
    jc .numeric_failure
    cmp rax, NEBOC_POLICY_MAX_BUDGET
    ja .numeric_type_failure
    mov [rbx + NEBOC_POLICY_BUDGET_OFFSET], rax
    call expect_value_close
    jc .set_failure
    or qword [r12 + NEBOC_PARSE_CLAUSE_MASK_OFFSET], NEBOC_PARSE_CLAUSE_BUDGET
    mov edi, ','
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure

    ; trust(public|internal|restricted|secret)
    lea rsi, [rel kw_trust]
    mov ecx, kw_trust_len
    call match_literal
    jc .parse_failure
    mov edi, '('
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure
    call parse_trust
    jc .lex_failure
    mov [rbx + NEBOC_POLICY_TRUST_OFFSET], rax
    call expect_value_close
    jc .set_failure
    or qword [r12 + NEBOC_PARSE_CLAUSE_MASK_OFFSET], NEBOC_PARSE_CLAUSE_TRUST
    mov edi, ','
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure

    ; audit(unsigned-64)
    lea rsi, [rel kw_audit]
    mov ecx, kw_audit_len
    call match_literal
    jc .parse_failure
    mov edi, '('
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure
    call parse_u64
    jc .numeric_failure
    mov [rbx + NEBOC_POLICY_AUDIT_ID_OFFSET], rax
    call expect_value_close
    jc .set_failure
    or qword [r12 + NEBOC_PARSE_CLAUSE_MASK_OFFSET], NEBOC_PARSE_CLAUSE_AUDIT

    mov edi, ')'
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure
    mov edi, '.'
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure
    lea rsi, [rel kw_permit]
    mov ecx, kw_permit_len
    call match_literal
    jc .parse_failure
    mov edi, '('
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure
    call parse_u64
    jc .numeric_failure
    cmp rax, NEBOC_POLICY_MAX_PERMIT
    ja .numeric_type_failure
    mov [rbx + NEBOC_POLICY_PERMIT_OFFSET], rax
    call expect_value_close
    jc .set_failure
    mov edi, ';'
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure
    mov edi, '}'
    call effects_capabilities_e_politicas_expect_char
    jc .parse_failure
    call effects_capabilities_e_politicas_skip_ws
    cmp r15, r14
    jne .parse_failure

    mov rax, r15
    sub rax, r13
    mov [r12 + neboc_effects_capabilities_e_politicas_PARSE_CONSUMED_OFFSET], rax

    ; Canonical FNV-1a64 over parsed q0..q9, independent of whitespace.
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.hash_loop:
    cmp rcx, NEBOC_PARSE_HASHED_OUTPUT_BYTES
    jae .hash_done
    movzx edx, byte [rbx + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .hash_loop
.hash_done:
    mov [r12 + neboc_effects_capabilities_e_politicas_PARSE_CANONICAL_HASH_OFFSET], rax
    xor eax, eax
    jmp .done

.set_failure:
    mov [r12 + neboc_effects_capabilities_e_politicas_PARSE_DIAGNOSTIC_OFFSET], rdx
    jmp .source_failure
.numeric_failure:
    mov qword [r12 + neboc_effects_capabilities_e_politicas_PARSE_DIAGNOSTIC_OFFSET], neboc_effects_capabilities_e_politicas_DIAG_LEX_driver_cli_linux_x86_64
    jmp .source_failure
.lex_failure:
    mov qword [r12 + neboc_effects_capabilities_e_politicas_PARSE_DIAGNOSTIC_OFFSET], neboc_effects_capabilities_e_politicas_DIAG_LEX_driver_cli_linux_x86_64
    jmp .source_failure
.parse_failure:
    mov qword [r12 + neboc_effects_capabilities_e_politicas_PARSE_DIAGNOSTIC_OFFSET], neboc_effects_capabilities_e_politicas_DIAG_PARSE_driver_cli_linux_x86_64
    jmp .source_failure
.numeric_type_failure:
    mov r15, r11
.type_failure:
    mov qword [r12 + neboc_effects_capabilities_e_politicas_PARSE_DIAGNOSTIC_OFFSET], neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
.source_failure:
    mov rax, r15
    sub rax, r13
    mov [r12 + neboc_effects_capabilities_e_politicas_PARSE_ERROR_OFFSET_OFFSET], rax
    mov [r12 + neboc_effects_capabilities_e_politicas_PARSE_CONSUMED_OFFSET], rax
    mov qword [r12 + neboc_effects_capabilities_e_politicas_PARSE_CANONICAL_HASH_OFFSET], 0
    mov rdi, rbx
    mov ecx, NEBOC_POLICY_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    jmp .done

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.limit_exceeded:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; Global parse cursor: r15, end: r14.  Whitespace is ASCII SP/HT/LF/CR.
effects_capabilities_e_politicas_skip_ws:
.loop:
    cmp r15, r14
    jae .done
    movzx eax, byte [r15]
    cmp al, ' '
    je .take
    cmp al, 9
    je .take
    cmp al, 10
    je .take
    cmp al, 13
    jne .done
.take:
    inc r15
    jmp .loop
.done:
    ret

; rsi=literal, ecx=length; advances cursor after optional whitespace.
match_literal:
    sub rsp, 8
    call effects_capabilities_e_politicas_skip_ws
    mov rax, r14
    sub rax, r15
    mov r9d, ecx
    cmp rax, r9
    jb .fail
    xor edx, edx
.loop:
    cmp edx, r9d
    jae .match
    mov al, [r15 + rdx]
    cmp al, [rsi + rdx]
    jne .fail
    inc edx
    jmp .loop
.match:
    add r15, r9
    lea rsp, [rsp + 8]
    clc
    ret
.fail:
    lea rsp, [rsp + 8]
    stc
    ret

; dil=character; advances cursor after optional whitespace.
effects_capabilities_e_politicas_expect_char:
    sub rsp, 8
    mov r9b, dil
    call effects_capabilities_e_politicas_skip_ws
    cmp r15, r14
    jae .fail
    cmp byte [r15], r9b
    jne .fail
    inc r15
    lea rsp, [rsp + 8]
    clc
    ret
.fail:
    lea rsp, [rsp + 8]
    stc
    ret

; Consumes ')' after a numeric or identifier value.  An identifier-like
; suffix is lexical; a structural delimiter mismatch is syntactic.
; Success CF=0. Failure rdx=LEX/PARSE diagnostic and CF=1.
expect_value_close:
    sub rsp, 8
    call effects_capabilities_e_politicas_skip_ws
    cmp r15, r14
    jae .parse_fail
    cmp byte [r15], ')'
    je .match
    movzx eax, byte [r15]
    cmp al, ','
    je .parse_fail
    cmp al, ';'
    je .parse_fail
    cmp al, '}'
    je .parse_fail
    cmp al, ']'
    je .parse_fail
    cmp al, '['
    je .parse_fail
    cmp al, '('
    je .parse_fail
    cmp al, '{'
    je .parse_fail
    mov edx, neboc_effects_capabilities_e_politicas_DIAG_LEX_driver_cli_linux_x86_64
    jmp .fail
.match:
    inc r15
    lea rsp, [rsp + 8]
    clc
    ret
.parse_fail:
    mov edx, neboc_effects_capabilities_e_politicas_DIAG_PARSE_driver_cli_linux_x86_64
.fail:
    lea rsp, [rsp + 8]
    stc
    ret

; Parses an effect list after its opening parenthesis and consumes ')'.
; Success rax=mask CF=0. Failure rdx=LEX/PARSE/TYPE diagnostic CF=1.
parse_effect_set:
    sub rsp, 8
    xor r10d, r10d
    call effects_capabilities_e_politicas_skip_ws
    cmp r15, r14
    jae .parse_fail
    cmp byte [r15], ')'
    jne .item
    inc r15
    xor eax, eax
    lea rsp, [rsp + 8]
    clc
    ret
.item:
    call effects_capabilities_e_politicas_skip_ws
    cmp r15, r14
    jae .parse_fail
    movzx eax, byte [r15]
    cmp al, ','
    je .parse_fail
    cmp al, ')'
    je .parse_fail
    cmp al, '('
    je .parse_fail
    cmp al, '['
    je .parse_fail
    cmp al, ']'
    je .parse_fail
    cmp al, ';'
    je .parse_fail
    cmp al, '{'
    je .parse_fail
    cmp al, '}'
    je .parse_fail
    mov r8, r15
    cmp al, 'a'
    jb .lex_fail
    cmp al, 'z'
    ja .lex_fail
.scan:
    cmp r15, r14
    jae .scan_done
    movzx eax, byte [r15]
    cmp al, 'a'
    jb .maybe_underscore
    cmp al, 'z'
    jbe .scan_take
.maybe_underscore:
    cmp al, '_'
    je .scan_take
    cmp al, '0'
    jb .scan_done
    cmp al, '9'
    ja .scan_done
.scan_take:
    inc r15
    jmp .scan
.scan_done:
    mov rcx, r15
    sub rcx, r8
    mov rdi, r8
    call effect_from_span
    cmp rax, -1
    je .lex_fail
    test r10, rax
    jnz .type_fail
    or r10, rax
    call effects_capabilities_e_politicas_skip_ws
    cmp r15, r14
    jae .parse_fail
    movzx eax, byte [r15]
    cmp al, ')'
    je .finish
    cmp al, ','
    jne .bad_separator
    inc r15
    call effects_capabilities_e_politicas_skip_ws
    cmp r15, r14
    jae .parse_fail
    cmp byte [r15], ')'
    je .parse_fail
    jmp .item
.bad_separator:
    cmp al, '.'
    je .lex_fail
    jmp .parse_fail
.finish:
    inc r15
    mov rax, r10
    lea rsp, [rsp + 8]
    clc
    ret
.lex_fail:
    mov r15, r8
    mov edx, neboc_effects_capabilities_e_politicas_DIAG_LEX_driver_cli_linux_x86_64
    lea rsp, [rsp + 8]
    stc
    ret
.type_fail:
    mov r15, r8
    mov edx, neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    lea rsp, [rsp + 8]
    stc
    ret
.parse_fail:
    mov edx, neboc_effects_capabilities_e_politicas_DIAG_PARSE_driver_cli_linux_x86_64
    lea rsp, [rsp + 8]
    stc
    ret

; Parses a non-empty unsigned decimal qword. CF denotes lexical/overflow fail.
parse_u64:
    sub rsp, 8
    call effects_capabilities_e_politicas_skip_ws
    mov r11, r15
    xor eax, eax
    xor r8d, r8d
.loop:
    cmp r15, r14
    jae .done
    movzx r9d, byte [r15]
    cmp r9b, '0'
    jb .done
    cmp r9b, '9'
    ja .done
    sub r9d, '0'
    mov ecx, 10
    mul rcx
    test rdx, rdx
    jnz .fail
    add rax, r9
    jc .fail
    inc r15
    inc r8
    jmp .loop
.done:
    test r8, r8
    jz .fail
    lea rsp, [rsp + 8]
    clc
    ret
.fail:
    lea rsp, [rsp + 8]
    stc
    ret

; Parses one trust identifier. Success rax=trust; unknown spelling CF=1.
parse_trust:
    sub rsp, 8
    call effects_capabilities_e_politicas_skip_ws
    mov r8, r15
    cmp r15, r14
    jae .fail
.scan:
    cmp r15, r14
    jae .scanned
    movzx eax, byte [r15]
    cmp al, 'a'
    jb .scanned
    cmp al, 'z'
    ja .scanned
    inc r15
    jmp .scan
.scanned:
    mov r9, r15
    sub r9, r8
    cmp r9, atom_public_len
    jne .internal
    mov rdi, r8
    lea rsi, [rel atom_public]
    mov edx, atom_public_len
    call effects_capabilities_e_politicas_span_equal
    test eax, eax
    jnz .public_match
.internal:
    cmp r9, atom_internal_len
    jne .restricted
    mov rdi, r8
    lea rsi, [rel atom_internal]
    mov edx, atom_internal_len
    call effects_capabilities_e_politicas_span_equal
    test eax, eax
    jnz .internal_match
.restricted:
    cmp r9, atom_restricted_len
    jne .secret
    mov rdi, r8
    lea rsi, [rel atom_restricted]
    mov edx, atom_restricted_len
    call effects_capabilities_e_politicas_span_equal
    test eax, eax
    jnz .restricted_match
.secret:
    cmp r9, atom_secret_len
    jne .fail
    mov rdi, r8
    lea rsi, [rel atom_secret]
    mov edx, atom_secret_len
    call effects_capabilities_e_politicas_span_equal
    test eax, eax
    jz .fail
    mov eax, NEBOC_TRUST_SECRET
    lea rsp, [rsp + 8]
    clc
    ret
.public_match:
    mov eax, NEBOC_TRUST_PUBLIC
    lea rsp, [rsp + 8]
    clc
    ret
.internal_match:
    mov eax, NEBOC_TRUST_INTERNAL
    lea rsp, [rsp + 8]
    clc
    ret
.restricted_match:
    mov eax, NEBOC_TRUST_RESTRICTED
    lea rsp, [rsp + 8]
    clc
    ret
.fail:
    mov r15, r8
    lea rsp, [rsp + 8]
    stc
    ret

; rdi=span, rcx=length. Returns effect bit or UINT64_MAX.
effect_from_span:
    sub rsp, 8
    mov r8, rdi
    mov r9, rcx
%macro EFFECT_CANDIDATE 3
    cmp r9, %2
    jne %%next
    mov rdi, r8
    lea rsi, [rel %1]
    mov edx, %2
    call effects_capabilities_e_politicas_span_equal
    test eax, eax
    jz %%next
    mov eax, %3
    lea rsp, [rsp + 8]
    ret
%%next:
%endmacro
    EFFECT_CANDIDATE atom_console_write, atom_console_write_len, NEBOC_EFFECT_CONSOLE_WRITE
    EFFECT_CANDIDATE atom_console_read, atom_console_read_len, NEBOC_EFFECT_CONSOLE_READ
    EFFECT_CANDIDATE atom_fs_read, atom_fs_read_len, NEBOC_EFFECT_FS_READ
    EFFECT_CANDIDATE atom_fs_write, atom_fs_write_len, NEBOC_EFFECT_FS_WRITE
    EFFECT_CANDIDATE atom_net_http, atom_net_http_len, NEBOC_EFFECT_NET_HTTP
    EFFECT_CANDIDATE atom_time_read, atom_time_read_len, NEBOC_EFFECT_TIME_READ
    EFFECT_CANDIDATE atom_random_read, atom_random_read_len, NEBOC_EFFECT_RANDOM_READ
    EFFECT_CANDIDATE atom_process_spawn, atom_process_spawn_len, NEBOC_EFFECT_PROCESS_SPAWN
    EFFECT_CANDIDATE atom_gpu_compute, atom_gpu_compute_len, NEBOC_EFFECT_GPU_COMPUTE
    EFFECT_CANDIDATE atom_distributed_send, atom_distributed_send_len, NEBOC_EFFECT_DISTRIBUTED_SEND
    EFFECT_CANDIDATE atom_unsafe, atom_unsafe_len, NEBOC_EFFECT_UNSAFE
    mov rax, -1
    lea rsp, [rsp + 8]
    ret

; rdi=span, rsi=literal, edx=length; eax=1 equal, 0 different.
effects_capabilities_e_politicas_span_equal:
    xor ecx, ecx
.loop:
    cmp ecx, edx
    jae .equal
    mov al, [rdi + rcx]
    cmp al, [rsi + rcx]
    jne .different
    inc ecx
    jmp .loop
.equal:
    mov eax, 1
    ret
.different:
    xor eax, eax
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
