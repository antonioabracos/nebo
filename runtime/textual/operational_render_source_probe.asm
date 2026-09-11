; Source-to-effect oracle and bounded operational state model for G070.
bits 64
default rel
%define NEBO_G070_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/operational_render_source_probe.inc"
%include "runtime/textual/render_console.inc"

section .rodata
g70_s1: db 'log ts=1042 level=info event=compile trace=tr-17 scope=build span=parse tag=nebo context={unit:4}'
g70_s1_len equ $-g70_s1
g70_s2: db 'buffer capacity=4 queued=3 flushed=3 mode=batch ownership=caller'
g70_s2_len equ $-g70_s2
g70_s3: db 'progress current=7 total=11 percent=63 metric=items counter=7 bytes=4096 speed=512'
g70_s3_len equ $-g70_s3
g70_s4: db 'time fake_ms=4242 elapsed_ms=242 duration_ms=200 iso=1970-01-01T00:00:04.242Z timezone=UTC'
g70_s4_len equ $-g70_s4
g70_s5: db 'rate fake_ms=1250 interval_ms=250 emitted=2 rejected=1 queue=0 policy=reject-newest'
g70_s5_len equ $-g70_s5
g70_s6: db 'operations-conformance:50/50 deterministic=headless failure-atomic=yes'
g70_s6_len equ $-g70_s6

section .data align=16
g70_nodes_1: dq RENDER_NODE_OPERATION,RENDER_FLAG_FALLBACK,g70_s1,g70_s1_len,RENDER_OPERATION_LOG,1
g70_nodes_2: dq RENDER_NODE_OPERATION,RENDER_FLAG_FALLBACK,g70_s2,g70_s2_len,RENDER_OPERATION_BUFFER,4
g70_nodes_3: dq RENDER_NODE_OPERATION,RENDER_FLAG_FALLBACK,g70_s3,g70_s3_len,RENDER_OPERATION_PROGRESS,11
g70_nodes_4: dq RENDER_NODE_OPERATION,RENDER_FLAG_FALLBACK,g70_s4,g70_s4_len,RENDER_OPERATION_TIME,4242
g70_nodes_5: dq RENDER_NODE_OPERATION,RENDER_FLAG_FALLBACK,g70_s5,g70_s5_len,RENDER_OPERATION_RATE,250
g70_nodes_6: dq RENDER_NODE_OPERATION,RENDER_FLAG_FALLBACK,g70_s6,g70_s6_len,RENDER_OPERATION_CONFORMANCE,0
g70_bad_token: dq RENDER_NODE_OPERATION,RENDER_FLAG_FALLBACK,g70_s1,g70_s1_len,99,0
g70_bad_capacity: dq RENDER_NODE_OPERATION,RENDER_FLAG_FALLBACK,g70_s2,g70_s2_len,RENDER_OPERATION_BUFFER,9
g70_bad_private: dq RENDER_NODE_OPERATION,RENDER_FLAG_FALLBACK|RENDER_FLAG_PRIVATE,g70_s1,g70_s1_len,RENDER_OPERATION_LOG,1

section .bss align=16
g70_output_a: resb 2048
g70_output_b: resb 2048
g70_atomic: resb 2048
g70_model_state: resb G070_STATE_SIZE
g70_model_snapshot: resb G070_STATE_SIZE
g70_model_item: resq 1

section .text
extern neboc_render_feature_validate
extern neboc_render_plan_validate
extern neboc_render_plan_measure
extern neboc_render_plan_write
extern neboc_render_operation_token_validate
global nebo_g070_source_probe
global nebo_g070_negative_probe
global nebo_g070_render_transcript
global nebo_g070_state_init
global nebo_g070_enqueue
global nebo_g070_advance
global nebo_g070_drain
global nebo_g070_progress
global nebo_g070_snapshot

