; G113 internal-service profile over the existing receiver-first RenderPlan
; language surface. Quoted tags are values, never public visual.* factories.
%define G113_FAMILY_KEY 0x4731313353524331
%define NEBO_G113_SOURCE_MIN_SEED 3301
%define NEBO_G113_SOURCE_MAX_SEED 3310

section .rodata
%macro G113_NAME 2
g113_n_%1: db %2
g113_n_%1_len equ $-g113_n_%1
%endmacro
G113_NAME root,'RenderPlan'
G113_NAME target_tag,'"domain-visual-service"'
G113_NAME event_tag,'"domain-visual"'
G113_NAME visual,'visual'
G113_NAME headless_event,'headlessEvent'
G113_NAME failure_atomic,'failureAtomic'
G113_NAME bounded,'bounded'
%undef G113_NAME

section .text
%macro G113_REQUIRE 2
    lea rsi,[rel g113_n_%1]
    mov edx,g113_n_%1_len
    call ls_contains_atom
    test eax,eax
    jz %2
%endmacro

g113_is_program:
    G113_REQUIRE root,.no
    G113_REQUIRE target_tag,.no
    G113_REQUIRE event_tag,.no
    G113_REQUIRE visual,.no
    G113_REQUIRE headless_event,.no
    G113_REQUIRE failure_atomic,.no
    G113_REQUIRE bounded,.no
    mov eax,1
    ret
.no:
    xor eax,eax
    ret

; G104 remains the parser owner; G113 attaches only after that contract and a
; bounded, source-derived subgroup have both been validated.
neboc_g113_source_parse:
    call neboc_g104_source_parse
    test eax,eax
    jnz .done
    mov rax,[rel g72_seed]
    cmp rax,NEBO_G113_SOURCE_MIN_SEED
    jb .range
    cmp rax,NEBO_G113_SOURCE_MAX_SEED
    ja .range
    sub eax,3300
    cmp eax,1
    jb .range
    cmp eax,10
    ja .range
    shl rax,32
    mov edi,dword [rel g72_seed]
    or rdi,rax
    mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
    mov rdx,G113_FAMILY_KEY
    call ls_success
.done:
    ret
.range:
    mov edi,22
    call ls_error
    ret

%undef G113_REQUIRE
