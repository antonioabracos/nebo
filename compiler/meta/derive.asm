; FILESYSTEM-PATHS-E-FORMATOS-F04 deterministic bounded derive eligibility and plan.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/meta/derive.inc"
section .text
NEBOC_ABI_FUNCTION nebo_derive_plan
 ; requested mask, field capability qwords, field count, output plan qword
 test rcx,rcx
 jz .invalid
 mov qword [rcx],0
 mov r8,rdi
 not r8
 test r8,NEBO_DERIVE_SUPPORTED
 ; ignore unrelated high bits check below explicitly
 mov r8,rdi
 and r8,~NEBO_DERIVE_SUPPORTED
 jnz .unsupported
 cmp rdx,NEBO_DERIVE_MAX_FIELDS
 ja .limit
 test rdx,rdx
 jz .success
 test rsi,rsi
 jz .invalid
 xor r8d,r8d
.loop:
 mov rax,[rsi+r8*8]
 test rdi,NEBO_DERIVE_EQ
 jz .hash
 test rax,NEBO_DERIVE_FIELD_EQ
 jz .ineligible
.hash:
 test rdi,NEBO_DERIVE_HASH
 jz .clone
 mov r9,NEBO_DERIVE_FIELD_EQ|NEBO_DERIVE_FIELD_HASH
 and r9,rax
 cmp r9,NEBO_DERIVE_FIELD_EQ|NEBO_DERIVE_FIELD_HASH
 jne .ineligible
.clone:
 test rdi,NEBO_DERIVE_CLONE
 jz .debug
 test rax,NEBO_DERIVE_FIELD_CLONE
 jz .ineligible
.debug:
 test rdi,NEBO_DERIVE_DEBUG
 jz .next
 test rax,NEBO_DERIVE_FIELD_DEBUG
 jz .ineligible
.next:
 inc r8
 cmp r8,rdx
 jb .loop
.success:
 mov [rcx],rdi
 xor eax,eax
 ret
.invalid: mov eax,NEBO_DERIVE_STATUS_INVALID
 ret
.unsupported: mov eax,NEBO_DERIVE_STATUS_UNSUPPORTED
 ret
.ineligible: mov eax,NEBO_DERIVE_STATUS_INELIGIBLE
 ret
.limit: mov eax,NEBO_DERIVE_STATUS_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
