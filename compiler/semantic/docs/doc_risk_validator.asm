; RF166-G157-F06 resolved ownership, cleanup, complexity and risk policy.
bits 64
default rel
%include "compiler/semantic/docs/doc_validation.inc"
global neboc_doc_risk_validate
global neboc_doc_validate_ownership
global neboc_doc_validate_complexity
global neboc_doc_validate_risks
section .text
neboc_doc_risk_validate:
neboc_doc_validate_ownership:
 DOCV_VALIDATE_REQUEST .ownership
.ownership:
 mov r8,[rdi+NEBOC_DOCV_SYMBOL_OWNERSHIP_OFFSET]
 mov r9,[rdi+NEBOC_DOCV_DOC_OWNERSHIP_OFFSET]
 cmp r8,r9
 jne .ownership_issue
 jmp neboc_doc_validate_complexity.validated
.ownership_issue:
 DOCV_PUBLISH_ISSUE NEBOC_DOCV_CODE_OWNERSHIP,NEBOC_DOCV_SEVERITY_WARNING,r8,r9,NEBOC_DOCV_FIX_SCAFFOLD_FIELD
neboc_doc_validate_complexity:
 DOCV_VALIDATE_REQUEST neboc_doc_validate_complexity.validated
.validated:
 mov r8,[rdi+NEBOC_DOCV_SYMBOL_COMPLEXITY_OFFSET]
 mov r9,[rdi+NEBOC_DOCV_DOC_COMPLEXITY_OFFSET]
 test r8,r8
 jz neboc_doc_validate_risks.validated
 cmp r8,r9
 jne .complexity_issue
 jmp neboc_doc_validate_risks.validated
.complexity_issue:
 DOCV_PUBLISH_ISSUE NEBOC_DOCV_CODE_COMPLEXITY,NEBOC_DOCV_SEVERITY_WARNING,r8,r9,NEBOC_DOCV_FIX_NONE
neboc_doc_validate_risks:
 DOCV_VALIDATE_REQUEST neboc_doc_validate_risks.validated
.validated:
 mov r8,[rdi+NEBOC_DOCV_REQUIRED_RISKS_OFFSET]
 mov r9,[rdi+NEBOC_DOCV_DOC_RISKS_OFFSET]
 mov rax,r9
 not rax
 and rax,r8
 jnz .risk_issue
 DOCV_PUBLISH_NONE
.risk_issue:
 mov r10,NEBOC_DOCV_SEVERITY_WARNING
 test qword [rdi+NEBOC_DOCV_POLICY_FLAGS_OFFSET],NEBOC_DOCV_POLICY_CONTRADICTIONS_ERROR
 jz .risk_ready
 mov r10,NEBOC_DOCV_SEVERITY_ERROR
.risk_ready:
 DOCV_PUBLISH_ISSUE NEBOC_DOCV_CODE_RISKS,r10,r8,r9,NEBOC_DOCV_FIX_NONE
section .note.GNU-stack noalloc noexec nowrite progbits
