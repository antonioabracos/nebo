bits 64
default rel
%include "runtime/textual/render_console.inc"
%include "runtime/textual/policy_catalog.inc"
section .text
extern neboc_render_feature_available
global _start
_start:
 mov edi,7402
 call neboc_render_feature_available
 cmp eax,1
 jne .fail
 mov edi,NEBO_G074_SLASH_ALLOW | NEBO_G074_SLASH_FALLBACK_PLAIN
 mov esi,NEBO_G074_TARGET_TERMINAL
 call nebo_g074_slash_policy_validate
 test eax,eax
 jnz .fail
 mov edi,NEBO_G074_SLASH_ALLOW | NEBO_G074_SLASH_DISABLE
 mov esi,NEBO_G074_TARGET_TERMINAL
 call nebo_g074_slash_policy_validate
 cmp eax,NEBO_G074_CONFLICT
 jne .fail
 xor edi,edi
 mov eax,60
 syscall
.fail: mov edi,76
 mov eax,60
 syscall
