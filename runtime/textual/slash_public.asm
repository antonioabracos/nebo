bits 64
default rel
%include "runtime/core/runtime_core.inc"
%include "runtime/textual/slash_dsl.inc"
extern nebo_runtime_trap
global nebo_runtime_slash_public
section .text
; op, typed input, caller-owned 16640-byte frame, explicit target.
; RenderPlan keeps its own source and parser facts. Rendering invokes the
; existing bounded two-pass native owner, with no publication on failure.
nebo_runtime_slash_public:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdx
 mov r12,rsi
 mov r13,rcx
 cmp edi,1
 je .construct
 cmp edi,2
 jne .bad
 mov rdi,[r12]
 mov rsi,[r12+8]
 mov edx,r13d
 lea rcx,[rbx+256]
 mov r8d,16384
 call neboc_slash_render
 test rax,rax
 js .bad
 mov r14,rax
 jmp .result
.construct:
 mov r14,[r12+8]
 cmp r14,4096
 ja .bad
 mov rdi,[r12]
 mov rsi,r14
 lea rdx,[rbx+160]
 lea rcx,[rbx+208]
 call neboc_slash_parse
 test eax,eax
 jnz .bad
 mov rsi,[r12]
 lea rdi,[rbx+256]
 mov rcx,r14
 rep movsb
.result:
 lea rax,[rbx+256]
 mov [rbx+128],rax
 mov [rbx+136],r14
 mov qword [rbx+144],0
 mov word [rbx+148],NEBO_RUNTIME_TEXT_ENCODING_UTF8
 lea rax,[rbx+128]
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.bad:
 mov edi,NEBO_RUNTIME_TRAP_CONTRACT_ASSERTION
 call nebo_runtime_trap
section .note.GNU-stack noalloc noexec nowrite progbits
