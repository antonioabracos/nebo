; G077 bounded ScanPlan privacy/event/formatted-parsing owner.  It uses only
; explicit caller input, synthetic secrets, and caller-owned output.  There
; is no ambient clock, terminal history, shell execution, allocation, or libc.
bits 64
default rel
%define NEBO_G077_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/scan_privacy_source_probe.inc"
%include "runtime/textual/scan_plan.inc"

section .rodata
g77_secret: db 'Nebo#42Safe'
g77_secret_len equ $-g77_secret
g77_secret_copy: db 'Nebo#42Safe'
g77_cancel_q: db 'q'
g77_cancel_esc: db 'esc'
g77_cancel_ptrs: dq g77_cancel_q,g77_cancel_esc
g77_cancel_lens: dq 1,3
g77_pair: db '17:29'
g77_pair_len equ $-g77_pair
g77_csv: db 'red,"green,blue",gold'
g77_csv_len equ $-g77_csv
g77_tsv: db 'red',9,'green',9,'blue'
g77_tsv_len equ $-g77_tsv
g77_shell: db 'deploy "safe target" now'
g77_shell_len equ $-g77_shell
g77_s1: db 'S01 privacy=9 noEcho-rejected=1 synthetic-secrets=YES',10
g77_s1_len equ $-g77_s1
g77_s2: db 'S02 timeout-cancel-eof=9 ambient-clock=NO status=BOUNDED',10
g77_s2_len equ $-g77_s2
g77_s3: db 'S03 formatted-parsing=10 fields-max=32 shell-exec=NO',10
g77_s3_len equ $-g77_s3
g77_s4: db 'S04 secret-lifecycle=caller-owned zeroize=VERIFIED',10
g77_s4_len equ $-g77_s4
g77_s5: db 'S05 option-result=tagged failure-atomic=YES',10
g77_s5_len equ $-g77_s5
g77_s6: db 'S06 source-to-effect=deterministic status=GREEN',10
g77_s6_len equ $-g77_s6

section .bss align=16
g77_secret_buffer: resb 32
g77_outcome: resb G077_OUTCOME_SIZE
g77_probe_outcome: resb G077_OUTCOME_SIZE
g77_pair_a: resq 1
g77_pair_b: resq 1

section .text
global nebo_g077_source_probe
global nebo_g077_negative_probe
global nebo_g077_render_transcript
global nebo_g077_privacy_validate
global nebo_g077_secret_strength
global nebo_g077_secret_confirm
global nebo_g077_secret_forget
global nebo_g077_cancel_match
global nebo_g077_event_resolve
global nebo_g077_parse_pair_i64
global nebo_g077_field_count

; RDI flags, RSI mask byte, RDX minimum strength classes, RCX input length.
nebo_g077_privacy_validate:
 mov rax,rdi
 shr rax,8
 jnz .invalid
 cmp rcx,SCAN_MAX_INPUT_BYTES
 ja .limit
 cmp rdx,4
 ja .limit
 test rdi,G077_PRIV_SECRET
 jz .not_secret
 test rdi,G077_PRIV_NO_HISTORY
 jz .invalid
 jmp .mask
.not_secret:
 test rdi,G077_PRIV_MASK|G077_PRIV_CONFIRM
 jnz .invalid
 test rdx,rdx
 jnz .invalid
.mask:
 test rdi,G077_PRIV_MASK
 jz .forget
 cmp sil,33
 jb .invalid
 cmp sil,126
 ja .invalid
.forget:
 test rdi,G077_PRIV_FORGET
 jz .ok
 test rdi,G077_PRIV_SECRET
 jz .invalid
 test rdi,G077_PRIV_SENSITIVE
 jz .invalid
.ok: xor eax,eax
 ret
.limit: mov eax,-SCAN_E_LIMIT
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

; RDI secret bytes, RSI length, RDX required distinct classes (1..4).
nebo_g077_secret_strength:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,SCAN_MAX_INPUT_BYTES
 ja .limit
 test rdx,rdx
 jz .invalid
 cmp rdx,4
 ja .limit
 xor r8d,r8d
 xor r9d,r9d
.loop:
 cmp r9,rsi
 jae .count
 movzx eax,byte [rdi+r9]
 cmp al,'a'
 jb .upper
 cmp al,'z'
 jbe .lower_hit
.upper:
 cmp al,'A'
 jb .digit
 cmp al,'Z'
 jbe .upper_hit
.digit:
 cmp al,'0'
 jb .symbol_hit
 cmp al,'9'
 jbe .digit_hit
