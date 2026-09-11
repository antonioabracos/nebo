; G076 bounded ScanPlan validation owner. No operation consults host locale,
; terminal state, time, network, or allocation. Mutable output is committed
; only after complete validation.
bits 64
default rel
%define NEBO_G076_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/scan_validation_source_probe.inc"
%include "runtime/textual/scan_plan.inc"

section .rodata
g76_text: db 'nebo42safe'
g76_text_len equ $-g76_text
g76_needle: db '42'
g76_needle_len equ $-g76_needle
g76_decimal: db '18,75'
g76_decimal_len equ $-g76_decimal
g76_yes: db 'yes'
g76_red: db 'red'
g76_green: db 'green'
g76_blue: db 'blue'
g76_choices: dq g76_red,g76_green,g76_blue
g76_choice_lens: dq 3,5,4
g76_prefix: db 'gr'
g76_indices: db 0,2
g76_s1: db 'S01 textual=11 deferred-pattern=1 status=BOUNDED',10
g76_s1_len equ $-g76_s1
g76_s2: db 'S02 numeric=10 locale=explicit status=BOUNDED',10
g76_s2_len equ $-g76_s2
g76_s3: db 'S03 choices=8 enum-deferred=1 oneOf-rejected=1 status=BOUNDED',10
g76_s3_len equ $-g76_s3
g76_s4: db 'S04 retry-ux=10 max-attempts=8 status=BOUNDED',10
g76_s4_len equ $-g76_s4
g76_s5: db 'S05 composition=failure-atomic status=GREEN',10
g76_s5_len equ $-g76_s5
g76_s6: db 'S06 source-to-effect=deterministic status=GREEN',10
g76_s6_len equ $-g76_s6

section .bss align=16
g76_retry_state: resb G076_RETRY_SIZE
g76_probe_word: resq 1

section .text
global nebo_g076_source_probe
global nebo_g076_negative_probe
global nebo_g076_render_transcript
global nebo_g076_text_match
global nebo_g076_numeric_validate
global nebo_g076_decimal_validate
global nebo_g076_prefix_index
global nebo_g076_multiselect_mask
global nebo_g076_yes_no
global nebo_g076_retry_init
global nebo_g076_retry_failure
global nebo_g076_retry_should_continue
global nebo_g076_retry_resolve

; RDI operation, RSI input, RDX input length, RCX needle, R8 needle length.
nebo_g076_text_match:
 test rsi,rsi
 jz .invalid
 test rcx,rcx
 jz .invalid
 test r8,r8
 jz .invalid
 cmp rdx,SCAN_MAX_INPUT_BYTES
 ja .limit
 cmp r8,rdx
 ja .miss
 cmp edi,G076_TEXT_CONTAINS
 je .contains
 cmp edi,G076_TEXT_STARTS
 je .starts
 cmp edi,G076_TEXT_ENDS
 je .ends
 jmp .invalid
.starts:
 xor r9d,r9d
 jmp .compare
.ends:
 mov r9,rdx
 sub r9,r8
 jmp .compare
.contains:
 xor r9d,r9d
.search:
 mov rax,rdx
 sub rax,r8
 cmp r9,rax
 ja .miss
.compare:
 xor r10d,r10d
.byte:
 cmp r10,r8
 jae .hit
 mov rax,r9
 add rax,r10
 mov al,[rsi+rax]
 cmp al,[rcx+r10]
 jne .next
 inc r10
 jmp .byte
.next:
 cmp edi,G076_TEXT_CONTAINS
 jne .miss
 inc r9
 jmp .search
.hit: xor eax,eax
 ret
.miss: mov eax,-SCAN_E_VALIDATE
 ret
.limit: mov eax,-SCAN_E_LIMIT
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

; RDI value, RSI min, RDX max, RCX flags, R8 nonzero multiple.
nebo_g076_numeric_validate:
 push rbx
 push r12
 sub rsp,8
 mov rbx,r8
 mov r12,rdi
 test rbx,rbx
 jle .invalid
 call neboc_scan_validate_int
 test eax,eax
 jnz .done
 mov rax,r12
 cqo
 idiv rbx
 test rdx,rdx
 jnz .validation
 xor eax,eax
 jmp .done
