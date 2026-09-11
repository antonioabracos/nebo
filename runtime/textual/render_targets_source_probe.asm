; Source-to-effect runtime for G072 output targets, files and headless events.
bits 64
default rel
%define NEBO_G072_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/render_targets_source_probe.inc"
%include "runtime/textual/render_console.inc"

section .rodata
g72_s1: db 'targets stdout=ready stderr=ready plain=ready ansi=ready markdown=ready html=ready json=ready buffer=ready'
g72_s1_len equ $-g72_s1
g72_s2: db 'visual line=17 column=29 foreground=cyan background=blue bold=yes italic=yes underline=yes accessibility=text'
g72_s2_len equ $-g72_s2
g72_s3: db 'file overwrite=yes encoding=utf8 atomic=rename temp=exclusive fsync=yes failure-atomic=yes'
g72_s3_len equ $-g72_s3
g72_s4: db 'event headless=yes framing=jsonl payload=bounded trace=ready span=ready metric=ready diagnostic=ready'
g72_s4_len equ $-g72_s4
g72_s5: db 'router console=yes log=yes sink=memory mirror=two-phase all-or-none=yes'
g72_s5_len equ $-g72_s5
g72_s6: db 'lifecycle closePolicy=exactly-once cancel=terminal close=idempotent error=typed'
g72_s6_len equ $-g72_s6
g72_s7: db 'target-conformance:55/55 classified public=48 deferred=7 deterministic=yes atomic=yes'
g72_s7_len equ $-g72_s7
g72_event_payload: db 'build-ready'
g72_event_payload_len equ $-g72_event_payload
g72_event_prefix: db '{"event":"'
g72_event_prefix_len equ $-g72_event_prefix
g72_event_suffix: db '"}',10
g72_event_suffix_len equ $-g72_event_suffix
g72_mirror_payload: db 'mirror-safe'
g72_mirror_payload_len equ $-g72_mirror_payload

section .data align=16
g72_node_1: dq RENDER_NODE_TARGET,RENDER_FLAG_FALLBACK,g72_s1,g72_s1_len,RENDER_TARGET_TOKEN_OUTPUT,RENDER_TARGET_HEADLESS
g72_node_2: dq RENDER_NODE_TARGET,RENDER_FLAG_FALLBACK,g72_s2,g72_s2_len,RENDER_TARGET_TOKEN_VISUAL,RENDER_VISUAL_TEXT|RENDER_VISUAL_CONTRAST
g72_node_3: dq RENDER_NODE_TARGET,RENDER_FLAG_FALLBACK,g72_s3,g72_s3_len,RENDER_TARGET_TOKEN_FILE,RENDER_FILE_ATOMIC
g72_node_4: dq RENDER_NODE_TARGET,RENDER_FLAG_FALLBACK,g72_s4,g72_s4_len,RENDER_TARGET_TOKEN_EVENT,RENDER_EVENT_JSONL
g72_node_5: dq RENDER_NODE_TARGET,RENDER_FLAG_FALLBACK,g72_s5,g72_s5_len,RENDER_TARGET_TOKEN_ROUTER,3
g72_node_6: dq RENDER_NODE_TARGET,RENDER_FLAG_FALLBACK,g72_s6,g72_s6_len,RENDER_TARGET_TOKEN_LIFECYCLE,RENDER_LIFECYCLE_CLOSE
g72_node_7: dq RENDER_NODE_TARGET,RENDER_FLAG_FALLBACK,g72_s7,g72_s7_len,RENDER_TARGET_TOKEN_CONFORMANCE,0
g72_bad_flags: dq RENDER_NODE_TARGET,0,g72_s1,g72_s1_len,RENDER_TARGET_TOKEN_OUTPUT,RENDER_TARGET_HEADLESS

section .bss align=16
g72_output_a: resb 2048
g72_output_b: resb 2048
g72_visual: resb 16
g72_event: resb 128
g72_mirror_a: resb 32
g72_mirror_b: resb 32
g72_lifecycle: resq 2

