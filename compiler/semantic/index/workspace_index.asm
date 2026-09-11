; RF166-G160-F04: deterministic workspace and local-package aggregation.
bits 64
default rel
%include "compiler/semantic/index/symbol_index.inc"
global neboc_index_workspace
section .text
align 16
neboc_index_workspace:
 INDEX_VALIDATE_REQUEST NEBOC_INDEX_OP_WORKSPACE,.validated
.validated:
 INDEX_REQUIRE_FLAGS NEBOC_INDEX_FLAG_ATOMIC|NEBOC_INDEX_FLAG_NO_CAPABILITY_GRANT,.policy
 cmp qword [rdi+NEBOC_INDEX_WORKSPACE_OFFSET],0
 je .contract
 cmp qword [rdi+NEBOC_INDEX_PACKAGE_ENTRIES_OFFSET],0
 je .publish
 INDEX_REQUIRE_FLAGS NEBOC_INDEX_FLAG_PACKAGE_LOCAL,.policy
.publish:
 INDEX_PUBLISH [rdi+NEBOC_INDEX_COLD_DIGEST_OFFSET],0
.contract:
 mov eax,NEBOC_INDEX_STATUS_CONTRACT
 ret
.policy:
 mov eax,NEBOC_INDEX_STATUS_POLICY
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
