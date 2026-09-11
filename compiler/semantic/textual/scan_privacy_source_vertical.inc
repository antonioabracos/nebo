; G077 token-owned ScanPlan privacy, cancellation/EOF, and safe formatted
; parsing vertical.  It admits only finite source shapes and never promotes
; the historical noEcho alias or unrestricted format/shell grammars.
%define G77_FAMILY_KEY 0x5246323034473737
%define G77_MIN_SEED 1700
%define G77_MAX_SEED 0xffffffff
%define G77_MAX_TIMEOUT_S 3600
%define G77_MAX_TIMEOUT_MS 3600000
%define G77_MAX_CANCEL_KEYS 16

section .rodata
%macro G77_NAME 2
g77_n_%1: db %2
g77_n_%1_len equ $-g77_n_%1
%endmacro
G77_NAME root,'ScanPlan'
G77_NAME privacy,'privacy'
G77_NAME events,'events'
G77_NAME formatted,'formatted'
G77_NAME secret_life,'secretLife'
G77_NAME outcome,'outcome'
G77_NAME closeout,'closeout77'
G77_NAME secret,'secret'
G77_NAME mask,'mask'
G77_NAME redact,'redact'
G77_NAME no_history,'noHistory'
G77_NAME confirm_secret,'confirmSecret'
G77_NAME min_strength,'minStrength'
G77_NAME sensitive,'sensitive'
G77_NAME forget,'forgetAfterUse'
G77_NAME untrusted,'untrusted'
G77_NAME timeout,'timeout'
G77_NAME timeout_ms,'timeoutMs'
G77_NAME cancel_on,'cancelOn'
G77_NAME cancel_keys,'cancelKeys'
G77_NAME eof_none,'eofAsNone'
G77_NAME eof_as,'eofAs'
G77_NAME on_cancel,'onCancel'
G77_NAME interruptible,'interruptible'
G77_NAME result,'result'
G77_NAME pattern,'pattern'
G77_NAME into,'into'
G77_NAME tuple,'tuple'
G77_NAME split,'split'
G77_NAME sep,'sep'
G77_NAME csv,'csv'
G77_NAME tsv,'tsv'
G77_NAME kv,'kv'
G77_NAME command,'command'
G77_NAME shell_words,'shellWords'
G77_NAME safe_pattern,'safePattern'
G77_NAME type_int,'Int'
G77_NAME fmt_space,'"%d %d"'
G77_NAME fmt_colon,'"%d:%d"'
G77_NAME print,'print'
%undef G77_NAME

section .bss align=16
g77_mode: resq 1
g77_seed: resq 1
g77_seed_seen: resq 1

section .text
%macro G77_REQUIRE 2
 lea rsi,[rel g77_n_%1]
 mov edx,g77_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g77_is_program:
 lea rsi,[rel g77_n_root]
 mov edx,g77_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
%macro G77_MARKER 1
 lea rsi,[rel g77_n_%1]
 mov edx,g77_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G77_MARKER privacy
 G77_MARKER events
 G77_MARKER formatted
 G77_MARKER secret_life
 G77_MARKER outcome
 G77_MARKER closeout
.no: xor eax,eax
 ret
.yes: mov eax,1
 ret
%undef G77_MARKER

; RDI token index -> EAX whether it names a callable admitted by G077.
g77_known_call:
 push rbx
 mov rbx,rdi
%macro G77_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g77_n_%1]
 mov edx,g77_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G77_KNOWN secret
 G77_KNOWN mask
 G77_KNOWN redact
 G77_KNOWN no_history
 G77_KNOWN confirm_secret
 G77_KNOWN min_strength
 G77_KNOWN sensitive
 G77_KNOWN forget
 G77_KNOWN untrusted
 G77_KNOWN timeout
 G77_KNOWN timeout_ms
 G77_KNOWN cancel_on
 G77_KNOWN cancel_keys
 G77_KNOWN eof_none
 G77_KNOWN eof_as
 G77_KNOWN on_cancel
 G77_KNOWN interruptible
 G77_KNOWN result
 G77_KNOWN pattern
 G77_KNOWN into
 G77_KNOWN tuple
 G77_KNOWN split
 G77_KNOWN sep
 G77_KNOWN csv
 G77_KNOWN tsv
 G77_KNOWN kv
 G77_KNOWN command
 G77_KNOWN shell_words
 G77_KNOWN safe_pattern
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret
%undef G77_KNOWN

