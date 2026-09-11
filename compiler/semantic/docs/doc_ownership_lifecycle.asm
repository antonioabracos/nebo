; Ownership, complexity, risk and lifecycle identities for DocRecordV1.
bits 64
default rel
%include "compiler/semantic/docs/doc_record.inc"
global neboc_doc_ownership_lifecycle
global neboc_doc_record_set_ownership
global neboc_doc_record_set_complexity
global neboc_doc_record_add_risk
global neboc_doc_record_set_since
global neboc_doc_record_set_deprecated
extern neboc_doc_record_set_slot

section .text
align 16
neboc_doc_ownership_lifecycle:
neboc_doc_record_set_ownership:
    mov edx, NEBOC_DOC_OFF_OWNERSHIP
    mov ecx, 1 << 7
    jmp neboc_doc_record_set_slot
align 16
neboc_doc_record_set_complexity:
    mov edx, NEBOC_DOC_OFF_COMPLEXITY
    mov ecx, 1 << 8
    jmp neboc_doc_record_set_slot
align 16
neboc_doc_record_add_risk:
    mov edx, NEBOC_DOC_OFF_RISKS
    mov ecx, 1 << 9
    jmp neboc_doc_record_set_slot
align 16
neboc_doc_record_set_since:
    mov edx, NEBOC_DOC_OFF_SINCE
    mov ecx, 1 << 10
    jmp neboc_doc_record_set_slot
align 16
neboc_doc_record_set_deprecated:
    mov edx, NEBOC_DOC_OFF_DEPRECATED
    mov ecx, 1 << 11
    jmp neboc_doc_record_set_slot
section .note.GNU-stack noalloc noexec nowrite progbits
