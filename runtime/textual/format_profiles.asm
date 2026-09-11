; G062 bounded typed formatting profiles for the freestanding x86-64 runtime.
; Every operation is pure, caller-buffered and failure-atomic. Locale,
; timezone, escaping and hashing policies are explicit integer capabilities.
bits 64
default rel
%include "runtime/textual/format_language.inc"
%include "runtime/textual/format_profiles.inc"
%include "runtime/math/transcendental.inc"

section .rodata align=16
format_profile_registry:
%assign __profile_id 1
%rep 4
 dq __profile_id,1,FORMAT_PROFILE_INPUT_TEXT,FORMAT_PROFILE_FLAG_PURE|FORMAT_PROFILE_FLAG_BOUNDED
%assign __profile_id __profile_id+1
%endrep
%rep 3
 dq __profile_id,2,FORMAT_PROFILE_INPUT_TEXT,FORMAT_PROFILE_FLAG_PURE|FORMAT_PROFILE_FLAG_BOUNDED
%assign __profile_id __profile_id+1
%endrep
%rep 13
 dq __profile_id,3,FORMAT_PROFILE_INPUT_INT,FORMAT_PROFILE_FLAG_PURE|FORMAT_PROFILE_FLAG_BOUNDED
%assign __profile_id __profile_id+1
%endrep
%rep 26
 dq __profile_id,4,FORMAT_PROFILE_INPUT_FLOAT,FORMAT_PROFILE_FLAG_PURE|FORMAT_PROFILE_FLAG_BOUNDED
%assign __profile_id __profile_id+1
%endrep
%rep 3
 dq __profile_id,5,FORMAT_PROFILE_INPUT_NUMBER,FORMAT_PROFILE_FLAG_PURE|FORMAT_PROFILE_FLAG_POLICY|FORMAT_PROFILE_FLAG_BOUNDED
%assign __profile_id __profile_id+1
%endrep
%rep 4
 dq __profile_id,6,FORMAT_PROFILE_INPUT_TEMPORAL,FORMAT_PROFILE_FLAG_PURE|FORMAT_PROFILE_FLAG_POLICY|FORMAT_PROFILE_FLAG_BOUNDED
%assign __profile_id __profile_id+1
%endrep
%rep 2
 dq __profile_id,7,FORMAT_PROFILE_INPUT_BYTES,FORMAT_PROFILE_FLAG_PURE|FORMAT_PROFILE_FLAG_BOUNDED
%assign __profile_id __profile_id+1
%endrep
%rep 3
 dq __profile_id,8,FORMAT_PROFILE_INPUT_STRUCTURAL,FORMAT_PROFILE_FLAG_PURE|FORMAT_PROFILE_FLAG_BOUNDED
%assign __profile_id __profile_id+1
%endrep
%rep 5
 dq __profile_id,9,FORMAT_PROFILE_INPUT_TEXT,FORMAT_PROFILE_FLAG_PURE|FORMAT_PROFILE_FLAG_POLICY|FORMAT_PROFILE_FLAG_BOUNDED
%assign __profile_id __profile_id+1
%endrep
 dq __profile_id,10,FORMAT_PROFILE_INPUT_PRIVATE,FORMAT_PROFILE_FLAG_PURE|FORMAT_PROFILE_FLAG_BOUNDED|FORMAT_PROFILE_FLAG_REDACTED
%assign __profile_id __profile_id+1
 dq __profile_id,10,FORMAT_PROFILE_INPUT_PRIVATE,FORMAT_PROFILE_FLAG_PURE|FORMAT_PROFILE_FLAG_POLICY|FORMAT_PROFILE_FLAG_BOUNDED
%undef __profile_id
format_profile_registry_end:

format_profile_hex: db '0123456789abcdef'
format_profile_hex_upper: db '0123456789ABCDEF'
format_profile_redacted: db '[redacted]'
format_profile_redacted_len equ $-format_profile_redacted
format_profile_html_lt: db '&lt;'
format_profile_html_gt: db '&gt;'
format_profile_html_amp: db '&amp;'
format_profile_html_quote: db '&quot;'
format_profile_ellipsis: db '...'
format_profile_eur: db 'EUR '
format_profile_kib: db ' KiB'
format_profile_kib_s: db ' KiB/s'
align 8
format_profile_pow10: dq 1.0,10.0,100.0,1000.0,10000.0,100000.0,1000000.0
format_profile_zero: dq 0.0
format_profile_hundred: dq 100.0
format_profile_i64_pos_limit: dq 0x43e0000000000000
format_profile_i64_neg_limit: dq 0xc3e0000000000000
format_profile_abs_mask: dq 0x7fffffffffffffff
format_profile_exp_mask: dq 0x7ff0000000000000

section .text
global neboc_format_profile_lookup
global neboc_format_profile_validate
global neboc_format_profile_text
global neboc_format_profile_layout
global neboc_format_int_to_base
global neboc_format_int_digit_count
global neboc_format_int_sum_digits
global neboc_format_int_reverse_digits_checked
global neboc_format_float_fixed
global neboc_format_float_scientific
global neboc_format_float_round_to
global neboc_format_float_unary
global neboc_format_float_to_int_checked
global neboc_format_float_classify
global neboc_format_float_compare
global neboc_format_number_profile
global neboc_format_temporal_profile
global neboc_format_structural_profile

; RDI profile id -> RAX immutable registry row or zero.
neboc_format_profile_lookup:
 cmp rdi,FORMAT_PROFILE_FIRST
 jb .missing
 cmp rdi,FORMAT_PROFILE_LAST
 ja .missing
 dec rdi
 shl rdi,5
 lea rax,[rel format_profile_registry]
 add rax,rdi
 ret
.missing:
 xor eax,eax
 ret

; RDI profile id, RSI declared input kind -> typed status.
neboc_format_profile_validate:
 sub rsp,8
 call neboc_format_profile_lookup
 add rsp,8
 test rax,rax
 jz .unavailable
 mov rcx,[rax+FORMAT_PROFILE_INPUT_KIND]
 test rcx,rcx
 jz .ok
 cmp rcx,rsi
 jne .invalid
.ok:
 xor eax,eax
 ret
.invalid:
 mov eax,FORMAT_E_INVALID
 ret
.unavailable:
 mov eax,FORMAT_E_UNAVAILABLE
 ret

