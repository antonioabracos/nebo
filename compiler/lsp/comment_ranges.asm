; G164 FoldingRange.comments: consume the compiler-owned trivia projection.
bits 64
default rel
global neboc_comment_ranges
extern neboc_comment_scan
section .text
neboc_comment_ranges:
    jmp neboc_comment_scan
section .note.GNU-stack noalloc noexec nowrite progbits
