; EFFECTS-CAPABILITIES-E-POLITICAS-PF003 policy semantic-envelope and abstract HIR/LIR invariants
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/policy_contract.inc"
%include "compiler/semantic/effect/effect_policy.inc"
%include "compiler/semantic/effect/effect_policy_semantic.inc"
%include "compiler/lowering/effects/effect_policy_ir.inc"

extern neboc_policy_parse
extern neboc_policy_semantic_analyze
extern neboc_policy_ir_lower
extern neboc_host_process_exit

; Inputs q0..q14, status, outputs q15..q24.
%macro SEM_CASE 26
    dq %1, %2, %3, %4, %5, %6, %7, %8, %9, %10
    dq %11, %12, %13, %14, %15, %16, %17, %18, %19, %20
    dq %21, %22, %23, %24, %25, %26
%endmacro

section .rodata align=8
policy_source:
    db 'start(){Policy(effects(console_write),capabilities(console_write),allow(console_write),deny(),budget(1),trust(public),audit(21)).permit(21);}'
policy_source_len equ $-policy_source

sem_cases:
; S01-S06: six frozen PF001/PF002 positive proofs.
sem_s01:
    SEM_CASE 1,1,1,0,1,0,21,21,0xd76cc3ae969d8624,0x7f,1,0,0,100,7, NEBOC_STATUS_OK,1,0,0,1,0,0x3772b5c5ed088704,1,3,0x3992a1784fe0977a,0
sem_s02:
    SEM_CASE 0,0,0,0,0,0,0,22,0xa3026736c2219733,0x7f,0,0,0,100,7, NEBOC_STATUS_OK,0,0,0,0,0,0xdc46f55909eac513,1,3,0xafa7e667a840a461,0
sem_s03:
    SEM_CASE 4,4,4,0,1,1,2301,23,0xb64d38f163abd597,0x7f,4,0,0,100,7, NEBOC_STATUS_OK,4,0,0,1,0,0xe411560ba30ca732,1,3,0x04b63edb83cd229e,0
sem_s04:
    SEM_CASE 35,35,35,0,3,0,2401,24,0x8cdced91ff54a91c,0x7f,35,0,0,100,7, NEBOC_STATUS_OK,35,0,0,3,0,0x98d3a5992c7d0ddc,1,3,0xd288deb5320e2c35,0
sem_s05:
    SEM_CASE 136,136,136,0,2,2,2501,25,0x75349ea34931538a,0x7f,136,0,0,100,7, NEBOC_STATUS_OK,136,0,0,2,0,0xb4cf6429896e37c0,1,3,0xe1831ed34b2b6bd3,0
sem_s06:
    SEM_CASE 1024,1024,1024,0,1,3,2601,26,0x59772c91361ab67a,0x7f,1024,0,0,100,7, NEBOC_STATUS_OK,1024,0,0,1,0,0x14b1a7819c233d8f,1,3,0x90fb367aebb2baea,0

; S07-S08: transitive union and the complete eleven-effect boundary.
sem_s07:
    SEM_CASE 3,3,3,0,2,0,2701,27,0x0f2c843bc964bf07,0x7f,1,2,0,100,7, NEBOC_STATUS_OK,3,0,0,2,0,0x45135efab35bd4c6,1,3,0x68f150b242eb2637,0
sem_s08:
    SEM_CASE 0x7ff,0x7ff,0x7ff,0,11,3,2801,28,0x1182195480383f1e,0x7f,0x7ff,0,0,100,7, NEBOC_STATUS_OK,0x7ff,0,0,11,0,0xb859396417dc0d97,1,3,0xdfbe52702e8a530b,0

; S09-S13: parser identity, clauses, flags and bounded monotonic provenance.
sem_s09:
    SEM_CASE 1,1,1,0,1,0,21,21,0xd76cc3ae969d8625,0x7f,1,0,0,100,7, NEBOC_STATUS_INVALID_SOURCE,0,0,0,0,neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64,0,0,0,0x22abae94e60170f3,0
