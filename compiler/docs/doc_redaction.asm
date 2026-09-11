; RF166-G158-F07 output privacy and host-path redaction validation.
bits 64
default rel
%include "compiler/docs/doc_examples.inc"
global neboc_doc_redaction
global neboc_doc_example_redact
section .text
neboc_doc_redaction:
neboc_doc_example_redact:
 DOCX_VALIDATE_REQUEST NEBOC_DOCX_OP_REDACTION,.validated
.validated:
 mov r8,[rdi+NEBOC_DOCX_PRIVACY_OFFSET]
 cmp r8,NEBOC_DOCX_PRIVACY_PUBLIC
 jb .contract
 cmp r8,NEBOC_DOCX_PRIVACY_SECRET
 ja .contract
 test qword [rdi+NEBOC_DOCX_FLAGS_OFFSET],NEBOC_DOCX_FLAG_SECRET_LEAK
 jnz .policy
 mov r9,[rdi+NEBOC_DOCX_RAW_OUTPUT_DIGEST_OFFSET]
 mov r10,[rdi+NEBOC_DOCX_PUBLISHED_OUTPUT_DIGEST_OFFSET]
 test r9,r9
 jz .contract
 test r10,r10
 jz .contract
 cmp r8,NEBOC_DOCX_PRIVACY_PUBLIC
 jne .sensitive
 cmp r9,r10
 jne .mismatch
 DOCX_PUBLISH r10,NEBOC_DOCX_CLASS_PUBLIC,r9,r10
.sensitive:
 test qword [rdi+NEBOC_DOCX_FLAGS_OFFSET],NEBOC_DOCX_FLAG_PATH_REDACTED
 jz .policy
 cmp r9,r10
 je .policy
 DOCX_PUBLISH r10,NEBOC_DOCX_CLASS_REDACTED,r9,r10
.contract:
 mov eax,NEBOC_DOCX_STATUS_CONTRACT
 ret
.policy:
 mov eax,NEBOC_DOCX_STATUS_POLICY
 ret
.mismatch:
 mov eax,NEBOC_DOCX_STATUS_MISMATCH
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
