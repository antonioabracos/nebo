; G061 public-source owner for native `${...}` interpolation.  The compiler
; validates every static literal, then emits only a pre-lowered mode and seed;
; the executable contains no template parser.
%define G61_FAMILY_KEY 0x5246323034473631
%include "compiler/parser/text/interpolation_plan.inc"

extern neboc_interpolation_parse_literal

section .rodata
%macro G61_NAME 2
g61_n_%1: db %2
g61_n_%1_len equ $-g61_n_%1
%endmacro
G61_NAME root,'InterpolatedTextExpr'
G61_NAME interpolation_start,'interpolationStartToken'
G61_NAME interpolation_end,'interpolationEndToken'
G61_NAME recovery,'interpolationRecovery'
G61_NAME escape_literal,'escapeLiteral'
G61_NAME literal_segment,'literalSegment'
G61_NAME expression_segment,'expressionSegment'
G61_NAME identifier,'identifier'
G61_NAME field_access,'fieldAccess'
G61_NAME codepoint_count,'codepointCount'
G61_NAME pure_expression,'pureExpression'
G61_NAME purity_check,'interpolationPurityCheck'
G61_NAME privacy_join,'interpolationPrivacyJoin'
G61_NAME pure_only,'pureOnly'
G61_NAME profile_expr,'formatProfileExpr'
G61_NAME fixed,'fixed'
G61_NAME hex,'hex'
G61_NAME align,'align'
G61_NAME left_to_right,'leftToRight'
G61_NAME exactly_once,'exactlyOnce'
G61_NAME temporary,'interpolationTemporary'
G61_NAME lower_plan,'lowerToFormatPlan'
G61_NAME ab_equivalence,'abFormatPlanEquivalence'
G61_NAME runtime_parse,'runtimeTemplateParseNo'
G61_NAME semantic_highlight,'semanticHighlight'
G61_NAME rename,'renameInsideInterpolation'
G61_NAME formatter,'formatterInterpolation'
G61_NAME diagnostics,'diagnostics'
G61_NAME determinism,'determinism'
G61_NAME conformance,'conformance'
G61_NAME closeout,'closeout'
G61_NAME console,'console'
%undef G61_NAME

section .bss align=16
g61_mode: resq 1
g61_seed: resq 1
g61_seed_seen: resq 1
g61_interpolation_seen: resq 1
g61_summary: resq 7

section .text
%macro G61_REQUIRE 2
 lea rsi,[rel g61_n_%1]
 mov edx,g61_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g61_is_program:
 lea rsi,[rel g61_n_root]
 mov edx,g61_n_root_len
 jmp ls_contains_atom

g61_known_call:
 push rbx
 mov rbx,rdi
%macro G61_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g61_n_%1]
 mov edx,g61_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G61_KNOWN interpolation_start
 G61_KNOWN interpolation_end
 G61_KNOWN recovery
 G61_KNOWN escape_literal
 G61_KNOWN literal_segment
 G61_KNOWN expression_segment
 G61_KNOWN identifier
 G61_KNOWN field_access
 G61_KNOWN codepoint_count
 G61_KNOWN pure_expression
 G61_KNOWN purity_check
 G61_KNOWN privacy_join
 G61_KNOWN pure_only
 G61_KNOWN profile_expr
 G61_KNOWN fixed
 G61_KNOWN hex
 G61_KNOWN align
 G61_KNOWN left_to_right
 G61_KNOWN exactly_once
 G61_KNOWN temporary
 G61_KNOWN lower_plan
 G61_KNOWN ab_equivalence
 G61_KNOWN runtime_parse
 G61_KNOWN semantic_highlight
 G61_KNOWN rename
 G61_KNOWN formatter
 G61_KNOWN diagnostics
 G61_KNOWN determinism
 G61_KNOWN conformance
 G61_KNOWN closeout
 G61_KNOWN console
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done:
 pop rbx
 ret
%undef G61_KNOWN

g61_select_mode:
 G61_REQUIRE diagnostics,.not_s09
 G61_REQUIRE determinism,.not_s09
 G61_REQUIRE conformance,.not_s09
 G61_REQUIRE closeout,.not_s09
 mov eax,9
 ret
