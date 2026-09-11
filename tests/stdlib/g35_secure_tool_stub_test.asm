bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/stdlib/secure_local_profile.inc"
extern neboc_secure_local_profile_validate
extern neboc_host_process_exit
section .bss align=16
p: resb SLP_SIZE
section .text
reset:
 lea rdi,[rel p]
 mov ecx,SLP_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel p+SLP_MODE],SLP_MODE_TOOL_STUB
 mov qword [rel p+SLP_IDENTITY_HASH],0x35aa
 mov qword [rel p+SLP_SCHEMA_HASH],0x35bb
 mov qword [rel p+SLP_CAPABILITY_MASK],1
 mov qword [rel p+SLP_BUDGET_USED],8
 mov qword [rel p+SLP_BUDGET_LIMIT],16
 mov qword [rel p+SLP_APPROVAL_REQUIRED],1
 mov qword [rel p+SLP_APPROVAL_GRANTED],1
 mov qword [rel p+SLP_PRIVACY_FLAGS],SLP_REQUIRED_PRIVACY
 mov qword [rel p+SLP_LINEAGE_HASH],0x35cc
 mov qword [rel p+SLP_OWNERSHIP_FLAGS],SLP_REQUIRED_OWNERSHIP
 mov qword [rel p+SLP_ISOLATION_FLAGS],SLP_REQUIRED_ISOLATION
 mov qword [rel p+SLP_EXTERNAL_ACTIONS],0
 call seal
 ret
seal:
 mov rax,SLP_SEAL_MAGIC
 lea rdi,[rel p]
 xor edx,edx
 mov ecx,13
.l: xor rax,[rdi+rdx*8]
 inc edx
 loop .l
 mov [rel p+SLP_SEAL],rax
 ret
bad:
 lea rdi,[rel p]
 call neboc_secure_local_profile_validate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 ret
global _start
_start:
 mov r15d,1
 xor edi,edi
 call neboc_secure_local_profile_validate
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail
 mov r15d,2
 call reset
 lea rdi,[rel p]
 call neboc_secure_local_profile_validate
 test eax,eax
 jnz fail
 cmp qword [rel p+SLP_RESULT],SLP_MODE_TOOL_STUB
 jne fail
 mov r15d,10
 call reset
 mov qword [rel p+SLP_SCHEMA_HASH],0
 call seal
 call bad
 inc r15d
 call reset
 mov qword [rel p+SLP_BUDGET_USED],17
 call seal
 call bad
 inc r15d
 call reset
 mov qword [rel p+SLP_APPROVAL_GRANTED],0
 call seal
 call bad
 inc r15d
 call reset
 mov qword [rel p+SLP_PRIVACY_FLAGS],0
 call seal
 call bad
 inc r15d
 call reset
 mov qword [rel p+SLP_EXTERNAL_ACTIONS],1
 call seal
 call bad
 inc r15d
 call reset
 inc qword [rel p+SLP_SEAL]
 call bad
 xor edi,edi
 jmp neboc_host_process_exit
fail: mov edi,r15d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
