; RF166-G155 short-field compatibility entry over the one DocParser owner.
bits 64
default rel
global neboc_doc_fields
extern neboc_doc_parse
section .text
neboc_doc_fields:
    jmp neboc_doc_parse
section .note.GNU-stack noalloc noexec nowrite progbits
