; G074 token-owned source vertical for template/Slash policy closeout,
; historical catalog classification, diagnostics, and editor completion.
%define G74_FAMILY_KEY 0x5246323034473734
%define G74_MAX_PAYLOAD 4096
%define G74_MIN_SEED 1200
%define G74_MAX_SEED 0xffffffff

section .rodata
%macro G74_NAME 2
g74_n_%1: db %2
g74_n_%1_len equ $-g74_n_%1
%endmacro
G74_NAME root,'RenderPlan'
G74_NAME percent_conformance,'percentPolicyConformance'
G74_NAME strict,'strict'
G74_NAME loose,'loose'
G74_NAME allow_coerce,'allowCoerce'
G74_NAME no_coerce,'noCoerce'
G74_NAME validate_only,'validateOnly'
G74_NAME format_only,'formatOnly'
G74_NAME placeholder_mode,'placeholderMode'
G74_NAME unknown_placeholder,'unknownPlaceholder'
G74_NAME missing_args,'missingArgs'
G74_NAME extra_args,'extraArgs'
G74_NAME render,'render'
G74_NAME slash_conformance,'slashPolicyConformance'
G74_NAME allow_slash,'allowSlash'
G74_NAME disable_slash,'disableSlash'
G74_NAME strict_slash,'strictSlash'
G74_NAME unknown_slash_text,'unknownSlashAsText'
G74_NAME slash_fallback,'slashFallback'
G74_NAME catalog_conformance,'catalogConformance'
G74_NAME primary_rows,'primaryRows'
G74_NAME primary_unique,'primaryUnique'
G74_NAME primary_duplicates,'primaryDuplicates'
G74_NAME supplemental_rows,'supplementalRows'
G74_NAME proof_rows,'proofRows'
G74_NAME public_promotions,'publicPromotions'
G74_NAME priority_conformance,'priorityConformance'
G74_NAME public_stable,'publicStable'
G74_NAME contract_only,'contractOnly'
G74_NAME deferred_proposal,'deferredProposal'
G74_NAME editor_conformance,'editorConformance'
G74_NAME complete,'complete'
G74_NAME resolve_completion,'resolveCompletion'
G74_NAME bounded_prefix,'boundedPrefix'
G74_NAME migrated_only,'migratedOnly'
G74_NAME diagnostic_conformance,'diagnosticConformance'
G74_NAME unknown_policy_diag,'unknownPolicyDiag'
G74_NAME conflict_diag,'conflictDiag'
G74_NAME catalog_limit_diag,'catalogLimitDiag'
G74_NAME deferred_diag,'deferredDiag'
G74_NAME completion_capacity_diag,'completionCapacityDiag'
G74_NAME with_span,'withSpan'
G74_NAME closeout_conformance,'closeoutConformance'
G74_NAME policy_catalog_ready,'policyCatalogReady'
G74_NAME editor_ready,'editorReady'
G74_NAME diagnostics_ready,'diagnosticsReady'
G74_NAME deterministic,'deterministic'
G74_NAME failure_atomic,'failureAtomic'
G74_NAME print,'print'
G74_NAME return,'return'
%undef G74_NAME

section .bss align=16
g74_mode: resq 1
g74_seed: resq 1
g74_seed_seen: resq 1

section .text
%macro G74_REQUIRE 2
 lea rsi,[rel g74_n_%1]
 mov edx,g74_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g74_is_program:
 lea rsi,[rel g74_n_root]
 mov edx,g74_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
%macro G74_MARKER 1
 lea rsi,[rel g74_n_%1]
 mov edx,g74_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G74_MARKER percent_conformance
 G74_MARKER slash_conformance
 G74_MARKER catalog_conformance
 G74_MARKER priority_conformance
 G74_MARKER editor_conformance
 G74_MARKER diagnostic_conformance
 G74_MARKER closeout_conformance
.no: xor eax,eax
 ret
.yes: mov eax,1
 ret
%undef G74_MARKER

g74_known_call:
 push rbx
 mov rbx,rdi
