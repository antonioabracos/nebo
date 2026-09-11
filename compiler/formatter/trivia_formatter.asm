; G164 Formatter.preserveTrivia: consume the compiler-owned trivia projection.
bits 64
default rel
global neboc_trivia_formatter
extern neboc_comment_scan
section .text
neboc_trivia_formatter:
    jmp neboc_comment_scan
section .note.GNU-stack noalloc noexec nowrite progbits