sem_s10:
    SEM_CASE 1,1,1,0,1,0,21,21,0xd76cc3ae969d8624,0x3f,1,0,0,100,7, NEBOC_STATUS_INVALID_SOURCE,0,0,0,0,neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64,0,0,0,0x2120a0addf77ba5a,0
sem_s11:
    SEM_CASE 1,1,1,0,1,0,21,21,0xd76cc3ae969d8624,0x7f,1,0,0,100,3, NEBOC_STATUS_INVALID_SOURCE,0,0,0,0,neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64,0,0,0,0x120aee41bb3e971e,0
sem_s12:
    SEM_CASE 1,1,1,0,1,0,21,21,0xd76cc3ae969d8624,0x7f,1,0,100,99,7, NEBOC_STATUS_INVALID_SOURCE,0,0,0,0,neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64,0,0,0,0xf111f86c4002b939,0
sem_s13:
    SEM_CASE 1,1,1,0,1,0,21,21,0xd76cc3ae969d8624,0x7f,1,0,0,4097,7, NEBOC_STATUS_INVALID_SOURCE,0,0,0,0,neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64,0,0,0,0xd124db302bad5e0f,0

; S14-S20: evaluator first-cause, exact masks, security, budget and audit.
sem_s14:
    SEM_CASE 0x800,0x800,0x800,0,1,3,1401,14,0x38fe0f68e389f6ab,0x7f,0x800,0,0,100,7, NEBOC_STATUS_INVALID_SOURCE,0,0,0,0,neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64,0xac89a430dc89135a,0,0,0xd6ae2fa5d70b1cc7,0
sem_s15:
    SEM_CASE 1,0,0,1,0,0,0,15,0x78687a6edd669d6b,0x7f,1,2,0,100,7, NEBOC_STATUS_INVALID_SOURCE,3,3,1,2,neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64,0xf68308a006873f5b,0,0,0x4b3f9e85de0d73a4,0
sem_s16:
    SEM_CASE 1,0,1,0,1,0,1601,16,0x16f172b854359a7e,0x7f,1,0,0,100,7, NEBOC_STATUS_INVALID_SOURCE,1,1,0,1,neboc_effects_capabilities_e_politicas_DIAG_SECURITY_driver_cli_linux_x86_64,0x82c9d09bb65858eb,0,0,0x3b55c9a18ff4625a,0
sem_s17:
    SEM_CASE 1,1,0,0,1,0,1701,17,0xd8c17be66f4f5ab3,0x7f,1,0,0,100,7, NEBOC_STATUS_INVALID_SOURCE,1,0,1,1,neboc_effects_capabilities_e_politicas_DIAG_SECURITY_driver_cli_linux_x86_64,0xa9fc70f9ec81baa6,0,0,0x6ae18ae44d587d58,0
sem_s18:
    SEM_CASE 1,1,1,1,1,0,1801,18,0x28ad9ccabc9314a3,0x7f,1,0,0,100,7, NEBOC_STATUS_INVALID_SOURCE,1,0,1,1,neboc_effects_capabilities_e_politicas_DIAG_SECURITY_driver_cli_linux_x86_64,0x01cf19e606bd4eb6,0,0,0x58b14c8f47fd9bc7,0
sem_s19:
    SEM_CASE 3,3,3,0,1,0,1901,19,0x8a599366dbb7f117,0x7f,3,0,0,100,7, NEBOC_STATUS_INVALID_SOURCE,3,0,0,2,neboc_effects_capabilities_e_politicas_DIAG_RUNTIME_driver_cli_linux_x86_64,0x6ac468fb4a4c2e05,0,0,0x77339aa1afd9eb2b,0
sem_s20:
    SEM_CASE 1,1,1,0,1,0,0,20,0xdb031867afe98810,0x7f,1,0,0,100,7, NEBOC_STATUS_INVALID_SOURCE,1,0,0,1,neboc_effects_capabilities_e_politicas_DIAG_SECURITY_driver_cli_linux_x86_64,0xabce9f455974f6c4,0,0,0x6af506b1600748cf,0
