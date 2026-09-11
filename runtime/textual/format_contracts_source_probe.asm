; G079 common bounded format layer. Concrete CSV/TSV/JSON/JSONL parsers are
; intentionally absent: values stay opaque while shared contracts, reports,
; schemas, capabilities, sampling and conversion mechanics are exercised.
bits 64
default rel
%define NEBO_G079_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/format_contracts_source_probe.inc"
%include "runtime/textual/format_data.inc"

section .rodata
g79_json: db '{"name":"nebo","count":79}'
g79_json_len equ $-g79_json
g79_plain: db '  bounded value  ',13,10
g79_plain_len equ $-g79_plain
g79_path: db 'fixtures/g079/value.data'
g79_path_len equ $-g79_path
g79_formula: db '=SUM(A1:A2)'
g79_formula_len equ $-g79_formula
g79_s1: db 'S01 registry=closed capabilities=explicit status=GREEN',10
g79_s1_len equ $-g79_s1
g79_s2: db 'S02 reports=atomic errors=structured warnings=structured',10
g79_s2_len equ $-g79_s2
g79_s3: db 'S03 schema=bounded compatibility=deterministic status=GREEN',10
g79_s3_len equ $-g79_s3
g79_s4: db 'S04 options=validated limits=4096,256,64,32 status=GREEN',10
g79_s4_len equ $-g79_s4
g79_s5: db 'S05 detection=advisory sample=bounded certainty=NO',10
g79_s5_len equ $-g79_s5
g79_s6: db 'S06 io=capability-plan ambient-access=NO atomic-output=YES',10
g79_s6_len equ $-g79_s6
g79_s7: db 'S07 convert=opaque pretty=canonical sanitize=bounded',10
g79_s7_len equ $-g79_s7
g79_s8: db 'S08 composition=8 source-to-effect=PASS open-findings=0',10
g79_s8_len equ $-g79_s8

section .bss align=16
g79_report: resb G079_REPORT_SIZE
g79_options: resb G079_OPTIONS_SIZE
g79_detection: resb G079_DETECTION_SIZE
g79_schema: resb G079_SCHEMA_SIZE
g79_output: resb G079_MAX_BYTES+8
g79_atomic: resb G079_REPORT_SIZE

section .text
global nebo_g079_source_probe
global nebo_g079_negative_probe
global nebo_g079_render_transcript
global nebo_g079_registry_lookup
global nebo_g079_report_add
global nebo_g079_schema_validate
global nebo_g079_options_validate
global nebo_g079_detect
global nebo_g079_sample
global nebo_g079_path_validate
global nebo_g079_transform
global nebo_g079_infer_schema
global nebo_g079_sanitize

; EDI kind, ESI capability mask, EDX registry version -> stable descriptor.
nebo_g079_registry_lookup:
 mov r8d,edi
 mov r9d,esi
 mov r10d,edx
 mov edi,r8d
 call format_validate_kind
 test eax,eax
 jnz .invalid
 test r9d,r9d
 jz .invalid
 test r9d,~G079_CAP_ALL
 jnz .invalid
 cmp r10d,1
 jne .unsupported
 mov eax,r8d
 shl rax,32
 mov edx,r9d
 shl rdx,8
 or rax,rdx
 or rax,r10
 ret
.unsupported: mov rax,-FMT_UNSUPPORTED
 ret
.invalid: mov rax,-FMT_INVALID
 ret

; RDI report, ESI severity, EDX code, RCX offset, R8D line, R9D column.
; All fields are validated before any caller-owned state is committed.
nebo_g079_report_add:
 test rdi,rdi
 jz .invalid
 cmp esi,G079_SEVERITY_ERROR
 je .severity_ok
 cmp esi,G079_SEVERITY_WARNING
 jne .invalid
.severity_ok:
 test edx,edx
 jz .invalid
 test r8d,r8d
 jz .invalid
 test r9d,r9d
 jz .invalid
 mov r10,[rdi+G079_REPORT_ERRORS]
 mov r11,[rdi+G079_REPORT_WARNINGS]
 cmp esi,G079_SEVERITY_ERROR
 jne .warning
 inc r10
 jmp .commit