; RDI profile id, RSI input, RDX len, RCX output, R8 capacity, R9 policy.
; Returns bytes or negative FORMAT_E_*. Profiles text/quote/escape/literal,
; JSON/Markdown/HTML/ANSI/plain and privacy redact/hash share this owner.
neboc_format_profile_text:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov ebx,edi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 mov r10,r9
 cmp r13,FORMAT_PROFILE_MAX_TEXT
 ja .text_limit
 test r13,r13
 jz .text_profile
 test r12,r12
 jz .text_invalid
.text_profile:
 cmp ebx,FORMAT_PROFILE_ESCAPE
 jne .text_measure
 cmp r10,FORMAT_PROFILE_POLICY_JSON
 je .escape_json
 cmp r10,FORMAT_PROFILE_POLICY_MARKDOWN
 je .escape_markdown
 cmp r10,FORMAT_PROFILE_POLICY_HTML
 je .escape_html
 cmp r10,FORMAT_PROFILE_POLICY_ANSI
 jne .text_invalid
 mov ebx,FORMAT_PROFILE_ANSI
 jmp .text_measure
.escape_json: mov ebx,70
 jmp .text_measure
.escape_markdown: mov ebx,FORMAT_PROFILE_MARKDOWN
 jmp .text_measure
.escape_html: mov ebx,FORMAT_PROFILE_HTML

.text_measure:
 cmp ebx,FORMAT_PROFILE_REDACT
 je .measure_redact
 cmp ebx,FORMAT_PROFILE_HASH
 je .measure_hash
 cmp ebx,FORMAT_PROFILE_TEXT
 je .measure_copy
 cmp ebx,FORMAT_PROFILE_LITERAL
 je .measure_copy
 cmp ebx,FORMAT_PROFILE_PLAIN
 je .measure_copy
 cmp ebx,FORMAT_PROFILE_QUOTE
 je .measure_quoted
 cmp ebx,FORMAT_PROFILE_JSON
 je .measure_quoted
 cmp ebx,70
 je .measure_json_escape
 cmp ebx,FORMAT_PROFILE_MARKDOWN
 je .measure_markdown
 cmp ebx,FORMAT_PROFILE_HTML
 je .measure_html
 cmp ebx,FORMAT_PROFILE_ANSI
 je .measure_ansi
 jmp .text_invalid
.measure_redact:
 mov r11d,format_profile_redacted_len
 jmp .text_preflight
.measure_hash:
 cmp r10,FORMAT_PROFILE_POLICY_FNV1A64
 jne .text_invalid
 mov r11d,16
 jmp .text_preflight
.measure_copy:
 mov r11,r13
 jmp .text_preflight
.measure_quoted:
 lea r11,[r13+2]
 jmp .measure_json_loop_start
.measure_json_escape:
 mov r11,r13
.measure_json_loop_start:
 xor ecx,ecx
.measure_json_loop:
 cmp rcx,r13
 jae .text_preflight
 mov al,[r12+rcx]
 cmp al,'"'
 je .measure_json_extra
 cmp al,'\'
 je .measure_json_extra
 cmp al,10
 jne .measure_json_next
.measure_json_extra:
 inc r11
.measure_json_next:
 inc rcx
 jmp .measure_json_loop
.measure_markdown:
 mov r11,r13
 xor ecx,ecx
.measure_markdown_loop:
 cmp rcx,r13
 jae .text_preflight
 mov al,[r12+rcx]
 cmp al,'*'
 je .measure_markdown_extra
 cmp al,'_'
 je .measure_markdown_extra
 cmp al,'['
 je .measure_markdown_extra
 cmp al,']'
 je .measure_markdown_extra
 cmp al,'#'
 je .measure_markdown_extra
 cmp al,'\'
 jne .measure_markdown_next
.measure_markdown_extra:
 inc r11
.measure_markdown_next:
 inc rcx
 jmp .measure_markdown_loop
.measure_ansi:
 mov r11,r13
 xor ecx,ecx
.measure_ansi_loop:
 cmp rcx,r13
 jae .text_preflight
 cmp byte [r12+rcx],27
 jne .measure_ansi_next
 inc r11
.measure_ansi_next:
 inc rcx
 jmp .measure_ansi_loop
.measure_html:
 mov r11,r13
 xor ecx,ecx
.measure_html_loop:
 cmp rcx,r13
 jae .text_preflight
 mov al,[r12+rcx]
 cmp al,'&'
 je .measure_html_amp
 cmp al,'<'
 je .measure_html_angle
 cmp al,'>'
 je .measure_html_angle
 cmp al,'"'
 jne .measure_html_next
 add r11,5
 jmp .measure_html_next
.measure_html_amp:
 add r11,4
 jmp .measure_html_next
.measure_html_angle:
 add r11,3
.measure_html_next:
 inc rcx
 jmp .measure_html_loop

.text_preflight:
 cmp r11,FORMAT_MAX_OUTPUT
 ja .text_limit
 cmp r11,r15
 ja .text_capacity
 test r11,r11
 jz .text_success
 test r14,r14
 jz .text_invalid
 lea rax,[r14+r11]
 cmp rax,r14
 jb .text_invalid
 lea rdx,[r12+r13]
 cmp rdx,r12
 jb .text_invalid
 cmp r14,rdx
 jae .text_write
 cmp rax,r12
 ja .text_invalid
.text_write:
 cmp ebx,FORMAT_PROFILE_REDACT
 je .write_redact
 cmp ebx,FORMAT_PROFILE_HASH
 je .write_hash
 cmp ebx,FORMAT_PROFILE_TEXT
 je .write_copy
 cmp ebx,FORMAT_PROFILE_LITERAL
 je .write_copy
 cmp ebx,FORMAT_PROFILE_PLAIN
 je .write_copy
 cmp ebx,FORMAT_PROFILE_QUOTE
 je .write_quoted
 cmp ebx,FORMAT_PROFILE_JSON
 je .write_quoted
 cmp ebx,70
 je .write_json_escape
 cmp ebx,FORMAT_PROFILE_MARKDOWN
 je .write_markdown
 cmp ebx,FORMAT_PROFILE_HTML
 je .write_html
 jmp .write_ansi
.write_redact:
 lea rsi,[rel format_profile_redacted]
 mov ecx,format_profile_redacted_len
 mov rdi,r14
 rep movsb
 jmp .text_success
.write_hash:
 mov rax,0xcbf29ce484222325
 mov rdx,0x100000001b3
 xor ecx,ecx
.hash_loop:
 cmp rcx,r13
 jae .hash_render
 movzx rdi,byte [r12+rcx]
 xor rax,rdi
 imul rax,rdx
 inc rcx
 jmp .hash_loop