sem_cases_end:
sem_case_count equ (sem_cases_end-sem_cases)/(26*8)
%if sem_case_count != 20
    %error "EFFECTS-CAPABILITIES-E-POLITICAS-PF003 requires exactly twenty primary semantic scenarios"
%endif

; Three evaluator range probes supplement the exact twenty-row semantic matrix.
sem_range_cases:
sem_range_budget:
    SEM_CASE 1,1,1,0,65536,0,21,21,0xe5e08a24af66910c,0x7f,1,0,0,100,7, NEBOC_STATUS_INVALID_SOURCE,0,0,0,0,neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64,0xa24b6d836e67a0dd,0,0,0xf7dd593c6564b075,0
sem_range_trust:
    SEM_CASE 1,1,1,0,1,4,21,21,0xbce894b7e2244da0,0x7f,1,0,0,100,7, NEBOC_STATUS_INVALID_SOURCE,0,0,0,0,neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64,0x692868c058c1b9b1,0,0,0x66910a2893a3497f,0
sem_range_permit:
    SEM_CASE 1,1,1,0,1,0,21,256,0xa4d66399d2f076f6,0x7f,1,0,0,100,7, NEBOC_STATUS_INVALID_SOURCE,0,0,0,0,neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64,0x6e304e5070a830a7,0,0,0x35efd7ae9cf103a0,0
sem_range_cases_end:
sem_range_case_count equ (sem_range_cases_end-sem_range_cases)/(26*8)

; Native provenance probe outside the exact 20/10 matrices: an empty source
; span is not a lowerable semantic envelope, even when every other field and
; the PF002 parser identity are authentic.
sem_empty_span:
    SEM_CASE 1,1,1,0,1,0,21,21,0xd76cc3ae969d8624,0x7f,1,0,0,0,7, NEBOC_STATUS_INVALID_SOURCE,0,0,0,0,neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64,0,0,0,0xb5d9c86a6f5bd6be,0

; semantic-case pointer, mutation selector, status, exact successful IR hash.
ir_cases:
    dq sem_s02,0,NEBOC_STATUS_OK,0x9f766cbe9713aabc       ; I01 pure
    dq sem_s01,0,NEBOC_STATUS_OK,0x97c382e5a7819ceb       ; I02 direct
    dq sem_s07,0,NEBOC_STATUS_OK,0xc03f2f7e1ae86c09       ; I03 transitive MASK_OR
    dq sem_s08,0,NEBOC_STATUS_OK,0xa73cda9829d92b47       ; I04 all effects
    dq sem_s01,1,NEBOC_STATUS_INVALID_SOURCE,0            ; I05 forged semantic hash
    dq sem_s01,2,NEBOC_STATUS_INVALID_SOURCE,0            ; I06 semantic diagnostic
    dq sem_s01,3,NEBOC_STATUS_INVALID_SOURCE,0            ; I07 deny decision
    dq sem_s01,4,NEBOC_STATUS_INVALID_SOURCE,0            ; I08 inferred mismatch
    dq sem_s01,5,NEBOC_STATUS_INVALID_SOURCE,0            ; I09 type/allocation mismatch
    dq sem_s01,6,NEBOC_STATUS_INVALID_SOURCE,0            ; I10 clause/flags/span
ir_cases_end:
ir_case_count equ (ir_cases_end-ir_cases)/(4*8)
%if ir_case_count != 10
    %error "EFFECTS-CAPABILITIES-E-POLITICAS-PF003 requires exactly ten primary IR scenarios"
%endif

section .bss align=16
semantic_request: resb neboc_effects_capabilities_e_politicas_SEMANTIC_REQUEST_SIZE
ir_request: resb neboc_effects_capabilities_e_politicas_IR_REQUEST_SIZE
parse_request: resb neboc_effects_capabilities_e_politicas_PARSE_REQUEST_SIZE
parsed_policy: resb NEBOC_POLICY_REQUEST_SIZE

section .text
clear_semantic:
    lea rdi, [rel semantic_request]
    mov ecx, neboc_effects_capabilities_e_politicas_SEMANTIC_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    ret