.warning: inc r11
.commit:
 mov [rdi+G079_REPORT_ERRORS],r10
 mov [rdi+G079_REPORT_WARNINGS],r11
 mov [rdi+G079_REPORT_LAST_CODE],rdx
 mov [rdi+G079_REPORT_LAST_OFFSET],rcx
 mov r10d,r8d
 shl r10,32
 mov eax,r9d
 or r10,rax
 mov rax,r10
 mov [rdi+G079_REPORT_LAST_POSITION],rax
 xor eax,eax
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; EDI schema fields, ESI value fields, EDX schema mask, ECX value mask,
; R8 output schema. Compatible values atomically publish bounded metadata.
nebo_g079_schema_validate:
 test r8,r8
 jz .invalid
 test edi,edi
 jz .invalid
 cmp edi,G079_MAX_FIELDS
 ja .limit
 cmp esi,edi
 jne .conflict
 mov eax,ecx
 and eax,edx
 cmp eax,edx
 jne .conflict
 mov [r8+G079_SCHEMA_FIELDS],rdi
 mov [r8+G079_SCHEMA_TYPE_MASK],rdx
 mov rax,0x473037390001
 mov [r8+G079_SCHEMA_LINEAGE],rax
 xor eax,eax
 ret
.conflict: mov eax,-FMT_CONFLICT
 ret
.limit: mov eax,-FMT_LIMIT
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; RDI options record. Limits and capability bits are closed and finite.
nebo_g079_options_validate:
 test rdi,rdi
 jz .invalid
 push rbx
 mov rbx,rdi
 mov r8,[rdi+G079_OPTIONS_BYTES]
 mov r9,[rdi+G079_OPTIONS_RECORDS]
 mov r10,[rdi+G079_OPTIONS_FIELDS]
 mov r11,[rdi+G079_OPTIONS_DEPTH]
 mov rdi,r8
 mov rsi,r9
 mov rdx,r10
 mov rcx,r11
 call format_check_limits
 test eax,eax
 jnz .limit_saved
 mov rax,[rbx+G079_OPTIONS_CAPS]
 test rax,rax
 jz .invalid_saved
 test rax,~G079_CAP_ALL
 jnz .invalid_saved
 xor eax,eax
 pop rbx
 ret
.limit_saved: mov eax,-FMT_LIMIT
 pop rbx
 ret
.invalid_saved: mov eax,-FMT_INVALID
 pop rbx
 ret
.limit: mov eax,-FMT_LIMIT
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; RDI bytes, RSI length, RDX detection record. Advisory result only.
nebo_g079_detect:
 test rdx,rdx
 jz .invalid
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,G079_MAX_BYTES
 ja .limit
 push rbx
 push r12
 mov rbx,rdx
 mov r12,rsi
 call format_detect
 test eax,eax
 jz .unknown
 mov [rbx+G079_DETECTION_KIND],rax
 mov [rbx+G079_DETECTION_CONFIDENCE],rdx
 mov [rbx+G079_DETECTION_SAMPLE_BYTES],r12
 xor eax,eax
 pop r12
 pop rbx
 ret
.unknown: pop r12
 pop rbx
 mov eax,-FMT_NOT_FOUND
 ret
.limit: mov eax,-FMT_LIMIT
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; RDI source, RSI length, RDX requested count, RCX output, R8 capacity.
nebo_g079_sample:
 test rdi,rdi
 jz .invalid
 test rcx,rcx
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,G079_MAX_BYTES
 ja .limit
 cmp rdx,rsi
 cmova rdx,rsi
 cmp rdx,r8
 ja .capacity
 mov rax,rdx
 mov rsi,rdi
 mov rdi,rcx
 mov rcx,rax
 rep movsb
 ret
.capacity: mov eax,-FMT_CAPACITY
 ret
.limit: mov eax,-FMT_LIMIT
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; Safe relative metadata for read/write/stream plans; no host access occurs.
nebo_g079_path_validate:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,256
 ja .limit
 cmp byte [rdi],'/'
 je .denied
 xor r8d,r8d
