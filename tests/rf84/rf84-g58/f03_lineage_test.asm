bits 64
default rel
%include "runtime/textual/text_privacy.inc"
extern neboc_text_with_lineage
extern neboc_text_lineage
extern neboc_lineage_merge
section .data
align 8
input: dq 0x2000,NEBO_TRUST_VERIFIED,8000,9000,0,0,NEBO_PRIVACY_FLAG_TRUSTED,0
section .bss
with_lineage: resb NEBO_PRIVACY_METADATA_SIZE
digest_a: resq 1
digest_b: resq 1
digest_reverse: resq 1
section .text
global _start
_start:
 lea rdi,[rel input]
 mov rsi,0x101
 lea rdx,[rel with_lineage]
 call neboc_text_with_lineage
 test eax,eax
 jnz fail
 lea rdi,[rel with_lineage]
 call neboc_text_lineage
 cmp rax,0x101
 jne fail
 mov rdi,0x101
 mov rsi,0x202
 lea rdx,[rel digest_a]
 call neboc_lineage_merge
 test eax,eax
 jnz fail
 mov rdi,0x101
 mov rsi,0x202
 lea rdx,[rel digest_b]
 call neboc_lineage_merge
 test eax,eax
 jnz fail
 mov rax,[rel digest_a]
 cmp rax,[rel digest_b]
 jne fail
 mov rdi,0x202
 mov rsi,0x101
 lea rdx,[rel digest_reverse]
 call neboc_lineage_merge
 test eax,eax
 jnz fail
 mov rax,[rel digest_a]
 cmp rax,[rel digest_reverse]
 je fail
 mov qword [rel digest_b],0x99
 xor edi,edi
 mov esi,0x202
 lea rdx,[rel digest_b]
 call neboc_lineage_merge
 cmp eax,NEBO_PRIVACY_ERROR_LINEAGE
 jne fail
 cmp qword [rel digest_b],0x99
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,3
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
