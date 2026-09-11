; G008 canonical public-source owner. Complete subgroup surface sets select one
; associative-collection family; fixture paths and filenames are never read.
%include "compiler/semantic/collections/hash_map_contract.inc"
%define G8_FAMILY_KEY 0x5246323034473038

section .rodata
%macro G8_NAME 2
g8_n_%1: db %2
g8_n_%1_len equ $-g8_n_%1
%endmacro
G8_NAME dict,'Dict'
G8_NAME set_type,'Set'
G8_NAME hasher,'Hasher'
G8_NAME hash_namespace,'hash'
G8_NAME equals,'equals'
G8_NAME hash,'hash'
G8_NAME new,'new'
G8_NAME write_bytes,'writeBytes'
G8_NAME finish,'finish'
G8_NAME hash_stable,'hashStable'
G8_NAME with_capacity,'withCapacity'
G8_NAME length,'length'
G8_NAME capacity,'capacity'
G8_NAME reserve,'reserve'
G8_NAME load_factor,'loadFactor'
G8_NAME insert,'insert'
G8_NAME get,'get'
G8_NAME get_mutable,'getMutable'
G8_NAME contains_key,'containsKey'
G8_NAME remove,'remove'
G8_NAME entry,'entry'
G8_NAME clear,'clear'
G8_NAME keys,'keys'
G8_NAME values,'values'
G8_NAME entries,'entries'
G8_NAME iteration_order,'iterationOrder'
G8_NAME to_sorted_entries,'toSortedEntries'
G8_NAME retain,'retain'
G8_NAME contains,'contains'
G8_NAME union,'union'
G8_NAME intersection,'intersection'
G8_NAME difference,'difference'
G8_NAME is_subset_of,'isSubsetOf'
G8_NAME reseed,'reseed'
G8_NAME collision_count,'collisionCount'
G8_NAME max_probe_length,'maxProbeLength'
G8_NAME randomized,'randomized'
G8_NAME deterministic,'deterministic'
G8_NAME validate_invariants,'validateInvariants'
%undef G8_NAME

section .bss align=16
g8_mode: resq 1
g8_seed: resq 1

section .text
%macro G8_REQUIRE 2
 lea rsi,[rel g8_n_%1]
 mov edx,g8_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

; RDI token index -> EAX whether a called member is part of the G008 contract.
g8_known_call:
 push rbx
 mov rbx,rdi
%macro G8_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g8_n_%1]
 mov edx,g8_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G8_KNOWN equals
 G8_KNOWN hash
 G8_KNOWN new
 G8_KNOWN write_bytes
 G8_KNOWN finish
 G8_KNOWN hash_stable
 G8_KNOWN with_capacity
 G8_KNOWN length
 G8_KNOWN capacity
 G8_KNOWN reserve
 G8_KNOWN load_factor
 G8_KNOWN insert
 G8_KNOWN get
 G8_KNOWN get_mutable
 G8_KNOWN contains_key
 G8_KNOWN remove
 G8_KNOWN entry
 G8_KNOWN clear
 G8_KNOWN keys
 G8_KNOWN values
 G8_KNOWN entries
 G8_KNOWN iteration_order
 G8_KNOWN to_sorted_entries
 G8_KNOWN retain
 G8_KNOWN contains
 G8_KNOWN union
 G8_KNOWN intersection
 G8_KNOWN difference
 G8_KNOWN is_subset_of
 G8_KNOWN reseed
 G8_KNOWN collision_count
 G8_KNOWN max_probe_length
 G8_KNOWN randomized
 G8_KNOWN deterministic
 G8_KNOWN validate_invariants
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G8_KNOWN

