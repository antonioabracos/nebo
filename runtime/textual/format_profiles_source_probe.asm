; G062 source-to-effect adapter. A mode succeeds only after validating every
; typed registry row in its subgroup and observing representative output from
; the shared formatting owner. The returned source seed is the process effect.
bits 64
default rel
%define NEBO_G062_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/format_profiles_source_probe.inc"
%include "runtime/textual/format_language.inc"
%include "runtime/textual/format_profiles.inc"
%include "runtime/math/transcendental.inc"

extern neboc_format_profile_lookup
extern neboc_format_profile_validate
extern neboc_format_profile_text
extern neboc_format_profile_layout
extern neboc_format_int_to_base
extern neboc_format_int_digit_count
extern neboc_format_int_sum_digits
extern neboc_format_int_reverse_digits_checked
extern neboc_format_float_fixed
extern neboc_format_float_scientific
extern neboc_format_float_round_to
extern neboc_format_float_unary
extern neboc_format_float_to_int_checked
extern neboc_format_float_classify
extern neboc_format_float_compare
extern neboc_format_number_profile
extern neboc_format_temporal_profile
extern neboc_format_structural_profile

section .rodata align=16
g62_range_start: dq 1,5,8,21,47,50,54,56,59,64
g62_range_end: dq 4,7,20,46,49,53,55,58,63,65
g62_range_kind: dq 1,1,2,3,4,5,6,7,1,8
g62_text: db 'A&',10
g62_text_len equ $-g62_text
g62_quote_expected: db '"A&',92,'n"'
g62_quote_expected_len equ $-g62_quote_expected
g62_json_expected: db '"A&',92,'n"'
g62_json_expected_len equ $-g62_json_expected
g62_html_expected: db 'A&amp;',10
g62_html_expected_len equ $-g62_html_expected
g62_markdown: db 'a*b'
g62_markdown_expected: db 'a',92,'*b'
g62_xy: db 'xy'
g62_long_text: db 'abcdefghi'
g62_ansi: db 'x',27,'y'
g62_ansi_expected: db 'x',92,'ey'
g62_redacted_expected: db '[redacted]'
g62_hex_expected: db '-ff'
g62_binary_expected: db '101010'
g62_align_expected: db '..xy..'
g62_pad_expected: db '---xy'
g62_truncate_expected: db 'abc...'
g62_fixed_expected: db '12.35'
g62_fixed_negative_expected: db '-12.35'
g62_scientific_expected: db '1.23e+03'
g62_scientific_negative_expected: db '-1.23e+03'
g62_percent_expected: db '73%'
g62_number_expected: db '73'
g62_currency_expected: db 'EUR 73'
g62_bytes_expected: db '2 KiB'
g62_speed_expected: db '3 KiB/s'
g62_date_expected: db '2026-09-02'
g62_time_expected: db '07:08:09'
g62_datetime_expected: db '2026-09-02T07:08:09'
g62_duration_expected: db 'PT73S'
g62_type_name: db 'Point'
g62_struct_value: db '3,5'
g62_inspect_expected: db '<Point 3,5>'
g62_struct_expected: db '{Point:3,5}'
g62_float_12_345: dq 12.346
g62_float_negative_12_345: dq -12.346
g62_float_1234: dq 1234.0
g62_float_negative_1234: dq -1234.0
g62_float_2_5: dq 2.5
g62_float_2: dq 2.0
g62_float_10: dq 10.0
g62_float_10_001: dq 10.001
g62_float_tol: dq 0.01
g62_float_zero: dq 0.0
g62_float_one: dq 1.0
g62_float_infinity: dq 0x7ff0000000000000

section .bss align=16
g62_output: resb 256
g62_before: resb 256
g62_layout: resb FORMAT_LAYOUT_SIZE
g62_temporal: resb FORMAT_TEMPORAL_SIZE
g62_structural: resb FORMAT_STRUCTURAL_SIZE
g62_stage: resd 1

