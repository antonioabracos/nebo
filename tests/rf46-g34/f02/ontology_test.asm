bits 64
default rel
%include "runtime/knowledge/ontology.inc"
extern nebo_ontology_path_exists
section .data
edges dq 1,2, 2,3, 1,4
section .text
global _start
_start:
 lea rdi,[edges]
 mov esi,3
 mov edx,1
 mov ecx,3
 mov r8d,2
 call nebo_ontology_path_exists
 cmp eax,NEBO_ONTOLOGY_FOUND
 jne fail
 lea rdi,[edges]
 mov esi,3
 mov edx,4
 mov ecx,3
 mov r8d,2
 call nebo_ontology_path_exists
 cmp eax,NEBO_ONTOLOGY_NOT_FOUND
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
