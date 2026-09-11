; G076 token-owned ScanPlan validation vertical. General regex and enum
; reflection are intentionally not admitted; all public choices and retries
; are finite and statically shaped.
%define G76_FAMILY_KEY 0x5246323034473736
%define G76_MIN_SEED 1500
%define G76_MAX_SEED 0xffffffff
%define G76_MAX_INPUT 4096
%define G76_MAX_ATTEMPTS 8

section .rodata
%macro G76_NAME 2
g76_n_%1: db %2
g76_n_%1_len equ $-g76_n_%1
%endmacro
G76_NAME root,'ScanPlan'
G76_NAME textual,'textRules'
G76_NAME numeric,'numeric'
G76_NAME choices,'choices'
G76_NAME retry_ux,'retryUx'
G76_NAME composition,'composition'
G76_NAME closeout,'closeout76'
G76_NAME min_len,'minLen'
G76_NAME max_len,'maxLen'
G76_NAME len,'len'
G76_NAME contains,'contains'
G76_NAME starts_with,'startsWith'
G76_NAME ends_with,'endsWith'
G76_NAME alnum,'alnum'
G76_NAME letters,'letters'
G76_NAME digits,'digits'
G76_NAME no_control,'noControlChars'
G76_NAME safe_text,'safeText'
G76_NAME num_min,'min'
G76_NAME num_max,'max'
G76_NAME range,'range'
G76_NAME positive,'positive'
G76_NAME non_negative,'nonNegative'
G76_NAME even,'even'
G76_NAME odd,'odd'
G76_NAME multiple_of,'multipleOf'
G76_NAME precision,'precision'
G76_NAME locale,'locale'
G76_NAME locale_pt,'"pt-PT"'
G76_NAME locale_c,'"C"'
G76_NAME choice,'choice'
G76_NAME yes_no,'yesNo'
G76_NAME confirm,'confirm'
G76_NAME menu,'menu'
G76_NAME select,'select'
G76_NAME multi_select,'multiSelect'
G76_NAME index_choice,'indexChoice'
G76_NAME autocomplete,'autocomplete'
G76_NAME retry,'retry'
G76_NAME max_attempts,'maxAttempts'
G76_NAME on_fail,'onFail'
G76_NAME error,'error'
G76_NAME hint,'hint'
G76_NAME example,'example'
G76_NAME explain,'explain'
G76_NAME diagnostic,'diagnostic'
G76_NAME teach,'teach'
G76_NAME print,'print'
%undef G76_NAME

section .bss align=16
g76_mode: resq 1
g76_seed: resq 1
g76_seed_seen: resq 1

section .text
%macro G76_REQUIRE 2
 lea rsi,[rel g76_n_%1]
 mov edx,g76_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g76_is_program:
 lea rsi,[rel g76_n_root]
 mov edx,g76_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
%macro G76_MARKER 1
 lea rsi,[rel g76_n_%1]
 mov edx,g76_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G76_MARKER textual
 G76_MARKER numeric
 G76_MARKER choices
 G76_MARKER retry_ux
 G76_MARKER composition
 G76_MARKER closeout
.no: xor eax,eax
 ret
.yes: mov eax,1
 ret
%undef G76_MARKER

g76_known_call:
 push rbx
 mov rbx,rdi
%macro G76_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g76_n_%1]
 mov edx,g76_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G76_KNOWN min_len
 G76_KNOWN max_len
 G76_KNOWN len
 G76_KNOWN contains
 G76_KNOWN starts_with
 G76_KNOWN ends_with
 G76_KNOWN alnum
 G76_KNOWN letters
 G76_KNOWN digits
 G76_KNOWN no_control
 G76_KNOWN safe_text
 G76_KNOWN num_min
 G76_KNOWN num_max
 G76_KNOWN range
 G76_KNOWN positive
 G76_KNOWN non_negative
 G76_KNOWN even
 G76_KNOWN odd
 G76_KNOWN multiple_of
 G76_KNOWN precision
 G76_KNOWN locale
 G76_KNOWN choice
 G76_KNOWN yes_no
 G76_KNOWN confirm
 G76_KNOWN menu
 G76_KNOWN select
 G76_KNOWN multi_select
 G76_KNOWN index_choice
 G76_KNOWN autocomplete
 G76_KNOWN retry
 G76_KNOWN max_attempts
 G76_KNOWN on_fail
 G76_KNOWN error
 G76_KNOWN hint
 G76_KNOWN example
 G76_KNOWN explain
 G76_KNOWN diagnostic
 G76_KNOWN teach
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret
%undef G76_KNOWN

