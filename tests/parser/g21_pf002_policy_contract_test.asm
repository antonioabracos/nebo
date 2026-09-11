; EFFECTS-CAPABILITIES-E-POLITICAS-PF002 native Policy parser GOLDEN and diagnostic contract tests
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/catalog.inc"
%include "compiler/parser/policy_contract.inc"
%include "compiler/semantic/effect/effect_policy.inc"

extern neboc_policy_parse
extern neboc_policy_evaluate
extern neboc_diagnostic_catalog_lookup
extern neboc_host_process_exit

%macro SOURCE 2
%1: db %2
%1 %+ _len equ $-%1
%endmacro

section .rodata
SOURCE p_console, 'start(){Policy(effects(console_write),capabilities(console_write),allow(console_write),deny(),budget(1),trust(public),audit(21)).permit(21);}'
p_console_ws: db "start() {",10," Policy( effects(console_write), capabilities(console_write), allow(console_write), deny(), budget(1), trust(public), audit(21) ).permit(21);",10,"}",10
p_console_ws_len equ $-p_console_ws
SOURCE p_pure, 'start(){Policy(effects(),capabilities(),allow(),deny(),budget(0),trust(public),audit(0)).permit(22);}'
SOURCE p_fs_read, 'start(){Policy(effects(fs_read),capabilities(fs_read),allow(fs_read),deny(),budget(1),trust(internal),audit(2301)).permit(23);}'
SOURCE p_combined, 'start(){Policy(effects(console_write,console_read,time_read),capabilities(console_write,console_read,time_read),allow(console_write,console_read,time_read),deny(),budget(3),trust(public),audit(2401)).permit(24);}'
SOURCE p_restricted, 'start(){Policy(effects(fs_write,process_spawn),capabilities(fs_write,process_spawn),allow(fs_write,process_spawn),deny(),budget(2),trust(restricted),audit(2501)).permit(25);}'
SOURCE p_unsafe, 'start(){Policy(effects(unsafe),capabilities(unsafe),allow(unsafe),deny(),budget(1),trust(secret),audit(2601)).permit(26);}'
SOURCE p_distinct, 'start(){Policy(effects(net_http,random_read,gpu_compute,distributed_send),capabilities(console_read,fs_read),allow(fs_write,time_read),deny(unsafe),budget(65535),trust(internal),audit(18446744073709551615)).permit(255);}'
SOURCE p_permit_zero, 'start(){Policy(effects(),capabilities(),allow(),deny(),budget(0),trust(public),audit(0)).permit(0);}'

SOURCE n_unknown, 'start(){Policy(effects(console_print),capabilities(),allow(),deny(),budget(1),trust(public),audit(1)).permit(1);}'
SOURCE n_alias, 'start(){Policy(effects(console.write),capabilities(),allow(),deny(),budget(1),trust(public),audit(1)).permit(1);}'
SOURCE n_duplicate, 'start(){Policy(effects(console_write,console_write),capabilities(),allow(),deny(),budget(1),trust(public),audit(1)).permit(1);}'
SOURCE n_bad_number, 'start(){Policy(effects(),capabilities(),allow(),deny(),budget(-1),trust(public),audit(1)).permit(1);}'
SOURCE n_reordered, 'start(){Policy(effects(),allow(),capabilities(),deny(),budget(0),trust(public),audit(0)).permit(1);}'
SOURCE n_missing_audit, 'start(){Policy(effects(),capabilities(),allow(),deny(),budget(0),trust(public)).permit(1);}'
SOURCE n_missing_comma, 'start(){Policy(effects() capabilities(),allow(),deny(),budget(0),trust(public),audit(0)).permit(1);}'
SOURCE n_trailing, 'start(){Policy(effects(),capabilities(),allow(),deny(),budget(0),trust(public),audit(0)).permit(1);}x'
SOURCE n_budget, 'start(){Policy(effects(),capabilities(),allow(),deny(),budget(65536),trust(public),audit(0)).permit(1);}'
SOURCE n_permit, 'start(){Policy(effects(),capabilities(),allow(),deny(),budget(0),trust(public),audit(0)).permit(256);}'
SOURCE n_audit_overflow, 'start(){Policy(effects(),capabilities(),allow(),deny(),budget(0),trust(public),audit(18446744073709551616)).permit(1);}'
SOURCE n_semicolon, 'start(){Policy(effects(),capabilities(),allow(),deny(),budget(0),trust(public),audit(0)).permit(1)}'
SOURCE n_budget_suffix, 'start(){Policy(effects(),capabilities(),allow(),deny(),budget(1x),trust(public),audit(0)).permit(1);}'
SOURCE n_audit_separator, 'start(){Policy(effects(),capabilities(),allow(),deny(),budget(0),trust(public),audit(1_0)).permit(1);}'
SOURCE n_trust_suffix, 'start(){Policy(effects(),capabilities(),allow(),deny(),budget(0),trust(public1),audit(0)).permit(1);}'
SOURCE n_leading_separator, 'start(){Policy(effects(,console_write),capabilities(),allow(),deny(),budget(1),trust(public),audit(1)).permit(1);}'
SOURCE n_double_separator, 'start(){Policy(effects(console_write,,fs_read),capabilities(),allow(),deny(),budget(2),trust(public),audit(1)).permit(1);}'
SOURCE n_bad_delimiter, 'start(){Policy(effects(),capabilities(),allow(),deny(),budget(1],trust(public),audit(0)).permit(1);}'

