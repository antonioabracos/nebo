; Source-to-effect oracle for G071 render security, locale and fallback policy.
bits 64
default rel
%define NEBO_G071_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/render_security_source_probe.inc"
%include "runtime/textual/render_console.inc"

section .rodata
g71_s1: db 'security private=secret sink=log action=redact mask=last4 hash=sha256 truncate=24 no-log=yes'
g71_s1_len equ $-g71_s1
g71_s2: db 'escape html=&lt;&amp;&quot;&gt; json=quote-backslash ansi=removed raw=explicit safe-html=typed'
g71_s2_len equ $-g71_s2
g71_s3: db 'locale id=pt-PT decimal=, thousands=. currency=EUR plural=itens timezone=UTC host-locale=unused'
g71_s3_len equ $-g71_s3
g71_s4: db 'accessibility screen-reader=compilacao color=off contrast=high symbols=off text-only=yes ascii=available'
g71_s4_len equ $-g71_s4
g71_s5: db 'fallback requested=ansi supported=plain selected=plain strict=target-error detection=explicit'
g71_s5_len equ $-g71_s5
g71_s6: db 'terminal color=off width=80 unicode=off ascii-fallback=yes capability-source=argument'
g71_s6_len equ $-g71_s6
g71_s7: db 'privacy class=sensitive transform=preserved sink=headless redaction=required audit=pass'
g71_s7_len equ $-g71_s7
g71_s8: db 'security-conformance:70/70 classified public=66 deferred=4 sinks=4 locales=2 deterministic=yes'
g71_s8_len equ $-g71_s8
g71_escape_input: db '<','&','"', '>'
g71_escape_input_len equ $-g71_escape_input
g71_escape_expected: db '&','l','t',';','&','a','m','p',';','&','q','u','o','t',';','&','g','t',';'
g71_escape_expected_len equ $-g71_escape_expected

section .data align=16
g71_nodes_1: dq RENDER_NODE_POLICY,RENDER_FLAG_FALLBACK,g71_s1,g71_s1_len,RENDER_POLICY_SECURITY,4
g71_nodes_2: dq RENDER_NODE_POLICY,RENDER_FLAG_FALLBACK,g71_s2,g71_s2_len,RENDER_POLICY_ESCAPE,RENDER_SINK_HTML
g71_nodes_3: dq RENDER_NODE_POLICY,RENDER_FLAG_FALLBACK,g71_s3,g71_s3_len,RENDER_POLICY_LOCALE,RENDER_LOCALE_PT_PT
g71_nodes_4: dq RENDER_NODE_POLICY,RENDER_FLAG_FALLBACK,g71_s4,g71_s4_len,RENDER_POLICY_ACCESSIBILITY,RENDER_ACCESS_TEXT|RENDER_ACCESS_HIGH_CONTRAST
g71_nodes_5: dq RENDER_NODE_POLICY,RENDER_FLAG_FALLBACK,g71_s5,g71_s5_len,RENDER_POLICY_FALLBACK,RENDER_TARGET_PLAIN
g71_nodes_6: dq RENDER_NODE_POLICY,RENDER_FLAG_FALLBACK,g71_s6,g71_s6_len,RENDER_POLICY_TERMINAL,RENDER_TERMINAL_WIDE
g71_nodes_7: dq RENDER_NODE_POLICY,RENDER_FLAG_FALLBACK,g71_s7,g71_s7_len,RENDER_POLICY_PRIVACY,RENDER_PRIVACY_SENSITIVE
g71_nodes_8: dq RENDER_NODE_POLICY,RENDER_FLAG_FALLBACK,g71_s8,g71_s8_len,RENDER_POLICY_CONFORMANCE,0
g71_bad_token: dq RENDER_NODE_POLICY,RENDER_FLAG_FALLBACK,g71_s1,g71_s1_len,99,0
g71_bad_flags: dq RENDER_NODE_POLICY,0,g71_s1,g71_s1_len,RENDER_POLICY_SECURITY,4
g71_bad_meta: dq RENDER_NODE_POLICY,RENDER_FLAG_FALLBACK,g71_s2,g71_s2_len,RENDER_POLICY_ESCAPE,99

