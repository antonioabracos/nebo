; G103 source-to-effect bridge for existing RenderPlan headless operations.
bits 64
default rel
%define NEBO_G103_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/headless_protocol_source_probe.inc"
%include "runtime/console/headless_protocol.inc"

global nebo_g103_source_probe
global nebo_g103_observation_probe
global nebo_g103_counter_probe
global nebo_g103_negative_probe

section .rodata
; One bit per canonical event kind. Modes are the ten bounded G103 subgroups.
g103_mode_masks: dw 0x0007,0x0018,0x0020,0x01c0,0x3e00
                 dw 0x003f,0x0528,0x0069,0x3e00,0x3fff

section .bss align=16
g103_events: resb NEBO_G103_EVENT_SIZE*NEBO_G103_BATCH_MAX
g103_batch: resb NEBO_G103_RECORD_SIZE*NEBO_G103_BATCH_MAX
g103_stream_batch: resb NEBO_G103_RECORD_SIZE*NEBO_G103_BATCH_MAX
g103_consumer_result: resb NEBO_G103_CONSUMER_RESULT_SIZE
g103_stream_state: resb NEBO_G103_STREAM_SIZE
g103_negative_events: resb NEBO_G103_EVENT_SIZE*2
g103_negative_buffer: resb NEBO_G103_RECORD_SIZE*2
g103_negative_result: resb NEBO_G103_CONSUMER_RESULT_SIZE

section .text
; EDI=kind, ESI=sequence, EDX=mode, ECX=seed, R8=event destination.
g103_fill_event:
 mov qword [r8+NEBO_G103_EVENT_VERSION_OFFSET],NEBO_G103_SCHEMA_VERSION
 mov [r8+NEBO_G103_EVENT_SEQUENCE_OFFSET],rsi
 mov [r8+NEBO_G103_EVENT_KIND_OFFSET],rdi
 mov [r8+NEBO_G103_EVENT_REGION_OFFSET],rdx
 mov eax,ecx
 add rax,rdi
 mov [r8+NEBO_G103_EVENT_VALUE_OFFSET],rax
 mov qword [r8+NEBO_G103_EVENT_FLAGS_OFFSET],0
 mov qword [r8+NEBO_G103_EVENT_CAPABILITIES_OFFSET],NEBO_G103_CAP_ALL
 cmp edi,NEBO_G103_EVENT_SCAN_REQUEST
 jne .response
 mov qword [r8+NEBO_G103_EVENT_VALUE_OFFSET],0
 ret
.response:
 cmp edi,NEBO_G103_EVENT_SCAN_RESPONSE
 jne .validation
 mov qword [r8+NEBO_G103_EVENT_FLAGS_OFFSET],NEBO_G103_FLAG_PRIVATE|NEBO_G103_FLAG_REDACTED
 ret
.validation:
 cmp edi,NEBO_G103_EVENT_SCAN_VALIDATION_FAILED
 je .done
 cmp edi,NEBO_G103_EVENT_SCAN_CANCELLED
 je .terminal
 cmp edi,NEBO_G103_EVENT_SCAN_TIMEOUT
 jne .done
.terminal:
 mov qword [r8+NEBO_G103_EVENT_VALUE_OFFSET],0
 mov qword [r8+NEBO_G103_EVENT_FLAGS_OFFSET],NEBO_G103_FLAG_TERMINAL
.done:
 ret

; EDI=mode, ESI=seed. Fill the source-derived event batch, return count.
g103_prepare_mode:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12d,edi
 mov r13d,esi
 lea rax,[rel g103_mode_masks]
 movzx ebx,word [rax+r12*2-2]
 xor r14d,r14d
 mov edi,1
.kind_loop:
 cmp edi,NEBO_G103_EVENT_MAX
 ja .done
 ; Masks are zero-based while event kinds begin at one.
 mov ecx,edi
 dec ecx
 bt ebx,ecx
 jnc .next
 imul rax,r14,NEBO_G103_EVENT_SIZE
 lea r8,[rel g103_events]
 add r8,rax
 mov esi,r14d
 inc esi
 mov edx,r12d
 mov ecx,r13d
 call g103_fill_event
 inc r14d
