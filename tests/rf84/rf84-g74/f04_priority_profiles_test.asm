bits 64
default rel
%include "runtime/textual/render_console.inc"
%include "runtime/textual/policy_catalog.inc"
section .text
extern neboc_render_feature_available
global _start
_start:
 mov edi,7404
 call neboc_render_feature_available
 cmp eax,1
 jne .fail
 mov edi,NEBO_G074_PRIORITY_PUBLIC
 call nebo_g074_priority_state
 cmp eax,NEBO_G074_MATURITY_PUBLIC_BOUNDED
 jne .fail
 mov edi,NEBO_G074_PRIORITY_CONTRACT
 call nebo_g074_priority_state
 cmp eax,NEBO_G074_MATURITY_CONTRACT_ONLY
 jne .fail
 mov edi,NEBO_G074_PRIORITY_DEFERRED
 call nebo_g074_priority_state
 cmp eax,NEBO_G074_MATURITY_DEFERRED
 jne .fail
 xor edi,edi
 mov eax,60
 syscall
.fail: mov edi,78
 mov eax,60
 syscall
