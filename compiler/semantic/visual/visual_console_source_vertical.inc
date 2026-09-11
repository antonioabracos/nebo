; Canonical public-source owner for Console documents, Window events, Canvas,
; accessible widgets and deterministic charts.
%define G18_FAMILY_KEY 0x5246323034473138

section .rodata
%macro G18_NAME 2
g18_n_%1: db %2
g18_n_%1_len equ $-g18_n_%1
%endmacro
G18_NAME console_type,'Console'
G18_NAME window_type,'Window'
G18_NAME canvas_type,'Canvas'
G18_NAME layout_type,'Layout'
G18_NAME button_type,'Button'
G18_NAME text_input_type,'TextInput'
G18_NAME label_type,'Label'
G18_NAME chart_type,'Chart'
G18_NAME visual_type,'visual'
G18_NAME red_type,'RED'
G18_NAME console,'console'
G18_NAME scan,'scan'
G18_NAME summarize,'summarize'
G18_NAME color,'color'
G18_NAME title,'title'
G18_NAME clear,'clear'
G18_NAME append,'append'
G18_NAME style,'style'
G18_NAME scroll_to_end,'scrollToEnd'
G18_NAME size,'size'
G18_NAME close,'close'
G18_NAME create,'create'
G18_NAME show,'show'
G18_NAME hide,'hide'
G18_NAME resize,'resize'
G18_NAME set_title,'setTitle'
G18_NAME request_redraw,'requestRedraw'
G18_NAME events,'events'
G18_NAME kind,'kind'
G18_NAME key,'key'
G18_NAME pointer,'pointer'
G18_NAME text_input,'textInput'
G18_NAME prevent_default,'preventDefault'
G18_NAME line,'line'
G18_NAME rectangle,'rectangle'
G18_NAME circle,'circle'
G18_NAME text,'text'
G18_NAME image,'image'
G18_NAME present,'present'
G18_NAME row,'row'
G18_NAME column,'column'
G18_NAME grid,'grid'
G18_NAME new,'new'
G18_NAME on,'on'
G18_NAME accessibility,'accessibility'
G18_NAME scatter,'scatter'
G18_NAME bar,'bar'
G18_NAME histogram,'histogram'
G18_NAME axis,'axis'
G18_NAME legend,'legend'
G18_NAME render,'render'
%undef G18_NAME

section .bss align=16
g18_mode: resq 1
g18_seed: resq 1
g18_seed_seen: resq 1

section .text
%macro G18_REQUIRE 2
 lea rsi,[rel g18_n_%1]
 mov edx,g18_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

; A current G018 program has one of the four public visual roots plus a
; contract-specific witness. Generic console-only programs stay with their
; earlier canonical owner unless they expose the complete G018 console set.
g18_is_program:
%macro G18_ROOT 1
 lea rsi,[rel g18_n_%1]
 mov edx,g18_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .root
%endmacro
 G18_ROOT window_type
 G18_ROOT canvas_type
 G18_ROOT layout_type
 G18_ROOT chart_type
 G18_ROOT console_type
 G18_ROOT visual_type
 G18_ROOT scroll_to_end
 G18_ROOT events
 jmp .no
.root:
%macro G18_WITNESS 1
 lea rsi,[rel g18_n_%1]
 mov edx,g18_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G18_WITNESS request_redraw
 G18_WITNESS prevent_default
 G18_WITNESS scroll_to_end
 G18_WITNESS summarize
 G18_WITNESS color
 G18_WITNESS accessibility
 G18_WITNESS histogram
 G18_WITNESS render
 G18_WITNESS present
 jmp .no
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret
%undef G18_WITNESS
%undef G18_ROOT

g18_count_atom:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rsi
 mov r13d,edx
 xor ebx,ebx
 xor r14d,r14d
.scan:
 cmp rbx,[rel ls_token_count]
 jae .done
 mov rdi,rbx
 mov rsi,r12
 mov edx,r13d
 call ls_token_match
 add r14d,eax
 inc rbx
 jmp .scan
.done:
 mov eax,r14d
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

g18_known_call:
 push rbx
 mov rbx,rdi
%macro G18_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g18_n_%1]
 mov edx,g18_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G18_KNOWN console
 G18_KNOWN scan
 G18_KNOWN summarize
 G18_KNOWN color
 G18_KNOWN title
 G18_KNOWN clear
 G18_KNOWN append
 G18_KNOWN style
 G18_KNOWN scroll_to_end
 G18_KNOWN size
 G18_KNOWN close
 G18_KNOWN create
 G18_KNOWN show
 G18_KNOWN hide
 G18_KNOWN resize
 G18_KNOWN set_title
 G18_KNOWN request_redraw
 G18_KNOWN events
 G18_KNOWN kind
 G18_KNOWN key
 G18_KNOWN pointer
 G18_KNOWN text_input
 G18_KNOWN prevent_default
 G18_KNOWN line
 G18_KNOWN rectangle
 G18_KNOWN circle
 G18_KNOWN text
 G18_KNOWN image
 G18_KNOWN present
 G18_KNOWN row
 G18_KNOWN column
 G18_KNOWN grid
 G18_KNOWN new
 G18_KNOWN on
 G18_KNOWN accessibility
 G18_KNOWN scatter
 G18_KNOWN bar
 G18_KNOWN histogram
 G18_KNOWN axis
 G18_KNOWN legend
 G18_KNOWN render
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G18_KNOWN

