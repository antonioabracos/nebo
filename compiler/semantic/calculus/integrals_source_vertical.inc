; G136 bounded source owner for exact numeric and symbolic integrals.  The
; grammar is deliberately explicit: binder variables, domains, methods,
; tolerances and budgets are source operands, and every call produces an
; IntegralResult observed through a checked method.  Values are evaluated
; once into caller-owned compiler scratch and lowered as one scalar effect.

%define G136_FAMILY_KEY 0x5246323034473136
%define G136_SAMPLE_CAPACITY 32
%define G136_SINGLE 1
%define G136_DOUBLE 2
%define G136_TRIPLE 3
%define G136_CONTOUR 4
%define G136_METHOD_TRAPEZOID 1
%define G136_METHOD_ADAPTIVE 2
%define G136_METHOD_RECTANGLE 3
%define G136_METHOD_LINE 4
%define G136_STATUS_BUDGET -12
%define G136_STATUS_NOT_CONVERGED -14
%define G136_STATUS_SYMBOLIC_UNSUPPORTED -15

section .rodata
g136_n_integrate: db 'integrate'
g136_n_integrate_len equ $-g136_n_integrate
g136_n_integrate2d: db 'integrate2D'
g136_n_integrate2d_len equ $-g136_n_integrate2d
g136_n_integrate3d: db 'integrate3D'
g136_n_integrate3d_len equ $-g136_n_integrate3d
g136_n_contour_integrate: db 'contourIntegrate'
g136_n_contour_integrate_len equ $-g136_n_contour_integrate
g136_n_indefinite: db 'indefinite'
g136_n_indefinite_len equ $-g136_n_indefinite
g136_n_symbolic: db 'symbolic'
g136_n_symbolic_len equ $-g136_n_symbolic
g136_n_trapezoid: db 'trapezoid'
g136_n_trapezoid_len equ $-g136_n_trapezoid
g136_n_adaptive: db 'adaptive'
g136_n_adaptive_len equ $-g136_n_adaptive
g136_n_rectangle: db 'rectangle'
g136_n_rectangle_len equ $-g136_n_rectangle
g136_n_line: db 'line'
g136_n_line_len equ $-g136_n_line
g136_n_clockwise: db 'clockwise'
g136_n_clockwise_len equ $-g136_n_clockwise
g136_n_counterclockwise: db 'counterclockwise'
g136_n_counterclockwise_len equ $-g136_n_counterclockwise
g136_n_value: db 'value'
g136_n_value_len equ $-g136_n_value
g136_n_numerator: db 'numerator'
g136_n_numerator_len equ $-g136_n_numerator
g136_n_denominator: db 'denominator'
g136_n_denominator_len equ $-g136_n_denominator
g136_n_error: db 'error'
g136_n_error_len equ $-g136_n_error
g136_n_iterations: db 'iterations'
g136_n_iterations_len equ $-g136_n_iterations
g136_n_status: db 'status'
g136_n_status_len equ $-g136_n_status
g136_n_converged: db 'converged'
g136_n_converged_len equ $-g136_n_converged
g136_n_exponent: db 'exponent'
g136_n_exponent_len equ $-g136_n_exponent
g136_n_constant: db 'constant'
g136_n_constant_len equ $-g136_n_constant
g136_n_orientation: db 'orientation'
g136_n_orientation_len equ $-g136_n_orientation

section .bss align=16
g136_scratch_start:
g136_kind: resq 1
g136_method: resq 1
g136_tolerance: resq 1
g136_budget: resq 1
g136_orientation: resq 1
g136_axis_names: resq 3
g136_axis_lower: resq 3
g136_axis_upper: resq 3
g136_samples: resq G136_SAMPLE_CAPACITY
g136_sample_count: resq 1
g136_res_status: resq 1
g136_res_num: resq 1
g136_res_den: resq 1
g136_res_error: resq 1
g136_res_iterations: resq 1
g136_res_converged: resq 1
g136_res_exponent: resq 1
g136_res_constant: resq 1
g136_res_orientation: resq 1
g136_scratch_end:

section .text

