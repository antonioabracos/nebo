; G075 bounded ScanPlan owner.  All state and output are caller-owned; every
; mutating operation validates capacity and policy before the first write.
bits 64
default rel
%define NEBO_G075_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/scan_plan_source_probe.inc"
%include "runtime/textual/scan_plan.inc"

section .rodata
g75_true: db 'true'
g75_true_len equ $-g75_true
g75_false: db 'false'
g75_false_len equ $-g75_false
g75_email: db 'reader@example.test'
g75_email_len equ $-g75_email
g75_slug_input: db '  Nebo   Scan  ',10
g75_slug_input_len equ $-g75_slug_input
g75_s1: db 'S01 kinds=19 status=PUBLIC_BOUNDED_GREEN',10
g75_s1_len equ $-g75_s1
g75_s2: db 'S02 empty-policies=6 status=PUBLIC_BOUNDED_GREEN',10
g75_s2_len equ $-g75_s2
g75_s3: db 'S03 normalizers=10 deferred-unicode=1 status=BOUNDED',10
g75_s3_len equ $-g75_s3
g75_s4: db 'S04 ir-abi=caller-owned status=GREEN',10
g75_s4_len equ $-g75_s4
g75_s5: db 'S05 spans-diagnostics=typed status=GREEN',10
g75_s5_len equ $-g75_s5
g75_s6: db 'S06 source-to-effect=deterministic status=GREEN',10
g75_s6_len equ $-g75_s6

section .bss align=16
g75_probe_state: resb G075_STATE_SIZE
g75_probe_output: resb G075_BUFFER_MAX
g75_probe_word: resq 1

section .text
global nebo_g075_source_probe
global nebo_g075_negative_probe
global nebo_g075_render_transcript
global nebo_g075_plan_init
global nebo_g075_validate_kind
global nebo_g075_empty_resolve
global nebo_g075_normalize

; RDI state, RSI kind, RDX flags, RCX span start, R8 span end -> status.
nebo_g075_plan_init:
 test rdi,rdi
 jz .invalid
 cmp rsi,SCAN_KIND_TEXT
 jb .invalid
 cmp rsi,SCAN_KIND_MAX
 ja .invalid
 cmp rcx,r8
 ja .invalid
 mov rax,rdx
 and eax,SCAN_FLAG_REQUIRED|SCAN_FLAG_OPTIONAL
 cmp eax,SCAN_FLAG_REQUIRED|SCAN_FLAG_OPTIONAL
 je .invalid
 mov r10,rcx
 push rdi
 xor eax,eax
 mov ecx,G075_STATE_SIZE/8
 rep stosq
 pop rdi
 mov [rdi+G075_STATE_KIND],rsi
 mov [rdi+G075_STATE_FLAGS],rdx
 mov [rdi+G075_STATE_SPAN_START],r10
 mov [rdi+G075_STATE_SPAN_END],r8
 xor eax,eax
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

; RDI kind, RSI bytes, RDX length -> status.  This is a finite, deterministic
; shape validator, not a locale-aware or network-aware validator.
nebo_g075_validate_kind:
 cmp rdi,SCAN_KIND_TEXT
 jb .invalid
 cmp rdi,SCAN_KIND_MAX
 ja .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,SCAN_MAX_INPUT_BYTES
 ja .limit
 cmp rdi,SCAN_KIND_RAW
 je .ok
 cmp rdi,SCAN_KIND_INT
 je .integer
 cmp rdi,SCAN_KIND_NUMBER
 je .number
 cmp rdi,SCAN_KIND_BOOL
 je .boolean
 cmp rdi,SCAN_KIND_CHAR
 je .character
 cmp rdi,SCAN_KIND_LINE
 je .line
 cmp rdi,SCAN_KIND_TOKEN
 je .token
 cmp rdi,SCAN_KIND_WORDS
 je .words
 cmp rdi,SCAN_KIND_LIST
 je .comma
 cmp rdi,SCAN_KIND_TUPLE
 je .comma
 cmp rdi,SCAN_KIND_DATE
 je .date
 cmp rdi,SCAN_KIND_TIME
 je .time
 cmp rdi,SCAN_KIND_DATETIME
 je .datetime
 cmp rdi,SCAN_KIND_EMAIL
 je .email
 cmp rdi,SCAN_KIND_URL
 je .url
 cmp rdi,SCAN_KIND_PATH
 je .path
 cmp rdi,SCAN_KIND_PASSWORD
 je .password
 cmp rdi,SCAN_KIND_JSON
 je .json
 ; text and words-like primitives reject ASCII controls except tab.
 xor ecx,ecx
