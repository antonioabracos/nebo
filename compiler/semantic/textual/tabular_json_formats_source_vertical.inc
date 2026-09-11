; G080 token-owned CSV/TSV/JSON/JSONL contracts. The vertical accepts only
; finite literal plans and publishes one stable family key to lowering.
%define G80_FAMILY_KEY 0x5246323034473830
%define G80_MIN_SEED 2800
%define G80_MAX_SEED 0xffffffff
%define G80_MAX_BYTES 4096
%define G80_MAX_FIELDS 64

section .rodata
%macro G80_NAME 2
g80_n_%1: db %2
g80_n_%1_len equ $-g80_n_%1
%endmacro
G80_NAME root,'FormatData'
G80_NAME csv_types,'csvTypes80'
G80_NAME csv_io,'csvIo80'
G80_NAME tsv,'tsv80'
G80_NAME json_values,'jsonValues80'
G80_NAME json_io,'jsonIo80'
G80_NAME json_typed,'jsonTyped80'
G80_NAME jsonl,'jsonl80'
G80_NAME closeout,'closeout80'
G80_NAME csv_options,'CsvOptions'
G80_NAME csv_write_options,'CsvWriteOptions'
G80_NAME csv_table,'CsvTable'
G80_NAME csv_row,'CsvRow'
G80_NAME csv_cell,'CsvCell'
G80_NAME describe,'describe'
G80_NAME parse,'parse'
G80_NAME read,'read'
G80_NAME read_with_schema,'readWithSchema'
G80_NAME stream_rows,'streamRows'
G80_NAME validate,'validate'
G80_NAME write,'write'
G80_NAME stringify,'stringify'
G80_NAME row_count,'rowCount'
G80_NAME headers,'headers'
G80_NAME sample,'sample'
G80_NAME json_value,'JsonValue'
G80_NAME object,'object'
G80_NAME array,'array'
G80_NAME set_text,'setText'
G80_NAME set_int,'setInt'
G80_NAME set_bool,'setBool'
G80_NAME is_object,'isObject'
G80_NAME is_array,'isArray'
G80_NAME is_null,'isNull'
G80_NAME read_as,'readAs'
G80_NAME to_text,'toText'
G80_NAME pretty,'pretty'
G80_NAME from_table,'fromTable'
G80_NAME to_struct,'toStruct'
G80_NAME to_dict,'toDict'
G80_NAME to_json_value,'toJsonValue'
G80_NAME decode_policy,'JsonDecodePolicy'
G80_NAME stream,'stream'
G80_NAME stream_events,'streamEvents'
G80_NAME dead_letter,'deadLetter'
G80_NAME compose,'compose'
G80_NAME security_audit,'securityAudit'
G80_NAME atomicity,'atomicity'
G80_NAME print,'print'
%undef G80_NAME

section .bss align=16
g80_mode: resq 1
g80_seed: resq 1
g80_seed_seen: resq 1

section .text
%macro G80_REQUIRE 2
 lea rsi,[rel g80_n_%1]
 mov edx,g80_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g80_is_program:
 lea rsi,[rel g80_n_root]
 mov edx,g80_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
%macro G80_MARKER 1
 lea rsi,[rel g80_n_%1]
 mov edx,g80_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G80_MARKER csv_types
 G80_MARKER csv_io
 G80_MARKER tsv
 G80_MARKER json_values
 G80_MARKER json_io
 G80_MARKER json_typed
 G80_MARKER jsonl
 G80_MARKER closeout
.no: xor eax,eax
 ret
.yes: mov eax,1
 ret
%undef G80_MARKER

g80_known_call:
 push rbx
 mov rbx,rdi
%macro G80_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g80_n_%1]
 mov edx,g80_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G80_KNOWN csv_options
 G80_KNOWN csv_write_options
 G80_KNOWN csv_table
 G80_KNOWN csv_row
 G80_KNOWN csv_cell
 G80_KNOWN describe
 G80_KNOWN parse
 G80_KNOWN read
 G80_KNOWN read_with_schema
 G80_KNOWN stream_rows
 G80_KNOWN validate
 G80_KNOWN write
 G80_KNOWN stringify
 G80_KNOWN row_count
 G80_KNOWN headers
 G80_KNOWN sample
 G80_KNOWN json_value
 G80_KNOWN object
 G80_KNOWN array
 G80_KNOWN set_text
 G80_KNOWN set_int
 G80_KNOWN set_bool
 G80_KNOWN is_object
 G80_KNOWN is_array
 G80_KNOWN is_null
 G80_KNOWN read_as
 G80_KNOWN to_text
 G80_KNOWN pretty
 G80_KNOWN from_table
 G80_KNOWN to_struct
 G80_KNOWN to_dict
 G80_KNOWN to_json_value
 G80_KNOWN decode_policy
 G80_KNOWN stream
 G80_KNOWN stream_events
 G80_KNOWN dead_letter
 G80_KNOWN compose
 G80_KNOWN security_audit
 G80_KNOWN atomicity
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret
%undef G80_KNOWN

