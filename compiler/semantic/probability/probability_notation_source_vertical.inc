; G138 bounded source owner for typed probability notation.  Model identity,
; distribution metadata, exact rational probabilities and budgets are explicit.
; Seeded sampling is deterministic and performs no allocation or ambient I/O.

%define G138_FAMILY_KEY 0x5246323034473138
%define G138_MODEL 1
%define G138_DISTRIBUTED 2
%define G138_INDEPENDENCE 3
%define G138_CONDITIONAL 4
%define G138_VARIABLE 5
%define G138_SAMPLE 6
%define G138_INFERENCE 7
%define G138_REPORT 8
%define G138_TYPE_DISCRETE 1
%define G138_TYPE_CONTINUOUS 2
%define G138_DIST_BERNOULLI 1
%define G138_DIST_UNIFORM 2
%define G138_MEASURE_COUNTING 1
%define G138_MEASURE_LEBESGUE 2
%define G138_REL_UNKNOWN 0
%define G138_REL_INDEPENDENT 1
%define G138_REL_DEPENDENT 2
%define G138_STATUS_OK 0
%define G138_STATUS_INVALID 1
%define G138_STATUS_UNKNOWN 2
%define G138_STATUS_BUDGET 3
%define G138_STATUS_LIMIT 4

section .rodata
g138_n_probabilityModel: db 'probabilityModel'
g138_n_probabilityModel_len equ $-g138_n_probabilityModel
g138_n_distributedAs: db 'distributedAs'
g138_n_distributedAs_len equ $-g138_n_distributedAs
g138_n_independentOf: db 'independentOf'
g138_n_independentOf_len equ $-g138_n_independentOf
g138_n_conditionalOn: db 'conditionalOn'
g138_n_conditionalOn_len equ $-g138_n_conditionalOn
g138_n_P: db 'P'
g138_n_P_len equ $-g138_n_P
g138_n_randomVariable: db 'randomVariable'
g138_n_randomVariable_len equ $-g138_n_randomVariable
g138_n_sampleProbability: db 'sampleProbability'
g138_n_sampleProbability_len equ $-g138_n_sampleProbability
g138_n_inferProbability: db 'inferProbability'
g138_n_inferProbability_len equ $-g138_n_inferProbability
g138_n_probabilityReport: db 'probabilityReport'
g138_n_probabilityReport_len equ $-g138_n_probabilityReport
g138_n_discrete: db 'discrete'
g138_n_discrete_len equ $-g138_n_discrete
g138_n_continuous: db 'continuous'
g138_n_continuous_len equ $-g138_n_continuous
g138_n_bernoulli: db 'bernoulli'
g138_n_bernoulli_len equ $-g138_n_bernoulli
g138_n_uniform: db 'uniform'
g138_n_uniform_len equ $-g138_n_uniform
g138_n_counting: db 'counting'
g138_n_counting_len equ $-g138_n_counting
g138_n_lebesgue: db 'lebesgue'
g138_n_lebesgue_len equ $-g138_n_lebesgue
g138_n_unknown: db 'unknown'
g138_n_unknown_len equ $-g138_n_unknown
g138_n_independent: db 'independent'
g138_n_independent_len equ $-g138_n_independent
g138_n_dependent: db 'dependent'
g138_n_dependent_len equ $-g138_n_dependent
g138_n_value: db 'value'
g138_n_value_len equ $-g138_n_value
g138_n_numerator: db 'numerator'
g138_n_numerator_len equ $-g138_n_numerator
g138_n_denominator: db 'denominator'
g138_n_denominator_len equ $-g138_n_denominator
g138_n_model: db 'model'
g138_n_model_len equ $-g138_n_model
g138_n_shape: db 'shape'
g138_n_shape_len equ $-g138_n_shape
g138_n_supportMin: db 'supportMin'
g138_n_supportMin_len equ $-g138_n_supportMin
g138_n_supportMax: db 'supportMax'
g138_n_supportMax_len equ $-g138_n_supportMax
g138_n_measure: db 'measure'
g138_n_measure_len equ $-g138_n_measure
g138_n_seed: db 'seed'
g138_n_seed_len equ $-g138_n_seed
g138_n_budget: db 'budget'
g138_n_budget_len equ $-g138_n_budget
g138_n_status: db 'status'
g138_n_status_len equ $-g138_n_status
g138_n_iterations: db 'iterations'
g138_n_iterations_len equ $-g138_n_iterations
g138_n_converged: db 'converged'
g138_n_converged_len equ $-g138_n_converged
g138_n_error: db 'error'
g138_n_error_len equ $-g138_n_error
g138_n_code: db 'code'
g138_n_code_len equ $-g138_n_code

