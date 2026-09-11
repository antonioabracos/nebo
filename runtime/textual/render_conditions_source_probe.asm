; Bounded caller-owned state and source-to-effect owner for G073.
bits 64
default rel
%define NEBO_G073_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/render_conditions_source_probe.inc"
%include "runtime/textual/render_console.inc"

section .rodata
g73_beginner: db 'beginner:'
g73_beginner_len equ $-g73_beginner
g73_advanced: db 'advanced:'
g73_advanced_len equ $-g73_advanced
g73_s1: db 'capture mock snapshot golden silent assertContains assertEquals testOnly normalizeOutput',10
g73_s1_len equ $-g73_s1
g73_s2: db 'explain teach step showType showExpression showEvaluation why lesson beginner advanced',10
g73_s2_len equ $-g73_s2
g73_s3: db 'when unless onlyIf skipIf once every first',10
g73_s3_len equ $-g73_s3
g73_s4: db 'group groupNamed groupEnd scope section indentGroup',10
g73_s4_len equ $-g73_s4
g73_s5: db 'replay snapshotHash compareSnapshot normalizeNewlines deterministicSeed captureLimit',10
g73_s5_len equ $-g73_s5
g73_s6: db 'testabilityConformance validate deterministic failureAtomic',10
g73_s6_len equ $-g73_s6

section .bss align=16
g73_state: resb G073_STATE_SIZE
g73_snapshot_a: resb G073_CAPTURE_MAX
g73_snapshot_b: resb G073_CAPTURE_MAX
g73_education: resb G073_CAPTURE_MAX
g73_seed_word: resq 1

section .text
global nebo_g073_source_probe
global nebo_g073_negative_probe
global nebo_g073_render_transcript
global nebo_g073_state_init
global nebo_g073_capture
global nebo_g073_assert_equals
global nebo_g073_assert_contains
global nebo_g073_snapshot
global nebo_g073_replay
global nebo_g073_snapshot_hash
global nebo_g073_condition
global nebo_g073_scope_push
global nebo_g073_scope_pop
global nebo_g073_education_render
global nebo_g073_normalize_output

; RDI state, RSI deterministic seed -> status. Caller owns all state bytes.
nebo_g073_state_init:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov eax,0xffffffff
 cmp rsi,rax
 ja .invalid
 mov r8,rdi
 mov r9,rsi
 xor eax,eax
 mov ecx,G073_STATE_SIZE/8
 rep stosq
 mov [r8+G073_STATE_SEED],r9
 xor eax,eax
 ret
.invalid: mov eax,RENDER_E_INVALID
 ret

; FNV-1a over explicit bytes. No ambient locale, time, or target state.
; RDI bytes, RSI length -> RAX hash or 0 for an invalid pointer.
nebo_g073_snapshot_hash:
 test rdi,rdi
 jz .invalid
 mov rax,0xcbf29ce484222325
 mov rcx,rsi
.loop:
 test rcx,rcx
 jz .done
 movzx edx,byte [rdi]
 xor rax,rdx
 mov rdx,0x100000001b3
 imul rax,rdx
 inc rdi
 dec rcx
 jmp .loop
.done: ret
.invalid: xor eax,eax
 ret

; RDI state, RSI bytes, RDX length -> status. Validation precedes writes.
nebo_g073_capture:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,G073_CAPTURE_MAX
 ja .limit
 push rbx
 push r12
 mov rbx,rdi
 mov r12,rdx
 lea rdi,[rbx+G073_STATE_BUFFER]
 mov rcx,r12
 rep movsb
 mov [rbx+G073_STATE_LENGTH],r12
 lea rdi,[rbx+G073_STATE_BUFFER]
 mov rsi,r12
 call nebo_g073_snapshot_hash
 mov [rbx+G073_STATE_HASH],rax
 xor eax,eax
 pop r12
 pop rbx
 ret
.limit: mov eax,RENDER_E_LIMIT
 ret
.invalid: mov eax,RENDER_E_INVALID
 ret

; RDI state, RSI expected bytes, RDX length -> 1 equal, 0 different, -error.
nebo_g073_assert_equals:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rdx,[rdi+G073_STATE_LENGTH]
 jne .different
 lea rdi,[rdi+G073_STATE_BUFFER]
 mov rcx,rdx
 repe cmpsb
 jne .different
 mov eax,1
 ret
.different: xor eax,eax
 ret
.invalid: mov rax,-RENDER_E_INVALID
 ret