section .text
global nebo_g062_source_probe
global nebo_g062_negative_probe

g62_clear_output:
 lea rdi,[rel g62_output]
 mov ecx,32
 mov rax,0xa5a5a5a5a5a5a5a5
 rep stosq
 ret

; RDI expected bytes, RSI length -> EAX bool against g62_output.
g62_output_equals:
 lea rdx,[rel g62_output]
 xor ecx,ecx
.loop:
 cmp rcx,rsi
 jae .yes
 mov al,[rdx+rcx]
 cmp al,[rdi+rcx]
 jne .no
 inc rcx
 jmp .loop
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

; EDI subgroup 1..10. Validate every public profile row and its input kind.
g62_validate_range:
 push rbx
 push r12
 push r13
 mov ebx,edi
 cmp ebx,1
 jb .fail
 cmp ebx,10
 ja .fail
 lea rax,[rel g62_range_start]
 mov r12,[rax+rbx*8-8]
 lea rax,[rel g62_range_end]
 mov r13,[rax+rbx*8-8]
.row:
 mov rdi,r12
 call neboc_format_profile_lookup
 test rax,rax
 jz .fail
 cmp [rax+FORMAT_PROFILE_ID],r12
 jne .fail
 cmp [rax+FORMAT_PROFILE_SUBGROUP],rbx
 jne .fail
 lea rcx,[rel g62_range_kind]
 mov rsi,[rcx+rbx*8-8]
 cmp [rax+FORMAT_PROFILE_INPUT_KIND],rsi
 jne .fail
 mov rdi,r12
 call neboc_format_profile_validate
 test eax,eax
 jnz .fail
 inc r12
 cmp r12,r13
 jbe .row
 xor eax,eax
 jmp .done
.fail:
 mov eax,1
.done:
 pop r13
 pop r12
 pop rbx
 ret

g62_mode_1:
 sub rsp,8
 call g62_clear_output
 mov edi,FORMAT_PROFILE_TEXT
 lea rsi,[rel g62_text]
 mov edx,g62_text_len
 lea rcx,[rel g62_output]
 mov r8d,256
 xor r9d,r9d
 call neboc_format_profile_text
 cmp rax,g62_text_len
 jne .fail
 call g62_clear_output
 mov edi,FORMAT_PROFILE_QUOTE
 lea rsi,[rel g62_text]
 mov edx,g62_text_len
 lea rcx,[rel g62_output]
 mov r8d,256
 xor r9d,r9d
 call neboc_format_profile_text
 cmp rax,g62_quote_expected_len
 jne .fail
 lea rdi,[rel g62_quote_expected]
 mov esi,g62_quote_expected_len
 call g62_output_equals
 test eax,eax
 jz .fail
 call g62_clear_output
 mov edi,FORMAT_PROFILE_ESCAPE
 lea rsi,[rel g62_text]
 mov edx,g62_text_len
 lea rcx,[rel g62_output]
 mov r8d,256
 mov r9d,FORMAT_PROFILE_POLICY_JSON
 call neboc_format_profile_text
 cmp rax,4
 jne .fail
 call g62_clear_output
 mov edi,FORMAT_PROFILE_LITERAL
 lea rsi,[rel g62_text]
 mov edx,g62_text_len
 lea rcx,[rel g62_output]
 mov r8d,256
 xor r9d,r9d
 call neboc_format_profile_text
 cmp rax,g62_text_len
 jne .fail
 xor eax,eax
 jmp .done
.fail: mov eax,11
.done: add rsp,8
 ret

