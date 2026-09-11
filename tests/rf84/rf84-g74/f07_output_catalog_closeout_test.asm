bits 64
default rel
%include "runtime/textual/render_console.inc"
%include "runtime/textual/policy_catalog.inc"
section .text
extern neboc_render_feature_available
global _start
_start:
 mov edi,7407
 call neboc_render_feature_available
 cmp eax,1
 jne .fail
 mov edi,7
 mov esi,1207
 call nebo_g074_source_probe
 cmp eax,183
 jne .fail
 mov ebx,1
.negative:
 mov edi,ebx
 call nebo_g074_negative_probe
 test eax,eax
 jnz .fail
 inc ebx
 cmp ebx,7
 jb .negative
 xor edi,edi
 mov eax,60
 syscall
.fail: mov edi,81
 mov eax,60
 syscall