; RDI first array token -> EAX whether ["...", ...] closes the call exactly.
g76_validate_text_array:
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
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_TEXT
 jne .bad
 inc r12d
 cmp r12d,32
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
 jne .bad
 mov eax,1
 jmp .done
.bad: xor eax,eax
.done: pop r12
 pop rbx
 ret

g76_validate_call:
 push rbx
 push r12
 mov rbx,rdi
 lea r12,[rbx+1]
%macro G76_ROUTE 2
 mov rdi,r12
 lea rsi,[rel g76_n_%1]
 mov edx,g76_n_%1_len
 call ls_token_match
 test eax,eax
 jnz %2
%endmacro
 G76_ROUTE min_len,.input_bound
 G76_ROUTE max_len,.input_bound
 G76_ROUTE num_min,.one_int
 G76_ROUTE num_max,.one_int
 G76_ROUTE multiple_of,.multiple
 G76_ROUTE precision,.precision
 G76_ROUTE max_attempts,.attempts
 G76_ROUTE on_fail,.one_int
 G76_ROUTE len,.two_len
 G76_ROUTE range,.two_int
 G76_ROUTE contains,.one_text
 G76_ROUTE starts_with,.one_text
 G76_ROUTE ends_with,.one_text
 G76_ROUTE locale,.locale
 G76_ROUTE error,.one_text
 G76_ROUTE hint,.one_text
 G76_ROUTE example,.one_text
 G76_ROUTE teach,.one_text
 G76_ROUTE choice,.array
 G76_ROUTE menu,.array
 G76_ROUTE select,.array
 G76_ROUTE multi_select,.array
 G76_ROUTE index_choice,.array
 G76_ROUTE autocomplete,.array
 G76_ROUTE retry,.retry
 ; Remaining admitted selectors are nullary.
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.one_int:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bad
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],0x7fffffff
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.input_bound:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test rdx,rdx
 jz .bad
 cmp rdx,G76_MAX_INPUT
 ja .bad
 jmp .one_int_tail
.multiple:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test rdx,rdx
 jz .bad
 cmp rdx,0x7fffffff
 ja .bad
 jmp .one_int_tail
.precision:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .bad
 cmp qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],9
 ja .bad
 jmp .one_int_tail
.attempts:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test rdx,rdx
 jz .bad
 cmp rdx,G76_MAX_ATTEMPTS
 ja .bad
.one_int_tail:
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.two_len:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 lea rdi,[rbx+5]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],G76_MAX_INPUT
 ja .bad
 cmp rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 ja .bad
 jmp .two_int
