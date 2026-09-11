; G010 canonical public-source owner for bounded typed data and finite streams.
%define G10_FAMILY_KEY 0x5246323034473130

section .rodata
%macro G10_NAME 2
g10_n_%1: db %2
g10_n_%1_len equ $-g10_n_%1
%endmacro
G10_NAME schema_type,'Schema'
G10_NAME row_type,'Row'
G10_NAME column_type,'Column'
G10_NAME table_type,'Table'
G10_NAME dataset_type,'Dataset'
G10_NAME event_type,'Event'
G10_NAME flow_type,'Flow'
G10_NAME stream_type,'Stream'
G10_NAME new,'new'
G10_NAME field,'field'
G10_NAME index_of,'indexOf'
G10_NAME from,'from'
G10_NAME get,'get'
G10_NAME project,'project'
G10_NAME to_tuple,'toTuple'
G10_NAME sum,'sum'
G10_NAME min,'min'
G10_NAME max,'max'
G10_NAME count_missing,'countMissing'
G10_NAME cast,'cast'
G10_NAME from_columns,'fromColumns'
G10_NAME row_count,'rowCount'
G10_NAME column_count,'columnCount'
G10_NAME select,'select'
G10_NAME filter,'filter'
G10_NAME sort_by,'sortBy'
G10_NAME group_by,'groupBy'
G10_NAME join,'join'
G10_NAME is_missing,'isMissing'
G10_NAME fill_missing,'fillMissing'
G10_NAME drop_missing,'dropMissing'
G10_NAME coalesce,'coalesce'
G10_NAME validate,'validate'
G10_NAME invalid_rows,'invalidRows'
G10_NAME from_tables,'fromTables'
G10_NAME schema,'schema'
G10_NAME partition_count,'partitionCount'
G10_NAME repartition,'repartition'
G10_NAME scan,'scan'
G10_NAME collect,'collect'
G10_NAME cache,'cache'
G10_NAME value,'value'
G10_NAME map,'map'
G10_NAME batch,'batch'
G10_NAME window,'window'
G10_NAME sink,'sink'
%undef G10_NAME

section .bss align=16
g10_mode: resq 1
g10_seed: resq 1

section .text
%macro G10_REQUIRE 2
 lea rsi,[rel g10_n_%1]
 mov edx,g10_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g10_known_call:
 push rbx
 mov rbx,rdi
%macro G10_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g10_n_%1]
 mov edx,g10_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G10_KNOWN new
 G10_KNOWN field
 G10_KNOWN index_of
 G10_KNOWN from
 G10_KNOWN get
 G10_KNOWN project
 G10_KNOWN to_tuple
 G10_KNOWN sum
 G10_KNOWN min
 G10_KNOWN max
 G10_KNOWN count_missing
 G10_KNOWN cast
 G10_KNOWN from_columns
 G10_KNOWN row_count
 G10_KNOWN column_count
 G10_KNOWN select
 G10_KNOWN filter
 G10_KNOWN sort_by
 G10_KNOWN group_by
 G10_KNOWN join
 G10_KNOWN is_missing
 G10_KNOWN fill_missing
 G10_KNOWN drop_missing
 G10_KNOWN coalesce
 G10_KNOWN validate
 G10_KNOWN invalid_rows
 G10_KNOWN from_tables
 G10_KNOWN schema
 G10_KNOWN partition_count
 G10_KNOWN repartition
 G10_KNOWN scan
 G10_KNOWN collect
 G10_KNOWN cache
 G10_KNOWN value
 G10_KNOWN map
 G10_KNOWN filter
 G10_KNOWN batch
 G10_KNOWN window
 G10_KNOWN sink
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G10_KNOWN

; Select only complete current-contract surface sets.  This keeps historical
; bounded Column/Event/Flow programs under their original semantic owners.
g10_select_mode:
 G10_REQUIRE event_type,.not_s06
 G10_REQUIRE flow_type,.not_s06
 G10_REQUIRE stream_type,.not_s06
 G10_REQUIRE value,.not_s06
 G10_REQUIRE from,.not_s06
 G10_REQUIRE map,.not_s06
 G10_REQUIRE filter,.not_s06
 G10_REQUIRE batch,.not_s06
 G10_REQUIRE window,.not_s06
 G10_REQUIRE sink,.not_s06
 mov eax,6
 ret
.not_s06:
 G10_REQUIRE dataset_type,.not_s05
 G10_REQUIRE from_tables,.not_s05
 G10_REQUIRE schema,.not_s05
 G10_REQUIRE partition_count,.not_s05
 G10_REQUIRE repartition,.not_s05
 G10_REQUIRE scan,.not_s05
 G10_REQUIRE collect,.not_s05
 G10_REQUIRE cache,.not_s05
 mov eax,5
 ret
.not_s05:
 G10_REQUIRE column_type,.not_s04
 G10_REQUIRE table_type,.not_s04
 G10_REQUIRE is_missing,.not_s04
 G10_REQUIRE fill_missing,.not_s04
 G10_REQUIRE drop_missing,.not_s04
 G10_REQUIRE coalesce,.not_s04
 G10_REQUIRE validate,.not_s04
 G10_REQUIRE invalid_rows,.not_s04
 mov eax,4
 ret
.not_s04:
 G10_REQUIRE table_type,.not_s03
 G10_REQUIRE from_columns,.not_s03
 G10_REQUIRE row_count,.not_s03
 G10_REQUIRE column_count,.not_s03
 G10_REQUIRE select,.not_s03
 G10_REQUIRE filter,.not_s03
 G10_REQUIRE sort_by,.not_s03
 G10_REQUIRE group_by,.not_s03
 G10_REQUIRE join,.not_s03
 mov eax,3
 ret
.not_s03:
 G10_REQUIRE column_type,.not_s02
 G10_REQUIRE from,.not_s02
 G10_REQUIRE get,.not_s02
 G10_REQUIRE cast,.not_s02
 G10_REQUIRE sum,.not_s02
 G10_REQUIRE min,.not_s02
 G10_REQUIRE max,.not_s02
 G10_REQUIRE count_missing,.not_s02
 mov eax,2
 ret
.not_s02:
 G10_REQUIRE schema_type,.not_s01
 G10_REQUIRE row_type,.not_s01
 G10_REQUIRE new,.not_s01
 G10_REQUIRE field,.not_s01
 G10_REQUIRE index_of,.not_s01
 G10_REQUIRE from,.not_s01
 G10_REQUIRE get,.not_s01
 G10_REQUIRE project,.not_s01
 G10_REQUIRE to_tuple,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g10_scan_program:
 push rbx
 xor ebx,ebx
.scan:
 cmp rbx,[rel ls_token_count]
 jae .syntax
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_EOF
 je .done
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .dot
 mov rdi,rbx
 call ls_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp qword [rel g10_seed],0
 jne .next
 test rdx,rdx
 jz .next
 mov [rel g10_seed],rdx
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
 call g10_known_call
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
 cmp qword [rel g10_seed],0
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

neboc_g010_source_parse:
 mov qword [rel g10_mode],0
 mov qword [rel g10_seed],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g10_select_mode
 test eax,eax
 jz .syntax
 mov [rel g10_mode],rax
 call g10_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g10_mode]
 shl rax,32
 mov edi,dword [rel g10_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G10_FAMILY_KEY
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

%undef G10_REQUIRE
