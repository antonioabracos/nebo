; RF166-G158-F04 deterministic bounded law corpus validation.
bits 64
default rel
%include "compiler/docs/doc_examples.inc"
global neboc_doc_law_run
global neboc_doc_law_run_corpus
section .text
neboc_doc_law_run:
neboc_doc_law_run_corpus:
 DOCX_VALIDATE_REQUEST NEBOC_DOCX_OP_LAW,.validated
.validated:
 cmp qword [rdi+NEBOC_DOCX_KIND_OFFSET],NEBOC_DOCX_KIND_LAW
 jne .contract
 cmp qword [rdi+NEBOC_DOCX_SEED_OFFSET],0
 je .contract
 mov r8,[rdi+NEBOC_DOCX_BUDGET_OFFSET]
 test r8,r8
 jz .limit
 cmp r8,NEBOC_DOCX_MAX_BUDGET
 ja .limit
 cmp qword [rdi+NEBOC_DOCX_OBSERVED_CASES_OFFSET],r8
 jne .mismatch
 cmp qword [rdi+NEBOC_DOCX_OBSERVED_FAILURES_OFFSET],0
 jne .mismatch
 mov r9,[rdi+NEBOC_DOCX_SEED_OFFSET]
 rol r9,29
 xor r9,[rdi+NEBOC_DOCX_SNIPPET_DIGEST_OFFSET]
 xor r9,r8
 DOCX_PUBLISH r9,NEBOC_DOCX_CLASS_LAW_PASS,r8,[rdi+NEBOC_DOCX_OBSERVED_CASES_OFFSET]
.contract:
 mov eax,NEBOC_DOCX_STATUS_CONTRACT
 ret
.mismatch:
 mov eax,NEBOC_DOCX_STATUS_MISMATCH
 ret
.limit:
 mov eax,NEBOC_DOCX_STATUS_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