cat_lex: db 'NEBO-EFFECTS-CAPABILITIES-E-POLITICAS-LEX-001'
cat_lex_len equ $-cat_lex
cat_parse: db 'NEBO-EFFECTS-CAPABILITIES-E-POLITICAS-PARSE-002'
cat_parse_len equ $-cat_parse
cat_type: db 'NEBO-EFFECTS-CAPABILITIES-E-POLITICAS-TYPE-003'
cat_type_len equ $-cat_type
cat_codegen: db 'NEBO-EFFECTS-CAPABILITIES-E-POLITICAS-CODEGEN-004'
cat_codegen_len equ $-cat_codegen
cat_runtime: db 'NEBO-EFFECTS-CAPABILITIES-E-POLITICAS-RUNTIME-005'
cat_runtime_len equ $-cat_runtime
cat_security: db 'NEBO-EFFECTS-CAPABILITIES-E-POLITICAS-SECURITY-006'
cat_security_len equ $-cat_security
msg_lex: db 'unknown or non-canonical Policy atom or literal'
msg_lex_len equ $-msg_lex
msg_parse: db 'malformed or non-canonical Policy clause order'
msg_parse_len equ $-msg_parse
msg_type: db 'Policy value or effect constraint is invalid'
msg_type_len equ $-msg_type
msg_codegen: db 'Policy proof cannot be lowered for this target or front'
msg_codegen_len equ $-msg_codegen
msg_runtime: db 'Policy evaluation budget is exceeded'
msg_runtime_len equ $-msg_runtime
msg_security: db 'Policy capability allow deny trust or audit check failed'
msg_security_len equ $-msg_security

section .bss align=16
parse_request: resb neboc_effects_capabilities_e_politicas_PARSE_REQUEST_SIZE
policy_output: resb NEBOC_POLICY_REQUEST_SIZE
catalog_entry: resb NEBOC_DIAG_ENTRY_SIZE
saved_hash: resq 1
alias_source: resb 512
long_source: resb neboc_effects_capabilities_e_politicas_PARSE_MAX_SOURCE_BYTES

section .text
clear_parse_state:
    lea rdi, [rel parse_request]
    mov ecx, neboc_effects_capabilities_e_politicas_PARSE_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    lea rdi, [rel policy_output]
    mov ecx, NEBOC_POLICY_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    ret

; rsi=source, edx=length
parse_source:
    sub rsp, 8
    call clear_parse_state
    lea rsp, [rsp + 8]
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_OFFSET], rsi
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_LENGTH_OFFSET], rdx
    lea rax, [rel policy_output]
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_OUTPUT_OFFSET], rax
    lea rdi, [rel parse_request]
    jmp neboc_policy_parse

; rdi=span, rsi=literal, edx=len -> eax bool
span_equal:
    xor ecx, ecx
.loop:
    cmp ecx, edx
    jae .yes
    mov al, [rdi + rcx]
    cmp al, [rsi + rcx]
    jne .no
    inc ecx
    jmp .loop
.yes:
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