section .bss align=16
g138_scratch_start:
g138_kind: resq 1
g138_model: resq 1
g138_budget: resq 1
g138_variable: resq 1
g138_variable_type: resq 1
g138_variable_shape: resq 1
g138_distribution: resq 1
g138_distribution_type: resq 1
g138_distribution_shape: resq 1
g138_support_min: resq 1
g138_support_max: resq 1
g138_measure: resq 1
g138_left: resq 1
g138_right: resq 1
g138_relation: resq 1
g138_joint_num: resq 1
g138_joint_den: resq 1
g138_condition_num: resq 1
g138_condition_den: resq 1
g138_seed: resq 1
g138_bound: resq 1
g138_successes: resq 1
g138_total: resq 1
g138_alpha: resq 1
g138_beta: resq 1
g138_report_status: resq 1
g138_result: resq 1
g138_numerator: resq 1
g138_denominator: resq 1
g138_status: resq 1
g138_iterations: resq 1
g138_converged: resq 1
g138_error: resq 1
g138_scratch_end:

section .text

g138_api_at:
 push rbx
 mov rbx,rdi
%macro G138_API_MATCH 1
 mov rdi,rbx
 lea rsi,[rel g138_n_%1]
 mov edx,g138_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G138_API_MATCH probabilityModel
 G138_API_MATCH distributedAs
 G138_API_MATCH independentOf
 G138_API_MATCH conditionalOn
 G138_API_MATCH randomVariable
 G138_API_MATCH sampleProbability
 G138_API_MATCH inferProbability
 G138_API_MATCH probabilityReport
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G138_API_MATCH

; Symbol tokens select this owner wherever they occur.  Portable APIs only
; select it at a complete expression position, preserving older member calls.
g138_is_program:
 push rbx
 xor ebx,ebx
.scan:
 cmp rbx,[rel ls_token_count]
 jae .no
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_DISTRIBUTED_AS
 je .yes
 cmp eax,NEBOC_TOKEN_INDEPENDENT_OF
 je .yes
 cmp eax,NEBOC_TOKEN_PROBABILITY_CONDITIONAL
 je .yes
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .next
 mov rdi,rbx
 call g138_api_at
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

g138_expect:
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

g138_expect_comma:
 mov edi,NEBOC_TOKEN_COMMA
 jmp g138_expect

g138_empty_call:
 sub rsp,8
 mov edi,NEBOC_TOKEN_LPAREN
 call g138_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call g138_expect
.done:
 add rsp,8
 ret

g138_parse_positive:
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
 ret

g138_parse_nonnegative:
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 test rdx,rdx
 js .domain
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.syntax:
 mov rax,-1
 ret

g138_next_positive:
 call g138_expect_comma
 test eax,eax
 jnz .done
 call g138_parse_positive
.done:
 ret

g138_next_nonnegative:
 call g138_expect_comma
 test eax,eax
 jnz .done
 call g138_parse_nonnegative
.done:
 ret

g138_next_signed:
 call g138_expect_comma
 test eax,eax
 jnz .done
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 xor eax,eax
 ret
.syntax:
 mov rax,-1
.done:
 ret

