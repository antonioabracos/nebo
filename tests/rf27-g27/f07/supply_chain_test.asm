bits 64
default rel
%include "runtime/security/supply_chain.inc"
extern nebo_sbom_entry_verify
extern nebo_sbom_catalog_verify
section .rodata
digest_a: times 32 db 0x11
digest_b: times 32 db 0x22
digest_c: times 32 db 0x33
zero: times 32 db 0
section .bss
align 16
entries resb NEBO_SBOM_ENTRY_SIZE*2
catalog resb NEBO_SBOM_CATALOG_SIZE
section .text
prepare:
 lea rdi,[entries]
 mov ecx,NEBO_SBOM_ENTRY_SIZE*2/8
 xor eax,eax
 rep stosq
 xor ecx,ecx
.loop:
 mov rax,rcx
 imul rax,NEBO_SBOM_ENTRY_SIZE
 lea rdx,[entries+rax]
 mov qword [rdx+NEBO_SBOM_ENTRY_VERSION],1
 lea rax,[digest_a]
 mov [rdx+NEBO_SBOM_ENTRY_PATH_DIGEST],rax
 lea rax,[digest_b]
 mov [rdx+NEBO_SBOM_ENTRY_CONTENT_DIGEST],rax
 lea rax,[digest_c]
 mov [rdx+NEBO_SBOM_ENTRY_PROVENANCE_DIGEST],rax
 mov qword [rdx+NEBO_SBOM_ENTRY_SIZE_BYTES],4096
 mov qword [rdx+NEBO_SBOM_ENTRY_KIND],1
 inc rcx
 cmp rcx,2
 jb .loop
 ret
global _start
_start:
 call prepare
 lea rdi,[entries]
 call nebo_sbom_entry_verify
 test eax,eax
 jnz .f1
 mov qword [entries+NEBO_SBOM_ENTRY_VERSION],2
 lea rdi,[entries]
 call nebo_sbom_entry_verify
 cmp eax,NEBO_SBOM_STATUS_VERSION
 jne .f2
 call prepare
 lea rax,[zero]
 mov [entries+NEBO_SBOM_ENTRY_CONTENT_DIGEST],rax
 lea rdi,[entries]
 call nebo_sbom_entry_verify
 cmp eax,NEBO_SBOM_STATUS_DIGEST
 jne .f3
 call prepare
 mov qword [entries+NEBO_SBOM_ENTRY_SIZE_BYTES],1073741825
 lea rdi,[entries]
 call nebo_sbom_entry_verify
 cmp eax,NEBO_SBOM_STATUS_SIZE
 jne .f4
 call prepare
 mov qword [entries+NEBO_SBOM_ENTRY_KIND],5
 lea rdi,[entries]
 call nebo_sbom_entry_verify
 cmp eax,NEBO_SBOM_STATUS_KIND
 jne .f5
 call prepare
 mov qword [entries+NEBO_SBOM_ENTRY_FLAGS],4
 lea rdi,[entries]
 call nebo_sbom_entry_verify
 cmp eax,NEBO_SBOM_STATUS_FLAGS
 jne .f6
 call prepare
 lea rdi,[catalog]
 mov ecx,NEBO_SBOM_CATALOG_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[entries]
 mov [catalog+NEBO_SBOM_CATALOG_ENTRIES],rax
 mov qword [catalog+NEBO_SBOM_CATALOG_COUNT],2
 lea rdi,[catalog]
 call nebo_sbom_catalog_verify
 test eax,eax
 jnz .f7
 cmp qword [catalog+NEBO_SBOM_CATALOG_VALID],2
 jne .f8
 mov qword [entries+NEBO_SBOM_ENTRY_SIZE+NEBO_SBOM_ENTRY_CONTENT_DIGEST],0
 lea rdi,[catalog]
 call nebo_sbom_catalog_verify
 cmp eax,NEBO_SBOM_STATUS_DIGEST
 jne .f9
 cmp qword [catalog+NEBO_SBOM_CATALOG_FIRST_BAD],2
 jne .f10
 mov qword [catalog+NEBO_SBOM_CATALOG_COUNT],8193
 lea rdi,[catalog]
 call nebo_sbom_catalog_verify
 cmp eax,NEBO_SBOM_STATUS_LIMIT
 jne .f11
 xor edi,edi
 call nebo_sbom_entry_verify
 cmp eax,NEBO_SBOM_STATUS_INVALID
 jne .f12
 xor edi,edi
 call nebo_sbom_catalog_verify
 cmp eax,NEBO_SBOM_STATUS_INVALID
 jne .f13
 xor edi,edi
 mov eax,60
 syscall
%macro FAIL 1
.f%1: mov edi,%1
 mov eax,60
 syscall
%endmacro
%assign i 1
%rep 13
FAIL i
%assign i i+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
