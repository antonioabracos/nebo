
bits 64
default rel
%include "compiler/meta/code_model.inc"
extern nebo_meta_budget_validate,nebo_meta_kind_compatible,nebo_meta_fragment_validate
section .bss
align 16
fragment resb NEBO_META_FRAGMENT_SIZE
snapshot resb NEBO_META_FRAGMENT_SIZE
context resb NEBO_META_CONTEXT_SIZE
budget resb NEBO_META_BUDGET_SIZE
section .text
global _start
_start:
 lea rdi,[fragment]
 mov ecx,NEBO_META_FRAGMENT_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,NEBO_META_MAGIC
 mov [fragment+NEBO_META_FRAGMENT_MAGIC],rax
 mov qword [fragment+NEBO_META_FRAGMENT_VERSION],NEBO_META_VERSION
 mov qword [fragment+NEBO_META_FRAGMENT_KIND],NEBO_META_KIND_EXPRESSION
 mov qword [fragment+NEBO_META_FRAGMENT_ORIGIN],NEBO_META_ORIGIN_HUMAN
 mov qword [fragment+NEBO_META_FRAGMENT_SPAN_ID],17
 mov qword [fragment+NEBO_META_FRAGMENT_SYMBOL_ID],23
 mov qword [fragment+NEBO_META_FRAGMENT_NODE_COUNT],8
 mov qword [fragment+NEBO_META_FRAGMENT_BYTE_COUNT],64
 mov qword [fragment+NEBO_META_FRAGMENT_EFFECT_MASK],2
 mov qword [fragment+NEBO_META_FRAGMENT_OWNER_ID],41
 mov qword [context+NEBO_META_CONTEXT_KIND_MASK],1
 mov qword [context+NEBO_META_CONTEXT_EFFECT_MASK],3
 mov qword [context+NEBO_META_CONTEXT_OWNER_ID],41
 mov qword [budget+NEBO_META_BUDGET_DEPTH],8
 mov qword [budget+NEBO_META_BUDGET_NODES],64
 mov qword [budget+NEBO_META_BUDGET_BYTES],4096
 mov qword [budget+NEBO_META_BUDGET_STEPS],1000
 mov qword [budget+NEBO_META_BUDGET_MEMORY],65536
 lea rdi,[budget]
 call nebo_meta_budget_validate
 test eax,eax
 jnz fail
 mov edi,NEBO_META_KIND_EXPRESSION
 mov esi,1
 call nebo_meta_kind_compatible
 test eax,eax
 jnz fail
 lea rdi,[fragment]
 lea rsi,[context]
 lea rdx,[budget]
 call nebo_meta_fragment_validate
 test eax,eax
 jnz fail
 ; Capture an exact snapshot before negative validation proves failure atomicity.
 lea rsi,[fragment]
 lea rdi,[snapshot]
 mov ecx,NEBO_META_FRAGMENT_SIZE/8
 rep movsq
 mov qword [budget+NEBO_META_BUDGET_NODES],7
 lea rdi,[fragment]
 lea rsi,[context]
 lea rdx,[budget]
 call nebo_meta_fragment_validate
 cmp eax,NEBO_META_STATUS_NODE_LIMIT
 jne fail
 lea rsi,[fragment]
 lea rdi,[snapshot]
 mov ecx,NEBO_META_FRAGMENT_SIZE/8
.compare:
 mov rax,[rsi]
 cmp rax,[rdi]
 jne fail
 add rsi,8
 add rdi,8
 loop .compare
 mov qword [budget+NEBO_META_BUDGET_NODES],64
 mov qword [context+NEBO_META_CONTEXT_EFFECT_MASK],1
 lea rdi,[fragment]
 lea rsi,[context]
 lea rdx,[budget]
 call nebo_meta_fragment_validate
 cmp eax,NEBO_META_STATUS_EFFECT_DENIED
 jne fail
 mov edi,NEBO_META_KIND_PATTERN
 mov esi,1
 call nebo_meta_kind_compatible
 cmp eax,NEBO_META_STATUS_BAD_KIND
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
