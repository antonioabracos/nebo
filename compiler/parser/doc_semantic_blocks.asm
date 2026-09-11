; RF166-G155 effects/capabilities/ownership entry over the one DocParser.
bits 64
default rel
global neboc_doc_semantic_blocks
extern neboc_doc_parse
section .text
neboc_doc_semantic_blocks:
    jmp neboc_doc_parse
section .note.GNU-stack noalloc noexec nowrite progbits
