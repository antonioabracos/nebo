; G069 token-owned public source vertical for bounded developer rendering.
%define G69_FAMILY_KEY 0x5246323034473639
%define G69_MAX_PAYLOAD 4096
%define G69_MAX_DEPTH 8
%define G69_MIN_SEED 700
%define G69_MAX_SEED 0xffffffff

section .rodata
%macro G69_NAME 2
g69_n_%1: db %2
g69_n_%1_len equ $-g69_n_%1
%endmacro
G69_NAME root,'RenderPlan'
G69_NAME code,'code'
G69_NAME diff,'diff'
G69_NAME patch,'patch'
G69_NAME line_numbers,'lineNumbers'
G69_NAME highlight,'highlight'
G69_NAME file,'file'
G69_NAME snippet,'snippet'
G69_NAME copyable,'copyable'
G69_NAME added,'added'
G69_NAME removed,'removed'
G69_NAME changed,'changed'
G69_NAME diagnostic,'diagnostic'
G69_NAME note,'note'
G69_NAME hint,'hint'
G69_NAME suggestion,'suggestion'
G69_NAME expected,'expected'
G69_NAME received,'received'
G69_NAME source_line,'sourceLine'
G69_NAME cursor,'cursor'
G69_NAME explain,'explain'
G69_NAME fix,'fix'
G69_NAME code_frame,'codeFrame'
G69_NAME severity,'severity'
G69_NAME debug,'debug'
G69_NAME inspect,'inspect'
G69_NAME type,'type'
G69_NAME pretty_type,'prettyType'
G69_NAME memory,'memory'
G69_NAME address,'address'
G69_NAME depth,'depth'
G69_NAME expand,'expand'
G69_NAME collapse,'collapse'
G69_NAME raw,'raw'
G69_NAME repr,'repr'
G69_NAME shape,'shape'
G69_NAME schema,'schema'
G69_NAME json,'json'
G69_NAME json_pretty,'jsonPretty'
G69_NAME yaml,'yaml'
G69_NAME toml,'toml'
G69_NAME csv,'csv'
G69_NAME tsv,'tsv'
G69_NAME xml,'xml'
G69_NAME ndjson,'ndjson'
G69_NAME key_value,'keyValue'
G69_NAME ini,'ini'
G69_NAME pretty,'pretty'
G69_NAME compact,'compact'
G69_NAME fields,'fields'
G69_NAME keys,'keys'
G69_NAME values,'values'
G69_NAME tuple_names,'tupleNames'
G69_NAME developer_conformance,'developerConformance'
G69_NAME validate,'validate'
G69_NAME write,'write'
G69_NAME console,'console'
G69_NAME deterministic,'deterministic'
%undef G69_NAME

section .bss align=16
g69_mode: resq 1
g69_seed: resq 1
g69_seed_seen: resq 1
g69_code_empty_seen: resq 1
g69_code_text_seen: resq 1

section .text
%macro G69_REQUIRE 2
 lea rsi,[rel g69_n_%1]
 mov edx,g69_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g69_is_program:
 push rbx
 lea rsi,[rel g69_n_root]
 mov edx,g69_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
 lea rsi,[rel g69_n_code]
 mov edx,g69_n_code_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel g69_n_diagnostic]
 mov edx,g69_n_diagnostic_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel g69_n_debug]
 mov edx,g69_n_debug_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel g69_n_json]
 mov edx,g69_n_json_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel g69_n_fields]
 mov edx,g69_n_fields_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel g69_n_pretty_type]
 mov edx,g69_n_pretty_type_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel g69_n_developer_conformance]
 mov edx,g69_n_developer_conformance_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
.no: xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret

g69_known_call:
 push rbx
 mov rbx,rdi
