; G071 token-owned source vertical for bounded render security policies.
%define G71_FAMILY_KEY 0x5246323034473731
%define G71_MAX_PAYLOAD 4096
%define G71_MIN_SEED 900
%define G71_MAX_SEED 0xffffffff

section .rodata
%macro G71_NAME 2
g71_n_%1: db %2
g71_n_%1_len equ $-g71_n_%1
%endmacro
G71_NAME root,'RenderPlan'
G71_NAME redact,'redact'
G71_NAME mask,'mask'
G71_NAME secret,'secret'
G71_NAME hash,'hash'
G71_NAME truncate,'truncate'
G71_NAME safe,'safe'
G71_NAME escape,'escape'
G71_NAME sanitize,'sanitize'
G71_NAME no_log,'noLog'
G71_NAME sensitive,'sensitive'
G71_NAME raw,'raw'
G71_NAME safe_html,'safeHtml'
G71_NAME quote,'quote'
G71_NAME literal,'literal'
G71_NAME no_ansi,'noAnsi'
G71_NAME locale,'locale'
G71_NAME currency,'currency'
G71_NAME date,'date'
G71_NAME time,'time'
G71_NAME datetime,'datetime'
G71_NAME number_format,'numberFormat'
G71_NAME decimal_separator,'decimalSeparator'
G71_NAME thousands_separator,'thousandsSeparator'
G71_NAME plural,'plural'
G71_NAME gender,'gender'
G71_NAME translate,'translate'
G71_NAME timezone,'timezone'
G71_NAME screen_reader,'screenReader'
G71_NAME no_color,'noColor'
G71_NAME high_contrast,'highContrast'
G71_NAME symbols,'symbols'
G71_NAME text_only,'textOnly'
G71_NAME alt,'alt'
G71_NAME aria,'aria'
G71_NAME no_emoji,'noEmoji'
G71_NAME ascii_only,'asciiOnly'
G71_NAME fallback,'fallback'
G71_NAME if_ansi,'ifAnsi'
G71_NAME if_markdown,'ifMarkdown'
G71_NAME if_console,'ifConsole'
G71_NAME if_file,'ifFile'
G71_NAME no_color_unsupported,'noColorIfUnsupported'
G71_NAME detect_target,'detectTarget'
G71_NAME auto,'auto'
G71_NAME strict_target,'strictTarget'
G71_NAME detect_terminal,'detectTerminal'
G71_NAME force_color,'forceColor'
G71_NAME width_auto,'widthAuto'
G71_NAME terminal_width,'terminalWidth'
G71_NAME unicode,'unicode'
G71_NAME ascii_fallback,'asciiFallback'
G71_NAME privacy_class,'privacyClass'
G71_NAME sink,'sink'
G71_NAME propagate_privacy,'propagatePrivacy'
G71_NAME require_redaction,'requireRedaction'
G71_NAME privacy_audit,'privacyAudit'
G71_NAME security_conformance,'securityConformance'
G71_NAME validate,'validate'
G71_NAME deterministic,'deterministic'
G71_NAME failure_atomic,'failureAtomic'
G71_NAME bounded,'bounded'
%undef G71_NAME

section .bss align=16
g71_mode: resq 1
g71_seed: resq 1
g71_seed_seen: resq 1

section .text
%macro G71_REQUIRE 2
 lea rsi,[rel g71_n_%1]
 mov edx,g71_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g71_is_program:
 lea rsi,[rel g71_n_root]
 mov edx,g71_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
%macro G71_MARKER 1
 lea rsi,[rel g71_n_%1]
 mov edx,g71_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G71_MARKER secret
 G71_MARKER safe_html
 G71_MARKER locale
 G71_MARKER screen_reader
 G71_MARKER fallback
 G71_MARKER detect_terminal
 G71_MARKER privacy_class
 G71_MARKER security_conformance
.no: xor eax,eax
 ret
.yes: mov eax,1
 ret
%undef G71_MARKER

g71_known_call:
 push rbx
 mov rbx,rdi
