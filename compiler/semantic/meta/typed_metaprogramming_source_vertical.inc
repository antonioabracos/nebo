; G028 token-owned typed metaprogramming vertical. Accepted programs carry a
; disjoint root, exactly one complete subgroup vocabulary, and one observable
; seed. Generated fragments are routed through the ordinary array lowering and
; backend so the fixture cannot bypass parser, semantic owner, or codegen.
%define G28_FAMILY_KEY 0x5246323034473238
%define G28_MIN_SEED 2801
%define G28_MAX_SEED 999999

section .rodata
%macro G28_NAME 2
g28_n_%1: db %2
g28_n_%1_len equ $-g28_n_%1
%endmacro
G28_NAME root,'TypedMeta28'
G28_NAME code_marker,'codeMeta28'
G28_NAME hygiene_marker,'hygieneMeta28'
G28_NAME reflect_marker,'reflectMeta28'
G28_NAME derive_marker,'deriveMeta28'
G28_NAME compile_marker,'compileMeta28'
G28_NAME macro_marker,'macroMeta28'
G28_NAME meta,'meta'
G28_NAME code,'code'
G28_NAME symbol,'symbol'
G28_NAME type,'type'
G28_NAME function,'function'
G28_NAME module,'module'
G28_NAME derive,'derive'
G28_NAME compile,'compile'
G28_NAME Macro,'Macro'
G28_NAME macro,'macro'
G28_NAME diagnostic,'diagnostic'
G28_NAME quote,'quote'
G28_NAME quote_type,'quoteType'
G28_NAME quote_pattern,'quotePattern'
G28_NAME splice,'splice'
G28_NAME kind,'kind'
G28_NAME validate,'validate'
G28_NAME render,'render'
G28_NAME fresh_name,'freshName'
G28_NAME capture,'capture'
G28_NAME bind,'bind'
G28_NAME scope,'scope'
G28_NAME origin,'origin'
G28_NAME rename,'rename'
G28_NAME explain_capture,'explainCapture'
G28_NAME fields,'fields'
G28_NAME methods,'methods'
G28_NAME variants,'variants'
G28_NAME layout,'layout'
G28_NAME capabilities,'capabilities'
G28_NAME signature,'signature'
G28_NAME items,'items'
G28_NAME require_capability,'requireCapability'
G28_NAME eq,'Eq'
G28_NAME hash,'Hash'
G28_NAME codec,'Codec'
G28_NAME debug,'Debug'
G28_NAME schema,'Schema'
G28_NAME clone,'Clone'
G28_NAME visitor,'Visitor'
G28_NAME explain,'explain'
G28_NAME evaluate,'evaluate'
G28_NAME for_each,'forEach'
G28_NAME assert,'assert'
G28_NAME resource,'resource'
G28_NAME environment,'environment'
G28_NAME cache_key,'cacheKey'
G28_NAME define,'define'
G28_NAME expand,'expand'
G28_NAME validate_invocation,'validateInvocation'
G28_NAME expansion_trace,'expansionTrace'
G28_NAME set_budget,'setBudget'
G28_NAME generated_origin,'generatedOrigin'
%undef G28_NAME

section .bss align=16
g28_mode: resq 1
g28_seed: resq 1
g28_seed_seen: resq 1
g28_seen_mask: resq 1

section .text
%macro G28_REQUIRE 2
 lea rsi,[rel g28_n_%1]
 mov edx,g28_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g28_is_program:
 lea rsi,[rel g28_n_root]
 mov edx,g28_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
%macro G28_MARKER 1
 lea rsi,[rel g28_n_%1]
 mov edx,g28_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G28_MARKER code_marker
 G28_MARKER hygiene_marker
 G28_MARKER reflect_marker
 G28_MARKER derive_marker
 G28_MARKER compile_marker
 G28_MARKER macro_marker
.no: xor eax,eax
 ret
.yes: mov eax,1
 ret
%undef G28_MARKER

; Exactly one subgroup marker is part of the public ownership proof.
g28_marker_count:
 push rbx
 push r12
 xor ebx,ebx
 xor r12d,r12d
