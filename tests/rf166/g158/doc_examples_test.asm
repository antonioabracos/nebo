; RF166-G158 native contract, policy, classification, and atomicity test.
bits 64
default rel
%include "compiler/docs/doc_examples.inc"
global _start
extern neboc_doc_example_plan
extern neboc_doc_example_compile
extern neboc_doc_example_run
extern neboc_doc_law_run
extern neboc_doc_staleness
extern neboc_doc_compatibility
extern neboc_doc_redaction

%define SENTINEL 0xa5a5a5a5a5a5a5a5

section .text
_start:
 ; F01: a complete example plan is admitted and malformed input is atomic.
 call initialize
 mov qword [rel request+NEBOC_DOCX_OPERATION_OFFSET],NEBOC_DOCX_OP_PLAN
 lea rdi,[rel request]
 lea rsi,[rel result]
 call neboc_doc_example_plan
 test eax,eax
 jnz fail
 cmp qword [rel result+NEBOC_DOCX_RESULT_CLASS_OFFSET],NEBOC_DOCX_CLASS_READY
 jne fail
 call initialize
 mov qword [rel request+NEBOC_DOCX_OPERATION_OFFSET],NEBOC_DOCX_OP_PLAN
 mov qword [rel request+NEBOC_DOCX_SNIPPET_DIGEST_OFFSET],0
 lea rdi,[rel request]
 lea rsi,[rel result]
 call neboc_doc_example_plan
 cmp eax,NEBOC_DOCX_STATUS_CONTRACT
 jne fail
 call assert_atomic

 ; F02: check, emit-asm, and build evidence must all be observed.
 call initialize
 mov qword [rel request+NEBOC_DOCX_OPERATION_OFFSET],NEBOC_DOCX_OP_COMPILE
 mov qword [rel request+NEBOC_DOCX_REQUESTED_MODES_OFFSET],NEBOC_DOCX_TRI_MODE
 mov qword [rel request+NEBOC_DOCX_OBSERVED_MODES_OFFSET],NEBOC_DOCX_TRI_MODE
 lea rdi,[rel request]
 lea rsi,[rel result]
 call neboc_doc_example_compile
 test eax,eax
 jnz fail
 cmp qword [rel result+NEBOC_DOCX_RESULT_CLASS_OFFSET],NEBOC_DOCX_CLASS_COMPILED
 jne fail
 mov qword [rel request+NEBOC_DOCX_OBSERVED_MODES_OFFSET],NEBOC_DOCX_MODE_CHECK
 call reset_result
 lea rdi,[rel request]
 lea rsi,[rel result]
 call neboc_doc_example_compile
 cmp eax,NEBOC_DOCX_STATUS_MISMATCH
 jne fail
 call assert_atomic

 ; F03: preflight authorization precedes execution; observations must match.
 call initialize
 mov qword [rel request+NEBOC_DOCX_OPERATION_OFFSET],NEBOC_DOCX_OP_RUN
 mov qword [rel request+NEBOC_DOCX_FLAGS_OFFSET],NEBOC_DOCX_FLAG_TARGET_SUPPORTED | NEBOC_DOCX_FLAG_RUNTIME_ALLOWED
 mov qword [rel request+NEBOC_DOCX_EXPECTED_EXIT_OFFSET],43
 mov rax,NEBOC_DOCX_OBSERVED_PENDING
 mov [rel request+NEBOC_DOCX_OBSERVED_EXIT_OFFSET],rax
 lea rdi,[rel request]
 lea rsi,[rel result]
 call neboc_doc_example_run
 test eax,eax
 jnz fail
 cmp qword [rel result+NEBOC_DOCX_RESULT_CLASS_OFFSET],NEBOC_DOCX_CLASS_READY
 jne fail
 mov qword [rel request+NEBOC_DOCX_OBSERVED_EXIT_OFFSET],43
 mov qword [rel request+NEBOC_DOCX_OUTPUT_BYTES_OFFSET],0
 call reset_result
 lea rdi,[rel request]
 lea rsi,[rel result]
 call neboc_doc_example_run
 test eax,eax
 jnz fail
 cmp qword [rel result+NEBOC_DOCX_RESULT_CLASS_OFFSET],NEBOC_DOCX_CLASS_MATCH
 jne fail
 mov qword [rel request+NEBOC_DOCX_DECLARED_EFFECTS_OFFSET],2
 call reset_result
 lea rdi,[rel request]
 lea rsi,[rel result]
 call neboc_doc_example_run
 cmp eax,NEBOC_DOCX_STATUS_POLICY
 jne fail
 call assert_atomic

 ; F04: laws are deterministic and bounded, without a universal claim.
 call initialize
 mov qword [rel request+NEBOC_DOCX_OPERATION_OFFSET],NEBOC_DOCX_OP_LAW
 mov qword [rel request+NEBOC_DOCX_KIND_OFFSET],NEBOC_DOCX_KIND_LAW
 mov qword [rel request+NEBOC_DOCX_SEED_OFFSET],158
 mov qword [rel request+NEBOC_DOCX_BUDGET_OFFSET],8
 mov qword [rel request+NEBOC_DOCX_OBSERVED_CASES_OFFSET],8
 lea rdi,[rel request]
 lea rsi,[rel result]
 call neboc_doc_law_run
 test eax,eax
 jnz fail
 cmp qword [rel result+NEBOC_DOCX_RESULT_CLASS_OFFSET],NEBOC_DOCX_CLASS_LAW_PASS
 jne fail
 mov qword [rel request+NEBOC_DOCX_OBSERVED_FAILURES_OFFSET],1
 call reset_result
 lea rdi,[rel request]
 lea rsi,[rel result]
 call neboc_doc_law_run
 cmp eax,NEBOC_DOCX_STATUS_MISMATCH
 jne fail
 call assert_atomic

 ; F05: fresh, stale, and explicit identity-preserving refactor states.
 call initialize
 mov qword [rel request+NEBOC_DOCX_OPERATION_OFFSET],NEBOC_DOCX_OP_STALENESS
 mov qword [rel request+NEBOC_DOCX_CURRENT_SIGNATURE_OFFSET],0x1111
 mov qword [rel request+NEBOC_DOCX_NEW_SYMBOL_ID_OFFSET],0x2222
 lea rdi,[rel request]
 lea rsi,[rel result]
 call neboc_doc_staleness
 test eax,eax
 jnz fail
 cmp qword [rel result+NEBOC_DOCX_RESULT_CLASS_OFFSET],NEBOC_DOCX_CLASS_FRESH
 jne fail
 mov qword [rel request+NEBOC_DOCX_PREVIOUS_SIGNATURE_OFFSET],0x3333
 mov qword [rel request+NEBOC_DOCX_OLD_SYMBOL_ID_OFFSET],0x4444
 call reset_result
 lea rdi,[rel request]
 lea rsi,[rel result]
 call neboc_doc_staleness
 test eax,eax
 jnz fail
 cmp qword [rel result+NEBOC_DOCX_RESULT_CLASS_OFFSET],NEBOC_DOCX_CLASS_STALE
 jne fail
 mov qword [rel request+NEBOC_DOCX_FLAGS_OFFSET],NEBOC_DOCX_FLAG_TARGET_SUPPORTED | NEBOC_DOCX_FLAG_REFACTOR_MAP
 mov qword [rel request+NEBOC_DOCX_DOC_REVISION_OFFSET],7
 mov qword [rel request+NEBOC_DOCX_OLD_DOC_REVISION_OFFSET],7
 call reset_result
 lea rdi,[rel request]
 lea rsi,[rel result]
 call neboc_doc_staleness
 test eax,eax
 jnz fail
 cmp qword [rel result+NEBOC_DOCX_RESULT_CLASS_OFFSET],NEBOC_DOCX_CLASS_PRESERVED
 jne fail

 ; F06: compatibility is additive, compatible, breaking, or unknown.
 call initialize
 mov qword [rel request+NEBOC_DOCX_OPERATION_OFFSET],NEBOC_DOCX_OP_COMPATIBILITY
 mov qword [rel request+NEBOC_DOCX_FLAGS_OFFSET],NEBOC_DOCX_FLAG_NEW_PRESENT
 mov qword [rel request+NEBOC_DOCX_NEW_API_DIGEST_OFFSET],0x5151
 lea rdi,[rel request]
 lea rsi,[rel result]
 call neboc_doc_compatibility
 test eax,eax
 jnz fail
 cmp qword [rel result+NEBOC_DOCX_RESULT_CLASS_OFFSET],NEBOC_DOCX_CLASS_ADDITIVE
 jne fail
 mov qword [rel request+NEBOC_DOCX_FLAGS_OFFSET],NEBOC_DOCX_FLAG_OLD_PRESENT | NEBOC_DOCX_FLAG_NEW_PRESENT
 mov qword [rel request+NEBOC_DOCX_OLD_API_DIGEST_OFFSET],0x5151
 call reset_result
 lea rdi,[rel request]
 lea rsi,[rel result]
 call neboc_doc_compatibility
 test eax,eax
 jnz fail
 cmp qword [rel result+NEBOC_DOCX_RESULT_CLASS_OFFSET],NEBOC_DOCX_CLASS_COMPATIBLE
 jne fail
 mov qword [rel request+NEBOC_DOCX_NEW_API_DIGEST_OFFSET],0x6161
 call reset_result
 lea rdi,[rel request]
 lea rsi,[rel result]
 call neboc_doc_compatibility
 test eax,eax
 jnz fail
 cmp qword [rel result+NEBOC_DOCX_RESULT_CLASS_OFFSET],NEBOC_DOCX_CLASS_BREAKING
 jne fail
 mov qword [rel request+NEBOC_DOCX_FLAGS_OFFSET],0
 call reset_result
 lea rdi,[rel request]
 lea rsi,[rel result]
 call neboc_doc_compatibility
 test eax,eax
 jnz fail
 cmp qword [rel result+NEBOC_DOCX_RESULT_CLASS_OFFSET],NEBOC_DOCX_CLASS_UNKNOWN
 jne fail

 ; F07/F08: public output is exact; sensitive output requires redaction.
 call initialize
 mov qword [rel request+NEBOC_DOCX_OPERATION_OFFSET],NEBOC_DOCX_OP_REDACTION
 mov qword [rel request+NEBOC_DOCX_PRIVACY_OFFSET],NEBOC_DOCX_PRIVACY_PUBLIC
 mov qword [rel request+NEBOC_DOCX_RAW_OUTPUT_DIGEST_OFFSET],0x7171
 mov qword [rel request+NEBOC_DOCX_PUBLISHED_OUTPUT_DIGEST_OFFSET],0x7171
 lea rdi,[rel request]
 lea rsi,[rel result]
 call neboc_doc_redaction
 test eax,eax
 jnz fail
 cmp qword [rel result+NEBOC_DOCX_RESULT_CLASS_OFFSET],NEBOC_DOCX_CLASS_PUBLIC
 jne fail
 mov qword [rel request+NEBOC_DOCX_PRIVACY_OFFSET],NEBOC_DOCX_PRIVACY_SECRET
 mov qword [rel request+NEBOC_DOCX_PUBLISHED_OUTPUT_DIGEST_OFFSET],0x8181
 mov qword [rel request+NEBOC_DOCX_FLAGS_OFFSET],NEBOC_DOCX_FLAG_TARGET_SUPPORTED | NEBOC_DOCX_FLAG_PATH_REDACTED
 call reset_result
 lea rdi,[rel request]
 lea rsi,[rel result]
 call neboc_doc_redaction
 test eax,eax
 jnz fail
 cmp qword [rel result+NEBOC_DOCX_RESULT_CLASS_OFFSET],NEBOC_DOCX_CLASS_REDACTED
 jne fail
 or qword [rel request+NEBOC_DOCX_FLAGS_OFFSET],NEBOC_DOCX_FLAG_SECRET_LEAK
 call reset_result
 lea rdi,[rel request]
 lea rsi,[rel result]
 call neboc_doc_redaction
 cmp eax,NEBOC_DOCX_STATUS_POLICY
 jne fail
 call assert_atomic

 xor edi,edi
 jmp exit

