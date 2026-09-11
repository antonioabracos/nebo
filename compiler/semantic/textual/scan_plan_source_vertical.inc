; G075 token-owned ScanPlan vertical.  It admits only the bounded public
; surface classified for this group and lowers the six subgroup contracts to
; a compact mode/seed value consumed by the runtime probe.
%define G75_FAMILY_KEY 0x5246323034473735
%define G75_MIN_SEED 1300
%define G75_MAX_SEED 0xffffffff

section .rodata
%macro G75_NAME 2
g75_n_%1: db %2
g75_n_%1_len equ $-g75_n_%1
%endmacro
G75_NAME root,'ScanPlan'
G75_NAME types,'types'
G75_NAME empty,'empty'
G75_NAME normalization,'normalization'
G75_NAME abi,'abi'
G75_NAME diagnostics,'diagnostics'
G75_NAME closeout,'closeout'
G75_NAME text,'text'
G75_NAME int,'int'
G75_NAME number,'number'
G75_NAME bool,'bool'
G75_NAME char,'char'
G75_NAME line,'line'
G75_NAME token,'token'
G75_NAME words,'words'
G75_NAME list,'list'
G75_NAME tuple,'tuple'
G75_NAME date,'date'
G75_NAME time,'time'
G75_NAME datetime,'datetime'
G75_NAME email,'email'
G75_NAME url,'url'
G75_NAME path,'path'
G75_NAME password,'password'
G75_NAME json,'json'
G75_NAME raw,'raw'
G75_NAME required,'required'
G75_NAME optional,'optional'
G75_NAME allow_empty,'allowEmpty'
G75_NAME default,'default'
G75_NAME fallback,'fallback'
G75_NAME empty_as_none,'emptyAsNone'
G75_NAME trim,'trim'
G75_NAME trim_start,'trimStart'
G75_NAME trim_end,'trimEnd'
G75_NAME lower,'lower'
G75_NAME upper,'upper'
G75_NAME capitalize,'capitalize'
G75_NAME normalize,'normalize'
G75_NAME spaces,'spaces'
G75_NAME unicode,'unicode'
G75_NAME strip_accents,'stripAccents'
G75_NAME slug,'slug'
G75_NAME chomp,'chomp'
G75_NAME type_int,'Int'
G75_NAME type_text,'Text'
G75_NAME print,'print'
%undef G75_NAME

section .bss align=16
g75_mode: resq 1
g75_seed: resq 1
g75_seed_seen: resq 1

section .text
%macro G75_REQUIRE 2
 lea rsi,[rel g75_n_%1]
 mov edx,g75_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g75_is_program:
 lea rsi,[rel g75_n_root]
 mov edx,g75_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
%macro G75_MARKER 1
 lea rsi,[rel g75_n_%1]
 mov edx,g75_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G75_MARKER types
 G75_MARKER empty
 G75_MARKER normalization
 G75_MARKER abi
 G75_MARKER diagnostics
 G75_MARKER closeout
.no: xor eax,eax
 ret
.yes: mov eax,1
 ret
%undef G75_MARKER

; RDI token index -> EAX whether it is a recognized callable selector.
g75_known_call:
 push rbx
 mov rbx,rdi
%macro G75_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g75_n_%1]
 mov edx,g75_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G75_KNOWN text
 G75_KNOWN int
 G75_KNOWN number
 G75_KNOWN bool
 G75_KNOWN char
 G75_KNOWN line
 G75_KNOWN token
 G75_KNOWN words
 G75_KNOWN list
 G75_KNOWN tuple
 G75_KNOWN date
 G75_KNOWN time
 G75_KNOWN datetime
 G75_KNOWN email
 G75_KNOWN url
 G75_KNOWN path
 G75_KNOWN password
 G75_KNOWN json
 G75_KNOWN raw
 G75_KNOWN required
 G75_KNOWN optional
 G75_KNOWN allow_empty
 G75_KNOWN default
 G75_KNOWN fallback
 G75_KNOWN empty_as_none
 G75_KNOWN trim
 G75_KNOWN trim_start
 G75_KNOWN trim_end
 G75_KNOWN lower
 G75_KNOWN upper
 G75_KNOWN capitalize
 G75_KNOWN normalize
 G75_KNOWN spaces
 G75_KNOWN strip_accents
 G75_KNOWN slug
 G75_KNOWN chomp
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret
%undef G75_KNOWN

; RDI dot-token index -> EAX exact-arity/type result.  Unicode normalization
; remains explicitly deferred; only `.normalize(.spaces())` is public here.
g75_validate_call:
 push rbx
 push r12
 mov rbx,rdi
 lea r12,[rbx+1]
%macro G75_ARG_MATCH 2
 mov rdi,r12
 lea rsi,[rel g75_n_%1]
 mov edx,g75_n_%1_len
 call ls_token_match
 test eax,eax
 jnz %2