.next:
 inc edi
 jmp .kind_loop
.done:
 mov eax,r14d
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; EDI=mode, ESI=seed. Exercise encode, stream, consume and round-trip.
nebo_g103_source_probe:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12d,edi
 mov r13d,esi
 cmp r12d,1
 jb .invalid
 cmp r12d,10
 ja .invalid
 cmp r13d,1000
 jb .invalid
 cmp r13d,9999
 ja .invalid
 call g103_prepare_mode
 mov r14d,eax
 test r14d,r14d
 jz .effect

 ; Capability and version diagnostics are observed before valid publication.
 cmp r12d,8
 jne .version_check
 mov rax,[rel g103_events+NEBO_G103_EVENT_CAPABILITIES_OFFSET]
 mov qword [rel g103_events+NEBO_G103_EVENT_CAPABILITIES_OFFSET],0
 push rax
 lea rdi,[rel g103_events]
 lea rsi,[rel g103_batch]
 mov edx,NEBO_G103_RECORD_SIZE
 call nebo_g103_encode_event
 pop rcx
 mov [rel g103_events+NEBO_G103_EVENT_CAPABILITIES_OFFSET],rcx
 cmp eax,NEBO_G103_ERROR_CAPABILITY
 jne .effect
.version_check:
 cmp r12d,9
 jne .encode
 mov qword [rel g103_events+NEBO_G103_EVENT_VERSION_OFFSET],2
 lea rdi,[rel g103_events]
 lea rsi,[rel g103_batch]
 mov edx,NEBO_G103_RECORD_SIZE
 call nebo_g103_encode_event
 mov qword [rel g103_events+NEBO_G103_EVENT_VERSION_OFFSET],NEBO_G103_SCHEMA_VERSION
 cmp eax,NEBO_G103_ERROR_VERSION
 jne .effect
.encode:
 lea rdi,[rel g103_events]
 mov esi,r14d
 lea rdx,[rel g103_batch]
 mov ecx,NEBO_G103_RECORD_SIZE*NEBO_G103_BATCH_MAX
 call nebo_g103_batch_encode
 test eax,eax
 js .done
 mov r15d,eax
 lea rdi,[rel g103_batch]
 mov esi,r15d
 lea rdx,[rel g103_consumer_result]
 call nebo_g103_consume_batch
 test eax,eax
 jnz .done
 cmp [rel g103_consumer_result+NEBO_G103_CONSUMER_COUNT_OFFSET],r14
 jne .effect
 cmp [rel g103_consumer_result+NEBO_G103_CONSUMER_LAST_SEQUENCE_OFFSET],r14
 jne .effect

 xor ebx,ebx
.roundtrip:
 cmp ebx,r14d
 jae .stream_check
 imul rdi,rbx,NEBO_G103_EVENT_SIZE
 lea rax,[rel g103_events]
 add rdi,rax
 call nebo_g103_roundtrip_event
 test eax,eax
 jnz .done
 inc ebx
 jmp .roundtrip
.stream_check:
 cmp r12d,6
 jne .success
 lea rax,[rel g103_stream_batch]
 mov [rel g103_stream_state+NEBO_G103_STREAM_BUFFER_OFFSET],rax
 mov qword [rel g103_stream_state+NEBO_G103_STREAM_CAPACITY_OFFSET],NEBO_G103_RECORD_SIZE*NEBO_G103_BATCH_MAX
 mov qword [rel g103_stream_state+NEBO_G103_STREAM_LENGTH_OFFSET],0
 mov qword [rel g103_stream_state+NEBO_G103_STREAM_NEXT_SEQUENCE_OFFSET],1
 mov qword [rel g103_stream_state+NEBO_G103_STREAM_COUNT_OFFSET],0
 xor ebx,ebx
.stream:
 cmp ebx,r14d
 jae .stream_compare
 imul rsi,rbx,NEBO_G103_EVENT_SIZE
 lea rax,[rel g103_events]
 add rsi,rax
 lea rdi,[rel g103_stream_state]
 call nebo_g103_stream_append
 test eax,eax
 jnz .done
 inc ebx
 jmp .stream