.hash_render:
 lea rsi,[rel format_profile_hex]
 mov ecx,16
 lea rdi,[r14+16]
.hash_digit:
 mov rdx,rax
 and edx,15
 mov dl,[rsi+rdx]
 dec rdi
 mov [rdi],dl
 shr rax,4
 dec ecx
 jnz .hash_digit
 jmp .text_success
.write_copy:
 mov rsi,r12
 mov rdi,r14
 mov rcx,r13
 rep movsb
 jmp .text_success
.write_quoted:
 mov byte [r14],'"'
 lea rdi,[r14+1]
 xor ecx,ecx
 jmp .write_json_loop
.write_json_escape:
 mov rdi,r14
 xor ecx,ecx
.write_json_loop:
 cmp rcx,r13
 jae .write_json_done
 mov al,[r12+rcx]
 cmp al,'"'
 je .write_json_slash
 cmp al,'\'
 je .write_json_slash
 cmp al,10
 jne .write_json_byte
 mov byte [rdi],'\'
 mov byte [rdi+1],'n'
 add rdi,2
 jmp .write_json_next
.write_json_slash:
 mov byte [rdi],'\'
 mov [rdi+1],al
 add rdi,2
 jmp .write_json_next
.write_json_byte:
 mov [rdi],al
 inc rdi
.write_json_next:
 inc rcx
 jmp .write_json_loop
.write_json_done:
 cmp ebx,70
 je .text_success
 mov byte [rdi],'"'
 jmp .text_success
.write_markdown:
 mov rdi,r14
 xor ecx,ecx
.write_markdown_loop:
 cmp rcx,r13
 jae .text_success
 mov al,[r12+rcx]
 cmp al,'*'
 je .write_markdown_slash
 cmp al,'_'
 je .write_markdown_slash
 cmp al,'['
 je .write_markdown_slash
 cmp al,']'
 je .write_markdown_slash
 cmp al,'#'
 je .write_markdown_slash
 cmp al,'\'
 jne .write_markdown_byte
.write_markdown_slash:
 mov byte [rdi],'\'
 inc rdi
.write_markdown_byte:
 mov [rdi],al
 inc rdi
 inc rcx
 jmp .write_markdown_loop
.write_ansi:
 mov rdi,r14
 xor ecx,ecx
.write_ansi_loop:
 cmp rcx,r13
 jae .text_success
 mov al,[r12+rcx]
 cmp al,27
 jne .write_ansi_byte
 mov byte [rdi],'\'
 mov byte [rdi+1],'e'
 add rdi,2
 jmp .write_ansi_next
.write_ansi_byte:
 mov [rdi],al
 inc rdi
.write_ansi_next:
 inc rcx
 jmp .write_ansi_loop
.write_html:
 mov rdi,r14
 xor ecx,ecx
.write_html_loop:
 cmp rcx,r13
 jae .text_success
 mov al,[r12+rcx]
 cmp al,'&'
 je .write_html_amp
 cmp al,'<'
 je .write_html_lt
 cmp al,'>'
 je .write_html_gt
 cmp al,'"'
 je .write_html_quote
 mov [rdi],al
 inc rdi
 jmp .write_html_next
.write_html_amp:
 lea rsi,[rel format_profile_html_amp]
 mov edx,5
 jmp .write_html_entity
.write_html_lt:
 lea rsi,[rel format_profile_html_lt]
 mov edx,4
 jmp .write_html_entity
.write_html_gt:
 lea rsi,[rel format_profile_html_gt]
 mov edx,4
 jmp .write_html_entity
.write_html_quote:
 lea rsi,[rel format_profile_html_quote]
 mov edx,6
.write_html_entity:
 push rcx
 mov rcx,rdx
 rep movsb
 pop rcx
.write_html_next:
 inc rcx
 jmp .write_html_loop

.text_success:
 mov rax,r11
 jmp .text_done
.text_invalid: mov rax,-FORMAT_E_INVALID
 jmp .text_done
.text_limit: mov rax,-FORMAT_E_LIMIT
 jmp .text_done
.text_capacity: mov rax,-FORMAT_E_CAPACITY
.text_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI FormatLayout request -> bytes or negative status. Width is a bounded
; byte/display-cell profile; multibyte truncation is rejected by the source
; profile until a later Unicode-width table is explicitly selected.
neboc_format_profile_layout:
 push rbx
 push r12
 push r13
 push r14
 push r15
 test rdi,rdi
 jz .layout_invalid
 mov rbx,rdi
 mov r12,[rbx+FORMAT_LAYOUT_DATA]
 mov r13,[rbx+FORMAT_LAYOUT_LENGTH]
 mov r14,[rbx+FORMAT_LAYOUT_OUTPUT]
 mov r15,[rbx+FORMAT_LAYOUT_CAPACITY]
 cmp r13,FORMAT_PROFILE_MAX_TEXT
 ja .layout_limit
 test r13,r13
 jz .layout_width
 test r12,r12
 jz .layout_invalid
.layout_width:
 mov r8,[rbx+FORMAT_LAYOUT_WIDTH]
 cmp r8,FORMAT_PROFILE_MAX_WIDTH
 ja .layout_limit
 mov rax,[rbx+FORMAT_LAYOUT_PROFILE]
 cmp rax,FORMAT_PROFILE_TRUNCATE
 je .layout_truncate
 cmp rax,FORMAT_PROFILE_ALIGN
 je .layout_pad
 cmp rax,FORMAT_PROFILE_PAD
 jne .layout_invalid
.layout_pad:
 movzx eax,byte [rbx+FORMAT_LAYOUT_FILL]
 test al,al
 jz .layout_invalid
 mov r9,r8
 cmp r9,r13
 jae .layout_pad_size
 mov r9,r13
.layout_pad_size:
 mov r10,r9
 sub r10,r13
 mov r11,[rbx+FORMAT_LAYOUT_SIDE]
 cmp r11,FORMAT_PROFILE_SIDE_CENTER
 ja .layout_invalid
 xor edx,edx
 cmp r11,FORMAT_PROFILE_SIDE_RIGHT
 je .layout_all_left
 cmp r11,FORMAT_PROFILE_SIDE_CENTER
 jne .layout_preflight
 mov rdx,r10
 shr rdx,1
 jmp .layout_preflight
.layout_all_left:
 mov rdx,r10
 jmp .layout_preflight
.layout_truncate:
 cmp r13,r8
 jbe .layout_no_truncate
 cmp r8,3
 jb .layout_invalid
 mov r9,r8
 jmp .layout_truncate_flag