%macro TEST_POSITIVE 10
    lea rsi, [rel %1]
    mov edx, %1 %+ _len
    call parse_source
    test eax, eax
    jnz fail
    cmp qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_DIAGNOSTIC_OFFSET], 0
    jne fail
    cmp qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_CONSUMED_OFFSET], %1 %+ _len
    jne fail
    cmp qword [rel parse_request + NEBOC_PARSE_CLAUSE_MASK_OFFSET], NEBOC_PARSE_CLAUSE_MASK_COMPLETE
    jne fail
    mov rax, %10
    cmp qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_CANONICAL_HASH_OFFSET], rax
    jne fail
    cmp qword [rel policy_output + NEBOC_POLICY_DIRECT_EFFECTS_OFFSET], %2
    jne fail
    cmp qword [rel policy_output + NEBOC_POLICY_DECLARED_EFFECTS_OFFSET], %2
    jne fail
    cmp qword [rel policy_output + NEBOC_POLICY_CAPABILITIES_OFFSET], %3
    jne fail
    cmp qword [rel policy_output + NEBOC_POLICY_ALLOW_OFFSET], %4
    jne fail
    cmp qword [rel policy_output + NEBOC_POLICY_BUDGET_OFFSET], %6
    jne fail
    cmp qword [rel policy_output + NEBOC_POLICY_TRUST_OFFSET], %7
    jne fail
    cmp qword [rel policy_output + NEBOC_POLICY_AUDIT_ID_OFFSET], %8
    jne fail
    cmp qword [rel policy_output + NEBOC_POLICY_PERMIT_OFFSET], %9
    jne fail
    cmp qword [rel policy_output + NEBOC_POLICY_DENY_OFFSET], %5
    jne fail
%endmacro

%macro TEST_NEGATIVE 4
    lea rsi, [rel %1]
    mov edx, %1 %+ _len
    call parse_source
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_DIAGNOSTIC_OFFSET], %2
    jne fail
    cmp qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_ERROR_OFFSET_OFFSET], %3
    jne fail
    cmp qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_CONSUMED_OFFSET], %3
    jne fail
    cmp qword [rel parse_request + NEBOC_PARSE_CLAUSE_MASK_OFFSET], %4
    jne fail
    cmp qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_CANONICAL_HASH_OFFSET], 0
    jne fail
    lea rdi, [rel policy_output]
    mov ecx, NEBOC_POLICY_REQUEST_QWORDS
%%zero_loop:
    cmp qword [rdi], 0
    jne fail
    add rdi, 8
    dec ecx
    jnz %%zero_loop
%endmacro

%macro TEST_CATALOG 6
    mov edi, %1
    lea rsi, [rel catalog_entry]
    call neboc_diagnostic_catalog_lookup
    test eax, eax
    jnz fail
    cmp qword [rel catalog_entry + NEBOC_DIAG_ENTRY_NAME_LENGTH_OFFSET], %3
    jne fail
    cmp qword [rel catalog_entry + NEBOC_DIAG_ENTRY_PHASE_OFFSET], %4
    jne fail
    cmp qword [rel catalog_entry + NEBOC_DIAG_ENTRY_SEVERITY_OFFSET], NEBOC_DIAGNOSTIC_SEVERITY_ERROR
    jne fail
    mov rdi, [rel catalog_entry + NEBOC_DIAG_ENTRY_NAME_OFFSET]
    lea rsi, [rel %2]
    mov edx, %3
    call span_equal
    test eax, eax
    jz fail
    cmp qword [rel catalog_entry + NEBOC_DIAG_ENTRY_MESSAGE_LENGTH_OFFSET], %6
    jne fail
    mov rdi, [rel catalog_entry + NEBOC_DIAG_ENTRY_MESSAGE_OFFSET]
    lea rsi, [rel %5]
    mov edx, %6
    call span_equal
    test eax, eax
    jz fail
%endmacro