section .bss align=16
g71_output_a: resb 2048
g71_output_b: resb 2048
g71_atomic: resb 2048
g71_escape_out: resb 128

section .text
extern neboc_render_feature_validate
extern neboc_render_plan_validate
extern neboc_render_plan_measure
extern neboc_render_plan_write
extern neboc_render_policy_token_validate
global nebo_g071_source_probe
global nebo_g071_negative_probe
global nebo_g071_render_transcript
global nebo_g071_escape_sink
global nebo_g071_locale_profile
global nebo_g071_select_profile
global nebo_g071_privacy_authorize

; EDI locale -> EAX packed thousands:decimal bytes or typed negative error.
nebo_g071_locale_profile:
 cmp edi,RENDER_LOCALE_EN_US
 je .en
 cmp edi,RENDER_LOCALE_PT_PT
 je .pt
 mov eax,-RENDER_E_INVALID
 ret
.en: mov eax,0x2c2e
 ret
.pt: mov eax,0x2e2c
 ret

; EDI requested profile bits, ESI supported bits, EDX strict.
; EAX selected profile or negative typed status.
nebo_g071_select_profile:
 test edi,edi
 jz .invalid
 mov eax,edi
 and eax,G071_PROFILE_MAX
 cmp eax,edi
 jne .invalid
 mov ecx,esi
 and ecx,G071_PROFILE_MAX
 and ecx,eax
 cmp ecx,eax
 je .selected
 test edx,edx
 jnz .target
 test ecx,ecx
 jnz .selected
 mov ecx,G071_PROFILE_TEXT
.selected:
 mov eax,ecx
 ret
.invalid: mov eax,-RENDER_E_INVALID
 ret
.target: mov eax,-RENDER_E_TARGET
 ret

; EDI privacy class, ESI target, EDX policy flags -> EAX typed status.
nebo_g071_privacy_authorize:
 cmp edi,RENDER_PRIVACY_PUBLIC
 jb .invalid
 cmp edi,RENDER_PRIVACY_MAX
 ja .invalid
 cmp esi,RENDER_TARGET_PLAIN
 jb .target
 cmp esi,RENDER_TARGET_HEADLESS
 ja .target
 cmp edi,RENDER_PRIVACY_PUBLIC
 je .ok
 test edx,RENDER_FLAG_REDACT
 jz .privacy
.ok: xor eax,eax
 ret
.invalid: mov eax,RENDER_E_INVALID
 ret
.target: mov eax,RENDER_E_TARGET
 ret
.privacy: mov eax,RENDER_E_PRIVACY
 ret

; RDI input, RSI bytes, EDX sink, RCX output, R8 capacity.
; RAX committed bytes or a negative typed error. Output is untouched on error.
nebo_g071_escape_sink:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov ebx,edx
 mov r14,rcx
 mov r15,r8
 test r13,r13
 jz .zero
 test r12,r12
 jz .invalid
 cmp r13,RENDER_MAX_PAYLOAD
 ja .limit
 cmp ebx,RENDER_SINK_HTML
 jb .invalid
 cmp ebx,RENDER_SINK_MAX
 ja .invalid
 xor r9d,r9d
 xor r10d,r10d
 cmp ebx,RENDER_SINK_QUOTED
 jne .measure
 add r9,2
.measure:
 cmp r10,r13
 jae .measured
 movzx eax,byte [r12+r10]
 cmp ebx,RENDER_SINK_HTML
 je .measure_html
 cmp ebx,RENDER_SINK_JSON
 je .measure_json
 cmp ebx,RENDER_SINK_ANSI_SAFE
 je .measure_ansi
 cmp al,'"'
 je .measure_two
 cmp al,92
 je .measure_two
 inc r9
 jmp .measure_next
.measure_html:
 cmp al,'&'
 je .measure_five
 cmp al,'<'
 je .measure_four
 cmp al,'>'
 je .measure_four
 cmp al,'"'
 je .measure_six
 inc r9
 jmp .measure_next