; Token index RDI -> EAX boolean for a portable integral API.
g136_api_at:
 push rbx
 mov rbx,rdi
%macro G136_API_MATCH 1
 mov rdi,rbx
 lea rsi,[rel g136_n_%1]
 mov edx,g136_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G136_API_MATCH integrate
 G136_API_MATCH integrate2d
 G136_API_MATCH integrate3d
 G136_API_MATCH contour_integrate
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G136_API_MATCH

; Claim a source only when an exact Registry binder or portable API appears.
g136_is_program:
 push rbx
 xor ebx,ebx
.scan:
 cmp rbx,[rel ls_token_count]
 jae .no
 mov rdi,rbx
    call ls_kind_at
    cmp eax,NEBOC_TOKEN_INTEGRAL_SINGLE
    je .candidate
    cmp eax,NEBOC_TOKEN_INTEGRAL_DOUBLE
    je .candidate
    cmp eax,NEBOC_TOKEN_INTEGRAL_TRIPLE
    je .candidate
    cmp eax,NEBOC_TOKEN_INTEGRAL_CONTOUR
    je .candidate
    cmp eax,NEBOC_TOKEN_IDENTIFIER
    jne .next
    mov rdi,rbx
    call g136_api_at
    test eax,eax
    jz .next
.candidate:
    ; The G136 grammar only permits a binder at the start of the body or
    ; immediately after its explicit composition operator.  This prevents a
    ; member call such as `expression.integrate(...)` from stealing an older
    ; source vertical merely because it shares the portable API spelling.
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

g136_expect_comma:
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

g136_empty_call:
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

; Parse identifier, lower and upper bound for axis RDI.
g136_parse_axis:
 push rbx
 push r12
 mov rbx,rdi
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rax,[rel ls_cursor]
 mov [g136_axis_names+rbx*8],rax
 inc qword [rel ls_cursor]
 call g136_expect_comma
 test eax,eax
 jnz .done
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov r12,rdx
 call g136_expect_comma
 test eax,eax
 jnz .done
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 cmp rdx,r12
 jle .domain
 mov [g136_axis_lower+rbx*8],r12
 mov [g136_axis_upper+rbx*8],rdx
 xor eax,eax
 jmp .done
.domain:
 mov eax,28
 jmp .done
.syntax:
 mov rax,-1
.done:
 pop r12
 pop rbx
 ret

; Parse a non-empty bounded signed-int list.
g136_parse_list:
 push rbx
 mov edi,NEBOC_TOKEN_RESERVED_LBRACKET
 call ls_expect_kind
 test eax,eax
 jz .syntax
 xor ebx,ebx
.value:
 cmp rbx,G136_SAMPLE_CAPACITY
 jae .limit
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov [g136_samples+rbx*8],rdx
 inc rbx
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 je .more
 cmp eax,NEBOC_TOKEN_RESERVED_RBRACKET
 jne .syntax
 inc qword [rel ls_cursor]
 mov [rel g136_sample_count],rbx
 xor eax,eax
 jmp .done
.more:
 inc qword [rel ls_cursor]
 jmp .value
.limit:
 mov eax,12
 jmp .done
.syntax:
 mov rax,-1
.done:
 pop rbx
 ret

; RDI axis count. Require distinct binder variables.
g136_validate_axes:
 cmp rdi,2
 jb .yes
 mov rdi,[rel g136_axis_names]
 mov rsi,[rel g136_axis_names+8]
 call ls_name_equal
 test eax,eax
 jnz .no
 cmp qword [rel g136_kind],G136_TRIPLE
 jne .yes
 mov rdi,[rel g136_axis_names]
 mov rsi,[rel g136_axis_names+16]
 call ls_name_equal
 test eax,eax
 jnz .no
 mov rdi,[rel g136_axis_names+8]
 mov rsi,[rel g136_axis_names+16]
 call ls_name_equal
 test eax,eax
 jnz .no
.yes:
 xor eax,eax
 ret
.no:
 mov eax,28
 ret

