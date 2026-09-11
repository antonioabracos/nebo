; G083 token-owned source vertical for bounded regex and source tooling.
; The TextTooling83 root is an evidence facade; public APIs are owned by the
; G083 SDK and CLI, while emitted programs call the native runtime probe.
%define G83_FAMILY_KEY 0x5246323034473833
%define G83_MIN_SEED 8301
%define G83_MAX_SEED 999999

section .rodata
%macro G83_NAME 2
g83_n_%1: db %2
g83_n_%1_len equ $-g83_n_%1
%endmacro
G83_NAME root,'TextTooling83'
G83_NAME s01,'regexTypes83'
G83_NAME s02,'regexOps83'
G83_NAME s03,'regexTransform83'
G83_NAME s04,'formatterTree83'
G83_NAME s05,'formatterCli83'
G83_NAME s06,'linter83'
G83_NAME s07,'safeFix83'
G83_NAME s08,'lspParity83'
G83_NAME s09,'invariants83'
G83_NAME s10,'closeout83'
G83_NAME regex,'regex'
G83_NAME regex_options,'regexOptions'
G83_NAME regex_error,'regexError'
G83_NAME regex_match,'regexMatch'
G83_NAME max_regex_steps,'maxRegexSteps'
G83_NAME compile,'compileRegex83'
G83_NAME is_match,'isMatchRegex83'
G83_NAME find,'findRegex83'
G83_NAME find_all,'findAllRegex83'
G83_NAME captures,'capturesRegex83'
G83_NAME replace,'replaceRegex83'
G83_NAME split,'splitRegex83'
G83_NAME extract,'extractRegex83'
G83_NAME escape,'escapeRegex83'
G83_NAME format_tree,'formatTree'
G83_NAME format,'formatTreeApply83'
G83_NAME check,'checkTree83'
G83_NAME diff,'diffTree83'
G83_NAME format_check,'formatCheck'
G83_NAME format_diff,'formatDiff'
G83_NAME format_stdout,'formatStdout'
G83_NAME format_write,'formatWrite'
G83_NAME registry,'registry'
G83_NAME lint_path,'lintPath'
G83_NAME recommended,'recommended'
G83_NAME report_modes,'reportModes'
G83_NAME warnings_as_errors,'warningsAsErrors'
G83_NAME fix_preview,'fixPreview'
G83_NAME fmt_maturity,'fmtMaturity'
G83_NAME lint_maturity,'lintMaturity'
G83_NAME no_tabs,'noTabs'
G83_NAME trailing_whitespace,'trailingWhitespace'
G83_NAME final_newline,'finalNewline'
G83_NAME line_too_long,'lineTooLong'
G83_NAME duplicate_import,'duplicateImport'
G83_NAME unused_import,'unusedImport'
G83_NAME missing_public_docs,'missingPublicDocs'
G83_NAME pipeline_too_long,'pipelineTooLong'
G83_NAME deprecated_api,'deprecatedApi'
G83_NAME privacy_output_leak,'privacyOutputLeak'
G83_NAME secret_output,'secretOutput'
G83_NAME implicit_effects,'implicitEffects'
G83_NAME style_drift,'styleDrift'
G83_NAME lost_comments,'lostComments'
G83_NAME fix_plan,'fixPlan'
G83_NAME preview,'previewFix83'
G83_NAME apply_atomic,'applyAtomic'
G83_NAME safe_class,'safeFixClass'
G83_NAME unsafe_class,'unsafeFixClass'
G83_NAME source_map_parity,'sourceMapParity'
G83_NAME lsp_text_edit,'lspTextEdit'
G83_NAME semantic_token,'semanticTokenInterpolation'
G83_NAME code_action,'codeAction'
G83_NAME formatter_idempotent,'formatterIdempotent'
G83_NAME ast_equivalent,'astEquivalent'
G83_NAME atomic_write,'atomicWrite'
G83_NAME comment_preservation,'commentPreservation'
G83_NAME all_green,'allGreen'
G83_NAME deterministic,'deterministic'
G83_NAME failure_atomic,'failureAtomic'
G83_NAME source_map_ready,'sourceMapReady'
G83_NAME print,'print'
G83_NAME return,'return'
%undef G83_NAME

section .bss align=16
g83_mode: resq 1
g83_seed: resq 1
g83_seed_seen: resq 1