; RDI state, RSI capacity, RDX interval_ms, RCX fake_start_ms -> status.
; Validation precedes all writes, so failure leaves caller state untouched.
nebo_g070_state_init:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,G070_STATE_QUEUE_SLOTS
 ja .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,RENDER_OPERATION_MAX_INTERVAL
 ja .invalid
 cmp rcx,RENDER_OPERATION_MAX_FAKE_MS
 ja .invalid
 mov r8,rdi
 mov r9,rsi
 mov r10,rdx
 mov r11,rcx
 xor eax,eax
 mov ecx,G070_STATE_SIZE/8
 rep stosq
 mov [r8+G070_STATE_NOW],r11
 mov [r8+G070_STATE_INTERVAL],r10
 mov [r8+G070_STATE_CAPACITY],r9
 mov rax,r11
 cmp rax,r10
 jb .ok
 sub rax,r10
 mov [r8+G070_STATE_LAST],rax
.ok: xor eax,eax
 ret
.invalid: mov eax,RENDER_E_INVALID
 ret

; RDI state, RSI monotonically meaningful event sequence -> status.
nebo_g070_enqueue:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rcx,[rdi+G070_STATE_CAPACITY]
 test rcx,rcx
 jz .invalid
 cmp rcx,G070_STATE_QUEUE_SLOTS
 ja .invalid
 mov rdx,[rdi+G070_STATE_COUNT]
 cmp rdx,rcx
 jae .capacity
 mov rax,[rdi+G070_STATE_HEAD]
 add rax,rdx
 xor edx,edx
 div rcx
 mov [rdi+rdx*8+G070_STATE_QUEUE],rsi
 inc qword [rdi+G070_STATE_COUNT]
 inc qword [rdi+G070_STATE_ENQUEUED]
 xor eax,eax
 ret
.capacity: mov eax,RENDER_E_CAPACITY
 ret
.invalid: mov eax,RENDER_E_INVALID
 ret

; RDI state, RSI delta_ms -> status. No host clock is consulted.
nebo_g070_advance:
 test rdi,rdi
 jz .invalid
 cmp rsi,RENDER_OPERATION_MAX_FAKE_MS
 ja .invalid
 mov rax,[rdi+G070_STATE_NOW]
 add rax,rsi
 jc .limit
 cmp rax,RENDER_OPERATION_MAX_FAKE_MS
 ja .limit
 mov [rdi+G070_STATE_NOW],rax
 xor eax,eax
 ret
.invalid: mov eax,RENDER_E_INVALID
 ret
.limit: mov eax,RENDER_E_LIMIT
 ret

; RDI state, RSI output qword buffer, RDX item capacity.
; RAX is 0/1 emitted items or a negative typed error. State/output are
; untouched on error or while the fake-clock rate window is closed.
nebo_g070_drain:
 test rdi,rdi
 jz .invalid
 mov rcx,[rdi+G070_STATE_COUNT]
 test rcx,rcx
 jz .none
 mov r8,[rdi+G070_STATE_NOW]
 mov r9,[rdi+G070_STATE_LAST]
 cmp r8,r9
 jb .invalid
 sub r8,r9
 cmp r8,[rdi+G070_STATE_INTERVAL]
 jb .none
 test rsi,rsi
 jz .capacity
 test rdx,rdx
 jz .capacity
 mov rax,[rdi+G070_STATE_HEAD]
 mov r10,[rdi+rax*8+G070_STATE_QUEUE]
 mov [rsi],r10
 inc rax
 cmp rax,[rdi+G070_STATE_CAPACITY]
 jb .store_head
 xor eax,eax
.store_head:
 mov [rdi+G070_STATE_HEAD],rax
 dec qword [rdi+G070_STATE_COUNT]
 inc qword [rdi+G070_STATE_EMITTED]
 mov rax,[rdi+G070_STATE_NOW]
 mov [rdi+G070_STATE_LAST],rax
 mov eax,1
 ret
.none: xor eax,eax
 ret
.capacity: mov rax,-RENDER_E_CAPACITY
 ret
.invalid: mov rax,-RENDER_E_INVALID
 ret

; RDI state, RSI current, RDX total -> status, failure atomic.
nebo_g070_progress:
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,RENDER_OPERATION_MAX_PROGRESS
 ja .limit
 cmp rsi,rdx
 ja .invalid
 mov [rdi+G070_STATE_PROGRESS],rsi
 mov [rdi+G070_STATE_TOTAL],rdx
 xor eax,eax
 ret