; Parse the operator/API and leave the cursor after `(`.
g136_parse_head:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGRAL_SINGLE
 je .single
 cmp eax,NEBOC_TOKEN_INTEGRAL_DOUBLE
 je .double
 cmp eax,NEBOC_TOKEN_INTEGRAL_TRIPLE
 je .triple
 cmp eax,NEBOC_TOKEN_INTEGRAL_CONTOUR
 je .contour
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g136_n_integrate]
 mov edx,g136_n_integrate_len
 call ls_token_match
 test eax,eax
 jnz .single
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g136_n_integrate2d]
 mov edx,g136_n_integrate2d_len
 call ls_token_match
 test eax,eax
 jnz .double
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g136_n_integrate3d]
 mov edx,g136_n_integrate3d_len
 call ls_token_match
 test eax,eax
 jnz .triple
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g136_n_contour_integrate]
 mov edx,g136_n_contour_integrate_len
 call ls_token_match
 test eax,eax
 jz .syntax
.contour:
 mov qword [rel g136_kind],G136_CONTOUR
 jmp .advance
.triple:
 mov qword [rel g136_kind],G136_TRIPLE
 jmp .advance
.double:
 mov qword [rel g136_kind],G136_DOUBLE
 jmp .advance
.single:
 mov qword [rel g136_kind],G136_SINGLE
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

; Parse a method identifier appropriate to the active integral kind.
g136_parse_method:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 cmp qword [rel g136_kind],G136_SINGLE
 jne .not_single
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g136_n_trapezoid]
 mov edx,g136_n_trapezoid_len
 call ls_token_match
 test eax,eax
 jnz .trapezoid
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g136_n_adaptive]
 mov edx,g136_n_adaptive_len
 call ls_token_match
 test eax,eax
 jnz .adaptive
 jmp .domain
.not_single:
 cmp qword [rel g136_kind],G136_CONTOUR
 je .line_check
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g136_n_rectangle]
 mov edx,g136_n_rectangle_len
 call ls_token_match
 test eax,eax
 jnz .rectangle
 jmp .domain
.line_check:
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g136_n_line]
 mov edx,g136_n_line_len
 call ls_token_match
 test eax,eax
 jz .domain
 mov qword [rel g136_method],G136_METHOD_LINE
 jmp .yes
.rectangle:
 mov qword [rel g136_method],G136_METHOD_RECTANGLE
 jmp .yes
.adaptive:
 mov qword [rel g136_method],G136_METHOD_ADAPTIVE
 jmp .yes
.trapezoid:
 mov qword [rel g136_method],G136_METHOD_TRAPEZOID
.yes:
 inc qword [rel ls_cursor]
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.syntax:
 mov rax,-1
 ret

; Parse positive tolerance/budget and the sample list.
g136_parse_controls_and_samples:
 call g136_expect_comma
 test eax,eax
 jnz .done
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 test rdx,rdx
 jle .domain
 mov [rel g136_tolerance],rdx
 call g136_expect_comma
 test eax,eax
 jnz .done
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 test rdx,rdx
 jle .domain
 mov [rel g136_budget],rdx
 call g136_expect_comma
 test eax,eax
 jnz .done
 call g136_parse_list
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.syntax:
 mov rax,-1
.done:
 ret

; Parse `binder, indefinite, symbolic, maxExponent, [coefficient, exponent])`.
g136_parse_symbolic:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rax,[rel ls_cursor]
 mov [rel g136_axis_names],rax
 inc qword [rel ls_cursor]
 call g136_expect_comma
 test eax,eax
 jnz .done
 lea rsi,[rel g136_n_indefinite]
 mov edx,g136_n_indefinite_len
 call ls_current_atom
 test eax,eax
 jz .syntax
 inc qword [rel ls_cursor]
 call g136_expect_comma
 test eax,eax
 jnz .done
 lea rsi,[rel g136_n_symbolic]
 mov edx,g136_n_symbolic_len
 call ls_current_atom
 test eax,eax
 jz .domain
 inc qword [rel ls_cursor]
 call g136_expect_comma
 test eax,eax
 jnz .done
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 test rdx,rdx
 js .domain
 mov [rel g136_budget],rdx
 call g136_expect_comma
 test eax,eax
 jnz .done
 call g136_parse_list
 test eax,eax
 jnz .done
 cmp qword [rel g136_sample_count],2
 jne .domain
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov qword [rel g136_method],G136_METHOD_TRAPEZOID
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.syntax:
 mov rax,-1