section .text
%macro G83_REQUIRE 2
 lea rsi,[rel g83_n_%1]
 mov edx,g83_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g83_is_program:
 lea rsi,[rel g83_n_root]
 mov edx,g83_n_root_len
 call ls_contains_atom
 ret

g83_known_call:
 push rbx
 mov rbx,rdi
%macro G83_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g83_n_%1]
 mov edx,g83_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G83_KNOWN s01
 G83_KNOWN s02
 G83_KNOWN s03
 G83_KNOWN s04
 G83_KNOWN s05
 G83_KNOWN s06
 G83_KNOWN s07
 G83_KNOWN s08
 G83_KNOWN s09
 G83_KNOWN s10
 G83_KNOWN regex
 G83_KNOWN regex_options
 G83_KNOWN regex_error
 G83_KNOWN regex_match
 G83_KNOWN max_regex_steps
 G83_KNOWN compile
 G83_KNOWN is_match
 G83_KNOWN find
 G83_KNOWN find_all
 G83_KNOWN captures
 G83_KNOWN replace
 G83_KNOWN split
 G83_KNOWN extract
 G83_KNOWN escape
 G83_KNOWN format_tree
 G83_KNOWN format
 G83_KNOWN check
 G83_KNOWN diff
 G83_KNOWN format_check
 G83_KNOWN format_diff
 G83_KNOWN format_stdout
 G83_KNOWN format_write
 G83_KNOWN registry
 G83_KNOWN lint_path
 G83_KNOWN recommended
 G83_KNOWN report_modes
 G83_KNOWN warnings_as_errors
 G83_KNOWN fix_preview
 G83_KNOWN fmt_maturity
 G83_KNOWN lint_maturity
 G83_KNOWN no_tabs
 G83_KNOWN trailing_whitespace
 G83_KNOWN final_newline
 G83_KNOWN line_too_long
 G83_KNOWN duplicate_import
 G83_KNOWN unused_import
 G83_KNOWN missing_public_docs
 G83_KNOWN pipeline_too_long
 G83_KNOWN deprecated_api
 G83_KNOWN privacy_output_leak
 G83_KNOWN secret_output
 G83_KNOWN implicit_effects
 G83_KNOWN style_drift
 G83_KNOWN lost_comments
 G83_KNOWN fix_plan
 G83_KNOWN preview
 G83_KNOWN apply_atomic
 G83_KNOWN safe_class
 G83_KNOWN unsafe_class
 G83_KNOWN source_map_parity
 G83_KNOWN lsp_text_edit
 G83_KNOWN semantic_token
 G83_KNOWN code_action
 G83_KNOWN formatter_idempotent
 G83_KNOWN ast_equivalent
 G83_KNOWN atomic_write
 G83_KNOWN comment_preservation
 G83_KNOWN all_green
 G83_KNOWN deterministic
 G83_KNOWN failure_atomic
 G83_KNOWN source_map_ready
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret
%undef G83_KNOWN

