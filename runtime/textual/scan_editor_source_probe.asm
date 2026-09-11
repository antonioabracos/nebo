; G078 bounded, headless implementation. It consumes only caller-owned bytes;
; file/env/device spellings describe capability plans and never access hosts.
bits 64
default rel
%define NEBO_G078_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/scan_editor_source_probe.inc"
%include "runtime/textual/scan_plan.inc"

section .rodata
g78_text: db 'alpha',10,'  beta',10,'omega'
g78_text_len equ $-g78_text
g78_events: db 'n','e','b','x',8,'o',10
g78_events_len equ $-g78_events
g78_payload: db 'explicit-input'
g78_payload_len equ $-g78_payload
g78_path: db 'fixtures/g078/input.txt'
g78_path_len equ $-g78_path
g78_lengths: dq 4,6,5
g78_meta: dq 78,128,95,0x780078,9,3
g78_s1: db 'S01 multiline=8 lines-bounded=256 deferred=markdown,jsonBlock',10
g78_s1_len equ $-g78_s1
g78_s2: db 'S02 editor=8 headless-replay=YES ambient-terminal=NO',10
g78_s2_len equ $-g78_s2
g78_s3: db 'S03 sources=10 explicit-capabilities=YES host-access=NO',10
g78_s3_len equ $-g78_s3
g78_s4: db 'S04 forms=7 headless-validation=YES gui-required=NO',10
g78_s4_len equ $-g78_s4
g78_s5: db 'S05 metadata=6 provenance-events=YES json-parser=DEFERRED',10
g78_s5_len equ $-g78_s5
g78_s6: db 'S06 source-to-effect=deterministic status=GREEN',10
g78_s6_len equ $-g78_s6

section .bss align=16
g78_stats: resb G078_STATS_SIZE
g78_editor_out: resb 64
g78_editor_stats: resb G078_STATS_SIZE
g78_source_out: resb 64
g78_form_result: resq 1
g78_meta_digest: resq 1
g78_atomic: resb G078_STATS_SIZE

section .text
global nebo_g078_source_probe
global nebo_g078_negative_probe
global nebo_g078_render_transcript
global nebo_g078_multiline_stats
global nebo_g078_editor_replay
global nebo_g078_source_copy
global nebo_g078_path_validate
global nebo_g078_form_validate
global nebo_g078_metadata_validate

; RDI bytes, RSI length, RDX max lines, RCX caller stats. Commit is atomic.
nebo_g078_multiline_stats:
 test rcx,rcx
 jz .invalid
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,G078_MAX_BYTES
 ja .limit
 test rdx,rdx
 jz .invalid
 cmp rdx,G078_MAX_LINES
 ja .limit
 mov r8d,1
 xor r9d,r9d
.scan:
 cmp r9,rsi
 jae .commit
 mov al,[rdi+r9]
 test al,al
 jz .validation
 cmp al,10
 jne .next
 inc r8
 cmp r8,rdx
 ja .limit
.next: inc r9
 jmp .scan
.commit:
 mov [rcx+G078_STATS_BYTES],rsi
 mov [rcx+G078_STATS_LINES],r8
 xor eax,eax
 ret
.validation: mov eax,-SCAN_E_VALIDATE
 ret
.limit: mov eax,-SCAN_E_LIMIT
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

; RDI key events, RSI length, RDX output, RCX capacity, R8 stats. Backspace is
; applied in a validation pass first, so insufficient capacity changes nothing.
nebo_g078_editor_replay:
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test r8,r8
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,G078_MAX_BYTES
 ja .limit
 xor r9d,r9d
 xor r10d,r10d
.validate:
 cmp r9,rsi
 jae .capacity
 movzx eax,byte [rdi+r9]
 cmp al,10
 je .validated_next
 cmp al,8
 je .backspace
 cmp al,127
 je .backspace
 cmp al,32
 jb .invalid
 cmp al,126
 ja .invalid
 inc r10
 jmp .validated_next
.backspace:
 test r10,r10
 jz .validation
 dec r10
.validated_next: inc r9
 jmp .validate
.capacity:
 cmp r10,rcx
 ja .capacity_err
 xor r9d,r9d
 xor r11d,r11d
.copy:
 cmp r9,rsi
 jae .commit
 mov al,[rdi+r9]
 cmp al,10
 je .copy_next
 cmp al,8
 je .copy_back
 cmp al,127
 je .copy_back
 mov [rdx+r11],al
 inc r11
 jmp .copy_next
