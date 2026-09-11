; G115 versioned Console ABI and renderer-plugin profile over the receiver-first
; RenderPlan syntax. Quoted tags are values, not public console factories.
%define G115_FAMILY_KEY 0x4731313553524331
%define NEBO_G115_SOURCE_MIN_SEED 3501
%define NEBO_G115_SOURCE_MAX_SEED 3510

section .rodata
%macro G115_NAME 2
g115_n_%1: db %2
g115_n_%1_len equ $-g115_n_%1
%endmacro
G115_NAME root,'RenderPlan'
G115_NAME target_tag,'"console-abi-service"'
G115_NAME event_tag,'"renderer-plugin"'
G115_NAME visual,'visual'
G115_NAME headless_event,'headlessEvent'
G115_NAME failure_atomic,'failureAtomic'
G115_NAME bounded,'bounded'
%undef G115_NAME

section .text
%macro G115_REQUIRE 2
    lea rsi,[rel g115_n_%1]
    mov edx,g115_n_%1_len
    call ls_contains_atom
    test eax,eax
    jz %2
%endmacro

g115_is_program:
    G115_REQUIRE root,.no
    G115_REQUIRE target_tag,.no
    G115_REQUIRE event_tag,.no
    G115_REQUIRE visual,.no
    G115_REQUIRE headless_event,.no
    G115_REQUIRE failure_atomic,.no
    G115_REQUIRE bounded,.no
    mov eax,1
    ret
.no:
    xor eax,eax
    ret

; G104 remains the syntax owner. G115 selects only the bounded internal ABI
; and renderer lifecycle lowering from values present in real Nebo source.
neboc_g115_source_parse:
    call neboc_g104_source_parse
    test eax,eax
    jnz .done
    mov rax,[rel g72_seed]
    cmp rax,NEBO_G115_SOURCE_MIN_SEED
    jb .range
    cmp rax,NEBO_G115_SOURCE_MAX_SEED
    ja .range
    sub eax,3500
    cmp eax,1
    jb .range
    cmp eax,10
    ja .range
    shl rax,32
    mov edi,dword [rel g72_seed]
    or rdi,rax
    mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
    mov rdx,G115_FAMILY_KEY
    call ls_success
.done:
    ret
.range:
    mov edi,22
    call ls_error
    ret

%undef G115_REQUIRE
