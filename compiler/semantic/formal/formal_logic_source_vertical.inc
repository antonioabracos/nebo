; G139 bounded source owner for formal logic.  Finite quantification, Boolean
; relations, proof/model results and work budgets remain explicit.  UNKNOWN
; and TIMEOUT are observable statuses and can never be extracted as proofs.

%define G139_FAMILY_KEY 0x5246323034473139
%define G139_FOR_ALL 1
%define G139_EXISTS 2
%define G139_NOT_EXISTS 3
%define G139_IMPLIES 4
%define G139_IFF 5
%define G139_PROVES 6
%define G139_SATISFIES 7
%define G139_NAND 8
%define G139_NOR 9
%define G139_STATUS_PROVED 0
%define G139_STATUS_DISPROVED 1
%define G139_STATUS_SAT 2
%define G139_STATUS_UNSAT 3
%define G139_STATUS_UNKNOWN 4
%define G139_STATUS_TIMEOUT 5

section .rodata
g139_n_forAll: db 'forAll'
g139_n_forAll_len equ $-g139_n_forAll
g139_n_exists: db 'exists'
g139_n_exists_len equ $-g139_n_exists
g139_n_notExists: db 'notExists'
g139_n_notExists_len equ $-g139_n_notExists
g139_n_implies: db 'implies'
g139_n_implies_len equ $-g139_n_implies
g139_n_iff: db 'iff'
g139_n_iff_len equ $-g139_n_iff
g139_n_proves: db 'proves'
g139_n_proves_len equ $-g139_n_proves
g139_n_satisfies: db 'satisfies'
g139_n_satisfies_len equ $-g139_n_satisfies
g139_n_nand: db 'nand'
g139_n_nand_len equ $-g139_n_nand
g139_n_nor: db 'nor'
g139_n_nor_len equ $-g139_n_nor
g139_n_proved: db 'proved'
g139_n_proved_len equ $-g139_n_proved
g139_n_disproved: db 'disproved'
g139_n_disproved_len equ $-g139_n_disproved
g139_n_sat: db 'sat'
g139_n_sat_len equ $-g139_n_sat
g139_n_unsat: db 'unsat'
g139_n_unsat_len equ $-g139_n_unsat
g139_n_unknown: db 'unknown'
g139_n_unknown_len equ $-g139_n_unknown
g139_n_timeout: db 'timeout'
g139_n_timeout_len equ $-g139_n_timeout
g139_n_value: db 'value'
g139_n_value_len equ $-g139_n_value
g139_n_status: db 'status'
g139_n_status_len equ $-g139_n_status
g139_n_proof: db 'proof'
g139_n_proof_len equ $-g139_n_proof
g139_n_witness: db 'witness'
g139_n_witness_len equ $-g139_n_witness
g139_n_budget: db 'budget'
g139_n_budget_len equ $-g139_n_budget
g139_n_steps: db 'steps'
g139_n_steps_len equ $-g139_n_steps
g139_n_code: db 'code'
g139_n_code_len equ $-g139_n_code

section .bss align=16
g139_scratch_start:
g139_kind: resq 1
g139_domain: resq 1
g139_count: resq 1
g139_unknown: resq 1
g139_timeout: resq 1
g139_left: resq 1
g139_right: resq 1
g139_requested_status: resq 1
g139_evidence: resq 1
g139_budget: resq 1
g139_status: resq 1
g139_value: resq 1
g139_proof: resq 1
g139_witness: resq 1
g139_steps: resq 1
g139_scratch_end:

section .text

g139_api_at:
 push rbx
 mov rbx,rdi
%macro G139_API_MATCH 1
 mov rdi,rbx
 lea rsi,[rel g139_n_%1]
 mov edx,g139_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G139_API_MATCH forAll
 G139_API_MATCH exists
 G139_API_MATCH notExists
 G139_API_MATCH implies
 G139_API_MATCH iff
 G139_API_MATCH proves
 G139_API_MATCH satisfies
 G139_API_MATCH nand
 G139_API_MATCH nor
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G139_API_MATCH

g139_is_program:
 push rbx
 xor ebx,ebx
.scan:
 cmp rbx,[rel ls_token_count]
 jae .no
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_FOR_ALL
 jb .identifier
 cmp eax,NEBOC_TOKEN_LOGIC_NOR
 jbe .yes
