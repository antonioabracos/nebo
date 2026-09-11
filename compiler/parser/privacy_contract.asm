; Nebo Assembly — PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-PF002 bounded privacy syntax/API contract
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/privacy_contract.inc"

section .rodata
kw_start: db 'start'
kw_start_len equ $-kw_start
kw_secret: db 'Secret'
kw_secret_len equ $-kw_secret
kw_personal_data: db 'PersonalData'
kw_personal_data_len equ $-kw_personal_data
kw_int: db 'Int'
kw_int_len equ $-kw_int
kw_text: db 'Text'
kw_text_len equ $-kw_text
kw_redact: db 'redact'
kw_redact_len equ $-kw_redact

atom_public: db 'public'
atom_public_len equ $-atom_public
atom_internal: db 'internal'
atom_internal_len equ $-atom_internal
atom_personal: db 'personal'
atom_personal_len equ $-atom_personal
atom_sensitive: db 'sensitive'
atom_sensitive_len equ $-atom_sensitive
atom_secret: db 'secret'
atom_secret_len equ $-atom_secret

section .text

; rdi = aligned pointer to neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_REQUEST_SIZE
; eax = NEBOC_STATUS_*.  This parser emits only a 13-qword syntax descriptor;
; it never invokes the PF001 evaluator or constructs its 35-qword record.
NEBOC_ABI_FUNCTION neboc_privacy_parse
    test rdi, rdi
    jz .invalid_argument
    test rdi, neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_ALIGNMENT - 1
    jnz .invalid_argument

    ; Prove the request range before dereferencing it, including hostile
    ; aligned addresses close to UINT64_MAX.
    mov r8, rdi
    add r8, neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_REQUEST_SIZE
    jc .invalid_argument
    cmp qword [rdi + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_SOURCE_OFFSET], 0
    je .invalid_argument
    cmp qword [rdi + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_OUTPUT_OFFSET], 0
    je .invalid_argument
    mov rax, [rdi + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_OUTPUT_OFFSET]
    test rax, NEBOC_PRIVACY_RESULT_ALIGNMENT - 1
    jnz .invalid_argument
    cmp qword [rdi + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_SOURCE_LENGTH_OFFSET], 0
    je .invalid_argument
    cmp qword [rdi + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_SOURCE_LENGTH_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_MAX_SOURCE_BYTES
    ja .limit_exceeded

    ; Request, source and output are an explicitly disjoint transactional ABI.
    mov r9, [rdi + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_SOURCE_OFFSET]
    mov r10, r9
    add r10, [rdi + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_SOURCE_LENGTH_OFFSET]
    jc .invalid_argument
    mov r11, [rdi + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_OUTPUT_OFFSET]
    mov rax, r11
    add rax, NEBOC_PRIVACY_RESULT_SIZE
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
    mov r13, [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_SOURCE_OFFSET]
    mov r14, r13
    add r14, [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_SOURCE_LENGTH_OFFSET]
    mov r15, r13
    mov rbx, [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_OUTPUT_OFFSET]

    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_ERROR_OFFSET_OFFSET], 0
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_DIAGNOSTIC_OFFSET], 0
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_CONSUMED_OFFSET], 0
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_CANONICAL_HASH_OFFSET], 0
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_FEATURE_MASK_OFFSET], 0
    mov rdi, rbx
    mov ecx, NEBOC_PRIVACY_RESULT_QWORDS
    xor eax, eax
    rep stosq
    mov qword [rbx + NEBOC_PRIVACY_RESULT_FLAGS_OFFSET], NEBOC_PRIVACY_FLAG_CANONICAL

    lea rsi, [rel kw_start]
    mov ecx, kw_start_len
    call match_identifier
    jc .proof_keyword_failure
    mov edi, '('
    call privacidade_dados_sensiveis_e_zero_trust_expect_char
    jc .parse_failure
    mov edi, ')'
    call privacidade_dados_sensiveis_e_zero_trust_expect_char
    jc .parse_failure
    mov edi, '{'
    call privacidade_dados_sensiveis_e_zero_trust_expect_char
    jc .parse_failure

    call parse_wrapper
    jc .reported_failure
    mov [rbx + NEBOC_PRIVACY_RESULT_WRAPPER_KIND_OFFSET], rax
    mov rcx, r8
    sub rcx, r13
    mov [rbx + NEBOC_PRIVACY_RESULT_WRAPPER_SPAN_OFFSET], rcx
    mov [rbx + NEBOC_PRIVACY_RESULT_WRAPPER_SPAN_LENGTH_OFFSET], r9
    cmp eax, NEBOC_PRIVACY_WRAPPER_SECRET
    jne .wrapper_personal
    mov qword [rbx + NEBOC_PRIVACY_RESULT_DIRECT_LABEL_OFFSET], NEBOC_LABEL_SECRET
    jmp .wrapper_done