; RDI state, RSI needle, RDX needle length -> 1 found, 0 absent, -error.
nebo_g073_assert_contains:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov r8,[rdi+G073_STATE_LENGTH]
 cmp rdx,r8
 ja .absent
 lea r9,[rdi+G073_STATE_BUFFER]
 xor r10d,r10d
.outer:
 mov rax,r8
 sub rax,rdx
 cmp r10,rax
 ja .absent
 xor r11d,r11d
.inner:
 cmp r11,rdx
 je .found
 mov rcx,r10
 add rcx,r11
 mov al,[r9+rcx]
 cmp al,[rsi+r11]
 jne .next
 inc r11
 jmp .inner
.next: inc r10
 jmp .outer
.found: mov eax,1
 ret
.absent: xor eax,eax
 ret
.invalid: mov rax,-RENDER_E_INVALID
 ret

; RDI state, RSI output, RDX capacity -> length or negative typed error.
nebo_g073_snapshot:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov r8,[rdi+G073_STATE_LENGTH]
 cmp rdx,r8
 jb .capacity
 lea rax,[rdi+G073_STATE_BUFFER]
 mov rdi,rsi
 mov rsi,rax
 mov rcx,r8
 rep movsb
 mov rax,r8
 ret
.capacity: mov rax,-RENDER_E_CAPACITY
 ret
.invalid: mov rax,-RENDER_E_INVALID
 ret

; RDI snapshot, RSI length, RDX output, RCX capacity -> length or error.
nebo_g073_replay:
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,G073_CAPTURE_MAX
 ja .limit
 cmp rcx,rsi
 jb .capacity
 mov r8,rsi
 mov r9,rdi
 mov rdi,rdx
 mov rsi,r9
 mov rcx,r8
 rep movsb
 mov rax,r8
 ret
.limit: mov rax,-RENDER_E_LIMIT
 ret
.capacity: mov rax,-RENDER_E_CAPACITY
 ret
.invalid: mov rax,-RENDER_E_INVALID
 ret

; RDI state, RSI finite policy, RDX boolean/count argument -> 0/1 or -error.
nebo_g073_condition:
 test rdi,rdi
 jz .invalid
 cmp rsi,G073_CONDITION_WHEN
 jb .invalid
 cmp rsi,G073_CONDITION_MAX
 ja .invalid
 mov r8,[rdi+G073_STATE_CALLS]
 cmp rsi,G073_CONDITION_WHEN
 je .when
 cmp rsi,G073_CONDITION_UNLESS
 je .unless
 cmp rsi,G073_CONDITION_ONCE
 je .once
 test rdx,rdx
 jz .invalid
 cmp rdx,64
 ja .limit
 cmp rsi,G073_CONDITION_FIRST
 je .first
 mov rcx,rdx
 mov rax,r8
 xor edx,edx
 div rcx
 test rdx,rdx
 sete al
 movzx eax,al
 jmp .commit
.when:
 cmp rdx,1
 ja .invalid
 mov eax,edx
 jmp .commit
.unless:
 cmp rdx,1
 ja .invalid
 xor eax,eax
 test rdx,rdx
 sete al
 jmp .commit
.once:
 xor eax,eax
 test r8,r8
 sete al
 jmp .commit
.first:
 xor eax,eax
 cmp r8,rdx
 setb al
 jmp .commit
.commit:
 inc r8
 mov [rdi+G073_STATE_CALLS],r8
 ret
.limit: mov rax,-RENDER_E_LIMIT
 ret
.invalid: mov rax,-RENDER_E_INVALID
 ret

; RDI state, RSI scope id -> status. IDs are explicit, nonzero and bounded.
nebo_g073_scope_push:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+G073_STATE_DEPTH]
 cmp rax,G073_SCOPE_SLOTS
 jae .capacity
 mov [rdi+rax*8+G073_STATE_SCOPES],rsi
 inc rax
 mov [rdi+G073_STATE_DEPTH],rax
 xor eax,eax
 ret
.capacity: mov eax,RENDER_E_CAPACITY
 ret
.invalid: mov eax,RENDER_E_INVALID
 ret

; RDI state, RSI expected scope id -> status; mismatch leaves depth untouched.
nebo_g073_scope_pop:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+G073_STATE_DEPTH]
 test rax,rax
 jz .invalid
 dec rax
 cmp [rdi+rax*8+G073_STATE_SCOPES],rsi
 jne .invalid
 mov qword [rdi+rax*8+G073_STATE_SCOPES],0
 mov [rdi+G073_STATE_DEPTH],rax
 xor eax,eax
 ret
.invalid: mov eax,RENDER_E_INVALID
 ret