g62_mode_2:
 sub rsp,8
 call g62_clear_output
 lea rbx,[rel g62_layout]
 mov qword [rbx+FORMAT_LAYOUT_PROFILE],FORMAT_PROFILE_ALIGN
 lea rax,[rel g62_xy]
 mov [rbx+FORMAT_LAYOUT_DATA],rax
 mov qword [rbx+FORMAT_LAYOUT_LENGTH],2
 mov qword [rbx+FORMAT_LAYOUT_WIDTH],6
 mov byte [rbx+FORMAT_LAYOUT_FILL],'.'
 mov qword [rbx+FORMAT_LAYOUT_SIDE],FORMAT_PROFILE_SIDE_CENTER
 lea rax,[rel g62_output]
 mov [rbx+FORMAT_LAYOUT_OUTPUT],rax
 mov qword [rbx+FORMAT_LAYOUT_CAPACITY],256
 mov rdi,rbx
 call neboc_format_profile_layout
 cmp rax,6
 jne .fail
 lea rdi,[rel g62_align_expected]
 mov esi,6
 call g62_output_equals
 test eax,eax
 jz .fail
 mov qword [rbx+FORMAT_LAYOUT_PROFILE],FORMAT_PROFILE_PAD
 mov byte [rbx+FORMAT_LAYOUT_FILL],'-'
 mov qword [rbx+FORMAT_LAYOUT_SIDE],FORMAT_PROFILE_SIDE_RIGHT
 mov qword [rbx+FORMAT_LAYOUT_WIDTH],5
 mov rdi,rbx
 call neboc_format_profile_layout
 cmp rax,5
 jne .fail
 lea rdi,[rel g62_pad_expected]
 mov esi,5
 call g62_output_equals
 test eax,eax
 jz .fail
 lea rax,[rel g62_long_text]
 mov [rbx+FORMAT_LAYOUT_DATA],rax
 mov qword [rbx+FORMAT_LAYOUT_LENGTH],9
 mov qword [rbx+FORMAT_LAYOUT_WIDTH],6
 mov qword [rbx+FORMAT_LAYOUT_PROFILE],FORMAT_PROFILE_TRUNCATE
 mov rdi,rbx
 call neboc_format_profile_layout
 cmp rax,6
 jne .fail
 lea rdi,[rel g62_truncate_expected]
 mov esi,6
 call g62_output_equals
 test eax,eax
 jz .fail
 xor eax,eax
 jmp .done
.fail: mov eax,21
.done: add rsp,8
 ret

g62_mode_3:
 sub rsp,8
 call g62_clear_output
 mov rdi,-255
 mov esi,16
 xor edx,edx
 lea rcx,[rel g62_output]
 mov r8d,256
 call neboc_format_int_to_base
 cmp rax,3
 jne .fail
 lea rdi,[rel g62_hex_expected]
 mov esi,3
 call g62_output_equals
 test eax,eax
 jz .fail
 mov rdi,42
 mov esi,2
 xor edx,edx
 lea rcx,[rel g62_output]
 mov r8d,256
 call neboc_format_int_to_base
 cmp rax,6
 jne .fail
 lea rdi,[rel g62_binary_expected]
 mov esi,6
 call g62_output_equals
 test eax,eax
 jz .fail
 mov rdi,-98760
 call neboc_format_int_digit_count
 cmp eax,5
 jne .fail
 mov rdi,-98760
 call neboc_format_int_sum_digits
 cmp eax,30
 jne .fail
 mov rdi,-1203
 call neboc_format_int_reverse_digits_checked
 test eax,eax
 jnz .fail
 cmp rdx,-3021
 jne .fail
 xor eax,eax
 jmp .done
.fail: mov eax,31
.done: add rsp,8
 ret