%macro G69_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g69_n_%1]
 mov edx,g69_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G69_KNOWN code
 G69_KNOWN diff
 G69_KNOWN patch
 G69_KNOWN line_numbers
 G69_KNOWN highlight
 G69_KNOWN file
 G69_KNOWN snippet
 G69_KNOWN copyable
 G69_KNOWN added
 G69_KNOWN removed
 G69_KNOWN changed
 G69_KNOWN diagnostic
 G69_KNOWN note
 G69_KNOWN hint
 G69_KNOWN suggestion
 G69_KNOWN expected
 G69_KNOWN received
 G69_KNOWN source_line
 G69_KNOWN cursor
 G69_KNOWN explain
 G69_KNOWN fix
 G69_KNOWN code_frame
 G69_KNOWN severity
 G69_KNOWN debug
 G69_KNOWN inspect
 G69_KNOWN type
 G69_KNOWN pretty_type
 G69_KNOWN memory
 G69_KNOWN address
 G69_KNOWN depth
 G69_KNOWN expand
 G69_KNOWN collapse
 G69_KNOWN raw
 G69_KNOWN repr
 G69_KNOWN shape
 G69_KNOWN schema
 G69_KNOWN json
 G69_KNOWN json_pretty
 G69_KNOWN yaml
 G69_KNOWN toml
 G69_KNOWN csv
 G69_KNOWN tsv
 G69_KNOWN xml
 G69_KNOWN ndjson
 G69_KNOWN key_value
 G69_KNOWN ini
 G69_KNOWN pretty
 G69_KNOWN compact
 G69_KNOWN fields
 G69_KNOWN keys
 G69_KNOWN values
 G69_KNOWN tuple_names
 G69_KNOWN developer_conformance
 G69_KNOWN validate
 G69_KNOWN write
 G69_KNOWN console
 G69_KNOWN deterministic
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret
%undef G69_KNOWN

; RDI dot-token index -> EAX boolean for exact bounded arity.
g69_validate_call:
 push rbx
 push r12
 mov rbx,rdi
 lea r12,[rbx+1]
%macro G69_ARG_MATCH 2
 mov rdi,r12
 lea rsi,[rel g69_n_%1]
 mov edx,g69_n_%1_len
 call ls_token_match
 test eax,eax
 jnz %2
%endmacro
 G69_ARG_MATCH code,.optional_text
 G69_ARG_MATCH file,.text
 G69_ARG_MATCH expected,.text
 G69_ARG_MATCH received,.text
 G69_ARG_MATCH source_line,.text
 G69_ARG_MATCH fix,.text
 G69_ARG_MATCH severity,.text
 G69_ARG_MATCH tuple_names,.text
 G69_ARG_MATCH cursor,.integer
 G69_ARG_MATCH depth,.integer
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
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,G69_MAX_PAYLOAD+2
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
 cmp rdx,G69_MAX_DEPTH
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .good
 jmp .bad
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
 cmp rdx,G69_MAX_PAYLOAD+2
 ja .bad
 lea rdi,[rbx+4]
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
%undef G69_ARG_MATCH

g69_select_mode:
 G69_REQUIRE developer_conformance,.not_s07
 G69_REQUIRE validate,.not_s07
 G69_REQUIRE write,.not_s07
 G69_REQUIRE console,.not_s07
 G69_REQUIRE deterministic,.not_s07
 mov eax,7
 ret
.not_s07:
 G69_REQUIRE code,.not_s01
 G69_REQUIRE diff,.not_s01
 G69_REQUIRE patch,.not_s01
 G69_REQUIRE line_numbers,.not_s01
 G69_REQUIRE highlight,.not_s01
 G69_REQUIRE file,.not_s01
 G69_REQUIRE snippet,.not_s01
 G69_REQUIRE copyable,.not_s01
 G69_REQUIRE added,.not_s01
 G69_REQUIRE removed,.not_s01
 G69_REQUIRE changed,.not_s01
 mov eax,1
 ret
.not_s01:
 G69_REQUIRE diagnostic,.not_s02
 G69_REQUIRE note,.not_s02
 G69_REQUIRE hint,.not_s02
 G69_REQUIRE suggestion,.not_s02
 G69_REQUIRE expected,.not_s02
 G69_REQUIRE received,.not_s02
 G69_REQUIRE source_line,.not_s02
 G69_REQUIRE cursor,.not_s02
 G69_REQUIRE explain,.not_s02
 G69_REQUIRE fix,.not_s02
 G69_REQUIRE code_frame,.not_s02
 G69_REQUIRE severity,.not_s02
 mov eax,2
 ret
.not_s02:
 G69_REQUIRE debug,.not_s03
 G69_REQUIRE inspect,.not_s03
 G69_REQUIRE type,.not_s03
 G69_REQUIRE pretty_type,.not_s03
 G69_REQUIRE memory,.not_s03
 G69_REQUIRE address,.not_s03
 G69_REQUIRE depth,.not_s03
 G69_REQUIRE expand,.not_s03
 G69_REQUIRE collapse,.not_s03
 G69_REQUIRE raw,.not_s03
 G69_REQUIRE repr,.not_s03
 G69_REQUIRE shape,.not_s03
 G69_REQUIRE schema,.not_s03
 mov eax,3
 ret
