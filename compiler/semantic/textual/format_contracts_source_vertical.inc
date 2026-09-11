; G079 token-owned common format contracts. Format-specific CSV/TSV/JSON/JSONL
; grammars remain owned by G080. This vertical accepts only finite literal
; plans and emits one stable family key for the shared lowering path.
%define G79_FAMILY_KEY 0x5246323034473739
%define G79_MIN_SEED 2300
%define G79_MAX_SEED 0xffffffff
%define G79_MAX_BYTES 4096
%define G79_MAX_FIELDS 64

section .rodata
%macro G79_NAME 2
g79_n_%1: db %2
g79_n_%1_len equ $-g79_n_%1
%endmacro
G79_NAME root,'FormatSystem'
G79_NAME contracts,'contracts79'
G79_NAME reports,'reports79'
G79_NAME schemas,'schemas79'
G79_NAME options,'options79'
G79_NAME detection,'detection79'
G79_NAME io,'io79'
G79_NAME conversion,'conversion79'
G79_NAME closeout,'closeout79'
G79_NAME format_kind,'FormatKind'
G79_NAME format_registry,'FormatRegistry'
G79_NAME format_capability,'FormatCapability'
G79_NAME format_error,'FormatError'
G79_NAME format_warning,'FormatWarning'
G79_NAME format_report,'FormatReport'
G79_NAME format_field,'FormatField'
G79_NAME format_schema,'FormatSchema'
G79_NAME validate,'validate'
G79_NAME compatibility,'compatibility'
G79_NAME parse_options,'ParseOptions'
G79_NAME write_options,'WriteOptions'
G79_NAME format_limits,'FormatLimits'
G79_NAME describe,'describe'
G79_NAME detect,'detect'
G79_NAME sample,'sample'
G79_NAME format_detection,'FormatDetection'
G79_NAME parse,'parse'
G79_NAME read,'read'
G79_NAME stream,'stream'
G79_NAME write,'write'
G79_NAME to_text,'toText'
G79_NAME to_bytes,'toBytes'
G79_NAME infer_schema,'inferSchema'
G79_NAME convert,'convert'
G79_NAME pretty,'pretty'
G79_NAME sanitize,'sanitize'
G79_NAME compose,'compose'
G79_NAME capability_audit,'capabilityAudit'
G79_NAME atomicity,'atomicity'
G79_NAME print,'print'
%undef G79_NAME

section .bss align=16
g79_mode: resq 1
g79_seed: resq 1
g79_seed_seen: resq 1

section .text
%macro G79_REQUIRE 2
 lea rsi,[rel g79_n_%1]
 mov edx,g79_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g79_is_program:
 lea rsi,[rel g79_n_root]
 mov edx,g79_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
%macro G79_MARKER 1
 lea rsi,[rel g79_n_%1]
 mov edx,g79_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G79_MARKER contracts
 G79_MARKER reports
 G79_MARKER schemas
 G79_MARKER options
 G79_MARKER detection
 G79_MARKER io
 G79_MARKER conversion
 G79_MARKER closeout
.no: xor eax,eax
 ret
.yes: mov eax,1
 ret
%undef G79_MARKER

g79_known_call:
 push rbx
 mov rbx,rdi
%macro G79_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g79_n_%1]
 mov edx,g79_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G79_KNOWN format_kind
 G79_KNOWN format_registry
 G79_KNOWN format_capability
 G79_KNOWN format_error
 G79_KNOWN format_warning
 G79_KNOWN format_report
 G79_KNOWN format_field
 G79_KNOWN format_schema
 G79_KNOWN validate
 G79_KNOWN compatibility
 G79_KNOWN parse_options
 G79_KNOWN write_options
 G79_KNOWN format_limits
 G79_KNOWN describe
 G79_KNOWN detect
 G79_KNOWN sample
 G79_KNOWN format_detection
 G79_KNOWN parse
 G79_KNOWN read
 G79_KNOWN stream
 G79_KNOWN write
 G79_KNOWN to_text
 G79_KNOWN to_bytes
 G79_KNOWN infer_schema
 G79_KNOWN convert
 G79_KNOWN pretty
 G79_KNOWN sanitize
 G79_KNOWN compose
 G79_KNOWN capability_audit
 G79_KNOWN atomicity
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret
%undef G79_KNOWN

; RDI dot token -> EAX exact literal arity and bounded values.
g79_validate_call:
 push rbx
 push r12
 mov rbx,rdi
 lea r12,[rbx+1]
%macro G79_ROUTE 2
 mov rdi,r12
 lea rsi,[rel g79_n_%1]
 mov edx,g79_n_%1_len
 call ls_token_match
 test eax,eax
 jnz %2