.wrapper_personal:
    mov qword [rbx + NEBOC_PRIVACY_RESULT_DIRECT_LABEL_OFFSET], NEBOC_LABEL_PERSONAL
.wrapper_done:
    or qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_FEATURE_MASK_OFFSET], NEBOC_PARSE_FEATURE_WRAPPER

    mov edi, '<'
    call privacidade_dados_sensiveis_e_zero_trust_expect_char
    jc .parse_failure
    call parse_payload_type
    jc .reported_failure
    mov [rbx + NEBOC_PRIVACY_RESULT_PAYLOAD_TYPE_ID_OFFSET], rax
    mov rcx, r8
    sub rcx, r13
    mov [rbx + NEBOC_PRIVACY_RESULT_TYPE_SPAN_OFFSET], rcx
    mov [rbx + NEBOC_PRIVACY_RESULT_TYPE_SPAN_LENGTH_OFFSET], r9
    or qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_FEATURE_MASK_OFFSET], NEBOC_PARSE_FEATURE_TYPE
    mov edi, '>'
    call privacidade_dados_sensiveis_e_zero_trust_expect_char
    jc .parse_failure

    call privacidade_dados_sensiveis_e_zero_trust_skip_ws
    cmp r15, r14
    jae .parse_failure
    cmp byte [r15], '.'
    jne .expect_semicolon

    mov rax, r15
    sub rax, r13
    mov [rbx + NEBOC_PRIVACY_RESULT_REDACT_SPAN_OFFSET], rax
    inc r15
    lea rsi, [rel kw_redact]
    mov ecx, kw_redact_len
    call match_identifier
    jc .reported_failure
    mov edi, '('
    call privacidade_dados_sensiveis_e_zero_trust_expect_char
    jc .parse_failure
    call parse_label_set
    jc .reported_failure
    mov [rbx + NEBOC_PRIVACY_RESULT_REDACTION_MASK_OFFSET], rax
    or qword [rbx + NEBOC_PRIVACY_RESULT_FLAGS_OFFSET], NEBOC_PRIVACY_FLAG_HAS_REDACT
    mov rax, r15
    sub rax, r13
    sub rax, [rbx + NEBOC_PRIVACY_RESULT_REDACT_SPAN_OFFSET]
    mov [rbx + NEBOC_PRIVACY_RESULT_REDACT_SPAN_LENGTH_OFFSET], rax
    or qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_FEATURE_MASK_OFFSET], NEBOC_PARSE_FEATURE_REDACT

