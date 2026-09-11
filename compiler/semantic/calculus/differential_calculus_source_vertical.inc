; G137 bounded source owner for differential and vector calculus.  Every
; public spelling carries explicit method, discretization, unit, dimensions
; and budget operands.  The owner evaluates checked integer reference plans
; once and lowers one observed scalar through the normal source pipeline.

%define G137_FAMILY_KEY 0x5246323034473137
%define G137_VALUE_CAPACITY 40
%define G137_COMPONENT_CAPACITY 16
%define G137_PARTIAL 1
%define G137_GRADIENT 2
%define G137_DIVERGENCE 3
%define G137_CURL 4
%define G137_LAPLACIAN 5
%define G137_METHOD_AUTODIFF 0
%define G137_METHOD_SYMBOLIC 1
%define G137_METHOD_NUMERIC 2
%define G137_POLICY_ANALYTIC 1
%define G137_POLICY_CENTRAL 2
%define G137_BOUNDARY_NONE 0
%define G137_BOUNDARY_DIRICHLET 1
%define G137_STATUS_BUDGET -12

section .rodata
g137_n_partial: db 'partial'
g137_n_partial_len equ $-g137_n_partial
g137_n_gradient: db 'gradient'
g137_n_gradient_len equ $-g137_n_gradient
g137_n_divergence: db 'divergence'
g137_n_divergence_len equ $-g137_n_divergence
g137_n_curl: db 'curl'
g137_n_curl_len equ $-g137_n_curl
g137_n_laplacian: db 'laplacian'
g137_n_laplacian_len equ $-g137_n_laplacian
g137_n_unitless: db 'unitless'
g137_n_unitless_len equ $-g137_n_unitless
g137_n_meters: db 'meters'
g137_n_meters_len equ $-g137_n_meters
g137_n_autodiff: db 'autodiff'
g137_n_autodiff_len equ $-g137_n_autodiff
g137_n_symbolic: db 'symbolic'
g137_n_symbolic_len equ $-g137_n_symbolic
g137_n_numeric: db 'numeric'
g137_n_numeric_len equ $-g137_n_numeric
g137_n_analytic: db 'analytic'
g137_n_analytic_len equ $-g137_n_analytic
g137_n_central: db 'central'
g137_n_central_len equ $-g137_n_central
g137_n_dirichlet: db 'dirichlet'
g137_n_dirichlet_len equ $-g137_n_dirichlet
g137_n_value: db 'value'
g137_n_value_len equ $-g137_n_value
g137_n_component: db 'component'
g137_n_component_len equ $-g137_n_component
g137_n_dimensions: db 'dimensions'
g137_n_dimensions_len equ $-g137_n_dimensions
g137_n_method: db 'method'
g137_n_method_len equ $-g137_n_method
g137_n_unit: db 'unit'
g137_n_unit_len equ $-g137_n_unit
g137_n_iterations: db 'iterations'
g137_n_iterations_len equ $-g137_n_iterations
g137_n_budget: db 'budget'
g137_n_budget_len equ $-g137_n_budget
g137_n_status: db 'status'
g137_n_status_len equ $-g137_n_status
g137_n_converged: db 'converged'
g137_n_converged_len equ $-g137_n_converged
g137_n_error: db 'error'
g137_n_error_len equ $-g137_n_error

section .bss align=16
g137_scratch_start:
g137_kind: resq 1
g137_method: resq 1
g137_policy: resq 1
g137_boundary: resq 1
g137_dimensions: resq 1
g137_unit: resq 1
g137_point: resq 1
g137_step: resq 1
g137_budget: resq 1
g137_values: resq G137_VALUE_CAPACITY
g137_value_count: resq 1
g137_result: resq G137_COMPONENT_CAPACITY
g137_result_count: resq 1
g137_status: resq 1
g137_iterations: resq 1
g137_error: resq 1
g137_converged: resq 1
g137_scratch_end:

section .text

g137_api_at:
 push rbx
 mov rbx,rdi
%macro G137_API_MATCH 1
 mov rdi,rbx
 lea rsi,[rel g137_n_%1]
 mov edx,g137_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G137_API_MATCH partial
 G137_API_MATCH gradient
 G137_API_MATCH divergence
 G137_API_MATCH curl
 G137_API_MATCH laplacian
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G137_API_MATCH

; Only a complete expression position can select G137.  Member calls from
; older scientific APIs therefore remain owned by their original vertical.
g137_is_program:
 push rbx
 xor ebx,ebx