global _start
_start:
    ; Six frozen positive GOLDEN values.
    TEST_POSITIVE p_console, 1, 1, 1, 0, 1, NEBOC_TRUST_PUBLIC, 21, 21, 0xd76cc3ae969d8624
    mov rax, [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_CANONICAL_HASH_OFFSET]
    mov [rel saved_hash], rax
    TEST_POSITIVE p_pure, 0, 0, 0, 0, 0, NEBOC_TRUST_PUBLIC, 0, 22, 0xa3026736c2219733
    TEST_POSITIVE p_fs_read, 4, 4, 4, 0, 1, NEBOC_TRUST_INTERNAL, 2301, 23, 0xb64d38f163abd597
    TEST_POSITIVE p_combined, 35, 35, 35, 0, 3, NEBOC_TRUST_PUBLIC, 2401, 24, 0x8cdced91ff54a91c
    TEST_POSITIVE p_restricted, 136, 136, 136, 0, 2, NEBOC_TRUST_RESTRICTED, 2501, 25, 0x75349ea34931538a
    TEST_POSITIVE p_unsafe, 1024, 1024, 1024, 0, 1, NEBOC_TRUST_SECRET, 2601, 26, 0x59772c91361ab67a

    ; Whitespace changes consumed bytes but not the canonical parsed hash.
    TEST_POSITIVE p_console_ws, 1, 1, 1, 0, 1, NEBOC_TRUST_PUBLIC, 21, 21, 0xd76cc3ae969d8624
    mov rax, [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_CANONICAL_HASH_OFFSET]
    cmp rax, [rel saved_hash]
    jne fail

    ; Structural coverage separates all four set fields, exercises deny and
    ; covers the four atoms absent from the six frozen positive proofs.
    TEST_POSITIVE p_distinct, 848, 6, 40, 1024, 65535, NEBOC_TRUST_INTERNAL, 0xffffffffffffffff, 255, 0x52b6f0db0c562cab
    cmp qword [rel policy_output + NEBOC_POLICY_CAPABILITIES_OFFSET], 6
    jne fail
    cmp qword [rel policy_output + NEBOC_POLICY_ALLOW_OFFSET], 40
    jne fail
    TEST_POSITIVE p_permit_zero, 0, 0, 0, 0, 0, NEBOC_TRUST_PUBLIC, 0, 0, 0xf14b84b8290b8965

    ; Reparse the canonical public proof before evaluator interoperability.
    TEST_POSITIVE p_console, 1, 1, 1, 0, 1, NEBOC_TRUST_PUBLIC, 21, 21, 0xd76cc3ae969d8624
    lea rdi, [rel policy_output]
    call neboc_policy_evaluate
    test eax, eax
    jnz fail
    cmp qword [rel policy_output + NEBOC_POLICY_DECISION_OFFSET], NEBOC_POLICY_DECISION_PERMIT
    jne fail

    ; Exact first-cause negative diagnostics.
    TEST_NEGATIVE n_unknown, neboc_effects_capabilities_e_politicas_DIAG_LEX_driver_cli_linux_x86_64, 23, 0
    TEST_NEGATIVE n_alias, neboc_effects_capabilities_e_politicas_DIAG_LEX_driver_cli_linux_x86_64, 23, 0
    TEST_NEGATIVE n_duplicate, neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64, 37, 0
    TEST_NEGATIVE n_bad_number, neboc_effects_capabilities_e_politicas_DIAG_LEX_driver_cli_linux_x86_64, 62, 0x0f
    TEST_NEGATIVE n_reordered, neboc_effects_capabilities_e_politicas_DIAG_PARSE_driver_cli_linux_x86_64, 25, 0x01
    TEST_NEGATIVE n_missing_audit, neboc_effects_capabilities_e_politicas_DIAG_PARSE_driver_cli_linux_x86_64, 78, 0x3f
    TEST_NEGATIVE n_missing_comma, neboc_effects_capabilities_e_politicas_DIAG_PARSE_driver_cli_linux_x86_64, 25, 0x01
    TEST_NEGATIVE n_trailing, neboc_effects_capabilities_e_politicas_DIAG_PARSE_driver_cli_linux_x86_64, 100, 0x7f
    TEST_NEGATIVE n_budget, neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64, 62, 0x0f
    TEST_NEGATIVE n_permit, neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64, 96, 0x7f
    TEST_NEGATIVE n_audit_overflow, neboc_effects_capabilities_e_politicas_DIAG_LEX_driver_cli_linux_x86_64, 104, 0x3f
    TEST_NEGATIVE n_semicolon, neboc_effects_capabilities_e_politicas_DIAG_PARSE_driver_cli_linux_x86_64, 98, 0x7f

    ; Lexical suffix hardening beyond the frozen twelve-row matrix.
    TEST_NEGATIVE n_budget_suffix, neboc_effects_capabilities_e_politicas_DIAG_LEX_driver_cli_linux_x86_64, 63, 0x0f
    TEST_NEGATIVE n_audit_separator, neboc_effects_capabilities_e_politicas_DIAG_LEX_driver_cli_linux_x86_64, 86, 0x3f
    TEST_NEGATIVE n_trust_suffix, neboc_effects_capabilities_e_politicas_DIAG_LEX_driver_cli_linux_x86_64, 77, 0x1f
    TEST_NEGATIVE n_leading_separator, neboc_effects_capabilities_e_politicas_DIAG_PARSE_driver_cli_linux_x86_64, 23, 0
    TEST_NEGATIVE n_double_separator, neboc_effects_capabilities_e_politicas_DIAG_PARSE_driver_cli_linux_x86_64, 37, 0
    TEST_NEGATIVE n_bad_delimiter, neboc_effects_capabilities_e_politicas_DIAG_PARSE_driver_cli_linux_x86_64, 63, 0x0f

    ; Invalid addresses/ranges are bounded and do not touch output.
    xor edi, edi
    call neboc_policy_parse
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail

    ; Null source, null output and zero length reject without output writes.
    call clear_parse_state
    mov rdx, 0x1122334455667788
    mov [rel policy_output], rdx
    mov qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_LENGTH_OFFSET], 1
    lea rax, [rel policy_output]
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_OUTPUT_OFFSET], rax
    lea rdi, [rel parse_request]
    call neboc_policy_parse
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    mov rax, 0x1122334455667788
    cmp qword [rel policy_output], rax
    jne fail
    call clear_parse_state
    mov rdx, 0x1122334455667788
    mov [rel policy_output], rdx
    lea rax, [rel p_console]
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_OFFSET], rax
    mov qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_LENGTH_OFFSET], p_console_len
    lea rdi, [rel parse_request]
    call neboc_policy_parse
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    mov rax, 0x1122334455667788
    cmp qword [rel policy_output], rax
    jne fail
    call clear_parse_state
    mov rdx, 0x1122334455667788
    mov [rel policy_output], rdx
    lea rax, [rel p_console]
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_OFFSET], rax
    lea rax, [rel policy_output]
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_OUTPUT_OFFSET], rax
    lea rdi, [rel parse_request]
    call neboc_policy_parse
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    mov rax, 0x1122334455667788
    cmp qword [rel policy_output], rax
    jne fail

    ; Misaligned output and request reject transactionally.
    call clear_parse_state
    mov rax, 0x1122334455667788
    mov [rel policy_output], rax
    lea rax, [rel p_console]
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_OFFSET], rax
    mov qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_LENGTH_OFFSET], p_console_len
    lea rax, [rel policy_output + 1]
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_OUTPUT_OFFSET], rax
    lea rdi, [rel parse_request]
    call neboc_policy_parse
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    mov rax, [rel policy_output]
    mov rdx, 0x1122334455667788
    cmp rax, rdx
    jne fail
    lea rdi, [rel parse_request + 1]
    call neboc_policy_parse
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail

    ; Arithmetic overflow and all three span-overlap forms reject before
    ; clearing either source or output.
    call clear_parse_state
    mov rdx, 0x1122334455667788
    mov [rel policy_output], rdx
    mov qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_OFFSET], -1
    mov qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_LENGTH_OFFSET], 2
    lea rax, [rel policy_output]
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_OUTPUT_OFFSET], rax
    lea rdi, [rel parse_request]
    call neboc_policy_parse
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    mov rax, 0x1122334455667788
    cmp qword [rel policy_output], rax
    jne fail

    cld
    lea rsi, [rel p_console]
    lea rdi, [rel alias_source]
    mov ecx, p_console_len
    rep movsb
    call clear_parse_state
    lea rax, [rel alias_source]
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_OFFSET], rax
    mov qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_LENGTH_OFFSET], p_console_len
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_OUTPUT_OFFSET], rax
    lea rdi, [rel parse_request]
    call neboc_policy_parse
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    cmp byte [rel alias_source], 's'
    jne fail

    call clear_parse_state
    mov rdx, 0x1122334455667788
    mov [rel policy_output], rdx
    lea rax, [rel parse_request]
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_OFFSET], rax
    mov qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_LENGTH_OFFSET], 8
    lea rax, [rel policy_output]
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_OUTPUT_OFFSET], rax
    lea rdi, [rel parse_request]
    call neboc_policy_parse
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    mov rax, 0x1122334455667788
    cmp qword [rel policy_output], rax
    jne fail

    call clear_parse_state
    lea rax, [rel p_console]
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_OFFSET], rax
    mov qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_LENGTH_OFFSET], p_console_len
    lea rax, [rel parse_request]
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_OUTPUT_OFFSET], rax
    lea rdi, [rel parse_request]
    call neboc_policy_parse
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    lea rax, [rel p_console]
    cmp qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_OFFSET], rax
    jne fail

    ; A valid source padded to exactly 4096 bytes parses; 4097 is a bounded
    ; limit error before any source read.
    cld
    lea rsi, [rel p_console]
    lea rdi, [rel long_source]
    mov ecx, p_console_len
    rep movsb
    mov ecx, neboc_effects_capabilities_e_politicas_PARSE_MAX_SOURCE_BYTES - p_console_len
    mov al, ' '
    rep stosb
    lea rsi, [rel long_source]
    mov edx, neboc_effects_capabilities_e_politicas_PARSE_MAX_SOURCE_BYTES
    call parse_source
    test eax, eax
    jne fail
    cmp qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_DIAGNOSTIC_OFFSET], 0
    jne fail
    cmp qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_CONSUMED_OFFSET], neboc_effects_capabilities_e_politicas_PARSE_MAX_SOURCE_BYTES
    jne fail
    mov rax, 0xd76cc3ae969d8624
    cmp qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_CANONICAL_HASH_OFFSET], rax
    jne fail

    call clear_parse_state
    lea rax, [rel p_console]
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_OFFSET], rax
    mov qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_LENGTH_OFFSET], neboc_effects_capabilities_e_politicas_PARSE_MAX_SOURCE_BYTES + 1
    lea rax, [rel policy_output]
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_OUTPUT_OFFSET], rax
    lea rdi, [rel parse_request]
    call neboc_policy_parse
    cmp eax, NEBOC_STATUS_LIMIT_EXCEEDED
    jne fail

    ; All six effects_capabilities_e_politicas IDs are exact shared-catalog name/message/severity/phase rows.
    TEST_CATALOG neboc_effects_capabilities_e_politicas_DIAG_LEX_diagnostics, cat_lex, cat_lex_len, NEBOC_DIAGNOSTIC_PHASE_LEX, msg_lex, msg_lex_len
    TEST_CATALOG neboc_effects_capabilities_e_politicas_DIAG_PARSE_diagnostics, cat_parse, cat_parse_len, NEBOC_DIAGNOSTIC_PHASE_PARSE, msg_parse, msg_parse_len
    TEST_CATALOG neboc_effects_capabilities_e_politicas_DIAG_TYPE_diagnostics, cat_type, cat_type_len, NEBOC_DIAGNOSTIC_PHASE_TYPE, msg_type, msg_type_len
    TEST_CATALOG neboc_effects_capabilities_e_politicas_DIAG_CODEGEN_diagnostics, cat_codegen, cat_codegen_len, NEBOC_DIAGNOSTIC_PHASE_CODEGEN, msg_codegen, msg_codegen_len
    TEST_CATALOG neboc_effects_capabilities_e_politicas_DIAG_RUNTIME_diagnostics, cat_runtime, cat_runtime_len, NEBOC_DIAGNOSTIC_PHASE_RUNTIME, msg_runtime, msg_runtime_len
    TEST_CATALOG neboc_effects_capabilities_e_politicas_DIAG_SECURITY_diagnostics, cat_security, cat_security_len, NEBOC_DIAGNOSTIC_PHASE_SECURITY, msg_security, msg_security_len

    ; SysV callee-saved registers and DF survive/clear across the parser API.
    call clear_parse_state
    lea rax, [rel p_console]
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_OFFSET], rax
    mov qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_LENGTH_OFFSET], p_console_len
    lea rax, [rel policy_output]
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_OUTPUT_OFFSET], rax
    mov rbx, 0x11111111
    mov rbp, 0x22222222
    mov r12, 0x33333333
    mov r13, 0x44444444
    mov r14, 0x55555555
    mov r15, 0x66666666
    std
    lea rdi, [rel parse_request]
    call neboc_policy_parse
    test eax, eax
    jnz fail
    cmp rbx, 0x11111111
    jne fail
    cmp rbp, 0x22222222
    jne fail
    cmp r12, 0x33333333
    jne fail
    cmp r13, 0x44444444
    jne fail
    cmp r14, 0x55555555
    jne fail
    cmp r15, 0x66666666
    jne fail
    pushfq
    pop rax
    test rax, 1 << 10
    jnz fail

pass:
    xor edi, edi
    jmp neboc_host_process_exit
fail:
    cld
    mov edi, 1
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