.done:
 ret

; Clear and compute a bounded IntegralResult for the parsed call.
g136_calculate:
 lea rdi,[rel g136_res_status]
 mov ecx,9
 xor eax,eax
 rep stosq
 mov qword [rel g136_res_den],1
 mov qword [rel g136_res_converged],1
 cmp qword [rel g136_kind],G136_SINGLE
 je .single
 cmp qword [rel g136_kind],G136_DOUBLE
 je .grid
 cmp qword [rel g136_kind],G136_TRIPLE
 je .grid
 jmp .contour
.single:
 cmp qword [rel g136_method],G136_METHOD_TRAPEZOID
 je .symbolic_or_numeric
 jmp .numeric_single
.symbolic_or_numeric:
 cmp qword [rel g136_sample_count],2
 jne .numeric_single
 cmp qword [rel g136_axis_upper],0
 jne .numeric_single
 cmp qword [rel g136_axis_lower],0
 jne .numeric_single
 ; Symbolic state uses budget as the explicit maximum admitted exponent.
 mov rax,[rel g136_samples+8]
 test rax,rax
 js .domain
 cmp rax,[rel g136_budget]
 ja .symbolic_unsupported
 inc rax
 jo .overflow
 mov [rel g136_res_den],rax
 mov [rel g136_res_exponent],rax
 mov rdx,[rel g136_samples]
 mov [rel g136_res_num],rdx
 mov qword [rel g136_res_constant],1
 mov qword [rel g136_res_iterations],1
 xor eax,eax
 ret
.symbolic_unsupported:
 mov qword [rel g136_res_status],G136_STATUS_SYMBOLIC_UNSUPPORTED
 mov qword [rel g136_res_converged],0
 mov qword [rel g136_res_iterations],1
 xor eax,eax
 ret
.numeric_single:
 mov rcx,[rel g136_sample_count]
 cmp rcx,2
 jb .domain
 cmp rcx,[rel g136_budget]
 ja .budget_samples
 mov r8,[rel g136_samples]
 add r8,[g136_samples+rcx*8-8]
 jo .overflow
 mov r9d,1
.single_sum:
 mov rax,rcx
 dec rax
 cmp r9,rax
 jae .single_scale
 mov rax,[g136_samples+r9*8]
 add rax,rax
 jo .overflow
 add r8,rax
 jo .overflow
 inc r9
 jmp .single_sum
.single_scale:
 mov rax,[rel g136_axis_upper]
 sub rax,[rel g136_axis_lower]
 jo .overflow
 imul r8,rax
 jo .overflow
 mov [rel g136_res_num],r8
 dec rcx
 add rcx,rcx
 jo .overflow
 mov [rel g136_res_den],rcx
 mov rax,[rel g136_sample_count]
 mov [rel g136_res_iterations],rax
 cmp qword [rel g136_method],G136_METHOD_ADAPTIVE
 jne .ok
 ; The bounded adaptive estimator compares exact coarse and fine integers.
 mov rax,[rel g136_res_num]
 cqo
 idiv qword [rel g136_res_den]
 test rdx,rdx
 jnz .domain
 mov r10,rax
 mov rax,[rel g136_samples]
 mov rcx,[rel g136_sample_count]
 add rax,[g136_samples+rcx*8-8]
 jo .overflow
 mov rcx,[rel g136_axis_upper]
 sub rcx,[rel g136_axis_lower]
 jo .overflow
 imul rax,rcx
 jo .overflow
 cqo
 mov ecx,2
 idiv rcx
 test rdx,rdx
 jnz .domain
 sub r10,rax
 jo .overflow
 jns .adaptive_abs
 neg r10
 jo .overflow
.adaptive_abs:
 mov [rel g136_res_error],r10
 cmp r10,[rel g136_tolerance]
 jbe .ok
 mov qword [rel g136_res_status],G136_STATUS_NOT_CONVERGED
 mov qword [rel g136_res_converged],0
 xor eax,eax
 ret
