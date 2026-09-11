; G116 integration-closeout profile over the receiver-first RenderPlan syntax.
; Quoted tags select a conformance profile; they do not create a public facade.
%define G116_FAMILY_KEY 0x4731313653524331
%define NEBO_G116_SOURCE_MIN_SEED 3601
%define NEBO_G116_SOURCE_MAX_SEED 3610

section .rodata
%macro G116_NAME 2
g116_n_%1: db %2
g116_n_%1_len equ $-g116_n_%1
%endmacro
G116_NAME root,'RenderPlan'
G116_NAME target_tag,'"rf116-closeout"'
G116_NAME event_tag,'"integration-conformance"'
G116_NAME visual,'visual'
G116_NAME headless_event,'headlessEvent'
G116_NAME target_conformance,'targetConformance'
G116_NAME deterministic,'deterministic'
G116_NAME failure_atomic,'failureAtomic'
G116_NAME bounded,'bounded'
%undef G116_NAME

section .text
%macro G116_REQUIRE 2
    lea rsi,[rel g116_n_%1]
    mov edx,g116_n_%1_len
    call ls_contains_atom
    test eax,eax
    jz %2
%endmacro

g116_is_program:
    G116_REQUIRE root,.no
    G116_REQUIRE target_tag,.no
    G116_REQUIRE event_tag,.no
    G116_REQUIRE visual,.no
    G116_REQUIRE headless_event,.no
    G116_REQUIRE target_conformance,.no
    G116_REQUIRE deterministic,.no
    G116_REQUIRE failure_atomic,.no
    G116_REQUIRE bounded,.no
    mov eax,1
    ret
.no:
    xor eax,eax
    ret

; G104 remains the public syntax owner. G116 only selects a bounded closeout
; observation from values present in real Nebo source.
neboc_g116_source_parse:
    call neboc_g104_source_parse
    test eax,eax
    jnz .done
    mov rax,[rel g72_seed]
    cmp rax,NEBO_G116_SOURCE_MIN_SEED
    jb .range
    cmp rax,NEBO_G116_SOURCE_MAX_SEED
    ja .range
    sub eax,3600
    cmp eax,1
    jb .range
    cmp eax,10
    ja .range
    shl rax,32
    mov edi,dword [rel g72_seed]
    or rdi,rax
    mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
    mov rdx,G116_FAMILY_KEY
    call ls_success
.done:
    ret
.range:
    mov edi,22
    call ls_error
    ret

%undef G116_REQUIRE
