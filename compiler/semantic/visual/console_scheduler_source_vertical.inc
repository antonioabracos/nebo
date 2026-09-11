; G110 internal-service profile over the existing receiver-first RenderPlan
; language surface. The quoted tags are data, not new visual.* callables.
%define G110_FAMILY_KEY 0x4731313053524331
%define NEBO_G110_SOURCE_MIN_SEED 3001
%define NEBO_G110_SOURCE_MAX_SEED 3009

section .rodata
%macro G110_NAME 2
g110_n_%1: db %2
g110_n_%1_len equ $-g110_n_%1
%endmacro
G110_NAME root,'RenderPlan'
G110_NAME target_tag,'"visual-service"'
G110_NAME event_tag,'"console-panel"'
G110_NAME visual,'visual'
G110_NAME headless_event,'headlessEvent'
G110_NAME failure_atomic,'failureAtomic'
G110_NAME bounded,'bounded'
%undef G110_NAME

section .text
%macro G110_REQUIRE 2
    lea rsi,[rel g110_n_%1]
    mov edx,g110_n_%1_len
    call ls_contains_atom
    test eax,eax
    jz %2
%endmacro

g110_is_program:
    G110_REQUIRE root,.no
    G110_REQUIRE target_tag,.no
    G110_REQUIRE event_tag,.no
    G110_REQUIRE visual,.no
    G110_REQUIRE headless_event,.no
    G110_REQUIRE failure_atomic,.no
    G110_REQUIRE bounded,.no
    mov eax,1
    ret
.no:
    xor eax,eax
    ret

; G104 remains the syntax owner for RenderPlan. This profile only retags the
; validated plan for G110 lowering after deriving a bounded subgroup from the
; source seed; paths and fixture names are never inspected.
neboc_g110_source_parse:
    call neboc_g104_source_parse
    test eax,eax
    jnz .done
    mov rax,[rel g72_seed]
    cmp rax,NEBO_G110_SOURCE_MIN_SEED
    jb .range
    cmp rax,NEBO_G110_SOURCE_MAX_SEED
    ja .range
    sub eax,3000
    cmp eax,1
    jb .range
    cmp eax,9
    ja .range
    shl rax,32
    mov edi,dword [rel g72_seed]
    or rdi,rax
    mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
    mov rdx,G110_FAMILY_KEY
    call ls_success
.done:
    ret
.range:
    mov edi,22
    call ls_error
    ret

%undef G110_REQUIRE
