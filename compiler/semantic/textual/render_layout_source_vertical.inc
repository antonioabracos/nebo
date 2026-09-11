; G068 token-owned public source vertical for bounded RenderPlan layout.
%define G68_FAMILY_KEY 0x5246323034473638
%define G68_MAX_PAYLOAD 4096
%define G68_MAX_ARGUMENT 120
%define G68_MIN_SEED 600
%define G68_MAX_SEED 0xffffffff

section .rodata
%macro G68_NAME 2
g68_n_%1: db %2
g68_n_%1_len equ $-g68_n_%1
%endmacro
G68_NAME root,'RenderPlan'
G68_NAME title,'title'
G68_NAME subtitle,'subtitle'
G68_NAME section,'section'
G68_NAME subsection,'subsection'
G68_NAME paragraph,'paragraph'
G68_NAME quote,'quote'
G68_NAME line,'line'
G68_NAME hr,'hr'
G68_NAME line_before,'lineBefore'
G68_NAME line_after,'lineAfter'
G68_NAME indent,'indent'
G68_NAME outdent,'outdent'
G68_NAME center,'center'
G68_NAME left,'left'
G68_NAME right,'right'
G68_NAME width,'width'
G68_NAME margin,'margin'
G68_NAME padding,'padding'
G68_NAME box,'box'
G68_NAME table,'table'
G68_NAME headers,'headers'
G68_NAME columns,'columns'
G68_NAME align,'align'
G68_NAME border,'border'
G68_NAME no_border,'noBorder'
G68_NAME compact,'compact'
G68_NAME pretty,'pretty'
G68_NAME csv,'csv'
G68_NAME tsv,'tsv'
G68_NAME markdown_table,'markdownTable'
G68_NAME sort_by,'sortBy'
G68_NAME limit,'limit'
G68_NAME summary,'summary'
G68_NAME totals,'totals'
G68_NAME list,'list'
G68_NAME ordered,'ordered'
G68_NAME unordered,'unordered'
G68_NAME bullets,'bullets'
G68_NAME checklist,'checklist'
G68_NAME numbered,'numbered'
G68_NAME tree,'tree'
G68_NAME inline,'inline'
G68_NAME multi_line,'multiLine'
G68_NAME prefix_items,'prefixItems'
G68_NAME suffix_items,'suffixItems'
G68_NAME each_line,'eachLine'
G68_NAME count,'count'
G68_NAME first,'first'
G68_NAME last,'last'
G68_NAME sample,'sample'
G68_NAME sort,'sort'
G68_NAME group_by,'groupBy'
G68_NAME filter_shown,'filterShown'
G68_NAME doc_title,'docTitle'
G68_NAME doc_section,'docSection'
G68_NAME markdown,'markdown'
G68_NAME admonition,'admonition'
G68_NAME example,'example'
G68_NAME definition,'definition'
G68_NAME toc,'toc'
G68_NAME link,'link'
G68_NAME anchor,'anchor'
G68_NAME width_cells,'widthCells'
G68_NAME wrap_words,'wrapWords'
G68_NAME align_left,'alignLeft'
G68_NAME align_center,'alignCenter'
G68_NAME align_right,'alignRight'
G68_NAME layout_conformance,'layoutConformance'
G68_NAME validate,'validate'
G68_NAME write,'write'
G68_NAME console,'console'
G68_NAME deterministic,'deterministic'
%undef G68_NAME

section .bss align=16
g68_mode: resq 1
g68_seed: resq 1
g68_seed_seen: resq 1

section .text
%macro G68_REQUIRE 2
 lea rsi,[rel g68_n_%1]
 mov edx,g68_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g68_is_program:
 push rbx
 lea rsi,[rel g68_n_root]
 mov edx,g68_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
 lea rsi,[rel g68_n_title]
 mov edx,g68_n_title_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel g68_n_table]
 mov edx,g68_n_table_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel g68_n_list]
 mov edx,g68_n_list_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel g68_n_each_line]
 mov edx,g68_n_each_line_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel g68_n_doc_title]
 mov edx,g68_n_doc_title_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel g68_n_width_cells]
 mov edx,g68_n_width_cells_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel g68_n_layout_conformance]
 mov edx,g68_n_layout_conformance_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
.no: xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret

g68_known_call:
 push rbx
 mov rbx,rdi
