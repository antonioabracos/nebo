; G164 SourceMap.mapTrivia: byte spans are published by the canonical scanner.
bits 64
default rel
global neboc_comment_source_map
extern neboc_comment_scan
section .text
neboc_comment_source_map:
    jmp neboc_comment_scan
section .note.GNU-stack noalloc noexec nowrite progbits