.expect_semicolon:
    mov edi, ';'
    call privacidade_dados_sensiveis_e_zero_trust_expect_char
    jc .parse_failure

    ; q5 identifies the statement start and q11 its half-open length through
    ; the semicolon, independent of surrounding function/braces whitespace.
    mov rax, r15
    sub rax, r13
    sub rax, [rbx + NEBOC_PRIVACY_RESULT_WRAPPER_SPAN_OFFSET]
    mov [rbx + NEBOC_PRIVACY_RESULT_STATEMENT_SPAN_LENGTH_OFFSET], rax
    mov edi, '}'
    call privacidade_dados_sensiveis_e_zero_trust_expect_char
    jc .parse_failure
    call privacidade_dados_sensiveis_e_zero_trust_skip_ws
    cmp r15, r14
    jne .parse_failure
    mov rax, r15
    sub rax, r13
    mov [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_CONSUMED_OFFSET], rax

    ; FNV-1a64 over q0..q4 only: no pointers, spans or source bytes.
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.hash_loop:
    cmp rcx, NEBOC_PRIVACY_HASHED_OUTPUT_BYTES
    jae .hash_done
    movzx edx, byte [rbx + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .hash_loop
.hash_done:
    mov [rbx + NEBOC_PRIVACY_RESULT_SHAPE_HASH_OFFSET], rax
    mov [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_CANONICAL_HASH_OFFSET], rax
    xor eax, eax
    jmp .done

.proof_keyword_failure:
    ; `start` is a structural proof keyword, not a privacy wrapper/type/label
    ; identifier. Missing, aliased or wrong-case spellings are therefore a
    ; syntax failure even though the shared identifier helper reports LEX.
    mov edx, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_PARSE_driver_cli_linux_x86_64
    jmp .reported_failure
.parse_failure:
    mov edx, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_PARSE_driver_cli_linux_x86_64
.reported_failure:
    mov [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_DIAGNOSTIC_OFFSET], rdx
    mov rax, r15
    sub rax, r13
    mov [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_ERROR_OFFSET_OFFSET], rax
    mov [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_CONSUMED_OFFSET], rax
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_CANONICAL_HASH_OFFSET], 0
    mov rdi, rbx
    mov ecx, NEBOC_PRIVACY_RESULT_QWORDS
    xor eax, eax
    rep stosq
    mov eax, NEBOC_STATUS_INVALID_SOURCE
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

; Global parse cursor: r15, end: r14.  Trivia is ASCII SP/HT/LF/CR plus
; bounded `//` line comments.  Public examples can therefore carry technical
; documentation without changing the pointerless privacy shape hash.
privacidade_dados_sensiveis_e_zero_trust_skip_ws:
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
    je .take
    cmp al, '/'
    jne .done
    mov rax, r15
    inc rax
    cmp rax, r14
    jae .done
    cmp byte [rax], '/'
    jne .done
    add r15, 2
.line_comment:
    cmp r15, r14
    jae .done
    cmp byte [r15], 10
    je .take
    inc r15
    jmp .line_comment
.take:
    inc r15
    jmp .loop
.done:
    ret

; Scans one ASCII identifier after optional whitespace.  Success returns its
; start in r8 and length in r9.  No identifier leaves the cursor in place.
scan_identifier:
    sub rsp, 8
    call privacidade_dados_sensiveis_e_zero_trust_skip_ws
    mov r8, r15
    cmp r15, r14
    jae .fail
    movzx eax, byte [r15]
    cmp al, 'A'
    jb .lower_or_underscore
    cmp al, 'Z'
    jbe .take_first
.lower_or_underscore:
    cmp al, 'a'
    jb .underscore
    cmp al, 'z'
    jbe .take_first
.underscore:
    cmp al, '_'
    jne .fail
.take_first:
    inc r15
.scan:
    cmp r15, r14
    jae .done
    movzx eax, byte [r15]
    cmp al, 'A'
    jb .maybe_lower
    cmp al, 'Z'
    jbe .take
.maybe_lower:
    cmp al, 'a'
    jb .maybe_digit
    cmp al, 'z'
    jbe .take
.maybe_digit:
    cmp al, '0'
    jb .maybe_underscore_tail
    cmp al, '9'
    jbe .take
.maybe_underscore_tail:
    cmp al, '_'
    jne .done
.take:
    inc r15
    jmp .scan
.done:
    mov r9, r15
    sub r9, r8
    lea rsp, [rsp + 8]
    clc
    ret