.invalid: mov eax,-SCAN_E_INVALID
 jmp .done
.validation: mov eax,-SCAN_E_VALIDATE
.done: add rsp,8
 pop r12
 pop rbx
 ret

; RDI bytes, RSI length, RDX exact fractional precision, RCX explicit locale.
nebo_g076_decimal_validate:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,SCAN_MAX_INPUT_BYTES
 ja .limit
 cmp rdx,9
 ja .limit
 cmp rcx,G076_LOCALE_C
 je .dot
 cmp rcx,G076_LOCALE_PT_PT
 jne .invalid
 mov r8b,','
 jmp .scan_init
.dot: mov r8b,'.'
.scan_init:
 xor r9d,r9d
 xor r10d,r10d
 xor r11d,r11d
 mov al,[rdi]
 cmp al,'+'
 je .skip_sign
 cmp al,'-'
 jne .scan
.skip_sign:
 inc r9
 cmp r9,rsi
 jae .validation
.scan:
 cmp r9,rsi
 jae .finish
 mov al,[rdi+r9]
 cmp al,r8b
 je .separator
 cmp al,'0'
 jb .validation
 cmp al,'9'
 ja .validation
 test r10d,r10d
 jz .next
 inc r11
.next: inc r9
 jmp .scan
.separator:
 test r10d,r10d
 jnz .validation
 test r9,r9
 jz .validation
 cmp r9,1
 jne .separator_ok
 mov al,[rdi]
 cmp al,'+'
 je .validation
 cmp al,'-'
 je .validation
.separator_ok:
 mov r10d,1
 inc r9
 jmp .scan
.finish:
 test rdx,rdx
 jz .no_fraction
 test r10d,r10d
 jz .validation
 cmp r11,rdx
 jne .validation
 xor eax,eax
 ret
.no_fraction:
 test r10d,r10d
 jnz .validation
 xor eax,eax
 ret
.validation: mov eax,-SCAN_E_VALIDATE
 ret
.limit: mov eax,-SCAN_E_LIMIT
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

; RDI prefix, RSI length, RDX pointers, RCX lengths, R8 count -> unique index.
nebo_g076_prefix_index:
 push rbx
 push r12
 push r13
 push r14
 push r15
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
 cmp r8,SCAN_MAX_CHOICES
 ja .limit
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov r11,r8
 xor ebx,ebx
 mov r10,-1
.candidate:
 cmp rbx,r11
 jae .finish
 mov rax,[r15+rbx*8]
 cmp r13,rax
 ja .candidate_next
 mov rdi,[r14+rbx*8]
 test rdi,rdi
 jz .invalid
 xor ecx,ecx
.prefix_byte:
 cmp rcx,r13
 jae .matched
 mov al,[r12+rcx]
 cmp al,[rdi+rcx]
 jne .candidate_next
 inc rcx
 jmp .prefix_byte
.matched:
 cmp r10,-1
 jne .validation
 mov r10,rbx
.candidate_next:
 inc rbx
 jmp .candidate
.finish:
 cmp r10,-1
 je .validation
 mov rax,r10
 jmp .done
.validation: mov rax,-SCAN_E_VALIDATE
 jmp .done
.limit: mov rax,-SCAN_E_LIMIT
 jmp .done
.invalid: mov rax,-SCAN_E_INVALID
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI byte indices, RSI count, RDX choice count, RCX output mask.
nebo_g076_multiselect_mask:
 test rdi,rdi
 jz .invalid
 test rcx,rcx
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,SCAN_MAX_CHOICES
 ja .limit
 test rdx,rdx
 jz .invalid
 cmp rdx,SCAN_MAX_CHOICES
 ja .limit
 mov r11,rcx
 xor r8d,r8d
 xor r9d,r9d
.mask_loop:
 cmp r9,rsi
 jae .commit
 movzx eax,byte [rdi+r9]
 cmp rax,rdx
 jae .validation
 mov r10,1
 mov ecx,eax
 shl r10,cl
 test r8,r10
 jnz .validation
 or r8,r10
 inc r9
 jmp .mask_loop
.commit:
 mov [r11],r8
 xor eax,eax
 ret