%endmacro
 G79_ROUTE describe,.nullary
 G79_ROUTE format_kind,.one_text
 G79_ROUTE format_capability,.one_text
 G79_ROUTE format_field,.one_text
 G79_ROUTE detect,.one_text
 G79_ROUTE parse,.one_text
 G79_ROUTE read,.one_text
 G79_ROUTE stream,.one_text
 G79_ROUTE to_text,.one_text
 G79_ROUTE to_bytes,.one_text
 G79_ROUTE validate,.one_text
 G79_ROUTE infer_schema,.one_text
 G79_ROUTE pretty,.one_text
 G79_ROUTE format_registry,.registry_version
 G79_ROUTE format_error,.one_int
 G79_ROUTE format_warning,.one_int
 G79_ROUTE format_report,.one_int
 G79_ROUTE format_schema,.field_bound
 G79_ROUTE compatibility,.field_bound
 G79_ROUTE parse_options,.one_int
 G79_ROUTE write_options,.one_int
 G79_ROUTE format_limits,.field_bound
 G79_ROUTE format_detection,.confidence
 G79_ROUTE compose,.compose_count
 G79_ROUTE capability_audit,.capability_mask
 G79_ROUTE atomicity,.atomicity_gate
 G79_ROUTE sample,.text_int
 G79_ROUTE write,.two_text
 G79_ROUTE convert,.two_text
 G79_ROUTE sanitize,.two_text
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
 cmp rdx,G79_MAX_BYTES+2
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.one_int:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test rdx,rdx
 jz .bad
 cmp rdx,G79_MAX_BYTES
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.registry_version:
 mov edx,1
 jmp .exact_int
.compose_count:
 mov edx,8
 jmp .exact_int
.atomicity_gate:
 mov edx,1
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
.field_bound:
 mov edx,G79_MAX_FIELDS
 jmp .bounded_int
.confidence:
 mov edx,100
 jmp .bounded_int
.capability_mask:
 mov edx,63
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
.text_int:
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
 cmp rdx,G79_MAX_FIELDS
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
.bad: xor eax,eax
.done:
 pop r12
 pop rbx
 ret
%undef G79_ROUTE

g79_select_mode:
 G79_REQUIRE contracts,.not_s01
 G79_REQUIRE format_kind,.not_s01
 G79_REQUIRE format_registry,.not_s01
 G79_REQUIRE format_capability,.not_s01
 mov eax,1
 ret
.not_s01:
 G79_REQUIRE reports,.not_s02
 G79_REQUIRE format_error,.not_s02
 G79_REQUIRE format_warning,.not_s02
 G79_REQUIRE format_report,.not_s02
 mov eax,2
 ret
.not_s02:
 G79_REQUIRE schemas,.not_s03
 G79_REQUIRE format_field,.not_s03
 G79_REQUIRE format_schema,.not_s03
 G79_REQUIRE validate,.not_s03
 G79_REQUIRE compatibility,.not_s03
 mov eax,3
 ret
.not_s03:
 G79_REQUIRE options,.not_s04
 G79_REQUIRE parse_options,.not_s04
 G79_REQUIRE write_options,.not_s04
 G79_REQUIRE format_limits,.not_s04
 mov eax,4
 ret
.not_s04:
 G79_REQUIRE detection,.not_s05
 G79_REQUIRE describe,.not_s05
 G79_REQUIRE detect,.not_s05
 G79_REQUIRE sample,.not_s05
 G79_REQUIRE format_detection,.not_s05
 mov eax,5
 ret
.not_s05:
 G79_REQUIRE io,.not_s06
 G79_REQUIRE parse,.not_s06
 G79_REQUIRE read,.not_s06
 G79_REQUIRE stream,.not_s06
 G79_REQUIRE write,.not_s06
 G79_REQUIRE to_text,.not_s06
 G79_REQUIRE to_bytes,.not_s06
 mov eax,6
 ret
.not_s06:
 G79_REQUIRE conversion,.not_s07
 G79_REQUIRE validate,.not_s07
 G79_REQUIRE infer_schema,.not_s07
 G79_REQUIRE convert,.not_s07
 G79_REQUIRE pretty,.not_s07
 G79_REQUIRE sanitize,.not_s07
 mov eax,7
 ret
.not_s07:
 G79_REQUIRE closeout,.none
 G79_REQUIRE compose,.none
 G79_REQUIRE capability_audit,.none
 G79_REQUIRE atomicity,.none
 mov eax,8
 ret
.none: xor eax,eax
 ret

g79_scan_program:
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
 cmp rdx,G79_MIN_SEED
 jb .next
 mov rax,G79_MAX_SEED
 cmp rdx,rax
 ja .next
 cmp qword [rel g79_seed_seen],0
 jne .unsupported
 mov qword [rel g79_seed_seen],1
 mov [rel g79_seed],rdx
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .unsupported
 lea rdi,[rbx+1]
 call g79_known_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g79_validate_call
 test eax,eax
 jz .unsupported
.next: inc rbx
 jmp .scan
.done:
 cmp qword [rel g79_seed_seen],1
 jne .unsupported
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return: pop rbx
 ret

neboc_g079_source_parse:
 mov qword [rel g79_mode],0
 mov qword [rel g79_seed],0
 mov qword [rel g79_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g79_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g79_mode],rax
 lea rsi,[rel g79_n_print]
 mov edx,g79_n_print_len
 call ls_contains_atom
 test eax,eax
 jnz .unsupported
 call g79_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g79_mode]
 shl rax,32
 mov edi,dword [rel g79_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G79_FAMILY_KEY
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

%undef G79_REQUIRE
