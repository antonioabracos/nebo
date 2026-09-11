; Token-owned public-source vertical for the generic bounded Slash DSL core.
; Selection depends on language atoms only; paths and fixture identities are
; deliberately unavailable here.
%define SLASH_CORE_FAMILY_KEY 0x534c415348434f52
%define SLASH_CORE_MAX_PAYLOAD 4096
%define SLASH_CORE_MAX_SEED 0xffffffff

extern neboc_slash_validate
extern neboc_slash_advanced_validate

section .rodata
%macro SC_NAME 2
sc_n_%1: db %2
sc_n_%1_len equ $-sc_n_%1
%endmacro
SC_NAME root,'SlashPlan'
SC_NAME source,'source'
SC_NAME tokenize,'tokenize'
SC_NAME parse,'parse'
SC_NAME render,'render'
SC_NAME plain,'plain'
SC_NAME ansi,'ansi'
SC_NAME markdown,'markdown'
SC_NAME html,'html'
SC_NAME console,'console'
SC_NAME slash_token,'slashToken'
SC_NAME slash_directive,'slashDirective'
SC_NAME slash_argument,'slashArgument'
SC_NAME slash_content,'slashContent'
SC_NAME structure,'structure'
SC_NAME states,'states'
SC_NAME styles,'styles'
SC_NAME lists,'lists'
SC_NAME tables,'tables'
SC_NAME objects,'objects'
SC_NAME fallbacks,'fallbacks'
SC_NAME title,'title'
SC_NAME page,'page'
SC_NAME ok,'ok'
SC_NAME red,'red'
SC_NAME color,'color'
SC_NAME bg,'bg'
SC_NAME list,'list'
SC_NAME task,'task'
SC_NAME table,'table'
SC_NAME align,'align'
SC_NAME tree,'tree'
SC_NAME object,'object'
SC_NAME conformance,'slashConformance'
SC_NAME validate,'validate'
SC_NAME deterministic,'deterministic'
SC_NAME failure_atomic,'failureAtomic'
SC_NAME bounded,'bounded'
SC_NAME code_forms,'codeForms'
SC_NAME diagnostics_advanced,'diagnosticsAdvanced'
SC_NAME metrics_advanced,'metricsAdvanced'
SC_NAME documentation_advanced,'documentationAdvanced'
SC_NAME visual_advanced,'visualAdvanced'
SC_NAME i18n_advanced,'i18nAdvanced'
SC_NAME security_advanced,'securityAdvanced'
SC_NAME conditionals_advanced,'conditionalsAdvanced'
SC_NAME advanced_conformance,'advancedConformance'
SC_NAME diff_forms,'diffForms'
SC_NAME locations,'locations'
SC_NAME allow_raw,'allowRaw'
SC_NAME unknown_text,'unknownSlashAsText'
SC_NAME strict_slash,'strictSlash'
SC_NAME slash_fallback,'slashFallback'
%undef SC_NAME

section .bss align=16
sc_mode: resq 1
sc_seed: resq 1
sc_seed_seen: resq 1
sc_source_hash: resq 1
sc_source_seen: resq 1

section .text
%macro SC_REQUIRE 2
 lea rsi,[rel sc_n_%1]
 mov edx,sc_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

sc_select_mode:
 SC_REQUIRE advanced_conformance,.not_g065_s09
 SC_REQUIRE unknown_text,.not_g065_s09
 SC_REQUIRE strict_slash,.not_g065_s09
 SC_REQUIRE slash_fallback,.not_g065_s09
 mov eax,18
 ret
.not_g065_s09:
 SC_REQUIRE conditionals_advanced,.not_g065_s08
 mov eax,17
 ret
.not_g065_s08:
 SC_REQUIRE security_advanced,.not_g065_s07
 SC_REQUIRE allow_raw,.not_g065_s07
 mov eax,16
 ret
.not_g065_s07:
 SC_REQUIRE i18n_advanced,.not_g065_s06
 mov eax,15
 ret
.not_g065_s06:
 SC_REQUIRE visual_advanced,.not_g065_s05
 mov eax,14
 ret
.not_g065_s05:
 SC_REQUIRE documentation_advanced,.not_g065_s04
 mov eax,13
 ret
.not_g065_s04:
 SC_REQUIRE metrics_advanced,.not_g065_s03
 mov eax,12
 ret