.invalid: mov eax,RENDER_E_INVALID
 ret
.limit: mov eax,RENDER_E_LIMIT
 ret

; RDI state, RSI caller-owned snapshot (G070_STATE_SIZE bytes) -> status.
nebo_g070_snapshot:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov r8,rdi
 mov rdi,rsi
 mov rsi,r8
 mov ecx,G070_STATE_SIZE/8
 rep movsq
 xor eax,eax
 ret
.invalid: mov eax,RENDER_E_INVALID
 ret

; RDI nodes, RSI count, EDX target, RCX expected, R8 expected length.
g70_run_plan:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
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
 lea rdi,[rel g70_output_a]
 mov ecx,2048
 mov al,0xa5
 rep stosb
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 lea rcx,[rel g70_output_a]
 mov r8d,2048
 call neboc_render_plan_write
 cmp rax,rbx
 jne .fail
 lea rsi,[rel g70_output_a]
 mov rdi,r15
 mov rcx,rbx
 repe cmpsb
 jne .fail
 lea rdi,[rel g70_output_b]
 mov ecx,2048
 mov al,0x5a
 rep stosb
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 lea rcx,[rel g70_output_b]
 mov r8d,2048
 call neboc_render_plan_write
 cmp rax,rbx
 jne .fail
 lea rsi,[rel g70_output_a]
 lea rdi,[rel g70_output_b]
 mov rcx,rbx
 repe cmpsb
 jne .fail
 lea rdi,[rel g70_atomic]
 mov ecx,2048
 mov al,0xcc
 rep stosb
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 lea rcx,[rel g70_atomic]
 lea r8,[rbx-1]
 call neboc_render_plan_write
 cmp rax,-RENDER_E_CAPACITY
 jne .fail
 cmp byte [rel g70_atomic],0xcc
 jne .fail
 xor eax,eax
 jmp .done
.fail: mov eax,1
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

g70_exercise_model:
 lea rdi,[rel g70_model_state]
 mov esi,2
 mov edx,250
 mov ecx,1000
 call nebo_g070_state_init
 test eax,eax
 jnz .fail
 lea rdi,[rel g70_model_state]
 mov esi,41
 call nebo_g070_enqueue
 test eax,eax
 jnz .fail
 lea rdi,[rel g70_model_state]
 mov esi,42
 call nebo_g070_enqueue
 test eax,eax
 jnz .fail
 lea rdi,[rel g70_model_state]
 mov esi,43
 call nebo_g070_enqueue
 cmp eax,RENDER_E_CAPACITY
 jne .fail
 lea rdi,[rel g70_model_state]
 lea rsi,[rel g70_model_item]
 mov edx,1
 call nebo_g070_drain
 cmp eax,1
 jne .fail
 cmp qword [rel g70_model_item],41
 jne .fail
 lea rdi,[rel g70_model_state]
 lea rsi,[rel g70_model_item]
 mov edx,1
 call nebo_g070_drain
 test eax,eax
 jnz .fail
 lea rdi,[rel g70_model_state]
 mov esi,249
 call nebo_g070_advance
 test eax,eax
 jnz .fail
 lea rdi,[rel g70_model_state]
 lea rsi,[rel g70_model_item]
 mov edx,1
 call nebo_g070_drain
 test eax,eax
 jnz .fail
 lea rdi,[rel g70_model_state]
 mov esi,1
 call nebo_g070_advance
 test eax,eax
 jnz .fail
 lea rdi,[rel g70_model_state]
 lea rsi,[rel g70_model_item]
 mov edx,1
 call nebo_g070_drain
 cmp eax,1
 jne .fail
 cmp qword [rel g70_model_item],42
 jne .fail
 lea rdi,[rel g70_model_state]
 mov esi,7
 mov edx,11
 call nebo_g070_progress
 test eax,eax
 jnz .fail
 lea rdi,[rel g70_model_state]
 lea rsi,[rel g70_model_snapshot]
 call nebo_g070_snapshot
 test eax,eax
 jnz .fail
 cmp qword [rel g70_model_snapshot+G070_STATE_NOW],1250
 jne .fail
 cmp qword [rel g70_model_snapshot+G070_STATE_COUNT],0
 jne .fail
 cmp qword [rel g70_model_snapshot+G070_STATE_ENQUEUED],2
 jne .fail
 cmp qword [rel g70_model_snapshot+G070_STATE_EMITTED],2
 jne .fail
 cmp qword [rel g70_model_snapshot+G070_STATE_PROGRESS],7
 jne .fail
 cmp qword [rel g70_model_snapshot+G070_STATE_TOTAL],11
 jne .fail
 xor eax,eax
 ret