.layout_no_truncate:
 mov r9,r13
.layout_truncate_flag:
 xor edx,edx
.layout_preflight:
 cmp r9,r15
 ja .layout_capacity
 test r9,r9
 jz .layout_success
 test r14,r14
 jz .layout_invalid
 lea rax,[r14+r9]
 cmp rax,r14
 jb .layout_invalid
 lea rcx,[r12+r13]
 cmp rcx,r12
 jb .layout_invalid
 cmp r14,rcx
 jae .layout_write
 cmp rax,r12
 ja .layout_invalid
.layout_write:
 cmp qword [rbx+FORMAT_LAYOUT_PROFILE],FORMAT_PROFILE_TRUNCATE
 je .layout_write_truncate
 movzx eax,byte [rbx+FORMAT_LAYOUT_FILL]
 mov rdi,r14
 mov rcx,rdx
 rep stosb
 mov rsi,r12
 mov rcx,r13
 rep movsb
 mov rcx,r10
 sub rcx,rdx
 movzx eax,byte [rbx+FORMAT_LAYOUT_FILL]
 rep stosb
 jmp .layout_success
.layout_write_truncate:
 cmp r13,r8
 jbe .layout_copy_all
 mov rcx,r8
 sub rcx,3
 mov rdi,r14
 mov rsi,r12
 rep movsb
 lea rsi,[rel format_profile_ellipsis]
 mov ecx,3
 rep movsb
 jmp .layout_success
.layout_copy_all:
 mov rdi,r14
 mov rsi,r12
 mov rcx,r13
 rep movsb
.layout_success:
 mov rax,r9
 jmp .layout_done
.layout_invalid: mov rax,-FORMAT_E_INVALID
 jmp .layout_done
.layout_limit: mov rax,-FORMAT_E_LIMIT
 jmp .layout_done
.layout_capacity: mov rax,-FORMAT_E_CAPACITY
.layout_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI signed value, ESI base 2..36, EDX flags(bit0 uppercase), RCX output,
; R8 capacity -> bytes or negative status.
neboc_format_int_to_base:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov r12,rdi
 mov r13d,esi
 mov ebx,edx
 mov r14,rcx
 mov r15,r8
 cmp r13d,2
 jb .base_invalid
 cmp r13d,36
 ja .base_invalid
 mov rax,r12
 xor r10d,r10d
 test rax,rax
 jns .base_magnitude
 mov r10d,1
 neg rax
.base_magnitude:
 lea r9,[rsp+79]
 xor ecx,ecx
 test rax,rax
 jnz .base_digits
 dec r9
 mov byte [r9],'0'
 mov ecx,1
 jmp .base_sign
.base_digits:
 xor edx,edx
 div r13
 test bl,1
 jz .base_lower
 lea rsi,[rel format_profile_hex_upper]
 jmp .base_digit
.base_lower:
 lea rsi,[rel format_profile_hex]
.base_digit:
 mov dl,[rsi+rdx]
 dec r9
 mov [r9],dl
 inc rcx
 test rax,rax
 jnz .base_digits
.base_sign:
 test r10d,r10d
 jz .base_preflight
 dec r9
 mov byte [r9],'-'
 inc rcx
.base_preflight:
 cmp rcx,r15
 ja .base_capacity
 test rcx,rcx
 jz .base_success
 test r14,r14
 jz .base_invalid
 mov rdi,r14
 mov rsi,r9
 mov r11,rcx
 rep movsb
 mov rcx,r11
.base_success:
 mov rax,rcx
 jmp .base_done
.base_invalid: mov rax,-FORMAT_E_INVALID
 jmp .base_done
.base_capacity: mov rax,-FORMAT_E_CAPACITY
.base_done:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

neboc_format_int_digit_count:
 mov rax,rdi
 test rax,rax
 jns .count_abs
 neg rax
.count_abs:
 mov ecx,1
 mov r8d,10
.count_loop:
 cmp rax,10
 jb .count_done
 xor edx,edx
 div r8
 inc ecx
 jmp .count_loop
.count_done:
 mov eax,ecx
 ret

neboc_format_int_sum_digits:
 mov rax,rdi
 test rax,rax
 jns .sum_abs
 neg rax
.sum_abs:
 xor ecx,ecx
 mov r8d,10
.sum_loop:
 xor edx,edx
 div r8
 add rcx,rdx
 test rax,rax
 jnz .sum_loop
 mov rax,rcx
 ret

; RDI signed input -> EAX status, RDX reversed signed value.
neboc_format_int_reverse_digits_checked:
 mov rax,rdi
 xor r8d,r8d
 test rax,rax
 jns .reverse_abs
 mov r8d,1
 neg rax
.reverse_abs:
 xor ecx,ecx
 mov r9d,10
.reverse_loop:
 xor edx,edx
 div r9
 imul rcx,rcx,10
 jo .reverse_overflow
 add rcx,rdx
 jo .reverse_overflow
 test rax,rax
 jnz .reverse_loop
 test r8d,r8d
 jz .reverse_ok
 neg rcx
 jo .reverse_overflow
.reverse_ok:
 mov rdx,rcx
 xor eax,eax
 ret
.reverse_overflow:
 xor edx,edx
 mov eax,FORMAT_E_LIMIT
 ret

; XMM0 value, EDI digits 0..6 -> rounded XMM0 and typed status EAX.
neboc_format_float_round_to:
 cmp edi,6
 ja .round_to_invalid
 movq rdx,xmm0
 and rdx,[rel format_profile_exp_mask]
 cmp rdx,[rel format_profile_exp_mask]
 je .round_to_domain
 movsxd rax,edi
 lea rdx,[rel format_profile_pow10]
 movsd xmm1,[rdx+rax*8]
 mulsd xmm0,xmm1
 ucomisd xmm0,xmm0
 jp .round_to_domain
 ucomisd xmm0,[rel format_profile_i64_pos_limit]
 jae .round_to_invalid
 ucomisd xmm0,[rel format_profile_i64_neg_limit]
 jb .round_to_invalid
 sub rsp,24
 movsd [rsp],xmm1
 call nebo_math_round_f64
 movsd xmm1,[rsp]
 add rsp,24
 test eax,eax
 jnz .round_to_return
 divsd xmm0,xmm1
.round_to_return:
 ret
.round_to_invalid:
 mov eax,FORMAT_E_LIMIT
 ret
.round_to_domain:
 mov eax,FORMAT_E_INVALID
 ret

