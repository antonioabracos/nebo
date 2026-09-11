; G030 token-owned bounded solver vertical. A disjoint profile root, exactly one
; subgroup marker, the complete receiver-qualified public vocabulary, and one
; observable seed are required before lowering can publish a result.
%define G30_FAMILY_KEY 0x5246323034473330
%define G30_MIN_SEED 3001
%define G30_MAX_SEED 999999

section .rodata
%macro G30_NAME 2
g30_n_%1: db %2
g30_n_%1_len equ $-g30_n_%1
%endmacro
G30_NAME root,'BoundedSolver30'
G30_NAME domain_marker,'domainModel30'
G30_NAME constraint_marker,'constraintModel30'
G30_NAME optimize_marker,'optimizeModel30'
G30_NAME schedule_marker,'scheduleModel30'
G30_NAME incremental_marker,'incrementalModel30'
G30_NAME diagnostic_marker,'diagnosticModel30'
G30_NAME Solver,'Solver'
G30_NAME solver,'solver'
G30_NAME symbolic,'symbolic'
G30_NAME solution,'solution'
G30_NAME Schedule,'Schedule'
G30_NAME schedule,'schedule'
G30_NAME task,'task'
G30_NAME new,'new'
G30_NAME int,'int'
G30_NAME bool,'bool'
G30_NAME enum,'enum'
G30_NAME set,'set'
G30_NAME real,'real'
G30_NAME domain,'domain'
G30_NAME is_bound,'isBound'
G30_NAME require,'require'
G30_NAME implies,'implies'
G30_NAME exactly_one,'exactlyOne'
G30_NAME all_different,'allDifferent'
G30_NAME sum,'sum'
G30_NAME equals,'equals'
G30_NAME element,'element'
G30_NAME table,'table'
G30_NAME circuit,'circuit'
G30_NAME minimize,'minimize'
G30_NAME maximize,'maximize'
G30_NAME lexicographic,'lexicographic'
G30_NAME weighted,'weighted'
G30_NAME pareto,'pareto'
G30_NAME set_gap,'setOptimalityGap'
G30_NAME objective_values,'objectiveValues'
G30_NAME optimality_status,'optimalityStatus'
G30_NAME task_method,'task'
G30_NAME before,'before'
G30_NAME requires,'requires'
G30_NAME no_overlap,'noOverlap'
G30_NAME cumulative,'cumulative'
G30_NAME calendar,'calendar'
G30_NAME makespan,'makespan'
G30_NAME push,'push'
G30_NAME pop,'pop'
G30_NAME assume,'assume'
G30_NAME solve,'solve'
G30_NAME solve_all,'solveAll'
G30_NAME next_solution,'nextSolution'
G30_NAME cancel,'cancel'
G30_NAME resume,'resume'
G30_NAME explain_unsat,'explainUnsat'
G30_NAME unsat_core,'unsatCore'
G30_NAME explain,'explain'
G30_NAME statistics,'statistics'
G30_NAME trace,'trace'
G30_NAME verify,'verify'
%undef G30_NAME

section .bss align=16
g30_mode: resq 1
g30_seed: resq 1
g30_seed_seen: resq 1
g30_seen_mask: resq 1

section .text
g30_is_program:
 sub rsp,8
 lea rsi,[rel g30_n_root]
 mov edx,g30_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
%macro G30_MARKER 1
 lea rsi,[rel g30_n_%1]
 mov edx,g30_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G30_MARKER domain_marker
 G30_MARKER constraint_marker
 G30_MARKER optimize_marker
 G30_MARKER schedule_marker
 G30_MARKER incremental_marker
 G30_MARKER diagnostic_marker
.no:
 xor eax,eax
 add rsp,8
 ret
.yes:
 mov eax,1
 add rsp,8
 ret
%undef G30_MARKER

g30_marker_count:
 push rbx
 push r12
 sub rsp,8
 xor ebx,ebx
 xor r12d,r12d
.scan:
 cmp r12,[rel ls_token_count]
 jae .done
%macro G30_COUNT 1
 mov rdi,r12
 lea rsi,[rel g30_n_%1]
 mov edx,g30_n_%1_len
 call ls_token_match
 test eax,eax
 jz %%next
 inc ebx
 jmp .next
%%next:
%endmacro
 G30_COUNT domain_marker
 G30_COUNT constraint_marker
 G30_COUNT optimize_marker
 G30_COUNT schedule_marker
 G30_COUNT incremental_marker
 G30_COUNT diagnostic_marker
.next:
 inc r12
 jmp .scan
.done:
 mov eax,ebx
 add rsp,8
 pop r12
 pop rbx
 ret
%undef G30_COUNT

g30_select_mode:
 sub rsp,8
%macro G30_SELECT 2
 lea rsi,[rel g30_n_%1]
 mov edx,g30_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %%next
 mov eax,%2
 add rsp,8
 ret