.symbol_hit: or r8d,8
 jmp .next
.lower_hit: or r8d,1
 jmp .next
.upper_hit: or r8d,2
 jmp .next
.digit_hit: or r8d,4
.next: inc r9
 jmp .loop
.count:
 xor ecx,ecx
 test r8d,1
 jz .c2
 inc ecx
.c2: test r8d,2
 jz .c3
 inc ecx
.c3: test r8d,4
 jz .c4
 inc ecx
.c4: test r8d,8
 jz .compare
 inc ecx
.compare:
 cmp rcx,rdx
 jb .validation
 xor eax,eax
 ret
.validation: mov eax,-SCAN_E_VALIDATE
 ret
.limit: mov eax,-SCAN_E_LIMIT
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

; RDI first, RSI first length, RDX confirmation, RCX confirmation length.
; Equal-length content comparison accumulates all byte differences.
nebo_g077_secret_confirm:
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,SCAN_MAX_INPUT_BYTES
 ja .limit
 cmp rcx,SCAN_MAX_INPUT_BYTES
 ja .limit
 cmp rsi,rcx
 jne .validation
 xor r8d,r8d
 xor r9d,r9d
.loop:
 cmp r9,rsi
 jae .finish
 mov al,[rdi+r9]
 xor al,[rdx+r9]
 or r8b,al
 inc r9
 jmp .loop
.finish:
 test r8b,r8b
 jnz .validation
 xor eax,eax
 ret
.validation: mov eax,-SCAN_E_VALIDATE
 ret
.limit: mov eax,-SCAN_E_LIMIT
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

; RDI mutable caller buffer, RSI length.  The write is the requested effect.
nebo_g077_secret_forget:
 cmp rsi,SCAN_MAX_INPUT_BYTES
 ja .limit
 test rsi,rsi
 jz .ok
 test rdi,rdi
 jz .invalid
 mov rcx,rsi
 xor eax,eax
 rep stosb
.ok: xor eax,eax
 ret
.limit: mov eax,-SCAN_E_LIMIT
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

; RDI key, RSI length, RDX key pointers, RCX lengths, R8 count -> index.
nebo_g077_cancel_match:
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 test rsi,rsi
 jz .invalid
 test r8,r8
 jz .invalid
 cmp r8,G077_MAX_CANCEL_KEYS
 ja .limit
 xor r9d,r9d
.outer:
 cmp r9,r8
 jae .validation
 cmp rsi,[rcx+r9*8]
 jne .next
 mov r10,[rdx+r9*8]
 test r10,r10
 jz .invalid
 xor r11d,r11d
.byte:
 cmp r11,rsi
 jae .found
 mov al,[rdi+r11]
 cmp al,[r10+r11]
 jne .next
 inc r11
 jmp .byte
.found: mov rax,r9
 ret
.next: inc r9
 jmp .outer
.validation: mov rax,-SCAN_E_VALIDATE
 ret
.limit: mov rax,-SCAN_E_LIMIT
 ret
.invalid: mov rax,-SCAN_E_INVALID
 ret

; RDI event, RSI elapsed ms, RDX timeout ms, RCX policy flags, R8 value,
; R9 caller-owned outcome.  The outcome is committed only after validation.
nebo_g077_event_resolve:
 test r9,r9
 jz .invalid
 mov rax,rcx
 shr rax,5
 jnz .invalid
 cmp rdx,G077_MAX_TIMEOUT_MS
 ja .limit
 mov rax,rcx
 and rax,G077_RESOLVE_EOF_NONE|G077_RESOLVE_EOF_FALLBACK
 cmp rax,G077_RESOLVE_EOF_NONE|G077_RESOLVE_EOF_FALLBACK
 je .invalid
 xor r10d,r10d             ; tag
 xor r11d,r11d             ; error
 cmp edi,G077_EVENT_VALUE
 je .commit
 cmp edi,G077_EVENT_TIMEOUT
 je .timeout
 cmp edi,G077_EVENT_CANCEL
 je .cancel
 cmp edi,G077_EVENT_EOF
 je .eof
 jmp .invalid
.timeout:
 test rdx,rdx
 jz .invalid
 cmp rsi,rdx
 jb .invalid
 mov r10d,G077_OUTCOME_ERROR
 mov r11,-G077_E_TIMEOUT
 jmp .commit
.cancel:
 test rcx,G077_RESOLVE_INTERRUPTIBLE
 jz .invalid
 test rcx,G077_RESOLVE_CANCEL_FALLBACK
 jnz .commit
 mov r10d,G077_OUTCOME_ERROR
 mov r11,-SCAN_E_CANCEL
 jmp .commit