%macro G68_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g68_n_%1]
 mov edx,g68_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G68_KNOWN title
 G68_KNOWN subtitle
 G68_KNOWN section
 G68_KNOWN subsection
 G68_KNOWN paragraph
 G68_KNOWN quote
 G68_KNOWN line
 G68_KNOWN hr
 G68_KNOWN line_before
 G68_KNOWN line_after
 G68_KNOWN indent
 G68_KNOWN outdent
 G68_KNOWN center
 G68_KNOWN left
 G68_KNOWN right
 G68_KNOWN width
 G68_KNOWN margin
 G68_KNOWN padding
 G68_KNOWN box
 G68_KNOWN table
 G68_KNOWN headers
 G68_KNOWN columns
 G68_KNOWN align
 G68_KNOWN border
 G68_KNOWN no_border
 G68_KNOWN compact
 G68_KNOWN pretty
 G68_KNOWN csv
 G68_KNOWN tsv
 G68_KNOWN markdown_table
 G68_KNOWN sort_by
 G68_KNOWN limit
 G68_KNOWN summary
 G68_KNOWN totals
 G68_KNOWN list
 G68_KNOWN ordered
 G68_KNOWN unordered
 G68_KNOWN bullets
 G68_KNOWN checklist
 G68_KNOWN numbered
 G68_KNOWN tree
 G68_KNOWN inline
 G68_KNOWN multi_line
 G68_KNOWN prefix_items
 G68_KNOWN suffix_items
 G68_KNOWN each_line
 G68_KNOWN count
 G68_KNOWN first
 G68_KNOWN last
 G68_KNOWN sample
 G68_KNOWN sort
 G68_KNOWN group_by
 G68_KNOWN filter_shown
 G68_KNOWN doc_title
 G68_KNOWN doc_section
 G68_KNOWN markdown
 G68_KNOWN admonition
 G68_KNOWN example
 G68_KNOWN definition
 G68_KNOWN toc
 G68_KNOWN link
 G68_KNOWN anchor
 G68_KNOWN width_cells
 G68_KNOWN wrap_words
 G68_KNOWN align_left
 G68_KNOWN align_center
 G68_KNOWN align_right
 G68_KNOWN layout_conformance
 G68_KNOWN validate
 G68_KNOWN write
 G68_KNOWN console
 G68_KNOWN deterministic
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret
%undef G68_KNOWN

; RDI dot-token index -> EAX boolean for exact bounded arity.
g68_validate_call:
 push rbx
 push r12
 mov rbx,rdi
 lea r12,[rbx+1]
%macro G68_ARG_MATCH 2
 mov rdi,r12
 lea rsi,[rel g68_n_%1]
 mov edx,g68_n_%1_len
 call ls_token_match
 test eax,eax
 jnz %2
%endmacro
 G68_ARG_MATCH indent,.integer
 G68_ARG_MATCH outdent,.integer
 G68_ARG_MATCH width,.integer
 G68_ARG_MATCH margin,.integer
 G68_ARG_MATCH padding,.integer
 G68_ARG_MATCH limit,.integer
 G68_ARG_MATCH first,.integer
 G68_ARG_MATCH last,.integer
 G68_ARG_MATCH sample,.integer
 G68_ARG_MATCH width_cells,.integer
 G68_ARG_MATCH headers,.text
 G68_ARG_MATCH columns,.text
 G68_ARG_MATCH align,.text
 G68_ARG_MATCH sort_by,.text
 G68_ARG_MATCH prefix_items,.text
 G68_ARG_MATCH suffix_items,.text
 G68_ARG_MATCH group_by,.text
 G68_ARG_MATCH filter_shown,.text
 G68_ARG_MATCH admonition,.text
 G68_ARG_MATCH link,.text
 G68_ARG_MATCH anchor,.text
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
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
 cmp rdx,G68_MAX_ARGUMENT
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
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
 cmp rdx,G68_MAX_PAYLOAD+2
 ja .bad
 lea rdi,[rbx+4]
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
%undef G68_ARG_MATCH

g68_select_mode:
 G68_REQUIRE layout_conformance,.not_s07
 G68_REQUIRE validate,.not_s07
 G68_REQUIRE write,.not_s07
 G68_REQUIRE console,.not_s07
 G68_REQUIRE deterministic,.not_s07
 mov eax,7
 ret
.not_s07:
 G68_REQUIRE width_cells,.not_s06
 G68_REQUIRE wrap_words,.not_s06
 G68_REQUIRE align_left,.not_s06
 G68_REQUIRE align_center,.not_s06
 G68_REQUIRE align_right,.not_s06
 mov eax,6
 ret
