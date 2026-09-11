; G111 internal-service profile over the existing receiver-first RenderPlan
; language surface. The quoted tags are data, not new visual.* callables.
%define G111_FAMILY_KEY 0x4731313153524331
%define NEBO_G111_SOURCE_MIN_SEED 3101
%define NEBO_G111_SOURCE_MAX_SEED 3109

section .rodata
%macro G111_NAME 2
g111_n_%1: db %2
g111_n_%1_len equ $-g111_n_%1
%endmacro
G111_NAME root,'RenderPlan'
G111_NAME target_tag,'"observability-service"'
G111_NAME event_tag,'"log-progress-timeline"'
G111_NAME visual,'visual'
G111_NAME headless_event,'headlessEvent'
G111_NAME failure_atomic,'failureAtomic'
G111_NAME bounded,'bounded'
%undef G111_NAME

section .text
%macro G111_REQUIRE 2
    lea rsi,[rel g111_n_%1]
    mov edx,g111_n_%1_len
    call ls_contains_atom
    test eax,eax
    jz %2
%endmacro

g111_is_program:
    G111_REQUIRE root,.no
    G111_REQUIRE target_tag,.no
    G111_REQUIRE event_tag,.no
    G111_REQUIRE visual,.no
    G111_REQUIRE headless_event,.no
    G111_REQUIRE failure_atomic,.no
    G111_REQUIRE bounded,.no
    mov eax,1
    ret
.no:
    xor eax,eax
    ret

; G104 remains the syntax owner for RenderPlan. This profile only retags the
; validated plan for G111 lowering after deriving a bounded subgroup from the
; source seed; paths and fixture names are never inspected.
neboc_g111_source_parse:
    call neboc_g104_source_parse
    test eax,eax
    jnz .done
    mov rax,[rel g72_seed]
    cmp rax,NEBO_G111_SOURCE_MIN_SEED
    jb .range
    cmp rax,NEBO_G111_SOURCE_MAX_SEED
    ja .range
    sub eax,3100
    cmp eax,1
    jb .range
    cmp eax,9
    ja .range
    shl rax,32
    mov edi,dword [rel g72_seed]
    or rdi,rax
    mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
    mov rdx,G111_FAMILY_KEY
    call ls_success
.done:
    ret
.range:
    mov edi,22
    call ls_error
    ret

%undef G111_REQUIRE