.fail: mov eax,1
 ret

%macro G70_RUN 5
 lea rdi,[rel %1]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 lea rcx,[rel %2]
 mov r8d,%3
 call g70_run_plan
 test eax,eax
 jnz .return
 mov edi,%4
 mov esi,%5
 mov edx,RENDER_FLAG_FALLBACK
 call neboc_render_operation_token_validate
 test eax,eax
 jnz .return
%endmacro

nebo_g070_source_probe:
 push rbx
 push r12
 mov ebx,esi
 mov r12d,edi
 lea edi,[r12d+7000]
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
 mov eax,RENDER_E_UNAVAILABLE
 jmp .return
.m1: G70_RUN g70_nodes_1,g70_s1,g70_s1_len,RENDER_OPERATION_LOG,1
 jmp .success
.m2: G70_RUN g70_nodes_2,g70_s2,g70_s2_len,RENDER_OPERATION_BUFFER,4
 call g70_exercise_model
 test eax,eax
 jnz .return
 jmp .success
.m3: G70_RUN g70_nodes_3,g70_s3,g70_s3_len,RENDER_OPERATION_PROGRESS,11
 jmp .success
.m4: G70_RUN g70_nodes_4,g70_s4,g70_s4_len,RENDER_OPERATION_TIME,4242
 jmp .success
.m5: G70_RUN g70_nodes_5,g70_s5,g70_s5_len,RENDER_OPERATION_RATE,250
 call g70_exercise_model
 test eax,eax
 jnz .return
 jmp .success
.m6: G70_RUN g70_nodes_6,g70_s6,g70_s6_len,RENDER_OPERATION_CONFORMANCE,0
.success: mov eax,ebx
.return:
 pop r12
 pop rbx
 ret
%undef G70_RUN

nebo_g070_negative_probe:
 cmp edi,1
 je .token
 cmp edi,2
 je .capacity
 cmp edi,3
 je .privacy
 cmp edi,4
 je .feature
 cmp edi,5
 je .progress
 cmp edi,6
 je .advance
 mov eax,RENDER_E_UNAVAILABLE
 ret
.token:
 mov edi,99
 xor esi,esi
 mov edx,RENDER_FLAG_FALLBACK
 jmp neboc_render_operation_token_validate
.capacity:
 lea rdi,[rel g70_bad_capacity]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 jmp neboc_render_plan_validate
.privacy:
 lea rdi,[rel g70_bad_private]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 jmp neboc_render_plan_validate
.feature:
 mov edi,7001
 xor esi,esi
 mov edx,8
 mov ecx,1
 mov r8d,RENDER_TARGET_HEADLESS
 jmp neboc_render_feature_validate
.progress:
 lea rdi,[rel g70_model_state]
 mov esi,12
 mov edx,11
 jmp nebo_g070_progress
.advance:
 lea rdi,[rel g70_model_state]
 mov rsi,RENDER_OPERATION_MAX_FAKE_MS+1
 jmp nebo_g070_advance

; EDI mode, RSI output, RDX capacity -> RAX committed bytes or typed error.
nebo_g070_render_transcript:
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
 mov rax,-RENDER_E_UNAVAILABLE
 ret
.m1: lea rdi,[rel g70_nodes_1]
 jmp .write
.m2: lea rdi,[rel g70_nodes_2]
 jmp .write
.m3: lea rdi,[rel g70_nodes_3]
 jmp .write
.m4: lea rdi,[rel g70_nodes_4]
 jmp .write
.m5: lea rdi,[rel g70_nodes_5]
 jmp .write
.m6: lea rdi,[rel g70_nodes_6]
.write:
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 mov rcx,r10
 mov r8,r11
 jmp neboc_render_plan_write