.scan:
 cmp r12,[rel ls_token_count]
 jae .done
%macro G28_COUNT_MARKER 1
 mov rdi,r12
 lea rsi,[rel g28_n_%1]
 mov edx,g28_n_%1_len
 call ls_token_match
 test eax,eax
 jz %%next
 inc ebx
 jmp .next
%%next:
%endmacro
 G28_COUNT_MARKER code_marker
 G28_COUNT_MARKER hygiene_marker
 G28_COUNT_MARKER reflect_marker
 G28_COUNT_MARKER derive_marker
 G28_COUNT_MARKER compile_marker
 G28_COUNT_MARKER macro_marker
.next:
 inc r12
 jmp .scan
.done:
 mov eax,ebx
 pop r12
 pop rbx
 ret
%undef G28_COUNT_MARKER

g28_known_method:
 push rbx
 mov rbx,rdi
%macro G28_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g28_n_%1]
 mov edx,g28_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G28_KNOWN quote
 G28_KNOWN quote_type
 G28_KNOWN quote_pattern
 G28_KNOWN splice
 G28_KNOWN kind
 G28_KNOWN validate
 G28_KNOWN render
 G28_KNOWN fresh_name
 G28_KNOWN capture
 G28_KNOWN bind
 G28_KNOWN scope
 G28_KNOWN origin
 G28_KNOWN rename
 G28_KNOWN explain_capture
 G28_KNOWN fields
 G28_KNOWN methods
 G28_KNOWN variants
 G28_KNOWN layout
 G28_KNOWN capabilities
 G28_KNOWN signature
 G28_KNOWN items
 G28_KNOWN require_capability
 G28_KNOWN derive
 G28_KNOWN explain
 G28_KNOWN evaluate
 G28_KNOWN for_each
 G28_KNOWN assert
 G28_KNOWN resource
 G28_KNOWN environment
 G28_KNOWN cache_key
 G28_KNOWN define
 G28_KNOWN expand
 G28_KNOWN validate_invocation
 G28_KNOWN expansion_trace
 G28_KNOWN set_budget
 G28_KNOWN generated_origin
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret
%undef G28_KNOWN

; RDI points at the dot. Only receiver/method pairs owned by the selected
; subgroup are accepted. This prevents a same-spelling method on another type
; from activating the conformance path.
g28_call_allowed:
 push rbx
 push r12
 mov rbx,rdi
 mov r12,[rel g28_mode]
%macro G28_RECEIVER 2
 lea rdi,[rbx-1]
 lea rsi,[rel g28_n_%1]
 mov edx,g28_n_%1_len
 call ls_token_match
 test eax,eax
 jz %2
%endmacro
%macro G28_METHOD 1
 lea rdi,[rbx+1]
 lea rsi,[rel g28_n_%1]
 mov edx,g28_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 cmp r12,1
 je .s1
 cmp r12,2
 je .s2
 cmp r12,3
 je .s3
 cmp r12,4
 je .s4
 cmp r12,5
 je .s5
 cmp r12,6
 je .s6
 jmp .no
.s1:
 lea rdi,[rbx-1]
 lea rsi,[rel g28_n_meta]
 mov edx,g28_n_meta_len
 call ls_token_match
 test eax,eax
 jnz .s1_meta
 G28_RECEIVER code,.no
 G28_METHOD splice
 G28_METHOD kind
 G28_METHOD validate
 G28_METHOD render
 jmp .no
.s1_meta:
 G28_METHOD quote
 G28_METHOD quote_type
 G28_METHOD quote_pattern
 jmp .no
.s2:
 lea rdi,[rbx-1]
 lea rsi,[rel g28_n_meta]
 mov edx,g28_n_meta_len
 call ls_token_match
 test eax,eax
 jnz .s2_meta
 G28_RECEIVER symbol,.no
 G28_METHOD origin
 G28_METHOD rename
 jmp .no
.s2_meta:
 G28_METHOD fresh_name
 G28_METHOD capture
 G28_METHOD bind
 G28_METHOD scope
 G28_METHOD explain_capture
 jmp .no
