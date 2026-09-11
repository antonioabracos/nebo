; Source-to-effect oracle for G060. Every compiler-emitted mode executes the
; real bounded percent formatter and compares its bytes with an independent
; constant transcript before returning the source seed.
bits 64
default rel
%define NEBO_G060_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/percent_template_source_probe.inc"
%include "runtime/textual/percent_format.inc"

section .rodata
g60_t1: db '%s:%d:%.1f:%b:%%'
g60_t1_len equ $-g60_t1
g60_e1: db 'ok:7:1.5:true:%'
g60_e1_len equ $-g60_e1
g60_t2: db '%v|%T|%q|%j|%#|%?'
g60_t2_len equ $-g60_t2
g60_e2: db '42|Text|"q"|"j"|{Structural:s}|<Structural i>'
g60_e2_len equ $-g60_e2
g60_t3: db '%04d|%x|%o'
g60_t3_len equ $-g60_t3
g60_e3: db '0007|ff|10'
g60_e3_len equ $-g60_e3
g60_t4: db '%.2f|%.2e'
g60_t4_len equ $-g60_t4
g60_e4: db '12.35|1.23e+01'
g60_e4_len equ $-g60_e4
g60_t5: db '%8s|%-8s'
g60_t5_len equ $-g60_t5
g60_e5: db '      go|left    '
g60_e5_len equ $-g60_e5
g60_t6: db '%{nome:s}|%{idade:d}'
g60_t6_len equ $-g60_t6
g60_e6: db 'Ana|37'
g60_e6_len equ $-g60_e6
g60_t7: db '%2$s|%1$d'
g60_t7_len equ $-g60_t7
g60_e7: db 'world|9'
g60_e7_len equ $-g60_e7
g60_t8: db '%s'
g60_t8_len equ $-g60_t8
g60_e8: db '73'
g60_e8_len equ $-g60_e8
g60_t9: db 'diagnostics=%%'
g60_t9_len equ $-g60_t9
g60_e9: db 'diagnostics=%'
g60_e9_len equ $-g60_e9
g60_policy_unknown: db '%z'
g60_policy_unknown_len equ $-g60_policy_unknown
g60_policy_missing: db '<missing>'
g60_policy_missing_len equ $-g60_policy_missing
g60_policy_percent: db '%%'
g60_policy_percent_len equ $-g60_policy_percent
g60_policy_percent_expected: db '%'
g60_policy_percent_expected_len equ $-g60_policy_percent_expected

g60_text_ok: db 'ok'
g60_text_ok_len equ $-g60_text_ok
g60_text_x: db 'x'
g60_text_x_len equ $-g60_text_x
g60_text_q: db 'q'
g60_text_q_len equ $-g60_text_q
g60_text_j: db 'j'
g60_text_j_len equ $-g60_text_j
g60_text_s: db 's'
g60_text_s_len equ $-g60_text_s
g60_text_i: db 'i'
g60_text_i_len equ $-g60_text_i
g60_text_go: db 'go'
g60_text_go_len equ $-g60_text_go
g60_text_left: db 'left'
g60_text_left_len equ $-g60_text_left
g60_text_ana: db 'Ana'
g60_text_ana_len equ $-g60_text_ana
g60_text_world: db 'world'
g60_text_world_len equ $-g60_text_world
g60_name_nome: db 'nome'
g60_name_nome_len equ $-g60_name_nome
g60_name_idade: db 'idade'
g60_name_idade_len equ $-g60_name_idade
g60_float_1_5: dq 1.5
g60_float_12_345: dq 12.346

g60_bad_1: db '%p'
g60_bad_1_len equ $-g60_bad_1
g60_bad_2: db '%d'
g60_bad_2_len equ $-g60_bad_2
g60_bad_3: db '%d'
g60_bad_3_len equ $-g60_bad_3
g60_bad_4: db '%999d'
g60_bad_4_len equ $-g60_bad_4
g60_bad_5: db '%{nome:s}'
g60_bad_5_len equ $-g60_bad_5
g60_bad_6: db '%0$s'
g60_bad_6_len equ $-g60_bad_6
g60_bad_7: db '%s'
g60_bad_7_len equ $-g60_bad_7
g60_bad_8: db '%s'
g60_bad_8_len equ $-g60_bad_8

