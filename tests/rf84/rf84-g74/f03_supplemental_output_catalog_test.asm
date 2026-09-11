bits 64
default rel
%include "runtime/textual/render_console.inc"
%include "runtime/textual/policy_catalog.inc"
section .data
catalog: times NEBO_G074_CATALOG_FIELD_COUNT dq 0x2a2a2a2a
section .text
extern neboc_render_feature_available
global _start
_start:
 mov edi,7403
 call neboc_render_feature_available
 cmp eax,1
 jne .fail
 mov dword [rel catalog],0x2a2a2a2a
 lea rdi,[rel catalog]
 mov esi,NEBO_G074_CATALOG_FIELD_COUNT-1
 call nebo_g074_catalog_counts_write
 cmp eax,NEBO_G074_CAPACITY
 jne .fail
 cmp dword [rel catalog],0x2a2a2a2a
 jne .fail
 lea rdi,[rel catalog]
 mov esi,NEBO_G074_CATALOG_FIELD_COUNT
 call nebo_g074_catalog_counts_write
 test eax,eax
 jnz .fail
 cmp qword [rel catalog],381
 jne .fail
 cmp qword [rel catalog+24],184
 jne .fail
 cmp qword [rel catalog+40],0
 jne .fail
 xor edi,edi
 mov eax,60
 syscall
.fail: mov edi,77
 mov eax,60
 syscall
