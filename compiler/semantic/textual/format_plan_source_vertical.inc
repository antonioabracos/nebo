; G059 public-source owner for typed FormatPlan and Text.format(...).console().
; Selection depends only on current lexer tokens, never fixture paths or full
; source byte identity.
%define G59_FAMILY_KEY 0x5246323034473539

section .rodata
%macro G59_NAME 2
g59_n_%1: db %2
g59_n_%1_len equ $-g59_n_%1
%endmacro
G59_NAME format_plan,'FormatPlan'
G59_NAME format_node,'FormatNode'
G59_NAME format_string,'FormatString'
G59_NAME static_format_string,'StaticFormatString'
G59_NAME formatted_text,'FormattedText'
G59_NAME format_error,'FormatError'
G59_NAME evaluation_order,'EvaluationOrder'
G59_NAME evaluation_count,'EvaluationCount'
G59_NAME format_temporary,'FormatTemporary'
G59_NAME format_effect_policy,'FormatEffectPolicy'
G59_NAME console_options,'ConsoleOptions'
G59_NAME console_data_arguments,'ConsoleDataArguments'
G59_NAME literal,'literal'
G59_NAME value,'value'
G59_NAME named,'named'
G59_NAME position,'position'
G59_NAME byte_size_checked,'byteSizeChecked'
G59_NAME render_to,'renderTo'
G59_NAME parse_checked,'parseChecked'
G59_NAME validate,'validate'
G59_NAME format,'format'
G59_NAME format_named,'formatNamed'
G59_NAME format_with,'formatWith'
G59_NAME left_to_right,'LEFT_TO_RIGHT'
G59_NAME exactly_once,'EXACTLY_ONCE'
G59_NAME measure,'measure'
G59_NAME write,'write'
G59_NAME size_overflow,'SizeOverflow'
G59_NAME allocation_failed,'AllocationFailed'
G59_NAME invalid_template,'InvalidTemplate'
G59_NAME binding,'binding'
G59_NAME clone,'clone'
G59_NAME drop,'drop'
G59_NAME console,'console'
%undef G59_NAME

section .bss align=16
g59_mode: resq 1
g59_seed: resq 1
g59_seed_seen: resq 1
g59_has_console_options: resq 1

section .text
%macro G59_REQUIRE 2
 lea rsi,[rel g59_n_%1]
 mov edx,g59_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g59_is_program:
%macro G59_ROOT 1
 lea rsi,[rel g59_n_%1]
 mov edx,g59_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G59_ROOT format_plan
 G59_ROOT format_node
 G59_ROOT format_string
 G59_ROOT static_format_string
 G59_ROOT formatted_text
 G59_ROOT format_error
 G59_ROOT evaluation_order
 G59_ROOT evaluation_count
 G59_ROOT format_temporary
 G59_ROOT console_options
 ; The canonical chained spelling has no type root, so require both methods.
 lea rsi,[rel g59_n_format]
 mov edx,g59_n_format_len
 call ls_contains_atom
 test eax,eax
 jz .no
 lea rsi,[rel g59_n_console]
 mov edx,g59_n_console_len
 call ls_contains_atom
 test eax,eax
 jz .no
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret
%undef G59_ROOT

g59_known_call:
 push rbx
 mov rbx,rdi
%macro G59_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g59_n_%1]
 mov edx,g59_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G59_KNOWN literal
 G59_KNOWN value
 G59_KNOWN named
 G59_KNOWN position
 G59_KNOWN byte_size_checked
 G59_KNOWN render_to
 G59_KNOWN parse_checked
 G59_KNOWN validate
 G59_KNOWN format
 G59_KNOWN format_named
 G59_KNOWN format_with
 G59_KNOWN measure
 G59_KNOWN write
 G59_KNOWN clone
 G59_KNOWN drop
 G59_KNOWN console
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G59_KNOWN

g59_select_mode:
 ; S08 is the transversal composition of both typed owners and the effect.
 G59_REQUIRE format_plan,.not_s08
 G59_REQUIRE format_string,.not_s08
 G59_REQUIRE format,.not_s08
 G59_REQUIRE console,.not_s08
 G59_REQUIRE measure,.not_s08
 mov eax,8
 ret
.not_s08:
 G59_REQUIRE console_options,.not_s07
 G59_REQUIRE console,.not_s07
 mov eax,7
 ret
.not_s07:
 G59_REQUIRE formatted_text,.not_s06
 G59_REQUIRE binding,.not_s06
 G59_REQUIRE clone,.not_s06
 G59_REQUIRE drop,.not_s06
 mov eax,6
 ret
