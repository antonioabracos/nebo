; RF166-G161-F03 core/prelude/imported member accounting.
bits 64
default rel
%include "compiler/lsp/completion.inc"
global neboc_completion_members
section .text
align 16
neboc_completion_members:
 COMPLETION_VALIDATE_COMMON NEBOC_COMPLETION_OP_MEMBERS
 COMPLETION_REQUIRE_FLAGS NEBOC_COMPLETION_FLAG_INDEX|NEBOC_COMPLETION_FLAG_TYPECHECKED
 cmp qword [rdi+NEBOC_COMPLETION_CANDIDATE_COUNT_OFFSET],0
 je .contract
 COMPLETION_PUBLISH
.contract:
 mov eax,NEBOC_COMPLETION_STATUS_CONTRACT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
