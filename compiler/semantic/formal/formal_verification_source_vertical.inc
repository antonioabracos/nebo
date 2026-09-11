; G029 token-owned bounded formal-verification vertical. The parser requires a
; disjoint root, exactly one subgroup marker, every surface in that subgroup,
; receiver/arity ownership, and one observable source seed before lowering.
%define G29_FAMILY_KEY 0x5246323034473239
%define G29_MIN_SEED 2901
%define G29_MAX_SEED 999999

section .rodata
%macro G29_NAME 2
g29_n_%1: db %2
g29_n_%1_len equ $-g29_n_%1
%endmacro
G29_NAME root,'FormalVerification29'
G29_NAME contract_marker,'contractCase29'
G29_NAME refinement_marker,'refinementCase29'
G29_NAME obligation_marker,'obligationCase29'
G29_NAME model_marker,'modelCase29'
G29_NAME proof_marker,'proofCase29'
G29_NAME tooling_marker,'toolingCase29'
G29_NAME requires,'requires'
G29_NAME ensures,'ensures'
G29_NAME invariant,'invariant'
G29_NAME modifies,'modifies'
G29_NAME decreases,'decreases'
G29_NAME refined_kw,'refined'
G29_NAME where_kw,'where'
G29_NAME assume_kw,'assume'
G29_NAME contract,'contract'
G29_NAME check_runtime,'checkAtRuntime'
G29_NAME explain,'explain'
G29_NAME input_value,'inputValue'
G29_NAME refine,'refine'
G29_NAME is,'is'
G29_NAME refined_value,'refinedValue'
G29_NAME base,'base'
G29_NAME refinement,'refinement'
G29_NAME predicate,'predicate'
G29_NAME explain_failure,'explainFailure'
G29_NAME verify,'verify'
G29_NAME function,'function'
G29_NAME module,'module'
G29_NAME no_overflow,'noOverflow'
G29_NAME no_bounds,'noOutOfBounds'
G29_NAME no_leak,'noLeak'
G29_NAME effects_within,'effectsWithin'
G29_NAME verification,'verification'
G29_NAME obligations,'obligations'
G29_NAME Model,'Model'
G29_NAME state,'state'
G29_NAME model,'model'
G29_NAME initial,'initial'
G29_NAME transition,'transition'
G29_NAME Property,'Property'
G29_NAME always,'always'
G29_NAME eventually,'eventually'
G29_NAME check,'check'
G29_NAME counterexample,'counterexample'
G29_NAME deadlocks,'deadlocks'
G29_NAME Proof,'Proof'
G29_NAME of,'of'
G29_NAME proof,'proof'
G29_NAME proof_verify,'verify'
G29_NAME proof_manifest,'proofManifest'
G29_NAME require_proof,'requireProof'
G29_NAME assumptions,'assumptions'
G29_NAME compose,'compose'
G29_NAME invalidate,'invalidateOnChange'
G29_NAME report,'report'
G29_NAME minimize,'minimizeCounterexample'
G29_NAME replay,'replay'
G29_NAME export_manifest,'exportProofManifest'
%undef G29_NAME

section .bss align=16
g29_mode: resq 1
g29_seed: resq 1
g29_seed_seen: resq 1
g29_seen_mask: resq 1

section .text
g29_is_program:
 sub rsp,8
 lea rsi,[rel g29_n_root]
 mov edx,g29_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
%macro G29_MARKER 1
 lea rsi,[rel g29_n_%1]
 mov edx,g29_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G29_MARKER contract_marker
 G29_MARKER refinement_marker
 G29_MARKER obligation_marker
 G29_MARKER model_marker
 G29_MARKER proof_marker
 G29_MARKER tooling_marker
.no:
 xor eax,eax
 add rsp,8
 ret
.yes:
 mov eax,1
 add rsp,8
 ret
%undef G29_MARKER

g29_marker_count:
 push rbx
 push r12
 sub rsp,8
 xor ebx,ebx
 xor r12d,r12d
.scan:
 cmp r12,[rel ls_token_count]
 jae .done