%%next:
%endmacro
 G30_SELECT domain_marker,1
 G30_SELECT constraint_marker,2
 G30_SELECT optimize_marker,3
 G30_SELECT schedule_marker,4
 G30_SELECT incremental_marker,5
 G30_SELECT diagnostic_marker,6
 xor eax,eax
 add rsp,8
 ret
%undef G30_SELECT

; RDI points to a dot token. Only public receiver/method pairs belonging to the
; selected subgroup are accepted. The sum(...).equals(...) chain is checked as
; a structural pair rather than as two unrelated atom occurrences.
g30_call_allowed:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,[rel g30_mode]
%macro G30_ALLOW 2
 lea rdi,[rbx-1]
 lea rsi,[rel g30_n_%1]
 mov edx,g30_n_%1_len
 call ls_token_match
 test eax,eax
 jz %%next
 lea rdi,[rbx+1]
 lea rsi,[rel g30_n_%2]
 mov edx,g30_n_%2_len
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
 G30_ALLOW Solver,new
 G30_ALLOW solver,int
 G30_ALLOW solver,bool
 G30_ALLOW solver,enum
 G30_ALLOW solver,set
 G30_ALLOW solver,real
 G30_ALLOW symbolic,domain
 G30_ALLOW symbolic,is_bound
 jmp .no
.s2:
 G30_ALLOW solver,require
 G30_ALLOW solver,implies
 G30_ALLOW solver,exactly_one
 G30_ALLOW solver,all_different
 G30_ALLOW solver,sum
 G30_ALLOW solver,element
 G30_ALLOW solver,table
 G30_ALLOW solver,circuit
 lea rdi,[rbx+1]
 lea rsi,[rel g30_n_equals]
 mov edx,g30_n_equals_len
 call ls_token_match
 test eax,eax
 jz .no
 cmp rbx,4
 jb .no
 lea rdi,[rbx-4]
 lea rsi,[rel g30_n_sum]
 mov edx,g30_n_sum_len
 call ls_token_match
 test eax,eax
 jnz .yes
 jmp .no
.s3:
 G30_ALLOW solver,minimize
 G30_ALLOW solver,maximize
 G30_ALLOW solver,lexicographic
 G30_ALLOW solver,weighted
 G30_ALLOW solver,pareto
 G30_ALLOW solver,set_gap
 G30_ALLOW solution,objective_values
 G30_ALLOW solution,optimality_status
 jmp .no
.s4:
 G30_ALLOW Schedule,new
 G30_ALLOW schedule,task_method
 G30_ALLOW task,before
 G30_ALLOW task,requires
 G30_ALLOW schedule,no_overlap
 G30_ALLOW schedule,cumulative
 G30_ALLOW schedule,calendar
 G30_ALLOW schedule,makespan
 jmp .no
.s5:
 G30_ALLOW solver,push
 G30_ALLOW solver,pop
 G30_ALLOW solver,assume
 G30_ALLOW solver,solve
 G30_ALLOW solver,solve_all
 G30_ALLOW solver,next_solution
 G30_ALLOW solver,cancel
 G30_ALLOW solver,resume
 jmp .no
.s6:
 G30_ALLOW solver,explain_unsat
 G30_ALLOW solver,unsat_core
 G30_ALLOW solution,explain
 G30_ALLOW solver,statistics
 G30_ALLOW solver,trace
 G30_ALLOW solver,verify
 jmp .no
.yes: mov eax,1
 jmp .done
.no: xor eax,eax
.done:
 add rsp,8
 pop r12
 pop rbx
 ret
%undef G30_ALLOW

; Validate public arity without assigning semantics to opaque argument atoms.
g30_validate_call:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 lea r12,[rbx+1]
%macro G30_SIG 2
 mov rdi,r12
 lea rsi,[rel g30_n_%1]
 mov edx,g30_n_%1_len
 call ls_token_match
 test eax,eax
 jnz %2
%endmacro
 G30_SIG domain,.zero
 G30_SIG is_bound,.zero
 G30_SIG objective_values,.zero
 G30_SIG optimality_status,.zero
 G30_SIG makespan,.zero
 G30_SIG push,.zero
 G30_SIG pop,.zero
 G30_SIG solve,.zero
 G30_SIG next_solution,.zero
 G30_SIG cancel,.zero
 G30_SIG explain_unsat,.zero
 G30_SIG unsat_core,.zero
 G30_SIG statistics,.zero
 G30_SIG new,.one
 G30_SIG bool,.one
 G30_SIG require,.one
 G30_SIG exactly_one,.one
 G30_SIG all_different,.one
 G30_SIG sum,.one
 G30_SIG equals,.one
 G30_SIG circuit,.one
 G30_SIG minimize,.one
 G30_SIG maximize,.one
 G30_SIG lexicographic,.one
 G30_SIG set_gap,.one
 G30_SIG before,.one
 G30_SIG no_overlap,.one
 G30_SIG assume,.one
 G30_SIG solve_all,.one
 G30_SIG resume,.one
 G30_SIG explain,.one
 G30_SIG trace,.one
 G30_SIG verify,.one
 G30_SIG int,.two
 G30_SIG enum,.two
 G30_SIG set,.two
 G30_SIG real,.two
 G30_SIG implies,.two
 G30_SIG table,.two
 G30_SIG weighted,.two
 G30_SIG pareto,.two
 G30_SIG task_method,.two
 G30_SIG requires,.two
 G30_SIG cumulative,.two
 G30_SIG calendar,.two
 G30_SIG element,.three
 jmp .bad