.measure_json:
 cmp al,32
 jb .invalid
 cmp al,'"'
 je .measure_two
 cmp al,92
 je .measure_two
 inc r9
 jmp .measure_next
.measure_ansi:
 cmp al,27
 je .measure_next
 inc r9
 jmp .measure_next
.measure_two: add r9,2
 jmp .measure_next
.measure_four: add r9,4
 jmp .measure_next
.measure_five: add r9,5
 jmp .measure_next
.measure_six: add r9,6
.measure_next:
 cmp r9,RENDER_MAX_OUTPUT
 ja .limit
 inc r10
 jmp .measure
.measured:
 cmp r9,r15
 ja .capacity
 test r9,r9
 jz .zero
 test r14,r14
 jz .invalid
 xor r10d,r10d
 mov r11,r14
 cmp ebx,RENDER_SINK_QUOTED
 jne .write
 mov byte [r11],'"'
 inc r11
.write:
 cmp r10,r13
 jae .written
 mov al,[r12+r10]
 cmp ebx,RENDER_SINK_HTML
 je .write_html
 cmp ebx,RENDER_SINK_JSON
 je .write_json
 cmp ebx,RENDER_SINK_ANSI_SAFE
 je .write_ansi
 cmp al,'"'
 je .write_slash
 cmp al,92
 je .write_slash
 mov [r11],al
 inc r11
 jmp .write_next
.write_html:
 cmp al,'&'
 je .write_amp
 cmp al,'<'
 je .write_lt
 cmp al,'>'
 je .write_gt
 cmp al,'"'
 je .write_quot
 mov [r11],al
 inc r11
 jmp .write_next
.write_json:
 cmp al,'"'
 je .write_slash
 cmp al,92
 je .write_slash
 mov [r11],al
 inc r11
 jmp .write_next
.write_ansi:
 cmp al,27
 je .write_next
 mov [r11],al
 inc r11
 jmp .write_next
.write_slash:
 mov byte [r11],92
 mov [r11+1],al
 add r11,2
 jmp .write_next
.write_amp:
 mov dword [r11],0x706d6126
 mov byte [r11+4],';'
 add r11,5
 jmp .write_next
.write_lt:
 mov dword [r11],0x3b746c26
 add r11,4
 jmp .write_next
.write_gt:
 mov dword [r11],0x3b746726
 add r11,4
 jmp .write_next
.write_quot:
 mov dword [r11],0x6f757126
 mov word [r11+4],0x3b74
 add r11,6
.write_next:
 inc r10
 jmp .write
.written:
 cmp ebx,RENDER_SINK_QUOTED
 jne .success
 mov byte [r11],'"'
.success:
 mov rax,r9
 jmp .done
.zero: xor eax,eax
 jmp .done
.invalid: mov rax,-RENDER_E_INVALID
 jmp .done
.limit: mov rax,-RENDER_E_LIMIT
 jmp .done
.capacity: mov rax,-RENDER_E_CAPACITY
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI nodes, RSI count, EDX target, RCX expected, R8 expected length.
g71_run_plan:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14d,edx
 mov r15,rcx
 mov rbx,r8
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 call neboc_render_plan_validate
 test eax,eax
 jnz .fail
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 call neboc_render_plan_measure
 cmp rax,rbx
 jne .fail
 lea rdi,[rel g71_output_a]
 mov ecx,2048
 mov al,0xa5
 rep stosb
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 lea rcx,[rel g71_output_a]
 mov r8d,2048
 call neboc_render_plan_write
 cmp rax,rbx
 jne .fail
 lea rsi,[rel g71_output_a]
 mov rdi,r15
 mov rcx,rbx
 repe cmpsb
 jne .fail
 lea rdi,[rel g71_output_b]
 mov ecx,2048
 mov al,0x5a
 rep stosb
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 lea rcx,[rel g71_output_b]
 mov r8d,2048
 call neboc_render_plan_write
 cmp rax,rbx
 jne .fail
 lea rsi,[rel g71_output_a]
 lea rdi,[rel g71_output_b]
 mov rcx,rbx
 repe cmpsb
 jne .fail
 lea rdi,[rel g71_atomic]
 mov ecx,2048
 mov al,0xcc
 rep stosb
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 lea rcx,[rel g71_atomic]
 lea r8,[rbx-1]
 call neboc_render_plan_write
 cmp rax,-RENDER_E_CAPACITY
 jne .fail
 cmp byte [rel g71_atomic],0xcc
 jne .fail
 xor eax,eax
 jmp .done