.loop:
 cmp r8,rsi
 jae .ok
 mov al,[rdi+r8]
 cmp al,32
 jb .denied
 cmp al,126
 ja .denied
 cmp al,92
 je .denied
 cmp al,'.'
 jne .next
 lea rax,[r8+1]
 cmp rax,rsi
 jae .next
 cmp byte [rdi+r8+1],'.'
 je .denied
.next: inc r8
 jmp .loop
.ok: xor eax,eax
 ret
.denied: mov eax,-FMT_CONFLICT
 ret
.limit: mov eax,-FMT_LIMIT
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; EDI operation, ESI caps, RDX input, RCX len, R8 output, R9 capacity.
; read/write/stream are explicit caller-data plans and require capabilities.
nebo_g079_transform:
 cmp edi,G079_OP_PARSE
 jb .invalid
 cmp edi,G079_OP_TO_BYTES
 ja .invalid
 test esi,~G079_CAP_ALL
 jnz .invalid
 cmp edi,G079_OP_READ
 jne .stream_check
 test esi,G079_CAP_READ
 jz .denied
.stream_check:
 cmp edi,G079_OP_STREAM
 jne .write_check
 mov eax,G079_CAP_READ|G079_CAP_STREAM
 and eax,esi
 cmp eax,G079_CAP_READ|G079_CAP_STREAM
 jne .denied
.write_check:
 cmp edi,G079_OP_WRITE
 jne .convert_check
 test esi,G079_CAP_WRITE
 jz .denied
.convert_check:
 cmp edi,G079_OP_TO_TEXT
 jb .payload
 test esi,G079_CAP_CONVERT
 jz .denied
.payload:
 test rdx,rdx
 jz .invalid
 test r8,r8
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp rcx,G079_MAX_BYTES
 ja .limit
 cmp rcx,r9
 ja .capacity
 mov rax,rcx
 mov rdi,r8
 mov rsi,rdx
 rep movsb
 ret
.denied: mov eax,-FMT_CONFLICT
 ret
.capacity: mov eax,-FMT_CAPACITY
 ret
.limit: mov eax,-FMT_LIMIT
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; RDI sample, RSI len, RDX output schema. Infers only bounded common metadata.
nebo_g079_infer_schema:
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,G079_MAX_BYTES
 ja .limit
 xor r8d,r8d
 xor r9d,r9d
.infer_loop:
 cmp r8,rsi
 jae .infer_commit
 mov al,[rdi+r8]
 test al,al
 jz .invalid
 cmp al,','
 je .separator
 cmp al,9
 jne .infer_next
.separator: inc r9
.infer_next: inc r8
 jmp .infer_loop
.infer_commit:
 inc r9
 cmp r9,G079_MAX_FIELDS
 ja .limit
 mov [rdx+G079_SCHEMA_FIELDS],r9
 mov qword [rdx+G079_SCHEMA_TYPE_MASK],1
 mov rax,0x473037390002
 mov [rdx+G079_SCHEMA_LINEAGE],rax
 xor eax,eax
 ret
.limit: mov eax,-FMT_LIMIT
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; RDI src, RSI len, RDX dst, RCX capacity, R8 policy (1 spreadsheet-safe).
nebo_g079_sanitize:
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,G079_MAX_BYTES
 ja .limit
 mov r9,rsi
 xor r10d,r10d
 cmp r8,1
 jne .validate
 mov al,[rdi]
 cmp al,'='
 je .quote
 cmp al,'+'
 je .quote
 cmp al,'-'
 je .quote
 cmp al,'@'
 jne .validate
.quote: mov r10d,1
.validate:
 mov r11,r10
 add r11,rsi
 cmp r11,rcx
 ja .capacity
 xor ecx,ecx
.validate_loop:
 cmp rcx,rsi
 jae .copy
 mov al,[rdi+rcx]
 test al,al
 jz .invalid
 cmp al,9
 je .validate_next
 cmp al,10
 je .validate_next
 cmp al,13
 je .validate_next
 cmp al,32
 jb .invalid
.validate_next: inc rcx
 jmp .validate_loop
.copy:
 test r10,r10
 jz .copy_payload
 mov byte [rdx],39
 inc rdx