.scan:
 cmp rbx,[rel ls_token_count]
 jae .no
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_PARTIAL_DERIVATIVE
 je .candidate
 cmp eax,NEBOC_TOKEN_GRADIENT
 je .candidate
 cmp eax,NEBOC_TOKEN_DIVERGENCE
 je .candidate
 cmp eax,NEBOC_TOKEN_CURL
 je .candidate
 cmp eax,NEBOC_TOKEN_LAPLACIAN
 je .candidate
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .next
 mov rdi,rbx
 call g137_api_at
 test eax,eax
 jz .next
.candidate:
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

g137_expect_comma:
 sub rsp,8
 mov edi,NEBOC_TOKEN_COMMA
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

g137_empty_call:
 sub rsp,8
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_RPAREN
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

g137_parse_list:
 push rbx
 mov edi,NEBOC_TOKEN_RESERVED_LBRACKET
 call ls_expect_kind
 test eax,eax
 jz .syntax
 xor ebx,ebx
.value:
 cmp rbx,G137_VALUE_CAPACITY
 jae .domain
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov [g137_values+rbx*8],rdx
 inc rbx
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 je .more
 cmp eax,NEBOC_TOKEN_RESERVED_RBRACKET
 jne .syntax
 inc qword [rel ls_cursor]
 mov [rel g137_value_count],rbx
 xor eax,eax
 jmp .done
.more:
 inc qword [rel ls_cursor]
 jmp .value
.domain:
 mov eax,28
 jmp .done
.syntax:
 mov rax,-1
.done:
 pop rbx
 ret

g137_parse_head:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_PARTIAL_DERIVATIVE
 je .partial
 cmp eax,NEBOC_TOKEN_GRADIENT
 je .gradient
 cmp eax,NEBOC_TOKEN_DIVERGENCE
 je .divergence
 cmp eax,NEBOC_TOKEN_CURL
 je .curl
 cmp eax,NEBOC_TOKEN_LAPLACIAN
 je .laplacian
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
%macro G137_HEAD_MATCH 2
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g137_n_%1]
 mov edx,g137_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .%2
%endmacro
 G137_HEAD_MATCH partial,partial
 G137_HEAD_MATCH gradient,gradient
 G137_HEAD_MATCH divergence,divergence
 G137_HEAD_MATCH curl,curl
 G137_HEAD_MATCH laplacian,laplacian
 jmp .syntax
.laplacian:
 mov qword [rel g137_kind],G137_LAPLACIAN
 jmp .advance
.curl:
 mov qword [rel g137_kind],G137_CURL
 jmp .advance
.divergence:
 mov qword [rel g137_kind],G137_DIVERGENCE
 jmp .advance
.gradient:
 mov qword [rel g137_kind],G137_GRADIENT
 jmp .advance
.partial:
 mov qword [rel g137_kind],G137_PARTIAL
.advance:
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 xor eax,eax
 ret
.syntax:
 mov rax,-1
 ret
%undef G137_HEAD_MATCH

g137_parse_unit:
 lea rsi,[rel g137_n_unitless]
 mov edx,g137_n_unitless_len
 call ls_current_atom
 test eax,eax
 jnz .unitless
 lea rsi,[rel g137_n_meters]
 mov edx,g137_n_meters_len
 call ls_current_atom
 test eax,eax
 jz .domain
 mov qword [rel g137_unit],2
 jmp .yes
.unitless:
 mov qword [rel g137_unit],1
.yes:
 inc qword [rel ls_cursor]
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret

g137_parse_method:
 lea rsi,[rel g137_n_autodiff]
 mov edx,g137_n_autodiff_len
 call ls_current_atom
 test eax,eax
 jnz .autodiff
 lea rsi,[rel g137_n_symbolic]
 mov edx,g137_n_symbolic_len
 call ls_current_atom
 test eax,eax
 jnz .symbolic
 lea rsi,[rel g137_n_numeric]
 mov edx,g137_n_numeric_len
 call ls_current_atom
 test eax,eax
 jz .domain
 mov qword [rel g137_method],G137_METHOD_NUMERIC
 jmp .yes
.symbolic:
 mov qword [rel g137_method],G137_METHOD_SYMBOLIC
 jmp .yes
.autodiff:
 mov qword [rel g137_method],G137_METHOD_AUTODIFF
.yes:
 inc qword [rel ls_cursor]
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret

g137_parse_policy:
 lea rsi,[rel g137_n_analytic]
 mov edx,g137_n_analytic_len
 call ls_current_atom
 test eax,eax
 jnz .analytic
 lea rsi,[rel g137_n_central]
 mov edx,g137_n_central_len
 call ls_current_atom
 test eax,eax
 jz .domain
 mov qword [rel g137_policy],G137_POLICY_CENTRAL
 jmp .yes
.analytic:
 mov qword [rel g137_policy],G137_POLICY_ANALYTIC
.yes:
 inc qword [rel ls_cursor]
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret

; Parse `unit, method, policy` after either a binder or dimension count.
g137_parse_profile:
 call g137_expect_comma
 test eax,eax
 jnz .done
 call g137_parse_unit
 test eax,eax
 jnz .done
 call g137_expect_comma
 test eax,eax
 jnz .done
 call g137_parse_method
 test eax,eax
 jnz .done
 call g137_expect_comma
 test eax,eax
 jnz .done
 call g137_parse_policy
.done:
 ret

g137_parse_positive_int:
 call g137_expect_comma
 test eax,eax
 jnz .done
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 test rdx,rdx
 jle .domain
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.syntax:
 mov rax,-1
.done:
 ret

g137_parse_tail_list:
 call g137_expect_comma
 test eax,eax
 jnz .done
 call g137_parse_list
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 xor eax,eax
 ret
.syntax:
 mov rax,-1
.done:
 ret

g137_parse_partial:
 ; Selected variable is a real binder token, not a string.
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 inc qword [rel ls_cursor]
 mov qword [rel g137_dimensions],1
 call g137_parse_profile
 test eax,eax
 jnz .done
 call g137_expect_comma
 test eax,eax
 jnz .done
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov [rel g137_point],rdx
 call g137_parse_positive_int
 test eax,eax
 jnz .done
 mov [rel g137_step],rdx
 call g137_parse_positive_int
 test eax,eax
 jnz .done
 cmp rdx,65536
 ja .domain
 mov [rel g137_budget],rdx
 call g137_parse_tail_list
 ret
.domain:
 mov eax,28
 ret
.syntax:
 mov rax,-1
.done:
 ret

g137_parse_dimensions:
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 test rdx,rdx
 jle .domain
 cmp rdx,G137_COMPONENT_CAPACITY
 ja .domain
 mov [rel g137_dimensions],rdx
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.syntax:
 mov rax,-1
 ret

g137_parse_vector:
 call g137_parse_dimensions
 test eax,eax
 jnz .done
 call g137_parse_profile
 test eax,eax
 jnz .done
 cmp qword [rel g137_kind],G137_LAPLACIAN
 je .laplacian_boundary
 cmp qword [rel g137_kind],G137_GRADIENT
 jne .budget
 call g137_parse_positive_int
 test eax,eax
 jnz .done
 mov [rel g137_step],rdx
 jmp .budget
.laplacian_boundary:
 call g137_expect_comma
 test eax,eax
 jnz .done
 lea rsi,[rel g137_n_dirichlet]
 mov edx,g137_n_dirichlet_len
 call ls_current_atom
 test eax,eax
 jz .domain
 inc qword [rel ls_cursor]
 mov qword [rel g137_boundary],G137_BOUNDARY_DIRICHLET
 call g137_parse_positive_int
 test eax,eax
 jnz .done
 mov [rel g137_step],rdx
 call g137_expect_comma
 test eax,eax
 jnz .done
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov [rel g137_point],rdx
.budget:
 call g137_parse_positive_int
 test eax,eax
 jnz .done
 cmp rdx,65536
 ja .domain
 mov [rel g137_budget],rdx
 call g137_parse_tail_list
 ret
.domain:
 mov eax,28
 ret
.syntax:
 mov rax,-1
.done:
 ret

g137_require_numeric_vector:
 cmp qword [rel g137_policy],G137_POLICY_CENTRAL
 jne .no
 cmp qword [rel g137_method],G137_METHOD_NUMERIC
 je .yes
 cmp qword [rel g137_kind],G137_GRADIENT
 jne .no
 cmp qword [rel g137_method],G137_METHOD_AUTODIFF
 jne .no
.yes:
 xor eax,eax
 ret
.no:
 mov eax,28
 ret

