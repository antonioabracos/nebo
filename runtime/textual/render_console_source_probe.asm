; Source-to-effect oracle for G066. Each compiler-emitted mode renders a real,
; immutable RenderPlan, verifies measured and committed bytes, repeats the
; render for determinism and checks failure atomicity before returning seed.
bits 64
default rel
%define NEBO_G066_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/render_console_source_probe.inc"
%include "runtime/textual/render_console.inc"

section .rodata
g66_lbracket: db '['
g66_rbracket: db ']'
g66_mid: db ']['
g66_alpha: db 'alpha'
g66_lparen: db '('
g66_rparen: db ')'
g66_red: db 'red'
g66_green: db 'green'
g66_blue: db 'blue'
g66_comma: db ','
g66_unicode: db '<',0xc3,0xa9,'&','>'
g66_left: db '  left'
g66_gap: db '    '
g66_right: db 'right'
g66_tail: db 'tail'
g66_stable: db 'stable'
g66_expected_1: db '[alpha][alpha]',10
g66_expected_1_len equ $-g66_expected_1
g66_expected_2: db '(red,green,blue)'
g66_expected_2_len equ $-g66_expected_2
g66_expected_3: db '&lt;',0xc3,0xa9,'&amp;&gt;'
g66_expected_3_len equ $-g66_expected_3
g66_expected_4: db '  left    right',10,'tail'
g66_expected_4_len equ $-g66_expected_4
g66_expected_5: db 'stable',10
g66_expected_5_len equ $-g66_expected_5

section .data align=16
g66_nodes_1:
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,g66_lbracket,1,0,0
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,g66_alpha,5,0,0
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,g66_mid,2,0,0
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,g66_alpha,5,0,0
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,g66_rbracket,1,0,0
 dq RENDER_NODE_BREAK,RENDER_FLAG_FALLBACK,0,0,0,0
g66_nodes_2:
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,g66_lparen,1,0,0
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,g66_red,3,0,0
 dq RENDER_NODE_SEPARATOR,RENDER_FLAG_FALLBACK,g66_comma,1,0,0
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,g66_green,5,0,0
 dq RENDER_NODE_SEPARATOR,RENDER_FLAG_FALLBACK,g66_comma,1,0,0
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,g66_blue,4,0,0
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,g66_rparen,1,0,0
g66_nodes_3:
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,g66_unicode,5,0,0
g66_nodes_4:
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,g66_left,6,0,0
 dq RENDER_NODE_SEPARATOR,RENDER_FLAG_FALLBACK,g66_gap,4,0,0
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,g66_right,5,0,0
 dq RENDER_NODE_BREAK,RENDER_FLAG_FALLBACK,0,0,0,0
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,g66_tail,4,0,0
g66_nodes_5:
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,g66_stable,6,0,0
 dq RENDER_NODE_BREAK,RENDER_FLAG_FALLBACK,0,0,0,0
g66_invalid_node:
 dq RENDER_NODE_TEXT,0,g66_stable,6,0,0
g66_private_node:
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK|RENDER_FLAG_PRIVATE,g66_stable,6,0,0

section .bss align=16
g66_output_a: resb 512
g66_output_b: resb 512
g66_atomic: resb 512

section .text
extern neboc_render_plan_validate
extern neboc_render_plan_measure
extern neboc_render_plan_write
global nebo_g066_source_probe
global nebo_g066_negative_probe

; RDI nodes, RSI count, EDX target, RCX expected, R8 expected length.
g66_run_plan:
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
 lea rdi,[rel g66_output_a]
 mov ecx,512
 mov al,0xa5
 rep stosb
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 lea rcx,[rel g66_output_a]
 mov r8d,512
 call neboc_render_plan_write
 cmp rax,rbx
 jne .fail
 lea rsi,[rel g66_output_a]
 mov rdi,r15
 mov rcx,rbx
 repe cmpsb
 jne .fail
 lea rdi,[rel g66_output_b]
 mov ecx,512
 mov al,0x5a
 rep stosb
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 lea rcx,[rel g66_output_b]
 mov r8d,512
 call neboc_render_plan_write
 cmp rax,rbx
 jne .fail
 lea rsi,[rel g66_output_a]
 lea rdi,[rel g66_output_b]
 mov rcx,rbx
 repe cmpsb
 jne .fail
 test rbx,rbx
 jz .ok
 lea rdi,[rel g66_atomic]
 mov ecx,512
 mov al,0xcc
 rep stosb
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 lea rcx,[rel g66_atomic]
 lea r8,[rbx-1]
 call neboc_render_plan_write
 cmp rax,-RENDER_E_CAPACITY
 jne .fail
 cmp byte [rel g66_atomic],0xcc
 jne .fail
.ok:
 xor eax,eax
 jmp .done
.fail:
 mov eax,1
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

nebo_g066_source_probe:
 push rbx
 mov ebx,esi
 cmp edi,1
 je .mode1
 cmp edi,2
 je .mode2
 cmp edi,3
 je .mode3
 cmp edi,4
 je .mode4
 cmp edi,5
 je .mode5
 mov eax,RENDER_E_UNAVAILABLE
 jmp .return
.mode1:
 lea rdi,[rel g66_nodes_1]
 mov esi,6
 mov edx,RENDER_TARGET_PLAIN
 lea rcx,[rel g66_expected_1]
 mov r8d,g66_expected_1_len
 jmp .run
.mode2:
 lea rdi,[rel g66_nodes_2]
 mov esi,7
 mov edx,RENDER_TARGET_PLAIN
 lea rcx,[rel g66_expected_2]
 mov r8d,g66_expected_2_len
 jmp .run
.mode3:
 lea rdi,[rel g66_nodes_3]
 mov esi,1
 mov edx,RENDER_TARGET_HTML
 lea rcx,[rel g66_expected_3]
 mov r8d,g66_expected_3_len
 jmp .run
.mode4:
 lea rdi,[rel g66_nodes_4]
 mov esi,5
 mov edx,RENDER_TARGET_PLAIN
 lea rcx,[rel g66_expected_4]
 mov r8d,g66_expected_4_len
 jmp .run
.mode5:
 lea rdi,[rel g66_nodes_5]
 mov esi,2
 mov edx,RENDER_TARGET_HEADLESS
 lea rcx,[rel g66_expected_5]
 mov r8d,g66_expected_5_len
.run:
 call g66_run_plan
 test eax,eax
 jnz .return
 mov eax,ebx
.return:
 pop rbx
 ret

; EDI case -> typed negative result for direct adversarial runtime tests.
nebo_g066_negative_probe:
 cmp edi,1
 je .invalid_flags
 cmp edi,2
 je .private
 cmp edi,3
 je .limit
 cmp edi,4
 je .target
 mov eax,RENDER_E_UNAVAILABLE
 ret
.invalid_flags:
 lea rdi,[rel g66_invalid_node]
 mov esi,1
 mov edx,RENDER_TARGET_PLAIN
 call neboc_render_plan_validate
 ret
.private:
 lea rdi,[rel g66_private_node]
 mov esi,1
 mov edx,RENDER_TARGET_PLAIN
 call neboc_render_plan_validate
 ret
.limit:
 lea rdi,[rel g66_nodes_1]
 mov esi,RENDER_MAX_NODES+1
 mov edx,RENDER_TARGET_PLAIN
 call neboc_render_plan_validate
 ret
.target:
 lea rdi,[rel g66_nodes_1]
 mov esi,1
 xor edx,edx
 call neboc_render_plan_validate
 ret
