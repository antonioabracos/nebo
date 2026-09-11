; G009 canonical public-source owner for bounded Node, Tree and Graph families.
%define G9_FAMILY_KEY 0x5246323034473039

section .rodata
%macro G9_NAME 2
g9_n_%1: db %2
g9_n_%1_len equ $-g9_n_%1
%endmacro
G9_NAME node,'Node'
G9_NAME tree,'Tree'
G9_NAME graph,'Graph'
G9_NAME new,'new'
G9_NAME id,'id'
G9_NAME value,'value'
G9_NAME replace_value,'replaceValue'
G9_NAME degree,'degree'
G9_NAME root,'root'
G9_NAME add_child,'addChild'
G9_NAME remove_subtree,'removeSubtree'
G9_NAME parent,'parent'
G9_NAME children,'children'
G9_NAME height,'height'
G9_NAME directed,'directed'
G9_NAME undirected,'undirected'
G9_NAME add_node,'addNode'
G9_NAME add_edge,'addEdge'
G9_NAME remove_node,'removeNode'
G9_NAME remove_edge,'removeEdge'
G9_NAME neighbors,'neighbors'
G9_NAME preorder,'preorder'
G9_NAME postorder,'postorder'
G9_NAME breadth_first,'breadthFirst'
G9_NAME depth_first,'depthFirst'
G9_NAME stop_when,'stopWhen'
G9_NAME path,'path'
G9_NAME has_cycle,'hasCycle'
G9_NAME topological_sort,'topologicalSort'
G9_NAME shortest_unweighted,'shortestPathUnweighted'
G9_NAME dijkstra,'dijkstra'
G9_NAME connected_components,'connectedComponents'
G9_NAME lowest_common_ancestor,'lowestCommonAncestor'
%undef G9_NAME

section .bss align=16
g9_mode: resq 1
g9_seed: resq 1

section .text
%macro G9_REQUIRE 2
 lea rsi,[rel g9_n_%1]
 mov edx,g9_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g9_known_call:
 push rbx
 mov rbx,rdi
%macro G9_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g9_n_%1]
 mov edx,g9_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G9_KNOWN new
 G9_KNOWN id
 G9_KNOWN value
 G9_KNOWN replace_value
 G9_KNOWN degree
 G9_KNOWN root
 G9_KNOWN add_child
 G9_KNOWN remove_subtree
 G9_KNOWN parent
 G9_KNOWN children
 G9_KNOWN height
 G9_KNOWN directed
 G9_KNOWN undirected
 G9_KNOWN add_node
 G9_KNOWN add_edge
 G9_KNOWN remove_node
 G9_KNOWN remove_edge
 G9_KNOWN neighbors
 G9_KNOWN preorder
 G9_KNOWN postorder
 G9_KNOWN breadth_first
 G9_KNOWN depth_first
 G9_KNOWN stop_when
 G9_KNOWN path
 G9_KNOWN has_cycle
 G9_KNOWN topological_sort
 G9_KNOWN shortest_unweighted
 G9_KNOWN dijkstra
 G9_KNOWN connected_components
 G9_KNOWN lowest_common_ancestor
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G9_KNOWN

; Complete surface sets claim one subgroup. Specific algorithm/traversal
; families precede the structural constructors they compose.
g9_select_mode:
 G9_REQUIRE graph,.not_s05
 G9_REQUIRE has_cycle,.not_s05
 G9_REQUIRE topological_sort,.not_s05
 G9_REQUIRE shortest_unweighted,.not_s05
 G9_REQUIRE dijkstra,.not_s05
 G9_REQUIRE connected_components,.not_s05
 G9_REQUIRE lowest_common_ancestor,.not_s05
 mov eax,5
 ret
.not_s05:
 G9_REQUIRE tree,.not_s04
 G9_REQUIRE graph,.not_s04
 G9_REQUIRE preorder,.not_s04
 G9_REQUIRE postorder,.not_s04
 G9_REQUIRE breadth_first,.not_s04
 G9_REQUIRE depth_first,.not_s04
 G9_REQUIRE stop_when,.not_s04
 G9_REQUIRE path,.not_s04
 mov eax,4
 ret
.not_s04:
 G9_REQUIRE graph,.not_s03
 G9_REQUIRE directed,.not_s03
 G9_REQUIRE undirected,.not_s03
 G9_REQUIRE add_node,.not_s03
 G9_REQUIRE add_edge,.not_s03
 G9_REQUIRE remove_node,.not_s03
 G9_REQUIRE remove_edge,.not_s03
 G9_REQUIRE neighbors,.not_s03
 mov eax,3
 ret
.not_s03:
 G9_REQUIRE tree,.not_s02
 G9_REQUIRE new,.not_s02
 G9_REQUIRE root,.not_s02
 G9_REQUIRE add_child,.not_s02
 G9_REQUIRE remove_subtree,.not_s02
 G9_REQUIRE parent,.not_s02
 G9_REQUIRE children,.not_s02
 G9_REQUIRE height,.not_s02
 mov eax,2
 ret
.not_s02:
 G9_REQUIRE node,.not_s01
 G9_REQUIRE new,.not_s01
 G9_REQUIRE id,.not_s01
 G9_REQUIRE value,.not_s01
 G9_REQUIRE replace_value,.not_s01
 G9_REQUIRE degree,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g9_scan_program:
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
 cmp qword [rel g9_seed],0
 jne .next
 test rdx,rdx
 jz .next
 mov [rel g9_seed],rdx
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
 call g9_known_call
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
 cmp qword [rel g9_seed],0
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

neboc_g009_source_parse:
 mov qword [rel g9_mode],0
 mov qword [rel g9_seed],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g9_select_mode
 test eax,eax
 jz .syntax
 mov [rel g9_mode],rax
 call g9_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g9_mode]
 shl rax,32
 mov edi,dword [rel g9_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G9_FAMILY_KEY
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

%undef G9_REQUIRE
