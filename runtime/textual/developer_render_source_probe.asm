; Source-to-effect oracle for G069 bounded developer rendering.
bits 64
default rel
%define NEBO_G069_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/developer_render_source_probe.inc"
%include "runtime/textual/render_console.inc"

section .rodata
g69_s1: db 'fn sum(a: Int, b: Int) -> Int { return a + b; }'
g69_s1_len equ $-g69_s1
g69_s2: db 'E204 expected Int, received Text',10,'source: total + name',10,'        ^^^^',10,'fix: parse(name)'
g69_s2_len equ $-g69_s2
g69_s3: db 'Point{x:3,y:5}: Point depth=2'
g69_s3_len equ $-g69_s3
g69_s4: db '{"id":17,"active":true,"tags":["nebo","typed"]}'
g69_s4_len equ $-g69_s4
g69_s5: db 'fields=(name="Ada",score=9) tuple=(Ada,9)'
g69_s5_len equ $-g69_s5
g69_s6: db 'type=Record{id:Int,name:Text} shape={id,name}'
g69_s6_len equ $-g69_s6
g69_s7: db 'developer-conformance:67/67'
g69_s7_len equ $-g69_s7
g69_redacted_expected: db '[redacted]'
g69_redacted_expected_len equ $-g69_redacted_expected

section .data
align 16
g69_nodes_1:
 dq RENDER_NODE_DEVELOPER,RENDER_FLAG_FALLBACK,g69_s1,g69_s1_len,RENDER_DEVELOPER_CODE,1
g69_nodes_1_count equ ($-g69_nodes_1)/RENDER_NODE_SIZE
g69_nodes_2:
 dq RENDER_NODE_DEVELOPER,RENDER_FLAG_FALLBACK,g69_s2,g69_s2_len,RENDER_DEVELOPER_DIAGNOSTIC,2
g69_nodes_2_count equ ($-g69_nodes_2)/RENDER_NODE_SIZE
g69_nodes_3:
 dq RENDER_NODE_DEVELOPER,RENDER_FLAG_FALLBACK|RENDER_FLAG_DEBUG,g69_s3,g69_s3_len,RENDER_DEVELOPER_INSPECTION,2
g69_nodes_3_count equ ($-g69_nodes_3)/RENDER_NODE_SIZE
g69_nodes_4:
 dq RENDER_NODE_DEVELOPER,RENDER_FLAG_FALLBACK,g69_s4,g69_s4_len,RENDER_DEVELOPER_SERIALIZATION,3
g69_nodes_4_count equ ($-g69_nodes_4)/RENDER_NODE_SIZE
g69_nodes_5:
 dq RENDER_NODE_DEVELOPER,RENDER_FLAG_FALLBACK,g69_s5,g69_s5_len,RENDER_DEVELOPER_OBJECT,2
g69_nodes_5_count equ ($-g69_nodes_5)/RENDER_NODE_SIZE
g69_nodes_6:
 dq RENDER_NODE_DEVELOPER,RENDER_FLAG_FALLBACK,g69_s6,g69_s6_len,RENDER_DEVELOPER_SCHEMA,2
g69_nodes_6_count equ ($-g69_nodes_6)/RENDER_NODE_SIZE
g69_nodes_7:
 dq RENDER_NODE_DEVELOPER,RENDER_FLAG_FALLBACK,g69_s7,g69_s7_len,RENDER_DEVELOPER_CONFORMANCE,1
g69_nodes_7_count equ ($-g69_nodes_7)/RENDER_NODE_SIZE
g69_bad_depth:
 dq RENDER_NODE_DEVELOPER,RENDER_FLAG_FALLBACK,g69_s6,g69_s6_len,RENDER_DEVELOPER_SCHEMA,9
g69_bad_capability:
 dq RENDER_NODE_DEVELOPER,RENDER_FLAG_FALLBACK,g69_s3,g69_s3_len,RENDER_DEVELOPER_INSPECTION,2
g69_bad_private:
 dq RENDER_NODE_DEVELOPER,RENDER_FLAG_FALLBACK|RENDER_FLAG_PRIVATE,g69_s2,g69_s2_len,RENDER_DEVELOPER_DIAGNOSTIC,2
g69_redacted:
 dq RENDER_NODE_DEVELOPER,RENDER_FLAG_FALLBACK|RENDER_FLAG_PRIVATE|RENDER_FLAG_REDACT,g69_s2,g69_s2_len,RENDER_DEVELOPER_DIAGNOSTIC,2

section .bss align=16
g69_output_a: resb 2048
g69_output_b: resb 2048
g69_atomic: resb 2048

section .text
extern neboc_render_feature_validate
extern neboc_render_plan_validate
extern neboc_render_plan_measure
extern neboc_render_plan_write
extern neboc_render_developer_token_validate
global nebo_g069_source_probe
global nebo_g069_negative_probe
global nebo_g069_render_transcript