%macro G71_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g71_n_%1]
 mov edx,g71_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G71_KNOWN redact
 G71_KNOWN mask
 G71_KNOWN secret
 G71_KNOWN hash
 G71_KNOWN truncate
 G71_KNOWN safe
 G71_KNOWN escape
 G71_KNOWN sanitize
 G71_KNOWN no_log
 G71_KNOWN sensitive
 G71_KNOWN raw
 G71_KNOWN safe_html
 G71_KNOWN quote
 G71_KNOWN literal
 G71_KNOWN no_ansi
 G71_KNOWN locale
 G71_KNOWN currency
 G71_KNOWN date
 G71_KNOWN time
 G71_KNOWN datetime
 G71_KNOWN number_format
 G71_KNOWN decimal_separator
 G71_KNOWN thousands_separator
 G71_KNOWN plural
 G71_KNOWN timezone
 G71_KNOWN screen_reader
 G71_KNOWN no_color
 G71_KNOWN high_contrast
 G71_KNOWN symbols
 G71_KNOWN text_only
 G71_KNOWN alt
 G71_KNOWN no_emoji
 G71_KNOWN ascii_only
 G71_KNOWN fallback
 G71_KNOWN if_ansi
 G71_KNOWN if_markdown
 G71_KNOWN if_console
 G71_KNOWN if_file
 G71_KNOWN no_color_unsupported
 G71_KNOWN detect_target
 G71_KNOWN auto
 G71_KNOWN strict_target
 G71_KNOWN detect_terminal
 G71_KNOWN force_color
 G71_KNOWN width_auto
 G71_KNOWN terminal_width
 G71_KNOWN unicode
 G71_KNOWN ascii_fallback
 G71_KNOWN privacy_class
 G71_KNOWN sink
 G71_KNOWN propagate_privacy
 G71_KNOWN require_redaction
 G71_KNOWN privacy_audit
 G71_KNOWN security_conformance
 G71_KNOWN validate
 G71_KNOWN deterministic
 G71_KNOWN failure_atomic
 G71_KNOWN bounded
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret
%undef G71_KNOWN

; RDI dot-token index -> EAX boolean for bounded arity and argument kinds.
g71_validate_call:
 push rbx
 push r12
 mov rbx,rdi
 lea r12,[rbx+1]
%macro G71_ARG_MATCH 2
 mov rdi,r12
 lea rsi,[rel g71_n_%1]
 mov edx,g71_n_%1_len
 call ls_token_match
 test eax,eax
 jnz %2
%endmacro
 G71_ARG_MATCH redact,.optional_text
 G71_ARG_MATCH mask,.optional_text
 G71_ARG_MATCH escape,.optional_text
 G71_ARG_MATCH truncate,.integer
 G71_ARG_MATCH symbols,.integer
 G71_ARG_MATCH unicode,.integer
 G71_ARG_MATCH plural,.plural
 G71_ARG_MATCH locale,.text
 G71_ARG_MATCH currency,.text
 G71_ARG_MATCH date,.text
 G71_ARG_MATCH time,.text
 G71_ARG_MATCH datetime,.text
 G71_ARG_MATCH number_format,.text
 G71_ARG_MATCH decimal_separator,.text
 G71_ARG_MATCH thousands_separator,.text
 G71_ARG_MATCH gender,.text
 G71_ARG_MATCH translate,.text
 G71_ARG_MATCH timezone,.text
 G71_ARG_MATCH screen_reader,.text
 G71_ARG_MATCH alt,.text
 G71_ARG_MATCH aria,.text
 G71_ARG_MATCH fallback,.text
 G71_ARG_MATCH if_ansi,.text
 G71_ARG_MATCH if_markdown,.text
 G71_ARG_MATCH if_console,.text
 G71_ARG_MATCH if_file,.text
 G71_ARG_MATCH privacy_class,.text
 G71_ARG_MATCH sink,.text
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
 mov rdi,r12
 lea rsi,[rel g71_n_escape]
 mov edx,g71_n_escape_len
 call ls_token_match
 test eax,eax
 jz .bounded_text
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,7
 jne .bounded_text
 mov r9,[rel ls_source]
 add r9,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp byte [r9],'"'
 jne .bounded_text
 cmp byte [r9+1],'s'
 jne .bounded_text
 cmp byte [r9+2],'h'
 jne .bounded_text
 cmp byte [r9+3],'e'
 jne .bounded_text
 cmp byte [r9+4],'l'
 jne .bounded_text
 cmp byte [r9+5],'l'
 jne .bounded_text
 cmp byte [r9+6],'"'
 je .bad
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
 cmp rdx,G71_MAX_PAYLOAD+2
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .good
 jmp .bad
