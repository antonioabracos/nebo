; G164 TriviaStore.attach: one canonical lexical projection, no second parser.
bits 64
default rel
global neboc_trivia_store
extern neboc_comment_scan
section .text
neboc_trivia_store:
    jmp neboc_comment_scan
section .note.GNU-stack noalloc noexec nowrite progbits