section .bss align=16
g60_request: resb PERCENT_REQUEST_SIZE
g60_nodes: resb PERCENT_NODE_SIZE*PERCENT_MAX_NODES
g60_args: resb PERCENT_ARG_SIZE*8
g60_output: resb 512
g60_before: resb 512

section .text
global nebo_g060_source_probe
global nebo_g060_negative_probe

g60_clear:
 call g60_clear_context
 lea rdi,[rel g60_args]
 mov ecx,(PERCENT_ARG_SIZE*8)/8
 xor eax,eax
 rep stosq
 ret

g60_clear_context:
 lea rdi,[rel g60_request]
 mov ecx,PERCENT_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel g60_nodes]
 mov ecx,(PERCENT_NODE_SIZE*PERCENT_MAX_NODES)/8
 rep stosq
 lea rdi,[rel g60_output]
 mov ecx,512
 mov al,0xa5
 rep stosb
 ret

; RDI template, RSI len, RDX args, RCX count, R8 policy, R9 expected,
; R10 expected length -> EAX zero/one.
g60_run:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov [rsp],r9
 mov [rsp+8],r10
 call g60_clear_context
 lea rdi,[rel g60_request]
 mov [rdi+PERCENT_REQUEST_TEMPLATE],r12
 mov [rdi+PERCENT_REQUEST_TEMPLATE_LEN],r13
 lea rax,[rel g60_nodes]
 mov [rdi+PERCENT_REQUEST_NODES],rax
 mov qword [rdi+PERCENT_REQUEST_NODE_CAP],PERCENT_MAX_NODES
 mov [rdi+PERCENT_REQUEST_ARGS],r14
 mov [rdi+PERCENT_REQUEST_ARG_COUNT],r15
 mov [rdi+PERCENT_REQUEST_POLICY],rbx
 lea rax,[rel g60_output]
 mov [rdi+PERCENT_REQUEST_OUTPUT],rax
 mov qword [rdi+PERCENT_REQUEST_CAPACITY],512
 call neboc_percent_render_request
 test eax,eax
 jnz .done
 lea rax,[rel g60_request]
 mov rcx,[rsp+8]
 cmp [rax+PERCENT_REQUEST_WRITTEN],rcx
 jne .bad_length
 mov rsi,[rsp]
 lea rdi,[rel g60_output]
 repe cmpsb
 jne .bad_bytes
 xor eax,eax
 jmp .done
.bad_length: mov eax,100
 jmp .done
.bad_bytes: mov eax,101
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

g60_mode_1:
 call g60_clear
 lea rax,[rel g60_text_ok]
 mov [rel g60_args+PERCENT_ARG_DATA],rax
 mov qword [rel g60_args+PERCENT_ARG_KIND],PERCENT_ARG_TEXT
 mov qword [rel g60_args+PERCENT_ARG_LENGTH],g60_text_ok_len
 mov qword [rel g60_args+PERCENT_ARG_SIZE+PERCENT_ARG_KIND],PERCENT_ARG_INT
 mov qword [rel g60_args+PERCENT_ARG_SIZE+PERCENT_ARG_DATA],7
 mov qword [rel g60_args+PERCENT_ARG_SIZE*2+PERCENT_ARG_KIND],PERCENT_ARG_FLOAT
 mov rax,[rel g60_float_1_5]
 mov [rel g60_args+PERCENT_ARG_SIZE*2+PERCENT_ARG_DATA],rax
 mov qword [rel g60_args+PERCENT_ARG_SIZE*3+PERCENT_ARG_KIND],PERCENT_ARG_BOOL
 mov qword [rel g60_args+PERCENT_ARG_SIZE*3+PERCENT_ARG_DATA],1
 lea rdi,[rel g60_t1]
 mov esi,g60_t1_len
 lea rdx,[rel g60_args]
 mov ecx,4
 xor r8d,r8d
 lea r9,[rel g60_e1]
 mov r10d,g60_e1_len
 jmp g60_run