; XMM0 value, EDI profile (floor/ceil/round/roundEven/trunc/fract).
neboc_format_float_unary:
 ucomisd xmm0,xmm0
 jp .float_unary_invalid
 ucomisd xmm0,[rel format_profile_i64_pos_limit]
 jae .float_unary_invalid
 ucomisd xmm0,[rel format_profile_i64_neg_limit]
 jb .float_unary_invalid
 cmp edi,FORMAT_PROFILE_FLOAT_FLOOR
 je nebo_math_floor_f64
 cmp edi,FORMAT_PROFILE_FLOAT_CEIL
 je nebo_math_ceil_f64
 cmp edi,FORMAT_PROFILE_FLOAT_ROUND
 je nebo_math_round_f64
 cmp edi,FORMAT_PROFILE_FLOAT_ROUND_EVEN
 je nebo_math_round_f64
 cmp edi,FORMAT_PROFILE_FLOAT_TRUNC
 je .float_trunc
 cmp edi,FORMAT_PROFILE_FLOAT_FRACT
 jne .float_unary_invalid
 movapd xmm1,xmm0
 cvttsd2si rax,xmm0
 cvtsi2sd xmm0,rax
 subsd xmm1,xmm0
 movapd xmm0,xmm1
 xor eax,eax
 ret
.float_trunc:
 cvttsd2si rax,xmm0
 cvtsi2sd xmm0,rax
 xor eax,eax
 ret
.float_unary_invalid:
 mov eax,FORMAT_E_INVALID
 ret

; XMM0 value, EDI toInt/truncToInt/roundToInt -> EAX status, RDX i64.
neboc_format_float_to_int_checked:
 push rbx
 mov ebx,edi
 ucomisd xmm0,[rel format_profile_i64_pos_limit]
 jae .float_int_invalid
 ucomisd xmm0,[rel format_profile_i64_neg_limit]
 jb .float_int_invalid
 cmp ebx,FORMAT_PROFILE_FLOAT_ROUND_INT
 jne .float_int_convert
 call nebo_math_round_f64
 test eax,eax
 jnz .float_int_done
.float_int_convert:
 cvttsd2si rdx,xmm0
 cmp ebx,FORMAT_PROFILE_FLOAT_TO_INT
 jne .float_int_ok
 cvtsi2sd xmm1,rdx
 ucomisd xmm0,xmm1
 jne .float_int_invalid
.float_int_ok:
 xor eax,eax
 jmp .float_int_done
.float_int_invalid:
 xor edx,edx
 mov eax,FORMAT_E_INVALID
.float_int_done:
 pop rbx
 ret

; XMM0 value -> EAX classification flags.
neboc_format_float_classify:
 jmp nebo_float_classify_f64

; XMM0 value, XMM1 reference, XMM2 tolerance, EDI comparison/error profile.
; Comparison profiles return Bool in EDX; error profiles return value in XMM0.
neboc_format_float_compare:
 cmp edi,FORMAT_PROFILE_FLOAT_APPROX
 je .compare_absolute
 cmp edi,FORMAT_PROFILE_FLOAT_REL_APPROX
 je .compare_relative
 cmp edi,FORMAT_PROFILE_FLOAT_CMP_APPROX
 je .compare_relative
 cmp edi,FORMAT_PROFILE_FLOAT_ABS_ERROR
 je .error_absolute
 cmp edi,FORMAT_PROFILE_FLOAT_REL_ERROR
 je .error_relative
 cmp edi,FORMAT_PROFILE_FLOAT_PCT_ERROR
 jne .compare_invalid
.error_relative:
 sub rsp,8
 call .errors_finite
 add rsp,8
 test eax,eax
 jnz .compare_invalid
 mov r8d,edi
 movapd xmm3,xmm1
 movq rax,xmm3
 and rax,[rel format_profile_abs_mask]
 movq xmm3,rax
 ucomisd xmm3,[rel format_profile_zero]
 je .compare_invalid
 movapd xmm4,xmm0
 subsd xmm4,xmm1
 movq rax,xmm4
 and rax,[rel format_profile_abs_mask]
 movq xmm0,rax
 divsd xmm0,xmm3
 cmp r8d,FORMAT_PROFILE_FLOAT_PCT_ERROR
 jne .compare_ok
 mulsd xmm0,[rel format_profile_hundred]
.compare_ok:
 xor eax,eax
 ret
.error_absolute:
 sub rsp,8
 call .errors_finite
 add rsp,8
 test eax,eax
 jnz .compare_invalid
 subsd xmm0,xmm1
 movq rax,xmm0
 and rax,[rel format_profile_abs_mask]
 movq xmm0,rax
 xor eax,eax
 ret
.compare_absolute:
 pxor xmm3,xmm3
 jmp .compare_call
.compare_relative:
 movapd xmm3,xmm2
 pxor xmm2,xmm2
.compare_call:
 sub rsp,8
 call nebo_float_approx_equal_f64
 add rsp,8
 ret
.compare_invalid:
 xor edx,edx
 mov eax,FORMAT_E_INVALID
 ret
.errors_finite:
 movq rax,xmm0
 and rax,[rel format_profile_exp_mask]
 cmp rax,[rel format_profile_exp_mask]
 je .errors_bad
 movq rax,xmm1
 and rax,[rel format_profile_exp_mask]
 cmp rax,[rel format_profile_exp_mask]
 je .errors_bad
 xor eax,eax
 ret
.errors_bad:
 mov eax,FORMAT_E_INVALID
 ret

; XMM0 nonnegative finite value, EDI digits 0..6, RSI out, RDX cap.
neboc_format_float_fixed:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,96
 mov ebx,edi
 mov r12,rsi
 mov r13,rdx
 mov qword [rsp+72],0
 cmp ebx,6
 ja .fixed_limit
 movq rax,xmm0
 mov rdx,rax
 and rdx,[rel format_profile_exp_mask]
 cmp rdx,[rel format_profile_exp_mask]
 je .fixed_invalid
 test rax,rax
 jns .fixed_nonnegative
 and rax,[rel format_profile_abs_mask]
 movq xmm0,rax
 mov qword [rsp+72],1