.not_g065_s03:
 SC_REQUIRE diagnostics_advanced,.not_g065_s02
 mov eax,11
 ret
.not_g065_s02:
 SC_REQUIRE code_forms,.not_g065_s01
 SC_REQUIRE diff_forms,.not_g065_s01
 SC_REQUIRE locations,.not_g065_s01
 mov eax,10
 ret
.not_g065_s01:
 SC_REQUIRE conformance,.not_s09
 SC_REQUIRE validate,.not_s09
 SC_REQUIRE deterministic,.not_s09
 SC_REQUIRE failure_atomic,.not_s09
 SC_REQUIRE bounded,.not_s09
 mov eax,9
 ret
.not_s09:
 SC_REQUIRE fallbacks,.not_s08
 SC_REQUIRE render,.not_s08
 SC_REQUIRE plain,.not_s08
 SC_REQUIRE ansi,.not_s08
 SC_REQUIRE markdown,.not_s08
 SC_REQUIRE html,.not_s08
 SC_REQUIRE console,.not_s08
 mov eax,8
 ret
.not_s08:
 SC_REQUIRE objects,.not_s07
 SC_REQUIRE tree,.not_s07
 SC_REQUIRE object,.not_s07
 mov eax,7
 ret
.not_s07:
 SC_REQUIRE tables,.not_s06
 SC_REQUIRE table,.not_s06
 SC_REQUIRE align,.not_s06
 mov eax,6
 ret
.not_s06:
 SC_REQUIRE lists,.not_s05
 SC_REQUIRE list,.not_s05
 SC_REQUIRE task,.not_s05
 mov eax,5
 ret
.not_s05:
 SC_REQUIRE styles,.not_s04
 SC_REQUIRE color,.not_s04
 SC_REQUIRE bg,.not_s04
 mov eax,4
 ret
.not_s04:
 SC_REQUIRE states,.not_s03
 SC_REQUIRE ok,.not_s03
 SC_REQUIRE red,.not_s03
 mov eax,3
 ret
.not_s03:
 SC_REQUIRE structure,.not_s02
 SC_REQUIRE title,.not_s02
 SC_REQUIRE page,.not_s02
 mov eax,2
 ret
.not_s02:
 SC_REQUIRE slash_token,.not_s01
 SC_REQUIRE slash_directive,.not_s01
 SC_REQUIRE slash_argument,.not_s01
 SC_REQUIRE slash_content,.not_s01
 SC_REQUIRE tokenize,.not_s01
 SC_REQUIRE parse,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

sc_is_program:
 lea rsi,[rel sc_n_root]
 mov edx,sc_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
 call sc_select_mode
 test eax,eax
 setnz al
 movzx eax,al
 ret
.no:
 xor eax,eax
 ret

sc_known_call:
 push rbx
 mov rbx,rdi
%macro SC_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel sc_n_%1]
 mov edx,sc_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 SC_KNOWN source
 SC_KNOWN tokenize
 SC_KNOWN parse
 SC_KNOWN render
 SC_KNOWN plain
 SC_KNOWN ansi
 SC_KNOWN markdown
 SC_KNOWN html
 SC_KNOWN console
 SC_KNOWN slash_token
 SC_KNOWN slash_directive
 SC_KNOWN slash_argument
 SC_KNOWN slash_content
 SC_KNOWN structure
 SC_KNOWN states
 SC_KNOWN styles
 SC_KNOWN lists
 SC_KNOWN tables
 SC_KNOWN objects
 SC_KNOWN fallbacks
 SC_KNOWN title
 SC_KNOWN page
 SC_KNOWN ok
 SC_KNOWN red
 SC_KNOWN color
 SC_KNOWN bg
 SC_KNOWN list
 SC_KNOWN task
 SC_KNOWN table
 SC_KNOWN align
 SC_KNOWN tree
 SC_KNOWN object
 SC_KNOWN conformance
 SC_KNOWN validate
 SC_KNOWN deterministic
 SC_KNOWN failure_atomic
 SC_KNOWN bounded
 SC_KNOWN code_forms
 SC_KNOWN diagnostics_advanced
 SC_KNOWN metrics_advanced
 SC_KNOWN documentation_advanced
 SC_KNOWN visual_advanced
 SC_KNOWN i18n_advanced
 SC_KNOWN security_advanced
 SC_KNOWN conditionals_advanced
 SC_KNOWN advanced_conformance
 SC_KNOWN diff_forms
 SC_KNOWN locations
 SC_KNOWN allow_raw
 SC_KNOWN unknown_text
 SC_KNOWN strict_slash
 SC_KNOWN slash_fallback
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef SC_KNOWN

