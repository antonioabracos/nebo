; G103 canonical in-memory owner for the versioned headless JSONL protocol.
; The protocol is operational: it serializes existing Console/RenderPlan
; events without adding a public language method or trusting the consumer.
bits 64
default rel
%define NEBO_G103_HEADLESS_PROTOCOL_IMPLEMENTATION 1
%include "runtime/console/headless_protocol.inc"

global nebo_g103_validate_event
global nebo_g103_encode_event
global nebo_g103_decode_event
global nebo_g103_roundtrip_event
global nebo_g103_batch_encode
global nebo_g103_consume_batch
global nebo_g103_stream_append
global nebo_g103_event_name

section .rodata
g103_version_prefix: db '{"v":'
g103_version_prefix_len equ $-g103_version_prefix
g103_prefix: db '{"v":1,"seq":"'
g103_prefix_len equ $-g103_prefix
g103_mid_kind: db '","kind":"'
g103_mid_kind_len equ $-g103_mid_kind
g103_mid_region: db '","region":"'
g103_mid_region_len equ $-g103_mid_region
g103_mid_value: db '","value":"'
g103_mid_value_len equ $-g103_mid_value
g103_mid_flags: db '","flags":"'
g103_mid_flags_len equ $-g103_mid_flags
g103_suffix: db '"}',10
g103_suffix_len equ $-g103_suffix
g103_hex: db '0123456789abcdef'

%macro G103_NAME 2
g103_name_%1: db %2
g103_name_%1_len equ $-g103_name_%1
%endmacro
G103_NAME emit,'console.emit'
G103_NAME clear,'console.clear'
G103_NAME region,'console.region'
G103_NAME text,'console.text'
G103_NAME write,'console.write'
G103_NAME table,'console.table'
G103_NAME plot2d,'console.plot2d'
G103_NAME graph,'console.graph'
G103_NAME dashboard,'console.dashboard'
G103_NAME scan_request,'console.scan.request'
G103_NAME scan_response,'console.scan.response'
G103_NAME scan_validation_failed,'console.scan.validation_failed'
G103_NAME scan_cancelled,'console.scan.cancelled'
G103_NAME scan_timeout,'console.scan.timeout'
%undef G103_NAME

g103_event_name_table:
 dq g103_name_emit,g103_name_emit_len
 dq g103_name_clear,g103_name_clear_len
 dq g103_name_region,g103_name_region_len
 dq g103_name_text,g103_name_text_len
 dq g103_name_write,g103_name_write_len
 dq g103_name_table,g103_name_table_len
 dq g103_name_plot2d,g103_name_plot2d_len
 dq g103_name_graph,g103_name_graph_len
 dq g103_name_dashboard,g103_name_dashboard_len
 dq g103_name_scan_request,g103_name_scan_request_len
 dq g103_name_scan_response,g103_name_scan_response_len
 dq g103_name_scan_validation_failed,g103_name_scan_validation_failed_len
 dq g103_name_scan_cancelled,g103_name_scan_cancelled_len
 dq g103_name_scan_timeout,g103_name_scan_timeout_len

g103_required_caps:
 dq NEBO_G103_CAP_EMIT
 dq NEBO_G103_CAP_CLEAR
 dq NEBO_G103_CAP_REGION
 dq NEBO_G103_CAP_TEXT
 dq NEBO_G103_CAP_TEXT
 dq NEBO_G103_CAP_TABLE
 dq NEBO_G103_CAP_VISUAL
 dq NEBO_G103_CAP_VISUAL
 dq NEBO_G103_CAP_VISUAL
 dq NEBO_G103_CAP_SCAN
 dq NEBO_G103_CAP_SCAN
 dq NEBO_G103_CAP_SCAN|NEBO_G103_CAP_DIAGNOSTIC
 dq NEBO_G103_CAP_SCAN
 dq NEBO_G103_CAP_SCAN