.two_int:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bad
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rdx,0x7fffffff
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+5]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bad
 lea rdi,[rbx+5]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],0x7fffffff
 ja .bad
 cmp rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 ja .bad
 lea rdi,[rbx+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.locale:
 lea rdi,[rbx+3]
 lea rsi,[rel g76_n_locale_pt]
 mov edx,g76_n_locale_pt_len
 call ls_token_match
 test eax,eax
 jnz .locale_tail
 lea rdi,[rbx+3]
 lea rsi,[rel g76_n_locale_c]
 mov edx,g76_n_locale_c_len
 call ls_token_match
 test eax,eax
 jz .bad
.locale_tail:
 lea rdi,[rbx+4]
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
.array:
 lea rdi,[rbx+3]
 call g76_validate_text_array
 jmp .done
.retry:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .good
 cmp eax,NEBOC_TOKEN_TEXT
 jne .bad
 lea rdi,[rbx+4]
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
%undef G76_ROUTE

g76_select_mode:
 G76_REQUIRE textual,.not_s01
 G76_REQUIRE min_len,.not_s01
 G76_REQUIRE max_len,.not_s01
 G76_REQUIRE len,.not_s01
 G76_REQUIRE contains,.not_s01
 G76_REQUIRE starts_with,.not_s01
 G76_REQUIRE ends_with,.not_s01
 G76_REQUIRE alnum,.not_s01
 G76_REQUIRE letters,.not_s01
 G76_REQUIRE digits,.not_s01
 G76_REQUIRE no_control,.not_s01
 G76_REQUIRE safe_text,.not_s01
 mov eax,1
 ret
.not_s01:
 G76_REQUIRE numeric,.not_s02
 G76_REQUIRE num_min,.not_s02
 G76_REQUIRE num_max,.not_s02
 G76_REQUIRE range,.not_s02
 G76_REQUIRE positive,.not_s02
 G76_REQUIRE non_negative,.not_s02
 G76_REQUIRE even,.not_s02
 G76_REQUIRE odd,.not_s02
 G76_REQUIRE multiple_of,.not_s02
 G76_REQUIRE precision,.not_s02
 G76_REQUIRE locale,.not_s02
 mov eax,2
 ret
.not_s02:
 G76_REQUIRE choices,.not_s03
 G76_REQUIRE choice,.not_s03
 G76_REQUIRE yes_no,.not_s03
 G76_REQUIRE confirm,.not_s03
 G76_REQUIRE menu,.not_s03
 G76_REQUIRE select,.not_s03
 G76_REQUIRE multi_select,.not_s03
 G76_REQUIRE index_choice,.not_s03
 G76_REQUIRE autocomplete,.not_s03
 mov eax,3
 ret
.not_s03:
 G76_REQUIRE retry_ux,.not_s04
 G76_REQUIRE retry,.not_s04
 G76_REQUIRE max_attempts,.not_s04
 G76_REQUIRE on_fail,.not_s04
 G76_REQUIRE error,.not_s04
 G76_REQUIRE hint,.not_s04
 G76_REQUIRE example,.not_s04
 G76_REQUIRE explain,.not_s04
 G76_REQUIRE diagnostic,.not_s04
 G76_REQUIRE teach,.not_s04
 mov eax,4
 ret
.not_s04:
 G76_REQUIRE composition,.not_s05
 G76_REQUIRE min_len,.not_s05
 G76_REQUIRE positive,.not_s05
 G76_REQUIRE choice,.not_s05
 G76_REQUIRE max_attempts,.not_s05
 mov eax,5
 ret
.not_s05:
 G76_REQUIRE closeout,.not_s06
 G76_REQUIRE safe_text,.not_s06
 G76_REQUIRE range,.not_s06
 G76_REQUIRE menu,.not_s06
 G76_REQUIRE retry,.not_s06
 G76_REQUIRE diagnostic,.not_s06
 mov eax,6
 ret
.not_s06: xor eax,eax
 ret

g76_scan_program:
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
 cmp rdx,G76_MIN_SEED
 jb .next
 mov rax,G76_MAX_SEED
 cmp rdx,rax
 ja .unsupported
 cmp qword [rel g76_seed_seen],0
 jne .unsupported
 mov qword [rel g76_seed_seen],1
 mov [rel g76_seed],rdx
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
 call g76_known_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g76_validate_call
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
 cmp qword [rel g76_seed_seen],1
 jne .unsupported
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return: pop rbx
 ret

neboc_g076_source_parse:
 mov qword [rel g76_mode],0
 mov qword [rel g76_seed],0
 mov qword [rel g76_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g76_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g76_mode],rax
 lea rsi,[rel g76_n_print]
 mov edx,g76_n_print_len
 call ls_contains_atom
 test eax,eax
 jnz .unsupported
 call g76_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g76_mode]
 shl rax,32
 mov edi,dword [rel g76_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G76_FAMILY_KEY
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

%undef G76_REQUIRE