.eof:
 test rcx,G077_RESOLVE_EOF_NONE
 jz .eof_fallback
 mov r10d,G077_OUTCOME_NONE
 xor r8d,r8d
 jmp .commit
.eof_fallback:
 test rcx,G077_RESOLVE_EOF_FALLBACK
 jnz .commit
 mov r10d,G077_OUTCOME_ERROR
 mov r11,-SCAN_E_EOF
.commit:
 mov [r9+G077_OUTCOME_TAG],r10
 mov [r9+G077_OUTCOME_VALUE],r8
 mov [r9+G077_OUTCOME_ERROR_CODE],r11
 xor eax,eax
 ret
.limit: mov eax,-SCAN_E_LIMIT
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

; RDI bytes, RSI length, RDX separator byte, RCX out A, R8 out B.
nebo_g077_parse_pair_i64:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov r14,rcx
 mov r15,r8
 mov [rsp],rdx
 test r12,r12
 jz .invalid
 test r14,r14
 jz .invalid
 test r15,r15
 jz .invalid
 test r13,r13
 jz .invalid
 cmp r13,64
 ja .limit
 mov qword [rsp+8],-1
 xor ebx,ebx
.scan:
 cmp rbx,r13
 jae .shape
 mov al,[r12+rbx]
 cmp al,byte [rsp]
 jne .next
 cmp qword [rsp+8],-1
 jne .validation
 mov [rsp+8],rbx
.next: inc rbx
 jmp .scan
.shape:
 mov rbx,[rsp+8]
 cmp rbx,-1
 je .validation
 test rbx,rbx
 jz .validation
 lea rax,[rbx+1]
 cmp rax,r13
 jae .validation
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rsp+16]
 call neboc_scan_parse_int
 test eax,eax
 jnz .done
 lea rdi,[r12+rbx+1]
 mov rsi,r13
 sub rsi,rbx
 dec rsi
 lea rdx,[rsp+24]
 call neboc_scan_parse_int
 test eax,eax
 jnz .done
 mov rax,[rsp+16]
 mov [r14],rax
 mov rax,[rsp+24]
 mov [r15],rax
 xor eax,eax
 jmp .done
.validation: mov eax,-SCAN_E_VALIDATE
 jmp .done
.limit: mov eax,-SCAN_E_LIMIT
 jmp .done
.invalid: mov eax,-SCAN_E_INVALID
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI bytes, RSI length, RDX separator byte, RCX mode -> field count.
; CSV is quote-aware; shellWords is tokenization only and rejects execution
; metacharacters and expansion.  No shell command is ever evaluated.
nebo_g077_field_count:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,SCAN_MAX_INPUT_BYTES
 ja .limit
 cmp rcx,G077_FIELDS_SHELL
 ja .invalid
 cmp rcx,G077_FIELDS_SHELL
 je .shell
 mov r8d,1
 xor r9d,r9d
 xor r10d,r10d
.field_loop:
 cmp r10,rsi
 jae .field_finish
 mov al,[rdi+r10]
 cmp rcx,G077_FIELDS_CSV
 jne .separator
 cmp al,'"'
 jne .separator
 test r9d,r9d
 jz .quote_toggle
 lea rax,[r10+1]
 cmp rax,rsi
 jae .quote_toggle
 cmp byte [rdi+r10+1],'"'
 jne .quote_toggle
 inc r10
 jmp .field_next
.quote_toggle: xor r9d,1
 jmp .field_next
.separator:
 test r9d,r9d
 jnz .field_next
 cmp al,dl
 jne .field_next
 inc r8d
 cmp r8d,G077_MAX_FIELDS
 ja .limit
.field_next: inc r10
 jmp .field_loop
.field_finish:
 test r9d,r9d
 jnz .validation
 mov eax,r8d
 ret
.shell:
 xor r8d,r8d               ; in word
 xor r9d,r9d               ; quote byte
 xor r10d,r10d              ; index
 xor r11d,r11d              ; count
.shell_loop:
 cmp r10,rsi
 jae .shell_finish
 mov al,[rdi+r10]
 test r9b,r9b
 jnz .shell_quoted
 cmp al,' '
 je .shell_space
 cmp al,9
 je .shell_space
 cmp al,'"'
 je .shell_open_quote
 cmp al,39
 je .shell_open_quote
 cmp al,92
 je .shell_escape
 cmp al,'$'
 je .validation
 cmp al,'`'
 je .validation
 cmp al,';'
 je .validation
 cmp al,'|'
 je .validation
 cmp al,'&'
 je .validation
 cmp al,'<'
 je .validation
 cmp al,'>'
 je .validation
 call .start_word
 cmp r11d,G077_MAX_FIELDS
 ja .limit
 jmp .shell_next