.identifier:
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .next
 mov rdi,rbx
 call g139_api_at
 test eax,eax
 jz .next
 test rbx,rbx
 jz .next
 lea rdi,[rbx-1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LBRACE
 je .yes
 cmp eax,NEBOC_TOKEN_PLUS
 je .yes
.next:
 inc rbx
 jmp .scan
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop rbx
 ret

g139_expect:
 sub rsp,8
 call ls_expect_kind
 test eax,eax
 jz .syntax
 xor eax,eax
 jmp .done
.syntax:
 mov rax,-1
.done:
 add rsp,8
 ret

g139_expect_comma:
 mov edi,NEBOC_TOKEN_COMMA
 jmp g139_expect

g139_empty_call:
 sub rsp,8
 mov edi,NEBOC_TOKEN_LPAREN
 call g139_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call g139_expect
.done:
 add rsp,8
 ret

g139_parse_positive:
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 test rdx,rdx
 jle .domain
 cmp rdx,1000000
 ja .domain
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.syntax:
 mov rax,-1
 ret

g139_parse_nonnegative:
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 test rdx,rdx
 js .domain
 cmp rdx,1000000
 ja .domain
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.syntax:
 mov rax,-1
 ret

g139_parse_bool:
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 cmp rdx,1
 ja .domain
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.syntax:
 mov rax,-1
 ret

g139_next_nonnegative:
 call g139_expect_comma
 test eax,eax
 jnz .done
 call g139_parse_nonnegative
.done:
 ret

g139_parse_status:
%macro G139_STATUS_MATCH 2
 lea rsi,[rel g139_n_%1]
 mov edx,g139_n_%1_len
 call ls_current_atom
 test eax,eax
 jnz .%2
%endmacro
 G139_STATUS_MATCH proved,proved
 G139_STATUS_MATCH disproved,disproved
 G139_STATUS_MATCH sat,sat
 G139_STATUS_MATCH unsat,unsat
 G139_STATUS_MATCH unknown,unknown
 G139_STATUS_MATCH timeout,timeout
 mov eax,28
 ret
.proved: mov rdx,G139_STATUS_PROVED
 jmp .yes
.disproved: mov rdx,G139_STATUS_DISPROVED
 jmp .yes
.sat: mov rdx,G139_STATUS_SAT
 jmp .yes
.unsat: mov rdx,G139_STATUS_UNSAT
 jmp .yes
.unknown: mov rdx,G139_STATUS_UNKNOWN
 jmp .yes
.timeout: mov rdx,G139_STATUS_TIMEOUT
.yes:
 inc qword [rel ls_cursor]
 xor eax,eax
 ret
%undef G139_STATUS_MATCH

g139_parse_budget_and_close:
 call g139_expect_comma
 test eax,eax
 jnz .done
 call g139_parse_positive
 test eax,eax
 jnz .done
 mov [rel g139_budget],rdx
 mov edi,NEBOC_TOKEN_RPAREN
 call g139_expect
.done:
 ret

g139_parse_head:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_FOR_ALL
 je .forall_symbol
 cmp eax,NEBOC_TOKEN_EXISTS
 je .exists_symbol
 cmp eax,NEBOC_TOKEN_NOT_EXISTS
 je .not_exists_symbol
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
%macro G139_HEAD 2
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g139_n_%1]
 mov edx,g139_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .%2
%endmacro
 G139_HEAD forAll,forall
 G139_HEAD exists,exists
 G139_HEAD notExists,not_exists
 G139_HEAD implies,implies
 G139_HEAD iff,iff
 G139_HEAD proves,proves
 G139_HEAD satisfies,satisfies
 G139_HEAD nand,nand
 G139_HEAD nor,nor
 jmp .syntax
.forall_symbol:
 mov qword [rel g139_kind],G139_FOR_ALL
 jmp .advance
.exists_symbol:
 mov qword [rel g139_kind],G139_EXISTS
 jmp .advance
.not_exists_symbol:
 mov qword [rel g139_kind],G139_NOT_EXISTS
 jmp .advance
.forall:
 mov qword [rel g139_kind],G139_FOR_ALL
 jmp .advance
.exists:
 mov qword [rel g139_kind],G139_EXISTS
 jmp .advance
.not_exists:
 mov qword [rel g139_kind],G139_NOT_EXISTS
 jmp .advance
.implies:
 mov qword [rel g139_kind],G139_IMPLIES
 jmp .advance
.iff:
 mov qword [rel g139_kind],G139_IFF
 jmp .advance