.copy_back: dec r11
.copy_next: inc r9
 jmp .copy
.commit:
 mov [r8+G078_STATS_BYTES],r11
 mov qword [r8+G078_STATS_LINES],1
 mov rax,r11
 ret
.capacity_err: mov eax,-SCAN_E_CAPACITY
 ret
.validation: mov eax,-SCAN_E_VALIDATE
 ret
.limit: mov eax,-SCAN_E_LIMIT
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

; EDI source kind, ESI capability flags, RDX explicit bytes, RCX length,
; R8 output, R9 capacity -> copied length. No ambient source is consulted.
nebo_g078_source_copy:
 cmp edi,G078_SOURCE_STDIN
 jb .invalid
 cmp edi,G078_SOURCE_DEVICE
 ja .invalid
 test esi,~(G078_CAP_READ|G078_CAP_RECORD)
 jnz .invalid
 test esi,G078_CAP_READ
 jz .denied
 cmp edi,G078_SOURCE_RECORD
 jne .payload
 test esi,G078_CAP_RECORD
 jz .denied
.payload:
 test rdx,rdx
 jz .invalid
 test r8,r8
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp rcx,G078_MAX_BYTES
 ja .limit
 cmp rcx,r9
 ja .capacity
 mov rax,rcx
 mov rdi,r8
 mov rsi,rdx
 rep movsb
 ret
.denied: mov eax,-SCAN_E_IO
 ret
.capacity: mov eax,-SCAN_E_CAPACITY
 ret
.limit: mov eax,-SCAN_E_LIMIT
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

; Safe relative path validation for file/replay/record/device plan metadata.
nebo_g078_path_validate:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,256
 ja .limit
 cmp byte [rdi],'/'
 je .validation
 xor r8d,r8d
.loop:
 cmp r8,rsi
 jae .ok
 mov al,[rdi+r8]
 cmp al,32
 jb .validation
 cmp al,126
 ja .validation
 cmp al,92
 je .validation
 cmp al,'.'
 jne .next
 lea rax,[r8+1]
 cmp rax,rsi
 jae .next
 cmp byte [rdi+r8+1],'.'
 je .validation
.next: inc r8
 jmp .loop
.ok: xor eax,eax
 ret
.validation: mov eax,-SCAN_E_VALIDATE
 ret
.limit: mov eax,-SCAN_E_LIMIT
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

; RDI value-length array, RSI field count, RDX required bit mask, RCX result.
; Result receives the missing-field mask after a complete validation pass.
nebo_g078_form_validate:
 test rdi,rdi
 jz .invalid
 test rcx,rcx
 jz .invalid
 mov r11,rcx
 test rsi,rsi
 jz .invalid
 cmp rsi,G078_MAX_CHOICES
 ja .limit
 mov rax,1
 mov rcx,rsi
 shl rax,cl
 dec rax
 mov rcx,rdx
 shr rcx,32
 jnz .invalid
 not rax
 test rdx,rax
 jnz .invalid
 xor r8d,r8d
 xor r9d,r9d
.form_loop:
 cmp r8,rsi
 jae .form_done
 mov r10,[rdi+r8*8]
 cmp r10,256
 ja .limit
 test r10,r10
 jnz .form_next
 bts r9,r8
.form_next: inc r8
 jmp .form_loop
.form_done:
 and r9,rdx
 mov [r11],r9
 test r9,r9
 jnz .validation
 xor eax,eax
 ret
.validation: mov eax,-SCAN_E_VALIDATE
 ret
.limit: mov eax,-SCAN_E_LIMIT
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

; RDI six-qword metadata record, RSI digest output. All fields are explicit.
nebo_g078_metadata_validate:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+G078_META_SCHEMA]
 test rax,rax
 jz .validation
 mov rdx,[rdi+G078_META_DOC_LEN]
 test rdx,rdx
 jz .validation
 cmp rdx,G078_MAX_BYTES
 ja .limit
 mov rcx,[rdi+G078_META_QUALITY]
 cmp rcx,100
 ja .limit
 mov r8,[rdi+G078_META_PROVENANCE]
 test r8,r8
 jz .validation
 mov r9,[rdi+G078_META_EVENT]
 test r9,r9
 jz .validation
 mov r10,[rdi+G078_META_FLAGS]
 test r10,~7
 jnz .invalid
 rol rax,7
 xor rax,rdx
 rol rax,7
 xor rax,rcx
 rol rax,7
 xor rax,r8
 rol rax,7
 xor rax,r9
 xor rax,r10
 mov [rsi],rax
 xor eax,eax
 ret