.validation: mov eax,-SCAN_E_VALIDATE
 ret
.limit: mov eax,-SCAN_E_LIMIT
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

; RDI bytes, RSI length -> 1 yes, 0 no, or typed error.
nebo_g076_yes_no:
 test rdi,rdi
 jz .invalid
 cmp rsi,1
 je .single
 cmp rsi,2
 je .no_word
 cmp rsi,3
 jne .validation
 mov al,[rdi]
 or al,0x20
 cmp al,'y'
 jne .validation
 mov al,[rdi+1]
 or al,0x20
 cmp al,'e'
 jne .validation
 mov al,[rdi+2]
 or al,0x20
 cmp al,'s'
 je .yes
 jmp .validation
.no_word:
 mov ax,[rdi]
 or ax,0x2020
 cmp ax,0x6f6e
 je .no
 jmp .validation
.single:
 mov al,[rdi]
 or al,0x20
 cmp al,'y'
 je .yes
 cmp al,'n'
 je .no
 jmp .validation
.yes: mov eax,1
 ret
.no: xor eax,eax
 ret
.validation: mov eax,-SCAN_E_VALIDATE
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

; Retry is finite (1..8) and caller-owned.
nebo_g076_retry_init:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,SCAN_MAX_ATTEMPTS
 ja .limit
 mov qword [rdi+G076_RETRY_ATTEMPTS],0
 mov [rdi+G076_RETRY_MAX],rsi
 mov qword [rdi+G076_RETRY_LAST],0
 mov [rdi+G076_RETRY_FALLBACK],rdx
 xor eax,eax
 ret
.limit: mov eax,-SCAN_E_LIMIT
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

nebo_g076_retry_failure:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jns .invalid
 mov rdx,[rdi+G076_RETRY_MAX]
 test rdx,rdx
 jz .invalid
 cmp rdx,SCAN_MAX_ATTEMPTS
 ja .invalid
 mov rax,[rdi+G076_RETRY_ATTEMPTS]
 cmp rax,rdx
 ja .invalid
 jae .validation
 mov rdx,rax
 inc rdx
 mov [rdi+G076_RETRY_LAST],rsi
 mov [rdi+G076_RETRY_ATTEMPTS],rdx
 xor eax,eax
 ret
.validation: mov eax,-SCAN_E_VALIDATE
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

nebo_g076_retry_should_continue:
 test rdi,rdi
 jz .invalid
 mov rdx,[rdi+G076_RETRY_MAX]
 test rdx,rdx
 jz .invalid
 cmp rdx,SCAN_MAX_ATTEMPTS
 ja .invalid
 mov rax,[rdi+G076_RETRY_ATTEMPTS]
 cmp rax,rdx
 ja .invalid
 setb al
 movzx eax,al
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

; RDI state, RSI value-valid flag, RDX value, RCX output.
nebo_g076_retry_resolve:
 test rdi,rdi
 jz .invalid
 test rcx,rcx
 jz .invalid
 mov r8,[rdi+G076_RETRY_MAX]
 test r8,r8
 jz .invalid
 cmp r8,SCAN_MAX_ATTEMPTS
 ja .invalid
 mov rax,[rdi+G076_RETRY_ATTEMPTS]
 cmp rax,r8
 ja .invalid
 test rsi,rsi
 jnz .value
 cmp rax,r8
 jb .validation
 mov rdx,[rdi+G076_RETRY_FALLBACK]
.value: mov [rcx],rdx
 xor eax,eax
 ret
.validation: mov eax,-SCAN_E_VALIDATE
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

; EDI subgroup mode, ESI seed -> seed on success (process exit is low byte).
nebo_g076_source_probe:
 cmp edi,1
 jb .invalid
 cmp edi,6
 ja .invalid
 cmp esi,G076_SEED_MIN
 jb .invalid
 push rbx
 push r12
 sub rsp,8
 mov ebx,edi
 mov r12d,esi
 cmp ebx,1
 je .textual
 cmp ebx,2
 je .numeric
 cmp ebx,3
 je .choices
 cmp ebx,4
 je .retry
 cmp ebx,5
 je .composition
 ; Closeout executes the same independent owners as the composed path.
