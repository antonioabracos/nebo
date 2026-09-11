bits 64
default rel
%include "runtime/console_fallback_source_probe.inc"

%ifndef G107_FRONT_MODE
%error G107_FRONT_MODE required
%endif
%ifndef G107_FRONT_VARIANT
%error G107_FRONT_VARIANT required
%endif
%ifndef G107_FRONT_MASK
%error G107_FRONT_MASK required
%endif

section .text
global _start
_start:
    mov edi,G107_FRONT_MODE
    mov esi,3700+G107_FRONT_MODE
    mov edx,G107_FRONT_VARIANT
    call nebo_g107_source_probe
    cmp eax,3700+G107_FRONT_MODE
    jne .fail
    mov edi,2
    call nebo_g107_surface_probe
    cmp rax,G107_FRONT_MASK
    jne .fail
    mov edi,7
    call nebo_g107_surface_probe
    cmp eax,1
    jne .fail
    mov eax,60
    xor edi,edi
    syscall
.fail:
    mov eax,60
    mov edi,G107_FRONT_MODE
    syscall