clear_ir:
    lea rdi, [rel ir_request]
    mov ecx, neboc_effects_capabilities_e_politicas_IR_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    ret

; rsi = SEM_CASE record. Copy its fifteen semantic inputs.
prepare_semantic_case:
    push rbx
    mov rbx, rsi
    call clear_semantic
    mov rsi, rbx
    lea rdi, [rel semantic_request]
    mov ecx, 15
    rep movsq
    pop rbx
    ret

; rsi = SEM_CASE record. Materialize its authenticated q0..q24 envelope.
prepare_ir_case:
    push rbx
    mov rbx, rsi
    call clear_ir
    mov rsi, rbx
    lea rdi, [rel ir_request]
    mov ecx, 15
    rep movsq
    lea rsi, [rbx + 16*8]
    lea rdi, [rel ir_request + NEBOC_IR_INFERRED_EFFECTS_OFFSET]
    mov ecx, 10
    rep movsq
    pop rbx
    ret

; edi = mutation selector used by I05..I10.
apply_ir_mutation:
    test edi, edi
    jz .done
    cmp edi, 1
    jne .diagnostic
    xor qword [rel ir_request + neboc_effects_capabilities_e_politicas_IR_SEMANTIC_HASH_OFFSET], 1
    ret
.diagnostic:
    cmp edi, 2
    jne .decision
    mov qword [rel ir_request + NEBOC_IR_SEMANTIC_DIAGNOSTIC_OFFSET], neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    mov rax, 0x62e1ea41329b24bb
    mov [rel ir_request + neboc_effects_capabilities_e_politicas_IR_SEMANTIC_HASH_OFFSET], rax
    ret
.decision:
    cmp edi, 3
    jne .inferred
    mov qword [rel ir_request + neboc_effects_capabilities_e_politicas_IR_DECISION_OFFSET], 0
    mov rax, 0x288a19c252aa137b
    mov [rel ir_request + neboc_effects_capabilities_e_politicas_IR_SEMANTIC_HASH_OFFSET], rax
    ret
.inferred:
    cmp edi, 4
    jne .type_allocation
    mov qword [rel ir_request + NEBOC_IR_INFERRED_EFFECTS_OFFSET], 2
    mov rax, 0xaa34075502ddfb69
    mov [rel ir_request + neboc_effects_capabilities_e_politicas_IR_SEMANTIC_HASH_OFFSET], rax
    ret
.type_allocation:
    cmp edi, 5
    jne .provenance
    mov qword [rel ir_request + NEBOC_IR_SEMANTIC_RESULT_TYPE_OFFSET], 0
    mov qword [rel ir_request + NEBOC_IR_SEMANTIC_ALLOCATIONS_OFFSET], 1
    mov rax, 0x1a97da6f44f14d59
    mov [rel ir_request + neboc_effects_capabilities_e_politicas_IR_SEMANTIC_HASH_OFFSET], rax
    ret
.provenance:
    mov qword [rel ir_request + NEBOC_IR_CLAUSE_MASK_OFFSET], 0
    mov qword [rel ir_request + NEBOC_IR_SEMANTIC_FLAGS_OFFSET], 0
    mov qword [rel ir_request + NEBOC_IR_SOURCE_END_OFFSET], 0
    mov rax, 0xd29e9aef931579c6
    mov [rel ir_request + neboc_effects_capabilities_e_politicas_IR_SEMANTIC_HASH_OFFSET], rax
.done:
    ret

; r14 = current SEM_CASE, validates status and all ten semantic outputs.
run_semantic_case:
    sub rsp, 8
    mov rsi, r14
    call prepare_semantic_case
    lea rdi, [rel semantic_request]
    call neboc_policy_semantic_analyze
    cmp rax, [r14 + 15*8]
    jne fail
    lea rsi, [rel semantic_request + NEBOC_SEMANTIC_INFERRED_EFFECTS_OFFSET]
    lea rdi, [r14 + 16*8]
    mov ecx, 10