initialize:
 lea rdi,[rel request]
 xor eax,eax
 mov ecx,NEBOC_DOCX_REQUEST_QWORDS
 rep stosq
 mov rax,NEBOC_DOCX_MAGIC
 mov [rel request+NEBOC_DOCX_MAGIC_OFFSET],rax
 mov qword [rel request+NEBOC_DOCX_VERSION_OFFSET],NEBOC_DOCX_VERSION
 mov qword [rel request+NEBOC_DOCX_SYMBOL_ID_OFFSET],0x111
 mov qword [rel request+NEBOC_DOCX_FIXTURE_ID_OFFSET],0x222
 mov qword [rel request+NEBOC_DOCX_SOURCE_DIGEST_OFFSET],0x333
 mov qword [rel request+NEBOC_DOCX_CONTEXT_DIGEST_OFFSET],0x444
 mov qword [rel request+NEBOC_DOCX_SNIPPET_DIGEST_OFFSET],0x555
 mov qword [rel request+NEBOC_DOCX_KIND_OFFSET],NEBOC_DOCX_KIND_EXAMPLE
 mov qword [rel request+NEBOC_DOCX_TARGET_ID_OFFSET],1
 mov qword [rel request+NEBOC_DOCX_TIMEOUT_MS_OFFSET],1000
 mov qword [rel request+NEBOC_DOCX_OUTPUT_LIMIT_OFFSET],1024
 mov qword [rel request+NEBOC_DOCX_FLAGS_OFFSET],NEBOC_DOCX_FLAG_TARGET_SUPPORTED
 jmp reset_result
reset_result:
 lea rdi,[rel result]
 mov rax,SENTINEL
 mov ecx,NEBOC_DOCX_RESULT_QWORDS
 rep stosq
 ret
assert_atomic:
 mov rax,SENTINEL
 lea rdi,[rel result]
 mov ecx,NEBOC_DOCX_RESULT_QWORDS
.atomic_loop:
 cmp [rdi],rax
 jne fail
 add rdi,8
 loop .atomic_loop
 ret
fail:
 mov edi,1
exit:
 mov eax,60
 syscall

section .bss
align 8
request: resq NEBOC_DOCX_REQUEST_QWORDS
result: resq NEBOC_DOCX_RESULT_QWORDS
section .note.GNU-stack noalloc noexec nowrite progbits