.stream_compare:
 cmp [rel g103_stream_state+NEBO_G103_STREAM_LENGTH_OFFSET],r15
 jne .effect
 lea rsi,[rel g103_batch]
 lea rdi,[rel g103_stream_batch]
 mov ecx,r15d
 cld
 repe cmpsb
 jne .effect
.success:
 mov eax,r13d
 jmp .done
.invalid: mov eax,NEBO_G103_ERROR_INVALID
 jmp .done
.effect: mov eax,NEBO_G103_ERROR_ROUNDTRIP
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI=mode, RSI=seed -> consumer digest after the full protocol path.
nebo_g103_observation_probe:
 push rbx
 mov ebx,esi
 call nebo_g103_source_probe
 cmp eax,ebx
 jne .failed
 mov rax,[rel g103_consumer_result+NEBO_G103_CONSUMER_DIGEST_OFFSET]
 pop rbx
 ret
.failed:
 cdqe
 pop rbx
 ret

; RDI=mode, RSI=seed, RDX=selector: count, bytes, last sequence or digest.
nebo_g103_counter_probe:
 push rbx
 push r12
 sub rsp,8
 mov ebx,esi
 mov r12,rdx
 call nebo_g103_source_probe
 cmp eax,ebx
 jne .done
 cmp r12,1
 je .count
 cmp r12,2
 je .bytes
 cmp r12,3
 je .last
 cmp r12,4
 je .digest
 mov eax,NEBO_G103_ERROR_INVALID
 jmp .done
.count: mov rax,[rel g103_consumer_result+NEBO_G103_CONSUMER_COUNT_OFFSET]
 jmp .done
.bytes:
 mov rax,[rel g103_consumer_result+NEBO_G103_CONSUMER_COUNT_OFFSET]
 imul rax,NEBO_G103_RECORD_SIZE
 jmp .done
.last: mov rax,[rel g103_consumer_result+NEBO_G103_CONSUMER_LAST_SEQUENCE_OFFSET]
 jmp .done
.digest: mov rax,[rel g103_consumer_result+NEBO_G103_CONSUMER_DIGEST_OFFSET]
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; Build one valid text event used by bounded adversarial cases.
g103_prepare_negative:
 lea r8,[rel g103_negative_events]
 mov edi,NEBO_G103_EVENT_TEXT
 mov esi,1
 mov edx,7
 mov ecx,1701
 call g103_fill_event
 ret

; RDI=case 1..16 -> stable typed failure; no case publishes partial output.
nebo_g103_negative_probe:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdi
 call g103_prepare_negative
 lea rdi,[rel g103_negative_buffer]
 mov rax,0x5a5a5a5a5a5a5a5a
 mov ecx,(NEBO_G103_RECORD_SIZE*2)/8
 cld
 rep stosq
 mov ebx,NEBO_G103_RECORD_SIZE
 cmp r12,1
 je .bad_version
 cmp r12,2
 je .bad_kind
 cmp r12,3
 je .bad_sequence
 cmp r12,4
 je .bad_region
 cmp r12,5
 je .bad_capability
 cmp r12,6
 je .request_leak
 cmp r12,7
 je .response_unredacted
 cmp r12,8
 je .terminal_payload
 cmp r12,9
 je .small_capacity
 cmp r12,10
 je .malformed
 cmp r12,11
 je .ordering
 cmp r12,12
 je .truncated
 cmp r12,13
 je .too_many
 cmp r12,14
 je .unknown_flags
 cmp r12,15
 je .empty_batch
 cmp r12,16
 je .null_decode
 mov eax,NEBO_G103_ERROR_INVALID
 jmp .done
.bad_version: mov qword [rel g103_negative_events+NEBO_G103_EVENT_VERSION_OFFSET],2
 jmp .encode
.bad_kind: mov qword [rel g103_negative_events+NEBO_G103_EVENT_KIND_OFFSET],15
 jmp .encode
.bad_sequence: mov qword [rel g103_negative_events+NEBO_G103_EVENT_SEQUENCE_OFFSET],0
 jmp .encode