g138_parse_type:
 lea rsi,[rel g138_n_discrete]
 mov edx,g138_n_discrete_len
 call ls_current_atom
 test eax,eax
 jnz .discrete
 lea rsi,[rel g138_n_continuous]
 mov edx,g138_n_continuous_len
 call ls_current_atom
 test eax,eax
 jz .domain
 mov rdx,G138_TYPE_CONTINUOUS
 jmp .yes
.discrete:
 mov rdx,G138_TYPE_DISCRETE
.yes:
 inc qword [rel ls_cursor]
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret

g138_parse_distribution:
 lea rsi,[rel g138_n_bernoulli]
 mov edx,g138_n_bernoulli_len
 call ls_current_atom
 test eax,eax
 jnz .bernoulli
 lea rsi,[rel g138_n_uniform]
 mov edx,g138_n_uniform_len
 call ls_current_atom
 test eax,eax
 jz .domain
 mov rdx,G138_DIST_UNIFORM
 jmp .yes
.bernoulli:
 mov rdx,G138_DIST_BERNOULLI
.yes:
 inc qword [rel ls_cursor]
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret

g138_parse_measure:
 lea rsi,[rel g138_n_counting]
 mov edx,g138_n_counting_len
 call ls_current_atom
 test eax,eax
 jnz .counting
 lea rsi,[rel g138_n_lebesgue]
 mov edx,g138_n_lebesgue_len
 call ls_current_atom
 test eax,eax
 jz .domain
 mov rdx,G138_MEASURE_LEBESGUE
 jmp .yes
.counting:
 mov rdx,G138_MEASURE_COUNTING
.yes:
 inc qword [rel ls_cursor]
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret

g138_parse_relation:
 lea rsi,[rel g138_n_unknown]
 mov edx,g138_n_unknown_len
 call ls_current_atom
 test eax,eax
 jnz .unknown
 lea rsi,[rel g138_n_independent]
 mov edx,g138_n_independent_len
 call ls_current_atom
 test eax,eax
 jnz .independent
 lea rsi,[rel g138_n_dependent]
 mov edx,g138_n_dependent_len
 call ls_current_atom
 test eax,eax
 jz .domain
 mov rdx,G138_REL_DEPENDENT
 jmp .yes
.independent:
 mov rdx,G138_REL_INDEPENDENT
 jmp .yes
.unknown:
 mov rdx,G138_REL_UNKNOWN
.yes:
 inc qword [rel ls_cursor]
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret

g138_parse_budget_and_close:
 call g138_next_positive
 test eax,eax
 jnz .done
 cmp rdx,1000000
 ja .domain
 mov [rel g138_budget],rdx
 mov edi,NEBOC_TOKEN_RPAREN
 call g138_expect
 ret
.domain:
 mov eax,28
.done:
 ret

g138_parse_head:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
%macro G138_HEAD 2
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g138_n_%1]
 mov edx,g138_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .%2
%endmacro
 G138_HEAD probabilityModel,model
 G138_HEAD distributedAs,distributed
 G138_HEAD independentOf,independence
 G138_HEAD conditionalOn,conditional
 G138_HEAD P,conditional_symbol
 G138_HEAD randomVariable,variable
 G138_HEAD sampleProbability,sample
 G138_HEAD inferProbability,inference
 G138_HEAD probabilityReport,report
 jmp .syntax
.model: mov qword [rel g138_kind],G138_MODEL
 jmp .advance
.distributed: mov qword [rel g138_kind],G138_DISTRIBUTED
 jmp .advance
.independence: mov qword [rel g138_kind],G138_INDEPENDENCE
 jmp .advance
.conditional: mov qword [rel g138_kind],G138_CONDITIONAL
 mov qword [rel g138_distribution],0
 jmp .advance
.conditional_symbol: mov qword [rel g138_kind],G138_CONDITIONAL
 mov qword [rel g138_distribution],1
 jmp .advance
.variable: mov qword [rel g138_kind],G138_VARIABLE
 jmp .advance
.sample: mov qword [rel g138_kind],G138_SAMPLE
 jmp .advance