g62_mode_4:
 sub rsp,8
 mov dword [rel g62_stage],42
 call g62_clear_output
 movsd xmm0,[rel g62_float_12_345]
 mov edi,2
 lea rsi,[rel g62_output]
 mov edx,256
 call neboc_format_float_fixed
 cmp rax,5
 jne .fail
 lea rdi,[rel g62_fixed_expected]
 mov esi,5
 call g62_output_equals
 test eax,eax
 jz .fail
 movsd xmm0,[rel g62_float_negative_12_345]
 mov edi,2
 lea rsi,[rel g62_output]
 mov edx,256
 call neboc_format_float_fixed
 cmp rax,6
 jne .fail
 lea rdi,[rel g62_fixed_negative_expected]
 mov esi,6
 call g62_output_equals
 test eax,eax
 jz .fail
 mov dword [rel g62_stage],43
 movsd xmm0,[rel g62_float_1234]
 mov edi,2
 lea rsi,[rel g62_output]
 mov edx,256
 call neboc_format_float_scientific
 cmp rax,8
 jne .fail
 lea rdi,[rel g62_scientific_expected]
 mov esi,8
 call g62_output_equals
 test eax,eax
 jz .fail
 movsd xmm0,[rel g62_float_negative_1234]
 mov edi,2
 lea rsi,[rel g62_output]
 mov edx,256
 call neboc_format_float_scientific
 cmp rax,9
 jne .fail
 lea rdi,[rel g62_scientific_negative_expected]
 mov esi,9
 call g62_output_equals
 test eax,eax
 jz .fail
 mov dword [rel g62_stage],44
 movsd xmm0,[rel g62_float_2_5]
 mov edi,0
 call neboc_format_float_round_to
 test eax,eax
 jnz .fail
 ucomisd xmm0,[rel g62_float_2]
 jne .fail
 mov dword [rel g62_stage],45
 movsd xmm0,[rel g62_float_2_5]
 mov edi,FORMAT_PROFILE_FLOAT_ROUND_INT
 call neboc_format_float_to_int_checked
 test eax,eax
 jnz .fail
 cmp rdx,2
 jne .fail
 mov dword [rel g62_stage],46
 movsd xmm0,[rel g62_float_12_345]
 mov edi,FORMAT_PROFILE_FLOAT_FLOOR
 call neboc_format_float_unary
 test eax,eax
 jnz .fail
 mov dword [rel g62_stage],47
 movsd xmm0,[rel g62_float_10]
 call neboc_format_float_classify
 test eax,NEBO_FLOAT_FINITE
 jz .fail
 mov dword [rel g62_stage],48
 movsd xmm0,[rel g62_float_10]
 movsd xmm1,[rel g62_float_10_001]
 movsd xmm2,[rel g62_float_tol]
 mov edi,FORMAT_PROFILE_FLOAT_APPROX
 call neboc_format_float_compare
 test eax,eax
 jnz .fail
 test edx,edx
 jz .fail
 mov dword [rel g62_stage],49
 movsd xmm0,[rel g62_float_10_001]
 movsd xmm1,[rel g62_float_10]
 movsd xmm2,[rel g62_float_tol]
 mov edi,FORMAT_PROFILE_FLOAT_ABS_ERROR
 call neboc_format_float_compare
 test eax,eax
 jnz .fail
 ucomisd xmm0,[rel g62_float_zero]
 jbe .fail
 xor eax,eax
 jmp .done
.fail: mov eax,[rel g62_stage]
.done: add rsp,8
 ret

g62_mode_5:
 sub rsp,8
 call g62_clear_output
 mov edi,FORMAT_PROFILE_PERCENT
 mov esi,73
 lea rdx,[rel g62_output]
 mov ecx,256
 mov r8d,FORMAT_PROFILE_POLICY_ROOT
 call neboc_format_number_profile
 cmp rax,3
 jne .fail
 lea rdi,[rel g62_percent_expected]
 mov esi,3
 call g62_output_equals
 test eax,eax
 jz .fail
 mov edi,FORMAT_PROFILE_NUMBER
 mov esi,73
 lea rdx,[rel g62_output]
 mov ecx,256
 mov r8d,FORMAT_PROFILE_POLICY_ROOT
 call neboc_format_number_profile
 cmp rax,2
 jne .fail
 mov edi,FORMAT_PROFILE_CURRENCY
 mov esi,73
 lea rdx,[rel g62_output]
 mov ecx,256
 mov r8d,FORMAT_PROFILE_POLICY_EUR
 call neboc_format_number_profile
 cmp rax,6
 jne .fail
 lea rdi,[rel g62_currency_expected]
 mov esi,6
 call g62_output_equals
 test eax,eax
 jz .fail
 xor eax,eax
 jmp .done
