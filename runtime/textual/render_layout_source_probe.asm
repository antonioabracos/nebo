; Source-to-effect oracle for G068 bounded RenderPlan structure tokens.
bits 64
default rel
%define NEBO_G068_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/render_layout_source_probe.inc"
%include "runtime/textual/render_console.inc"

section .rodata
g68_s1_a: db '# Nebo Layout'
g68_s1_a_len equ $-g68_s1_a
g68_s1_b: db 'Section'
g68_s1_b_len equ $-g68_s1_b
g68_s1_c: db '  body'
g68_s1_c_len equ $-g68_s1_c
g68_expected_1: db '# Nebo Layout',10,'Section',10,'  body'
g68_expected_1_len equ $-g68_expected_1

g68_s2: db 'name | score',10,'Ada | 7',10,'Lin | 9',10,'Total | 16'
g68_s2_len equ $-g68_s2
g68_expected_2 equ g68_s2
g68_expected_2_len equ g68_s2_len

g68_s3: db '1. alpha',10,'2. beta',10,'[ ] gamma'
g68_s3_len equ $-g68_s3
g68_expected_3 equ g68_s3
g68_expected_3_len equ g68_s3_len

g68_s4: db 'count=3',10,'first=21',10,'last=55',10,'sample=34'
g68_s4_len equ $-g68_s4
g68_expected_4 equ g68_s4
g68_expected_4_len equ g68_s4_len

g68_s5: db '# Layout Guide',10,'> Note: bounded',10,'[example](#layout)'
g68_s5_len equ $-g68_s5
g68_expected_5 equ g68_s5
g68_expected_5_len equ g68_s5_len

g68_s6_a: db 'left'
g68_s6_a_len equ $-g68_s6_a
g68_s6_b: db '  centered'
g68_s6_b_len equ $-g68_s6_b
g68_s6_c: db '           right'
g68_s6_c_len equ $-g68_s6_c
g68_expected_6: db 'left',10,'  centered',10,'           right'
g68_expected_6_len equ $-g68_expected_6

g68_s7: db 'layout-conformance:75/75'
g68_s7_len equ $-g68_s7
g68_expected_7 equ g68_s7
g68_expected_7_len equ g68_s7_len

section .data
align 16
g68_nodes_1:
 dq RENDER_NODE_STRUCTURE,RENDER_FLAG_FALLBACK,g68_s1_a,g68_s1_a_len,RENDER_STRUCTURE_TITLE,0
 dq RENDER_NODE_BREAK,RENDER_FLAG_FALLBACK,0,0,0,0
 dq RENDER_NODE_STRUCTURE,RENDER_FLAG_FALLBACK,g68_s1_b,g68_s1_b_len,RENDER_STRUCTURE_SECTION,0
 dq RENDER_NODE_BREAK,RENDER_FLAG_FALLBACK,0,0,0,0
 dq RENDER_NODE_STRUCTURE,RENDER_FLAG_FALLBACK,g68_s1_c,g68_s1_c_len,RENDER_STRUCTURE_ALIGNMENT,0
g68_nodes_1_count equ ($-g68_nodes_1)/RENDER_NODE_SIZE
g68_nodes_2:
 dq RENDER_NODE_STRUCTURE,RENDER_FLAG_FALLBACK,g68_s2,g68_s2_len,RENDER_STRUCTURE_TABLE,0
g68_nodes_2_count equ ($-g68_nodes_2)/RENDER_NODE_SIZE
g68_nodes_3:
 dq RENDER_NODE_STRUCTURE,RENDER_FLAG_FALLBACK,g68_s3,g68_s3_len,RENDER_STRUCTURE_LIST,0
g68_nodes_3_count equ ($-g68_nodes_3)/RENDER_NODE_SIZE
g68_nodes_4:
 dq RENDER_NODE_STRUCTURE,RENDER_FLAG_FALLBACK,g68_s4,g68_s4_len,RENDER_STRUCTURE_COLLECTION,0