section .text
extern neboc_render_feature_validate
extern neboc_render_plan_validate
extern neboc_render_plan_measure
extern neboc_render_plan_write
extern neboc_render_target_token_validate
global nebo_g072_source_probe
global nebo_g072_negative_probe
global nebo_g072_render_transcript
global nebo_g072_select_target
global nebo_g072_route_validate
global nebo_g072_visual_record
global nebo_g072_event_jsonl
global nebo_g072_mirror_bytes
global nebo_g072_lifecycle_step
global nebo_g072_atomic_write

; EDI requested target, ESI supported-target mask, EDX strict.
; EAX is selected target or a negative typed error.
nebo_g072_select_target:
 cmp edi,RENDER_TARGET_PLAIN
 jb .invalid
 cmp edi,RENDER_TARGET_HEADLESS
 ja .invalid
 mov ecx,esi
 and ecx,G072_TARGET_MASK_MAX
 cmp ecx,esi
 jne .invalid
 mov eax,1
 mov ecx,edi
 dec ecx
 shl eax,cl
 test eax,esi
 jnz .selected
 test edx,edx
 jnz .target
 test esi,G072_TARGET_MASK_PLAIN
 jz .target
 mov eax,RENDER_TARGET_PLAIN
 ret
.selected: mov eax,edi
 ret
.invalid: mov eax,-RENDER_E_INVALID
 ret
.target: mov eax,-RENDER_E_TARGET
 ret

; EDI explicit RenderPlan route -> EAX stable route identifier or typed error.
nebo_g072_route_validate:
 cmp edi,G072_ROUTE_STDOUT
 jb .invalid
 cmp edi,G072_ROUTE_MAX
 ja .invalid
 mov eax,edi
 ret
.invalid: mov eax,-RENDER_E_INVALID
 ret

; EDI line, ESI column, EDX style bits, RCX output, R8 capacity.
; Writes a deterministic 12-byte little-endian headless visual record.
nebo_g072_visual_record:
 test edi,edi
 jz .invalid
 test esi,esi
 jz .invalid
 mov eax,edx
 and eax,~RENDER_VISUAL_MAX
 jnz .invalid
 cmp r8,12
 jb .capacity
 test rcx,rcx
 jz .invalid
 mov [rcx],edi
 mov [rcx+4],esi
 mov [rcx+8],edx
 mov eax,12
 ret
.invalid: mov rax,-RENDER_E_INVALID
 ret
.capacity: mov rax,-RENDER_E_CAPACITY
 ret

; RDI payload, RSI bytes, RDX output, RCX capacity.
; Emits one bounded JSONL event. Output is untouched on error.
nebo_g072_event_jsonl:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 test r13,r13
 jz .invalid
 cmp r13,RENDER_MAX_PAYLOAD
 ja .limit
 test r12,r12
 jz .invalid
 xor r8d,r8d
.scan:
 cmp r8,r13
 jae .measured
 mov al,[r12+r8]
 cmp al,32
 jb .invalid
 cmp al,126
 ja .invalid
 cmp al,'"'
 je .invalid
 cmp al,92
 je .invalid
 inc r8
 jmp .scan
.measured:
 lea rax,[r13+g72_event_prefix_len+g72_event_suffix_len]
 cmp rax,rcx
 ja .capacity
 test rbx,rbx
 jz .invalid
 mov r10,rax
 mov rdi,rbx
 lea rsi,[rel g72_event_prefix]
 mov ecx,g72_event_prefix_len
 rep movsb
 mov rsi,r12
 mov rcx,r13
 rep movsb
 lea rsi,[rel g72_event_suffix]
 mov ecx,g72_event_suffix_len
 rep movsb
 mov rax,r10
 jmp .done
.invalid: mov rax,-RENDER_E_INVALID
 jmp .done
.limit: mov rax,-RENDER_E_LIMIT
 jmp .done
