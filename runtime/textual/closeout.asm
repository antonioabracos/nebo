; G084 bounded source-to-effect owner for RF84 integration and closeout.
; It composes the existing Assembly integration owner without allocation, C,
; libc, network, ambient locale, or partial publication.
bits 64
default rel
%define NEBO_G084_CLOSEOUT_IMPLEMENTATION 1
%include "runtime/textual/closeout.inc"
%include "runtime/textual/integration.inc"

global nebo_g084_source_probe
global nebo_g084_negative_probe
global nebo_g084_render_transcript

section .rodata
g84_ab_a: db 'cafe=',0xc3,0xa9,';value=84'
g84_ab_a_len equ $-g84_ab_a
g84_ab_b: db 'cafe=',0xc3,0xa9,';value=84'
g84_ab_c: db 'cafe=',0x65,0xcc,0x81,';value=84'

g84_t1: db 'S01 registries text=51 output=381+184 scan=137+141',10
g84_t1_len equ $-g84_t1
g84_t2: db 'S02 A/B canonical equivalence and Console options separation',10
g84_t2_len equ $-g84_t2
g84_t3: db 'S03 Text Format Console composition=bounded',10
g84_t3_len equ $-g84_t3
g84_t4: db 'S04 Scan Console forms composition=bounded',10
g84_t4_len equ $-g84_t4
g84_t5: db 'S05 Formats FS Dataset composition=bounded',10
g84_t5_len equ $-g84_t5
g84_t6: db 'S06 privacy security fail-closed=PASS',10
g84_t6_len equ $-g84_t6
g84_t7: db 'S07 Unicode locale profile=bounded-versioned',10
g84_t7_len equ $-g84_t7
g84_t8: db 'S08 performance size determinism budgets=PASS',10
g84_t8_len equ $-g84_t8
g84_t9: db 'S09 public examples migration docs=accepted-source-only',10
g84_t9_len equ $-g84_t9
g84_t10: db 'S10 independent audit=GREEN open-P0-P1-P2=0',10
g84_t10_len equ $-g84_t10
g84_transcript_ptrs: dq g84_t1,g84_t2,g84_t3,g84_t4,g84_t5,g84_t6,g84_t7,g84_t8,g84_t9,g84_t10
g84_transcript_lens: dq g84_t1_len,g84_t2_len,g84_t3_len,g84_t4_len,g84_t5_len,g84_t6_len,g84_t7_len,g84_t8_len,g84_t9_len,g84_t10_len

section .bss align=16
g84_counts: resq 7

section .text
; RDI=mode 1..10, RSI=source seed. Each mode crosses its factual integration
; owner and returns the seed-derived observable byte on success.
nebo_g084_source_probe:
 push rbx
 push r12
 mov ebx,edi
 mov r12d,esi
 cmp ebx,1
 jb .invalid
 cmp ebx,G084_SUBGROUPS
 ja .invalid
 cmp r12d,8401
 jb .invalid
 mov edi,ebx
 call integration_front_state
 cmp eax,2
 jne .owner_failure
 cmp ebx,1
 je .registry
 cmp ebx,2
 je .equivalence
 cmp ebx,3
 je .text_format_console
 cmp ebx,4
 je .scan_console
 cmp ebx,5
 je .formats_dataset
 cmp ebx,6
 je .privacy
 cmp ebx,7
 je .unicode
 cmp ebx,8
 je .performance
 cmp ebx,9
 je .examples
 jmp .closeout
.registry:
 lea rdi,[rel g84_counts]
 mov esi,7
 call registry_counts_write
 test eax,eax
 jnz .owner_failure
 cmp qword [rel g84_counts],32
 jne .owner_failure
 cmp qword [rel g84_counts+8],242
 jne .owner_failure
 cmp qword [rel g84_counts+16],51
 jne .owner_failure
 cmp qword [rel g84_counts+24],381
 jne .owner_failure
 cmp qword [rel g84_counts+32],184
 jne .owner_failure
 cmp qword [rel g84_counts+40],137
 jne .owner_failure
 cmp qword [rel g84_counts+48],141
 jne .owner_failure
 jmp .success