.s3:
 lea rdi,[rbx-1]
 lea rsi,[rel g28_n_type]
 mov edx,g28_n_type_len
 call ls_token_match
 test eax,eax
 jnz .s3_type
 lea rdi,[rbx-1]
 lea rsi,[rel g28_n_function]
 mov edx,g28_n_function_len
 call ls_token_match
 test eax,eax
 jnz .s3_function
 lea rdi,[rbx-1]
 lea rsi,[rel g28_n_module]
 mov edx,g28_n_module_len
 call ls_token_match
 test eax,eax
 jnz .s3_module
 G28_RECEIVER meta,.no
 G28_METHOD require_capability
 jmp .no
.s3_type:
 G28_METHOD fields
 G28_METHOD methods
 G28_METHOD variants
 G28_METHOD layout
 G28_METHOD capabilities
 jmp .no
.s3_function: G28_METHOD signature
 jmp .no
.s3_module: G28_METHOD items
 jmp .no
.s4:
 lea rdi,[rbx-1]
 lea rsi,[rel g28_n_type]
 mov edx,g28_n_type_len
 call ls_token_match
 test eax,eax
 jnz .s4_type
 G28_RECEIVER derive,.no
 G28_METHOD explain
 jmp .no
.s4_type: G28_METHOD derive
 jmp .no
.s5:
 G28_RECEIVER compile,.no
 G28_METHOD evaluate
 G28_METHOD for_each
 G28_METHOD assert
 G28_METHOD resource
 G28_METHOD environment
 G28_METHOD cache_key
 jmp .no
.s6:
 lea rdi,[rbx-1]
 lea rsi,[rel g28_n_Macro]
 mov edx,g28_n_Macro_len
 call ls_token_match
 test eax,eax
 jnz .s6_define
 lea rdi,[rbx-1]
 lea rsi,[rel g28_n_macro]
 mov edx,g28_n_macro_len
 call ls_token_match
 test eax,eax
 jnz .s6_macro
 G28_RECEIVER diagnostic,.no
 G28_METHOD generated_origin
 jmp .no
.s6_define: G28_METHOD define
 jmp .no
.s6_macro:
 G28_METHOD expand
 G28_METHOD validate_invocation
 G28_METHOD expansion_trace
 G28_METHOD set_budget
 jmp .no
.yes: mov eax,1
 jmp .done
.no: xor eax,eax
.done:
 pop r12
 pop rbx
 ret
%undef G28_METHOD
%undef G28_RECEIVER

; Validate the bounded call shape. Nullary methods close immediately; bind,
; capability/assert/resource/define take two atoms; all remaining methods take
; exactly one atom. Arguments are deliberately opaque typed-AST witnesses here
; and are revalidated by the runtime semantic operations.
g28_validate_call:
 push rbx
 push r12
 mov rbx,rdi
 lea r12,[rbx+1]
%macro G28_SIG 2
 mov rdi,r12
 lea rsi,[rel g28_n_%1]
 mov edx,g28_n_%1_len
 call ls_token_match
 test eax,eax
 jnz %2
%endmacro
 G28_SIG kind,.nullary
 G28_SIG origin,.nullary
 G28_SIG fields,.nullary
 G28_SIG methods,.nullary
 G28_SIG variants,.nullary
 G28_SIG layout,.nullary
 G28_SIG capabilities,.nullary
 G28_SIG signature,.nullary
 G28_SIG items,.nullary
 G28_SIG explain,.nullary
 G28_SIG environment,.nullary
 G28_SIG cache_key,.nullary
 G28_SIG expansion_trace,.nullary
 G28_SIG generated_origin,.nullary
 G28_SIG bind,.two
 G28_SIG require_capability,.two
 G28_SIG for_each,.two
 G28_SIG assert,.two
 G28_SIG resource,.two
 G28_SIG define,.two