.inference: mov qword [rel g138_kind],G138_INFERENCE
 jmp .advance
.report: mov qword [rel g138_kind],G138_REPORT
.advance:
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call g138_expect
 ret
.syntax:
 mov rax,-1
 ret
%undef G138_HEAD

g138_parse_model:
 call g138_parse_positive
 test eax,eax
 jnz .done
 mov [rel g138_model],rdx
 call g138_parse_budget_and_close
.done:
 ret

g138_parse_distributed:
 call g138_parse_positive
 test eax,eax
 jnz .done
 mov [rel g138_model],rdx
 call g138_next_positive
 test eax,eax
 jnz .done
 mov [rel g138_variable],rdx
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_DISTRIBUTED_AS
 jne .named
 mov qword [rel g138_relation],1
 mov edi,NEBOC_TOKEN_DISTRIBUTED_AS
 call g138_expect
 test eax,eax
 jnz .done
 call g138_parse_distribution
 test eax,eax
 jnz .done
 mov [rel g138_distribution],rdx
 jmp .type
.named:
 mov qword [rel g138_relation],0
 call g138_expect_comma
 test eax,eax
 jnz .done
 call g138_parse_type
 test eax,eax
 jnz .done
 mov [rel g138_variable_type],rdx
 call g138_next_positive
 test eax,eax
 jnz .done
 mov [rel g138_variable_shape],rdx
 call g138_expect_comma
 test eax,eax
 jnz .done
 call g138_parse_distribution
 test eax,eax
 jnz .done
 mov [rel g138_distribution],rdx
.type:
 call g138_expect_comma
 test eax,eax
 jnz .done
 call g138_parse_type
 test eax,eax
 jnz .done
 cmp qword [rel g138_relation],0
 je .named_distribution_type
 mov [rel g138_variable_type],rdx
 call g138_next_positive
 test eax,eax
 jnz .done
 mov [rel g138_variable_shape],rdx
 call g138_expect_comma
 test eax,eax
 jnz .done
 call g138_parse_type
 test eax,eax
 jnz .done
.named_distribution_type:
 mov [rel g138_distribution_type],rdx
 call g138_next_positive
 test eax,eax
 jnz .done
 mov [rel g138_distribution_shape],rdx
 call g138_next_signed
 test eax,eax
 jnz .done
 mov [rel g138_support_min],rdx
 call g138_next_signed
 test eax,eax
 jnz .done
 mov [rel g138_support_max],rdx
 call g138_parse_budget_and_close
.done:
 ret

g138_parse_independence:
 call g138_parse_positive
 test eax,eax
 jnz .done
 mov [rel g138_model],rdx
 call g138_next_positive
 test eax,eax
 jnz .done
 mov [rel g138_left],rdx
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INDEPENDENT_OF
 jne .named
 mov edi,NEBOC_TOKEN_INDEPENDENT_OF
 call g138_expect
 test eax,eax
 jnz .done
 call g138_parse_positive
 jmp .right
.named:
 call g138_next_positive
.right:
 test eax,eax
 jnz .done
 mov [rel g138_right],rdx
 call g138_expect_comma
 test eax,eax
 jnz .done
 call g138_parse_relation
 test eax,eax
 jnz .done
 mov [rel g138_relation],rdx
 call g138_parse_budget_and_close
.done:
 ret

g138_parse_conditional:
 call g138_parse_positive
 test eax,eax
 jnz .done
 mov [rel g138_model],rdx
 call g138_next_nonnegative
 test eax,eax
 jnz .done
 mov [rel g138_joint_num],rdx
 call g138_next_positive
 test eax,eax
 jnz .done
 mov [rel g138_joint_den],rdx
 cmp qword [rel g138_distribution],0
 je .named
 mov edi,NEBOC_TOKEN_PROBABILITY_CONDITIONAL
 call g138_expect
 test eax,eax
 jnz .done
 call g138_parse_positive
 jmp .condition
.named:
 call g138_next_positive