g68_nodes_4_count equ ($-g68_nodes_4)/RENDER_NODE_SIZE
g68_nodes_5:
 dq RENDER_NODE_STRUCTURE,RENDER_FLAG_FALLBACK,g68_s5,g68_s5_len,RENDER_STRUCTURE_DOCUMENTATION,0
g68_nodes_5_count equ ($-g68_nodes_5)/RENDER_NODE_SIZE
g68_nodes_6:
 dq RENDER_NODE_STRUCTURE,RENDER_FLAG_FALLBACK,g68_s6_a,g68_s6_a_len,RENDER_STRUCTURE_WIDTH,16
 dq RENDER_NODE_BREAK,RENDER_FLAG_FALLBACK,0,0,0,0
 dq RENDER_NODE_STRUCTURE,RENDER_FLAG_FALLBACK,g68_s6_b,g68_s6_b_len,RENDER_STRUCTURE_ALIGNMENT,0
 dq RENDER_NODE_BREAK,RENDER_FLAG_FALLBACK,0,0,0,0
 dq RENDER_NODE_STRUCTURE,RENDER_FLAG_FALLBACK,g68_s6_c,g68_s6_c_len,RENDER_STRUCTURE_ALIGNMENT,0
g68_nodes_6_count equ ($-g68_nodes_6)/RENDER_NODE_SIZE
g68_nodes_7:
 dq RENDER_NODE_STRUCTURE,RENDER_FLAG_FALLBACK,g68_s7,g68_s7_len,RENDER_STRUCTURE_CONFORMANCE,0
g68_nodes_7_count equ ($-g68_nodes_7)/RENDER_NODE_SIZE

g68_bad_width:
 dq RENDER_NODE_STRUCTURE,RENDER_FLAG_FALLBACK,g68_s7,g68_s7_len,RENDER_STRUCTURE_WIDTH,0
g68_bad_private:
 dq RENDER_NODE_STRUCTURE,RENDER_FLAG_FALLBACK|RENDER_FLAG_PRIVATE,g68_s7,g68_s7_len,RENDER_STRUCTURE_CONFORMANCE,0

section .bss align=16
g68_output_a: resb 1024
g68_output_b: resb 1024
g68_atomic: resb 1024

section .text
extern neboc_render_feature_validate
extern neboc_render_plan_validate
extern neboc_render_plan_measure
extern neboc_render_plan_write
extern neboc_render_structure_token_validate
global nebo_g068_source_probe
global nebo_g068_negative_probe
global nebo_g068_render_transcript

; RDI nodes, RSI count, EDX target, RCX expected, R8 expected length.
g68_run_plan:
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
 lea rdi,[rel g68_output_a]
 mov ecx,1024
 mov al,0xa5
 rep stosb
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 lea rcx,[rel g68_output_a]
 mov r8d,1024
 call neboc_render_plan_write
 cmp rax,rbx
 jne .fail
 lea rsi,[rel g68_output_a]
 mov rdi,r15
 mov rcx,rbx
 repe cmpsb
 jne .fail
 lea rdi,[rel g68_output_b]
 mov ecx,1024
 mov al,0x5a
 rep stosb
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 lea rcx,[rel g68_output_b]
 mov r8d,1024
 call neboc_render_plan_write
 cmp rax,rbx
 jne .fail
 lea rsi,[rel g68_output_a]
 lea rdi,[rel g68_output_b]
 mov rcx,rbx
 repe cmpsb
 jne .fail
 lea rdi,[rel g68_atomic]
 mov ecx,1024
 mov al,0xcc
 rep stosb
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 lea rcx,[rel g68_atomic]
 lea r8,[rbx-1]
 call neboc_render_plan_write
 cmp rax,-RENDER_E_CAPACITY
 jne .fail
 cmp byte [rel g68_atomic],0xcc
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

%macro G68_RUN 5
 lea rdi,[rel %1]
 mov esi,%2
 mov edx,%3
 lea rcx,[rel %4]
 mov r8d,%5
 call g68_run_plan
 test eax,eax
 jnz .return
%endmacro