g18_select_mode:
 G18_REQUIRE chart_type,.not_s07
 G18_REQUIRE line,.not_s07
 G18_REQUIRE scatter,.not_s07
 G18_REQUIRE bar,.not_s07
 G18_REQUIRE histogram,.not_s07
 G18_REQUIRE axis,.not_s07
 G18_REQUIRE legend,.not_s07
 G18_REQUIRE render,.not_s07
 G18_REQUIRE title,.not_s07
 mov eax,7
 ret
.not_s07:
 G18_REQUIRE layout_type,.not_s06
 G18_REQUIRE row,.not_s06
 G18_REQUIRE column,.not_s06
 G18_REQUIRE grid,.not_s06
 G18_REQUIRE button_type,.not_s06
 G18_REQUIRE text_input_type,.not_s06
 G18_REQUIRE label_type,.not_s06
 G18_REQUIRE new,.not_s06
 G18_REQUIRE on,.not_s06
 G18_REQUIRE accessibility,.not_s06
 lea rsi,[rel g18_n_new]
 mov edx,g18_n_new_len
 call g18_count_atom
 cmp eax,3
 jb .not_s06
 mov eax,6
 ret
.not_s06:
 G18_REQUIRE canvas_type,.not_s05
 G18_REQUIRE create,.not_s05
 G18_REQUIRE clear,.not_s05
 G18_REQUIRE line,.not_s05
 G18_REQUIRE rectangle,.not_s05
 G18_REQUIRE circle,.not_s05
 G18_REQUIRE text,.not_s05
 G18_REQUIRE image,.not_s05
 G18_REQUIRE present,.not_s05
 mov eax,5
 ret
.not_s05:
 G18_REQUIRE events,.not_s04
 G18_REQUIRE kind,.not_s04
 G18_REQUIRE key,.not_s04
 G18_REQUIRE pointer,.not_s04
 G18_REQUIRE text_input,.not_s04
 G18_REQUIRE resize,.not_s04
 G18_REQUIRE prevent_default,.not_s04
 mov eax,4
 ret
.not_s04:
 G18_REQUIRE window_type,.not_s03
 G18_REQUIRE create,.not_s03
 G18_REQUIRE show,.not_s03
 G18_REQUIRE hide,.not_s03
 G18_REQUIRE resize,.not_s03
 G18_REQUIRE set_title,.not_s03
 G18_REQUIRE request_redraw,.not_s03
 G18_REQUIRE close,.not_s03
 mov eax,3
 ret
.not_s03:
 G18_REQUIRE scroll_to_end,.not_s02
 G18_REQUIRE append,.not_s02
 G18_REQUIRE style,.not_s02
 G18_REQUIRE size,.not_s02
 G18_REQUIRE clear,.not_s02
 G18_REQUIRE title,.not_s02
 G18_REQUIRE close,.not_s02
 mov eax,2
 ret
.not_s02:
 G18_REQUIRE console_type,.not_s01
 G18_REQUIRE visual_type,.not_s01
 G18_REQUIRE red_type,.not_s01
 G18_REQUIRE console,.not_s01
 G18_REQUIRE scan,.not_s01
 G18_REQUIRE summarize,.not_s01
 G18_REQUIRE color,.not_s01
 lea rsi,[rel g18_n_console]
 mov edx,g18_n_console_len
 call g18_count_atom
 cmp eax,3
 jb .not_s01
 lea rsi,[rel g18_n_scan]
 mov edx,g18_n_scan_len
 call g18_count_atom
 cmp eax,2
 jb .not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g18_scan_program:
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
 mov rdi,rbx
 call ls_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp qword [rel g18_seed_seen],0
 jne .next
 mov qword [rel g18_seed_seen],1
 mov [rel g18_seed],rdx
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
 call g18_known_call
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
 cmp qword [rel g18_seed],0
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

neboc_g018_source_parse:
 mov qword [rel g18_mode],0
 mov qword [rel g18_seed],0
 mov qword [rel g18_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g18_select_mode
 test eax,eax
 jz .syntax
 mov [rel g18_mode],rax
 call g18_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g18_mode]
 shl rax,32
 mov edi,dword [rel g18_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G18_FAMILY_KEY
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

%undef G18_REQUIRE