.fixed_nonnegative:
 movsxd rax,ebx
 lea rdx,[rel format_profile_pow10]
 movsd xmm1,[rdx+rax*8]
 mulsd xmm0,xmm1
 movsd [rsp+80],xmm1
 call nebo_math_round_f64
 test eax,eax
 jnz .fixed_invalid
 ucomisd xmm0,[rel format_profile_i64_pos_limit]
 jae .fixed_limit
 cvttsd2si rdi,xmm0
 mov esi,10
 xor edx,edx
 lea rcx,[rsp]
 mov r8d,64
 call neboc_format_int_to_base
 test rax,rax
 js .fixed_return
 mov r14,rax
 test ebx,ebx
 jz .fixed_integer
 cmp r14,rbx
 jbe .fixed_leading_zero
 lea r15,[r14+1]
 mov rax,r15
 add rax,[rsp+72]
 cmp rax,r13
 ja .fixed_capacity
 test r12,r12
 jz .fixed_invalid
 mov rdi,r12
 cmp qword [rsp+72],0
 je .fixed_decimal_unsigned
 mov byte [rdi],'-'
 inc rdi
.fixed_decimal_unsigned:
 mov rcx,r14
 sub rcx,rbx
 lea rsi,[rsp]
 rep movsb
 mov byte [rdi],'.'
 inc rdi
 mov rcx,rbx
 rep movsb
 mov rax,r15
 add rax,[rsp+72]
 jmp .fixed_return
.fixed_leading_zero:
 lea r15,[rbx+2]
 mov rax,r15
 add rax,[rsp+72]
 cmp rax,r13
 ja .fixed_capacity
 test r12,r12
 jz .fixed_invalid
 mov rdi,r12
 cmp qword [rsp+72],0
 je .fixed_leading_unsigned
 mov byte [rdi],'-'
 inc rdi
.fixed_leading_unsigned:
 mov byte [rdi],'0'
 mov byte [rdi+1],'.'
 add rdi,2
 mov rcx,rbx
 sub rcx,r14
 mov al,'0'
 rep stosb
 lea rsi,[rsp]
 mov rcx,r14
 rep movsb
 mov rax,r15
 add rax,[rsp+72]
 jmp .fixed_return
.fixed_integer:
 mov rax,r14
 add rax,[rsp+72]
 cmp rax,r13
 ja .fixed_capacity
 test r14,r14
 jz .fixed_success_integer
 test r12,r12
 jz .fixed_invalid
 mov rdi,r12
 cmp qword [rsp+72],0
 je .fixed_integer_unsigned
 mov byte [rdi],'-'
 inc rdi
.fixed_integer_unsigned:
 lea rsi,[rsp]
 mov rcx,r14
 rep movsb
.fixed_success_integer:
 mov rax,r14
 add rax,[rsp+72]
 jmp .fixed_return
.fixed_invalid: mov rax,-FORMAT_E_INVALID
 jmp .fixed_return
.fixed_limit: mov rax,-FORMAT_E_LIMIT
 jmp .fixed_return
.fixed_capacity: mov rax,-FORMAT_E_CAPACITY
.fixed_return:
 add rsp,96
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Bounded finite scientific notation, including signed zero: mantissa e±NN.
neboc_format_float_scientific:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,96
 mov ebx,edi
 mov r12,rsi
 mov r13,rdx
 mov qword [rsp+80],0
 cmp ebx,6
 ja .sci_limit
 movq rax,xmm0
 mov rdx,rax
 and rdx,[rel format_profile_exp_mask]
 cmp rdx,[rel format_profile_exp_mask]
 je .sci_invalid
 test rax,rax
 jns .sci_nonnegative
 and rax,[rel format_profile_abs_mask]
 movq xmm0,rax
 mov qword [rsp+80],1
.sci_nonnegative:
 xor r14d,r14d
 ucomisd xmm0,[rel format_profile_zero]
 je .sci_mantissa
 movsd xmm1,[rel format_profile_pow10+8]
.sci_high:
 ucomisd xmm0,xmm1
 jb .sci_low
 divsd xmm0,xmm1
 inc r14d
 cmp r14d,99
 ja .sci_limit
 jmp .sci_high
.sci_low:
 movsd xmm2,[rel format_profile_pow10]
 ucomisd xmm0,xmm2
 jae .sci_mantissa
 mulsd xmm0,xmm1
 dec r14d
 cmp r14d,-99
 jl .sci_limit
 jmp .sci_low
.sci_mantissa:
 mov edi,ebx
 lea rsi,[rsp]
 mov edx,64
 call neboc_format_float_fixed
 test rax,rax
 js .sci_return
 mov r15,rax
 ; Rounding a mantissa just below ten may carry into the exponent. Normalize
 ; the already-rounded private bytes; never evaluate or round the input twice.
 cmp r15,2
 jb .sci_normalized
 cmp byte [rsp],'1'
 jne .sci_normalized
 cmp byte [rsp+1],'0'
 jne .sci_normalized
 inc r14d
 cmp r14d,99
 jg .sci_limit
 mov ecx,2
.sci_carry_shift:
 cmp rcx,r15
 jae .sci_carry_done
 mov dl,[rsp+rcx]
 mov [rsp+rcx-1],dl
 inc rcx
 jmp .sci_carry_shift
.sci_carry_done:
 dec r15
.sci_normalized:
 lea rcx,[r15+4]
 add rcx,[rsp+80]
 cmp rcx,r13
 ja .sci_capacity
 test r12,r12
 jz .sci_invalid
 mov rdi,r12
 cmp qword [rsp+80],0
 je .sci_unsigned
 mov byte [rdi],'-'
 inc rdi
.sci_unsigned:
 lea rsi,[rsp]
 mov rcx,r15
 rep movsb
 mov byte [rdi],'e'
 mov eax,r14d
 test eax,eax
 js .sci_negative
 mov byte [rdi+1],'+'
 jmp .sci_exp
.sci_negative:
 mov byte [rdi+1],'-'
 neg eax
.sci_exp:
 xor edx,edx
 mov ecx,10
 div ecx
 add al,'0'
 add dl,'0'
 mov [rdi+2],al
 mov [rdi+3],dl
 lea rax,[r15+4]
 add rax,[rsp+80]
 jmp .sci_return
.sci_invalid: mov rax,-FORMAT_E_INVALID
 jmp .sci_return
.sci_limit: mov rax,-FORMAT_E_LIMIT
 jmp .sci_return
.sci_capacity: mov rax,-FORMAT_E_CAPACITY
.sci_return:
 add rsp,96
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; EDI percent/number/currency/bytes/speed profile, RSI integer value,
; RDX output, RCX capacity, R8 explicit policy.
neboc_format_number_profile:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov ebx,edi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 cmp ebx,FORMAT_PROFILE_PERCENT
 je .number_root_policy
 cmp ebx,FORMAT_PROFILE_NUMBER
 jne .number_currency_policy
