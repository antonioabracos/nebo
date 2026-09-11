; RF166-G160-F03: exports admitted by the canonical .ni InterfaceReader.
bits 64
default rel
%include "compiler/semantic/index/symbol_index.inc"
global neboc_index_interface
section .text
align 16
neboc_index_interface:
 INDEX_VALIDATE_REQUEST NEBOC_INDEX_OP_INTERFACE,.validated
.validated:
 INDEX_REQUIRE_FLAGS NEBOC_INDEX_FLAG_INTERFACE_VALIDATED|NEBOC_INDEX_FLAG_ATOMIC,.policy
 cmp qword [rdi+NEBOC_INDEX_INTERFACE_ENTRIES_OFFSET],0
 je .contract
 cmp qword [rdi+NEBOC_INDEX_COLD_DIGEST_OFFSET],0
 je .contract
 INDEX_PUBLISH [rdi+NEBOC_INDEX_COLD_DIGEST_OFFSET],0
.contract:
 mov eax,NEBOC_INDEX_STATUS_CONTRACT
 ret
.policy:
 mov eax,NEBOC_INDEX_STATUS_POLICY
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