.zero:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
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
.three:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+8]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.bad: xor eax,eax
.done:
 add rsp,8
 pop r12
 pop rbx
 ret
%undef G30_SIG

g30_mark_surface:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,[rel g30_mode]
%macro G30_SEEN 2
 lea rdi,[rbx+1]
 lea rsi,[rel g30_n_%1]
 mov edx,g30_n_%1_len
 call ls_token_match
 test eax,eax
 jz %%next
 or qword [rel g30_seen_mask],%2
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
 G30_SEEN new,1
 G30_SEEN int,2
 G30_SEEN bool,4
 G30_SEEN enum,8
 G30_SEEN set,16
 G30_SEEN real,32
 G30_SEEN domain,64
 G30_SEEN is_bound,128
 jmp .done
.s2:
 G30_SEEN require,1
 G30_SEEN implies,2
 G30_SEEN exactly_one,4
 G30_SEEN all_different,8
 G30_SEEN equals,16
 G30_SEEN element,32
 G30_SEEN table,64
 G30_SEEN circuit,128
 jmp .done
.s3:
 G30_SEEN minimize,1
 G30_SEEN maximize,2
 G30_SEEN lexicographic,4
 G30_SEEN weighted,8
 G30_SEEN pareto,16
 G30_SEEN set_gap,32
 G30_SEEN objective_values,64
 G30_SEEN optimality_status,128
 jmp .done
.s4:
 G30_SEEN new,1
 G30_SEEN task_method,2
 G30_SEEN before,4
 G30_SEEN requires,8
 G30_SEEN no_overlap,16
 G30_SEEN cumulative,32
 G30_SEEN calendar,64
 G30_SEEN makespan,128
 jmp .done
.s5:
 G30_SEEN push,1
 G30_SEEN pop,2
 G30_SEEN assume,4
 G30_SEEN solve,8
 G30_SEEN solve_all,16
 G30_SEEN next_solution,32
 G30_SEEN cancel,64
 G30_SEEN resume,128
 jmp .done
.s6:
 G30_SEEN explain_unsat,1
 G30_SEEN unsat_core,2
 G30_SEEN explain,4
 G30_SEEN statistics,8
 G30_SEEN trace,16
 G30_SEEN verify,32
.done:
 add rsp,8
 pop r12
 pop rbx
 ret
%undef G30_SEEN

g30_scan_program:
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
 cmp rdx,G30_MIN_SEED
 jb .next
 cmp rdx,G30_MAX_SEED
 ja .next
 cmp qword [rel g30_seed_seen],0
 jne .unsupported
 mov qword [rel g30_seed_seen],1
 mov [rel g30_seed],rdx
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 mov rdi,rbx
 call g30_call_allowed
 test eax,eax
 jz .unsupported
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .unsupported
 mov rdi,rbx
 call g30_validate_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g30_mark_surface
.next:
 inc rbx
 jmp .scan
.complete:
 cmp qword [rel g30_seed_seen],1
 jne .unsupported
 mov rax,[rel g30_mode]
 cmp rax,6
 je .expect_six
 cmp qword [rel g30_seen_mask],0xff
 jne .unsupported
 xor eax,eax
 jmp .return
.expect_six:
 cmp qword [rel g30_seen_mask],0x3f
 jne .unsupported
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return:
 pop rbx
 ret

neboc_g030_source_parse:
 sub rsp,8
 mov qword [rel g30_mode],0
 mov qword [rel g30_seed],0
 mov qword [rel g30_seed_seen],0
 mov qword [rel g30_seen_mask],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g30_marker_count
 cmp eax,1
 jne .unsupported
 call g30_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g30_mode],rax
 call g30_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g30_mode]
 shl rax,32
 mov edi,dword [rel g30_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G30_FAMILY_KEY
 call ls_success
 add rsp,8
 ret
.syntax: mov edi,20
 call ls_error
 add rsp,8
 ret
.unsupported: mov edi,24
 call ls_error
 add rsp,8
 ret
.diagnostic: mov edi,eax
 call ls_error
 add rsp,8
 ret