g60_mode_2:
 call g60_clear
 mov qword [rel g60_args+PERCENT_ARG_KIND],PERCENT_ARG_INT
 mov qword [rel g60_args+PERCENT_ARG_DATA],42
 lea rax,[rel g60_text_x]
 mov qword [rel g60_args+PERCENT_ARG_SIZE+PERCENT_ARG_KIND],PERCENT_ARG_TEXT
 mov [rel g60_args+PERCENT_ARG_SIZE+PERCENT_ARG_DATA],rax
 mov qword [rel g60_args+PERCENT_ARG_SIZE+PERCENT_ARG_LENGTH],g60_text_x_len
 lea rax,[rel g60_text_q]
 mov qword [rel g60_args+PERCENT_ARG_SIZE*2+PERCENT_ARG_KIND],PERCENT_ARG_TEXT
 mov [rel g60_args+PERCENT_ARG_SIZE*2+PERCENT_ARG_DATA],rax
 mov qword [rel g60_args+PERCENT_ARG_SIZE*2+PERCENT_ARG_LENGTH],g60_text_q_len
 lea rax,[rel g60_text_j]
 mov qword [rel g60_args+PERCENT_ARG_SIZE*3+PERCENT_ARG_KIND],PERCENT_ARG_TEXT
 mov [rel g60_args+PERCENT_ARG_SIZE*3+PERCENT_ARG_DATA],rax
 mov qword [rel g60_args+PERCENT_ARG_SIZE*3+PERCENT_ARG_LENGTH],g60_text_j_len
 lea rax,[rel g60_text_s]
 mov qword [rel g60_args+PERCENT_ARG_SIZE*4+PERCENT_ARG_KIND],PERCENT_ARG_STRUCTURAL
 mov [rel g60_args+PERCENT_ARG_SIZE*4+PERCENT_ARG_DATA],rax
 mov qword [rel g60_args+PERCENT_ARG_SIZE*4+PERCENT_ARG_LENGTH],g60_text_s_len
 lea rax,[rel g60_text_i]
 mov qword [rel g60_args+PERCENT_ARG_SIZE*5+PERCENT_ARG_KIND],PERCENT_ARG_STRUCTURAL
 mov [rel g60_args+PERCENT_ARG_SIZE*5+PERCENT_ARG_DATA],rax
 mov qword [rel g60_args+PERCENT_ARG_SIZE*5+PERCENT_ARG_LENGTH],g60_text_i_len
 lea rdi,[rel g60_t2]
 mov esi,g60_t2_len
 lea rdx,[rel g60_args]
 mov ecx,6
 xor r8d,r8d
 lea r9,[rel g60_e2]
 mov r10d,g60_e2_len
 jmp g60_run

g60_mode_3:
 call g60_clear
 mov qword [rel g60_args+PERCENT_ARG_KIND],PERCENT_ARG_INT
 mov qword [rel g60_args+PERCENT_ARG_DATA],7
 mov qword [rel g60_args+PERCENT_ARG_SIZE+PERCENT_ARG_KIND],PERCENT_ARG_INT
 mov qword [rel g60_args+PERCENT_ARG_SIZE+PERCENT_ARG_DATA],255
 mov qword [rel g60_args+PERCENT_ARG_SIZE*2+PERCENT_ARG_KIND],PERCENT_ARG_INT
 mov qword [rel g60_args+PERCENT_ARG_SIZE*2+PERCENT_ARG_DATA],8
 lea rdi,[rel g60_t3]
 mov esi,g60_t3_len
 lea rdx,[rel g60_args]
 mov ecx,3
 xor r8d,r8d
 lea r9,[rel g60_e3]
 mov r10d,g60_e3_len
 jmp g60_run

g60_mode_4:
 call g60_clear
 mov rax,[rel g60_float_12_345]
 mov qword [rel g60_args+PERCENT_ARG_KIND],PERCENT_ARG_FLOAT
 mov [rel g60_args+PERCENT_ARG_DATA],rax
 mov qword [rel g60_args+PERCENT_ARG_SIZE+PERCENT_ARG_KIND],PERCENT_ARG_FLOAT
 mov [rel g60_args+PERCENT_ARG_SIZE+PERCENT_ARG_DATA],rax
 lea rdi,[rel g60_t4]
 mov esi,g60_t4_len
 lea rdx,[rel g60_args]
 mov ecx,2
 xor r8d,r8d
 lea r9,[rel g60_e4]
 mov r10d,g60_e4_len
 jmp g60_run