.copy_payload:
 mov rcx,rsi
 mov rsi,rdi
 mov rdi,rdx
 rep movsb
 mov rax,r11
 ret
.capacity: mov eax,-FMT_CAPACITY
 ret
.limit: mov eax,-FMT_LIMIT
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; EDI subgroup mode, ESI seed -> deterministic observable process value.
nebo_g079_source_probe:
 push r12
 push r13
 cmp edi,1
 jb .invalid
 cmp edi,8
 ja .invalid
 cmp esi,G079_SEED_MIN
 jb .invalid
 mov r12d,edi
 mov r13d,esi
 cmp r12d,1
 je .s1
 cmp r12d,2
 je .s2
 cmp r12d,3
 je .s3
 cmp r12d,4
 je .s4
 cmp r12d,5
 je .s5
 cmp r12d,6
 je .s6
 cmp r12d,7
 je .s7
 jmp .s8
.s1:
 mov edi,FMT_JSON
 mov esi,G079_CAP_READ|G079_CAP_DETECT
 mov edx,1
 call nebo_g079_registry_lookup
 test rax,rax
 js .invalid
 jmp .effect
.s2:
 lea rdi,[rel g79_report]
 mov esi,G079_SEVERITY_WARNING
 mov edx,79
 mov ecx,4
 mov r8d,2
 mov r9d,5
 call nebo_g079_report_add
 test eax,eax
 jnz .invalid
 jmp .effect
.s3:
 mov edi,2
 mov esi,2
 mov edx,3
 mov ecx,7
 lea r8,[rel g79_schema]
 call nebo_g079_schema_validate
 test eax,eax
 jnz .invalid
 jmp .effect
.s4:
 mov qword [rel g79_options+G079_OPTIONS_BYTES],4096
 mov qword [rel g79_options+G079_OPTIONS_RECORDS],256
 mov qword [rel g79_options+G079_OPTIONS_FIELDS],64
 mov qword [rel g79_options+G079_OPTIONS_DEPTH],32
 mov qword [rel g79_options+G079_OPTIONS_CAPS],G079_CAP_ALL
 lea rdi,[rel g79_options]
 call nebo_g079_options_validate
 test eax,eax
 jnz .invalid
 jmp .effect
.s5:
 lea rdi,[rel g79_json]
 mov esi,g79_json_len
 lea rdx,[rel g79_detection]
 call nebo_g079_detect
 test eax,eax
 jnz .invalid
 lea rdi,[rel g79_json]
 mov esi,g79_json_len
 mov edx,8
 lea rcx,[rel g79_output]
 mov r8d,G079_MAX_BYTES
 call nebo_g079_sample
 test rax,rax
 js .invalid
 jmp .effect
.s6:
 mov edi,G079_OP_PARSE
 xor esi,esi
 lea rdx,[rel g79_plain]
 mov ecx,g79_plain_len
 lea r8,[rel g79_output]
 mov r9d,G079_MAX_BYTES
 call nebo_g079_transform
 test rax,rax
 js .invalid
 mov edi,G079_OP_READ
 mov esi,G079_CAP_READ
 lea rdx,[rel g79_plain]
 mov ecx,g79_plain_len
 lea r8,[rel g79_output]
 mov r9d,G079_MAX_BYTES
 call nebo_g079_transform
 test rax,rax
 js .invalid
 mov edi,G079_OP_STREAM
 mov esi,G079_CAP_READ|G079_CAP_STREAM
 lea rdx,[rel g79_plain]
 mov ecx,g79_plain_len
 lea r8,[rel g79_output]
 mov r9d,G079_MAX_BYTES
 call nebo_g079_transform
 test rax,rax
 js .invalid
 mov edi,G079_OP_WRITE
 mov esi,G079_CAP_WRITE
 lea rdx,[rel g79_plain]
 mov ecx,g79_plain_len
 lea r8,[rel g79_output]
 mov r9d,G079_MAX_BYTES
 call nebo_g079_transform
 test rax,rax
 js .invalid
 mov edi,G079_OP_TO_TEXT
 mov esi,G079_CAP_CONVERT
 lea rdx,[rel g79_plain]
 mov ecx,g79_plain_len
 lea r8,[rel g79_output]
 mov r9d,G079_MAX_BYTES
 call nebo_g079_transform
 test rax,rax
 js .invalid
 mov edi,G079_OP_TO_BYTES
 mov esi,G079_CAP_CONVERT
 lea rdx,[rel g79_plain]
 mov ecx,g79_plain_len
 lea r8,[rel g79_output]
 mov r9d,G079_MAX_BYTES
 call nebo_g079_transform
 test rax,rax
 js .invalid
 jmp .effect
