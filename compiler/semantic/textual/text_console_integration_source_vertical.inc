; G084 token-owned source vertical for bounded RF84 integration evidence.
; Rf84Closeout84 is an internal evidence facade, not a new public API.
%define G84_FAMILY_KEY 0x5246323034473834
%define G84_MIN_SEED 8401
%define G84_MAX_SEED 999999

section .rodata
%macro G84_NAME 2
g84_n_%1: db %2
g84_n_%1_len equ $-g84_n_%1
%endmacro
G84_NAME root,'Rf84Closeout84'
G84_NAME s01,'registries84'
G84_NAME s02,'equivalence84'
G84_NAME s03,'textFormatConsole84'
G84_NAME s04,'scanConsoleForms84'
G84_NAME s05,'formatsFsDataset84'
G84_NAME s06,'privacySecurity84'
G84_NAME s07,'unicodeLocale84'
G84_NAME s08,'performanceDeterminism84'
G84_NAME s09,'publicExamples84'
G84_NAME s10,'closeout84'
G84_NAME text_api_registry,'textApiRegistry'
G84_NAME output_registry,'outputCapabilityRegistry'
G84_NAME scan_registry,'scanCapabilityRegistry'
G84_NAME format_registry,'formatProfileRegistry'
G84_NAME diagnostic_registry,'diagnosticRegistry'
G84_NAME schema_registry,'schemaRegistry'
G84_NAME ab_corpus,'abEquivalenceCorpus'
G84_NAME dynamic_corpus,'dynamicTemplateCorpus'
G84_NAME pure_corpus,'pureExpressionCorpus'
G84_NAME console_separation,'consoleOptionsSeparation'
G84_NAME composition_green,'compositionGreen'
G84_NAME security_green,'securityGreen'
G84_NAME unicode_bounded,'unicodeBounded'
G84_NAME budget_green,'budgetGreen'
G84_NAME docs_green,'docsGreen'
G84_NAME independent_audit,'independentAudit'
G84_NAME zero_findings,'zeroFindings'
G84_NAME all_green,'allGreen'
G84_NAME print,'print'
G84_NAME return,'return'
%undef G84_NAME

section .bss align=16
g84_mode: resq 1
g84_seed: resq 1
g84_seed_seen: resq 1

section .text
%macro G84_REQUIRE 2
 lea rsi,[rel g84_n_%1]
 mov edx,g84_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g84_is_program:
 lea rsi,[rel g84_n_root]
 mov edx,g84_n_root_len
 call ls_contains_atom
 ret

g84_known_call:
 push rbx
 mov rbx,rdi
%macro G84_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g84_n_%1]
 mov edx,g84_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G84_KNOWN s01
 G84_KNOWN s02
 G84_KNOWN s03
 G84_KNOWN s04
 G84_KNOWN s05
 G84_KNOWN s06
 G84_KNOWN s07
 G84_KNOWN s08
 G84_KNOWN s09
 G84_KNOWN s10
 G84_KNOWN text_api_registry
 G84_KNOWN output_registry
 G84_KNOWN scan_registry
 G84_KNOWN format_registry
 G84_KNOWN diagnostic_registry
 G84_KNOWN schema_registry
 G84_KNOWN ab_corpus
 G84_KNOWN dynamic_corpus
 G84_KNOWN pure_corpus
 G84_KNOWN console_separation
 G84_KNOWN composition_green
 G84_KNOWN security_green
 G84_KNOWN unicode_bounded
 G84_KNOWN budget_green
 G84_KNOWN docs_green
 G84_KNOWN independent_audit
 G84_KNOWN zero_findings
 G84_KNOWN all_green
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret
%undef G84_KNOWN

