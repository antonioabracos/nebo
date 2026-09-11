; RF166-G161-F01 CompletionContext.fromPosition(snapshot, position).
bits 64
default rel
%include "compiler/lsp/completion.inc"
global neboc_completion_context
section .text
align 16
neboc_completion_context:
 COMPLETION_VALIDATE_COMMON NEBOC_COMPLETION_OP_CONTEXT
 COMPLETION_REQUIRE_FLAGS NEBOC_COMPLETION_FLAG_DETERMINISTIC
 COMPLETION_PUBLISH
section .note.GNU-stack noalloc noexec nowrite progbits