; RDI nodes, RSI count, EDX target, RCX expected, R8 expected length.
g69_run_plan:
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
 lea rdi,[rel g69_output_a]
 mov ecx,2048
 mov al,0xa5
 rep stosb
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 lea rcx,[rel g69_output_a]
 mov r8d,2048
 call neboc_render_plan_write
 cmp rax,rbx
 jne .fail
 lea rsi,[rel g69_output_a]
 mov rdi,r15
 mov rcx,rbx
 repe cmpsb
 jne .fail
 lea rdi,[rel g69_output_b]
 mov ecx,2048
 mov al,0x5a
 rep stosb
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 lea rcx,[rel g69_output_b]
 mov r8d,2048
 call neboc_render_plan_write
 cmp rax,rbx
 jne .fail
 lea rsi,[rel g69_output_a]
 lea rdi,[rel g69_output_b]
 mov rcx,rbx
 repe cmpsb
 jne .fail
 lea rdi,[rel g69_atomic]
 mov ecx,2048
 mov al,0xcc
 rep stosb
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 lea rcx,[rel g69_atomic]
 lea r8,[rbx-1]
 call neboc_render_plan_write
 cmp rax,-RENDER_E_CAPACITY
 jne .fail
 cmp byte [rel g69_atomic],0xcc
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

%macro G69_RUN 5
 lea rdi,[rel %1]
 mov esi,%2
 mov edx,%3
 lea rcx,[rel %4]
 mov r8d,%5
 call g69_run_plan
 test eax,eax
 jnz .return
%endmacro

nebo_g069_source_probe:
 push rbx
 push r12
 mov ebx,esi
 mov r12d,edi
 lea edi,[r12d+6900]
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
.m1: G69_RUN g69_nodes_1,g69_nodes_1_count,RENDER_TARGET_PLAIN,g69_s1,g69_s1_len
 jmp .success
.m2: G69_RUN g69_nodes_2,g69_nodes_2_count,RENDER_TARGET_HEADLESS,g69_s2,g69_s2_len
 jmp .success
.m3: G69_RUN g69_nodes_3,g69_nodes_3_count,RENDER_TARGET_HEADLESS,g69_s3,g69_s3_len
 jmp .success
.m4: G69_RUN g69_nodes_4,g69_nodes_4_count,RENDER_TARGET_HEADLESS,g69_s4,g69_s4_len
 jmp .success
.m5: G69_RUN g69_nodes_5,g69_nodes_5_count,RENDER_TARGET_PLAIN,g69_s5,g69_s5_len
 jmp .success
.m6: G69_RUN g69_nodes_6,g69_nodes_6_count,RENDER_TARGET_HEADLESS,g69_s6,g69_s6_len
 jmp .success
.m7: G69_RUN g69_nodes_7,g69_nodes_7_count,RENDER_TARGET_HEADLESS,g69_s7,g69_s7_len
.success: mov eax,ebx
.return:
 pop r12
 pop rbx
 ret
%undef G69_RUN

nebo_g069_negative_probe:
 cmp edi,1
 je .token
 cmp edi,2
 je .depth
 cmp edi,3
 je .capability
 cmp edi,4
 je .privacy
 cmp edi,5
 je .feature
 cmp edi,6
 je .redaction
 cmp edi,7
 je .debug_scope
 mov eax,RENDER_E_UNAVAILABLE
 ret
.token:
 mov edi,99
 mov esi,1
 mov edx,RENDER_FLAG_FALLBACK
 jmp neboc_render_developer_token_validate
.depth:
 lea rdi,[rel g69_bad_depth]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 jmp neboc_render_plan_validate
.capability:
 lea rdi,[rel g69_bad_capability]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 jmp neboc_render_plan_validate
.privacy:
 lea rdi,[rel g69_bad_private]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 jmp neboc_render_plan_validate
.feature:
 mov edi,6901
 xor esi,esi
 mov edx,8
 mov ecx,1
 mov r8d,RENDER_TARGET_HEADLESS
 jmp neboc_render_feature_validate
.redaction:
 lea rdi,[rel g69_redacted]
 mov esi,1
 mov edx,RENDER_TARGET_HEADLESS
 lea rcx,[rel g69_redacted_expected]
 mov r8d,g69_redacted_expected_len
 jmp g69_run_plan
.debug_scope:
 mov edi,RENDER_DEVELOPER_CODE
 mov esi,1
 mov edx,RENDER_FLAG_FALLBACK|RENDER_FLAG_DEBUG
 jmp neboc_render_developer_token_validate

; EDI mode, RSI output, RDX capacity -> RAX committed bytes or typed error.
nebo_g069_render_transcript:
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
 lea rdi,[rel g69_nodes_1]
 mov esi,g69_nodes_1_count
 mov edx,RENDER_TARGET_PLAIN
 jmp .write
.m2:
 lea rdi,[rel g69_nodes_2]
 mov esi,g69_nodes_2_count
 mov edx,RENDER_TARGET_HEADLESS
 jmp .write
.m3:
 lea rdi,[rel g69_nodes_3]
 mov esi,g69_nodes_3_count
 mov edx,RENDER_TARGET_HEADLESS
 jmp .write
.m4:
 lea rdi,[rel g69_nodes_4]
 mov esi,g69_nodes_4_count
 mov edx,RENDER_TARGET_HEADLESS
 jmp .write
.m5:
 lea rdi,[rel g69_nodes_5]
 mov esi,g69_nodes_5_count
 mov edx,RENDER_TARGET_PLAIN
 jmp .write
.m6:
 lea rdi,[rel g69_nodes_6]
 mov esi,g69_nodes_6_count
 mov edx,RENDER_TARGET_HEADLESS
 jmp .write
.m7:
 lea rdi,[rel g69_nodes_7]
 mov esi,g69_nodes_7_count
 mov edx,RENDER_TARGET_HEADLESS
.write:
 mov rcx,r10
 mov r8,r11
 jmp neboc_render_plan_write
