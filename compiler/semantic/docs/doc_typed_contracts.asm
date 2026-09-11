; Typed error, effect and capability identities for DocRecordV1.  These
; records describe authority but never grant it.
bits 64
default rel
%include "compiler/semantic/docs/doc_record.inc"
global neboc_doc_typed_contracts
global neboc_doc_record_add_error
global neboc_doc_record_add_effect
global neboc_doc_record_add_capability
extern neboc_doc_record_set_slot

section .text
align 16
neboc_doc_typed_contracts:
neboc_doc_record_add_error:
    mov edx, NEBOC_DOC_OFF_ERRORS
    mov ecx, 1 << 4
    jmp neboc_doc_record_set_slot
align 16
neboc_doc_record_add_effect:
    mov edx, NEBOC_DOC_OFF_EFFECTS
    mov ecx, 1 << 5
    jmp neboc_doc_record_set_slot
align 16
neboc_doc_record_add_capability:
    mov edx, NEBOC_DOC_OFF_CAPABILITIES
    mov ecx, 1 << 6
    jmp neboc_doc_record_set_slot
section .note.GNU-stack noalloc noexec nowrite progbits
