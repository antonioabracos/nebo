; G073 token-owned source vertical for bounded testability and conditional rendering.
%define G73_FAMILY_KEY 0x5246323034473733
%define G73_MAX_PAYLOAD 4096
%define G73_MIN_SEED 1100
%define G73_MAX_SEED 0xffffffff
%define G73_MAX_COUNT 64

section .rodata
%macro G73_NAME 2
g73_n_%1: db %2
g73_n_%1_len equ $-g73_n_%1
%endmacro
G73_NAME root,'RenderPlan'
G73_NAME capture,'capture'
G73_NAME mock,'mock'
G73_NAME snapshot,'snapshot'
G73_NAME golden,'golden'
G73_NAME silent,'silent'
G73_NAME assert_contains,'assertContains'
G73_NAME assert_equals,'assertEquals'
G73_NAME test_only,'testOnly'
G73_NAME normalize_output,'normalizeOutput'
G73_NAME explain,'explain'
G73_NAME teach,'teach'
G73_NAME step,'step'
G73_NAME show_type,'showType'
G73_NAME show_expression,'showExpression'
G73_NAME show_evaluation,'showEvaluation'
G73_NAME why,'why'
G73_NAME lesson,'lesson'
G73_NAME beginner,'beginner'
G73_NAME advanced,'advanced'
G73_NAME when,'when'
G73_NAME unless,'unless'
G73_NAME only_if,'onlyIf'
G73_NAME skip_if,'skipIf'
G73_NAME once,'once'
G73_NAME every,'every'
G73_NAME first,'first'
G73_NAME group,'group'
G73_NAME group_end,'groupEnd'
G73_NAME scope,'scope'
G73_NAME section,'section'
G73_NAME indent_group,'indentGroup'
G73_NAME replay,'replay'
G73_NAME snapshot_hash,'snapshotHash'
G73_NAME compare_snapshot,'compareSnapshot'
G73_NAME normalize_newlines,'normalizeNewlines'
G73_NAME deterministic_seed,'deterministicSeed'
G73_NAME capture_limit,'captureLimit'
G73_NAME testability_conformance,'testabilityConformance'
G73_NAME validate,'validate'
G73_NAME deterministic,'deterministic'
G73_NAME failure_atomic,'failureAtomic'
G73_NAME true,'true'
G73_NAME false,'false'
G73_NAME print,'print'
%undef G73_NAME

section .bss align=16
g73_mode: resq 1
g73_seed: resq 1
g73_seed_seen: resq 1

section .text
%macro G73_REQUIRE 2
 lea rsi,[rel g73_n_%1]
 mov edx,g73_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g73_is_program:
 lea rsi,[rel g73_n_root]
 mov edx,g73_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
%macro G73_MARKER 1
 lea rsi,[rel g73_n_%1]
 mov edx,g73_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G73_MARKER capture
 G73_MARKER explain
 G73_MARKER only_if
 G73_MARKER group_end
 G73_MARKER snapshot_hash
 G73_MARKER testability_conformance
.no: xor eax,eax
 ret
.yes: mov eax,1
 ret
%undef G73_MARKER

g73_known_call:
 push rbx
 mov rbx,rdi
%macro G73_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g73_n_%1]
 mov edx,g73_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G73_KNOWN capture
 G73_KNOWN mock
 G73_KNOWN snapshot
 G73_KNOWN golden
 G73_KNOWN silent
 G73_KNOWN assert_contains
 G73_KNOWN assert_equals
 G73_KNOWN test_only
 G73_KNOWN normalize_output
 G73_KNOWN explain
 G73_KNOWN teach
 G73_KNOWN step
 G73_KNOWN show_type
 G73_KNOWN show_expression
 G73_KNOWN show_evaluation
 G73_KNOWN why
 G73_KNOWN lesson
 G73_KNOWN beginner
 G73_KNOWN advanced
 G73_KNOWN when
 G73_KNOWN unless
 G73_KNOWN only_if
 G73_KNOWN skip_if
 G73_KNOWN once
 G73_KNOWN every
 G73_KNOWN first
 G73_KNOWN group
 G73_KNOWN group_end
 G73_KNOWN scope
 G73_KNOWN section
 G73_KNOWN indent_group
 G73_KNOWN replay
 G73_KNOWN snapshot_hash
 G73_KNOWN compare_snapshot
 G73_KNOWN normalize_newlines
 G73_KNOWN deterministic_seed
 G73_KNOWN capture_limit
 G73_KNOWN testability_conformance
 G73_KNOWN validate
 G73_KNOWN deterministic
 G73_KNOWN failure_atomic
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret
%undef G73_KNOWN

; RDI dot-token index -> EAX boolean for exact arity and bounded argument kind.
g73_validate_call:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 lea r12,[rbx+1]
%macro G73_ARG_MATCH 2
 mov rdi,r12
 lea rsi,[rel g73_n_%1]
 mov edx,g73_n_%1_len
 call ls_token_match
 test eax,eax
 jnz %2