.compare:
    mov rax, [rsi]
    cmp rax, [rdi]
    jne fail
    add rsi, 8
    add rdi, 8
    dec ecx
    jnz .compare
    lea rsp, [rsp + 8]
    ret

; The current IR request must fail transactionally with TYPE and no other IR.
expect_ir_invalid:
    sub rsp, 8
    lea rdi, [rel ir_request]
    call neboc_policy_ir_lower
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    lea rsi, [rel ir_request + neboc_effects_capabilities_e_politicas_IR_OUTPUT_OFFSET]
    xor edx, edx
.output_loop:
    cmp edx, 9
    jne .expect_zero
    cmp qword [rsi], neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    jne fail
    jmp .next
.expect_zero:
    cmp qword [rsi], 0
    jne fail
.next:
    add rsi, 8
    inc edx
    cmp edx, neboc_effects_capabilities_e_politicas_IR_OUTPUT_QWORDS
    jb .output_loop
    lea rsp, [rsp + 8]
    ret

global _start
_start:
    ; Exact twenty-row semantic matrix.
    lea r14, [rel sem_cases]
    mov r15d, sem_case_count
    mov r13d, 1
.semantic_loop:
    call run_semantic_case
    add r14, 26*8
    inc r13d
    dec r15d
    jnz .semantic_loop

    ; Budget, trust and permit are independently bounded evaluator inputs.
    lea r14, [rel sem_range_cases]
    mov r15d, sem_range_case_count
.range_loop:
    call run_semantic_case
    add r14, 26*8
    inc r13d
    dec r15d
    jnz .range_loop

    ; A zero-width semantic source span is rejected identically to the IR
    ; provenance gate; the exact diagnostic envelope and FNV hash are frozen.
    mov r13d, 31
    lea r14, [rel sem_empty_span]
    call run_semantic_case

    ; Exact ten-row HIR/LIR matrix.
    lea r14, [rel ir_cases]
    mov r15d, ir_case_count
    mov r13d, 101
.ir_loop:
    mov rsi, [r14]
    call prepare_ir_case
    mov edi, [r14 + 8]
    call apply_ir_mutation
    lea rdi, [rel ir_request]
    call neboc_policy_ir_lower
    cmp rax, [r14 + 16]
    jne fail
    test eax, eax
    jnz .negative_ir

    cmp qword [rel ir_request + NEBOC_IR_HIR_EFFECT_UNION_OFFSET], NEBOC_HIR_EFFECT_UNION
    jne fail
    cmp qword [rel ir_request + neboc_effects_capabilities_e_politicas_IR_HIR_POLICY_GATE_OFFSET], neboc_effects_capabilities_e_politicas_HIR_POLICY_GATE
    jne fail
    cmp qword [rel ir_request + NEBOC_IR_HIR_PERMIT_OFFSET], NEBOC_HIR_PERMIT
    jne fail
    cmp qword [rel ir_request + NEBOC_IR_LIR_MASK_OR_OFFSET], NEBOC_LIR_MASK_OR
    jne fail
    cmp qword [rel ir_request + NEBOC_IR_LIR_POLICY_ASSERT_OFFSET], NEBOC_LIR_POLICY_ASSERT
    jne fail
    cmp qword [rel ir_request + NEBOC_IR_LIR_CONST_I64_OFFSET], NEBOC_LIR_CONST_I64
    jne fail
    cmp qword [rel ir_request + neboc_effects_capabilities_e_politicas_IR_RESULT_TYPE_OFFSET], NEBOC_POLICY_IR_RESULT_TYPE_INT
    jne fail
    mov rax, [rel ir_request + NEBOC_IR_PERMIT_OFFSET]
    cmp [rel ir_request + NEBOC_IR_PERMIT_CONSTANT_OFFSET], rax
    jne fail
    mov rax, [rel ir_request + NEBOC_IR_INFERRED_EFFECTS_OFFSET]
    cmp [rel ir_request + NEBOC_IR_EFFECTIVE_MASK_OFFSET], rax
    jne fail
    cmp qword [rel ir_request + neboc_effects_capabilities_e_politicas_IR_DIAGNOSTIC_OFFSET], 0
    jne fail
    cmp qword [rel ir_request + neboc_effects_capabilities_e_politicas_IR_ALLOCATIONS_OFFSET], 0
    jne fail
    mov rax, [r14 + 24]
    cmp [rel ir_request + neboc_effects_capabilities_e_politicas_IR_HASH_OFFSET], rax
    jne fail
    jmp .next_ir