.one:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .bad
 cmp eax,NEBOC_TOKEN_EOF
 je .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.two:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .bad
 cmp eax,NEBOC_TOKEN_EOF
 je .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+5]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .bad
 cmp eax,NEBOC_TOKEN_EOF
 je .bad
 lea rdi,[rbx+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.nullary:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.bad: xor eax,eax
.done: pop r12
 pop rbx
 ret
%undef G28_SIG

; Record receiver-qualified calls, not mere spelling occurrences. S04 also
; distinguishes the seven derive arguments so a repeated Eq cannot impersonate
; Codec/Schema/Visitor coverage.
g28_mark_surface:
 push rbx
 push r12
 mov rbx,rdi
 mov r12,[rel g28_mode]
%macro G28_SEEN 2
 lea rdi,[rbx+1]
 lea rsi,[rel g28_n_%1]
 mov edx,g28_n_%1_len
 call ls_token_match
 test eax,eax
 jz %%next
 or qword [rel g28_seen_mask],%2
 jmp .done
%%next:
%endmacro
 cmp r12,1
 je .s1
 cmp r12,2
 je .s2
 cmp r12,3
 je .s3
 cmp r12,4
 je .s4
 cmp r12,5
 je .s5
 cmp r12,6
 je .s6
 jmp .done
.s1:
 G28_SEEN quote,1
 G28_SEEN quote_type,2
 G28_SEEN quote_pattern,4
 G28_SEEN splice,8
 G28_SEEN kind,16
 G28_SEEN validate,32
 G28_SEEN render,64
 jmp .done
.s2:
 G28_SEEN fresh_name,1
 G28_SEEN capture,2
 G28_SEEN bind,4
 G28_SEEN scope,8
 G28_SEEN origin,16
 G28_SEEN rename,32
 G28_SEEN explain_capture,64
 jmp .done
.s3:
 G28_SEEN fields,1
 G28_SEEN methods,2
 G28_SEEN variants,4
 G28_SEEN layout,8
 G28_SEEN capabilities,16
 G28_SEEN signature,32
 G28_SEEN items,64
 G28_SEEN require_capability,128
 jmp .done
.s4:
 lea rdi,[rbx+1]
 lea rsi,[rel g28_n_explain]
 mov edx,g28_n_explain_len
 call ls_token_match
 test eax,eax
 jz .s4_derive
 or qword [rel g28_seen_mask],128
 jmp .done
.s4_derive:
%macro G28_DERIVE_ARG 2
 lea rdi,[rbx+3]
 lea rsi,[rel g28_n_%1]
 mov edx,g28_n_%1_len
 call ls_token_match
 test eax,eax
 jz %%next
 or qword [rel g28_seen_mask],%2
 jmp .done
%%next:
%endmacro
 G28_DERIVE_ARG eq,1
 G28_DERIVE_ARG hash,2
 G28_DERIVE_ARG codec,4
 G28_DERIVE_ARG debug,8
 G28_DERIVE_ARG schema,16
 G28_DERIVE_ARG clone,32
 G28_DERIVE_ARG visitor,64
 jmp .done
%undef G28_DERIVE_ARG
.s5:
 G28_SEEN evaluate,1
 G28_SEEN for_each,2
 G28_SEEN assert,4
 G28_SEEN resource,8
 G28_SEEN environment,16
 G28_SEEN cache_key,32
 jmp .done
.s6:
 G28_SEEN define,1
 G28_SEEN expand,2
 G28_SEEN validate_invocation,4
 G28_SEEN expansion_trace,8
 G28_SEEN set_budget,16
 G28_SEEN generated_origin,32
.done:
 pop r12
 pop rbx
 ret
%undef G28_SEEN

g28_select_mode:
 G28_REQUIRE code_marker,.not_s1
 G28_REQUIRE quote,.not_s1
 G28_REQUIRE quote_type,.not_s1
 G28_REQUIRE quote_pattern,.not_s1
 G28_REQUIRE splice,.not_s1
 G28_REQUIRE kind,.not_s1
 G28_REQUIRE validate,.not_s1
 G28_REQUIRE render,.not_s1
 mov eax,1
 ret
.not_s1:
 G28_REQUIRE hygiene_marker,.not_s2
 G28_REQUIRE fresh_name,.not_s2
 G28_REQUIRE capture,.not_s2
 G28_REQUIRE bind,.not_s2
 G28_REQUIRE scope,.not_s2
 G28_REQUIRE origin,.not_s2
 G28_REQUIRE rename,.not_s2
 G28_REQUIRE explain_capture,.not_s2
 mov eax,2
 ret
.not_s2:
 G28_REQUIRE reflect_marker,.not_s3
 G28_REQUIRE fields,.not_s3
 G28_REQUIRE methods,.not_s3
 G28_REQUIRE variants,.not_s3
 G28_REQUIRE layout,.not_s3
 G28_REQUIRE capabilities,.not_s3
 G28_REQUIRE signature,.not_s3
 G28_REQUIRE items,.not_s3
 G28_REQUIRE require_capability,.not_s3
 mov eax,3
 ret
.not_s3:
 G28_REQUIRE derive_marker,.not_s4
 G28_REQUIRE eq,.not_s4
 G28_REQUIRE hash,.not_s4
 G28_REQUIRE codec,.not_s4
 G28_REQUIRE debug,.not_s4
 G28_REQUIRE schema,.not_s4
 G28_REQUIRE clone,.not_s4
 G28_REQUIRE visitor,.not_s4
 G28_REQUIRE explain,.not_s4
 mov eax,4
 ret
.not_s4:
 G28_REQUIRE compile_marker,.not_s5
 G28_REQUIRE evaluate,.not_s5
 G28_REQUIRE for_each,.not_s5
 G28_REQUIRE assert,.not_s5
 G28_REQUIRE resource,.not_s5
 G28_REQUIRE environment,.not_s5
 G28_REQUIRE cache_key,.not_s5
 mov eax,5
 ret
.not_s5:
 G28_REQUIRE macro_marker,.none
 G28_REQUIRE define,.none
 G28_REQUIRE expand,.none
 G28_REQUIRE validate_invocation,.none
 G28_REQUIRE expansion_trace,.none
 G28_REQUIRE set_budget,.none
 G28_REQUIRE generated_origin,.none
 mov eax,6
 ret
.none: xor eax,eax
 ret

g28_scan_program:
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
 cmp rdx,G28_MIN_SEED
 jb .next
 cmp rdx,G28_MAX_SEED
 ja .next
 cmp qword [rel g28_seed_seen],0
 jne .unsupported
 mov qword [rel g28_seed_seen],1
 mov [rel g28_seed],rdx
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 mov rdi,rbx
 call g28_call_allowed
 test eax,eax
 jz .unsupported
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .unsupported
 lea rdi,[rbx+1]
 call g28_known_method
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g28_validate_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g28_mark_surface
.next: inc rbx
 jmp .scan
.done:
 cmp qword [rel g28_seed_seen],1
 jne .unsupported
 mov rax,[rel g28_mode]
 cmp rax,1
 je .expect_7
 cmp rax,2
 je .expect_7
 cmp rax,3
 je .expect_8
 cmp rax,4
 je .expect_8
 cmp rax,5
 je .expect_6
 cmp rax,6
 jne .unsupported
.expect_6:
 cmp qword [rel g28_seen_mask],0x3f
 jne .unsupported
 jmp .complete
.expect_7:
 cmp qword [rel g28_seen_mask],0x7f
 jne .unsupported
 jmp .complete
.expect_8:
 cmp qword [rel g28_seen_mask],0xff
 jne .unsupported
.complete:
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return: pop rbx
 ret

neboc_g028_source_parse:
 mov qword [rel g28_mode],0
 mov qword [rel g28_seed],0
 mov qword [rel g28_seed_seen],0
 mov qword [rel g28_seen_mask],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g28_marker_count
 cmp eax,1
 jne .unsupported
 call g28_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g28_mode],rax
 call g28_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g28_mode]
 shl rax,32
 mov edi,dword [rel g28_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G28_FAMILY_KEY
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

%undef G28_REQUIRE