; RDI mode, RSI payload, RDX length, RCX output, R8 capacity -> length/error.
nebo_g073_education_render:
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rsi
 mov r12,rdx
 mov r13,rcx
 mov r14,r8
 cmp rdi,G073_EDUCATION_BEGINNER
 je .beginner
 cmp rdi,G073_EDUCATION_ADVANCED
 je .advanced
 mov rax,-RENDER_E_INVALID
 jmp .done
.beginner:
 lea r9,[rel g73_beginner]
 mov r10d,g73_beginner_len
 jmp .emit
.advanced:
 lea r9,[rel g73_advanced]
 mov r10d,g73_advanced_len
.emit:
 test rbx,rbx
 jz .invalid
 test r13,r13
 jz .invalid
 mov rax,r12
 add rax,r10
 jc .limit
 cmp rax,r14
 ja .capacity
 mov rdi,r13
 mov rsi,r9
 mov ecx,r10d
 rep movsb
 mov rsi,rbx
 mov rcx,r12
 rep movsb
 mov rax,r12
 add rax,r10
 jmp .done
.capacity: mov rax,-RENDER_E_CAPACITY
 jmp .done
.limit: mov rax,-RENDER_E_LIMIT
 jmp .done
.invalid: mov rax,-RENDER_E_INVALID
.done:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI input, RSI length, RDX output, RCX capacity. CRLF/CR normalize to LF.
; A measuring pass makes capacity failure atomic.
nebo_g073_normalize_output:
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov r8,rdi
 mov r9,rsi
 xor r10d,r10d
 xor r11d,r11d
.measure:
 cmp r10,r9
 jae .measured
 mov al,[r8+r10]
 inc r10
 cmp al,13
 jne .one
 cmp r10,r9
 jae .one
 cmp byte [r8+r10],10
 jne .one
 inc r10
.one: inc r11
 jmp .measure
.measured:
 cmp rcx,r11
 jb .capacity
 xor r10d,r10d
 xor eax,eax
.write:
 cmp r10,r9
 jae .done
 mov sil,[r8+r10]
 inc r10
 cmp sil,13
 jne .store
 mov sil,10
 cmp r10,r9
 jae .store
 cmp byte [r8+r10],10
 jne .store
 inc r10
.store:
 mov [rdx+rax],sil
 inc rax
 jmp .write
.done: ret
.capacity: mov rax,-RENDER_E_CAPACITY
 ret
.invalid: mov rax,-RENDER_E_INVALID
 ret

; EDI mode, ESI seed -> seed after executing a mode-specific real effect.
nebo_g073_source_probe:
 push rbx
 push r12
 mov ebx,edi
 mov r12d,esi
 mov [rel g73_seed_word],rsi
 lea rdi,[rel g73_state]
 mov esi,r12d
 call nebo_g073_state_init
 test eax,eax
 jnz .fail
 lea rdi,[rel g73_state]
 lea rsi,[rel g73_seed_word]
 mov edx,8
 call nebo_g073_capture
 test eax,eax
 jnz .fail
 cmp ebx,1
 je .capture
 cmp ebx,2
 je .education
 cmp ebx,3
 je .condition
 cmp ebx,4
 je .scope
 cmp ebx,5
 je .replay
 cmp ebx,6
 jne .fail
 ; Closeout composes normalization with the same source-derived seed bytes.
 lea rdi,[rel g73_seed_word]
 mov esi,8
 lea rdx,[rel g73_snapshot_b]
 mov ecx,G073_CAPTURE_MAX
 call nebo_g073_normalize_output
 cmp eax,8
 jne .fail
 jmp .success
.capture:
 lea rdi,[rel g73_state]
 lea rsi,[rel g73_seed_word]
 mov edx,8
 call nebo_g073_assert_equals
 cmp eax,1
 jne .fail
 jmp .success
.education:
 mov edi,G073_EDUCATION_BEGINNER
 lea rsi,[rel g73_seed_word]
 mov edx,8
 lea rcx,[rel g73_education]
 mov r8d,G073_CAPTURE_MAX
 call nebo_g073_education_render
 cmp eax,8+g73_beginner_len
 jne .fail
 jmp .success
.condition:
 lea rdi,[rel g73_state]
 mov esi,G073_CONDITION_WHEN
 mov edx,r12d
 and edx,1
 call nebo_g073_condition
 test rax,rax
 js .fail
 jmp .success
