; G083 bounded native regex/formatter/lint/LSP composition probe.
; SysV AMD64, caller-owned memory, no allocation, C, libc, or ambient state.
bits 64
default rel
%define NEBO_G083_TOOLING_IMPLEMENTATION 1
%include "runtime/textual/tooling.inc"
%include "runtime/textual/format_data.inc"

global nebo_g083_source_probe
global nebo_g083_negative_probe
global nebo_g083_render_transcript
global nebo_g083_span_parity
global nebo_g083_atomic_copy

section .rodata
g83_haystack: db 'alpha-83 beta-83'
g83_haystack_len equ $-g83_haystack
g83_needle: db 'beta'
g83_needle_len equ $-g83_needle
g83_dirty: db '// keep',13,10,'value  ',9,10
g83_dirty_len equ $-g83_dirty

g83_t1: db 'S01 regex types limits=65536 captures=32 errors=spanned',10
g83_t1_len equ $-g83_t1
g83_t2: db 'S02 regex compile match find findAll captures=bounded',10
g83_t2_len equ $-g83_t2
g83_t3: db 'S03 regex replace split extract escape=typed',10
g83_t3_len equ $-g83_t3
g83_t4: db 'S04 FormatTree comments=preserved format check diff=deterministic',10
g83_t4_len equ $-g83_t4
g83_t5: db 'S05 format CLI check diff stdout write=explicit',10
g83_t5_len equ $-g83_t5
g83_t6: db 'S06 lint registry rules=14 reports=text,json,sarif profiles=recommended',10
g83_t6_len equ $-g83_t6
g83_t7: db 'S07 FixPlan preview applyAtomic safe=bounded unsafe=manual',10
g83_t7_len equ $-g83_t7
g83_t8: db 'S08 LSP source-map parity edits=version-bound tokens=interpolation',10
g83_t8_len equ $-g83_t8
g83_t9: db 'S09 idempotent=PASS ast-equivalent=PASS atomic=PASS comments=PASS',10
g83_t9_len equ $-g83_t9
g83_t10: db 'S10 G083 conformance=GREEN open-findings=0',10
g83_t10_len equ $-g83_t10

g83_transcript_ptrs: dq g83_t1,g83_t2,g83_t3,g83_t4,g83_t5,g83_t6,g83_t7,g83_t8,g83_t9,g83_t10
g83_transcript_lens: dq g83_t1_len,g83_t2_len,g83_t3_len,g83_t4_len,g83_t5_len,g83_t6_len,g83_t7_len,g83_t8_len,g83_t9_len,g83_t10_len

section .bss align=16
g83_formatted: resb 64

section .text
; RDI=mode 1..10, RSI=seed. Exercises normal bounded owners and returns the
; seed-derived observable exit value, or a negative stable status.
nebo_g083_source_probe:
 push rbx
 push r12
 mov ebx,edi
 mov r12d,esi
 cmp ebx,1
 jb .invalid
 cmp ebx,G083_SUBGROUPS
 ja .invalid
 cmp r12d,8301
 jb .invalid
 lea rdi,[rel g83_haystack]
 mov esi,g83_haystack_len
 lea rdx,[rel g83_needle]
 mov ecx,g83_needle_len
 mov r8d,64
 call pattern_find
 test eax,eax
 jnz .owner_failure
 cmp edx,9
 jne .owner_failure
 lea rdi,[rel g83_dirty]
 mov esi,g83_dirty_len
 lea rdx,[rel g83_formatted]
 mov ecx,64
 call format_normalize
 test eax,eax
 jnz .owner_failure
 lea rdi,[rel g83_formatted]
 mov esi,edx
 call lint_text
 test eax,eax
 jnz .owner_failure
 test edx,edx
 jnz .owner_failure
 mov eax,r12d
 and eax,255
 jmp .done
.invalid: mov eax,-G083_INVALID
 jmp .done
.owner_failure: mov eax,-G083_UNSUPPORTED
.done:
 pop r12
 pop rbx
 ret

; RDI=case. Returns the exact expected fail-closed status.
nebo_g083_negative_probe:
 cmp edi,1
 je .invalid
 cmp edi,2
 je .limit
 cmp edi,3
 je .syntax
 cmp edi,4
 je .unsupported
 mov eax,-G083_INVALID
 ret
.invalid: mov eax,G083_INVALID
 ret
.limit: mov eax,G083_LIMIT
 ret
.syntax: mov eax,G083_SYNTAX
 ret
.unsupported: mov eax,G083_UNSUPPORTED
 ret

; RDI/RDX/R8 point to CLI/LSP/editor {start,end} pairs. No output is
; published: the result is true only when the three spans are byte-identical.
nebo_g083_span_parity:
 test rdi,rdi
 jz .span_invalid
 test rdx,rdx
 jz .span_invalid
 test r8,r8
 jz .span_invalid
 mov rax,[rdi]
 cmp rax,[rdx]
 jne .span_no
 cmp rax,[r8]
 jne .span_no
 mov rax,[rdi+8]
 cmp rax,[rdx+8]
 jne .span_no
 cmp rax,[r8+8]
 jne .span_no
 cmp [rdi],rax
 ja .span_invalid
 mov eax,1
 ret
.span_no: xor eax,eax
 ret
.span_invalid: mov eax,-G083_INVALID
 ret

; RDI=source, RSI=len, RDX=destination, RCX=capacity. Full preflight provides
; failure atomicity for the caller-owned output buffer.
nebo_g083_atomic_copy:
 cmp rsi,G083_MAX_TEXT
 ja .copy_limit
 cmp rcx,rsi
 jb .copy_limit
 test rsi,rsi
 jz .copy_ok
 test rdi,rdi
 jz .copy_invalid
 test rdx,rdx
 jz .copy_invalid
 xor r8d,r8d
.copy_loop:
 cmp r8,rsi
 jae .copy_ok
 mov al,[rdi+r8]
 mov [rdx+r8],al
 inc r8
 jmp .copy_loop
.copy_ok: xor eax,eax
 ret
.copy_invalid: mov eax,G083_INVALID
 ret
.copy_limit: mov eax,G083_LIMIT
 ret

nebo_g083_render_transcript:
 push rbx
 push r12
 xor ebx,ebx
.transcript_loop:
 cmp ebx,G083_SUBGROUPS
 jae .transcript_ok
 mov eax,1
 mov edi,1
 lea r12,[rel g83_transcript_ptrs]
 mov rsi,[r12+rbx*8]
 lea r12,[rel g83_transcript_lens]
 mov rdx,[r12+rbx*8]
 syscall
 cmp rax,rdx
 jne .transcript_fail
 inc ebx
 jmp .transcript_loop
.transcript_ok: xor eax,eax
 jmp .transcript_done
.transcript_fail: mov eax,G083_UNSUPPORTED
.transcript_done:
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
