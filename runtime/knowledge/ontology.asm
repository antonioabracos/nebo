; RUNTIME-DISTRIBUIDO-E-STREAMING-DISTRIBUIDO-F02 bounded ontology path reachability over nominal node IDs.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/knowledge/ontology.inc"
section .text
NEBOC_ABI_FUNCTION nebo_ontology_path_exists
 test rdi,rdi
 jz .invalid
 cmp rsi,NEBO_ONTOLOGY_MAX_EDGES
 ja .limit
 cmp rdx,NEBO_ONTOLOGY_MAX_NODES
 jae .invalid
 cmp rcx,NEBO_ONTOLOGY_MAX_NODES
 jae .invalid
 test r8,r8
 jz .limit
 cmp r8,NEBO_ONTOLOGY_MAX_DEPTH
 ja .limit
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rcx
 mov r14,rdi
 mov r15,rsi
 xor r12d,r12d
 bts r12,rdx
 xor r13d,r13d
.depth:
 bt r12,rbx
 jc .found
 cmp r13,r8
 jae .not_found
 mov r11,r12
 xor eax,eax
.edges:
 cmp rax,r15
 jae .advance
 mov r9,rax
 shl r9,4
 mov rcx,[r14+r9]
 cmp rcx,NEBO_ONTOLOGY_MAX_NODES
 jae .invalid_saved
 bt r12,rcx
 jnc .next
 mov r10,[r14+r9+8]
 cmp r10,NEBO_ONTOLOGY_MAX_NODES
 jae .invalid_saved
 bts r11,r10
.next:
 inc rax
 jmp .edges
.advance:
 cmp r11,r12
 je .not_found
 mov r12,r11
 inc r13
 jmp .depth
.found:
 mov eax,NEBO_ONTOLOGY_FOUND
 jmp .restore
.not_found:
 mov eax,NEBO_ONTOLOGY_NOT_FOUND
 jmp .restore
.invalid_saved:
 mov eax,NEBO_ONTOLOGY_INVALID
.restore:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid: mov eax,NEBO_ONTOLOGY_INVALID
 ret
.limit: mov eax,NEBO_ONTOLOGY_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