g60_mode_5:
 call g60_clear
 lea rax,[rel g60_text_go]
 mov qword [rel g60_args+PERCENT_ARG_KIND],PERCENT_ARG_TEXT
 mov [rel g60_args+PERCENT_ARG_DATA],rax
 mov qword [rel g60_args+PERCENT_ARG_LENGTH],g60_text_go_len
 lea rax,[rel g60_text_left]
 mov qword [rel g60_args+PERCENT_ARG_SIZE+PERCENT_ARG_KIND],PERCENT_ARG_TEXT
 mov [rel g60_args+PERCENT_ARG_SIZE+PERCENT_ARG_DATA],rax
 mov qword [rel g60_args+PERCENT_ARG_SIZE+PERCENT_ARG_LENGTH],g60_text_left_len
 lea rdi,[rel g60_t5]
 mov esi,g60_t5_len
 lea rdx,[rel g60_args]
 mov ecx,2
 xor r8d,r8d
 lea r9,[rel g60_e5]
 mov r10d,g60_e5_len
 jmp g60_run

g60_mode_6:
 call g60_clear
 lea rdi,[rel g60_name_nome]
 mov esi,g60_name_nome_len
 call neboc_percent_name_hash
 mov [rel g60_args+PERCENT_ARG_NAME_HASH],rax
 lea rax,[rel g60_text_ana]
 mov qword [rel g60_args+PERCENT_ARG_KIND],PERCENT_ARG_TEXT
 mov [rel g60_args+PERCENT_ARG_DATA],rax
 mov qword [rel g60_args+PERCENT_ARG_LENGTH],g60_text_ana_len
 lea rdi,[rel g60_name_idade]
 mov esi,g60_name_idade_len
 call neboc_percent_name_hash
 mov [rel g60_args+PERCENT_ARG_SIZE+PERCENT_ARG_NAME_HASH],rax
 mov qword [rel g60_args+PERCENT_ARG_SIZE+PERCENT_ARG_KIND],PERCENT_ARG_INT
 mov qword [rel g60_args+PERCENT_ARG_SIZE+PERCENT_ARG_DATA],37
 lea rdi,[rel g60_t6]
 mov esi,g60_t6_len
 lea rdx,[rel g60_args]
 mov ecx,2
 xor r8d,r8d
 lea r9,[rel g60_e6]
 mov r10d,g60_e6_len
 jmp g60_run

g60_mode_7:
 call g60_clear
 mov qword [rel g60_args+PERCENT_ARG_KIND],PERCENT_ARG_INT
 mov qword [rel g60_args+PERCENT_ARG_DATA],9
 lea rax,[rel g60_text_world]
 mov qword [rel g60_args+PERCENT_ARG_SIZE+PERCENT_ARG_KIND],PERCENT_ARG_TEXT
 mov [rel g60_args+PERCENT_ARG_SIZE+PERCENT_ARG_DATA],rax
 mov qword [rel g60_args+PERCENT_ARG_SIZE+PERCENT_ARG_LENGTH],g60_text_world_len
 lea rdi,[rel g60_t7]
 mov esi,g60_t7_len
 lea rdx,[rel g60_args]
 mov ecx,2
 xor r8d,r8d
 lea r9,[rel g60_e7]
 mov r10d,g60_e7_len
 jmp g60_run

g60_mode_8:
 call g60_clear
 mov qword [rel g60_args+PERCENT_ARG_KIND],PERCENT_ARG_INT
 mov qword [rel g60_args+PERCENT_ARG_DATA],73
 lea rdi,[rel g60_t8]
 mov esi,g60_t8_len
 lea rdx,[rel g60_args]
 mov ecx,1
 mov r8d,PERCENT_POLICY_ALLOW_COERCE
 lea r9,[rel g60_e8]
 mov r10d,g60_e8_len
 jmp g60_run

g60_mode_9:
 call g60_clear
 lea rdi,[rel g60_t9]
 mov esi,g60_t9_len
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 lea r9,[rel g60_e9]
 mov r10d,g60_e9_len
 jmp g60_run

; EDI mode 1..9, ESI nonzero source seed -> EAX seed only after observation.
nebo_g060_source_probe:
 push rbx
 mov ebx,esi
 test ebx,ebx
 jz .fail
 cmp edi,1
 je .m1
 cmp edi,2
 je .m2
 cmp edi,3
 je .m3
 cmp edi,4
 je .m4
 cmp edi,5
 je .m5
 cmp edi,6
 je .m6
 cmp edi,7
 je .m7
 cmp edi,8
 je .m8
 cmp edi,9
 je .m9
 jmp .fail
.m1: call g60_mode_1
 jmp .checked
.m2: call g60_mode_2
 jmp .checked
.m3: call g60_mode_3
 jmp .checked
.m4: call g60_mode_4
 jmp .checked
.m5: call g60_mode_5
 jmp .checked
