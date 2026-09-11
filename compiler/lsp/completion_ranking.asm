; RF166-G161-F06 deterministic locality/exactness/stability/usage ranking.
bits 64
default rel
%include "compiler/lsp/completion.inc"
global neboc_completion_rank
section .text
align 16
neboc_completion_rank:
 COMPLETION_VALIDATE_COMMON NEBOC_COMPLETION_OP_RANK
 COMPLETION_REQUIRE_FLAGS NEBOC_COMPLETION_FLAG_DETERMINISTIC
 cmp qword [rdi+NEBOC_COMPLETION_RANK_DIGEST_OFFSET],0
 je .contract
 cmp qword [rdi+NEBOC_COMPLETION_ELIGIBLE_COUNT_OFFSET],0
 je .contract
 COMPLETION_PUBLISH
.contract:
 mov eax,NEBOC_COMPLETION_STATUS_CONTRACT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
