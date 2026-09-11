; G104 internal live-console profile over the existing RenderPlan surface.
; G072 remains the syntax/type owner; this profile only selects the concrete
; window-backend lifecycle lowered by the runtime bridge.
%define G104_FAMILY_KEY 0x4731303453524331

section .rodata
%macro G104_NAME 2
g104_n_%1: db %2
g104_n_%1_len equ $-g104_n_%1
%endmacro
G104_NAME root,'RenderPlan'
G104_NAME stdout,'stdout'
G104_NAME stderr,'stderr'
G104_NAME target,'target'
G104_NAME plain,'plain'
G104_NAME visual,'visual'
G104_NAME headless_event,'headlessEvent'
G104_NAME event,'event'
G104_NAME payload,'payload'
G104_NAME headless,'headless'
G104_NAME jsonl,'jsonl'
G104_NAME target_conformance,'targetConformance'
G104_NAME validate,'validate'
G104_NAME deterministic,'deterministic'
G104_NAME failure_atomic,'failureAtomic'
G104_NAME bounded,'bounded'
%undef G104_NAME

section .text
%macro G104_REQUIRE 2
 lea rsi,[rel g104_n_%1]
 mov edx,g104_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

; The conjunction is deliberately narrower than G103 and G072 so existing
; programs retain their owner. Source paths and fixture names are irrelevant.
g104_is_program:
 G104_REQUIRE root,.no
 G104_REQUIRE stdout,.no
 G104_REQUIRE stderr,.no
 G104_REQUIRE target,.no
 G104_REQUIRE plain,.no
 G104_REQUIRE visual,.no
 G104_REQUIRE headless_event,.no
 G104_REQUIRE event,.no
 G104_REQUIRE payload,.no
 G104_REQUIRE headless,.no
 G104_REQUIRE jsonl,.no
 G104_REQUIRE target_conformance,.no
 G104_REQUIRE validate,.no
 G104_REQUIRE deterministic,.no
 G104_REQUIRE failure_atomic,.no
 G104_REQUIRE bounded,.no
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

neboc_g104_source_parse:
 call neboc_g072_source_parse
 test eax,eax
 jnz .done
 cmp qword [rel g72_seed],1401
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
 mov rdx,G104_FAMILY_KEY
 call ls_success
.done:
 ret
.range:
 mov edi,22
 call ls_error
 ret

%undef G104_REQUIRE