.not_s06:
 G68_REQUIRE doc_title,.not_s05
 G68_REQUIRE doc_section,.not_s05
 G68_REQUIRE markdown,.not_s05
 G68_REQUIRE admonition,.not_s05
 G68_REQUIRE example,.not_s05
 G68_REQUIRE definition,.not_s05
 G68_REQUIRE toc,.not_s05
 G68_REQUIRE link,.not_s05
 G68_REQUIRE anchor,.not_s05
 mov eax,5
 ret
.not_s05:
 G68_REQUIRE each_line,.not_s04
 G68_REQUIRE inline,.not_s04
 G68_REQUIRE summary,.not_s04
 G68_REQUIRE count,.not_s04
 G68_REQUIRE first,.not_s04
 G68_REQUIRE last,.not_s04
 G68_REQUIRE limit,.not_s04
 G68_REQUIRE sample,.not_s04
 G68_REQUIRE sort,.not_s04
 G68_REQUIRE group_by,.not_s04
 G68_REQUIRE filter_shown,.not_s04
 mov eax,4
 ret
.not_s04:
 G68_REQUIRE list,.not_s03
 G68_REQUIRE ordered,.not_s03
 G68_REQUIRE unordered,.not_s03
 G68_REQUIRE bullets,.not_s03
 G68_REQUIRE checklist,.not_s03
 G68_REQUIRE numbered,.not_s03
 G68_REQUIRE tree,.not_s03
 G68_REQUIRE inline,.not_s03
 G68_REQUIRE multi_line,.not_s03
 G68_REQUIRE prefix_items,.not_s03
 G68_REQUIRE suffix_items,.not_s03
 mov eax,3
 ret
.not_s03:
 G68_REQUIRE table,.not_s02
 G68_REQUIRE headers,.not_s02
 G68_REQUIRE columns,.not_s02
 G68_REQUIRE align,.not_s02
 G68_REQUIRE border,.not_s02
 G68_REQUIRE no_border,.not_s02
 G68_REQUIRE compact,.not_s02
 G68_REQUIRE pretty,.not_s02
 G68_REQUIRE csv,.not_s02
 G68_REQUIRE tsv,.not_s02
 G68_REQUIRE markdown_table,.not_s02
 G68_REQUIRE sort_by,.not_s02
 G68_REQUIRE limit,.not_s02
 G68_REQUIRE summary,.not_s02
 G68_REQUIRE totals,.not_s02
 mov eax,2
 ret
.not_s02:
 G68_REQUIRE title,.not_s01
 G68_REQUIRE subtitle,.not_s01
 G68_REQUIRE section,.not_s01
 G68_REQUIRE subsection,.not_s01
 G68_REQUIRE paragraph,.not_s01
 G68_REQUIRE quote,.not_s01
 G68_REQUIRE line,.not_s01
 G68_REQUIRE hr,.not_s01
 G68_REQUIRE line_before,.not_s01
 G68_REQUIRE line_after,.not_s01
 G68_REQUIRE indent,.not_s01
 G68_REQUIRE outdent,.not_s01
 G68_REQUIRE center,.not_s01
 G68_REQUIRE left,.not_s01
 G68_REQUIRE right,.not_s01
 G68_REQUIRE width,.not_s01
 G68_REQUIRE margin,.not_s01
 G68_REQUIRE padding,.not_s01
 G68_REQUIRE box,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g68_scan_program:
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
 cmp rdx,G68_MIN_SEED
 jb .next
 mov rax,G68_MAX_SEED
 cmp rdx,rax
 ja .unsupported
 cmp qword [rel g68_seed_seen],0
 jne .unsupported
 mov qword [rel g68_seed_seen],1
 mov [rel g68_seed],rdx
 jmp .next
.text:
 cmp eax,NEBOC_TOKEN_TEXT
 jne .dot
 mov rdi,rbx
 call ls_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,G68_MAX_PAYLOAD+2
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
 call g68_known_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g68_validate_call
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
 cmp qword [rel g68_seed_seen],1
 jne .unsupported
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return: pop rbx
 ret

neboc_g068_source_parse:
 mov qword [rel g68_mode],0
 mov qword [rel g68_seed],0
 mov qword [rel g68_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g68_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g68_mode],rax
 call g68_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g68_mode]
 shl rax,32
 mov edi,dword [rel g68_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G68_FAMILY_KEY
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

%undef G68_REQUIRE
