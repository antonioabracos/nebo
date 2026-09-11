bits 64
default rel
%include "runtime/core/runtime_core.inc"
%include "runtime/textual/format_data.inc"
extern nebo_runtime_trap
global nebo_runtime_regex_public
section .rodata
; The current SDK Regex.escape policy, including literal whitespace.
regex_special: db '()[]{}?*+-|^$',92,'.&~# ',9,10,13,11,12
regex_special_len equ $-regex_special
section .text
; op, caller-owned 1024-byte frame. Regex is an owned decoded literal pattern.
; This initial source profile admits Unicode literal patterns and escaped
; punctuation, no metacharacter operators or captures. Unsupported regex
; forms fail closed. The established native pattern_find owns bounded search.
nebo_runtime_regex_public:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rsi
 mov r12,rdi
 cmp edi,2
 je .match
 cmp edi,1
 je .compile
 cmp edi,3
 je .escape
 jmp .bad
.compile:
 mov rax,[rbx]
 mov r13,[rax]
 mov r14,[rax+8]
 cmp r14,256
 ja .bad
 xor r15d,r15d
 xor r10d,r10d
.compile_loop:
 cmp r15,r14
 jae .result
 mov al,[r13+r15]
 cmp al,92
 je .escaped
 cmp al,'.'
 je .bad
 cmp al,'^'
 je .bad
 cmp al,'$'
 je .bad
 cmp al,'*'
 je .bad
 cmp al,'+'
 je .bad
 cmp al,'?'
 je .bad
 cmp al,'{'
 je .bad
 cmp al,'['
 je .bad
 cmp al,'('
 je .bad
 cmp al,')'
 je .bad
 cmp al,'|'
 je .bad
 jmp .copy_pattern
.escaped:
 inc r15
 cmp r15,r14
 jae .bad
 mov al,[r13+r15]
 call .is_special
 test edx,edx
 jz .bad
.copy_pattern:
 mov [rbx+256+r10],al
 inc r10
 inc r15
 jmp .compile_loop
.escape:
 mov rax,[rbx]
 mov r13,[rax]
 mov r14,[rax+8]
 cmp r14,256
 ja .bad
 xor r15d,r15d
 xor r10d,r10d
.escape_loop:
 cmp r15,r14
 jae .result
 mov al,[r13+r15]
 call .is_special
 test edx,edx
 jz .copy_escape
 mov byte [rbx+256+r10],92
 inc r10
.copy_escape:
 mov [rbx+256+r10],al
 inc r10
 inc r15
 jmp .escape_loop
.result:
 lea rax,[rbx+256]
 mov [rbx+128],rax
 mov [rbx+136],r10
 mov qword [rbx+144],0
 mov word [rbx+148],NEBO_RUNTIME_TEXT_ENCODING_UTF8
 lea rax,[rbx+128]
 jmp .done
.match:
 mov rax,[rbx+8]
 mov rdi,[rax]
 mov rsi,[rax+8]
 cmp rsi,4096
 ja .bad
 mov rax,[rbx]
 mov rdx,[rax]
 mov rcx,[rax+8]
 cmp rcx,256
 ja .bad
 test rcx,rcx
 jz .empty_match
 mov r8d,65536
 call pattern_find
 test eax,eax
 jz .empty_match
 cmp eax,FMT_NOT_FOUND
 jne .bad
 xor eax,eax
 jmp .done
.empty_match:
 mov eax,1
 jmp .done
.is_special:
 lea r11,[rel regex_special]
 xor ecx,ecx
 xor edx,edx
.special_loop:
 cmp ecx,regex_special_len
 jae .special_done
 cmp al,[r11+rcx]
 je .special_yes
 inc ecx
 jmp .special_loop
.special_yes:
 mov edx,1
.special_done:
 ret
.bad:
 mov edi,NEBO_RUNTIME_TRAP_CONTRACT_ASSERTION
 call nebo_runtime_trap
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