.m6: call g60_mode_6
 jmp .checked
.m7: call g60_mode_7
 jmp .checked
.m8: call g60_mode_8
 jmp .checked
.m9: call g60_mode_9
.checked:
 test eax,eax
 jnz .done
 mov eax,ebx
 jmp .done
.fail: mov eax,1
.done:
 pop rbx
 ret

; Set up one diagnostic request. RDI template, RSI len, RDX args, RCX count,
; R8 policy, R9 capacity -> EAX diagnostic.
g60_diagnostic_case:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov [rsp],r9
 call g60_clear_context
 lea rdi,[rel g60_request]
 mov [rdi+PERCENT_REQUEST_TEMPLATE],r12
 mov [rdi+PERCENT_REQUEST_TEMPLATE_LEN],r13
 lea rax,[rel g60_nodes]
 mov [rdi+PERCENT_REQUEST_NODES],rax
 mov qword [rdi+PERCENT_REQUEST_NODE_CAP],PERCENT_MAX_NODES
 mov [rdi+PERCENT_REQUEST_ARGS],r14
 mov [rdi+PERCENT_REQUEST_ARG_COUNT],r15
 mov [rdi+PERCENT_REQUEST_POLICY],rbx
 lea rax,[rel g60_output]
 mov [rdi+PERCENT_REQUEST_OUTPUT],rax
 mov rax,[rsp]
 mov [rdi+PERCENT_REQUEST_CAPACITY],rax
 call neboc_percent_render_request
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Returns zero only when all eight stable diagnostics and atomic failure are
; observed independently of the source fixtures.
nebo_g060_negative_probe:
 push rbx
 ; 001 unknown/rejected %p.
 mov ebx,111
 lea rdi,[rel g60_bad_1]
 mov esi,g60_bad_1_len
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 mov r9d,512
 call g60_diagnostic_case
 cmp eax,PERCENT_DIAG_UNKNOWN_PLACEHOLDER
 jne .bad
 ; 002 arity mismatch.
 mov ebx,112
 lea rdi,[rel g60_bad_2]
 mov esi,g60_bad_2_len
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 mov r9d,512
 call g60_diagnostic_case
 cmp eax,PERCENT_DIAG_ARITY_MISMATCH
 jne .bad
 ; 003 incompatible type.
 mov ebx,113
 call g60_clear
 lea rax,[rel g60_text_x]
 mov qword [rel g60_args+PERCENT_ARG_KIND],PERCENT_ARG_TEXT
 mov [rel g60_args+PERCENT_ARG_DATA],rax
 mov qword [rel g60_args+PERCENT_ARG_LENGTH],g60_text_x_len
 lea rdi,[rel g60_bad_3]
 mov esi,g60_bad_3_len
 lea rdx,[rel g60_args]
 mov ecx,1
 xor r8d,r8d
 mov r9d,512
 call g60_diagnostic_case
 cmp eax,PERCENT_DIAG_TYPE_MISMATCH
 jne .bad
 ; 004 width/precision.
 mov ebx,114
 lea rdi,[rel g60_bad_4]
 mov esi,g60_bad_4_len
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 mov r9d,512
 call g60_diagnostic_case
 cmp eax,PERCENT_DIAG_WIDTH_PRECISION
 jne .bad
 ; 005 named missing.
 mov ebx,115
 lea rdi,[rel g60_bad_5]
 mov esi,g60_bad_5_len
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 mov r9d,512
 call g60_diagnostic_case
 cmp eax,PERCENT_DIAG_NAMED_ARGUMENT
 jne .bad
 ; 006 positional index.
 mov ebx,116
 lea rdi,[rel g60_bad_6]
 mov esi,g60_bad_6_len
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 mov r9d,512
 call g60_diagnostic_case
 cmp eax,PERCENT_DIAG_POSITIONAL_INDEX
 jne .bad
 ; 007 approved coercion disabled.
 mov ebx,117
 call g60_clear
 mov qword [rel g60_args+PERCENT_ARG_KIND],PERCENT_ARG_INT
 mov qword [rel g60_args+PERCENT_ARG_DATA],8
 lea rdi,[rel g60_bad_7]
 mov esi,g60_bad_7_len
 lea rdx,[rel g60_args]
 mov ecx,1
 xor r8d,r8d
 mov r9d,512
 call g60_diagnostic_case
 cmp eax,PERCENT_DIAG_COERCION_FORBIDDEN
 jne .bad
 ; 008 bounded output; verify the sentinel is untouched.
 mov ebx,118
 call g60_clear
 lea rax,[rel g60_text_world]
 mov qword [rel g60_args+PERCENT_ARG_KIND],PERCENT_ARG_TEXT
 mov [rel g60_args+PERCENT_ARG_DATA],rax
 mov qword [rel g60_args+PERCENT_ARG_LENGTH],g60_text_world_len
 lea rdi,[rel g60_bad_8]
 mov esi,g60_bad_8_len
 lea rdx,[rel g60_args]
 mov ecx,1
 xor r8d,r8d
 mov r9d,1
 call g60_diagnostic_case
 cmp eax,PERCENT_DIAG_OUTPUT_LIMIT
 jne .bad
 cmp byte [rel g60_output],0xa5
 jne .bad
 ; The complete loose flag set is valid, while contradictory modes fail.
 mov ebx,119
 mov edi,PERCENT_POLICY_LOOSE
 call neboc_percent_policy_validate
 test eax,eax
 jnz .bad
 mov edi,PERCENT_POLICY_NAMED_ONLY | PERCENT_POLICY_POSITIONAL_ONLY
 call neboc_percent_policy_validate
 cmp eax,PERCENT_DIAG_UNKNOWN_PLACEHOLDER
 jne .bad
 ; Explicit unknown, missing and extra policies are independently observable.
 mov ebx,120
 lea rdi,[rel g60_policy_unknown]
 mov esi,g60_policy_unknown_len
 xor edx,edx
 xor ecx,ecx
 mov r8d,PERCENT_POLICY_UNKNOWN_LITERAL
 lea r9,[rel g60_policy_unknown]
 mov r10d,g60_policy_unknown_len
 call g60_run
 test eax,eax
 jnz .bad
 mov ebx,121
 lea rdi,[rel g60_t8]
 mov esi,g60_t8_len
 xor edx,edx
 xor ecx,ecx
 mov r8d,PERCENT_POLICY_ALLOW_MISSING
 lea r9,[rel g60_policy_missing]
 mov r10d,g60_policy_missing_len
 call g60_run
 test eax,eax
 jnz .bad
 mov ebx,122
 call g60_clear
 mov qword [rel g60_args+PERCENT_ARG_KIND],PERCENT_ARG_INT
 mov qword [rel g60_args+PERCENT_ARG_DATA],99
 lea rdi,[rel g60_policy_percent]
 mov esi,g60_policy_percent_len
 lea rdx,[rel g60_args]
 mov ecx,1
 mov r8d,PERCENT_POLICY_ALLOW_EXTRA
 lea r9,[rel g60_policy_percent_expected]
 mov r10d,g60_policy_percent_expected_len
 call g60_run
 test eax,eax
 jnz .bad
 ; Validate-only measures but never commits the caller sentinel.
 mov ebx,123
 call g60_clear
 lea rax,[rel g60_text_world]
 mov qword [rel g60_args+PERCENT_ARG_KIND],PERCENT_ARG_TEXT
 mov [rel g60_args+PERCENT_ARG_DATA],rax
 mov qword [rel g60_args+PERCENT_ARG_LENGTH],g60_text_world_len
 lea rdi,[rel g60_t8]
 mov esi,g60_t8_len
 lea rdx,[rel g60_args]
 mov ecx,1
 mov r8d,PERCENT_POLICY_VALIDATE_ONLY
 mov r9d,512
 call g60_diagnostic_case
 test eax,eax
 jnz .bad
 cmp byte [rel g60_output],0xa5
 jne .bad
 ; Diagnostic identifiers are materialized by the runtime, not just prose.
 mov ebx,124
 mov r10d,1
.diagnostic_name:
 mov rdi,r10
 call neboc_percent_diagnostic_name
 test rax,rax
 jz .bad
 cmp rdx,15
 jne .bad
 cmp dword [rax],'NEBO'
 jne .bad
 mov dl,[rax+14]
 mov ecx,r10d
 add cl,'0'
 cmp dl,cl
 jne .bad
 inc r10d
 cmp r10d,8
 jbe .diagnostic_name
 mov edi,9
 call neboc_percent_diagnostic_name
 test rax,rax
 jnz .bad
 test rdx,rdx
 jnz .bad
 xor eax,eax
 pop rbx
 ret
.bad:
 mov eax,ebx
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