%macro G29_COUNT 1
 mov rdi,r12
 lea rsi,[rel g29_n_%1]
 mov edx,g29_n_%1_len
 call ls_token_match
 test eax,eax
 jz %%next
 inc ebx
 jmp .next
%%next:
%endmacro
 G29_COUNT contract_marker
 G29_COUNT refinement_marker
 G29_COUNT obligation_marker
 G29_COUNT model_marker
 G29_COUNT proof_marker
 G29_COUNT tooling_marker
.next:
 inc r12
 jmp .scan
.done:
 mov eax,ebx
 add rsp,8
 pop r12
 pop rbx
 ret
%undef G29_COUNT

g29_select_mode:
 sub rsp,8
%macro G29_SELECT 2
 lea rsi,[rel g29_n_%1]
 mov edx,g29_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %%next
 mov eax,%2
 add rsp,8
 ret
%%next:
%endmacro
 G29_SELECT contract_marker,1
 G29_SELECT refinement_marker,2
 G29_SELECT obligation_marker,3
 G29_SELECT model_marker,4
 G29_SELECT proof_marker,5
 G29_SELECT tooling_marker,6
 xor eax,eax
 add rsp,8
 ret
%undef G29_SELECT

; RDI points to a dot token. Only receiver/method pairs from the selected
; subgroup are accepted; shared spellings such as verify stay receiver-owned.
g29_call_allowed:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,[rel g29_mode]
%macro G29_ALLOW 2
 lea rdi,[rbx-1]
 lea rsi,[rel g29_n_%1]
 mov edx,g29_n_%1_len
 call ls_token_match
 test eax,eax
 jz %%next
 lea rdi,[rbx+1]
 lea rsi,[rel g29_n_%2]
 mov edx,g29_n_%2_len
 call ls_token_match
 test eax,eax
 jnz .yes
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
 jmp .no
.s1:
 G29_ALLOW contract,check_runtime
 G29_ALLOW contract,explain
 jmp .no
.s2:
 G29_ALLOW input_value,refine
 G29_ALLOW input_value,is
 G29_ALLOW refined_value,base
 G29_ALLOW refinement,predicate
 G29_ALLOW refinement,explain_failure
 jmp .no
.s3:
 G29_ALLOW verify,function
 G29_ALLOW verify,module
 G29_ALLOW verify,no_overflow
 G29_ALLOW verify,no_bounds
 G29_ALLOW verify,no_leak
 G29_ALLOW verify,effects_within
 G29_ALLOW verification,obligations
 jmp .no
.s4:
 G29_ALLOW Model,state
 G29_ALLOW model,initial
 G29_ALLOW model,transition
 G29_ALLOW Property,always
 G29_ALLOW Property,eventually
 G29_ALLOW model,check
 G29_ALLOW model,counterexample
 G29_ALLOW model,deadlocks
 jmp .no
.s5:
 G29_ALLOW Proof,of
 G29_ALLOW proof,proof_verify
 G29_ALLOW module,proof_manifest
 G29_ALLOW module,require_proof
 G29_ALLOW proof,assumptions
 G29_ALLOW proof,compose
 G29_ALLOW proof,invalidate
 jmp .no
.s6:
 G29_ALLOW verification,report
 G29_ALLOW verification,minimize
 G29_ALLOW verification,replay
 G29_ALLOW verification,export_manifest
 jmp .no
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r12
 pop rbx
 ret
%undef G29_ALLOW

; Public arity validation. refine<T>() and is<T>() retain their explicit type
; argument and are checked separately from ordinary call syntax.
g29_validate_call:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 lea r12,[rbx+1]
 lea rdi,[rbx+1]
 lea rsi,[rel g29_n_refine]
 mov edx,g29_n_refine_len
 call ls_token_match
 test eax,eax
 jnz .generic_zero
 lea rdi,[rbx+1]
 lea rsi,[rel g29_n_is]
 mov edx,g29_n_is_len
 call ls_token_match
 test eax,eax
 jnz .generic_zero