%endmacro
 G73_ARG_MATCH golden,.text
 G73_ARG_MATCH assert_contains,.text
 G73_ARG_MATCH assert_equals,.text
 G73_ARG_MATCH teach,.text
 G73_ARG_MATCH lesson,.text
 G73_ARG_MATCH scope,.text
 G73_ARG_MATCH section,.text
 G73_ARG_MATCH group,.optional_text
 G73_ARG_MATCH when,.boolean
 G73_ARG_MATCH unless,.boolean
 G73_ARG_MATCH only_if,.boolean
 G73_ARG_MATCH skip_if,.boolean
 G73_ARG_MATCH every,.count
 G73_ARG_MATCH first,.count
 G73_ARG_MATCH deterministic_seed,.integer
 G73_ARG_MATCH capture_limit,.integer
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.optional_text:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .good
 cmp eax,NEBOC_TOKEN_TEXT
 jne .bad
 jmp .bounded_text
.text:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_TEXT
 jne .bad
.bounded_text:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,G73_MAX_PAYLOAD+2
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .good
 jmp .bad
.boolean:
 lea rdi,[rbx+3]
 lea rsi,[rel g73_n_true]
 mov edx,g73_n_true_len
 call ls_token_match
 test eax,eax
 jnz .boolean_close
 lea rdi,[rbx+3]
 lea rsi,[rel g73_n_false]
 mov edx,g73_n_false_len
 call ls_token_match
 test eax,eax
 jz .bad
.boolean_close:
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .good
 jmp .bad
.count:
 mov r13d,G73_MAX_COUNT
 jmp .bounded_integer
.integer:
 mov r13d,G73_MAX_PAYLOAD
.bounded_integer:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bad
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test rdx,rdx
 jz .bad
 cmp rdx,r13
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .good
.bad: xor eax,eax
 jmp .done
.good: mov eax,1
.done:
 pop r13
 pop r12
 pop rbx
 ret
%undef G73_ARG_MATCH

g73_select_mode:
 G73_REQUIRE testability_conformance,.not_s06
 G73_REQUIRE validate,.not_s06
 G73_REQUIRE deterministic,.not_s06
 G73_REQUIRE failure_atomic,.not_s06
 mov eax,6
 ret
.not_s06:
 G73_REQUIRE replay,.not_s05
 G73_REQUIRE snapshot_hash,.not_s05
 G73_REQUIRE compare_snapshot,.not_s05
 G73_REQUIRE normalize_newlines,.not_s05
 G73_REQUIRE deterministic_seed,.not_s05
 G73_REQUIRE capture_limit,.not_s05
 mov eax,5
 ret
.not_s05:
 G73_REQUIRE group,.not_s04
 G73_REQUIRE group_end,.not_s04
 G73_REQUIRE scope,.not_s04
 G73_REQUIRE section,.not_s04
 G73_REQUIRE indent_group,.not_s04
 mov eax,4
 ret
.not_s04:
 G73_REQUIRE when,.not_s03
 G73_REQUIRE unless,.not_s03
 G73_REQUIRE only_if,.not_s03
 G73_REQUIRE skip_if,.not_s03
 G73_REQUIRE once,.not_s03
 G73_REQUIRE every,.not_s03
 G73_REQUIRE first,.not_s03
 mov eax,3
 ret
.not_s03:
 G73_REQUIRE explain,.not_s02
 G73_REQUIRE teach,.not_s02
 G73_REQUIRE step,.not_s02
 G73_REQUIRE show_type,.not_s02
 G73_REQUIRE show_expression,.not_s02
 G73_REQUIRE show_evaluation,.not_s02
 G73_REQUIRE why,.not_s02
 G73_REQUIRE lesson,.not_s02
 G73_REQUIRE beginner,.not_s02
 G73_REQUIRE advanced,.not_s02
 mov eax,2
 ret
.not_s02:
 G73_REQUIRE capture,.not_s01
 G73_REQUIRE mock,.not_s01
 G73_REQUIRE snapshot,.not_s01
 G73_REQUIRE golden,.not_s01
 G73_REQUIRE silent,.not_s01
 G73_REQUIRE assert_contains,.not_s01
 G73_REQUIRE assert_equals,.not_s01
 G73_REQUIRE test_only,.not_s01
 G73_REQUIRE normalize_output,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g73_scan_program:
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
 cmp rdx,G73_MIN_SEED
 jb .next
 mov rax,G73_MAX_SEED
 cmp rdx,rax
 ja .unsupported
 cmp qword [rel g73_seed_seen],0
 jne .unsupported
 mov qword [rel g73_seed_seen],1
 mov [rel g73_seed],rdx
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
 cmp rdx,G73_MAX_PAYLOAD+2
 ja .unsupported
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 ; Match the method lexeme rather than requiring IDENTIFIER: `when` is a
 ; canonical keyword token, but remains a valid RenderPlan method after dot.
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .next
 lea rdi,[rbx+1]
 call g73_known_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g73_validate_call
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
 cmp qword [rel g73_seed_seen],1
 jne .unsupported
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return: pop rbx
 ret

neboc_g073_source_parse:
 mov qword [rel g73_mode],0
 mov qword [rel g73_seed],0
 mov qword [rel g73_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g73_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g73_mode],rax
 lea rsi,[rel g73_n_print]
 mov edx,g73_n_print_len
 call ls_contains_atom
 test eax,eax
 jnz .unsupported
 call g73_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g73_mode]
 shl rax,32
 mov edi,dword [rel g73_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G73_FAMILY_KEY
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

%undef G73_REQUIRE