.grid:
 mov rcx,[rel g136_sample_count]
 test rcx,rcx
 jz .domain
 cmp rcx,[rel g136_budget]
 ja .budget_samples
 xor r8d,r8d
 xor r9d,r9d
.grid_sum:
 add r8,[g136_samples+r9*8]
 jo .overflow
 inc r9
 cmp r9,rcx
 jb .grid_sum
 mov rax,[rel g136_axis_upper]
 sub rax,[rel g136_axis_lower]
 jo .overflow
 mov rdx,[rel g136_axis_upper+8]
 sub rdx,[rel g136_axis_lower+8]
 jo .overflow
 imul rax,rdx
 jo .overflow
 cmp qword [rel g136_kind],G136_TRIPLE
 jne .grid_volume
 mov rdx,[rel g136_axis_upper+16]
 sub rdx,[rel g136_axis_lower+16]
 jo .overflow
 imul rax,rdx
 jo .overflow
.grid_volume:
 imul r8,rax
 jo .overflow
 mov [rel g136_res_num],r8
 mov [rel g136_res_den],rcx
 mov [rel g136_res_iterations],rcx
 xor eax,eax
 ret
.contour:
 mov rcx,[rel g136_sample_count]
 test rcx,rcx
 jz .domain
 test rcx,3
 jnz .domain
 shr rcx,2
 mov rax,[rel g136_axis_upper]
 sub rax,[rel g136_axis_lower]
 jo .overflow
 cmp rcx,rax
 jne .domain
 cmp rcx,[rel g136_budget]
 ja .budget_iterations
 xor r8d,r8d
 xor r9d,r9d
.contour_sum:
 mov rax,r9
 shl rax,2
 mov rdx,[g136_samples+rax*8]
 imul rdx,[g136_samples+rax*8+16]
 jo .overflow
 mov r10,[g136_samples+rax*8+8]
 imul r10,[g136_samples+rax*8+24]
 jo .overflow
 add rdx,r10
 jo .overflow
 add r8,rdx
 jo .overflow
 inc r9
 cmp r9,rcx
 jb .contour_sum
 imul r8,[rel g136_orientation]
 jo .overflow
 mov [rel g136_res_num],r8
 mov [rel g136_res_iterations],rcx
 mov rax,[rel g136_orientation]
 mov [rel g136_res_orientation],rax
 xor eax,eax
 ret
.budget_samples:
 mov rcx,[rel g136_sample_count]
.budget_iterations:
 mov qword [rel g136_res_status],G136_STATUS_BUDGET
 mov [rel g136_res_iterations],rcx
 mov qword [rel g136_res_converged],0
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.overflow:
 mov eax,10
 ret
.ok:
 xor eax,eax
 ret

; Parse the checked IntegralResult observer and return its scalar in RDX.
g136_parse_observer:
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
%macro G136_OBSERVER 2
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g136_n_%1]
 mov edx,g136_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .%2
%endmacro
 G136_OBSERVER value,value
 G136_OBSERVER numerator,numerator
 G136_OBSERVER denominator,denominator
 G136_OBSERVER error,error
 G136_OBSERVER iterations,iterations
 G136_OBSERVER status,status
 G136_OBSERVER converged,converged
 G136_OBSERVER exponent,exponent
 G136_OBSERVER constant,constant
 G136_OBSERVER orientation,orientation
 jmp .syntax
.value:
 call .require_success
 test eax,eax
 jnz .done
 mov rax,[rel g136_res_num]
 cqo
 idiv qword [rel g136_res_den]
 test rdx,rdx
 jnz .domain
 mov rdx,rax
 jmp .consume
.numerator:
 call .require_success
 test eax,eax
 jnz .done
 mov rdx,[rel g136_res_num]
 jmp .consume
.denominator:
 call .require_success
 test eax,eax
 jnz .done
 mov rdx,[rel g136_res_den]
 jmp .consume
.error:
 mov rdx,[rel g136_res_error]
 jmp .consume
