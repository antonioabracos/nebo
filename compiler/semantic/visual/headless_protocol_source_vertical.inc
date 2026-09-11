; G103 internal protocol profile over the existing RenderPlan surface.
; No new public syntax is introduced: a complete target-conformance JSONL
; plan is reclassified for protocol lowering after G072 validates every call.
%define G103_FAMILY_KEY 0x4731303353524331

section .rodata
%macro G103_NAME 2
g103_n_%1: db %2
g103_n_%1_len equ $-g103_n_%1
%endmacro
G103_NAME root,'RenderPlan'
G103_NAME event,'event'
G103_NAME payload,'payload'
G103_NAME headless,'headless'
G103_NAME jsonl,'jsonl'
G103_NAME target_conformance,'targetConformance'
G103_NAME validate,'validate'
G103_NAME deterministic,'deterministic'
G103_NAME failure_atomic,'failureAtomic'
G103_NAME bounded,'bounded'
%undef G103_NAME

section .text
%macro G103_REQUIRE 2
 lea rsi,[rel g103_n_%1]
 mov edx,g103_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

; This conjunction reserves an internal profile without adding a method or
; stealing any existing single-subgroup G069/G072/G073 source program.
g103_is_program:
 G103_REQUIRE root,.no
 G103_REQUIRE event,.no
 G103_REQUIRE payload,.no
 G103_REQUIRE headless,.no
 G103_REQUIRE jsonl,.no
 G103_REQUIRE target_conformance,.no
 G103_REQUIRE validate,.no
 G103_REQUIRE deterministic,.no
 G103_REQUIRE failure_atomic,.no
 G103_REQUIRE bounded,.no
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

; G072 remains the syntax/type owner. This wrapper only derives the internal
; subgroup and changes the lowering family. The final two seed digits select
; subgroup 01..10; no source path or fixture name participates.
neboc_g103_source_parse:
 call neboc_g072_source_parse
 test eax,eax
 jnz .done
 cmp qword [rel g72_seed],1301
 jb .range
 cmp qword [rel g72_seed],9999
 ja .range
 mov rax,[rel g72_seed]
 xor edx,edx
 mov ecx,100
 div rcx
 cmp edx,1
 jb .range
 cmp edx,10
 ja .range
 mov eax,edx
 shl rax,32
 mov edi,dword [rel g72_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G103_FAMILY_KEY
 call ls_success
.done:
 ret
.range:
 mov edi,22
 call ls_error
 ret

%undef G103_REQUIRE