; RDI first array token -> EAX for a nonempty literal array capped at 16.
g77_validate_cancel_array:
 push rbx
 push r12
 mov rbx,rdi
 xor r12d,r12d
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RESERVED_LBRACKET
 jne .bad
 inc rbx
.item:
 mov rdi,rbx
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,2                    ; reject an empty quoted cancellation key
 jbe .bad
 inc r12d
 cmp r12d,G77_MAX_CANCEL_KEYS
 ja .bad
 inc rbx
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RESERVED_RBRACKET
 je .close
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 inc rbx
 jmp .item
.close:
 inc rbx
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.bad: xor eax,eax
.done: pop r12
 pop rbx
 ret

; RDI dot token -> exact arity and bounded literal shape.
g77_validate_call:
 push rbx
 push r12
 mov rbx,rdi
 lea r12,[rbx+1]
%macro G77_ROUTE 2
 mov rdi,r12
 lea rsi,[rel g77_n_%1]
 mov edx,g77_n_%1_len
 call ls_token_match
 test eax,eax
 jnz %2
%endmacro
 G77_ROUTE mask,.mask
 G77_ROUTE min_strength,.strength
 G77_ROUTE timeout,.timeout_s
 G77_ROUTE timeout_ms,.timeout_ms
 G77_ROUTE cancel_on,.one_byte_text
 G77_ROUTE eof_as,.one_text
 G77_ROUTE on_cancel,.one_text
 G77_ROUTE split,.one_byte_text
 G77_ROUTE sep,.one_byte_text
 G77_ROUTE kv,.one_byte_text
 G77_ROUTE cancel_keys,.array
 G77_ROUTE pattern,.format_space
 G77_ROUTE safe_pattern,.format_colon
 G77_ROUTE into,.into
 G77_ROUTE tuple,.tuple
 ; Remaining admitted selectors are nullary.
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.one_text:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_TEXT
 jne .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.one_byte_text:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,3                    ; exactly one source byte plus two quotes
 jne .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.mask:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,3                    ; one byte plus two quotes
 jne .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.strength:
 mov ecx,4
 jmp .bounded_int
.timeout_s:
 mov ecx,G77_MAX_TIMEOUT_S
 jmp .bounded_int
.timeout_ms:
 mov ecx,G77_MAX_TIMEOUT_MS
.bounded_int:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test rdx,rdx
 jz .bad
 cmp rdx,rcx
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.array:
 lea rdi,[rbx+3]
 call g77_validate_cancel_array
 jmp .done
.format_space:
 lea rdi,[rbx+3]
 lea rsi,[rel g77_n_fmt_space]
 mov edx,g77_n_fmt_space_len
 call ls_token_match
 test eax,eax
 jz .bad
 jmp .format_tail
.format_colon:
 lea rdi,[rbx+3]
 lea rsi,[rel g77_n_fmt_colon]
 mov edx,g77_n_fmt_colon_len
 call ls_token_match
 test eax,eax
 jz .bad
.format_tail:
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.tuple:
 lea rdi,[rbx+3]
 lea rsi,[rel g77_n_type_int]
 mov edx,g77_n_type_int_len
 call ls_token_match
 test eax,eax
 jz .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+5]
 lea rsi,[rel g77_n_type_int]
 mov edx,g77_n_type_int_len
 call ls_token_match
 test eax,eax
 jz .bad
 lea rdi,[rbx+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.into:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_DOT
 jne .bad
 lea rdi,[rbx+4]
 lea rsi,[rel g77_n_tuple]
 mov edx,g77_n_tuple_len
 call ls_token_match
 test eax,eax
 jz .bad
 lea rdi,[rbx+5]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .bad
 lea rdi,[rbx+6]
 lea rsi,[rel g77_n_type_int]
 mov edx,g77_n_type_int_len
 call ls_token_match
 test eax,eax
 jz .bad
 lea rdi,[rbx+7]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+8]
 lea rsi,[rel g77_n_type_int]
 mov edx,g77_n_type_int_len
 call ls_token_match
 test eax,eax
 jz .bad
 lea rdi,[rbx+9]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .bad
 lea rdi,[rbx+10]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.bad: xor eax,eax
.done:
 pop r12
 pop rbx
 ret
%undef G77_ROUTE