.number_root_policy:
 cmp r15,FORMAT_PROFILE_POLICY_ROOT
 jne .number_invalid
 jmp .number_policy_done
.number_currency_policy:
 cmp ebx,FORMAT_PROFILE_CURRENCY
 jne .number_unit_policy
 cmp r15,FORMAT_PROFILE_POLICY_EUR
 jne .number_invalid
 jmp .number_policy_done
.number_unit_policy:
 cmp ebx,FORMAT_PROFILE_BYTES
 je .number_require_iec
 cmp ebx,FORMAT_PROFILE_SPEED
 jne .number_invalid
.number_require_iec:
 cmp r15,FORMAT_PROFILE_POLICY_IEC
 jne .number_invalid
.number_policy_done:
 cmp ebx,FORMAT_PROFILE_BYTES
 je .number_div_kib
 cmp ebx,FORMAT_PROFILE_SPEED
 jne .number_convert
.number_div_kib:
 test r12,r12
 js .number_invalid
 mov rax,r12
 xor edx,edx
 mov ecx,1024
 div rcx
 mov r12,rax
.number_convert:
 mov rdi,r12
 mov esi,10
 xor edx,edx
 lea rcx,[rsp]
 mov r8d,64
 call neboc_format_int_to_base
 test rax,rax
 js .number_return
 mov r9,rax
 mov r10,r9
 cmp ebx,FORMAT_PROFILE_PERCENT
 jne .number_not_percent
 inc r10
 jmp .number_preflight
.number_not_percent:
 cmp ebx,FORMAT_PROFILE_CURRENCY
 jne .number_not_currency
 add r10,4
 jmp .number_preflight
.number_not_currency:
 cmp ebx,FORMAT_PROFILE_BYTES
 jne .number_not_bytes
 add r10,4
 jmp .number_preflight
.number_not_bytes:
 cmp ebx,FORMAT_PROFILE_SPEED
 jne .number_plain
 add r10,6
 jmp .number_preflight
.number_plain:
 cmp ebx,FORMAT_PROFILE_NUMBER
 jne .number_invalid
.number_preflight:
 cmp r10,r14
 ja .number_capacity
 test r13,r13
 jz .number_invalid
 mov rdi,r13
 cmp ebx,FORMAT_PROFILE_CURRENCY
 jne .number_digits
 lea rsi,[rel format_profile_eur]
 mov ecx,4
 rep movsb
.number_digits:
 lea rsi,[rsp]
 mov rcx,r9
 rep movsb
 cmp ebx,FORMAT_PROFILE_PERCENT
 jne .number_suffix
 mov byte [rdi],'%'
 jmp .number_success
.number_suffix:
 cmp ebx,FORMAT_PROFILE_BYTES
 jne .number_speed
 lea rsi,[rel format_profile_kib]
 mov ecx,4
 rep movsb
 jmp .number_success
.number_speed:
 cmp ebx,FORMAT_PROFILE_SPEED
 jne .number_success
 lea rsi,[rel format_profile_kib_s]
 mov ecx,6
 rep movsb
.number_success:
 mov rax,r10
 jmp .number_return
.number_invalid: mov rax,-FORMAT_E_INVALID
 jmp .number_return
.number_capacity: mov rax,-FORMAT_E_CAPACITY
.number_return:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; EDI temporal profile, RSI Temporal record, RDX out, RCX cap.
neboc_format_temporal_profile:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov ebx,edi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 test r12,r12
 jz .temporal_invalid
 mov rax,[r12+FORMAT_TEMPORAL_MONTH]
 cmp rax,1
 jb .temporal_invalid
 cmp rax,12
 ja .temporal_invalid
 mov rax,[r12+FORMAT_TEMPORAL_DAY]
 cmp rax,1
 jb .temporal_invalid
 cmp rax,31
 ja .temporal_invalid
 mov r8,[r12+FORMAT_TEMPORAL_MONTH]
 mov r9,[r12+FORMAT_TEMPORAL_DAY]
 cmp r8,2
 je .temporal_february
 cmp r8,4
 je .temporal_thirty_day
 cmp r8,6
 je .temporal_thirty_day
 cmp r8,9
 je .temporal_thirty_day
 cmp r8,11
 jne .temporal_calendar_ok
.temporal_thirty_day:
 cmp r9,30
 ja .temporal_invalid
 jmp .temporal_calendar_ok
.temporal_february:
 mov rax,[r12+FORMAT_TEMPORAL_YEAR]
 xor edx,edx
 mov ecx,4
 div rcx
 test rdx,rdx
 jnz .temporal_february_common
 mov rax,[r12+FORMAT_TEMPORAL_YEAR]
 xor edx,edx
 mov ecx,100
 div rcx
 test rdx,rdx
 jnz .temporal_february_leap
 mov rax,[r12+FORMAT_TEMPORAL_YEAR]
 xor edx,edx
 mov ecx,400
 div rcx
 test rdx,rdx
 jz .temporal_february_leap
.temporal_february_common:
 cmp r9,28
 ja .temporal_invalid
 jmp .temporal_calendar_ok
.temporal_february_leap:
 cmp r9,29
 ja .temporal_invalid
.temporal_calendar_ok:
 mov rax,[r12+FORMAT_TEMPORAL_HOUR]
 cmp rax,23
 ja .temporal_invalid
 mov rax,[r12+FORMAT_TEMPORAL_MINUTE]
 cmp rax,59
 ja .temporal_invalid
 mov rax,[r12+FORMAT_TEMPORAL_SECOND]
 cmp rax,59
 ja .temporal_invalid
 cmp ebx,FORMAT_PROFILE_DATE
 je .temporal_date
 cmp ebx,FORMAT_PROFILE_TIME
 je .temporal_time
 cmp ebx,FORMAT_PROFILE_DATETIME
 je .temporal_datetime
 cmp ebx,FORMAT_PROFILE_DURATION
 jne .temporal_invalid
 mov rdi,[r12+FORMAT_TEMPORAL_DURATION_SECONDS]
 test rdi,rdi
 js .temporal_invalid
 mov esi,10
 xor edx,edx
 lea rcx,[rsp]
 mov r8d,64
 call neboc_format_int_to_base
 test rax,rax
 js .temporal_return
 lea r15,[rax+3]
 cmp r15,r14
 ja .temporal_capacity
 test r13,r13
 jz .temporal_invalid
 mov byte [r13],'P'
 mov byte [r13+1],'T'
 lea rdi,[r13+2]
 lea rsi,[rsp]
 mov rcx,rax
 rep movsb
 mov byte [rdi],'S'
 mov rax,r15
 jmp .temporal_return