.fail:
    xor r9d, r9d
    lea rsp, [rsp + 8]
    stc
    ret

; rsi=literal, ecx=length.  Unknown identifier spellings are lexical;
; missing structural identifiers are parse failures.
match_identifier:
    sub rsp, 8
    mov r10, rsi
    mov r11d, ecx
    call scan_identifier
    jc .parse_fail
    cmp r9d, r11d
    jne .lex_fail
    mov rdi, r8
    mov rsi, r10
    mov edx, r11d
    call privacidade_dados_sensiveis_e_zero_trust_span_equal
    test eax, eax
    jz .lex_fail
    lea rsp, [rsp + 8]
    clc
    ret
.lex_fail:
    mov r15, r8
    mov edx, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_LEX_driver_cli_linux_x86_64
    lea rsp, [rsp + 8]
    stc
    ret
.parse_fail:
    mov edx, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_PARSE_driver_cli_linux_x86_64
    lea rsp, [rsp + 8]
    stc
    ret

; dil=character; advances cursor after optional whitespace.
privacidade_dados_sensiveis_e_zero_trust_expect_char:
    sub rsp, 8
    mov r9b, dil
    call privacidade_dados_sensiveis_e_zero_trust_skip_ws
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

; Success: eax=wrapper kind, r8/r9=exact source span.  Failure: rdx=diag.
parse_wrapper:
    sub rsp, 8
    call scan_identifier
    jc .parse_fail
    cmp r9, kw_secret_len
    jne .personal_data
    mov rdi, r8
    lea rsi, [rel kw_secret]
    mov edx, kw_secret_len
    call privacidade_dados_sensiveis_e_zero_trust_span_equal
    test eax, eax
    jnz .secret_match
.personal_data:
    cmp r9, kw_personal_data_len
    jne .lex_fail
    mov rdi, r8
    lea rsi, [rel kw_personal_data]
    mov edx, kw_personal_data_len
    call privacidade_dados_sensiveis_e_zero_trust_span_equal
    test eax, eax
    jz .lex_fail
    mov eax, NEBOC_PRIVACY_WRAPPER_PERSONAL_DATA
    lea rsp, [rsp + 8]
    clc
    ret
.secret_match:
    mov eax, NEBOC_PRIVACY_WRAPPER_SECRET
    lea rsp, [rsp + 8]
    clc
    ret
.lex_fail:
    mov r15, r8
    mov edx, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_LEX_driver_cli_linux_x86_64
    lea rsp, [rsp + 8]
    stc
    ret
.parse_fail:
    mov edx, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_PARSE_driver_cli_linux_x86_64
    lea rsp, [rsp + 8]
    stc
    ret

; Success: eax=stable TypeId, r8/r9=exact source span.  Failure: rdx=diag.
parse_payload_type:
    sub rsp, 8
    call scan_identifier
    jc .parse_fail
    cmp r9, kw_int_len
    jne .text
    mov rdi, r8
    lea rsi, [rel kw_int]
    mov edx, kw_int_len
    call privacidade_dados_sensiveis_e_zero_trust_span_equal
    test eax, eax
    jnz .int_match
.text:
    cmp r9, kw_text_len
    jne .lex_fail
    mov rdi, r8
    lea rsi, [rel kw_text]
    mov edx, kw_text_len
    call privacidade_dados_sensiveis_e_zero_trust_span_equal
    test eax, eax
    jz .lex_fail
    mov eax, NEBOC_PRIVACY_PAYLOAD_TYPE_TEXT
    lea rsp, [rsp + 8]
    clc
    ret
.int_match:
    mov eax, NEBOC_PRIVACY_PAYLOAD_TYPE_INT
    lea rsp, [rsp + 8]
    clc
    ret
.lex_fail:
    mov r15, r8
    mov edx, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_LEX_driver_cli_linux_x86_64
    lea rsp, [rsp + 8]
    stc
    ret
.parse_fail:
    mov edx, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_PARSE_driver_cli_linux_x86_64
    lea rsp, [rsp + 8]
    stc
    ret