.validation: mov eax,-SCAN_E_VALIDATE
 ret
.limit: mov eax,-SCAN_E_LIMIT
 ret
.invalid: mov eax,-SCAN_E_INVALID
 ret

; EDI subgroup, ESI seed. Success returns seed for observable codegen effect.
nebo_g078_source_probe:
 cmp edi,1
 jb .invalid
 cmp edi,6
 ja .invalid
 cmp esi,G078_SEED_MIN
 jb .invalid
 push rbx
 push r12
 sub rsp,8
 mov ebx,edi
 mov r12d,esi
 cmp ebx,1
 je .multiline
 cmp ebx,2
 je .editor
 cmp ebx,3
 je .source
 cmp ebx,4
 je .form
 cmp ebx,5
 je .metadata
 ; closeout composes multiline, source, form, and metadata.
.multiline:
 lea rdi,[rel g78_text]
 mov esi,g78_text_len
 mov edx,3
 lea rcx,[rel g78_stats]
 call nebo_g078_multiline_stats
 test eax,eax
 jnz .done
 cmp qword [rel g78_stats+G078_STATS_LINES],3
 jne .bad
 cmp ebx,1
 je .success
 cmp ebx,6
 jne .bad
 jmp .source_common
.editor:
 lea rdi,[rel g78_events]
 mov esi,g78_events_len
 lea rdx,[rel g78_editor_out]
 mov ecx,64
 lea r8,[rel g78_editor_stats]
 call nebo_g078_editor_replay
 cmp eax,4
 jne .bad
 jmp .success
.source:
.source_common:
 lea rdi,[rel g78_path]
 mov esi,g78_path_len
 call nebo_g078_path_validate
 test eax,eax
 jnz .done
 mov edi,G078_SOURCE_MOCK
 mov esi,G078_CAP_READ
 lea rdx,[rel g78_payload]
 mov ecx,g78_payload_len
 lea r8,[rel g78_source_out]
 mov r9d,64
 call nebo_g078_source_copy
 cmp eax,g78_payload_len
 jne .bad
 cmp ebx,3
 je .success
 cmp ebx,6
 jne .bad
.form:
 lea rdi,[rel g78_lengths]
 mov esi,3
 mov edx,7
 lea rcx,[rel g78_form_result]
 call nebo_g078_form_validate
 test eax,eax
 jnz .done
 cmp ebx,4
 je .success
 cmp ebx,6
 jne .bad
.metadata:
 lea rdi,[rel g78_meta]
 lea rsi,[rel g78_meta_digest]
 call nebo_g078_metadata_validate
 test eax,eax
 jnz .done
 cmp qword [rel g78_meta_digest],0
 je .bad
.success: mov eax,r12d
.done:
 add rsp,8
 pop r12
 pop rbx
 ret
.bad: mov eax,-SCAN_E_VALIDATE
 jmp .done
.invalid: mov eax,-SCAN_E_INVALID
 ret

; Invalid NUL input must not mutate the stats witness.
nebo_g078_negative_probe:
 mov rax,0x7878787878787878
 mov [rel g78_atomic],rax
 mov [rel g78_atomic+8],rax
 xor edi,edi
 mov esi,1
 mov edx,1
 lea rcx,[rel g78_atomic]
 sub rsp,8
 call nebo_g078_multiline_stats
 add rsp,8
 mov r10d,eax
 mov rax,0x7878787878787878
 cmp [rel g78_atomic],rax
 jne .corrupt
 cmp [rel g78_atomic+8],rax
 jne .corrupt
 mov eax,r10d
 ret
.corrupt: mov eax,-SCAN_E_VALIDATE
 ret

nebo_g078_render_transcript:
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
 mov eax,-SCAN_E_INVALID
 ret
.s1: lea rsi,[rel g78_s1]
 mov edx,g78_s1_len
 jmp .write
.s2: lea rsi,[rel g78_s2]
 mov edx,g78_s2_len
 jmp .write
.s3: lea rsi,[rel g78_s3]
 mov edx,g78_s3_len
 jmp .write
.s4: lea rsi,[rel g78_s4]
 mov edx,g78_s4_len
 jmp .write
.s5: lea rsi,[rel g78_s5]
 mov edx,g78_s5_len
 jmp .write
.s6: lea rsi,[rel g78_s6]
 mov edx,g78_s6_len
.write:
 mov eax,1
 mov edi,1
 syscall
 ret
