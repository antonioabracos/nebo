; GPU-E-COMPUTACAO-ACELERADA-F04 RGA visible materialization and explicit causal stability.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/crdt/crdt_list.inc"
section .text
NEBOC_ABI_FUNCTION nebo_rga_materialize
 ; values,tombstones,count,out,capacity,out_count
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rcx,rcx
 jz .invalid
 test r9,r9
 jz .invalid
 cmp rdx,NEBO_RGA_MAX_NODES
 ja .limit
 xor eax,eax
 xor r10d,r10d
.count:
 cmp rax,rdx
 jae .preflight
 cmp byte [rsi+rax],0
 jne .next_count
 inc r10
.next_count: inc rax
 jmp .count
.preflight:
 cmp r10,r8
 ja .limit
 xor eax,eax
 xor r11d,r11d
.copy:
 cmp rax,rdx
 jae .done
 cmp byte [rsi+rax],0
 jne .next
 mov r10,[rdi+rax*8]
 mov [rcx+r11*8],r10
 inc r11
.next: inc rax
 jmp .copy
.done:
 mov [r9],r11
 xor eax,eax
 ret
.invalid: mov eax,NEBO_RGA_INVALID
 ret
.limit: mov eax,NEBO_RGA_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_causal_stable_min
 ; local,peer_ack,count,out
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp rdx,16
 ja .limit
 xor eax,eax
.loop:
 cmp rax,rdx
 jae .ok
 mov r8,[rdi+rax*8]
 mov r9,[rsi+rax*8]
 cmp r8,r9
 cmova r8,r9
 mov [rcx+rax*8],r8
 inc rax
 jmp .loop
.ok: xor eax,eax
 ret
.invalid: mov eax,NEBO_RGA_INVALID
 ret
.limit: mov eax,NEBO_RGA_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