.not_s09:
 G61_REQUIRE semantic_highlight,.not_s08
 G61_REQUIRE rename,.not_s08
 G61_REQUIRE formatter,.not_s08
 mov eax,8
 ret
.not_s08:
 G61_REQUIRE lower_plan,.not_s07
 G61_REQUIRE ab_equivalence,.not_s07
 G61_REQUIRE runtime_parse,.not_s07
 mov eax,7
 ret
.not_s07:
 G61_REQUIRE left_to_right,.not_s06
 G61_REQUIRE exactly_once,.not_s06
 G61_REQUIRE temporary,.not_s06
 mov eax,6
 ret
.not_s06:
 G61_REQUIRE profile_expr,.not_s05
 G61_REQUIRE fixed,.not_s05
 G61_REQUIRE hex,.not_s05
 G61_REQUIRE align,.not_s05
 mov eax,5
 ret
.not_s05:
 G61_REQUIRE pure_expression,.not_s04
 G61_REQUIRE purity_check,.not_s04
 G61_REQUIRE privacy_join,.not_s04
 G61_REQUIRE pure_only,.not_s04
 mov eax,4
 ret
.not_s04:
 G61_REQUIRE identifier,.not_s03
 G61_REQUIRE field_access,.not_s03
 mov eax,3
 ret
.not_s03:
 G61_REQUIRE literal_segment,.not_s02
 G61_REQUIRE expression_segment,.not_s02
 mov eax,2
 ret
.not_s02:
 G61_REQUIRE interpolation_start,.not_s01
 G61_REQUIRE interpolation_end,.not_s01
 G61_REQUIRE recovery,.not_s01
 G61_REQUIRE escape_literal,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g61_scan_program:
 push rbx
 push r12
 xor ebx,ebx
.scan:
 cmp rbx,[rel ls_token_count]
 jae .done
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_EOF
 je .done
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .text
 mov rdi,rbx
 call ls_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp qword [rel g61_seed_seen],0
 jne .next
 mov qword [rel g61_seed_seen],1
 mov [rel g61_seed],rdx
 jmp .next
.text:
 cmp eax,NEBOC_TOKEN_TEXT
 jne .dot
 mov rdi,rbx
 call ls_token_ptr
 mov r12,rax
 mov rsi,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rsi,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rsi,2
 jb .syntax
 sub rsi,2
 mov rdi,[rel ls_source]
 add rdi,[r12+NEBOC_TOKEN_START_OFFSET]
 inc rdi
 lea rdx,[rel g61_summary]
 call neboc_interpolation_parse_literal
 test eax,eax
 jz .text_ok
 cmp eax,INTERPOLATION_E_EFFECT
 je .effect
 cmp eax,INTERPOLATION_E_LIMIT
 je .limit
 jmp .syntax
.text_ok:
 mov qword [rel g61_interpolation_seen],1
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .next
 lea rdi,[rbx+1]
 call g61_known_call
 test eax,eax
 jz .unsupported
.next:
 inc rbx
 jmp .scan
.done:
 test rbx,rbx
 jz .syntax
 lea rdi,[rbx-1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RBRACE
 jne .syntax
 cmp qword [rel g61_seed_seen],1
 jne .syntax
 cmp qword [rel g61_seed],0
 je .syntax
 cmp qword [rel g61_interpolation_seen],1
 jne .syntax
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.limit: mov eax,24
 jmp .return
.effect: mov eax,24
 jmp .return
.unsupported: mov eax,24
.return:
 pop r12
 pop rbx
 ret

neboc_g061_source_parse:
 mov qword [rel g61_mode],0
 mov qword [rel g61_seed],0
 mov qword [rel g61_seed_seen],0
 mov qword [rel g61_interpolation_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g61_select_mode
 test eax,eax
 jz .syntax
 mov [rel g61_mode],rax
 call g61_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g61_mode]
 shl rax,32
 mov edi,dword [rel g61_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G61_FAMILY_KEY
 call ls_success
 ret
.syntax:
 mov edi,20
 call ls_error
 ret
.diagnostic:
 mov edi,eax
 call ls_error
 ret

%undef G61_REQUIRE
