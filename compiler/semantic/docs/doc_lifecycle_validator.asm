; RF166-G157-F07 resolved lifecycle, edition and target availability.
bits 64
default rel
%include "compiler/semantic/docs/doc_validation.inc"
global neboc_doc_lifecycle_validate
global neboc_doc_validate_lifecycle
global neboc_doc_validate_target_availability
section .text
neboc_doc_lifecycle_validate:
neboc_doc_validate_lifecycle:
 DOCV_VALIDATE_REQUEST .lifecycle
.lifecycle:
 mov r8,[rdi+NEBOC_DOCV_CURRENT_VERSION_OFFSET]
 mov r9,[rdi+NEBOC_DOCV_SINCE_OFFSET]
 cmp r9,r8
 ja .life_issue
 mov rax,[rdi+NEBOC_DOCV_DEPRECATED_OFFSET]
 test rax,rax
 jz neboc_doc_validate_target_availability.validated
 cmp rax,r9
 jb .life_issue
 jmp neboc_doc_validate_target_availability.validated
.life_issue:
 DOCV_PUBLISH_ISSUE NEBOC_DOCV_CODE_LIFECYCLE,NEBOC_DOCV_SEVERITY_WARNING,r8,r9,NEBOC_DOCV_FIX_NONE
neboc_doc_validate_target_availability:
 DOCV_VALIDATE_REQUEST neboc_doc_validate_target_availability.validated
.validated:
 mov r8,[rdi+NEBOC_DOCV_ACTIVE_TARGET_OFFSET]
 mov r9,[rdi+NEBOC_DOCV_DOC_TARGET_OFFSET]
 test r9,r9
 jz .same
 test r8,r9
 jz .target_issue
.same:
 DOCV_PUBLISH_NONE
.target_issue:
 DOCV_PUBLISH_ISSUE NEBOC_DOCV_CODE_TARGET,NEBOC_DOCV_SEVERITY_ERROR,r8,r9,NEBOC_DOCV_FIX_NONE
section .note.GNU-stack noalloc noexec nowrite progbits