.bad_region: mov qword [rel g103_negative_events+NEBO_G103_EVENT_REGION_OFFSET],0
 jmp .encode
.bad_capability: mov qword [rel g103_negative_events+NEBO_G103_EVENT_CAPABILITIES_OFFSET],0
 jmp .encode
.request_leak:
 mov qword [rel g103_negative_events+NEBO_G103_EVENT_KIND_OFFSET],NEBO_G103_EVENT_SCAN_REQUEST
 mov qword [rel g103_negative_events+NEBO_G103_EVENT_VALUE_OFFSET],1
 jmp .encode
.response_unredacted:
 mov qword [rel g103_negative_events+NEBO_G103_EVENT_KIND_OFFSET],NEBO_G103_EVENT_SCAN_RESPONSE
 mov qword [rel g103_negative_events+NEBO_G103_EVENT_FLAGS_OFFSET],0
 jmp .encode
.terminal_payload:
 mov qword [rel g103_negative_events+NEBO_G103_EVENT_KIND_OFFSET],NEBO_G103_EVENT_SCAN_CANCELLED
 mov qword [rel g103_negative_events+NEBO_G103_EVENT_FLAGS_OFFSET],NEBO_G103_FLAG_TERMINAL
 mov qword [rel g103_negative_events+NEBO_G103_EVENT_VALUE_OFFSET],1
 jmp .encode
.small_capacity:
 mov ebx,NEBO_G103_RECORD_SIZE-1
.encode:
 lea rdi,[rel g103_negative_events]
 lea rsi,[rel g103_negative_buffer]
 mov edx,ebx
 call nebo_g103_encode_event
 jmp .done
.malformed:
 mov byte [rel g103_negative_buffer],'!'
 lea rdi,[rel g103_negative_buffer]
 mov esi,NEBO_G103_RECORD_SIZE
 lea rdx,[rel g103_negative_events]
 call nebo_g103_decode_event
 jmp .done
.ordering:
 lea rdi,[rel g103_negative_events]
 mov esi,2
 lea rdx,[rel g103_negative_buffer]
 mov ecx,NEBO_G103_RECORD_SIZE*2
 ; Complete the second event but deliberately skip sequence two.
 lea r8,[rel g103_negative_events+NEBO_G103_EVENT_SIZE]
 mov edi,NEBO_G103_EVENT_TABLE
 mov esi,3
 mov edx,7
 mov ecx,1701
 call g103_fill_event
 lea rdi,[rel g103_negative_events]
 mov esi,2
 lea rdx,[rel g103_negative_buffer]
 mov ecx,NEBO_G103_RECORD_SIZE*2
 call nebo_g103_batch_encode
 test eax,eax
 js .done
 lea rdi,[rel g103_negative_buffer]
 mov esi,eax
 lea rdx,[rel g103_negative_result]
 call nebo_g103_consume_batch
 jmp .done
.truncated:
 lea rdi,[rel g103_negative_events]
 lea rsi,[rel g103_negative_buffer]
 mov edx,NEBO_G103_RECORD_SIZE
 call nebo_g103_encode_event
 test eax,eax
 js .done
 lea rdi,[rel g103_negative_buffer]
 mov esi,NEBO_G103_RECORD_SIZE-1
 lea rdx,[rel g103_negative_result]
 call nebo_g103_consume_batch
 jmp .done
.too_many:
 lea rdi,[rel g103_negative_events]
 mov esi,NEBO_G103_BATCH_MAX+1
 lea rdx,[rel g103_negative_buffer]
 mov ecx,NEBO_G103_RECORD_SIZE*2
 call nebo_g103_batch_encode
 jmp .done
.unknown_flags:
 mov qword [rel g103_negative_events+NEBO_G103_EVENT_FLAGS_OFFSET],8
 jmp .encode
.empty_batch:
 lea rdi,[rel g103_negative_buffer]
 xor esi,esi
 lea rdx,[rel g103_negative_result]
 call nebo_g103_consume_batch
 jmp .done
.null_decode:
 lea rdi,[rel g103_negative_buffer]
 mov esi,NEBO_G103_RECORD_SIZE
 xor edx,edx
 call nebo_g103_decode_event
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