g137_budget_check:
 ; RDI is the number of reference evaluations required.
 cmp rdi,[rel g137_budget]
 jbe .yes
 mov qword [rel g137_status],G137_STATUS_BUDGET
 mov qword [rel g137_converged],0
 mov [rel g137_iterations],rdi
 mov eax,1
 ret
.yes:
 mov [rel g137_iterations],rdi
 xor eax,eax
 ret

g137_calculate_partial:
 cmp qword [rel g137_value_count],2
 jne .domain
 cmp qword [rel g137_method],G137_METHOD_NUMERIC
 je .numeric
 cmp qword [rel g137_policy],G137_POLICY_ANALYTIC
 jne .domain
 mov edi,1
 call g137_budget_check
 test eax,eax
 jnz .ok
 mov rcx,[rel g137_values+8]
 test rcx,rcx
 js .domain
 cmp rcx,16
 ja .domain
 test rcx,rcx
 jz .zero
 mov r8,1
 mov r9,rcx
 dec r9
.power:
 test r9,r9
 jz .scaled
 imul r8,[rel g137_point]
 jo .overflow
 dec r9
 jmp .power
.scaled:
 imul r8,[rel g137_values]
 jo .overflow
 imul r8,rcx
 jo .overflow
 mov [rel g137_result],r8
 jmp .publish
.zero:
 mov qword [rel g137_result],0
 jmp .publish
.numeric:
 cmp qword [rel g137_policy],G137_POLICY_CENTRAL
 jne .domain
 mov edi,2
 call g137_budget_check
 test eax,eax
 jnz .ok
 mov rax,[rel g137_values]
 sub rax,[rel g137_values+8]
 jo .overflow
 mov rcx,[rel g137_step]
 add rcx,rcx
 jo .overflow
 cqo
 idiv rcx
 test rdx,rdx
 jnz .domain
 mov [rel g137_result],rax
.publish:
 mov qword [rel g137_result_count],1
.ok:
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.overflow:
 mov eax,10
 ret

g137_calculate_gradient:
 call g137_require_numeric_vector
 test eax,eax
 jnz .done
 mov rcx,[rel g137_dimensions]
 mov rax,rcx
 add rax,rax
 jo .overflow
 cmp [rel g137_value_count],rax
 jne .domain
 mov rdi,rax
 call g137_budget_check
 test eax,eax
 jnz .ok
 mov r10,[rel g137_step]
 add r10,r10
 jo .overflow
 xor r9d,r9d
.loop:
 mov rax,[g137_values+r9*8]
 mov r11,r9
 add r11,rcx
 sub rax,[g137_values+r11*8]
 jo .overflow
 cqo
 idiv r10
 test rdx,rdx
 jnz .domain
 mov [g137_result+r9*8],rax
 inc r9
 cmp r9,rcx
 jb .loop
 mov [rel g137_result_count],rcx
.ok:
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.overflow:
 mov eax,10
.done:
 ret

g137_calculate_divergence:
 call g137_require_numeric_vector
 test eax,eax
 jnz .done
 mov rcx,[rel g137_dimensions]
 cmp [rel g137_value_count],rcx
 jne .domain
 mov rdi,rcx
 call g137_budget_check
 test eax,eax
 jnz .ok
 xor eax,eax
 xor r9d,r9d
.loop:
 add rax,[g137_values+r9*8]
 jo .overflow
 inc r9
 cmp r9,rcx
 jb .loop
 mov [rel g137_result],rax
 mov qword [rel g137_result_count],1
.ok:
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.overflow:
 mov eax,10
.done:
 ret

g137_calculate_curl:
 call g137_require_numeric_vector
 test eax,eax
 jnz .done
 cmp qword [rel g137_dimensions],3
 jne .domain
 cmp qword [rel g137_value_count],9
 jne .domain
 mov edi,9
 call g137_budget_check
 test eax,eax
 jnz .ok
 mov r8,[rel g137_values+56]
 sub r8,[rel g137_values+40]
 jo .overflow
 mov r9,[rel g137_values+16]
 sub r9,[rel g137_values+48]
 jo .overflow
 mov r10,[rel g137_values+24]
 sub r10,[rel g137_values+8]
 jo .overflow
 mov [rel g137_result],r8
 mov [rel g137_result+8],r9
 mov [rel g137_result+16],r10
 mov qword [rel g137_result_count],3
.ok:
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.overflow:
 mov eax,10
.done:
 ret