; RDI points at a dot token. Each public operation has one finite literal
; signature; overloads use explicit source names to avoid ambiguous dispatch.
g80_validate_call:
 push rbx
 push r12
 mov rbx,rdi
 lea r12,[rbx+1]
%macro G80_ROUTE 2
 mov rdi,r12
 lea rsi,[rel g80_n_%1]
 mov edx,g80_n_%1_len
 call ls_token_match
 test eax,eax
 jnz %2
%endmacro
 G80_ROUTE describe,.nullary
 G80_ROUTE object,.nullary
 G80_ROUTE array,.nullary
 G80_ROUTE is_object,.nullary
 G80_ROUTE is_array,.nullary
 G80_ROUTE is_null,.nullary
 G80_ROUTE to_dict,.nullary
 G80_ROUTE to_json_value,.nullary
 G80_ROUTE parse,.one_text
 G80_ROUTE read,.read_overload
 G80_ROUTE stream_rows,.one_text
 G80_ROUTE stringify,.one_text
 G80_ROUTE row_count,.one_text
 G80_ROUTE headers,.one_text
 G80_ROUTE to_text,.one_text
 G80_ROUTE pretty,.one_text
 G80_ROUTE from_table,.one_text
 G80_ROUTE to_struct,.one_text
 G80_ROUTE stream,.one_text
 G80_ROUTE dead_letter,.one_text
 G80_ROUTE csv_cell,.one_text
 G80_ROUTE csv_options,.one_int
 G80_ROUTE csv_write_options,.one_int
 G80_ROUTE csv_table,.bounded_fields
 G80_ROUTE csv_row,.bounded_fields
 G80_ROUTE json_value,.json_tag
 G80_ROUTE decode_policy,.decode_policy
 G80_ROUTE read_with_schema,.text_int
 G80_ROUTE validate,.text_int
 G80_ROUTE sample,.text_int
 G80_ROUTE set_int,.text_int
 G80_ROUTE set_bool,.text_bool
 G80_ROUTE write,.write_overload
 G80_ROUTE set_text,.two_text
 G80_ROUTE read_as,.two_text
 G80_ROUTE stream_events,.two_text
 G80_ROUTE compose,.compose_count
 G80_ROUTE security_audit,.one_gate
 G80_ROUTE atomicity,.one_gate
 xor eax,eax
 jmp .done
.nullary:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.one_text:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,2
 jbe .bad
 cmp rdx,G80_MAX_BYTES+2
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.read_overload:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,2
 jbe .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .read_one
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+5]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test rdx,rdx
 jz .bad
 cmp rdx,G80_MAX_BYTES
 ja .bad
 lea rdi,[rbx+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.read_one: mov eax,1
 jmp .done
.one_int:
 mov edx,G80_MAX_BYTES
 jmp .bounded_int
.bounded_fields:
 mov edx,G80_MAX_FIELDS
 jmp .bounded_int
.json_tag:
 mov edx,4
 jmp .bounded_int
.decode_policy:
 mov edx,2
 jmp .bounded_int
.one_gate:
 mov edx,1
 jmp .exact_int
.compose_count:
 mov edx,8
.exact_int:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .bad
 cmp [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],rdx
 jne .bad
 jmp .int_tail
.bounded_int:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .bad
 mov rcx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test rcx,rcx
 jz .bad
 cmp rcx,rdx
 ja .bad
.int_tail:
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.text_bool:
 mov r10d,1
 jmp .text_int_common
.text_int:
 mov r10d,G80_MAX_FIELDS
.text_int_common:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,2
 jbe .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+5]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test rdx,rdx
 jz .bad
 cmp rdx,r10
 ja .bad
 lea rdi,[rbx+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.two_text:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,2
 jbe .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+5]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,2
 jbe .bad
 lea rdi,[rbx+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.write_overload:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+5]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne .bad
 lea rdi,[rbx+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .write_two
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+7]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rdx,1
 jb .bad
 cmp rdx,2
 ja .bad
 lea rdi,[rbx+8]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.write_two: mov eax,1
 jmp .done
.bad: xor eax,eax
.done:
 pop r12
 pop rbx
 ret
%undef G80_ROUTE

g80_select_mode:
 G80_REQUIRE csv_types,.not_s01
 G80_REQUIRE csv_options,.not_s01
 G80_REQUIRE csv_write_options,.not_s01
 G80_REQUIRE csv_table,.not_s01
 G80_REQUIRE csv_row,.not_s01
 G80_REQUIRE csv_cell,.not_s01
 mov eax,1
 ret