.text_loop:
 cmp rcx,rdx
 jae .ok
 movzx eax,byte [rsi+rcx]
 cmp al,9
 je .text_next
 cmp al,32
 jb .invalid
.text_next: inc rcx
 jmp .text_loop
.integer:
 sub rsp,8
 mov rdi,rsi
 mov rsi,rdx
 lea rdx,[rel g75_probe_word]
 call neboc_scan_parse_int
 add rsp,8
 ret
.number:
 xor ecx,ecx
 xor r8d,r8d
 xor r10d,r10d
 mov al,[rsi]
 cmp al,'+'
 je .number_sign
 cmp al,'-'
 jne .number_loop
.number_sign:
 inc rcx
 cmp rcx,rdx
 jae .invalid
.number_loop:
 cmp rcx,rdx
 jae .number_done
 mov al,[rsi+rcx]
 cmp al,'.'
 jne .number_digit
 inc r8d
 cmp r8d,1
 ja .invalid
 jmp .number_next
.number_digit:
 cmp al,'0'
 jb .invalid
 cmp al,'9'
 ja .invalid
 inc r10d
.number_next: inc rcx
 jmp .number_loop
.number_done:
 test r10d,r10d
 jz .invalid
 cmp byte [rsi+rdx-1],'.'
 je .invalid
 xor eax,eax
 ret
.boolean:
 cmp rdx,4
 jne .boolean_false
 cmp dword [rsi],0x65757274
 je .ok
.boolean_false:
 cmp rdx,5
 jne .invalid
 cmp dword [rsi],0x736c6166
 jne .invalid
 cmp byte [rsi+4],'e'
 jne .invalid
 jmp .ok
.character:
 cmp rdx,1
 jne .invalid
 jmp .ok
.line:
 xor ecx,ecx
.line_loop:
 cmp rcx,rdx
 jae .ok
 mov al,[rsi+rcx]
 cmp al,10
 je .invalid
 cmp al,13
 je .invalid
 inc rcx
 jmp .line_loop
.token:
 xor ecx,ecx
.token_loop:
 cmp rcx,rdx
 jae .ok
 mov al,[rsi+rcx]
 cmp al,32
 jbe .invalid
 inc rcx
 jmp .token_loop
.words:
 mov al,' '
 jmp .find_byte
.comma:
 mov al,','
.find_byte:
 xor ecx,ecx
.find_loop:
 cmp rcx,rdx
 jae .invalid
 cmp [rsi+rcx],al
 je .ok
 inc rcx
 jmp .find_loop
.date:
 cmp rdx,10
 jne .invalid
 cmp byte [rsi+4],'-'
 jne .invalid
 cmp byte [rsi+7],'-'
 jne .invalid
 jmp .ok
.time:
 cmp rdx,8
 jne .invalid
 cmp byte [rsi+2],':'
 jne .invalid
 cmp byte [rsi+5],':'
 jne .invalid
 jmp .ok
.datetime:
 mov al,'T'
 jmp .find_byte
.email:
 cmp byte [rsi],'@'
 je .invalid
 cmp byte [rsi+rdx-1],'@'
 je .invalid
 mov al,'@'
 jmp .find_byte
