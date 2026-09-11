; RF166-G155 callable-contract compatibility entry over the one DocParser.
bits 64
default rel
global neboc_doc_contract_blocks
extern neboc_doc_parse
section .text
neboc_doc_contract_blocks:
    jmp neboc_doc_parse
section .note.GNU-stack noalloc noexec nowrite progbits
