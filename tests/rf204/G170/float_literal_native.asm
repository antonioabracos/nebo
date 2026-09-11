; Bounded fixture records exercise the real literal materializer under all
; ambient rounding modes. Output contains status, bits and parsed digit counts.
bits 64
default rel
extern neboc_decimal_binary64_exact
section .rodata
input_blob: incbin G170_LITERAL_DATA
input_end:
section .data
input_cursor dq input_blob
section .bss
alignb 16
header resq 2
output resq 4
source resb 65537
original_cw resw 1
active_cw resw 1
after_cw resw 1
alignb 4
original_mxcsr resd 1
active_mxcsr resd 1
after_mxcsr resd 1
section .text
global _start
_start:
 lea rsi,[header]
 mov edx,16
 call read_exact
 test eax,eax
 jnz .read_failed
 cmp qword [header],65537
 ja .bad
 cmp qword [header+8],3
 ja .bad
 lea rsi,[source]
 mov rdx,[header]
 call read_exact
 test eax,eax
 jnz .bad
 fnstcw [original_cw]
 stmxcsr [original_mxcsr]
 movzx eax,word [original_cw]
 and eax,0xf3ff
 mov ecx,[header+8]
 shl ecx,10
 or eax,ecx
 mov [active_cw],ax
 mov eax,[original_mxcsr]
 and eax,0xffff9fff
 mov ecx,[header+8]
 shl ecx,13
 or eax,ecx
 mov [active_mxcsr],eax
 fldcw [active_cw]
 ldmxcsr [active_mxcsr]
 lea rdi,[source]
 mov rsi,[header]
 call neboc_decimal_binary64_exact
 mov [output],rax
 mov [output+8],rdx
 mov [output+16],rcx
 mov [output+24],r8
 fnstcw [after_cw]
 stmxcsr [after_mxcsr]
 mov ax,[active_cw]
 cmp ax,[after_cw]
 jne .bad
 mov eax,[active_mxcsr]
 cmp eax,[after_mxcsr]
 jne .bad
 fldcw [original_cw]
 ldmxcsr [original_mxcsr]
 mov eax,1
 mov edi,1
 lea rsi,[output]
 mov edx,32
 syscall
 cmp rax,32
 jne .bad
 jmp _start
.read_failed:
 cmp eax,1
 jne .bad
 xor edi,edi
 jmp .exit
.bad:
 mov edi,71
.exit:
 mov eax,60
 syscall

; Return 1 only for EOF before any bytes, 2 for truncated input.
read_exact:
 mov rdi,rsi
 mov rsi,[rel input_cursor]
 lea r8,[rel input_end]
 sub r8,rsi
 test rdx,rdx
 jz .ok
 test r8,r8
 jz .eof
 cmp r8,rdx
 jb .bad
 mov rcx,rdx
 rep movsb
 mov [rel input_cursor],rsi
.ok:
 xor eax,eax
 ret
.eof:
 mov eax,1
 ret
.bad:
 mov eax,2
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