section .text
; RDI=event. Validate authority, privacy and bounded protocol fields.
nebo_g103_validate_event:
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBO_G103_EVENT_VERSION_OFFSET],NEBO_G103_SCHEMA_VERSION
 jne .version
 mov rax,[rdi+NEBO_G103_EVENT_SEQUENCE_OFFSET]
 cmp rax,1
 jb .bounds
 cmp rax,1000000
 ja .bounds
 mov rax,[rdi+NEBO_G103_EVENT_KIND_OFFSET]
 cmp rax,NEBO_G103_EVENT_EMIT
 jb .kind
 cmp rax,NEBO_G103_EVENT_MAX
 ja .kind
 mov rcx,[rdi+NEBO_G103_EVENT_REGION_OFFSET]
 cmp rcx,1
 jb .bounds
 cmp rcx,4095
 ja .bounds
 mov rcx,[rdi+NEBO_G103_EVENT_FLAGS_OFFSET]
 test rcx,~NEBO_G103_FLAG_KNOWN
 jnz .privacy
 mov rdx,[rdi+NEBO_G103_EVENT_CAPABILITIES_OFFSET]
 test rdx,~NEBO_G103_CAP_ALL
 jnz .capability
 lea r8,[rel g103_required_caps]
 mov r9,[r8+rax*8-8]
 mov r8,rdx
 and r8,r9
 cmp r8,r9
 jne .capability
 cmp rax,NEBO_G103_EVENT_SCAN_REQUEST
 je .scan_request
 cmp rax,NEBO_G103_EVENT_SCAN_RESPONSE
 je .scan_response
 cmp rax,NEBO_G103_EVENT_SCAN_VALIDATION_FAILED
 je .scan_validation
 cmp rax,NEBO_G103_EVENT_SCAN_CANCELLED
 je .scan_terminal
 cmp rax,NEBO_G103_EVENT_SCAN_TIMEOUT
 je .scan_terminal
 xor eax,eax
 ret
.scan_request:
 cmp qword [rdi+NEBO_G103_EVENT_VALUE_OFFSET],0
 jne .privacy
 test rcx,NEBO_G103_FLAG_PRIVATE|NEBO_G103_FLAG_REDACTED
 jnz .privacy
 xor eax,eax
 ret
.scan_response:
 cmp qword [rdi+NEBO_G103_EVENT_VALUE_OFFSET],0
 je .privacy
 mov rax,rcx
 and rax,NEBO_G103_FLAG_PRIVATE|NEBO_G103_FLAG_REDACTED
 cmp rax,NEBO_G103_FLAG_PRIVATE|NEBO_G103_FLAG_REDACTED
 jne .privacy
 xor eax,eax
 ret
.scan_validation:
 cmp qword [rdi+NEBO_G103_EVENT_VALUE_OFFSET],0
 je .privacy
 xor eax,eax
 ret
.scan_terminal:
 cmp qword [rdi+NEBO_G103_EVENT_VALUE_OFFSET],0
 jne .privacy
 test rcx,NEBO_G103_FLAG_TERMINAL
 jz .privacy
 xor eax,eax
 ret
.invalid: mov eax,NEBO_G103_ERROR_INVALID
 ret
.version: mov eax,NEBO_G103_ERROR_VERSION
 ret
.kind: mov eax,NEBO_G103_ERROR_KIND
 ret
.bounds: mov eax,NEBO_G103_ERROR_BOUNDS
 ret
.capability: mov eax,NEBO_G103_ERROR_CAPABILITY
 ret
.privacy: mov eax,NEBO_G103_ERROR_PRIVACY
 ret

; RDI destination, RSI source, ECX length. Return advanced RDI.
g103_copy:
 cld
 rep movsb
 ret

; RDI destination, RAX value. Emit canonical lowercase hexadecimal.
g103_write_hex16:
 lea r8,[rdi+16]
 lea r9,[rel g103_hex]
 mov ecx,16
.loop:
 dec r8
 mov rdx,rax
 and edx,15
 mov dl,[r9+rdx]
 mov [r8],dl
 shr rax,4
 dec ecx
 jnz .loop
 add rdi,16
 ret

g103_write_hex2:
 lea r8,[rdi+2]
 lea r9,[rel g103_hex]
 mov ecx,2
.loop:
 dec r8
 mov rdx,rax
 and edx,15
 mov dl,[r9+rdx]
 mov [r8],dl
 shr rax,4
 dec ecx
 jnz .loop
 add rdi,2
 ret

; RDI bytes, ECX digits -> RAX value and EDX=0, or EDX=1.
g103_parse_hex:
 xor eax,eax
 xor edx,edx
 xor r8d,r8d
.loop:
 cmp r8d,ecx
 jae .done
 movzx r9d,byte [rdi+r8]
 cmp r9b,'0'
 jb .bad
 cmp r9b,'9'
 jbe .digit
 cmp r9b,'a'
 jb .bad
 cmp r9b,'f'
 ja .bad
 sub r9d,'a'-10
 jmp .add
.digit:
 sub r9d,'0'
.add:
 shl rax,4
 or rax,r9
 inc r8d
 jmp .loop