.url:
 cmp rdx,7
 jb .invalid
 cmp dword [rsi],0x70747468
 jne .invalid
 cmp byte [rsi+4],':'
 je .url_http
 cmp rdx,8
 jb .invalid
 cmp byte [rsi+4],'s'
 jne .invalid
 cmp byte [rsi+5],':'
 jne .invalid
 cmp byte [rsi+6],'/'
 jne .invalid
 cmp byte [rsi+7],'/'
 jne .invalid
 jmp .ok
.url_http:
 cmp byte [rsi+5],'/'
 jne .invalid
 cmp byte [rsi+6],'/'
 jne .invalid
 jmp .ok
.path:
 mov al,[rsi]
 cmp al,'/'
 je .ok
 cmp al,'.'
 jne .invalid
 jmp .ok
.password:
 cmp rdx,8
 jb .invalid
 jmp .ok
.json:
 mov al,[rsi]
 mov cl,[rsi+rdx-1]
 cmp al,'{'
 jne .json_array
 cmp cl,'}'
 jne .invalid
 jmp .ok
.json_array:
 cmp al,'['
 jne .invalid
 cmp cl,']'
 jne .invalid
.ok: xor eax,eax
 ret
.limit: mov eax,-SCAN_E_LIMIT
 ret
.invalid: mov eax,-SCAN_E_VALIDATE
 ret

; RDI policy, RSI input length, RDX default, RCX fallback, R8 output -> status.
nebo_g075_empty_resolve:
 test r8,r8
 jz .invalid
 cmp rdi,G075_EMPTY_REQUIRED
 jb .invalid
 cmp rdi,G075_EMPTY_AS_NONE
 ja .invalid
 test rsi,rsi
 jnz .present
 cmp rdi,G075_EMPTY_REQUIRED
 je .required
 cmp rdi,G075_EMPTY_DEFAULT
 je .default
 cmp rdi,G075_EMPTY_FALLBACK
 je .fallback
 mov qword [r8],0
 xor eax,eax
 ret
.default: mov [r8],rdx
 xor eax,eax
 ret
.fallback: mov [r8],rcx
 xor eax,eax
 ret
.present: mov [r8],rsi
 xor eax,eax
 ret
.required: mov eax,-SCAN_E_VALIDATE
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

; RDI operation, RSI source, RDX length, RCX output, R8 capacity -> length/error.
; Normalization is deliberately ASCII/UTF-8-Latin bounded and locale-free.
nebo_g075_normalize:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 cmp rbx,G075_NORM_TRIM
 jb .invalid
 cmp rbx,G075_NORM_CHOMP
 ja .invalid
 test r12,r12
 jz .invalid
 test r14,r14
 jz .invalid
 cmp r13,G075_BUFFER_MAX
 ja .limit
 xor r9d,r9d
 mov r10,r13
 cmp rbx,G075_NORM_CHOMP
 jne .left
 test r10,r10
 jz .measure
 cmp byte [r12+r10-1],10
 jne .measure
 dec r10
 test r10,r10
 jz .measure
 cmp byte [r12+r10-1],13
 jne .measure
 dec r10
 jmp .measure
.left:
 cmp rbx,G075_NORM_TRIM
 je .trim_left
 cmp rbx,G075_NORM_TRIM_START
 je .trim_left
 jmp .right
.trim_left:
 cmp r9,r10
 jae .right
 mov al,[r12+r9]
 cmp al,' '
 je .left_inc
 cmp al,9
 jne .right
.left_inc: inc r9
 jmp .trim_left
.right:
 cmp rbx,G075_NORM_TRIM
 je .trim_right
 cmp rbx,G075_NORM_TRIM_END
 jne .measure
.trim_right:
 cmp r10,r9
 jbe .measure
 mov al,[r12+r10-1]
 cmp al,' '
 je .right_dec
 cmp al,9
 jne .measure
.right_dec: dec r10
 jmp .trim_right
.measure:
 ; All supported transforms are non-expanding; validating source length before
 ; writes preserves failure atomicity for the output buffer.
 mov rax,r10
 sub rax,r9
 cmp rax,r15
 ja .capacity
 xor r8d,r8d
 xor r11d,r11d