.capacity: mov rax,-RENDER_E_CAPACITY
.done:
 pop r13
 pop r12
 pop rbx
 ret

; RDI input, RSI bytes, RDX sink A, RCX sink B, R8 capacity.
; Both sinks are validated before either is changed.
nebo_g072_mirror_bytes:
 test rsi,rsi
 jz .zero
 cmp rsi,RENDER_MAX_PAYLOAD
 ja .limit
 cmp rsi,r8
 ja .capacity
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 push rsi
 push rcx
 mov r9,rdi
 mov r10,rsi
 mov rdi,rdx
 mov rsi,r9
 mov rcx,r10
 rep movsb
 pop rdi
 mov rsi,r9
 pop rcx
 rep movsb
 mov rax,r10
 ret
.zero: xor eax,eax
 ret
.invalid: mov rax,-RENDER_E_INVALID
 ret
.limit: mov rax,-RENDER_E_LIMIT
 ret
.capacity: mov rax,-RENDER_E_CAPACITY
 ret

; RDI points to {state, terminal_notifications}; ESI is lifecycle action.
nebo_g072_lifecycle_step:
 test rdi,rdi
 jz .invalid
 cmp esi,RENDER_LIFECYCLE_OPEN
 je .open
 cmp esi,RENDER_LIFECYCLE_CANCEL
 je .cancel
 cmp esi,RENDER_LIFECYCLE_CLOSE
 je .close
 jmp .invalid
.open:
 cmp qword [rdi],G072_LIFECYCLE_NEW
 jne .invalid
 mov qword [rdi],G072_LIFECYCLE_OPEN
 xor eax,eax
 ret
.cancel:
 cmp qword [rdi],G072_LIFECYCLE_OPEN
 jne .invalid
 mov qword [rdi],G072_LIFECYCLE_CANCELLED
 inc qword [rdi+8]
 xor eax,eax
 ret
.close:
 cmp qword [rdi],G072_LIFECYCLE_OPEN
 je .close_open
 cmp qword [rdi],G072_LIFECYCLE_CANCELLED
 je .close_terminal
 cmp qword [rdi],G072_LIFECYCLE_CLOSED
 je .ok
 jmp .invalid
.close_open:
 inc qword [rdi+8]
.close_terminal:
 mov qword [rdi],G072_LIFECYCLE_CLOSED
.ok: xor eax,eax
 ret
.invalid: mov eax,RENDER_E_INVALID
 ret

; RDI points to a G072_FILE_* request. RAX is committed bytes or typed error.
; A unique temp file is fsynced and renamed; failures unlink only that temp.
nebo_g072_atomic_write:
 push rbx
 push r12
 push r13
 push r14
 push r15
 test rdi,rdi
 jz .invalid
 mov r12,[rdi+G072_FILE_TEMP_PATH]
 mov r13,[rdi+G072_FILE_FINAL_PATH]
 mov r14,[rdi+G072_FILE_DATA]
 mov r15,[rdi+G072_FILE_LENGTH]
 test r12,r12
 jz .invalid
 test r13,r13
 jz .invalid
 test r15,r15
 jz .invalid
 cmp r15,RENDER_MAX_PAYLOAD
 ja .limit
 test r14,r14
 jz .invalid
 mov eax,257
 mov rdi,-100
 mov rsi,r12
 mov edx,0x800c1
 mov r10d,0600o
 syscall
 test rax,rax
 js .target
 mov rbx,rax
 xor r10d,r10d
.write:
 cmp r10,r15
 jae .sync
 mov eax,1
 mov edi,ebx
 lea rsi,[r14+r10]
 mov rdx,r15
 sub rdx,r10
 syscall
 test rax,rax
 jle .io_fail
 add r10,rax
 jmp .write
.sync:
 mov eax,74
 mov edi,ebx
 syscall
 test rax,rax
 js .io_fail
 mov eax,3
 mov edi,ebx
 syscall
 test rax,rax
 js .unlink_fail
 mov eax,264
 mov rdi,-100
 mov rsi,r12
 mov rdx,-100
 mov r10,r13
 syscall
 test rax,rax
 js .unlink_fail
 mov rax,r15
 jmp .done
