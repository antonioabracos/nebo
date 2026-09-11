; Canonical public-source owner for bounded reactive signals, cells,
; computations, incremental collections, dataflow graphs and observation.
%define G31_FAMILY_KEY 0x5246323034473331

section .rodata
%macro G31_NAME 2
g31_n_%1: db %2
g31_n_%1_len equ $-g31_n_%1
%endmacro
G31_NAME signal_type,'Signal'
G31_NAME signal,'signal'
G31_NAME of,'of'
G31_NAME value,'value'
G31_NAME map,'map'
G31_NAME combine,'combine'
G31_NAME distinct,'distinct'
G31_NAME changes,'changes'
G31_NAME subscribe,'subscribe'
G31_NAME cancel,'cancel'
G31_NAME cell_type,'Cell'
G31_NAME mutable,'mutable'
G31_NAME set,'set'
G31_NAME update,'update'
G31_NAME reactive_type,'Reactive'
G31_NAME transaction,'transaction'
G31_NAME commit,'commit'
G31_NAME rollback,'rollback'
G31_NAME changed_cells,'changedCells'
G31_NAME version,'version'
G31_NAME computed_type,'Computed'
G31_NAME from,'from'
G31_NAME invalidate,'invalidate'
G31_NAME recompute,'recompute'
G31_NAME dependencies,'dependencies'
G31_NAME dependents,'dependents'
G31_NAME why_changed,'whyChanged'
G31_NAME cache_policy,'cachePolicy'
G31_NAME reactive_list_type,'ReactiveList'
G31_NAME delta,'delta'
G31_NAME incremental_map,'incrementalMap'
G31_NAME incremental_filter,'incrementalFilter'
G31_NAME incremental_sort,'incrementalSort'
G31_NAME patch,'patch'
G31_NAME reactive_dict_type,'ReactiveDict'
G31_NAME invert,'invert'
G31_NAME dataflow_graph_type,'DataflowGraph'
G31_NAME new,'new'
G31_NAME source,'source'
G31_NAME node,'node'
G31_NAME connect,'connect'
G31_NAME compile,'compile'
G31_NAME run,'run'
G31_NAME snapshot,'snapshot'
G31_NAME restore,'restore'
G31_NAME reactive,'reactive'
G31_NAME trace,'trace'
G31_NAME graph_report,'graphReport'
G31_NAME persist,'persist'
G31_NAME stream_type,'Stream'
G31_NAME to_signal,'toSignal'
G31_NAME to_stream,'toStream'
G31_NAME await_stable,'awaitStable'
%undef G31_NAME

section .bss align=16
g31_mode: resq 1
g31_seed: resq 1

section .text
%macro G31_REQUIRE 2
 lea rsi,[rel g31_n_%1]
 mov edx,g31_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

; A dotted call belongs to this vertical only when it is one of the public
; calls above. This keeps malformed or invented operations out of codegen.
g31_known_call:
 push rbx
 mov rbx,rdi
%macro G31_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g31_n_%1]
 mov edx,g31_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G31_KNOWN of
 G31_KNOWN value
 G31_KNOWN map
 G31_KNOWN combine
 G31_KNOWN distinct
 G31_KNOWN changes
 G31_KNOWN subscribe
 G31_KNOWN cancel
 G31_KNOWN mutable
 G31_KNOWN set
 G31_KNOWN update
 G31_KNOWN transaction
 G31_KNOWN commit
 G31_KNOWN rollback
 G31_KNOWN changed_cells
 G31_KNOWN version
 G31_KNOWN from
 G31_KNOWN invalidate
 G31_KNOWN recompute
 G31_KNOWN dependencies
 G31_KNOWN dependents
 G31_KNOWN why_changed
 G31_KNOWN cache_policy
 G31_KNOWN delta
 G31_KNOWN incremental_map
 G31_KNOWN incremental_filter
 G31_KNOWN incremental_sort
 G31_KNOWN patch
 G31_KNOWN invert
 G31_KNOWN new
 G31_KNOWN source
 G31_KNOWN node
 G31_KNOWN connect
 G31_KNOWN compile
 G31_KNOWN run
 G31_KNOWN snapshot
 G31_KNOWN restore
 G31_KNOWN trace
 G31_KNOWN graph_report
 G31_KNOWN persist
 G31_KNOWN to_signal
 G31_KNOWN to_stream
 G31_KNOWN await_stable
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G31_KNOWN

