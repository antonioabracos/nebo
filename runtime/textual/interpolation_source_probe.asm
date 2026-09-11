; G061 source-to-effect runtime owner.  All templates below are already
; lowered FormatPlan nodes: generated programs never carry or call a parser.
bits 64
default rel
%define NEBO_G061_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/interpolation_source_probe.inc"
%include "runtime/textual/format_language.inc"
%include "runtime/textual/format_profiles.inc"

extern neboc_format_plan_write
extern nebo_format_plan_evaluate_once

section .rodata
g61_m1_a: db '${literal}|token'
g61_m1_a_len equ $-g61_m1_a
g61_m2_a: db 'Ada:'
g61_m2_a_len equ $-g61_m2_a
g61_m2_b: db '42'
g61_m2_b_len equ $-g61_m2_b
g61_m3_a: db 'user='
g61_m3_a_len equ $-g61_m3_a
g61_m3_b: db 'Mira'
g61_m3_b_len equ $-g61_m3_b
g61_m4_a: db 'sum='
g61_m4_a_len equ $-g61_m4_a
g61_m4_b: db '11'
g61_m4_b_len equ $-g61_m4_b
g61_m5_a: db '12.35'
g61_m5_a_len equ $-g61_m5_a
g61_m5_sep: db '|'
g61_m5_sep_len equ $-g61_m5_sep
g61_m5_b: db '000000ff'
g61_m5_b_len equ $-g61_m5_b
g61_m5_sep2: db '|'
g61_m5_sep2_len equ $-g61_m5_sep2
g61_m5_c: db '                 Ana'
g61_m5_c_len equ $-g61_m5_c
g61_m6_a: db 'L'
g61_m6_a_len equ $-g61_m6_a
g61_m6_sep: db '|'
g61_m6_sep_len equ $-g61_m6_sep
g61_m6_b: db 'R'
g61_m6_b_len equ $-g61_m6_b
g61_m7_a: db 'same='
g61_m7_a_len equ $-g61_m7_a
g61_m7_b: db '19'
g61_m7_b_len equ $-g61_m7_b
g61_m8_a: db 'rename=user.name'
g61_m8_a_len equ $-g61_m8_a
g61_m9_a: db 'G061:GREEN'
g61_m9_a_len equ $-g61_m9_a

align 8
g61_nodes_1:
 dq FORMAT_NODE_LITERAL,g61_m1_a,g61_m1_a_len,0
g61_nodes_2:
 dq FORMAT_NODE_LITERAL,g61_m2_a,g61_m2_a_len,0
 dq FORMAT_NODE_VALUE,g61_m2_b,g61_m2_b_len,0
g61_nodes_3:
 dq FORMAT_NODE_LITERAL,g61_m3_a,g61_m3_a_len,0
 dq FORMAT_NODE_VALUE,g61_m3_b,g61_m3_b_len,0
g61_nodes_4:
 dq FORMAT_NODE_LITERAL,g61_m4_a,g61_m4_a_len,0
 dq FORMAT_NODE_VALUE,g61_m4_b,g61_m4_b_len,0
g61_nodes_5:
 dq FORMAT_NODE_VALUE,g61_m5_a,g61_m5_a_len,FORMAT_PROFILE_FIXED
 dq FORMAT_NODE_LITERAL,g61_m5_sep2,g61_m5_sep2_len,0
 dq FORMAT_NODE_VALUE,g61_m5_b,g61_m5_b_len,FORMAT_PROFILE_HEX
 dq FORMAT_NODE_LITERAL,g61_m5_sep,g61_m5_sep_len,0
 dq FORMAT_NODE_VALUE,g61_m5_c,g61_m5_c_len,FORMAT_PROFILE_ALIGN
g61_nodes_6:
 dq FORMAT_NODE_VALUE,g61_m6_a,g61_m6_a_len,0
 dq FORMAT_NODE_LITERAL,g61_m6_sep,g61_m6_sep_len,0
 dq FORMAT_NODE_VALUE,g61_m6_b,g61_m6_b_len,0
g61_nodes_7:
 dq FORMAT_NODE_LITERAL,g61_m7_a,g61_m7_a_len,0
 dq FORMAT_NODE_VALUE,g61_m7_b,g61_m7_b_len,0
g61_nodes_7_b:
 dq FORMAT_NODE_LITERAL,g61_m7_a,g61_m7_a_len,0
 dq FORMAT_NODE_VALUE,g61_m7_b,g61_m7_b_len,0
g61_nodes_8:
 dq FORMAT_NODE_LITERAL,g61_m8_a,g61_m8_a_len,0
g61_nodes_9:
 dq FORMAT_NODE_LITERAL,g61_m9_a,g61_m9_a_len,0

