; RUNTIME-DISTRIBUIDO-E-STREAMING-DISTRIBUIDO-F05 explicit local-vector dot and versioned hybrid score components.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/knowledge/hybrid.inc"
section .text
NEBOC_ABI_FUNCTION nebo_hybrid_score_v1
 ; a,b,dimension,lexical,out_semantic,out_total; total=3*lexical+2*dot
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test r8,r8
 jz .invalid
 test r9,r9
 jz .invalid
 test rdx,rdx
 jz .limit
 cmp rdx,NEBO_HYBRID_MAX_DIM
 ja .limit
 xor eax,eax
 xor r10d,r10d
.loop:
 cmp rax,rdx
 jae .done
 mov r11,[rdi+rax*8]
 imul r11,[rsi+rax*8]
 add r10,r11
 inc rax
 jmp .loop
.done:
 mov [r8],r10
 lea rax,[rcx+rcx*2]
 lea r10,[rax+r10*2]
 mov [r9],r10
 xor eax,eax
 ret
.invalid: mov eax,NEBO_HYBRID_INVALID
 ret
.limit: mov eax,NEBO_HYBRID_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