; Parses a non-empty comma-separated label set and consumes ')'.  Public is
; the empty label and therefore invalid as explicit redaction authority.
; Duplicate labels and public yield TYPE at the first offending atom.
parse_label_set:
    sub rsp, 8
    xor r10d, r10d
    call privacidade_dados_sensiveis_e_zero_trust_skip_ws
    cmp r15, r14
    jae .parse_fail
    cmp byte [r15], ')'
    je .empty_type_fail
.item:
    call privacidade_dados_sensiveis_e_zero_trust_skip_ws
    cmp r15, r14
    jae .parse_fail
    cmp byte [r15], ','
    je .parse_fail
    cmp byte [r15], ')'
    je .parse_fail
    call scan_identifier
    jc .missing_identifier
    mov rdi, r8
    mov rcx, r9
    call label_from_span
    cmp rax, -1
    je .lex_fail
    test rax, rax
    jz .type_fail
    test r10, rax
    jnz .type_fail
    or r10, rax
    call privacidade_dados_sensiveis_e_zero_trust_skip_ws
    cmp r15, r14
    jae .parse_fail
    cmp byte [r15], ')'
    je .finish
    cmp byte [r15], ','
    jne .parse_fail
    inc r15
    call privacidade_dados_sensiveis_e_zero_trust_skip_ws
    cmp r15, r14
    jae .parse_fail
    cmp byte [r15], ')'
    je .parse_fail
    cmp byte [r15], ','
    je .parse_fail
    jmp .item
.finish:
    inc r15
    mov rax, r10
    lea rsp, [rsp + 8]
    clc
    ret
.missing_identifier:
    cmp r15, r14
    jae .parse_fail
    movzx eax, byte [r15]
    cmp al, ';'
    je .parse_fail
    cmp al, '}'
    je .parse_fail
    cmp al, '('
    je .parse_fail
    cmp al, '['
    je .parse_fail
    cmp al, ']'
    je .parse_fail
    mov r8, r15
    jmp .lex_fail
.empty_type_fail:
    mov r8, r15
    jmp .type_fail
.lex_fail:
    mov r15, r8
    mov edx, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_LEX_driver_cli_linux_x86_64
    lea rsp, [rsp + 8]
    stc
    ret
.type_fail:
    mov r15, r8
    mov edx, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_codegen_privacy_x86_64
    lea rsp, [rsp + 8]
    stc
    ret
.parse_fail:
    mov edx, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_PARSE_driver_cli_linux_x86_64
    lea rsp, [rsp + 8]
    stc
    ret

; rdi=span, rcx=length.  Returns a label bit, public=0, or UINT64_MAX.
label_from_span:
    sub rsp, 8
    mov r8, rdi
    mov r9, rcx
%macro LABEL_CANDIDATE 3
    cmp r9, %2
    jne %%next
    mov rdi, r8
    lea rsi, [rel %1]
    mov edx, %2
    call privacidade_dados_sensiveis_e_zero_trust_span_equal
    test eax, eax
    jz %%next
    mov eax, %3
    lea rsp, [rsp + 8]
    ret
%%next:
%endmacro
    LABEL_CANDIDATE atom_public, atom_public_len, NEBOC_LABEL_PUBLIC
    LABEL_CANDIDATE atom_internal, atom_internal_len, NEBOC_LABEL_INTERNAL
    LABEL_CANDIDATE atom_personal, atom_personal_len, NEBOC_LABEL_PERSONAL
    LABEL_CANDIDATE atom_sensitive, atom_sensitive_len, NEBOC_LABEL_SENSITIVE
    LABEL_CANDIDATE atom_secret, atom_secret_len, NEBOC_LABEL_SECRET
    mov rax, -1
    lea rsp, [rsp + 8]
    ret

; rdi=span, rsi=literal, edx=length; eax=1 equal, 0 different.
privacidade_dados_sensiveis_e_zero_trust_span_equal:
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
