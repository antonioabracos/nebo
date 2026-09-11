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
 test rdi,7
 jnz .arg
 test r8,r8
 jz .arg
 test r8,7
 jnz .arg
 test rsi,rsi
 jz .source
 test rdx,rdx
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
 mov rcx,rsi
 shl rcx,3
 lea r9,[rdi+rcx]
 lea r10,[r8+8]
 cmp rdi,r10
 jae .ranges_ok
 cmp r8,r9
 jb .arg
.ranges_ok:
 xor ecx,ecx
.validate_masks:
 cmp rcx,rsi
 jae .masks_ok
 mov r10,[rdi+rcx*8]
 cmp rsi,64
 je .mask_entry_ok
 mov r11,1
 mov r9,rcx
 mov ecx,esi
 shl r11,cl
 mov rcx,r9
 dec r11
 not r11
 test r10,r11
 jnz .source
.mask_entry_ok:
 inc rcx
 jmp .validate_masks
.masks_ok:
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

; cache_key(graph_digest, revision, profile_digest, out*) -> status.
NEBOC_ABI_FUNCTION neboc_module_graph_cache_key
 test rdi,rdi
 jz .key_source
 test rsi,rsi
 jz .key_source
 test rdx,rdx
 jz .key_source
 test rcx,rcx
 jz .key_arg
 test rcx,7
 jnz .key_arg
 mov rax,0xcbf29ce484222325
 xor rax,rdi
 mov r8,0x100000001b3
 imul rax,r8
 xor rax,rsi
 imul rax,r8
 xor rax,rdx
 imul rax,r8
 test rax,rax
 jnz .key_publish
 mov eax,1
.key_publish:
 mov [rcx],rax
 xor eax,eax
 ret
.key_arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.key_source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