g61_modes:
 dq g61_nodes_1,1,g61_m1_a,g61_m1_a_len
 dq g61_nodes_2,2,g61_m2_a,g61_m2_a_len+g61_m2_b_len
 dq g61_nodes_3,2,g61_m3_a,g61_m3_a_len+g61_m3_b_len
 dq g61_nodes_4,2,g61_m4_a,g61_m4_a_len+g61_m4_b_len
 dq g61_nodes_5,5,g61_m5_a,g61_m5_a_len+g61_m5_sep_len+g61_m5_b_len+g61_m5_sep2_len+g61_m5_c_len
 dq g61_nodes_6,3,g61_m6_a,g61_m6_a_len+g61_m6_sep_len+g61_m6_b_len
 dq g61_nodes_7,2,g61_m7_a,g61_m7_a_len+g61_m7_b_len
 dq g61_nodes_8,1,g61_m8_a,g61_m8_a_len
 dq g61_nodes_9,1,g61_m9_a,g61_m9_a_len

g61_eval_nodes: dq 1,0, 0,0, 1,1
g61_eval_duplicate: dq 1,0, 1,0

section .bss align=16
g61_output_a: resb 128
g61_output_b: resb 128
g61_eval_result: resq 2

section .text
global nebo_g061_source_probe
global nebo_g061_negative_probe

g61_clear_outputs:
 lea rdi,[rel g61_output_a]
 mov ecx,32
 mov eax,0xa5a5a5a5
 rep stosd
 lea rdi,[rel g61_output_b]
 mov ecx,32
 rep stosd
 ret

; EDI mode 1..9, ESI nonzero source seed.  The seed is returned only after
; exact FormatPlan bytes and subgroup-specific invariants were observed.
nebo_g061_source_probe:
 push rbx
 push r12
 push r13
 mov ebx,esi
 test ebx,ebx
 jz .source_fail
 cmp edi,1
 jb .source_fail
 cmp edi,9
 ja .source_fail
 mov r12d,edi
 call g61_clear_outputs
 lea rax,[rel g61_modes]
 dec r12
 shl r12,5
 add rax,r12
 mov rdi,[rax]
 mov rsi,[rax+8]
 lea rdx,[rel g61_output_a]
 mov ecx,128
 mov r13,[rax+24]
 push qword [rax+16]
 call neboc_format_plan_write
 pop rsi
 cmp rax,r13
 jne .source_fail
 lea rdi,[rel g61_output_a]
 mov rcx,r13
 repe cmpsb
 jne .source_fail
 mov rax,r12
 shr rax,5
 inc eax
 cmp eax,6
 jne .source_mode_7
 lea rdi,[rel g61_eval_nodes]
 mov esi,3
 mov edx,2
 mov ecx,3
 lea r8,[rel g61_eval_result]
 call nebo_format_plan_evaluate_once
 test eax,eax
 jnz .source_fail
 cmp qword [rel g61_eval_result],3
 jne .source_fail
 cmp qword [rel g61_eval_result+8],3
 jne .source_fail
.source_mode_7:
 mov rax,r12
 shr rax,5
 inc eax
 cmp eax,7
 jne .source_ok
 lea rdi,[rel g61_nodes_7_b]
 mov esi,2
 lea rdx,[rel g61_output_b]
 mov ecx,128
 call neboc_format_plan_write
 cmp rax,g61_m7_a_len+g61_m7_b_len
 jne .source_fail
 lea rsi,[rel g61_output_a]
 lea rdi,[rel g61_output_b]
 mov ecx,g61_m7_a_len+g61_m7_b_len
 repe cmpsb
 jne .source_fail
.source_ok:
 mov eax,ebx
 jmp .source_done
.source_fail:
 xor eax,eax
.source_done:
 pop r13
 pop r12
 pop rbx
 ret

; Returns zero only after capacity failure atomicity and duplicate-evaluation
; rejection are observed independently.
nebo_g061_negative_probe:
 push rbx
 call g61_clear_outputs
 mov rbx,[rel g61_output_a]
 lea rdi,[rel g61_nodes_1]
 mov esi,1
 lea rdx,[rel g61_output_a]
 xor ecx,ecx
 call neboc_format_plan_write
 cmp rax,-FORMAT_E_CAPACITY
 jne .negative_fail
 cmp [rel g61_output_a],rbx
 jne .negative_fail
 mov rax,0xa5a5a5a5a5a5a5a5
 mov [rel g61_eval_result],rax
 mov [rel g61_eval_result+8],rax
 lea rdi,[rel g61_eval_duplicate]
 mov esi,2
 mov edx,1
 mov ecx,2
 lea r8,[rel g61_eval_result]
 call nebo_format_plan_evaluate_once
 cmp eax,3
 jne .negative_fail
 mov rax,0xa5a5a5a5a5a5a5a5
 cmp [rel g61_eval_result],rax
 jne .negative_fail
 xor eax,eax
 jmp .negative_done
.negative_fail:
 mov eax,1
.negative_done:
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