.fail: mov eax,51
.done: add rsp,8
 ret

g62_init_temporal:
 lea rdi,[rel g62_temporal]
 mov qword [rdi+FORMAT_TEMPORAL_YEAR],2026
 mov qword [rdi+FORMAT_TEMPORAL_MONTH],9
 mov qword [rdi+FORMAT_TEMPORAL_DAY],2
 mov qword [rdi+FORMAT_TEMPORAL_HOUR],7
 mov qword [rdi+FORMAT_TEMPORAL_MINUTE],8
 mov qword [rdi+FORMAT_TEMPORAL_SECOND],9
 mov qword [rdi+FORMAT_TEMPORAL_DURATION_SECONDS],73
 ret

g62_mode_6:
 sub rsp,8
 call g62_init_temporal
 mov edi,FORMAT_PROFILE_DATE
 lea rsi,[rel g62_temporal]
 lea rdx,[rel g62_output]
 mov ecx,256
 call neboc_format_temporal_profile
 cmp rax,10
 jne .fail
 lea rdi,[rel g62_date_expected]
 mov esi,10
 call g62_output_equals
 test eax,eax
 jz .fail
 mov edi,FORMAT_PROFILE_TIME
 lea rsi,[rel g62_temporal]
 lea rdx,[rel g62_output]
 mov ecx,256
 call neboc_format_temporal_profile
 cmp rax,8
 jne .fail
 lea rdi,[rel g62_time_expected]
 mov esi,8
 call g62_output_equals
 test eax,eax
 jz .fail
 mov edi,FORMAT_PROFILE_DATETIME
 lea rsi,[rel g62_temporal]
 lea rdx,[rel g62_output]
 mov ecx,256
 call neboc_format_temporal_profile
 cmp rax,19
 jne .fail
 lea rdi,[rel g62_datetime_expected]
 mov esi,19
 call g62_output_equals
 test eax,eax
 jz .fail
 mov edi,FORMAT_PROFILE_DURATION
 lea rsi,[rel g62_temporal]
 lea rdx,[rel g62_output]
 mov ecx,256
 call neboc_format_temporal_profile
 cmp rax,5
 jne .fail
 lea rdi,[rel g62_duration_expected]
 mov esi,5
 call g62_output_equals
 test eax,eax
 jz .fail
 xor eax,eax
 jmp .done
.fail: mov eax,61
.done: add rsp,8
 ret

g62_mode_7:
 sub rsp,8
 mov edi,FORMAT_PROFILE_BYTES
 mov esi,2048
 lea rdx,[rel g62_output]
 mov ecx,256
 mov r8d,FORMAT_PROFILE_POLICY_IEC
 call neboc_format_number_profile
 cmp rax,5
 jne .fail
 lea rdi,[rel g62_bytes_expected]
 mov esi,5
 call g62_output_equals
 test eax,eax
 jz .fail
 mov edi,FORMAT_PROFILE_SPEED
 mov esi,3072
 lea rdx,[rel g62_output]
 mov ecx,256
 mov r8d,FORMAT_PROFILE_POLICY_IEC
 call neboc_format_number_profile
 cmp rax,7
 jne .fail
 lea rdi,[rel g62_speed_expected]
 mov esi,7
 call g62_output_equals
 test eax,eax
 jz .fail
 xor eax,eax
 jmp .done
.fail: mov eax,71
.done: add rsp,8
 ret