.condition:
 test eax,eax
 jnz .done
 mov [rel g138_condition_num],rdx
 call g138_next_positive
 test eax,eax
 jnz .done
 mov [rel g138_condition_den],rdx
 call g138_parse_budget_and_close
.done:
 ret

g138_parse_variable:
 call g138_parse_positive
 test eax,eax
 jnz .done
 mov [rel g138_model],rdx
 call g138_next_positive
 test eax,eax
 jnz .done
 mov [rel g138_variable],rdx
 call g138_expect_comma
 test eax,eax
 jnz .done
 call g138_parse_type
 test eax,eax
 jnz .done
 mov [rel g138_variable_type],rdx
 call g138_expect_comma
 test eax,eax
 jnz .done
 call g138_parse_distribution
 test eax,eax
 jnz .done
 mov [rel g138_distribution],rdx
 call g138_next_signed
 test eax,eax
 jnz .done
 mov [rel g138_support_min],rdx
 call g138_next_signed
 test eax,eax
 jnz .done
 mov [rel g138_support_max],rdx
 call g138_next_positive
 test eax,eax
 jnz .done
 mov [rel g138_variable_shape],rdx
 call g138_expect_comma
 test eax,eax
 jnz .done
 call g138_parse_measure
 test eax,eax
 jnz .done
 mov [rel g138_measure],rdx
 call g138_parse_budget_and_close
.done:
 ret

g138_parse_sample:
 call g138_parse_positive
 test eax,eax
 jnz .done
 mov [rel g138_model],rdx
 call g138_next_positive
 test eax,eax
 jnz .done
 mov [rel g138_seed],rdx
 call g138_next_positive
 test eax,eax
 jnz .done
 mov [rel g138_bound],rdx
 call g138_parse_budget_and_close
.done:
 ret

g138_parse_inference:
 call g138_parse_positive
 test eax,eax
 jnz .done
 mov [rel g138_model],rdx
 call g138_next_nonnegative
 test eax,eax
 jnz .done
 mov [rel g138_successes],rdx
 call g138_next_nonnegative
 test eax,eax
 jnz .done
 mov [rel g138_total],rdx
 call g138_next_positive
 test eax,eax
 jnz .done
 mov [rel g138_alpha],rdx
 call g138_next_positive
 test eax,eax
 jnz .done
 mov [rel g138_beta],rdx
 call g138_parse_budget_and_close
.done:
 ret

g138_parse_report:
 call g138_parse_positive
 test eax,eax
 jnz .done
 mov [rel g138_model],rdx
 call g138_next_nonnegative
 test eax,eax
 jnz .done
 mov [rel g138_joint_num],rdx
 call g138_next_positive
 test eax,eax
 jnz .done
 mov [rel g138_joint_den],rdx
 call g138_next_nonnegative
 test eax,eax
 jnz .done
 cmp rdx,4
 ja .domain
 mov [rel g138_report_status],rdx
 call g138_parse_budget_and_close
 ret
.domain:
 mov eax,28
.done:
 ret

g138_parse_term_body:
 cmp qword [rel g138_kind],G138_MODEL
 je g138_parse_model
 cmp qword [rel g138_kind],G138_DISTRIBUTED
 je g138_parse_distributed
 cmp qword [rel g138_kind],G138_INDEPENDENCE
 je g138_parse_independence
 cmp qword [rel g138_kind],G138_CONDITIONAL
 je g138_parse_conditional
 cmp qword [rel g138_kind],G138_VARIABLE
 je g138_parse_variable
 cmp qword [rel g138_kind],G138_SAMPLE
 je g138_parse_sample
 cmp qword [rel g138_kind],G138_INFERENCE
 je g138_parse_inference
 jmp g138_parse_report

g138_budget_check:
 cmp rdi,[rel g138_budget]
 jbe .yes
 mov qword [rel g138_status],G138_STATUS_BUDGET
 mov qword [rel g138_converged],0
 mov [rel g138_iterations],rdi
 mov eax,1
 ret