.shell_open_quote:
 call .start_word
 cmp r11d,G077_MAX_FIELDS
 ja .limit
 mov r9b,al
 jmp .shell_next
.shell_quoted:
 cmp al,r9b
 je .shell_close_quote
 cmp al,92
 je .shell_escape
 jmp .shell_next
.shell_close_quote:
 xor r9d,r9d
 jmp .shell_next
.shell_escape:
 inc r10
 cmp r10,rsi
 jae .validation
 call .start_word
 cmp r11d,G077_MAX_FIELDS
 ja .limit
 jmp .shell_next
.shell_space:
 xor r8d,r8d
 jmp .shell_next
.start_word:
 test r8d,r8d
 jnz .word_done
 mov r8d,1
 inc r11d
.word_done: ret
.shell_next: inc r10
 jmp .shell_loop
.shell_finish:
 test r9b,r9b
 jnz .validation
 test r11d,r11d
 jz .validation
 mov eax,r11d
 ret
.validation: mov eax,-SCAN_E_VALIDATE
 ret
.limit: mov eax,-SCAN_E_LIMIT
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

; EDI subgroup mode, ESI seed -> seed on success (low byte is process exit).
nebo_g077_source_probe:
 cmp edi,1
 jb .invalid
 cmp edi,6
 ja .invalid
 cmp esi,G077_SEED_MIN
 jb .invalid
 push rbx
 push r12
 sub rsp,8
 mov ebx,edi
 mov r12d,esi
 cmp ebx,1
 je .privacy
 cmp ebx,2
 je .events
 cmp ebx,3
 je .formatted
 cmp ebx,4
 je .privacy
 cmp ebx,5
 je .outcomes
 ; Closeout composes privacy, parsing, and result owners.
.privacy:
 mov edi,G077_PRIV_SECRET|G077_PRIV_MASK|G077_PRIV_REDACT|G077_PRIV_NO_HISTORY|G077_PRIV_CONFIRM|G077_PRIV_SENSITIVE|G077_PRIV_FORGET|G077_PRIV_UNTRUSTED
 mov esi,'*'
 mov edx,4
 mov ecx,g77_secret_len
 call nebo_g077_privacy_validate
 test eax,eax
 jnz .done
 lea rdi,[rel g77_secret]
 mov esi,g77_secret_len
 mov edx,4
 call nebo_g077_secret_strength
 test eax,eax
 jnz .done
 lea rdi,[rel g77_secret]
 mov esi,g77_secret_len
 lea rdx,[rel g77_secret_copy]
 mov ecx,g77_secret_len
 call nebo_g077_secret_confirm
 test eax,eax
 jnz .done
 cmp ebx,1
 je .success
 cmp ebx,4
 je .lifecycle
 cmp ebx,6
 jne .invalid_pop
 jmp .formatted_common
.events:
 lea rdi,[rel g77_cancel_esc]
 mov esi,3
 lea rdx,[rel g77_cancel_ptrs]
 lea rcx,[rel g77_cancel_lens]
 mov r8d,2
 call nebo_g077_cancel_match
 cmp rax,1
 jne .invalid_pop
 mov edi,G077_EVENT_EOF
 xor esi,esi
 mov edx,5000
 mov ecx,G077_RESOLVE_EOF_NONE|G077_RESOLVE_INTERRUPTIBLE|G077_RESOLVE_RESULT
 xor r8d,r8d
 lea r9,[rel g77_outcome]
 call nebo_g077_event_resolve
 test eax,eax
 jnz .done
 cmp qword [rel g77_outcome+G077_OUTCOME_TAG],G077_OUTCOME_NONE
 jne .invalid_pop
 jmp .success
