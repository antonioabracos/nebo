; MACHINE-LEARNING-NEURON-NETWORK-E-MODEL-F07 bounded backup verification and compaction.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/database/db_maintenance.inc"
extern nebo_db_fnv1a64
section .text
NEBOC_ABI_FUNCTION nebo_db_backup_copy
 ; src,dst,bytes,out_hash
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rcx,rcx
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBO_DB_BACKUP_MAX_BYTES
 ja .limit
 push rbx
 push r12
 mov rbx,rsi
 mov r12,rcx
 xor eax,eax
.copy:
 cmp rax,rdx
 jae .hash
 mov r8b,[rdi+rax]
 mov [rbx+rax],r8b
 inc rax
 jmp .copy
.hash:
 mov rdi,rbx
 mov rsi,rdx
 call nebo_db_fnv1a64
 mov [r12],rax
 pop r12
 pop rbx
 xor eax,eax
 ret
.invalid: mov eax,NEBO_DB_MAINT_INVALID
 ret
.limit: mov eax,NEBO_DB_MAINT_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_db_backup_verify
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rdx,NEBO_DB_BACKUP_MAX_BYTES
 ja .limit
 xor eax,eax
.loop:
 cmp rax,rdx
 jae .ok
 mov r8b,[rdi+rax]
 cmp r8b,[rsi+rax]
 jne .mismatch
 inc rax
 jmp .loop
.ok: xor eax,eax
 ret
.invalid: mov eax,NEBO_DB_MAINT_INVALID
 ret
.limit: mov eax,NEBO_DB_MAINT_LIMIT
 ret
.mismatch: mov eax,NEBO_DB_MAINT_MISMATCH
 ret

NEBOC_ABI_FUNCTION nebo_db_compact_nonzero
 ; src,count,dst,capacity,out_count
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test r8,r8
 jz .invalid
 cmp rsi,4096
 ja .limit
 xor eax,eax
 xor r9d,r9d
.count:
 cmp rax,rsi
 jae .preflight
 cmp qword [rdi+rax*8],0
 je .next_count
 inc r9
.next_count:
 inc rax
 jmp .count
.preflight:
 cmp r9,rcx
 ja .limit
 xor eax,eax
 xor r10d,r10d
.copy:
 cmp rax,rsi
 jae .done
 mov r11,[rdi+rax*8]
 test r11,r11
 jz .next
 mov [rdx+r10*8],r11
 inc r10
.next:
 inc rax
 jmp .copy
.done:
 mov [r8],r10
 xor eax,eax
 ret
.invalid: mov eax,NEBO_DB_MAINT_INVALID
 ret
.limit: mov eax,NEBO_DB_MAINT_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