; RDI dot token -> EAX boolean for exact bounded argument grammar.
sc_validate_call:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 lea rdi,[rbx+1]
 lea rsi,[rel sc_n_source]
 mov edx,sc_n_source_len
 call ls_token_match
 test eax,eax
 jnz .source
 lea rdi,[rbx+1]
 lea rsi,[rel sc_n_render]
 mov edx,sc_n_render_len
 call ls_token_match
 test eax,eax
 jnz .render
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.source:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_TEXT
 jne .bad
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 mov r8,[rax+NEBOC_TOKEN_START_OFFSET]
 sub rdx,r8
 cmp rdx,SLASH_CORE_MAX_PAYLOAD+2
 ja .bad
 cmp rdx,2
 jb .bad
 sub rdx,2
 mov r13,rdx
 mov r12,[rel ls_source]
 lea r12,[r12+r8+1]
 mov rsi,r13
 mov rdi,r12
 cmp qword [rel sc_mode],10
 jb .source_core_validate
 xor edx,edx
 cmp qword [rel sc_mode],16
 jne .source_unknown_policy
 mov edx,2
.source_unknown_policy:
 cmp qword [rel sc_mode],18
 jne .source_advanced_validate
 mov edx,1
.source_advanced_validate:
 xor ecx,ecx
 call neboc_slash_advanced_validate
 jmp .source_validate_done
.source_core_validate:
 call neboc_slash_validate
.source_validate_done:
 test eax,eax
 jnz .bad
 cmp qword [rel sc_source_seen],0
 jne .bad
 mov eax,2166136261
 xor ecx,ecx
.hash:
 cmp rcx,r13
 jae .hash_done
 movzx edx,byte [r12+rcx]
 xor eax,edx
 imul eax,eax,16777619
 inc rcx
 jmp .hash
.hash_done:
 mov [rel sc_source_hash],rax
 mov qword [rel sc_source_seen],1
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.render:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_DOT
 jne .bad
 lea rdi,[rbx+4]
 call sc_known_call
 test eax,eax
 jz .bad
 lea rdi,[rbx+5]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .bad
 lea rdi,[rbx+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .bad
 lea rdi,[rbx+7]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.bad:
 xor eax,eax
.done:
 pop r13
 pop r12
 pop rbx
 ret

sc_scan_program:
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
 jne .text
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
 test rdx,rdx
 jz .unsupported
 mov rax,SLASH_CORE_MAX_SEED
 cmp rdx,rax
 ja .unsupported
 cmp qword [rel sc_seed_seen],0
 jne .unsupported
 mov qword [rel sc_seed_seen],1
 mov [rel sc_seed],rdx
 jmp .next
.text:
 cmp eax,NEBOC_TOKEN_TEXT
 jne .dot
 mov rdi,rbx
 call ls_token_ptr
 test rax,rax
 jz .syntax
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,SLASH_CORE_MAX_PAYLOAD+2
 ja .unsupported
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .next
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .next
 lea rdi,[rbx+1]
 call sc_known_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call sc_validate_call
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
 cmp qword [rel sc_seed_seen],1
 jne .unsupported
 cmp qword [rel sc_source_seen],1
 jne .unsupported
 xor eax,eax
 jmp .return
.syntax:
 mov eax,20
 jmp .return
.unsupported:
 mov eax,24
.return:
 pop rbx
 ret

neboc_slash_core_source_parse:
 mov qword [rel sc_mode],0
 mov qword [rel sc_seed],0
 mov qword [rel sc_seed_seen],0
 mov qword [rel sc_source_hash],0
 mov qword [rel sc_source_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call sc_select_mode
 test eax,eax
 jz .unsupported
 mov [rel sc_mode],rax
 call sc_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel sc_mode]
 shl rax,32
 mov edi,dword [rel sc_seed]
 xor edi,dword [rel sc_source_hash]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,SLASH_CORE_FAMILY_KEY
 call ls_success
 ret
.syntax:
 mov edi,20
 call ls_error
 ret
.unsupported:
 mov edi,24
 call ls_error
 ret
.diagnostic:
 mov edi,eax
 call ls_error
 ret

%undef SC_REQUIRE
