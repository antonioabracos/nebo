; RF166-G161-F04 local stdlib/package auto-import candidates.
bits 64
default rel
%include "compiler/lsp/completion.inc"
global neboc_completion_auto_import
section .text
align 16
neboc_completion_auto_import:
 COMPLETION_VALIDATE_COMMON NEBOC_COMPLETION_OP_AUTO_IMPORT
 COMPLETION_REQUIRE_FLAGS NEBOC_COMPLETION_FLAG_INDEX|NEBOC_COMPLETION_FLAG_NO_GRANTS
 COMPLETION_PUBLISH
section .note.GNU-stack noalloc noexec nowrite progbits
