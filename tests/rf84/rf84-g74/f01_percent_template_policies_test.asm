bits 64
default rel
%include "runtime/textual/render_console.inc"
%include "runtime/textual/percent_format.inc"
section .text
extern neboc_render_feature_available
global _start
_start:
 mov edi,7401
 call neboc_render_feature_available
 cmp eax,1
 jne .fail
 xor edi,edi
 call neboc_percent_policy_validate
 test eax,eax
 jnz .fail
 mov edi,PERCENT_POLICY_LOOSE
 call neboc_percent_policy_validate
 test eax,eax
 jnz .fail
 mov edi,PERCENT_POLICY_NAMED_ONLY | PERCENT_POLICY_POSITIONAL_ONLY
 call neboc_percent_policy_validate
 test eax,eax
 jz .fail
 xor edi,edi
 mov eax,60
 syscall
.fail: mov edi,75
 mov eax,60
 syscall