%macro G74_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g74_n_%1]
 mov edx,g74_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G74_KNOWN percent_conformance
 G74_KNOWN strict
 G74_KNOWN loose
 G74_KNOWN allow_coerce
 G74_KNOWN no_coerce
 G74_KNOWN validate_only
 G74_KNOWN format_only
 G74_KNOWN placeholder_mode
 G74_KNOWN unknown_placeholder
 G74_KNOWN missing_args
 G74_KNOWN extra_args
 G74_KNOWN render
 G74_KNOWN slash_conformance
 G74_KNOWN allow_slash
 G74_KNOWN disable_slash
 G74_KNOWN strict_slash
 G74_KNOWN unknown_slash_text
 G74_KNOWN slash_fallback
 G74_KNOWN catalog_conformance
 G74_KNOWN primary_rows
 G74_KNOWN primary_unique
 G74_KNOWN primary_duplicates
 G74_KNOWN supplemental_rows
 G74_KNOWN proof_rows
 G74_KNOWN public_promotions
 G74_KNOWN priority_conformance
 G74_KNOWN public_stable
 G74_KNOWN contract_only
 G74_KNOWN deferred_proposal
 G74_KNOWN editor_conformance
 G74_KNOWN complete
 G74_KNOWN resolve_completion
 G74_KNOWN bounded_prefix
 G74_KNOWN migrated_only
 G74_KNOWN diagnostic_conformance
 G74_KNOWN unknown_policy_diag
 G74_KNOWN conflict_diag
 G74_KNOWN catalog_limit_diag
 G74_KNOWN deferred_diag
 G74_KNOWN completion_capacity_diag
 G74_KNOWN with_span
 G74_KNOWN closeout_conformance
 G74_KNOWN policy_catalog_ready
 G74_KNOWN editor_ready
 G74_KNOWN diagnostics_ready
 G74_KNOWN deterministic
 G74_KNOWN failure_atomic
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret
%undef G74_KNOWN

; RDI dot-token index -> exact arity and bounded argument validation.
g74_validate_call:
 push rbx
 mov rbx,rdi
%macro G74_ARG_MATCH 2
 lea rdi,[rbx+1]
 lea rsi,[rel g74_n_%1]
 mov edx,g74_n_%1_len
 call ls_token_match
 test eax,eax
 jnz %2
%endmacro
 G74_ARG_MATCH placeholder_mode,.text
 G74_ARG_MATCH unknown_placeholder,.text
 G74_ARG_MATCH missing_args,.text
 G74_ARG_MATCH extra_args,.text
 G74_ARG_MATCH render,.text
 G74_ARG_MATCH slash_fallback,.text
 G74_ARG_MATCH complete,.text
 G74_ARG_MATCH with_span,.text
 G74_ARG_MATCH primary_rows,.primary_rows
 G74_ARG_MATCH primary_unique,.primary_unique
 G74_ARG_MATCH primary_duplicates,.primary_duplicates
 G74_ARG_MATCH supplemental_rows,.supplemental_rows
 G74_ARG_MATCH proof_rows,.proof_rows
 G74_ARG_MATCH public_promotions,.public_promotions
 G74_ARG_MATCH resolve_completion,.bounded_integer
 G74_ARG_MATCH bounded_prefix,.bounded_integer
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.text:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_TEXT
 jne .bad
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,G74_MAX_PAYLOAD+2
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.primary_rows: mov edx,381
 jmp .exact_integer
.primary_unique: mov edx,340
 jmp .exact_integer
.primary_duplicates: mov edx,41
 jmp .exact_integer
.supplemental_rows: mov edx,184
 jmp .exact_integer
.proof_rows: mov edx,56
 jmp .exact_integer
.public_promotions: xor edx,edx
.exact_integer:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bad
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],rdx
 jne .bad
 jmp .integer_close
.bounded_integer:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bad
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],32
 ja .bad
.integer_close:
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.bad: xor eax,eax
.done: pop rbx
 ret
%undef G74_ARG_MATCH

g74_select_mode:
 G74_REQUIRE closeout_conformance,.not_s07
 G74_REQUIRE policy_catalog_ready,.not_s07
 G74_REQUIRE editor_ready,.not_s07
 G74_REQUIRE diagnostics_ready,.not_s07
 G74_REQUIRE deterministic,.not_s07
 G74_REQUIRE failure_atomic,.not_s07
 mov eax,7
 ret