.write:
 cmp r9,r10
 jae .written
 movzx eax,byte [r12+r9]
 cmp rbx,G075_NORM_SPACES
 je .spaces
 cmp rbx,G075_NORM_SLUG
 je .slug
 cmp rbx,G075_NORM_STRIP
 je .accent
 cmp rbx,G075_NORM_LOWER
 je .lower
 cmp rbx,G075_NORM_UPPER
 je .upper
 cmp rbx,G075_NORM_CAPITALIZE
 jne .store
 test r9,r9
 jnz .store
 cmp al,'a'
 jb .capitalize_done
 cmp al,'z'
 ja .capitalize_done
 sub al,32
.capitalize_done: jmp .store
.lower:
 cmp al,'A'
 jb .store
 cmp al,'Z'
 ja .store
 add al,32
 jmp .store
.upper:
 cmp al,'a'
 jb .store
 cmp al,'z'
 ja .store
 sub al,32
 jmp .store
.spaces:
 cmp al,' '
 je .space_emit
 cmp al,9
 jne .nonspace
.space_emit:
 test r8d,r8d
 jnz .next
 mov r8d,1
 mov al,' '
 jmp .store
.nonspace: xor r8d,r8d
 jmp .store
.slug:
 cmp al,' '
 je .slug_sep
 cmp al,9
 je .slug_sep
 cmp al,'A'
 jb .slug_char
 cmp al,'Z'
 ja .slug_char
 add al,32
.slug_char:
 cmp al,'0'
 jb .slug_letter
 cmp al,'9'
 jbe .slug_keep
.slug_letter:
 cmp al,'a'
 jb .slug_accent
 cmp al,'z'
 jbe .slug_keep
.slug_accent:
 cmp al,0xc3
 je .accent
 jmp .next
.slug_keep: xor r8d,r8d
 jmp .store
.slug_sep:
 test r11,r11
 jz .next
 test r8d,r8d
 jnz .next
 mov r8d,1
 mov al,'-'
 jmp .store
.accent:
 ; UTF-8 Latin-1 acute/grave/circumflex/diaeresis subset.
 cmp al,0xc3
 jne .accent_ascii
 lea rax,[r9+1]
 cmp rax,r10
 jae .next
 movzx eax,byte [r12+r9+1]
 cmp al,0xa0
 jb .next
 cmp al,0xa5
 jbe .accent_a
 cmp al,0xa8
 jb .accent_e_check
 cmp al,0xab
 jbe .accent_e
.accent_e_check:
 cmp al,0xa8
 jb .accent_i_check
.accent_i_check:
 cmp al,0xac
 jb .accent_o_check
 cmp al,0xaf
 jbe .accent_i
.accent_o_check:
 cmp al,0xb2
 jb .accent_u_check
 cmp al,0xb6
 jbe .accent_o
.accent_u_check:
 cmp al,0xb9
 jb .next
 cmp al,0xbc
 ja .next
 mov al,'u'
 jmp .accent_commit
.accent_a: mov al,'a'
 jmp .accent_commit
.accent_e: mov al,'e'
 jmp .accent_commit
.accent_i: mov al,'i'
 jmp .accent_commit
.accent_o: mov al,'o'
.accent_commit: inc r9
 cmp rbx,G075_NORM_SLUG
 jne .store
 xor r8d,r8d
 jmp .store
.accent_ascii:
 cmp rbx,G075_NORM_SLUG
 jne .store
 jmp .next
.store:
 mov [r14+r11],al
 inc r11
.next: inc r9
 jmp .write
.written:
 cmp rbx,G075_NORM_SLUG
 jne .return_length
 test r11,r11
 jz .return_length
 cmp byte [r14+r11-1],'-'
 jne .return_length
 dec r11
.return_length: mov rax,r11
 jmp .done
.capacity: mov rax,-SCAN_E_CAPACITY
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