nebo_g068_source_probe:
 push rbx
 push r12
 mov ebx,esi
 mov r12d,edi
 lea edi,[r12d+6800]
 mov esi,RENDER_FLAG_FALLBACK
 mov edx,128
 mov ecx,2
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
.m1: G68_RUN g68_nodes_1,g68_nodes_1_count,RENDER_TARGET_PLAIN,g68_expected_1,g68_expected_1_len
 jmp .success
.m2: G68_RUN g68_nodes_2,g68_nodes_2_count,RENDER_TARGET_MARKDOWN,g68_expected_2,g68_expected_2_len
 jmp .success
.m3: G68_RUN g68_nodes_3,g68_nodes_3_count,RENDER_TARGET_PLAIN,g68_expected_3,g68_expected_3_len
 jmp .success
.m4: G68_RUN g68_nodes_4,g68_nodes_4_count,RENDER_TARGET_HEADLESS,g68_expected_4,g68_expected_4_len
 jmp .success
.m5: G68_RUN g68_nodes_5,g68_nodes_5_count,RENDER_TARGET_MARKDOWN,g68_expected_5,g68_expected_5_len
 jmp .success
.m6: G68_RUN g68_nodes_6,g68_nodes_6_count,RENDER_TARGET_HEADLESS,g68_expected_6,g68_expected_6_len
 jmp .success
.m7: G68_RUN g68_nodes_7,g68_nodes_7_count,RENDER_TARGET_HEADLESS,g68_expected_7,g68_expected_7_len
.success: mov eax,ebx
.return:
 pop r12
 pop rbx
 ret
%undef G68_RUN

nebo_g068_negative_probe:
 cmp edi,1
 je .token
 cmp edi,2
 je .width
 cmp edi,3
 je .node_width
 cmp edi,4
 je .privacy
 cmp edi,5
 je .feature
 mov eax,RENDER_E_UNAVAILABLE
 ret
.token:
 mov edi,99
 xor esi,esi
 jmp neboc_render_structure_token_validate
.width:
 mov edi,RENDER_STRUCTURE_WIDTH
 mov esi,RENDER_MAX_DISPLAY_CELLS+1
 jmp neboc_render_structure_token_validate
.node_width:
 lea rdi,[rel g68_bad_width]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 jmp neboc_render_plan_validate
.privacy:
 lea rdi,[rel g68_bad_private]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 jmp neboc_render_plan_validate
.feature:
 mov edi,6801
 xor esi,esi
 mov edx,8
 mov ecx,1
 mov r8d,RENDER_TARGET_HEADLESS
 jmp neboc_render_feature_validate

; EDI mode, RSI output, RDX capacity -> RAX committed bytes or typed error.
; This exposes observed renderer bytes to an oracle outside this object.
nebo_g068_render_transcript:
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
.m1:
 lea rdi,[rel g68_nodes_1]
 mov esi,g68_nodes_1_count
 mov edx,RENDER_TARGET_PLAIN
 jmp .write
.m2:
 lea rdi,[rel g68_nodes_2]
 mov esi,g68_nodes_2_count
 mov edx,RENDER_TARGET_MARKDOWN
 jmp .write
.m3:
 lea rdi,[rel g68_nodes_3]
 mov esi,g68_nodes_3_count
 mov edx,RENDER_TARGET_PLAIN
 jmp .write
.m4:
 lea rdi,[rel g68_nodes_4]
 mov esi,g68_nodes_4_count
 mov edx,RENDER_TARGET_HEADLESS
 jmp .write
.m5:
 lea rdi,[rel g68_nodes_5]
 mov esi,g68_nodes_5_count
 mov edx,RENDER_TARGET_MARKDOWN
 jmp .write
.m6:
 lea rdi,[rel g68_nodes_6]
 mov esi,g68_nodes_6_count
 mov edx,RENDER_TARGET_HEADLESS
 jmp .write
.m7:
 lea rdi,[rel g68_nodes_7]
 mov esi,g68_nodes_7_count
 mov edx,RENDER_TARGET_HEADLESS
.write:
 mov rcx,r10
 mov r8,r11
 jmp neboc_render_plan_write
