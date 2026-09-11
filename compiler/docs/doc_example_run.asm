; RF166-G158-F03 expected exit/output and deny-by-default execution policy.
bits 64
default rel
%include "compiler/docs/doc_examples.inc"
global neboc_doc_example_run
global neboc_doc_example_expected_output
global neboc_doc_example_isolate
section .text
neboc_doc_example_run:
neboc_doc_example_expected_output:
neboc_doc_example_isolate:
 DOCX_VALIDATE_REQUEST NEBOC_DOCX_OP_RUN,.validated
.validated:
 cmp qword [rdi+NEBOC_DOCX_KIND_OFFSET],NEBOC_DOCX_KIND_EXAMPLE
 jne .contract
 mov rax,[rdi+NEBOC_DOCX_FLAGS_OFFSET]
 test rax,NEBOC_DOCX_FLAG_TARGET_SUPPORTED
 jz .policy
 test rax,NEBOC_DOCX_FLAG_RUNTIME_ALLOWED
 jz .policy
 mov r8,[rdi+NEBOC_DOCX_DECLARED_EFFECTS_OFFSET]
 mov r9,[rdi+NEBOC_DOCX_ALLOWED_EFFECTS_OFFSET]
 not r9
 test r8,r9
 jnz .policy
 mov r8,[rdi+NEBOC_DOCX_DECLARED_CAPS_OFFSET]
 mov r9,[rdi+NEBOC_DOCX_GRANTED_CAPS_OFFSET]
 not r9
 test r8,r9
 jnz .policy
 mov r8,[rdi+NEBOC_DOCX_OUTPUT_LIMIT_OFFSET]
 test r8,r8
 jz .limit
 cmp r8,NEBOC_DOCX_MAX_OUTPUT_BYTES
 ja .limit
 cmp qword [rdi+NEBOC_DOCX_EXPECTED_EXIT_OFFSET],255
 ja .contract
 mov r9,[rdi+NEBOC_DOCX_OBSERVED_EXIT_OFFSET]
 cmp r9,NEBOC_DOCX_OBSERVED_PENDING
 je .authorized
 cmp r9,255
 ja .mismatch
 mov rax,[rdi+NEBOC_DOCX_OUTPUT_BYTES_OFFSET]
 cmp rax,r8
 ja .limit
 cmp r9,[rdi+NEBOC_DOCX_EXPECTED_EXIT_OFFSET]
 jne .mismatch
 mov r8,[rdi+NEBOC_DOCX_SNIPPET_DIGEST_OFFSET]
 xor r8,[rdi+NEBOC_DOCX_RAW_OUTPUT_DIGEST_OFFSET]
 DOCX_PUBLISH r8,NEBOC_DOCX_CLASS_MATCH,[rdi+NEBOC_DOCX_EXPECTED_EXIT_OFFSET],r9
.authorized:
 mov r8,[rdi+NEBOC_DOCX_SNIPPET_DIGEST_OFFSET]
 DOCX_PUBLISH r8,NEBOC_DOCX_CLASS_READY,[rdi+NEBOC_DOCX_EXPECTED_EXIT_OFFSET],NEBOC_DOCX_OBSERVED_PENDING
.contract:
 mov eax,NEBOC_DOCX_STATUS_CONTRACT
 ret
.policy:
 mov eax,NEBOC_DOCX_STATUS_POLICY
 ret
.mismatch:
 mov eax,NEBOC_DOCX_STATUS_MISMATCH
 ret
.limit:
 mov eax,NEBOC_DOCX_STATUS_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