g31_select_mode:
 G31_REQUIRE reactive,.not_s06
 G31_REQUIRE trace,.not_s06
 G31_REQUIRE graph_report,.not_s06
 G31_REQUIRE persist,.not_s06
 G31_REQUIRE restore,.not_s06
 G31_REQUIRE stream_type,.not_s06
 G31_REQUIRE to_signal,.not_s06
 G31_REQUIRE to_stream,.not_s06
 G31_REQUIRE await_stable,.not_s06
 mov eax,6
 ret
.not_s06:
 G31_REQUIRE dataflow_graph_type,.not_s05
 G31_REQUIRE new,.not_s05
 G31_REQUIRE source,.not_s05
 G31_REQUIRE node,.not_s05
 G31_REQUIRE connect,.not_s05
 G31_REQUIRE compile,.not_s05
 G31_REQUIRE run,.not_s05
 G31_REQUIRE snapshot,.not_s05
 G31_REQUIRE restore,.not_s05
 mov eax,5
 ret
.not_s05:
 G31_REQUIRE reactive_list_type,.not_s04
 G31_REQUIRE from,.not_s04
 G31_REQUIRE delta,.not_s04
 G31_REQUIRE incremental_map,.not_s04
 G31_REQUIRE incremental_filter,.not_s04
 G31_REQUIRE incremental_sort,.not_s04
 G31_REQUIRE patch,.not_s04
 G31_REQUIRE reactive_dict_type,.not_s04
 G31_REQUIRE invert,.not_s04
 mov eax,4
 ret
.not_s04:
 G31_REQUIRE computed_type,.not_s03
 G31_REQUIRE from,.not_s03
 G31_REQUIRE value,.not_s03
 G31_REQUIRE invalidate,.not_s03
 G31_REQUIRE recompute,.not_s03
 G31_REQUIRE dependencies,.not_s03
 G31_REQUIRE dependents,.not_s03
 G31_REQUIRE why_changed,.not_s03
 G31_REQUIRE cache_policy,.not_s03
 mov eax,3
 ret
.not_s03:
 G31_REQUIRE cell_type,.not_s02
 G31_REQUIRE mutable,.not_s02
 G31_REQUIRE set,.not_s02
 G31_REQUIRE update,.not_s02
 G31_REQUIRE reactive_type,.not_s02
 G31_REQUIRE transaction,.not_s02
 G31_REQUIRE commit,.not_s02
 G31_REQUIRE rollback,.not_s02
 G31_REQUIRE changed_cells,.not_s02
 G31_REQUIRE version,.not_s02
 mov eax,2
 ret
.not_s02:
 G31_REQUIRE signal_type,.not_s01
 G31_REQUIRE of,.not_s01
 G31_REQUIRE value,.not_s01
 G31_REQUIRE map,.not_s01
 G31_REQUIRE combine,.not_s01
 G31_REQUIRE distinct,.not_s01
 G31_REQUIRE changes,.not_s01
 G31_REQUIRE subscribe,.not_s01
 G31_REQUIRE cancel,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g31_scan_program:
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
 cmp qword [rel g31_seed],0
 jne .next
 test rdx,rdx
 jz .next
 mov [rel g31_seed],rdx
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
 call g31_known_call
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
 cmp qword [rel g31_seed],0
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

neboc_g031_source_parse:
 mov qword [rel g31_mode],0
 mov qword [rel g31_seed],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g31_select_mode
 test eax,eax
 jz .syntax
 mov [rel g31_mode],rax
 call g31_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g31_mode]
 shl rax,32
 mov edi,dword [rel g31_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G31_FAMILY_KEY
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

%undef G31_REQUIRE