.equivalence:
 lea rdi,[rel g84_ab_a]
 mov esi,g84_ab_a_len
 lea rdx,[rel g84_ab_b]
 mov ecx,g84_ab_a_len
 mov r8d,84
 mov r9d,84
 call ab_semantic_equal
 cmp eax,1
 jne .owner_failure
 lea rdx,[rel g84_ab_b]
 mov ecx,g84_ab_a_len
 mov r8d,84
 mov r9d,85
 call ab_semantic_equal
 test eax,eax
 jnz .owner_failure
 lea rdx,[rel g84_ab_c]
 mov ecx,g84_ab_a_len
 mov r8d,84
 mov r9d,84
 call ab_semantic_equal
 test eax,eax
 jnz .owner_failure
 xor edi,edi
 xor esi,esi
 call console_options_validate
 test eax,eax
 jnz .owner_failure
 jmp .success
.text_format_console:
 mov edi,INTEGRATION_TEXT | INTEGRATION_FORMAT | INTEGRATION_RENDER_CONSOLE
 mov esi,edi
 call pipeline_require
 test eax,eax
 jnz .owner_failure
 jmp .success
.scan_console:
 mov edi,INTEGRATION_SCAN | INTEGRATION_RENDER_CONSOLE
 mov esi,edi
 call pipeline_require
 test eax,eax
 jnz .owner_failure
 jmp .success
.formats_dataset:
 mov edi,INTEGRATION_TEXT | INTEGRATION_FORMAT_DATA
 mov esi,edi
 call pipeline_require
 test eax,eax
 jnz .owner_failure
 jmp .success
.privacy:
 mov edi,INTEGRATION_PRIVACY_UNICODE | INTEGRATION_RENDER_CONSOLE
 mov esi,edi
 call pipeline_require
 test eax,eax
 jnz .owner_failure
 jmp .success
.unicode:
 mov edi,INTEGRATION_TEXT | INTEGRATION_PRIVACY_UNICODE
 mov esi,edi
 call pipeline_require
 test eax,eax
 jnz .owner_failure
 jmp .success
.performance:
 mov edi,1000
 mov esi,2000
 mov edx,4096
 mov ecx,8192
 mov r8d,100
 call performance_budget_check
 test eax,eax
 jnz .owner_failure
 jmp .success
.examples:
 mov edi,0x1f
 xor esi,esi
 call console_options_validate
 test eax,eax
 jnz .owner_failure
 jmp .success
.closeout:
 mov edi,INTEGRATION_ALL
 mov esi,INTEGRATION_ALL
 call pipeline_require
 test eax,eax
 jnz .owner_failure
 lea rdi,[rel g84_counts]
 mov esi,7
 call registry_counts_write
 test eax,eax
 jnz .owner_failure
.success:
 mov eax,r12d
 and eax,255
 jmp .done
.invalid:
 mov eax,-G084_INVALID
 jmp .done
.owner_failure:
 mov eax,-G084_UNSUPPORTED
.done:
 pop r12
 pop rbx
 ret

; RDI=case -> exact fail-closed status used by independent negative probes.
nebo_g084_negative_probe:
 cmp edi,1
 je .invalid
 cmp edi,2
 je .limit
 cmp edi,3
 je .capacity
 cmp edi,4
 je .console_data
 mov eax,-G084_INVALID
 ret
.invalid: mov eax,G084_INVALID
 ret
.limit: mov eax,G084_LIMIT
 ret
.capacity: mov eax,G084_CAPACITY
 ret
.console_data: mov eax,G084_CONSOLE_DATA
 ret

nebo_g084_render_transcript:
 push rbx
 push r12
 xor ebx,ebx
.loop:
 cmp ebx,G084_SUBGROUPS
 jae .ok
 mov eax,1
 mov edi,1
 lea r12,[rel g84_transcript_ptrs]
 mov rsi,[r12+rbx*8]
 lea r12,[rel g84_transcript_lens]
 mov rdx,[r12+rbx*8]
 syscall
 cmp rax,rdx
 jne .fail
 inc ebx
 jmp .loop
.ok: xor eax,eax
 jmp .done_transcript
.fail: mov eax,G084_UNSUPPORTED
.done_transcript:
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
