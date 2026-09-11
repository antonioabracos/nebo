bits 64
default rel
%include "runtime/textual/text_query.inc"
extern neboc_text_query_profile
extern neboc_text_query_cost
section .text
global _start
_start:
 call neboc_text_query_profile
 cmp eax,NEBO_QUERY_PROFILE_SCALAR_DETERMINISTIC
 jne fail
 mov edi,100
 mov esi,4
 call neboc_text_query_cost
 cmp eax,400
 jne fail
 mov edi,NEBO_QUERY_COST_LIMIT
 mov esi,2
 call neboc_text_query_cost
 cmp rax,-1
 jne fail
 mov edi,42
 xor esi,esi
 call neboc_text_query_cost
 cmp eax,42
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,6
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