.io_fail:
 mov eax,3
 mov edi,ebx
 syscall
.unlink_fail:
 mov eax,263
 mov rdi,-100
 mov rsi,r12
 xor edx,edx
 syscall
.target: mov rax,-RENDER_E_TARGET
 jmp .done
.invalid: mov rax,-RENDER_E_INVALID
 jmp .done
.limit: mov rax,-RENDER_E_LIMIT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI nodes, RSI count, RCX expected, R8 expected length.
g72_run_plan:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rcx
 mov rbx,r8
 mov rdi,r12
 mov rsi,r13
 mov edx,RENDER_TARGET_HEADLESS
 call neboc_render_plan_validate
 test eax,eax
 jnz .fail
 mov rdi,r12
 mov rsi,r13
 mov edx,RENDER_TARGET_HEADLESS
 call neboc_render_plan_measure
 cmp rax,rbx
 jne .fail
 mov rdi,r12
 mov rsi,r13
 mov edx,RENDER_TARGET_HEADLESS
 lea rcx,[rel g72_output_a]
 mov r8d,2048
 call neboc_render_plan_write
 cmp rax,rbx
 jne .fail
 lea rsi,[rel g72_output_a]
 mov rdi,r14
 mov rcx,rbx
 repe cmpsb
 jne .fail
 xor eax,eax
 jmp .done
.fail: mov eax,1
.done:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

%macro G72_RUN 3
 lea rdi,[rel %1]
 mov esi,1
 lea rcx,[rel %2]
 mov r8d,%3
 call g72_run_plan
 test eax,eax
 jnz .return
%endmacro

nebo_g072_source_probe:
 push rbx
 push r12
 push r13
 mov ebx,esi
 mov r12d,edi
 lea edi,[r12d+7200]
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
 mov eax,RENDER_E_UNAVAILABLE
 jmp .return
.m1:
 G72_RUN g72_node_1,g72_s1,g72_s1_len
 mov r13d,G072_ROUTE_STDOUT
.route_loop:
 mov edi,r13d
 call nebo_g072_route_validate
 cmp eax,r13d
 jne .return
 inc r13d
 cmp r13d,G072_ROUTE_MAX+1
 jb .route_loop
 mov r13d,RENDER_TARGET_PLAIN
.target_loop:
 mov edi,RENDER_TARGET_TOKEN_OUTPUT
 mov esi,r13d
 mov edx,RENDER_FLAG_FALLBACK
 call neboc_render_target_token_validate
 test eax,eax
 jnz .return
 inc r13d
 cmp r13d,RENDER_TARGET_HEADLESS+1
 jb .target_loop
 mov edi,RENDER_TARGET_HEADLESS
 mov esi,G072_TARGET_MASK_PLAIN|G072_TARGET_MASK_HEADLESS
 xor edx,edx
 call nebo_g072_select_target
 cmp eax,RENDER_TARGET_HEADLESS
 jne .return
 jmp .success
.m2:
 G72_RUN g72_node_2,g72_s2,g72_s2_len
 mov edi,17
 mov esi,29
 mov edx,RENDER_VISUAL_TEXT|RENDER_VISUAL_CONTRAST
 lea rcx,[rel g72_visual]
 mov r8d,16
 call nebo_g072_visual_record
 cmp eax,12
 jne .return
 jmp .success
.m3:
 G72_RUN g72_node_3,g72_s3,g72_s3_len
 jmp .success
.m4:
 G72_RUN g72_node_4,g72_s4,g72_s4_len
 lea rdi,[rel g72_event_payload]
 mov esi,g72_event_payload_len
 lea rdx,[rel g72_event]
 mov ecx,128
 call nebo_g072_event_jsonl
 test eax,eax
 js .return
 jmp .success