g62_init_structural:
 lea rdi,[rel g62_structural]
 lea rax,[rel g62_type_name]
 mov [rdi+FORMAT_STRUCTURAL_TYPE],rax
 mov qword [rdi+FORMAT_STRUCTURAL_TYPE_LENGTH],5
 lea rax,[rel g62_struct_value]
 mov [rdi+FORMAT_STRUCTURAL_VALUE],rax
 mov qword [rdi+FORMAT_STRUCTURAL_VALUE_LENGTH],3
 mov qword [rdi+FORMAT_STRUCTURAL_DEPTH],2
 lea rax,[rel g62_output]
 mov [rdi+FORMAT_STRUCTURAL_OUTPUT],rax
 mov qword [rdi+FORMAT_STRUCTURAL_CAPACITY],256
 ret

g62_mode_8:
 sub rsp,8
 call g62_init_structural
 lea rbx,[rel g62_structural]
 mov qword [rbx+FORMAT_STRUCTURAL_PROFILE],FORMAT_PROFILE_TYPE
 mov rdi,rbx
 call neboc_format_structural_profile
 cmp rax,5
 jne .fail
 lea rdi,[rel g62_type_name]
 mov esi,5
 call g62_output_equals
 test eax,eax
 jz .fail
 mov qword [rbx+FORMAT_STRUCTURAL_PROFILE],FORMAT_PROFILE_INSPECT
 mov rdi,rbx
 call neboc_format_structural_profile
 cmp rax,11
 jne .fail
 lea rdi,[rel g62_inspect_expected]
 mov esi,11
 call g62_output_equals
 test eax,eax
 jz .fail
 mov qword [rbx+FORMAT_STRUCTURAL_PROFILE],FORMAT_PROFILE_STRUCTURAL
 mov rdi,rbx
 call neboc_format_structural_profile
 cmp rax,11
 jne .fail
 lea rdi,[rel g62_struct_expected]
 mov esi,11
 call g62_output_equals
 test eax,eax
 jz .fail
 xor eax,eax
 jmp .done
.fail: mov eax,81
.done: add rsp,8
 ret

g62_mode_9:
 sub rsp,8
 mov edi,FORMAT_PROFILE_JSON
 lea rsi,[rel g62_text]
 mov edx,g62_text_len
 lea rcx,[rel g62_output]
 mov r8d,256
 xor r9d,r9d
 call neboc_format_profile_text
 cmp rax,g62_json_expected_len
 jne .fail
 lea rdi,[rel g62_json_expected]
 mov esi,g62_json_expected_len
 call g62_output_equals
 test eax,eax
 jz .fail
 mov edi,FORMAT_PROFILE_MARKDOWN
 lea rsi,[rel g62_markdown]
 mov edx,3
 lea rcx,[rel g62_output]
 mov r8d,256
 xor r9d,r9d
 call neboc_format_profile_text
 cmp rax,4
 jne .fail
 lea rdi,[rel g62_markdown_expected]
 mov esi,4
 call g62_output_equals
 test eax,eax
 jz .fail
 mov edi,FORMAT_PROFILE_HTML
 lea rsi,[rel g62_text]
 mov edx,g62_text_len
 lea rcx,[rel g62_output]
 mov r8d,256
 xor r9d,r9d
 call neboc_format_profile_text
 cmp rax,g62_html_expected_len
 jne .fail
 lea rdi,[rel g62_html_expected]
 mov esi,g62_html_expected_len
 call g62_output_equals
 test eax,eax
 jz .fail
 mov edi,FORMAT_PROFILE_ANSI
 lea rsi,[rel g62_ansi]
 mov edx,3
 lea rcx,[rel g62_output]
 mov r8d,256
 xor r9d,r9d
 call neboc_format_profile_text
 cmp rax,4
 jne .fail
 lea rdi,[rel g62_ansi_expected]
 mov esi,4
 call g62_output_equals
 test eax,eax
 jz .fail
 mov edi,FORMAT_PROFILE_PLAIN
 lea rsi,[rel g62_text]
 mov edx,g62_text_len
 lea rcx,[rel g62_output]
 mov r8d,256
 xor r9d,r9d
 call neboc_format_profile_text
 cmp rax,g62_text_len
 jne .fail
 xor eax,eax
 jmp .done
