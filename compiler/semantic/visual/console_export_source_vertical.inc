; G114 export/privacy profile over the receiver-first RenderPlan language
; surface. Quoted tags are values, never public visual.* factories.
%define G114_FAMILY_KEY 0x4731313453524331
%define NEBO_G114_SOURCE_MIN_SEED 3401
%define NEBO_G114_SOURCE_MAX_SEED 3409

section .rodata
%macro G114_NAME 2
g114_n_%1: db %2
g114_n_%1_len equ $-g114_n_%1
%endmacro
G114_NAME root,'RenderPlan'
G114_NAME target_tag,'"export-privacy-service"'
G114_NAME event_tag,'"privacy-audited"'
G114_NAME visual,'visual'
G114_NAME headless_event,'headlessEvent'
G114_NAME failure_atomic,'failureAtomic'
G114_NAME bounded,'bounded'
%undef G114_NAME

section .text
%macro G114_REQUIRE 2
    lea rsi,[rel g114_n_%1]
    mov edx,g114_n_%1_len
    call ls_contains_atom
    test eax,eax
    jz %2
%endmacro

g114_is_program:
    G114_REQUIRE root,.no
    G114_REQUIRE target_tag,.no
    G114_REQUIRE event_tag,.no
    G114_REQUIRE visual,.no
    G114_REQUIRE headless_event,.no
    G114_REQUIRE failure_atomic,.no
    G114_REQUIRE bounded,.no
    mov eax,1
    ret
.no:
    xor eax,eax
    ret

; G104 remains the syntax owner. G114 adds only the bounded source identity
; required to select the export/privacy host-service lowering.
neboc_g114_source_parse:
    call neboc_g104_source_parse
    test eax,eax
    jnz .done
    mov rax,[rel g72_seed]
    cmp rax,NEBO_G114_SOURCE_MIN_SEED
    jb .range
    cmp rax,NEBO_G114_SOURCE_MAX_SEED
    ja .range
    sub eax,3400
    cmp eax,1
    jb .range
    cmp eax,9
    ja .range
    shl rax,32
    mov edi,dword [rel g72_seed]
    or rdi,rax
    mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
    mov rdx,G114_FAMILY_KEY
    call ls_success
.done:
    ret
.range:
    mov edi,22
    call ls_error
    ret

%undef G114_REQUIRE