; Full surface membership prevents comments or single method names from
; claiming a subgroup. The most specific families are checked first.
g8_select_mode:
 G8_REQUIRE dict,.not_s06
 G8_REQUIRE hash_namespace,.not_s06
 G8_REQUIRE reseed,.not_s06
 G8_REQUIRE collision_count,.not_s06
 G8_REQUIRE max_probe_length,.not_s06
 G8_REQUIRE randomized,.not_s06
 G8_REQUIRE deterministic,.not_s06
 G8_REQUIRE validate_invariants,.not_s06
 mov eax,6
 ret
.not_s06:
 G8_REQUIRE set_type,.not_s05
 G8_REQUIRE new,.not_s05
 G8_REQUIRE insert,.not_s05
 G8_REQUIRE contains,.not_s05
 G8_REQUIRE remove,.not_s05
 G8_REQUIRE union,.not_s05
 G8_REQUIRE intersection,.not_s05
 G8_REQUIRE difference,.not_s05
 G8_REQUIRE is_subset_of,.not_s05
 mov eax,5
 ret
.not_s05:
 G8_REQUIRE dict,.not_s04
 G8_REQUIRE keys,.not_s04
 G8_REQUIRE values,.not_s04
 G8_REQUIRE entries,.not_s04
 G8_REQUIRE iteration_order,.not_s04
 G8_REQUIRE to_sorted_entries,.not_s04
 G8_REQUIRE retain,.not_s04
 mov eax,4
 ret
.not_s04:
 G8_REQUIRE dict,.not_s03
 G8_REQUIRE insert,.not_s03
 G8_REQUIRE get,.not_s03
 G8_REQUIRE get_mutable,.not_s03
 G8_REQUIRE contains_key,.not_s03
 G8_REQUIRE remove,.not_s03
 G8_REQUIRE entry,.not_s03
 G8_REQUIRE clear,.not_s03
 mov eax,3
 ret
.not_s03:
 G8_REQUIRE dict,.not_s02
 G8_REQUIRE new,.not_s02
 G8_REQUIRE with_capacity,.not_s02
 G8_REQUIRE length,.not_s02
 G8_REQUIRE capacity,.not_s02
 G8_REQUIRE reserve,.not_s02
 G8_REQUIRE load_factor,.not_s02
 mov eax,2
 ret
.not_s02:
 G8_REQUIRE hasher,.not_s01
 G8_REQUIRE equals,.not_s01
 G8_REQUIRE hash,.not_s01
 G8_REQUIRE new,.not_s01
 G8_REQUIRE write_bytes,.not_s01
 G8_REQUIRE finish,.not_s01
 G8_REQUIRE hash_stable,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

; The shared lexer has already produced the canonical token stream. This pass
; validates called members, bounded capacities and a source-derived oracle.
g8_scan_program:
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
 cmp qword [rel g8_seed],0
 jne .next
 test rdx,rdx
 jz .next
 mov [rel g8_seed],rdx
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
 call g8_known_call
 test eax,eax
 jz .unsupported
 lea rdi,[rbx+1]
 lea rsi,[rel g8_n_with_capacity]
 mov edx,g8_n_with_capacity_len
 call ls_token_match
 test eax,eax
 jz .next
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .type
 lea rdi,[rbx+3]
 call ls_token_ptr
 mov rax,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rax,NEBO_DICT_MIN_CAPACITY
 jb .limit
 cmp rax,NEBO_DICT_MAX_CAPACITY
 ja .limit
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
 cmp qword [rel g8_seed],0
 je .syntax
 xor eax,eax
 jmp .return
.syntax:
 mov eax,20
 jmp .return
.type:
 mov eax,21
 jmp .return
.limit:
 mov eax,23
 jmp .return
.unsupported:
 mov eax,24
.return:
 pop rbx
 ret

neboc_g008_source_parse:
 mov qword [rel g8_mode],0
 mov qword [rel g8_seed],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g8_select_mode
 test eax,eax
 jz .syntax
 mov [rel g8_mode],rax
 call g8_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g8_mode]
 shl rax,32
 mov edi,dword [rel g8_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G8_FAMILY_KEY
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

%undef G8_REQUIRE