.negative_ir:
    lea rsi, [rel ir_request + neboc_effects_capabilities_e_politicas_IR_OUTPUT_OFFSET]
    xor edx, edx
.negative_output_loop:
    cmp edx, 9
    jne .negative_zero
    cmp qword [rsi], neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    jne fail
    jmp .negative_output_next
.negative_zero:
    cmp qword [rsi], 0
    jne fail
.negative_output_next:
    add rsi, 8
    inc edx
    cmp edx, neboc_effects_capabilities_e_politicas_IR_OUTPUT_QWORDS
    jb .negative_output_loop
.next_ir:
    add r14, 4*8
    inc r13d
    dec r15d
    jnz .ir_loop

    ; Authenticated hardening probes reach invariants bundled by I08-I10 one
    ; at a time: parser identity, cost, allocations, flags and source bounds.
    mov r13d, 121
    lea rsi, [rel sem_s01]
    call prepare_ir_case
    mov rax, 0xd76cc3ae969d8625
    mov [rel ir_request + NEBOC_IR_PARSER_HASH_OFFSET], rax
    mov rax, 0x8fbd41436d1d5b43
    mov [rel ir_request + neboc_effects_capabilities_e_politicas_IR_SEMANTIC_HASH_OFFSET], rax
    call expect_ir_invalid

    inc r13d
    lea rsi, [rel sem_s01]
    call prepare_ir_case
    mov qword [rel ir_request + NEBOC_IR_COST_OFFSET], 2
    mov rax, 0xdcdbef7b06f5f8c9
    mov [rel ir_request + neboc_effects_capabilities_e_politicas_IR_SEMANTIC_HASH_OFFSET], rax
    call expect_ir_invalid

    inc r13d
    lea rsi, [rel sem_s01]
    call prepare_ir_case
    mov qword [rel ir_request + NEBOC_IR_SEMANTIC_ALLOCATIONS_OFFSET], 1
    call expect_ir_invalid

    inc r13d
    lea rsi, [rel sem_s01]
    call prepare_ir_case
    mov qword [rel ir_request + NEBOC_IR_SEMANTIC_FLAGS_OFFSET], 3
    mov rax, 0x3976a0cb3018ebbe
    mov [rel ir_request + neboc_effects_capabilities_e_politicas_IR_SEMANTIC_HASH_OFFSET], rax
    call expect_ir_invalid

    inc r13d
    lea rsi, [rel sem_s01]
    call prepare_ir_case
    mov qword [rel ir_request + NEBOC_IR_SOURCE_END_OFFSET], 0
    mov rax, 0x958cc726cb630f9e
    mov [rel ir_request + neboc_effects_capabilities_e_politicas_IR_SEMANTIC_HASH_OFFSET], rax
    call expect_ir_invalid

    inc r13d
    lea rsi, [rel sem_s01]
    call prepare_ir_case
    mov qword [rel ir_request + NEBOC_IR_SOURCE_END_OFFSET], 4097
    mov rax, 0xfacdbdc4e86b67ef
    mov [rel ir_request + neboc_effects_capabilities_e_politicas_IR_SEMANTIC_HASH_OFFSET], rax
    call expect_ir_invalid

    ; Real parser -> semantic -> IR chain for the canonical public proof.
    mov r13d, 201
    lea rdi, [rel parse_request]
    mov ecx, neboc_effects_capabilities_e_politicas_PARSE_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    lea rdi, [rel parsed_policy]
    mov ecx, NEBOC_POLICY_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    lea rax, [rel policy_source]
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_OFFSET], rax
    mov qword [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_SOURCE_LENGTH_OFFSET], policy_source_len
    lea rax, [rel parsed_policy]
    mov [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_OUTPUT_OFFSET], rax
    lea rdi, [rel parse_request]
    call neboc_policy_parse
    test eax, eax
    jnz fail
    mov rax, 0xd76cc3ae969d8624
    cmp [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_CANONICAL_HASH_OFFSET], rax
    jne fail

    call clear_semantic