; Every evidence-facade method is nullary. Typed arguments are exercised by
; the independent SDK/CLI and native-runtime oracles.
g83_validate_call:
 lea rdi,[rdi+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 ret

g83_select_mode:
 G83_REQUIRE s10,.not_s10
 G83_REQUIRE all_green,.not_s10
 G83_REQUIRE deterministic,.not_s10
 G83_REQUIRE failure_atomic,.not_s10
 G83_REQUIRE source_map_ready,.not_s10
 mov eax,10
 ret
.not_s10:
 G83_REQUIRE s09,.not_s09
 G83_REQUIRE formatter_idempotent,.not_s09
 G83_REQUIRE ast_equivalent,.not_s09
 G83_REQUIRE atomic_write,.not_s09
 G83_REQUIRE comment_preservation,.not_s09
 mov eax,9
 ret
.not_s09:
 G83_REQUIRE s08,.not_s08
 G83_REQUIRE source_map_parity,.not_s08
 G83_REQUIRE lsp_text_edit,.not_s08
 G83_REQUIRE semantic_token,.not_s08
 G83_REQUIRE code_action,.not_s08
 mov eax,8
 ret
.not_s08:
 G83_REQUIRE s07,.not_s07
 G83_REQUIRE fix_plan,.not_s07
 G83_REQUIRE preview,.not_s07
 G83_REQUIRE apply_atomic,.not_s07
 G83_REQUIRE safe_class,.not_s07
 G83_REQUIRE unsafe_class,.not_s07
 mov eax,7
 ret
.not_s07:
 G83_REQUIRE s06,.not_s06
 G83_REQUIRE registry,.not_s06
 G83_REQUIRE lint_path,.not_s06
 G83_REQUIRE recommended,.not_s06
 G83_REQUIRE report_modes,.not_s06
 G83_REQUIRE warnings_as_errors,.not_s06
 G83_REQUIRE fix_preview,.not_s06
 G83_REQUIRE fmt_maturity,.not_s06
 G83_REQUIRE lint_maturity,.not_s06
 G83_REQUIRE no_tabs,.not_s06
 G83_REQUIRE trailing_whitespace,.not_s06
 G83_REQUIRE final_newline,.not_s06
 G83_REQUIRE line_too_long,.not_s06
 G83_REQUIRE duplicate_import,.not_s06
 G83_REQUIRE unused_import,.not_s06
 G83_REQUIRE missing_public_docs,.not_s06
 G83_REQUIRE pipeline_too_long,.not_s06
 G83_REQUIRE deprecated_api,.not_s06
 G83_REQUIRE privacy_output_leak,.not_s06
 G83_REQUIRE secret_output,.not_s06
 G83_REQUIRE implicit_effects,.not_s06
 G83_REQUIRE style_drift,.not_s06
 G83_REQUIRE lost_comments,.not_s06
 mov eax,6
 ret
.not_s06:
 G83_REQUIRE s05,.not_s05
 G83_REQUIRE format_check,.not_s05
 G83_REQUIRE format_diff,.not_s05
 G83_REQUIRE format_stdout,.not_s05
 G83_REQUIRE format_write,.not_s05
 mov eax,5
 ret
.not_s05:
 G83_REQUIRE s04,.not_s04
 G83_REQUIRE format_tree,.not_s04
 G83_REQUIRE format,.not_s04
 G83_REQUIRE check,.not_s04
 G83_REQUIRE diff,.not_s04
 mov eax,4
 ret
.not_s04:
 G83_REQUIRE s03,.not_s03
 G83_REQUIRE replace,.not_s03
 G83_REQUIRE split,.not_s03
 G83_REQUIRE extract,.not_s03
 G83_REQUIRE escape,.not_s03
 mov eax,3
 ret
.not_s03:
 G83_REQUIRE s02,.not_s02
 G83_REQUIRE compile,.not_s02
 G83_REQUIRE is_match,.not_s02
 G83_REQUIRE find,.not_s02
 G83_REQUIRE find_all,.not_s02
 G83_REQUIRE captures,.not_s02
 mov eax,2
 ret
.not_s02:
 G83_REQUIRE s01,.not_s01
 G83_REQUIRE regex,.not_s01
 G83_REQUIRE regex_options,.not_s01
 G83_REQUIRE regex_error,.not_s01
 G83_REQUIRE regex_match,.not_s01
 G83_REQUIRE max_regex_steps,.not_s01
 mov eax,1
 ret
.not_s01: xor eax,eax
 ret

g83_scan_program:
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
 cmp rdx,G83_MIN_SEED
 jb .next
 cmp rdx,G83_MAX_SEED
 ja .unsupported
 cmp qword [rel g83_seed_seen],0
 jne .unsupported
 mov qword [rel g83_seed_seen],1
 mov [rel g83_seed],rdx
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .next
 lea rdi,[rbx+1]
 call g83_known_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g83_validate_call
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
 cmp qword [rel g83_seed_seen],1
 jne .unsupported
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return: pop rbx
 ret

neboc_g083_source_parse:
 mov qword [rel g83_mode],0
 mov qword [rel g83_seed],0
 mov qword [rel g83_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g83_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g83_mode],rax
 lea rsi,[rel g83_n_print]
 mov edx,g83_n_print_len
 call ls_contains_atom
 test eax,eax
 jnz .unsupported
 lea rsi,[rel g83_n_return]
 mov edx,g83_n_return_len
 call ls_contains_atom
 test eax,eax
 jnz .unsupported
 call g83_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g83_mode]
 shl rax,32
 mov edi,dword [rel g83_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G83_FAMILY_KEY
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

%undef G83_REQUIRE
