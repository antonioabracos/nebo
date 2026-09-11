; RF166-G155 lifecycle-field compatibility entry over the one DocParser.
bits 64
default rel
global neboc_doc_lifecycle
extern neboc_doc_parse
section .text
neboc_doc_lifecycle:
    jmp neboc_doc_parse
section .note.GNU-stack noalloc noexec nowrite progbits