.integer:
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
 cmp rdx,4096
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .good
 jmp .bad
.plural:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+5]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_TEXT
 jne .bad
 lea rdi,[rbx+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+7]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_TEXT
 jne .bad
 lea rdi,[rbx+8]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .bad
.good: mov eax,1
 jmp .done
.bad: xor eax,eax
.done:
 pop r12
 pop rbx
 ret
%undef G71_ARG_MATCH

g71_select_mode:
 G71_REQUIRE security_conformance,.not_s08
 G71_REQUIRE validate,.not_s08
 G71_REQUIRE deterministic,.not_s08
 G71_REQUIRE failure_atomic,.not_s08
 G71_REQUIRE bounded,.not_s08
 mov eax,8
 ret
.not_s08:
 G71_REQUIRE privacy_class,.not_s07
 G71_REQUIRE sink,.not_s07
 G71_REQUIRE propagate_privacy,.not_s07
 G71_REQUIRE require_redaction,.not_s07
 G71_REQUIRE privacy_audit,.not_s07
 mov eax,7
 ret
.not_s07:
 G71_REQUIRE detect_terminal,.not_s06
 G71_REQUIRE terminal_width,.not_s06
 G71_REQUIRE ascii_fallback,.not_s06
 mov eax,6
 ret
.not_s06:
 G71_REQUIRE fallback,.not_s05
 G71_REQUIRE detect_target,.not_s05
 G71_REQUIRE strict_target,.not_s05
 mov eax,5
 ret
.not_s05:
 G71_REQUIRE screen_reader,.not_s04
 G71_REQUIRE high_contrast,.not_s04
 G71_REQUIRE text_only,.not_s04
 mov eax,4
 ret
.not_s04:
 G71_REQUIRE locale,.not_s03
 G71_REQUIRE currency,.not_s03
 G71_REQUIRE plural,.not_s03
 G71_REQUIRE timezone,.not_s03
 mov eax,3
 ret
.not_s03:
 G71_REQUIRE safe_html,.not_s02
 G71_REQUIRE quote,.not_s02
 G71_REQUIRE no_ansi,.not_s02
 mov eax,2
 ret
.not_s02:
 G71_REQUIRE secret,.not_s01
 G71_REQUIRE truncate,.not_s01
 G71_REQUIRE sanitize,.not_s01
 G71_REQUIRE no_log,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g71_scan_program:
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
.seed_candidate:
 mov rdi,rbx
 call ls_token_ptr
 test rax,rax
 jz .syntax
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rdx,G71_MIN_SEED
 jb .next
 mov rax,G71_MAX_SEED
 cmp rdx,rax
 ja .unsupported
 cmp qword [rel g71_seed_seen],0
 jne .unsupported
 mov qword [rel g71_seed_seen],1
 mov [rel g71_seed],rdx
 jmp .next
.text:
 cmp eax,NEBOC_TOKEN_TEXT
 jne .dot
 mov rdi,rbx
 call ls_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,G71_MAX_PAYLOAD+2
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
 call g71_known_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g71_validate_call
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
 cmp qword [rel g71_seed_seen],1
 jne .unsupported
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return: pop rbx
 ret

neboc_g071_source_parse:
 mov qword [rel g71_mode],0
 mov qword [rel g71_seed],0
 mov qword [rel g71_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g71_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g71_mode],rax
 call g71_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g71_mode]
 shl rax,32
 mov edi,dword [rel g71_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G71_FAMILY_KEY
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

%undef G71_REQUIRE