.not_s06:
 G59_REQUIRE format_plan,.not_s05
 G59_REQUIRE format_error,.not_s05
 G59_REQUIRE measure,.not_s05
 G59_REQUIRE write,.not_s05
 G59_REQUIRE size_overflow,.not_s05
 G59_REQUIRE allocation_failed,.not_s05
 G59_REQUIRE invalid_template,.not_s05
 mov eax,5
 ret
.not_s05:
 G59_REQUIRE evaluation_order,.not_s04
 G59_REQUIRE left_to_right,.not_s04
 G59_REQUIRE evaluation_count,.not_s04
 G59_REQUIRE exactly_once,.not_s04
 G59_REQUIRE format_temporary,.not_s04
 G59_REQUIRE format_effect_policy,.not_s04
 mov eax,4
 ret
.not_s04:
 G59_REQUIRE format,.not_s03
 G59_REQUIRE format_named,.not_s03
 G59_REQUIRE format_with,.not_s03
 G59_REQUIRE console,.not_s03
 mov eax,3
 ret
.not_s03:
 G59_REQUIRE format_string,.not_s02
 G59_REQUIRE parse_checked,.not_s02
 G59_REQUIRE validate,.not_s02
 G59_REQUIRE static_format_string,.not_s02
 mov eax,2
 ret
.not_s02:
 G59_REQUIRE format_plan,.not_s01
 G59_REQUIRE format_node,.not_s01
 G59_REQUIRE literal,.not_s01
 G59_REQUIRE value,.not_s01
 G59_REQUIRE named,.not_s01
 G59_REQUIRE position,.not_s01
 G59_REQUIRE byte_size_checked,.not_s01
 G59_REQUIRE render_to,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g59_scan_program:
 push rbx
 xor ebx,ebx
 lea rsi,[rel g59_n_console_options]
 mov edx,g59_n_console_options_len
 call ls_contains_atom
 mov [rel g59_has_console_options],rax
.scan:
 cmp rbx,[rel ls_token_count]
 jae .done
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_EOF
 je .done
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .dot
 mov rdi,rbx
 call ls_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp qword [rel g59_seed_seen],0
 jne .next
 mov qword [rel g59_seed_seen],1
 mov [rel g59_seed],rdx
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
 call g59_known_call
 test eax,eax
 jz .unsupported
 ; console(data...) is not a formatting API. One presentation argument is
 ; accepted only in a program that explicitly names ConsoleOptions.
 lea rdi,[rbx+1]
 lea rsi,[rel g59_n_console]
 mov edx,g59_n_console_len
 call ls_token_match
 test eax,eax
 jz .next
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .next
 cmp qword [rel g59_has_console_options],1
 jne .unsupported
 ; Exactly one presentation argument is the maximum. Nested calls are allowed,
 ; but a comma at this call's first nesting level would be data varargs.
 lea r10,[rbx+3]
 mov r11d,1
.console_arg_scan:
 cmp r10,[rel ls_token_count]
 jae .syntax
 mov rdi,r10
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_EOF
 je .syntax
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .console_arg_close
 inc r11d
 jmp .console_arg_next
.console_arg_close:
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .console_arg_comma
 dec r11d
 jz .next
 jmp .console_arg_next
.console_arg_comma:
 cmp eax,NEBOC_TOKEN_COMMA
 jne .console_arg_next
 cmp r11d,1
 je .unsupported
.console_arg_next:
 inc r10
 jmp .console_arg_scan
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
 cmp qword [rel g59_seed_seen],1
 jne .syntax
 cmp qword [rel g59_seed],0
 je .syntax
 xor eax,eax
 jmp .return
.syntax:
 mov eax,20
 jmp .return
.unsupported:
 mov eax,24
.return:
 pop rbx
 ret

neboc_g059_source_parse:
 mov qword [rel g59_mode],0
 mov qword [rel g59_seed],0
 mov qword [rel g59_seed_seen],0
 mov qword [rel g59_has_console_options],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g59_select_mode
 test eax,eax
 jz .syntax
 mov [rel g59_mode],rax
 call g59_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g59_mode]
 shl rax,32
 mov edi,dword [rel g59_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G59_FAMILY_KEY
 call ls_success
 ret
.syntax:
 mov edi,20
 call ls_error
 ret
.diagnostic:
 mov edi,eax
 call ls_error
 ret

%undef G59_REQUIRE