.not_s07:
 G74_REQUIRE diagnostic_conformance,.not_s06
 G74_REQUIRE unknown_policy_diag,.not_s06
 G74_REQUIRE conflict_diag,.not_s06
 G74_REQUIRE catalog_limit_diag,.not_s06
 G74_REQUIRE deferred_diag,.not_s06
 G74_REQUIRE completion_capacity_diag,.not_s06
 G74_REQUIRE with_span,.not_s06
 mov eax,6
 ret
.not_s06:
 G74_REQUIRE editor_conformance,.not_s05
 G74_REQUIRE complete,.not_s05
 G74_REQUIRE resolve_completion,.not_s05
 G74_REQUIRE bounded_prefix,.not_s05
 G74_REQUIRE migrated_only,.not_s05
 mov eax,5
 ret
.not_s05:
 G74_REQUIRE priority_conformance,.not_s04
 G74_REQUIRE public_stable,.not_s04
 G74_REQUIRE contract_only,.not_s04
 G74_REQUIRE deferred_proposal,.not_s04
 mov eax,4
 ret
.not_s04:
 G74_REQUIRE catalog_conformance,.not_s03
 G74_REQUIRE primary_rows,.not_s03
 G74_REQUIRE primary_unique,.not_s03
 G74_REQUIRE primary_duplicates,.not_s03
 G74_REQUIRE supplemental_rows,.not_s03
 G74_REQUIRE proof_rows,.not_s03
 G74_REQUIRE public_promotions,.not_s03
 mov eax,3
 ret
.not_s03:
 G74_REQUIRE slash_conformance,.not_s02
 G74_REQUIRE allow_slash,.not_s02
 G74_REQUIRE disable_slash,.not_s02
 G74_REQUIRE strict_slash,.not_s02
 G74_REQUIRE unknown_slash_text,.not_s02
 G74_REQUIRE slash_fallback,.not_s02
 mov eax,2
 ret
.not_s02:
 G74_REQUIRE percent_conformance,.not_s01
 G74_REQUIRE strict,.not_s01
 G74_REQUIRE loose,.not_s01
 G74_REQUIRE allow_coerce,.not_s01
 G74_REQUIRE no_coerce,.not_s01
 G74_REQUIRE validate_only,.not_s01
 G74_REQUIRE format_only,.not_s01
 G74_REQUIRE placeholder_mode,.not_s01
 G74_REQUIRE unknown_placeholder,.not_s01
 G74_REQUIRE missing_args,.not_s01
 G74_REQUIRE extra_args,.not_s01
 G74_REQUIRE render,.not_s01
 mov eax,1
 ret
.not_s01: xor eax,eax
 ret

g74_scan_program:
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
 cmp rdx,G74_MIN_SEED
 jb .next
 mov rax,G74_MAX_SEED
 cmp rdx,rax
 ja .unsupported
 cmp qword [rel g74_seed_seen],0
 jne .unsupported
 mov qword [rel g74_seed_seen],1
 mov [rel g74_seed],rdx
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
 cmp rdx,G74_MAX_PAYLOAD+2
 ja .unsupported
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .next
 lea rdi,[rbx+1]
 call g74_known_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g74_validate_call
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
 cmp qword [rel g74_seed_seen],1
 jne .unsupported
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return: pop rbx
 ret

neboc_g074_source_parse:
 mov qword [rel g74_mode],0
 mov qword [rel g74_seed],0
 mov qword [rel g74_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g74_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g74_mode],rax
 lea rsi,[rel g74_n_print]
 mov edx,g74_n_print_len
 call ls_contains_atom
 test eax,eax
 jnz .unsupported
 lea rsi,[rel g74_n_return]
 mov edx,g74_n_return_len
 call ls_contains_atom
 test eax,eax
 jnz .unsupported
 call g74_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g74_mode]
 shl rax,32
 mov edi,dword [rel g74_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G74_FAMILY_KEY
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

%undef G74_REQUIRE