.not_s01:
 G80_REQUIRE csv_io,.not_s02
 G80_REQUIRE describe,.not_s02
 G80_REQUIRE parse,.not_s02
 G80_REQUIRE read,.not_s02
 G80_REQUIRE read_with_schema,.not_s02
 G80_REQUIRE stream_rows,.not_s02
 G80_REQUIRE validate,.not_s02
 G80_REQUIRE write,.not_s02
 G80_REQUIRE stringify,.not_s02
 G80_REQUIRE row_count,.not_s02
 G80_REQUIRE headers,.not_s02
 G80_REQUIRE sample,.not_s02
 mov eax,2
 ret
.not_s02:
 G80_REQUIRE tsv,.not_s03
 G80_REQUIRE describe,.not_s03
 G80_REQUIRE parse,.not_s03
 G80_REQUIRE read,.not_s03
 G80_REQUIRE stream_rows,.not_s03
 G80_REQUIRE write,.not_s03
 mov eax,3
 ret
.not_s03:
 G80_REQUIRE json_values,.not_s04
 G80_REQUIRE json_value,.not_s04
 G80_REQUIRE object,.not_s04
 G80_REQUIRE array,.not_s04
 G80_REQUIRE set_text,.not_s04
 G80_REQUIRE set_int,.not_s04
 G80_REQUIRE set_bool,.not_s04
 G80_REQUIRE is_object,.not_s04
 G80_REQUIRE is_array,.not_s04
 G80_REQUIRE is_null,.not_s04
 mov eax,4
 ret
.not_s04:
 G80_REQUIRE json_io,.not_s05
 G80_REQUIRE describe,.not_s05
 G80_REQUIRE parse,.not_s05
 G80_REQUIRE read,.not_s05
 G80_REQUIRE read_as,.not_s05
 G80_REQUIRE to_text,.not_s05
 G80_REQUIRE stringify,.not_s05
 G80_REQUIRE pretty,.not_s05
 G80_REQUIRE from_table,.not_s05
 G80_REQUIRE validate,.not_s05
 mov eax,5
 ret
.not_s05:
 G80_REQUIRE json_typed,.not_s06
 G80_REQUIRE to_struct,.not_s06
 G80_REQUIRE to_dict,.not_s06
 G80_REQUIRE to_json_value,.not_s06
 G80_REQUIRE decode_policy,.not_s06
 mov eax,6
 ret
.not_s06:
 G80_REQUIRE jsonl,.not_s07
 G80_REQUIRE stream,.not_s07
 G80_REQUIRE stream_rows,.not_s07
 G80_REQUIRE stream_events,.not_s07
 G80_REQUIRE write,.not_s07
 G80_REQUIRE validate,.not_s07
 G80_REQUIRE dead_letter,.not_s07
 mov eax,7
 ret
.not_s07:
 G80_REQUIRE closeout,.none
 G80_REQUIRE compose,.none
 G80_REQUIRE security_audit,.none
 G80_REQUIRE atomicity,.none
 mov eax,8
 ret
.none: xor eax,eax
 ret

g80_scan_program:
 push rbx
 mov rbx,[rel ls_cursor]
.scan:
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_EOF
 je .syntax
 cmp eax,NEBOC_TOKEN_RBRACE
 je .done
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .dot
 test rbx,rbx
 jz .syntax
 lea rdi,[rbx-1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 je .next
 cmp eax,NEBOC_TOKEN_COMMA
 je .next
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 jne .next
 mov rdi,rbx
 call ls_token_ptr
 test rax,rax
 jz .syntax
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rdx,G80_MIN_SEED
 jb .next
 mov rax,G80_MAX_SEED
 cmp rdx,rax
 ja .next
 cmp qword [rel g80_seed_seen],0
 jne .unsupported
 mov qword [rel g80_seed_seen],1
 mov [rel g80_seed],rdx
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .unsupported
 lea rdi,[rbx+1]
 call g80_known_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g80_validate_call
 test eax,eax
 jz .unsupported
.next: inc rbx
 jmp .scan
.done:
 cmp qword [rel g80_seed_seen],1
 jne .unsupported
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return: pop rbx
 ret

neboc_g080_source_parse:
 mov qword [rel g80_mode],0
 mov qword [rel g80_seed],0
 mov qword [rel g80_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g80_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g80_mode],rax
 lea rsi,[rel g80_n_print]
 mov edx,g80_n_print_len
 call ls_contains_atom
 test eax,eax
 jnz .unsupported
 call g80_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g80_mode]
 shl rax,32
 mov edi,dword [rel g80_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G80_FAMILY_KEY
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

%undef G80_REQUIRE