.proves:
 mov qword [rel g139_kind],G139_PROVES
 jmp .advance
.satisfies:
 mov qword [rel g139_kind],G139_SATISFIES
 jmp .advance
.nand:
 mov qword [rel g139_kind],G139_NAND
 jmp .advance
.nor:
 mov qword [rel g139_kind],G139_NOR
.advance:
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call g139_expect
 ret
.syntax:
 mov rax,-1
 ret
%undef G139_HEAD

g139_parse_quantifier:
 call g139_parse_positive
 test eax,eax
 jnz .done
 mov [rel g139_domain],rdx
 call g139_next_nonnegative
 test eax,eax
 jnz .done
 mov [rel g139_count],rdx
 call g139_next_nonnegative
 test eax,eax
 jnz .done
 mov [rel g139_unknown],rdx
 call g139_next_nonnegative
 test eax,eax
 jnz .done
 mov [rel g139_timeout],rdx
 call g139_parse_budget_and_close
.done:
 ret

g139_binary_token:
 cmp qword [rel g139_kind],G139_IMPLIES
 je .implies
 cmp qword [rel g139_kind],G139_IFF
 je .iff
 cmp qword [rel g139_kind],G139_NAND
 je .nand
 mov eax,NEBOC_TOKEN_LOGIC_NOR
 ret
.implies: mov eax,NEBOC_TOKEN_LOGIC_IMPLIES
 ret
.iff: mov eax,NEBOC_TOKEN_LOGIC_IFF
 ret
.nand: mov eax,NEBOC_TOKEN_LOGIC_NAND
 ret

g139_parse_binary:
 call g139_parse_bool
 test eax,eax
 jnz .done
 mov [rel g139_left],rdx
 call g139_binary_token
 mov r8d,eax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,r8d
 jne .named
 inc qword [rel ls_cursor]
 jmp .right
.named:
 call g139_expect_comma
 test eax,eax
 jnz .done
.right:
 call g139_parse_bool
 test eax,eax
 jnz .done
 mov [rel g139_right],rdx
 call g139_parse_budget_and_close
.done:
 ret

g139_relation_token:
 cmp qword [rel g139_kind],G139_PROVES
 jne .satisfies
 mov eax,NEBOC_TOKEN_PROVES
 ret
.satisfies:
 mov eax,NEBOC_TOKEN_SATISFIES
 ret

g139_parse_relation:
 call g139_parse_positive
 test eax,eax
 jnz .done
 mov [rel g139_left],rdx
 call g139_relation_token
 mov r8d,eax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,r8d
 jne .named
 inc qword [rel ls_cursor]
 jmp .right
.named:
 call g139_expect_comma
 test eax,eax
 jnz .done
.right:
 call g139_parse_positive
 test eax,eax
 jnz .done
 mov [rel g139_right],rdx
 call g139_expect_comma
 test eax,eax
 jnz .done
 call g139_parse_status
 test eax,eax
 jnz .done
 mov [rel g139_requested_status],rdx
 call g139_next_nonnegative
 test eax,eax
 jnz .done
 mov [rel g139_evidence],rdx
 call g139_parse_budget_and_close
.done:
 ret

g139_parse_body:
 cmp qword [rel g139_kind],G139_NOT_EXISTS
 jbe g139_parse_quantifier
 cmp qword [rel g139_kind],G139_PROVES
 je g139_parse_relation
 cmp qword [rel g139_kind],G139_SATISFIES
 je g139_parse_relation
 jmp g139_parse_binary

; RDI is required deterministic work.  EAX=1 means budget timeout.
g139_budget_check:
 mov [rel g139_steps],rdi
 cmp [rel g139_budget],rdi
 jae .yes
 mov rax,[rel g139_budget]
 mov [rel g139_steps],rax
 mov qword [rel g139_status],G139_STATUS_TIMEOUT
 mov qword [rel g139_proof],0
 mov qword [rel g139_witness],0
 mov eax,1
 ret
.yes:
 xor eax,eax
 ret