.fail: mov eax,1
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

%macro G71_RUN 5
 lea rdi,[rel %1]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 lea rcx,[rel %2]
 mov r8d,%3
 call g71_run_plan
 test eax,eax
 jnz .return
 mov edi,%4
 mov esi,%5
 mov edx,RENDER_FLAG_FALLBACK
 call neboc_render_policy_token_validate
 test eax,eax
 jnz .return
%endmacro

nebo_g071_source_probe:
 push rbx
 push r12
 mov ebx,esi
 mov r12d,edi
 lea edi,[r12d+7100]
 mov esi,RENDER_FLAG_FALLBACK
 mov edx,256
 mov ecx,3
 mov r8d,RENDER_TARGET_HEADLESS
 call neboc_render_feature_validate
 test eax,eax
 jnz .return
 cmp r12d,1
 je .m1
 cmp r12d,2
 je .m2
 cmp r12d,3
 je .m3
 cmp r12d,4
 je .m4
 cmp r12d,5
 je .m5
 cmp r12d,6
 je .m6
 cmp r12d,7
 je .m7
 cmp r12d,8
 je .m8
 mov eax,RENDER_E_UNAVAILABLE
 jmp .return
.m1:
 G71_RUN g71_nodes_1,g71_s1,g71_s1_len,RENDER_POLICY_SECURITY,4
 mov edi,RENDER_PRIVACY_SECRET
 mov esi,RENDER_TARGET_HEADLESS
 mov edx,RENDER_FLAG_REDACT
 call nebo_g071_privacy_authorize
 test eax,eax
 jnz .return
 jmp .success
.m2:
 G71_RUN g71_nodes_2,g71_s2,g71_s2_len,RENDER_POLICY_ESCAPE,RENDER_SINK_HTML
 lea rdi,[rel g71_escape_input]
 mov esi,g71_escape_input_len
 mov edx,RENDER_SINK_HTML
 lea rcx,[rel g71_escape_out]
 mov r8d,128
 call nebo_g071_escape_sink
 cmp rax,g71_escape_expected_len
 jne .return
 lea rsi,[rel g71_escape_out]
 lea rdi,[rel g71_escape_expected]
 mov ecx,g71_escape_expected_len
 repe cmpsb
 jne .return
 jmp .success
.m3:
 G71_RUN g71_nodes_3,g71_s3,g71_s3_len,RENDER_POLICY_LOCALE,RENDER_LOCALE_PT_PT
 mov edi,RENDER_LOCALE_PT_PT
 call nebo_g071_locale_profile
 cmp eax,0x2e2c
 jne .return
 jmp .success
.m4:
 G71_RUN g71_nodes_4,g71_s4,g71_s4_len,RENDER_POLICY_ACCESSIBILITY,RENDER_ACCESS_TEXT|RENDER_ACCESS_HIGH_CONTRAST
 mov edi,G071_PROFILE_TEXT|G071_PROFILE_CONTRAST
 mov esi,G071_PROFILE_TEXT|G071_PROFILE_CONTRAST
 xor edx,edx
 call nebo_g071_select_profile
 cmp eax,G071_PROFILE_TEXT|G071_PROFILE_CONTRAST
 jne .return
 jmp .success
.m5:
 G71_RUN g71_nodes_5,g71_s5,g71_s5_len,RENDER_POLICY_FALLBACK,RENDER_TARGET_PLAIN
 mov edi,G071_PROFILE_CONTRAST
 mov esi,G071_PROFILE_TEXT
 xor edx,edx
 call nebo_g071_select_profile
 cmp eax,G071_PROFILE_TEXT
 jne .return
 jmp .success