%endmacro
 G75_ARG_MATCH list,.list
 G75_ARG_MATCH tuple,.tuple
 G75_ARG_MATCH default,.integer
 G75_ARG_MATCH fallback,.integer
 G75_ARG_MATCH normalize,.normalize
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.list:
 lea rdi,[rbx+3]
 lea rsi,[rel g75_n_type_int]
 mov edx,g75_n_type_int_len
 call ls_token_match
 test eax,eax
 jz .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .good
 jmp .bad
.tuple:
 lea rdi,[rbx+3]
 lea rsi,[rel g75_n_type_int]
 mov edx,g75_n_type_int_len
 call ls_token_match
 test eax,eax
 jz .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+5]
 lea rsi,[rel g75_n_type_text]
 mov edx,g75_n_type_text_len
 call ls_token_match
 test eax,eax
 jz .bad
 lea rdi,[rbx+6]
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
 mov rax,0x7fffffff
 cmp rdx,rax
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .good
 jmp .bad
.normalize:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_DOT
 jne .bad
 lea rdi,[rbx+4]
 lea rsi,[rel g75_n_spaces]
 mov edx,g75_n_spaces_len
 call ls_token_match
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
 je .good
.bad: xor eax,eax
 jmp .done
.good: mov eax,1
.done:
 pop r12
 pop rbx
 ret
%undef G75_ARG_MATCH

g75_select_mode:
 G75_REQUIRE types,.not_s01
 G75_REQUIRE text,.not_s01
 G75_REQUIRE int,.not_s01
 G75_REQUIRE number,.not_s01
 G75_REQUIRE bool,.not_s01
 G75_REQUIRE char,.not_s01
 G75_REQUIRE line,.not_s01
 G75_REQUIRE token,.not_s01
 G75_REQUIRE words,.not_s01
 G75_REQUIRE list,.not_s01
 G75_REQUIRE tuple,.not_s01
 G75_REQUIRE date,.not_s01
 G75_REQUIRE time,.not_s01
 G75_REQUIRE datetime,.not_s01
 G75_REQUIRE email,.not_s01
 G75_REQUIRE url,.not_s01
 G75_REQUIRE path,.not_s01
 G75_REQUIRE password,.not_s01
 G75_REQUIRE json,.not_s01
 G75_REQUIRE raw,.not_s01
 mov eax,1
 ret
.not_s01:
 G75_REQUIRE empty,.not_s02
 G75_REQUIRE required,.not_s02
 G75_REQUIRE optional,.not_s02
 G75_REQUIRE allow_empty,.not_s02
 G75_REQUIRE default,.not_s02
 G75_REQUIRE fallback,.not_s02
 G75_REQUIRE empty_as_none,.not_s02
 mov eax,2
 ret
.not_s02:
 G75_REQUIRE normalization,.not_s03
 G75_REQUIRE trim,.not_s03
 G75_REQUIRE trim_start,.not_s03
 G75_REQUIRE trim_end,.not_s03
 G75_REQUIRE lower,.not_s03
 G75_REQUIRE upper,.not_s03
 G75_REQUIRE capitalize,.not_s03
 G75_REQUIRE normalize,.not_s03
 G75_REQUIRE spaces,.not_s03
 G75_REQUIRE strip_accents,.not_s03
 G75_REQUIRE slug,.not_s03
 G75_REQUIRE chomp,.not_s03
 mov eax,3
 ret
.not_s03:
 G75_REQUIRE abi,.not_s04
 G75_REQUIRE text,.not_s04
 G75_REQUIRE required,.not_s04
 G75_REQUIRE trim,.not_s04
 mov eax,4
 ret
.not_s04:
 G75_REQUIRE diagnostics,.not_s05
 G75_REQUIRE int,.not_s05
 G75_REQUIRE required,.not_s05
 mov eax,5
 ret
.not_s05:
 G75_REQUIRE closeout,.not_s06
 G75_REQUIRE text,.not_s06
 G75_REQUIRE optional,.not_s06
 G75_REQUIRE empty_as_none,.not_s06
 mov eax,6
 ret
.not_s06:
 xor eax,eax
 ret

g75_scan_program:
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
 cmp rdx,G75_MIN_SEED
 jb .next
 mov rax,G75_MAX_SEED
 cmp rdx,rax
 ja .unsupported
 cmp qword [rel g75_seed_seen],0
 jne .unsupported
 mov qword [rel g75_seed_seen],1
 mov [rel g75_seed],rdx
 jmp .next
.dot:
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
 call g75_known_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g75_validate_call
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
 cmp qword [rel g75_seed_seen],1
 jne .unsupported
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return: pop rbx
 ret

neboc_g075_source_parse:
 mov qword [rel g75_mode],0
 mov qword [rel g75_seed],0
 mov qword [rel g75_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g75_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g75_mode],rax
 lea rsi,[rel g75_n_print]
 mov edx,g75_n_print_len
 call ls_contains_atom
 test eax,eax
 jnz .unsupported
 call g75_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g75_mode]
 shl rax,32
 mov edi,dword [rel g75_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G75_FAMILY_KEY
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

%undef G75_REQUIRE