; The evidence-facade methods are nullary; typed owners are exercised by the
; independent native and registry oracles.
g84_validate_call:
 lea rdi,[rdi+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 ret

g84_select_mode:
 G84_REQUIRE s10,.not_s10
 G84_REQUIRE independent_audit,.not_s10
 G84_REQUIRE zero_findings,.not_s10
 G84_REQUIRE all_green,.not_s10
 mov eax,10
 ret
.not_s10:
 G84_REQUIRE s09,.not_s09
 G84_REQUIRE docs_green,.not_s09
 mov eax,9
 ret
.not_s09:
 G84_REQUIRE s08,.not_s08
 G84_REQUIRE budget_green,.not_s08
 mov eax,8
 ret
.not_s08:
 G84_REQUIRE s07,.not_s07
 G84_REQUIRE unicode_bounded,.not_s07
 mov eax,7
 ret
.not_s07:
 G84_REQUIRE s06,.not_s06
 G84_REQUIRE security_green,.not_s06
 mov eax,6
 ret
.not_s06:
 G84_REQUIRE s05,.not_s05
 G84_REQUIRE composition_green,.not_s05
 mov eax,5
 ret
.not_s05:
 G84_REQUIRE s04,.not_s04
 G84_REQUIRE composition_green,.not_s04
 mov eax,4
 ret
.not_s04:
 G84_REQUIRE s03,.not_s03
 G84_REQUIRE composition_green,.not_s03
 mov eax,3
 ret
.not_s03:
 G84_REQUIRE s02,.not_s02
 G84_REQUIRE ab_corpus,.not_s02
 G84_REQUIRE dynamic_corpus,.not_s02
 G84_REQUIRE pure_corpus,.not_s02
 G84_REQUIRE console_separation,.not_s02
 mov eax,2
 ret
.not_s02:
 G84_REQUIRE s01,.not_s01
 G84_REQUIRE text_api_registry,.not_s01
 G84_REQUIRE output_registry,.not_s01
 G84_REQUIRE scan_registry,.not_s01
 G84_REQUIRE format_registry,.not_s01
 G84_REQUIRE diagnostic_registry,.not_s01
 G84_REQUIRE schema_registry,.not_s01
 mov eax,1
 ret
.not_s01: xor eax,eax
 ret

g84_scan_program:
 push rbx
 xor ebx,ebx
.scan:
 cmp rbx,[rel ls_token_count]
 jae .done
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_EOF
 je .done
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .dot
 test rbx,rbx
 jz .seed_candidate
 lea rdi,[rbx-1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 je .next
 cmp eax,NEBOC_TOKEN_COMMA
 je .next
.seed_candidate:
 mov rdi,rbx
 call ls_token_ptr
 test rax,rax
 jz .syntax
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rdx,G84_MIN_SEED
 jb .next
 cmp rdx,G84_MAX_SEED
 ja .unsupported
 cmp qword [rel g84_seed_seen],0
 jne .unsupported
 mov qword [rel g84_seed_seen],1
 mov [rel g84_seed],rdx
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .next
 lea rdi,[rbx+1]
 call g84_known_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g84_validate_call
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
 cmp qword [rel g84_seed_seen],1
 jne .unsupported
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return: pop rbx
 ret

neboc_g084_source_parse:
 mov qword [rel g84_mode],0
 mov qword [rel g84_seed],0
 mov qword [rel g84_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g84_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g84_mode],rax
 lea rsi,[rel g84_n_print]
 mov edx,g84_n_print_len
 call ls_contains_atom
 test eax,eax
 jnz .unsupported
 lea rsi,[rel g84_n_return]
 mov edx,g84_n_return_len
 call ls_contains_atom
 test eax,eax
 jnz .unsupported
 call g84_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g84_mode]
 shl rax,32
 mov edi,dword [rel g84_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G84_FAMILY_KEY
 call ls_success
 ret
.syntax: mov edi,20
 call ls_error
 ret
.unsupported: mov edi,24
 call ls_error
 ret
.diagnostic: mov edi,eax
 call ls_error
 ret

%undef G84_REQUIRE
