; RF166-G161-F07 lazy DocRecord resolve and transactional auto-import.
bits 64
default rel
%include "compiler/lsp/completion.inc"
global neboc_completion_resolve
section .text
align 16
neboc_completion_resolve:
 COMPLETION_VALIDATE_COMMON NEBOC_COMPLETION_OP_RESOLVE
 COMPLETION_REQUIRE_FLAGS NEBOC_COMPLETION_FLAG_DOC
 cmp qword [rdi+NEBOC_COMPLETION_SELECTED_SYMBOL_OFFSET],0
 je .contract
 cmp qword [rdi+NEBOC_COMPLETION_DOC_HANDLE_OFFSET],0
 je .contract
 cmp qword [rdi+NEBOC_COMPLETION_IMPORT_DIGEST_OFFSET],0
 je .publish
 COMPLETION_REQUIRE_FLAGS NEBOC_COMPLETION_FLAG_EXPLICIT_EDIT|NEBOC_COMPLETION_FLAG_ATOMIC
.publish:
 COMPLETION_PUBLISH
.contract:
 mov eax,NEBOC_COMPLETION_STATUS_CONTRACT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