.fail: mov eax,91
.done: add rsp,8
 ret

g62_mode_10:
 sub rsp,8
 mov edi,FORMAT_PROFILE_REDACT
 lea rsi,[rel g62_text]
 mov edx,g62_text_len
 lea rcx,[rel g62_output]
 mov r8d,256
 xor r9d,r9d
 call neboc_format_profile_text
 cmp rax,10
 jne .fail
 lea rdi,[rel g62_redacted_expected]
 mov esi,10
 call g62_output_equals
 test eax,eax
 jz .fail
 mov edi,FORMAT_PROFILE_HASH
 lea rsi,[rel g62_text]
 mov edx,g62_text_len
 lea rcx,[rel g62_output]
 mov r8d,256
 mov r9d,FORMAT_PROFILE_POLICY_FNV1A64
 call neboc_format_profile_text
 cmp rax,16
 jne .fail
 xor eax,eax
 jmp .done
.fail: mov eax,101
.done: add rsp,8
 ret

; EDI mode, ESI source seed -> EAX source seed after concrete observations.
nebo_g062_source_probe:
 push rbx
 push r12
 push r13
 mov ebx,edi
 mov r13d,esi
 mov edi,ebx
 call g62_validate_range
 test eax,eax
 jnz .fail
 cmp ebx,1
 je .m1
 cmp ebx,2
 je .m2
 cmp ebx,3
 je .m3
 cmp ebx,4
 je .m4
 cmp ebx,5
 je .m5
 cmp ebx,6
 je .m6
 cmp ebx,7
 je .m7
 cmp ebx,8
 je .m8
 cmp ebx,9
 je .m9
 cmp ebx,10
 je .m10
 jmp .fail
.m1: call g62_mode_1
 jmp .checked
.m2: call g62_mode_2
 jmp .checked
.m3: call g62_mode_3
 jmp .checked
.m4: call g62_mode_4
 jmp .checked
.m5: call g62_mode_5
 jmp .checked
.m6: call g62_mode_6
 jmp .checked
.m7: call g62_mode_7
 jmp .checked
.m8: call g62_mode_8
 jmp .checked
.m9: call g62_mode_9
 jmp .checked
.m10: call g62_mode_10
.checked:
 test eax,eax
 jnz .done
 mov eax,r13d
 jmp .done
.fail:
 mov eax,1
.done:
 pop r13
 pop r12
 pop rbx
 ret

; Independent negative/adversarial probe. Returns zero only if invalid type,
; policy and capacity are rejected without modifying the caller buffer.
nebo_g062_negative_probe:
 push rbx
 sub rsp,16
 mov dword [rel g62_stage],111
 mov edi,0
 call neboc_format_profile_lookup
 test rax,rax
 jnz .fail
 mov dword [rel g62_stage],112
 mov edi,FORMAT_PROFILE_TEXT
 mov esi,FORMAT_PROFILE_INPUT_FLOAT
 call neboc_format_profile_validate
 cmp eax,FORMAT_E_INVALID
 jne .fail
 mov dword [rel g62_stage],113
 call g62_clear_output
 lea rsi,[rel g62_output]
 lea rdi,[rel g62_before]
 mov ecx,32
 rep movsq
 mov edi,FORMAT_PROFILE_QUOTE
 lea rsi,[rel g62_text]
 mov edx,g62_text_len
 lea rcx,[rel g62_output]
 mov r8d,1
 xor r9d,r9d
 call neboc_format_profile_text
 cmp rax,-FORMAT_E_CAPACITY
 jne .fail
 mov dword [rel g62_stage],114
 lea rsi,[rel g62_output]
 lea rdi,[rel g62_before]
 mov ecx,32
