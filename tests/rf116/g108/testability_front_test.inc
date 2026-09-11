%ifndef G108_FRONT_MODE
%error "G108_FRONT_MODE is required"
%endif
%ifndef G108_FRONT_SEED
%error "G108_FRONT_SEED is required"
%endif
%ifndef G108_FRONT_VARIANT
%error "G108_FRONT_VARIANT is required"
%endif
%ifndef G108_FRONT_FINAL_LENGTH
%define G108_FRONT_FINAL_LENGTH 57
%endif

bits 64
default rel
%include "runtime/console_testability_source_probe.inc"

section .note.GNU-stack noalloc noexec nowrite progbits
section .text
global _start
_start:
    ; Each legacy front now executes the source-owned capture/snapshot/replay
    ; pipeline and observes its independently derived state.
    mov edi,G108_FRONT_MODE
    mov esi,G108_FRONT_SEED
    mov edx,G108_FRONT_VARIANT
    call nebo_g108_source_probe
    cmp eax,G108_FRONT_SEED
    jne .fail
    mov edi,1
    call nebo_g108_surface_probe
    cmp eax,G108_FRONT_MODE
    jne .fail
    mov edi,3
    call nebo_g108_surface_probe
    cmp eax,G108_FRONT_FINAL_LENGTH
    jne .fail
    mov edi,5
    call nebo_g108_surface_probe
    cmp eax,129
    jne .fail
    mov edi,6
    call nebo_g108_surface_probe
    cmp eax,G108_FRONT_SEED
    jne .fail
    mov edi,10
    call nebo_g108_surface_probe
    cmp eax,1
    jne .fail
    mov edi,11
    call nebo_g108_surface_probe
    cmp eax,NEBO_G108_MATURITY_DETERMINISTIC_REPLAY_GREEN
    jne .fail
    mov edi,G108_FRONT_MODE
    call nebo_g108_negative_probe
    test eax,eax
    jne .fail
    mov edi,G108_FRONT_MODE
    mov esi,G108_FRONT_SEED
    mov edx,G108_FRONT_VARIANT
    call nebo_g108_source_probe
    cmp eax,G108_FRONT_SEED
    jne .fail
    mov eax,60
    xor edi,edi
    syscall
.fail:
    mov eax,60
    mov edi,1
    syscall