.m6:
 G71_RUN g71_nodes_6,g71_s6,g71_s6_len,RENDER_POLICY_TERMINAL,RENDER_TERMINAL_WIDE
 mov edi,G071_PROFILE_ASCII
 mov esi,G071_PROFILE_ASCII
 xor edx,edx
 call nebo_g071_select_profile
 cmp eax,G071_PROFILE_ASCII
 jne .return
 jmp .success
.m7:
 G71_RUN g71_nodes_7,g71_s7,g71_s7_len,RENDER_POLICY_PRIVACY,RENDER_PRIVACY_SENSITIVE
 mov edi,RENDER_PRIVACY_SENSITIVE
 mov esi,RENDER_TARGET_HEADLESS
 mov edx,RENDER_FLAG_REDACT
 call nebo_g071_privacy_authorize
 test eax,eax
 jnz .return
 jmp .success
.m8:
 G71_RUN g71_nodes_8,g71_s8,g71_s8_len,RENDER_POLICY_CONFORMANCE,0
.success: mov eax,ebx
.return:
 pop r12
 pop rbx
 ret
%undef G71_RUN

nebo_g071_negative_probe:
 cmp edi,1
 je .token
 cmp edi,2
 je .meta
 cmp edi,3
 je .flags
 cmp edi,4
 je .privacy
 cmp edi,5
 je .feature
 cmp edi,6
 je .locale
 cmp edi,7
 je .strict
 cmp edi,8
 je .escape
 mov eax,RENDER_E_UNAVAILABLE
 ret
.token:
 mov edi,99
 xor esi,esi
 mov edx,RENDER_FLAG_FALLBACK
 jmp neboc_render_policy_token_validate
.meta:
 lea rdi,[rel g71_bad_meta]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 jmp neboc_render_plan_validate
.flags:
 lea rdi,[rel g71_bad_flags]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 jmp neboc_render_plan_validate
.privacy:
 mov edi,RENDER_PRIVACY_SECRET
 mov esi,RENDER_TARGET_HEADLESS
 xor edx,edx
 jmp nebo_g071_privacy_authorize
.feature:
 mov edi,7101
 xor esi,esi
 mov edx,8
 mov ecx,1
 mov r8d,RENDER_TARGET_HEADLESS
 jmp neboc_render_feature_validate
.locale:
 mov edi,99
 call nebo_g071_locale_profile
 neg eax
 ret
.strict:
 mov edi,G071_PROFILE_CONTRAST
 mov esi,G071_PROFILE_TEXT
 mov edx,1
 call nebo_g071_select_profile
 neg eax
 ret
.escape:
 lea rdi,[rel g71_escape_input]
 mov esi,g71_escape_input_len
 mov edx,99
 lea rcx,[rel g71_escape_out]
 mov r8d,128
 call nebo_g071_escape_sink
 neg eax
 ret

; EDI mode, RSI output, RDX capacity -> RAX committed bytes or typed error.
nebo_g071_render_transcript:
 mov r9d,edi
 mov r10,rsi
 mov r11,rdx
 cmp r9d,1
 je .m1
 cmp r9d,2
 je .m2
 cmp r9d,3
 je .m3
 cmp r9d,4
 je .m4
 cmp r9d,5
 je .m5
 cmp r9d,6
 je .m6
 cmp r9d,7
 je .m7
 cmp r9d,8
 je .m8
 mov rax,-RENDER_E_UNAVAILABLE
 ret
.m1: lea rdi,[rel g71_nodes_1]
 jmp .write
.m2: lea rdi,[rel g71_nodes_2]
 jmp .write
.m3: lea rdi,[rel g71_nodes_3]
 jmp .write
.m4: lea rdi,[rel g71_nodes_4]
 jmp .write
.m5: lea rdi,[rel g71_nodes_5]
 jmp .write
.m6: lea rdi,[rel g71_nodes_6]
 jmp .write
.m7: lea rdi,[rel g71_nodes_7]
 jmp .write
.m8: lea rdi,[rel g71_nodes_8]
.write:
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 mov rcx,r10
 mov r8,r11
 jmp neboc_render_plan_write
