; G112 internal-service profile over the existing receiver-first RenderPlan
; language surface. Quoted tags are values, never public visual.* factories.
%define G112_FAMILY_KEY 0x4731313253524331
%define NEBO_G112_SOURCE_MIN_SEED 3201
%define NEBO_G112_SOURCE_MAX_SEED 3209

section .rodata
%macro G112_NAME 2
g112_n_%1: db %2
g112_n_%1_len equ $-g112_n_%1
%endmacro
G112_NAME root,'RenderPlan'
G112_NAME target_tag,'"chart-table-service"'
G112_NAME event_tag,'"chart-table"'
G112_NAME visual,'visual'
G112_NAME headless_event,'headlessEvent'
G112_NAME failure_atomic,'failureAtomic'
G112_NAME bounded,'bounded'
%undef G112_NAME

section .text
%macro G112_REQUIRE 2
    lea rsi,[rel g112_n_%1]
    mov edx,g112_n_%1_len
    call ls_contains_atom
    test eax,eax
    jz %2
%endmacro

g112_is_program:
    G112_REQUIRE root,.no
    G112_REQUIRE target_tag,.no
    G112_REQUIRE event_tag,.no
    G112_REQUIRE visual,.no
    G112_REQUIRE headless_event,.no
    G112_REQUIRE failure_atomic,.no
    G112_REQUIRE bounded,.no
    mov eax,1
    ret
.no:
    xor eax,eax
    ret

; G104 remains the parser owner; G112 attaches only after that contract and a
; bounded source-derived subgroup have both been validated.
neboc_g112_source_parse:
    call neboc_g104_source_parse
    test eax,eax
    jnz .done
    mov rax,[rel g72_seed]
    cmp rax,NEBO_G112_SOURCE_MIN_SEED
    jb .range
    cmp rax,NEBO_G112_SOURCE_MAX_SEED
    ja .range
    sub eax,3200
    cmp eax,1
    jb .range
    cmp eax,9
    ja .range
    shl rax,32
    mov edi,dword [rel g72_seed]
    or rdi,rax
    mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
    mov rdx,G112_FAMILY_KEY
    call ls_success
.done:
    ret
.range:
    mov edi,22
    call ls_error
    ret

%undef G112_REQUIRE
