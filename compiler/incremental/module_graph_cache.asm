; IDENTIDADE-DE-MODULOS-SOURCE-UNITS-ROOTS-E-MODULE-GRAPH-DETERMINISTICO-F07 revision-bound module graph invalidation closure.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/modules.inc"
section .text
; graph_invalidate(dependent_masks*, count, changed_mask, out_mask*) -> status
NEBOC_ABI_FUNCTION neboc_module_graph_invalidate
 test rdi,rdi
 jz .arg
 test r8,r8
 jz .arg
 test r8,7
 jnz .arg
 test rsi,rsi
 jz .source
 cmp rsi,NEBOC_MODULE_MAX_NODES
 ja .limit
 cmp rsi,64
 je .mask_ok
 mov ecx,esi
 mov r9,1
 shl r9,cl
 dec r9
 mov rax,rdx
 not r9
 test rax,r9
 jnz .source
.mask_ok:
 mov rax,rdx
.closure:
 mov r9,rax
 xor ecx,ecx
.node:
 cmp rcx,rsi
 jae .round
 bt rax,rcx
 jnc .next
 or r9,[rdi+rcx*8]
.next:
 inc rcx
 jmp .node
.round:
 cmp r9,rax
 je .publish
 mov rax,r9
 jmp .closure
.publish:
 mov [r8],rax
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
