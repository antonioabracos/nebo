; GPU-E-COMPUTACAO-ACELERADA-F06 canonical state hash and causally stable metadata compaction.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/replication/converge.inc"
extern nebo_db_fnv1a64
section .text
NEBOC_ABI_FUNCTION nebo_replica_state_hash
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,NEBO_CONVERGE_MAX
 ja .limit
 push rbx
 mov rbx,rdx
 shl rsi,3
 call nebo_db_fnv1a64
 mov [rbx],rax
 pop rbx
 xor eax,eax
 ret
.invalid: mov eax,NEBO_CONVERGE_INVALID
 ret
.limit: mov eax,NEBO_CONVERGE_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_compact_stable_dots
 ; sequences,count,stable,out,capacity,out_count
 test rdi,rdi
 jz .invalid
 test rcx,rcx
 jz .invalid
 test r9,r9
 jz .invalid
 cmp rsi,NEBO_CONVERGE_MAX
 ja .limit
 xor eax,eax
 xor r10d,r10d
.count:
 cmp rax,rsi
 jae .preflight
 cmp [rdi+rax*8],rdx
 jbe .next_count
 inc r10
.next_count: inc rax
 jmp .count
.preflight:
 cmp r10,r8
 ja .limit
 xor eax,eax
 xor r11d,r11d
.copy:
 cmp rax,rsi
 jae .done
 mov r10,[rdi+rax*8]
 cmp r10,rdx
 jbe .next
 mov [rcx+r11*8],r10
 inc r11
.next: inc rax
 jmp .copy
.done:
 mov [r9],r11
 xor eax,eax
 ret
.invalid: mov eax,NEBO_CONVERGE_INVALID
 ret
.limit: mov eax,NEBO_CONVERGE_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
