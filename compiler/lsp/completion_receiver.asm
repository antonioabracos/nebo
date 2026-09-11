; RF166-G161-F02 receiver TypeId/constraint resolution.
bits 64
default rel
%include "compiler/lsp/completion.inc"
global neboc_completion_receiver
section .text
align 16
neboc_completion_receiver:
 COMPLETION_VALIDATE_COMMON NEBOC_COMPLETION_OP_RECEIVER
 COMPLETION_REQUIRE_FLAGS NEBOC_COMPLETION_FLAG_TYPECHECKED
 cmp qword [rdi+NEBOC_COMPLETION_RECEIVER_TYPE_OFFSET],0
 je .contract
 cmp qword [rdi+NEBOC_COMPLETION_RECEIVER_EVALUATIONS_OFFSET],1
 jne .contract
 COMPLETION_PUBLISH
.contract:
 mov eax,NEBOC_COMPLETION_STATUS_CONTRACT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
