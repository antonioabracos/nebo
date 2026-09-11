; RF166-G157-F04 resolved typed declared/possible/unused error sets.
bits 64
default rel
%include "compiler/semantic/docs/doc_validation.inc"
global neboc_doc_error_validate
global neboc_doc_validate_errors
section .text
neboc_doc_error_validate:
neboc_doc_validate_errors:
 DOCV_VALIDATE_REQUEST .validated
.validated:
 mov r8,[rdi+NEBOC_DOCV_SYMBOL_ERRORS_OFFSET]
 mov r9,[rdi+NEBOC_DOCV_DOC_ERRORS_OFFSET]
 mov rax,r8
 not rax
 and rax,r9
 jnz .extra
 mov rax,r9
 not rax
 and rax,r8
 jnz .missing
 DOCV_PUBLISH_NONE
.missing:
 mov r10,NEBOC_DOCV_SEVERITY_WARNING
 test qword [rdi+NEBOC_DOCV_POLICY_FLAGS_OFFSET],NEBOC_DOCV_POLICY_CONTRADICTIONS_ERROR
 jz .missing_ready
 mov r10,NEBOC_DOCV_SEVERITY_ERROR
.missing_ready:
 DOCV_PUBLISH_ISSUE NEBOC_DOCV_CODE_ERRORS_MISSING,r10,r8,r9,NEBOC_DOCV_FIX_SCAFFOLD_FIELD
.extra:
 DOCV_PUBLISH_ISSUE NEBOC_DOCV_CODE_ERRORS_EXTRA,NEBOC_DOCV_SEVERITY_WARNING,r8,r9,NEBOC_DOCV_FIX_NONE
section .note.GNU-stack noalloc noexec nowrite progbits