.composition:
 mov edi,G076_TEXT_CONTAINS
 lea rsi,[rel g76_text]
 mov edx,g76_text_len
 lea rcx,[rel g76_needle]
 mov r8d,g76_needle_len
 call nebo_g076_text_match
 test eax,eax
 jnz .done
 mov edi,24
 mov esi,1
 mov edx,99
 mov ecx,SCAN_INT_EVEN|SCAN_INT_POSITIVE
 mov r8d,6
 call nebo_g076_numeric_validate
 test eax,eax
 jnz .done
 lea rdi,[rel g76_green]
 mov esi,5
 lea rdx,[rel g76_choices]
 lea rcx,[rel g76_choice_lens]
 mov r8d,3
 call neboc_scan_choice_index
 cmp rax,1
 jne .invalid_pop
 jmp .retry_common
.textual:
 mov edi,G076_TEXT_CONTAINS
 lea rsi,[rel g76_text]
 mov edx,g76_text_len
 lea rcx,[rel g76_needle]
 mov r8d,g76_needle_len
 call nebo_g076_text_match
 test eax,eax
 jnz .done
 lea rdi,[rel g76_text]
 mov esi,g76_text_len
 mov edx,3
 mov ecx,20
 mov r8d,SCAN_TEXT_NO_CONTROL|SCAN_TEXT_ALNUM
 call neboc_scan_validate_text
 test eax,eax
 jnz .done
 jmp .success
.numeric:
 mov edi,24
 mov esi,1
 mov edx,99
 mov ecx,SCAN_INT_EVEN|SCAN_INT_POSITIVE
 mov r8d,6
 call nebo_g076_numeric_validate
 test eax,eax
 jnz .done
 lea rdi,[rel g76_decimal]
 mov esi,g76_decimal_len
 mov edx,2
 mov ecx,G076_LOCALE_PT_PT
 call nebo_g076_decimal_validate
 test eax,eax
 jnz .done
 jmp .success
.choices:
 lea rdi,[rel g76_green]
 mov esi,5
 lea rdx,[rel g76_choices]
 lea rcx,[rel g76_choice_lens]
 mov r8d,3
 call neboc_scan_choice_index
 cmp rax,1
 jne .invalid_pop
 lea rdi,[rel g76_prefix]
 mov esi,2
 lea rdx,[rel g76_choices]
 lea rcx,[rel g76_choice_lens]
 mov r8d,3
 call nebo_g076_prefix_index
 cmp rax,1
 jne .invalid_pop
 jmp .success
.retry:
.retry_common:
 lea rdi,[rel g76_retry_state]
 mov esi,2
 mov edx,77
 call nebo_g076_retry_init
 test eax,eax
 jnz .done
 lea rdi,[rel g76_retry_state]
 mov rsi,-SCAN_E_VALIDATE
 call nebo_g076_retry_failure
 test eax,eax
 jnz .done
 lea rdi,[rel g76_retry_state]
 call nebo_g076_retry_should_continue
 cmp eax,1
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

; A fixed independent negative probe: an invalid selection must not
; commit its caller-owned output.
nebo_g076_negative_probe:
 mov rax,0x7777777777777777
 mov [rel g76_probe_word],rax
 lea rdi,[rel g76_indices]
 mov esi,2
 mov edx,2
 lea rcx,[rel g76_probe_word]
 ; second index is outside choice_count and must fail atomically.
 jmp nebo_g076_multiselect_mask

nebo_g076_render_transcript:
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
.s1: lea rsi,[rel g76_s1]
 mov edx,g76_s1_len
 jmp .write
.s2: lea rsi,[rel g76_s2]
 mov edx,g76_s2_len
 jmp .write
.s3: lea rsi,[rel g76_s3]
 mov edx,g76_s3_len
 jmp .write
.s4: lea rsi,[rel g76_s4]
 mov edx,g76_s4_len
 jmp .write
.s5: lea rsi,[rel g76_s5]
 mov edx,g76_s5_len
 jmp .write
.s6: lea rsi,[rel g76_s6]
 mov edx,g76_s6_len
.write:
 mov eax,1
 mov edi,1
 syscall
 ret