.bad:
 mov edx,1
.done:
 ret

; RDI actual, RSI expected, EDX length -> EAX boolean.
g103_match:
 mov ecx,edx
 cld
 repe cmpsb
 sete al
 movzx eax,al
 ret

; RDI=event, RSI=output, RDX=capacity. Return record bytes or typed error.
nebo_g103_encode_event:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call nebo_g103_validate_event
 test eax,eax
 jnz .done
 test r13,r13
 jz .invalid
 cmp r14,NEBO_G103_RECORD_SIZE
 jb .capacity
 mov rdi,r13
 lea rsi,[rel g103_prefix]
 mov ecx,g103_prefix_len
 call g103_copy
 mov rax,[r12+NEBO_G103_EVENT_SEQUENCE_OFFSET]
 call g103_write_hex16
 lea rsi,[rel g103_mid_kind]
 mov ecx,g103_mid_kind_len
 call g103_copy
 mov rax,[r12+NEBO_G103_EVENT_KIND_OFFSET]
 call g103_write_hex2
 lea rsi,[rel g103_mid_region]
 mov ecx,g103_mid_region_len
 call g103_copy
 mov rax,[r12+NEBO_G103_EVENT_REGION_OFFSET]
 call g103_write_hex16
 lea rsi,[rel g103_mid_value]
 mov ecx,g103_mid_value_len
 call g103_copy
 mov rax,[r12+NEBO_G103_EVENT_VALUE_OFFSET]
 call g103_write_hex16
 lea rsi,[rel g103_mid_flags]
 mov ecx,g103_mid_flags_len
 call g103_copy
 mov rax,[r12+NEBO_G103_EVENT_FLAGS_OFFSET]
 call g103_write_hex16
 lea rsi,[rel g103_suffix]
 mov ecx,g103_suffix_len
 call g103_copy
 mov eax,NEBO_G103_RECORD_SIZE
 jmp .done
.invalid: mov eax,NEBO_G103_ERROR_INVALID
 jmp .done
.capacity: mov eax,NEBO_G103_ERROR_CAPACITY
.done:
 pop r14
 pop r13
 pop r12
 ret

; RDI=one canonical JSONL record, RSI=length, RDX=decoded event.
; Consumer output has zero capabilities: decoding never grants authority.
nebo_g103_decode_event:
 push r12
 push r13
 sub rsp,72
 mov r12,rdi
 mov r13,rdx
 test r12,r12
 jz .invalid
 test r13,r13
 jz .invalid
 cmp rsi,NEBO_G103_RECORD_SIZE
 jne .syntax
 lea rdi,[r12]
 lea rsi,[rel g103_version_prefix]
 mov edx,g103_version_prefix_len
 call g103_match
 test eax,eax
 jz .syntax
 cmp byte [r12+g103_version_prefix_len],'1'
 jne .version
 lea rdi,[r12]
 lea rsi,[rel g103_prefix]
 mov edx,g103_prefix_len
 call g103_match
 test eax,eax
 jz .syntax
 lea rdi,[r12+30]
 lea rsi,[rel g103_mid_kind]
 mov edx,g103_mid_kind_len
 call g103_match
 test eax,eax
 jz .syntax
 lea rdi,[r12+42]
 lea rsi,[rel g103_mid_region]
 mov edx,g103_mid_region_len
 call g103_match
 test eax,eax
 jz .syntax
 lea rdi,[r12+70]
 lea rsi,[rel g103_mid_value]
 mov edx,g103_mid_value_len
 call g103_match
 test eax,eax
 jz .syntax
 lea rdi,[r12+97]
 lea rsi,[rel g103_mid_flags]
 mov edx,g103_mid_flags_len
 call g103_match
 test eax,eax
 jz .syntax
 lea rdi,[r12+124]
 lea rsi,[rel g103_suffix]
 mov edx,g103_suffix_len
 call g103_match
 test eax,eax
 jz .syntax
 mov qword [rsp+NEBO_G103_EVENT_VERSION_OFFSET],NEBO_G103_SCHEMA_VERSION
 lea rdi,[r12+NEBO_G103_RECORD_SEQUENCE_OFFSET]
 mov ecx,16
 call g103_parse_hex
 test edx,edx
 jnz .syntax
 mov [rsp+NEBO_G103_EVENT_SEQUENCE_OFFSET],rax
 lea rdi,[r12+NEBO_G103_RECORD_KIND_OFFSET]
 mov ecx,2
 call g103_parse_hex
 test edx,edx
 jnz .syntax
 mov [rsp+NEBO_G103_EVENT_KIND_OFFSET],rax
 lea rdi,[r12+NEBO_G103_RECORD_REGION_OFFSET]
 mov ecx,16
 call g103_parse_hex
 test edx,edx
 jnz .syntax
 mov [rsp+NEBO_G103_EVENT_REGION_OFFSET],rax
 lea rdi,[r12+NEBO_G103_RECORD_VALUE_OFFSET]
 mov ecx,16
 call g103_parse_hex
 test edx,edx
 jnz .syntax
 mov [rsp+NEBO_G103_EVENT_VALUE_OFFSET],rax
 lea rdi,[r12+NEBO_G103_RECORD_FLAGS_OFFSET]
 mov ecx,16
 call g103_parse_hex
 test edx,edx
 jnz .syntax
 mov [rsp+NEBO_G103_EVENT_FLAGS_OFFSET],rax
 mov qword [rsp+NEBO_G103_EVENT_CAPABILITIES_OFFSET],NEBO_G103_CAP_ALL
 mov rdi,rsp
 call nebo_g103_validate_event
 test eax,eax
 jnz .done
 mov rsi,rsp
 mov rdi,r13
 mov ecx,6
 cld
 rep movsq
 mov qword [r13+NEBO_G103_EVENT_CAPABILITIES_OFFSET],0
 xor eax,eax
 jmp .done