%macro PIPE_COPY 2
    mov rax, [rel parsed_policy + %1]
    mov [rel semantic_request + %2], rax
%endmacro
    PIPE_COPY NEBOC_POLICY_DECLARED_EFFECTS_OFFSET, NEBOC_SEMANTIC_DECLARED_EFFECTS_OFFSET
    PIPE_COPY NEBOC_POLICY_CAPABILITIES_OFFSET, NEBOC_SEMANTIC_CAPABILITIES_OFFSET
    PIPE_COPY NEBOC_POLICY_ALLOW_OFFSET, NEBOC_SEMANTIC_ALLOW_OFFSET
    PIPE_COPY NEBOC_POLICY_DENY_OFFSET, NEBOC_SEMANTIC_DENY_OFFSET
    PIPE_COPY NEBOC_POLICY_BUDGET_OFFSET, NEBOC_SEMANTIC_BUDGET_OFFSET
    PIPE_COPY NEBOC_POLICY_TRUST_OFFSET, NEBOC_SEMANTIC_TRUST_OFFSET
    PIPE_COPY NEBOC_POLICY_AUDIT_ID_OFFSET, NEBOC_SEMANTIC_AUDIT_ID_OFFSET
    PIPE_COPY NEBOC_POLICY_PERMIT_OFFSET, NEBOC_SEMANTIC_PERMIT_OFFSET
    mov rax, [rel parse_request + neboc_effects_capabilities_e_politicas_PARSE_CANONICAL_HASH_OFFSET]
    mov [rel semantic_request + NEBOC_SEMANTIC_PARSER_HASH_OFFSET], rax
    mov rax, [rel parse_request + NEBOC_PARSE_CLAUSE_MASK_OFFSET]
    mov [rel semantic_request + NEBOC_SEMANTIC_CLAUSE_MASK_OFFSET], rax
    mov rax, [rel parsed_policy + NEBOC_POLICY_DIRECT_EFFECTS_OFFSET]
    mov [rel semantic_request + NEBOC_SEMANTIC_RESOLVED_DIRECT_EFFECTS_OFFSET], rax
    mov qword [rel semantic_request + NEBOC_SEMANTIC_SOURCE_START_OFFSET], 0
    mov qword [rel semantic_request + NEBOC_SEMANTIC_SOURCE_END_OFFSET], policy_source_len
    mov qword [rel semantic_request + NEBOC_SEMANTIC_FLAGS_OFFSET], NEBOC_SEMANTIC_FLAG_REQUIRED
    lea rdi, [rel semantic_request]
    call neboc_policy_semantic_analyze
    test eax, eax
    jnz fail
    mov rax, 0x6ad0de38d581ae03
    cmp [rel semantic_request + neboc_effects_capabilities_e_politicas_SEMANTIC_HASH_OFFSET], rax
    jne fail
    cmp qword [rel semantic_request + neboc_effects_capabilities_e_politicas_SEMANTIC_ALLOCATIONS_OFFSET], 0
    jne fail

    call clear_ir
    lea rsi, [rel semantic_request]
    lea rdi, [rel ir_request]
    mov ecx, neboc_effects_capabilities_e_politicas_SEMANTIC_REQUEST_QWORDS
    rep movsq
    lea rdi, [rel ir_request]
    call neboc_policy_ir_lower
    test eax, eax
    jnz fail
    mov rax, 0x1be0bb791809c755
    cmp [rel ir_request + neboc_effects_capabilities_e_politicas_IR_HASH_OFFSET], rax
    jne fail
    cmp qword [rel ir_request + neboc_effects_capabilities_e_politicas_IR_ALLOCATIONS_OFFSET], 0
    jne fail

    ; Repeated analysis/lowering is bit-for-bit deterministic.
    lea rdi, [rel semantic_request]
    call neboc_policy_semantic_analyze
    test eax, eax
    jnz fail
    mov rax, 0x6ad0de38d581ae03
    cmp [rel semantic_request + neboc_effects_capabilities_e_politicas_SEMANTIC_HASH_OFFSET], rax
    jne fail
    lea rdi, [rel ir_request]
    call neboc_policy_ir_lower
    test eax, eax
    jnz fail
    mov rax, 0x1be0bb791809c755
    cmp [rel ir_request + neboc_effects_capabilities_e_politicas_IR_HASH_OFFSET], rax
    jne fail

    ; Null/misaligned requests are rejected without a write.
    mov r13d, 202
    xor edi, edi
    call neboc_policy_semantic_analyze
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    mov rax, 0x1122334455667788
    mov [rel semantic_request], rax
    mov [rel semantic_request + neboc_effects_capabilities_e_politicas_SEMANTIC_ALLOCATIONS_OFFSET], rax
    lea rdi, [rel semantic_request + 1]
    call neboc_policy_semantic_analyze
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    mov rax, 0x1122334455667788
    cmp [rel semantic_request], rax
    jne fail
    cmp [rel semantic_request + neboc_effects_capabilities_e_politicas_SEMANTIC_ALLOCATIONS_OFFSET], rax
    jne fail
    xor edi, edi
    call neboc_policy_ir_lower
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    mov rax, 0x8877665544332211
    mov [rel ir_request], rax
    mov [rel ir_request + neboc_effects_capabilities_e_politicas_IR_HASH_OFFSET], rax
    lea rdi, [rel ir_request + 1]
    call neboc_policy_ir_lower
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    mov rax, 0x8877665544332211
    cmp [rel ir_request], rax
    jne fail
    cmp [rel ir_request + neboc_effects_capabilities_e_politicas_IR_HASH_OFFSET], rax
    jne fail

    ; SysV callee-saved registers survive and DF is clear on both public APIs.
    mov r13d, 203
    lea rsi, [rel sem_s01]
    call prepare_semantic_case
    mov rbx, 0x11111111
    mov rbp, 0x22222222
    mov r12, 0x33333333
    mov r13, 0x44444444
    mov r14, 0x55555555
    mov r15, 0x66666666
    std
    lea rdi, [rel semantic_request]
    call neboc_policy_semantic_analyze
    test eax, eax
    jnz fail_abi
    cmp rbx, 0x11111111
    jne fail_abi
    cmp rbp, 0x22222222
    jne fail_abi
    cmp r12, 0x33333333
    jne fail_abi
    cmp r13, 0x44444444
    jne fail_abi
    cmp r14, 0x55555555
    jne fail_abi
    cmp r15, 0x66666666
    jne fail_abi
    pushfq
    pop rax
    test rax, 1 << 10
    jnz fail_abi

    lea rsi, [rel sem_s01]
    call prepare_ir_case
    mov rbx, 0x11111111
    mov rbp, 0x22222222
    mov r12, 0x33333333
    mov r13, 0x44444444
    mov r14, 0x55555555
    mov r15, 0x66666666
    std
    lea rdi, [rel ir_request]
    call neboc_policy_ir_lower
    test eax, eax
    jnz fail_abi
    cmp rbx, 0x11111111
    jne fail_abi
    cmp rbp, 0x22222222
    jne fail_abi
    cmp r12, 0x33333333
    jne fail_abi
    cmp r13, 0x44444444
    jne fail_abi
    cmp r14, 0x55555555
    jne fail_abi
    cmp r15, 0x66666666
    jne fail_abi
    pushfq
    pop rax
    test rax, 1 << 10
    jnz fail_abi

pass:
    xor edi, edi
    jmp neboc_host_process_exit
fail_abi:
    cld
    mov edi, 203
    jmp neboc_host_process_exit
fail:
    cld
    mov edi, r13d
    test edi, edi
    jnz .exit
    mov edi, 255
.exit:
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