.m5:
 G72_RUN g72_node_5,g72_s5,g72_s5_len
 lea rdi,[rel g72_mirror_payload]
 mov esi,g72_mirror_payload_len
 lea rdx,[rel g72_mirror_a]
 lea rcx,[rel g72_mirror_b]
 mov r8d,32
 call nebo_g072_mirror_bytes
 cmp eax,g72_mirror_payload_len
 jne .return
 jmp .success
.m6:
 G72_RUN g72_node_6,g72_s6,g72_s6_len
 mov qword [rel g72_lifecycle],G072_LIFECYCLE_NEW
 mov qword [rel g72_lifecycle+8],0
 lea rdi,[rel g72_lifecycle]
 mov esi,RENDER_LIFECYCLE_OPEN
 call nebo_g072_lifecycle_step
 test eax,eax
 jnz .return
 lea rdi,[rel g72_lifecycle]
 mov esi,RENDER_LIFECYCLE_CLOSE
 call nebo_g072_lifecycle_step
 test eax,eax
 jnz .return
 jmp .success
.m7:
 G72_RUN g72_node_7,g72_s7,g72_s7_len
.success: mov eax,ebx
.return:
 pop r13
 pop r12
 pop rbx
 ret
%undef G72_RUN

nebo_g072_negative_probe:
 cmp edi,1
 je .token
 cmp edi,2
 je .aux
 cmp edi,3
 je .flags
 cmp edi,4
 je .route
 cmp edi,5
 je .visual
 cmp edi,6
 je .event
 cmp edi,7
 je .lifecycle
 mov eax,RENDER_E_UNAVAILABLE
 ret
.token:
 mov edi,99
 xor esi,esi
 mov edx,RENDER_FLAG_FALLBACK
 jmp neboc_render_target_token_validate
.aux:
 mov edi,RENDER_TARGET_TOKEN_FILE
 mov esi,99
 mov edx,RENDER_FLAG_FALLBACK
 jmp neboc_render_target_token_validate
.flags:
 lea rdi,[rel g72_bad_flags]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 jmp neboc_render_plan_validate
.route:
 mov edi,RENDER_TARGET_HTML
 mov esi,G072_TARGET_MASK_PLAIN
 mov edx,1
 call nebo_g072_select_target
 neg eax
 ret
.visual:
 lea rcx,[rel g72_visual]
 mov rax,0xa5a5a5a5a5a5a5a5
 mov [rcx],rax
 mov edi,1
 mov esi,1
 mov edx,RENDER_VISUAL_TEXT
 mov r8d,11
 call nebo_g072_visual_record
 neg eax
 ret
.event:
 lea rdi,[rel g72_event_prefix]
 mov esi,g72_event_prefix_len
 lea rdx,[rel g72_event]
 mov ecx,128
 call nebo_g072_event_jsonl
 neg eax
 ret
.lifecycle:
 mov qword [rel g72_lifecycle],G072_LIFECYCLE_NEW
 mov qword [rel g72_lifecycle+8],0
 lea rdi,[rel g72_lifecycle]
 mov esi,RENDER_LIFECYCLE_CLOSE
 jmp nebo_g072_lifecycle_step

; EDI mode, RSI output, RDX capacity -> RAX committed bytes or typed error.
nebo_g072_render_transcript:
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
 mov rax,-RENDER_E_UNAVAILABLE
 ret
.m1: lea rdi,[rel g72_node_1]
 jmp .write
.m2: lea rdi,[rel g72_node_2]
 jmp .write
.m3: lea rdi,[rel g72_node_3]
 jmp .write
.m4: lea rdi,[rel g72_node_4]
 jmp .write
.m5: lea rdi,[rel g72_node_5]
 jmp .write
.m6: lea rdi,[rel g72_node_6]
 jmp .write
.m7: lea rdi,[rel g72_node_7]
.write:
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 mov rcx,r10
 mov r8,r11
 jmp neboc_render_plan_write
