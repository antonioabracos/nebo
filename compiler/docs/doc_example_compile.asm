; RF166-G158-F02 compiler tri-mode evidence validation.
bits 64
default rel
%include "compiler/docs/doc_examples.inc"
global neboc_doc_example_compile
global neboc_doc_law_compile_property
section .text
neboc_doc_example_compile:
neboc_doc_law_compile_property:
 DOCX_VALIDATE_REQUEST NEBOC_DOCX_OP_COMPILE,.validated
.validated:
 cmp qword [rdi+NEBOC_DOCX_SYMBOL_ID_OFFSET],0
 je .contract
 cmp qword [rdi+NEBOC_DOCX_FIXTURE_ID_OFFSET],0
 je .contract
 cmp qword [rdi+NEBOC_DOCX_REQUESTED_MODES_OFFSET],NEBOC_DOCX_TRI_MODE
 jne .contract
 cmp qword [rdi+NEBOC_DOCX_OBSERVED_MODES_OFFSET],NEBOC_DOCX_TRI_MODE
 jne .mismatch
 test qword [rdi+NEBOC_DOCX_FLAGS_OFFSET],NEBOC_DOCX_FLAG_TARGET_SUPPORTED
 jz .policy
 mov r8,[rdi+NEBOC_DOCX_CONTEXT_DIGEST_OFFSET]
 xor r8,[rdi+NEBOC_DOCX_SNIPPET_DIGEST_OFFSET]
 rol r8,23
 xor r8,[rdi+NEBOC_DOCX_SOURCE_DIGEST_OFFSET]
 DOCX_PUBLISH r8,NEBOC_DOCX_CLASS_COMPILED,NEBOC_DOCX_TRI_MODE,[rdi+NEBOC_DOCX_OBSERVED_MODES_OFFSET]
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