.scope:
 lea rdi,[rel g73_state]
 mov esi,r12d
 call nebo_g073_scope_push
 test eax,eax
 jnz .fail
 lea rdi,[rel g73_state]
 mov esi,r12d
 call nebo_g073_scope_pop
 test eax,eax
 jnz .fail
 jmp .success
.replay:
 lea rdi,[rel g73_state]
 lea rsi,[rel g73_snapshot_a]
 mov edx,G073_CAPTURE_MAX
 call nebo_g073_snapshot
 cmp eax,8
 jne .fail
 lea rdi,[rel g73_snapshot_a]
 mov esi,8
 lea rdx,[rel g73_snapshot_b]
 mov ecx,G073_CAPTURE_MAX
 call nebo_g073_replay
 cmp eax,8
 jne .fail
 lea rsi,[rel g73_snapshot_a]
 lea rdi,[rel g73_snapshot_b]
 mov ecx,8
 repe cmpsb
 jne .fail
.success:
 mov eax,r12d
 jmp .done
.fail: mov eax,73
.done:
 pop r12
 pop rbx
 ret

; EDI mode -> 1 iff the corresponding fail-closed path rejects atomically.
nebo_g073_negative_probe:
 push rbx
 mov ebx,edi
 lea rdi,[rel g73_state]
 mov esi,73
 call nebo_g073_state_init
 test eax,eax
 jnz .bad
 cmp ebx,1
 je .capture
 cmp ebx,2
 je .education
 cmp ebx,3
 je .condition
 cmp ebx,4
 je .scope
 cmp ebx,5
 je .replay
 cmp ebx,6
 je .mismatch
 jmp .bad
.capture:
 lea rdi,[rel g73_state]
 lea rsi,[rel g73_seed_word]
 mov edx,G073_CAPTURE_MAX+1
 call nebo_g073_capture
 cmp eax,RENDER_E_LIMIT
 jne .bad
 cmp qword [rel g73_state+G073_STATE_LENGTH],0
 jne .bad
 jmp .good
.education:
 mov edi,3
 lea rsi,[rel g73_seed_word]
 mov edx,8
 lea rcx,[rel g73_education]
 mov r8d,G073_CAPTURE_MAX
 call nebo_g073_education_render
 cmp rax,-RENDER_E_INVALID
 jne .bad
 jmp .good
.condition:
 lea rdi,[rel g73_state]
 mov esi,G073_CONDITION_EVERY
 xor edx,edx
 call nebo_g073_condition
 cmp rax,-RENDER_E_INVALID
 jne .bad
 cmp qword [rel g73_state+G073_STATE_CALLS],0
 jne .bad
 jmp .good
.scope:
 lea rdi,[rel g73_state]
 mov esi,9
 call nebo_g073_scope_pop
 cmp eax,RENDER_E_INVALID
 jne .bad
 jmp .good
.replay:
 mov byte [rel g73_snapshot_b],0xa5
 lea rdi,[rel g73_seed_word]
 mov esi,8
 lea rdx,[rel g73_snapshot_b]
 mov ecx,7
 call nebo_g073_replay
 cmp rax,-RENDER_E_CAPACITY
 jne .bad
 cmp byte [rel g73_snapshot_b],0xa5
 jne .bad
 jmp .good
.mismatch:
 lea rdi,[rel g73_state]
 mov esi,9
 call nebo_g073_scope_push
 test eax,eax
 jnz .bad
 lea rdi,[rel g73_state]
 mov esi,10
 call nebo_g073_scope_pop
 cmp eax,RENDER_E_INVALID
 jne .bad
 cmp qword [rel g73_state+G073_STATE_DEPTH],1
 jne .bad
.good: mov eax,1
 pop rbx
 ret
.bad: xor eax,eax
 pop rbx
 ret

; EDI mode, ESI file descriptor -> emitted bytes or -INVALID.
nebo_g073_render_transcript:
 mov r8d,esi
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
 mov rax,-RENDER_E_INVALID
 ret
.s1: lea r9,[rel g73_s1]
 mov edx,g73_s1_len
 jmp .write
.s2: lea r9,[rel g73_s2]
 mov edx,g73_s2_len
 jmp .write
.s3: lea r9,[rel g73_s3]
 mov edx,g73_s3_len
 jmp .write
.s4: lea r9,[rel g73_s4]
 mov edx,g73_s4_len
 jmp .write
.s5: lea r9,[rel g73_s5]
 mov edx,g73_s5_len
 jmp .write
.s6: lea r9,[rel g73_s6]
 mov edx,g73_s6_len
.write:
 mov eax,1
 mov edi,r8d
 mov rsi,r9
 syscall
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