g139_calculate_quantifier:
 mov rdi,[rel g139_domain]
 call g139_budget_check
 test eax,eax
 jnz .ok
 mov rax,[rel g139_count]
 add rax,[rel g139_unknown]
 jo .overflow
 add rax,[rel g139_timeout]
 jo .overflow
 cmp rax,[rel g139_domain]
 ja .domain
 mov rcx,[rel g139_domain]
 sub rcx,rax
 cmp qword [rel g139_kind],G139_FOR_ALL
 je .forall
 cmp qword [rel g139_kind],G139_EXISTS
 je .exists
 ; notExists: any witness disproves; otherwise undecided dominates proof.
 cmp qword [rel g139_count],0
 jne .disproved
 cmp qword [rel g139_timeout],0
 jne .timeout
 cmp qword [rel g139_unknown],0
 jne .unknown
 mov qword [rel g139_status],G139_STATUS_PROVED
 mov qword [rel g139_value],1
 jmp .ok
.forall:
 test rcx,rcx
 jnz .disproved
 cmp qword [rel g139_timeout],0
 jne .timeout
 cmp qword [rel g139_unknown],0
 jne .unknown
 mov qword [rel g139_status],G139_STATUS_PROVED
 mov qword [rel g139_value],1
 jmp .ok
.exists:
 cmp qword [rel g139_count],0
 jne .sat
 cmp qword [rel g139_timeout],0
 jne .timeout
 cmp qword [rel g139_unknown],0
 jne .unknown
 mov qword [rel g139_status],G139_STATUS_UNSAT
 mov qword [rel g139_value],0
 jmp .ok
.sat:
 mov qword [rel g139_status],G139_STATUS_SAT
 mov qword [rel g139_value],1
 jmp .ok
.disproved:
 mov qword [rel g139_status],G139_STATUS_DISPROVED
 mov qword [rel g139_value],0
 jmp .ok
.unknown:
 mov qword [rel g139_status],G139_STATUS_UNKNOWN
 jmp .ok
.timeout:
 mov qword [rel g139_status],G139_STATUS_TIMEOUT
.ok:
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.overflow:
 mov eax,10
 ret

g139_calculate_binary:
 mov edi,2
 call g139_budget_check
 test eax,eax
 jnz .ok
 mov rax,[rel g139_left]
 mov rdx,[rel g139_right]
 cmp qword [rel g139_kind],G139_IMPLIES
 je .implies
 cmp qword [rel g139_kind],G139_IFF
 je .iff
 cmp qword [rel g139_kind],G139_NAND
 je .nand
 or rax,rdx
 xor rax,1
 jmp .publish
.implies:
 xor rax,1
 or rax,rdx
 jmp .publish
.iff:
 cmp rax,rdx
 sete al
 movzx rax,al
 jmp .publish
.nand:
 and rax,rdx
 xor rax,1
.publish:
 mov [rel g139_value],rax
 test rax,rax
 jz .false
 mov qword [rel g139_status],G139_STATUS_PROVED
 jmp .ok
.false:
 mov qword [rel g139_status],G139_STATUS_DISPROVED
.ok:
 xor eax,eax
 ret

g139_calculate_relation:
 mov edi,4
 call g139_budget_check
 test eax,eax
 jnz .ok
 mov rax,[rel g139_requested_status]
 cmp qword [rel g139_kind],G139_PROVES
 jne .model
 cmp rax,G139_STATUS_PROVED
 je .proved
 cmp rax,G139_STATUS_DISPROVED
 je .disproved
 cmp rax,G139_STATUS_UNKNOWN
 je .undecided
 cmp rax,G139_STATUS_TIMEOUT
 jne .domain
 jmp .undecided
.proved:
 cmp qword [rel g139_evidence],0
 je .domain
 mov [rel g139_status],rax
 mov qword [rel g139_value],1
 mov rdx,[rel g139_evidence]
 mov [rel g139_proof],rdx
 jmp .ok
.disproved:
 cmp qword [rel g139_evidence],0
 je .domain
 mov [rel g139_status],rax
 mov qword [rel g139_value],0
 mov rdx,[rel g139_evidence]
 mov [rel g139_witness],rdx
 jmp .ok
.model:
 cmp rax,G139_STATUS_SAT
 je .sat
 cmp rax,G139_STATUS_UNSAT
 je .unsat
 cmp rax,G139_STATUS_UNKNOWN
 je .undecided
 cmp rax,G139_STATUS_TIMEOUT
 jne .domain
 jmp .undecided
.sat:
 cmp qword [rel g139_evidence],0
 jne .domain
 mov [rel g139_status],rax
 mov qword [rel g139_value],1
 jmp .ok