g137_calculate_laplacian:
 call g137_require_numeric_vector
 test eax,eax
 jnz .done
 cmp qword [rel g137_boundary],G137_BOUNDARY_DIRICHLET
 jne .domain
 mov rcx,[rel g137_dimensions]
 mov rax,rcx
 add rax,rax
 jo .overflow
 cmp [rel g137_value_count],rax
 jne .domain
 mov rdi,rax
 call g137_budget_check
 test eax,eax
 jnz .ok
 mov r8,[rel g137_point]
 add r8,r8
 jo .overflow
 xor eax,eax
 xor r9d,r9d
.loop:
 mov r10,[g137_values+r9*8]
 mov r11,r9
 add r11,rcx
 add r10,[g137_values+r11*8]
 jo .overflow
 sub r10,r8
 jo .overflow
 add rax,r10
 jo .overflow
 inc r9
 cmp r9,rcx
 jb .loop
 cqo
 idiv qword [rel g137_step]
 test rdx,rdx
 jnz .domain
 mov [rel g137_result],rax
 mov qword [rel g137_result_count],1
.ok:
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.overflow:
 mov eax,10
.done:
 ret

g137_calculate:
 mov qword [rel g137_converged],1
 cmp qword [rel g137_kind],G137_PARTIAL
 je g137_calculate_partial
 cmp qword [rel g137_kind],G137_GRADIENT
 je g137_calculate_gradient
 cmp qword [rel g137_kind],G137_DIVERGENCE
 je g137_calculate_divergence
 cmp qword [rel g137_kind],G137_CURL
 je g137_calculate_curl
 jmp g137_calculate_laplacian

g137_require_success:
 cmp qword [rel g137_status],0
 jne .no
 xor eax,eax
 ret
.no:
 mov eax,28
 ret

g137_parse_observer:
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
%macro G137_OBSERVER 2
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g137_n_%1]
 mov edx,g137_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .%2
%endmacro
 G137_OBSERVER value,value
 G137_OBSERVER component,component
 G137_OBSERVER dimensions,dimensions
 G137_OBSERVER method,method
 G137_OBSERVER unit,unit
 G137_OBSERVER iterations,iterations
 G137_OBSERVER budget,budget
 G137_OBSERVER status,status
 G137_OBSERVER converged,converged
 G137_OBSERVER error,error
 jmp .syntax
.value:
 call g137_require_success
 test eax,eax
 jnz .done
 cmp qword [rel g137_result_count],1
 jne .domain
 mov rdx,[rel g137_result]
 push rdx
 inc qword [rel ls_cursor]
 call g137_empty_call
 pop rdx
 ret
.component:
 call g137_require_success
 test eax,eax
 jnz .done
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 test rdx,rdx
 js .domain
 cmp rdx,[rel g137_result_count]
 jae .domain
 mov r8,[g137_result+rdx*8]
 push r8
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 pop rdx
 test eax,eax
 jz .syntax
 xor eax,eax
 ret
.dimensions:
 mov rdx,[rel g137_dimensions]
 jmp .empty
.method:
 mov rdx,[rel g137_method]
 jmp .empty
.unit:
 mov rdx,[rel g137_unit]
 jmp .empty
.iterations:
 mov rdx,[rel g137_iterations]
 jmp .empty
.budget:
 mov rdx,[rel g137_budget]
 jmp .empty
.status:
 mov rdx,[rel g137_status]
 jmp .empty
.converged:
 mov rdx,[rel g137_converged]
 jmp .empty
.error:
 mov rdx,[rel g137_error]
.empty:
 push rdx
 inc qword [rel ls_cursor]
 call g137_empty_call
 pop rdx
 ret
.domain:
 mov eax,28
 ret
.syntax:
 mov rax,-1
.done:
 ret
%undef G137_OBSERVER

g137_parse_term:
 call g137_parse_head
 test eax,eax
 jnz .done
 cmp qword [rel g137_kind],G137_PARTIAL
 jne .vector
 call g137_parse_partial
 jmp .parsed
.vector:
 call g137_parse_vector
.parsed:
 test eax,eax
 jnz .done
 call g137_calculate
 test eax,eax
 jnz .done
 call g137_parse_observer
.done:
 ret

g137_parse_program:
 push rbx
 sub rsp,16
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call .clear_term
 call g137_parse_term
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
 call g137_parse_term
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
 mov rdx,G137_FAMILY_KEY
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
 lea rdi,[rel g137_scratch_start]
 mov ecx,(g137_scratch_end-g137_scratch_start)/8
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