%macro G29_SIG 2
 mov rdi,r12
 lea rsi,[rel g29_n_%1]
 mov edx,g29_n_%1_len
 call ls_token_match
 test eax,eax
 jnz %2
%endmacro
 G29_SIG explain,.zero
 G29_SIG base,.zero
 G29_SIG predicate,.zero
 G29_SIG obligations,.zero
 G29_SIG counterexample,.zero
 G29_SIG deadlocks,.zero
 G29_SIG proof_verify,.zero
 G29_SIG proof_manifest,.zero
 G29_SIG assumptions,.zero
 G29_SIG invalidate,.zero
 G29_SIG report,.zero
 G29_SIG minimize,.zero
 G29_SIG export_manifest,.zero
 G29_SIG check_runtime,.one
 G29_SIG explain_failure,.one
 G29_SIG function,.one
 G29_SIG module,.one
 G29_SIG no_overflow,.one
 G29_SIG no_bounds,.one
 G29_SIG no_leak,.one
 G29_SIG effects_within,.one
 G29_SIG state,.one
 G29_SIG initial,.one
 G29_SIG always,.one
 G29_SIG eventually,.one
 G29_SIG check,.one
 G29_SIG require_proof,.one
 G29_SIG compose,.one
 G29_SIG replay,.one
 G29_SIG transition,.two
 G29_SIG of,.two
 jmp .bad