.not_s03:
 G69_REQUIRE json,.not_s04
 G69_REQUIRE json_pretty,.not_s04
 G69_REQUIRE yaml,.not_s04
 G69_REQUIRE toml,.not_s04
 G69_REQUIRE csv,.not_s04
 G69_REQUIRE tsv,.not_s04
 G69_REQUIRE xml,.not_s04
 G69_REQUIRE ndjson,.not_s04
 G69_REQUIRE key_value,.not_s04
 G69_REQUIRE ini,.not_s04
 G69_REQUIRE pretty,.not_s04
 G69_REQUIRE compact,.not_s04
 mov eax,4
 ret
.not_s04:
 G69_REQUIRE fields,.not_s05
 G69_REQUIRE pretty,.not_s05
 G69_REQUIRE compact,.not_s05
 G69_REQUIRE expand,.not_s05
 G69_REQUIRE depth,.not_s05
 G69_REQUIRE keys,.not_s05
 G69_REQUIRE values,.not_s05
 G69_REQUIRE schema,.not_s05
 G69_REQUIRE tuple_names,.not_s05
 mov eax,5
 ret
.not_s05:
 G69_REQUIRE type,.not_s06
 G69_REQUIRE pretty_type,.not_s06
 G69_REQUIRE shape,.not_s06
 G69_REQUIRE schema,.not_s06
 mov eax,6
 ret
.not_s06:
 xor eax,eax
 ret

g69_scan_program:
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
 mov rdi,rbx
 call ls_token_ptr
 test rax,rax
 jz .syntax
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rdx,G69_MIN_SEED
 jb .next
 mov rax,G69_MAX_SEED
 cmp rdx,rax
 ja .unsupported
 cmp qword [rel g69_seed_seen],0
 jne .unsupported
 mov qword [rel g69_seed_seen],1
 mov [rel g69_seed],rdx
 jmp .next
.text:
 cmp eax,NEBOC_TOKEN_TEXT
 jne .dot
 mov rdi,rbx
 call ls_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,G69_MAX_PAYLOAD+2
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
 call g69_known_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g69_validate_call
 test eax,eax
 jz .unsupported
 lea rdi,[rbx+1]
 lea rsi,[rel g69_n_code]
 mov edx,g69_n_code_len
 call ls_token_match
 test eax,eax
 jz .next
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .code_empty
 cmp eax,NEBOC_TOKEN_TEXT
 jne .unsupported
 cmp qword [rel g69_code_text_seen],0
 jne .unsupported
 mov qword [rel g69_code_text_seen],1
 jmp .next
.code_empty:
 cmp qword [rel g69_code_empty_seen],0
 jne .unsupported
 mov qword [rel g69_code_empty_seen],1
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
 lea rsi,[rel g69_n_memory]
 mov edx,g69_n_memory_len
 call ls_contains_atom
 test eax,eax
 jnz .require_debug
 lea rsi,[rel g69_n_address]
 mov edx,g69_n_address_len
 call ls_contains_atom
 test eax,eax
 jz .seed
.require_debug:
 lea rsi,[rel g69_n_debug]
 mov edx,g69_n_debug_len
 call ls_contains_atom
 test eax,eax
 jz .unsupported
.seed:
 cmp qword [rel g69_seed_seen],1
 jne .unsupported
 cmp qword [rel g69_mode],1
 jne .valid
 cmp qword [rel g69_code_empty_seen],1
 jne .unsupported
 cmp qword [rel g69_code_text_seen],1
 jne .unsupported
.valid:
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return: pop rbx
 ret

neboc_g069_source_parse:
 mov qword [rel g69_mode],0
 mov qword [rel g69_seed],0
 mov qword [rel g69_seed_seen],0
 mov qword [rel g69_code_empty_seen],0
 mov qword [rel g69_code_text_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g69_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g69_mode],rax
 call g69_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g69_mode]
 shl rax,32
 mov edi,dword [rel g69_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G69_FAMILY_KEY
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

%undef G69_REQUIRE