.invalid: mov eax,NEBO_G103_ERROR_INVALID
 jmp .done
.version: mov eax,NEBO_G103_ERROR_VERSION
 jmp .done
.syntax: mov eax,NEBO_G103_ERROR_SYNTAX
.done:
 add rsp,72
 pop r13
 pop r12
 ret

; RDI=event. Encode then consume and compare all transported fields.
nebo_g103_roundtrip_event:
 push r12
 sub rsp,192
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov rdi,r12
 mov rsi,rsp
 mov edx,NEBO_G103_RECORD_SIZE
 call nebo_g103_encode_event
 cmp eax,NEBO_G103_RECORD_SIZE
 jne .done
 mov rdi,rsp
 mov esi,NEBO_G103_RECORD_SIZE
 lea rdx,[rsp+128]
 call nebo_g103_decode_event
 test eax,eax
 jnz .done
 mov rsi,r12
 lea rdi,[rsp+128]
 mov ecx,6
 cld
 repe cmpsq
 jne .mismatch
 xor eax,eax
 jmp .done
.invalid: mov eax,NEBO_G103_ERROR_INVALID
 jmp .done
.mismatch: mov eax,NEBO_G103_ERROR_ROUNDTRIP
.done:
 add rsp,192
 pop r12
 ret

; RDI=event array, RSI=count, RDX=output, RCX=capacity.
; Prevalidation guarantees all-or-none publication.
nebo_g103_batch_encode:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 test r12,r12
 jz .invalid
 test r14,r14
 jz .invalid
 cmp r13,1
 jb .bounds
 cmp r13,NEBO_G103_BATCH_MAX
 ja .bounds
 imul rax,r13,NEBO_G103_RECORD_SIZE
 cmp r15,rax
 jb .capacity
 xor ebx,ebx
.validate:
 cmp rbx,r13
 jae .emit_start
 imul rdi,rbx,NEBO_G103_EVENT_SIZE
 add rdi,r12
 call nebo_g103_validate_event
 test eax,eax
 jnz .done
 inc rbx
 jmp .validate
.emit_start:
 xor ebx,ebx
.emit:
 cmp rbx,r13
 jae .success
 imul rdi,rbx,NEBO_G103_EVENT_SIZE
 add rdi,r12
 imul rsi,rbx,NEBO_G103_RECORD_SIZE
 add rsi,r14
 mov edx,NEBO_G103_RECORD_SIZE
 call nebo_g103_encode_event
 cmp eax,NEBO_G103_RECORD_SIZE
 jne .done
 inc rbx
 jmp .emit
.success:
 imul rax,r13,NEBO_G103_RECORD_SIZE
 jmp .done
.invalid: mov eax,NEBO_G103_ERROR_INVALID
 jmp .done
.bounds: mov eax,NEBO_G103_ERROR_BOUNDS
 jmp .done