.iterations:
 mov rdx,[rel g136_res_iterations]
 jmp .consume
.status:
 mov rdx,[rel g136_res_status]
 jmp .consume
.converged:
 mov rdx,[rel g136_res_converged]
 jmp .consume
.exponent:
 call .require_success
 test eax,eax
 jnz .done
 mov rdx,[rel g136_res_exponent]
 jmp .consume
.constant:
 call .require_success
 test eax,eax
 jnz .done
 mov rdx,[rel g136_res_constant]
 jmp .consume
.orientation:
 call .require_success
 test eax,eax
 jnz .done
 mov rdx,[rel g136_res_orientation]
.consume:
 push rdx
 inc qword [rel ls_cursor]
 call g136_empty_call
 pop rdx
 test eax,eax
 jnz .done
 xor eax,eax
 ret
.require_success:
 cmp qword [rel g136_res_status],0
 jne .require_failed
 xor eax,eax
 ret
.require_failed:
 mov eax,28
 ret
.domain:
 mov eax,28
 jmp .done
.syntax:
 mov rax,-1
.done:
 ret
%undef G136_OBSERVER

; Parse one integral call and its observer.
g136_parse_term:
 call g136_parse_head
 test eax,eax
 jnz .done
 ; Single integral overload with an `indefinite` domain is symbolic.
 cmp qword [rel g136_kind],G136_SINGLE
 jne .numeric
 mov rdi,[rel ls_cursor]
 add rdi,2
 lea rsi,[rel g136_n_indefinite]
 mov edx,g136_n_indefinite_len
 call ls_token_match
 test eax,eax
 jz .numeric
 mov qword [rel g136_axis_lower],0
 mov qword [rel g136_axis_upper],0
 call g136_parse_symbolic
 test eax,eax
 jnz .done
 jmp .calculate
.numeric:
 xor edi,edi
 call g136_parse_axis
 test eax,eax
 jnz .done
 cmp qword [rel g136_kind],G136_SINGLE
 je .axes_done
 cmp qword [rel g136_kind],G136_CONTOUR
 je .axes_done
 call g136_expect_comma
 test eax,eax
 jnz .done
 mov edi,1
 call g136_parse_axis
 test eax,eax
 jnz .done
 cmp qword [rel g136_kind],G136_DOUBLE
 je .axes_done
 call g136_expect_comma
 test eax,eax
 jnz .done
 mov edi,2
 call g136_parse_axis
 test eax,eax
 jnz .done
.axes_done:
 mov rdi,[rel g136_kind]
 cmp rdi,G136_CONTOUR
 je .axes_valid
 call g136_validate_axes
 test eax,eax
 jnz .done
.axes_valid:
 call g136_expect_comma
 test eax,eax
 jnz .done
 call g136_parse_method
 test eax,eax
 jnz .done
 cmp qword [rel g136_kind],G136_CONTOUR
 jne .controls
 call g136_expect_comma
 test eax,eax
 jnz .done
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g136_n_clockwise]
 mov edx,g136_n_clockwise_len
 call ls_token_match
 test eax,eax
 jnz .clockwise
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g136_n_counterclockwise]
 mov edx,g136_n_counterclockwise_len
 call ls_token_match
 test eax,eax
 jz .domain
 mov qword [rel g136_orientation],1
 jmp .orientation_ready
.clockwise:
 mov qword [rel g136_orientation],-1
.orientation_ready:
 inc qword [rel ls_cursor]
.controls:
 call g136_parse_controls_and_samples
 test eax,eax
 jnz .done
.calculate:
 call g136_calculate
 test eax,eax
 jnz .done
 call g136_parse_observer
 ret
.domain:
 mov eax,28
.done:
 ret

; Complete bounded program: checked integral observations joined by checked +.
g136_parse_program:
 push rbx
 sub rsp,16
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call .clear_term
 call g136_parse_term
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
 call g136_parse_term
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
 mov rdx,G136_FAMILY_KEY
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
 lea rdi,[rel g136_scratch_start]
 mov ecx,(g136_scratch_end-g136_scratch_start)/8
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