.temporal_date: mov r15d,10
 jmp .temporal_preflight
.temporal_time: mov r15d,8
 jmp .temporal_preflight
.temporal_datetime: mov r15d,19
.temporal_preflight:
 cmp r15,r14
 ja .temporal_capacity
 test r13,r13
 jz .temporal_invalid
 cmp ebx,FORMAT_PROFILE_TIME
 je .temporal_write_time
 mov rax,[r12+FORMAT_TEMPORAL_YEAR]
 cmp rax,9999
 ja .temporal_invalid
 mov rdi,r13
 mov ecx,1000
 xor edx,edx
 div rcx
 add al,'0'
 mov [rdi],al
 mov rax,rdx
 mov ecx,100
 xor edx,edx
 div rcx
 add al,'0'
 mov [rdi+1],al
 mov rax,rdx
 mov ecx,10
 xor edx,edx
 div rcx
 add al,'0'
 add dl,'0'
 mov [rdi+2],al
 mov [rdi+3],dl
 mov byte [rdi+4],'-'
 mov rax,[r12+FORMAT_TEMPORAL_MONTH]
 call .write_two_at_5
 mov byte [rdi+7],'-'
 mov rax,[r12+FORMAT_TEMPORAL_DAY]
 call .write_two_at_8
 cmp ebx,FORMAT_PROFILE_DATE
 je .temporal_success
 mov byte [rdi+10],'T'
 lea rdi,[rdi+11]
 jmp .temporal_write_time_common
.temporal_write_time:
 mov rdi,r13
.temporal_write_time_common:
 mov rax,[r12+FORMAT_TEMPORAL_HOUR]
 call .write_two_at_0
 mov byte [rdi+2],':'
 mov rax,[r12+FORMAT_TEMPORAL_MINUTE]
 call .write_two_at_3
 mov byte [rdi+5],':'
 mov rax,[r12+FORMAT_TEMPORAL_SECOND]
 call .write_two_at_6
.temporal_success:
 mov rax,r15
 jmp .temporal_return
.write_two_at_0:
 xor edx,edx
 mov ecx,10
 div rcx
 add al,'0'
 add dl,'0'
 mov [rdi],al
 mov [rdi+1],dl
 ret
.write_two_at_3:
 xor edx,edx
 mov ecx,10
 div rcx
 add al,'0'
 add dl,'0'
 mov [rdi+3],al
 mov [rdi+4],dl
 ret
.write_two_at_5:
 xor edx,edx
 mov ecx,10
 div rcx
 add al,'0'
 add dl,'0'
 mov [rdi+5],al
 mov [rdi+6],dl
 ret
.write_two_at_6:
 xor edx,edx
 mov ecx,10
 div rcx
 add al,'0'
 add dl,'0'
 mov [rdi+6],al
 mov [rdi+7],dl
 ret
.write_two_at_8:
 xor edx,edx
 mov ecx,10
 div rcx
 add al,'0'
 add dl,'0'
 mov [rdi+8],al
 mov [rdi+9],dl
 ret
.temporal_invalid: mov rax,-FORMAT_E_INVALID
 jmp .temporal_return
.temporal_capacity: mov rax,-FORMAT_E_CAPACITY
.temporal_return:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI Structural request -> bytes or negative status.
neboc_format_structural_profile:
 push rbx
 push r12
 push r13
 push r14
 push r15
 test rdi,rdi
 jz .struct_invalid
 mov rbx,rdi
 mov r12,[rbx+FORMAT_STRUCTURAL_TYPE]
 mov r13,[rbx+FORMAT_STRUCTURAL_TYPE_LENGTH]
 mov r14,[rbx+FORMAT_STRUCTURAL_VALUE]
 mov r15,[rbx+FORMAT_STRUCTURAL_VALUE_LENGTH]
 cmp r13,FORMAT_PROFILE_MAX_TEXT
 ja .struct_limit
 cmp r15,FORMAT_PROFILE_MAX_TEXT
 ja .struct_limit
 cmp qword [rbx+FORMAT_STRUCTURAL_DEPTH],FORMAT_PROFILE_MAX_DEPTH
 ja .struct_limit
 test r13,r13
 jz .struct_invalid
 test r12,r12
 jz .struct_invalid
 test r15,r15
 jz .struct_value_ok
 test r14,r14
 jz .struct_invalid
.struct_value_ok:
 mov r8,[rbx+FORMAT_STRUCTURAL_PROFILE]
 cmp r8,FORMAT_PROFILE_TYPE
 je .struct_type
 cmp r8,FORMAT_PROFILE_INSPECT
 je .struct_inspect
 cmp r8,FORMAT_PROFILE_STRUCTURAL
 jne .struct_invalid
 mov r9,r13
 add r9,r15
 jc .struct_limit
 add r9,3
 jc .struct_limit
 mov r10d,'{'
 mov r11d,':'
 mov edx,'}'
 jmp .struct_preflight
.struct_inspect:
 mov r9,r13
 add r9,r15
 jc .struct_limit
 add r9,3
 jc .struct_limit
 mov r10d,'<'
 mov r11d,' '
 mov edx,'>'
 jmp .struct_preflight
.struct_type:
 mov r9,r13
.struct_preflight:
 cmp r9,[rbx+FORMAT_STRUCTURAL_CAPACITY]
 ja .struct_capacity
 mov rdi,[rbx+FORMAT_STRUCTURAL_OUTPUT]
 test rdi,rdi
 jz .struct_invalid
 cmp r8,FORMAT_PROFILE_TYPE
 je .struct_copy_type
 mov [rdi],r10b
 inc rdi
.struct_copy_type:
 mov rsi,r12
 mov rcx,r13
 rep movsb
 cmp r8,FORMAT_PROFILE_TYPE
 je .struct_success
 mov [rdi],r11b
 inc rdi
 mov rsi,r14
 mov rcx,r15
 rep movsb
 mov [rdi],dl
.struct_success:
 mov rax,r9
 jmp .struct_done
.struct_invalid: mov rax,-FORMAT_E_INVALID
 jmp .struct_done
.struct_limit: mov rax,-FORMAT_E_LIMIT
 jmp .struct_done
.struct_capacity: mov rax,-FORMAT_E_CAPACITY
.struct_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