.unsat:
 cmp qword [rel g139_evidence],0
 je .domain
 mov [rel g139_status],rax
 mov qword [rel g139_value],0
 mov rdx,[rel g139_evidence]
 mov [rel g139_witness],rdx
 jmp .ok
.undecided:
 cmp qword [rel g139_evidence],0
 jne .domain
 mov [rel g139_status],rax
.ok:
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret

g139_calculate:
 cmp qword [rel g139_kind],G139_NOT_EXISTS
 jbe g139_calculate_quantifier
 cmp qword [rel g139_kind],G139_PROVES
 je g139_calculate_relation
 cmp qword [rel g139_kind],G139_SATISFIES
 je g139_calculate_relation
 jmp g139_calculate_binary

g139_require_decided:
 cmp qword [rel g139_status],G139_STATUS_UNKNOWN
 jae .no
 xor eax,eax
 ret
.no:
 mov eax,28
 ret

g139_parse_observer:
 mov edi,NEBOC_TOKEN_DOT
 call g139_expect
 test eax,eax
 jnz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
%macro G139_OBSERVER 2
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g139_n_%1]
 mov edx,g139_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .%2
%endmacro
 G139_OBSERVER value,value
 G139_OBSERVER status,status
 G139_OBSERVER proof,proof
 G139_OBSERVER witness,witness
 G139_OBSERVER budget,budget
 G139_OBSERVER steps,steps
 G139_OBSERVER code,code
 jmp .syntax
.value:
 call g139_require_decided
 test eax,eax
 jnz .done
 mov rdx,[rel g139_value]
 jmp .empty
.status:
 mov rdx,[rel g139_status]
 jmp .empty
.proof:
 cmp qword [rel g139_kind],G139_PROVES
 jne .domain
 cmp qword [rel g139_status],G139_STATUS_PROVED
 jne .domain
 mov rdx,[rel g139_proof]
 jmp .empty
.witness:
 cmp qword [rel g139_status],G139_STATUS_DISPROVED
 je .witness_ok
 cmp qword [rel g139_status],G139_STATUS_UNSAT
 jne .domain
.witness_ok:
 mov rdx,[rel g139_witness]
 jmp .empty
.budget:
 mov rdx,[rel g139_budget]
 jmp .empty
.steps:
 mov rdx,[rel g139_steps]
 jmp .empty
.code:
 mov rdx,[rel g139_status]
 add rdx,139000
.empty:
 push rdx
 inc qword [rel ls_cursor]
 call g139_empty_call
 pop rdx
 ret
.domain:
 mov eax,28
 ret
.syntax:
 mov rax,-1
.done:
 ret
%undef G139_OBSERVER

g139_parse_term:
 call g139_parse_head
 test eax,eax
 jnz .done
 call g139_parse_body
 test eax,eax
 jnz .done
 call g139_calculate
 test eax,eax
 jnz .done
 call g139_parse_observer
.done:
 ret

g139_parse_program:
 push rbx
 sub rsp,16
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call .clear_term
 call g139_parse_term
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 mov [rsp],rdx
.plus_loop:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_PLUS
 jne .finish
 inc qword [rel ls_cursor]
 call .clear_term
 call g139_parse_term
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 add [rsp],rdx
 jo .overflow
 jmp .plus_loop
.finish:
 call ls_finish_program
 test eax,eax
 jz .syntax
 mov rdi,[rsp]
 mov esi,NEBOC_VECTOR_VERTICAL_FLAGS_REQUIRED
 mov rdx,G139_FAMILY_KEY
 call ls_success
 jmp .done
.semantic:
 call .record_error_token
 mov edi,eax
 call ls_error
 jmp .done
.overflow:
 call .record_error_token
 mov edi,10
 call ls_error
 jmp .done
.syntax:
 call .record_error_token
 mov edi,24
 call ls_error
 jmp .done
.clear_term:
 lea rdi,[rel g139_scratch_start]
 mov ecx,(g139_scratch_end-g139_scratch_start)/8
 xor eax,eax
 rep stosq
 ret
.record_error_token:
 mov r8,rax
 mov rcx,[rel ls_cursor]
 cmp rcx,[rel ls_token_count]
 jb .error_token_ready
 mov rcx,[rel ls_token_count]
 test rcx,rcx
 jz .error_token_ready
 dec rcx
.error_token_ready:
 mov rax,[rel ls_request]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_ERROR_TOKEN_OFFSET],rcx
 mov rax,r8
 ret
.done:
 add rsp,16
 pop rbx
 ret
