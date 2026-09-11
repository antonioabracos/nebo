; RF166-G158-F01 DocExamplePlan validation and isolated context identity.
bits 64
default rel
%include "compiler/docs/doc_examples.inc"
global neboc_doc_example_plan
section .text
neboc_doc_example_plan:
 DOCX_VALIDATE_REQUEST NEBOC_DOCX_OP_PLAN,.validated
.validated:
 cmp qword [rdi+NEBOC_DOCX_SYMBOL_ID_OFFSET],0
 je .contract
 cmp qword [rdi+NEBOC_DOCX_FIXTURE_ID_OFFSET],0
 je .contract
 cmp qword [rdi+NEBOC_DOCX_SOURCE_DIGEST_OFFSET],0
 je .contract
 cmp qword [rdi+NEBOC_DOCX_CONTEXT_DIGEST_OFFSET],0
 je .contract
 cmp qword [rdi+NEBOC_DOCX_SNIPPET_DIGEST_OFFSET],0
 je .contract
 mov rax,[rdi+NEBOC_DOCX_KIND_OFFSET]
 cmp rax,NEBOC_DOCX_KIND_EXAMPLE
 jb .contract
 cmp rax,NEBOC_DOCX_KIND_LAW
 ja .contract
 test qword [rdi+NEBOC_DOCX_FLAGS_OFFSET],NEBOC_DOCX_FLAG_TARGET_SUPPORTED
 jz .policy
 mov rax,[rdi+NEBOC_DOCX_TIMEOUT_MS_OFFSET]
 test rax,rax
 jz .limit
 cmp rax,NEBOC_DOCX_MAX_TIMEOUT_MS
 ja .limit
 mov rax,[rdi+NEBOC_DOCX_OUTPUT_LIMIT_OFFSET]
 test rax,rax
 jz .limit
 cmp rax,NEBOC_DOCX_MAX_OUTPUT_BYTES
 ja .limit
 mov r8,[rdi+NEBOC_DOCX_SOURCE_DIGEST_OFFSET]
 xor r8,[rdi+NEBOC_DOCX_CONTEXT_DIGEST_OFFSET]
 rol r8,17
 xor r8,[rdi+NEBOC_DOCX_SNIPPET_DIGEST_OFFSET]
 xor r8,[rdi+NEBOC_DOCX_FIXTURE_ID_OFFSET]
 DOCX_PUBLISH r8,NEBOC_DOCX_CLASS_READY,[rdi+NEBOC_DOCX_KIND_OFFSET],[rdi+NEBOC_DOCX_TARGET_ID_OFFSET]
.contract:
 mov eax,NEBOC_DOCX_STATUS_CONTRACT
 ret
.policy:
 mov eax,NEBOC_DOCX_STATUS_POLICY
 ret
.limit:
 mov eax,NEBOC_DOCX_STATUS_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
