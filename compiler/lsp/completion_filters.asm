; RF166-G161-F05 visibility/effect/capability/target/edition filters.
bits 64
default rel
%include "compiler/lsp/completion.inc"
global neboc_completion_filter
section .text
align 16
neboc_completion_filter:
 COMPLETION_VALIDATE_COMMON NEBOC_COMPLETION_OP_FILTER
 COMPLETION_REQUIRE_FLAGS NEBOC_COMPLETION_FLAG_PRIVATE_FILTERED|NEBOC_COMPLETION_FLAG_NO_GRANTS
 COMPLETION_PUBLISH
section .note.GNU-stack noalloc noexec nowrite progbits