.s7:
 mov edi,2
 mov esi,2
 mov edx,3
 mov ecx,7
 lea r8,[rel g79_schema]
 call nebo_g079_schema_validate
 test eax,eax
 jnz .invalid
 lea rdi,[rel g79_plain]
 mov esi,g79_plain_len
 lea rdx,[rel g79_schema]
 call nebo_g079_infer_schema
 test eax,eax
 jnz .invalid
 mov edi,G079_OP_TO_TEXT
 mov esi,G079_CAP_CONVERT
 lea rdx,[rel g79_plain]
 mov ecx,g79_plain_len
 lea r8,[rel g79_output]
 mov r9d,G079_MAX_BYTES
 call nebo_g079_transform
 test rax,rax
 js .invalid
 lea rdi,[rel g79_plain]
 mov esi,g79_plain_len
 lea rdx,[rel g79_output]
 mov ecx,G079_MAX_BYTES
 call format_normalize
 test eax,eax
 jnz .invalid
 lea rdi,[rel g79_formula]
 mov esi,g79_formula_len
 lea rdx,[rel g79_output]
 mov ecx,G079_MAX_BYTES
 mov r8d,1
 call nebo_g079_sanitize
 test rax,rax
 js .invalid
 jmp .effect
.s8:
 lea rdi,[rel g79_path]
 mov esi,g79_path_len
 call nebo_g079_path_validate
 test eax,eax
 jnz .invalid
.effect:
 mov eax,r13d
 mov edx,r12d
 shl edx,1
 add eax,edx
 rol eax,5
 and eax,255
 test eax,eax
 jnz .return
 mov eax,r12d
.return:
 pop r13
 pop r12
 ret
.invalid: mov eax,255
 pop r13
 pop r12
 ret

nebo_g079_negative_probe:
 lea rdi,[rel g79_atomic]
 mov r10,0x7979797979797979
 mov [rdi],r10
 xor esi,esi
 mov edx,1
 xor ecx,ecx
 mov r8d,1
 mov r9d,1
 call nebo_g079_report_add
 cmp eax,-FMT_INVALID
 jne .bad
 cmp [rel g79_atomic],r10
 jne .bad
 mov edi,21
 mov esi,G079_CAP_READ
 mov edx,1
 call nebo_g079_registry_lookup
 cmp rax,-FMT_INVALID
 jne .bad
 xor eax,eax
 ret
.bad: mov eax,1
 ret

nebo_g079_render_transcript:
 mov eax,1
 mov edi,1
 lea rsi,[rel g79_s1]
 mov edx,g79_s1_len
 syscall
 mov eax,1
 mov edi,1
 lea rsi,[rel g79_s2]
 mov edx,g79_s2_len
 syscall
 mov eax,1
 mov edi,1
 lea rsi,[rel g79_s3]
 mov edx,g79_s3_len
 syscall
 mov eax,1
 mov edi,1
 lea rsi,[rel g79_s4]
 mov edx,g79_s4_len
 syscall
 mov eax,1
 mov edi,1
 lea rsi,[rel g79_s5]
 mov edx,g79_s5_len
 syscall
 mov eax,1
 mov edi,1
 lea rsi,[rel g79_s6]
 mov edx,g79_s6_len
 syscall
 mov eax,1
 mov edi,1
 lea rsi,[rel g79_s7]
 mov edx,g79_s7_len
 syscall
 mov eax,1
 mov edi,1
 lea rsi,[rel g79_s8]
 mov edx,g79_s8_len
 syscall
 xor eax,eax
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
