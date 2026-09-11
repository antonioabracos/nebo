bits 64
default rel
%include "compiler/meta/code_model.inc"
%include "compiler/meta/quote_splice.inc"
extern nebo_meta_quote_clone,nebo_meta_splice_validate,nebo_meta_fresh_symbol,nebo_meta_capture_validate
section .bss
align 16
source resb NEBO_META_FRAGMENT_SIZE
output resb NEBO_META_FRAGMENT_SIZE
context resb NEBO_META_CONTEXT_SIZE
budget resb NEBO_META_BUDGET_SIZE
section .text
global _start
_start:
 lea rdi,[source]
 mov ecx,NEBO_META_FRAGMENT_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,NEBO_META_MAGIC
 mov [source+NEBO_META_FRAGMENT_MAGIC],rax
 mov qword [source+NEBO_META_FRAGMENT_VERSION],1
 mov qword [source+NEBO_META_FRAGMENT_KIND],NEBO_META_KIND_EXPRESSION
 mov qword [source+NEBO_META_FRAGMENT_ORIGIN],NEBO_META_ORIGIN_HUMAN
 mov qword [source+NEBO_META_FRAGMENT_SPAN_ID],11
 mov qword [source+NEBO_META_FRAGMENT_SYMBOL_ID],12
 mov qword [source+NEBO_META_FRAGMENT_NODE_COUNT],3
 mov qword [source+NEBO_META_FRAGMENT_BYTE_COUNT],24
 mov qword [source+NEBO_META_FRAGMENT_OWNER_ID],7
 mov qword [context+NEBO_META_CONTEXT_KIND_MASK],1
 mov qword [context+NEBO_META_CONTEXT_EFFECT_MASK],0
 mov qword [context+NEBO_META_CONTEXT_OWNER_ID],7
 mov qword [budget+NEBO_META_BUDGET_DEPTH],4
 mov qword [budget+NEBO_META_BUDGET_NODES],8
 mov qword [budget+NEBO_META_BUDGET_BYTES],64
 mov qword [budget+NEBO_META_BUDGET_STEPS],100
 mov qword [budget+NEBO_META_BUDGET_MEMORY],1024
 mov edi,19
 mov esi,23
 mov edx,5
 call nebo_meta_fresh_symbol
 mov r9,rax
 lea rdi,[source]
 lea rsi,[output]
 lea rdx,[context]
 lea rcx,[budget]
 mov r8d,99
 call nebo_meta_quote_clone
 test eax,eax
 jnz fail
 cmp qword [output+NEBO_META_FRAGMENT_ORIGIN],NEBO_META_ORIGIN_GENERATED
 jne fail
 cmp qword [output+NEBO_META_FRAGMENT_SPAN_ID],99
 jne fail
 cmp qword [source+NEBO_META_FRAGMENT_SPAN_ID],11
 jne fail
 lea rdi,[output]
 lea rsi,[context]
 lea rdx,[budget]
 call nebo_meta_splice_validate
 test eax,eax
 jnz fail
 mov edi,12
 mov esi,NEBO_META_CAPTURE_EXPLICIT
 call nebo_meta_capture_validate
 test eax,eax
 jnz fail
 mov edi,12
 xor esi,esi
 call nebo_meta_capture_validate
 cmp eax,NEBO_META_STATUS_CAPTURE_DENIED
 jne fail
 ; Bad destination request must not touch output.
 mov qword [output],0x55
 lea rdi,[source]
 xor esi,esi
 lea rdx,[context]
 lea rcx,[budget]
 mov r8d,2
 mov r9d,3
 call nebo_meta_quote_clone
 cmp eax,NEBO_META_STATUS_INVALID_ARGUMENT
 jne fail
 cmp qword [output],0x55
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail: mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