.generic_zero:
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LESS
 jne .bad
 lea rdi,[rbx+3]
 call ls_kind_at
 test eax,eax
 jz .bad
 cmp eax,NEBOC_TOKEN_GREATER
 je .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_GREATER
 jne .bad
 lea rdi,[rbx+5]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .bad
 lea rdi,[rbx+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.zero:
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .bad
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.one:
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .bad
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .bad
 test eax,eax
 jz .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.two:
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .bad
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .bad
 test eax,eax
 jz .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+5]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .bad
 test eax,eax
 jz .bad
 lea rdi,[rbx+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.bad:
 xor eax,eax
.done:
 add rsp,8
 pop r12
 pop rbx
 ret
%undef G29_SIG

g29_mark_call:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,[rel g29_mode]
%macro G29_SEEN 2
 lea rdi,[rbx+1]
 lea rsi,[rel g29_n_%1]
 mov edx,g29_n_%1_len
 call ls_token_match
 test eax,eax
 jz %%next
 or qword [rel g29_seen_mask],%2
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
 G29_SEEN check_runtime,32
 G29_SEEN explain,64
 jmp .done
.s2:
 G29_SEEN refine,4
 G29_SEEN is,8
 G29_SEEN base,16
 G29_SEEN predicate,32
 G29_SEEN explain_failure,64
 jmp .done
.s3:
 G29_SEEN function,1
 G29_SEEN module,2
 G29_SEEN no_overflow,4
 G29_SEEN no_bounds,8
 G29_SEEN no_leak,16
 G29_SEEN effects_within,32
 G29_SEEN obligations,64
 jmp .done
.s4:
 G29_SEEN state,1
 G29_SEEN initial,2
 G29_SEEN transition,4
 G29_SEEN always,8
 G29_SEEN eventually,16
 G29_SEEN check,32
 G29_SEEN counterexample,64
 G29_SEEN deadlocks,128
 jmp .done
.s5:
 G29_SEEN of,1
 G29_SEEN proof_verify,2
 G29_SEEN proof_manifest,4
 G29_SEEN require_proof,8
 G29_SEEN assumptions,16
 G29_SEEN compose,32
 G29_SEEN invalidate,64
 jmp .done
.s6:
 G29_SEEN report,1
 G29_SEEN minimize,2
 G29_SEEN replay,4
 G29_SEEN export_manifest,8
.done:
 add rsp,8
 pop r12
 pop rbx
 ret
%undef G29_SEEN

; RDI token index -> EAX 0 for ordinary token, 1 for validated bare surface,
; 2 for malformed bare surface.
g29_mark_bare:
 push rbx
 sub rsp,16
 mov rbx,rdi
 cmp qword [rel g29_mode],1
 je .s1
 cmp qword [rel g29_mode],2
 je .s2
 jmp .none
.s1:
%macro G29_BARE 2
 mov rdi,rbx
 lea rsi,[rel g29_n_%1]
 mov edx,g29_n_%1_len
 call ls_token_match
 test eax,eax
 jz %%next
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 je .malformed
 test eax,eax
 jz .malformed
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 jne .malformed
 or qword [rel g29_seen_mask],%2
 mov eax,1
 jmp .done
%%next:
%endmacro
 G29_BARE requires,1
 G29_BARE ensures,2
 G29_BARE invariant,4
 G29_BARE modifies,8
 G29_BARE decreases,16
 jmp .none
.s2:
 mov rdi,rbx
 lea rsi,[rel g29_n_refined_kw]
 mov edx,g29_n_refined_kw_len
 call ls_token_match
 test eax,eax
 jz .assume
 lea rdi,[rbx+2]
 lea rsi,[rel g29_n_where_kw]
 mov edx,g29_n_where_kw_len
 call ls_token_match
 test eax,eax
 jz .malformed
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 jne .malformed
 or qword [rel g29_seen_mask],1
 mov eax,1
 jmp .done
.assume:
 mov rdi,rbx
 lea rsi,[rel g29_n_assume_kw]
 mov edx,g29_n_assume_kw_len
 call ls_token_match
 test eax,eax
 jz .none
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 je .malformed
 test eax,eax
 jz .malformed
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 jne .malformed
 or qword [rel g29_seen_mask],2
 mov eax,1
 jmp .done
.none:
 xor eax,eax
 jmp .done
.malformed:
 mov eax,2
.done:
 add rsp,16
 pop rbx
 ret
%undef G29_BARE

g29_scan_program:
 push rbx
 mov rbx,[rel ls_cursor]
.scan:
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_EOF
 je .syntax
 cmp eax,NEBOC_TOKEN_RBRACE
 je .complete
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bare
 test rbx,rbx
 jz .syntax
 lea rdi,[rbx-1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 je .bare
 cmp eax,NEBOC_TOKEN_COMMA
 je .bare
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 jne .bare
 mov rdi,rbx
 call ls_token_ptr
 test rax,rax
 jz .syntax
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rdx,G29_MIN_SEED
 jb .bare
 cmp rdx,G29_MAX_SEED
 ja .bare
 cmp qword [rel g29_seed_seen],0
 jne .unsupported
 mov qword [rel g29_seed_seen],1
 mov [rel g29_seed],rdx
.bare:
 mov rdi,rbx
 call g29_mark_bare
 cmp eax,2
 je .unsupported
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 mov rdi,rbx
 call g29_call_allowed
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g29_validate_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g29_mark_call
.next:
 inc rbx
 jmp .scan
.complete:
 cmp qword [rel g29_seed_seen],1
 jne .unsupported
 mov rax,[rel g29_mode]
 cmp rax,4
 je .expect_eight
 cmp rax,6
 je .expect_four
 cmp qword [rel g29_seen_mask],0x7f
 jne .unsupported
 xor eax,eax
 jmp .return
.expect_eight:
 cmp qword [rel g29_seen_mask],0xff
 jne .unsupported
 xor eax,eax
 jmp .return
.expect_four:
 cmp qword [rel g29_seen_mask],0x0f
 jne .unsupported
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

neboc_g029_source_parse:
 sub rsp,8
 mov qword [rel g29_mode],0
 mov qword [rel g29_seed],0
 mov qword [rel g29_seed_seen],0
 mov qword [rel g29_seen_mask],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g29_marker_count
 cmp eax,1
 jne .unsupported
 call g29_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g29_mode],rax
 call g29_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g29_mode]
 shl rax,32
 mov edi,dword [rel g29_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G29_FAMILY_KEY
 call ls_success
 add rsp,8
 ret
.syntax:
 mov edi,20
 call ls_error
 add rsp,8
 ret
.unsupported:
 mov edi,24
 call ls_error
 add rsp,8
 ret
.diagnostic:
 mov edi,eax
 call ls_error
 add rsp,8
 ret