.capacity: mov eax,NEBO_G103_ERROR_CAPACITY
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI=batch bytes, RSI=length, RDX=result. Enforce exact framing/order.
nebo_g103_consume_batch:
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov r12,rdi
 mov rbp,rdx
 test r12,r12
 jz .invalid
 test rbp,rbp
 jz .invalid
 test rsi,rsi
 jz .bounds
 mov rax,rsi
 xor edx,edx
 mov ecx,NEBO_G103_RECORD_SIZE
 div rcx
 test rdx,rdx
 jnz .syntax
 cmp rax,1
 jb .bounds
 cmp rax,NEBO_G103_BATCH_MAX
 ja .bounds
 mov r13,rax
 xor r14d,r14d
 mov r15,0xcbf29ce484222325
.loop:
 cmp r14,r13
 jae .publish
 imul rdi,r14,NEBO_G103_RECORD_SIZE
 add rdi,r12
 mov esi,NEBO_G103_RECORD_SIZE
 mov rdx,rsp
 call nebo_g103_decode_event
 test eax,eax
 jnz .done
 mov rax,r14
 inc rax
 cmp [rsp+NEBO_G103_EVENT_SEQUENCE_OFFSET],rax
 jne .ordering
 mov rax,[rsp+NEBO_G103_EVENT_SEQUENCE_OFFSET]
 xor r15,rax
 rol r15,9
 xor r15,[rsp+NEBO_G103_EVENT_KIND_OFFSET]
 rol r15,13
 xor r15,[rsp+NEBO_G103_EVENT_REGION_OFFSET]
 rol r15,17
 xor r15,[rsp+NEBO_G103_EVENT_VALUE_OFFSET]
 rol r15,21
 xor r15,[rsp+NEBO_G103_EVENT_FLAGS_OFFSET]
 inc r14
 jmp .loop
.publish:
 mov [rbp+NEBO_G103_CONSUMER_COUNT_OFFSET],r13
 mov [rbp+NEBO_G103_CONSUMER_LAST_SEQUENCE_OFFSET],r13
 mov [rbp+NEBO_G103_CONSUMER_DIGEST_OFFSET],r15
 mov qword [rbp+NEBO_G103_CONSUMER_VIOLATIONS_OFFSET],0
 xor eax,eax
 jmp .done
.invalid: mov eax,NEBO_G103_ERROR_INVALID
 jmp .done
.bounds: mov eax,NEBO_G103_ERROR_BOUNDS
 jmp .done
.syntax: mov eax,NEBO_G103_ERROR_SYNTAX
 jmp .done
.ordering: mov eax,NEBO_G103_ERROR_ORDERING
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 ret

; RDI=stream state, RSI=event. Commit cursor/count only after one full record.
nebo_g103_stream_append:
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 test r12,r12
 jz .invalid
 test r13,r13
 jz .invalid
 mov rax,[r12+NEBO_G103_STREAM_NEXT_SEQUENCE_OFFSET]
 cmp [r13+NEBO_G103_EVENT_SEQUENCE_OFFSET],rax
 jne .ordering
 mov rdx,[r12+NEBO_G103_STREAM_CAPACITY_OFFSET]
 sub rdx,[r12+NEBO_G103_STREAM_LENGTH_OFFSET]
 jc .capacity
 mov rsi,[r12+NEBO_G103_STREAM_BUFFER_OFFSET]
 test rsi,rsi
 jz .invalid
 add rsi,[r12+NEBO_G103_STREAM_LENGTH_OFFSET]
 mov rdi,r13
 call nebo_g103_encode_event
 cmp eax,NEBO_G103_RECORD_SIZE
 jne .done
 add qword [r12+NEBO_G103_STREAM_LENGTH_OFFSET],NEBO_G103_RECORD_SIZE
 inc qword [r12+NEBO_G103_STREAM_NEXT_SEQUENCE_OFFSET]
 inc qword [r12+NEBO_G103_STREAM_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.invalid: mov eax,NEBO_G103_ERROR_INVALID
 jmp .done
.capacity: mov eax,NEBO_G103_ERROR_CAPACITY
 jmp .done
.ordering: mov eax,NEBO_G103_ERROR_ORDERING
.done:
 pop r13
 pop r12
 ret

; EDI=kind -> RAX=name pointer, RDX=length; zeroes for an unknown kind.
nebo_g103_event_name:
 cmp edi,NEBO_G103_EVENT_EMIT
 jb .bad
 cmp edi,NEBO_G103_EVENT_MAX
 ja .bad
 dec edi
 lea rcx,[rel g103_event_name_table]
 movsxd rdi,edi
 shl rdi,4
 mov rax,[rcx+rdi]
 mov rdx,[rcx+rdi+8]
 ret
.bad:
 xor eax,eax
 xor edx,edx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