g77_select_mode:
 G77_REQUIRE privacy,.not_s01
 G77_REQUIRE secret,.not_s01
 G77_REQUIRE mask,.not_s01
 G77_REQUIRE redact,.not_s01
 G77_REQUIRE no_history,.not_s01
 G77_REQUIRE confirm_secret,.not_s01
 G77_REQUIRE min_strength,.not_s01
 G77_REQUIRE sensitive,.not_s01
 G77_REQUIRE forget,.not_s01
 G77_REQUIRE untrusted,.not_s01
 mov eax,1
 ret
.not_s01:
 G77_REQUIRE events,.not_s02
 G77_REQUIRE timeout,.not_s02
 G77_REQUIRE timeout_ms,.not_s02
 G77_REQUIRE cancel_on,.not_s02
 G77_REQUIRE cancel_keys,.not_s02
 G77_REQUIRE eof_none,.not_s02
 G77_REQUIRE eof_as,.not_s02
 G77_REQUIRE on_cancel,.not_s02
 G77_REQUIRE interruptible,.not_s02
 G77_REQUIRE result,.not_s02
 mov eax,2
 ret
.not_s02:
 G77_REQUIRE formatted,.not_s03
 G77_REQUIRE pattern,.not_s03
 G77_REQUIRE into,.not_s03
 G77_REQUIRE tuple,.not_s03
 G77_REQUIRE split,.not_s03
 G77_REQUIRE sep,.not_s03
 G77_REQUIRE csv,.not_s03
 G77_REQUIRE tsv,.not_s03
 G77_REQUIRE kv,.not_s03
 G77_REQUIRE command,.not_s03
 G77_REQUIRE shell_words,.not_s03
 G77_REQUIRE safe_pattern,.not_s03
 mov eax,3
 ret
.not_s03:
 G77_REQUIRE secret_life,.not_s04
 G77_REQUIRE secret,.not_s04
 G77_REQUIRE confirm_secret,.not_s04
 G77_REQUIRE min_strength,.not_s04
 G77_REQUIRE sensitive,.not_s04
 G77_REQUIRE forget,.not_s04
 mov eax,4
 ret
.not_s04:
 G77_REQUIRE outcome,.not_s05
 G77_REQUIRE eof_none,.not_s05
 G77_REQUIRE on_cancel,.not_s05
 G77_REQUIRE interruptible,.not_s05
 G77_REQUIRE result,.not_s05
 mov eax,5
 ret
.not_s05:
 G77_REQUIRE closeout,.not_s06
 G77_REQUIRE secret,.not_s06
 G77_REQUIRE timeout_ms,.not_s06
 G77_REQUIRE cancel_on,.not_s06
 G77_REQUIRE eof_none,.not_s06
 G77_REQUIRE safe_pattern,.not_s06
 G77_REQUIRE into,.not_s06
 G77_REQUIRE result,.not_s06
 mov eax,6
 ret
.not_s06: xor eax,eax
 ret

g77_scan_program:
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
 cmp rdx,G77_MIN_SEED
 jb .next
 mov rax,G77_MAX_SEED
 cmp rdx,rax
 ja .unsupported
 cmp qword [rel g77_seed_seen],0
 jne .unsupported
 mov qword [rel g77_seed_seen],1
 mov [rel g77_seed],rdx
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_RESERVED_LBRACKET
 je .next
 cmp eax,NEBOC_TOKEN_RESERVED_RBRACKET
 je .next
 cmp eax,NEBOC_TOKEN_PLUS
 jb .dot_test
 cmp eax,NEBOC_TOKEN_LATERAL_FLOW
 jbe .unsupported
.dot_test:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .unsupported
 lea rdi,[rbx+1]
 call g77_known_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g77_validate_call
 test eax,eax
 jz .unsupported
.next: inc rbx
 jmp .scan
.done:
 test rbx,rbx
 jz .syntax
 lea rdi,[rbx-1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RBRACE
 jne .syntax
 cmp qword [rel g77_seed_seen],1
 jne .unsupported
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return: pop rbx
 ret

neboc_g077_source_parse:
 mov qword [rel g77_mode],0
 mov qword [rel g77_seed],0
 mov qword [rel g77_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g77_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g77_mode],rax
 lea rsi,[rel g77_n_print]
 mov edx,g77_n_print_len
 call ls_contains_atom
 test eax,eax
 jnz .unsupported
 call g77_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g77_mode]
 shl rax,32
 mov edi,dword [rel g77_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G77_FAMILY_KEY
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

%undef G77_REQUIRE
