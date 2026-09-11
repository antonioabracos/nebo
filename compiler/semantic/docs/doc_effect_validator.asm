; RF166-G157-F05 resolved effect and capability reconciliation.
bits 64
default rel
%include "compiler/semantic/docs/doc_validation.inc"
global neboc_doc_effect_validate
global neboc_doc_validate_effects
global neboc_doc_validate_capabilities
section .text
neboc_doc_effect_validate:
neboc_doc_validate_effects:
 DOCV_VALIDATE_REQUEST .effects
.effects:
 mov r8,[rdi+NEBOC_DOCV_SYMBOL_EFFECTS_OFFSET]
 mov r9,[rdi+NEBOC_DOCV_DOC_EFFECTS_OFFSET]
 cmp r8,r9
 jne .effect_issue
 jmp neboc_doc_validate_capabilities.validated
.effect_issue:
 mov r10,NEBOC_DOCV_SEVERITY_WARNING
 test qword [rdi+NEBOC_DOCV_POLICY_FLAGS_OFFSET],NEBOC_DOCV_POLICY_CONTRADICTIONS_ERROR
 jz .effect_ready
 mov r10,NEBOC_DOCV_SEVERITY_ERROR
.effect_ready:
 DOCV_PUBLISH_ISSUE NEBOC_DOCV_CODE_EFFECTS,r10,r8,r9,NEBOC_DOCV_FIX_NONE
neboc_doc_validate_capabilities:
 DOCV_VALIDATE_REQUEST neboc_doc_validate_capabilities.validated
.validated:
 mov r8,[rdi+NEBOC_DOCV_SYMBOL_CAPABILITIES_OFFSET]
 mov r9,[rdi+NEBOC_DOCV_DOC_CAPABILITIES_OFFSET]
 cmp r8,r9
 jne .cap_issue
 DOCV_PUBLISH_NONE
.cap_issue:
 mov r10,NEBOC_DOCV_SEVERITY_WARNING
 test qword [rdi+NEBOC_DOCV_POLICY_FLAGS_OFFSET],NEBOC_DOCV_POLICY_CONTRADICTIONS_ERROR
 jz .cap_ready
 mov r10,NEBOC_DOCV_SEVERITY_ERROR
.cap_ready:
 DOCV_PUBLISH_ISSUE NEBOC_DOCV_CODE_CAPABILITIES,r10,r8,r9,NEBOC_DOCV_FIX_SCAFFOLD_FIELD
section .note.GNU-stack noalloc noexec nowrite progbits