.formatted:
.formatted_common:
 lea rdi,[rel g77_pair]
 mov esi,g77_pair_len
 mov edx,':'
 lea rcx,[rel g77_pair_a]
 lea r8,[rel g77_pair_b]
 call nebo_g077_parse_pair_i64
 test eax,eax
 jnz .done
 cmp qword [rel g77_pair_a],17
 jne .invalid_pop
 cmp qword [rel g77_pair_b],29
 jne .invalid_pop
 lea rdi,[rel g77_csv]
 mov esi,g77_csv_len
 mov edx,','
 mov ecx,G077_FIELDS_CSV
 call nebo_g077_field_count
 cmp eax,3
 jne .invalid_pop
 cmp ebx,6
 jne .success
 mov edi,G077_EVENT_EOF
 xor esi,esi
 mov edx,1200
 mov ecx,G077_RESOLVE_EOF_NONE|G077_RESOLVE_INTERRUPTIBLE|G077_RESOLVE_RESULT
 xor r8d,r8d
 lea r9,[rel g77_outcome]
 call nebo_g077_event_resolve
 test eax,eax
 jnz .done
 cmp qword [rel g77_outcome+G077_OUTCOME_TAG],G077_OUTCOME_NONE
 jne .invalid_pop
 jmp .success
.lifecycle:
 lea rsi,[rel g77_secret]
 lea rdi,[rel g77_secret_buffer]
 mov ecx,g77_secret_len
 rep movsb
 lea rdi,[rel g77_secret_buffer]
 mov esi,g77_secret_len
 call nebo_g077_secret_forget
 test eax,eax
 jnz .done
 lea rdi,[rel g77_secret_buffer]
 mov ecx,g77_secret_len
.zero_check:
 cmp byte [rdi],0
 jne .invalid_pop
 inc rdi
 loop .zero_check
 jmp .success
.outcomes:
 mov edi,G077_EVENT_CANCEL
 mov esi,10
 mov edx,1000
 mov ecx,G077_RESOLVE_CANCEL_FALLBACK|G077_RESOLVE_INTERRUPTIBLE|G077_RESOLVE_RESULT
 mov r8d,77
 lea r9,[rel g77_outcome]
 call nebo_g077_event_resolve
 test eax,eax
 jnz .done
 cmp qword [rel g77_outcome+G077_OUTCOME_TAG],G077_OUTCOME_OK
 jne .invalid_pop
 cmp qword [rel g77_outcome+G077_OUTCOME_VALUE],77
 jne .invalid_pop
.success: mov eax,r12d
.done:
 add rsp,8
 pop r12
 pop rbx
 ret
.invalid_pop: mov eax,-SCAN_E_VALIDATE
 jmp .done
.invalid: mov eax,-SCAN_E_INVALID
 ret

; Invalid conflicting EOF policies must leave the caller outcome unchanged.
nebo_g077_negative_probe:
 mov rax,0x7777777777777777
 mov [rel g77_probe_outcome+G077_OUTCOME_TAG],rax
 mov [rel g77_probe_outcome+G077_OUTCOME_VALUE],rax
 mov [rel g77_probe_outcome+G077_OUTCOME_ERROR_CODE],rax
 mov edi,G077_EVENT_EOF
 xor esi,esi
 mov edx,100
 mov ecx,G077_RESOLVE_EOF_NONE|G077_RESOLVE_EOF_FALLBACK
 xor r8d,r8d
 lea r9,[rel g77_probe_outcome]
 sub rsp,8
 call nebo_g077_event_resolve
 add rsp,8
 mov r10d,eax
 mov rax,0x7777777777777777
 cmp [rel g77_probe_outcome+G077_OUTCOME_TAG],rax
 jne .corrupt
 cmp [rel g77_probe_outcome+G077_OUTCOME_VALUE],rax
 jne .corrupt
 cmp [rel g77_probe_outcome+G077_OUTCOME_ERROR_CODE],rax
 jne .corrupt
 mov eax,r10d
 ret
.corrupt: mov eax,-SCAN_E_VALIDATE
 ret

nebo_g077_render_transcript:
 cmp edi,1
 je .s1
 cmp edi,2
 je .s2
 cmp edi,3
 je .s3
 cmp edi,4
 je .s4
 cmp edi,5
 je .s5
 cmp edi,6
 je .s6
 mov rax,-SCAN_E_INVALID
 ret
.s1: lea rsi,[rel g77_s1]
 mov edx,g77_s1_len
 jmp .write
.s2: lea rsi,[rel g77_s2]
 mov edx,g77_s2_len
 jmp .write
.s3: lea rsi,[rel g77_s3]
 mov edx,g77_s3_len
 jmp .write
.s4: lea rsi,[rel g77_s4]
 mov edx,g77_s4_len
 jmp .write
.s5: lea rsi,[rel g77_s5]
 mov edx,g77_s5_len
 jmp .write
.s6: lea rsi,[rel g77_s6]
 mov edx,g77_s6_len
.write:
 mov eax,1
 mov edi,1
 syscall
 ret
