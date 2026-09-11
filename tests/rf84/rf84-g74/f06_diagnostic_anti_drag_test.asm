bits 64
default rel
%include "runtime/textual/render_console.inc"
%include "runtime/textual/policy_catalog.inc"
section .data
diagnostic: times NEBO_G074_DIAG_SIZE db 0xa5
section .text
extern neboc_render_feature_available
global _start
_start:
 mov edi,7406
 call neboc_render_feature_available
 cmp eax,1
 jne .fail
 mov edi,NEBO_G074_DIAG_POLICY_CONFLICT
 mov esi,6
 mov edx,18
 lea rcx,[rel diagnostic]
 call nebo_g074_diagnostic_write
 test eax,eax
 jnz .fail
 cmp qword [rel diagnostic+NEBO_G074_DIAG_CODE],0x7402
 jne .fail
 mov byte [rel diagnostic],0xa5
 mov edi,NEBO_G074_DIAG_UNKNOWN_POLICY
 mov esi,20
 mov edx,4
 lea rcx,[rel diagnostic]
 call nebo_g074_diagnostic_write
 cmp eax,NEBO_G074_INVALID
 jne .fail
 cmp byte [rel diagnostic],0xa5
 jne .fail
 xor edi,edi
 mov eax,60
 syscall
.fail: mov edi,80
 mov eax,60
 syscall