.yes:
 mov [rel g138_iterations],rdi
 xor eax,eax
 ret

g138_validate_support:
 mov rax,[rel g138_support_min]
 cmp rax,[rel g138_support_max]
 jg .domain
 cmp qword [rel g138_distribution],G138_DIST_BERNOULLI
 jne .uniform
 cmp qword [rel g138_variable_type],G138_TYPE_DISCRETE
 jne .domain
 cmp qword [rel g138_support_min],0
 jne .domain
 cmp qword [rel g138_support_max],1
 jne .domain
 xor eax,eax
 ret
.uniform:
 cmp rax,[rel g138_support_max]
 je .domain
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret

; RAX=numerator, RDX=positive denominator; return reduced RAX/RDX.
g138_reduce:
 mov r8,rax
 mov r9,rdx
 mov r10,rax
 mov r11,rdx
.gcd:
 test r11,r11
 jz .publish
 mov rax,r10
 xor edx,edx
 div r11
 mov r10,r11
 mov r11,rdx
 jmp .gcd
.publish:
 mov rax,r8
 xor edx,edx
 div r10
 mov r8,rax
 mov rax,r9
 xor edx,edx
 div r10
 mov rdx,rax
 mov rax,r8
 ret

g138_calculate_model:
 mov edi,1
 call g138_budget_check
 test eax,eax
 jnz .ok
 mov rax,[rel g138_model]
 mov [rel g138_result],rax
.ok:
 xor eax,eax
 ret

g138_calculate_distributed:
 mov edi,2
 call g138_budget_check
 test eax,eax
 jnz .ok
 cmp qword [rel g138_variable_shape],16
 ja .domain
 cmp qword [rel g138_distribution_shape],16
 ja .domain
 mov rax,[rel g138_variable_type]
 cmp rax,[rel g138_distribution_type]
 jne .domain
 mov rax,[rel g138_variable_shape]
 cmp rax,[rel g138_distribution_shape]
 jne .domain
 call g138_validate_support
 test eax,eax
 jnz .done
 mov qword [rel g138_result],1
.ok:
 xor eax,eax
 ret
.domain:
 mov eax,28
.done:
 ret

g138_calculate_independence:
 mov edi,2
 call g138_budget_check
 test eax,eax
 jnz .ok
 mov rax,[rel g138_left]
 cmp rax,[rel g138_right]
 je .domain
 cmp qword [rel g138_relation],G138_REL_UNKNOWN
 je .unknown
 xor eax,eax
 cmp qword [rel g138_relation],G138_REL_INDEPENDENT
 sete al
 mov [rel g138_result],rax
.ok:
 xor eax,eax
 ret
.unknown:
 mov qword [rel g138_status],G138_STATUS_UNKNOWN
 mov qword [rel g138_converged],0
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret

g138_calculate_conditional:
 mov edi,4
 call g138_budget_check
 test eax,eax
 jnz .ok
 mov rax,[rel g138_joint_num]
 cmp rax,[rel g138_joint_den]
 ja .domain
 mov rax,[rel g138_condition_num]
 cmp rax,[rel g138_condition_den]
 ja .domain
 mov r8,[rel g138_joint_num]
 imul r8,[rel g138_condition_den]
 jo .overflow
 mov r9,[rel g138_joint_den]
 imul r9,[rel g138_condition_num]
 jo .overflow
 cmp r8,r9
 ja .domain
 mov rax,r8
 mov rdx,r9
 call g138_reduce
 mov [rel g138_numerator],rax
 mov [rel g138_denominator],rdx
.ok:
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.overflow:
 mov eax,10
 ret

g138_calculate_variable:
 mov edi,1
 call g138_budget_check
 test eax,eax
 jnz .ok
 cmp qword [rel g138_variable_shape],16
 ja .domain
 cmp qword [rel g138_variable_type],G138_TYPE_DISCRETE
 jne .continuous
 cmp qword [rel g138_measure],G138_MEASURE_COUNTING
 jne .domain
 jmp .support