.atomic:
 mov rax,[rsi]
 cmp rax,[rdi]
 jne .fail
 add rsi,8
 add rdi,8
 loop .atomic
 mov dword [rel g62_stage],115
 mov edi,FORMAT_PROFILE_HASH
 lea rsi,[rel g62_text]
 mov edx,g62_text_len
 lea rcx,[rel g62_output]
 mov r8d,256
 mov r9d,FORMAT_PROFILE_POLICY_ROOT
 call neboc_format_profile_text
 cmp rax,-FORMAT_E_INVALID
 jne .fail
 mov dword [rel g62_stage],116
 lea rbx,[rel g62_layout]
 mov qword [rbx+FORMAT_LAYOUT_PROFILE],FORMAT_PROFILE_PAD
 mov qword [rbx+FORMAT_LAYOUT_WIDTH],FORMAT_PROFILE_MAX_WIDTH+1
 mov rdi,rbx
 call neboc_format_profile_layout
 cmp rax,-FORMAT_E_LIMIT
 jne .fail
 mov dword [rel g62_stage],117
 mov rdi,8085774586302733229
 call neboc_format_int_reverse_digits_checked
 cmp eax,FORMAT_E_LIMIT
 jne .fail
 mov dword [rel g62_stage],118
 call g62_init_temporal
 mov qword [rel g62_temporal+FORMAT_TEMPORAL_MONTH],13
 mov edi,FORMAT_PROFILE_DATE
 lea rsi,[rel g62_temporal]
 lea rdx,[rel g62_output]
 mov ecx,256
 call neboc_format_temporal_profile
 cmp rax,-FORMAT_E_INVALID
 jne .fail
 mov dword [rel g62_stage],119
 call g62_init_structural
 mov qword [rel g62_structural+FORMAT_STRUCTURAL_DEPTH],FORMAT_PROFILE_MAX_DEPTH+1
 lea rdi,[rel g62_structural]
 call neboc_format_structural_profile
 cmp rax,-FORMAT_E_LIMIT
 jne .fail
 mov dword [rel g62_stage],120
 movsd xmm0,[rel g62_float_infinity]
 mov edi,FORMAT_PROFILE_FLOAT_TRUNC
 call neboc_format_float_unary
 cmp eax,FORMAT_E_INVALID
 jne .fail
 mov dword [rel g62_stage],121
 movsd xmm0,[rel g62_float_infinity]
 mov edi,2
 lea rsi,[rel g62_output]
 mov edx,256
 call neboc_format_float_fixed
 cmp rax,-FORMAT_E_INVALID
 jne .fail
 mov dword [rel g62_stage],122
 mov edi,FORMAT_PROFILE_BYTES
 mov rsi,-1
 lea rdx,[rel g62_output]
 mov ecx,256
 mov r8d,FORMAT_PROFILE_POLICY_IEC
 call neboc_format_number_profile
 cmp rax,-FORMAT_E_INVALID
 jne .fail
 mov dword [rel g62_stage],123
 call g62_init_temporal
 mov qword [rel g62_temporal+FORMAT_TEMPORAL_YEAR],2025
 mov qword [rel g62_temporal+FORMAT_TEMPORAL_MONTH],2
 mov qword [rel g62_temporal+FORMAT_TEMPORAL_DAY],29
 mov edi,FORMAT_PROFILE_DATE
 lea rsi,[rel g62_temporal]
 lea rdx,[rel g62_output]
 mov ecx,256
 call neboc_format_temporal_profile
 cmp rax,-FORMAT_E_INVALID
 jne .fail
 mov dword [rel g62_stage],124
 call g62_init_structural
 mov qword [rel g62_structural+FORMAT_STRUCTURAL_VALUE],0
 lea rdi,[rel g62_structural]
 call neboc_format_structural_profile
 cmp rax,-FORMAT_E_INVALID
 jne .fail
 xor eax,eax
 jmp .done
.fail:
 mov eax,[rel g62_stage]
.done:
 add rsp,16
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
