; G164 CommentPolicy.maxNesting and DocCommentClassifier.classify share the
; canonical scanner; comment-like spellings never produce a DocRecord.
bits 64
default rel
global neboc_comment_security
extern neboc_comment_scan
section .text
neboc_comment_security:
    jmp neboc_comment_scan
section .note.GNU-stack noalloc noexec nowrite progbits