.continuous:
 cmp qword [rel g138_measure],G138_MEASURE_LEBESGUE
 jne .domain
.support:
 call g138_validate_support
 test eax,eax
 jnz .done
 mov rax,[rel g138_variable]
 mov [rel g138_result],rax
.ok:
 xor eax,eax
 ret
.domain:
 mov eax,28
.done:
 ret

g138_calculate_sample:
 mov edi,1
 call g138_budget_check
 test eax,eax
 jnz .ok
 cmp qword [rel g138_bound],1000000
 ja .limit
 mov rax,[rel g138_seed]
 mov rcx,rax
 shl rcx,13
 xor rax,rcx
 mov rcx,rax
 shr rcx,7
 xor rax,rcx
 mov rcx,rax
 shl rcx,17
 xor rax,rcx
 xor edx,edx
 div qword [rel g138_bound]
 mov [rel g138_result],rdx
.ok:
 xor eax,eax
 ret
.limit:
 mov qword [rel g138_status],G138_STATUS_LIMIT
 mov qword [rel g138_converged],0
 xor eax,eax
 ret

g138_calculate_inference:
 mov edi,1
 call g138_budget_check
 test eax,eax
 jnz .ok
 mov rax,[rel g138_successes]
 cmp rax,[rel g138_total]
 ja .domain
 cmp qword [rel g138_total],1000000
 ja .domain
 add rax,[rel g138_alpha]
 jo .overflow
 mov rdx,[rel g138_total]
 add rdx,[rel g138_alpha]
 jo .overflow
 add rdx,[rel g138_beta]
 jo .overflow
 call g138_reduce
 mov [rel g138_numerator],rax
 mov [rel g138_denominator],rdx
.ok:
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.overflow:
 mov eax,10
 ret

g138_calculate_report:
 mov edi,1
 call g138_budget_check
 test eax,eax
 jnz .ok
 mov rax,[rel g138_joint_num]
 cmp rax,[rel g138_joint_den]
 ja .domain
 mov rdx,[rel g138_joint_den]
 call g138_reduce
 mov [rel g138_numerator],rax
 mov [rel g138_denominator],rdx
.ok:
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret

g138_calculate:
 mov qword [rel g138_converged],1
 cmp qword [rel g138_kind],G138_MODEL
 je g138_calculate_model
 cmp qword [rel g138_kind],G138_DISTRIBUTED
 je g138_calculate_distributed
 cmp qword [rel g138_kind],G138_INDEPENDENCE
 je g138_calculate_independence
 cmp qword [rel g138_kind],G138_CONDITIONAL
 je g138_calculate_conditional
 cmp qword [rel g138_kind],G138_VARIABLE
 je g138_calculate_variable
 cmp qword [rel g138_kind],G138_SAMPLE
 je g138_calculate_sample
 cmp qword [rel g138_kind],G138_INFERENCE
 je g138_calculate_inference
 jmp g138_calculate_report

g138_require_success:
 cmp qword [rel g138_status],G138_STATUS_OK
 jne .no
 xor eax,eax
 ret
.no:
 mov eax,28
 ret

g138_parse_observer:
 mov edi,NEBOC_TOKEN_DOT
 call g138_expect
 test eax,eax
 jnz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
%macro G138_OBSERVER 2
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g138_n_%1]
 mov edx,g138_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .%2
%endmacro
 G138_OBSERVER value,value
 G138_OBSERVER numerator,numerator
 G138_OBSERVER denominator,denominator
 G138_OBSERVER model,model
 G138_OBSERVER shape,shape
 G138_OBSERVER supportMin,support_min
 G138_OBSERVER supportMax,support_max
 G138_OBSERVER measure,measure
 G138_OBSERVER seed,seed
 G138_OBSERVER budget,budget
 G138_OBSERVER status,status
 G138_OBSERVER iterations,iterations
 G138_OBSERVER converged,converged
 G138_OBSERVER error,error
 G138_OBSERVER code,code
 jmp .syntax