; EDI subgroup mode, ESI explicit deterministic seed -> seed or typed error.
nebo_g075_source_probe:
 cmp edi,1
 jb .invalid
 cmp edi,6
 ja .invalid
 cmp esi,G075_SEED_MIN
 jb .invalid
 push rbx
 push r12
 mov ebx,edi
 mov r12d,esi
 lea rdi,[rel g75_probe_state]
 mov esi,SCAN_KIND_TEXT
 mov edx,SCAN_FLAG_REQUIRED
 mov ecx,11
 mov r8d,29
 call nebo_g075_plan_init
 test eax,eax
 jnz .done
 cmp ebx,1
 je .types
 cmp ebx,2
 je .empty
 cmp ebx,3
 je .normalize
 cmp ebx,4
 je .abi
 cmp ebx,5
 je .diagnostic
 mov edi,7506
 mov esi,SCAN_KIND_JSON
 mov edx,SCAN_FLAG_OPTIONAL
 mov ecx,64
 mov r8d,2
 mov r9d,SCAN_SOURCE_MOCK
 call neboc_scan_feature_validate
 test eax,eax
 jnz .done
 jmp .success
.types:
 mov edi,SCAN_KIND_EMAIL
 lea rsi,[rel g75_email]
 mov edx,g75_email_len
 call nebo_g075_validate_kind
 test eax,eax
 jnz .done
 jmp .success
.empty:
 mov edi,G075_EMPTY_DEFAULT
 xor esi,esi
 mov edx,17
 mov ecx,23
 lea r8,[rel g75_probe_word]
 call nebo_g075_empty_resolve
 test eax,eax
 jnz .done
 cmp qword [rel g75_probe_word],17
 jne .invalid_pop
 jmp .success
.normalize:
 mov edi,G075_NORM_SLUG
 lea rsi,[rel g75_slug_input]
 mov edx,g75_slug_input_len
 lea rcx,[rel g75_probe_output]
 mov r8d,G075_BUFFER_MAX
 call nebo_g075_normalize
 cmp eax,9
 jne .invalid_pop
 jmp .success
.abi:
 mov edi,7504
 mov esi,SCAN_KIND_TEXT
 mov edx,SCAN_FLAG_REQUIRED|SCAN_FLAG_TRIM
 mov ecx,128
 mov r8d,1
 mov r9d,SCAN_SOURCE_MOCK
 call neboc_scan_feature_validate
 test eax,eax
 jnz .done
 jmp .success
.diagnostic:
 lea rdi,[rel g75_probe_state]
 mov esi,SCAN_KIND_INT
 mov edx,SCAN_FLAG_REQUIRED|SCAN_FLAG_OPTIONAL
 mov ecx,31
 mov r8d,19
 call nebo_g075_plan_init
 cmp eax,-SCAN_E_INVALID
 jne .invalid_pop
.success: mov eax,r12d
.done:
 pop r12
 pop rbx
 ret
.invalid_pop: mov eax,-SCAN_E_VALIDATE
 jmp .done
.invalid: mov eax,-SCAN_E_INVALID
 ret

nebo_g075_negative_probe:
 lea rdi,[rel g75_probe_state]
 mov esi,SCAN_KIND_TEXT
 mov edx,SCAN_FLAG_REQUIRED|SCAN_FLAG_OPTIONAL
 xor ecx,ecx
 xor r8d,r8d
 jmp nebo_g075_plan_init

; EDI mode -> bytes written to stdout or typed error.
nebo_g075_render_transcript:
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
.s1: lea rsi,[rel g75_s1]
 mov edx,g75_s1_len
 jmp .write
.s2: lea rsi,[rel g75_s2]
 mov edx,g75_s2_len
 jmp .write
.s3: lea rsi,[rel g75_s3]
 mov edx,g75_s3_len
 jmp .write
.s4: lea rsi,[rel g75_s4]
 mov edx,g75_s4_len
 jmp .write
.s5: lea rsi,[rel g75_s5]
 mov edx,g75_s5_len
 jmp .write
.s6: lea rsi,[rel g75_s6]
 mov edx,g75_s6_len
.write:
 mov eax,1
 mov edi,1
 syscall
 ret
