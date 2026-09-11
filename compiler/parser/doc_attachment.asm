; RF166-G155 attachment compatibility entry over the one DocParser owner.
bits 64
default rel
global neboc_doc_attach
extern neboc_doc_parse
section .text
neboc_doc_attach:
    jmp neboc_doc_parse
section .note.GNU-stack noalloc noexec nowrite progbits
