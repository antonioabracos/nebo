; G164 Registry amendment surface: exact alias of the canonical scanner.
bits 64
default rel
global neboc_block_comment_registry
extern neboc_comment_scan
section .text
neboc_block_comment_registry:
    jmp neboc_comment_scan
section .note.GNU-stack noalloc noexec nowrite progbits
