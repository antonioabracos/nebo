; GPU-E-COMPUTACAO-ACELERADA-F02 bounded version-vector partial order and checkpoints.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/replication/version_vector.inc"
section .text
NEBOC_ABI_FUNCTION nebo_vv_compare
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBO_VV_MAX_REPLICAS
 ja .invalid
 xor eax,eax
 xor r8d,r8d
 xor r9d,r9d
.loop:
 cmp rax,rdx
 jae .classify
 mov r10,[rdi+rax*8]
 mov r11,[rsi+rax*8]
 cmp r10,r11
 jb .less
 ja .greater
.next:
 inc rax
 jmp .loop
.less:
 mov r8d,1
 jmp .next
.greater:
 mov r9d,1
 jmp .next
.classify:
 test r8d,r8d
 jz .not_less
 test r9d,r9d
 jnz .concurrent
 mov eax,NEBO_VV_BEFORE
 ret
.not_less:
 test r9d,r9d
 jz .equal
 mov eax,NEBO_VV_AFTER
 ret
.equal:
 mov eax,NEBO_VV_EQUAL
 ret
.concurrent:
 mov eax,NEBO_VV_CONCURRENT
 ret
.invalid:
 mov eax,NEBO_VV_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_vv_checkpoint
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rdx,NEBO_VV_MAX_REPLICAS
 ja .invalid
 xor eax,eax
.copy:
 cmp rax,rdx
 jae .done
 mov rcx,[rdi+rax*8]
 mov [rsi+rax*8],rcx
 inc rax
 jmp .copy
.done:
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_VV_INVALID
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