.value:
 call g138_require_success
 test eax,eax
 jnz .done
 cmp qword [rel g138_kind],G138_CONDITIONAL
 je .domain
 cmp qword [rel g138_kind],G138_INFERENCE
 je .domain
 cmp qword [rel g138_kind],G138_REPORT
 je .domain
 mov rdx,[rel g138_result]
 jmp .empty
.numerator:
 call g138_require_success
 test eax,eax
 jnz .done
 cmp qword [rel g138_kind],G138_CONDITIONAL
 je .numerator_ok
 cmp qword [rel g138_kind],G138_INFERENCE
 je .numerator_ok
 cmp qword [rel g138_kind],G138_REPORT
 jne .domain
.numerator_ok:
 mov rdx,[rel g138_numerator]
 jmp .empty
.denominator:
 call g138_require_success
 test eax,eax
 jnz .done
 cmp qword [rel g138_kind],G138_CONDITIONAL
 je .denominator_ok
 cmp qword [rel g138_kind],G138_INFERENCE
 je .denominator_ok
 cmp qword [rel g138_kind],G138_REPORT
 jne .domain
.denominator_ok:
 mov rdx,[rel g138_denominator]
 jmp .empty
.model:
 mov rdx,[rel g138_model]
 jmp .empty
.shape:
 cmp qword [rel g138_kind],G138_VARIABLE
 je .shape_ok
 cmp qword [rel g138_kind],G138_DISTRIBUTED
 jne .domain
.shape_ok:
 mov rdx,[rel g138_variable_shape]
 jmp .empty
.support_min:
 cmp qword [rel g138_kind],G138_VARIABLE
 je .support_min_ok
 cmp qword [rel g138_kind],G138_DISTRIBUTED
 jne .domain
.support_min_ok:
 mov rdx,[rel g138_support_min]
 jmp .empty
.support_max:
 cmp qword [rel g138_kind],G138_VARIABLE
 je .support_max_ok
 cmp qword [rel g138_kind],G138_DISTRIBUTED
 jne .domain
.support_max_ok:
 mov rdx,[rel g138_support_max]
 jmp .empty
.measure:
 cmp qword [rel g138_kind],G138_VARIABLE
 jne .domain
 mov rdx,[rel g138_measure]
 jmp .empty
.seed:
 cmp qword [rel g138_kind],G138_SAMPLE
 jne .domain
 mov rdx,[rel g138_seed]
 jmp .empty
.budget:
 mov rdx,[rel g138_budget]
 jmp .empty
.status:
 cmp qword [rel g138_kind],G138_REPORT
 jne .runtime_status
 mov rdx,[rel g138_report_status]
 jmp .empty
.runtime_status:
 mov rdx,[rel g138_status]
 jmp .empty
.iterations:
 mov rdx,[rel g138_iterations]
 jmp .empty
.converged:
 mov rdx,[rel g138_converged]
 jmp .empty
.error:
 mov rdx,[rel g138_error]
 jmp .empty
.code:
 cmp qword [rel g138_kind],G138_REPORT
 jne .domain
 mov rdx,[rel g138_report_status]
 add rdx,138000
.empty:
 push rdx
 inc qword [rel ls_cursor]
 call g138_empty_call
 pop rdx
 ret
.domain:
 mov eax,28
 ret
.syntax:
 mov rax,-1
.done:
 ret
%undef G138_OBSERVER

g138_parse_term:
 call g138_parse_head
 test eax,eax
 jnz .done
 call g138_parse_term_body
 test eax,eax
 jnz .done
 call g138_calculate
 test eax,eax
 jnz .done
 call g138_parse_observer
.done:
 ret

g138_parse_program:
 push rbx
 sub rsp,16
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call .clear_term
 call g138_parse_term
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
 call g138_parse_term
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
 mov rdx,G138_FAMILY_KEY
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
 lea rdi,[rel g138_scratch_start]
 mov ecx,(g138_scratch_end-g138_scratch_start)/8
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
