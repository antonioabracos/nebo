bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/security/supply_chain.inc"
section .text
digest_nonzero:
 test rdi,rdi
 jz .zero
 mov rax,[rdi]
 or rax,[rdi+8]
 or rax,[rdi+16]
 or rax,[rdi+24]
 setnz al
 movzx eax,al
 ret
.zero: xor eax,eax
 ret
NEBOC_ABI_FUNCTION nebo_sbom_entry_verify
 test rdi,rdi
 jz .invalid
 test rdi,7
 jnz .invalid
 push r12
 mov r12,rdi
 mov qword [r12+NEBO_SBOM_ENTRY_REASON],0
 cmp qword [r12+NEBO_SBOM_ENTRY_VERSION],1
 jne .version
 mov rdi,[r12+NEBO_SBOM_ENTRY_PATH_DIGEST]
 call digest_nonzero
 test eax,eax
 jz .digest
 mov rdi,[r12+NEBO_SBOM_ENTRY_CONTENT_DIGEST]
 call digest_nonzero
 test eax,eax
 jz .digest
 mov rdi,[r12+NEBO_SBOM_ENTRY_PROVENANCE_DIGEST]
 call digest_nonzero
 test eax,eax
 jz .digest
 mov rax,[r12+NEBO_SBOM_ENTRY_SIZE_BYTES]
 cmp rax,NEBO_SBOM_MAX_FILE_SIZE
 ja .size
 mov rax,[r12+NEBO_SBOM_ENTRY_KIND]
 test rax,rax
 jz .kind
 cmp rax,4
 ja .kind
 mov rax,[r12+NEBO_SBOM_ENTRY_FLAGS]
 test rax,0xfffffffffffffffc
 jnz .flags
 xor eax,eax
 jmp .done
.version: mov eax,NEBO_SBOM_STATUS_VERSION
 jmp .reason
.digest: mov eax,NEBO_SBOM_STATUS_DIGEST
 jmp .reason
.size: mov eax,NEBO_SBOM_STATUS_SIZE
 jmp .reason
.kind: mov eax,NEBO_SBOM_STATUS_KIND
 jmp .reason
.flags: mov eax,NEBO_SBOM_STATUS_FLAGS
.reason: mov [r12+NEBO_SBOM_ENTRY_REASON],rax
.done: pop r12
 ret
.invalid: mov eax,NEBO_SBOM_STATUS_INVALID
 ret
NEBOC_ABI_FUNCTION nebo_sbom_catalog_verify
 test rdi,rdi
 jz .c_invalid
 test rdi,7
 jnz .c_invalid
 mov qword [rdi+NEBO_SBOM_CATALOG_VALID],0
 mov qword [rdi+NEBO_SBOM_CATALOG_FIRST_BAD],0
 mov r8,[rdi+NEBO_SBOM_CATALOG_ENTRIES]
 test r8,r8
 jz .c_invalid
 mov r9,[rdi+NEBO_SBOM_CATALOG_COUNT]
 test r9,r9
 jz .c_invalid
 cmp r9,NEBO_SBOM_MAX_ENTRIES
 ja .c_limit
 xor ecx,ecx
.loop:
 mov rax,rcx
 imul rax,NEBO_SBOM_ENTRY_SIZE
 add rax,r8
 cmp qword [rax+NEBO_SBOM_ENTRY_VERSION],1
 jne .bad
 cmp qword [rax+NEBO_SBOM_ENTRY_PATH_DIGEST],0
 je .bad
 cmp qword [rax+NEBO_SBOM_ENTRY_CONTENT_DIGEST],0
 je .bad
 cmp qword [rax+NEBO_SBOM_ENTRY_PROVENANCE_DIGEST],0
 je .bad
 mov rdx,[rax+NEBO_SBOM_ENTRY_SIZE_BYTES]
 cmp rdx,NEBO_SBOM_MAX_FILE_SIZE
 ja .bad
 mov rdx,[rax+NEBO_SBOM_ENTRY_KIND]
 test rdx,rdx
 jz .bad
 cmp rdx,4
 ja .bad
 inc rcx
 cmp rcx,r9
 jb .loop
 mov [rdi+NEBO_SBOM_CATALOG_VALID],r9
 xor eax,eax
 ret
.bad: inc rcx
 mov [rdi+NEBO_SBOM_CATALOG_FIRST_BAD],rcx
 mov eax,NEBO_SBOM_STATUS_DIGEST
 ret
.c_limit: mov eax,NEBO_SBOM_STATUS_LIMIT
 ret
.c_invalid: mov eax,NEBO_SBOM_STATUS_INVALID
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
