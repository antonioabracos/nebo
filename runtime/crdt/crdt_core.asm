; GPU-E-COMPUTACAO-ACELERADA-F03 PN-counter and join-semilattice core for OR/MV structures.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/crdt/crdt_core.inc"
section .text
NEBOC_ABI_FUNCTION nebo_crdt_merge_max
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp rcx,NEBO_CRDT_MAX_REPLICAS
 ja .limit
 xor eax,eax
.loop:
 cmp rax,rcx
 jae .ok
 mov r8,[rdi+rax*8]
 mov r9,[rsi+rax*8]
 cmp r8,r9
 cmovb r8,r9
 mov [rdx+rax*8],r8
 inc rax
 jmp .loop
.ok: xor eax,eax
 ret
.invalid: mov eax,NEBO_CRDT_INVALID
 ret
.limit: mov eax,NEBO_CRDT_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_pn_counter_value
 ; positive[],negative[],count,out_signed
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp rdx,NEBO_CRDT_MAX_REPLICAS
 ja .limit
 xor eax,eax
 xor r8d,r8d
 xor r9d,r9d
.loop:
 cmp rax,rdx
 jae .done
 add r8,[rdi+rax*8]
 add r9,[rsi+rax*8]
 inc rax
 jmp .loop
.done:
 sub r8,r9
 mov [rcx],r8
 xor eax,eax
 ret
.invalid: mov eax,NEBO_CRDT_INVALID
 ret
.limit: mov eax,NEBO_CRDT_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
